"""
Distribuidora La Mundial - Interfaz web del sistema de base de datos.

Aplicacion Flask que se conecta a la base `la_mundial` (MySQL) y permite:
  * consultar el catalogo y el stock (vista v_stock_productos)
  * mantener productos (INSERT / UPDATE / DELETE)
  * emitir tickets y registrar ventas (procedimiento sp_registrar_venta)
  * ver reportes (consultas del archivo 06_consultas.sql)
  * ejecutar los procesos masivos (procedimientos del archivo 08)

Ejecucion:
    pip install -r requirements.txt
    set DB_PASSWORD=...   (Windows)   /   export DB_PASSWORD=...  (Linux/Mac)
    python app.py   ->  http://127.0.0.1:5000
"""
import os
from datetime import date

import pymysql
from flask import Flask, flash, redirect, render_template, request, url_for

app = Flask(__name__)
app.secret_key = os.environ.get("SECRET_KEY", "la-mundial-dev")

DB = dict(
    host=os.environ.get("DB_HOST", "127.0.0.1"),
    port=int(os.environ.get("DB_PORT", "3306")),
    user=os.environ.get("DB_USER", "root"),
    password=os.environ.get("DB_PASSWORD", ""),
    database=os.environ.get("DB_NAME", "la_mundial"),
    charset="utf8mb4",
    cursorclass=pymysql.cursors.DictCursor,
    autocommit=True,
)


def conectar():
    return pymysql.connect(**DB)


def consulta(sql, params=None):
    """SELECT -> lista de diccionarios."""
    with conectar() as cn, cn.cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchall()


def uno(sql, params=None):
    filas = consulta(sql, params)
    return filas[0] if filas else None


def ejecutar(sql, params=None):
    """INSERT / UPDATE / DELETE -> filas afectadas."""
    with conectar() as cn, cn.cursor() as cur:
        return cur.execute(sql, params)


def llamar(sql_call, params, salidas):
    """CALL a un procedimiento con parametros OUT (@variables)."""
    with conectar() as cn, cn.cursor() as cur:
        cur.execute(sql_call, params)
        while cur.nextset():
            pass
        cur.execute("SELECT " + ", ".join(f"{s} AS `{s[1:]}`" for s in salidas))
        return cur.fetchone()


def error_bd(e):
    return e.args[1] if len(e.args) > 1 else str(e)


def entero(valor, defecto=None):
    try:
        return int(valor)
    except (TypeError, ValueError):
        return defecto


@app.context_processor
def contexto():
    return {"motor": "MySQL"}


@app.template_filter("clp")
def clp(valor):
    if valor is None:
        return "-"
    return "$" + f"{int(valor):,}".replace(",", ".")


# ---- Filtros de presentacion (compartidos con la otra version de la app) ----
ESTADOS = {"OK": "Al día", "REPONER": "Reponer", "SIN STOCK": "Sin stock",
           "emitido": "En espera", "atendido": "Atendido", "anulado": "Anulado"}
MESES = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]


@app.template_filter("estado")
def f_estado(valor):
    return ESTADOS.get(valor, valor)


@app.template_filter("slug")
def f_slug(valor):
    return str(valor).lower().replace(" ", "-")


@app.template_filter("fecha")
def f_fecha(valor):
    s = str(valor)[:10]
    try:
        a, m, d = s.split("-")
        return f"{int(d)} {MESES[int(m) - 1]} {a}"
    except (ValueError, IndexError):
        return s


@app.template_filter("hora")
def f_hora(valor):
    if hasattr(valor, "total_seconds"):          # MySQL entrega TIME como timedelta
        seg = int(valor.total_seconds())
        return f"{seg // 3600:02d}:{seg % 3600 // 60:02d}"
    return str(valor)[:5]


@app.template_filter("corto")
def f_corto(valor):
    return str(valor)[:16].replace("T", " ")


