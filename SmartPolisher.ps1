# 0. Hide the PowerShell console window programmatically to run silently in the background
$win32Code = @"
using System;
using System.Runtime.InteropServices;

public class ConsoleHelper {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    public static void HideConsole() {
        IntPtr hwnd = GetConsoleWindow();
        if (hwnd != IntPtr.Zero) {
            ShowWindow(hwnd, 0); // 0 = SW_HIDE
        }
    }
}
"@
Add-Type -TypeDefinition $win32Code
[ConsoleHelper]::HideConsole()

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
    # If config does not exist, create a default multi-mode one
    $defaultConfig = @{
        gemini_api_key = "YOUR_GEMINI_API_KEY_HERE"
        model_name = "gemini-3.1-flash-lite"
        enable_notifications = $true
        modes = @(
            @{
                name = "Standard"
                system_prompt = "You are a professional editor. Improve the following text for grammar, spelling, clarity, and tone while preserving its original meaning. Keep the tone natural, professional, and friendly (suitable for Slack, email, and professional messaging). Do not add any conversational filler, notes, greetings, or explanations before or after the corrected text. Return ONLY the enhanced text itself."
                hotkey = @{
                    modifiers = @("Control", "Alt")
                    key = "G"
                }
            },
            @{
                name = "Professional"
                system_prompt = "You are a professional editor. Rewrite the following text to make it highly professional, formal, and polite, suitable for business emails or communication with executives. Do not add any conversational filler, notes, greetings, or explanations before or after the corrected text. Return ONLY the polished text itself."
                hotkey = @{
                    modifiers = @("Control", "Alt")
                    key = "P"
                }
            },
            @{
                name = "Shorten"
                system_prompt = "You are a professional editor. Condense the following text to make it extremely concise and direct, suitable for quick Slack or Teams messages. Keep the core information but remove wordiness. Do not add conversational filler, notes, or explanations before or after the corrected text. Return ONLY the shortened text itself."
                hotkey = @{
                    modifiers = @("Control", "Alt")
                    key = "S"
                }
            },
            @{
                name = "Elaborate"
                system_prompt = "You are a professional editor. Expand the following text to make it more detailed, well-structured, and clear. Add professional phrasing and detail while keeping the original meaning. Do not add conversational filler, notes, or explanations before or after the corrected text. Return ONLY the expanded text itself."
                hotkey = @{
                    modifiers = @("Control", "Alt")
                    key = "E"
                }
            }
        )
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
$notify.Text = "SmartPolisher (Multi-Mode)"
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
using System.Collections.Generic;

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
    private Action<int> _callback;
    private List<int> _registeredIds = new List<int>();

    public HotKeyForm(Action<int> callback) {
        _callback = callback;
    }

    public bool AddHotKey(int id, uint modifiers, uint key) {
        bool success = RegisterHotKey(this.Handle, id, modifiers, key);
        if (success) {
            _registeredIds.Add(id);
        }
        return success;
    }

    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_HOTKEY) {
            int id = m.WParam.ToInt32();
            if (_callback != null) {
                _callback(id);
            }
        }
        base.WndProc(ref m);
    }

    protected override void Dispose(bool disposing) {
        foreach (int id in _registeredIds) {
            UnregisterHotKey(this.Handle, id);
        }
        base.Dispose(disposing);
    }
}
"@

# Compile the C# helper code
Add-Type -TypeDefinition $csharpCode -ReferencedAssemblies "System.Windows.Forms", "System.Drawing"

function Show-PromptDialog {
    param(
        [string]$Title = "SmartPolisher Custom Command"
    )
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(400, 160)
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.ShowInTaskbar = $false
    $form.TopMost = $true
    
    # Modern dark theme colors
    $form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $form.ForeColor = [System.Drawing.Color]::White

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Enter custom instruction for selected text:"
    $label.Location = New-Object System.Drawing.Point(15, 15)
    $label.Size = New-Object System.Drawing.Size(370, 20)
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(15, 40)
    $textBox.Size = New-Object System.Drawing.Size(355, 25)
    $textBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $textBox.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
    $textBox.ForeColor = [System.Drawing.Color]::White
    $textBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $form.Controls.Add($textBox)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "Execute"
    $btnOk.Location = New-Object System.Drawing.Point(185, 80)
    $btnOk.Size = New-Object System.Drawing.Size(85, 28)
    $btnOk.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btnOk.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnOk.FlatAppearance.BorderSize = 0
    $btnOk.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    $btnOk.ForeColor = [System.Drawing.Color]::White
    $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnOk)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = New-Object System.Drawing.Point(285, 80)
    $btnCancel.Size = New-Object System.Drawing.Size(85, 28)
    $btnCancel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $btnCancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnCancel.FlatAppearance.BorderSize = 1
    $btnCancel.FlatAppearance.BorderColor = [System.Drawing.Color]::Gray
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    $form.AcceptButton = $btnOk
    $form.CancelButton = $btnCancel

    $form.Add_Shown({
        $textBox.Focus()
    })

    $result = $form.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $textBox.Text
    }
    return $null
}

