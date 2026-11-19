---
version: 1
slug: "web-templates-base-html"
primary_target: "web/templates/base.html"
related_targets: ["app/templates/base.html"]
---

# Interfaz de mesón: Confitería La Mundial

Scope: todas las pantallas de la app (web/templates y app/templates comparten plantillas). Visitor mode: Operate.
Audience: vendedores y cajeros en el mesón en hora punta; demostración proyectada en sala de clases.
Task: entregar número, buscar producto, registrar venta con precio por tipo de cliente, ver qué reponer.
Constraints: controles web estándar; elementos de BD evaluados visibles como notas discretas; montos CLP.

## Direction contract

THESIS: La pantalla habla como los carteles de precio rotulados a mano de los mayoristas de Santiago: cifras que se leen desde la fila. Rechaza el panel SaaS gris con tarjetas KPI y el kitsch pastel de dulcería.

OWN-WORLD: Fondo blanco cartulina (página y paneles en blanco puro), tinta negra plena y rojo marcador del logo (#D7261E aprox.); amarillo cartulina flúor solo en carteles de precio y turno. Archivo para la interfaz (pesos 500–900, ancho normal y condensado), Yellowtail solo para la marca, Knewave solo para cifras de cartel (reemplaza a Permanent Marker, cuyo "1" se leía como comillas en el número de turno). Bordes negros de 2px, esquinas casi rectas, sin sombras difusas.

STORY: El vendedor ve el número que sigue, lo entrega, encuentra el producto con su precio grande, registra la venta y sabe qué reponer.

FIRST VIEWPORT: Barra superior blanca: marca manuscrita roja + "Confitería" negra a la izquierda, navegación en pestañas a la derecha. Debajo, a la izquierda, el cartel de turno: cartulina amarilla levemente girada con "Próximo número" y la cifra en rojo marcador a ~140px; botón negro "Entregar número N". A la derecha, cartel "Por reponer" con lista corta. Luego franja de cifras del día y tabla de últimas ventas.

FORM: Cartel pintado a mano, posición 1 de mi lista ordenada (la tirada asignó la 3; el usuario eligió la opción propia). seed:62e777d73b92740b
Signature move: precios y número de turno rotulados como cartel (Knewave roja sobre cartulina amarilla) en Mesón, catálogo y total de la venta; nunca en tablas densas de reportes.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
