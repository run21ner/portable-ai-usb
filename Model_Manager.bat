@echo off
title Portable AI - Model Manager
color 0B
setlocal EnableDelayedExpansion

set "USB=%~dp0"
set "OLLAMA_EXE=%USB%ollama\ollama.exe"
set "OLLAMA_DATA=%USB%ollama\data"
set "MODELS_DIR=%USB%models"
set "OLLAMA_MODELS=%OLLAMA_DATA%"
set "OLLAMA_HOST=127.0.0.1:11434"

cls
echo.
echo  ==========================================
echo    PORTABLE AI ^| Model Manager
echo  ==========================================
echo.

:: --- Pre-flight ---
if not exist "%OLLAMA_EXE%" (
    echo  [!] ERROR: ollama\ollama.exe not found.
    echo      Run install.bat first.
    echo.
    pause
    exit /b 1
)

if not exist "%MODELS_DIR%" mkdir "%MODELS_DIR%"

:: --- Check if Ollama server is already running ---
set "STARTED_SERVER=0"
powershell -NoProfile -Command ^
  "try { Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/version' -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1

if errorlevel 1 (
    echo  [*] Starting Ollama server temporarily...
    start "" /B cmd /c "set "OLLAMA_MODELS=%OLLAMA_DATA%" && set "OLLAMA_HOST=127.0.0.1:11434" && "%OLLAMA_EXE%" serve >nul 2>&1"
    set "STARTED_SERVER=1"
    <nul set /p "=     Waiting"
    :WaitServe
    ping 127.0.0.1 -n 2 >nul
    <nul set /p "=."
    powershell -NoProfile -Command ^
      "try { Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/version' -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
    if errorlevel 1 goto WaitServe
    echo.
    echo  [+] Ollama server ready.
) else (
    echo  [+] Ollama server already running.
)
echo.

:: ================================================================
::  MAIN MENU
:: ================================================================
:MainMenu
echo  What would you like to do?
echo.
echo    [1]  Pull from Ollama Library
echo    [2]  Pull from HuggingFace (GGUF)
echo    [3]  Register a local GGUF file already on this machine
echo    [4]  List all models
echo    [5]  Remove a model
echo    [0]  Exit
echo.
set "MAINCHOICE="
set /p MAINCHOICE="  Selection: "

if "%MAINCHOICE%"=="1" goto OllamaMenu
if "%MAINCHOICE%"=="2" goto HuggingFaceMenu
if "%MAINCHOICE%"=="3" goto RegisterLocal
if "%MAINCHOICE%"=="4" goto ListModels
if "%MAINCHOICE%"=="5" goto RemoveModel
if "%MAINCHOICE%"=="0" goto Exit
echo  Invalid selection.
echo.
goto MainMenu

:: ================================================================
::  OPTION 1 - OLLAMA LIBRARY
:: ================================================================
:OllamaMenu
cls
echo.
echo  ==========================================
echo    Pull from Ollama Library
echo  ==========================================
echo.
echo  Recommended for 8 GB RAM / CPU-only systems:
echo.
echo    [1]  llama3.2          ~2.0 GB   Best balance of speed + quality
echo    [2]  llama3.2:1b       ~1.3 GB   Fastest, lower quality
echo    [3]  mistral           ~4.1 GB   Strong reasoning
echo    [4]  phi3:mini         ~2.2 GB   Microsoft - very efficient
echo    [5]  gemma2:2b         ~1.6 GB   Google - fast and capable
echo    [6]  deepseek-r1:1.5b  ~1.1 GB   Reasoning model, very small
echo    [7]  qwen2.5:3b        ~2.0 GB   Multilingual, strong coder
echo    [8]  Type a custom model name
echo    [0]  Back
echo.
echo  Browse all models at: https://ollama.com/library
echo.
set "OCHOICE="
set /p OCHOICE="  Selection: "

if "%OCHOICE%"=="0" goto BackToMain
if "%OCHOICE%"=="1" set "MODEL=llama3.2"
if "%OCHOICE%"=="2" set "MODEL=llama3.2:1b"
if "%OCHOICE%"=="3" set "MODEL=mistral"
if "%OCHOICE%"=="4" set "MODEL=phi3:mini"
if "%OCHOICE%"=="5" set "MODEL=gemma2:2b"
if "%OCHOICE%"=="6" set "MODEL=deepseek-r1:1.5b"
if "%OCHOICE%"=="7" set "MODEL=qwen2.5:3b"
if "%OCHOICE%"=="8" (
    echo.
    set "MODEL="
    set /p MODEL="  Enter model name (e.g. llama3.2 or mistral:7b): "
    if "!MODEL!"=="" goto OllamaMenu
)
if "!MODEL!"=="" (
    echo  Invalid selection.
    goto OllamaMenu
)

