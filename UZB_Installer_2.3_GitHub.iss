; SAKHO UZB Keyboard 2.3 (x64) installer
; Upgrade from 2.2: preserves AppId and keyboard MSI ProductCode.
; Validate on a clean VM before public distribution. Inno Setup 6.3+.

#define MyAppName "SAKHO UZB Keyboard"
#define MyAppVersion "2.3"
#define MyAppPublisher "Saxobiddin Xudayberdiyev"
#define MyExeName "SAKHO_UZB_LongPress_2.3.exe"
#define MyProductCode "{88CFB0E1-7F06-4147-A208-3BC7FEE2BC59}"
#define ProjectDir "C:\Users\sakho\OneDrive\Документы\uzb"
#define ReleaseDir "C:\Users\sakho\Desktop\UZB_Release"

[Setup]
; Keep the SAME AppId as 2.2 for an in-place Inno Setup upgrade.
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
OutputDir={#ReleaseDir}
OutputBaseFilename=SAKHO_UZB_Keyboard_2_3_Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName=SAKHO UZB Keyboard 2.3
LicenseFile={#ProjectDir}\LICENSE.txt
SetupLogging=yes
UninstallLogging=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Files]
; Stage the ORIGINAL 2.2 keyboard installer and its companion DLLs unchanged.
Source: "{#ProjectDir}\UZB_amd64.msi"; DestName: "UZB_amd64.msi"; Flags: dontcopy
Source: "{#ProjectDir}\amd64\UZB.dll"; DestName: "amd64_UZB.dll"; Flags: dontcopy
Source: "{#ProjectDir}\wow64\UZB.dll"; DestName: "wow64_UZB.dll"; Flags: dontcopy

; AutoHotkey v2 x64 program: confirm actual compiled EXE uses 300 ms before release.
Source: "{#ReleaseDir}\{#MyExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ProjectDir}\LICENSE.txt"; DestDir: "{app}\licenses"; Flags: ignoreversion
Source: "{#ProjectDir}\AUTOHOTKEY_LICENSE.txt"; DestDir: "{app}\licenses"; Flags: ignoreversion

[InstallDelete]
; Remove ONLY known obsolete executable files, after stopping them.
Type: files; Name: "{app}\SAKHO_UZB_LongPress.exe"
Type: files; Name: "{app}\SAKHO_UZB_LongPress_2.exe"
Type: files; Name: "{app}\SAKHO_UZB_LongPress_2.2.exe"
Type: files; Name: "{app}\SAKHO_UZB_LongPress_2.2_REBUILD.exe"

[Registry]
; System-wide startup: process runs in the *interactive user's* normal context
; at next logon, NOT automatically elevated. Confirm multi-user behavior separately.
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "SAKHO_UZB_LongPress"; ValueData: """{app}\{#MyExeName}"""; Flags: uninsdeletevalue

[Run]
Filename: "{app}\{#MyExeName}"; Description: "Start SAKHO UZB LongPress 2.3"; Flags: nowait postinstall skipifsilent runasoriginaluser

[UninstallRun]
Filename: "{sys}\taskkill.exe"; Parameters: "/F /IM {#MyExeName}"; Flags: runhidden; RunOnceId: "StopLongPress23"

[Code]
function MsiQueryProductState(szProduct: String): Integer;
  external 'MsiQueryProductStateW@msi.dll stdcall';

const
  STATE_INSTALLED = 5;
  OWNERSHIP_KEY = 'Software\SAKHO UZB Keyboard';
  OWNERSHIP_VALUE = 'MSIInstalledBySakho23';

var
  KeyboardInstalledThisRun: Boolean;
  SetupCompleted: Boolean;
  KeyboardRestart: Boolean;
  KeyboardUninstallRestart: Boolean;

function RunMSI(const Parameters: String; var ExitCode: Integer): Boolean;
begin
  Result := Exec(ExpandConstant('{sys}\msiexec.exe'),
    Parameters, '', SW_HIDE, ewWaitUntilTerminated, ExitCode);
end;

procedure KillProcess(const ImageName: String);
var
  ExitCode: Integer;
begin
  if not Exec(ExpandConstant('{sys}\taskkill.exe'),
    '/F /IM "' + ImageName + '"', '', SW_HIDE,
    ewWaitUntilTerminated, ExitCode) then
    Log('Could not start taskkill for ' + ImageName)
  else
    Log('taskkill ' + ImageName + ' exit code: ' + IntToStr(ExitCode));
end;

procedure StopLongPress();
begin
  KillProcess('SAKHO_UZB_LongPress.exe');
  KillProcess('SAKHO_UZB_LongPress_2.exe');
  KillProcess('SAKHO_UZB_LongPress_2.2.exe');
  KillProcess('SAKHO_UZB_LongPress_2.2_REBUILD.exe');
  KillProcess('{#MyExeName}');
end;

function StageKeyboardFiles(): Boolean;
var
  Base: String;
begin
  Result := False;
  try
    ExtractTemporaryFile('UZB_amd64.msi');
    ExtractTemporaryFile('amd64_UZB.dll');
    ExtractTemporaryFile('wow64_UZB.dll');
    Base := ExpandConstant('{tmp}\');
    if not ForceDirectories(Base + 'amd64') then Exit;
    if not ForceDirectories(Base + 'wow64') then Exit;
    if not CopyFile(Base + 'amd64_UZB.dll', Base + 'amd64\UZB.dll', False) then Exit;
    if not CopyFile(Base + 'wow64_UZB.dll', Base + 'wow64\UZB.dll', False) then Exit;
    Result := FileExists(Base + 'UZB_amd64.msi');
  except
    Log('StageKeyboardFiles failed: ' + GetExceptionMessage);
  end;
end;

function KeyboardLayoutRegistered(): Boolean;
var
  Keys: TArrayOfString;
  I: Integer;
  K, DllName, LayoutText, LayoutId: String;
begin
  Result := False;
  if not RegGetSubkeyNames(HKLM,
    'SYSTEM\CurrentControlSet\Control\Keyboard Layouts', Keys) then
  begin
    Log('Unable to enumerate registered keyboard layouts.');
    Exit;
  end;

  for I := 0 to GetArrayLength(Keys) - 1 do
  begin
    K := 'SYSTEM\CurrentControlSet\Control\Keyboard Layouts\' + Keys[I];
    if RegQueryStringValue(HKLM, K, 'Layout File', DllName) and
       RegQueryStringValue(HKLM, K, 'Layout Text', LayoutText) then
    begin
      if (CompareText(DllName, 'uzb.dll') = 0) and
         (CompareText(LayoutText, 'Uzbek Latin Keyboard') = 0) then
      begin
        if RegQueryStringValue(HKLM, K, 'Layout Id', LayoutId) then
          Log('Matching keyboard layout: ' + Keys[I] + ' (Layout Id=' + LayoutId + ')')
        else
          Log('Matching keyboard layout: ' + Keys[I] + ' (Layout Id missing)');
        Result := True;
        Exit;
      end;
    end;
  end;
  Log('SAKHO keyboard registration not found by DLL and layout text.');
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ExitCode: Integer;
  MSIPath, LogPath, RepairParams: String;
  MsiAlreadyInstalled: Boolean;
begin
  Result := '';
  NeedsRestart := False;
  StopLongPress();

  MsiAlreadyInstalled := MsiQueryProductState('{#MyProductCode}') = STATE_INSTALLED;
  if MsiAlreadyInstalled and KeyboardLayoutRegistered() then
  begin
    Log('Existing keyboard MSI and registration verified; no MSI action needed.');
    Exit;
  end;

  { MSI may be installed while its HKLM keyboard-layout registration is missing.
    Repair through Windows Installer rather than manually writing registry values. }
  if MsiAlreadyInstalled then
  begin
    Log('MSI installed, but keyboard registration missing or inconsistent; repairing.');
    LogPath := ExpandConstant('{commonappdata}\SAKHO_UZB_Repair_23.log');
    RepairParams := '/famus "{#MyProductCode}" /qn /norestart /L*v "' + LogPath + '"';
    if not RunMSI(RepairParams, ExitCode) then
    begin
      Result := 'Could not launch Windows Installer repair. Log: ' + LogPath;
      Exit;
    end;
    if (ExitCode <> 0) and (ExitCode <> 3010) then
    begin
      Result := 'MSI repair failed (' + IntToStr(ExitCode) + '). Log: ' + LogPath;
      Exit;
    end;
    KeyboardRestart := ExitCode = 3010;
    if not KeyboardLayoutRegistered() then
      Result := 'MSI repair completed, but SAKHO keyboard registration was not restored.' + #13 + #10 + 'Check the MSI source, package identity and log: ' + LogPath;
  end;

  if not StageKeyboardFiles() then
  begin
    Result := 'Could not stage UZB MSI and keyboard DLL files.';
    Exit;
  end;

  MSIPath := ExpandConstant('{tmp}\UZB_amd64.msi');
  LogPath := ExpandConstant('{commonappdata}\SAKHO_UZB_Install_23.log');
  if not RunMSI('/i "' + MSIPath + '" /qn /norestart /L*v "' + LogPath + '"', ExitCode) then
  begin
    Result := 'Failed to launch Windows Installer.';
    Exit;
  end;

  if (ExitCode = 0) or (ExitCode = 3010) then
  begin
    KeyboardInstalledThisRun := True;
    KeyboardRestart := ExitCode = 3010;
    Log('Keyboard MSI installed; exit=' + IntToStr(ExitCode));
    if not KeyboardLayoutRegistered() then
      Result := 'MSI completed but SAKHO keyboard registry entry is absent or differs.' + #13 + #10 + 'Log: ' + LogPath;
  end
  else
    Result := 'Keyboard MSI failed (' + IntToStr(ExitCode) + '). Log: ' + LogPath;
end;

// Inform the user if the custom layout is installed system-wide but not yet
// present in their per-user Win+Space input list. Does not modify user profiles.
procedure CurPageChanged(CurPageID: Integer);
begin
  if (CurPageID = wpFinished) and (not WizardSilent) then
  begin
    WizardForm.FinishedLabel.Caption :=
      WizardForm.FinishedLabel.Caption + #13#10#13#10 +
      'If SAKHO UZB is missing from Win+Space, open Windows Settings > ' +
      'Time & Language > Language & Region. Add the Uzbek language if ' +
      'necessary, then open its Language options > Keyboards > Add a keyboard ' +
      'and select the installed Uzbek Latin Keyboard layout. ' +
      'Sign out and sign in again if the new layout does not appear.';
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    SetupCompleted := True;
    if KeyboardInstalledThisRun then
    begin
      if not RegWriteDWordValue(HKLM, OWNERSHIP_KEY, OWNERSHIP_VALUE, 1) then
        Log('WARNING: Could not persist MSI ownership marker; MSI will be preserved on uninstall.');
    end;
  end;
end;

procedure DeinitializeSetup();
var
  ExitCode: Integer;
  LogPath: String;
begin
  if KeyboardInstalledThisRun and (not SetupCompleted) then
  begin
    LogPath := ExpandConstant('{commonappdata}\SAKHO_UZB_Rollback_23.log');
    if RunMSI('/x "{#MyProductCode}" /qn /norestart /L*v "' + LogPath + '"', ExitCode) then
      Log('Rollback MSI result: ' + IntToStr(ExitCode))
    else
      Log('Failed to start MSI rollback. See ' + LogPath);
  end;
end;

function NeedRestart(): Boolean;
begin
  Result := KeyboardRestart;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ExitCode: Integer;
  Marker: Cardinal;
  LogPath: String;
begin
  if CurUninstallStep <> usUninstall then Exit;
  { Preserve MSIs installed before this 2.3 setup (including older 2.2 setups). }
  if not RegQueryDWordValue(HKLM, OWNERSHIP_KEY, OWNERSHIP_VALUE, Marker) then
  begin
    Log('No MSI ownership marker; leaving shared/existing keyboard MSI installed.');
    Exit;
  end;
  if Marker <> 1 then Exit;

  if MsiQueryProductState('{#MyProductCode}') <> STATE_INSTALLED then
  begin
    RegDeleteValue(HKLM, OWNERSHIP_KEY, OWNERSHIP_VALUE);
    Exit;
  end;

  LogPath := ExpandConstant('{commonappdata}\SAKHO_UZB_Uninstall_23.log');
  if not RunMSI('/x "{#MyProductCode}" /qn /norestart /L*v "' + LogPath + '"', ExitCode) then
  begin
    MsgBox('Unable to start keyboard MSI removal. Log: ' + LogPath,
      mbError, MB_OK);
    Exit;
  end;

  if (ExitCode = 0) or (ExitCode = 3010) or (ExitCode = 1605) then
  begin
    KeyboardUninstallRestart := ExitCode = 3010;
    RegDeleteValue(HKLM, OWNERSHIP_KEY, OWNERSHIP_VALUE);
    RegDeleteKeyIfEmpty(HKLM, OWNERSHIP_KEY);
  end
  else
    MsgBox('Keyboard MSI removal failed (' + IntToStr(ExitCode) + '). Log: ' + LogPath,
      mbError, MB_OK);
end;

function UninstallNeedRestart(): Boolean;
begin
  Result := KeyboardUninstallRestart;
end;
