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
