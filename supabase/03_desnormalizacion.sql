-- =====================================================================
--  03_desnormalizacion.sql  (PostgreSQL / Supabase)
--  Columna derivada venta.total, mantenida por un trigger PL/pgSQL.
--  (Justificacion completa en sql/03_desnormalizacion.sql y en el informe.)
-- =====================================================================
ALTER TABLE venta ADD COLUMN total INT NOT NULL DEFAULT 0;

UPDATE venta v
   SET total = COALESCE((SELECT SUM(d.cantidad * d.precio_unit)
                           FROM detalle_venta d WHERE d.id_venta = v.id_venta), 0);

CREATE OR REPLACE FUNCTION trg_detalle_total() RETURNS trigger
LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        UPDATE venta SET total = total - OLD.cantidad * OLD.precio_unit
         WHERE id_venta = OLD.id_venta;
    END IF;
    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        UPDATE venta SET total = total + NEW.cantidad * NEW.precio_unit
         WHERE id_venta = NEW.id_venta;
    END IF;
    RETURN NULL;   -- trigger AFTER: el valor de retorno se ignora
END $$;

CREATE TRIGGER trg_detalle_total
AFTER INSERT OR UPDATE OR DELETE ON detalle_venta
FOR EACH ROW EXECUTE FUNCTION trg_detalle_total();

-- Comprobacion (debe devolver 0 filas)
SELECT v.id_venta, v.total, SUM(d.cantidad * d.precio_unit) AS calculado
FROM venta v JOIN detalle_venta d ON d.id_venta = v.id_venta
GROUP BY v.id_venta, v.total
HAVING v.total <> SUM(d.cantidad * d.precio_unit);
