USE nexus_energy_db;
GO

/* ============================================================
   NEXUS ENERGY
   03_insert_initial_data.sql

   Este archivo inserta únicamente los datos iniciales.

   IMPORTANTE:
   - NO crea tablas.
   - NO modifica la estructura de las tablas.
   - Los dispositivos son perfiles pequeños para simulación.
   - Ningún dispositivo inicia conectado al stand.
   - Ningún dispositivo inicia con simulación activa.
   - El dashboard principal mostrará únicamente el dispositivo
     que posteriormente sea conectado mediante el simulador.
   ============================================================ */


/* ============================================================
   1. USUARIO INICIAL
   ============================================================

   Este usuario es solamente para tener un registro inicial
   mientras terminamos el sistema de autenticación.

   NOTA:
   El valor de password_hash es temporal.
   El backend posteriormente deberá trabajar con contraseñas
   correctamente hasheadas.
   ============================================================ */

IF NOT EXISTS (
    SELECT 1
    FROM usuarios
    WHERE email = 'brauni@nexus.com'
)
BEGIN
    INSERT INTO usuarios (
        nombre,
        email,
        password_hash,
        creado_en
    )
    VALUES (
        N'Brauni Soto',
        N'brauni@nexus.com',
        N'123456',
        GETDATE()
    );
END;
GO


/* ============================================================
   2. CARGADOR DE CELULAR
   ============================================================

   Perfil:
   - 5 V
   - hasta aproximadamente 1 A
   - aproximadamente 5 W en funcionamiento

   El consumo exacto durante la simulación será generado por
   la aplicación simuladora.

   Standby:
   Representa el pequeño consumo cuando el cargador permanece
   conectado pero no está realizando una carga activa.

   IMPORTANTE:
   conectado = 0
   simulacion_activa = 0

   Por lo tanto, NO aparecerá inicialmente como dispositivo
   conectado en el dashboard.
   ============================================================ */

IF NOT EXISTS (
    SELECT 1
    FROM dispositivos
    WHERE device_id = 'SIM_CARGADOR_5V_1A'
)
BEGIN
    INSERT INTO dispositivos (
        nombre,
        ubicacion,
        estado_on,
        conectado,
        simulacion_activa,
        watts_actuales,
        amps_actuales,
        volts_actuales,
        costo_mxn_hora,
        es_vampiro,
        watts_standby,
        watts_min,
        watts_max,
        voltaje_nominal,
        device_id,
        mac_esp32,
        ultima_comunicacion,
        creado_en
    )
    VALUES (
        N'Cargador de celular',
        N'Stand NEXUS',
        0,
        0,
        0,
        0.0,
        0.0,
        0.0,
        0.0,
        0,
        0.25,
        0.5,
        5.0,
        5.0,
        N'SIM_CARGADOR_5V_1A',
        NULL,
        NULL,
        GETDATE()
    );
END;
GO


/* ============================================================
   3. CARGADOR USB-C DE 33 W
   ============================================================

   Perfil:
   - cargador de hasta 33 W
   - voltaje de referencia de 5 V para la simulación inicial
   - consumo variable durante funcionamiento

   El simulador podrá generar diferentes niveles de consumo
   dentro del rango configurado.

   Standby:
   pequeño consumo cuando el cargador permanece conectado
   pero no está realizando una carga activa.
   ============================================================ */

IF NOT EXISTS (
    SELECT 1
    FROM dispositivos
    WHERE device_id = 'SIM_CARGADOR_33W'
)
BEGIN
    INSERT INTO dispositivos (
        nombre,
        ubicacion,
        estado_on,
        conectado,
        simulacion_activa,
        watts_actuales,
        amps_actuales,
        volts_actuales,
        costo_mxn_hora,
        es_vampiro,
        watts_standby,
        watts_min,
        watts_max,
        voltaje_nominal,
        device_id,
        mac_esp32,
        ultima_comunicacion,
        creado_en
    )
    VALUES (
        N'Cargador USB-C 33W',
        N'Stand NEXUS',
        0,
        0,
        0,
        0.0,
        0.0,
        0.0,
        0.0,
        0,
        0.30,
        3.0,
        33.0,
        5.0,
        N'SIM_CARGADOR_33W',
        NULL,
        NULL,
        GETDATE()
    );
