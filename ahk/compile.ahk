^!c::
    SetWorkingDir, %A_ScriptDir%\..\bat
    Run, simulate.bat
    WinWait C:\WINDOWS\system32\cmd.exe
    WinMaximize
Return