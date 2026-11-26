# crear-borrador.ps1 — Crea un borrador (NO lo envia). Queda en Borradores para revisar.
#
# Responder a un correo de la bandeja (mantiene el hilo y el destinatario):
#   ... crear-borrador.ps1 -Numero 3 -Cuerpo "texto de la respuesta"
# Correo nuevo a una direccion:
#   ... crear-borrador.ps1 -Para "alguien@frm.utn.edu.ar" -Asunto "..." -Cuerpo "..."
#
# El -Cuerpo conviene pasarlo como ruta a un archivo .txt con -CuerpoArchivo para textos largos.
param(
  [int]$Numero = 0,
  [string]$Para = "",
  [string]$Asunto = "",
  [string]$Cuerpo = "",
  [string]$CuerpoArchivo = "",
  [string]$Adjunto = ""        # una o varias rutas separadas por punto y coma ';'
)
$ErrorActionPreference = "Stop"
if ($CuerpoArchivo -and (Test-Path $CuerpoArchivo)) { $Cuerpo = Get-Content $CuerpoArchivo -Raw }
if (-not $Cuerpo) { Write-Output "ERROR: falta el cuerpo del mensaje."; exit 1 }
# Adjuntos: separar por ';' y validar
$Adjuntos = @()
if ($Adjunto) { $Adjuntos = $Adjunto.Split(';') | ForEach-Object { $_.Trim() } | Where-Object { $_ } }
foreach ($a in $Adjuntos) { if (-not (Test-Path $a)) { Write-Output "ERROR: no existe el adjunto: $a"; exit 1 } }
try {
  try { $ol = [Runtime.InteropServices.Marshal]::GetActiveObject("Outlook.Application") }
  catch { $ol = New-Object -ComObject Outlook.Application }
  $ns = $ol.GetNamespace("MAPI")
} catch { Write-Output "ERROR: no se pudo abrir Outlook."; exit 1 }

if ($Numero -gt 0) {
  # Responder a un correo existente (preserva hilo y destinatario)
  $inbox = $ns.GetDefaultFolder(6)
  $items = $inbox.Items; $items.Sort("[ReceivedTime]", $true)
  $n = 0; $orig = $null
  foreach ($m in $items) { if ($m.Class -ne 43) { continue }; $n++; if ($n -eq $Numero) { $orig = $m; break } }
  if (-not $orig) { Write-Output "No existe el correo numero $Numero."; exit 1 }
  $reply = $orig.Reply()
  $reply.Body = $Cuerpo + "`r`n`r`n" + $reply.Body   # respuesta arriba, cita abajo
  foreach ($a in $Adjuntos) { [void]$reply.Attachments.Add($a) }
  $reply.Save()
  Write-Output ("Borrador de RESPUESTA creado (sin enviar).")
  Write-Output ("Para: {0} | Asunto: {1} | Adjuntos: {2}" -f $reply.To, $reply.Subject, $reply.Attachments.Count)
} else {
  if (-not $Para -or -not $Asunto) { Write-Output "ERROR: para un correo nuevo hace falta -Para y -Asunto."; exit 1 }
  $mail = $ol.CreateItem(0)   # 0 = MailItem
  $mail.To = $Para
  $mail.Subject = $Asunto
  $mail.Body = $Cuerpo
  foreach ($a in $Adjuntos) { [void]$mail.Attachments.Add($a) }
  $mail.Save()
  Write-Output ("Borrador NUEVO creado (sin enviar).")
  Write-Output ("Para: {0} | Asunto: {1} | Adjuntos: {2}" -f $mail.To, $mail.Subject, $mail.Attachments.Count)
}
# resumen de Borradores
$drafts = $ns.GetDefaultFolder(16)   # 16 = Borradores
Write-Output ("Total en Borradores: {0}" -f $drafts.Items.Count)
