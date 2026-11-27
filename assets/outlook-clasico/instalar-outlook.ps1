# instalar-outlook.ps1 - Instala el Outlook CLASICO (el que la skill maneja) con la herramienta
# oficial de Microsoft (Office Deployment Tool). Es la misma instalacion que se probo y funciono
# el 25/11/2026 (ver docs/Investigacion-y-Solucion-Correos-TUP.pdf, seccion 5):
#   - Producto Microsoft 365 Apps (O365ProPlusRetail), se activa con la cuenta institucional (A3).
#   - Excluye el Outlook NUEVO (OutlookForWindows): si no, queda el nuevo por defecto.
#   - Si la PC tiene un Office viejo (2016/2019 MSI) lo reemplaza (RemoveMSI) por el actual
#     completo, para no perder Word ni Excel. Sin Office previo, instala SOLO Outlook.
#   - Los archivos van a C:\Users\Public (el instalador de Microsoft no lee carpetas privadas).
#   - Baja el paquete directo de Microsoft (sin paquete local: un paquete parcial da error 1603).
#
#   ... instalar-outlook.ps1 -Revisar              que hay, que va a hacer y TODOS los riesgos (no cambia nada)
#   ... instalar-outlook.ps1 -Confirmado           instala. SOLO despues de contarle los riesgos a la
#                                                  persona y de que diga que si (Windows pide permiso: "Si")
#   ... instalar-outlook.ps1 -VolverAlClasico      apaga el interruptor "Nuevo Outlook"
#   ... instalar-outlook.ps1 -SoloPreparar         baja y verifica el instalador, sin instalar
#
# Tarda de 10 a 25 minutos segun internet: la skill lo lanza en segundo plano.
param([switch]$Revisar, [switch]$Confirmado, [switch]$VolverAlClasico, [switch]$SoloPreparar)
. "$PSScriptRoot\buzon-comun.ps1"
$ProgressPreference = "SilentlyContinue"
$e = Estado-Outlook

# Programas de Office viejos instalados con MSI (2010-2019). RemoveMSI los saca TODOS
# (tambien Visio, Project, etc. si los hay), por eso se listan en los riesgos.
$msi = @(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                         "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
         Where-Object { $_.DisplayName -match '^Microsoft (Office|Visio|Project|Access|Excel|Word|PowerPoint|Outlook|Publisher|OneNote|InfoPath|SharePoint Designer|Lync|Skype)' -and
                        $_.WindowsInstaller -eq 1 -and $_.SystemComponent -ne 1 } |
         Select-Object -ExpandProperty DisplayName -Unique)
$hayOfficeViejo = $msi.Count -gt 0

function Riesgos {
  $r = @()
  if ($hayOfficeViejo) {
    $r += "Se DESINSTALA el Office que tiene ahora: " + ($msi -join ", ") + ". Se reemplaza por el Office actual (Outlook clasico, Word, Excel, PowerPoint, Access, Publisher, OneNote). Si alguno de la lista no esta en el Office actual (por ejemplo Visio o Project), se pierde."
    $r += "El Office nuevo se activa con la cuenta institucional, no con la clave del Office viejo. Si deja de tener esa cuenta (por ejemplo, deja de trabajar o estudiar ahi), se queda sin Office."
    $r += "Si la cuenta no incluye Office de escritorio (las A1 no; las A3 y A5 si), el Office viejo se saca igual y el nuevo no se puede activar: se quedaria sin Office que funcione. Confirmar la licencia antes."
    $r += "Los correos, la cuenta de Outlook y los documentos NO se borran (en la prueba del 25/11 quedaron todos)."
  } elseif ($e.office) {
    $r += "Se modifica el Office que ya tiene ($($e.office)) para sumarle Outlook clasico. Word y Excel quedan, pero pueden aparecer programas de Office que no tenia (PowerPoint, Access, Publisher, OneNote)."
  } else {
    $r += "Se instala solo el Outlook clasico. No se toca ningun otro programa."
    $r += "Se activa con la cuenta institucional: si la cuenta no incluye Office de escritorio (las A1 no; las A3 y A5 si), Outlook queda instalado pero sin poder usarse."
  }
  if ($e.nuevo) { $r += "El Outlook nuevo queda instalado al lado; no se usa ni molesta." }
  $abiertos = @(Get-Process WINWORD, EXCEL, POWERPNT, OUTLOOK, MSACCESS, MSPUB, ONENOTE, VISIO, WINPROJ -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessName -Unique)
  $r += "Durante la instalacion Microsoft CIERRA solos Word, Excel, Outlook y el resto de Office, sin preguntar: lo que no este guardado se pierde. Guardar y cerrar todo antes." + $(if ($abiertos) { " AHORA estan abiertos: " + ($abiertos -join ", ") + "." } else { "" })
  $r += "Tarda de 10 a 25 minutos y baja entre 2 y 3 GB de internet. No apagar ni reiniciar la PC mientras tanto."
  $libre = try { [math]::Round((Get-PSDrive C -ErrorAction Stop).Free / 1GB, 1) } catch { $null }
  if ($null -ne $libre -and $libre -lt 10) { $r += "Hay poco espacio en el disco C: ($libre GB libres; hacen falta unos 10 GB)." }
  $esAdminPosible = [bool]((whoami /groups) -match 'S-1-5-32-544')
  $r += "Windows va a pedir permiso de administrador (el cartel 'Desea permitir que esta aplicacion haga cambios'). " + $(if ($esAdminPosible) { "Esta cuenta puede darlo tocando 'Si'." } else { "Esta cuenta NO es administradora: va a hacer falta que alguien con la contrasena de administrador la escriba." })
  $r
}

