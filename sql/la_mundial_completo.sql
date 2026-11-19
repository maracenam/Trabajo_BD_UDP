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
-- =====================================================================
--  02_carga_datos.sql
--  Datos de prueba (todas las tablas con 4 tuplas o mas).
-- =====================================================================
USE la_mundial;

INSERT INTO categoria (nombre) VALUES
 ('Chocolates'), ('Galletas'), ('Snacks'), ('Bebidas'),
 ('Caramelos'), ('Aseo personal');

INSERT INTO marca (nombre) VALUES
 ('Nestle'), ('Costa'), ('Arcor'), ('McKay'), ('Evercrisp'),
 ('Coca-Cola'), ('Ambrosoli'), ('Dove'), ('Colgate'), ('Savory Sur');

INSERT INTO proveedor (rut, razon_social, telefono, email) VALUES
 ('76123456-7', 'Distribuidora Andes SpA',        '226001100', 'ventas@andesspa.cl'),
 ('77234567-8', 'Comercial Dulce Sur Ltda.',      '226002200', 'contacto@dulcesur.cl'),
 ('78345678-9', 'Embotelladora Central S.A.',     '226003300', 'pedidos@embcentral.cl'),
 ('79456789-0', 'Higiene Total Chile SpA',        '226004400', 'ventas@higienetotal.cl'),
 ('76567890-1', 'Importadora Snack Market Ltda.', NULL,        'snackmarket@correo.cl');

-- precio_det = precio al detalle / precio_may = precio por mayor (CLP)
INSERT INTO producto (sku, nombre, precio_det, precio_may, id_categoria, id_marca, id_proveedor) VALUES
 ('7802800000011', 'Chocolate Sahne-Nuss 160 g',         2990, 2490, 1, 1, 1),
 ('7802800000028', 'Chocolate Trencito 150 g',           2490, 2050, 1, 1, 1),
 ('7802215000015', 'Chocolate Costa Rama Leche 115 g',   1990, 1650, 1, 2, 2),
 ('7790580000016', 'Bombones Arcor Surtidos 200 g',      4590, 3800, 1, 3, 2),
 ('7802215000022', 'Galletas Costa Frac 130 g',           890,  720, 2, 2, 2),
 ('7613030000013', 'Galletas McKay Triton 126 g',         950,  780, 2, 4, 1),
 ('7613030000020', 'Galletas McKay Kuky 120 g',           990,  810, 2, 4, 1),
 ('7802215000039', 'Galletas Costa Chocman 33 g',         350,  270, 2, 2, 2),
 ('7802000000014', 'Papas Fritas Evercrisp 250 g',       2590, 2150, 3, 5, 5),
 ('7802000000021', 'Ramitas Evercrisp 200 g',            1690, 1400, 3, 5, 5),
 ('7802000000038', 'Mani Salado Savory Sur 150 g',       1290, 1050, 3, 10, 5),
 ('7801610000011', 'Coca-Cola Original 1,5 L',           1890, 1590, 4, 6, 3),
 ('7801610000028', 'Coca-Cola Zero 1,5 L',               1890, 1590, 4, 6, 3),
 ('7801610000035', 'Agua Benedictino 1,5 L',              990,  790, 4, 6, 3),
 ('7802225000014', 'Caramelos Ambrosoli Frutales 400 g', 2290, 1890, 5, 7, 2),
 ('7802225000021', 'Calugas Ambrosoli Leche 300 g',      2690, 2200, 5, 7, 2),
 ('7891150000016', 'Jabon Dove Original 90 g',            990,  820, 6, 8, 4),
 ('7891150000023', 'Shampoo Dove Reconstruccion 400 ml', 4290, 3600, 6, 8, 4),
 ('7891024000014', 'Pasta Dental Colgate Total 90 g',    2390, 1990, 6, 9, 4),
 ('7891024000021', 'Cepillo Dental Colgate Medio',       1490, 1190, 6, 9, 4);

INSERT INTO stock (id_producto, cantidad, stock_min, fecha_act) VALUES
 ( 1, 180, 50, '2026-11-02'), ( 2, 220, 60, '2026-11-02'),
 ( 3,  40, 60, '2026-11-03'), ( 4,  25, 20, '2026-11-03'),
 ( 5, 300, 80, '2026-11-01'), ( 6, 260, 80, '2026-11-01'),
 ( 7,  70, 80, '2026-11-01'), ( 8, 500, 150,'2026-11-04'),
 ( 9,  90, 40, '2026-11-02'), (10, 110, 40, '2026-11-02'),
 (11,  15, 30, '2026-11-05'), (12, 140, 60, '2026-11-03'),
 (13, 120, 60, '2026-11-03'), (14, 200, 60, '2026-11-03'),
 (15,  60, 30, '2026-11-04'), (16,  12, 25, '2026-11-04'),
 (17, 150, 50, '2026-11-01'), (18,  35, 20, '2026-11-01'),
 (19,  80, 30, '2026-11-01'), (20,  18, 25, '2026-11-01');

INSERT INTO tipo_cliente (nombre, aplica_precio_may) VALUES
 ('Minorista',    0),
 ('Mayorista',    1),
 ('Turista',      0),
 ('Distribuidor', 1);

INSERT INTO cliente (rut, nombre, telefono, id_tipo_cliente) VALUES
 ('66666666-6', 'Cliente General (boleta)',        NULL,        1),
 ('12345678-5', 'Camila Rojas Fuentes',            '912345678', 1),
 ('15987654-3', 'Jorge Munoz Soto',                '987654321', 1),
 ('76998877-K', 'Minimarket Don Pepe SpA',         '225556677', 2),
 ('77665544-2', 'Almacen La Esquina Ltda.',        '224443322', 2),
 ('P1234567',   'Joao Silva (Brasil)',             NULL,        3),
 ('P7654321',   'Mariana Costa (Brasil)',          NULL,        3),
 ('78112233-4', 'Distribuidora Norte Grande SpA',  '552223344', 4);

