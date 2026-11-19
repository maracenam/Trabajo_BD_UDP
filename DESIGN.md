---
name: Confitería La Mundial · Sistema de mesón
description: Interfaz de ventas y stock que habla como los carteles de precio rotulados a mano de los mayoristas de Santiago.
colors:
  rojo: "#D7261E"
  amarillo: "#FFE14A"
  tinta: "#000000"
  tinta-2: "#4A4A4A"
  linea: "#DCDAD5"
  cartulina: "#FFFFFF"
  fondo: "#FFFFFF"
  ok: "#17703A"
  ok-fondo: "#E2F1E6"
  alerta: "#8A5200"
  alerta-fondo: "#FFF0C7"
  error: "#B3150D"
  error-fondo: "#FDE3E0"
typography:
  marca:
    fontFamily: "Yellowtail, cursive"
    fontSize: "44px"
    fontWeight: 400
    lineHeight: 0.95
    letterSpacing: "0em"
  rotulo-turno:
    fontFamily: "Knewave, Archivo, sans-serif"
    fontSize: "clamp(110px, 12vw, 160px)"
    fontWeight: 400
    lineHeight: 0.82
    letterSpacing: "0.02em"
  rotulo-total:
    fontFamily: "Knewave, Archivo, sans-serif"
    fontSize: "54px"
    fontWeight: 400
    lineHeight: 0.9
    letterSpacing: "0.02em"
  rotulo-precio:
    fontFamily: "Knewave, Archivo, sans-serif"
    fontSize: "17px"
    fontWeight: 400
    lineHeight: 1.15
    letterSpacing: "0.03em"
  display:
    fontFamily: "Archivo, Helvetica, Arial, sans-serif"
    fontSize: "clamp(32px, 3.6vw, 46px)"
    fontWeight: 900
    lineHeight: 1
    letterSpacing: "-0.01em"
    fontVariation: "'wdth' 85"
  headline:
    fontFamily: "Archivo, Helvetica, Arial, sans-serif"
    fontSize: "22px"
    fontWeight: 800
    lineHeight: 1.15
    fontVariation: "'wdth' 90"
  cifra:
    fontFamily: "Archivo, Helvetica, Arial, sans-serif"
    fontSize: "30px"
    fontWeight: 900
    lineHeight: 1.05
    fontVariation: "'wdth' 80"
    fontFeature: "'tnum'"
  title:
    fontFamily: "Archivo, Helvetica, Arial, sans-serif"
    fontSize: "15px"
    fontWeight: 700
    lineHeight: 1
  body:
    fontFamily: "Archivo, Helvetica, Arial, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
    fontFeature: "'tnum'"
  bajada:
    fontFamily: "Archivo, Helvetica, Arial, sans-serif"
    fontSize: "17px"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "Archivo, Helvetica, Arial, sans-serif"
    fontSize: "14.5px"
    fontWeight: 700
    lineHeight: 1.5
  encabezado-tabla:
    fontFamily: "Archivo, Helvetica, Arial, sans-serif"
    fontSize: "14px"
    fontWeight: 800
    lineHeight: 1.2
    fontVariation: "'wdth' 90"
  nota:
    fontFamily: "Archivo, Helvetica, Arial, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.5
rounded:
  precio: "2px"
  sm: "3px"
  md: "4px"
spacing:
  xs: "6px"
  sm: "12px"
  md: "16px"
  lg: "24px"
  xl: "32px"
