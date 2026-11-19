-- =====================================================================
--  06_consultas.sql  (PostgreSQL / Supabase)
--  CONSULTAS (queries) sobre la base de datos
-- =====================================================================

-- Q1. Busqueda rapida de productos por nombre (usa idx_producto_nombre)
SELECT sku, producto, marca, precio_det, precio_may, cantidad, estado_stock
FROM v_stock_productos
WHERE lower(producto) LIKE 'galletas%'
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
       ROUND(100.0 * SUM(d.cantidad * d.precio_unit)
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
       COUNT(*) FILTER (WHERE estado = 'atendido') AS atendidos,
       COUNT(*) FILTER (WHERE estado = 'anulado')  AS anulados,
       COUNT(*) FILTER (WHERE estado = 'emitido')  AS pendientes,
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
WHERE tc.aplica_precio_may
GROUP BY cl.id_cliente, cl.nombre
ORDER BY ahorro DESC;
