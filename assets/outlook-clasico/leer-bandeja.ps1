# leer-bandeja.ps1 — Lista correos de la bandeja de entrada del Outlook clasico por COM.
# No muestra ventanas. Sin token, sin navegador, sin consentimiento de admin.
#
#   powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File leer-bandeja.ps1 [-Cantidad 25] [-SoloSinLeer]
#
# El numero de cada correo sirve para pasarselo a leer-correo.ps1 / crear-borrador.ps1.
param(
  [int]$Cantidad = 25,
  [switch]$SoloSinLeer
)
$ErrorActionPreference = "Stop"
try {
  try { $ol = [Runtime.InteropServices.Marshal]::GetActiveObject("Outlook.Application") }
  catch { $ol = New-Object -ComObject Outlook.Application }
  $ns = $ol.GetNamespace("MAPI")
  $inbox = $ns.GetDefaultFolder(6)   # 6 = Bandeja de entrada
} catch {
  Write-Output "ERROR: no se pudo abrir Outlook. Abrilo una vez a mano y volve a intentar."
  exit 1
}
$items = $inbox.Items
$items.Sort("[ReceivedTime]", $true)
Write-Output ("BANDEJA: {0} | Total: {1} | Sin leer: {2}" -f $inbox.Parent.Name, $items.Count, $inbox.UnReadItemCount)
Write-Output ("=" * 70)
$n = 0
foreach ($m in $items) {
  if ($m.Class -ne 43) { continue }         # 43 = MailItem
  if ($SoloSinLeer -and -not $m.UnRead) { continue }
  $n++
  if ($n -gt $Cantidad) { break }
  $de = $m.SenderName; if (-not $de) { $de = "(sin remitente)" }
  if ($de.Length -gt 26) { $de = $de.Substring(0,24) + ".." }
  $marca = if ($m.UnRead) { "*" } else { " " }
  Write-Output ("{0,3}. [{1}] {2:dd/MM HH:mm}  {3,-26}  {4}" -f $n, $marca, $m.ReceivedTime, $de, $m.Subject)
}
Write-Output ("=" * 70)
Write-Output "(* = sin leer)  ver uno: leer-correo.ps1 -Numero <n>"
