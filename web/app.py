"""
Distribuidora La Mundial - interfaz web publicada en Vercel.

Misma aplicacion que app/app.py (MySQL), pero la base de datos es
PostgreSQL en Supabase. La app se comunica con la API REST de Supabase
(PostgREST): lee las vistas y ejecuta las funciones PL/pgSQL por RPC.

Variables de entorno: SUPABASE_URL y SUPABASE_KEY (llave publicable).
"""
import os
from datetime import datetime
from zoneinfo import ZoneInfo

import requests
from flask import Flask, flash, redirect, render_template, request, url_for

app = Flask(__name__)
app.secret_key = os.environ.get("SECRET_KEY", "la-mundial-vercel")

SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://dxzzkjkamnybmkflipyi.supabase.co").rstrip("/")
# Llave "publicable": esta pensada para ser publica; la seguridad la da RLS
# (solo lectura) + funciones SECURITY DEFINER para escribir.
SUPABASE_KEY = os.environ.get("SUPABASE_KEY", "sb_publishable_-7PlPl4eHDpywNxXw9yG6w_8t5XgtN5")
HEADERS = {"apikey": SUPABASE_KEY, "Content-Type": "application/json"}
API = SUPABASE_URL + "/rest/v1/"
sesion = requests.Session()


class ErrorBD(Exception):
    pass


def _respuesta(r):
    if r.status_code >= 400:
        try:
            msg = r.json().get("message") or r.text
        except ValueError:
            msg = r.text
        raise ErrorBD(msg)
    return r.json() if r.content else None


def leer(recurso, **params):
    """GET sobre una tabla o vista (filtros con sintaxis PostgREST)."""
    params.setdefault("select", "*")
    return _respuesta(sesion.get(API + recurso, headers=HEADERS, params=params, timeout=20))


def rpc(funcion, **args):
    """Ejecuta una funcion PL/pgSQL."""
    return _respuesta(sesion.post(API + "rpc/" + funcion, headers=HEADERS, json=args, timeout=25))


def entero(valor, defecto=None):
    try:
        return int(valor)
    except (TypeError, ValueError):
        return defecto


def hoy():
    return datetime.now(ZoneInfo("America/Santiago")).date().isoformat()


@app.template_filter("clp")
def clp(valor):
    if valor is None:
        return "-"
    return "$" + f"{int(float(valor)):,}".replace(",", ".")


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


@app.errorhandler(ErrorBD)
def error_bd(e):
    flash("Error de base de datos: " + str(e), "error")
    return render_template("base.html"), 500


@app.context_processor
def contexto():
    return {"motor": "PostgreSQL en Supabase"}


# ---------------------------------------------------------------------
@app.route("/")
def inicio():
    kpi = rpc("fn_kpis")
    ultimas = leer("v_resumen_ventas", order="fecha.desc,hora.desc", limit=8)
    reponer = leer("v_stock_productos", select="producto,cantidad,stock_min,estado_stock",
                   estado_stock="neq.OK", order="unidades_faltantes.desc", limit=8)
    ult = leer("ticket", select="numero", fecha=f"eq.{hoy()}", order="numero.desc", limit=1)
    siguiente = (ult[0]["numero"] if ult else 0) + 1
    return render_template("inicio.html", kpi=kpi, ultimas=ultimas, reponer=reponer,
                           siguiente=siguiente, nuevo_ticket=bool(request.args.get("nuevo")))


def catalogos():
    return dict(
        categorias=leer("categoria", order="nombre"),
        marcas=leer("marca", order="nombre"),
        proveedores=leer("proveedor", order="razon_social"),
    )


@app.route("/productos")
def productos():
    q = request.args.get("q", "").strip()
    cat = entero(request.args.get("categoria"))
    filas = rpc("fn_buscar_productos", p_q=q, p_categoria=cat)
    return render_template("productos.html", filas=filas, q=q, cat=cat, **catalogos())


def _guardar_producto(id_producto):
    f = request.form
    rpc("fn_producto_guardar", p_id=id_producto, p_sku=f["sku"], p_nombre=f["nombre"],
        p_precio_det=entero(f["precio_det"]), p_precio_may=entero(f["precio_may"]),
        p_id_categoria=entero(f["id_categoria"]), p_id_marca=entero(f["id_marca"]),
        p_id_proveedor=entero(f["id_proveedor"]), p_stock_min=entero(f.get("stock_min"), 0),
        p_cantidad=entero(f.get("cantidad"), 0))


