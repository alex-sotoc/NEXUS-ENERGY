from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Dispositivo
from app.schemas import DeviceDetailResponse, DeviceResponse
from app.routes.metrics import get_last_telemetry


router = APIRouter(
    prefix="/api/devices",
    tags=["Devices"],
)


# ============================================================
# CONFIGURACION DE CONEXION DEL HARDWARE
# ============================================================

ONLINE_TIMEOUT_SECONDS = 10


# ============================================================
# GET /api/devices
# ============================================================

@router.get(
    "",
    response_model=list[DeviceResponse],
)
def get_devices(
    db: Session = Depends(get_db),
):
    dispositivos = db.scalars(
        select(Dispositivo).order_by(Dispositivo.id)
    ).all()

    devices = []

    for dispositivo in dispositivos:
        devices.append(
            DeviceResponse(
                id=dispositivo.id,
                device_id=dispositivo.mac_esp32 or "",
                nombre=dispositivo.nombre,
                ubicacion=dispositivo.ubicacion,
                estado_on=bool(dispositivo.estado_on),
                watts_actuales=float(dispositivo.watts_actuales or 0.0),
                costo_mxn_hora=float(dispositivo.costo_mxn_hora or 0.0),
                es_vampiro=bool(dispositivo.es_vampiro),
                creado_en=dispositivo.creado_en,
            )
        )

    return devices


# ============================================================
# GET /api/devices/{device_id}
# ============================================================

@router.get(
    "/{device_id}",
    response_model=DeviceDetailResponse,
)
def get_device(
    device_id: str,
    db: Session = Depends(get_db),
):
    dispositivo = db.scalar(
        select(Dispositivo).where(
            Dispositivo.mac_esp32 == device_id
        )
    )

    if dispositivo is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                f"No existe un dispositivo registrado con "
                f"device_id '{device_id}'."
            ),
        )

    last_telemetry = get_last_telemetry(
        db=db,
        dispositivo_id=dispositivo.id,
    )

    online = False

    if last_telemetry is not None:
        from datetime import datetime

        elapsed_seconds = (
            datetime.now() - last_telemetry.fecha_hora
        ).total_seconds()

        online = elapsed_seconds <= ONLINE_TIMEOUT_SECONDS

    return DeviceDetailResponse(
        id=dispositivo.id,
        device_id=dispositivo.mac_esp32 or "",
        nombre=dispositivo.nombre,
        ubicacion=dispositivo.ubicacion,
        estado_on=bool(dispositivo.estado_on),
        watts_actuales=float(dispositivo.watts_actuales or 0.0),
        costo_mxn_hora=float(dispositivo.costo_mxn_hora or 0.0),
        es_vampiro=bool(dispositivo.es_vampiro),
        creado_en=dispositivo.creado_en,
        last_telemetry_at=(
            last_telemetry.fecha_hora
            if last_telemetry is not None
            else None
        ),
        online=online,
    )