# Programmatically append Custom Command mode to config modes for hotkey registration
if ($null -ne $config -and $null -ne $config.modes) {
    $customMode = @{
        name = "Custom Command"
        system_prompt = "You are a professional assistant. Follow the user's custom instruction to transform the following text. Do not add any conversational filler, notes, greetings, or explanations before or after the modified text. Return ONLY the final transformed text."
        hotkey = @{
            modifiers = @("Control", "Alt")
            key = "C"
        }
        is_custom = $true
    }
    $customModeObj = $customMode | ConvertTo-Json | ConvertFrom-Json
    
    $tempList = New-Object System.Collections.Generic.List[System.Object]
    foreach ($m in $config.modes) {
        $tempList.Add($m)
    }
    $tempList.Add($customModeObj)
    $config.modes = $tempList.ToArray()
}

# Define what happens when a hotkey is pressed (receives the mode ID)
$callback = {
    param([int]$modeId)

    # 1. Resolve which mode was triggered (1-based index)
    $mode = $config.modes[$modeId - 1]
    if ($null -eq $mode) { return }

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

    # Show prompt dialog if this is a custom command!
    $customPrompt = $null
    if ($mode.is_custom -eq $true) {
        $customPrompt = Show-PromptDialog
        if ([string]::IsNullOrWhiteSpace($customPrompt)) {
            # User cancelled or entered empty
            if ($oldClipboard) {
                [System.Windows.Forms.Clipboard]::SetText($oldClipboard)
            }
            return
        }
        Show-Notification "SmartPolisher" "Processing custom command..." "Info"
    } else {
        # Show status notification for standard modes
        Show-Notification "SmartPolisher" "Polishing text ($($mode.name) mode)..." "Info"
    }

    # Call Gemini API
    try {
        $promptText = ""
        if ($mode.is_custom -eq $true) {
            $promptText = "$($mode.system_prompt)`n`nInstruction: $customPrompt`n`nText to transform:`n$selectedText"
        } else {
            $promptText = "$($mode.system_prompt)`n`nText to improve:`n$selectedText"
        }

        $body = @{
            contents = @(
                @{
                    parts = @(
                        @{
                            text = $promptText
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
                
                Show-Notification "SmartPolisher" "Polished ($($mode.name)) successfully!" "Info"
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
$form = New-Object HotKeyForm $callback

# Parse and register all modes
$successCount = 0
$index = 1
foreach ($mode in $config.modes) {
    # Parse hotkey modifiers
    $modifiersValue = 0
    foreach ($mod in $mode.hotkey.modifiers) {
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
        $keyString = $mode.hotkey.key
        $keyEnum = [System.Windows.Forms.Keys]::Parse([System.Windows.Forms.Keys], $keyString, $true)
        $keyValue = [int]$keyEnum
    } catch {
        # Fallback to key index-based or 'G'
        $keyValue = 0x47
    }

    # Register the hotkey
    $isReg = $form.AddHotKey($index, $modifiersValue, $keyValue)
    if ($isReg) {
        $successCount++
    } else {
        Show-Notification "SmartPolisher Warning" "Could not register hotkey for mode '$($mode.name)'." "Warning"
    }
    $index++
}

# If no hotkeys registered, exit
if ($successCount -eq 0) {
    Show-Notification "SmartPolisher Error" "Failed to register any shortcuts. Exiting." "Error"
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
$activeModes = @()
foreach ($m in $config.modes) {
    $modStr = $m.hotkey.modifiers -join "+"
    $activeModes += "$($m.name) ($modStr+$($m.hotkey.key))"
}
Show-Notification "SmartPolisher is Ready" "Active modes: $($activeModes -join ', ')" "Info"

# Start the WinForms Application event loop
[System.Windows.Forms.Application]::Run($form)
