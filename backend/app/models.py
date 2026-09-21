from datetime import datetime

from sqlalchemy import (
    BigInteger,
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


# ============================================================
# USUARIO
# ============================================================

class Usuario(Base):
    __tablename__ = "usuarios"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )

    nombre: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    email: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        unique=True,
    )

    password_hash: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    creado_en: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )


# ============================================================
# DISPOSITIVO
# ============================================================

class Dispositivo(Base):
    __tablename__ = "dispositivos"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )

    nombre: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    ubicacion: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    # Estado del relay.
    #
    # True  = relay encendido
    # False = relay apagado
    estado_on: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
    )

    # Indica si el dispositivo está conectado
    # al stand/simulador.
    conectado: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
    )

    # Indica si el simulador está enviando
    # telemetría para este dispositivo.
    simulacion_activa: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
    )

    # ========================================================
    # TELEMETRÍA ACTUAL
    # ========================================================

    watts_actuales: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    amps_actuales: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    volts_actuales: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    # ========================================================
    # COSTO
    # ========================================================

    costo_mxn_hora: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    # ========================================================
    # PERFIL DE SIMULACIÓN
    # ========================================================

    es_vampiro: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
    )

    watts_standby: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    watts_min: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    watts_max: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    voltaje_nominal: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    # ========================================================
    # IDENTIFICADORES
    # ========================================================

    # Identificador lógico del dispositivo.
    #
    # Ejemplo:
    # SIM_CARGADOR_5V_1A
    # SIM_CARGADOR_33W
    # SIM_VENTILADOR_PEQUENO
    device_id: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        unique=True,
        index=True,
    )

    # Identificador del ESP32/ESP8266 físico.
    #
    # Los perfiles del simulador inicialmente tienen NULL.
    mac_esp32: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
        index=True,
    )

    # ========================================================
    # FECHAS
    # ========================================================

    ultima_comunicacion: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    creado_en: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    # ========================================================
    # RELACIÓN CON HISTORIAL
    # ========================================================

    lecturas: Mapped[list["LecturaConsumo"]] = relationship(
        back_populates="dispositivo",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )


# ============================================================
# LECTURA DE CONSUMO
# ============================================================

class LecturaConsumo(Base):
    __tablename__ = "lecturas_consumo"

    id: Mapped[int] = mapped_column(
        BigInteger,
        primary_key=True,
        autoincrement=True,
    )

    dispositivo_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey(
            "dispositivos.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    watts: Mapped[float] = mapped_column(
        Float,
        nullable=False,
    )

    amps: Mapped[float] = mapped_column(
        Float,
        nullable=False,
    )

    volts: Mapped[float] = mapped_column(
        Float,
        nullable=False,
    )

    costo_mxn: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    fecha_hora: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
    )

    dispositivo: Mapped["Dispositivo"] = relationship(
        back_populates="lecturas",
    )