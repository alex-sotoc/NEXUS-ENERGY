from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Dispositivo, LecturaConsumo
from app.schemas import (
    SimulatorConnectRequest,
    SimulatorDisconnectRequest,
    SimulatorModeRequest,
    SimulatorCustomDeviceRequest,
    SimulatorStateResponse,
    TelemetryRequest,
    TelemetryResponse,
)


router = APIRouter(
    prefix="/api/simulator",
    tags=["Simulator"],
)


# ============================================================
# CONFIGURACIÓN DE COSTO DE ENERGÍA
# ============================================================

# Tarifa utilizada actualmente por el prototipo NEXUS ENERGY.
#
# Representa:
#
#     pesos mexicanos por kWh
#
# Este valor es configurable.
#
# IMPORTANTE:
# Se utiliza como tarifa de prueba del prototipo.
# No representa automáticamente una tarifa oficial de CFE.
TARIFA_MXN_KWH = 1.10


# Evita que una pausa larga del simulador genere
# de golpe un costo exagerado cuando vuelva a enviar
# telemetría.
#
# La aplicación simuladora normalmente transmite
# aproximadamente cada 2 segundos.
MAX_INTERVAL_SECONDS = 10.0


# ============================================================
# PERFILES DE DISPOSITIVOS DEL SIMULADOR
# ============================================================

SIMULATOR_PROFILES = {
    "SIM_CARGADOR_5V_1A": {
        "nombre": "Cargador 5V 1A",
        "ubicacion": "Stand NEXUS",
        "watts_standby": 0.10,
        "watts_min": 3.50,
        "watts_max": 5.00,
        "voltaje_nominal": 5.0,
        "es_vampiro": True,
    },

    "SIM_CARGADOR_33W": {
        "nombre": "Cargador 33W",
        "ubicacion": "Stand NEXUS",
        "watts_standby": 0.20,
        "watts_min": 20.00,
        "watts_max": 33.00,
        "voltaje_nominal": 5.0,
        "es_vampiro": True,
    },

    "SIM_VENTILADOR_PEQUENO": {
        "nombre": "Ventilador pequeño",
        "ubicacion": "Stand NEXUS",
        "watts_standby": 0.00,
        "watts_min": 3.00,
        "watts_max": 10.00,
        "voltaje_nominal": 5.0,
        "es_vampiro": False,
    },
}


# ============================================================
# HELPERS
# ============================================================

def _utc_now() -> datetime:
    """
    Devuelve la fecha/hora actual en UTC sin información
    de zona horaria para mantener compatibilidad con SQL Server.
    """
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _safe_float(value) -> float:
    """
    Convierte un valor a float de manera segura.

    Si el valor es None o no puede convertirse,
    devuelve 0.0.
    """

    if value is None:
        return 0.0

    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


def _calculate_energy_cost(
    watts: float,
    elapsed_seconds: float,
) -> float:
    """
    Calcula el costo de energía correspondiente
    al intervalo entre dos lecturas.

    Fórmula:

        horas = segundos / 3600

        kWh = (watts / 1000) * horas

        costo_mxn = kWh * TARIFA_MXN_KWH

    El resultado representa el costo generado
    únicamente durante el intervalo de esta lectura.
    """

    watts = max(
        0.0,
        _safe_float(watts),
    )

    elapsed_seconds = max(
        0.0,
        _safe_float(elapsed_seconds),
    )

    # Evitamos contabilizar un periodo demasiado largo
    # si el simulador estuvo pausado, desconectado
    # o perdió temporalmente la comunicación.
    elapsed_seconds = min(
        elapsed_seconds,
        MAX_INTERVAL_SECONDS,
    )

    hours = (
        elapsed_seconds / 3600.0
    )

    kwh = (
        watts / 1000.0
    ) * hours

    costo_mxn = (
        kwh * TARIFA_MXN_KWH
    )

    return costo_mxn