components:
  boton:
    backgroundColor: "{colors.tinta}"
    textColor: "{colors.cartulina}"
    rounded: "{rounded.md}"
    padding: "0 20px"
    height: "46px"
  boton-hover:
    backgroundColor: "{colors.rojo}"
    textColor: "{colors.cartulina}"
  boton-sec:
    backgroundColor: "{colors.cartulina}"
    textColor: "{colors.tinta}"
    rounded: "{rounded.md}"
    padding: "0 20px"
    height: "46px"
  boton-sec-hover:
    backgroundColor: "{colors.amarillo}"
    textColor: "{colors.tinta}"
  boton-peligro:
    backgroundColor: "{colors.cartulina}"
    textColor: "{colors.error}"
    rounded: "{rounded.md}"
    padding: "0 20px"
    height: "46px"
  boton-peligro-hover:
    backgroundColor: "{colors.error-fondo}"
    textColor: "{colors.error}"
  boton-chico:
    padding: "0 12px"
    height: "36px"
  campo:
    backgroundColor: "{colors.cartulina}"
    textColor: "{colors.tinta}"
    rounded: "{rounded.md}"
    padding: "9px 11px"
    height: "44px"
  cartel:
    backgroundColor: "{colors.amarillo}"
    textColor: "{colors.tinta}"
    rounded: "{rounded.sm}"
    padding: "26px 32px 28px"
  precio:
    backgroundColor: "{colors.amarillo}"
    textColor: "{colors.rojo}"
    typography: "{typography.rotulo-precio}"
    rounded: "{rounded.precio}"
    padding: "3px 8px 1px"
  panel:
    backgroundColor: "{colors.cartulina}"
    textColor: "{colors.tinta}"
    rounded: "{rounded.md}"
    padding: "22px 24px"
  menu-item:
    backgroundColor: "{colors.cartulina}"
    textColor: "{colors.tinta}"
    typography: "{typography.title}"
    padding: "14px 14px 13px"
  menu-item-hover:
    backgroundColor: "{colors.amarillo}"
    textColor: "{colors.tinta}"
  menu-item-actual:
    backgroundColor: "{colors.tinta}"
    textColor: "{colors.cartulina}"
  estado-ok:
    backgroundColor: "{colors.ok-fondo}"
    textColor: "{colors.ok}"
    rounded: "{rounded.sm}"
    padding: "2px 8px"
  estado-reponer:
    backgroundColor: "{colors.alerta-fondo}"
    textColor: "{colors.alerta}"
    rounded: "{rounded.sm}"
    padding: "2px 8px"
  estado-sin-stock:
    backgroundColor: "{colors.error-fondo}"
    textColor: "{colors.error}"
    rounded: "{rounded.sm}"
    padding: "2px 8px"
---

# Design System: Confitería La Mundial · Sistema de mesón

## Overview

**Creative North Star: "El cartel del mayorista"**

La interfaz se comporta como el mesón de un mayorista de confites de Santiago: cartulina blanca, tinta negra plena, el rojo marcador del logo y, donde importa una cifra que debe leerse desde la fila, un cartel de cartulina amarilla rotulado a mano y colgado levemente torcido. Todo lo demás es mostrador de trabajo: tablas con borde negro, botones negros que se vuelven rojos, etiquetas en Archivo pesada. Rechaza explícitamente el panel SaaS gris con tarjetas KPI y el kitsch pastel de dulcería.

La densidad es de herramienta de mesón, no de tablero: textos grandes, alto contraste y controles de al menos 44 px, porque se usa de pie en hora punta y se proyecta en sala de clases. La expresividad está concentrada en tres lugares (la marca manuscrita, el número de turno y los precios/total rotulados); el resto del sistema es sobrio a propósito para que esos tres griten.

Los elementos de base de datos que se evalúan (vista, índice, procedimientos, transacciones) aparecen como notas discretas en gris con el nombre técnico en `code`, nunca como carteles.

**Key Characteristics:**
- Fondo y paneles blanco puro; tinta negra `#000` para texto, bordes y botón primario.
- Bordes negros de 2px y esquinas casi rectas (2–4px) en todo contenedor.
- Cartel amarillo girado como único gesto decorativo, reservado a turno, precio y total.
- Tres familias con funciones cerradas: Archivo (interfaz), Yellowtail (marca), Knewave (cifras de cartel).
- Cifras tabulares en todo el documento; montos CLP sin decimales.
- Sin sombras difusas: la profundidad es borde y color, no elevación.

## Colors

