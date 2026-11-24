-- =====================================================================
--  demo.sql  (Supabase / PostgreSQL)
--  Consultas para la demostración, en el orden del recorrido.
--  En el SQL Editor de Supabase: SELECCIONAR el bloque de cada paso y
--  presionar Ctrl+Enter (ejecuta solo lo seleccionado).
-- =====================================================================

-- ---------------------------------------------------------------------
-- PASO 1 · Sistema funcionando: las 12 tablas y sus tuplas
-- ---------------------------------------------------------------------
SELECT 'categoria' AS tabla, COUNT(*) AS tuplas FROM categoria UNION ALL
SELECT 'marca', COUNT(*) FROM marca UNION ALL
SELECT 'proveedor', COUNT(*) FROM proveedor UNION ALL
SELECT 'producto', COUNT(*) FROM producto UNION ALL
SELECT 'stock', COUNT(*) FROM stock UNION ALL
SELECT 'tipo_cliente', COUNT(*) FROM tipo_cliente UNION ALL
SELECT 'cliente', COUNT(*) FROM cliente UNION ALL
SELECT 'empleado', COUNT(*) FROM empleado UNION ALL
SELECT 'ticket', COUNT(*) FROM ticket UNION ALL
SELECT 'venta', COUNT(*) FROM venta UNION ALL
SELECT 'detalle_venta', COUNT(*) FROM detalle_venta UNION ALL
SELECT 'historial_precio', COUNT(*) FROM historial_precio;

-- ---------------------------------------------------------------------
-- PASO 3 · Vista: el stock real en una sola consulta
-- ---------------------------------------------------------------------
SELECT producto, categoria, cantidad, stock_min, estado_stock
FROM v_stock_productos
ORDER BY unidades_faltantes DESC, producto;

-- ---------------------------------------------------------------------
-- PASO 4 · Desnormalización: total guardado vs. total calculado
--          (ejecutar ANTES y DESPUÉS de registrar la venta en la app)
-- ---------------------------------------------------------------------
SELECT v.id_venta, v.total AS total_guardado,
       SUM(d.cantidad * d.precio_unit) AS total_calculado
FROM venta v JOIN detalle_venta d ON d.id_venta = v.id_venta
GROUP BY v.id_venta, v.total
ORDER BY v.id_venta DESC
LIMIT 5;

-- ---------------------------------------------------------------------
-- PASO 6 · Procesamiento masivo: reajuste de precios (cada bloque por separado)
-- ---------------------------------------------------------------------
-- 6a. Precios de los chocolates ANTES del reajuste
SELECT producto, precio_det, precio_may
FROM v_stock_productos
WHERE categoria = 'Chocolates'
ORDER BY producto;

-- 6b. Reajuste masivo: +5% a toda la categoría Chocolates (id 1).
--     Recorre los productos con un cursor, redondea a la decena y deja auditoría.
SELECT sp_reajuste_precios(1, 5, 'Alza proveedor chocolates') AS productos_reajustados;

-- 6c. Precios DESPUÉS: todos subieron 5%
SELECT producto, precio_det, precio_may
FROM v_stock_productos
WHERE categoria = 'Chocolates'
ORDER BY producto;

-- 6d. Auditoría: una fila por cada producto reajustado
SELECT nombre AS producto, precio_det_ant, precio_det_nuevo, precio_may_ant, precio_may_nuevo,
       to_char(fecha_cambio AT TIME ZONE 'America/Santiago', 'DD-MM-YYYY HH24:MI') AS fecha, motivo
FROM v_historial_precio
ORDER BY id_historial DESC
LIMIT 5;

-- 6e. Reajuste inválido (500%): da ERROR (es lo esperado) y no cambia ningún precio
SELECT sp_reajuste_precios(1, 500, 'Prueba de error');

-- 6f. Venta con más unidades que el stock: da ERROR y la transacción se deshace completa
SELECT COUNT(*) AS ventas_antes FROM venta;
SELECT sp_registrar_venta((SELECT id_ticket FROM sp_emitir_ticket()), 4, 2, '5:10,16:99999');
SELECT COUNT(*) AS ventas_despues FROM venta;

