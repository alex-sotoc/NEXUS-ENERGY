/*
    ============================================================
    NEXUS ENERGY
    02_create_tables.sql
    ============================================================

    Reconstruye las tablas principales de NEXUS ENERGY.

    Tablas:
        usuarios
        dispositivos
        lecturas_consumo

    IMPORTANTE:
        Este script elimina las tablas anteriores y sus datos.
        Se recomienda ejecutarlo solamente cuando se quiera
        reiniciar completamente la estructura de la aplicación.
*/

USE nexus_energy_db;
GO


/* ============================================================
   1. ELIMINAR TABLAS ANTERIORES
   ============================================================ */

IF OBJECT_ID(N'dbo.lecturas_consumo', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.lecturas_consumo;
END
GO

IF OBJECT_ID(N'dbo.dispositivos', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.dispositivos;
END
GO

IF OBJECT_ID(N'dbo.usuarios', N'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.usuarios;
END
GO


/* ============================================================
   2. TABLA: usuarios
   ============================================================ */

CREATE TABLE dbo.usuarios
(
    id INT IDENTITY(1,1) NOT NULL,

    nombre NVARCHAR(100) NOT NULL,

    email NVARCHAR(150) NOT NULL,

    password_hash NVARCHAR(255) NOT NULL,

    creado_en DATETIME2 NOT NULL
        CONSTRAINT DF_usuarios_creado_en
        DEFAULT SYSDATETIME(),

    CONSTRAINT PK_usuarios
        PRIMARY KEY (id),

    CONSTRAINT UQ_usuarios_email
        UNIQUE (email)
);
GO


/* ============================================================
   3. TABLA: dispositivos
   ============================================================ */

CREATE TABLE dbo.dispositivos
(
    id INT IDENTITY(1,1) NOT NULL,

    /*
        Nombre que verá el usuario.
        Ejemplo:
            Televisor Sala
            Refrigerador
            Consola
    */
    nombre NVARCHAR(100) NOT NULL,

    /*
        Ubicación física o lógica.
    */
    ubicacion NVARCHAR(100) NULL,

    /*
        Estado del relay.
        1 = encendido
        0 = apagado
    */
    estado_on BIT NOT NULL
        CONSTRAINT DF_dispositivos_estado_on
        DEFAULT 0,

    /*
        Indica si el dispositivo está actualmente
        conectado al sistema de simulación.
    */
    conectado BIT NOT NULL
        CONSTRAINT DF_dispositivos_conectado
        DEFAULT 0,

    /*
        Indica si el simulador está generando
        telemetría para este dispositivo.
    */
    simulacion_activa BIT NOT NULL
        CONSTRAINT DF_dispositivos_simulacion_activa
        DEFAULT 0,

    /*
        Últimos valores conocidos del dispositivo.
    */
    watts_actuales FLOAT NOT NULL
        CONSTRAINT DF_dispositivos_watts_actuales
        DEFAULT 0.0,

    amps_actuales FLOAT NOT NULL
        CONSTRAINT DF_dispositivos_amps_actuales
        DEFAULT 0.0,

    volts_actuales FLOAT NOT NULL
        CONSTRAINT DF_dispositivos_volts_actuales
        DEFAULT 0.0,

    /*
        Costo estimado por hora.
    */
    costo_mxn_hora FLOAT NOT NULL
        CONSTRAINT DF_dispositivos_costo_mxn_hora
        DEFAULT 0.0,

    /*
        Indica si el dispositivo tiene
        comportamiento de consumo vampiro.
    */
    es_vampiro BIT NOT NULL
        CONSTRAINT DF_dispositivos_es_vampiro
        DEFAULT 0,

    /*
        Consumo simulado cuando el dispositivo
        se encuentra en standby.
    */
    watts_standby FLOAT NOT NULL
        CONSTRAINT DF_dispositivos_watts_standby
        DEFAULT 0.0,

    /*
        Consumo mínimo durante la simulación.
    */
    watts_min FLOAT NOT NULL
        CONSTRAINT DF_dispositivos_watts_min
        DEFAULT 0.0,

    /*
        Consumo máximo durante la simulación.
    */
    watts_max FLOAT NOT NULL
        CONSTRAINT DF_dispositivos_watts_max
        DEFAULT 0.0,

    /*
        Voltaje utilizado por el simulador.
        Normalmente 127 V para nuestro prototipo.
    */
    voltaje_nominal FLOAT NOT NULL
        CONSTRAINT DF_dispositivos_voltaje_nominal
        DEFAULT 127.0,

    /*
        Identificador del ESP32/ESP8266 asociado.
        Ejemplo:
            ESP32_RELAY_01
    */
    device_id NVARCHAR(100) NOT NULL,

    /*
        MAC o identificador físico del ESP32/ESP8266.
        Puede quedar NULL mientras no exista
        un identificador físico específico.
    */
    mac_esp32 NVARCHAR(50) NULL,

    /*
        Última vez que el backend recibió una
        comunicación relacionada con el dispositivo.
    */
    ultima_comunicacion DATETIME2 NULL,

    /*
        Fecha de creación del registro.
    */
    creado_en DATETIME2 NOT NULL
        CONSTRAINT DF_dispositivos_creado_en
        DEFAULT SYSDATETIME(),

    CONSTRAINT PK_dispositivos
        PRIMARY KEY (id),

    CONSTRAINT UQ_dispositivos_device_id
        UNIQUE (device_id),

    /*
        Evitamos valores negativos en parámetros
        de simulación.
    */
    CONSTRAINT CK_dispositivos_watts_actuales
        CHECK (watts_actuales >= 0),

    CONSTRAINT CK_dispositivos_amps_actuales
        CHECK (amps_actuales >= 0),

    CONSTRAINT CK_dispositivos_volts_actuales
        CHECK (volts_actuales >= 0),

    CONSTRAINT CK_dispositivos_costo
        CHECK (costo_mxn_hora >= 0),

    CONSTRAINT CK_dispositivos_standby
        CHECK (watts_standby >= 0),

    CONSTRAINT CK_dispositivos_watts_min
        CHECK (watts_min >= 0),

    CONSTRAINT CK_dispositivos_watts_max
        CHECK (watts_max >= watts_min),

    CONSTRAINT CK_dispositivos_voltaje
        CHECK (voltaje_nominal >= 0)
);
GO


/* ============================================================
   4. TABLA: lecturas_consumo
   ============================================================ */

CREATE TABLE dbo.lecturas_consumo
(
    id BIGINT IDENTITY(1,1) NOT NULL,

    /*
        Dispositivo al que pertenece la lectura.
    */
    dispositivo_id INT NOT NULL,

    /*
        Valores generados por el simulador.
    */
    watts FLOAT NOT NULL,

    amps FLOAT NOT NULL,

    volts FLOAT NOT NULL,

    /*
        Costo correspondiente a esta lectura.
    */
    costo_mxn FLOAT NOT NULL,

    /*
        Momento en que se generó la lectura.
    */
    fecha_hora DATETIME2 NOT NULL
        CONSTRAINT DF_lecturas_consumo_fecha_hora
        DEFAULT SYSDATETIME(),

    CONSTRAINT PK_lecturas_consumo
        PRIMARY KEY (id),

    CONSTRAINT FK_lecturas_consumo_dispositivo
        FOREIGN KEY (dispositivo_id)
        REFERENCES dbo.dispositivos(id)
        ON DELETE CASCADE,

    CONSTRAINT CK_lecturas_watts
        CHECK (watts >= 0),

    CONSTRAINT CK_lecturas_amps
        CHECK (amps >= 0),

    CONSTRAINT CK_lecturas_volts
        CHECK (volts >= 0),

    CONSTRAINT CK_lecturas_costo
        CHECK (costo_mxn >= 0)
);
GO


/* ============================================================
   5. ÍNDICES
   ============================================================ */

CREATE INDEX IX_dispositivos_mac_esp32
ON dbo.dispositivos(mac_esp32);
GO

CREATE INDEX IX_dispositivos_conectado
ON dbo.dispositivos(conectado);
GO

CREATE INDEX IX_dispositivos_simulacion_activa
ON dbo.dispositivos(simulacion_activa);
GO

CREATE INDEX IX_lecturas_consumo_dispositivo_fecha
ON dbo.lecturas_consumo(dispositivo_id, fecha_hora DESC);
GO

CREATE INDEX IX_lecturas_consumo_fecha
ON dbo.lecturas_consumo(fecha_hora DESC);
GO


/* ============================================================
   6. COMPROBACIÓN DE TABLAS
   ============================================================ */

SELECT
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO