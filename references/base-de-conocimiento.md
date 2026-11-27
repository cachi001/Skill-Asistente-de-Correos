# Base de conocimiento: cómo se arma y cómo se mantiene

Leé esto para armar la base (opción 2) o cuando haya que agregar una respuesta nueva.

La base es lo único de lo que la skill saca información institucional. Por eso cada
entrada la valida una persona: una fecha o un requisito equivocado copiado a cien
respuestas es peor que no responder.

## Dónde vive

`~/.correos-tup/conocimiento/` (o `$CORREOS_TUP_HOME/conocimiento/`). Un archivo Markdown
por tema, en la misma máquina, así lo leen igual la terminal y la app de escritorio de
Claude Code. Se lee y se escribe con las herramientas de archivos normales. Vos lo podés
abrir y corregir cuando quieras.

## Temas

Los temas salen del uso del buzón (lo que la persona contestó en "La primera vez", guardado en
`~/.correos-tup/perfil.md`) y de los correos reales, no de una lista fija. Proponelos vos a
partir de lo que viste y confirmalos con ella antes de crear los archivos.

Por ejemplo, un buzón de **pedidos entre oficinas** puede tener "Ajustes razonables",
"Altas de usuarios", "Resoluciones y feriados", "Pedidos de docentes". Un buzón de
**consultas de alumnos y aspirantes** suele quedar parecido a esto:

| Archivo | Cubre |
|---|---|
| `inscripcion-y-admision.md` | Preinscripción, ingreso, documentación, cupos |
| `cursada.md` | Inscripción a materias, comisiones, horarios, correlatividades, regularidad |
| `examenes.md` | Mesas, inscripción a finales, recuperatorios, promoción |
| `tramites-administrativos.md` | Constancias, certificados, equivalencias, cambios de datos, títulos |
| `acceso-al-campus.md` | Cómo entrar al campus virtual, usuario institucional, recuperar contraseña (el procedimiento, NUNCA credenciales de nadie) |
| `becas-y-aranceles.md` | Becas, pagos, aranceles si los hay |
| `contactos-y-derivaciones.md` | A quién derivar lo que este buzón no resuelve |

Cada archivo arranca con un **índice** de sus preguntas. Plantilla de cada entrada:
`assets/plantilla-entrada.md`.

## Varias facultades

La TUP se cursa en distintas facultades regionales y un mismo trámite puede resolverse
distinto en cada una. Por eso cada entrada lleva **Ámbito** (la facultad o sede a la que
aplica, o "todas").

Si el tema no depende de la facultad (por ejemplo un pedido interno), el Ámbito queda en
"todas" y no hace falta preguntar.

- Si el buzón atiende **una sola** facultad: los archivos van sueltos y el Ámbito queda
  como dato dentro de cada entrada.
- Si atiende **varias**: una carpeta por facultad, cada una con sus temas
  (`FRM/cursada.md`, `FRBA/cursada.md`...), así no se cruzan ni físicamente.

Preguntale a la persona cuántas facultades atiende antes de elegir la estructura.

## Armado inicial desde correos ya respondidos

1. Traé los correos que la persona ya respondió. En Gmail, los enviados:
   `in:sent newer_than:180d`. En Outlook, corré `indexar-enviados` una vez y después buscá
   con `buscar-respuestas`. Si hay pocos, ampliá el período.
2. Agrupá por tema (no por remitente). Un tema es un pedido o una pregunta que se repite con
   la misma respuesta: "¿cómo pido la constancia de alumno regular?", "¿cómo se carga un
   ajuste razonable?".
3. Para cada tema redactá una entrada **generalizada**:
   - Sin nombres, correos, DNI, legajos ni casos particulares.
   - Con la respuesta que efectivamente se dio, no con una mejorada que inventes.
   - Si dos respuestas al mismo tema se contradicen, no elijas: anotá las dos y preguntá.
   - Marcá `Ámbito` (facultad) y `Modalidad` (presencial/virtual/ambas). Si cambia según
     una u otra, poné las versiones en "Diferencias por facultad/modalidad".
   - Todo dato con vencimiento (fechas, links de formularios, montos) va en `Vigencia`.
4. **No guardes nada solo: proponé y preguntá, con tus sugerencias.** Mostrale **un tema
   por vez** (varias entradas juntas, no de a una) con la pregunta interactiva. Por cada
   entrada: lo que se respondió y de qué correo salió (fecha y quién), y **tu sugerencia**
   concreta cuando veas algo para mejorar. Por ejemplo:
   - "Esta respuesta no dice el horario: ¿lo agrego?"
   - "La fecha vence el 30/06/2027: la marco para avisarte."
   - "Hay dos respuestas distintas: te recomiendo la del 20/11 porque es la más nueva."
   - "Le sumaría el link del formulario que mandaste el 12/11."

   La opción recomendada va primera ("Guardar con mi sugerencia (Recomendado)" · "Guardar
   como se respondió" · "Corregir" · "No va"). Lo que ya está claro en los enviados se
   propone listo para aceptar con un clic, para que validar sea rápido; pero lo decide ella.
   Recién con su respuesta escribí el archivo y poné `Validado: <fecha> por <persona>`.
5. Los temas con un solo correo no alcanzan para una entrada: listalos aparte como "vistos
   una vez" y preguntá si quiere cargarlos igual.

Si la persona tiene documentos oficiales (reglamento, calendario académico, instructivos),
leelos también y marcá la `Fuente`. Ante una diferencia entre el documento oficial y lo
que se venía respondiendo, señalala y que decida la persona.

## Mantenimiento

- Cada vez que la persona responde una consulta que la base no cubría, ofrecé agregarla
  como entrada nueva (con su OK y sin datos personales).
- Antes de usar una entrada con `Vigencia` vencida, avisá y pedí el dato actualizado.
- Si la persona corrige un borrador que salió de una entrada, preguntá si la corrección
  va también a la entrada.
- Mantené el índice de cada archivo al día. Si un tema pasa de ~15-20 entradas, partilo.
