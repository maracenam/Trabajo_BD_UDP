-- =====================================================================
--  02_datos.sql  (PostgreSQL / Supabase)
--  Datos de prueba (todas las tablas con 4 tuplas o mas).
-- =====================================================================

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
 ('Minorista',    false),
 ('Mayorista',    true),
 ('Turista',      false),
 ('Distribuidor', true);

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
