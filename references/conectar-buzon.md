# Conectar el correo

Hay dos caminos, según el correo:

- **Gmail** (cuenta común o Google Workspace): el conector oficial de Gmail de Claude. Está
  abajo.
- **Correo institucional de Microsoft (Outlook)**: el Outlook clásico de la computadora. No
  se usa ningún conector de Microsoft. Todo está en `outlook-clasico.md`: corré
  `revisar-equipo` y, si falta la cuenta, `agregar-cuenta`.

## Gmail

1. Entrá a https://claude.ai/settings/connectors (o Configuración → Conectores).
2. Buscá **Gmail** y tocá **Conectar**.
3. Iniciá sesión con la cuenta y aceptá los permisos.

Listo. No se vence cada semana y no hay que crear nada en Google Cloud. La contraseña la
escribe la persona en la ventana de Google; la skill nunca la pide.

## Después de conectar

Reiniciá Claude Code si las tools no aparecen de entrada. Para confirmar que anda, pedile
a la skill que liste los correos sin responder (opción 1 del menú).
