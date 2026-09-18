from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Dispositivo, LecturaConsumo
from app.schemas import (
    HardwareStatusResponse,
    HardwareToggleRequest,
    HardwareToggleResponse,
    TelemetryRequest,
    TelemetryResponse,
)


router = APIRouter(
    prefix="/api",
    tags=["Hardware"],
)


def resolve_device(
    db: Session,
    device_id: str,
) -> Dispositivo:
    """
    Resuelve un dispositivo mediante:

    ESP32_RELAY_01

    o mediante:

    1
    """

    value = str(device_id).strip()

    if not value:
        raise HTTPException(
            status_code=400,
            detail="El device_id no puede estar vacío.",
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
        raise HTTPException(
            status_code=404,
            detail=(
                f"No existe un dispositivo con "
                f"device_id '{value}'."
            ),
        )

    return device


@router.post(
    "/telemetry",
    response_model=TelemetryResponse,
)
def receive_telemetry(
    data: TelemetryRequest,
    db: Session = Depends(get_db),
):
    """
    Recibe la telemetría enviada por el ESP8266.

    Ejemplo recibido:

    {
        "device_id": "ESP32_RELAY_01",
        "watts": 100,
        "amps": 0.79,
        "volts": 127
    }

    Busca el dispositivo mediante mac_esp32,
    obtiene su ID numérico y guarda la lectura.
    """

    device = db.scalar(
        select(Dispositivo).where(
            Dispositivo.mac_esp32 == data.device_id
        )
    )

    if device is None:
        raise HTTPException(
            status_code=404,
            detail=(
                "No existe un dispositivo registrado "
                f"con mac_esp32='{data.device_id}'."
            ),
        )

    now = datetime.now()

    if data.costo_mxn is not None:
        costo_mxn = data.costo_mxn
    else:
        costo_mxn = (
            data.watts / 1000.0
        ) * (
            device.costo_mxn_hora or 0.0
        )

    lectura = LecturaConsumo(
        dispositivo_id=device.id,
        watts=data.watts,
        costo_mxn=costo_mxn,
        fecha_hora=now,
        amps=data.amps,
        volts=data.volts,
    )

    device.watts_actuales = data.watts

    db.add(lectura)
    db.commit()
    db.refresh(lectura)

    return TelemetryResponse(
        message="Telemetría registrada correctamente.",
        device_id=data.device_id,
        device_database_id=device.id,
        watts=data.watts,
        amps=data.amps,
        volts=data.volts,
    )


@router.get(
    "/hardware/status/{device_id}",
    response_model=HardwareStatusResponse,
)
def get_hardware_status(
    device_id: str,
    db: Session = Depends(get_db),
):
    """
    Obtiene el estado del hardware.

    Acepta:

        ESP32_RELAY_01

    o:

        1
    """

    device = resolve_device(
        db,
        device_id,
    )

    last_telemetry = db.scalar(
        select(LecturaConsumo)
        .where(
            LecturaConsumo.dispositivo_id == device.id
        )
        .order_by(
            LecturaConsumo.id.desc()
        )
    )

    online = False

    if last_telemetry is not None:
        if last_telemetry.fecha_hora is not None:
            online = (
                datetime.now()
                - last_telemetry.fecha_hora
            ) <= timedelta(seconds=10)

    return HardwareStatusResponse(
        device_id=(
            device.mac_esp32
            or str(device.id)
        ),
        device_database_id=device.id,
        device_name=device.nombre,
        relay_state=bool(
            device.estado_on
        ),
        online=online,
        last_telemetry_at=(
            last_telemetry.fecha_hora
            if last_telemetry is not None
            else None
        ),
    )


@router.post(
    "/hardware/toggle",
    response_model=HardwareToggleResponse,
)
def toggle_hardware(
    data: HardwareToggleRequest,
    db: Session = Depends(get_db),
):
    """
    Cambia el estado del dispositivo.

    Acepta:

        ESP32_RELAY_01

    o:

        1
    """

    device = resolve_device(
        db,
        data.device_id,
    )

    device.estado_on = data.relay_state

    db.commit()
    db.refresh(device)

    return HardwareToggleResponse(
        message="Estado del dispositivo actualizado.",
        device_id=(
            device.mac_esp32
            or str(device.id)
        ),
        device_database_id=device.id,
        relay_state=bool(
            device.estado_on
        ),
    )