def _find_device(
    db: Session,
    device_id: str,
) -> Dispositivo | None:
    """
    Busca un dispositivo por su device_id.
    """

    return (
        db.query(Dispositivo)
        .filter(
            Dispositivo.device_id == device_id
        )
        .first()
    )


def _get_profile(
    device_id: str,
) -> dict:
    """
    Obtiene el perfil conocido del dispositivo.

    Si el device_id no pertenece a uno de los
    dispositivos oficiales del simulador,
    genera un perfil genérico.
    """

    profile = SIMULATOR_PROFILES.get(
        device_id
    )

    if profile is not None:
        return profile

    return {
        "nombre": device_id,
        "ubicacion": "Stand NEXUS",
        "watts_standby": 0.0,
        "watts_min": 0.0,
        "watts_max": 0.0,
        "voltaje_nominal": 5.0,
        "es_vampiro": False,
    }


def _create_device(
    db: Session,
    device_id: str,
) -> Dispositivo:
    """
    Crea automáticamente un dispositivo si no existe.
    """

    profile = _get_profile(
        device_id
    )

    device = Dispositivo(
        device_id=device_id,

        nombre=profile["nombre"],
        ubicacion=profile["ubicacion"],

        estado_on=False,
        conectado=False,
        simulacion_activa=False,

        watts_actuales=0.0,
        amps_actuales=0.0,
        volts_actuales=0.0,

        costo_mxn_hora=0.0,

        es_vampiro=profile["es_vampiro"],

        watts_standby=profile["watts_standby"],
        watts_min=profile["watts_min"],
        watts_max=profile["watts_max"],

        voltaje_nominal=profile["voltaje_nominal"],

        mac_esp32=None,

        ultima_comunicacion=None,
        creado_en=_utc_now(),
    )

    db.add(device)

    # Inserta sin cerrar todavía la transacción.
    db.flush()

    return device


def _disconnect_other_devices(
    db: Session,
    except_device_id: str | None = None,
):
    """
    Garantiza que solamente exista un dispositivo
    conectado al simulador al mismo tiempo.

    Para SQL Server utilizamos == True.
    """

    query = db.query(
        Dispositivo
    ).filter(
        Dispositivo.conectado == True
    )

    if except_device_id is not None:
        query = query.filter(
            Dispositivo.device_id
            != except_device_id
        )

    devices = query.all()

    for device in devices:

        device.conectado = False
        device.simulacion_activa = False

        device.estado_on = False

        device.watts_actuales = 0.0
        device.amps_actuales = 0.0
        device.volts_actuales = 0.0

        # Al desconectarse no existe consumo actual,
        # por lo tanto tampoco existe costo por hora.
        device.costo_mxn_hora = 0.0

        device.ultima_comunicacion = (
            _utc_now()
        )


def _state_response(
    device: Dispositivo,
) -> SimulatorStateResponse:
    """
    Construye la respuesta que recibe
    la aplicación simuladora.

    Solo muestra valores distintos de cero si:

        conectado = True
        simulacion_activa = True
        estado_on = True
    """

    show_values = (
        bool(device.conectado)
        and bool(device.simulacion_activa)
        and bool(device.estado_on)
    )

    if show_values:

        watts = _safe_float(
            device.watts_actuales
        )

        amps = _safe_float(
            device.amps_actuales
        )

        volts = _safe_float(
            device.volts_actuales
        )

    else:

        watts = 0.0
        amps = 0.0
        volts = 0.0

    return SimulatorStateResponse(
        device_id=device.device_id,
        device_name=device.nombre,

        connected=bool(
            device.conectado
        ),

        simulation_active=bool(
            device.simulacion_activa
        ),

        relay_state=bool(
            device.estado_on
        ),

        watts=watts,
        amps=amps,
        volts=volts,

        timestamp=device.ultima_comunicacion,
    )


def _generate_custom_device_id(
    db: Session,
) -> str:
    """
    Genera un identificador interno único
    para dispositivos personalizados.
    """

    for _ in range(10):

        device_id = (
            "CUSTOM_"
            + uuid4().hex[:12].upper()
        )

        existing = _find_device(
            db=db,
            device_id=device_id,
        )

        if existing is None:
            return device_id

    raise HTTPException(
        status_code=500,
        detail=(
            "No fue posible generar un "
            "identificador único."
        ),
    )


