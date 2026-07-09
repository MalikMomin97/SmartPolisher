# SmartPolisher Automatic Installer & Shortcut Generator
# This script configures config.json and creates Desktop/Folder shortcuts dynamically for any user.

$ScriptDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($ScriptDir)) {
    $ScriptDir = Get-Location
}

Write-Host "=== SmartPolisher Setup ===" -ForegroundColor Cyan

# 1. Create config.json from example template if it doesn't exist
$ConfigFile = "$ScriptDir\config.json"
$ExampleFile = "$ScriptDir\config.example.json"

if (-not (Test-Path $ConfigFile)) {
    if (Test-Path $ExampleFile) {
        Copy-Item -Path $ExampleFile -Destination $ConfigFile
        Write-Host "[+] Created config.json from template." -ForegroundColor Green
    } else {
        Write-Host "[-] Error: config.example.json not found!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[*] config.json already exists. Skipping copy." -ForegroundColor Yellow
}

# 2. Programmatically generate Shortcuts with active folder paths
Write-Host "[*] Generating Windows Shortcuts..." -ForegroundColor Yellow

$WshShell = New-Object -ComObject WScript.Shell
$TargetScript = "$ScriptDir\SmartPolisher.ps1"

function Create-Shortcut {
    param(
        [string]$Path,
        [string]$IconPath = "shell32.dll",
        [int]$IconIndex = 137 # System Gear Icon
    )
    try {
        $Shortcut = $WshShell.CreateShortcut($Path)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$TargetScript`""
        $Shortcut.WorkingDirectory = $ScriptDir
        $Shortcut.Description = "SmartPolisher AI-powered global text assistant (Ctrl+Alt+G/P/S/E/C)"
        $Shortcut.IconLocation = "$IconPath, $IconIndex"
        $Shortcut.Save()
        Write-Host "[+] Shortcut created: $Path" -ForegroundColor Green
    } catch {
        Write-Host "[-] Failed to create shortcut at $Path. Error: $_" -ForegroundColor Red
    }
}

# Create local folder shortcut
Create-Shortcut -Path "$ScriptDir\SmartPolisher.lnk"

# Create Desktop shortcut
$DesktopPath = [System.Environment]::GetFolderPath("Desktop")
if ($DesktopPath) {
    Create-Shortcut -Path "$DesktopPath\SmartPolisher.lnk"
}

Write-Host "`n=== Setup Complete! ===" -ForegroundColor Cyan
Write-Host "1. Open 'config.json' and enter your Gemini API key." -ForegroundColor White
Write-Host "2. Double-click the 'SmartPolisher' icon on your Desktop to start using it!" -ForegroundColor White
