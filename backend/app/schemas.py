from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


# ============================================================
# USUARIO
# ============================================================

class UserResponse(BaseModel):
    id: int
    nombre: str
    email: str
    creado_en: datetime | None = None

    model_config = ConfigDict(
        from_attributes=True,
    )


# ============================================================
# AUTENTICACIÓN
# ============================================================

class LoginRequest(BaseModel):
    email: str = Field(
        min_length=3,
        max_length=100,
    )

    password: str = Field(
        min_length=1,
        max_length=255,
    )


class LoginResponse(BaseModel):
    message: str
    user: UserResponse


class RegisterRequest(BaseModel):
    nombre: str = Field(
        min_length=2,
        max_length=100,
    )

    email: str = Field(
        min_length=3,
        max_length=100,
    )

    password: str = Field(
        min_length=6,
        max_length=255,
    )


# ============================================================
# DISPOSITIVOS
# ============================================================

class DeviceResponse(BaseModel):
    id: int
    device_id: str
    nombre: str
    ubicacion: str | None = None

    estado_on: bool
    conectado: bool
    simulacion_activa: bool

    watts_actuales: float
    amps_actuales: float
    volts_actuales: float

    costo_mxn_hora: float

    es_vampiro: bool

    watts_standby: float
    watts_min: float
    watts_max: float
    voltaje_nominal: float

    mac_esp32: str | None = None
    ultima_comunicacion: datetime | None = None
    creado_en: datetime | None = None

    model_config = ConfigDict(
        from_attributes=True,
    )


class DeviceCreateRequest(BaseModel):
    nombre: str = Field(
        min_length=2,
        max_length=100,
    )

    ubicacion: str | None = Field(
        default="Stand NEXUS",
        max_length=100,
    )

    device_id: str = Field(
        min_length=2,
        max_length=100,
    )

    costo_mxn_hora: float = Field(
        default=0.0,
        ge=0,
    )

    es_vampiro: bool = False

    watts_standby: float = Field(
        default=0.0,
        ge=0,
    )

    watts_min: float = Field(
        default=0.0,
        ge=0,
    )

    watts_max: float = Field(
        default=0.0,
        ge=0,
    )

    voltaje_nominal: float = Field(
        default=0.0,
        ge=0,
    )

    mac_esp32: str | None = Field(
        default=None,
        max_length=50,
    )


class DeviceStateResponse(BaseModel):
    device_id: str
    conectado: bool
    estado_on: bool
    simulacion_activa: bool

    watts_actuales: float
    amps_actuales: float
    volts_actuales: float

    ultima_comunicacion: datetime | None = None


# ============================================================
# TELEMETRÍA
# ============================================================

class TelemetryRequest(BaseModel):
    device_id: str

    watts: float = Field(
        ge=0,
    )

    amps: float = Field(
        ge=0,
    )

    volts: float = Field(
        ge=0,
    )

    costo_mxn: float | None = Field(
        default=None,
        ge=0,
    )


class TelemetryResponse(BaseModel):
    message: str
    device_id: str
    device_database_id: int

    watts: float
    amps: float
    volts: float

    timestamp: datetime


# ============================================================
# HARDWARE / RELAY
# ============================================================

class HardwareStatusResponse(BaseModel):
    device_id: str
    device_database_id: int
    device_name: str

    relay_state: bool
    online: bool

    last_telemetry_at: datetime | None = None


class HardwareToggleRequest(BaseModel):
    device_id: str

    relay_state: bool


class HardwareToggleResponse(BaseModel):
    message: str

    device_id: str
    device_database_id: int

    relay_state: bool


# ============================================================
# MÉTRICAS EN TIEMPO REAL
# ============================================================

class RealtimeMetricsResponse(BaseModel):
    device_id: str
    device_name: str

    watts: float
    amps: float
    volts: float

    relay_state: bool
    connected: bool
    simulation_active: bool
    online: bool

    timestamp: datetime | None = None


# ============================================================
# HISTORIAL
# ============================================================

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


# ============================================================
# SIMULADOR
# ============================================================

class SimulatorConnectRequest(BaseModel):
    device_id: str = Field(
        min_length=2,
        max_length=100,
    )


class SimulatorDisconnectRequest(BaseModel):
    device_id: str = Field(
        min_length=2,
        max_length=100,
    )


class SimulatorStateResponse(BaseModel):
    device_id: str
    device_name: str

    connected: bool
    simulation_active: bool
    relay_state: bool

    watts: float
    amps: float
    volts: float

    timestamp: datetime | None = None


# ============================================================
# MODO DEL SIMULADOR
# ============================================================

class SimulatorModeRequest(BaseModel):
    device_id: str = Field(
        min_length=2,
        max_length=100,
    )

    mode: str = Field(
        min_length=2,
        max_length=20,
    )


# ============================================================
# DISPOSITIVO PERSONALIZADO DEL SIMULADOR
# ============================================================

class SimulatorCustomDeviceRequest(BaseModel):
    nombre: str = Field(
        min_length=2,
        max_length=100,
    )

    voltaje_nominal: float = Field(
        gt=0,
        le=1000,
    )

    watts_min: float = Field(
        ge=0,
        le=100000,
    )

    watts_max: float = Field(
        ge=0,
        le=100000,
    )

    watts_standby: float = Field(
        default=0.0,
        ge=0,
        le=100000,
    )

    es_vampiro: bool = False