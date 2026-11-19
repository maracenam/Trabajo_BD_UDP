-- =====================================================================
--  08_procesamiento_masivo.sql
--  PROCESAMIENTO MASIVO mediante procedimientos almacenados
--  (SQL procedural de MySQL, equivalente a PL/SQL / T-SQL).
--
--  Todos los procesos que modifican varias tablas se ejecutan dentro de
--  una TRANSACCION: si cualquier paso falla se hace ROLLBACK y la base
--  queda como estaba (atomicidad).
--
--  Rutinas:
--   fn_precio_cliente      precio que corresponde a un cliente
--   sp_emitir_ticket       entrega el siguiente numero de atencion del dia
--   sp_registrar_venta     venta completa: detalle + descuento de stock
--   sp_reajuste_precios    reajuste masivo de precios con auditoria (cursor)
--   sp_reposicion_masiva   repone todos los productos bajo el minimo
--   sp_cierre_dia          anula tickets no atendidos al cierre
--   sp_recalcular_totales  re-sincroniza la columna desnormalizada
--   sp_generar_ventas_simuladas  carga masiva de N ventas (temporada alta)
-- =====================================================================
USE la_mundial;

DROP FUNCTION  IF EXISTS fn_precio_cliente;
DROP PROCEDURE IF EXISTS sp_emitir_ticket;
DROP PROCEDURE IF EXISTS sp_registrar_venta;
DROP PROCEDURE IF EXISTS sp_reajuste_precios;
DROP PROCEDURE IF EXISTS sp_reposicion_masiva;
DROP PROCEDURE IF EXISTS sp_cierre_dia;
DROP PROCEDURE IF EXISTS sp_recalcular_totales;
DROP PROCEDURE IF EXISTS sp_generar_ventas_simuladas;

DELIMITER $$

