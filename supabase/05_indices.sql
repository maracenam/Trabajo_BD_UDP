-- =====================================================================
--  05_indices.sql  (PostgreSQL / Supabase)  - INDICES SECUNDARIOS
--  (justificacion en sql/05_indices.sql y en el informe)
-- =====================================================================

-- 1) Busqueda de productos por nombre SIN distinguir mayusculas.
--    Indice de expresion sobre lower(nombre) con text_pattern_ops para
--    que PostgreSQL lo use con LIKE 'texto%'.
CREATE INDEX idx_producto_nombre ON producto (lower(nombre) text_pattern_ops);

-- 2) Reportes por rango de fechas y por empleado
CREATE INDEX idx_venta_fecha_empleado ON venta (fecha, id_empleado);

-- 3) "Ticket N de hoy" y unicidad del numero de atencion por dia
CREATE UNIQUE INDEX idx_ticket_fecha_numero ON ticket (fecha, numero);

-- Verificacion. Con pocas filas PostgreSQL prefiere leer la tabla completa
-- (es mas barato); se desactiva el seq scan solo para ver el plan con indice.
-- Tras cargar ventas con sp_generar_ventas_simuladas el indice se usa solo.
SET enable_seqscan = off;
EXPLAIN SELECT id_producto, nombre FROM producto WHERE lower(nombre) LIKE 'chocolate%';
EXPLAIN SELECT fecha, id_empleado, COUNT(*), SUM(total) FROM venta
        WHERE fecha BETWEEN '2026-11-10' AND '2026-11-11' GROUP BY fecha, id_empleado;
EXPLAIN SELECT id_ticket, estado FROM ticket WHERE fecha = '2026-11-12' AND numero = 4;
RESET enable_seqscan;
