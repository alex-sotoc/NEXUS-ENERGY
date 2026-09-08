CREATE DATABASE nexus_energy_db;
GO

USE nexus_energy_db;
GO

CREATE TABLE usuarios (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    email NVARCHAR(100) UNIQUE NOT NULL,
    password_hash NVARCHAR(255) NOT NULL,
    creado_en DATETIME DEFAULT GETDATE()
);

CREATE TABLE dispositivos (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    ubicacion NVARCHAR(100) DEFAULT 'General',
    estado_on BIT DEFAULT 1,
    watts_actuales FLOAT DEFAULT 0.0,
    costo_mxn_hora FLOAT DEFAULT 0.0,
    es_vampiro BIT DEFAULT 0,
    mac_esp32 NVARCHAR(50) NULL,
    creado_en DATETIME DEFAULT GETDATE()
);

CREATE TABLE lecturas_consumo (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    dispositivo_id INT FOREIGN KEY REFERENCES dispositivos(id),
    watts FLOAT NOT NULL,
    costo_mxn FLOAT NOT NULL,
    fecha_hora DATETIME DEFAULT GETDATE()
);

INSERT INTO usuarios (nombre, email, password_hash) 
VALUES ('Brauni Soto', 'brauni@nexus.com', '123456');

INSERT INTO dispositivos (nombre, ubicacion, estado_on, watts_actuales, costo_mxn_hora, es_vampiro, mac_esp32) 
VALUES 
('Televisor Sala', 'Sala', 1, 120.0, 0.85, 1, 'ESP32_RELAY_01'),
('Refrigerador', 'Cocina', 1, 90.0, 0.65, 0, 'ESP32_RELAY_02'),
('Aire Acondicionado', 'Recámara', 0, 0.0, 0.0, 0, 'ESP32_RELAY_03'),
('Consola de Juegos', 'Sala', 1, 50.0, 0.35, 1, 'ESP32_RELAY_04');
GO