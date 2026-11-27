# agregar-cuenta.ps1 — Abre la ventana de Outlook "Agregar cuenta" para que la persona inicie sesion.
# La skill NO ve ni escribe la contrasena: la persona la pone en la ventana oficial de Microsoft.
# Si Outlook esta cerrado, lo abre y espera a que este listo.
#
#   powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File agregar-cuenta.ps1
#
# La ventana es modal: este script queda esperando hasta que la persona la cierre.
# Por eso la skill lo lanza aparte, sin esperar (ver references/outlook-clasico.md).
$ErrorActionPreference = "Stop"
$exe = @(
  "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE",
  "C:\Program Files (x86)\Microsoft Office\root\Office16\OUTLOOK.EXE"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $exe) { Write-Output "ERROR: no encuentro el Outlook clasico instalado."; exit 1 }

if (-not (Get-Process OUTLOOK -ErrorAction SilentlyContinue)) { Start-Process $exe }

# Esperar a que Outlook tenga su ventana principal (hasta ~90 s)
$exp = $null
for ($i = 0; $i -lt 45 -and -not $exp; $i++) {
  try { $ol = New-Object -ComObject Outlook.Application; $exp = $ol.ActiveExplorer() } catch {}
  if (-not $exp) { Start-Sleep -Seconds 2 }
}
if (-not $exp) { Write-Output "ERROR: Outlook no termino de abrir. Abrilo a mano y volve a intentar."; exit 1 }

try {
  $exp.Activate()
  $exp.CommandBars.ExecuteMso("AddAccount")   # misma accion que Archivo > Agregar cuenta
} catch {
  Write-Output "ERROR: no se pudo abrir la ventana. Hacelo a mano: Archivo > Agregar cuenta."
  exit 1
}
Write-Output "Ventana de agregar cuenta cerrada."
