# agregar-cuenta.ps1 — Abre la ventana de Outlook "Agregar cuenta" para que la persona inicie sesion.
# La skill NO ve ni escribe la contrasena: la persona la pone en la ventana oficial de Microsoft.
# Si Outlook esta cerrado, lo abre y espera a que este listo.
#
#   powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File agregar-cuenta.ps1
#
# La ventana es modal: este script queda esperando hasta que la persona la cierre.
# Por eso la skill lo lanza aparte, sin esperar (ver references/outlook-clasico.md).
. "$PSScriptRoot\buzon-comun.ps1"
$ErrorActionPreference = "Stop"
$est = Estado-Outlook
$exe = $est.clasico
if (-not $exe) { Write-Output "ERROR: no hay Outlook clasico instalado. Primero: instalar-outlook.ps1"; exit 1 }
if ($est.usaNuevo) { Write-Output "ERROR: el interruptor 'Nuevo Outlook' esta prendido y abriria el nuevo. Primero: instalar-outlook.ps1 -VolverAlClasico"; exit 1 }

# Outlook recien instalado, sin ninguna cuenta: al abrirlo muestra solo su pantalla de
# "Agregar cuenta". No hay que hacer nada mas.
if (-not $est.perfil) {
  if (-not (Get-Process OUTLOOK -ErrorAction SilentlyContinue)) { Start-Process $exe }
  Write-Output "Outlook se abrio con su pantalla para agregar la cuenta (es la primera vez). La persona pone su correo y sigue los pasos."
  exit 0
}

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