# ============================================================
# CONECTAR DISPOSITIVO AL SIMULADOR
# ============================================================

@router.post(
    "/connect",
    response_model=SimulatorStateResponse,
)
def connect_simulator_device(
    request: SimulatorConnectRequest,
    db: Session = Depends(get_db),
):
    """
    Selecciona el dispositivo que utilizará
    actualmente la aplicación simuladora.

    Si el dispositivo existe:
        se reutiliza.

    Si no existe:
        se crea automáticamente.

    Solamente puede existir un dispositivo conectado
    al simulador al mismo tiempo.

    Al conectarlo comienza con el relay lógico apagado.
    """

    try:

        # ----------------------------------------------------
        # 1. BUSCAR DISPOSITIVO
        # ----------------------------------------------------

        device = _find_device(
            db=db,
            device_id=request.device_id,
        )

        # ----------------------------------------------------
        # 2. SI NO EXISTE, CREARLO
        # ----------------------------------------------------

        if device is None:

            device = _create_device(
                db=db,
                device_id=request.device_id,
            )

        # ----------------------------------------------------
        # 3. DESCONECTAR CUALQUIER OTRO DISPOSITIVO
        # ----------------------------------------------------

        _disconnect_other_devices(
            db=db,
            except_device_id=device.device_id,
        )

        # ----------------------------------------------------
        # 4. CONECTAR EL DISPOSITIVO
        # ----------------------------------------------------

        device.conectado = True
        device.simulacion_activa = True

        # Todavía no comienza a consumir.
        # La app simuladora elegirá working o standby.
        device.estado_on = False

        device.watts_actuales = 0.0
        device.amps_actuales = 0.0
        device.volts_actuales = 0.0

        # Al conectarse todavía no existe consumo.
        device.costo_mxn_hora = 0.0

        device.ultima_comunicacion = (
            _utc_now()
        )

        # ----------------------------------------------------
        # 5. GUARDAR
        # ----------------------------------------------------

        db.commit()

        # ----------------------------------------------------
        # 6. RECARGAR
        # ----------------------------------------------------

        db.refresh(
            device
        )

        # ----------------------------------------------------
        # 7. RESPONDER
        # ----------------------------------------------------

        return _state_response(
            device
        )

    except HTTPException:

        db.rollback()
        raise

    except Exception as e:

        db.rollback()

        raise HTTPException(
            status_code=400,
            detail=str(e),
        )


# ============================================================
# CAMBIAR MODO DEL SIMULADOR
# ============================================================

