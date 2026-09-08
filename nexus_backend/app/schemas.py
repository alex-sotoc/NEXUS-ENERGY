from pydantic import BaseModel
from typing import Optional
from datetime import datetime

# Esquemas de Dispositivos
class DispositivoBase(BaseModel):
    nombre: str
    ubicacion: Optional[str] = "General"
    estado_on: bool = True
    watts_actuales: float = 0.0
    costo_mxn_hora: float = 0.0
    es_vampiro: bool = False
    mac_esp32: Optional[str] = None

class DispositivoCreate(DispositivoBase):
    pass

class DispositivoResponse(DispositivoBase):
    id: int
    creado_en: datetime

    class Config:
        from_attributes = True

# Esquema para comandos del Asistente de Voz
class ComandoVozRequest(BaseModel):
    texto: str

class ComandoVozResponse(BaseModel):
    accion_ejecutada: str
    mensaje_respuesta: str
    dispositivo_afectado: Optional[str] = None
    nuevo_estado: Optional[bool] = None