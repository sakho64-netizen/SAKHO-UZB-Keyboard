
#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook True
InstallKeybdHook()

; ============================================
; SAKHO UZB Keyboard 2.2
; LongPress: 300 ms
; Backspace ishlatilmaydi
; UZB layout avtomatik aniqlanadi
; ============================================

LongMs := 300

; UZB layout HKL kodini reestrdan aniqlash
GetUZBHKL() {
    static cachedHKL := 0

    if cachedHKL
        return cachedHKL

    root := "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts"

    Loop Reg, root, "K" {
        try {
            path := A_LoopRegKey "\" A_LoopRegName
            dll := RegRead(path, "Layout File")

            if StrLower(dll) != "uzb.dll"
                continue

            layoutId := RegRead(path, "Layout Id")
            langId := Integer("0x" SubStr(A_LoopRegName, -4))

            cachedHKL := 0xF0000000
                | ((0xF000 | Integer("0x" layoutId)) << 16)
                | langId

            return cachedHKL & 0xFFFFFFFF
        }
    }

    return 0
}

; Faqat UZB layout faol bo'lganda ishlaydi
IsUZB() {
    uzbHKL := GetUZBHKL()
    if !uzbHKL
        return false

    cb := 8 + 6 * A_PtrSize + 16
    gti := Buffer(cb, 0)
    NumPut("UInt", cb, gti, 0)

    if !DllCall("GetGUIThreadInfo",
        "UInt", 0,
        "Ptr", gti.Ptr,
        "Int")
        return false

    hwndFocus := NumGet(gti, 8 + A_PtrSize, "Ptr")
    if !hwndFocus
        return false

    tid := DllCall("GetWindowThreadProcessId",
        "Ptr", hwndFocus,
        "Ptr", 0,
        "UInt")
    if !tid
        return false

    hkl := DllCall("GetKeyboardLayout",
        "UInt", tid,
        "Ptr")

    return (hkl & 0xFFFFFFFF) = uzbHKL
}

; ============================================
; LongPress hotkeys
; ============================================

#HotIf IsUZB()

; Kichik harflar
$SC018::LongPressNoBackspace("SC018", "o", "ö", "Ö")
$SC022::LongPressNoBackspace("SC022", "g", "ğ", "Ğ")
$SC01F::LongPressNoBackspace("SC01F", "s", "ş", "Ş")
$SC02E::LongPressNoBackspace("SC02E", "c", "ç", "Ç")

; Katta harflar (Shift)
$+SC018::LongPressNoBackspace("SC018", "o", "ö", "Ö")
$+SC022::LongPressNoBackspace("SC022", "g", "ğ", "Ğ")
$+SC01F::LongPressNoBackspace("SC01F", "s", "ş", "Ş")
$+SC02E::LongPressNoBackspace("SC02E", "c", "ç", "Ç")

#HotIf

; ============================================
; Backspace'siz LongPress algoritmi
; ============================================

LongPressNoBackspace(sc, plain, small, capital) {
    global LongMs

    upper := GetKeyState("Shift", "P") != GetKeyState("CapsLock", "T")

    ; Qisqa bosish: oddiy harf
    if KeyWait(sc, "T" (LongMs / 1000)) {
        SendText(upper ? StrUpper(plain) : plain)
        return
    }

    ; Uzoq bosish: maxsus harf
    SendText(upper ? capital : small)

    ; Tugma qo'yib yuborilishini kutish
    KeyWait(sc)
}
