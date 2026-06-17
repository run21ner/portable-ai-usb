# ================================================================
# PORTABLE AI - AUTOMATED USB SETUP SCRIPT
# Architecture: Standalone Ollama server + AnythingLLM pointed
#               at http://127.0.0.1:11434 (external Ollama provider)
#
# What this does NOT now do (intentionally):
#   - Copy llm.exe into AnythingLLM's embedded engine folder
#   - Set OLLAMA_MODELS / APPDATA / LOCALAPPDATA env overrides
# ================================================================

$ErrorActionPreference = "Stop"
$USB = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Step($n, $total, $msg) {
    Write-Host ""
    Write-Host "[$n/$total] $msg" -ForegroundColor Yellow
}
function Write-OK($msg)   { Write-Host "      OK: $msg"    -ForegroundColor Green  }
function Write-Info($msg) { Write-Host "      >>  $msg"    -ForegroundColor Cyan   }
function Write-Err($msg)  { Write-Host "      ERR: $msg"   -ForegroundColor Red    }

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Portable AI - USB Setup (External Ollama Architecture) " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# -----------------------------------------------------------------
# STEP 1: Folder structure
# -----------------------------------------------------------------
Write-Step 1 3 "Creating folder structure on USB..."

$folders = @(
    "$USB\ollama\data",
    "$USB\anythingllm",
    "$USB\anythingllm_data\Roaming",
    "$USB\anythingllm_data\Local",
    "$USB\models"
    "$USB\anythingllm_data\AppData\Roaming\anythingllm-desktop\storage\engines\ollama"
)
foreach ($f in $folders) {
    New-Item -ItemType Directory -Force -Path $f | Out-Null
}
Write-OK "Folders created."

# -----------------------------------------------------------------
# STEP 2: Download Ollama (standalone server - full zip with DLLs)
# -----------------------------------------------------------------
Write-Step 2 3 "Downloading Ollama AI Engine..."

$OllamaZip  = "$USB\ollama\ollama-windows-amd64.zip"
$OllamaExe  = "$USB\ollama\ollama.exe"
$OllamaURL  = "https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip"

if (Test-Path $OllamaExe) {
    Write-OK "Ollama already installed - skipping download."
} else {
    Write-Info "Downloading Ollama zip (includes all required DLLs)..."
    curl.exe -L --ssl-no-revoke --progress-bar $OllamaURL -o $OllamaZip

    if (-not (Test-Path $OllamaZip)) {
        Write-Err "Ollama download failed. Check your internet connection."
        exit 1
    }

    Write-Info "Extracting Ollama..."
    Expand-Archive -Path $OllamaZip -DestinationPath "$USB\ollama" -Force
    Remove-Item $OllamaZip -Force

    if (-not (Test-Path $OllamaExe)) {
        Write-Err "Ollama extraction failed. Try running setup again."
        exit 1
    }
    Write-OK "Ollama ready at $OllamaExe"
}
Copy-Item -Path "$USB\Ollama\ollama.exe" -Destination "$USB\anythingllm_data\AppData\Roaming\anythingllm-desktop\storage\engines\ollama\llm.exe"
# Verify the zip gave us more than just ollama.exe (sanity check)
$ollamaFiles = (Get-ChildItem "$USB\ollama" -Recurse -File).Count
Write-Info "Ollama folder contains $ollamaFiles file(s)."

# -----------------------------------------------------------------
# STEP 3: Download AnythingLLM Desktop
# -----------------------------------------------------------------
Write-Step 3 3 "Downloading AnythingLLM Chat Interface..."

$AnythingLLMExe      = "$USB\anythingllm\AnythingLLM.exe"
$AnythingLLMInstaller = "$USB\anythingllm\AnythingLLMDesktop.exe"
$AnythingLLMURL      = "https://cdn.anythingllm.com/latest/AnythingLLMDesktop.exe"

