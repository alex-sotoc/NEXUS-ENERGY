from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Dispositivo, LecturaConsumo
from app.schemas import (
    HistoryItem,
    HistoryResponse,
    RealtimeMetricsResponse,
)


router = APIRouter(
    prefix="/api/metrics",
    tags=["Metrics"],
)


# ============================================================
# CONFIGURACIÓN
# ============================================================

# Si el backend no recibe comunicación del simulador
# durante más de 15 segundos, online será False.
ONLINE_SECONDS = 15


# ============================================================
# HELPERS
# ============================================================

def _utc_now() -> datetime:
    """
    Devuelve la fecha y hora actual en UTC sin timezone
    para mantener compatibilidad con SQL Server.
    """
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _safe_float(value) -> float:
    """
    Convierte un valor a float de manera segura.
    Si el valor es None o inválido devuelve 0.0.
    """
    if value is None:
        return 0.0

    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


def _find_device(
    db: Session,
    device_id: str,
) -> Dispositivo | None:
    """
    Busca un dispositivo utilizando su device_id.
    """

    return (
        db.query(Dispositivo)
        .filter(
            Dispositivo.device_id == device_id
        )
        .first()
    )


def _find_active_device(
    db: Session,
) -> Dispositivo | None:
    """
    Busca el dispositivo actualmente conectado.

    IMPORTANTE PARA SQL SERVER:

    NO utilizar:

        Dispositivo.conectado.is_(True)

    porque puede generar:

        WHERE dispositivos.conectado IS 1

    SQL Server no acepta esa sintaxis.

    Utilizamos:

        Dispositivo.conectado == True

    para obtener una comparación compatible.
    """

    return (
        db.query(Dispositivo)
        .filter(
            Dispositivo.conectado == True
        )
        .order_by(
            Dispositivo.ultima_comunicacion.desc(),
            Dispositivo.id.desc(),
        )
        .first()
    )


def _is_online(
    device: Dispositivo,
) -> bool:
    """
    Determina si el dispositivo está comunicándose
    actualmente con el backend.

    Para considerarlo online:

    1. Debe estar conectado.
    2. Debe tener ultima_comunicacion.
    3. La última comunicación debe tener como máximo
       ONLINE_SECONDS segundos.
    """

    if not bool(device.conectado):
        return False

    if device.ultima_comunicacion is None:
        return False

    now = _utc_now()

    difference = (
        now - device.ultima_comunicacion
    ).total_seconds()

    return difference <= ONLINE_SECONDS


def _build_realtime_response(
    device: Dispositivo,
) -> RealtimeMetricsResponse:
    """
    Construye la respuesta de métricas en tiempo real.

    Las métricas solamente se muestran si:

        relay encendido
        +
        dispositivo conectado
        +
        simulación activa

    Si alguna condición no se cumple:

        watts = 0
        amps = 0
        volts = 0
    """

    relay_state = bool(
        device.estado_on
    )

    connected = bool(
        device.conectado
    )

    simulation_active = bool(
        device.simulacion_activa
    )

    should_show_values = (
        relay_state
        and connected
        and simulation_active
    )

    if should_show_values:

        watts = _safe_float(
            device.watts_actuales
        )

        amps = _safe_float(
            device.amps_actuales
        )

        volts = _safe_float(
            device.volts_actuales
        )

    else:

        watts = 0.0
        amps = 0.0
        volts = 0.0

    return RealtimeMetricsResponse(
        device_id=device.device_id,
        device_name=device.nombre,

        watts=watts,
        amps=amps,
        volts=volts,

        relay_state=relay_state,
        connected=connected,
        simulation_active=simulation_active,

        online=_is_online(device),

        timestamp=device.ultima_comunicacion,
    )


# ============================================================
# MÉTRICAS EN TIEMPO REAL POR DEVICE_ID
# ============================================================

