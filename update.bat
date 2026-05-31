@echo off
title Portable AI - Updater
color 0B

echo ===================================================
echo        PORTABLE AI - UPDATE TOOL
echo ===================================================
echo.
echo This will update AnythingLLM and/or Ollama to the
echo latest versions. Your chats and settings are safe.
echo.
echo Make sure the AI is NOT running before continuing!
echo.
pause

:: 1. Kill anything still running just in case
echo [*] Stopping any running processes...
wmic process where "name='ollama.exe'" delete             >nul 2>&1
wmic process where "name='llm.exe'" delete                >nul 2>&1
wmic process where "name='AnythingLLM.exe'" delete        >nul 2>&1
wmic process where "name='AnythingLLMDesktop.exe'" delete >nul 2>&1
ping 127.0.0.1 -n 3 >nul
echo [+] Done.

echo.
echo What would you like to update?
echo.
echo [1] AnythingLLM only
echo [2] Ollama only
echo [3] Both
echo.
set "choice="
set /p choice="Selection: "

if "%choice%"=="1" goto UpdateALLM
if "%choice%"=="2" goto UpdateOllama
if "%choice%"=="3" goto UpdateALLM
echo Invalid selection.
goto End

:: -------------------------------------------------------
:: UPDATE ANYTHINGLLM
:: -------------------------------------------------------
:UpdateALLM
echo.
echo [*] Downloading latest AnythingLLM...
set "INSTALLER=%~dp0anythingllm\AnythingLLMDesktop.exe"
curl.exe -L --ssl-no-revoke --progress-bar "https://cdn.anythingllm.com/latest/AnythingLLMDesktop.exe" -o "%INSTALLER%"

if not exist "%INSTALLER%" (
    echo [!] ERROR: Download failed. Check your internet connection.
    goto End
)

echo [*] Installing over existing version...
powershell -Command "(New-Object -ComObject Scripting.FileSystemObject).GetFolder('%~dp0').ShortPath" > "%TEMP%\shortpath.txt"
set /p ShortPath= < "%TEMP%\shortpath.txt"
del "%TEMP%\shortpath.txt" >nul 2>&1

powershell -Command "Start-Process -FilePath '%INSTALLER%' -ArgumentList '/S /D=%ShortPath%anythingllm' -Wait"

if exist "%~dp0anythingllm\AnythingLLM.exe" (
    del /f /q "%INSTALLER%" >nul 2>&1
    echo [+] AnythingLLM updated successfully!
) else (
    echo [!] WARNING: Could not verify update. Installer kept at: %INSTALLER%
)

if "%choice%"=="3" goto UpdateOllama
goto End

:: -------------------------------------------------------
:: UPDATE OLLAMA
:: -------------------------------------------------------
:UpdateOllama
echo.
echo [*] Downloading latest Ollama...
set "OLLAMAZIP=%~dp0ollama\ollama-update.zip"
curl.exe -L --ssl-no-revoke --progress-bar "https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip" -o "%OLLAMAZIP%"

if not exist "%OLLAMAZIP%" (
    echo [!] ERROR: Download failed. Check your internet connection.
    goto End
)

echo [*] Extracting Ollama...
powershell -Command "Expand-Archive -Path '%OLLAMAZIP%' -DestinationPath '%~dp0ollama' -Force"
del /f /q "%OLLAMAZIP%" >nul 2>&1

if exist "%~dp0ollama\ollama.exe" (
    echo [+] Ollama updated successfully!
) else (
    echo [!] ERROR: Ollama extraction failed.
)

:End
echo.
echo ===================================================
echo         ALL DONE!
echo ===================================================
echo.
echo Launch the AI anytime with start-windows.bat
echo.
pause