# ---------------------------------------------------------------------
# Inicio
# ---------------------------------------------------------------------
@app.route("/")
def inicio():
    hoy = date.today()
    kpi = uno(
        """SELECT (SELECT COUNT(*) FROM venta WHERE fecha = %s)               AS ventas_hoy,
                  (SELECT COALESCE(SUM(total),0) FROM venta WHERE fecha = %s) AS monto_hoy,
                  (SELECT COUNT(*) FROM v_stock_productos WHERE estado_stock <> 'OK') AS a_reponer,
                  (SELECT COUNT(*) FROM ticket WHERE estado = 'emitido')     AS tickets_pend,
                  (SELECT COUNT(*) FROM producto)                            AS productos,
                  (SELECT COUNT(*) FROM venta)                               AS ventas_total""",
        (hoy, hoy),
    )
    ultimas = consulta("SELECT * FROM v_resumen_ventas ORDER BY fecha DESC, hora DESC LIMIT 8")
    reponer = consulta(
        """SELECT producto, cantidad, stock_min, estado_stock FROM v_stock_productos
           WHERE estado_stock <> 'OK' ORDER BY unidades_faltantes DESC LIMIT 8"""
    )
    siguiente = uno("SELECT COALESCE(MAX(numero), 0) + 1 AS n FROM ticket WHERE fecha = CURDATE()")["n"]
    return render_template("inicio.html", kpi=kpi, ultimas=ultimas, reponer=reponer,
                           siguiente=siguiente, nuevo_ticket=bool(request.args.get("nuevo")))


# ---------------------------------------------------------------------
# Productos (catalogo + CRUD)
# ---------------------------------------------------------------------
def catalogos():
    return dict(
        categorias=consulta("SELECT * FROM categoria ORDER BY nombre"),
        marcas=consulta("SELECT * FROM marca ORDER BY nombre"),
        proveedores=consulta("SELECT * FROM proveedor ORDER BY razon_social"),
    )


@app.route("/productos")
def productos():
    q = request.args.get("q", "").strip()
    cat = entero(request.args.get("categoria"))
    sql = "SELECT * FROM v_stock_productos WHERE 1=1"
    params = []
    if q:
        sql += " AND (producto LIKE %s OR sku = %s OR marca LIKE %s)"
        params += [q + "%", q, q + "%"]
    if cat:
        sql += " AND categoria = (SELECT nombre FROM categoria WHERE id_categoria = %s)"
        params.append(cat)
    sql += " ORDER BY categoria, producto"
    return render_template(
        "productos.html", filas=consulta(sql, params), q=q, cat=cat, **catalogos()
    )


@app.route("/productos/nuevo", methods=["GET", "POST"])
def producto_nuevo():
    if request.method == "POST":
        f = request.form
        try:
            with conectar() as cn, cn.cursor() as cur:
                cn.begin()
                cur.execute(
                    """INSERT INTO producto (sku, nombre, precio_det, precio_may,
                                             id_categoria, id_marca, id_proveedor)
                       VALUES (%s,%s,%s,%s,%s,%s,%s)""",
                    (f["sku"].strip(), f["nombre"].strip(), f["precio_det"], f["precio_may"],
                     f["id_categoria"], f["id_marca"], f["id_proveedor"]),
                )
                cur.execute(
                    "INSERT INTO stock (id_producto, cantidad, stock_min, fecha_act) "
                    "VALUES (LAST_INSERT_ID(), %s, %s, CURDATE())",
                    (f.get("cantidad") or 0, f.get("stock_min") or 0),
                )
                cn.commit()
            flash(f"Producto '{f['nombre']}' creado.", "ok")
            return redirect(url_for("productos"))
        except pymysql.MySQLError as e:
            flash("No se pudo crear: " + error_bd(e), "error")
    return render_template("producto_form.html", p=None, **catalogos())


