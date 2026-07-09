Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Save current script folder path
$ScriptDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($ScriptDir)) {
    $ScriptDir = Get-Location
}

# 1. Load config file
$ConfigFile = "$ScriptDir\config.json"
if (-not (Test-Path $ConfigFile)) {
    # If config does not exist, create a default one
    $defaultConfig = @{
        gemini_api_key = "YOUR_GEMINI_API_KEY_HERE"
        model_name = "gemini-3.1-flash-lite"
        system_prompt = "You are a professional editor. Improve the following text for grammar, spelling, clarity, and tone while preserving its original meaning. Keep the tone natural, professional, and friendly (suitable for Slack, email, and professional messaging). Do not add any conversational filler, notes, greetings, or explanations before or after the corrected text. Return ONLY the enhanced text itself."
        hotkey = @{
            modifiers = @("Control", "Alt")
            key = "G"
        }
        enable_notifications = $true
    }
    $defaultConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigFile -Encoding utf8
}

$config = Get-Content -Raw -Path $ConfigFile | ConvertFrom-Json

# Write PID file for process management
$PidFile = "$ScriptDir\smartpolisher.pid"
$PID | Out-File -FilePath $PidFile -Encoding ascii -Force

# Setup NotifyIcon first to allow early notification error messaging
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.SystemIcons]::Application
$notify.Text = "SmartPolisher (Ctrl+Alt+G)"
$notify.Visible = $true

function Show-Notification {
    param(
        [string]$Title,
        [string]$Message,
        [string]$IconType = "Info"
    )
    if ($config.enable_notifications -eq $true) {
        $tooltipIcon = [System.Windows.Forms.ToolTipIcon]::$IconType
        $notify.ShowBalloonTip(3000, $Title, $Message, $tooltipIcon)
    }
}

