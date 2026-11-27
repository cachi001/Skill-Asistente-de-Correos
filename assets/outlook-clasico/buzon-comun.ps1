# buzon-comun.ps1 — Funciones compartidas por los scripts (se carga con: . "$PSScriptRoot\buzon-comun.ps1").
# Un "buzon" es cualquier carpeta raiz del Outlook: la cuenta propia, otra cuenta agregada
# o un buzon compartido (Certificaciones, Protocolo...). Se elige con -Buzon <parte del nombre o direccion>.

function Conectar-Outlook {
  try {
    $script:ol = New-Object -ComObject Outlook.Application
    $script:ns = $script:ol.GetNamespace("MAPI")
  } catch {
    Write-Output "ERROR: no se pudo abrir Outlook. Abrilo una vez a mano y volve a intentar."
    exit 1
  }
}

# Cuenta de envio asociada a un buzon (solo existe para cuentas agregadas, no para compartidos)
function Cuenta-DeBuzon($store) {
  foreach ($a in $script:ns.Accounts) {
    try { if ($a.DeliveryStore.StoreID -eq $store.StoreID) { return $a } } catch {}
  }
  return $null
}

function Direccion-DeBuzon($store) {
  $a = Cuenta-DeBuzon $store
  if ($a) { return $a.SmtpAddress }
  try {
    $pa = $store.PropertyAccessor
    $eid = $pa.GetProperty("http://schemas.microsoft.com/mapi/proptag/0x661B0102")  # duenio del buzon
    $ae = $script:ns.GetAddressEntryFromID($pa.BinaryToString($eid))
    return $ae.GetExchangeUser().PrimarySmtpAddress
  } catch { return "" }
}

function Tipo-DeBuzon($store) {
  if ($store.StoreID -eq $script:ns.DefaultStore.StoreID) { return "tu cuenta" }
  if (Cuenta-DeBuzon $store) { return "otra cuenta" }
  if ($store.ExchangeStoreType -eq 1) { return "compartido" }
  return "otro"
}

# Solo buzones con bandeja de entrada (deja afuera archivos de datos y carpetas publicas)
function Lista-Buzones {
  $r = @()
  foreach ($s in $script:ns.Stores) {
    try { [void]$s.GetDefaultFolder(6); $r += $s } catch {}
  }
  return $r
}

# Sin -Buzon: la cuenta principal. Con -Buzon: el unico que coincide por nombre o direccion.
function Elegir-Buzon([string]$nombre) {
  if (-not $nombre) { return $script:ns.DefaultStore }
  $hits = @()
  foreach ($s in (Lista-Buzones)) {
    if ($s.DisplayName -like "*$nombre*" -or (Direccion-DeBuzon $s) -like "*$nombre*") { $hits += $s }
  }
  if ($hits.Count -eq 1) { return $hits[0] }
  if ($hits.Count -eq 0) { Write-Output "ERROR: no hay ningun buzon que coincida con '$nombre'." }
  else { Write-Output "ERROR: '$nombre' coincide con varios buzones. Precisa mas:" }
  foreach ($s in (Lista-Buzones)) { Write-Output (" - {0} <{1}>" -f $s.DisplayName, (Direccion-DeBuzon $s)) }
  exit 1
}

# Hace que el borrador salga desde el buzon elegido (cuenta agregada o compartido)
function Fijar-Remitente($mail, $store) {
  if ($store.StoreID -eq $script:ns.DefaultStore.StoreID) { return }
  $a = Cuenta-DeBuzon $store
  if ($a) { $mail.SendUsingAccount = $a; return }
  $dir = Direccion-DeBuzon $store
  if ($dir) { $mail.SentOnBehalfOfName = $dir }
}

# Desde que direccion va a salir un borrador
function Remitente-DeBorrador($mail) {
  if ($mail.SentOnBehalfOfName) { return $mail.SentOnBehalfOfName }
  try { if ($mail.SendUsingAccount) { return $mail.SendUsingAccount.SmtpAddress } } catch {}
  return (Direccion-DeBuzon $script:ns.DefaultStore)
}

