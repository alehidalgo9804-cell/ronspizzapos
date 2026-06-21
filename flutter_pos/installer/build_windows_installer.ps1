param(
  [string]$ApiBaseUrl = "https://ronspizza.net/ronspizzapos/backend/public",
  [string]$InnoPath = "",
  [string]$VcRedistPath = "C:\Installers\VC_redist",
  [string]$AppVersion = "1.0.0"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host "[1/4] flutter clean"
flutter clean

Write-Host "[2/4] flutter pub get"
flutter pub get

Write-Host "[3/4] flutter build windows --release"
flutter build windows --release --dart-define="API_BASE_URL=$ApiBaseUrl" --dart-define="APP_VERSION=$AppVersion"

$buildDir = Join-Path $projectRoot "build\windows\x64\runner\Release"
if (-not (Test-Path (Join-Path $buildDir "rons_pizza_pos.exe"))) {
  throw "No se encontró rons_pizza_pos.exe en $buildDir"
}

if ([string]::IsNullOrWhiteSpace($InnoPath) -or -not (Test-Path $InnoPath)) {
  $innoCandidates = @(
    "C:\Program Files\Inno Setup 7\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 7\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
  )
  $foundInno = $innoCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ([string]::IsNullOrWhiteSpace($InnoPath) -and $foundInno) {
    $InnoPath = $foundInno
  }
}

if ([string]::IsNullOrWhiteSpace($InnoPath) -or -not (Test-Path $InnoPath)) {
  throw "No se encontró ISCC.exe. Rutas probadas: Inno Setup 7/6. Puedes pasar -InnoPath explícito."
}

$issPath = Join-Path $PSScriptRoot "RonsPizzaPOS.iss"
if (-not (Test-Path $issPath)) {
  throw "No se encontró el script Inno: $issPath"
}

$cmdArgs = @(
  "/DBuildDir=$buildDir",
  "/DAppVersion=$AppVersion"
)

$vcCandidates = @(
  $VcRedistPath,
  "$VcRedistPath.exe",
  "C:\Installers\VC_redist.exe",
  "C:\Installers\VC_redist.x64.exe"
)
$vcFound = $vcCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($vcFound) {
  Write-Host "Incluyendo VC++ Redistributable: $vcFound"
  $cmdArgs += "/DVCREDIST=$vcFound"
} else {
  Write-Host "VC++ Redistributable no encontrado (se compila setup sin incluirlo)."
}

$cmdArgs += $issPath

Write-Host "[4/4] Compilando instalador Inno Setup"
& $InnoPath @cmdArgs

Write-Host "Listo. Setup generado en: $buildDir\installer"
