# esperar-buzon.ps1 - Despues de agregar una cuenta, espera a que Outlook baje sus correos,
# mostrandole a la persona una ventanita con lo que va pasando. Solo lee.
#
#   ... esperar-buzon.ps1 -Buzon alberto [-Minutos 5]
#
# Termina cuando la bandeja deja de crecer (3 chequeos iguales) o al llegar al tiempo maximo.
param(
  [Parameter(Mandatory = $true)][string]$Buzon,
  [int]$Minutos = 5
)
. "$PSScriptRoot\buzon-comun.ps1"
$ErrorActionPreference = "Stop"
$fin = (Get-Date).AddMinutes($Minutos)
$ant = -1; $iguales = 0; $nombre = $Buzon
Progreso-Iniciar ("Preparando la cuenta " + $Buzon)
$script:prog.ini = (Get-Date).AddSeconds(-5)   # que la ventanita aparezca enseguida
while ((Get-Date) -lt $fin) {
  $n = -1
  try {
    $ol = New-Object -ComObject Outlook.Application; $script:ns = $ol.GetNamespace("MAPI")
    foreach ($s in $script:ns.Stores) {
      if ($s.DisplayName -like "*$Buzon*") { $nombre = $s.DisplayName; try { $n = $s.GetDefaultFolder(6).Items.Count } catch {} }
    }
  } catch {}
  $txt = if ($n -lt 0) { "Esperando que Outlook muestre la cuenta..." } else { "Outlook esta bajando los correos: van $n" }
  for ($k = 0; $k -lt 10; $k++) { Progreso-Avanzar 0 0 $txt; Start-Sleep -Milliseconds 300 }
  if ($n -gt 0 -and $n -eq $ant) { $iguales++ } else { $iguales = 0 }
  if ($iguales -ge 3) { break }
  $ant = $n
}
Progreso-Cerrar
if ($ant -le 0) { Write-Output "TODAVIA NO: la cuenta $Buzon no aparece o no tiene correos. Revisa que la ventana de Outlook haya terminado."; exit 1 }
Write-Output ("LISTO: {0} con {1} correos en la bandeja de entrada." -f $nombre, $ant)
