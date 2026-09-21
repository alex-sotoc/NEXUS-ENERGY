# NEXUS ENERGY - Backend

Backend central de NEXUS ENERGY.

## Arquitectura

El backend utiliza:

- FastAPI
- SQLAlchemy
- SQL Server
- ODBC Driver 18
- Pydantic

## Aplicaciones conectadas

Este backend será utilizado por:

1. App principal
2. App simulador
3. ESP32/ESP8266 mediante las rutas de hardware

No se crearán dos backends.

Existe un único backend FastAPI.

## Base de datos

Servidor:

ALEX

Base:

nexus_energy_db

## Ejecución

Desde la carpeta `backend`:

```bash
uvicorn app.main:app --reload