Paleta de mesón: cartulina blanca y tinta negra con un rojo marcador como única voz de acento y un amarillo flúor que solo existe dentro de los carteles.

### Primary
- **Rojo marcador** (`rojo`): el rojo tomate del logo. Marca "La Mundial", cifras rotuladas (turno, precio, total), estado hover de botón primario, subrayado de enlaces, anillo de foco, caret y `accent-color` de campos, y cifras que piden atención (`quedan N`, "Productos por reponer" cuando es distinto de cero).

### Secondary
- **Amarillo cartulina** (`amarillo`): fondo del cartel de turno, del total de la venta y de las etiquetas de precio. Fuera de los carteles solo aparece como respuesta a interacción: hover de menú, pestañas y botón secundario, anillo de foco de campos y selección de texto.

### Neutral
- **Tinta** (`tinta`): texto principal, todos los bordes estructurales (2px), barra inferior del encabezado (3px), botón primario y pestaña actual.
- **Tinta gastada** (`tinta-2`): bajadas, notas, `dt` de cifras, texto tenue, placeholders, pie del motor.
- **Línea de lápiz** (`linea`): separadores internos de filas, listas y celdas de la franja de cifras.
- **Cartulina** (`cartulina`) y **Fondo** (`fondo`): ambos blanco puro; página, barra, paneles, tablas y campos.

### Estados
- **Verde atendido** (`ok` sobre `ok-fondo`): stock OK, número atendido, aviso de éxito.
- **Ámbar reponer** (`alerta` sobre `alerta-fondo`): bajo mínimo, número en espera/emitido.
- **Rojo error** (`error` sobre `error-fondo`): sin stock, anulado, aviso de error, botón Eliminar. Es un rojo más oscuro que `rojo` para que el error no se confunda con la marca.

### Named Rules
**The Cartulina Amarilla Rule.** El amarillo en reposo solo vive dentro de un cartel (turno, precio, total). Fuera de él aparece únicamente como respuesta a hover, foco o selección.

**The Un Solo Rojo Rule.** `rojo` es marca y cifra de cartel; `error` es error. No se intercambian.

## Typography

**Display Font:** Archivo (con Helvetica, Arial, sans-serif), variable 100–900 y ancho 62–125%, autoalojada
**Brand Font:** Yellowtail (con cursive), solo para "La Mundial"
**Rótulo Font:** Knewave (con Archivo), solo para cifras de cartel

**Character:** Archivo pesada y algo condensada hace de letrero de mostrador; Knewave pone la mano del rotulador en las cifras que se leen desde la fila; Yellowtail reproduce tipográficamente el pincel del logo. Knewave reemplazó a Permanent Marker porque su "1" se leía como comillas en el número de turno.

### Hierarchy
- **Marca** (Yellowtail 400, 44px, 36px bajo 960px, girada −4°): solo el logotipo, sobre "CONFITERÍA" en Archivo 900 12px con 0.04em.
- **Rótulo turno** (Knewave 400, clamp(110px, 12vw, 160px), 0.82): el próximo número en el cartel del Mesón.
- **Rótulo total** (Knewave 400, 54px, 34px en móvil): total a cobrar en Nueva venta.
- **Rótulo precio** (Knewave 400, 17px, 0.03em): precio al detalle en el catálogo.
- **Display** (Archivo 900, clamp(32px, 3.6vw, 46px), ancho 85%, −0.01em): un H1 por pantalla.
- **Headline** (Archivo 800, 22px, ancho 90%): títulos de sección y panel; 20px en el cartel de turno, 18px en el total.
- **Cifra** (Archivo 900, 30px, ancho 80%): valores de la franja de cifras del día.
- **Title** (Archivo 700, 15px): ítems de menú y pestañas.
- **Body** (Archivo 400, 16px/1.5, cifras tabulares): texto corriente; tablas a 15.5px.
- **Bajada** (Archivo 400, 17px, máx. 66ch, `tinta-2`): frase bajo el H1.
- **Label** (Archivo 700, 14.5px): etiquetas de campo; encabezados de tabla en 800 14px ancho 90%.
- **Nota** (Archivo 400, 14px, máx. 75ch, `tinta-2`): notas técnicas de base de datos, texto tenue.

