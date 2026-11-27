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

1. **Windows + Outlook clásico instalado.** Fijate primero con `instalar-outlook.ps1 -Revisar`
   (no cambia nada). Según lo que diga:
   - `CLASICO` → seguí al paso 2.
   - `USA EL NUEVO` → el clásico está, pero el interruptor "Nuevo Outlook" lo redirige al
     nuevo. Con su OK, corré `instalar-outlook.ps1 -VolverAlClasico` (no pide permiso de
     administrador) y que cierre el Outlook nuevo si está abierto.
   - `SOLO EL NUEVO` o `NINGUNO` → **instalalo vos**, no le mandes instrucciones. Con su OK,
     lanzá `instalar-outlook.ps1` **en segundo plano** (tarda de 5 a 15 minutos). Antes
     decile: "Va a aparecer un cartel de Windows preguntando si permitís cambios: tocá Sí.
     Después vas a ver la ventana de Microsoft instalando Outlook, con su barra. No hace
     falta que hagas nada más; te aviso cuando termine." El script baja el instalador
     oficial de Microsoft (con una barra), comprueba que tenga la firma de Microsoft e
     instala **solo Outlook**, sin Word ni Excel. El Outlook nuevo puede quedar instalado,
     no molesta.
   - `OFFICE SIN OUTLOOK` → no se instala desde acá, porque podría sacar Word o Excel.
     Explicale que lo agregue desde Configuración > Aplicaciones > Microsoft 365 > Modificar,
     o que se lo pida a quien administra la PC.

   Si responde `CANCELADO`, no aceptó el cartel de Windows: preguntale si quiere reintentar.
   Si responde `NO SE INSTALO`, lo más probable es que su cuenta no incluya Office de
   escritorio (las **A1** no lo incluyen; las A3/A5 sí). Ahí ofrecé el plan B (abajo).
2. **La cuenta agregada al Outlook clásico** (login + MFA). Se hace una vez. **No le des
   instrucciones a la persona: abrile vos la ventana** con `agregar-cuenta.ps1` (abre Outlook si
   está cerrado y dispara "Agregar cuenta"). Lanzalo aparte, sin esperar, porque la ventana
   queda abierta hasta que la persona termina:
   `Start-Process powershell -WindowStyle Hidden -ArgumentList '-ExecutionPolicy Bypass -File "<ruta>\agregar-cuenta.ps1"'`
   Después decile solo esto: "Te abrí la ventana de Outlook. Poné el correo, tocá Conectar,
   la contraseña y la verificación del celular. Avisame cuando diga que está lista."
   La contraseña la escribe la persona en la ventana de Microsoft; nunca se la pidas.
   Si Outlook está recién instalado y no tiene ninguna cuenta, `agregar-cuenta.ps1` solo lo
   abre: Outlook muestra de entrada su pantalla para poner el correo.
3. **Que Outlook haya abierto una vez** y aceptado las condiciones (pasa solo en el paso 2).
   Si no, el modo automático da el error `0x80080005` (Outlook nunca arrancó).
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
  respuestas e índices. No cambia nada ni abre Outlook. Distingue si hay solo el Outlook
  nuevo, ninguno, Office sin Outlook, o el interruptor "Nuevo Outlook" prendido.
- **Instalar o recuperar el clásico:** `... instalar-outlook.ps1 [-Revisar | -VolverAlClasico]`
  (ver Requisitos, paso 1). Instalar va siempre en segundo plano y con el OK de la persona.

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

## Plan B: si no se puede tener el Outlook clásico

Pasa si la cuenta no incluye Office de escritorio (por ejemplo las A1), si la PC no es
Windows o si no le dejan instalar programas. La skill no puede leer la bandeja sola, pero
sí ayudar a responder:

1. La persona copia el correo (o varios) desde el Outlook que tenga, incluso el de la web,
   y lo pega en el chat.
2. La skill lo trata igual que uno leído de la bandeja: lo clasifica, busca en la base de
   respuestas y arma la respuesta escrita, con su fuente.
3. La persona la copia y la envía desde su Outlook. La skill no envía nada en este modo.

Explicáselo en simple y sin hacerlo sentir un problema: "Con tu cuenta no puedo entrar a la
bandeja, pero si me pegás el correo acá te armo la respuesta para que la mandes vos".
