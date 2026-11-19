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
