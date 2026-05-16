# Instaladores Ron's Pizza POS

## Archivos incluidos
- `RonsPizzaPOS.iss`: script de Inno Setup para generar `RonsPizzaPOS-Setup.exe`
- `build_windows_installer.ps1`: compila Windows release y luego crea instalador
- `build_apk_release.ps1`: compila APK release

## 1) Generar instalador Windows (.exe)
Desde PowerShell en `flutter_pos`:

```powershell
powershell -ExecutionPolicy Bypass -File .\installer\build_windows_installer.ps1
```

Con parámetros opcionales:

```powershell
powershell -ExecutionPolicy Bypass -File .\installer\build_windows_installer.ps1 `
  -ApiBaseUrl "https://ronspizza.net/ronspizzapos/backend/public" `
  -InnoPath "C:\Program Files\Inno Setup 7\ISCC.exe" `
  -VcRedistPath "C:\Installers\VC_redist"
```

Salida esperada:
- EXE app: `build\windows\x64\runner\Release\rons_pizza_pos.exe`
- Setup: `build\windows\x64\runner\Release\installer\RonsPizzaPOS-Setup.exe`

## 2) Generar APK Android
Desde PowerShell en `flutter_pos`:

```powershell
powershell -ExecutionPolicy Bypass -File .\installer\build_apk_release.ps1
```

Salida esperada:
- `build\app\outputs\flutter-apk\app-release.apk`

## Notas
- Ambos scripts ya inyectan `API_BASE_URL` con HostGator por default.
- El script de Windows autodetecta Inno Setup 7/6.
- `-VcRedistPath` acepta ruta con o sin `.exe`.
- Si no existe el VC++ Redistributable, el setup se crea igual pero sin incluirlo.
