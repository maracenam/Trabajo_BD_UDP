-- =====================================================================
--  08_procesamiento_masivo.sql  (PostgreSQL / Supabase)
--  PROCESAMIENTO MASIVO con funciones PL/pgSQL.
--
--  En PostgreSQL cada llamada a una funcion es ATOMICA: se ejecuta dentro
--  de una transaccion y, si ocurre un RAISE EXCEPTION (o cualquier error),
--  se deshace TODO lo que hizo la funcion (ROLLBACK automatico).
--
--  SECURITY DEFINER: la API publica de Supabase (rol anon) no tiene
--  permiso para escribir en las tablas; solo puede ejecutar estas
--  funciones, que validan los datos antes de modificar la base.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Precio que paga un cliente segun su tipo
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_precio_cliente(p_id_producto INT, p_id_cliente INT)
RETURNS INT LANGUAGE sql STABLE SET search_path = public AS $$
    SELECT CASE WHEN tc.aplica_precio_may THEN p.precio_may ELSE p.precio_det END
      FROM producto p, cliente c
      JOIN tipo_cliente tc ON tc.id_tipo_cliente = c.id_tipo_cliente
     WHERE p.id_producto = p_id_producto AND c.id_cliente = p_id_cliente
$$;

-- ---------------------------------------------------------------------
-- Emite el siguiente ticket del dia
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_emitir_ticket(p_fecha DATE DEFAULT NULL)
RETURNS TABLE (id_ticket INT, numero INT)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
#variable_conflict use_column
DECLARE
    v_fecha DATE := COALESCE(p_fecha, fn_hoy());
    v_num   INT;
    v_id    INT;
BEGIN
    -- evita que dos cajas obtengan el mismo numero al mismo tiempo
    PERFORM pg_advisory_xact_lock(hashtext('ticket' || v_fecha));
    SELECT COALESCE(MAX(t.numero), 0) + 1 INTO v_num FROM ticket t WHERE t.fecha = v_fecha;
    INSERT INTO ticket (numero, fecha, hora, estado)
    VALUES (v_num, v_fecha, fn_hora(), 'emitido')
    RETURNING ticket.id_ticket INTO v_id;
    RETURN QUERY SELECT v_id, v_num;
END $$;

-- ---------------------------------------------------------------------
-- Registra una venta completa (todo o nada)
--   p_items: 'id_producto:cantidad,id_producto:cantidad,...'
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_registrar_venta(p_id_ticket INT, p_id_cliente INT,
                                              p_id_empleado INT, p_items TEXT)
RETURNS INT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_estado  VARCHAR(15);
    v_fecha_t DATE;
    v_hora_t  TIME;
    v_venta   INT;
    v_par     TEXT;
    v_prod    INT;
    v_cant    INT;
    v_disp    INT;
    v_lineas  INT := 0;
