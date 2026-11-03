# ============================================================
#  Manga Translation Glasses - Desktop Setup Script
#  For: Windows PC (RTX 3080), Username: steve
#  All downloads & project files go to D:\ (C: is low on space)
#
#  HOW TO RUN:
#    1. Right-click PowerShell -> "Run as Administrator"
#    2. Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#    3. D:\manga_glasses\setup_manga_glasses.ps1
# ============================================================

$ErrorActionPreference = "Continue"
$ProjectPath   = "D:\manga_ocr_server"
$DownloadPath  = "D:\Downloads_MangaSetup"
$LogFile       = "$DownloadPath\setup_log.txt"

function Write-OK   { param($msg) Write-Host "  [OK]   $msg" -ForegroundColor Green;  Add-Content $LogFile "  OK:   $msg" -EA SilentlyContinue }
function Write-Warn { param($msg) Write-Host "  [WARN] $msg" -ForegroundColor Yellow; Add-Content $LogFile "  WARN: $msg" -EA SilentlyContinue }
function Write-Fail { param($msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red;    Add-Content $LogFile "  FAIL: $msg" -EA SilentlyContinue }
function Write-Info { param($msg) Write-Host "  $msg"        -ForegroundColor Cyan;   Add-Content $LogFile "  INFO: $msg" -EA SilentlyContinue }
function Write-Step { param($n, $msg) $line = "`n[$n] $msg"; Write-Host $line -ForegroundColor Yellow; Add-Content $LogFile $line -EA SilentlyContinue }

# Create directories
New-Item -ItemType Directory -Path $ProjectPath  -Force | Out-Null
New-Item -ItemType Directory -Path $DownloadPath -Force | Out-Null
"Setup log - $(Get-Date)" | Out-File $LogFile -Encoding UTF8

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "    Manga Translation Glasses - Desktop Setup             " -ForegroundColor Cyan
Write-Host "    All files saved to D:\  (conserving C: space)        " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan


# ============================================================
# [1] CHECK PYTHON
# ============================================================
Write-Step 1 "Checking Python installation..."

$pyVer = $null
try { $pyVer = (python --version 2>&1).ToString().Trim() } catch {}

if ($pyVer -match "Python 3\.11") {
    Write-OK "Python 3.11 found: $pyVer"
} elseif ($pyVer -match "Python 3\.(\d+)") {
    $minor = [int]$Matches[1]
    if ($minor -ge 8) {
        Write-Warn "Python 3.$minor found (3.11 recommended, but 3.$minor should work): $pyVer"
    } else {
        Write-Fail "Python 3.$minor is too old. Install 3.11 from python.org"
        Write-Info "Tip: Install to D:\Python311 to save space on C:"
    }
} else {
    Write-Fail "Python not found in PATH. Output: $pyVer"
    Write-Info "Install Python 3.11 from: https://python.org"
    Write-Info "During install: CHECK 'Add Python to PATH'"
    Write-Info "Install to D:\Python311 to save space on C:"
    Read-Host "`nPress Enter after installing Python, then re-run this script"
    exit 1
}

$pipVer = $null
try { $pipVer = (pip --version 2>&1).ToString().Trim() } catch {}
if ($pipVer -match "pip") {
    Write-OK "pip found: $pipVer"
} else {
    Write-Warn "pip not found. Try: python -m ensurepip --upgrade"
}


# ============================================================
# [2] VS CODE - REMOTE-SSH EXTENSION
# ============================================================
Write-Step 2 "Installing VS Code Remote-SSH extension..."

$codeCmd = Get-Command code -ErrorAction SilentlyContinue
if ($codeCmd) {
    Write-OK "VS Code found at: $($codeCmd.Source)"
    $extResult = code --install-extension ms-vscode-remote.remote-ssh 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Remote-SSH extension installed/verified"
    } else {
        Write-Warn "Extension install output: $extResult"
        Write-Info "If it says 'already installed' that is fine"
    }
} else {
    Write-Warn "'code' command not in PATH"
    Write-Info "In VS Code: Ctrl+Shift+X -> search 'Remote - SSH' -> Install"
    Write-Info "Extension ID: ms-vscode-remote.remote-ssh"
}


