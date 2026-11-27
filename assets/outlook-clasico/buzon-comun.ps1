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
