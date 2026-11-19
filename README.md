# Distribuidora La Mundial — Fase 2: Implementación

Trabajo semestral de Base de Datos (UDP). Implementación en **MySQL 8** (probado también en MariaDB 10.11) del modelo de la fase Diseño.

## Contenido

| Ruta | Qué es | Punto de la pauta |
|---|---|---|
| `sql/01_creacion_tablas.sql` | Base `la_mundial`, 12 tablas, PK/FK/UNIQUE/CHECK | Sistema funcionando |
| `sql/02_carga_datos.sql` | Datos de prueba (≥ 4 tuplas por tabla) | Consultas |
| `sql/03_desnormalizacion.sql` | `venta.total` + 3 triggers | Desnormalización (0,5) |
| `sql/04_vistas.sql` | `v_stock_productos`, `v_resumen_ventas` | Vista (0,5) |
| `sql/05_indices.sql` | 3 índices secundarios + `EXPLAIN` | Índices secundarios (0,5) |
| `sql/06_consultas.sql` | 12 consultas de negocio | Consulta (0,5) |
| `sql/07_actualizaciones.sql` | INSERT / UPDATE / DELETE / ROLLBACK | Actualización (0,5) |
| `sql/08_procesamiento_masivo.sql` | 1 función + 7 procedimientos con transacciones | Procesamiento masivo (1,0) |
| `sql/la_mundial_completo.sql` | Los scripts 01–08 unidos, para ejecutar de una vez | |
| `app/` | Interfaz web (Python + Flask) | Puntaje adicional (interfaz) |
| `docs/Informe_Implementacion.docx` | Informe de la fase Implementación | |
| `docs/Presentacion_Implementacion.pptx` | Presentación para la demo | |

## Instalar la base de datos

En MySQL Workbench: abrir `sql/la_mundial_completo.sql` y ejecutar todo (⚡).

Desde la consola:

```bash
mysql -u root -p --table < sql/la_mundial_completo.sql
```

El script borra y vuelve a crear la base `la_mundial`, así que se puede ejecutar de nuevo para partir de cero antes de la demo.

## Ejecutar la interfaz web

```bash
cd app
pip install -r requirements.txt
```

Variables de conexión (por defecto `127.0.0.1:3306`, usuario `root`, base `la_mundial`): `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`.

```bash
DB_PASSWORD=tu_clave python app.py
```

En Windows (PowerShell): `$env:DB_PASSWORD="tu_clave"; python app.py`. Luego abrir http://127.0.0.1:5000

## Guion de demostración

1. **Productos y stock** → buscar "Chocolate" (usa `idx_producto_nombre`).
2. **Nueva venta** → emitir ticket, elegir un cliente mayorista y vender: se aplica `precio_may` y se descuenta el stock.
3. Repetir pidiendo 9999 unidades → la venta se rechaza completa (ROLLBACK).
4. **Procesos masivos** → reajuste de 5 % a Chocolates (ver historial), reposición, generar 1000 ventas.
5. **Reportes** → ventas por día, por tipo de cliente, top productos.
