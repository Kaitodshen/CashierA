; CashierA Windows installer (Inno Setup 6, https://jrsoftware.org/isinfo.php).
;
; 1. flutter build windows --release --dart-define-from-file=config/prod.json
; 2. iscc /DAppVersion=0.2.0 app\windows\installer\cashiera.iss
;    (run from the repository root; output: app\build\installer\)
;
; The terminal keeps its data in the user's AppData folder, so reinstalling or
; upgrading keeps the local database, the pairing and the printer settings.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#define AppName "CashierA"
#define BuildDir "..\..\build\windows\x64\runner\Release"

[Setup]
AppId={{0B62C5D7-B1C3-499C-8AE9-7BDDFDB6AA6A}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=CashierA
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir=..\..\build\installer
OutputBaseFilename=CashierA-Setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern
PrivilegesRequiredOverridesAllowed=dialog
CloseApplications=yes

[Languages]
Name: "indonesian"; MessagesFile: "compiler:Languages\Indonesian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\cashiera.exe"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\cashiera.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\cashiera.exe"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