# ============================================================
# [3] PIP INSTALL
# ============================================================
Write-Step 3 "Installing manga-ocr, flask, and pillow..."
Write-Info "Note: The ~440MB OCR model downloads on FIRST server start, not now."

pip install manga-ocr flask pillow
if ($LASTEXITCODE -eq 0) {
    Write-OK "Packages installed: manga-ocr, flask, pillow"
} else {
    Write-Fail "pip install failed (exit code $LASTEXITCODE)"
    Write-Info "Try manually: pip install manga-ocr flask pillow"
}


# ============================================================
# [4+5] CREATE PROJECT FILES
# ============================================================
Write-Step "4+5" "Creating project files in $ProjectPath..."

$ocrPy = 'from flask import Flask, request, jsonify' + "`r`n"
$ocrPy += 'from manga_ocr import MangaOcr' + "`r`n"
$ocrPy += 'import PIL.Image, io' + "`r`n"
$ocrPy += "`r`n"
$ocrPy += 'app = Flask(__name__)' + "`r`n"
$ocrPy += 'print("Loading OCR model...")' + "`r`n"
$ocrPy += 'mocr = MangaOcr()' + "`r`n"
$ocrPy += 'print("OCR server ready on port 5050")' + "`r`n"
$ocrPy += "`r`n"
$ocrPy += "@app.route('/ocr', methods=['POST'])" + "`r`n"
$ocrPy += 'def ocr():' + "`r`n"
$ocrPy += '    img = PIL.Image.open(io.BytesIO(request.data))' + "`r`n"
$ocrPy += "    return jsonify({'text': mocr(img)})" + "`r`n"
$ocrPy += "`r`n"
$ocrPy += "if __name__ == '__main__':" + "`r`n"
$ocrPy += "    app.run(host='0.0.0.0', port=5050)" + "`r`n"

[System.IO.File]::WriteAllText("$ProjectPath\ocr_server.py", $ocrPy, [System.Text.Encoding]::UTF8)
Write-OK "Created: $ProjectPath\ocr_server.py"

$batFull = "@echo off`r`necho Starting Manga OCR Server...`r`ncd /d D:\manga_ocr_server`r`npython ocr_server.py`r`npause"
[System.IO.File]::WriteAllText("$ProjectPath\start_ocr_server.bat", $batFull, [System.Text.Encoding]::ASCII)
Write-OK "Created: $ProjectPath\start_ocr_server.bat"

$batSilent = "@echo off`r`ncd /d D:\manga_ocr_server`r`nstart /min cmd /c python ocr_server.py"
[System.IO.File]::WriteAllText("$ProjectPath\start_ocr_server_silent.bat", $batSilent, [System.Text.Encoding]::ASCII)
Write-OK "Created: $ProjectPath\start_ocr_server_silent.bat (used by auto-start)"


# ============================================================
# [6] STARTUP SHORTCUT
# ============================================================
Write-Step 6 "Creating Windows startup shortcut..."

