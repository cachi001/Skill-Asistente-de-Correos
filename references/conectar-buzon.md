# Conectar el buzón (conectores oficiales de Claude)

Leé esto si las tools de `Gmail` o `Microsoft 365` no aparecen, o si la persona quiere
cambiar de buzón. La skill no instala nada: usa los conectores oficiales de Claude.

## Gmail (sin trabas)

1. Entrá a https://claude.ai/settings/connectors (o Configuración → Conectores).
2. Buscá **Gmail** y tocá **Conectar**.
3. Iniciá sesión con la cuenta y aceptá los permisos.

Listo. El permiso lo dio Anthropic ante Google, así que no se vence cada semana y no hay
que crear nada en Google Cloud. Sirve para una cuenta de Gmail común o un Google
Workspace institucional. Para verificar: pedile a la skill "buscá mis últimos correos".

## Microsoft 365 / Outlook institucional (necesita aprobación del admin)

1. Entrá a https://claude.ai/settings/connectors y conectá **Microsoft 365** con la
   cuenta institucional (cuenta profesional o educativa, no personal).
2. Si aparece **"Se necesita la aprobación del administrador"**, la facultad no deja que
   cada persona autorice apps. Un administrador tiene que aprobar el conector una vez, y
   después todos los de esa facultad lo usan sin volver a pedir nada.

Esto no es evitable desde la cuenta de la persona: Microsoft pone la decisión del lado de
la institución. No sirve usar usuario y contraseña por otro lado; el acceso siempre pasa
por esta aprobación.

### Mensaje para sistemas/IT (para que la persona lo copie)

> Hola. Desde la Tecnicatura Universitaria en Programación queremos usar el conector
> oficial de Microsoft 365 de Claude para atender las consultas que llegan por correo. Al
> conectar con la cuenta institucional aparece "Se necesita la aprobación del
> administrador".
>
> Necesitaríamos que un administrador global otorgue el consentimiento para la
> organización, de alguna de estas formas:
>
> 1. Desde Claude: entrar a https://claude.ai/settings/connectors con una cuenta de
>    administrador global, conectar Microsoft 365 y, en la pantalla de permisos, tildar la
>    opción de dar consentimiento en nombre de la organización.
> 2. Desde Microsoft Entra, dando consentimiento de administrador a estas apps:
>    - M365 MCP Client for Claude: 08ad6f98-a4f8-4635-bb8d-f1a3044760f0
>    - M365 MCP Server for Claude: 07c030f6-5743-41b7-ba00-0a6e85f37c17
>
>    (abriendo, con cuenta de admin, `https://login.microsoftonline.com/<ID_de_inquilino>/adminconsent?client_id=<app>` para cada una y aceptando.)
>
> Además de lectura, necesitamos los permisos de escritura de correo (Mail.ReadWrite y
> Mail.Send) para dejar respuestas como borradores. Cada envío lo aprueba una persona.
>
> Guía oficial: https://support.claude.com/en/articles/12542951-enable-and-use-the-microsoft-365-connector
>
> Gracias.

Para FRM el ID de inquilino es `35eb0af4-75f7-4d23-9121-51af4d93ccc7`. Para otra
facultad, pedíselo a IT o sacalo del error de autenticación.

### Escritura (borradores y envío) en Microsoft

En cuentas institucionales, redactar y enviar dependen de que el admin habilite las tools
de escritura además de dar el consentimiento. Si solo está la lectura, la skill igual
sirve: lee los correos y arma las respuestas para que la persona las pegue y envíe desde
Outlook.

## Después de conectar

Reiniciá Claude Code si las tools no aparecen de entrada. Para confirmar que anda, pedile
a la skill que liste los correos sin responder (opción 1 del menú).
