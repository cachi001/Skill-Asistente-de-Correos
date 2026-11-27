# Planilla de seguimiento (Google Sheets)

Leé esto cuando la persona quiera llevar la planilla o pida un informe. Se arma con el
conector de Google Sheets (para crear el archivo vacío se usa el de Google Drive). Lleva
nombres y correos: es **privada de la persona**, no se comparte, y va separada de la base de
respuestas (la base nunca guarda datos de personas).

Antes de crearla, preguntá con la pregunta interactiva si la quiere y si arranca vacía o con
los correos que ya se vieron. Nunca la compartas ni la muevas sin que lo pida.

## Dónde queda: el link siempre a mano

- Al crearla, guardá su título, id, link y la cuenta de Google en
  `~/.correos-tup/planilla.json`. Así la skill (y `revisar-equipo`) siempre sabe cuál es.
- **Dá el link completo, en su propia línea**, cada vez que la creás, la actualizás o la
  persona pregunta por ella. No lo escondas dentro de una frase:

  📊 Planilla de seguimiento:
  https://docs.google.com/spreadsheets/d/<id>/edit

- Decile también dónde la encuentra sin el link: en su Google Drive ("Mi unidad"), con ese
  título, en la cuenta de Google con la que está conectado Claude.
- Ofrecé abrírsela en el navegador (pregunta interactiva). Si dice que sí:
  `Start-Process "<link>"`.

## Reglas que valen para toda la planilla

- **Toda hoja y toda tabla tiene título y una explicación** en palabras simples (qué muestra
  y para qué sirve), arriba de la tabla. Nunca una tabla suelta.
- **Lo más nuevo arriba.** En Seguimiento y en Pendientes, los correos más nuevos van
  primero. Los correos nuevos se agregan insertando una fila debajo del encabezado (fila 5),
  no al final.
- **Siempre se ve de qué buzón es cada correo** (columna Buzón), porque una misma persona
  puede atender su casilla y buzones compartidos.
- Las opciones de las listas se ven como etiquetas de color (cada valor con su color), no
  como texto plano.
- Sin palabras técnicas; los mismos nombres que usa la skill en el chat.

## Las cinco hojas, en este orden

| Hoja | Qué tiene | Quién la escribe |
|---|---|---|
| **Cómo usarla** | Para qué sirve cada hoja y qué significa cada opción (Prioridad, Revisión, Estado) | Fija |
| **Seguimiento** | Una fila por correo, los más nuevos arriba (si alguien escribe dos veces por cosas distintas, dos filas) | La skill agrega y actualiza filas; la persona puede corregir |
| **Pendientes** | Solo lo que está "Sin responder" o "Para revisar", los más nuevos arriba, con "Días esperando" | Sola, con fórmulas |
| **Resumen** | Selector de buzón (Todos o uno), indicadores con su explicación, tablas por estado, tema y prioridad, y tres gráficos | Sola, con fórmulas |
| **Opciones** | Los valores de las listas desplegables (buzones, modalidad, temas, prioridad, revisión, estado) | La persona, para sumar un tema o un buzón |

Cada hoja arranca con: fila 1 título, fila 2 explicación, fila 4 encabezados, fila 5 datos.

## Columnas de Seguimiento

| Fecha | Buzón | Nombre | Correo | Facultad | Modalidad | Tema | Qué pidió | Prioridad | Revisión | Estado | Respondido | Notas |
|---|---|---|---|---|---|---|---|---|---|---|---|---|

- **Buzón:** a qué casilla llegó (la propia o una compartida, como Certificaciones).
- **Modalidad:** Presencial / Virtual / No aclara.
- **Tema:** los temas del buzón (de `perfil.md`), en la hoja Opciones.
- **Prioridad:** Alta / Media / Baja. Alta solo con señales claras (fecha límite, "urgente",
  alguien molesto o que escribió varias veces). Sin señal, Media.
- **Revisión:** Rápida / Con cuidado / Te consulta (sale del tema en la base).
- **Estado:** Sin responder / Para revisar / Enviado / Derivado / No requiere.
- **Qué pidió:** una línea. El texto completo queda en el correo, no acá.
- **Notas:** por ejemplo a quién se derivó, escrito como corresponda; no supongas si es una
  persona, una oficina u otra facultad.

## Resumen

- Arriba, "Buzón que se muestra": una lista con Todos y cada buzón. Todas las cifras y los
  gráficos se filtran por esa elección.
- "Cómo viene el correo": indicador, valor y qué significa (correos registrados, sin
  responder, para revisar, respondidos, porcentaje respondido, prioridad alta sin resolver,
  días promedio para responder, correo sin responder más antiguo).
- "Correos por estado", "Correos por tema" y "Correos por prioridad", cada una con título y
  explicación.
- Gráficos: anillo por estado, columnas por tema, barras apiladas por prioridad.
- Todo son fórmulas sobre Seguimiento y Opciones: se actualiza solo.

## Cómo crearla: copiar la plantilla