$StartupFolder = [System.Environment]::GetFolderPath("Startup")
$ShortcutPath  = "$StartupFolder\MangaOCRServer.lnk"
try {
    $WS = New-Object -ComObject WScript.Shell
    $SC = $WS.CreateShortcut($ShortcutPath)
    $SC.TargetPath       = "cmd.exe"
    $SC.Arguments        = "/c `"D:\manga_ocr_server\start_ocr_server_silent.bat`""
    $SC.WorkingDirectory = $ProjectPath
    $SC.Description      = "Manga OCR Server - Auto-start on login"
    $SC.WindowStyle      = 7
    $SC.Save()
    Write-OK "Startup shortcut created: $ShortcutPath"
} catch {
    Write-Fail "Could not create shortcut: $_"
    Write-Info "Manually: Win+R -> shell:startup -> put start_ocr_server.bat shortcut there"
}


# ============================================================
# [7] LOCAL IP ADDRESS
# ============================================================
Write-Step 7 "Finding your local IP address..."

$allIPs = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notmatch '^127\.' -and $_.IPAddress -notmatch '^169\.254\.' } |
    Sort-Object InterfaceIndex

$bestIP = $null
foreach ($ipObj in $allIPs) {
    $adapter     = Get-NetAdapter | Where-Object { $_.ifIndex -eq $ipObj.InterfaceIndex } -EA SilentlyContinue
    $adapterName = if ($adapter) { $adapter.Name } else { "Interface $($ipObj.InterfaceIndex)" }
    $adapterStat = if ($adapter) { $adapter.Status } else { "Unknown" }
    Write-Host "  -> $($ipObj.IPAddress.PadRight(18)) ($adapterName, $adapterStat)" -ForegroundColor Green

    if ($adapterStat -eq 'Up' -and -not $bestIP) {
        if ($ipObj.IPAddress -match '^192\.168\.' -or
            $ipObj.IPAddress -match '^10\.'        -or
            $ipObj.IPAddress -match '^172\.(1[6-9]|2\d|3[01])\.') {
            $bestIP = $ipObj.IPAddress
        }
    }
}

if ($bestIP) {
    Write-Host ""
    Write-Host "  *** YOUR DESKTOP IP: $bestIP ***" -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "  Use this as OCR_SERVER_IP in your Pi script" -ForegroundColor Cyan
    Add-Content $LogFile "  DESKTOP IP: $bestIP"
} else {
    Write-Warn "Could not auto-detect primary LAN IP - check the list above"
}


# ============================================================
# [8] FIREWALL RULE
# ============================================================
Write-Step 8 "Adding Windows Firewall inbound rule for TCP port 5050..."

$existingRule = Get-NetFirewallRule -DisplayName "MangaOCR-Port5050" -EA SilentlyContinue
if ($existingRule) {
    Write-OK "Firewall rule already exists"
} else {
    try {
        New-NetFirewallRule `
            -DisplayName "MangaOCR-Port5050" `
            -Direction   Inbound `
            -Protocol    TCP `
            -LocalPort   5050 `
            -Action      Allow `
            -Profile     Any `
            -Description "Allow Manga OCR Flask server port 5050 for Raspberry Pi" | Out-Null
        Write-OK "Firewall rule created: Allow TCP 5050 Inbound (all profiles)"
    } catch {
        Write-Fail "Could not add firewall rule: $_"
        Write-Info "Manually: Windows Defender Firewall -> Advanced -> New Inbound Rule -> TCP 5050"
    }
}


# ============================================================
# [9] SYNTAX CHECK OCR SERVER
# ============================================================
Write-Step 9 "Syntax-checking ocr_server.py..."

$pyScript = "$ProjectPath\ocr_server.py"
$checkCmd = "import ast; src=open(r'" + $pyScript + "').read(); ast.parse(src); print('PASS')"
$syntaxResult = python -c $checkCmd 2>&1

if ("$syntaxResult" -like "*PASS*") {
    Write-OK "ocr_server.py syntax is valid"
    Write-Info "To do a full test (downloads ~440MB model on first run):"
    Write-Info "  cd D:\manga_ocr_server"
    Write-Info "  python ocr_server.py"
    Write-Info "  -> Should print: OCR server ready on port 5050"
} else {
    Write-Warn "Syntax check output: $syntaxResult"
    Write-Info "You can still test manually: cd D:\manga_ocr_server && python ocr_server.py"
}


# ============================================================
# [10] DOWNLOAD RASPBERRY PI IMAGER
# ============================================================
Write-Step 10 "Downloading Raspberry Pi Imager to $DownloadPath..."