INSERT INTO empleado (rut, nombre, cargo) VALUES
 ('16111222-3', 'Pedro Gonzalez Lagos',  'Vendedor'),
 ('17222333-4', 'Valentina Diaz Perez',  'Vendedora'),
 ('18333444-5', 'Ricardo Morales Vega',  'Cajero'),
 ('13444555-6', 'Carolina Herrera Ruiz', 'Jefa de Local'),
 ('19555666-7', 'Felipe Castro Nunez',   'Vendedor');

-- Tickets de atencion (el numero se reinicia cada dia)
INSERT INTO ticket (numero, fecha, hora, estado) VALUES
 (1, '2026-11-10', '09:05:00', 'atendido'),
 (2, '2026-11-10', '09:12:00', 'atendido'),
 (3, '2026-11-10', '09:20:00', 'anulado'),
 (4, '2026-11-10', '10:02:00', 'atendido'),
 (5, '2026-11-10', '11:40:00', 'atendido'),
 (1, '2026-11-11', '09:01:00', 'atendido'),
 (2, '2026-11-11', '09:30:00', 'atendido'),
 (3, '2026-11-11', '10:15:00', 'atendido'),
 (4, '2026-11-11', '12:45:00', 'atendido'),
 (1, '2026-11-12', '09:10:00', 'atendido'),
 (2, '2026-11-12', '09:55:00', 'atendido'),
 (3, '2026-11-12', '11:20:00', 'atendido'),
 (4, '2026-11-12', '16:05:00', 'emitido'),
 (5, '2026-11-12', '16:20:00', 'emitido');

INSERT INTO venta (fecha, hora, id_ticket, id_cliente, id_empleado) VALUES
 ('2026-11-10', '09:09:00',  1, 2, 1),
 ('2026-11-10', '09:25:00',  2, 4, 2),
 ('2026-11-10', '10:10:00',  4, 6, 1),
 ('2026-11-10', '11:52:00',  5, 1, 3),
 ('2026-11-11', '09:08:00',  6, 7, 2),
 ('2026-11-11', '09:41:00',  7, 5, 5),
 ('2026-11-11', '10:20:00',  8, 3, 1),
 ('2026-11-11', '13:02:00',  9, 8, 4),
 ('2026-11-12', '09:18:00', 10, 6, 5),
 ('2026-11-12', '10:05:00', 11, 4, 2),
 ('2026-11-12', '11:31:00', 12, 2, 3);

-- precio_unit: precio vigente al momento de la venta segun tipo de cliente
INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unit) VALUES
 ( 1,  1,  2, 2990), ( 1, 12,  1, 1890), ( 1,  5,  3,  890),
 ( 2,  8, 60,  270), ( 2,  5, 40,  720), ( 2, 12, 24, 1590), ( 2,  9, 10, 2150),
 ( 3,  1, 10, 2990), ( 3,  2, 12, 2490), ( 3,  4,  3, 4590),
 ( 4, 17,  2,  990), ( 4, 19,  1, 2390),
 ( 5,  1, 15, 2990), ( 5,  3, 20, 1990), ( 5, 16,  4, 2690),
 ( 6,  6, 36,  780), ( 6,  7, 36,  810), ( 6, 14, 24,  790),
 ( 7, 10,  2, 1690), ( 7, 13,  1, 1890),
 ( 8,  2, 48, 2050), ( 8,  3, 48, 1650), ( 8, 15, 20, 1890), ( 8, 11, 30, 1050),
 ( 9,  4,  5, 4590), ( 9,  2,  8, 2490),
 (10,  8, 80,  270), (10, 18,  6, 3600), (10, 20, 12, 1190),
 (11, 15,  1, 2290), (11,  9,  1, 2590);
-- =====================================================================
--  03_desnormalizacion.sql
--  DESNORMALIZACION: columna derivada venta.total
--
--  En la fase Diseno la tabla Venta NO guardaba el total (era un dato
--  derivado de SUM(cantidad * precio_unit) en Detalle_Venta, y guardarlo
--  rompe la 3FN: total depende de las lineas de detalle, no de id_venta).
--
--  Justificacion para desnormalizar:
--   * Los reportes mas usados (ventas del dia, ventas por cliente,
--     por empleado y por tipo de cliente) solo necesitan el monto total
--     de cada venta. Sin la columna, cada reporte debe hacer JOIN con
--     Detalle_Venta y agrupar (GROUP BY) todas sus lineas.
--   * En temporada alta (otono-invierno, turistas) Detalle_Venta es la
--     tabla que mas crece (varias lineas por venta), por lo que evitar
--     ese JOIN + SUM acelera los reportes y la pantalla de caja.
--   * El total de una venta cerrada casi no cambia, por lo que el costo
--     de mantener la redundancia es bajo.
--
--  Control de la redundancia: tres triggers sobre Detalle_Venta
--  mantienen venta.total sincronizado ante INSERT, UPDATE y DELETE, y el
--  procedimiento sp_recalcular_totales (08) permite re-sincronizar en
--  forma masiva.
-- =====================================================================
USE la_mundial;

ALTER TABLE venta
    ADD COLUMN total INT NOT NULL DEFAULT 0 AFTER id_empleado;

