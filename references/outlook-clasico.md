# Microsoft por Outlook clásico (modo COM)

Este es **el** camino para atender un buzón **Microsoft 365 institucional**. La skill
maneja el **Outlook clásico de escritorio** que la persona ya tiene abierto, por su
interfaz interna (COM), como lo haría una macro. No se usa ningún conector de Microsoft.

**No usa token, no abre el navegador, no necesita el permiso del administrador, es gratis.**

## Cuándo se usa esta vía

- El buzón es Microsoft 365 / Outlook (no Gmail). Siempre.
- La persona tiene **Outlook CLÁSICO** instalado en una PC Windows, con su cuenta
  configurada. (El "Outlook nuevo" / `olk.exe` NO sirve: no tiene COM.)

Si el buzón es Gmail, usá el conector oficial de Gmail (`conectar-buzon.md`).

## Requisitos (una sola vez)

1. **Windows + Outlook clásico instalado** y con derecho a usarse. Si la cuenta es
   Microsoft 365 A3/A5 (o cualquier plan con Office de escritorio), se puede instalar el
   Outlook clásico actual gratis desde `portal.office.com` → "Instalar Office"
   (o con la herramienta de implementación de Office para forzar el clásico). El plan
   **A1 NO** incluye Office de escritorio.
2. **La cuenta agregada al Outlook clásico** (login + MFA). Se hace una vez. **No le des
   instrucciones a la persona: abrile vos la ventana** con `agregar-cuenta.ps1` (abre Outlook si
   está cerrado y dispara "Agregar cuenta"). Lanzalo aparte, sin esperar, porque la ventana
   queda abierta hasta que la persona termina:
   `Start-Process powershell -WindowStyle Hidden -ArgumentList '-ExecutionPolicy Bypass -File "<ruta>\agregar-cuenta.ps1"'`
   Después decile solo esto: "Te abrí la ventana de Outlook. Poné el correo, tocá Conectar,
   la contraseña y la verificación del celular. Avisame cuando diga que está lista."
   La contraseña la escribe la persona en la ventana de Microsoft; nunca se la pidas.
3. **Abrir Outlook una vez a mano** después de instalarlo (aceptar condiciones, iniciar
   sesión). Si no, el modo automático da el error `0x80080005` (Outlook nunca arrancó).
4. **Quitar el cartel de "acceso por programa"** (una vez, con permiso de administrador):
   en `HKCU\Software\Policies\Microsoft\Office\16.0\Outlook\Security` poner
   `AdminSecurityMode`=3 y todos los `PromptOOM*`=**2** (2 = aprobar siempre; 1 = preguntar
   = el cartel; 0 = denegar). Reiniciar Outlook. Sin esto, cada sesión muestra un cartel
   pidiendo "Permitir". En Office actual (con soporte) muchas veces ni aparece.

## Cómo opera la skill (scripts en `assets/outlook-clasico/`)

Todos corren **ocultos** (`-WindowStyle Hidden`), sin mostrar consolas a la persona.
El `-Numero` es el que devuelve el listado (orden: más nuevos primero).

- **Ver qué buzones hay** (cuenta propia, otras cuentas, compartidos):
  `... listar-buzones.ps1`
  Todos los demás scripts aceptan `-Buzon <parte del nombre o dirección>`. Sin `-Buzon` usan la
  cuenta principal. Si el nombre coincide con más de uno, no adivinan: devuelven error y la lista.
  El `-Numero` vale **dentro de un buzón**: listá, leé y respondé siempre con el mismo `-Buzon`.
  Al responder desde un compartido, el borrador sale "en nombre de" su dirección
  (`SentOnBehalfOfName`); eso exige que la cuenta tenga permiso de enviar como o en nombre de ese
  buzón. Si no lo tiene, el envío rebota: avisale a la persona y no reintentes.
  Leer un correo **no** lo marca como leído.

- **Chequeo al empezar:** `... revisar-equipo.ps1` — versión de la skill (y si hay una nueva),
  Outlook instalado y abierto, cartel de acceso, buzones y cuáles están en solo lectura, base de
  respuestas e índices. No cambia nada ni abre Outlook.

