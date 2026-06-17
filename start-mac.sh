#!/bin/zsh
# ================================================================
# PORTABLE AI - LAUNCHER FOR MAC-OS
# ================================================================

USB="$(cd "$(dirname "$0")" && pwd)"
OLLAMA_EXE="$USB/ollama/ollama"
OLLAMA_DATA="$USB/ollama/data"
DATA="$USB/anythingllm_data"
LOG_OLLAMA="$DATA/ollama.log"
LOG_APP="$DATA/anythingllm.log"

export OLLAMA_MODELS="$OLLAMA_DATA"
export OLLAMA_HOST="127.0.0.1:11434"

echo "==================================================="
echo "        Portable AI - Mac Launcher                 "
echo "==================================================="

# Pre-flight check
if [ ! -f "$OLLAMA_EXE" ] || [ ! -d "$USB/anythingllm/AnythingLLM.app" ]; then
    echo -e "\n[!] ERROR: App structures not found. Run ./install.sh first.\n"
    exit 1
fi

echo "[*] Cleaning up leftover instances..."
pkill -f "ollama serve" 2>/dev/null
pkill -f "AnythingLLM" 2>/dev/null
sleep 2

mkdir -p "$DATA"
> "$LOG_OLLAMA"
> "$LOG_APP"

# --- Watcher Sub-Process Loop ---
run_watcher() {
    while true; do
        sleep 10
        if ! pgrep -f "$OLLAMA_EXE serve" > /dev/null; then
            OLLAMA_MODELS="$OLLAMA_DATA" OLLAMA_HOST="127.0.0.1:11434" "$OLLAMA_EXE" serve >> "$LOG_OLLAMA" 2>&1 &
        fi
    done
}

# --- Booting Services ---
echo "[*] Initializing Ollama server locally..."
"$OLLAMA_EXE" serve >> "$LOG_OLLAMA" 2>&1 &
OLLAMA_PID=$!

echo "[*] Waiting for server API handshake..."
ATTEMPTS=0
while [ $ATTEMPTS -lt 30 ]; do
    if curl -s http://127.0.0.1:11434/api/version >/dev/null; then
        echo "[+] Ollama environment accepted connection."
        break
    fi
    printf "."
    sleep 1
    ATTEMPTS=$((ATTEMPTS+1))
done

# Run background watcher thread
run_watcher &
WATCHER_PID=$!

echo "[*] Opening localized AnythingLLM client container..."
# Passing direct standard storage directory modifications directly into Electron context
ELECTRON_RUN_AS_NODE=1 "$USB/anythingllm/AnythingLLM.app/Contents/MacOS/AnythingLLM" --user-data-dir="$DATA" >> "$LOG_APP" 2>&1 &
APP_PID=$!

echo -e "\n---------------------------------------------------"
echo "   AI Ecosystem Active. Streamed telemetry below."
echo "   Press [CTRL+C] in this terminal window to exit safely."
echo "---------------------------------------------------"

# Inline log printing translation (Replaces tail engine loop)
tail -f "$LOG_OLLAMA" "$LOG_APP" &
TAIL_PID=$!

# Trap intercept cleanly kills all children recursively on close
cleanup() {
    echo -e "\n[*] Terminating services down safely..."
    kill $WATCHER_PID $TAIL_PID 2>/dev/null
    pkill -f "$OLLAMA_EXE serve" 2>/dev/null
    kill $APP_PID 2>/dev/null
    echo "[+] Done."
    exit 0
}
trap cleanup INT TERM

wait