-- ---------------------------------------------------------------------
-- PASO 7 · Índices secundarios
-- ---------------------------------------------------------------------
-- 7.0 Carga masiva de 2.000 ventas (temporada alta), para que el efecto del índice se note
SELECT sp_generar_ventas_simuladas(2000, 120) AS ventas_creadas;
SELECT sp_recalcular_totales() AS ventas_con_diferencias;   -- debe dar 0

-- 7a. Los 3 índices secundarios
SELECT tablename AS tabla, indexname AS indice, indexdef AS definicion
FROM pg_indexes
WHERE indexname IN ('idx_producto_nombre', 'idx_venta_fecha_empleado', 'idx_ticket_fecha_numero');

-- 7b. Con el índice: "Index Scan" o "Bitmap Index Scan" on idx_venta_fecha_empleado
EXPLAIN SELECT fecha, id_empleado, COUNT(*) AS ventas, SUM(total) AS monto
FROM venta
WHERE fecha BETWEEN fn_hoy() - 7 AND fn_hoy()
GROUP BY fecha, id_empleado;

-- 7c. Sin poder usar índices: "Seq Scan" (recorre toda la tabla)
SET enable_indexscan = off;
SET enable_bitmapscan = off;
EXPLAIN SELECT fecha, id_empleado, COUNT(*) AS ventas, SUM(total) AS monto
FROM venta
WHERE fecha BETWEEN fn_hoy() - 7 AND fn_hoy()
GROUP BY fecha, id_empleado;

-- 7d. Volver a la normalidad (ejecutar siempre después de 7c)
RESET enable_indexscan;
RESET enable_bitmapscan;

-- 7e. Ticket del día: "Index Scan using idx_ticket_fecha_numero"
EXPLAIN SELECT id_ticket, estado FROM ticket WHERE fecha = fn_hoy() AND numero = 1;

-- ---------------------------------------------------------------------
-- PASO 8 · Consultas de negocio (más ejemplos en 06_consultas.sql)
-- ---------------------------------------------------------------------
-- 8a. Ventas por tipo de cliente
SELECT tc.nombre AS tipo_cliente, COUNT(v.id_venta) AS ventas, COALESCE(SUM(v.total), 0) AS monto
FROM tipo_cliente tc
LEFT JOIN cliente cl ON cl.id_tipo_cliente = tc.id_tipo_cliente
LEFT JOIN venta v    ON v.id_cliente = cl.id_cliente
GROUP BY tc.id_tipo_cliente, tc.nombre
ORDER BY monto DESC;

-- 8b. Clientes que compran sobre el promedio (subconsulta)
SELECT cl.nombre, SUM(v.total) AS total_comprado
FROM cliente cl JOIN venta v ON v.id_cliente = cl.id_cliente
GROUP BY cl.id_cliente, cl.nombre
HAVING SUM(v.total) > (SELECT AVG(total) FROM venta)
ORDER BY total_comprado DESC;

-- 8c. Top 5 productos más vendidos
SELECT p.nombre AS producto, SUM(d.cantidad) AS unidades, SUM(d.cantidad * d.precio_unit) AS ingresos
FROM detalle_venta d JOIN producto p ON p.id_producto = d.id_producto
GROUP BY p.id_producto, p.nombre
ORDER BY unidades DESC
LIMIT 5;

-- ---------------------------------------------------------------------
-- PASO 9 · Integridad (cada uno da ERROR: es lo esperado)
-- ---------------------------------------------------------------------
-- 9a. SKU duplicado -> viola la llave secundaria uk_producto_sku
INSERT INTO producto (sku, nombre, precio_det, precio_may, id_categoria, id_marca, id_proveedor)
VALUES ('7802800000011', 'chocolate sahne nuss', 2990, 2490, 1, 1, 1);

-- 9b. Marca con productos -> viola la llave foránea fk_producto_marca
DELETE FROM marca WHERE nombre = 'Nestlé';

-- ---------------------------------------------------------------------
-- AL TERMINAR · Dejar la base como al inicio (equivale a reiniciar.sql)
-- ---------------------------------------------------------------------
SELECT * FROM sp_reiniciar_demo();