-- Carga inicial del total a partir del detalle existente
UPDATE venta v
SET v.total = (SELECT COALESCE(SUM(d.cantidad * d.precio_unit), 0)
               FROM detalle_venta d
               WHERE d.id_venta = v.id_venta);

DROP TRIGGER IF EXISTS trg_detalle_ai;
DROP TRIGGER IF EXISTS trg_detalle_au;
DROP TRIGGER IF EXISTS trg_detalle_ad;

DELIMITER $$

CREATE TRIGGER trg_detalle_ai AFTER INSERT ON detalle_venta
FOR EACH ROW
BEGIN
    UPDATE venta
       SET total = total + NEW.cantidad * NEW.precio_unit
     WHERE id_venta = NEW.id_venta;
END$$

CREATE TRIGGER trg_detalle_au AFTER UPDATE ON detalle_venta
FOR EACH ROW
BEGIN
    UPDATE venta
       SET total = total - OLD.cantidad * OLD.precio_unit
     WHERE id_venta = OLD.id_venta;
    UPDATE venta
       SET total = total + NEW.cantidad * NEW.precio_unit
     WHERE id_venta = NEW.id_venta;
END$$

CREATE TRIGGER trg_detalle_ad AFTER DELETE ON detalle_venta
FOR EACH ROW
BEGIN
    UPDATE venta
       SET total = total - OLD.cantidad * OLD.precio_unit
     WHERE id_venta = OLD.id_venta;
END$$

DELIMITER ;

-- Comprobacion: total desnormalizado vs. total calculado (debe dar 0 filas)
SELECT v.id_venta, v.total, SUM(d.cantidad * d.precio_unit) AS total_calculado
FROM venta v
JOIN detalle_venta d ON d.id_venta = v.id_venta
GROUP BY v.id_venta, v.total
HAVING v.total <> SUM(d.cantidad * d.precio_unit);
-- =====================================================================
--  04_vistas.sql
--  VISTAS
-- =====================================================================
USE la_mundial;

-- ---------------------------------------------------------------------
-- Vista principal: v_stock_productos
--
-- Justificacion: el problema central del negocio era el "stock poco
-- confiable" y la lentitud de los vendedores para buscar productos.
-- Esta vista entrega, en una sola consulta simple, el catalogo unico
-- con su categoria, marca, proveedor, precios, unidades disponibles y
-- un indicador de reposicion. Asi:
--   * el vendedor no necesita conocer los 5 JOIN que hay detras;
--   * todas las pantallas (caja, bodega, reportes) leen la MISMA regla
--     de "bajo minimo", evitando criterios distintos por usuario;
--   * se puede otorgar permiso de lectura sobre la vista sin exponer
--     las tablas base (seguridad).
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_stock_productos AS
SELECT p.id_producto,
       p.sku,
       p.nombre                         AS producto,
       c.nombre                         AS categoria,
       m.nombre                         AS marca,
       pr.razon_social                  AS proveedor,
       p.precio_det,
       p.precio_may,
       s.cantidad,
       s.stock_min,
       s.fecha_act,
       CASE
           WHEN s.cantidad = 0              THEN 'SIN STOCK'
           WHEN s.cantidad < s.stock_min    THEN 'REPONER'
           ELSE 'OK'
       END                              AS estado_stock,
       GREATEST(s.stock_min - s.cantidad, 0) AS unidades_faltantes
FROM producto  p
JOIN categoria c  ON c.id_categoria  = p.id_categoria
JOIN marca     m  ON m.id_marca      = p.id_marca
JOIN proveedor pr ON pr.id_proveedor = p.id_proveedor
JOIN stock     s  ON s.id_producto   = p.id_producto;

-- ---------------------------------------------------------------------
-- Vista complementaria: v_resumen_ventas
--
-- Justificacion: encabezado de cada venta con nombres legibles (cliente,
-- tipo de cliente, empleado, numero de ticket) y su total (columna
-- desnormalizada). Es la base de los reportes de ventas diarias y de la
-- comparacion mayorista/minorista que pidio el negocio.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_resumen_ventas AS
SELECT v.id_venta,
       v.fecha,
       v.hora,
       t.numero                        AS numero_ticket,
       cl.rut                          AS rut_cliente,
       cl.nombre                       AS cliente,
       tc.nombre                       AS tipo_cliente,
       e.nombre                        AS empleado,
       (SELECT COUNT(*) FROM detalle_venta d WHERE d.id_venta = v.id_venta) AS lineas,
       v.total
FROM venta        v
JOIN ticket       t  ON t.id_ticket        = v.id_ticket
JOIN cliente      cl ON cl.id_cliente      = v.id_cliente
JOIN tipo_cliente tc ON tc.id_tipo_cliente = cl.id_tipo_cliente
JOIN empleado     e  ON e.id_empleado      = v.id_empleado;

-- Ejemplos de uso
SELECT producto, categoria, cantidad, stock_min, estado_stock
FROM v_stock_productos
WHERE estado_stock <> 'OK'
ORDER BY unidades_faltantes DESC;

SELECT * FROM v_resumen_ventas ORDER BY fecha, hora;
-- =====================================================================
--  05_indices.sql
--  INDICES SECUNDARIOS
--
--  Las PK, UNIQUE (llaves secundarias) y FK ya generan indices
--  automaticamente en InnoDB. Los siguientes indices son ADICIONALES y
--  responden a las consultas mas frecuentes del negocio.
-- =====================================================================
USE la_mundial;