@app.route("/productos/<int:id_producto>/editar", methods=["GET", "POST"])
def producto_editar(id_producto):
    if request.method == "POST":
        f = request.form
        try:
            ejecutar(
                """UPDATE producto SET sku=%s, nombre=%s, precio_det=%s, precio_may=%s,
                          id_categoria=%s, id_marca=%s, id_proveedor=%s
                   WHERE id_producto=%s""",
                (f["sku"].strip(), f["nombre"].strip(), f["precio_det"], f["precio_may"],
                 f["id_categoria"], f["id_marca"], f["id_proveedor"], id_producto),
            )
            ejecutar(
                "UPDATE stock SET stock_min=%s, fecha_act=CURDATE() WHERE id_producto=%s",
                (f.get("stock_min") or 0, id_producto),
            )
            flash("Producto actualizado.", "ok")
            return redirect(url_for("productos"))
        except pymysql.MySQLError as e:
            flash("No se pudo actualizar: " + error_bd(e), "error")
    p = uno(
        """SELECT p.*, s.cantidad, s.stock_min FROM producto p
           JOIN stock s ON s.id_producto = p.id_producto WHERE p.id_producto = %s""",
        (id_producto,),
    )
    if not p:
        flash("Producto no encontrado.", "error")
        return redirect(url_for("productos"))
    return render_template("producto_form.html", p=p, **catalogos())


@app.route("/productos/<int:id_producto>/eliminar", methods=["POST"])
def producto_eliminar(id_producto):
    try:
        ejecutar("DELETE FROM producto WHERE id_producto = %s", (id_producto,))
        flash("Producto eliminado.", "ok")
    except pymysql.MySQLError as e:
        flash("No se puede eliminar (tiene ventas asociadas): " + error_bd(e), "error")
    return redirect(url_for("productos"))


@app.route("/stock/<int:id_producto>/ingreso", methods=["POST"])
def stock_ingreso(id_producto):
    unidades = entero(request.form.get("unidades"), 0)
    if unidades <= 0:
        flash("Ingrese una cantidad mayor a 0.", "error")
    else:
        ejecutar(
            "UPDATE stock SET cantidad = cantidad + %s, fecha_act = CURDATE() WHERE id_producto = %s",
            (unidades, id_producto),
        )
        flash(f"Se ingresaron {unidades} unidades.", "ok")
    return redirect(request.referrer or url_for("productos"))


# ---------------------------------------------------------------------
# Ventas
# ---------------------------------------------------------------------
@app.route("/ventas")
def ventas():
    desde = request.args.get("desde") or None
    hasta = request.args.get("hasta") or None
    sql = "SELECT * FROM v_resumen_ventas WHERE 1=1"
    params = []
    if desde:
        sql += " AND fecha >= %s"
        params.append(desde)
    if hasta:
        sql += " AND fecha <= %s"
        params.append(hasta)
    sql += " ORDER BY fecha DESC, hora DESC LIMIT 300"
    filas = consulta(sql, params)
    return render_template("ventas.html", filas=filas, desde=desde, hasta=hasta,
                           total=sum(f["total"] for f in filas))


@app.route("/ventas/<int:id_venta>")
def venta_detalle(id_venta):
    v = uno("SELECT * FROM v_resumen_ventas WHERE id_venta = %s", (id_venta,))
    if not v:
        flash("Venta no encontrada.", "error")
        return redirect(url_for("ventas"))
    lineas = consulta(
        """SELECT p.sku, p.nombre, d.cantidad, d.precio_unit,
                  d.cantidad * d.precio_unit AS subtotal
           FROM detalle_venta d JOIN producto p ON p.id_producto = d.id_producto
           WHERE d.id_venta = %s""",
        (id_venta,),
    )
    return render_template("venta_detalle.html", v=v, lineas=lineas)


@app.route("/ventas/ticket", methods=["POST"])
def emitir_ticket():
    r = llamar("CALL sp_emitir_ticket(NULL, @t, @n)", None, ["@t", "@n"])
    flash(f"Número {r['n']} entregado.", "ok")
    if request.form.get("desde") == "meson":
        return redirect(url_for("inicio", nuevo=1))
    return redirect(url_for("venta_nueva", ticket=r["t"]))


