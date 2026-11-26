# leer-correo.ps1 — Muestra un correo completo (remitente, fecha, asunto, cuerpo) por COM.
# El -Numero es el que aparece en leer-bandeja.ps1 (mismo orden: mas nuevos primero).
#
#   powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File leer-correo.ps1 -Numero 3
param(
  [Parameter(Mandatory=$true)][int]$Numero
)
$ErrorActionPreference = "Stop"
try {
  try { $ol = [Runtime.InteropServices.Marshal]::GetActiveObject("Outlook.Application") }
  catch { $ol = New-Object -ComObject Outlook.Application }
  $ns = $ol.GetNamespace("MAPI")
  $inbox = $ns.GetDefaultFolder(6)
} catch { Write-Output "ERROR: no se pudo abrir Outlook."; exit 1 }
$items = $inbox.Items
$items.Sort("[ReceivedTime]", $true)
$n = 0; $target = $null
foreach ($m in $items) {
  if ($m.Class -ne 43) { continue }
  $n++
  if ($n -eq $Numero) { $target = $m; break }
}
if (-not $target) { Write-Output "No existe el correo numero $Numero."; exit 1 }
# Resolver el correo del remitente en formato corto (SMTP), no el codigo largo de Exchange
$mail = $target.SenderEmailAddress
try { if ($target.SenderEmailType -eq "EX") { $mail = $target.Sender.GetExchangeUser().PrimarySmtpAddress } } catch {}
Write-Output ("De:     {0} <{1}>" -f $target.SenderName, $mail)
Write-Output ("Fecha:  {0:dd/MM/yyyy HH:mm}" -f $target.ReceivedTime)
Write-Output ("Asunto: {0}" -f $target.Subject)
Write-Output ("-" * 70)
$cuerpo = $target.Body

# Cortar el historial citado (ahorra tokens): quedarse solo con el mensaje mas reciente.
$marcadores = @(
  '(?m)^_{5,}\s*$',               # linea de guiones bajos de Outlook
  '(?m)^De:\s.+',                 # inicio de un correo citado (es)
  '(?m)^From:\s.+',               # idem (en)
  '(?m)^-{3,}\s*Mensaje original', # "----- Mensaje original -----"
  '(?m)^El\s.+escribi[oó]:\s*$'   # "El ... escribió:"
)
$corte = $cuerpo.Length
foreach ($mk in $marcadores) {
  $m = [regex]::Match($cuerpo, $mk)
  if ($m.Success -and $m.Index -lt $corte -and $m.Index -gt 40) { $corte = $m.Index }
}
$recortadoHistorial = $corte -lt $cuerpo.Length
if ($recortadoHistorial) { $cuerpo = $cuerpo.Substring(0, $corte).TrimEnd() }
if ($cuerpo.Length -gt 4000) { $cuerpo = $cuerpo.Substring(0,4000) + "`n...(texto largo recortado)..." }
Write-Output $cuerpo
if ($recortadoHistorial) { Write-Output "`n[se omitio el historial citado del hilo para ahorrar; pedir el correo completo si hace falta]" }