-- ---------------------------------------------------------------------
-- Precio que paga un cliente: mayor o detalle segun su tipo
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_precio_cliente(p_id_producto INT, p_id_cliente INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_precio INT;
    SELECT CASE WHEN tc.aplica_precio_may = 1 THEN p.precio_may
                ELSE p.precio_det END
      INTO v_precio
      FROM producto p, cliente c
      JOIN tipo_cliente tc ON tc.id_tipo_cliente = c.id_tipo_cliente
     WHERE p.id_producto = p_id_producto
       AND c.id_cliente  = p_id_cliente;
    RETURN v_precio;
END$$

-- ---------------------------------------------------------------------
-- Emite el siguiente ticket de atencion del dia (numero se reinicia
-- diariamente). p_fecha NULL = hoy.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_emitir_ticket(IN  p_fecha     DATE,
                                  OUT p_id_ticket INT,
                                  OUT p_numero    INT)
BEGIN
    DECLARE v_fecha DATE;
    SET v_fecha = COALESCE(p_fecha, CURDATE());

    SELECT COALESCE(MAX(numero), 0) + 1 INTO p_numero
      FROM ticket WHERE fecha = v_fecha;

    INSERT INTO ticket (numero, fecha, hora, estado)
    VALUES (p_numero, v_fecha, CURTIME(), 'emitido');

    SET p_id_ticket = LAST_INSERT_ID();
END$$

-- ---------------------------------------------------------------------
-- Registra una venta completa en UNA transaccion.
--   p_items: lista 'id_producto:cantidad,id_producto:cantidad,...'
--   Por cada item: bloquea la fila de stock (FOR UPDATE), valida que
--   haya unidades, inserta la linea con el precio segun tipo de cliente
--   y descuenta el stock. Al final marca el ticket como atendido.
--   Si algo falla (sin stock, ticket invalido, etc.) -> ROLLBACK total.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_registrar_venta(IN  p_id_ticket   INT,
                                    IN  p_id_cliente  INT,
                                    IN  p_id_empleado INT,
                                    IN  p_items       VARCHAR(2000),
                                    OUT p_id_venta    INT)
BEGIN
    DECLARE v_lista   VARCHAR(2010);
    DECLARE v_par     VARCHAR(50);
    DECLARE v_prod    INT;
    DECLARE v_cant    INT;
    DECLARE v_disp    INT;
    DECLARE v_estado  VARCHAR(15);
    DECLARE v_fecha_t DATE;
    DECLARE v_hora_t  TIME;
    DECLARE v_lineas  INT DEFAULT 0;
    DECLARE v_msg     VARCHAR(200);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- 1. Validar ticket
    SELECT estado, fecha, hora INTO v_estado, v_fecha_t, v_hora_t
      FROM ticket WHERE id_ticket = p_id_ticket FOR UPDATE;
    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El ticket no existe';
    ELSEIF v_estado <> 'emitido' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El ticket ya fue atendido o anulado';
    END IF;

    -- 2. Encabezado de la venta
    INSERT INTO venta (fecha, hora, id_ticket, id_cliente, id_empleado, total)
    VALUES (v_fecha_t,
            IF(v_fecha_t = CURDATE(), CURTIME(), ADDTIME(v_hora_t, '00:05:00')),
            p_id_ticket, p_id_cliente, p_id_empleado, 0);
    SET p_id_venta = LAST_INSERT_ID();

    -- 3. Recorrer los items
    SET v_lista = CONCAT(p_items, ',');
    WHILE LOCATE(',', v_lista) > 0 DO
        SET v_par   = TRIM(SUBSTRING_INDEX(v_lista, ',', 1));
        SET v_lista = SUBSTRING(v_lista, LOCATE(',', v_lista) + 1);

        IF v_par <> '' THEN
            SET v_prod = CAST(SUBSTRING_INDEX(v_par, ':', 1)  AS UNSIGNED);
            SET v_cant = CAST(SUBSTRING_INDEX(v_par, ':', -1) AS UNSIGNED);
            SET v_disp = NULL;

            IF v_cant IS NULL OR v_cant <= 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cantidad invalida en la lista de items';
            END IF;

            SELECT cantidad INTO v_disp
              FROM stock WHERE id_producto = v_prod FOR UPDATE;

            IF v_disp IS NULL THEN
                SET v_msg = CONCAT('Producto ', v_prod, ' no existe');
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
            ELSEIF v_disp < v_cant THEN
                SET v_msg = CONCAT('Stock insuficiente para producto ', v_prod,
                                   ' (disponible ', v_disp, ', solicitado ', v_cant, ')');
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
            END IF;

            INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unit)
            VALUES (p_id_venta, v_prod, v_cant, fn_precio_cliente(v_prod, p_id_cliente));

            UPDATE stock
               SET cantidad = cantidad - v_cant, fecha_act = CURDATE()
             WHERE id_producto = v_prod;

            SET v_lineas = v_lineas + 1;
        END IF;
    END WHILE;

    IF v_lineas = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta no tiene productos';
    END IF;

    -- 4. Cerrar el ticket
    UPDATE ticket SET estado = 'atendido' WHERE id_ticket = p_id_ticket;

    COMMIT;
END$$

-- ---------------------------------------------------------------------
-- Reajuste MASIVO de precios por categoria (o de todo el catalogo si
-- p_id_categoria es NULL). Usa un CURSOR para recorrer los productos,
-- deja registro de cada cambio en historial_precio y redondea a la
-- decena de pesos. Todo en una transaccion.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_reajuste_precios(IN  p_id_categoria INT,
                                     IN  p_porcentaje   DECIMAL(5,2),
                                     IN  p_motivo       VARCHAR(100),
                                     OUT p_actualizados INT)
