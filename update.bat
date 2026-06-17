@echo off
title Portable AI - Updater
color 0B
setlocal

echo ===================================================
echo        PORTABLE AI - UPDATE TOOL
echo ===================================================
echo.
echo This will update AnythingLLM and/or Ollama to
echo the latest versions. Your chats and settings
echo are preserved.
echo.
echo Make sure the AI is NOT running before continuing!
echo.
pause

set "USB=%~dp0"

:: Kill anything still running just in case
echo [*] Stopping any running processes...
taskkill /F /IM ollama.exe             >nul 2>&1
taskkill /F /IM AnythingLLM.exe        >nul 2>&1
taskkill /F /IM AnythingLLMDesktop.exe >nul 2>&1
ping 127.0.0.1 -n 3 >nul
echo [+] Done.
echo.

echo What would you like to update?
echo.
echo   [1] AnythingLLM only
echo   [2] Ollama only
echo   [3] Both
echo.
set "choice="
set /p choice="Selection: "

if "%choice%"=="1" goto UpdateALLM
if "%choice%"=="2" goto UpdateOllama
if "%choice%"=="3" goto UpdateALLM
echo Invalid selection.
goto End

:: ------------------------------------------------------------------
:: UPDATE ANYTHINGLLM
:: ------------------------------------------------------------------
:UpdateALLM
echo.
echo [*] Downloading latest AnythingLLM...
set "INSTALLER=%USB%anythingllm\AnythingLLMDesktop.exe"
curl.exe -L --ssl-no-revoke --progress-bar ^
  "https://cdn.anythingllm.com/latest/AnythingLLMDesktop.exe" ^
  -o "%INSTALLER%"

if not exist "%INSTALLER%" (
    echo [!] ERROR: Download failed. Check your internet connection.
    if "%choice%"=="3" goto UpdateOllama
    goto End
)

echo [*] Installing over existing version (silent)...
powershell -NoProfile -Command ^
  "$fso = New-Object -ComObject Scripting.FileSystemObject;" ^
  "$short = $fso.GetFolder('%USB%').ShortPath;" ^
  "Start-Process -FilePath '%INSTALLER%' -ArgumentList ('/S /D=' + $short + 'anythingllm') -Wait"

if exist "%USB%anythingllm\AnythingLLM.exe" (
    del /f /q "%INSTALLER%" >nul 2>&1
    echo [+] AnythingLLM updated successfully!
) else (
    echo [!] WARNING: Could not verify update.
    echo     Installer kept at: %INSTALLER%
    echo     Run it manually and install into: %USB%anythingllm
)

if "%choice%"=="3" goto UpdateOllama
goto End

:: ------------------------------------------------------------------
:: UPDATE OLLAMA (full zip - keeps all DLLs current)
:: ------------------------------------------------------------------
:UpdateOllama
echo.
echo [*] Downloading latest Ollama zip...
set "OLLAMAZIP=%USB%ollama\ollama-update.zip"
curl.exe -L --ssl-no-revoke --progress-bar ^
  "https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip" ^
  -o "%OLLAMAZIP%"

if not exist "%OLLAMAZIP%" (
    echo [!] ERROR: Download failed. Check your internet connection.
    goto End
)

echo [*] Extracting Ollama (overwrites existing files)...
powershell -NoProfile -Command ^
  "Expand-Archive -Path '%OLLAMAZIP%' -DestinationPath '%USB%ollama' -Force"
del /f /q "%OLLAMAZIP%" >nul 2>&1

if exist "%USB%ollama\ollama.exe" (
    echo [+] Ollama updated successfully!
) else (
    echo [!] ERROR: Ollama extraction failed. Try again.
)

:End
echo.
echo ===================================================
echo         ALL DONE!
echo ===================================================
echo.
echo Launch the AI anytime with start-windows.bat
echo.
endlocal
pause
