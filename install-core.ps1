# ================================================================
# PORTABLE UNCENSORED AI - AUTOMATED USB SETUP SCRIPT
# ================================================================
# This script downloads and configures Anything LLM. Everything needed to run
# a fully private, portable AI from a USB drive.
# ================================================================

$USB_Drive = Split-Path -Parent $MyInvocation.MyCommand.Path

# Set OLLAMA_MODELS early so nothing leaks to C: drive during install
$env:OLLAMA_MODELS = "$USB_Drive\ollama\data"
$env:APPDATA       = "$USB_Drive\anythingllm_data\Roaming"
$env:LOCALAPPDATA  = "$USB_Drive\anythingllm_data\Local"
$env:USERPROFILE   = "$USB_Drive\anythingllm_data"

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Starting Automated Portable AI USB Setup!              " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------------
# STEP 1: Create folder structure
# -----------------------------------------------------------------
Write-Host "[1/3] Creating folders on USB drive..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$USB_Drive\ollama\data"                        | Out-Null
New-Item -ItemType Directory -Force -Path "$USB_Drive\anythingllm"                        | Out-Null
New-Item -ItemType Directory -Force -Path "$USB_Drive\anythingllm_data\Roaming"           | Out-Null
New-Item -ItemType Directory -Force -Path "$USB_Drive\anythingllm_data\Local"             | Out-Null
New-Item -ItemType Directory -Force -Path "$USB_Drive\models"
Write-Host "      Done." -ForegroundColor Green


# -----------------------------------------------------------------
# STEP 2: Download Ollama (the AI engine)
# -----------------------------------------------------------------
Write-Host ""
Write-Host "[2/3] Downloading Ollama AI Engine..." -ForegroundColor Yellow

$OllamaURL  = "https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip"
$OllamaDest = "$USB_Drive\ollama\ollama-windows-amd64.zip"

if (Test-Path "$USB_Drive\ollama\ollama.exe") {
    Write-Host "      Ollama already installed! Skipping..." -ForegroundColor Green
} else {
    Write-Host "      Downloading Ollama..." -ForegroundColor Magenta
    curl.exe -L --ssl-no-revoke --progress-bar $OllamaURL -o $OllamaDest

    if (-Not (Test-Path $OllamaDest)) {
        Write-Host "      ERROR: Ollama download failed. Check your internet connection." -ForegroundColor Red
        pause
        exit 1
    }

    Write-Host "      Extracting Ollama..." -ForegroundColor Yellow
    Expand-Archive -Path $OllamaDest -DestinationPath "$USB_Drive\ollama" -Force
    Remove-Item $OllamaDest -Force

    if (Test-Path "$USB_Drive\ollama\ollama.exe") {
        Write-Host "      Ollama Setup Complete!" -ForegroundColor Green
    } else {
        Write-Host "      ERROR: Ollama extraction failed. Try running setup again." -ForegroundColor Red
        pause
        exit 1
    }
}


# -----------------------------------------------------------------
# STEP 3: Download AnythingLLM (the chat interface)
# -----------------------------------------------------------------
Write-Host ""
Write-Host "[3/3] Downloading AnythingLLM Chat Interface..." -ForegroundColor Yellow

$AnythingLLMURL = "https://cdn.anythingllm.com/latest/AnythingLLMDesktop.exe"
$InstallerDest  = "$USB_Drive\anythingllm\AnythingLLMDesktop.exe"

if (Test-Path "$USB_Drive\anythingllm\AnythingLLM.exe") {
    Write-Host "      AnythingLLM already set up! Skipping..." -ForegroundColor Green
} else {
    # Download installer if not already present or is incomplete (<10 MB)
    if (-Not (Test-Path $InstallerDest) -or (Get-Item $InstallerDest).length -lt 10000000) {
        Write-Host "      Downloading AnythingLLM installer..." -ForegroundColor Magenta
        curl.exe -L --ssl-no-revoke --progress-bar $AnythingLLMURL -o $InstallerDest
    }

    if (-Not (Test-Path $InstallerDest)) {
        Write-Host "      ERROR: AnythingLLM download failed. Check your internet connection." -ForegroundColor Red
        pause
        exit 1
    }

    Write-Host "      Extracting AnythingLLM to USB (this takes 1-2 minutes)..." -ForegroundColor Magenta

    # Use 8.3 short path to avoid issues with spaces in folder names
    $ShortPath  = (New-Object -ComObject Scripting.FileSystemObject).GetFolder($USB_Drive).ShortPath
    $ExtractDir = "$ShortPath\anythingllm"

    Start-Process -FilePath $InstallerDest -ArgumentList "/S /D=$ExtractDir" -Wait

    if (Test-Path "$USB_Drive\anythingllm\AnythingLLM.exe") {
        Remove-Item $InstallerDest -Force -ErrorAction SilentlyContinue
        Write-Host "      AnythingLLM extracted and ready!" -ForegroundColor Green
    } else {
        Write-Host "" 
        Write-Host "      WARNING: Auto-extraction may have failed." -ForegroundColor Red
        Write-Host "      The installer is still at: $InstallerDest" -ForegroundColor Yellow
        Write-Host "      Please run it manually and install into: $USB_Drive\anythingllm" -ForegroundColor Yellow
        Write-Host ""
    }
}


# -----------------------------------------------------------------
# ALL DONE!
# -----------------------------------------------------------------
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   SETUP COMPLETE! YOUR PORTABLE AI IS READY!             " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  To start your AI: Double-click start-windows.bat" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to close this installer..." -ForegroundColor Yellow
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