echo.
echo  [*] Pulling: !MODEL!
echo      Saving to: %OLLAMA_DATA%
echo.
"%OLLAMA_EXE%" pull !MODEL!

if errorlevel 1 (
    echo.
    echo  [!] Pull failed. Check the model name and your internet connection.
) else (
    echo.
    echo  [+] Done! "!MODEL!" is ready to use.
    echo      Select it in AnythingLLM ^> Settings ^> LLM ^> Ollama Model.
)
echo.
pause
goto BackToMain

:: ================================================================
::  OPTION 2 - HUGGINGFACE GGUF
:: ================================================================
:HuggingFaceMenu
cls
echo.
echo  ==========================================
echo    Pull from HuggingFace (GGUF)
echo  ==========================================
echo.
echo  HOW TO USE:
echo  -----------
echo   Paste a repo URL - optionally add :QUANTIZATION at the end
echo   to skip the file list and download directly.
echo.
echo   No quant   -^>  shows all .gguf files to pick from
echo   With quant -^>  auto-selects the matching file
echo.
echo   EXAMPLES:
echo     https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF
echo     https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF:Q4_K_M
echo     https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF:Q2_K
echo     https://huggingface.co/TheBloke/Mistral-7B-v0.1-GGUF:Q4_K_M
echo.
echo  QUANT GUIDE (for 8 GB RAM / CPU-only):
echo    Q2_K    = Smallest file, lowest quality
echo    Q3_K_S  = Very small
echo    Q4_K_M  = RECOMMENDED - best speed/quality balance
echo    Q5_K_M  = Slightly better quality, larger file
echo    Q6_K    = Near full quality, needs more RAM
echo    Q8_0    = Highest quality, very large
echo.
echo  POPULAR REPOS:
echo    https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF
echo    https://huggingface.co/bartowski/Phi-3-mini-4k-instruct-GGUF
echo    https://huggingface.co/bartowski/gemma-2-2b-it-GGUF
echo    https://huggingface.co/TheBloke  (huge collection)
echo.
echo  [0]  Back
echo.
set "HF_INPUT="
set /p HF_INPUT="  Paste URL (with optional :QUANT) or 0 to go back: "

if "!HF_INPUT!"=="0" goto BackToMain
if "!HF_INPUT!"=="" goto HuggingFaceMenu

:: ------------------------------------------------------------------
:: Split input into base URL and optional quant hint
:: Strip "https://" first, then split remainder on ":"
::   remainder = "huggingface.co/owner/repo:Q4_K_M"
::   token 1   = "huggingface.co/owner/repo"
::   token 2   = "Q4_K_M"  (quant, may be empty)
:: ------------------------------------------------------------------
set "HF_QUANT="
set "HF_URL=!HF_INPUT!"
set "STRIPPED=!HF_INPUT:https://=!"

echo !STRIPPED! | findstr ":" >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=1,2 delims=:" %%A in ("!STRIPPED!") do (
        set "HF_REPO_PART=%%A"
        set "HF_QUANT=%%B"
    )
    set "HF_URL=https://!HF_REPO_PART!"
)

if "!HF_URL:~-1!"=="/" set "HF_URL=!HF_URL:~0,-1!"
set "HF_REPO=!HF_URL:https://huggingface.co/=!"

echo !HF_REPO! | findstr /R "^[^/][^/]*/[^/][^/]*$" >nul 2>&1
if errorlevel 1 (
    echo.
    echo  [!] That does not look like a valid HuggingFace repo URL.
    echo      Expected: https://huggingface.co/owner/repo-name
    echo      Got     : !HF_INPUT!
    echo.
    pause
    goto HuggingFaceMenu
)

if not "!HF_QUANT!"=="" (
    echo.
    echo  [*] Repo  : !HF_REPO!
    echo      Quant : !HF_QUANT!
) else (
    echo.
    echo  [*] Repo  : !HF_REPO!
    echo      Quant : (not specified - will show file list)
)

