#!/bin/zsh
# ================================================================
# PORTABLE AI - UPDATE PROCESSOR FOR MAC-OS
# ================================================================

USB="$(cd "$(dirname "$0")" && pwd)"

echo "==================================================="
echo "        PORTABLE AI - MAC UPDATE TOOL              "
echo "==================================================="
echo "Ensure all active core system running operations are terminated."
echo "Press ENTER to begin process..."
read -r

pkill -f "ollama serve" 2>/dev/null
pkill -f "AnythingLLM" 2>/dev/null

echo "Select operations index suite:"
echo " [1] AnythingLLM Instance Only"
echo " [2] Ollama Processing Core Only"
echo " [3] Execute Both Pipelines"
echo -n "Selection: "
read -r update_choice

if [ "$update_choice" = "1" ] || [ "$update_choice" = "3" ]; then
    echo "[*] Querying fresh AnythingLLM assets..."
    rm -rf "$USB/anythingllm/AnythingLLM.app"
    DMG_PATH="$USB/anythingllm/AnythingLLM.dmg"
    
    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ]; then
        curl -L "https://cdn.anythingllm.com/latest/AnythingLLMDesktop-Silicon.dmg" -o "$DMG_PATH"
    else
        curl -L "https://cdn.anythingllm.com/latest/AnythingLLMDesktop.dmg" -o "$DMG_PATH"
    fi
    
    MOUNT_POINT=$(mktemp -d /tmp/anythingllm-dmg.XXXXXX)
    hdiutil attach "$DMG_PATH" -mountpoint "$MOUNT_POINT" -nobrowse -quiet
    cp -R "$MOUNT_POINT/AnythingLLM.app" "$USB/anythingllm/"
    hdiutil detach "$MOUNT_POINT" -quiet
    rm -rf "$MOUNT_POINT" "$DMG_PATH"
    echo "[+] AnythingLLM app container refreshed."
fi

if [ "$update_choice" = "2" ] || [ "$update_choice" = "3" ]; then
    echo "[*] Querying fresh Ollama distribution layer..."
    OLLAMA_ZIP="$USB/ollama/ollama-darwin.zip"
    curl -L "https://ollama.com/download/ollama-darwin.zip" -o "$OLLAMA_ZIP"
    unzip -q -o "$OLLAMA_ZIP" -d "$USB/ollama/"
    rm -f "$OLLAMA_ZIP"
    chmod +x "$USB/ollama/ollama"
    echo "[+] Ollama engine binary update staged successfully."
fi

echo -e "\nProcess processing pipelines successfully run."