$piDest = "$DownloadPath\imager_latest.exe"
if (Test-Path $piDest) {
    Write-OK "Already downloaded: $piDest"
} else {
    $piURLs = @(
        "https://downloads.raspberrypi.com/imager/imager_latest.exe",
        "https://downloads.raspberrypi.org/imager/imager_latest.exe"
    )
    $dlOK = $false
    foreach ($url in $piURLs) {
        try {
            Write-Host "  Trying: $url" -ForegroundColor Gray
            Invoke-WebRequest -Uri $url -OutFile $piDest -UseBasicParsing -TimeoutSec 120
            $dlOK = $true; break
        } catch { continue }
    }
    if ($dlOK) {
        $sz = [math]::Round((Get-Item $piDest).Length / 1MB, 1)
        Write-OK "Downloaded Pi Imager (${sz} MB) -> $piDest"
        Write-Info "Run it to install"
    } else {
        Write-Warn "Auto-download failed"
        Write-Info "Download manually: https://www.raspberrypi.com/software/"
    }
}


# ============================================================
# [11] DOWNLOAD PUTTY
# ============================================================
Write-Step 11 "Downloading PuTTY SSH client to $DownloadPath..."

$puttyDest = "$DownloadPath\putty-installer.msi"
if (Test-Path $puttyDest) {
    Write-OK "Already downloaded: $puttyDest"
} else {
    $puttyURLs = @(
        "https://the.earth.li/~sgtatham/putty/latest/w64/putty-64bit-0.82-installer.msi",
        "https://the.earth.li/~sgtatham/putty/latest/w64/putty-64bit-0.81-installer.msi",
        "https://the.earth.li/~sgtatham/putty/latest/w64/putty-installer.msi"
    )
    $dlOK = $false
    foreach ($url in $puttyURLs) {
        try {
            Write-Host "  Trying: $url" -ForegroundColor Gray
            Invoke-WebRequest -Uri $url -OutFile $puttyDest -UseBasicParsing -TimeoutSec 60
            $dlOK = $true; break
        } catch { continue }
    }
    if ($dlOK) {
        $sz = [math]::Round((Get-Item $puttyDest).Length / 1MB, 1)
        Write-OK "Downloaded PuTTY (${sz} MB) -> $puttyDest"
        Write-Info "Install with: msiexec /i `"$puttyDest`""
    } else {
        Write-Warn "Auto-download failed"
        Write-Info "Download manually: https://www.putty.org"
    }
}


# ============================================================
# FINAL SUMMARY
# ============================================================
$finalIP = if ($bestIP) { $bestIP } else { "(see Step 7 output above)" }

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "                    SETUP COMPLETE                       " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Project files:  D:\manga_ocr_server\"
Write-Host "  Downloads:      D:\Downloads_MangaSetup\"
Write-Host "  Log:            D:\Downloads_MangaSetup\setup_log.txt"
Write-Host "  OCR port:       5050 (firewall rule added)"
Write-Host ""
Write-Host "  *** YOUR DESKTOP IP: $finalIP ***" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host ""
Write-Host "  NEXT STEPS:" -ForegroundColor Yellow
Write-Host "  1. Install Pi Imager:  D:\Downloads_MangaSetup\imager_latest.exe"
Write-Host "  2. Install PuTTY:      msiexec /i D:\Downloads_MangaSetup\putty-installer.msi"
Write-Host "  3. Test OCR server:    cd D:\manga_ocr_server && python ocr_server.py"
Write-Host "     (First run downloads ~440MB model - just let it go)"
Write-Host "  4. Use the IP above in your Pi script as OCR_SERVER_IP"
Write-Host "  5. OCR server auto-starts minimized on every Windows login"
Write-Host ""

Add-Content $LogFile "Setup completed: $(Get-Date)"
Add-Content $LogFile "Final IP: $finalIP"

Write-Host "Press any key to exit..." -ForegroundColor Gray
try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch {}