# Check if Gemini API key has been filled in
if ($config.gemini_api_key -eq "YOUR_GEMINI_API_KEY_HERE" -or [string]::IsNullOrEmpty($config.gemini_api_key)) {
    Show-Notification "Configuration Needed" "Please configure your Gemini API key in config.json. Opening file now..." "Warning"
    Start-Sleep -Seconds 2
    Start-Process notepad.exe -ArgumentList "`"$ConfigFile`""
    if (Test-Path $PidFile) { Remove-Item $PidFile -Force }
    $notify.Visible = $false
    [System.Windows.Forms.Application]::Exit()
    exit
}

# Define C# classes for hotkey handling and keyboard simulation
$csharpCode = @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class KeyboardHelper {
    [DllImport("user32.dll")]
    private static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, int dwExtraInfo);

    private const int KEYEVENTF_KEYUP = 0x0002;
    private const byte VK_CONTROL = 0x11;
    private const byte VK_MENU = 0x12; // Alt key
    private const byte VK_SHIFT = 0x10;
    private const byte VK_C = 0x43;
    private const byte VK_V = 0x56;

    public static void SimulateCopy() {
        // Release Alt, Control, Shift temporarily to avoid modifier conflicts
        keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, 0);
        keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0);
        keybd_event(VK_SHIFT, 0, KEYEVENTF_KEYUP, 0);

        // Press Ctrl + C
        keybd_event(VK_CONTROL, 0, 0, 0);
        keybd_event(VK_C, 0, 0, 0);
        System.Threading.Thread.Sleep(80);
        keybd_event(VK_C, 0, KEYEVENTF_KEYUP, 0);
        keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0);
    }

    public static void SimulatePaste() {
        // Release Alt, Control, Shift temporarily to avoid modifier conflicts
        keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, 0);
        keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0);
        keybd_event(VK_SHIFT, 0, KEYEVENTF_KEYUP, 0);

        // Press Ctrl + V
        keybd_event(VK_CONTROL, 0, 0, 0);
        keybd_event(VK_V, 0, 0, 0);
        System.Threading.Thread.Sleep(80);
        keybd_event(VK_V, 0, KEYEVENTF_KEYUP, 0);
        keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0);
    }
}

public class HotKeyForm : Form {
    [DllImport("user32.dll")]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll")]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    private const int WM_HOTKEY = 0x0312;
    private Action _callback;
    public bool IsRegistered { get; private set; }

    public HotKeyForm(uint modifiers, uint key, Action callback) {
        _callback = callback;
        IsRegistered = RegisterHotKey(this.Handle, 1, modifiers, key);
    }

    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_HOTKEY && m.WParam.ToInt32() == 1) {
            if (_callback != null) {
                _callback();
            }
        }
        base.WndProc(ref m);
    }

    protected override void Dispose(bool disposing) {
        UnregisterHotKey(this.Handle, 1);
        base.Dispose(disposing);
    }
}
"@

# Compile the C# helper code
Add-Type -TypeDefinition $csharpCode -ReferencedAssemblies "System.Windows.Forms", "System.Drawing"

# Parse hotkey modifiers
$modifiersValue = 0
foreach ($mod in $config.hotkey.modifiers) {
    switch ($mod.ToLower()) {
        "alt" { $modifiersValue = $modifiersValue -bor 0x0001 }
        "control" { $modifiersValue = $modifiersValue -bor 0x0002 }
        "ctrl" { $modifiersValue = $modifiersValue -bor 0x0002 }
        "shift" { $modifiersValue = $modifiersValue -bor 0x0004 }
        "win" { $modifiersValue = $modifiersValue -bor 0x0008 }
    }
}

# Parse key
try {
    $keyString = $config.hotkey.key
    $keyEnum = [System.Windows.Forms.Keys]::Parse([System.Windows.Forms.Keys], $keyString, $true)
    $keyValue = [int]$keyEnum
} catch {
    # Fallback to 'G' if parsing fails
    $keyValue = 0x47
}

# Define what happens when the hotkey is pressed
$callback = {
    # Show status
    Show-Notification "SmartPolisher" "Polishing selected text..." "Info"

    # Save original clipboard to restore it later
    $oldClipboard = [System.Windows.Forms.Clipboard]::GetText()
    [System.Windows.Forms.Clipboard]::Clear()

    # Simulate copy to grab selected text
    [KeyboardHelper]::SimulateCopy()
    Start-Sleep -Milliseconds 120 # Safe delay to let the OS write to the clipboard without lock contention

    $selectedText = [System.Windows.Forms.Clipboard]::GetText()
    
    # If clipboard is still empty, warn the user
    if ([string]::IsNullOrWhiteSpace($selectedText)) {
        Show-Notification "SmartPolisher" "No text selected! Please highlight the text you want to enhance first." "Warning"
        # Restore clipboard
        if ($oldClipboard) {
            [System.Windows.Forms.Clipboard]::SetText($oldClipboard)
        }
        return
    }

    # Call Gemini API
    try {
        $body = @{
            contents = @(
                @{
                    parts = @(
                        @{
                            text = "$($config.system_prompt)`n`nText to improve:`n$selectedText"
                        }
                    )
                }
            )
        } | ConvertTo-Json -Depth 10

        # Construct request headers and URL
        $headers = @{
            "Content-Type" = "application/json"
        }
        $url = "https://generativelanguage.googleapis.com/v1beta/models/$($config.model_name):generateContent?key=$($config.gemini_api_key)"
        
        # Invoke REST call
        $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -Headers $headers -ContentType "application/json; charset=utf-8"
        
        # Parse result
        if ($null -ne $response -and $null -ne $response.candidates -and $response.candidates.Count -gt 0) {
            $enhancedText = $response.candidates[0].content.parts[0].text
            if ($enhancedText) {
                # Trim LLM wrapper characters (e.g. trailing quotes or newlines)
                $enhancedText = $enhancedText.Trim()
                
                # Copy polished text to clipboard
                [System.Windows.Forms.Clipboard]::SetText($enhancedText)
                
                # Simulate paste
                [KeyboardHelper]::SimulatePaste()
                Start-Sleep -Milliseconds 150 # Safe delay to let application finish pasting before clipboard restoration
                
                Show-Notification "SmartPolisher" "Text enhanced successfully!" "Info"
            } else {
                throw "Gemini response was empty."
            }
        } else {
            throw "Invalid response format from Gemini API."
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Show-Notification "SmartPolisher Error" "Failed to enhance text. Error: $errMsg" "Error"
    }

    # Restore the user's original clipboard contents (important quality-of-life feature!)
    if ($oldClipboard) {
        [System.Windows.Forms.Clipboard]::SetText($oldClipboard)
    } else {
        [System.Windows.Forms.Clipboard]::Clear()
    }
}

# Create hotkey Form
$form = New-Object HotKeyForm $modifiersValue, $keyValue, $callback

if (-not $form.IsRegistered) {
    Show-Notification "SmartPolisher Error" "Could not register hotkey. It might be in use by another application." "Error"
    if (Test-Path $PidFile) { Remove-Item $PidFile -Force }
    $notify.Visible = $false
    [System.Windows.Forms.Application]::Exit()
    exit
}

# Build Tray Icon Context Menu
$contextMenu = New-Object System.Windows.Forms.ContextMenu
$exitMenuItem = New-Object System.Windows.Forms.MenuItem("Exit")
$exitMenuItem.Add_Click({
    if (Test-Path $PidFile) {
        Remove-Item $PidFile -Force
    }
    $notify.Visible = $false
    [System.Windows.Forms.Application]::Exit()
})
$contextMenu.MenuItems.Add($exitMenuItem)
$notify.ContextMenu = $contextMenu

# Show startup success notification
$modKeys = $config.hotkey.modifiers -join "+"
Show-Notification "SmartPolisher is Ready" "Running in background. Highlight text and press $modKeys+$($config.hotkey.key) to polish!" "Info"

# Start the WinForms Application event loop
[System.Windows.Forms.Application]::Run($form)
