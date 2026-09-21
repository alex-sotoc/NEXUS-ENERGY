/*
    ============================================================
    NEXUS ENERGY
    01_create_database.sql
    ============================================================

    Crea la base de datos principal del proyecto.

    IMPORTANTE:
    - No elimina una base de datos existente.
    - Si nexus_energy_db ya existe, no hace nada.
*/

IF DB_ID(N'nexus_energy_db') IS NULL
BEGIN
    CREATE DATABASE nexus_energy_db;
END
GO

USE nexus_energy_db;
GO

SELECT
    DB_NAME() AS base_de_datos_actual;
GO