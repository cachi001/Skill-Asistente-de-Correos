# enviar-borrador.ps1 — Envia UN borrador ya creado. Solo se corre con el OK de la persona.
# Se identifica el borrador por parte del asunto (-Asunto) para no mandar el equivocado.
# Busca en los Borradores de todos los buzones. Con -Buzon, solo los que salen desde ese buzon.
#
#   powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File enviar-borrador.ps1 -Asunto "Constancia de alumno" [-Buzon Certificaciones]
#
# Si varios borradores coinciden, NO envia ninguno y los lista (para elegir mejor).
param(
  [Parameter(Mandatory=$true)][string]$Asunto,
  [string]$Buzon = ""
)
. "$PSScriptRoot\buzon-comun.ps1"
$ErrorActionPreference = "Stop"
Conectar-Outlook
$dirBuzon = ""
if ($Buzon) { $dirBuzon = Direccion-DeBuzon (Elegir-Buzon $Buzon) }

$coincidencias = @(); $vistos = @{}
foreach ($s in (Lista-Buzones)) {
  try { $drafts = $s.GetDefaultFolder(16) } catch { continue }   # 16 = Borradores
  foreach ($m in $drafts.Items) {
    if ($m.Class -ne 43 -or $m.Subject -notlike "*$Asunto*") { continue }
    if ($vistos.ContainsKey($m.EntryID)) { continue }; $vistos[$m.EntryID] = 1
    if ($dirBuzon -and (Remitente-DeBorrador $m) -ne $dirBuzon) { continue }
    $coincidencias += $m
  }
}

if ($coincidencias.Count -eq 0) { Write-Output "No hay ningun borrador cuyo asunto contenga: $Asunto"; exit 1 }
if ($coincidencias.Count -gt 1) {
  Write-Output "HAY VARIOS borradores que coinciden. No envio ninguno. Precisa mas el asunto o el buzon:"
  foreach ($m in $coincidencias) { Write-Output (" - Desde: {0} | Para: {1} | Asunto: {2}" -f (Remitente-DeBorrador $m), $m.To, $m.Subject) }
  exit 1
}
$b = $coincidencias[0]
$desde = Remitente-DeBorrador $b; $para = $b.To; $asu = $b.Subject
$b.Send()
Write-Output ("ENVIADO desde {0} | Para {1} | Asunto: {2}" -f $desde, $para, $asu)
