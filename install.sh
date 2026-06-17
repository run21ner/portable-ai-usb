#!/bin/zsh
# ================================================================
# PORTABLE AI - AUTOMATED MAC SETUP SCRIPT
# Architecture: Standalone Ollama server + AnythingLLM Desktop
# ================================================================

# Color definitions
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

USB="$(cd "$(dirname "$0")" && pwd)"

write_step() { echo -e "\n${YELLOW}[$1/$2] $3${NC}" }
write_ok()   { echo -e "      ${GREEN}OK: $1${NC}" }
write_info() { echo -e "      ${CYAN}>> $1${NC}" }
write_err()  { echo -e "      ${RED}ERR: $1${NC}" }

echo -e "${CYAN}=========================================================="
echo "   Portable AI - Mac USB Setup (Standalone Architecture)  "
echo -e "==========================================================${NC}"
echo "This will download everything you need onto this USB drive."
echo "Total download size: ~1.5 GB. Ensure your connection is stable."
echo "Press ENTER to continue..."
read -r

# --- STEP 1: Folder Structure ---
write_step 1 3 "Creating folder structure on USB..."
mkdir -p "$USB/ollama/data"
mkdir -p "$USB/anythingllm"
mkdir -p "$USB/anythingllm_data"
mkdir -p "$USB/models"
write_ok "Folders created."

# --- STEP 2: Download Ollama ---
write_step 2 3 "Downloading Ollama AI Engine for Mac..."
OLLAMA_ZIP="$USB/ollama/ollama-darwin.zip"
OLLAMA_EXE="$USB/ollama/ollama"

if [ -f "$OLLAMA_EXE" ]; then
    write_ok "Ollama already installed - skipping download."
else
    write_info "Downloading latest Ollama binary bundle..."
    curl -L --progress-bar "https://ollama.com/download/ollama-darwin.zip" -o "$OLLAMA_ZIP"
    
    if [ ! -f "$OLLAMA_ZIP" ]; then
        write_err "Ollama download failed."
        exit 1
    fi

    write_info "Extracting Ollama..."
    unzip -q -o "$OLLAMA_ZIP" -d "$USB/ollama/"
    rm -f "$OLLAMA_ZIP"
    
    if [ ! -f "$OLLAMA_EXE" ]; then
        write_err "Ollama extraction verification failed."
        exit 1
    fi
    chmod +x "$OLLAMA_EXE"
    write_ok "Ollama engine ready at $OLLAMA_EXE"
fi

# --- STEP 3: Download & Stage AnythingLLM ---
write_step 3 3 "Downloading AnythingLLM Mac Client..."
ANYTHINGLLM_APP="$USB/anythingllm/AnythingLLM.app"
DMG_PATH="$USB/anythingllm/AnythingLLM.dmg"

if [ -d "$ANYTHINGLLM_APP" ]; then
    write_ok "AnythingLLM App bundle already staged - skipping."
else
    write_info "Downloading AnythingLLM DMG build..."
    # Auto-detect Apple Silicon (M1/M2/M3) vs Intel to grab right framework
    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ]; then
        write_info "Detected Apple Silicon architecture..."
        curl -L --progress-bar "https://cdn.anythingllm.com/latest/AnythingLLMDesktop-Silicon.dmg" -o "$DMG_PATH"
    else
        write_info "Detected Intel x86 architecture..."
        curl -L --progress-bar "https://cdn.anythingllm.com/latest/AnythingLLMDesktop.dmg" -o "$DMG_PATH"
    fi

    if [ ! -f "$DMG_PATH" ]; then
        write_err "AnythingLLM installer download failed."
        exit 1
    fi

    write_info "Mounting disk image and staging application natively..."
    MOUNT_POINT=$(mktemp -d /tmp/anythingllm-dmg.XXXXXX)
    hdiutil attach "$DMG_PATH" -mountpoint "$MOUNT_POINT" -nobrowse -quiet
    
    cp -R "$MOUNT_POINT/AnythingLLM.app" "$USB/anythingllm/"
    
    hdiutil detach "$MOUNT_POINT" -quiet
    rm -rf "$MOUNT_POINT"
    rm -f "$DMG_PATH"

    if [ ! -d "$ANYTHINGLLM_APP" ]; then
        write_err "Failed to transfer app bundle from disk image."
        exit 1
    fi
    write_ok "AnythingLLM deployment structured successfully."
fi

echo -e "\n${CYAN}==========================================================${NC}"
echo -e "${GREEN}   SETUP COMPLETE! Ready to run.${NC}"
echo -e "${CYAN}==========================================================${NC}"
echo "  Next steps: Run ./start-mac.sh to initialize application ecosystem."
