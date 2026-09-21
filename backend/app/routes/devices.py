from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Dispositivo
from app.schemas import (
    DeviceCreateRequest,
    DeviceResponse,
    DeviceStateResponse,
)


router = APIRouter(
    prefix="/api/devices",
    tags=["Devices"],
)


# ============================================================
# HELPERS
# ============================================================

def _utc_now() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _safe_float(value) -> float:
    if value is None:
        return 0.0

    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


def _safe_bool(value) -> bool:
    return bool(value)


def _device_to_response(
    device: Dispositivo,
) -> DeviceResponse:
    """
    Convierte un modelo Dispositivo de SQLAlchemy
    en el esquema DeviceResponse utilizado por FastAPI.
    """

    return DeviceResponse(
        id=device.id,
        device_id=device.device_id,
        nombre=device.nombre,
        ubicacion=device.ubicacion,

        estado_on=_safe_bool(
            device.estado_on
        ),

        conectado=_safe_bool(
            device.conectado
        ),

        simulacion_activa=_safe_bool(
            device.simulacion_activa
        ),

        watts_actuales=_safe_float(
            device.watts_actuales
        ),

        amps_actuales=_safe_float(
            device.amps_actuales
        ),

        volts_actuales=_safe_float(
            device.volts_actuales
        ),

        costo_mxn_hora=_safe_float(
            device.costo_mxn_hora
        ),

        es_vampiro=_safe_bool(
            device.es_vampiro
        ),

        watts_standby=_safe_float(
            device.watts_standby
        ),

        watts_min=_safe_float(
            device.watts_min
        ),

        watts_max=_safe_float(
            device.watts_max
        ),

        voltaje_nominal=_safe_float(
            device.voltaje_nominal
        ),

        mac_esp32=device.mac_esp32,

        ultima_comunicacion=device.ultima_comunicacion,
        creado_en=device.creado_en,
    )


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


# ============================================================
# LISTAR TODOS LOS DISPOSITIVOS
# ============================================================

@router.get(
    "",
    response_model=list[DeviceResponse],
)
def get_devices(
    db: Session = Depends(get_db),
):
    """
    Devuelve todos los dispositivos registrados.
    """

    try:

        devices = (
            db.query(Dispositivo)
            .order_by(
                Dispositivo.id.asc()
            )
            .all()
        )

        return [
            _device_to_response(device)
            for device in devices
        ]

    except Exception as e:

        db.rollback()

        raise HTTPException(
            status_code=400,
            detail=str(e),
        )


# ============================================================
# OBTENER DISPOSITIVO ACTIVO
# ============================================================

@router.get(
    "/active",
    response_model=DeviceResponse,
)
def get_active_device(
    db: Session = Depends(get_db),
):
    """
    Devuelve el dispositivo actualmente conectado
    al simulador.

    IMPORTANTE:

    En SQL Server NO debemos usar:

        Dispositivo.conectado.is_(True)

    porque SQLAlchemy genera:

        WHERE dispositivos.conectado IS 1

    y SQL Server devuelve error.

    Por eso utilizamos:

        Dispositivo.conectado == True

    lo cual genera una comparación compatible.
    """

    try:

        device = (
            db.query(Dispositivo)

            # --------------------------------------------
            # CORRECCIÓN PARA SQL SERVER
            # --------------------------------------------
            .filter(
                Dispositivo.conectado == True
            )

            .order_by(
                Dispositivo.ultima_comunicacion.desc(),
                Dispositivo.id.desc(),
            )

            .first()
        )

        if device is None:
            raise HTTPException(
                status_code=404,
                detail=(
                    "No hay ningún dispositivo "
                    "conectado actualmente."
                ),
            )

        return _device_to_response(
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
# OBTENER UN DISPOSITIVO POR DEVICE_ID
# ============================================================

@router.get(
    "/{device_id}",
    response_model=DeviceResponse,
)
def get_device(
    device_id: str,
    db: Session = Depends(get_db),
):
    """
    Obtiene un dispositivo específico utilizando
    su device_id.
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
                    f"Dispositivo '{device_id}' "
                    "no encontrado."
                ),
            )

        return _device_to_response(
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
# ESTADO RESUMIDO DEL DISPOSITIVO
# ============================================================

@router.get(
    "/{device_id}/state",
    response_model=DeviceStateResponse,
)
def get_device_state(
    device_id: str,
    db: Session = Depends(get_db),
):
    """
    Devuelve únicamente el estado operativo
    del dispositivo.
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
                    f"Dispositivo '{device_id}' "
                    "no encontrado."
                ),
            )

        return DeviceStateResponse(
            device_id=device.device_id,

            conectado=_safe_bool(
                device.conectado
            ),

            estado_on=_safe_bool(
                device.estado_on
            ),

            simulacion_activa=_safe_bool(
                device.simulacion_activa
            ),

            watts_actuales=_safe_float(
                device.watts_actuales
            ),

            amps_actuales=_safe_float(
                device.amps_actuales
            ),

            volts_actuales=_safe_float(
                device.volts_actuales
            ),

            ultima_comunicacion=(
                device.ultima_comunicacion
            ),
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
# CREAR DISPOSITIVO MANUALMENTE
# ============================================================

@router.post(
    "",
    response_model=DeviceResponse,
    status_code=201,
)
def create_device(
    request: DeviceCreateRequest,
    db: Session = Depends(get_db),
):
    """
    Crea manualmente un dispositivo.

    El simulador también puede crear dispositivos
    automáticamente mediante:

        POST /api/simulator/connect
    """

    try:

        # ----------------------------------------------------
        # 1. COMPROBAR SI YA EXISTE
        # ----------------------------------------------------

        existing = _find_device(
            db=db,
            device_id=request.device_id,
        )

        if existing is not None:
            raise HTTPException(
                status_code=409,
                detail=(
                    f"El dispositivo "
                    f"'{request.device_id}' "
                    "ya existe."
                ),
            )

        # ----------------------------------------------------
        # 2. CREAR MODELO
        # ----------------------------------------------------

        device = Dispositivo(
            device_id=request.device_id,
            nombre=request.nombre,
            ubicacion=request.ubicacion,

            estado_on=False,
            conectado=False,
            simulacion_activa=False,

            watts_actuales=0.0,
            amps_actuales=0.0,
            volts_actuales=0.0,

            costo_mxn_hora=(
                request.costo_mxn_hora
            ),

            es_vampiro=(
                request.es_vampiro
            ),

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

            mac_esp32=request.mac_esp32,

            ultima_comunicacion=None,

            creado_en=_utc_now(),
        )

        # ----------------------------------------------------
        # 3. AGREGAR Y GUARDAR
        # ----------------------------------------------------

        db.add(device)

        db.commit()

        db.refresh(device)

        # ----------------------------------------------------
        # 4. RESPONDER
        # ----------------------------------------------------

        return _device_to_response(
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