function Situacion {
  if ($e.clasico -and $e.usaNuevo) { return "USA EL NUEVO" }
  if ($e.clasico) { return "CLASICO" }
  if ($e.office -or $hayOfficeViejo) { return "OFFICE SIN OUTLOOK" }
  if ($e.nuevo) { return "SOLO EL NUEVO" }
  return "NINGUNO"
}
$sit = Situacion

if ($Revisar) {
  switch ($sit) {
    "CLASICO"            { Write-Output ("CLASICO: el Outlook clasico esta instalado ({0}). {1}" -f $e.clasico, $(if ($e.perfil) { "Ya tiene cuenta configurada." } else { "Falta agregar la cuenta: agregar-cuenta.ps1" })) }
    "USA EL NUEVO"       { Write-Output "USA EL NUEVO: el clasico esta instalado pero el interruptor 'Nuevo Outlook' esta prendido, asi que abre el nuevo. Solucion: instalar-outlook.ps1 -VolverAlClasico" }
    "OFFICE SIN OUTLOOK" { Write-Output "OFFICE SIN OUTLOOK: hay Office pero sin Outlook clasico. Solucion: instalar-outlook.ps1 (deja Office actualizado con Outlook; Word y Excel quedan)." }
    "SOLO EL NUEVO"      { Write-Output "SOLO EL NUEVO: solo esta el Outlook nuevo, que la skill no puede manejar. Solucion: instalar-outlook.ps1 (instala el clasico)." }
    "NINGUNO"            { Write-Output "NINGUNO: no hay Outlook. Solucion: instalar-outlook.ps1 (instala solo el Outlook clasico)." }
  }
  if ($sit -ne "CLASICO" -and $sit -ne "USA EL NUEVO") {
    foreach ($x in Riesgos) { Write-Output ("RIESGO: " + $x) }
    Write-Output "Para instalar: contarle TODOS los riesgos a la persona, pedirle permiso, y recien con su si: instalar-outlook.ps1 -Confirmado"
  }
  exit 0
}

if ($VolverAlClasico) {
  if (-not $e.clasico) { Write-Output "NO: no hay Outlook clasico instalado. Primero hay que instalarlo (instalar-outlook.ps1)."; exit 1 }
  $k = 'HKCU:\Software\Microsoft\Office\16.0\Outlook\Preferences'
  if (-not (Test-Path $k)) { New-Item -Path $k | Out-Null }   # sin -Force: no borrar valores existentes
  Set-ItemProperty -Path $k -Name UseNewOutlook -Value 0 -Type DWord
  Write-Output "LISTO: el interruptor 'Nuevo Outlook' quedo apagado. Si el Outlook nuevo esta abierto, cerralo; la proxima vez abre el clasico."
  exit 0
}

