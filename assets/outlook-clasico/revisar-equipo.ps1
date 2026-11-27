# revisar-equipo.ps1 - Chequeo rapido al empezar: que esta listo y que falta, en palabras simples.
# No cambia nada (si Outlook esta cerrado, no lo abre).
#
#   ... revisar-equipo.ps1
param()
. "$PSScriptRoot\buzon-comun.ps1"

function Linea([bool]$ok, [string]$txt, [string]$siNo = "") {
  if ($ok) { Write-Output ("[OK]    " + $txt) } else { Write-Output ("[FALTA] " + $txt + $(if ($siNo) { " -> " + $siNo } else { "" })) }
}
Write-Output "CHEQUEO DEL EQUIPO"
Write-Output ("=" * 70)

# 1. Version de la skill
$vLocal = ""; $rv = Join-Path $PSScriptRoot "..\..\VERSION"
if (Test-Path $rv) { $vLocal = (Get-Content $rv -Raw).Trim() }
$vWeb = ""
try { $vWeb = (Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 "https://raw.githubusercontent.com/cachi001/Skill-Asistente-de-Correos/main/VERSION").Content.Trim() } catch {}
if ($vWeb -and $vLocal -and ([version]$vWeb -gt [version]$vLocal)) {
  Linea $false ("Skill version $vLocal (hay una nueva: $vWeb)") "actualizar con: npx skills update tup-asistente-correos -g -y"
} else { Linea $true ("Skill version $vLocal" + $(if (-not $vWeb) { " (no pude comprobar si hay una nueva)" } else { " (es la ultima)" })) }

# 2. Outlook clasico
$est = Estado-Outlook
$exe = $est.clasico
if ($exe) { Linea $true "Outlook clasico instalado" }
elseif ($est.office) { Linea $false ("Outlook clasico instalado (hay Office sin Outlook: {0})" -f $est.office) "instalarlo con instalar-outlook.ps1 (Word y Excel quedan)" }
elseif ($est.nuevo) { Linea $false "Outlook clasico instalado (solo esta el Outlook nuevo, que no sirve)" "instalarlo con instalar-outlook.ps1" }
else { Linea $false "Outlook clasico instalado (no hay ningun Outlook)" "instalarlo con instalar-outlook.ps1 (Gmail funciona igual sin Outlook)" }
if ($exe) { Linea (-not $est.usaNuevo) "Se abre el clasico (interruptor 'Nuevo Outlook' apagado)" "apagarlo con instalar-outlook.ps1 -VolverAlClasico" }
if ($exe) { Linea $est.perfil "Cuenta configurada en Outlook" "agregarla con agregar-cuenta.ps1" }
$abierto = [bool](Get-Process OUTLOOK -ErrorAction SilentlyContinue)
if ($exe) { Linea $abierto "Outlook abierto" "la skill lo abre sola cuando haga falta" }

# 3. Cartel de "acceso por programa"
$k = "HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security"
$sinCartel = $false
try { $v = Get-ItemProperty $k -ErrorAction Stop; $sinCartel = ($v.AdminSecurityMode -eq 3 -and $v.PromptOOMSend -eq 2) } catch {}
if ($exe) { Linea $sinCartel "Sin el cartel de 'permitir acceso' de Outlook" "puede aparecer un cartel pidiendo 'Permitir' (ver outlook-clasico.md)" }

# 4. Buzones (solo si Outlook ya esta abierto, para no abrirlo)
if ($abierto) {
  try {
    $script:ol = New-Object -ComObject Outlook.Application; $script:ns = $script:ol.GetNamespace("MAPI")
    $bs = @(Lista-Buzones)
    Linea ($bs.Count -gt 0) ("Buzones en Outlook: " + $bs.Count)
    foreach ($s in $bs) {
      $m = if (Es-SoloLectura $s) { " [SOLO LECTURA]" } else { "" }
      Write-Output ("          - {0} <{1}>{2}" -f $s.DisplayName, (Direccion-DeBuzon $s), $m)
    }
  } catch { Linea $false "No pude leer los buzones" "reintentar en unos segundos" }
}

# 5. Base de respuestas e indices
$base = Join-Path (Carpeta-Datos) "conocimiento"
$temas = @(Get-ChildItem $base -Filter *.md -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "_*" })
Linea ($temas.Count -gt 0) ("Base de respuestas: {0} temas" -f $temas.Count) "se arma con la persona (opcion 2), a partir de los enviados"
$idx = @(Get-ChildItem (Carpeta-Datos "indice") -Filter *.json -ErrorAction SilentlyContinue)
foreach ($i in $idx) { Write-Output ("[OK]    Indice de enviados: {0} (al {1:dd/MM/yyyy})" -f $i.BaseName, $i.LastWriteTime) }
if (-not $idx) { Linea $false "Indice de enviados" "se arma una vez con indexar-enviados.ps1 (barra de progreso)" }
Write-Output ("=" * 70)
Write-Output "Google Sheets y Gmail los revisa Claude (son conectores, no se ven desde aca)."
