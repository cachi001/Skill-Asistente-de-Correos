# ponerse-al-dia.ps1 - Todo lo necesario para el resumen, en UNA sola pasada (rapido).
# Trae los correos de la bandeja de los ultimos N dias que nadie respondio todavia, agrupa los
# que son de la misma persona por el mismo tema, y devuelve fecha, remitente y el texto (sin
# historial citado). Ordenado por fecha, el mas nuevo arriba. SOLO LEE: no marca nada como leido.
# Cada fila trae "numero N": es el del correo mas nuevo de ese grupo, el mismo que usan
# leer-correo.ps1 y crear-borrador.ps1 -Numero (con el mismo -Buzon).
#
#   ... ponerse-al-dia.ps1 -Buzon "Tec Programacion" [-Dias 14] [-Incluir respondidos] [-Largo 700] [-SoloNuevos]
#
#  -SoloNuevos : solo lo que llego desde la ultima vez que se corrio para ese buzon.
#  -Incluir respondidos : muestra tambien los ya respondidos desde Outlook (marcados).
param(
  [string]$Buzon = "",
  [int]$Dias = 14,
  [int]$Largo = 700,
  [string]$Incluir = "",
  [switch]$SoloNuevos
)
. "$PSScriptRoot\buzon-comun.ps1"
$ErrorActionPreference = "Stop"
Conectar-Outlook
$store = Elegir-Buzon $Buzon
$dirBuzon = (Direccion-DeBuzon $store).ToLower()
$rutaEstado = Join-Path (Carpeta-Datos "estado") ((Clave-DeBuzon $store) + ".json")
$estado = Leer-Json $rutaEstado

$desde = (Get-Date).AddDays(-$Dias)
if ($SoloNuevos -and $estado -and $estado.ultimaVez) { $desde = [datetime]$estado.ultimaVez }
$inicioCorrida = Get-Date

$inbox = $store.GetDefaultFolder(6)
$items = $inbox.Items
$items.Sort("[ReceivedTime]", $true)
$sinLeerAntes = $inbox.UnReadItemCount

# Primero cuantos hay en el periodo (para la barra de progreso)
$lista = New-Object System.Collections.ArrayList
foreach ($m in $items) {
  if ($m.Class -ne 43) { continue }
  if ($m.ReceivedTime -lt $desde) { break }
  [void]$lista.Add($m)
}

Progreso-Iniciar ("Leyendo los correos de " + $store.DisplayName)
$grupos = [ordered]@{}
$i = 0; $yaRespondidos = 0
foreach ($m in $lista) {
  $i++
  Progreso-Avanzar $i $lista.Count "Leyendo los correos que llegaron"
  $resp = Estado-Respuesta $m
  if ($resp -and $Incluir -ne "respondidos") { $yaRespondidos++; continue }
  $correo = (Correo-DeRemitente $m)
  if ($correo -and $correo.ToLower() -eq $dirBuzon) { continue }   # mensajes del propio buzon
  $tema = ($m.Subject -replace '^\s*((RE|Re|RV|Rv|FW|Fw|Fwd|FWD|RE \d+)\s*:\s*)+', '').Trim().ToLower()
  $clave = ("{0}|{1}" -f $correo, $tema)
  if (-not $grupos.Contains($clave)) {
    $c = Cortar-Historial $m.Body
    $grupos[$clave] = [ordered]@{
      numero = $i   # mismo numero que leer-bandeja / leer-correo / crear-borrador -Numero
      ultimo = $m.ReceivedTime; primero = $m.ReceivedTime; cantidad = 1
      de = $m.SenderName; correo = $correo; asunto = $m.Subject
      sinLeer = $m.UnRead; respondido = $resp; texto = (Una-Linea $c.texto $Largo)
      adjuntos = $m.Attachments.Count
    }
  } else {
    $g = $grupos[$clave]; $g.cantidad++; $g.primero = $m.ReceivedTime
    if ($m.UnRead) { $g.sinLeer = $true }
    if ($g.texto.Length -lt $Largo) {   # sumar el texto de los anteriores, si entra
      $c = Cortar-Historial $m.Body
      $g.texto = Una-Linea ($g.texto + " || antes (" + $m.ReceivedTime.ToString("dd/MM") + "): " + $c.texto) ($Largo * 2)
    }
  }
}
Progreso-Cerrar

Write-Output ("BUZON: {0} <{1}>" -f $store.DisplayName, $dirBuzon)
Write-Output ("Periodo: desde {0:dd/MM/yyyy HH:mm} | Correos en el periodo: {1} | Ya respondidos desde Outlook: {2} | Para revisar: {3} personas/temas" -f $desde, $lista.Count, $yaRespondidos, $grupos.Count)
Write-Output ("=" * 70)
$n = 0
foreach ($g in $grupos.Values) {
  $n++
  $veces = if ($g.cantidad -gt 1) { " ({0} correos, desde el {1:dd/MM})" -f $g.cantidad, $g.primero } else { "" }
  $marca = @()
  if ($g.sinLeer) { $marca += "sin leer" }
  if ($g.respondido) { $marca += $g.respondido }
  if ($g.adjuntos -gt 0) { $marca += ("{0} adjunto(s)" -f $g.adjuntos) }
  Write-Output ("{0}. {1:dd/MM HH:mm} | {2} <{3}>{4} | {5}" -f $n, $g.ultimo, $g.de, $g.correo, $veces, $g.asunto)
  $marca += ("numero {0}" -f $g.numero)
  Write-Output ("   [" + ($marca -join ", ") + "]")
  Write-Output ("   " + $g.texto)
  Write-Output ""
}
if ($grupos.Count -eq 0) { Write-Output "No hay correos sin responder en ese periodo." }

# Control de solo lectura: la cantidad de sin leer no tiene que cambiar
Write-Output ("Sin leer antes: {0} | despues: {1}" -f $sinLeerAntes, $inbox.UnReadItemCount)
Guardar-Json ([ordered]@{ ultimaVez = $inicioCorrida.ToString("s") }) $rutaEstado
