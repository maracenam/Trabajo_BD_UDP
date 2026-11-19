# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Vendedores y cajeros en el mesón de Confitería La Mundial, atendiendo en hora punta con fila de clientes: mayoristas y minoristas de Santiago, y turistas (sobre todo brasileños) que compran chocolates en cantidad en otoño-invierno. Su trabajo: entregar el número de atención, buscar productos rápido, registrar la venta con el precio correcto según el tipo de cliente y saber qué falta reponer. Secundario: el profesor del ramo Base de Datos (UDP), que evalúa el sistema en una demostración en sala de clases.

## Product Purpose

Sistema interno de ventas y stock que reemplaza un registro rudimentario con productos duplicados, nombres inconsistentes y stock poco confiable. Éxito: atender más rápido en el mesón, un catálogo único por SKU, stock real en una sola fila por producto, ventas registradas por tipo de cliente. Es el trabajo semestral (fase Implementación) del ramo Base de Datos.

## Positioning

La atención por número de ticket es el corazón del local: el número de turno conecta la fila física con la venta registrada. Precio por mayor o al detalle se aplica solo según el tipo de cliente.

## Operating Context

- Atención por tickets numerados que se reinician cada día; cada venta nace de un ticket (estados: en espera, atendido, anulado).
- Dos líneas de negocio: confites, chocolates, galletas, bebidas y snacks; y aseo personal (escenario del trabajo).
- Tipos de cliente: Minorista, Mayorista, Turista, Distribuidor.
- Demostración en notebook o proyector en sala de clases (UDP).
- Montos en pesos chilenos, sin decimales.

## Capabilities and Constraints

- Flask con dos backends: `app/` (MySQL local) y `web/` (Supabase/PostgreSQL, publicado en Vercel). Las plantillas Jinja son las mismas en ambos.
- Pantallas: Mesón (inicio), Nueva venta, Productos y stock (CRUD + ingreso), Ventas y detalle, Reportes, Procesos masivos.
- La interfaz debe dejar visibles, sin estorbar, los elementos que se evalúan: vista `v_stock_productos`, índice `idx_producto_nombre`, desnormalización `venta.total`, procedimientos almacenados y transacciones.

## Brand Commitments

- Nombre real: **Confitería La Mundial** (confiterialamundial.cl). Lema público: "Un mundo en dulces y confites". Se presenta como "la distribuidora de confites al por mayor más rica de Santiago".
- Logotipo: "La Mundial" en letra manuscrita de pincel, rojo tomate, con "CONFITERÍA" en sans negra pesada debajo.
- Locales reales: casa matriz Chiloé 1996 (Santiago), sucursal Alameda 2783 (Santiago), además de San Bernardo, Puente Alto, Las Condes y Ñuñoa. Horario de tiendas: lunes a viernes 9:30–17:45, sábado 9:30–13:30.

## Evidence on Hand

- Logo de referencia del sitio público (no se embebe el archivo; la marca se reproduce tipográficamente).
- Datos de demostración en `sql/02_carga_datos.sql` y `supabase/02_datos.sql` (sintéticos: clientes, empleados, ventas).
- No hay testimonios, cifras de negocio ni fotos propias del local: no inventarlos.

## Product Principles

1. La fila manda: lo primero en pantalla es el turno y la acción de atender.
2. Un producto, un SKU, un stock: la interfaz nunca muestra duplicados ni cifras ambiguas.
3. Cero cálculo mental para el vendedor: precio y stock correctos a la vista.
4. La base de datos se demuestra trabajando, no con carteles.

## Accessibility & Inclusion

Uso rápido de pie en el mesón y proyección en sala: textos grandes y de alto contraste, foco de teclado visible, controles de al menos 42 px.