if ($sit -eq "CLASICO" -or $sit -eq "USA EL NUEVO") { Write-Output ("YA ESTA: el Outlook clasico ya esta instalado ({0}). No hace falta instalar nada." -f $e.clasico); exit 0 }
if (-not $Confirmado -and -not $SoloPreparar) {
  Write-Output "NO INSTALO: falta el permiso de la persona. Primero instalar-outlook.ps1 -Revisar, contarle todos los riesgos, preguntarle, y solo con su si: instalar-outlook.ps1 -Confirmado"
  exit 2
}

# 1. Bajar el instalador oficial (con barra) y comprobar que es de Microsoft
$dir = "C:\Users\Public\correos-tup\instalador"
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
Get-ChildItem $dir -Directory -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue   # nada de paquetes viejos al lado
$setup = Join-Path $dir "setup.exe"
$url = "https://officecdn.microsoft.com/pr/wsus/setup.exe"
Progreso-Iniciar "Instalando Outlook"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$wc = New-Object Net.WebClient
try {
  $tarea = $wc.DownloadFileTaskAsync($url, $setup)
  while (-not $tarea.IsCompleted) {
    $van = 0; if (Test-Path $setup) { $van = (Get-Item $setup).Length }
    Progreso-Avanzar ([math]::Min(99, [int](100 * $van / 7000000))) 100 "Bajando el instalador de Microsoft"
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

# 2. Configuracion (la probada). Sin Office previo: solo Outlook. Con Office: completo.
$bits = if ([Environment]::Is64BitOperatingSystem) { "64" } else { "32" }
$fuera = @("OutlookForWindows", "Groove", "Lync")
$completo = [bool]($e.office -or $hayOfficeViejo)
if (-not $completo) { $fuera += "Access","Excel","OneDrive","OneNote","PowerPoint","Publisher","Teams","Word","Bing" }
$logs = Join-Path $dir "logs"
$xml = @"
<Configuration>
  <Add OfficeClientEdition="$bits" Channel="Current">
    <Product ID="O365ProPlusRetail">
      <Language ID="es-es" />
$(($fuera | ForEach-Object { "      <ExcludeApp ID=""$_"" />" }) -join "`r`n")
    </Product>
  </Add>
$(if ($hayOfficeViejo) { "  <RemoveMSI />`r`n" })  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
  <Property Name="SharedComputerLicensing" Value="0" />
  <Display Level="Full" AcceptEULA="TRUE" />
  <Logging Level="Standard" Path="$logs" />
</Configuration>
"@
$cfg = Join-Path $dir "configuracion.xml"
[IO.File]::WriteAllText($cfg, $xml)
$que = if ($hayOfficeViejo) { "reemplaza el Office viejo por el actual (Outlook clasico, Word, Excel y PowerPoint)" } elseif ($completo) { "suma Outlook clasico al Office que ya hay" } else { "instala solo el Outlook clasico" }

if ($SoloPreparar) {
  Write-Output ("PREPARADO: instalador de Microsoft verificado ({0}). Va a: {1}. Configuracion en {2}. No se instalo nada." -f $firma.SignerCertificate.Subject.Split(',')[0], $que, $cfg)
  exit 0
}

# 3. Instalar: Windows pide permiso ("Si") y aparece la ventana de Microsoft con su barra
try {
  $p = Start-Process -FilePath $setup -ArgumentList "/configure `"$cfg`"" -WorkingDirectory $dir -Verb RunAs -PassThru
} catch {
  Write-Output "CANCELADO: no se acepto el permiso de Windows. Cuando quieras lo volvemos a intentar y en el cartel tocas 'Si'."
  exit 1
}
$p.WaitForExit()   # con /configure, setup.exe espera a que la instalacion termine
# Por las dudas, darle unos minutos a que aparezca OUTLOOK.EXE
for ($i = 0; $i -lt 20 -and -not (Estado-Outlook).clasico; $i++) { Start-Sleep -Seconds 15 }
$e = Estado-Outlook
if ($e.clasico) {
  Write-Output ("INSTALADO: el Outlook clasico quedo en {0} ({1}). Siguiente paso: agregar-cuenta.ps1 (la primera vez Outlook pide iniciar sesion, y eso activa la licencia)." -f $e.clasico, $que)
  exit 0
}
$cod = try { $p.ExitCode } catch { "?" }
Write-Output ("NO SE INSTALO (codigo {0}). Detalle en {1}. Si la cuenta no incluye Office de escritorio (por ejemplo las A1), Microsoft no deja usarlo con esa cuenta." -f $cod, $logs)
exit 1
