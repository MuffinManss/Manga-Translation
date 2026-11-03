# Manga Translation Glasses — Desktop Setup Guide
**PC: Windows + RTX 3080 | User: steve | D: drive used for all files**

---

## ✅ Quick Start — Run the Setup Script

The PowerShell script (`setup_manga_glasses.ps1`) handles everything automatically.

### Steps:
1. **Copy all 3 files to `D:\`** (or anywhere on D:):
   - `setup_manga_glasses.ps1`
   - `ocr_server.py`
   - `start_ocr_server.bat`

2. **Right-click PowerShell → Run as Administrator**

3. Run:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   cd D:\
   .\setup_manga_glasses.ps1
   ```

4. **The script will do ALL of this automatically:**

| Step | What happens |
|------|-------------|
| 1 | Checks Python version and PATH |
| 2 | Installs VS Code Remote-SSH extension |
| 3 | `pip install manga-ocr flask pillow` |
| 4+5 | Creates `D:\manga_ocr_server\ocr_server.py` and `.bat` |
| 6 | Creates startup shortcut in `shell:startup` |
| 7 | Displays your local IP address (put this in Pi script) |
| 8 | Adds Windows Firewall rule: Allow TCP 5050 Inbound |
| 9 | Syntax-checks the OCR server script |
| 10 | Downloads Raspberry Pi Imager to `D:\Downloads_MangaSetup\` |
| 11 | Downloads PuTTY installer to `D:\Downloads_MangaSetup\` |

---

## 📁 File Locations After Setup

```
D:\
├── manga_ocr_server\
│   ├── ocr_server.py              ← Flask OCR server (runs on port 5050)
│   ├── start_ocr_server.bat       ← Interactive launcher (shows console)
│   └── start_ocr_server_silent.bat ← Minimized launcher (used by auto-start)
│
└── Downloads_MangaSetup\
    ├── imager_latest.exe           ← Raspberry Pi Imager installer
    ├── putty-installer.msi         ← PuTTY SSH client
    └── setup_log.txt               ← Log of what the script did
```

```
C:\Users\steve\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\
└── MangaOCRServer.lnk              ← Auto-start shortcut (created by script)
```

---

## 🧪 Testing the OCR Server

After the script finishes, open a terminal and run:
```
cd D:\manga_ocr_server
python ocr_server.py
```

**First run:** Downloads the ~440MB OCR model from HuggingFace. Just let it run.

**Expected output:**
```
Loading OCR model...
OCR server ready on port 5050
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:5050
```

---

## 🌐 Your Desktop IP (for the Pi script)

The script will display your IP at Step 7 and in the final summary.
It's usually something like `192.168.1.x` or `192.168.0.x`.

In your Pi script, set:
```python
OCR_SERVER_IP = "192.168.x.x"   # ← replace with YOUR IP from Step 7
OCR_SERVER_PORT = 5050
```

---

## 📡 VS Code Remote SSH (connecting to Pi later)

Once your Pi is set up with SSH enabled:
1. Open VS Code
2. Press `Ctrl+Shift+P` → type `Remote-SSH: Connect to Host`
3. Enter: `pi@192.168.x.x` (or `pi@raspberrypi.local`)
4. You're now editing files directly on the Pi from your desktop

---

## 🔧 Manual Steps (if script can't do them)

### If Python isn't installed:
- Download: https://python.org/downloads/release/python-3119/
- Install to `D:\Python311` to save space on C:
- CHECK "Add Python to PATH" during installation

### If VS Code Remote-SSH extension install fails:
- Open VS Code → `Ctrl+Shift+X`
- Search: `Remote - SSH`
- Click Install on `ms-vscode-remote.remote-ssh`

### If firewall rule wasn't added:
- Windows Defender Firewall → Advanced Settings
- Inbound Rules → New Rule
- Type: Port → TCP → Port 5050 → Allow → All profiles → Name: MangaOCR-Port5050

### If Pi Imager download failed:
- https://www.raspberrypi.com/software/

### If PuTTY download failed:
- https://www.putty.org → Windows 64-bit MSI
- Install with: `msiexec /i putty-installer.msi`

---

## 🚀 What's Next (when Pi arrives)

1. Use **Raspberry Pi Imager** to flash Raspberry Pi OS Lite (64-bit) to SD card
   - In Imager settings: enable SSH, set username/password, set WiFi credentials
2. Boot Pi, find its IP via router or `ping raspberrypi.local`
3. SSH in with PuTTY or Windows Terminal: `ssh pi@<pi-ip>`
4. Install Pi-side camera/glasses script on the Pi
5. Set `OCR_SERVER_IP` in Pi script to your desktop IP from Step 7
6. The Pi captures images → sends to desktop OCR server → gets text back

---

*Generated for Manga Translation Glasses project — Desktop setup phase*