@app.route("/productos/nuevo", methods=["GET", "POST"])
def producto_nuevo():
    if request.method == "POST":
        try:
            _guardar_producto(None)
            flash(f"Producto '{request.form['nombre']}' creado.", "ok")
            return redirect(url_for("productos"))
        except ErrorBD as e:
            flash("No se pudo crear: " + str(e), "error")
    return render_template("producto_form.html", p=None, **catalogos())


@app.route("/productos/<int:id_producto>/editar", methods=["GET", "POST"])
def producto_editar(id_producto):
    if request.method == "POST":
        try:
            _guardar_producto(id_producto)
            flash("Producto actualizado.", "ok")
            return redirect(url_for("productos"))
        except ErrorBD as e:
            flash("No se pudo actualizar: " + str(e), "error")
    filas = leer("producto", select="*,stock(cantidad,stock_min)", id_producto=f"eq.{id_producto}")
    if not filas:
        flash("Producto no encontrado.", "error")
        return redirect(url_for("productos"))
    p = filas[0]
    st = p.pop("stock") or {}
    if isinstance(st, list):
        st = st[0] if st else {}
    p.update(st)
    return render_template("producto_form.html", p=p, **catalogos())


@app.route("/productos/<int:id_producto>/eliminar", methods=["POST"])
def producto_eliminar(id_producto):
    try:
        rpc("fn_producto_eliminar", p_id=id_producto)
        flash("Producto eliminado.", "ok")
    except ErrorBD as e:
        flash("No se puede eliminar (tiene ventas asociadas): " + str(e), "error")
    return redirect(url_for("productos"))


@app.route("/stock/<int:id_producto>/ingreso", methods=["POST"])
def stock_ingreso(id_producto):
    unidades = entero(request.form.get("unidades"), 0)
    try:
        rpc("fn_stock_ingreso", p_id=id_producto, p_unidades=unidades)
        flash(f"Se ingresaron {unidades} unidades.", "ok")
    except ErrorBD as e:
        flash(str(e), "error")
    return redirect(request.referrer or url_for("productos"))


# ---------------------------------------------------------------------
@app.route("/ventas")
def ventas():
    desde = request.args.get("desde") or None
    hasta = request.args.get("hasta") or None
    params = {"order": "fecha.desc,hora.desc", "limit": 300}
    filtros = []
    if desde:
        filtros.append(f"fecha.gte.{desde}")
    if hasta:
        filtros.append(f"fecha.lte.{hasta}")
    if filtros:
        params["and"] = "(" + ",".join(filtros) + ")"
    filas = leer("v_resumen_ventas", **params)
    return render_template("ventas.html", filas=filas, desde=desde, hasta=hasta,
                           total=sum(f["total"] for f in filas))


@app.route("/ventas/<int:id_venta>")
def venta_detalle(id_venta):
    v = leer("v_resumen_ventas", id_venta=f"eq.{id_venta}")
    if not v:
        flash("Venta no encontrada.", "error")
        return redirect(url_for("ventas"))
    lineas = []
    for d in leer("detalle_venta", select="cantidad,precio_unit,producto(sku,nombre)",
                  id_venta=f"eq.{id_venta}", order="id_detalle"):
        lineas.append(dict(sku=d["producto"]["sku"], nombre=d["producto"]["nombre"],
                           cantidad=d["cantidad"], precio_unit=d["precio_unit"],
                           subtotal=d["cantidad"] * d["precio_unit"]))
    return render_template("venta_detalle.html", v=v[0], lineas=lineas)


@app.route("/ventas/ticket", methods=["POST"])
def emitir_ticket():
    r = rpc("sp_emitir_ticket")[0]
    flash(f"Número {r['numero']} entregado.", "ok")
    if request.form.get("desde") == "meson":
        return redirect(url_for("inicio", nuevo=1))
    return redirect(url_for("venta_nueva", ticket=r["id_ticket"]))