@router.post(
    "/mode",
    response_model=SimulatorStateResponse,
)
def set_simulator_mode(
    request: SimulatorModeRequest,
    db: Session = Depends(get_db),
):
    """
    Cambia el modo lógico del dispositivo.

    Modos permitidos:

        working
        standby

    En ambos modos el dispositivo continúa
    recibiendo energía, por lo tanto:

        conectado = True
        simulacion_activa = True
        estado_on = True

    La diferencia entre working y standby
    estará en los valores que envíe la
    aplicación simuladora.

    IMPORTANTE:

    Si posteriormente la app principal apaga
    el relay, estado_on pasará a False y el
    endpoint de telemetría forzará los valores
    nuevamente a cero.
    """

    try:

        # ----------------------------------------------------
        # 1. BUSCAR DISPOSITIVO
        # ----------------------------------------------------

        device = _find_device(
            db=db,
            device_id=request.device_id,
        )

        if device is None:

            raise HTTPException(
                status_code=404,
                detail=(
                    f"Dispositivo "
                    f"'{request.device_id}' "
                    "no encontrado."
                ),
            )

        # ----------------------------------------------------
        # 2. VALIDAR MODO
        # ----------------------------------------------------

        mode = (
            request.mode
            .strip()
            .lower()
        )

        if mode not in {
            "working",
            "standby",
        }:

            raise HTTPException(
                status_code=400,
                detail=(
                    "Modo no válido. "
                    "Utiliza 'working' "
                    "o 'standby'."
                ),
            )

        # ----------------------------------------------------
        # 3. DESCONECTAR OTROS DISPOSITIVOS
        # ----------------------------------------------------

        _disconnect_other_devices(
            db=db,
            except_device_id=device.device_id,
        )

        # ----------------------------------------------------
        # 4. ACTIVAR DISPOSITIVO
        # ----------------------------------------------------

        device.conectado = True
        device.simulacion_activa = True

        # Tanto working como standby significan
        # que el dispositivo sigue energizado.
        device.estado_on = True

        # Limpiamos la lectura anterior.
        # La siguiente petición /telemetry
        # escribirá el valor del nuevo modo.
        device.watts_actuales = 0.0
        device.amps_actuales = 0.0
        device.volts_actuales = 0.0

        device.costo_mxn_hora = 0.0

        device.ultima_comunicacion = (
            _utc_now()
        )

        # ----------------------------------------------------
        # 5. GUARDAR
        # ----------------------------------------------------

        db.commit()

        db.refresh(
            device
        )

        # ----------------------------------------------------
        # 6. RESPONDER
        # ----------------------------------------------------

        return _state_response(
            device
        )

    except HTTPException:

        db.rollback()
        raise

    except Exception as e:

        db.rollback()

        raise HTTPException(
            status_code=400,
            detail=str(e),
        )


# ============================================================
# CREAR DISPOSITIVO PERSONALIZADO
# ============================================================

@router.post(
    "/custom-device",
    response_model=SimulatorStateResponse,
)
def create_custom_simulator_device(
    request: SimulatorCustomDeviceRequest,
    db: Session = Depends(get_db),
):
    """
    Crea un dispositivo personalizado desde
    la aplicación simuladora.

    Se genera automáticamente un device_id interno.

    El dispositivo queda:

        conectado = True
        simulacion_activa = True
        estado_on = False

    Después la app simuladora podrá cambiarlo
    a working o standby mediante /mode.
    """

    try:

        # ----------------------------------------------------
        # 1. LIMPIAR NOMBRE
        # ----------------------------------------------------

        nombre = (
            request.nombre
            .strip()
        )

        if len(nombre) < 2:

            raise HTTPException(
                status_code=400,
                detail=(
                    "El nombre del dispositivo "
                    "debe tener al menos "
                    "2 caracteres."
                ),
            )

        # ----------------------------------------------------
        # 2. VALIDAR RANGO DE POTENCIA
        # ----------------------------------------------------

        if (
            request.watts_max
            < request.watts_min
        ):

            raise HTTPException(
                status_code=400,
                detail=(
                    "La potencia máxima no puede "
                    "ser menor que la potencia mínima."
                ),
            )

        # ----------------------------------------------------
        # 3. GENERAR IDENTIFICADOR INTERNO
        # ----------------------------------------------------

        device_id = (
            _generate_custom_device_id(
                db
            )
        )

        # ----------------------------------------------------
        # 4. DESCONECTAR OTROS DISPOSITIVOS
        # ----------------------------------------------------

        _disconnect_other_devices(
            db=db,
        )

        # ----------------------------------------------------
        # 5. DETERMINAR CONSUMO VAMPIRO
        # ----------------------------------------------------

        # Si existe consumo standby mayor que cero,
        # automáticamente se considera vampiro.
        es_vampiro = (
            bool(request.es_vampiro)
            or request.watts_standby > 0
        )

        # ----------------------------------------------------
        # 6. CREAR DISPOSITIVO
        # ----------------------------------------------------

        now = _utc_now()

        device = Dispositivo(
            device_id=device_id,

            nombre=nombre,
            ubicacion="Stand NEXUS",

            estado_on=False,
            conectado=True,
            simulacion_activa=True,

            watts_actuales=0.0,
            amps_actuales=0.0,
            volts_actuales=0.0,

            costo_mxn_hora=0.0,

            es_vampiro=es_vampiro,

            watts_standby=(
                request.watts_standby
            ),

            watts_min=(
                request.watts_min
            ),

            watts_max=(
                request.watts_max
            ),

            voltaje_nominal=(
                request.voltaje_nominal
            ),

            mac_esp32=None,

            ultima_comunicacion=now,
            creado_en=now,
        )

        # ----------------------------------------------------
        # 7. GUARDAR
        # ----------------------------------------------------

        db.add(
            device
        )

        db.commit()

        db.refresh(
            device
        )

        # ----------------------------------------------------
        # 8. RESPONDER
        # ----------------------------------------------------

        return _state_response(
            device
        )

    except HTTPException:

        db.rollback()
        raise

    except Exception as e:

        db.rollback()

        raise HTTPException(
            status_code=400,
            detail=str(e),
        )


