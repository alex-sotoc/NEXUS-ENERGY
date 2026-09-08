from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.database import Base

class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    creado_en = Column(DateTime, server_default=func.now())

class Dispositivo(Base):
    __tablename__ = "dispositivos"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    ubicacion = Column(String(100), default="General")
    estado_on = Column(Boolean, default=True)
    watts_actuales = Column(Float, default=0.0)
    costo_mxn_hora = Column(Float, default=0.0)
    es_vampiro = Column(Boolean, default=False)
    mac_esp32 = Column(String(50), nullable=True)
    creado_en = Column(DateTime, server_default=func.now())

class LecturaConsumo(Base):
    __tablename__ = "lecturas_consumo"

    id = Column(Integer, primary_key=True, index=True)
    dispositivo_id = Column(Integer, ForeignKey("dispositivos.id"))
    watts = Column(Float, nullable=False)
    costo_mxn = Column(Float, nullable=False)
    fecha_hora = Column(DateTime, server_default=func.now())