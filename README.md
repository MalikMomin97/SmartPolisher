# SmartPolisher ✍️✨

SmartPolisher is a lightweight, zero-dependency, native Windows background tool that instantly polishes the grammar, tone, spelling, and clarity of any highlighted text on your computer when you press `Ctrl + Alt + G`. 

It works seamlessly across all Windows applications including **Slack, Microsoft Teams, Outlook, Gmail, Web Browsers, Visual Studio Code, Word, and Notepad**.

---

## 🚀 Setup Instructions

### 1. Get a Gemini API Key
To use the tool, you will need a free Google Gemini API Key:
1. Go to [Google AI Studio](https://aistudio.google.com/).
2. Log in with your Google account.
3. Click **Get API key** and copy it.

### 2. Configure SmartPolisher
1. Open the [config.json](file:///D:/API-Projects/New%20folder/config.json) file in your editor (or double-click to open in Notepad).
2. Replace `"YOUR_GEMINI_API_KEY_HERE"` with your actual API key.
3. Save the file.

### 3. Run the Tool
- Double-click **[Start-SmartPolisher.bat](file:///D:/API-Projects/New%20folder/Start-SmartPolisher.bat)** to start the tool in the background.
- You will see a Windows system notification in the bottom-right corner saying: **"SmartPolisher is Ready"**.
- A small default application icon will appear in your system tray (bottom-right next to the clock).

---

## 💡 How to Use

1. **Highlight/select any text** you have typed anywhere on your computer (e.g. inside Slack, an email draft, or a document).
2. Press **`Ctrl + Alt + G`**.
3. You will see a notification: **"Polishing selected text..."**.
4. Within a second, the highlighted text will be replaced with perfect, professional grammar!
5. *Note: Your previous clipboard history is restored immediately after pasting, so you won't lose your copied items!*

---

## ⚙️ Customization

You can customize how the tool works by editing the [config.json](file:///D:/API-Projects/New%20folder/config.json) file:

- **`model_name`**: Change to another Gemini model if desired (e.g., `gemini-1.5-flash` or `gemini-2.5-flash`).
- **`system_prompt`**: Customize the editing style! For example, you can tell it to make your text sound like a formal email, a concise Slack message, or translate it into another language.
- **`hotkey`**: You can change the modifiers (e.g. using `Shift` or `Control`) or key (e.g. `P` instead of `G`) by updating the array. For example:
  ```json
  "hotkey": {
    "modifiers": ["Control", "Shift"],
    "key": "E"
  }
  ```
- **`enable_notifications`**: Set to `false` to suppress notifications.

*Note: Restart SmartPolisher after editing config.json for changes to take effect.*

---

## 🛑 How to Stop the Tool

- Right-click the **SmartPolisher** icon in your system tray and click **Exit**.
- Alternatively, double-click **[Stop-SmartPolisher.bat](file:///D:/API-Projects/New%20folder/Stop-SmartPolisher.bat)**.