-- ---------------------------------------------------------------------
-- 1) producto(nombre)
--    El reclamo principal de los vendedores era la lentitud al buscar
--    productos. En el meson se busca por nombre ("Trencito", "Costa"...),
--    no por id ni SKU. Sin indice, cada busqueda recorre toda la tabla
--    (full scan). Con el indice, una busqueda por prefijo
--    (nombre LIKE 'Chocolate%') o por igualdad usa un recorrido de rango.
-- ---------------------------------------------------------------------
CREATE INDEX idx_producto_nombre ON producto (nombre);

-- ---------------------------------------------------------------------
-- 2) venta(fecha, id_empleado)
--    Los reportes diarios/mensuales filtran ventas por rango de fechas
--    (ventas del dia, temporada otono-invierno) y frecuentemente las
--    agrupan por empleado. Venta es una de las tablas de mayor
--    crecimiento, por lo que este indice evita recorrerla completa.
-- ---------------------------------------------------------------------
CREATE INDEX idx_venta_fecha_empleado ON venta (fecha, id_empleado);

-- ---------------------------------------------------------------------
-- 3) ticket(fecha, numero)  - UNICO
--    El numero de atencion se reinicia cada dia; la combinacion
--    (fecha, numero) identifica al ticket en el meson y no debe repetirse.
--    El indice acelera la busqueda "ticket N de hoy" y ademas impide
--    emitir dos veces el mismo numero en un mismo dia.
-- ---------------------------------------------------------------------
CREATE UNIQUE INDEX idx_ticket_fecha_numero ON ticket (fecha, numero);

-- ---------------------------------------------------------------------
-- Verificacion: el optimizador usa los indices
-- (columna "key" del EXPLAIN)
-- ---------------------------------------------------------------------
EXPLAIN SELECT id_producto, nombre, precio_det
        FROM producto
        WHERE nombre LIKE 'Chocolate%';

EXPLAIN SELECT fecha, id_empleado, COUNT(*) AS ventas, SUM(total) AS monto
        FROM venta
        WHERE fecha BETWEEN '2026-11-10' AND '2026-11-11'
        GROUP BY fecha, id_empleado;

EXPLAIN SELECT id_ticket, estado
        FROM ticket
        WHERE fecha = '2026-11-12' AND numero = 4;

SHOW INDEX FROM producto;
-- =====================================================================
--  06_consultas.sql
--  CONSULTAS (queries) sobre la base de datos
-- =====================================================================
USE la_mundial;

-- Q1. Busqueda rapida de productos por nombre (usa idx_producto_nombre)
SELECT sku, producto, marca, precio_det, precio_may, cantidad, estado_stock
FROM v_stock_productos
WHERE producto LIKE 'Galletas%'
ORDER BY producto;

-- Q2. Productos que se deben reponer, agrupados por proveedor
SELECT proveedor, producto, cantidad, stock_min, unidades_faltantes
FROM v_stock_productos
WHERE estado_stock IN ('REPONER', 'SIN STOCK')
ORDER BY proveedor, unidades_faltantes DESC;

-- Q3. Ventas por dia (cantidad de ventas, monto total y ticket promedio)
SELECT fecha,
       COUNT(*)          AS n_ventas,
       SUM(total)        AS monto_total,
       ROUND(AVG(total)) AS ticket_promedio
FROM venta
GROUP BY fecha
ORDER BY fecha;

-- Q4. Ventas por tipo de cliente (mayorista vs. minorista vs. turista...)
SELECT tc.nombre      AS tipo_cliente,
       COUNT(v.id_venta) AS n_ventas,
       COALESCE(SUM(v.total), 0) AS monto_total
FROM tipo_cliente tc
LEFT JOIN cliente cl ON cl.id_tipo_cliente = tc.id_tipo_cliente
LEFT JOIN venta   v  ON v.id_cliente       = cl.id_cliente
GROUP BY tc.id_tipo_cliente, tc.nombre
ORDER BY monto_total DESC;

-- Q5. Top 5 productos mas vendidos (unidades e ingresos)
SELECT p.sku, p.nombre AS producto,
       SUM(d.cantidad)                 AS unidades,
       SUM(d.cantidad * d.precio_unit) AS ingresos
FROM detalle_venta d
JOIN producto p ON p.id_producto = d.id_producto
GROUP BY p.id_producto, p.sku, p.nombre
ORDER BY unidades DESC
LIMIT 5;

-- Q6. Ingresos por categoria y participacion porcentual
SELECT c.nombre AS categoria,
       SUM(d.cantidad * d.precio_unit) AS ingresos,
       ROUND(100 * SUM(d.cantidad * d.precio_unit)
             / (SELECT SUM(cantidad * precio_unit) FROM detalle_venta), 1) AS pct
FROM detalle_venta d
JOIN producto  p ON p.id_producto  = d.id_producto
JOIN categoria c ON c.id_categoria = p.id_categoria
GROUP BY c.id_categoria, c.nombre
ORDER BY ingresos DESC;

-- Q7. Ranking de empleados por monto vendido
SELECT e.nombre, e.cargo,
       COUNT(v.id_venta)         AS n_ventas,
       COALESCE(SUM(v.total), 0) AS monto_vendido
FROM empleado e
LEFT JOIN venta v ON v.id_empleado = e.id_empleado
GROUP BY e.id_empleado, e.nombre, e.cargo
ORDER BY monto_vendido DESC;

-- Q8. Detalle completo (boleta) de una venta
SELECT v.id_venta, v.fecha, v.hora, cl.nombre AS cliente,
       p.nombre AS producto, d.cantidad, d.precio_unit,
       d.cantidad * d.precio_unit AS subtotal
FROM venta v
JOIN cliente       cl ON cl.id_cliente  = v.id_cliente
JOIN detalle_venta d  ON d.id_venta     = v.id_venta
JOIN producto      p  ON p.id_producto  = d.id_producto
WHERE v.id_venta = 2;

