-- =====================================================================
--  04_vistas.sql  (PostgreSQL / Supabase)
--  security_invoker = true: la vista respeta los permisos (RLS) de quien
--  consulta, recomendacion de Supabase.
-- =====================================================================

-- Vista principal (justificacion en el informe)
CREATE OR REPLACE VIEW v_stock_productos WITH (security_invoker = true) AS
SELECT p.id_producto, p.sku, p.nombre AS producto,
       c.id_categoria, c.nombre AS categoria, m.nombre AS marca,
       pr.razon_social AS proveedor, p.precio_det, p.precio_may,
       s.cantidad, s.stock_min, s.fecha_act,
       CASE WHEN s.cantidad = 0           THEN 'SIN STOCK'
            WHEN s.cantidad < s.stock_min THEN 'REPONER'
            ELSE 'OK' END                       AS estado_stock,
       GREATEST(s.stock_min - s.cantidad, 0)    AS unidades_faltantes
FROM producto p
JOIN categoria c  ON c.id_categoria  = p.id_categoria
JOIN marca m      ON m.id_marca      = p.id_marca
JOIN proveedor pr ON pr.id_proveedor = p.id_proveedor
JOIN stock s      ON s.id_producto   = p.id_producto;

-- Vista complementaria: encabezado legible de cada venta
CREATE OR REPLACE VIEW v_resumen_ventas WITH (security_invoker = true) AS
SELECT v.id_venta, v.fecha, v.hora, t.numero AS numero_ticket,
       cl.rut AS rut_cliente, cl.nombre AS cliente, tc.nombre AS tipo_cliente,
       e.nombre AS empleado,
       (SELECT COUNT(*) FROM detalle_venta d WHERE d.id_venta = v.id_venta)::int AS lineas,
       v.total
FROM venta v
JOIN ticket t        ON t.id_ticket        = v.id_ticket
JOIN cliente cl      ON cl.id_cliente      = v.id_cliente
JOIN tipo_cliente tc ON tc.id_tipo_cliente = cl.id_tipo_cliente
JOIN empleado e      ON e.id_empleado      = v.id_empleado;

-- Vistas de reportes (consultas de 06 expuestas para la interfaz web)
CREATE OR REPLACE VIEW rpt_ventas_dia WITH (security_invoker = true) AS
SELECT fecha, COUNT(*)::int AS n_ventas, SUM(total)::int AS monto_total,
       ROUND(AVG(total))::int AS ticket_promedio
FROM venta GROUP BY fecha;

CREATE OR REPLACE VIEW rpt_ventas_tipo WITH (security_invoker = true) AS
SELECT tc.nombre AS tipo_cliente, COUNT(v.id_venta)::int AS n_ventas,
       COALESCE(SUM(v.total), 0)::int AS monto_total
FROM tipo_cliente tc
LEFT JOIN cliente cl ON cl.id_tipo_cliente = tc.id_tipo_cliente
LEFT JOIN venta v    ON v.id_cliente = cl.id_cliente
GROUP BY tc.id_tipo_cliente, tc.nombre;

CREATE OR REPLACE VIEW rpt_top_productos WITH (security_invoker = true) AS
SELECT p.sku, p.nombre AS producto, SUM(d.cantidad)::int AS unidades,
       SUM(d.cantidad * d.precio_unit)::int AS ingresos
FROM detalle_venta d JOIN producto p ON p.id_producto = d.id_producto
GROUP BY p.id_producto, p.sku, p.nombre;

CREATE OR REPLACE VIEW rpt_ingresos_categoria WITH (security_invoker = true) AS
SELECT c.nombre AS categoria, SUM(d.cantidad * d.precio_unit)::int AS ingresos,
       ROUND(100.0 * SUM(d.cantidad * d.precio_unit)
             / (SELECT SUM(cantidad * precio_unit) FROM detalle_venta), 1) AS pct
FROM detalle_venta d
JOIN producto p  ON p.id_producto  = d.id_producto
JOIN categoria c ON c.id_categoria = p.id_categoria
GROUP BY c.id_categoria, c.nombre;

CREATE OR REPLACE VIEW rpt_ranking_empleados WITH (security_invoker = true) AS
SELECT e.nombre, e.cargo, COUNT(v.id_venta)::int AS n_ventas,
       COALESCE(SUM(v.total), 0)::int AS monto_vendido
FROM empleado e LEFT JOIN venta v ON v.id_empleado = e.id_empleado
GROUP BY e.id_empleado, e.nombre, e.cargo;

CREATE OR REPLACE VIEW rpt_tickets_dia WITH (security_invoker = true) AS
SELECT fecha,
       COUNT(*) FILTER (WHERE estado = 'atendido')::int AS atendidos,
       COUNT(*) FILTER (WHERE estado = 'anulado')::int  AS anulados,
       COUNT(*) FILTER (WHERE estado = 'emitido')::int  AS pendientes,
       COUNT(*)::int AS total_tickets
FROM ticket GROUP BY fecha;

CREATE OR REPLACE VIEW rpt_productos_sin_venta WITH (security_invoker = true) AS
SELECT p.sku, p.nombre FROM producto p
WHERE NOT EXISTS (SELECT 1 FROM detalle_venta d WHERE d.id_producto = p.id_producto);

CREATE OR REPLACE VIEW v_historial_precio WITH (security_invoker = true) AS
SELECT h.*, p.nombre FROM historial_precio h JOIN producto p ON p.id_producto = h.id_producto;

SELECT producto, categoria, cantidad, stock_min, estado_stock
FROM v_stock_productos WHERE estado_stock <> 'OK' ORDER BY unidades_faltantes DESC;