echo  [*] Fetching file list from HuggingFace...
set "HF_API=https://huggingface.co/api/models/!HF_REPO!"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try {" ^
  "  $r = Invoke-WebRequest -Uri '!HF_API!' -UseBasicParsing -ErrorAction Stop | ConvertFrom-Json;" ^
  "  $files = $r.siblings | Where-Object { $_.rfilename -like '*.gguf' } | Select-Object -ExpandProperty rfilename;" ^
  "  $files | ForEach-Object { Write-Output $_ }" ^
  "} catch { Write-Error $_.Exception.Message; exit 1 }" > "%TEMP%\hf_gguf_files.txt" 2>"%TEMP%\hf_err.txt"

if errorlevel 1 (
    echo.
    echo  [!] Could not reach HuggingFace or repo not found.
    echo      Check the URL and your internet connection.
    echo.
    pause
    goto HuggingFaceMenu
)

set "GGUF_COUNT=0"
for /f "usebackq delims=" %%F in ("%TEMP%\hf_gguf_files.txt") do set /a GGUF_COUNT+=1

if %GGUF_COUNT%==0 (
    echo.
    echo  [!] No .gguf files found in that repo.
    echo      Make sure you are linking to a GGUF model repo.
    echo.
    pause
    goto HuggingFaceMenu
)

set "CHOSEN_FILE="

if not "!HF_QUANT!"=="" (
    for /f "usebackq delims=" %%F in ("%TEMP%\hf_gguf_files.txt") do (
        if "!CHOSEN_FILE!"=="" (
            echo %%F | findstr /I "!HF_QUANT!" >nul 2>&1
            if not errorlevel 1 set "CHOSEN_FILE=%%F"
        )
    )
    if "!CHOSEN_FILE!"=="" (
        echo.
        echo  [!] No file matching "!HF_QUANT!" found in this repo.
        echo      Available files:
        for /f "usebackq delims=" %%F in ("%TEMP%\hf_gguf_files.txt") do echo      %%F
        echo.
        echo  Tip: re-paste the URL without :QUANT to pick from the list.
        echo.
        pause
        goto HuggingFaceMenu
    )
    echo  [+] Auto-selected: !CHOSEN_FILE!
    goto SkipFileList
)

echo.
echo  Found !GGUF_COUNT! GGUF file(s) in !HF_REPO!:
echo.
set "IDX=0"
for /f "usebackq delims=" %%F in ("%TEMP%\hf_gguf_files.txt") do (
    set /a IDX+=1
    set "FILE_!IDX!=%%F"
    echo    [!IDX!]  %%F
)
echo.
echo  TIP: Q4_K_M is the best quality/size tradeoff for most systems.
echo.
set "FILEIDX="
set /p FILEIDX="  Select file number (or 0 to go back): "

if "!FILEIDX!"=="0" goto HuggingFaceMenu
if "!FILEIDX!"=="" goto HuggingFaceMenu

set "CHOSEN_FILE=!FILE_%FILEIDX%!"
if "!CHOSEN_FILE!"=="" (
    echo  Invalid selection.
    goto HuggingFaceMenu
)

:SkipFileList

echo.
set "SAFE_NAME=!HF_REPO:/=-!"
if not "!HF_QUANT!"=="" set "SAFE_NAME=!SAFE_NAME!-!HF_QUANT!"
echo  Give this model a short name for Ollama/AnythingLLM.
echo  (Letters, numbers, hyphens only. No spaces.)
echo  Suggestion: !SAFE_NAME!
echo.
set "MODEL_NAME="
set /p MODEL_NAME="  Model name (press Enter to use suggestion): "
if "!MODEL_NAME!"=="" set "MODEL_NAME=!SAFE_NAME!"

set "HF_FILE_URL=https://huggingface.co/!HF_REPO!/resolve/main/!CHOSEN_FILE!"
set "DEST=%MODELS_DIR%\!CHOSEN_FILE!"

echo.
echo  [*] Downloading: !CHOSEN_FILE!
echo      From : !HF_FILE_URL!
echo      To   : !DEST!
echo.
curl.exe -L --ssl-no-revoke --progress-bar "!HF_FILE_URL!" -o "!DEST!"

if errorlevel 1 (
    echo.
    echo  [!] Download failed. Check your internet connection.
    echo.
    pause
    goto HuggingFaceMenu
)

if not exist "!DEST!" (
    echo.
    echo  [!] File not found after download. Something went wrong.
    echo.
    pause
    goto HuggingFaceMenu
)

echo.
echo  [+] Download complete. Registering with Ollama...
call :DoRegister "!DEST!" "!MODEL_NAME!"
echo.
pause
goto BackToMain

:: ================================================================
::  OPTION 3 - REGISTER A LOCAL GGUF FILE
:: ================================================================
:RegisterLocal
cls
echo.
echo  ==========================================
echo    Register a Local GGUF File
echo  ==========================================
echo.
echo  Use this to register a .gguf file that is already on your
echo  machine (on this USB or anywhere on your PC) with Ollama
echo  so it appears in AnythingLLM.
echo.
echo  WHERE TO LOOK:
echo    - This USB models folder : %MODELS_DIR%
echo    - Default HuggingFace cache : C:\Users\%USERNAME%\.cache\huggingface
echo    - Default Ollama models     : C:\Users\%USERNAME%\.ollama\models\blobs
echo    - LM Studio models          : C:\Users\%USERNAME%\.lmstudio\models
echo.

:: --- Scan USB models folder for unregistered GGUFs ---
echo  Scanning USB models folder for .gguf files...
echo.

:: Get list of already-registered model names from Ollama
"%OLLAMA_EXE%" list > "%TEMP%\ollama_list.txt" 2>nul

set "SCAN_IDX=0"
for /f "usebackq delims=" %%F in ('dir /b /s "%MODELS_DIR%\*.gguf" 2^>nul') do (
    set /a SCAN_IDX+=1
    set "SCAN_FILE_!SCAN_IDX!=%%F"
    set "SCAN_NAME_!SCAN_IDX!=%%~nF"
    echo    [!SCAN_IDX!]  %%~nxF
    echo          Path: %%F
    echo.
)

if %SCAN_IDX%==0 (
    echo  (No .gguf files found in %MODELS_DIR%)
    echo.
)

echo    [M]  Enter a path manually (for files elsewhere on this PC)
echo    [0]  Back
echo.
set "REGCHOICE="
set /p REGCHOICE="  Selection: "

if /i "!REGCHOICE!"=="0" goto BackToMain
if /i "!REGCHOICE!"=="M" goto RegisterManual

:: Validate numeric selection
set "GGUF_PATH="
if defined SCAN_FILE_!REGCHOICE! (
    set "GGUF_PATH=!SCAN_FILE_%REGCHOICE%!"
    set "GGUF_SUGGEST=!SCAN_NAME_%REGCHOICE%!"
) else (
    echo  Invalid selection.
    goto RegisterLocal
)

goto RegisterDoIt

:RegisterManual
echo.
echo  Paste the full path to the .gguf file.
echo  Example: C:\Users\Ravi\Downloads\llama-3.2.Q4_K_M.gguf
echo.
set "GGUF_PATH="
set /p GGUF_PATH="  Path: "
if "!GGUF_PATH!"=="" goto RegisterLocal

:: Strip surrounding quotes if user pasted them
set "GGUF_PATH=!GGUF_PATH:"=!"

if not exist "!GGUF_PATH!" (
    echo.
    echo  [!] File not found: !GGUF_PATH!
    echo      Check the path and try again.
    echo.
    pause
    goto RegisterLocal
)

:: Derive suggestion from filename
for %%F in ("!GGUF_PATH!") do set "GGUF_SUGGEST=%%~nF"

:RegisterDoIt
echo.
echo  File: !GGUF_PATH!
echo.
echo  Give this model a short name for Ollama/AnythingLLM.
echo  (Letters, numbers, hyphens only. No spaces.)
echo  Suggestion: !GGUF_SUGGEST!
echo.
set "REG_NAME="
set /p REG_NAME="  Model name (press Enter to use suggestion): "
if "!REG_NAME!"=="" set "REG_NAME=!GGUF_SUGGEST!"

call :DoRegister "!GGUF_PATH!" "!REG_NAME!"
echo.
pause
goto BackToMain

:: ================================================================
::  OPTION 4 - LIST MODELS
:: ================================================================
:ListModels
cls
echo.
echo  ==========================================
echo    All Models on this USB
echo  ==========================================
echo.

:: --- Ollama registered models ---
echo  REGISTERED WITH OLLAMA (usable in AnythingLLM):
echo  -------------------------------------------------
"%OLLAMA_EXE%" list 2>nul
if errorlevel 1 echo  (Could not reach Ollama server)
echo.

:: --- GGUF files on USB ---
echo  GGUF FILES IN %MODELS_DIR%:
echo  -------------------------------------------------
set "FOUND_GGUF=0"
for /f "usebackq delims=" %%F in ('dir /b /s "%MODELS_DIR%\*.gguf" 2^>nul') do (
    set "FOUND_GGUF=1"
    :: Get file size in MB via PowerShell
    for /f "usebackq delims=" %%S in (`powershell -NoProfile -Command "(Get-Item '%%F').Length / 1MB -as [int]"`) do (
        echo    %%~nxF  [%%S MB]
        echo    Path: %%F
        echo.
    )
)
if "!FOUND_GGUF!"=="0" echo  (none)
echo.

:: --- Models in C:\Users\..\.ollama (system Ollama) ---
echo  MODELS IN SYSTEM OLLAMA (C:\Users\%USERNAME%\.ollama\models):
echo  -------------------------------------------------
if exist "C:\Users\%USERNAME%\.ollama\models\manifests" (
    dir /b /s "C:\Users\%USERNAME%\.ollama\models\manifests" 2>nul | findstr /V "^$" || echo  (none)
) else (
    echo  (not found - system Ollama may not be installed)
)
echo.
pause
goto BackToMain

:: ================================================================
::  OPTION 5 - REMOVE MODEL
:: ================================================================
:RemoveModel
cls
echo.
echo  ==========================================
echo    Remove a Model
echo  ==========================================
echo.
echo  Currently registered Ollama models:
echo.
"%OLLAMA_EXE%" list
echo.
set "RM_MODEL="
set /p RM_MODEL="  Enter exact model name to remove (or 0 to go back): "
if "!RM_MODEL!"=="0" goto BackToMain
if "!RM_MODEL!"=="" goto RemoveModel

echo.
echo  [*] Removing !RM_MODEL! from Ollama...
"%OLLAMA_EXE%" rm !RM_MODEL!
if errorlevel 1 (
    echo  [!] Remove failed. Copy the name exactly from the list above.
) else (
    echo  [+] Removed from Ollama successfully.
    echo.
    echo  NOTE: If you also want to delete the .gguf file from disk,
    echo  find it in %MODELS_DIR% and delete it manually.
)
echo.
pause
goto BackToMain

:: ================================================================
::  SHARED SUBROUTINE - Register a GGUF file with Ollama
::  Usage: call :DoRegister "C:\path\to\file.gguf" "model-name"
:: ================================================================
:DoRegister
set "REG_GGUF_PATH=%~1"
set "REG_MODEL_NAME=%~2"

set "MODELFILE=%MODELS_DIR%\Modelfile_%REG_MODEL_NAME%"
echo FROM %REG_GGUF_PATH%     > "%MODELFILE%"
echo PARAMETER num_ctx 4096  >> "%MODELFILE%"

echo  [*] Registering "%REG_MODEL_NAME%" with Ollama...
"%OLLAMA_EXE%" create "%REG_MODEL_NAME%" -f "%MODELFILE%"

if errorlevel 1 (
    echo.
    echo  [!] Registration failed.
    echo      The .gguf file is at  : %REG_GGUF_PATH%
    echo      The Modelfile is at   : %MODELFILE%
    echo      Retry manually with:
    echo        ollama\ollama.exe create %REG_MODEL_NAME% -f "%MODELFILE%"
) else (
    echo.
    echo  [+] "%REG_MODEL_NAME%" registered successfully!
    echo      Select it in AnythingLLM ^> Settings ^> LLM ^> Ollama Model.
)
goto :eof

:: ================================================================
::  HELPERS
:: ================================================================
:BackToMain
cls
echo.
echo  ==========================================
echo    PORTABLE AI ^| Model Manager
echo  ==========================================
echo.
goto MainMenu

:Exit
if "%STARTED_SERVER%"=="1" (
    echo.
    echo  [*] Stopping temporary Ollama server...
    taskkill /F /IM ollama.exe >nul 2>&1
)
echo.
echo  Goodbye!
echo.
endlocal
exit /b 0
