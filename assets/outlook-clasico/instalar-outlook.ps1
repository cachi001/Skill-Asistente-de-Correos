# instalar-outlook.ps1 - Deja la PC lista con el Outlook CLASICO (el que la skill sabe manejar).
# Usa la herramienta oficial de Microsoft (Office Deployment Tool) e instala SOLO Outlook,
# sin Word, Excel ni nada mas. La persona ve la ventana de Microsoft con su propia barra.
#
#   ... instalar-outlook.ps1 -Revisar          solo dice que hay en la PC (no cambia nada)
#   ... instalar-outlook.ps1                   instala el clasico (Windows pide permiso: "Si")
#   ... instalar-outlook.ps1 -VolverAlClasico  apaga el interruptor "Nuevo Outlook"
#   ... instalar-outlook.ps1 -SoloPreparar     baja y verifica el instalador, sin instalar
#
# Tarda entre 5 y 15 minutos segun internet: la skill lo lanza en segundo plano.
param([switch]$Revisar, [switch]$VolverAlClasico, [switch]$SoloPreparar)
. "$PSScriptRoot\buzon-comun.ps1"
$ProgressPreference = "SilentlyContinue"
$e = Estado-Outlook

function Situacion($e) {
  if ($e.clasico -and $e.usaNuevo) { return "USA EL NUEVO" }
  if ($e.clasico) { return "CLASICO" }
  if ($e.office) { return "OFFICE SIN OUTLOOK" }
  if ($e.nuevo) { return "SOLO EL NUEVO" }
  return "NINGUNO"
}
$sit = Situacion $e

if ($Revisar) {
  switch ($sit) {
    "CLASICO"            { Write-Output ("CLASICO: el Outlook clasico esta instalado ({0}). {1}" -f $e.clasico, $(if ($e.perfil) { "Ya tiene cuenta configurada." } else { "Falta agregar la cuenta: agregar-cuenta.ps1" })) }
    "USA EL NUEVO"       { Write-Output "USA EL NUEVO: el clasico esta instalado pero el interruptor 'Nuevo Outlook' esta prendido, asi que abre el nuevo. Solucion: instalar-outlook.ps1 -VolverAlClasico" }
    "OFFICE SIN OUTLOOK" { Write-Output ("OFFICE SIN OUTLOOK: hay Office ({0}) pero sin Outlook. No lo instalo desde aca para no tocar Word o Excel. Se agrega desde Configuracion > Aplicaciones > Microsoft 365 > Modificar, o con quien administra la PC." -f $e.office) }
    "SOLO EL NUEVO"      { Write-Output "SOLO EL NUEVO: solo esta el Outlook nuevo, que la skill no puede manejar. Solucion: instalar el clasico con instalar-outlook.ps1 (el nuevo puede quedar)." }
    "NINGUNO"            { Write-Output "NINGUNO: no hay Outlook. Solucion: instalar el clasico con instalar-outlook.ps1" }
  }
  exit 0
}

if ($VolverAlClasico) {
  if (-not $e.clasico) { Write-Output "NO: no hay Outlook clasico instalado. Primero hay que instalarlo (instalar-outlook.ps1)."; exit 1 }
  $k = 'HKCU:\Software\Microsoft\Office\16.0\Outlook\Preferences'
  if (-not (Test-Path $k)) { New-Item -Path $k | Out-Null }
  Set-ItemProperty -Path $k -Name UseNewOutlook -Value 0 -Type DWord
  Write-Output "LISTO: el interruptor 'Nuevo Outlook' quedo apagado. Si el Outlook nuevo esta abierto, cerralo; la proxima vez abre el clasico."
  exit 0
}

