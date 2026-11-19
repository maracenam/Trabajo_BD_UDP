-- =====================================================================
--  04_vistas.sql
--  VISTAS
-- =====================================================================
USE la_mundial;

-- ---------------------------------------------------------------------
-- Vista principal: v_stock_productos
--
-- Justificacion: el problema central del negocio era el "stock poco
-- confiable" y la lentitud de los vendedores para buscar productos.
-- Esta vista entrega, en una sola consulta simple, el catalogo unico
-- con su categoria, marca, proveedor, precios, unidades disponibles y
-- un indicador de reposicion. Asi:
--   * el vendedor no necesita conocer los 5 JOIN que hay detras;
--   * todas las pantallas (caja, bodega, reportes) leen la MISMA regla
--     de "bajo minimo", evitando criterios distintos por usuario;
--   * se puede otorgar permiso de lectura sobre la vista sin exponer
--     las tablas base (seguridad).
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_stock_productos AS
SELECT p.id_producto,
       p.sku,
       p.nombre                         AS producto,
       c.nombre                         AS categoria,
       m.nombre                         AS marca,
       pr.razon_social                  AS proveedor,
       p.precio_det,
       p.precio_may,
       s.cantidad,
       s.stock_min,
       s.fecha_act,
       CASE
           WHEN s.cantidad = 0              THEN 'SIN STOCK'
           WHEN s.cantidad < s.stock_min    THEN 'REPONER'
           ELSE 'OK'
       END                              AS estado_stock,
       GREATEST(s.stock_min - s.cantidad, 0) AS unidades_faltantes
FROM producto  p
JOIN categoria c  ON c.id_categoria  = p.id_categoria
JOIN marca     m  ON m.id_marca      = p.id_marca
JOIN proveedor pr ON pr.id_proveedor = p.id_proveedor
JOIN stock     s  ON s.id_producto   = p.id_producto;

-- ---------------------------------------------------------------------
-- Vista complementaria: v_resumen_ventas
--
-- Justificacion: encabezado de cada venta con nombres legibles (cliente,
-- tipo de cliente, empleado, numero de ticket) y su total (columna
-- desnormalizada). Es la base de los reportes de ventas diarias y de la
-- comparacion mayorista/minorista que pidio el negocio.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_resumen_ventas AS
SELECT v.id_venta,
       v.fecha,
       v.hora,
       t.numero                        AS numero_ticket,
       cl.rut                          AS rut_cliente,
       cl.nombre                       AS cliente,
       tc.nombre                       AS tipo_cliente,
       e.nombre                        AS empleado,
       (SELECT COUNT(*) FROM detalle_venta d WHERE d.id_venta = v.id_venta) AS lineas,
       v.total
FROM venta        v
JOIN ticket       t  ON t.id_ticket        = v.id_ticket
JOIN cliente      cl ON cl.id_cliente      = v.id_cliente
JOIN tipo_cliente tc ON tc.id_tipo_cliente = cl.id_tipo_cliente
JOIN empleado     e  ON e.id_empleado      = v.id_empleado;

-- Ejemplos de uso
SELECT producto, categoria, cantidad, stock_min, estado_stock
FROM v_stock_productos
WHERE estado_stock <> 'OK'
ORDER BY unidades_faltantes DESC;

SELECT * FROM v_resumen_ventas ORDER BY fecha, hora;
