from datetime import datetime

from sqlalchemy.orm import Session

from app import crud
from app.models import Dispositivo, LecturaConsumo


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
# VALIDAR TELEMETRÍA
# ============================================================

def validate_telemetry(
    watts: float,
    amps: float,
    volts: float,
) -> bool:
    """
    Valida que los valores de telemetría sean válidos.
    """

    if watts < 0:
        return False

    if amps < 0:
        return False

    if volts < 0:
        return False

    return True


# ============================================================
# GUARDAR TELEMETRÍA
# ============================================================

def save_telemetry(
    db: Session,
    *,
    device_id: str,
    watts: float,
    amps: float,
    volts: float,
    costo_mxn: float = 0.0,
    timestamp: datetime | None = None,
) -> LecturaConsumo | None:
    """
    Guarda una lectura de telemetría.

    IMPORTANTE:

    Aunque el simulador mande valores, el backend vuelve
    a validar el estado del dispositivo.

    Si está desconectado o el relay está apagado,
    los valores se fuerzan a cero.
    """

    if not validate_telemetry(
        watts,
        amps,
        volts,
    ):
        raise ValueError(
            "Los valores de telemetría no pueden ser negativos."
        )

    device = get_device(
        db,
        device_id,
    )

    if device is None:
        return None

    # --------------------------------------------------------
    # VALIDAR ESTADO REAL DEL DISPOSITIVO
    # --------------------------------------------------------

    if not device.conectado:
        watts = 0.0
        amps = 0.0
        volts = 0.0

    elif not device.simulacion_activa:
        watts = 0.0
        amps = 0.0
        volts = 0.0

    elif not device.estado_on:
        watts = 0.0
        amps = 0.0
        volts = 0.0

    # --------------------------------------------------------
    # GUARDAR
    # --------------------------------------------------------

    reading = crud.create_telemetry(
        db,
        device=device,
        watts=watts,
        amps=amps,
        volts=volts,
        costo_mxn=max(
            0.0,
            costo_mxn,
        ),
        timestamp=timestamp,
    )

    return reading


# ============================================================
# ÚLTIMA TELEMETRÍA
# ============================================================

def get_last_reading(
    db: Session,
    device_id: str,
) -> LecturaConsumo | None:

    device = get_device(
        db,
        device_id,
    )

    if device is None:
        return None

    return crud.get_last_telemetry(
        db,
        device,
    )


# ============================================================
# HISTORIAL
# ============================================================

def get_history(
    db: Session,
    device_id: str,
    *,
    hours: int = 24,
    limit: int = 100,
) -> list[LecturaConsumo]:

    device = get_device(
        db,
        device_id,
    )

    if device is None:
        return []

    return crud.get_history(
        db,
        device,
        hours=hours,
        limit=limit,
    )


# ============================================================
# OBTENER MÉTRICAS ACTUALES
# ============================================================

def get_current_metrics(
    db: Session,
    device_id: str,
) -> dict | None:

    device = get_device(
        db,
        device_id,
    )

    if device is None:
        return None

    # --------------------------------------------------------
    # DISPOSITIVO APAGADO O DESCONECTADO
    # --------------------------------------------------------

    if (
        not device.conectado
        or not device.simulacion_activa
        or not device.estado_on
    ):
        return {
            "device_id": device.device_id,
            "device_name": device.nombre,
            "watts": 0.0,
            "amps": 0.0,
            "volts": 0.0,
            "relay_state": device.estado_on,
            "connected": device.conectado,
            "simulation_active": device.simulacion_activa,
            "online": False,
            "timestamp": device.ultima_comunicacion,
        }

    # --------------------------------------------------------
    # DISPOSITIVO ACTIVO
    # --------------------------------------------------------

    return {
        "device_id": device.device_id,
        "device_name": device.nombre,
        "watts": device.watts_actuales,
        "amps": device.amps_actuales,
        "volts": device.volts_actuales,
        "relay_state": device.estado_on,
        "connected": device.conectado,
        "simulation_active": device.simulacion_activa,
        "online": True,
        "timestamp": device.ultima_comunicacion,
    }


# ============================================================
# PONER TELEMETRÍA EN CERO
# ============================================================

def zero_telemetry(
    db: Session,
    device_id: str,
) -> Dispositivo | None:

    device = get_device(
        db,
        device_id,
    )

    if device is None:
        return None

    device.watts_actuales = 0.0
    device.amps_actuales = 0.0
    device.volts_actuales = 0.0

    device.ultima_comunicacion = None

    db.commit()
    db.refresh(device)

    return device


# ============================================================
# REINICIAR TELEMETRÍA DE UN DISPOSITIVO
# ============================================================

def reset_device_telemetry(
    db: Session,
    device_id: str,
) -> Dispositivo | None:

    return zero_telemetry(
        db,
        device_id,
    )