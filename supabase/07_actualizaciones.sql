-- =====================================================================
--  07_actualizaciones.sql  (PostgreSQL / Supabase)
--  INSERT, UPDATE y DELETE
-- =====================================================================

-- INSERT 1) producto + su stock (1:1) en una sola sentencia (CTE + RETURNING)
WITH nuevo AS (
    INSERT INTO producto (sku, nombre, precio_det, precio_may, id_categoria, id_marca, id_proveedor)
    VALUES ('7802800000035', 'Chocolate Sahne-Nuss Blanco 160 g', 2990, 2490, 1, 1, 1)
    RETURNING id_producto
)
INSERT INTO stock (id_producto, cantidad, stock_min, fecha_act)
SELECT id_producto, 100, 40, fn_hoy() FROM nuevo;

-- INSERT 2) cliente mayorista
INSERT INTO cliente (rut, nombre, telefono, id_tipo_cliente)
VALUES ('76111222-3', 'Kiosco El Paseo SpA', '229998877',
        (SELECT id_tipo_cliente FROM tipo_cliente WHERE nombre = 'Mayorista'));

-- INSERT 3) SKU duplicado -> rechazado por la llave secundaria (descomentar)
-- INSERT INTO producto (sku, nombre, precio_det, precio_may, id_categoria, id_marca, id_proveedor)
-- VALUES ('7802800000011', 'chocolate sahne nuss', 2990, 2490, 1, 1, 1);
--   -> ERROR: duplicate key value violates unique constraint "uk_producto_sku"

-- UPDATE 4) precio puntual
UPDATE producto SET precio_det = 2090, precio_may = 1750 WHERE sku = '7802215000015';

-- UPDATE 5) ingreso de mercaderia (UPDATE ... FROM)
UPDATE stock s SET cantidad = s.cantidad + 120, fecha_act = fn_hoy()
  FROM producto p
 WHERE p.id_producto = s.id_producto AND p.sku = '7802215000015';

-- UPDATE 6) datos de contacto de un proveedor
UPDATE proveedor SET telefono = '226005500', email = 'ventas@snackmarket.cl'
 WHERE rut = '76567890-1';

-- UPDATE 7) corregir una linea: el trigger recalcula venta.total
SELECT id_venta, total FROM venta WHERE id_venta = 1;
UPDATE detalle_venta SET cantidad = 4 WHERE id_venta = 1 AND id_producto = 5;
SELECT id_venta, total FROM venta WHERE id_venta = 1;

-- DELETE 8) linea de detalle (el trigger descuenta el total)
DELETE FROM detalle_venta WHERE id_venta = 11 AND id_producto = 9;

-- DELETE 9) cliente sin ventas
INSERT INTO cliente (rut, nombre, id_tipo_cliente) VALUES ('11111111-1', 'Cliente de prueba', 1);
DELETE FROM cliente c
 WHERE c.rut = '11111111-1'
   AND NOT EXISTS (SELECT 1 FROM venta v WHERE v.id_cliente = c.id_cliente);

-- DELETE 10) integridad referencial (descomentar)
-- DELETE FROM marca WHERE nombre = 'Nestle';
--   -> ERROR: update or delete on table "marca" violates foreign key constraint

-- Transaccion con ROLLBACK (ejecutar en psql o en el SQL Editor por bloques)
BEGIN;
    UPDATE stock SET cantidad = 0 WHERE id_producto = 1;
ROLLBACK;
SELECT id_producto, cantidad FROM stock WHERE id_producto = 1;
