from datetime import datetime

from pydantic import BaseModel, ConfigDict


class DeviceResponse(BaseModel):
    id: int
    device_id: str
    nombre: str
    ubicacion: str | None
    estado_on: bool
    watts_actuales: float
    costo_mxn_hora: float
    es_vampiro: bool
    creado_en: datetime | None

    model_config = ConfigDict(from_attributes=True)


class DeviceDetailResponse(DeviceResponse):
    last_telemetry_at: datetime | None
    online: bool


class TelemetryRequest(BaseModel):
    device_id: str
    watts: float
    amps: float
    volts: float
    costo_mxn: float | None = None


class TelemetryResponse(BaseModel):
    message: str
    device_id: str
    device_database_id: int
    watts: float
    amps: float
    volts: float


class HardwareStatusResponse(BaseModel):
    device_id: str
    device_database_id: int
    device_name: str
    relay_state: bool
    online: bool
    last_telemetry_at: datetime | None


class HardwareToggleRequest(BaseModel):
    device_id: str
    relay_state: bool


class HardwareToggleResponse(BaseModel):
    message: str
    device_id: str
    device_database_id: int
    relay_state: bool


class RealtimeMetricsResponse(BaseModel):
    device_id: str
    device_name: str
    watts: float
    amps: float
    volts: float
    relay_state: bool
    online: bool
    timestamp: datetime | None


class HistoryItem(BaseModel):
    id: int
    watts: float
    amps: float
    volts: float
    costo_mxn: float
    timestamp: datetime


class HistoryResponse(BaseModel):
    device_id: str
    device_name: str
    readings: list[HistoryItem]