- **Ponerse al día (lo recomendado, una sola pasada):**
  `... ponerse-al-dia.ps1 -Buzon "Tec Programacion" [-Dias 14] [-SoloNuevos] [-Largo 700]`
  Trae lo que **nadie respondió** (se fija si el correo ya se respondió o reenvió desde Outlook,
  por cualquiera que use el buzón), agrupa por persona y tema ("4 correos, desde el 24/11"),
  ordena por fecha y trae el texto sin el historial. Cada fila tiene su `numero` para leer o
  responder. `-SoloNuevos` trae solo lo llegado desde la vez anterior. Al final muestra los sin
  leer antes y después (tienen que ser iguales). Si son muchos, aparece la barra de progreso.

- **Listar la bandeja tal cual:**
  `powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File leer-bandeja.ps1 [-Cantidad 25] [-SoloSinLeer]`
  Devuelve N correos con número, fecha, remitente y asunto.

- **Leer uno completo** (para entender qué pide):
  `... leer-correo.ps1 -Numero 3`
  Devuelve remitente, fecha, asunto y el cuerpo (sin el historial citado del hilo).

- **Dejar un borrador** (NO envía; queda en Borradores):
  - Respuesta en el hilo: `... crear-borrador.ps1 -Numero 3 -CuerpoArchivo "C:\...\respuesta.txt"`
  - Correo nuevo: `... crear-borrador.ps1 -Para "x@..." -Asunto "..." -CuerpoArchivo "..."`
  - Con adjuntos: agregar `-Adjunto "C:\ruta\archivo1.pdf;C:\ruta\imagen.png"` (una o varias rutas, separadas por `;`).
  Para textos largos conviene `-CuerpoArchivo` (ruta a un .txt) en vez de `-Cuerpo`.
  (Probado en vivo: envío a la propia casilla con imagen adjunta; llegó en ~7 s con el adjunto OK.)

  Devuelve un **CÓDIGO DE ENVÍO** de 4 números, de un solo uso, para ese borrador.

- **Enviar un borrador** (solo con el OK de la persona, y **un OK = un correo**):
  `... enviar-borrador.ps1 -Codigo 4821`
  Sin el código de ese borrador no envía. El código se borra al enviar, así que no se puede
  mandar dos veces. Si el borrador ya no está (se envió o se borró), no hace nada y avisa.

- **Solo lectura por buzón** (lo decide la persona):
  `... modo-buzon.ps1 -Buzon alberto -SoloLectura si` (o `no`). Sin parámetros muestra el modo
  de cada buzón. En solo lectura, `crear-borrador` y `enviar-borrador` se niegan (salen con
  "BLOQUEADO"). Se guarda en `~/.correos-tup/buzones.json`.

- **Cómo se respondió antes:**
  `... indexar-enviados.ps1 -Buzon "Tec Programacion" [-Dias 180]` recorre los Enviados una vez y
  guarda en `~/.correos-tup/indice/` cada respuesta con la pregunta que contestaba, y aparte los
  avisos masivos (traen fechas y requisitos). Tapa DNI, legajos, teléfonos y correos. Las veces
  siguientes solo suma lo nuevo. También dice quién firma más (para copiar el estilo).
  `... buscar-respuestas.ps1 -Buzon "Tec Programacion" -Texto "fecha pago cuota"` busca ahí al
  instante, sin abrir Outlook, y devuelve las más parecidas con su fecha.

- **Esperar a que baje una cuenta nueva:**
  `... esperar-buzon.ps1 -Buzon alberto` — después de `agregar-cuenta`, muestra una ventanita
  con lo que va bajando y termina cuando la bandeja deja de crecer.

**Ventanita de progreso:** los scripts largos (ponerse al día con muchos correos, indexar,
esperar una cuenta) abren una ventana con una barra, cuántos van de cuántos y cuánto falta.
Solo aparece si la tarea pasa de ~2 segundos. Se apaga con `CORREOS_TUP_SIN_VENTANA=1`.

## Flujo con la persona

Es el mismo de la skill: listar sin responder → leer cada uno → mostrar el resumen en
castellano (de quién / qué pide / qué conviene hacer) y pedir confirmación → armar los
borradores desde la base de conocimiento → mostrar cada borrador completo → crear el
borrador → enviar **solo** con el OK para ese correo. La clasificación por tema, facultad
y modalidad la hace la skill leyendo la base; estos scripts solo leen y escriben en Outlook.

## Límite para escalar al equipo

Solo sirve en una PC con el Outlook clásico instalado y la cuenta configurada. Un colega
con cuenta que no incluya Office de escritorio (p. ej. A1) no puede por esta vía: ahí el
camino es el conector oficial con el consentimiento del admin, o Gmail.
