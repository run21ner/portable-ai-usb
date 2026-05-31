#!/bin/bash
# ===================================================
#        PORTABLE AI - UPDATE TOOL (MAC)
# ===================================================

USB_PATH="$(cd "$(dirname "$0")" && pwd)"

echo "==================================================="
echo "       PORTABLE AI - UPDATE TOOL"
echo "==================================================="
echo ""
echo "This will update AnythingLLM and/or Ollama to the"
echo "latest versions. Your chats and settings are safe."
echo ""
echo "Make sure the AI is NOT running before continuing!"
echo ""
read -p "Press ENTER to continue..."

# 1. Kill anything still running
echo "[*] Stopping any running processes..."
pkill -f "ollama" 2>/dev/null
pkill -f "AnythingLLM" 2>/dev/null
sleep 2
echo "[+] Done."

echo ""
echo "What would you like to update?"
echo ""
echo "1) AnythingLLM only"
echo "2) Ollama only"
echo "3) Both"
echo ""
read -p "Selection: " choice

# -------------------------------------------------------
# UPDATE ANYTHINGLLM
# -------------------------------------------------------
update_anythingllm() {
    echo ""
    echo "[*] Downloading latest AnythingLLM for Mac..."
    INSTALLER="$USB_PATH/anythingllm/AnythingLLMDesktop.dmg"
    curl -L --progress-bar "https://cdn.anythingllm.com/latest/AnythingLLMDesktop-x86_64.dmg" -o "$INSTALLER"

    if [ ! -f "$INSTALLER" ]; then
        echo "[!] ERROR: Download failed. Check your internet connection."
        return 1
    fi

    echo "[*] Mounting installer..."
    MOUNT_POINT=$(hdiutil attach "$INSTALLER" | grep Volumes | awk '{print $3}')

    if [ -z "$MOUNT_POINT" ]; then
        echo "[!] ERROR: Could not mount DMG."
        return 1
    fi

    echo "[*] Installing over existing version..."
    rm -rf "$USB_PATH/anythingllm/AnythingLLM.app" 2>/dev/null
    cp -R "$MOUNT_POINT/AnythingLLM.app" "$USB_PATH/anythingllm/"

    hdiutil detach "$MOUNT_POINT" >dev/null 2>&1
    rm -f "$INSTALLER"

    if [ -d "$USB_PATH/anythingllm/AnythingLLM.app" ]; then
        echo "[+] AnythingLLM updated successfully!"
    else
        echo "[!] ERROR: Could not verify update."
    fi
}

# -------------------------------------------------------
# UPDATE OLLAMA
# -------------------------------------------------------
update_ollama() {
    echo ""
    echo "[*] Downloading latest Ollama for Mac..."
    OLLAMA_ZIP="$USB_PATH/ollama/ollama-update.zip"
    curl -L --progress-bar "https://github.com/ollama/ollama/releases/latest/download/ollama-darwin.zip" -o "$OLLAMA_ZIP"

    if [ ! -f "$OLLAMA_ZIP" ]; then
        echo "[!] ERROR: Download failed. Check your internet connection."
        return 1
    fi

    echo "[*] Extracting Ollama..."
    unzip -o "$OLLAMA_ZIP" -d "$USB_PATH/ollama/" >dev/null 2>&1
    chmod +x "$USB_PATH/ollama/ollama"
    rm -f "$OLLAMA_ZIP"

    if [ -f "$USB_PATH/ollama/ollama" ]; then
        echo "[+] Ollama updated successfully!"
    else
        echo "[!] ERROR: Ollama extraction failed."
    fi
}

case "$choice" in
    1) update_anythingllm ;;
    2) update_ollama ;;
    3) update_anythingllm; update_ollama ;;
    *) echo "Invalid selection." ;;
esac

echo ""
echo "==================================================="
echo "        ALL DONE!"
echo "==================================================="
echo ""
echo "Launch the AI anytime with start-mac.command"
echo ""
read -p "Press ENTER to close..."
