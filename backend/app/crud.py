from datetime import datetime, timedelta

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app.models import Dispositivo, LecturaConsumo, Usuario


# ============================================================
# USUARIOS
# ============================================================

def get_user_by_email(
    db: Session,
    email: str,
) -> Usuario | None:

    statement = select(Usuario).where(
        Usuario.email == email
    )

    return db.scalar(statement)


def get_user_by_id(
    db: Session,
    user_id: int,
) -> Usuario | None:

    statement = select(Usuario).where(
        Usuario.id == user_id
    )

    return db.scalar(statement)


def create_user(
    db: Session,
    nombre: str,
    email: str,
    password_hash: str,
) -> Usuario:

    user = Usuario(
        nombre=nombre,
        email=email,
        password_hash=password_hash,
        creado_en=datetime.now(),
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    return user


# ============================================================
# DISPOSITIVOS
# ============================================================

def get_devices(
    db: Session,
) -> list[Dispositivo]:

    statement = select(Dispositivo).order_by(
        Dispositivo.id
    )

    return list(db.scalars(statement).all())


def get_device_by_id(
    db: Session,
    device_database_id: int,
) -> Dispositivo | None:

    statement = select(Dispositivo).where(
        Dispositivo.id == device_database_id
    )

    return db.scalar(statement)


def get_device_by_device_id(
    db: Session,
    device_id: str,
) -> Dispositivo | None:

    statement = select(Dispositivo).where(
        Dispositivo.device_id == device_id
    )

    return db.scalar(statement)


def get_device_by_mac(
    db: Session,
    mac_esp32: str,
) -> Dispositivo | None:

    statement = select(Dispositivo).where(
        Dispositivo.mac_esp32 == mac_esp32
    )

    return db.scalar(statement)


def create_device(
    db: Session,
    *,
    nombre: str,
    ubicacion: str | None,
    device_id: str,
    costo_mxn_hora: float,
    es_vampiro: bool,
    watts_standby: float,
    watts_min: float,
    watts_max: float,
    voltaje_nominal: float,
    mac_esp32: str | None = None,
) -> Dispositivo:

    now = datetime.now()

    device = Dispositivo(
        nombre=nombre,
        ubicacion=ubicacion,

        estado_on=False,
        conectado=False,
        simulacion_activa=False,

        watts_actuales=0.0,
        amps_actuales=0.0,
        volts_actuales=0.0,

        costo_mxn_hora=costo_mxn_hora,

        es_vampiro=es_vampiro,

        watts_standby=watts_standby,
        watts_min=watts_min,
        watts_max=watts_max,
        voltaje_nominal=voltaje_nominal,

        device_id=device_id,
        mac_esp32=mac_esp32,

        ultima_comunicacion=None,
        creado_en=now,
    )

    db.add(device)
    db.commit()
    db.refresh(device)

    return device


# ============================================================
# ESTADO DEL DISPOSITIVO
# ============================================================

def update_device_relay(
    db: Session,
    device: Dispositivo,
    relay_state: bool,
) -> Dispositivo:

    device.estado_on = relay_state

    # Si el relay se apaga, el consumo físico/simulado
    # debe detenerse.
    if not relay_state:
        device.watts_actuales = 0.0
        device.amps_actuales = 0.0

        # Conservamos el voltaje nominal para tener
        # referencia del dispositivo.
        #
        # La lógica final de telemetría podrá decidir
        # posteriormente si el voltaje mostrado debe ser
        # nominal o 0 cuando el relay esté apagado.
        device.volts_actuales = device.voltaje_nominal

    db.commit()
    db.refresh(device)

    return device


def connect_device(
    db: Session,
    device: Dispositivo,
) -> Dispositivo:

    device.conectado = True
    device.simulacion_activa = True

    # La conexión no enciende automáticamente el relay.
    # El relay se controla por separado.
    device.estado_on = False

    device.watts_actuales = 0.0
    device.amps_actuales = 0.0
    device.volts_actuales = 0.0

    device.ultima_comunicacion = datetime.now()

    db.commit()
    db.refresh(device)

    return device


def disconnect_device(
    db: Session,
    device: Dispositivo,
) -> Dispositivo:

    device.conectado = False
    device.simulacion_activa = False
    device.estado_on = False

    device.watts_actuales = 0.0
    device.amps_actuales = 0.0
    device.volts_actuales = 0.0

    device.ultima_comunicacion = None

    db.commit()
    db.refresh(device)

    return device


# ============================================================
# TELEMETRÍA
# ============================================================

def create_telemetry(
    db: Session,
    *,
    device: Dispositivo,
    watts: float,
    amps: float,
    volts: float,
    costo_mxn: float,
    timestamp: datetime | None = None,
) -> LecturaConsumo:

    now = timestamp or datetime.now()

    reading = LecturaConsumo(
        dispositivo_id=device.id,
        watts=watts,
        amps=amps,
        volts=volts,
        costo_mxn=costo_mxn,
        fecha_hora=now,
    )

    db.add(reading)

    device.watts_actuales = watts
    device.amps_actuales = amps
    device.volts_actuales = volts
    device.ultima_comunicacion = now

    db.commit()
    db.refresh(reading)

    return reading


def get_last_telemetry(
    db: Session,
    device: Dispositivo,
) -> LecturaConsumo | None:

    statement = (
        select(LecturaConsumo)
        .where(
            LecturaConsumo.dispositivo_id == device.id
        )
        .order_by(
            desc(LecturaConsumo.fecha_hora)
        )
        .limit(1)
    )

    return db.scalar(statement)


def get_history(
    db: Session,
    device: Dispositivo,
    *,
    hours: int = 24,
    limit: int = 100,
) -> list[LecturaConsumo]:

    since = datetime.now() - timedelta(
        hours=hours
    )

    statement = (
        select(LecturaConsumo)
        .where(
            LecturaConsumo.dispositivo_id == device.id,
            LecturaConsumo.fecha_hora >= since,
        )
        .order_by(
            desc(LecturaConsumo.fecha_hora)
        )
        .limit(limit)
    )

    return list(
        db.scalars(statement).all()
    )


# ============================================================
# ESTADO DEL STAND
# ============================================================

def get_connected_devices(
    db: Session,
) -> list[Dispositivo]:

    statement = (
        select(Dispositivo)
        .where(
            Dispositivo.conectado.is_(True)
        )
        .order_by(
            Dispositivo.id
        )
    )

    return list(
        db.scalars(statement).all()
    )


def get_connected_device(
    db: Session,
) -> Dispositivo | None:

    statement = (
        select(Dispositivo)
        .where(
            Dispositivo.conectado.is_(True)
        )
        .order_by(
            Dispositivo.id
        )
        .limit(1)
    )

    return db.scalar(statement)


def disconnect_all_devices(
    db: Session,
) -> None:

    devices = get_connected_devices(db)

    for device in devices:
        device.conectado = False
        device.simulacion_activa = False
        device.estado_on = False

        device.watts_actuales = 0.0
        device.amps_actuales = 0.0
        device.volts_actuales = 0.0

        device.ultima_comunicacion = None

    db.commit()