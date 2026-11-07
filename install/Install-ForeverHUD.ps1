<#
.SYNOPSIS
  Instala ForeverHUD en World of Warcraft: Forever.
.DESCRIPTION
  Detecta la carpeta del cliente, guarda una copia del addon anterior y copia la
  version nueva verificando el numero de ficheros.
.PARAMETER WowPath
  Ruta raiz del cliente (la que contiene _forever_). Si se omite, se autodetecta.
.PARAMETER Source
  Carpeta ForeverHUD a instalar. Por defecto, la del repositorio.
.PARAMETER DryRun
  Muestra lo que haria sin tocar el disco.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File install\Install-ForeverHUD.ps1
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File install\Install-ForeverHUD.ps1 -WowPath 'D:\World of Warcraft' -Force
#>
[CmdletBinding()]
param(
  [string]$WowPath,
  [string]$Source,
  [switch]$Force,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$addonName = 'ForeverHUD'

function Write-Step([string]$text) { Write-Host ('  ' + $text) }

if (-not $Source) { $Source = Join-Path $PSScriptRoot '..\ForeverHUD' }
$Source = (Resolve-Path $Source).Path
if (-not (Test-Path (Join-Path $Source 'ForeverHUD.toc'))) {
  throw "No encuentro ForeverHUD.toc en $Source"
}

function Test-ClientRoot([string]$root) {
  return (Test-Path (Join-Path $root '_forever_\Interface\AddOns'))
}

function Find-ClientRoot {
  $roots = @(
    'C:\Program Files (x86)\World of Warcraft',
    'C:\Program Files\World of Warcraft',
    'C:\World of Warcraft',
    'C:\Games\World of Warcraft',
    'D:\World of Warcraft',
    'D:\Games\World of Warcraft',
    'E:\World of Warcraft'
  )
  foreach ($root in $roots) {
    if (Test-ClientRoot $root) { return $root }
  }
  $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' }
  foreach ($drive in $drives) {
    $candidates = Get-ChildItem -Path $drive.Root -Directory -Depth 2 -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -match 'World of Warcraft|Warcraft' }
    foreach ($candidate in $candidates) {
      if (Test-ClientRoot $candidate.FullName) { return $candidate.FullName }
    }
  }
  return $null
}

Write-Host ''
Write-Host 'ForeverHUD installer' -ForegroundColor Yellow
Write-Host ''

if (-not $WowPath) {
  Write-Step 'Buscando World of Warcraft: Forever...'
  $WowPath = Find-ClientRoot
} elseif (Test-ClientRoot $WowPath) {
  $WowPath = (Resolve-Path $WowPath).Path
}

if (-not $WowPath) {
  Write-Host 'No se encontro el cliente. Indica la carpeta raiz con -WowPath.' -ForegroundColor Red
  Write-Host 'Ejemplo: -WowPath "D:\World of Warcraft"' -ForegroundColor DarkGray
  exit 1
}

$addons = Join-Path $WowPath '_forever_\Interface\AddOns'
$dest = Join-Path $addons $addonName
Write-Step "Cliente: $WowPath"
Write-Step "Destino: $dest"

if (-not (Test-Path $addons)) {
  throw "La carpeta AddOns no existe: $addons"
}

if ((Test-Path $dest) -and (-not $Force)) {
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $backup = $dest + '.bak-' + $stamp
  Write-Step "Version anterior encontrada. Copia de seguridad: $backup"
  if (-not $DryRun) { Move-Item -LiteralPath $dest -Destination $backup }
}

if ($DryRun) {
  Write-Step 'DryRun: no se ha copiado nada.'
  exit 0
}

Copy-Item -LiteralPath $Source -Destination $dest -Recurse -Force

$expected = (Get-ChildItem -LiteralPath $Source -Recurse -File).Count
$actual = (Get-ChildItem -LiteralPath $dest -Recurse -File).Count
if ($expected -ne $actual) {
  throw "Verificacion fallida: $actual de $expected ficheros copiados"
}

$tocLine = Select-String -Path (Join-Path $dest 'ForeverHUD.toc') -Pattern '^## Version: (.+)$'
$version = $tocLine.Matches[0].Groups[1].Value
Write-Host ''
Write-Host "Instalado ForeverHUD $version ($actual ficheros)" -ForegroundColor Green
Write-Host 'Abre el juego, comprueba el addon en la lista y escribe /fh.' -ForegroundColor Gray
Write-Host ''
