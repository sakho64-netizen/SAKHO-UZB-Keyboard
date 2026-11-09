#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook True
Persistent
InstallKeybdHook()

; SAKHO UZB Keyboard 2.3 - KeyWait TEST
; Hold threshold: 300 ms. Only applies when the SAKHO UZB layout is active.
; The script does not edit the registry or install a keyboard layout.

global HoldSeconds := 0.300
global UzbHKLs := Map()
global UzbDebug := ""
global ActivePresses := Map()

RefreshUzb()
SetTimer(RefreshUzb, 30000)

; Physical scan codes for O, G, S and C on the target keyboard.
#HotIf IsUzb() && !GetKeyState("Ctrl", "P") && !GetKeyState("Alt", "P") && !GetKeyState("LWin", "P") && !GetKeyState("RWin", "P")
$*SC018::HoldKey("SC018", "o", "ö", "Ö")
$*SC022::HoldKey("SC022", "g", "ğ", "Ğ")
$*SC01F::HoldKey("SC01F", "s", "ş", "Ş")
$*SC02E::HoldKey("SC02E", "c", "ç", "Ç")
#HotIf

; Always available. Refresh the list before showing diagnostics.
^!+k:: {
    global UzbDebug, UzbHKLs
    RefreshUzb()
    hkl := CurrentHkl()
    MsgBox("Current HKL: " Format("0x{:08X}", hkl)
        . "`nSAKHO detected: " (UzbHKLs.Has(hkl) ? "YES" : "NO")
        . "`n`nRegistered layouts:`n" (UzbDebug = "" ? "(none found)" : UzbDebug),
        "SAKHO UZB 2.3 diagnostics")
}

RefreshUzb(*) {
    global UzbHKLs, UzbDebug
    found := Map()
    debugText := ""
    root := "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts"
    try {
        Loop Reg, root, "K" {
            keyName := A_LoopRegName
            path := root "\" keyName
            try {
                dllName := StrLower(RegRead(path, "Layout File", ""))
                displayName := RegRead(path, "Layout Text", "")
                ; Recognise the known DLLs or the explicit SAKHO brand name.
                if !(dllName = "uzb.dll" || dllName = "sakhouzb.dll"
                    || InStr(displayName, "SAKHO UZB", false))
                    continue

                ; A directly matching KLID is possible on some layouts.
                if RegExMatch(keyName, "i)^[0-9a-f]{8}$") {
                    directHKL := Integer("0x" keyName) & 0xFFFFFFFF
                    found[directHKL] := true
                }

                idText := RegRead(path, "Layout Id", "")
                expected := "not available"
                if (idText != "" && RegExMatch(idText, "i)^[0-9a-f]{1,4}$")
                    && RegExMatch(keyName, "i)^[0-9a-f]{8}$")) {
                    id := Integer("0x" idText)
                    langId := Integer("0x" SubStr(keyName, -4))
                    calculated := (0xF0000000 | ((0xF000 | id) << 16) | langId) & 0xFFFFFFFF
                    found[calculated] := true
                    expected := Format("0x{:08X}", calculated)
                }
                debugText .= keyName " | " dllName " | " displayName
                    . " | ID=" idText " | computed=" expected "`n"
            } catch as err {
                debugText .= "ERROR reading " keyName ": " err.Message "`n"
            }
        }
        ; Atomic replacement: do not expose a partially built map to hotkeys.
        UzbHKLs := found
    } catch as err {
        debugText .= "ERROR scanning registry: " err.Message "`n"
    }
    UzbDebug := debugText
}

CurrentHkl() {
    hwnd := DllCall("GetForegroundWindow", "Ptr")
    if !hwnd
        return 0
    tid := DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "Ptr", 0, "UInt")
    if !tid
        return 0
    return DllCall("GetKeyboardLayout", "UInt", tid, "Ptr") & 0xFFFFFFFF
}

IsUzb(*) {
    global UzbHKLs
    return UzbHKLs.Has(CurrentHkl())
}

HoldKey(sc, plain, accented, accentedUpper, *) {
    global HoldSeconds, ActivePresses

    ; Ignore typematic re-entry for the same physical key.
    if ActivePresses.Has(sc)
        return
    ActivePresses[sc] := true

    startWindow := DllCall("GetForegroundWindow", "Ptr")
    startHkl := CurrentHkl()
    isUpper := GetKeyState("Shift", "P") != GetKeyState("CapsLock", "T")
    try {
        ; KeyWait returns true when released before timeout.
        releasedQuickly := KeyWait(sc, "T" HoldSeconds)
        ; Never type into another window or a different keyboard layout.
        if (DllCall("GetForegroundWindow", "Ptr") != startWindow
            || CurrentHkl() != startHkl || !IsUzb()) {
            ; If the key is still held, wait for its release without typing.
            if !releasedQuickly
                KeyWait(sc)
            return
        }

        if releasedQuickly {
            SendText(isUpper ? StrUpper(plain) : plain)
        } else {
            SendText(isUpper ? accentedUpper : accented)
            ; Suppress auto-repeat until the physical key is released.
            KeyWait(sc)
        }
    } finally {
        ActivePresses.Delete(sc)
    }
}
