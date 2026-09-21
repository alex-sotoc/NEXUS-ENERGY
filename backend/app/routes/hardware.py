import os

import httpx

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Dispositivo
from app.schemas import (
    HardwareStatusResponse,
    HardwareToggleRequest,
    HardwareToggleResponse,
)


router = APIRouter(
    prefix="/api/hardware",
    tags=["Hardware"],
)


# ============================================================
# CONFIGURACIÓN
# ============================================================

ESP32_TIMEOUT = float(
    os.getenv(
        "ESP32_TIMEOUT",
        "3.0",
    )
)

DEFAULT_ESP32_URL = os.getenv(
    "ESP32_URL",
    "",
)


# ============================================================
# HELPERS
# ============================================================

def _find_device(
    db: Session,
    device_id: str,
) -> Dispositivo | None:

    return (
        db.query(Dispositivo)
        .filter(
            Dispositivo.device_id
            == device_id
        )
        .first()
    )


def _get_esp32_url(
    device: Dispositivo,
) -> str | None:
    """
    Obtiene la dirección del ESP32.

    Prioridad:

    1. ESP32_URL del entorno.
    2. mac_esp32 si contiene una URL.

    Ejemplo:

    ESP32_URL=http://192.168.1.150
    """

    if DEFAULT_ESP32_URL:
        return DEFAULT_ESP32_URL.rstrip("/")

    if device.mac_esp32:
        value = str(
            device.mac_esp32
        ).strip()

        if value.startswith(
            "http://"
        ) or value.startswith(
            "https://"
        ):
            return value.rstrip("/")

    return None


# ============================================================
# STATUS
# ============================================================

@router.get(
    "/status/{device_id}",
    response_model=HardwareStatusResponse,
)
async def get_hardware_status(
    device_id: str,
    db: Session = Depends(get_db),
):
    device = _find_device(
        db=db,
        device_id=device_id,
    )

    if device is None:
        raise HTTPException(
            status_code=404,
            detail=f"Dispositivo '{device_id}' no encontrado.",
        )

    esp32_url = _get_esp32_url(device)

    # --------------------------------------------------------
    # Si no existe URL del ESP32, usamos el estado guardado
    # en la base de datos.
    # --------------------------------------------------------

    if not esp32_url:
        return HardwareStatusResponse(
            device_id=device.device_id,
            device_database_id=device.id,
            device_name=device.nombre,

            relay_state=bool(
                device.estado_on
            ),

            online=False,

            last_telemetry_at=(
                device.ultima_comunicacion
            ),
        )

    # --------------------------------------------------------
    # Consultar ESP32
    # --------------------------------------------------------

    try:
        async with httpx.AsyncClient(
            timeout=ESP32_TIMEOUT
        ) as client:

            response = await client.get(
                f"{esp32_url}/status"
            )

        if response.status_code != 200:
            raise RuntimeError(
                f"ESP32 respondió HTTP "
                f"{response.status_code}"
            )

        data = response.json()

        relay_state = bool(
            data.get(
                "relay",
                data.get(
                    "relayState",
                    data.get(
                        "state",
                        device.estado_on,
                    ),
                ),
            )
        )

        # Sincronizamos el estado del hardware
        # con SQL Server.
        device.estado_on = relay_state

        db.commit()

        return HardwareStatusResponse(
            device_id=device.device_id,
            device_database_id=device.id,
            device_name=device.nombre,

            relay_state=relay_state,

            online=True,

            last_telemetry_at=(
                device.ultima_comunicacion
            ),
        )

    except Exception:
        # ----------------------------------------------------
        # Si el ESP32 no responde, NO inventamos que está online.
        # ----------------------------------------------------

        return HardwareStatusResponse(
            device_id=device.device_id,
            device_database_id=device.id,
            device_name=device.nombre,

            relay_state=bool(
                device.estado_on
            ),

            online=False,

            last_telemetry_at=(
                device.ultima_comunicacion
            ),
        )


# ============================================================
# TOGGLE / CONTROL DEL RELAY
# ============================================================

@router.post(
    "/toggle",
    response_model=HardwareToggleResponse,
)
async def toggle_hardware(
    request: HardwareToggleRequest,
    db: Session = Depends(get_db),
):
    """
    Controla el relay físico.

    Flujo:

    Flutter principal
          ↓
    FastAPI
          ↓
    ESP32
          ↓
    Relay físico

    Y posteriormente el estado queda guardado
    en SQL Server.
    """

    device = _find_device(
        db=db,
        device_id=request.device_id,
    )

    if device is None:
        raise HTTPException(
            status_code=404,
            detail=f"Dispositivo '{request.device_id}' no encontrado.",
        )

    desired_state = bool(
        request.relay_state
    )

    esp32_url = _get_esp32_url(
        device
    )

    # --------------------------------------------------------
    # SIN ESP32 CONFIGURADO
    # --------------------------------------------------------

    if not esp32_url:
        device.estado_on = desired_state

        if not desired_state:
            device.watts_actuales = 0.0
            device.amps_actuales = 0.0
            device.volts_actuales = 0.0

        db.commit()

        return HardwareToggleResponse(
            message=(
                "Relay actualizado en la base de datos. "
                "No hay ESP32 configurado."
            ),

            device_id=device.device_id,
            device_database_id=device.id,

            relay_state=desired_state,
        )

    # --------------------------------------------------------
    # CONTROL REAL DEL ESP32
    # --------------------------------------------------------

    try:
        endpoint = (
            "on"
            if desired_state
            else "off"
        )

        response = None

        async with httpx.AsyncClient(
            timeout=ESP32_TIMEOUT
        ) as client:

            # Primero intentamos el endpoint
            # /control?state=on/off que ya existe
            # en tu ESP32.
            response = await client.get(
                f"{esp32_url}/control",
                params={
                    "state": endpoint,
                },
            )

            # ------------------------------------------------
            # Compatibilidad adicional
            # ------------------------------------------------

            if response.status_code != 200:

                fallback_path = (
                    "/relay/on"
                    if desired_state
                    else "/relay/off"
                )

                response = await client.get(
                    f"{esp32_url}{fallback_path}"
                )

        if response.status_code != 200:
            raise HTTPException(
                status_code=502,
                detail=(
                    "El ESP32 rechazó la orden "
                    f"de relay. HTTP {response.status_code}."
                ),
            )

        # ----------------------------------------------------
        # Actualizar DB después de enviar la orden
        # ----------------------------------------------------

        device.estado_on = desired_state

        if not desired_state:
            device.watts_actuales = 0.0
            device.amps_actuales = 0.0
            device.volts_actuales = 0.0

        db.commit()

        return HardwareToggleResponse(
            message=(
                "Relay físico actualizado correctamente."
            ),

            device_id=device.device_id,
            device_database_id=device.id,

            relay_state=desired_state,
        )

    except HTTPException:
        raise

    except httpx.RequestError as exc:

        raise HTTPException(
            status_code=502,
            detail=(
                "No fue posible comunicarse con el ESP32: "
                f"{exc}"
            ),
        )

    except Exception as exc:

        raise HTTPException(
            status_code=500,
            detail=(
                "Error al controlar el relay: "
                f"{exc}"
            ),
        )