from datetime import datetime

from sqlalchemy import BigInteger, Boolean, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


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

    estado_on: Mapped[bool | None] = mapped_column(
        Boolean,
        nullable=True,
        default=True,
    )

    watts_actuales: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
        default=0.0,
    )

    costo_mxn_hora: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
        default=0.0,
    )

    es_vampiro: Mapped[bool | None] = mapped_column(
        Boolean,
        nullable=True,
        default=False,
    )

    mac_esp32: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
        index=True,
    )

    creado_en: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )


class LecturaConsumo(Base):
    __tablename__ = "lecturas_consumo"

    id: Mapped[int] = mapped_column(
        BigInteger,
        primary_key=True,
        autoincrement=True,
    )

    dispositivo_id: Mapped[int | None] = mapped_column(
        Integer,
        ForeignKey("dispositivos.id"),
        nullable=True,
    )

    watts: Mapped[float] = mapped_column(
        Float,
        nullable=False,
    )

    costo_mxn: Mapped[float] = mapped_column(
        Float,
        nullable=False,
    )

    fecha_hora: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    amps: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
    )

    volts: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
    )