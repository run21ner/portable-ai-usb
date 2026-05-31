@echo off
title Portable Uncensored AI - Launcher
color 0A

echo ===================================================
echo       Launching Portable AI Engine from USB...
echo ===================================================

:: 1. Define paths
set "DATA_PATH=%~dp0anythingllm_data"
set "APP_DATA_PATH=%DATA_PATH%\Roaming\anythingllm-desktop"
set "LOG_FILE=%DATA_PATH%\anythingllm.log"
set "ALOG_FILE=%APP_DATA_PATH%\anythingllm_app.log"
set "WATCHER_TMP=%DATA_PATH%\watcher.ps1"

:: 2. Nuke ALL leftover processes
echo [*] Cleaning up any leftover processes...
wmic process where "name='ollama.exe'" delete             >nul 2>&1
wmic process where "name='llm.exe'" delete                >nul 2>&1
wmic process where "name='AnythingLLM.exe'" delete        >nul 2>&1
wmic process where "name='AnythingLLMDesktop.exe'" delete >nul 2>&1
powershell -Command "Get-Process powershell | Where-Object {$_.MainWindowTitle -eq ''} | Stop-Process -Force" >nul 2>&1
ping 127.0.0.1 -n 3 >nul
echo [+] Cleanup done.

:: 3. Create folder structure if missing
if not exist "%DATA_PATH%\Roaming" mkdir "%DATA_PATH%\Roaming"
if not exist "%DATA_PATH%\Local"   mkdir "%DATA_PATH%\Local"

:: 4. Clear old log files
echo. > "%LOG_FILE%"
echo. > "%ALOG_FILE%"

:: 5. Set Ollama storage path
set "OLLAMA_MODELS=%APP_DATA_PATH%\storage\models\ollama"
set "STORAGE_DIR=%DATA_PATH%"

:: 6. Write watcher script - watches ollama log for stream aborts
echo $LogFile      = '%LOG_FILE%'                                                          > "%WATCHER_TMP%"
echo $OllamaExe    = '%~dp0ollama\ollama.exe'                                             >> "%WATCHER_TMP%"
echo $OllamaModels = '%~dp0ollama\data'                                                   >> "%WATCHER_TMP%"
echo $lastSize = 0                                                                         >> "%WATCHER_TMP%"
echo while ($true) {                                                                       >> "%WATCHER_TMP%"
echo     Start-Sleep -Seconds 2                                                            >> "%WATCHER_TMP%"
echo     if (-Not (Test-Path $LogFile)) { continue }                                      >> "%WATCHER_TMP%"
echo     try { $currentSize = (Get-Item $LogFile).length } catch { continue }             >> "%WATCHER_TMP%"
echo     if ($currentSize -le $lastSize) { continue }                                     >> "%WATCHER_TMP%"
echo     try {                                                                             >> "%WATCHER_TMP%"
echo         $stream = [System.IO.File]::Open($LogFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite) >> "%WATCHER_TMP%"
echo         $stream.Seek($lastSize, 'Begin') ^| Out-Null                                 >> "%WATCHER_TMP%"
echo         $reader = New-Object System.IO.StreamReader($stream)                         >> "%WATCHER_TMP%"
echo         $newText = $reader.ReadToEnd()                                                >> "%WATCHER_TMP%"
echo         $reader.Close()                                                               >> "%WATCHER_TMP%"
echo         $stream.Close()                                                               >> "%WATCHER_TMP%"
echo     } catch { continue }                                                              >> "%WATCHER_TMP%"
echo     $lastSize = $currentSize                                                          >> "%WATCHER_TMP%"
echo     if ($newText -match '\[STREAM ABORTED\]') {                                      >> "%WATCHER_TMP%"
echo         Stop-Process -Name 'ollama' -Force -ErrorAction SilentlyContinue             >> "%WATCHER_TMP%"
echo         Stop-Process -Name 'llm'    -Force -ErrorAction SilentlyContinue             >> "%WATCHER_TMP%"
echo         Start-Sleep -Seconds 2                                                        >> "%WATCHER_TMP%"
echo         $env:OLLAMA_MODELS = $OllamaModels                                           >> "%WATCHER_TMP%"
echo         Start-Process -FilePath $OllamaExe -ArgumentList 'serve' -WindowStyle Hidden >> "%WATCHER_TMP%"
echo         Start-Sleep -Seconds 5                                                        >> "%WATCHER_TMP%"
echo     }                                                                                 >> "%WATCHER_TMP%"
echo }                                                                                     >> "%WATCHER_TMP%"