@app.route("/ventas/nueva", methods=["GET", "POST"])
def venta_nueva():
    if request.method == "POST":
        f = request.form
        items = []
        for prod, cant in zip(f.getlist("producto"), f.getlist("cantidad")):
            if entero(prod) and entero(cant, 0) > 0:
                items.append(f"{int(prod)}:{int(cant)}")
        if not items:
            flash("Agregue al menos un producto.", "error")
        else:
            try:
                r = llamar(
                    "CALL sp_registrar_venta(%s, %s, %s, %s, @v)",
                    (f["id_ticket"], f["id_cliente"], f["id_empleado"], ",".join(items)),
                    ["@v"],
                )
                flash(f"Venta #{r['v']} registrada correctamente.", "ok")
                return redirect(url_for("venta_detalle", id_venta=r["v"]))
            except pymysql.MySQLError as e:
                flash("Venta rechazada (ROLLBACK): " + error_bd(e), "error")
    tickets = consulta(
        "SELECT id_ticket, numero, fecha, hora FROM ticket WHERE estado = 'emitido' "
        "ORDER BY fecha DESC, numero"
    )
    clientes = consulta(
        """SELECT c.id_cliente, c.nombre, c.rut, t.nombre AS tipo, t.aplica_precio_may AS mayor FROM cliente c
           JOIN tipo_cliente t ON t.id_tipo_cliente = c.id_tipo_cliente ORDER BY c.nombre"""
    )
    empleados = consulta("SELECT id_empleado, nombre FROM empleado ORDER BY nombre")
    prods = consulta(
        "SELECT id_producto, producto, precio_det, precio_may, cantidad "
        "FROM v_stock_productos ORDER BY producto"
    )
    return render_template("venta_nueva.html", tickets=tickets, clientes=clientes,
                           empleados=empleados, prods=prods,
                           ticket_sel=entero(request.args.get("ticket")))


# ---------------------------------------------------------------------
# Reportes
# ---------------------------------------------------------------------
REPORTES = {
    "dia": ("Ventas por dia",
            """SELECT fecha, COUNT(*) AS n_ventas, SUM(total) AS monto_total,
                      ROUND(AVG(total)) AS ticket_promedio
               FROM venta GROUP BY fecha ORDER BY fecha DESC LIMIT 60"""),
    "tipo": ("Ventas por tipo de cliente",
             """SELECT tc.nombre AS tipo_cliente, COUNT(v.id_venta) AS n_ventas,
                       COALESCE(SUM(v.total),0) AS monto_total
                FROM tipo_cliente tc
                LEFT JOIN cliente cl ON cl.id_tipo_cliente = tc.id_tipo_cliente
                LEFT JOIN venta v ON v.id_cliente = cl.id_cliente
                GROUP BY tc.id_tipo_cliente, tc.nombre ORDER BY monto_total DESC"""),
    "top": ("Top 10 productos mas vendidos",
            """SELECT p.sku, p.nombre AS producto, SUM(d.cantidad) AS unidades,
                      SUM(d.cantidad*d.precio_unit) AS ingresos
               FROM detalle_venta d JOIN producto p ON p.id_producto = d.id_producto
               GROUP BY p.id_producto, p.sku, p.nombre ORDER BY unidades DESC LIMIT 10"""),
    "categoria": ("Ingresos por categoria",
                  """SELECT c.nombre AS categoria, SUM(d.cantidad*d.precio_unit) AS ingresos,
                            ROUND(100*SUM(d.cantidad*d.precio_unit) /
                                  (SELECT SUM(cantidad*precio_unit) FROM detalle_venta),1) AS pct
                     FROM detalle_venta d
                     JOIN producto p ON p.id_producto = d.id_producto
                     JOIN categoria c ON c.id_categoria = p.id_categoria
                     GROUP BY c.id_categoria, c.nombre ORDER BY ingresos DESC"""),
    "empleados": ("Ranking de empleados",
                  """SELECT e.nombre, e.cargo, COUNT(v.id_venta) AS n_ventas,
                            COALESCE(SUM(v.total),0) AS monto_vendido
                     FROM empleado e LEFT JOIN venta v ON v.id_empleado = e.id_empleado
                     GROUP BY e.id_empleado, e.nombre, e.cargo ORDER BY monto_vendido DESC"""),
    "tickets": ("Estado de tickets por dia",
                """SELECT fecha, SUM(estado='atendido') AS atendidos, SUM(estado='anulado') AS anulados,
                          SUM(estado='emitido') AS pendientes, COUNT(*) AS total_tickets
                   FROM ticket GROUP BY fecha ORDER BY fecha DESC LIMIT 60"""),
    "sin_venta": ("Productos sin ventas",
                  """SELECT p.sku, p.nombre FROM producto p
                     WHERE NOT EXISTS (SELECT 1 FROM detalle_venta d
                                       WHERE d.id_producto = p.id_producto)"""),
}
MONEDA = {"monto_total", "ticket_promedio", "ingresos", "monto_vendido"}


