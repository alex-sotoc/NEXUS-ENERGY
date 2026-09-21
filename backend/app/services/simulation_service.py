import random
from datetime import datetime

from sqlalchemy.orm import Session

from app import crud
from app.models import Dispositivo


# ============================================================
# OBTENER DISPOSITIVO
# ============================================================

def get_device(
    db: Session,
    device_id: str,
) -> Dispositivo | None:

    return crud.get_device_by_device_id(
        db,
        device_id,
    )


# ============================================================
# CONECTAR DISPOSITIVO AL SIMULADOR
# ============================================================

def connect_device(
    db: Session,
    device_id: str,
) -> Dispositivo | None:
    """
    Conecta un dispositivo al simulador.

    La conexión NO enciende el relay.

    Por lo tanto:

        conectado = True
        simulacion_activa = True
        estado_on = False
        watts = 0
        amps = 0
        volts = 0
    """

    device = get_device(
        db,
        device_id,
    )

    if device is None:
        return None

    return crud.connect_device(
        db,
        device,
    )


# ============================================================
# DESCONECTAR DISPOSITIVO
# ============================================================

def disconnect_device(
    db: Session,
    device_id: str,
) -> Dispositivo | None:
    """
    Desconecta el dispositivo del simulador.

    Todo el consumo queda en cero.
    """

    device = get_device(
        db,
        device_id,
    )

    if device is None:
        return None

    return crud.disconnect_device(
        db,
        device,
    )


# ============================================================
# GENERAR WATTS
# ============================================================

def generate_watts(
    device: Dispositivo,
) -> float:
    """
    Genera un valor de consumo simulado.

    Reglas:

    1. Si no está conectado -> 0 W
    2. Si la simulación no está activa -> 0 W
    3. Si el relay está apagado -> 0 W
    4. Si está encendido -> valor entre watts_min y watts_max
    """

    if not device.conectado:
        return 0.0

    if not device.simulacion_activa:
        return 0.0

    if not device.estado_on:
        return 0.0

    minimum = max(
        0.0,
        device.watts_min,
    )

    maximum = max(
        minimum,
        device.watts_max,
    )

    if maximum == 0:
        return 0.0

    return round(
        random.uniform(
            minimum,
            maximum,
        ),
        2,
    )


# ============================================================
# GENERAR STANDBY
# ============================================================

def generate_standby_watts(
    device: Dispositivo,
) -> float:
    """
    Genera consumo standby.

    IMPORTANTE:

    El standby únicamente representa el consumo vampiro
    mientras el dispositivo está conectado pero no está
    siendo utilizado.

    En esta etapa no lo mostramos cuando el relay está
    completamente desconectado.
    """

    if not device.conectado:
        return 0.0

    if not device.simulacion_activa:
        return 0.0

    if device.estado_on:
        return 0.0

    if not device.es_vampiro:
        return 0.0

    return round(
        max(
            0.0,
            device.watts_standby,
        ),
        2,
    )


# ============================================================
# GENERAR VOLTAJE
# ============================================================

def generate_voltage(
    device: Dispositivo,
) -> float:
    """
    Genera el voltaje simulado.

    Si el dispositivo está completamente desconectado,
    devuelve 0.

    Si está conectado y activo, utiliza el voltaje nominal.
    """

    if not device.conectado:
        return 0.0

    if not device.simulacion_activa:
        return 0.0

    if not device.estado_on:
        return 0.0

    return round(
        max(
            0.0,
            device.voltaje_nominal,
        ),
        2,
    )


# ============================================================
# GENERAR AMPERAJE
# ============================================================

def calculate_amps(
    watts: float,
    volts: float,
) -> float:
    """
    Calcula amperaje utilizando:

        I = P / V
    """

    if volts <= 0:
        return 0.0

    return round(
        watts / volts,
        4,
    )


# ============================================================
# GENERAR LECTURA COMPLETA
# ============================================================

