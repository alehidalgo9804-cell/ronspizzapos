param(
  [string]$ApiBaseUrl = "https://ronspizza.net/ronspizzapos/backend/public"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host "[1/3] flutter clean"
flutter clean

Write-Host "[2/3] flutter pub get"
flutter pub get

Write-Host "[3/3] flutter build apk --release"
flutter build apk --release --dart-define="API_BASE_URL=$ApiBaseUrl"

$apkPath = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkPath)) {
  throw "No se encontró APK en: $apkPath"
}

Write-Host "APK generado en: $apkPath"
