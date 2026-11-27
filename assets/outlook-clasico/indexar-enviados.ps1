# indexar-enviados.ps1 - Recorre UNA vez los Enviados de un buzon y guarda un indice local de
# "que se pregunto / que se respondio", para armar respuestas al instante sin volver a buscar.
# SOLO LEE el correo. El indice queda en la computadora (~/.correos-tup/indice/), no en la skill.
#
#   ... indexar-enviados.ps1 -Buzon "Tec Programacion" [-Dias 180]
#
# - Respuestas a una o pocas personas -> "respuestas" (con la pregunta citada, si la hay).
# - Envios a muchas personas (avisos)  -> "avisos" (suelen traer fechas, lugares y requisitos).
# Se tapan DNI, legajos, telefonos y direcciones de correo para no guardar datos personales.
# Con indice previo, solo agrega lo enviado despues (rapido); -Rehacer lo arma de cero.
param(
  [string]$Buzon = "",
  [int]$Dias = 180,
  [switch]$Rehacer
)
. "$PSScriptRoot\buzon-comun.ps1"
$ErrorActionPreference = "Stop"
Conectar-Outlook
$store = Elegir-Buzon $Buzon
$ruta = Join-Path (Carpeta-Datos "indice") ((Clave-DeBuzon $store) + ".json")

function Tapar([string]$t) {
  $t = $t -replace '[\w.+-]+@[\w-]+(\.[\w-]+)+', '[correo]'
  $t = $t -replace '\b\d{2}\.?\d{3}\.?\d{3}\b', '[numero]'     # DNI
  $t = $t -replace '(?i)\b(leg(ajo)?\.?\s*(n[o.]?\s*)?[:#]?\s*)\d{4,6}\b', '$1[numero]'
  $t = $t -replace '(?i)\b(dni\s*[:#]?\s*)\d{1,2}[\s.]?\d{3}[\s.]?\d{3}\b', '$1[numero]'
  $t = $t -replace '\b(\+?\d[\d\s-]{8,}\d)\b', '[telefono]'
  return $t
}

$previo = $null
if (-not $Rehacer) { $previo = Leer-Json $ruta }
$desde = (Get-Date).AddDays(-$Dias)
if ($previo -and $previo.hasta) { $desde = [datetime]$previo.hasta }

$items = $store.GetDefaultFolder(5).Items
$items.Sort("[SentOn]", $true)
$lista = New-Object System.Collections.ArrayList
foreach ($m in $items) {
  if ($m.Class -ne 43) { continue }
  if ($m.SentOn -le $desde) { break }
  [void]$lista.Add($m)
}

$respuestas = New-Object System.Collections.ArrayList
$avisos = New-Object System.Collections.ArrayList
if ($previo) {
  foreach ($r in @($previo.respuestas)) { if ($r) { [void]$respuestas.Add($r) } }
  foreach ($a in @($previo.avisos)) { if ($a) { [void]$avisos.Add($a) } }
}
$vistosAviso = @{}; foreach ($a in $avisos) { $vistosAviso[$a.asunto] = 1 }
$firmas = @{}

Progreso-Iniciar ("Aprendiendo como se responde en " + $store.DisplayName)
$i = 0
foreach ($m in $lista) {
  $i++
  Progreso-Avanzar $i $lista.Count "Leyendo los correos enviados (se hace una sola vez)"
  $c = Cortar-Historial $m.Body
  if (-not $c.texto) { continue }
  $asunto = Tapar ($m.Subject -replace '^\s*((RE|Re|RV|Rv|FW|Fw|Fwd|FWD)\s*:\s*)+', '').Trim()
  $destinatarios = 0; try { $destinatarios = $m.Recipients.Count } catch {}
  if ($destinatarios -gt 3) {
    if ($vistosAviso.ContainsKey($asunto)) { continue }   # el mismo aviso a varios grupos
    $vistosAviso[$asunto] = 1
    [void]$avisos.Add([ordered]@{ fecha = $m.SentOn.ToString("yyyy-MM-dd"); asunto = $asunto; texto = (Una-Linea (Tapar $c.texto) 2500) })
    continue
  }
  # firma: las dos ultimas lineas no vacias de la respuesta
  $lineas = @($c.texto -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  if ($lineas.Count -ge 2) { $f = ($lineas[-2..-1] -join " / "); if ($f.Length -lt 120) { $firmas[$f] = 1 + [int]$firmas[$f] } }
  $pregunta = ""
  if ($c.citado) {
    $q = Cortar-Historial (($c.citado -split "`r?`n", 2 | Select-Object -Last 1))
    $q2 = ($q.texto -replace '(?m)^(De|From|Enviado|Sent|Para|To|CC|Asunto|Subject)\s*:.*$', '')
    $pregunta = Una-Linea (Tapar $q2) 700
  }
  [void]$respuestas.Add([ordered]@{ fecha = $m.SentOn.ToString("yyyy-MM-dd"); asunto = $asunto; pregunta = $pregunta; respuesta = (Una-Linea (Tapar $c.texto) 1500) })
}
Progreso-Cerrar

$hasta = if ($lista.Count -gt 0) { $lista[0].SentOn.ToString("s") } elseif ($previo) { $previo.hasta } else { (Get-Date).ToString("s") }
$firmasPrev = @{}
if ($previo -and $previo.firmas) { foreach ($p in $previo.firmas.PSObject.Properties) { $firmasPrev[$p.Name] = [int]$p.Value } }
foreach ($k in $firmas.Keys) { $firmasPrev[$k] = $firmas[$k] + [int]$firmasPrev[$k] }

Guardar-Json ([ordered]@{
  buzon = $store.DisplayName; direccion = (Direccion-DeBuzon $store); hasta = $hasta
  actualizado = (Get-Date).ToString("s"); respuestas = $respuestas; avisos = $avisos; firmas = $firmasPrev
}) $ruta

Write-Output ("INDICE de {0}: {1} respuestas y {2} avisos (nuevos en esta pasada: {3} correos)." -f $store.DisplayName, $respuestas.Count, $avisos.Count, $lista.Count)
Write-Output "Temas que mas se respondieron:"
$respuestas | Group-Object { $_.asunto.ToLower() } | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object { Write-Output ("  {0,4}  {1}" -f $_.Count, $_.Group[0].asunto) }
Write-Output "Firmas mas usadas (quien responde):"
$firmasPrev.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5 | ForEach-Object { Write-Output ("  {0,4}  {1}" -f $_.Value, $_.Key) }
Write-Output "Buscar como se respondio algo: buscar-respuestas.ps1 -Buzon ... -Texto ""palabras"""