BEGIN
    -- 1. Validar ticket (bloqueando la fila)
    SELECT estado, fecha, hora INTO v_estado, v_fecha_t, v_hora_t
      FROM ticket WHERE id_ticket = p_id_ticket FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El ticket no existe';
    ELSIF v_estado <> 'emitido' THEN
        RAISE EXCEPTION 'El ticket ya fue atendido o anulado';
    END IF;

    -- 2. Encabezado
    INSERT INTO venta (fecha, hora, id_ticket, id_cliente, id_empleado, total)
    VALUES (v_fecha_t,
            CASE WHEN v_fecha_t = fn_hoy() THEN fn_hora() ELSE v_hora_t + interval '5 minutes' END,
            p_id_ticket, p_id_cliente, p_id_empleado, 0)
    RETURNING id_venta INTO v_venta;

    -- 3. Items
    FOREACH v_par IN ARRAY string_to_array(COALESCE(p_items, ''), ',') LOOP
        v_par := trim(v_par);
        CONTINUE WHEN v_par = '';
        BEGIN
            v_prod := split_part(v_par, ':', 1)::INT;
            v_cant := split_part(v_par, ':', 2)::INT;
        EXCEPTION WHEN invalid_text_representation THEN
            RAISE EXCEPTION 'Item mal escrito: "%"', v_par;
        END;
        IF v_cant IS NULL OR v_cant <= 0 THEN
            RAISE EXCEPTION 'Cantidad invalida en el item "%"', v_par;
        END IF;

        SELECT cantidad INTO v_disp FROM stock WHERE id_producto = v_prod FOR UPDATE;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Producto % no existe', v_prod;
        ELSIF v_disp < v_cant THEN
            RAISE EXCEPTION 'Stock insuficiente para producto % (disponible %, solicitado %)',
                            v_prod, v_disp, v_cant;
        END IF;

        INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unit)
        VALUES (v_venta, v_prod, v_cant, fn_precio_cliente(v_prod, p_id_cliente));

        UPDATE stock SET cantidad = cantidad - v_cant, fecha_act = fn_hoy()
         WHERE id_producto = v_prod;
        v_lineas := v_lineas + 1;
    END LOOP;

    IF v_lineas = 0 THEN
        RAISE EXCEPTION 'La venta no tiene productos';
    END IF;

    -- 4. Cerrar ticket
    UPDATE ticket SET estado = 'atendido' WHERE id_ticket = p_id_ticket;
    RETURN v_venta;
END $$;

-- ---------------------------------------------------------------------
-- Reajuste masivo de precios con CURSOR y auditoria
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_reajuste_precios(p_id_categoria INT, p_porcentaje NUMERIC,
                                               p_motivo TEXT DEFAULT 'Reajuste masivo')
RETURNS INT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    cur_productos CURSOR FOR
        SELECT id_producto, precio_det, precio_may FROM producto
         WHERE p_id_categoria IS NULL OR id_categoria = p_id_categoria
         FOR UPDATE;
    r       RECORD;
    v_det   INT;
    v_may   INT;
    v_n     INT := 0;
BEGIN
    IF p_porcentaje IS NULL OR p_porcentaje <= -50 OR p_porcentaje > 100 THEN
        RAISE EXCEPTION 'Porcentaje fuera de rango (-50, 100]';
    END IF;

    OPEN cur_productos;
    LOOP
        FETCH cur_productos INTO r;
        EXIT WHEN NOT FOUND;
        v_det := GREATEST(10, ROUND(r.precio_det * (1 + p_porcentaje / 100) / 10) * 10);
        v_may := LEAST(v_det, GREATEST(10, ROUND(r.precio_may * (1 + p_porcentaje / 100) / 10) * 10));

        INSERT INTO historial_precio (id_producto, precio_det_ant, precio_det_nuevo,
                                      precio_may_ant, precio_may_nuevo, fecha_cambio, motivo)
        VALUES (r.id_producto, r.precio_det, v_det, r.precio_may, v_may, now(),
                COALESCE(NULLIF(p_motivo, ''), 'Reajuste masivo'));

        UPDATE producto SET precio_det = v_det, precio_may = v_may
         WHERE CURRENT OF cur_productos;
        v_n := v_n + 1;
    END LOOP;
    CLOSE cur_productos;
    RETURN v_n;
END $$;

-- ---------------------------------------------------------------------
-- Reposicion masiva de stock
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_reposicion_masiva(p_factor INT DEFAULT 2)
RETURNS TABLE (productos INT, unidades INT)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_factor INT := CASE WHEN p_factor IS NULL OR p_factor < 1 THEN 2 ELSE p_factor END;
BEGIN
    RETURN QUERY
    WITH repuestos AS (
        UPDATE stock s
           SET cantidad = s.stock_min * v_factor, fecha_act = fn_hoy()
          FROM stock antes
         WHERE antes.id_stock = s.id_stock AND s.cantidad < s.stock_min
        RETURNING s.cantidad - antes.cantidad AS agregadas
    )
    SELECT COUNT(*)::INT, COALESCE(SUM(agregadas), 0)::INT FROM repuestos;
END $$;

