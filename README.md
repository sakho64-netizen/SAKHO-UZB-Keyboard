# SAKHO UZB Keyboard

**Version 2.3 — release candidate (testing)** · Windows 10/11 x64

SAKHO UZB Keyboard is a custom Uzbek Latin keyboard layout for Windows. It combines an MSKLC keyboard layout with an AutoHotkey-based LongPress helper.

> **Release status:** Version 2.3 is still being tested. Do not replace the published 2.2 release until installation, upgrade, restart and uninstall tests are complete.

## Uzbekcha

### Dastur haqida

SAKHO UZB Keyboard Windows 10 va Windows 11 ning **x64 (Intel/AMD)** tizimlari uchun moʻljallangan oʻzbek lotin klaviaturasi loyihasidir. Maxsus harflarni olish uchun tugmani bosib turish mumkin.

| Tugma | Qisqa bosish | 300 ms bosib turish |
| --- | --- | --- |
| O | o | ö |
| G | g | ğ |
| S | s | ş |
| C | c | ç |

**Shift** bilan `Ö`, `Ğ`, `Ş`, `Ç` harflari kiritiladi; CapsLock bilan ishlash ham LongPress skriptida hisobga olingan.

### Oʻrnatish (2.3 sinov versiyasi)

1. Sinov uchun chiqarilgan `SAKHO_UZB_Keyboard_2_3_Setup.exe` faylini ishga tushiring.
2. Litsenziya shartlarini oʻqing va rozilik bildiring.
3. Oʻrnatishni yakunlang; tizim qayta yuklashni soʻrasa, ishlaringizni saqlab qayta yuklang.
4. `Win + Space` roʻyxatida klaviatura koʻrinmasa, Windows **Settings → Time & language → Language & region** orqali o‘zbek tili va tegishli `Uzbek Latin Keyboard` joylashuvini qoʻshishni tekshiring. Sozlamalardagi nom Windows tiliga qarab farq qilishi mumkin.
5. Notepad’da `o g s c` va `ö ğ ş ç` ni sinang.

**Diagnostika:** LongPress ishga tushgach, `Ctrl + Alt + Shift + K` ni bosing. Oynada joriy HKL va klaviatura tanilgan-tanilmagani koʻrsatiladi. `YES` chiqishi harflar barcha ilovalarda toʻgʻri ishlashini kafolatlamaydi.

### Muhim cheklovlar

- Hozircha faqat Windows 10/11 **x64** uchun moʻljallangan; 32-bit va ARM64 qoʻllab-quvvatlanishi tasdiqlanmagan.
- Yuqori huquqli (administrator) dasturlarda AutoHotkey kiritish cheklovlari boʻlishi mumkin.
- Barcha Windows 10/11 yigʻilmalari va har bir kompyuterda ishlashi hali tasdiqlanmagan.
- LongPress 2.3 uchun standart vaqt **300 ms**; eski 2.2 relizi alohida saqlanadi.

## English

SAKHO UZB Keyboard provides an Uzbek Latin keyboard layout for Windows 10/11 x64, plus a 300 ms LongPress helper for `ö`, `ğ`, `ş`, and `ç` (uppercase with Shift).

**Version 2.3 is a release candidate, not yet a publicly validated stable release.** The existing 2.2 GitHub release should remain available during testing.

To diagnose layout detection while the helper is running, press **Ctrl+Alt+Shift+K**. If the keyboard does not appear in the **Win+Space** switcher, check the language and keyboard settings for the current Windows user.

## Source and licensing

Project files include the keyboard layout source (`UZB.klc`), the LongPress AutoHotkey source, the Inno Setup installer source, and `LICENSE.txt` / `AUTOHOTKEY_LICENSE.txt`. Consult the actual license files in the repository for terms; this README does not replace them.

## Releases

- **2.2** — previously published release; retain for rollback.
- **2.3** — release candidate with KeyWait LongPress, 300 ms hold time, improved HKL diagnostics and installer checks. Publish after clean-VM testing.

See [CHANGELOG.md](CHANGELOG.md) for details.
