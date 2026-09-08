import asyncio
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List

from app.database import engine, Base, get_db
from app.models import Dispositivo
from app.schemas import DispositivoResponse, ComandoVozRequest, ComandoVozResponse
from app.simulator import simular_lecturas_esp32

# Crear tablas si no existen
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Nexus Energy API", version="1.0.0")

# Habilitar CORS para conexión remota/local desde Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    # Iniciar la simulación del ESP32 en segundo plano
    asyncio.create_task(simular_lecturas_esp32())

@app.get("/")
def read_root():
    return {"status": "online", "system": "Nexus Energy Backend"}

@app.get("/dispositivos", response_model=List[DispositivoResponse])
def obtener_dispositivos(db: Session = Depends(get_db)):
    return db.query(Dispositivo).all()

@app.post("/dispositivos/{dispositivo_id}/toggle")
def alternar_estado_dispositivo(dispositivo_id: int, db: Session = Depends(get_db)):
    dev = db.query(Dispositivo).filter(Dispositivo.id == dispositivo_id).first()
    if not dev:
        raise HTTPException(status_code=404, detail="Dispositivo no encontrado")
    
    dev.estado_on = not dev.estado_on
    if not dev.estado_on:
        dev.watts_actuales = 0.0
        dev.costo_mxn_hora = 0.0
    else:
        dev.watts_actuales = 100.0  # Valor base de encendido
        dev.costo_mxn_hora = 0.30
        
    db.commit()
    db.refresh(dev)
    return {"id": dev.id, "nombre": dev.nombre, "estado_on": dev.estado_on}

@app.post("/asistente-voz", response_model=ComandoVozResponse)
def procesar_comando_voz(request: ComandoVozRequest, db: Session = Depends(get_db)):
    texto = request.texto.lower()
    dispositivos = db.query(Dispositivo).all()
    
    for dev in dispositivos:
        if dev.nombre.lower() in texto:
            if "apagar" in texto or "apaga" in texto:
                dev.estado_on = False
                dev.watts_actuales = 0.0
                dev.costo_mxn_hora = 0.0
                db.commit()
                return ComandoVozResponse(
                    accion_ejecutada="APAGAR",
                    mensaje_respuesta=f"Entendido, apagando {dev.nombre}.",
                    dispositivo_afectado=dev.nombre,
                    nuevo_estado=False
                )
            elif "encender" in texto or "prende" in texto or "enciende" in texto:
                dev.estado_on = True
                dev.watts_actuales = 120.0
                db.commit()
                return ComandoVozResponse(
                    accion_ejecutada="ENCENDER",
                    mensaje_respuesta=f"Entendido, encendiendo {dev.nombre}.",
                    dispositivo_afectado=dev.nombre,
                    nuevo_estado=True
                )
                
    return ComandoVozResponse(
        accion_ejecutada="NINGUNA",
        mensaje_respuesta="No logré identificar el dispositivo o la acción solicitada."
    )