-- ---------------------------------------------------------------------
-- Cierre del dia: anula tickets no atendidos
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_cierre_dia(p_fecha DATE DEFAULT NULL)
RETURNS INT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_n INT;
BEGIN
    UPDATE ticket SET estado = 'anulado'
     WHERE estado = 'emitido' AND fecha <= COALESCE(p_fecha, fn_hoy());
    GET DIAGNOSTICS v_n = ROW_COUNT;
    RETURN v_n;
END $$;

-- ---------------------------------------------------------------------
-- Re-sincroniza la columna desnormalizada venta.total
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_recalcular_totales()
RETURNS INT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_n INT;
BEGIN
    UPDATE venta v SET total = COALESCE(d.t, 0)
      FROM venta v2
      LEFT JOIN (SELECT id_venta, SUM(cantidad * precio_unit) AS t
                   FROM detalle_venta GROUP BY id_venta) d ON d.id_venta = v2.id_venta
     WHERE v2.id_venta = v.id_venta AND v.total <> COALESCE(d.t, 0);
    GET DIAGNOSTICS v_n = ROW_COUNT;
    RETURN v_n;
END $$;

-- ---------------------------------------------------------------------
-- Carga masiva de ventas simuladas (temporada alta)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_generar_ventas_simuladas(p_cantidad INT, p_dias INT DEFAULT 30)
RETURNS INT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    i        INT;
    j        INT;
    v_items  TEXT;
    v_prod   INT;
    v_cant   INT;
    v_fecha  DATE;
    v_ticket INT;
    v_n      INT := 0;
    v_dias   INT := GREATEST(COALESCE(p_dias, 30), 1);
BEGIN
    IF p_cantidad IS NULL OR p_cantidad < 1 OR p_cantidad > 3000 THEN
        RAISE EXCEPTION 'La cantidad debe estar entre 1 y 3000';
    END IF;

    FOR i IN 0 .. p_cantidad - 1 LOOP
        IF i % 25 = 0 THEN
            PERFORM sp_reposicion_masiva(5);
        END IF;

        v_items := '';
        FOR j IN 1 .. 1 + floor(random() * 4)::INT LOOP
            v_cant := 1 + floor(random() * 6)::INT;
            SELECT id_producto INTO v_prod FROM stock
             WHERE cantidad >= v_cant * 4 ORDER BY random() LIMIT 1;
            IF FOUND AND position(v_prod || ':' IN v_items) = 0 THEN
                v_items := v_items || CASE WHEN v_items = '' THEN '' ELSE ',' END
                                   || v_prod || ':' || v_cant;
            END IF;
        END LOOP;

        CONTINUE WHEN v_items = '';
        v_fecha := fn_hoy() - floor(random() * v_dias)::INT;
        SELECT t.id_ticket INTO v_ticket FROM sp_emitir_ticket(v_fecha) t;
        UPDATE ticket SET hora = time '09:00' + floor(random() * 9 * 3600) * interval '1 second'
         WHERE id_ticket = v_ticket;
        PERFORM sp_registrar_venta(v_ticket,
                                   (SELECT id_cliente  FROM cliente  ORDER BY random() LIMIT 1),
                                   (SELECT id_empleado FROM empleado ORDER BY random() LIMIT 1),
                                   v_items);
        v_n := v_n + 1;
    END LOOP;
    RETURN v_n;
END $$;

-- =====================================================================
-- Funciones de apoyo para la interfaz web (mantenedor de productos)
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_kpis()
RETURNS JSON LANGUAGE sql STABLE SET search_path = public AS $$
    SELECT json_build_object(
        'ventas_hoy',   (SELECT COUNT(*) FROM venta WHERE fecha = fn_hoy()),
        'monto_hoy',    (SELECT COALESCE(SUM(total), 0) FROM venta WHERE fecha = fn_hoy()),
        'a_reponer',    (SELECT COUNT(*) FROM v_stock_productos WHERE estado_stock <> 'OK'),
        'tickets_pend', (SELECT COUNT(*) FROM ticket WHERE estado = 'emitido'),
        'productos',    (SELECT COUNT(*) FROM producto),
        'ventas_total', (SELECT COUNT(*) FROM venta))
