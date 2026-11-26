# Microsoft por Outlook clásico (modo COM)

Esta es la vía para atender un buzón **Microsoft 365 institucional** cuando el conector
oficial de Microsoft no está disponible (la facultad no deja que cada persona autorice la
app: aparece "Se necesita la aprobación del administrador"). En vez de eso, la skill
maneja el **Outlook clásico de escritorio** que la persona ya tiene abierto, por su
interfaz interna (COM), como lo haría una macro.

**No usa token, no abre el navegador, no necesita el consentimiento del admin, es gratis.**

## Cuándo se usa esta vía

- El buzón es Microsoft 365 / Outlook (no Gmail).
- El conector oficial de Microsoft está bloqueado (admin consent) — ver `conectar-buzon.md`.
- La persona tiene **Outlook CLÁSICO** instalado en una PC Windows, con su cuenta
  configurada. (El "Outlook nuevo" / `olk.exe` NO sirve: no tiene COM.)

Si el buzón es Gmail, usá el conector oficial (más simple). Esta vía es solo para
Microsoft sin admin consent.

## Requisitos (una sola vez)

1. **Windows + Outlook clásico instalado** y con derecho a usarse. Si la cuenta es
   Microsoft 365 A3/A5 (o cualquier plan con Office de escritorio), se puede instalar el
   Outlook clásico actual gratis desde `portal.office.com` → "Instalar Office"
   (o con la herramienta de implementación de Office para forzar el clásico). El plan
   **A1 NO** incluye Office de escritorio.
2. **La cuenta agregada al Outlook clásico** (Archivo → Agregar cuenta, login + MFA). Esto
   crea el buzón local (OST). Se hace una vez.
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

- **Ponerse al día / listar:**
  `powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File leer-bandeja.ps1 [-Cantidad 25] [-SoloSinLeer]`
  Devuelve N correos con número, fecha, remitente y asunto.

- **Leer uno completo** (para entender qué pide):
  `... leer-correo.ps1 -Numero 3`
  Devuelve remitente, fecha, asunto, EntryID y el cuerpo.

- **Dejar un borrador** (NO envía; queda en Borradores):
  - Respuesta en el hilo: `... crear-borrador.ps1 -Numero 3 -CuerpoArchivo "C:\...\respuesta.txt"`
  - Correo nuevo: `... crear-borrador.ps1 -Para "x@..." -Asunto "..." -CuerpoArchivo "..."`
  - Con adjuntos: agregar `-Adjunto "C:\ruta\archivo1.pdf","C:\ruta\imagen.png"` (una o varias rutas).
  Para textos largos conviene `-CuerpoArchivo` (ruta a un .txt) en vez de `-Cuerpo`.
  (Probado en vivo: envío a la propia casilla con imagen adjunta; llegó en ~7 s con el adjunto OK.)

- **Enviar un borrador** (solo con el OK de la persona, y **un OK = un correo**):
  `... enviar-borrador.ps1 -Asunto "parte del asunto"`
  Si varios borradores coinciden, NO envía ninguno y los lista (para precisar).

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
