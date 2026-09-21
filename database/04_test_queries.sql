/*
    ============================================================
    NEXUS ENERGY
    04_test_queries.sql
    ============================================================

    Pruebas básicas de la base de datos.
*/

USE nexus_energy_db;
GO


/* ============================================================
   PRUEBA 1
   Ver tablas
   ============================================================ */

SELECT
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO


/* ============================================================
   PRUEBA 2
   Usuarios
   ============================================================ */

SELECT
    id,
    nombre,
    email,
    creado_en
FROM dbo.usuarios;
GO


/* ============================================================
   PRUEBA 3
   Dispositivos
   ============================================================ */

SELECT
    id,
    nombre,
    ubicacion,
    device_id,
    mac_esp32,
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
    ultima_comunicacion,
    creado_en
FROM dbo.dispositivos
ORDER BY id;
GO


/* ============================================================
   PRUEBA 4
   Buscar dispositivo por device_id
   ============================================================ */

SELECT
    *
FROM dbo.dispositivos
WHERE device_id = N'ESP32_RELAY_01';
GO


/* ============================================================
   PRUEBA 5
   Buscar dispositivo por ESP32
   ============================================================ */

SELECT
    *
FROM dbo.dispositivos
WHERE mac_esp32 = N'ESP32_RELAY_01';
GO


/* ============================================================
   PRUEBA 6
   Comprobar lecturas
   ============================================================ */

SELECT
    id,
    dispositivo_id,
    watts,
    amps,
    volts,
    costo_mxn,
    fecha_hora
FROM dbo.lecturas_consumo
ORDER BY fecha_hora DESC;
GO


/* ============================================================
   PRUEBA 7
   Relación dispositivos -> lecturas
   ============================================================ */

SELECT
    d.id AS dispositivo_id,
    d.nombre,
    l.id AS lectura_id,
    l.watts,
    l.amps,
    l.volts,
    l.costo_mxn,
    l.fecha_hora
FROM dbo.dispositivos AS d
LEFT JOIN dbo.lecturas_consumo AS l
    ON l.dispositivo_id = d.id
ORDER BY
    d.id,
    l.fecha_hora DESC;
GO


/* ============================================================
   PRUEBA 8
   Conteo de registros
   ============================================================ */

SELECT
    (SELECT COUNT(*) FROM dbo.usuarios)
        AS total_usuarios,

    (SELECT COUNT(*) FROM dbo.dispositivos)
        AS total_dispositivos,

    (SELECT COUNT(*) FROM dbo.lecturas_consumo)
        AS total_lecturas;
GO