Lo más seguro es **copiar la planilla de ejemplo** con Google Drive (`copy_file`) y borrar las
filas de ejemplo, en vez de armarla de cero: la copia ya trae todo, incluido el estilo de
las listas desplegables. Ese estilo ("Chip", la etiqueta redondeada) **no se puede poner con
el conector de Sheets**: solo desde la pantalla (Datos > Validación de datos > Opciones
avanzadas > Estilo de visualización > Chip). Si alguna vez hay que armarla de cero, ese paso
se hace con el navegador (Playwright) y después se mira con una captura.

Plantilla: "Seguimiento de correos (ejemplo)", id `14_A1lpyzD2M3fnySOD44E3odw2hYcNQ-E6-9cWDfeKM`
(si la persona no tiene acceso a ese archivo, armala de cero siguiendo esta guía).

Después de crearla o cambiarla, **mirala en pantalla** (navegador y captura) antes de decir
que quedó bien: los datos pueden estar perfectos y verse mal (títulos cortados, flechitas en
filas vacías, colores que no coinciden).

## Formato

- Título azul (#1F5FA8) grande, explicación en gris; encabezados azules con letra blanca,
  fijos al bajar; filtros en Seguimiento; filas alternadas en gris muy claro.
- Etiquetas de color: Alta rojo, Media amarillo, Baja gris; Rápida verde, Con cuidado
  amarillo, Te consulta naranja; Sin responder naranja, Para revisar celeste, Enviado verde,
  Derivado lila, No requiere gris.
- Configuración regional Argentina (es_AR): en las fórmulas los argumentos van con `;`.
- Las listas desplegables cubren **solo las filas con datos** (si no, aparecen flechitas en
  todas las filas vacías). Por eso las filas nuevas se insertan dentro de la tabla (ver
  "Cuándo se escribe").
- "Qué pidió" va con ajuste de texto (se ve completo) y todo centrado en vertical.
- En Pendientes, la primera columna es **Días esperando**, para que se vea sin moverse. Se
  lee como texto ("Hoy", "1 día", "3 días", con el formato de número
  `[=0]"Hoy";[=1]"1 día";0" días"`) y lleva color según la demora: verde hasta 1 día,
  amarillo 2 o 3 días, rojo 4 o más.
- Las explicaciones de la fila 2 tienen que entrar en el ancho de la pantalla: cortas.
- Los gráficos usan los mismos colores que las etiquetas (por ejemplo Enviado verde,
  Sin responder naranja), no los colores automáticos.

## Al terminar de armarla o cambiarla: contar todo

Cuando la creás o le cambiás algo, explicale **todo lo que se hizo y dónde quedó**, sin
dejar nada afuera, en este orden:
1. El link completo, en su propia línea, y dónde está en Drive.
2. Cada hoja: qué tiene y qué se colocó (filas, columnas, listas desplegables, colores,
   fórmulas, gráficos).
3. Qué revisaste y salió bien (por ejemplo: los números del Resumen coinciden).
4. Qué se escribe solo de acá en adelante y qué puede tocar ella.
Recién después, preguntá si quiere cambiar algo.

## Cuándo se escribe: cada vez que se usa la skill

No hay nada automático en segundo plano: la hoja Seguimiento se carga **cuando la persona usa
la skill** (por ejemplo "ponete al día"). Pendientes, Resumen y Días esperando se actualizan
solos porque son fórmulas.

Al ponerse al día con planilla (`~/.correos-tup/planilla.json` existe):
1. Corré `ponerse-al-dia -Incluir respondidos` (solo lee; no marca nada). Los ya contestados
   desde Outlook vienen como `[respondido el dd/mm/aaaa]`: esa es la fecha de Respondido.
2. Leé Seguimiento (`get_values` de A4:M) y quedate solo con los correos que **no están**
   (mismo correo y mismo "Qué pidió", o misma persona y misma fecha). Los que ya están y
   cambiaron de estado (por ejemplo ahora respondidos), actualizá Estado, Respondido y Notas.
3. Insertá las filas nuevas **dentro** de la tabla (`insertDimension` desde la fila 6,
   `inheritFromBefore: true`): así heredan las listas con estilo chip y los colores.
4. Escribí los datos y ordená la tabla por Fecha, del más nuevo al más viejo (`sortRange`
   sobre A5:M hasta la última fila, columna A descendente).
5. Clasificá cada fila: Tema, Prioridad, Revisión y Estado (respondido → Enviado; un
   "gracias" o un aviso → No requiere; el resto → Sin responder, o Para revisar si ya armaste
   la respuesta). Escribí "Qué pidió" en una línea, sin DNI ni legajo.
6. Miralo en pantalla y contale a la persona qué se cargó, con el link.

Al enviar o derivar: se actualizan Estado, Respondido y Notas de esa fila. Nunca se borran
filas.

Probado el 27/11/2026 con Tec Programacion (35 correos reales de 3 días, en solo lectura:
35 sin leer antes y después): "Seguimiento de correos - Tec Programacion".

Ejemplo armado y probado (con datos inventados): "Seguimiento de correos (ejemplo)", 27/11/2026.