BEGIN
    DECLARE v_fin     INT DEFAULT 0;
    DECLARE v_id      INT;
    DECLARE v_det     INT;
    DECLARE v_may     INT;
    DECLARE v_det_new INT;
    DECLARE v_may_new INT;

    DECLARE cur_productos CURSOR FOR
        SELECT id_producto, precio_det, precio_may
          FROM producto
         WHERE p_id_categoria IS NULL OR id_categoria = p_id_categoria
         FOR UPDATE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_porcentaje IS NULL OR p_porcentaje <= -50 OR p_porcentaje > 100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Porcentaje fuera de rango (-50, 100]';
    END IF;

    SET p_actualizados = 0;
    START TRANSACTION;
    OPEN cur_productos;
    leer: LOOP
        FETCH cur_productos INTO v_id, v_det, v_may;
        IF v_fin = 1 THEN LEAVE leer; END IF;

        SET v_det_new = GREATEST(10, ROUND(v_det * (1 + p_porcentaje / 100) / 10) * 10);
        SET v_may_new = LEAST(v_det_new,
                              GREATEST(10, ROUND(v_may * (1 + p_porcentaje / 100) / 10) * 10));

        INSERT INTO historial_precio (id_producto, precio_det_ant, precio_det_nuevo,
                                      precio_may_ant, precio_may_nuevo, fecha_cambio, motivo)
        VALUES (v_id, v_det, v_det_new, v_may, v_may_new, NOW(),
                COALESCE(p_motivo, 'Reajuste masivo'));

        UPDATE producto
           SET precio_det = v_det_new, precio_may = v_may_new
         WHERE id_producto = v_id;

        SET p_actualizados = p_actualizados + 1;
    END LOOP;
    CLOSE cur_productos;
    COMMIT;
END$$

-- ---------------------------------------------------------------------
-- Reposicion masiva: todo producto bajo su stock minimo se repone hasta
-- p_factor veces el minimo (orden de compra automatica).
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_reposicion_masiva(IN  p_factor    INT,
                                      OUT p_productos INT,
                                      OUT p_unidades  INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_factor IS NULL OR p_factor < 1 THEN
        SET p_factor = 2;
    END IF;

    START TRANSACTION;
    SELECT COUNT(*), COALESCE(SUM(stock_min * p_factor - cantidad), 0)
      INTO p_productos, p_unidades
      FROM stock
     WHERE cantidad < stock_min;

    UPDATE stock
       SET cantidad  = stock_min * p_factor,
           fecha_act = CURDATE()
     WHERE cantidad < stock_min;
    COMMIT;
END$$

-- ---------------------------------------------------------------------
-- Cierre del dia: anula todos los tickets que quedaron emitidos (sin
-- atender) hasta la fecha indicada.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_cierre_dia(IN p_fecha DATE, OUT p_anulados INT)
BEGIN
    START TRANSACTION;
    UPDATE ticket
       SET estado = 'anulado'
     WHERE estado = 'emitido'
       AND fecha <= COALESCE(p_fecha, CURDATE());
    SET p_anulados = ROW_COUNT();
    COMMIT;
END$$

-- ---------------------------------------------------------------------
-- Re-sincroniza la columna desnormalizada venta.total con el detalle.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_recalcular_totales(OUT p_corregidas INT)
BEGIN
    START TRANSACTION;
    UPDATE venta v
      LEFT JOIN (SELECT id_venta, SUM(cantidad * precio_unit) AS t
                   FROM detalle_venta GROUP BY id_venta) d
             ON d.id_venta = v.id_venta
       SET v.total = COALESCE(d.t, 0)
     WHERE v.total <> COALESCE(d.t, 0);
    SET p_corregidas = ROW_COUNT();
    COMMIT;
END$$

-- ---------------------------------------------------------------------
-- Carga masiva: genera p_cantidad ventas aleatorias distribuidas en los
-- ultimos p_dias dias (simula la temporada alta de turistas). Cada venta
-- pasa por sp_registrar_venta, por lo que respeta stock, precios por
-- tipo de cliente y triggers. Sirve para probar rendimiento e indices.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_generar_ventas_simuladas(IN  p_cantidad INT,
                                             IN  p_dias     INT,
                                             OUT p_creadas  INT)
BEGIN
    DECLARE i           INT DEFAULT 0;
    DECLARE j           INT;
    DECLARE v_items     VARCHAR(2000);
    DECLARE v_n_items   INT;
    DECLARE v_prod      INT;
    DECLARE v_cant      INT;
    DECLARE v_cliente   INT;
    DECLARE v_empleado  INT;
    DECLARE v_fecha     DATE;
    DECLARE v_ticket    INT;
    DECLARE v_numero    INT;
    DECLARE v_venta     INT;
    DECLARE v_x         INT;
    DECLARE v_y         INT;

    SET p_creadas = 0;
    SET p_dias = GREATEST(COALESCE(p_dias, 30), 1);
    WHILE i < p_cantidad DO
        -- cada 25 ventas se repone lo que quedo bajo el minimo
        IF MOD(i, 25) = 0 THEN
            CALL sp_reposicion_masiva(5, v_x, v_y);
        END IF;

        SET v_fecha = DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * p_dias) DAY);
        SELECT id_cliente  INTO v_cliente  FROM cliente  ORDER BY RAND() LIMIT 1;
        SELECT id_empleado INTO v_empleado FROM empleado ORDER BY RAND() LIMIT 1;

        -- arma entre 1 y 4 items con productos que tengan stock suficiente
        SET v_items = '';
        SET v_n_items = 1 + FLOOR(RAND() * 4);
        SET j = 0;
        WHILE j < v_n_items DO
            SET v_cant = 1 + FLOOR(RAND() * 6);
            SET v_prod = NULL;
            SELECT id_producto INTO v_prod
              FROM stock WHERE cantidad >= v_cant * 4
             ORDER BY RAND() LIMIT 1;
            IF v_prod IS NOT NULL
               AND FIND_IN_SET(CONCAT(v_prod, ':', v_cant), v_items) = 0 THEN
                SET v_items = CONCAT(v_items, IF(v_items = '', '', ','), v_prod, ':', v_cant);
            END IF;
            SET j = j + 1;
        END WHILE;

        IF v_items <> '' THEN
            CALL sp_emitir_ticket(v_fecha, v_ticket, v_numero);
            UPDATE ticket SET hora = SEC_TO_TIME(9 * 3600 + FLOOR(RAND() * 9 * 3600))
             WHERE id_ticket = v_ticket;
            CALL sp_registrar_venta(v_ticket, v_cliente, v_empleado, v_items, v_venta);
            SET p_creadas = p_creadas + 1;
        END IF;

        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