-- Q9. Clientes que compraron sobre el promedio de compra (subconsulta)
SELECT cl.rut, cl.nombre, tc.nombre AS tipo, SUM(v.total) AS total_comprado
FROM cliente cl
JOIN tipo_cliente tc ON tc.id_tipo_cliente = cl.id_tipo_cliente
JOIN venta v         ON v.id_cliente       = cl.id_cliente
GROUP BY cl.id_cliente, cl.rut, cl.nombre, tc.nombre
HAVING SUM(v.total) > (SELECT AVG(total) FROM venta)
ORDER BY total_comprado DESC;

-- Q10. Estado de los tickets por dia (atendidos, anulados y pendientes)
SELECT fecha,
       SUM(estado = 'atendido') AS atendidos,
       SUM(estado = 'anulado')  AS anulados,
       SUM(estado = 'emitido')  AS pendientes,
       COUNT(*)                 AS total_tickets
FROM ticket
GROUP BY fecha
ORDER BY fecha;

-- Q11. Productos que nunca se han vendido (NOT EXISTS)
SELECT p.sku, p.nombre
FROM producto p
WHERE NOT EXISTS (SELECT 1 FROM detalle_venta d WHERE d.id_producto = p.id_producto);

-- Q12. Margen por venta al por mayor: ahorro que obtienen mayoristas
--      y distribuidores respecto del precio al detalle
SELECT cl.nombre AS cliente,
       SUM(d.cantidad * p.precio_det)              AS valor_a_precio_detalle,
       SUM(d.cantidad * d.precio_unit)             AS valor_pagado,
       SUM(d.cantidad * (p.precio_det - d.precio_unit)) AS ahorro
FROM venta v
JOIN cliente       cl ON cl.id_cliente      = v.id_cliente
JOIN tipo_cliente  tc ON tc.id_tipo_cliente = cl.id_tipo_cliente
JOIN detalle_venta d  ON d.id_venta         = v.id_venta
JOIN producto      p  ON p.id_producto      = d.id_producto
WHERE tc.aplica_precio_may = 1
GROUP BY cl.id_cliente, cl.nombre
ORDER BY ahorro DESC;
-- =====================================================================
--  07_actualizaciones.sql
--  ACTUALIZACION DE DATOS: INSERT, UPDATE y DELETE
-- =====================================================================
USE la_mundial;

-- ---------------------------------------------------------------------
-- INSERT
-- ---------------------------------------------------------------------
-- 1) Nuevo producto en el catalogo unico + su registro de stock (1:1)
INSERT INTO producto (sku, nombre, precio_det, precio_may, id_categoria, id_marca, id_proveedor)
VALUES ('7802800000035', 'Chocolate Sahne-Nuss Blanco 160 g', 2990, 2490, 1, 1, 1);

INSERT INTO stock (id_producto, cantidad, stock_min, fecha_act)
VALUES (LAST_INSERT_ID(), 100, 40, CURDATE());

-- 2) Nuevo cliente mayorista
INSERT INTO cliente (rut, nombre, telefono, id_tipo_cliente)
VALUES ('76111222-3', 'Kiosco El Paseo SpA', '229998877',
        (SELECT id_tipo_cliente FROM tipo_cliente WHERE nombre = 'Mayorista'));

-- 3) Intento de insertar un producto DUPLICADO (mismo SKU):
--    la llave secundaria UNIQUE(sku) lo rechaza -> soluciona la
--    "redundancia" del sistema antiguo. (Descomentar para probar.)
-- INSERT INTO producto (sku, nombre, precio_det, precio_may, id_categoria, id_marca, id_proveedor)
-- VALUES ('7802800000011', 'chocolate sahne nuss', 2990, 2490, 1, 1, 1);
--   -> ERROR 1062: Duplicate entry '7802800000011' for key 'uk_producto_sku'

-- ---------------------------------------------------------------------
-- UPDATE
-- ---------------------------------------------------------------------
-- 4) Cambio de precio de un producto puntual
UPDATE producto
   SET precio_det = 2090, precio_may = 1750
 WHERE sku = '7802215000015';          -- Chocolate Costa Rama Leche

-- 5) Ingreso de mercaderia: suma unidades al stock de un producto
UPDATE stock s
JOIN producto p ON p.id_producto = s.id_producto
   SET s.cantidad = s.cantidad + 120,
       s.fecha_act = CURDATE()
 WHERE p.sku = '7802215000015';

-- 6) Actualizacion de datos de contacto de un proveedor
UPDATE proveedor
   SET telefono = '226005500', email = 'ventas@snackmarket.cl'
 WHERE rut = '76567890-1';

-- 7) Corregir la cantidad de una linea de venta.
--    El trigger trg_detalle_au recalcula automaticamente venta.total.
SELECT id_venta, total FROM venta WHERE id_venta = 1;           -- antes
UPDATE detalle_venta SET cantidad = 4
 WHERE id_venta = 1 AND id_producto = 5;
SELECT id_venta, total FROM venta WHERE id_venta = 1;           -- despues

-- ---------------------------------------------------------------------
-- DELETE
-- ---------------------------------------------------------------------
-- 8) Eliminar una linea de detalle (trigger trg_detalle_ad descuenta el total)
DELETE FROM detalle_venta
 WHERE id_venta = 11 AND id_producto = 9;

-- 9) Eliminar un cliente que no tiene ventas asociadas
INSERT INTO cliente (rut, nombre, telefono, id_tipo_cliente)
VALUES ('11111111-1', 'Cliente de prueba', NULL, 1);
DELETE FROM cliente
 WHERE rut = '11111111-1'
   AND NOT EXISTS (SELECT 1 FROM venta v WHERE v.id_cliente = cliente.id_cliente);