# ============================================================
# DESCONECTAR DISPOSITIVO DEL SIMULADOR
# ============================================================

@router.post(
    "/disconnect",
    response_model=SimulatorStateResponse,
)
def disconnect_simulator(
    request: SimulatorDisconnectRequest,
    db: Session = Depends(get_db),
):
    """
    Detiene completamente la simulación
    del dispositivo seleccionado.
    """

    try:

        # ----------------------------------------------------
        # 1. BUSCAR
        # ----------------------------------------------------

        device = _find_device(
            db=db,
            device_id=request.device_id,
        )

        if device is None:

            raise HTTPException(
                status_code=404,
                detail=(
                    f"Dispositivo "
                    f"'{request.device_id}' "
                    "no encontrado."
                ),
            )

        # ----------------------------------------------------
        # 2. DESCONECTAR
        # ----------------------------------------------------

        device.conectado = False
        device.simulacion_activa = False

        device.estado_on = False

        device.watts_actuales = 0.0
        device.amps_actuales = 0.0
        device.volts_actuales = 0.0

        device.costo_mxn_hora = 0.0

        device.ultima_comunicacion = (
            _utc_now()
        )

        # ----------------------------------------------------
        # 3. GUARDAR
        # ----------------------------------------------------

        db.commit()

        db.refresh(
            device
        )

        # ----------------------------------------------------
        # 4. RESPONDER
        # ----------------------------------------------------

        return _state_response(
            device
        )

    except HTTPException:

        db.rollback()
        raise

    except Exception as e:

        db.rollback()

        raise HTTPException(
            status_code=400,
            detail=str(e),
        )


# ============================================================
# CONSULTAR ESTADO DEL SIMULADOR
# ============================================================

@router.get(
    "/state/{device_id}",
    response_model=SimulatorStateResponse,
)
def get_simulator_state(
    device_id: str,
    db: Session = Depends(get_db),
):
    """
    Devuelve el estado actual de un dispositivo
    dentro del simulador.
    """

    try:

        device = _find_device(
            db=db,
            device_id=device_id,
        )

        if device is None:

            raise HTTPException(
                status_code=404,
                detail=(
                    f"Dispositivo "
                    f"'{device_id}' "
                    "no encontrado."
                ),
            )

        return _state_response(
            device
        )

    except HTTPException:

        db.rollback()
        raise

    except Exception as e:

        db.rollback()

        raise HTTPException(
            status_code=400,
            detail=str(e),
        )


# ============================================================
# RECIBIR TELEMETRÍA SIMULADA
# ============================================================

