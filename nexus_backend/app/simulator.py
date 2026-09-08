import asyncio
import random
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models import Dispositivo, LecturaConsumo

TARIFA_MXN_PER_KWH = 2.85  # Tarifa promedio estimada en Pesos Mexicanos

async def simular_lecturas_esp32():
    """Simula variaciones de lectura de los sensores ESP32 cada 3 segundos"""
    while True:
        await asyncio.sleep(3)
        db: Session = SessionLocal()
        try:
            dispositivos = db.query(Dispositivo).filter(Dispositivo.estado_on == True).all()
            for dev in dispositivos:
                # Variación aleatoria de +/- 3 Watts para simular corriente real
                variacion = random.uniform(-3.0, 3.0)
                dev.watts_actuales = max(5.0, round(dev.watts_actuales + variacion, 1))
                
                # Cálculo de costo en MXN por hora
                dev.costo_mxn_hora = round((dev.watts_actuales / 1000.0) * TARIFA_MXN_PER_KWH, 2)
                
                # Registrar historial de lectura
                lectura = LecturaConsumo(
                    dispositivo_id=dev.id,
                    watts=dev.watts_actuales,
                    costo_mxn=dev.costo_mxn_hora
                )
                db.add(lectura)
            
            db.commit()
        except Exception as e:
            print(f"Error en simulación: {e}")
            db.rollback()
        finally:
            db.close()