@app.route("/reportes")
def reportes():
    clave = request.args.get("r", "dia")
    if clave not in REPORTES:
        clave = "dia"
    titulo, sql = REPORTES[clave]
    filas = consulta(sql)
    return render_template("reportes.html", reportes=REPORTES, clave=clave, titulo=titulo,
                           filas=filas, sql=sql, moneda=MONEDA)


# ---------------------------------------------------------------------
# Procesamiento masivo
# ---------------------------------------------------------------------
@app.route("/procesos", methods=["GET", "POST"])
def procesos():
    if request.method == "POST":
        accion = request.form.get("accion")
        f = request.form
        try:
            if accion == "reajuste":
                cat = entero(f.get("id_categoria"))
                r = llamar("CALL sp_reajuste_precios(%s, %s, %s, @n)",
                           (cat, f.get("porcentaje"), f.get("motivo") or "Reajuste masivo"),
                           ["@n"])
                flash(f"Reajuste aplicado a {r['n']} productos.", "ok")
            elif accion == "reposicion":
                r = llamar("CALL sp_reposicion_masiva(%s, @p, @u)",
                           (entero(f.get("factor"), 2),), ["@p", "@u"])
                flash(f"Reposicion: {r['p']} productos, {r['u']} unidades.", "ok")
            elif accion == "cierre":
                r = llamar("CALL sp_cierre_dia(%s, @a)", (f.get("fecha") or None,), ["@a"])
                flash(f"Cierre de dia: {r['a']} tickets anulados.", "ok")
            elif accion == "recalcular":
                r = llamar("CALL sp_recalcular_totales(@c)", None, ["@c"])
                flash(f"Totales verificados: {r['c']} ventas corregidas.", "ok")
            elif accion == "simular":
                n = min(max(entero(f.get("cantidad"), 100), 1), 20000)
                r = llamar("CALL sp_generar_ventas_simuladas(%s, %s, @c)",
                           (n, entero(f.get("dias"), 30)), ["@c"])
                flash(f"Se generaron {r['c']} ventas simuladas.", "ok")
        except pymysql.MySQLError as e:
            flash("Proceso cancelado (ROLLBACK): " + error_bd(e), "error")
        return redirect(url_for("procesos"))
    historial = consulta(
        """SELECT h.*, p.nombre FROM historial_precio h
           JOIN producto p ON p.id_producto = h.id_producto
           ORDER BY h.id_historial DESC LIMIT 15"""
    )
    return render_template("procesos.html", historial=historial,
                           categorias=consulta("SELECT * FROM categoria ORDER BY nombre"),
                           hoy=date.today().isoformat())


if __name__ == "__main__":
    app.run(debug=True)
