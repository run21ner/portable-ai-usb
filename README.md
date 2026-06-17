# 🔒 Portable-AI-USB

> A fully private, portable AI assistant that runs 100% from a USB flash drive.  
> No installation. No internet after setup. No data leaves the drive. Works on **Windows** and **Mac**.

---

## ⚡ What's Inside

| Component | Purpose |
|-----------|---------|
| **[Ollama](https://ollama.com)** | Lightweight engine that runs AI models locally |
| **[AnythingLLM](https://anythingllm.com)** | Clean chat interface with workspace support |
| **Your model of choice** | Any model supported by Ollama (e.g. LLaMA 3, Mistral, Phi-3) |

Everything — the engine, the interface, your chats, and the model — lives on the USB drive.

---

## 🛠️ Requirements

- USB drive with **at least 16 GB free** (32 GB recommended)
- Format the USB as **exFAT** (cross-platform: works on Windows and Mac)
- Internet connection for the **initial setup only** (~2–3 GB download)

---

## 🚀 Setup (One Time Only)

### Windows

1. Copy all files from this repo to the **root of your USB drive**
2. Double-click **`install.bat`** on the USB drive
3. Wait for the downloads to finish (~15–30 minutes depending on your connection)
4. Once complete, you're ready — no reboot needed

### Mac

1. Open **Terminal** in the project folder and make the scripts executable by running:
   ```bash
   chmod +x *.sh
---

## ▶️ How to Use

### Windows
1. Double-click **`start-windows.bat`**
2. A terminal window will open — keep it running while you chat
3. The AnythingLLM interface will launch automatically
4. Press `Ctrl+C` in the terminal when done, then follow the shutdown prompt

### Mac
1. Double-click **`start-mac.sh`**
2. First launch: it auto-downloads the Mac engine (~2 min)
3. The AnythingLLM window opens automatically
4. Press `Enter` in the terminal to shut down safely

> ⚠️ **First launch on any new computer** may take 30–60 seconds to initialise.

---

## 🤖 Loading a Model

You can either download models from `https://huggingface.co/`

## Or

You can open AnythingLLM and connect it to Ollama at `http://localhost:11434`.

Then pull a model via the terminal (while Ollama is running):

```bash
# Example — swap for any model on https://ollama.com/library
ollama pull llama3
ollama pull mistral
ollama pull phi3
```

The model will be saved to the USB drive, not your computer.

> CPU-only: expect 10–30 seconds per response. GPU (if available) will be much faster.

---

## 🔄 Updating

### Windows
Double-click **`update.bat`** and choose what to update:
- `[1]` AnythingLLM only
- `[2]` Ollama only
- `[3]` Both

### Mac
Double-click **`update-mac.command`** and follow the same prompts.

Your chats and settings are never touched by updates.

---

## 🔐 Privacy

- **Zero footprint** — nothing is written to the host computer
- All AI data, models, chats, and settings stay on the USB
- Fully offline after initial setup
- No telemetry, no cloud sync, no tracking

---

## 📁 USB Drive Structure

```
USB Drive/
├── install.bat               ← Windows setup (run once)
├── install-core.ps1          ← Called by install.bat
├── start-windows.bat         ← Windows launcher
├── start-mac.command         ← Mac launcher
├── update.bat                ← Windows updater
├── update-mac.command        ← Mac updater
├── ollama/                   ← Ollama engine (Windows)
├── ollama_mac/               ← Ollama engine (Mac, auto-downloaded)
├── ollama/data/              ← AI model files
├── anythingllm/              ← AnythingLLM app (Windows)
├── anythingllm_mac/          ← AnythingLLM app (Mac)
└── anythingllm_data/         ← Your chats & settings (portable)
```
If you do not see these folders then do not worry as they will apear after you run the install file.

---

## ⚠️ Known Limitations

- USB 3.0 or faster is strongly recommended for acceptable load times
- AnythingLLM and Ollama are **third-party tools** — this repo only provides the glue scripts
- Model availability depends on your USB storage size

---

## 📜 License

MIT — see [LICENSE](LICENSE) for details.

**Third-party components:**
- Ollama — [MIT License](https://github.com/ollama/ollama/blob/main/LICENSE)
- AnythingLLM — [MIT License](https://github.com/Mintplex-Labs/anything-llm/blob/master/LICENSE)
- AI models — licensed individually by their respective authors (check [Ollama's library](https://ollama.com/library) for details)