-- 10) Integridad referencial: NO se puede eliminar una marca con productos
--     (Descomentar para probar.)
-- DELETE FROM marca WHERE nombre = 'Nestle';
--   -> ERROR 1451: Cannot delete or update a parent row: a foreign key constraint fails

-- ---------------------------------------------------------------------
-- Transaccion con ROLLBACK: los cambios se deshacen
-- ---------------------------------------------------------------------
START TRANSACTION;
    UPDATE stock SET cantidad = 0 WHERE id_producto = 1;
    SELECT id_producto, cantidad FROM stock WHERE id_producto = 1;   -- 0
ROLLBACK;
SELECT id_producto, cantidad FROM stock WHERE id_producto = 1;       -- valor original
-- =====================================================================
--  08_procesamiento_masivo.sql
--  PROCESAMIENTO MASIVO mediante procedimientos almacenados
--  (SQL procedural de MySQL, equivalente a PL/SQL / T-SQL).
--
--  Todos los procesos que modifican varias tablas se ejecutan dentro de
--  una TRANSACCION: si cualquier paso falla se hace ROLLBACK y la base
--  queda como estaba (atomicidad).
--
--  Rutinas:
--   fn_precio_cliente      precio que corresponde a un cliente
--   sp_emitir_ticket       entrega el siguiente numero de atencion del dia
--   sp_registrar_venta     venta completa: detalle + descuento de stock
--   sp_reajuste_precios    reajuste masivo de precios con auditoria (cursor)
--   sp_reposicion_masiva   repone todos los productos bajo el minimo
--   sp_cierre_dia          anula tickets no atendidos al cierre
--   sp_recalcular_totales  re-sincroniza la columna desnormalizada
--   sp_generar_ventas_simuladas  carga masiva de N ventas (temporada alta)
-- =====================================================================
USE la_mundial;

DROP FUNCTION  IF EXISTS fn_precio_cliente;
DROP PROCEDURE IF EXISTS sp_emitir_ticket;
DROP PROCEDURE IF EXISTS sp_registrar_venta;
DROP PROCEDURE IF EXISTS sp_reajuste_precios;
DROP PROCEDURE IF EXISTS sp_reposicion_masiva;
DROP PROCEDURE IF EXISTS sp_cierre_dia;
DROP PROCEDURE IF EXISTS sp_recalcular_totales;
DROP PROCEDURE IF EXISTS sp_generar_ventas_simuladas;

DELIMITER $$

-- ---------------------------------------------------------------------
-- Precio que paga un cliente: mayor o detalle segun su tipo
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_precio_cliente(p_id_producto INT, p_id_cliente INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_precio INT;
    SELECT CASE WHEN tc.aplica_precio_may = 1 THEN p.precio_may
                ELSE p.precio_det END
      INTO v_precio
      FROM producto p, cliente c
      JOIN tipo_cliente tc ON tc.id_tipo_cliente = c.id_tipo_cliente
     WHERE p.id_producto = p_id_producto
       AND c.id_cliente  = p_id_cliente;
    RETURN v_precio;
END$$

-- ---------------------------------------------------------------------
-- Emite el siguiente ticket de atencion del dia (numero se reinicia
-- diariamente). p_fecha NULL = hoy.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_emitir_ticket(IN  p_fecha     DATE,
                                  OUT p_id_ticket INT,
                                  OUT p_numero    INT)
BEGIN
    DECLARE v_fecha DATE;
    SET v_fecha = COALESCE(p_fecha, CURDATE());

    SELECT COALESCE(MAX(numero), 0) + 1 INTO p_numero
      FROM ticket WHERE fecha = v_fecha;

    INSERT INTO ticket (numero, fecha, hora, estado)
    VALUES (p_numero, v_fecha, CURTIME(), 'emitido');

    SET p_id_ticket = LAST_INSERT_ID();
END$$

-- ---------------------------------------------------------------------
-- Registra una venta completa en UNA transaccion.
--   p_items: lista 'id_producto:cantidad,id_producto:cantidad,...'
--   Por cada item: bloquea la fila de stock (FOR UPDATE), valida que
--   haya unidades, inserta la linea con el precio segun tipo de cliente
--   y descuenta el stock. Al final marca el ticket como atendido.
--   Si algo falla (sin stock, ticket invalido, etc.) -> ROLLBACK total.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_registrar_venta(IN  p_id_ticket   INT,
                                    IN  p_id_cliente  INT,
                                    IN  p_id_empleado INT,
                                    IN  p_items       VARCHAR(2000),
                                    OUT p_id_venta    INT)
BEGIN
    DECLARE v_lista   VARCHAR(2010);
    DECLARE v_par     VARCHAR(50);
    DECLARE v_prod    INT;
    DECLARE v_cant    INT;
    DECLARE v_disp    INT;
    DECLARE v_estado  VARCHAR(15);
    DECLARE v_fecha_t DATE;
    DECLARE v_hora_t  TIME;
    DECLARE v_lineas  INT DEFAULT 0;
    DECLARE v_msg     VARCHAR(200);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- 1. Validar ticket
    SELECT estado, fecha, hora INTO v_estado, v_fecha_t, v_hora_t
      FROM ticket WHERE id_ticket = p_id_ticket FOR UPDATE;
    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El ticket no existe';
    ELSEIF v_estado <> 'emitido' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El ticket ya fue atendido o anulado';
    END IF;

    -- 2. Encabezado de la venta
    INSERT INTO venta (fecha, hora, id_ticket, id_cliente, id_empleado, total)
    VALUES (v_fecha_t,
            IF(v_fecha_t = CURDATE(), CURTIME(), ADDTIME(v_hora_t, '00:05:00')),
            p_id_ticket, p_id_cliente, p_id_empleado, 0);
    SET p_id_venta = LAST_INSERT_ID();

    -- 3. Recorrer los items
    SET v_lista = CONCAT(p_items, ',');
    WHILE LOCATE(',', v_lista) > 0 DO
        SET v_par   = TRIM(SUBSTRING_INDEX(v_lista, ',', 1));
        SET v_lista = SUBSTRING(v_lista, LOCATE(',', v_lista) + 1);

        IF v_par <> '' THEN
            SET v_prod = CAST(SUBSTRING_INDEX(v_par, ':', 1)  AS UNSIGNED);
            SET v_cant = CAST(SUBSTRING_INDEX(v_par, ':', -1) AS UNSIGNED);
            SET v_disp = NULL;

            IF v_cant IS NULL OR v_cant <= 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cantidad invalida en la lista de items';
            END IF;

            SELECT cantidad INTO v_disp
              FROM stock WHERE id_producto = v_prod FOR UPDATE;

            IF v_disp IS NULL THEN
                SET v_msg = CONCAT('Producto ', v_prod, ' no existe');
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
            ELSEIF v_disp < v_cant THEN
                SET v_msg = CONCAT('Stock insuficiente para producto ', v_prod,
                                   ' (disponible ', v_disp, ', solicitado ', v_cant, ')');
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
            END IF;

            INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unit)
            VALUES (p_id_venta, v_prod, v_cant, fn_precio_cliente(v_prod, p_id_cliente));

            UPDATE stock
               SET cantidad = cantidad - v_cant, fecha_act = CURDATE()
             WHERE id_producto = v_prod;

            SET v_lineas = v_lineas + 1;
        END IF;
    END WHILE;

    IF v_lineas = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta no tiene productos';
    END IF;

    -- 4. Cerrar el ticket
    UPDATE ticket SET estado = 'atendido' WHERE id_ticket = p_id_ticket;

    COMMIT;
