
#define MyAppName "SAKHO UZB Keyboard"
#define MyAppVersion "2.2"
#define MyAppPublisher "Saxobiddin Xudayberdiyev"
#define MyExeName "SAKHO_UZB_LongPress_2.2.exe"
#define MyProductCode "{88CFB0E1-7F06-4147-A208-3BC7FEE2BC59}"

[Setup]
AppId={{364302F5-858B-4052-BEAE-C58171A07543}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
OutputDir=output
OutputBaseFilename=SAKHO_UZB_Keyboard_2_2_Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern dynamic
UninstallDisplayName=SAKHO UZB Keyboard 2.2
LicenseFile={#SourcePath}LICENSE.txt

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Files]
; MSKLC 64-bit keyboard installer
Source: "{#SourcePath}UZB_amd64.msi"; DestName: "UZB_amd64.msi"; Flags: dontcopy

; Keyboard DLL files
Source: "{#SourcePath}amd64\UZB.dll"; DestName: "amd64_UZB.dll"; Flags: dontcopy
Source: "{#SourcePath}wow64\UZB.dll"; DestName: "wow64_UZB.dll"; Flags: dontcopy

; LongPress application
Source: "{#SourcePath}SAKHO_UZB_LongPress_2.2.exe"; DestDir: "{app}"; Flags: ignoreversion


[InstallDelete]
Type: files; Name: "{app}\SAKHO_UZB_LongPress.exe"

[Registry]
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "SAKHO_UZB_LongPress"; ValueData: """{app}\{#MyExeName}"""; Flags: uninsdeletevalue

[Run]
Filename: "{app}\{#MyExeName}"; Description: "Start SAKHO UZB LongPress"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\taskkill.exe"; Parameters: "/F /IM {#MyExeName}"; Flags: runhidden; RunOnceId: "StopLongPress22"

[Code]
function MsiQueryProductState(szProduct: String): Integer;
  external 'MsiQueryProductStateW@msi.dll stdcall';

const
  STATE_INSTALLED = 5;
var
  KeyboardRestart: Boolean;
  KeyboardInstalled: Boolean;
  KeyboardUninstallRestart: Boolean;
  SetupCompleted: Boolean;

function StageKeyboardFiles(): Boolean;
var
  Base: String;
begin
  Result := False;

  ExtractTemporaryFile('UZB_amd64.msi');
  ExtractTemporaryFile('amd64_UZB.dll');
  ExtractTemporaryFile('wow64_UZB.dll');

  Base := ExpandConstant('{tmp}\');

  if not ForceDirectories(Base + 'amd64') then
    Exit;

  if not ForceDirectories(Base + 'wow64') then
    Exit;

  if not CopyFile(
    Base + 'amd64_UZB.dll',
    Base + 'amd64\UZB.dll',
    False
  ) then
    Exit;

  if not CopyFile(
    Base + 'wow64_UZB.dll',
    Base + 'wow64\UZB.dll',
    False
  ) then
    Exit;

  Result := True;
end;

  
function RunMSI(const Parameters: String; var ExitCode: Integer): Boolean;
begin
  Result := Exec(
    ExpandConstant('{sys}\msiexec.exe'),
    Parameters, '', SW_HIDE, ewWaitUntilTerminated, ExitCode
  );
end;

procedure StopLongPress();
var
  ExitCode: Integer;
begin
  Exec(
    ExpandConstant('{sys}\taskkill.exe'),
    '/F /IM SAKHO_UZB_LongPress.exe',
    '', SW_HIDE, ewWaitUntilTerminated, ExitCode
  );

  Exec(
    ExpandConstant('{sys}\taskkill.exe'),
    '/F /IM SAKHO_UZB_LongPress_2.exe',
    '', SW_HIDE, ewWaitUntilTerminated, ExitCode
  );

  Exec(
    ExpandConstant('{sys}\taskkill.exe'),
    '/F /IM {#MyExeName}',
    '', SW_HIDE, ewWaitUntilTerminated, ExitCode
  );
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ExitCode: Integer;
  MSIPath, LogPath: String;
begin
    Result := '';
    StopLongPress();

    { MSI avvaldan o'rnatilgan bo'lsa, qayta o'rnatmaymiz }
    if MsiQueryProductState('{#MyProductCode}') = STATE_INSTALLED then
      Exit;

  if not StageKeyboardFiles() then
begin
  Result := 'MSI va DLL fayllarini tayyorlashda xatolik yuz berdi.';
  Exit;
end;
  MSIPath := ExpandConstant('{tmp}\UZB_amd64.msi');
  LogPath := ExpandConstant('{commonappdata}\SAKHO_UZB_Install.log');

  if not FileExists(MSIPath) then
  begin
    Result := 'UZB_amd64.msi not found.';
    Exit;
  end;

  if not RunMSI(
    '/i "' + MSIPath + '" /qn /norestart /L*v "' + LogPath + '"',
    ExitCode
  ) then
  begin
    Result := 'Unable to start Windows Installer.';
    Exit;
  end;

  if (ExitCode = 0) or (ExitCode = 3010) then
  begin
    KeyboardInstalled := True;
    if ExitCode = 3010 then
    begin
      KeyboardRestart := True;
    end;
  end
  else
  begin
    Result := 'Keyboard installation failed. MSI code: ' +
      IntToStr(ExitCode) + #13#10 + 'Log: ' + LogPath;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    SetupCompleted := True;
end;

procedure DeinitializeSetup();
var
  ExitCode: Integer;
  LogPath: String;
begin
  if KeyboardInstalled and (not SetupCompleted) then
  begin
    LogPath := ExpandConstant('{commonappdata}\SAKHO_UZB_Rollback.log');
    RunMSI(
      '/x "{#MyProductCode}" /qn /norestart /L*v "' + LogPath + '"',
      ExitCode
    );
  end;
end;

function NeedRestart(): Boolean;
begin
  Result := KeyboardInstalled or KeyboardRestart;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ExitCode: Integer;
  LogPath: String;
begin
  if (CurUninstallStep = usUninstall) and
   (MsiQueryProductState('{#MyProductCode}') = STATE_INSTALLED) then
  begin
    LogPath := ExpandConstant('{commonappdata}\SAKHO_UZB_Uninstall.log');

    if not RunMSI(
      '/x "{#MyProductCode}" /qn /norestart /L*v "' + LogPath + '"',
      ExitCode
    ) then
    begin
      SuppressibleMsgBox(
        'Unable to start Windows Installer.',
        mbError, MB_OK, IDOK
      );
    end
    else if (ExitCode = 0) or (ExitCode = 3010) then
    begin
      KeyboardUninstallRestart := (ExitCode = 3010);
    end
    else if ExitCode = 1605 then
    begin
      KeyboardUninstallRestart := False;
    end
    else
    begin
      SuppressibleMsgBox(
        'Keyboard removal failed. MSI code: ' +
        IntToStr(ExitCode) + #13#10 + 'Log: ' + LogPath,
        mbError, MB_OK, IDOK
      );
    end;
  end;
end;

function UninstallNeedRestart(): Boolean;
begin
  Result := KeyboardUninstallRestart;
end;
