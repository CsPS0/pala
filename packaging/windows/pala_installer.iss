; Inno Setup Script for Pala (All-in-One: Desktop GUI + CLI / TUI)
#define MyAppName "Pala"
#define MyAppVersion "1.2.3"
#define MyAppPublisher "CsPS0"
#define MyAppURL "https://github.com/CsPS0/pala"
#define MyAppExeName "palapp.exe"
#define MyCliExeName "pala.exe"

[Setup]
AppId={{E681B45F-91CD-49D1-9B5B-9A4B7415D491}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=..\..\dist
OutputBaseFilename=Pala-Setup
SetupIconFile=..\..\app\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "hungarian"; MessagesFile: "compiler:Languages\Hungarian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "Teljes telepítés (Desktop GUI + CLI a PATH-ban)"
Name: "desktoponly"; Description: "Csak Pala Desktop (Grafikus felület)"
Name: "clionly"; Description: "Csak Pala CLI / TUI (Parancssor)"
Name: "custom"; Description: "Egyéni választás"; Flags: iscustom

[Components]
Name: "desktop"; Description: "Pala Desktop — Grafikus asztali alkalmazás"; Types: full desktoponly custom; Flags: checkablealone
Name: "cli"; Description: "Pala CLI & TUI — Parancssoros terminálos eszköz"; Types: full clionly custom; Flags: checkablealone

[Tasks]
Name: "desktopicon"; Description: "Asztali parancsikon létrehozása"; GroupDescription: "További parancsikonok:"; Components: desktop
Name: "addtopath"; Description: "Pala hozzáadása a PATH környezeti változóhoz (parancssori eléréshez)"; GroupDescription: "Rendszerintegráció:"; Components: cli

[Files]
; Desktop GUI files
Source: "..\..\app\build\windows\x64\runner\Release\*"; DestDir: "{app}\desktop"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: desktop
; Standalone CLI executable
Source: "..\..\pala.exe"; DestDir: "{app}\bin"; DestName: "pala.exe"; Flags: ignoreversion; Components: cli
; Shortcut helper
Source: "..\..\scripts\install_start_menu_shortcut.ps1"; DestDir: "{app}\scripts"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\Pala Desktop"; Filename: "{app}\desktop\{#MyAppExeName}"; Components: desktop
Name: "{autodesktop}\Pala Desktop"; Filename: "{app}\desktop\{#MyAppExeName}"; Tasks: desktopicon; Components: desktop
Name: "{autoprograms}\Pala CLI (Terminál)"; Filename: "{app}\bin\{#MyCliExeName}"; Components: cli

[Registry]
Root: HKCU; Subkey: "Environment"; ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}\bin"; Tasks: addtopath; Check: NeedsAddPath(ExpandConstant('{app}\bin'))

[Run]
Filename: "{app}\desktop\{#MyAppExeName}"; Description: "Pala Desktop indítása most"; Flags: nowait postinstall skipifsilent; Components: desktop

[Code]
function NeedsAddPath(Param: string): boolean;
var
  OrigPath: string;
begin
  if not RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', OrigPath)
  then begin
    Result := True;
    exit;
  end;
  Result := Pos(';' + Param + ';', ';' + OrigPath + ';') = 0;
end;