def generate_reading(
    db: Session,
    device_id: str,
) -> dict | None:
    """
    Genera una lectura completa para un dispositivo.

    Esta función todavía NO guarda automáticamente
    la lectura en historial.

    Solamente genera los valores.

    Esto permite que telemetry_service.py sea el encargado
    de guardar la telemetría.
    """

    device = get_device(
        db,
        device_id,
    )

    if device is None:
        return None

    timestamp = datetime.now()

    # --------------------------------------------------------
    # DISPOSITIVO DESCONECTADO
    # --------------------------------------------------------

    if not device.conectado:
        return {
            "device_id": device.device_id,
            "watts": 0.0,
            "amps": 0.0,
            "volts": 0.0,
            "timestamp": timestamp,
        }

    # --------------------------------------------------------
    # SIMULACIÓN DESACTIVADA
    # --------------------------------------------------------

    if not device.simulacion_activa:
        return {
            "device_id": device.device_id,
            "watts": 0.0,
            "amps": 0.0,
            "volts": 0.0,
            "timestamp": timestamp,
        }

    # --------------------------------------------------------
    # RELAY APAGADO
    # --------------------------------------------------------

    if not device.estado_on:
        return {
            "device_id": device.device_id,
            "watts": 0.0,
            "amps": 0.0,
            "volts": 0.0,
            "timestamp": timestamp,
        }

    # --------------------------------------------------------
    # DISPOSITIVO ENCENDIDO
    # --------------------------------------------------------

    watts = generate_watts(
        device,
    )

    volts = generate_voltage(
        device,
    )

    amps = calculate_amps(
        watts,
        volts,
    )

    return {
        "device_id": device.device_id,
        "watts": watts,
        "amps": amps,
        "volts": volts,
        "timestamp": timestamp,
    }


# ============================================================
# GENERAR Y GUARDAR LECTURA
# ============================================================

def generate_and_save_reading(
    db: Session,
    device_id: str,
) -> Dispositivo | None:
    """
    Genera una lectura y la almacena mediante CRUD.

    Esta será una de las funciones principales que utilizará
    la ruta del simulador.
    """

    device = get_device(
        db,
        device_id,
    )

    if device is None:
        return None

    reading = generate_reading(
        db,
        device_id,
    )

    if reading is None:
        return None

    watts = reading["watts"]
    amps = reading["amps"]
    volts = reading["volts"]

    # --------------------------------------------------------
    # COSTO SIMULADO
    # --------------------------------------------------------

    costo_mxn = calculate_hourly_cost(
        device,
        watts,
    )

    crud.create_telemetry(
        db,
        device=device,
        watts=watts,
        amps=amps,
        volts=volts,
        costo_mxn=costo_mxn,
        timestamp=reading["timestamp"],
    )

    return device


# ============================================================
# CALCULAR COSTO
# ============================================================

def calculate_hourly_cost(
    device: Dispositivo,
    watts: float,
) -> float:
    """
    Calcula un costo aproximado por hora.

    El valor costo_mxn_hora se mantiene como tarifa
    configurada para el dispositivo.

    Para esta primera versión utilizamos la proporción
    del consumo actual respecto a su rango máximo.
    """

    if watts <= 0:
        return 0.0

    if device.watts_max <= 0:
        return 0.0

    ratio = watts / device.watts_max

    ratio = min(
        max(
            ratio,
            0.0,
        ),
        1.0,
    )

    return round(
        device.costo_mxn_hora * ratio,
        4,
    )


# ============================================================
# ESTADO DEL SIMULADOR
# ============================================================

def get_simulator_state(
    db: Session,
    device_id: str,
) -> Dispositivo | None:

    return get_device(
        db,
        device_id,
    )


# ============================================================
# DESACTIVAR TODOS LOS DISPOSITIVOS
# ============================================================

def stop_all_simulations(
    db: Session,
) -> None:
    """
    Detiene todas las simulaciones conectadas al stand.
    """

    crud.disconnect_all_devices(
        db,
    )