-- =====================================================================
--  demo.sql  -  Consultas para la demostración, en el orden del recorrido.
--  En MySQL Workbench: poner el cursor en cada bloque y ejecutar con
--  Ctrl+Enter (solo la sentencia actual).
-- =====================================================================
USE la_mundial;
SET NAMES utf8mb4;

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
-- PASO 6 · Procesamiento masivo: carga de 2.000 ventas (temporada alta)
-- ---------------------------------------------------------------------
CALL sp_generar_ventas_simuladas(2000, 120, @creadas);
SELECT @creadas AS ventas_creadas, (SELECT COUNT(*) FROM venta) AS ventas_totales;

-- Control de la desnormalización después de la carga (debe dar 0)
CALL sp_recalcular_totales(@corregidas);
SELECT @corregidas AS ventas_con_diferencias;

-- Venta que falla: no queda nada a medias (ROLLBACK)
CALL sp_emitir_ticket(NULL, @t, @n);
SELECT COUNT(*) INTO @antes FROM venta;
CALL sp_registrar_venta(@t, 4, 2, '5:10,16:99999', @v);   -- da error 1644: es lo esperado
SELECT @antes AS ventas_antes, COUNT(*) AS ventas_despues FROM venta;

-- ---------------------------------------------------------------------
-- PASO 7 · Índices secundarios (con 2.000 ventas el efecto es claro)
-- ---------------------------------------------------------------------
SHOW INDEX FROM venta;

-- Usa idx_venta_fecha_empleado (columna key; type = range)
EXPLAIN SELECT fecha, id_empleado, COUNT(*) AS ventas, SUM(total) AS monto
FROM venta
WHERE fecha BETWEEN CURDATE() - INTERVAL 7 DAY AND CURDATE()
GROUP BY fecha, id_empleado;

-- Mismo filtro sin poder usar el índice: recorre toda la tabla (type = ALL)
EXPLAIN SELECT fecha, id_empleado, COUNT(*) AS ventas, SUM(total) AS monto
FROM venta IGNORE INDEX (idx_venta_fecha_empleado)
WHERE fecha BETWEEN CURDATE() - INTERVAL 7 DAY AND CURDATE()
GROUP BY fecha, id_empleado;

-- Búsqueda por nombre (idx_producto_nombre) y ticket del día (idx_ticket_fecha_numero)
EXPLAIN SELECT id_producto, nombre FROM producto WHERE nombre LIKE 'Chocolate%';
EXPLAIN SELECT id_ticket, estado FROM ticket WHERE fecha = CURDATE() AND numero = 1;

-- ---------------------------------------------------------------------
-- PASO 8 · Consultas de negocio (más ejemplos en 06_consultas.sql)
-- ---------------------------------------------------------------------
-- Ventas por tipo de cliente
SELECT tc.nombre AS tipo_cliente, COUNT(v.id_venta) AS ventas, COALESCE(SUM(v.total), 0) AS monto
FROM tipo_cliente tc
LEFT JOIN cliente cl ON cl.id_tipo_cliente = tc.id_tipo_cliente
LEFT JOIN venta v    ON v.id_cliente = cl.id_cliente
GROUP BY tc.id_tipo_cliente, tc.nombre
ORDER BY monto DESC;

-- Clientes que compran sobre el promedio (subconsulta)
SELECT cl.nombre, SUM(v.total) AS total_comprado
FROM cliente cl JOIN venta v ON v.id_cliente = cl.id_cliente
GROUP BY cl.id_cliente, cl.nombre
HAVING SUM(v.total) > (SELECT AVG(total) FROM venta)
ORDER BY total_comprado DESC;

-- Top 5 productos más vendidos
SELECT p.nombre AS producto, SUM(d.cantidad) AS unidades, SUM(d.cantidad * d.precio_unit) AS ingresos
FROM detalle_venta d JOIN producto p ON p.id_producto = d.id_producto
GROUP BY p.id_producto, p.nombre
ORDER BY unidades DESC
LIMIT 5;

-- ---------------------------------------------------------------------
-- PASO 9 · Integridad (errores esperados, para mostrar las restricciones)
-- ---------------------------------------------------------------------
-- SKU duplicado -> error 1062 (llave secundaria UNIQUE)
INSERT INTO producto (sku, nombre, precio_det, precio_may, id_categoria, id_marca, id_proveedor)
VALUES ('7802800000011', 'chocolate sahne nuss', 2990, 2490, 1, 1, 1);

-- Marca con productos -> error 1451 (llave foránea)
DELETE FROM marca WHERE nombre = 'Nestlé';
