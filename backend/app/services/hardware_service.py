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
    """
    Obtiene un dispositivo utilizando su device_id lógico.

    Ejemplo:
        SIM_CARGADOR_5V_1A
        SIM_CARGADOR_33W
        SIM_VENTILADOR_PEQUENO
    """

    return crud.get_device_by_device_id(
        db,
        device_id,
    )


# ============================================================
# OBTENER ESTADO DEL HARDWARE
# ============================================================

def get_hardware_status(
    db: Session,
    device_id: str,
) -> Dispositivo | None:
    """
    Devuelve el dispositivo y su estado actual.

    El relay es controlado por estado_on.
    """

    return get_device(
        db,
        device_id,
    )


# ============================================================
# CAMBIAR ESTADO DEL RELAY
# ============================================================

def set_relay_state(
    db: Session,
    device_id: str,
    relay_state: bool,
) -> Dispositivo | None:
    """
    Cambia el estado del relay.

    True:
        Relay encendido.

    False:
        Relay apagado.

    Cuando el relay se apaga:
        watts = 0
        amps = 0

    El voltaje se mantiene según la lógica definida
    actualmente en crud.update_device_relay().
    """

    device = get_device(
        db,
        device_id,
    )

    if device is None:
        return None

    device = crud.update_device_relay(
        db,
        device,
        relay_state,
    )

    return device


# ============================================================
# ENCENDER RELAY
# ============================================================

def turn_on(
    db: Session,
    device_id: str,
) -> Dispositivo | None:
    """
    Enciende el relay del dispositivo.
    """

    return set_relay_state(
        db,
        device_id,
        True,
    )


# ============================================================
# APAGAR RELAY
# ============================================================

def turn_off(
    db: Session,
    device_id: str,
) -> Dispositivo | None:
    """
    Apaga el relay del dispositivo.

    El consumo queda en cero.
    """

    return set_relay_state(
        db,
        device_id,
        False,
    )


# ============================================================
# VALIDAR SI EL RELAY ESTÁ ENCENDIDO
# ============================================================

def is_relay_on(
    db: Session,
    device_id: str,
) -> bool | None:
    """
    Devuelve:

        True  -> relay encendido
        False -> relay apagado
        None  -> dispositivo inexistente
    """

    device = get_device(
        db,
        device_id,
    )

    if device is None:
        return None

    return device.estado_on


# ============================================================
# SINCRONIZAR CON HARDWARE FÍSICO
# ============================================================

def register_hardware(
    db: Session,
    device_id: str,
    mac_esp32: str,
) -> Dispositivo | None:
    """
    Asocia un ESP32/ESP8266 físico con un dispositivo lógico.

    Esta función no enciende el relay.

    Solamente registra qué hardware físico corresponde
    al dispositivo.
    """

    device = get_device(
        db,
        device_id,
    )

    if device is None:
        return None

    device.mac_esp32 = mac_esp32
    device.ultima_comunicacion = datetime.now()

    db.commit()
    db.refresh(device)

    return device


# ============================================================
# ACTUALIZAR COMUNICACIÓN DEL HARDWARE
# ============================================================

def update_hardware_heartbeat(
    db: Session,
    device_id: str,
) -> Dispositivo | None:
    """
    Actualiza la última comunicación del ESP32/ESP8266.
    """

    device = get_device(
        db,
        device_id,
    )

    if device is None:
        return None

    device.ultima_comunicacion = datetime.now()

    db.commit()
    db.refresh(device)

    return device


# ============================================================
# OBTENER HARDWARE POR MAC
# ============================================================

def get_device_by_mac(
    db: Session,
    mac_esp32: str,
) -> Dispositivo | None:
    """
    Busca un dispositivo asociado a un ESP32/ESP8266.
    """

    return crud.get_device_by_mac(
        db,
        mac_esp32,
    )