END$$

-- ---------------------------------------------------------------------
-- Reajuste MASIVO de precios por categoria (o de todo el catalogo si
-- p_id_categoria es NULL). Usa un CURSOR para recorrer los productos,
-- deja registro de cada cambio en historial_precio y redondea a la
-- decena de pesos. Todo en una transaccion.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_reajuste_precios(IN  p_id_categoria INT,
                                     IN  p_porcentaje   DECIMAL(5,2),
                                     IN  p_motivo       VARCHAR(100),
                                     OUT p_actualizados INT)
BEGIN
    DECLARE v_fin     INT DEFAULT 0;
    DECLARE v_id      INT;
    DECLARE v_det     INT;
    DECLARE v_may     INT;
    DECLARE v_det_new INT;
    DECLARE v_may_new INT;

    DECLARE cur_productos CURSOR FOR
        SELECT id_producto, precio_det, precio_may
          FROM producto
         WHERE p_id_categoria IS NULL OR id_categoria = p_id_categoria
         FOR UPDATE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_porcentaje IS NULL OR p_porcentaje <= -50 OR p_porcentaje > 100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Porcentaje fuera de rango (-50, 100]';
    END IF;

    SET p_actualizados = 0;
    START TRANSACTION;
    OPEN cur_productos;
    leer: LOOP
        FETCH cur_productos INTO v_id, v_det, v_may;
        IF v_fin = 1 THEN LEAVE leer; END IF;

        SET v_det_new = GREATEST(10, ROUND(v_det * (1 + p_porcentaje / 100) / 10) * 10);
        SET v_may_new = LEAST(v_det_new,
                              GREATEST(10, ROUND(v_may * (1 + p_porcentaje / 100) / 10) * 10));

        INSERT INTO historial_precio (id_producto, precio_det_ant, precio_det_nuevo,
                                      precio_may_ant, precio_may_nuevo, fecha_cambio, motivo)
        VALUES (v_id, v_det, v_det_new, v_may, v_may_new, NOW(),
                COALESCE(p_motivo, 'Reajuste masivo'));

        UPDATE producto
           SET precio_det = v_det_new, precio_may = v_may_new
         WHERE id_producto = v_id;

        SET p_actualizados = p_actualizados + 1;
    END LOOP;
    CLOSE cur_productos;
    COMMIT;
END$$

