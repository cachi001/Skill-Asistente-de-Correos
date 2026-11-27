# crear-borrador.ps1 — Crea un borrador (NO lo envia). Queda en Borradores para revisar.
#
# Responder a un correo de la bandeja (mantiene el hilo y el destinatario):
#   ... crear-borrador.ps1 -Numero 3 -CuerpoArchivo "C:\...\respuesta.txt" [-Buzon Certificaciones]
# Correo nuevo a una direccion:
#   ... crear-borrador.ps1 -Para "alguien@frm.utn.edu.ar" -Asunto "..." -Cuerpo "..." [-Buzon ...]
#
# Con -Buzon, el -Numero es el de ese buzon y la respuesta SALE DESDE ese buzon
# (cuenta agregada: se envia con esa cuenta; compartido: "en nombre de" su direccion).
# Para textos largos conviene -CuerpoArchivo (ruta a un .txt) en vez de -Cuerpo.
param(
  [int]$Numero = 0,
  [string]$Buzon = "",
  [string]$Para = "",
  [string]$Asunto = "",
  [string]$Cuerpo = "",
  [string]$CuerpoArchivo = "",
  [string]$Adjunto = ""        # una o varias rutas separadas por punto y coma ';'
)
. "$PSScriptRoot\buzon-comun.ps1"
$ErrorActionPreference = "Stop"
if ($CuerpoArchivo -and (Test-Path $CuerpoArchivo)) { $Cuerpo = Get-Content $CuerpoArchivo -Raw -Encoding UTF8 }
if (-not $Cuerpo) { Write-Output "ERROR: falta el cuerpo del mensaje."; exit 1 }
$Adjuntos = @()
if ($Adjunto) { $Adjuntos = $Adjunto.Split(';') | ForEach-Object { $_.Trim() } | Where-Object { $_ } }
foreach ($a in $Adjuntos) { if (-not (Test-Path $a)) { Write-Output "ERROR: no existe el adjunto: $a"; exit 1 } }
Conectar-Outlook
$store = Elegir-Buzon $Buzon

if ($Numero -gt 0) {
  $items = $store.GetDefaultFolder(6).Items; $items.Sort("[ReceivedTime]", $true)
  $n = 0; $orig = $null
  foreach ($m in $items) { if ($m.Class -ne 43) { continue }; $n++; if ($n -eq $Numero) { $orig = $m; break } }
  if (-not $orig) { Write-Output "No existe el correo numero $Numero en ese buzon."; exit 1 }
  $mail = $orig.Reply()
  $mail.Body = $Cuerpo + "`r`n`r`n" + $mail.Body   # respuesta arriba, cita abajo
  $tipo = "RESPUESTA"
} else {
  if (-not $Para -or -not $Asunto) { Write-Output "ERROR: para un correo nuevo hace falta -Para y -Asunto."; exit 1 }
  $mail = $ol.CreateItem(0)   # 0 = MailItem
  $mail.To = $Para
  $mail.Subject = $Asunto
  $mail.Body = $Cuerpo
  $tipo = "NUEVO"
}
Fijar-Remitente $mail $store
foreach ($a in $Adjuntos) { [void]$mail.Attachments.Add($a) }
$mail.Save()
Write-Output ("Borrador {0} creado (sin enviar)." -f $tipo)
Write-Output ("Sale desde: {0} | Para: {1} | Asunto: {2} | Adjuntos: {3}" -f (Remitente-DeBorrador $mail), $mail.To, $mail.Subject, $mail.Attachments.Count)