### Named Rules
**The Tres Voces Rule.** Yellowtail solo dice "La Mundial"; Knewave solo rotula cifras de cartel (turno, precio, total); todo lo demás es Archivo. Knewave nunca entra a tablas densas de reportes, ventas o historial.

**The Cifra Tabular Rule.** `font-variant-numeric: tabular-nums` está en `body`; montos y cantidades se alinean a la derecha en tablas.

## Layout

Contenedor centrado de 1280px máx. con 32px de margen lateral (16px bajo 960px). La barra superior pone la marca a la izquierda y el menú en pestañas alineado a la derecha y al borde inferior; bajo 960px el menú baja a ancho completo.

Cada pantalla abre con una cabecera flexible (H1 + bajada a la izquierda, acción principal a la derecha, 24px abajo). El Mesón es una grilla 1.25fr / 1fr (cartel de turno + panel "Por reponer", 32px de separación), seguida de la franja de cifras (`auto-fit, minmax(170px, 1fr)`) y la tabla de últimas ventas. Nueva venta es grilla 1fr / 300px con el cartel del total pegajoso (`top: 20px`); bajo 960px colapsa a una columna y el total se vuelve barra pegajosa inferior sin giro. Los formularios usan `auto-fit, minmax(min(220px, 100%), 1fr)` con 16px de separación.

Bajo 640px el catálogo deja de ser tabla: cada producto es un bloque en grilla de dos columnas con acciones a ancho completo, sin desplazamiento lateral; columnas secundarias se ocultan.

Ritmo de espacio observado: 6 / 12 / 16 / 24 / 32px, con 22px para relleno de paneles y márgenes entre bloques, y 28–40px entre secciones.

## Elevation & Depth

Sistema plano. No hay sombras difusas ni elevación: la profundidad se expresa con bordes negros de 2px, el contraste blanco/amarillo y el giro del cartel. El único `box-shadow` del sistema es una línea dura de 2px en `linea` (`2px 0 0, 0 2px 0`) usada como divisor interno de celdas en la franja de cifras y en la grilla de procesos: es un trazo de separación, no una sombra.

### Named Rules
**The Sin Sombra Rule.** Nada flota. Un elemento se distingue por borde, color o rotación, nunca por sombra difusa.

## Shapes

Esquinas casi rectas: 4px (`md`) para paneles, tablas, botones, campos, pestañas y avisos; 3px (`sm`) para el cartel, los estados y `code`; 2px (`precio`) para la etiqueta de precio. Los ítems del menú redondean solo arriba (4px 4px 0 0) para leerse como pestañas sobre la línea negra de 3px.

Bordes: 2px `tinta` en todo contenedor estructural, 3px bajo la barra superior, 1.5px en etiquetas de precio y estados (`currentColor`), 1px `linea` en separadores de fila.

Rotación: el cartel cuelga a −1.2°, la etiqueta de precio a −2°, la marca a −4°. Es la única geometría no ortogonal del sistema.

## Components

### Buttons
Contundentes y planos, como un cartel de "caja".
- **Shape:** esquinas casi rectas (4px), borde 2px, alto mínimo 46px, Archivo 800 16px.
- **Primary (`boton`):** fondo `tinta`, texto blanco, relleno horizontal 20px.
- **Hover / Focus:** pasa a `rojo` (fondo y borde); al presionar baja 1px; foco con anillo `rojo` de 3px a 2px de distancia.
- **Secundario (`boton sec`):** blanco con borde y texto `tinta`; hover amarillo.
- **Peligro (`boton peligro`):** blanco con borde y texto `error`; hover `error-fondo`.
- **Chico (`boton chico`):** 36px de alto, 12px de relleno, 14px; para acciones por fila.
- **Cargando:** al enviar un formulario POST el texto cambia a `data-cargando` (o "Procesando…"), `aria-busy` y opacidad 0.65; evita entregar dos números.