-- =====================================================================
-- Ejemplos de ejecucion
-- =====================================================================

-- a) Emitir ticket y registrar una venta de un turista (precio detalle)
CALL sp_emitir_ticket(NULL, @ticket, @num);
SELECT @ticket AS id_ticket, @num AS numero_atencion;
CALL sp_registrar_venta(@ticket, 6, 1, '1:6,2:6,16:2', @venta);
SELECT * FROM v_resumen_ventas WHERE id_venta = @venta;

-- b) Venta que FALLA por falta de stock -> ROLLBACK (no queda nada a medias)
CALL sp_emitir_ticket(NULL, @ticket2, @num2);
-- CALL sp_registrar_venta(@ticket2, 4, 2, '5:10,16:9999', @venta2);
--   -> ERROR 1644: Stock insuficiente para producto 16 (...)

-- c) Reajuste de 5% a los Chocolates por alza del proveedor
CALL sp_reajuste_precios(1, 5.00, 'Alza proveedor chocolates', @n);
SELECT @n AS productos_reajustados;
SELECT * FROM historial_precio ORDER BY id_historial DESC LIMIT 5;

-- d) Reposicion automatica de todo lo que esta bajo el minimo
CALL sp_reposicion_masiva(3, @prods, @unid);
SELECT @prods AS productos_repuestos, @unid AS unidades_pedidas;

-- e) Cierre del dia: anula tickets pendientes
CALL sp_cierre_dia(CURDATE(), @anulados);
SELECT @anulados AS tickets_anulados;

-- f) Control de la desnormalizacion
CALL sp_recalcular_totales(@corr);
SELECT @corr AS ventas_corregidas;

-- g) Carga masiva de prueba (descomentar; ej.: 2000 ventas en 120 dias)
-- CALL sp_generar_ventas_simuladas(2000, 120, @creadas);
-- SELECT @creadas;