# ---------------------------------------------------------------------------
# Carpeta de datos de la skill (fuera de la skill): ~/.correos-tup o $env:CORREOS_TUP_HOME
# ---------------------------------------------------------------------------
function Carpeta-Datos([string]$sub = "") {
  $base = $env:CORREOS_TUP_HOME
  if (-not $base) { $base = Join-Path $env:USERPROFILE ".correos-tup" }
  $p = if ($sub) { Join-Path $base $sub } else { $base }
  if (-not (Test-Path $p)) { [void](New-Item -ItemType Directory -Force $p) }
  return $p
}

function Leer-Json([string]$ruta) {
  if (-not (Test-Path $ruta)) { return $null }
  try { return (Get-Content $ruta -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
}

function Guardar-Json($obj, [string]$ruta) {
  $obj | ConvertTo-Json -Depth 6 | Out-File -Encoding utf8 $ruta
}

# Nombre de archivo seguro para un buzon (por su direccion)
function Clave-DeBuzon($store) {
  $d = Direccion-DeBuzon $store
  if (-not $d) { $d = $store.DisplayName }
  return ($d.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
}

# ---------------------------------------------------------------------------
# Modo solo lectura por buzon (lo decide la persona con modo-buzon.ps1)
# Si un buzon esta en solo lectura, ningun script puede crear borradores ni enviar desde el.
# ---------------------------------------------------------------------------
function Es-SoloLectura($store) {
  $cfg = Leer-Json (Join-Path (Carpeta-Datos) "buzones.json")
  if (-not $cfg) { return $false }
  $k = Clave-DeBuzon $store
  $e = $cfg.PSObject.Properties[$k]
  return ($e -and $e.Value.soloLectura -eq $true)
}

function Exigir-Escritura($store) {
  if (Es-SoloLectura $store) {
    Write-Output ("BLOQUEADO: el buzon {0} <{1}> esta en modo SOLO LECTURA. No se crea ni se envia nada." -f $store.DisplayName, (Direccion-DeBuzon $store))
    Write-Output "Solo la persona puede cambiarlo (modo-buzon.ps1 -Buzon ... -SoloLectura no)."
    exit 2
  }
}

# ---------------------------------------------------------------------------
# Candado de envio: cada borrador armado por la skill recibe un codigo de un solo uso.
# enviar-borrador.ps1 solo envia con ese codigo, y lo borra al enviar (un OK = un correo).
# ---------------------------------------------------------------------------
function Ruta-Codigos { return (Join-Path (Carpeta-Datos) "envios-pendientes.json") }

function Nuevo-CodigoEnvio($mail, [string]$desde) {
  $ruta = Ruta-Codigos
  $tabla = @{}
  $prev = Leer-Json $ruta
  if ($prev) { foreach ($p in $prev.PSObject.Properties) { $tabla[$p.Name] = $p.Value } }
  do { $cod = "{0:D4}" -f (Get-Random -Minimum 1000 -Maximum 9999) } while ($tabla.ContainsKey($cod))
  $tabla[$cod] = [ordered]@{ entryId = $mail.EntryID; storeId = $mail.Parent.StoreID; para = $mail.To; asunto = $mail.Subject; desde = $desde; creado = (Get-Date).ToString("s") }
  Guardar-Json $tabla $ruta
  return $cod
}

function Tomar-CodigoEnvio([string]$cod) {
  $prev = Leer-Json (Ruta-Codigos)
  if (-not $prev) { return $null }
  $e = $prev.PSObject.Properties[$cod]
  if ($e) { return $e.Value } else { return $null }
}

function Borrar-CodigoEnvio([string]$cod) {
  $ruta = Ruta-Codigos
  $prev = Leer-Json $ruta
  if (-not $prev) { return }
  $tabla = @{}
  foreach ($p in $prev.PSObject.Properties) { if ($p.Name -ne $cod) { $tabla[$p.Name] = $p.Value } }
  Guardar-Json $tabla $ruta
}

# ---------------------------------------------------------------------------
# Que Outlook hay en la PC (no cambia nada):
#   clasico  = ruta del OUTLOOK.EXE clasico, o vacio
#   nuevo    = esta instalado el "Outlook nuevo" (olk, no sirve: no tiene COM)
#   usaNuevo = el interruptor "Nuevo Outlook" esta prendido (el clasico abre el nuevo)
#   office   = productos de Office instalados (para no tocarlos al instalar)
#   perfil   = el clasico ya tiene al menos una cuenta configurada
# ---------------------------------------------------------------------------
function Estado-Outlook {
  $exe = $null
  try { $exe = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE' -ErrorAction Stop).'(default)' } catch {}
  if (-not ($exe -and (Test-Path $exe))) {
    $exe = @("$env:ProgramFiles\Microsoft Office\root\Office16\OUTLOOK.EXE",
             "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\OUTLOOK.EXE",
             "$env:ProgramFiles\Microsoft Office\Office16\OUTLOOK.EXE",
             "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OUTLOOK.EXE") |
           Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
  }
  $nuevo = $false
  try { $nuevo = [bool](Get-AppxPackage -Name Microsoft.OutlookForWindows -ErrorAction Stop) } catch {}
  $usaNuevo = $false
  try { $usaNuevo = ((Get-ItemProperty 'HKCU:\Software\Microsoft\Office\16.0\Outlook\Preferences' -ErrorAction Stop).UseNewOutlook -eq 1) } catch {}
  $office = ""
  try { $office = [string](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration' -ErrorAction Stop).ProductReleaseIds } catch {}
  $perfil = [bool](Get-ChildItem 'HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles' -ErrorAction SilentlyContinue)
  @{ clasico = [string]$exe; nuevo = $nuevo; usaNuevo = $usaNuevo; office = $office; perfil = $perfil }
}

# ---------------------------------------------------------------------------
# Ventanita de progreso para la persona (para lo que tarda). Solo aparece si la tarea
# dura mas de ~2 segundos. Con total 0 la barra se mueve sin porcentaje.
# Se desactiva con $env:CORREOS_TUP_SIN_VENTANA = "1".
# ---------------------------------------------------------------------------
function Progreso-Iniciar([string]$titulo) {
  $script:prog = @{ titulo = $titulo; ini = Get-Date; ult = [datetime]::MinValue; f = $null }
}

function Progreso-Avanzar([int]$n, [int]$total, [string]$texto) {
  if (-not $script:prog -or $env:CORREOS_TUP_SIN_VENTANA -eq "1") { return }
  $ahora = Get-Date
  if (-not $script:prog.f) {
    if (($ahora - $script:prog.ini).TotalSeconds -lt 2) { return }
    try {
      Add-Type -AssemblyName System.Windows.Forms, System.Drawing
      $f = New-Object Windows.Forms.Form
      $f.Text = "Asistente de correos"; $f.Width = 480; $f.Height = 175
      $f.FormBorderStyle = "FixedDialog"; $f.ControlBox = $false; $f.TopMost = $true
      $f.AutoScaleMode = "None"; $f.StartPosition = "Manual"
      $wa = [Windows.Forms.Screen]::PrimaryScreen.WorkingArea   # centrada a mano (CenterScreen falla con pantallas agrandadas)
      $f.Left = $wa.Left + [int](($wa.Width - $f.Width) / 2); $f.Top = $wa.Top + [int](($wa.Height - $f.Height) / 2)
      $t = New-Object Windows.Forms.Label; $t.Text = $script:prog.titulo; $t.Left = 16; $t.Top = 14; $t.Width = 440
      $t.Font = New-Object Drawing.Font("Segoe UI", 11, [Drawing.FontStyle]::Bold)
      $b = New-Object Windows.Forms.ProgressBar; $b.Left = 16; $b.Top = 50; $b.Width = 430; $b.Height = 22
      $d = New-Object Windows.Forms.Label; $d.Left = 16; $d.Top = 84; $d.Width = 440; $d.Height = 40
      $d.Font = New-Object Drawing.Font("Segoe UI", 9.5)
      $f.Controls.AddRange(@($t, $b, $d))
      # Los scripts corren ocultos y Windows oculta tambien la PRIMERA ventana que se muestra;
      # por eso se muestra, se esconde y se vuelve a mostrar.
      $f.Show(); $f.Hide(); $f.Show(); $f.Activate()
      $script:prog.f = $f; $script:prog.b = $b; $script:prog.d = $d
    } catch { $script:prog = $null; return }
  }
  if (($ahora - $script:prog.ult).TotalMilliseconds -lt 250) { [Windows.Forms.Application]::DoEvents(); return }
  $script:prog.ult = $ahora
  if ($total -gt 0) {
    $script:prog.b.Style = "Blocks"
    $pct = [math]::Min(100, [int](100 * $n / $total)); $script:prog.b.Value = $pct
    $seg = ($ahora - $script:prog.ini).TotalSeconds
    $resta = if ($n -gt 0) { [int]($seg / $n * ($total - $n)) } else { 0 }
    $falta = if ($resta -ge 90) { "falta(n) unos {0} minutos" -f [math]::Ceiling($resta / 60) } elseif ($resta -gt 5) { "faltan unos {0} segundos" -f $resta } else { "ya casi" }
    $script:prog.d.Text = "{0}`n{1} de {2} ({3}%) - {4}" -f $texto, $n, $total, $pct, $falta
  } else {
    $script:prog.b.Style = "Marquee"
    $script:prog.d.Text = $texto
  }
  [Windows.Forms.Application]::DoEvents()
}

function Progreso-Cerrar {
  if ($script:prog -and $script:prog.f) { try { $script:prog.f.Close(); $script:prog.f.Dispose() } catch {} }
  $script:prog = $null
}

# ---------------------------------------------------------------------------
# Texto de un correo sin el historial citado (ahorra lectura)
# ---------------------------------------------------------------------------
function Cortar-Historial([string]$cuerpo) {
  if (-not $cuerpo) { return @{ texto = ""; citado = "" } }
  $marcadores = @('(?m)^_{5,}\s*$', '(?m)^De:\s.+', '(?m)^From:\s.+', '(?m)^-{3,}\s*Mensaje original', '(?m)^El\s.+escribi[o\u00f3]:\s*$', '(?m)^On\s.+wrote:\s*$')
  $corte = $cuerpo.Length
  foreach ($mk in $marcadores) {
    $m = [regex]::Match($cuerpo, $mk)
    if ($m.Success -and $m.Index -lt $corte -and $m.Index -gt 20) { $corte = $m.Index }
  }
  return @{ texto = $cuerpo.Substring(0, $corte).Trim(); citado = $cuerpo.Substring($corte).Trim() }
}

function Una-Linea([string]$t, [int]$largo) {
  $t = ($t -replace '\s+', ' ').Trim()
  if ($largo -gt 0 -and $t.Length -gt $largo) { $t = $t.Substring(0, $largo) + "..." }
  return $t
}

function Correo-DeRemitente($m) {
  $mail = $m.SenderEmailAddress
  try { if ($m.SenderEmailType -eq "EX") { $mail = $m.Sender.GetExchangeUser().PrimarySmtpAddress } } catch {}
  return $mail
}

# Si el correo ya fue respondido o reenviado desde Outlook (por cualquiera que use el buzon)
function Estado-Respuesta($m) {
  try {
    $v = $m.PropertyAccessor.GetProperty("http://schemas.microsoft.com/mapi/proptag/0x10810003")
    if ($v -eq 102 -or $v -eq 103) { return "respondido" }
    if ($v -eq 104) { return "reenviado" }
  } catch {}
  return ""
}