:: 7. Start Ollama and pipe to its own log
echo [*] Starting Ollama Engine...
start "" /B cmd /c ""%~dp0ollama\ollama.exe" serve >> "%LOG_FILE%" 2>&1"
ping 127.0.0.1 -n 8 >nul
echo [+] Ollama is running.

:: 8. Find AnythingLLM
echo [*] Starting AnythingLLM Interface...
if exist "%~dp0anythingllm\AnythingLLM.exe" (
    set "APP_PATH=%~dp0anythingllm\AnythingLLM.exe"
) else if exist "%~dp0anythingllm_app\AnythingLLM.exe" (
    set "APP_PATH=%~dp0anythingllm_app\AnythingLLM.exe"
) else (
    echo ERROR: AnythingLLM.exe was not found! Run install.bat first.
    pause
    exit /b
)

:: 9. Launch AnythingLLM and pipe ALL output to the log
start "" /B cmd /c ""%APP_PATH%" --production --user-data-dir="%DATA_PATH%\Roaming" >> "%ALOG_FILE%" 2>&1"
echo [+] AnythingLLM is running.

:: 10. Wait a moment before starting watcher so log file is not locked
ping 127.0.0.1 -n 4 >nul

:: 11. Launch watcher in background
echo [*] Starting background recovery watcher...
start "" /B powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "%WATCHER_TMP%"
echo [+] Watcher is running.

echo.
echo ===================================================
echo   SYSTEM ONLINE: Your AI is running from the USB!
echo ===================================================
echo.
echo Showing live backend log. Press CTRL+C to get the
echo shutdown prompt when you are done.
echo ---------------------------------------------------
echo.

:: 12. Stream BOTH log files live to console
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$log1 = '%LOG_FILE%'; $log2 = '%ALOG_FILE%'; $p1 = 0; $p2 = 0;" ^
 "while ($true) {" ^
 "  Start-Sleep -Milliseconds 500;" ^
 "  foreach ($entry in @(@{log=$log1; pos=[ref]$p1; tag='[ollama]'}, @{log=$log2; pos=[ref]$p2; tag='[app]'})) {" ^
 "    if (-Not (Test-Path $entry.log)) { continue };" ^
 "    try {" ^
 "      $f = [System.IO.File]::Open($entry.log, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite);" ^
 "      $f.Seek($entry.pos.Value, 'Begin') | Out-Null;" ^
 "      $r = New-Object System.IO.StreamReader($f);" ^
 "      $t = $r.ReadToEnd(); $r.Close(); $f.Close();" ^
 "      if ($t.Length -gt 0) { Write-Host ($entry.tag + ' ' + $t) -NoNewline; $entry.pos.Value += [System.Text.Encoding]::UTF8.GetByteCount($t) }" ^
 "    } catch {}" ^
 "  }" ^
 "}"

:: 13. Reached after CTRL+C
echo.
echo ---------------------------------------------------
echo Press [R] then [ENTER] to RESTART.
echo Press [ENTER] (empty) to SHUT DOWN.
echo.
set "userinput="
set /p userinput="Selection: "

:: 14. Full kill
echo.
echo Shutting down AI services...
wmic process where "name='ollama.exe'" delete             >nul 2>&1
wmic process where "name='llm.exe'" delete                >nul 2>&1
wmic process where "name='AnythingLLM.exe'" delete        >nul 2>&1
wmic process where "name='AnythingLLMDesktop.exe'" delete >nul 2>&1
powershell -Command "Get-Process powershell | Where-Object {$_.MainWindowTitle -eq ''} | Stop-Process -Force" >nul 2>&1

:: 15. Verify all dead
:CheckProcesses
tasklist /FI "IMAGENAME eq ollama.exe" 2>nul | find /I "ollama.exe" >nul
if not errorlevel 1 (
    wmic process where "name='ollama.exe'" delete >nul 2>&1
    ping 127.0.0.1 -n 2 >nul
    goto CheckProcesses
)
tasklist /FI "IMAGENAME eq llm.exe" 2>nul | find /I "llm.exe" >nul
if not errorlevel 1 (
    wmic process where "name='llm.exe'" delete >nul 2>&1
    ping 127.0.0.1 -n 2 >nul
    goto CheckProcesses
)
echo All processes confirmed dead.

:: 16. Restart vs Shutdown
if /i "%userinput%"=="R" (
    echo Restarting system...
    ping 127.0.0.1 -n 3 >nul
    start "" cmd /c "%~f0"
    exit /b
)

echo.
echo AI Engine shut down. You may safely eject the USB.
ping 127.0.0.1 -n 4 >nul
exit
