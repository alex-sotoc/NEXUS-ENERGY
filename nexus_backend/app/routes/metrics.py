from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Dispositivo, LecturaConsumo
from app.schemas import (
    HistoryItem,
    HistoryResponse,
    RealtimeMetricsResponse,
)


router = APIRouter(
    prefix="/api/metrics",
    tags=["Metrics"],
)


def resolve_device(
    db: Session,
    device_id: str,
) -> Dispositivo:
    """
    Busca un dispositivo usando:

    1. El identificador del ESP32/ESP8266:
       ESP32_RELAY_01

    2. El ID numérico de SQL Server:
       1
    """

    value = str(device_id).strip()

    if not value:
        raise ValueError(
            "El device_id no puede estar vacío."
        )

    if value.isdigit():
        device = db.get(
            Dispositivo,
            int(value),
        )
    else:
        device = db.scalar(
            select(Dispositivo).where(
                Dispositivo.mac_esp32 == value
            )
        )

    if device is None:
        raise ValueError(
            f"No existe un dispositivo con device_id '{value}'."
        )

    return device


def get_last_telemetry(
    db: Session,
    device_id: int,
) -> LecturaConsumo | None:
    """
    Obtiene la última lectura de un dispositivo
    utilizando el ID numérico de la base de datos.
    """

    return db.scalar(
        select(LecturaConsumo)
        .where(
            LecturaConsumo.dispositivo_id == device_id
        )
        .order_by(
            LecturaConsumo.id.desc()
        )
    )


@router.get(
    "/realtime/{device_id}",
    response_model=RealtimeMetricsResponse,
)
def get_realtime_metrics(
    device_id: str,
    db: Session = Depends(get_db),
):
    """
    Obtiene las métricas más recientes.

    Acepta:

        /api/metrics/realtime/ESP32_RELAY_01

    o:

        /api/metrics/realtime/1
    """

    try:
        device = resolve_device(
            db,
            device_id,
        )
    except ValueError as error:
        from fastapi import HTTPException

        raise HTTPException(
            status_code=404,
            detail=str(error),
        )

    last_telemetry = get_last_telemetry(
        db,
        device.id,
    )

    if last_telemetry is None:
        return RealtimeMetricsResponse(
            device_id=device.mac_esp32 or str(device.id),
            device_name=device.nombre,
            watts=float(
                device.watts_actuales or 0.0
            ),
            amps=0.0,
            volts=0.0,
            relay_state=bool(
                device.estado_on
            ),
            online=False,
            timestamp=None,
        )

    online = False

    if last_telemetry.fecha_hora is not None:
        online = (
            datetime.now()
            - last_telemetry.fecha_hora
        ) <= timedelta(seconds=10)

    return RealtimeMetricsResponse(
        device_id=device.mac_esp32 or str(device.id),
        device_name=device.nombre,
        watts=float(
            last_telemetry.watts or 0.0
        ),
        amps=float(
            last_telemetry.amps or 0.0
        ),
        volts=float(
            last_telemetry.volts or 0.0
        ),
        relay_state=bool(
            device.estado_on
        ),
        online=online,
        timestamp=last_telemetry.fecha_hora,
    )


@router.get(
    "/history/{device_id}",
    response_model=HistoryResponse,
)
def get_history(
    device_id: str,
    hours: int = Query(
        default=24,
        ge=1,
        le=168,
    ),
    limit: int = Query(
        default=100,
        ge=1,
        le=1000,
    ),
    db: Session = Depends(get_db),
):
    """
    Obtiene el historial de consumo.

    Acepta tanto:

        ESP32_RELAY_01

    como:

        1
    """

    try:
        device = resolve_device(
            db,
            device_id,
        )
    except ValueError as error:
        from fastapi import HTTPException

        raise HTTPException(
            status_code=404,
            detail=str(error),
        )

    since = (
        datetime.now()
        - timedelta(hours=hours)
    )

    readings = db.scalars(
        select(LecturaConsumo)
        .where(
            LecturaConsumo.dispositivo_id == device.id,
            LecturaConsumo.fecha_hora >= since,
        )
        .order_by(
            LecturaConsumo.id.desc()
        )
        .limit(limit)
    ).all()

    readings = list(
        reversed(readings)
    )

    result = [
        HistoryItem(
            id=reading.id,
            watts=float(
                reading.watts or 0.0
            ),
            amps=float(
                reading.amps or 0.0
            ),
            volts=float(
                reading.volts or 0.0
            ),
            costo_mxn=float(
                reading.costo_mxn or 0.0
            ),
            timestamp=reading.fecha_hora,
        )
        for reading in readings
        if reading.fecha_hora is not None
    ]

    return HistoryResponse(
        device_id=device.mac_esp32 or str(device.id),
        device_name=device.nombre,
        readings=result,
    )