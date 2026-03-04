#Requires AutoHotkey v2.0
DetectHiddenWindows true

tmExe := "C:\Windows\System32\TotalMixFX.exe"
mainTitleNeedle := "TotalMix FX"   ; <-- passt zu deinem tasklist /v Output

IsWindow(hwnd)  => DllCall("user32\IsWindow", "ptr", hwnd, "int") != 0
IsVisible(hwnd) => DllCall("user32\IsWindowVisible", "ptr", hwnd, "int") != 0

GetMainHwnd() {
    global mainTitleNeedle
    for hwnd in WinGetList() {
        if !IsWindow(hwnd)
            continue
        try {
            t := WinGetTitle("ahk_id " hwnd)
        } catch {
            continue
        }
        if InStr(t, mainTitleNeedle)
            return hwnd
    }
    return 0
}

EnsureShown(timeoutMs := 12000) {
    global tmExe
    start := A_TickCount
    launched := false

    loop {
        hwnd := GetMainHwnd()
        if hwnd {
            try WinShow("ahk_id " hwnd)
            try WinRestore("ahk_id " hwnd)
            try WinActivate("ahk_id " hwnd)
            if IsVisible(hwnd)
                return true
        } else if !launched {
            Run '"' tmExe '"'
            launched := true
        }

        if (A_TickCount - start) > timeoutMs
            return false
        Sleep 50
    }
}

EnsureHidden(timeoutMs := 2000) {
    start := A_TickCount
    loop {
        hwnd := GetMainHwnd()
        if !hwnd
            return true
        try WinHide("ahk_id " hwnd)
        if !IsVisible(hwnd)
            return true
        if (A_TickCount - start) > timeoutMs
            return false
        Sleep 30
    }
}

global _busy := false

F12::
{
    global _busy
    if _busy
        return
    _busy := true
    try {
        hwnd := GetMainHwnd()
        if !hwnd {
            EnsureShown(15000)
            return
        }
        if IsVisible(hwnd)
            EnsureHidden()
        else
            EnsureShown(4000)
    } finally {
        _busy := false
    }
}