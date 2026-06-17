#!/bin/zsh
# ================================================================
# PORTABLE AI | MODEL MANAGER FOR MAC-OS
# ================================================================

USB="$(cd "$(dirname "$0")" && pwd)"
OLLAMA_EXE="$USB/ollama/ollama"
OLLAMA_DATA="$USB/ollama/data"
MODELS_DIR="$USB/models"

export OLLAMA_MODELS="$OLLAMA_DATA"
export OLLAMA_HOST="127.0.0.1:11434"

if [ ! -f "$OLLAMA_EXE" ]; then
    echo "[!] ERROR: Run ./install.sh first."
    exit 1
fi
mkdir -p "$MODELS_DIR"

# Ensure server is active up front
if ! curl -s http://127.0.0.1:11434/api/version >/dev/null; then
    echo "[*] Waking local server context..."
    "$OLLAMA_EXE" serve >/dev/null 2>&1 &
    sleep 3
fi

do_register() {
    local filepath="$1"
    local modelname="$2"
    local modelfile="$MODELS_DIR/Modelfile_$modelname"
    
    echo "FROM $filepath" > "$modelfile"
    echo "PARAMETER num_ctx 4096" >> "$modelfile"
    
    echo "[*] Registering $modelname into context..."
    "$OLLAMA_EXE" create "$modelname" -f "$modelfile"
}

while true; do
    clear
    echo "=========================================="
    echo "  PORTABLE AI | Model Manager (macOS)"
    echo "=========================================="
    echo "  [1] Pull from Ollama Library"
    echo "  [2] Pull from HuggingFace (GGUF)"
    echo "  [3] Register local GGUF file"
    echo "  [4] List models"
    echo "  [5] Remove model"
    echo "  [0] Exit"
    echo -n "  Selection: "
    read -r choice

    case $choice in
        1)
            clear
            echo "Pulling from Official Library..."
            echo "Options: llama3.2, llama3.2:1b, mistral, deepseek-r1:1.5b"
            echo -n "Enter model configuration string: "
            read -r model
            if [ ! -z "$model" ]; then
                "$OLLAMA_EXE" pull "$model"
                echo "Press enter to return..."; read -r
            fi
            ;;
        2)
            clear
            echo "HuggingFace Interface Tool"
            echo -n "Paste explicit Repo URL (e.g., https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF): "
            read -r url
            repo_path="${url#https://huggingface.co/}"
            
            echo "[*] Parsing files via HF open API..."
            # Pull file index lists utilizing simple JSON scanning patterns
            files=$(curl -s "https://huggingface.co/api/models/$repo_path" | grep -o '"rfilename":"[^"]*\.gguf"' | cut -d'"' -f4)
            
            if [ -z "$files" ]; then
                echo "[!] No files encountered. Verify repo path structures."
                echo "Press enter..."; read -r
                continue
            fi
            
            echo "Available GGUF Files Found:"
            echo "$files" | awk '{print NR, $0}'
            echo -n "Enter index number to download: "
            read -r file_idx
            
            chosen_file=$(echo "$files" | sed -n "${file_idx}p")
            if [ ! -z "$chosen_file" ]; then
                dest_path="$MODELS_DIR/$chosen_file"
                echo "[*] Launching download connection stream..."
                curl -L "https://huggingface.co/$repo_path/resolve/main/$chosen_file" -o "$dest_path"
                
                clean_name=$(echo "$chosen_file" | tr '[:upper:]' '[:lower:]' | sed 's/\.gguf//g' | tr '_' '-')
                do_register "$dest_path" "$clean_name"
                echo "Complete. Press enter..."; read -r
            fi
            ;;
        3)
            clear
            echo "Register Local Target"
            # Lists internal models directory files automatically
            files=("$MODELS_DIR"/*.gguf(N))
            if [ ${#files} -gt 0 ]; then
                for i in {1..${#files}}; do
                    echo "[$i] $(basename ${files[$i]})"
                done
                echo -n "Select file number or type path manually (M): "
                read -r fchoice
                if [[ "$fchoice" =~ ^[0-9]+$ ]] && [ "$fchoice" -le ${#files} ]; then
                    target_file="${files[$fchoice]}"
                fi
            fi
            
            if [ -z "$target_file" ]; then
                echo -n "Paste absolute full Unix file path: "
                read -r target_file
            fi
            
            if [ -f "$target_file" ]; then
                echo -n "Give this model a short execution string identifier: "
                read -r m_name
                do_register "$target_file" "$m_name"
            else
                echo "[!] File target unresolved."
            fi
            echo "Press enter..."; read -r
            ;;
        4)
            clear
            "$OLLAMA_EXE" list
            echo "Press enter to continue..."; read -r
            ;;
        5)
            clear
            "$OLLAMA_EXE" list
            echo -n "Enter model string name to clear: "
            read -r rmodel
            "$OLLAMA_EXE" rm "$rmodel"
            echo "Target cleared. Press enter..."; read -r
            ;;
        0)
            exit 0
            ;;
    esac
done