### Cartel (componente firma)
Cartulina amarilla con borde negro 2px, esquina 3px, girada −1.2°. Contiene una cifra en Knewave roja. Dos usos: **turno** (título "Próximo número", cifra de 110–160px, texto y botón negro "Entregar número N" al lado) y **total de la venta** (título "Total a cobrar", monto 54px, regla de precio, botón Registrar). Al entregar un número nuevo el cartel de turno "se cuelga": cae 18px desde −6° en 0.7s con `cubic-bezier(.2, .8, .25, 1)`, solo si el usuario no pide movimiento reducido.

### Etiqueta de precio
Mini-cartel inline: amarillo, borde 1.5px `tinta`, esquina 2px, Knewave 17px roja, girada −2°. Marca el precio al detalle en el catálogo; el precio por mayor va en Archivo 700 a su lado.

### Cards / Containers
- **Corner Style:** 4px.
- **Background:** `cartulina`.
- **Shadow Strategy:** ninguna (ver Elevation & Depth).
- **Border:** 2px `tinta`.
- **Internal Padding:** 22px 24px en paneles; franja de cifras con celdas de 14px 20px divididas por trazo `linea`.

### Tablas
Contenedor con borde negro 2px y esquina 4px, desplazamiento horizontal propio. Encabezados Archivo 800 14px sobre una línea negra de 2px; filas de 11px 14px separadas por 1px `linea`; hover de fila en crema muy pálido; `tfoot` con línea negra de 2px y peso 800. Filas vacías dicen qué hacer a continuación.

### Inputs / Fields
- **Style:** blanco, borde 2px gris piedra, esquina 4px, Archivo 500 16px, alto mínimo 44px.
- **Focus:** borde pasa a `tinta` y aparece un anillo `amarillo` de 3px pegado al borde; caret rojo.
- **Hover:** borde `tinta`.

### Estados (chips)
- **Style:** Archivo 700 13px, relleno 2px 8px, esquina 3px, borde 1.5px del color del texto sobre su fondo pálido.
- **Variantes:** ok/atendido (verde), reponer/emitido (ámbar), sin stock/anulado (rojo error).

### Avisos
Banda con borde 2px `currentColor`, esquina 4px, Archivo 700; éxito en verde, error en rojo error, con `role="status"` o `role="alert"`.

### Navigation
Barra blanca con línea inferior negra de 3px. Ítems Archivo 700 15px con esquinas superiores de 4px; hover amarillo; página actual en negro con texto blanco (`aria-current="page"`). Las pestañas de Reportes repiten el mismo lenguaje con borde 2px completo. Bajo 960px el menú ocupa todo el ancho bajo la marca.

## Do's and Don'ts

### Do:
- **Do** reservar Knewave roja sobre cartulina amarilla para el número de turno, el precio al detalle del catálogo y el total de la venta.
- **Do** delimitar todo contenedor con borde `tinta` de 2px y esquina de 2–4px.
- **Do** usar el botón negro que se vuelve rojo como única acción primaria por bloque; las demás van como secundario blanco.
- **Do** mostrar los elementos de base de datos evaluados como `.nota` gris con el nombre técnico en `code`.
- **Do** mantener controles de al menos 44px y el foco visible (anillo rojo de 3px; amarillo en campos).
- **Do** proteger el movimiento del cartel con `prefers-reduced-motion`.

### Don't:
- **Don't** usar Knewave ni el cartel amarillo en tablas densas de reportes, ventas o historial.
- **Don't** usar Yellowtail para nada que no sea "La Mundial".
- **Don't** agregar sombras difusas ni tarjetas KPI flotantes estilo panel SaaS gris.
- **Don't** introducir pasteles de dulcería ni nuevos acentos de color fuera de `rojo` y `amarillo`.
- **Don't** usar `rojo` de marca para errores ni `error` como acento de marca.