END;
GO


/* ============================================================
   4. VENTILADOR PEQUEÑO
   ============================================================

   Perfil:
   - ventilador pequeño
   - consumo bajo
   - 127 V de referencia
   - consumo variable durante funcionamiento

   No estamos modelando un ventilador industrial ni un equipo
   de alto consumo.

   El objetivo es representar un pequeño dispositivo que pueda
   utilizarse físicamente en el prototipo.
   ============================================================ */

IF NOT EXISTS (
    SELECT 1
    FROM dispositivos
    WHERE device_id = 'SIM_VENTILADOR_PEQUENO'
)
BEGIN
    INSERT INTO dispositivos (
        nombre,
        ubicacion,
        estado_on,
        conectado,
        simulacion_activa,
        watts_actuales,
        amps_actuales,
        volts_actuales,
        costo_mxn_hora,
        es_vampiro,
        watts_standby,
        watts_min,
        watts_max,
        voltaje_nominal,
        device_id,
        mac_esp32,
        ultima_comunicacion,
        creado_en
    )
    VALUES (
        N'Ventilador pequeño',
        N'Stand NEXUS',
        0,
        0,
        0,
        0.0,
        0.0,
        0.0,
        0.0,
        0,
        1.0,
        15.0,
        35.0,
        127.0,
        N'SIM_VENTILADOR_PEQUENO',
        NULL,
        NULL,
        GETDATE()
    );
END;
GO


/* ============================================================
   5. LIMPIEZA DE ESTADO INICIAL
   ============================================================

   Esta sección garantiza que, aunque el script se ejecute
   nuevamente, los perfiles no queden accidentalmente conectados
   al stand.

   NO modifica los perfiles de simulación.
   Únicamente restablece el estado operativo inicial.
   ============================================================ */

UPDATE dispositivos
SET
    conectado = 0,
    simulacion_activa = 0,
    estado_on = 0,
    watts_actuales = 0.0,
    amps_actuales = 0.0,
    volts_actuales = 0.0,
    ultima_comunicacion = NULL
WHERE device_id IN (
    'SIM_CARGADOR_5V_1A',
    'SIM_CARGADOR_33W',
    'SIM_VENTILADOR_PEQUENO'
);
GO


/* ============================================================
   6. VERIFICACIÓN FINAL
   ============================================================ */

SELECT
    id,
    device_id,
    nombre,
    ubicacion,
    estado_on,
    conectado,
    simulacion_activa,
    watts_actuales,
    amps_actuales,
    volts_actuales,
    watts_standby,
    watts_min,
    watts_max,
    voltaje_nominal,
    mac_esp32,
    ultima_comunicacion,
    creado_en
FROM dispositivos
WHERE device_id IN (
    'SIM_CARGADOR_5V_1A',
    'SIM_CARGADOR_33W',
    'SIM_VENTILADOR_PEQUENO'
)
ORDER BY id;
GO


/* ============================================================
   7. RESUMEN
   ============================================================ */

SELECT
    COUNT(*) AS total_dispositivos_simulacion,
    SUM(
        CASE
            WHEN conectado = 1 THEN 1
            ELSE 0
        END
    ) AS dispositivos_conectados,
    SUM(
        CASE
            WHEN simulacion_activa = 1 THEN 1
            ELSE 0
        END
    ) AS simulaciones_activas
FROM dispositivos
WHERE device_id IN (
    'SIM_CARGADOR_5V_1A',
    'SIM_CARGADOR_33W',
    'SIM_VENTILADOR_PEQUENO'
);
GO