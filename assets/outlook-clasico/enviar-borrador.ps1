# enviar-borrador.ps1 - Envia UN borrador armado por la skill. Solo se corre con el OK de la persona.
#
#   powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File enviar-borrador.ps1 -Codigo 4821
#
# Candado de envio:
#  - Necesita el CODIGO DE ENVIO que dio crear-borrador.ps1 para ese borrador. Sin codigo no envia.
#  - El codigo se usa una sola vez: despues de enviar se borra (un OK = un correo).
#  - Si el buzon esta en modo solo lectura, no envia.
#  - Si el borrador ya no esta (se envio o se borro), no hace nada.
# Los borradores escritos a mano en Outlook no tienen codigo: se envian desde Outlook.
param(
  [Parameter(Mandatory = $true)][string]$Codigo
)
. "$PSScriptRoot\buzon-comun.ps1"
$ErrorActionPreference = "Stop"

$e = Tomar-CodigoEnvio $Codigo
if (-not $e) {
  Write-Output "NO ENVIADO: el codigo $Codigo no existe o ya se uso. Cada borrador tiene su propio codigo y sirve una sola vez."
  exit 1
}
Conectar-Outlook
$b = $null
try { $b = $ns.GetItemFromID($e.entryId, $e.storeId) } catch {}
if (-not $b -or $b.Class -ne 43 -or $b.Sent -or $b.Parent.EntryID -ne $b.Parent.Store.GetDefaultFolder(16).EntryID) {
  Borrar-CodigoEnvio $Codigo
  Write-Output "NO ENVIADO: ese borrador ya no esta en Borradores (se envio o se borro). Revisa Elementos enviados antes de armar otro."
  exit 1
}
Exigir-Escritura $b.Parent.Store
$desde = Remitente-DeBorrador $b; $para = $b.To; $asu = $b.Subject
foreach ($s in (Lista-Buzones)) { if ((Direccion-DeBuzon $s) -eq $desde) { Exigir-Escritura $s } }   # el buzon desde el que sale

Borrar-CodigoEnvio $Codigo        # se consume ANTES de enviar: nunca se puede usar dos veces
$b.Send()
Write-Output ("ENVIADO desde {0} | Para {1} | Asunto: {2}" -f $desde, $para, $asu)
