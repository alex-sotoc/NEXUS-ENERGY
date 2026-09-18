from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes.devices import router as devices_router
from app.routes.hardware import router as hardware_router
from app.routes.metrics import router as metrics_router


app = FastAPI(
    title="NEXUS Energy API",
    description="Backend IoT para monitoreo y control energético.",
    version="1.0.0",
)


# ============================================================
# CORS
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


# ============================================================
# ROUTERS
# ============================================================

app.include_router(hardware_router)
app.include_router(devices_router)
app.include_router(metrics_router)


# ============================================================
# ROOT
# ============================================================

@app.get("/")
def root():
    return {
        "application": "NEXUS Energy",
        "status": "online",
        "version": "1.0.0",
    }


# ============================================================
# HEALTH CHECK
# ============================================================

@app.get("/health")
def health_check():
    return {
        "status": "ok",
    }