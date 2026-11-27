# listar-buzones.ps1 — Muestra los buzones del Outlook (cuenta propia, otras cuentas y compartidos).
# El nombre que aparece es el que se pasa como -Buzon a los demas scripts.
#
#   powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File listar-buzones.ps1
. "$PSScriptRoot\buzon-comun.ps1"
$ErrorActionPreference = "Stop"
Conectar-Outlook
Write-Output "BUZONES EN ESTE OUTLOOK"
Write-Output ("=" * 70)
foreach ($s in (Lista-Buzones)) {
  $inb = $s.GetDefaultFolder(6)
  Write-Output ("- {0} <{1}> | {2} | {3} correos, {4} sin leer" -f $s.DisplayName, (Direccion-DeBuzon $s), (Tipo-DeBuzon $s), $inb.Items.Count, $inb.UnReadItemCount)
}
Write-Output ("=" * 70)
Write-Output "Para usar uno: -Buzon <nombre>  (sin -Buzon se usa tu cuenta)"