$$;

CREATE OR REPLACE FUNCTION fn_buscar_productos(p_q TEXT DEFAULT '', p_categoria INT DEFAULT NULL)
RETURNS SETOF v_stock_productos LANGUAGE sql STABLE SET search_path = public AS $$
    SELECT * FROM v_stock_productos
     WHERE (COALESCE(p_q, '') = ''
            OR lower(producto) LIKE lower(p_q) || '%'      -- usa idx_producto_nombre
            OR sku = p_q
            OR lower(marca) LIKE lower(p_q) || '%')
       AND (p_categoria IS NULL OR id_categoria = p_categoria)
     ORDER BY categoria, producto
$$;

CREATE OR REPLACE FUNCTION fn_producto_guardar(p_id INT, p_sku TEXT, p_nombre TEXT,
        p_precio_det INT, p_precio_may INT, p_id_categoria INT, p_id_marca INT,
        p_id_proveedor INT, p_stock_min INT DEFAULT 0, p_cantidad INT DEFAULT 0)
RETURNS INT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_id INT := p_id;
BEGIN
    IF v_id IS NULL THEN
        INSERT INTO producto (sku, nombre, precio_det, precio_may, id_categoria, id_marca, id_proveedor)
        VALUES (trim(p_sku), trim(p_nombre), p_precio_det, p_precio_may, p_id_categoria, p_id_marca, p_id_proveedor)
        RETURNING id_producto INTO v_id;
        INSERT INTO stock (id_producto, cantidad, stock_min, fecha_act)
        VALUES (v_id, COALESCE(p_cantidad, 0), COALESCE(p_stock_min, 0), fn_hoy());
    ELSE
        UPDATE producto SET sku = trim(p_sku), nombre = trim(p_nombre), precio_det = p_precio_det,
               precio_may = p_precio_may, id_categoria = p_id_categoria, id_marca = p_id_marca,
               id_proveedor = p_id_proveedor
         WHERE id_producto = v_id;
        IF NOT FOUND THEN RAISE EXCEPTION 'Producto % no existe', v_id; END IF;
        UPDATE stock SET stock_min = COALESCE(p_stock_min, 0), fecha_act = fn_hoy()
         WHERE id_producto = v_id;
    END IF;
    RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION fn_producto_eliminar(p_id INT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    DELETE FROM producto WHERE id_producto = p_id;
END $$;

CREATE OR REPLACE FUNCTION fn_stock_ingreso(p_id INT, p_unidades INT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF p_unidades IS NULL OR p_unidades <= 0 THEN
        RAISE EXCEPTION 'Ingrese una cantidad mayor a 0';
    END IF;
    UPDATE stock SET cantidad = cantidad + p_unidades, fecha_act = fn_hoy() WHERE id_producto = p_id;
END $$;

-- Las funciones internas no se exponen por la API
REVOKE EXECUTE ON FUNCTION trg_detalle_total() FROM PUBLIC, anon, authenticated;

-- =====================================================================
-- Ejemplos de ejecucion
-- =====================================================================
-- SELECT * FROM sp_emitir_ticket();                                 -- nuevo ticket
-- SELECT sp_registrar_venta(15, 6, 1, '1:6,2:6,16:2');              -- venta
-- SELECT sp_registrar_venta(16, 4, 2, '5:10,16:9999');              -- falla -> se deshace todo
-- SELECT sp_reajuste_precios(1, 5, 'Alza proveedor chocolates');    -- reajuste
-- SELECT * FROM sp_reposicion_masiva(3);                            -- reposicion
-- SELECT sp_cierre_dia();                                           -- cierre
-- SELECT sp_recalcular_totales();                                   -- control desnormalizacion
-- SELECT sp_generar_ventas_simuladas(2000, 120);                    -- carga masiva
