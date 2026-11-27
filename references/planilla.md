# Planilla de seguimiento (Google Sheets)

Leé esto cuando la persona quiera llevar la planilla o pida un informe. Se arma con el
conector de Google Sheets (para crear el archivo vacío se usa el de Google Drive). Lleva
nombres y correos: es **privada de la persona**, no se comparte, y va separada de la base de
respuestas (la base nunca guarda datos de personas).

Antes de crearla, preguntá con la pregunta interactiva si la quiere y si arranca vacía o con
los correos que ya se vieron. Nunca la compartas ni la muevas sin que lo pida.

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
