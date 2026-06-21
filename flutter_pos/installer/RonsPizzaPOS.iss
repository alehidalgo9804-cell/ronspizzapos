#define AppName "Rons Pizza POS"
#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#define AppPublisher "Rons Pizza"
#define AppExeName "rons_pizza_pos.exe"

#ifndef BuildDir
  #error BuildDir no definido. Compila Flutter Windows y pasa /DBuildDir="ruta" al compilar este script.
#endif

#define BuildOutput BuildDir

[Setup]
AppId={{5A9A09F0-7E5A-4A38-B0AF-0EC0C8E34B4A}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir={#BuildOutput}\installer
OutputBaseFilename=RonsPizzaPOS-Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en escritorio"; GroupDescription: "Accesos directos:"; Flags: unchecked

[Files]
Source: "{#BuildOutput}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Si quieres incluir VC++ Redistributable, compila con /DVCREDIST="C:\ruta\VC_redist.x64.exe"
#ifdef VCREDIST
Source: "{#VCREDIST}"; DestDir: "{tmp}"; DestName: "VC_redist.x64.exe"; Flags: deleteafterinstall
#endif

[Run]
#ifdef VCREDIST
Filename: "{tmp}\VC_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Instalando Microsoft Visual C++ Redistributable..."; Flags: waituntilterminated
#endif
Filename: "{app}\{#AppExeName}"; Description: "Iniciar {#AppName}"; Flags: nowait postinstall skipifsilent

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

