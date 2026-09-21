from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes.auth import router as auth_router
from app.routes.devices import router as devices_router
from app.routes.hardware import router as hardware_router
from app.routes.metrics import router as metrics_router
from app.routes.simulator import router as simulator_router


# ============================================================
# APLICACIÓN
# ============================================================

app = FastAPI(
    title="NEXUS ENERGY API",
    description=(
        "Backend de NEXUS ENERGY para monitoreo, "
        "simulación y control de dispositivos eléctricos."
    ),
    version="1.0.0",
)


# ============================================================
# CORS
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# ROUTER — AUTENTICACIÓN
# ============================================================

app.include_router(
    auth_router,
)


# ============================================================
# ROUTER — DISPOSITIVOS
# ============================================================

app.include_router(
    devices_router,
)


# ============================================================
# ROUTER — MÉTRICAS
# ============================================================

app.include_router(
    metrics_router,
)


# ============================================================
# ROUTER — HARDWARE / RELAY
# ============================================================

app.include_router(
    hardware_router,
)


# ============================================================
# ROUTER — SIMULADOR
# ============================================================

app.include_router(
    simulator_router,
)


# ============================================================
# ROOT
# ============================================================

@app.get("/")
def root():
    return {
        "message": "NEXUS ENERGY API",
        "status": "online",
        "version": "1.0.0",
    }


# ============================================================
# HEALTH CHECK
# ============================================================

@app.get(
    "/health",
)
def health_check():
    return {
        "status": "healthy",
        "service": "nexus-energy-backend",
    }