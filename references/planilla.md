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

## Al terminar de armarla o cambiarla: contar todo

Cuando la creás o le cambiás algo, explicale **todo lo que se hizo y dónde quedó**, sin
dejar nada afuera, en este orden:
1. El link completo, en su propia línea, y dónde está en Drive.
2. Cada hoja: qué tiene y qué se colocó (filas, columnas, listas desplegables, colores,
   fórmulas, gráficos).
3. Qué revisaste y salió bien (por ejemplo: los números del Resumen coinciden).
4. Qué se escribe solo de acá en adelante y qué puede tocar ella.
Recién después, preguntá si quiere cambiar algo.

## Las cuatro hojas

| Hoja | Qué tiene | Quién la escribe |
|---|---|---|
| **Seguimiento** | Una fila por correo (si alguien escribe dos veces por cosas distintas, dos filas) | La skill agrega y actualiza filas; la persona puede corregir |
| **Pendientes** | Solo lo que está "Sin responder" o "Para revisar", del más viejo al más nuevo, con cuántos días lleva esperando | Sola, con fórmulas |
| **Resumen** | Indicadores, tablas por estado, tema y prioridad, y tres gráficos | Sola, con fórmulas |
| **Listas** | Los valores de las listas desplegables | La persona (por ejemplo, para cambiar los temas) |

## Columnas de Seguimiento

| Fecha | Nombre | Correo | Facultad | Modalidad | Tema | Qué pidió | Prioridad | Revisión | Estado | Respondido | Notas |
|---|---|---|---|---|---|---|---|---|---|---|---|

- **Modalidad:** Presencial / Virtual / No aclara.
- **Tema:** los temas del buzón (de `perfil.md`), en la hoja Listas.
- **Prioridad:** Alta / Media / Baja. Alta solo con señales claras (fecha límite, "urgente",
  alguien molesto o que escribió varias veces). Sin señal, Media.
- **Revisión:** Rápida / Con cuidado / Te consulta (sale del tema en la base).
- **Estado:** Sin responder / Para revisar / Enviado / Derivado / No requiere.
- **Qué pidió:** una línea. El texto completo queda en el correo, no acá.
- **Notas:** por ejemplo a quién se derivó, escrito como corresponda; no supongas si es una
  persona, una oficina u otra facultad.

## Resumen

- Indicadores: correos registrados, sin responder, para revisar, respondidos, porcentaje
  respondido, prioridad alta sin resolver, días promedio para responder y el correo sin
  responder más antiguo.
- Tablas: por estado, por tema (correos y pendientes) y por prioridad (resueltos y pendientes).
- Gráficos: torta por estado, columnas por tema, barras apiladas por prioridad.
- Todo son fórmulas sobre Seguimiento y Listas: se actualiza solo.

## Formato

- Encabezado azul (#1F5FA8) con letra blanca, fijo arriba; filtros en Seguimiento.
- Color solo donde sirve: Prioridad Alta rojo suave, Sin responder amarillo suave, Enviado
  verde suave.
- La planilla se crea en configuración regional Argentina (es_AR): en las fórmulas los
  argumentos van separados con `;`.

## Cuándo se escribe

- Al ponerse al día: una fila por cada correo nuevo, con Estado "Sin responder" o "Para revisar".
- Al enviar o derivar: se actualizan Estado, Respondido y Notas de esa fila.
- Nunca se borran filas.

Ejemplo armado y probado (con datos inventados): "Seguimiento de correos (ejemplo)", 27/11/2026.