@app.route("/ventas/nueva", methods=["GET", "POST"])
def venta_nueva():
    if request.method == "POST":
        f = request.form
        items = [f"{int(p)}:{int(c)}" for p, c in zip(f.getlist("producto"), f.getlist("cantidad"))
                 if entero(p) and entero(c, 0) > 0]
        if not items:
            flash("Agregue al menos un producto.", "error")
        else:
            try:
                id_venta = rpc("sp_registrar_venta", p_id_ticket=entero(f.get("id_ticket")),
                               p_id_cliente=entero(f["id_cliente"]),
                               p_id_empleado=entero(f["id_empleado"]), p_items=",".join(items))
                flash(f"Venta #{id_venta} registrada correctamente.", "ok")
                return redirect(url_for("venta_detalle", id_venta=id_venta))
            except ErrorBD as e:
                flash("Venta rechazada (ROLLBACK): " + str(e), "error")
    tickets = leer("ticket", select="id_ticket,numero,fecha,hora", estado="eq.emitido",
                   order="fecha.desc,numero")
    clientes = [dict(c, tipo=c["tipo_cliente"]["nombre"]) for c in
                leer("cliente", select="id_cliente,nombre,rut,tipo_cliente(nombre)", order="nombre")]
    empleados = leer("empleado", select="id_empleado,nombre", order="nombre")
    prods = leer("v_stock_productos", select="id_producto,producto,precio_det,precio_may,cantidad",
                 order="producto")
    return render_template("venta_nueva.html", tickets=tickets, clientes=clientes,
                           empleados=empleados, prods=prods,
                           ticket_sel=entero(request.args.get("ticket")))


# ---------------------------------------------------------------------
REPORTES = {
    "dia": ("Ventas por dia", "rpt_ventas_dia", {"order": "fecha.desc", "limit": 60}),
    "tipo": ("Ventas por tipo de cliente", "rpt_ventas_tipo", {"order": "monto_total.desc"}),
    "top": ("Top 10 productos mas vendidos", "rpt_top_productos", {"order": "unidades.desc", "limit": 10}),
    "categoria": ("Ingresos por categoria", "rpt_ingresos_categoria", {"order": "ingresos.desc"}),
    "empleados": ("Ranking de empleados", "rpt_ranking_empleados", {"order": "monto_vendido.desc"}),
    "tickets": ("Estado de tickets por dia", "rpt_tickets_dia", {"order": "fecha.desc", "limit": 60}),
    "sin_venta": ("Productos sin ventas", "rpt_productos_sin_venta", {}),
}
MONEDA = {"monto_total", "ticket_promedio", "ingresos", "monto_vendido"}


@app.route("/reportes")
def reportes():
    clave = request.args.get("r", "dia")
    if clave not in REPORTES:
        clave = "dia"
    titulo, vista, params = REPORTES[clave]
    filas = leer(vista, **params)
    orden = params.get("order", "").replace(".desc", " DESC").replace(".asc", "")
    sql = f"SELECT * FROM {vista}" + (f" ORDER BY {orden}" if orden else "") + \
          (f" LIMIT {params['limit']}" if "limit" in params else "") + \
          ";\n\n-- La definicion de la vista esta en supabase/04_vistas.sql"
    return render_template("reportes.html", reportes=REPORTES, clave=clave, titulo=titulo,
                           filas=filas, sql=sql, moneda=MONEDA)


@app.route("/procesos", methods=["GET", "POST"])
def procesos():
    if request.method == "POST":
        f = request.form
        accion = f.get("accion")
        try:
            if accion == "reajuste":
                n = rpc("sp_reajuste_precios", p_id_categoria=entero(f.get("id_categoria")),
                        p_porcentaje=float(f.get("porcentaje") or 0),
                        p_motivo=f.get("motivo") or "Reajuste masivo")
                flash(f"Reajuste aplicado a {n} productos.", "ok")
            elif accion == "reposicion":
                r = rpc("sp_reposicion_masiva", p_factor=entero(f.get("factor"), 2))[0]
                flash(f"Reposicion: {r['productos']} productos, {r['unidades']} unidades.", "ok")
            elif accion == "cierre":
                n = rpc("sp_cierre_dia", p_fecha=f.get("fecha") or None)
                flash(f"Cierre de dia: {n} tickets anulados.", "ok")
            elif accion == "recalcular":
                n = rpc("sp_recalcular_totales")
                flash(f"Totales verificados: {n} ventas corregidas.", "ok")
            elif accion == "simular":
                cant = min(max(entero(f.get("cantidad"), 100), 1), 500)
                n = rpc("sp_generar_ventas_simuladas", p_cantidad=cant, p_dias=entero(f.get("dias"), 30))
                flash(f"Se generaron {n} ventas simuladas.", "ok")
        except (ErrorBD, ValueError) as e:
            flash("Proceso cancelado (ROLLBACK): " + str(e), "error")
        return redirect(url_for("procesos"))
    historial = leer("v_historial_precio", order="id_historial.desc", limit=15)
    for h in historial:
        h["fecha_cambio"] = h["fecha_cambio"][:19].replace("T", " ")
    return render_template("procesos.html", historial=historial,
                           categorias=leer("categoria", order="nombre"), hoy=hoy(), max_simular=500)


if __name__ == "__main__":
    app.run(debug=True)
