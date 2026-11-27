# modo-buzon.ps1 - Pone o saca un buzon del modo SOLO LECTURA. Solo cuando la persona lo pide.
# En solo lectura, crear-borrador y enviar-borrador se niegan a trabajar con ese buzon.
#
#   ... modo-buzon.ps1 -Buzon alberto -SoloLectura si
#   ... modo-buzon.ps1 -Buzon alberto -SoloLectura no
#   ... modo-buzon.ps1            (sin nada: muestra como esta cada buzon)
param(
  [string]$Buzon = "",
  [ValidateSet("", "si", "no")][string]$SoloLectura = ""
)
. "$PSScriptRoot\buzon-comun.ps1"
$ErrorActionPreference = "Stop"
Conectar-Outlook
$ruta = Join-Path (Carpeta-Datos) "buzones.json"

if ($Buzon -and $SoloLectura) {
  $store = Elegir-Buzon $Buzon
  $tabla = @{}
  $prev = Leer-Json $ruta
  if ($prev) { foreach ($p in $prev.PSObject.Properties) { $tabla[$p.Name] = $p.Value } }
  $k = Clave-DeBuzon $store
  $tabla[$k] = [ordered]@{ nombre = $store.DisplayName; direccion = (Direccion-DeBuzon $store); soloLectura = ($SoloLectura -eq "si"); cambiado = (Get-Date).ToString("s") }
  Guardar-Json $tabla $ruta
  $txt = if ($SoloLectura -eq "si") { "SOLO LECTURA (no se crea ni se envia nada)" } else { "normal (se pueden armar borradores y enviar con OK)" }
  Write-Output ("Listo: {0} <{1}> queda en modo {2}." -f $store.DisplayName, (Direccion-DeBuzon $store), $txt)
  exit 0
}

Write-Output "MODO DE CADA BUZON"
foreach ($s in (Lista-Buzones)) {
  $m = if (Es-SoloLectura $s) { "SOLO LECTURA" } else { "normal" }
  Write-Output (" - {0} <{1}> : {2}" -f $s.DisplayName, (Direccion-DeBuzon $s), $m)
}