@router.get(
    "/realtime/{device_id}",
    response_model=RealtimeMetricsResponse,
)
def get_realtime_metrics(
    device_id: str,
    db: Session = Depends(get_db),
):
    """
    Devuelve las métricas actuales de un dispositivo.

    REGLAS:

    Relay apagado:
        watts = 0
        amps = 0
        volts = 0

    Simulador desconectado:
        watts = 0
        amps = 0
        volts = 0

    Simulación inactiva:
        watts = 0
        amps = 0
        volts = 0

    Relay encendido + conectado + simulación activa:
        devuelve los valores actuales.
    """

    try:

        # ----------------------------------------------------
        # 1. BUSCAR DISPOSITIVO
        # ----------------------------------------------------

        device = _find_device(
            db=db,
            device_id=device_id,
        )

        # ----------------------------------------------------
        # 2. COMPROBAR QUE EXISTA
        # ----------------------------------------------------

        if device is None:
            raise HTTPException(
                status_code=404,
                detail=(
                    f"Dispositivo '{device_id}' "
                    "no encontrado."
                ),
            )

        # ----------------------------------------------------
        # 3. CONSTRUIR RESPUESTA
        # ----------------------------------------------------

        return _build_realtime_response(
            device
        )

    except HTTPException:

        db.rollback()
        raise

    except Exception as e:

        db.rollback()

        raise HTTPException(
            status_code=400,
            detail=str(e),
        )


# ============================================================
# MÉTRICAS DEL DISPOSITIVO ACTIVO
# ============================================================

@router.get(
    "/realtime",
    response_model=RealtimeMetricsResponse,
)
def get_active_realtime_metrics(
    db: Session = Depends(get_db),
):
    """
    Obtiene automáticamente el dispositivo actualmente
    conectado y devuelve sus métricas.

    Este será uno de los endpoints principales
    utilizados posteriormente por la aplicación Flutter.
    """

    try:

        # ----------------------------------------------------
        # 1. BUSCAR DISPOSITIVO ACTIVO
        # ----------------------------------------------------

        device = _find_active_device(
            db=db,
        )

        # ----------------------------------------------------
        # 2. COMPROBAR QUE EXISTA UNO CONECTADO
        # ----------------------------------------------------

        if device is None:
            raise HTTPException(
                status_code=404,
                detail=(
                    "No hay ningún dispositivo "
                    "conectado."
                ),
            )

        # ----------------------------------------------------
        # 3. CONSTRUIR RESPUESTA
        # ----------------------------------------------------

        return _build_realtime_response(
            device
        )

    except HTTPException:

        db.rollback()
        raise

    except Exception as e:

        db.rollback()

        raise HTTPException(
            status_code=400,
            detail=str(e),
        )


# ============================================================
# HISTORIAL DEL DISPOSITIVO
# ============================================================

@router.get(
    "/history/{device_id}",
    response_model=HistoryResponse,
)
def get_history(
    device_id: str,

    limit: int = Query(
        default=50,
        ge=1,
        le=500,
    ),

    db: Session = Depends(get_db),
):
    """
    Devuelve las últimas lecturas almacenadas
    del dispositivo.

    El parámetro limit indica cuántas lecturas
    como máximo queremos obtener.

    Ejemplo:

        /api/metrics/history/SIM_CARGADOR_33W?limit=50
    """

    try:

        # ----------------------------------------------------
        # 1. BUSCAR DISPOSITIVO
        # ----------------------------------------------------

        device = _find_device(
            db=db,
            device_id=device_id,
        )

        # ----------------------------------------------------
        # 2. COMPROBAR QUE EXISTA
        # ----------------------------------------------------

        if device is None:
            raise HTTPException(
                status_code=404,
                detail=(
                    f"Dispositivo '{device_id}' "
                    "no encontrado."
                ),
            )

        # ----------------------------------------------------
        # 3. CONSULTAR LECTURAS
        # ----------------------------------------------------

        readings = (
            db.query(LecturaConsumo)
            .filter(
                LecturaConsumo.dispositivo_id
                == device.id
            )
            .order_by(
                LecturaConsumo.fecha_hora.desc()
            )
            .limit(limit)
            .all()
        )

        # ----------------------------------------------------
        # 4. CONVERTIR LECTURAS
        # ----------------------------------------------------

        items = []

        # La consulta viene de más reciente a más antigua.
        # reversed permite devolverlas cronológicamente.
        for reading in reversed(readings):

            item = HistoryItem(
                id=reading.id,

                watts=_safe_float(
                    reading.watts
                ),

                amps=_safe_float(
                    reading.amps
                ),

                volts=_safe_float(
                    reading.volts
                ),

                costo_mxn=_safe_float(
                    reading.costo_mxn
                ),

                timestamp=reading.fecha_hora,
            )

            items.append(
                item
            )

        # ----------------------------------------------------
        # 5. RESPONDER
        # ----------------------------------------------------

        return HistoryResponse(
            device_id=device.device_id,
            device_name=device.nombre,
            readings=items,
        )

    except HTTPException:

        db.rollback()
        raise

    except Exception as e:

        db.rollback()

        raise HTTPException(
            status_code=400,
            detail=str(e),
        )