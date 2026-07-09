# SmartPolisher ✍️✨

SmartPolisher is a lightweight, zero-dependency, native Windows background utility that instantly polishes your writing or transforms highlighted text anywhere on your computer using global shortcuts.

It works seamlessly across all Windows applications including **Slack, Microsoft Teams, Outlook, Gmail, Web Browsers, Visual Studio Code, Word, and Notepad**.

---

## 🚀 Setup Instructions (For You and Others)

If you are sharing this tool with others, they only need to follow these 3 simple steps:

### 1. Download & Install
1. Clone this repository or download it as a ZIP file.
2. Extract the files and double-click **[Setup.bat](file:///D:/API-Projects/New%20folder/Setup.bat)**.
   * *This will automatically create a configuration file and generate a professional shortcut on your desktop!*

### 2. Get a Gemini API Key
To use the tool, you will need a free Google Gemini API Key:
1. Go to [Google AI Studio](https://aistudio.google.com/).
2. Log in with your Google account.
3. Click **Get API key** and copy it.

### 3. Add Key & Run
1. Open the newly created `config.json` file in your folder.
2. Replace `"YOUR_GEMINI_API_KEY_HERE"` with your actual API key and save.
3. Double-click the **SmartPolisher** shortcut on your **Desktop** to start the app in the background!

---

## 💡 How to Use (Shortcuts)

Highlight any text on your screen and press one of the following shortcuts:

| Shortcut | Action Mode | Description |
| :--- | :--- | :--- |
| **`Ctrl + Alt + G`** | **Standard** | Corrects grammar, typos, and makes your text polite and friendly. |
| **`Ctrl + Alt + P`** | **Professional** | Rewrites your text to sound executive, formal, and business-ready. |
| **`Ctrl + Alt + S`** | **Shorten** | Condenses text to make it extremely concise (perfect for Slack/Teams). |
| **`Ctrl + Alt + E`** | **Elaborate** | Expands your sentences into detailed, well-structured paragraphs. |
| **`Ctrl + Alt + C`** | **Custom Command** | Opens a sleek **dark-themed input box** to enter any custom AI instruction (e.g. *"translate to French"* or *"format as bullet points"*). |

---

## ⚙️ Customization

You can edit `config.json` to customize your prompt styles, edit hotkey bindings, choose different models, or disable notifications. 

*Note: Restart SmartPolisher after editing config.json for changes to take effect.*

---

## 🛑 How to Stop the Tool

* Right-click the **SmartPolisher** icon in your system tray (bottom-right next to the clock) and click **Exit**.
* Alternatively, double-click **[Stop-SmartPolisher.bat](file:///D:/API-Projects/New%20folder/Stop-SmartPolisher.bat)**.