@router.post(
    "/telemetry",
    response_model=TelemetryResponse,
)
def receive_simulated_telemetry(
    request: TelemetryRequest,
    db: Session = Depends(get_db),
):
    """
    Recibe una lectura generada por
    la aplicación simuladora.

    Para aceptar valores diferentes de cero
    deben cumplirse:

        1. El dispositivo existe.
        2. Está conectado.
        3. La simulación está activa.
        4. El relay está encendido.

    Si alguna condición no se cumple,
    FastAPI ignora el consumo recibido
    y guarda una lectura en cero.

    El costo de energía NO depende del valor
    costo_mxn enviado por Flutter.

    FastAPI calcula automáticamente el costo
    utilizando:

        potencia
        tiempo entre lecturas
        tarifa MXN/kWh
    """

    try:

        # ----------------------------------------------------
        # 1. BUSCAR DISPOSITIVO
        # ----------------------------------------------------

        device = _find_device(
            db=db,
            device_id=request.device_id,
        )

        if device is None:

            raise HTTPException(
                status_code=404,
                detail=(
                    f"Dispositivo "
                    f"'{request.device_id}' "
                    "no encontrado."
                ),
            )

        now = _utc_now()

        # ----------------------------------------------------
        # 2. CALCULAR TIEMPO ENTRE LECTURAS
        # ----------------------------------------------------

        if device.ultima_comunicacion is not None:

            elapsed_seconds = (
                now
                - device.ultima_comunicacion
            ).total_seconds()

        else:

            # La aplicación simuladora transmite
            # normalmente cada 2 segundos.
            elapsed_seconds = 2.0

        # Evitamos valores negativos.
        elapsed_seconds = max(
            0.0,
            elapsed_seconds,
        )

        # ----------------------------------------------------
        # 3. COMPROBAR SI SE ADMITE CONSUMO
        # ----------------------------------------------------

        simulation_allowed = (
            bool(device.conectado)
            and bool(device.simulacion_activa)
            and bool(device.estado_on)
        )

        # ----------------------------------------------------
        # 4. PREPARAR VALORES
        # ----------------------------------------------------

        if simulation_allowed:

            watts = _safe_float(
                request.watts
            )

            amps = _safe_float(
                request.amps
            )

            volts = _safe_float(
                request.volts
            )

            # ----------------------------------------------
            # NUEVO:
            # FASTAPI CALCULA EL COSTO EN MXN
            # ----------------------------------------------

            costo_mxn = _calculate_energy_cost(
                watts=watts,
                elapsed_seconds=elapsed_seconds,
            )

        else:

            watts = 0.0
            amps = 0.0
            volts = 0.0
            costo_mxn = 0.0

        # ----------------------------------------------------
        # 5. ACTUALIZAR VALORES ACTUALES
        # ----------------------------------------------------

        device.watts_actuales = watts
        device.amps_actuales = amps
        device.volts_actuales = volts

        # Costo estimado si la potencia actual
        # permaneciera durante una hora.
        #
        # Ejemplo:
        #
        # 100 W = 0.1 kW
        #
        # 0.1 kW * $1.10/kWh
        # = $0.11 MXN por hora
        if simulation_allowed:

            device.costo_mxn_hora = (
                (watts / 1000.0)
                * TARIFA_MXN_KWH
            )

        else:

            device.costo_mxn_hora = 0.0

        device.ultima_comunicacion = now

        # ----------------------------------------------------
        # 6. CREAR HISTORIAL
        # ----------------------------------------------------

        reading = LecturaConsumo(
            dispositivo_id=device.id,

            watts=watts,
            amps=amps,
            volts=volts,

            # Este valor ya fue calculado por FastAPI.
            costo_mxn=costo_mxn,

            fecha_hora=now,
        )

        db.add(
            reading
        )

        # ----------------------------------------------------
        # 7. GUARDAR
        # ----------------------------------------------------

        db.commit()

        # ----------------------------------------------------
        # 8. RECARGAR LECTURA
        # ----------------------------------------------------

        db.refresh(
            reading
        )

        # ----------------------------------------------------
        # 9. RESPONDER
        # ----------------------------------------------------

        return TelemetryResponse(
            message=(
                "Telemetría simulada recibida."
            ),

            device_id=device.device_id,

            device_database_id=device.id,

            watts=watts,
            amps=amps,
            volts=volts,

            timestamp=now,
        )

    except HTTPException:

        db.rollback()
        raise

    except Exception as e:

        db.rollback()

        raise HTTPException(
            status_code=400,
            detail=str(e),
        )