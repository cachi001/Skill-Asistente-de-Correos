# enviar-borrador.ps1 — Envia UN borrador ya creado. Solo se corre con el OK de la persona.
# Se identifica el borrador por parte del asunto (-Asunto) para no mandar el equivocado.
#
#   powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File enviar-borrador.ps1 -Asunto "Constancia de alumno"
#
# Si varios borradores coinciden, NO envia ninguno y los lista (para elegir mejor el texto).
param(
  [Parameter(Mandatory=$true)][string]$Asunto
)
$ErrorActionPreference = "Stop"
try {
  try { $ol = [Runtime.InteropServices.Marshal]::GetActiveObject("Outlook.Application") }
  catch { $ol = New-Object -ComObject Outlook.Application }
  $ns = $ol.GetNamespace("MAPI")
  $drafts = $ns.GetDefaultFolder(16)   # 16 = Borradores
} catch { Write-Output "ERROR: no se pudo abrir Outlook."; exit 1 }

$coincidencias = @()
foreach ($m in $drafts.Items) { if ($m.Class -eq 43 -and $m.Subject -like "*$Asunto*") { $coincidencias += $m } }

if ($coincidencias.Count -eq 0) { Write-Output "No hay ningun borrador cuyo asunto contenga: $Asunto"; exit 1 }
if ($coincidencias.Count -gt 1) {
  Write-Output "HAY VARIOS borradores que coinciden. No envio ninguno. Precisa mas el asunto:"
  foreach ($m in $coincidencias) { Write-Output (" - Para: {0} | Asunto: {1}" -f $m.To, $m.Subject) }
  exit 1
}
$b = $coincidencias[0]
$para = $b.To; $asu = $b.Subject
$b.Send()
Write-Output ("ENVIADO: Para {0} | Asunto: {1}" -f $para, $asu)