-- ---------------------------------------------------------------------
-- Reposicion masiva: todo producto bajo su stock minimo se repone hasta
-- p_factor veces el minimo (orden de compra automatica).
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_reposicion_masiva(IN  p_factor    INT,
                                      OUT p_productos INT,
                                      OUT p_unidades  INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_factor IS NULL OR p_factor < 1 THEN
        SET p_factor = 2;
    END IF;

    START TRANSACTION;
    SELECT COUNT(*), COALESCE(SUM(stock_min * p_factor - cantidad), 0)
      INTO p_productos, p_unidades
      FROM stock
     WHERE cantidad < stock_min;

    UPDATE stock
       SET cantidad  = stock_min * p_factor,
           fecha_act = CURDATE()
     WHERE cantidad < stock_min;
    COMMIT;
END$$

-- ---------------------------------------------------------------------
-- Cierre del dia: anula todos los tickets que quedaron emitidos (sin
-- atender) hasta la fecha indicada.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_cierre_dia(IN p_fecha DATE, OUT p_anulados INT)
BEGIN
    START TRANSACTION;
    UPDATE ticket
       SET estado = 'anulado'
     WHERE estado = 'emitido'
       AND fecha <= COALESCE(p_fecha, CURDATE());
    SET p_anulados = ROW_COUNT();
    COMMIT;
END$$

-- ---------------------------------------------------------------------
-- Re-sincroniza la columna desnormalizada venta.total con el detalle.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_recalcular_totales(OUT p_corregidas INT)
BEGIN
    START TRANSACTION;
    UPDATE venta v
      LEFT JOIN (SELECT id_venta, SUM(cantidad * precio_unit) AS t
                   FROM detalle_venta GROUP BY id_venta) d
             ON d.id_venta = v.id_venta
       SET v.total = COALESCE(d.t, 0)
     WHERE v.total <> COALESCE(d.t, 0);
    SET p_corregidas = ROW_COUNT();
    COMMIT;
END$$

-- ---------------------------------------------------------------------
-- Carga masiva: genera p_cantidad ventas aleatorias distribuidas en los
-- ultimos p_dias dias (simula la temporada alta de turistas). Cada venta
-- pasa por sp_registrar_venta, por lo que respeta stock, precios por
-- tipo de cliente y triggers. Sirve para probar rendimiento e indices.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_generar_ventas_simuladas(IN  p_cantidad INT,
                                             IN  p_dias     INT,
                                             OUT p_creadas  INT)
BEGIN
    DECLARE i           INT DEFAULT 0;
    DECLARE j           INT;
    DECLARE v_items     VARCHAR(2000);
    DECLARE v_n_items   INT;
    DECLARE v_prod      INT;
    DECLARE v_cant      INT;
    DECLARE v_cliente   INT;
    DECLARE v_empleado  INT;
    DECLARE v_fecha     DATE;
    DECLARE v_ticket    INT;
    DECLARE v_numero    INT;
    DECLARE v_venta     INT;
    DECLARE v_x         INT;
    DECLARE v_y         INT;

    SET p_creadas = 0;
    SET p_dias = GREATEST(COALESCE(p_dias, 30), 1);
    WHILE i < p_cantidad DO
        -- cada 25 ventas se repone lo que quedo bajo el minimo
        IF MOD(i, 25) = 0 THEN
            CALL sp_reposicion_masiva(5, v_x, v_y);
        END IF;

        SET v_fecha = DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * p_dias) DAY);
        SELECT id_cliente  INTO v_cliente  FROM cliente  ORDER BY RAND() LIMIT 1;
        SELECT id_empleado INTO v_empleado FROM empleado ORDER BY RAND() LIMIT 1;

        -- arma entre 1 y 4 items con productos que tengan stock suficiente
        SET v_items = '';
        SET v_n_items = 1 + FLOOR(RAND() * 4);
        SET j = 0;
        WHILE j < v_n_items DO
            SET v_cant = 1 + FLOOR(RAND() * 6);
            SET v_prod = NULL;
            SELECT id_producto INTO v_prod
              FROM stock WHERE cantidad >= v_cant * 4
             ORDER BY RAND() LIMIT 1;
            IF v_prod IS NOT NULL
               AND FIND_IN_SET(CONCAT(v_prod, ':', v_cant), v_items) = 0 THEN
                SET v_items = CONCAT(v_items, IF(v_items = '', '', ','), v_prod, ':', v_cant);
            END IF;
            SET j = j + 1;
        END WHILE;

        IF v_items <> '' THEN
            CALL sp_emitir_ticket(v_fecha, v_ticket, v_numero);
            UPDATE ticket SET hora = SEC_TO_TIME(9 * 3600 + FLOOR(RAND() * 9 * 3600))
             WHERE id_ticket = v_ticket;
            CALL sp_registrar_venta(v_ticket, v_cliente, v_empleado, v_items, v_venta);
            SET p_creadas = p_creadas + 1;
        END IF;

        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

-- =====================================================================
-- Ejemplos de ejecucion
-- =====================================================================

-- a) Emitir ticket y registrar una venta de un turista (precio detalle)
CALL sp_emitir_ticket(NULL, @ticket, @num);
SELECT @ticket AS id_ticket, @num AS numero_atencion;
CALL sp_registrar_venta(@ticket, 6, 1, '1:6,2:6,16:2', @venta);
SELECT * FROM v_resumen_ventas WHERE id_venta = @venta;

-- b) Venta que FALLA por falta de stock -> ROLLBACK (no queda nada a medias)
CALL sp_emitir_ticket(NULL, @ticket2, @num2);
-- CALL sp_registrar_venta(@ticket2, 4, 2, '5:10,16:9999', @venta2);
--   -> ERROR 1644: Stock insuficiente para producto 16 (...)

-- c) Reajuste de 5% a los Chocolates por alza del proveedor
CALL sp_reajuste_precios(1, 5.00, 'Alza proveedor chocolates', @n);
SELECT @n AS productos_reajustados;
SELECT * FROM historial_precio ORDER BY id_historial DESC LIMIT 5;

-- d) Reposicion automatica de todo lo que esta bajo el minimo
CALL sp_reposicion_masiva(3, @prods, @unid);
SELECT @prods AS productos_repuestos, @unid AS unidades_pedidas;

-- e) Cierre del dia: anula tickets pendientes
CALL sp_cierre_dia(CURDATE(), @anulados);
SELECT @anulados AS tickets_anulados;

-- f) Control de la desnormalizacion
CALL sp_recalcular_totales(@corr);
SELECT @corr AS ventas_corregidas;

-- g) Carga masiva de prueba (descomentar; ej.: 2000 ventas en 120 dias)
-- CALL sp_generar_ventas_simuladas(2000, 120, @creadas);
-- SELECT @creadas;
