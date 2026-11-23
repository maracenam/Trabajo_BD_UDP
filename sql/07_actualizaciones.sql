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
-- DELETE FROM marca WHERE nombre = 'Nestlé';
--   -> ERROR 1451: Cannot delete or update a parent row: a foreign key constraint fails

-- ---------------------------------------------------------------------
-- Transaccion con ROLLBACK: los cambios se deshacen
-- ---------------------------------------------------------------------
START TRANSACTION;
    UPDATE stock SET cantidad = 0 WHERE id_producto = 1;
    SELECT id_producto, cantidad FROM stock WHERE id_producto = 1;   -- 0
ROLLBACK;
SELECT id_producto, cantidad FROM stock WHERE id_producto = 1;       -- valor original