if ($sit -eq "CLASICO" -or $sit -eq "USA EL NUEVO") { Write-Output ("YA ESTA: el Outlook clasico ya esta instalado ({0}). No hace falta instalar nada." -f $e.clasico); exit 0 }
if ($sit -eq "OFFICE SIN OUTLOOK") {
  Write-Output ("NO INSTALO: hay Office ({0}) pero sin Outlook. Instalar desde aca podria sacar Word o Excel. Agregalo desde Configuracion > Aplicaciones > Microsoft 365 > Modificar, o pediselo a quien administra la PC." -f $e.office)
  exit 1
}

# 1. Bajar el instalador oficial (con barra) y comprobar que es de Microsoft
$dir = Carpeta-Datos "instalador"
$setup = Join-Path $dir "setup.exe"
$url = "https://officecdn.microsoft.com/pr/wsus/setup.exe"
Progreso-Iniciar "Instalando Outlook"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$wc = New-Object Net.WebClient
try {
  $tarea = $wc.DownloadFileTaskAsync($url, $setup)
  $total = 7000000
  while (-not $tarea.IsCompleted) {
    $van = 0; if (Test-Path $setup) { $van = (Get-Item $setup).Length }
    Progreso-Avanzar ([math]::Min(99, [int](100 * $van / $total))) 100 "Bajando el instalador de Microsoft"
    Start-Sleep -Milliseconds 200
  }
  if ($tarea.IsFaulted) { throw $tarea.Exception }
} catch {
  Progreso-Cerrar
  Write-Output "NO SE PUDO BAJAR el instalador de Microsoft. Revisa que haya internet y volve a intentar."
  exit 1
}
Progreso-Cerrar
$firma = Get-AuthenticodeSignature $setup
if ($firma.Status -ne "Valid" -or $firma.SignerCertificate.Subject -notmatch "Microsoft Corporation") {
  Remove-Item $setup -Force -ErrorAction SilentlyContinue
  Write-Output "NO INSTALO: el instalador bajado no tiene la firma de Microsoft. Lo borre por seguridad."
  exit 1
}

# 2. Configuracion: solo Outlook, en el idioma de Windows
$bits = if ([Environment]::Is64BitOperatingSystem) { "64" } else { "32" }
$fuera = "Access","Excel","Groove","Lync","OneDrive","OneNote","PowerPoint","Publisher","Teams","Word","Bing"
$xml = @"
<Configuration>
  <Add OfficeClientEdition="$bits" Channel="Current">
    <Product ID="O365ProPlusRetail">
      <Language ID="MatchOS" Fallback="es-es" />
$(($fuera | ForEach-Object { "      <ExcludeApp ID=""$_"" />" }) -join "`r`n")
    </Product>
  </Add>
  <Display Level="Full" AcceptEULA="TRUE" />
</Configuration>
"@
$cfg = Join-Path $dir "solo-outlook.xml"
[IO.File]::WriteAllText($cfg, $xml)

if ($SoloPreparar) {
  Write-Output ("PREPARADO: instalador de Microsoft verificado ({0}) y configuracion en {1}. No se instalo nada." -f $firma.SignerCertificate.Subject.Split(',')[0], $cfg)
  exit 0
}

# 3. Instalar: Windows pide permiso y aparece la ventana de Microsoft con su barra
try {
  $p = Start-Process -FilePath $setup -ArgumentList "/configure `"$cfg`"" -WorkingDirectory $dir -Verb RunAs -PassThru
} catch {
  Write-Output "CANCELADO: no se acepto el permiso de Windows. Cuando quieras, lo volvemos a intentar y en el cartel tocas 'Si'."
  exit 1
}
$p.WaitForExit()
$e = Estado-Outlook
if ($e.clasico) {
  Write-Output ("INSTALADO: el Outlook clasico quedo en {0}. Siguiente paso: agregar-cuenta.ps1 para iniciar sesion." -f $e.clasico)
  exit 0
}
$cod = try { $p.ExitCode } catch { "?" }
Write-Output ("NO SE INSTALO (codigo {0}). Puede que la ventana de Microsoft se haya cerrado antes o que tu cuenta no incluya Office de escritorio (por ejemplo las A1)." -f $cod)
exit 1
