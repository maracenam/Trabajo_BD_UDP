-- =====================================================================
--  Distribuidora La Mundial - Fase Implementacion
--  01_creacion_tablas.sql
--  Crea la base de datos y las 11 tablas del modelo de la fase Diseno
--  (mas la tabla de auditoria Historial_Precio usada por el
--  procesamiento masivo).
--  RDBMS: MySQL 8.0+  (probado tambien en MariaDB 10.11)
-- =====================================================================

DROP DATABASE IF EXISTS la_mundial;
CREATE DATABASE la_mundial CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE la_mundial;

-- ---------------------------------------------------------------------
-- Catalogos
-- ---------------------------------------------------------------------
CREATE TABLE categoria (
    id_categoria INT          NOT NULL AUTO_INCREMENT,
    nombre       VARCHAR(15)  NOT NULL,
    CONSTRAINT pk_categoria PRIMARY KEY (id_categoria),
    CONSTRAINT uk_categoria_nombre UNIQUE (nombre)            -- LS
) ENGINE = InnoDB;

CREATE TABLE marca (
    id_marca INT         NOT NULL AUTO_INCREMENT,
    nombre   VARCHAR(20) NOT NULL,
    CONSTRAINT pk_marca PRIMARY KEY (id_marca),
    CONSTRAINT uk_marca_nombre UNIQUE (nombre)                -- LS
) ENGINE = InnoDB;

