# buscar-respuestas.ps1 - Busca en el indice de enviados (indexar-enviados.ps1) como se respondio
# antes algo parecido. Instantaneo: no abre Outlook ni lee el correo.
#
#   ... buscar-respuestas.ps1 -Buzon "Tec Programacion" -Texto "fecha de pago de la cuota" [-Max 3]
#
# Devuelve las respuestas y los avisos que mas se parecen, con su fecha (la mas nueva gana si empatan).
param(
  [string]$Buzon = "",
  [Parameter(Mandatory = $true)][string]$Texto,
  [int]$Max = 3
)
. "$PSScriptRoot\buzon-comun.ps1"
$ErrorActionPreference = "Stop"

function Normalizar([string]$t) {
  $t = $t.ToLower().Normalize([Text.NormalizationForm]::FormD)
  return ($t -replace '\p{Mn}', '' -replace '[^a-z0-9 ]', ' ')
}
$vacias = @("para","como","cual","cuando","donde","quiero","queria","saber","consulta","consultar","hola","buenas","tardes","dias","noches","gracias","desde","sobre","esta","este","estoy","tengo","puedo","seria","favor","muchas","saludos","que","los","las","del","una","con","por","mas")
$palabras = @((Normalizar $Texto) -split '\s+' | Where-Object { $_.Length -ge 3 -and $vacias -notcontains $_ } | Select-Object -Unique)
if (-not $palabras) { Write-Output "ERROR: pone palabras mas concretas (ej: 'fecha pago cuota')."; exit 1 }

# Buscar el indice: por nombre de buzon si hay Outlook, si no, el unico indice que exista
$dirIdx = Carpeta-Datos "indice"
$archivos = @(Get-ChildItem $dirIdx -Filter *.json -ErrorAction SilentlyContinue)
if ($Buzon) { $archivos = @($archivos | Where-Object { $_.BaseName -like ("*" + (($Buzon.ToLower()) -replace '[^a-z0-9]+', '-') + "*") }) }
if ($archivos.Count -eq 0) {
  if ($Buzon) {   # quizas -Buzon es el nombre visible: resolverlo por Outlook
    Conectar-Outlook; $s = Elegir-Buzon $Buzon
    $archivos = @(Get-ChildItem $dirIdx -Filter ((Clave-DeBuzon $s) + ".json") -ErrorAction SilentlyContinue)
  }
}
if ($archivos.Count -eq 0) { Write-Output "No hay indice para ese buzon. Primero: indexar-enviados.ps1 -Buzon ..."; exit 1 }
if ($archivos.Count -gt 1) { Write-Output "Hay varios indices, precisa -Buzon:"; $archivos | ForEach-Object { " - " + $_.BaseName }; exit 1 }
$idx = Leer-Json $archivos[0].FullName

function Puntaje([string]$t, [int]$peso) {
  $n = Normalizar $t; $p = 0
  foreach ($w in $palabras) { if ($n -match ("\b" + [regex]::Escape($w))) { $p += $peso } }
  return $p
}
$cands = @()
foreach ($r in @($idx.respuestas)) {
  $p = (Puntaje ($r.asunto + " " + $r.pregunta) 2) + (Puntaje $r.respuesta 1)
  if ($p -gt 0) { $cands += [pscustomobject]@{ tipo = "RESPUESTA"; p = $p; fecha = $r.fecha; asunto = $r.asunto; pregunta = $r.pregunta; texto = $r.respuesta } }
}
foreach ($a in @($idx.avisos)) {
  $p = (Puntaje $a.asunto 2) + (Puntaje $a.texto 1)
  if ($p -gt 0) { $cands += [pscustomobject]@{ tipo = "AVISO"; p = $p; fecha = $a.fecha; asunto = $a.asunto; pregunta = ""; texto = $a.texto } }
}
Write-Output ("Buscando en {0} (indice al {1}): {2}" -f $idx.buzon, ([datetime]$idx.hasta).ToString("dd/MM/yyyy"), ($palabras -join ", "))
if (-not $cands) { Write-Output "No encontre nada parecido en lo enviado. Hay que preguntarle a la persona."; exit 0 }
$top = $cands | Sort-Object @{ e = { $_.p }; Descending = $true }, @{ e = { $_.fecha }; Descending = $true } | Select-Object -First $Max
foreach ($c in $top) {
  Write-Output ("=== {0} del {1} | {2}" -f $c.tipo, ([datetime]$c.fecha).ToString("dd/MM/yyyy"), $c.asunto)
  if ($c.pregunta) { Write-Output ("   Le preguntaron: " + (Una-Linea $c.pregunta 400)) }
  Write-Output ("   Se respondio: " + (Una-Linea $c.texto 1200))
  Write-Output ""
}