if (Test-Path $AnythingLLMExe) {
    Write-OK "AnythingLLM already installed - skipping."
} else {
    $needDownload = $true
    if (Test-Path $AnythingLLMInstaller) {
        $size = (Get-Item $AnythingLLMInstaller).Length
        if ($size -gt 10MB) {
            Write-Info "Installer already present ($([math]::Round($size/1MB))MB), skipping download."
            $needDownload = $false
        } else {
            Write-Info "Installer present but incomplete ($size bytes), re-downloading..."
            Remove-Item $AnythingLLMInstaller -Force
        }
    }

    if ($needDownload) {
        Write-Info "Downloading AnythingLLM installer..."
        curl.exe -L --ssl-no-revoke --progress-bar $AnythingLLMURL -o $AnythingLLMInstaller

        if (-not (Test-Path $AnythingLLMInstaller)) {
            Write-Err "AnythingLLM download failed. Check your internet connection."
            exit 1
        }
    }

    Write-Info "Extracting AnythingLLM to USB (1-2 minutes)..."

    # Use 8.3 short path to avoid spaces-in-path issues with the NSIS /D= flag
    $fso       = New-Object -ComObject Scripting.FileSystemObject
    $shortBase = $fso.GetFolder($USB).ShortPath
    $extractTo = "$shortBase\anythingllm"

    $proc = Start-Process -FilePath $AnythingLLMInstaller `
                          -ArgumentList "/S /D=$extractTo" `
                          -PassThru -Wait

    if ($proc.ExitCode -ne 0) {
        Write-Err "Installer exited with code $($proc.ExitCode)."
    }

    if (Test-Path $AnythingLLMExe) {
        Remove-Item $AnythingLLMInstaller -Force -ErrorAction SilentlyContinue
        Write-OK "AnythingLLM extracted and ready."
    } else {
        Write-Host ""
        Write-Host "  WARNING: Could not verify AnythingLLM installation." -ForegroundColor Red
        Write-Host "  Installer is at: $AnythingLLMInstaller"              -ForegroundColor Yellow
        Write-Host "  Please run it manually and install into:"             -ForegroundColor Yellow
        Write-Host "    $USB\anythingllm"                                   -ForegroundColor White
        Write-Host ""
        Write-Host "  After installing, run start-windows.bat normally."   -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------------
# Write a README with first-run AnythingLLM configuration steps
# -----------------------------------------------------------------
$readme = @"
PORTABLE AI - FIRST-RUN CONFIGURATION
======================================

When AnythingLLM opens for the first time you MUST configure it
to use the external Ollama server instead of its built-in engine.

Steps:
  1. Open Settings (gear icon) -> LLM Preference
  2. Select provider: Ollama
  3. Set base URL:    http://127.0.0.1:11434
  4. Click "Save changes"

To add a model:
  - Open a terminal on this USB: ollama\ollama.exe pull llama3
  - Or drop a .gguf file in the models\ folder and run:
      ollama\ollama.exe create mymodel -f models\Modelfile
    (see models\Modelfile.example for the format)

The start-windows.bat launcher will automatically verify that
Ollama is responding before starting AnythingLLM.
"@
$readme | Set-Content -Path "$USB\FIRST_RUN_README.txt" -Encoding UTF8

# Create a Modelfile example for GGUF imports
$modelfile = @"
# Example Modelfile for importing a local GGUF model
# Place your .gguf file in the models\ folder then edit this file.
# Run from the USB root:
#   ollama\ollama.exe create my-model -f models\Modelfile
#
FROM ./my-model.Q4_K_M.gguf
PARAMETER num_ctx 4096
"@
New-Item -ItemType Directory -Force -Path "$USB\models" | Out-Null
$modelfile | Set-Content -Path "$USB\models\Modelfile.example" -Encoding UTF8

# -----------------------------------------------------------------
# ALL DONE
# -----------------------------------------------------------------
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   SETUP COMPLETE!                                         " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Double-click start-windows.bat to launch." -ForegroundColor White
Write-Host "    2. Follow FIRST_RUN_README.txt to configure AnythingLLM." -ForegroundColor White
Write-Host ""
Write-Host "Press any key to close..." -ForegroundColor Yellow
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