CREATE TABLE proveedor (
    id_proveedor INT          NOT NULL AUTO_INCREMENT,
    rut          VARCHAR(10)  NOT NULL,
    razon_social VARCHAR(100) NOT NULL,
    telefono     CHAR(9)      NULL,
    email        VARCHAR(100) NULL,
    CONSTRAINT pk_proveedor PRIMARY KEY (id_proveedor),
    CONSTRAINT uk_proveedor_rut UNIQUE (rut),                 -- LS
    CONSTRAINT uk_proveedor_razon UNIQUE (razon_social)       -- LS
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Productos y stock
-- ---------------------------------------------------------------------
CREATE TABLE producto (
    id_producto  INT          NOT NULL AUTO_INCREMENT,
    sku          VARCHAR(20)  NOT NULL,
    nombre       VARCHAR(100) NOT NULL,
    precio_det   INT          NOT NULL,
    precio_may   INT          NOT NULL,
    id_categoria INT          NOT NULL,
    id_marca     INT          NOT NULL,
    id_proveedor INT          NOT NULL,
    CONSTRAINT pk_producto PRIMARY KEY (id_producto),
    CONSTRAINT uk_producto_sku UNIQUE (sku),                  -- LS
    CONSTRAINT fk_producto_categoria FOREIGN KEY (id_categoria)
        REFERENCES categoria (id_categoria),
    CONSTRAINT fk_producto_marca FOREIGN KEY (id_marca)
        REFERENCES marca (id_marca),
    CONSTRAINT fk_producto_proveedor FOREIGN KEY (id_proveedor)
        REFERENCES proveedor (id_proveedor),
    CONSTRAINT ck_producto_precios CHECK (precio_det > 0 AND precio_may > 0
                                          AND precio_may <= precio_det)
) ENGINE = InnoDB;

CREATE TABLE stock (
    id_stock    INT  NOT NULL AUTO_INCREMENT,
    id_producto INT  NOT NULL,
    cantidad    INT  NOT NULL DEFAULT 0,
    stock_min   INT  NOT NULL DEFAULT 0,
    fecha_act   DATE NOT NULL,
    CONSTRAINT pk_stock PRIMARY KEY (id_stock),
    CONSTRAINT uk_stock_producto UNIQUE (id_producto),        -- LS (1:1)
    CONSTRAINT fk_stock_producto FOREIGN KEY (id_producto)
        REFERENCES producto (id_producto) ON DELETE CASCADE,
    CONSTRAINT ck_stock_cantidad CHECK (cantidad >= 0 AND stock_min >= 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Clientes y empleados
-- ---------------------------------------------------------------------
CREATE TABLE tipo_cliente (
    id_tipo_cliente   INT         NOT NULL AUTO_INCREMENT,
    nombre            VARCHAR(20) NOT NULL,
    aplica_precio_may TINYINT(1)  NOT NULL DEFAULT 0,  -- 1 = paga precio por mayor
    CONSTRAINT pk_tipo_cliente PRIMARY KEY (id_tipo_cliente),
    CONSTRAINT uk_tipo_cliente_nombre UNIQUE (nombre)         -- LS
) ENGINE = InnoDB;

CREATE TABLE cliente (
    id_cliente      INT          NOT NULL AUTO_INCREMENT,
    rut             VARCHAR(10)  NOT NULL,
    nombre          VARCHAR(100) NOT NULL,
    telefono        CHAR(9)      NULL,
    id_tipo_cliente INT          NOT NULL,
    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
    CONSTRAINT uk_cliente_rut UNIQUE (rut),                   -- LS
    CONSTRAINT fk_cliente_tipo FOREIGN KEY (id_tipo_cliente)
        REFERENCES tipo_cliente (id_tipo_cliente)
) ENGINE = InnoDB;

CREATE TABLE empleado (
    id_empleado INT          NOT NULL AUTO_INCREMENT,
    rut         VARCHAR(10)  NOT NULL,
    nombre      VARCHAR(100) NOT NULL,
    cargo       VARCHAR(30)  NOT NULL,
    CONSTRAINT pk_empleado PRIMARY KEY (id_empleado),
    CONSTRAINT uk_empleado_rut UNIQUE (rut)                   -- LS
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Atencion y ventas
-- ---------------------------------------------------------------------
CREATE TABLE ticket (
    id_ticket INT         NOT NULL AUTO_INCREMENT,
    numero    INT         NOT NULL,
    fecha     DATE        NOT NULL,
    hora      TIME        NOT NULL,
    estado    VARCHAR(15) NOT NULL DEFAULT 'emitido',
    CONSTRAINT pk_ticket PRIMARY KEY (id_ticket),
    CONSTRAINT ck_ticket_estado CHECK (estado IN ('emitido', 'atendido', 'anulado'))
) ENGINE = InnoDB;

CREATE TABLE venta (
    id_venta    INT  NOT NULL AUTO_INCREMENT,
    fecha       DATE NOT NULL,
    hora        TIME NOT NULL,
    id_ticket   INT  NOT NULL,
    id_cliente  INT  NOT NULL,
    id_empleado INT  NOT NULL,
    CONSTRAINT pk_venta PRIMARY KEY (id_venta),
    CONSTRAINT uk_venta_ticket UNIQUE (id_ticket),            -- LS (1:1)
    CONSTRAINT fk_venta_ticket FOREIGN KEY (id_ticket)
        REFERENCES ticket (id_ticket),
    CONSTRAINT fk_venta_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente),
    CONSTRAINT fk_venta_empleado FOREIGN KEY (id_empleado)
        REFERENCES empleado (id_empleado)
) ENGINE = InnoDB;

CREATE TABLE detalle_venta (
    id_detalle  INT NOT NULL AUTO_INCREMENT,
    id_venta    INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad    INT NOT NULL,
    precio_unit INT NOT NULL,
    CONSTRAINT pk_detalle_venta PRIMARY KEY (id_detalle),
    CONSTRAINT fk_detalle_venta FOREIGN KEY (id_venta)
        REFERENCES venta (id_venta) ON DELETE CASCADE,
    CONSTRAINT fk_detalle_producto FOREIGN KEY (id_producto)
        REFERENCES producto (id_producto),
    CONSTRAINT ck_detalle_valores CHECK (cantidad > 0 AND precio_unit > 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Auditoria de precios (soporte para el procesamiento masivo)
-- ---------------------------------------------------------------------
CREATE TABLE historial_precio (
    id_historial    INT          NOT NULL AUTO_INCREMENT,
    id_producto     INT          NOT NULL,
    precio_det_ant  INT          NOT NULL,
    precio_det_nuevo INT         NOT NULL,
    precio_may_ant  INT          NOT NULL,
    precio_may_nuevo INT         NOT NULL,
    fecha_cambio    DATETIME     NOT NULL,
    motivo          VARCHAR(100) NOT NULL,
    CONSTRAINT pk_historial_precio PRIMARY KEY (id_historial),
    CONSTRAINT fk_historial_producto FOREIGN KEY (id_producto)
        REFERENCES producto (id_producto) ON DELETE CASCADE
) ENGINE = InnoDB;
