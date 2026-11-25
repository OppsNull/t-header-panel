<div align="center">

# ⚡ T-Header Control Panel

**A professional, unified control panel for the T-Header project in Termux — with full Arabic/English support.**

[![Version](https://img.shields.io/badge/version-4.4.0-blue.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()
[![Platform](https://img.shields.io/badge/platform-Termux-orange.svg)]()

</div>

## 📖 About

**T-Header Control Panel** is a complete rewrite of the original [remo7777/T-Header](https://github.com/remo7777/T-Header) script. It transforms the scattered commands into a single, elegant, interactive menu — bilingual (Arabic RTL-fixed / English).

## ✨ Features

- 🎨 **Interactive UI**: Built with `gum` and `fzf`.
- 🌍 **Arabic Support**: Uses `fribidi` to fix reversed Arabic text in Termux.
- 🔤 **Bilingual Interface**: Switch between Arabic and English from the menu (option 15) — remembered between sessions.
- 🔄 **Auto-Updater**: Checks GitHub for new versions; verifies downloads before replacing itself.
- 🐚 **Zsh & Oh-my-zsh Setup**: Fully automated with fallback mirrors and error handling.
- 🧩 **Zsh Plugin Manager**: Install, enable, list, and remove external or built-in plugins — with safe rebuild of `.zshrc` (backups made before every change).
- ⌨️ **Keyboard Layouts**: Standard, programmer, and numbers `termux.properties` presets.
- 💾 **Backup System**: Automatic backups of `.zshrc`, `termux.properties`, and config before any modification.
- 🛠️ **Self-Healing**: Detects missing dependencies and installs them automatically.
- 🖥️ **Terminal Header**: Optional figlet + logo greeting every time you open a new session.
- ⚡ **Direct Commands**: `clogo`, `ctitle`, `ctpro`, `cztheme` shortcuts from the shell.

## 🚀 Installation

Run in Termux:

```bash
curl -fsSL https://raw.githubusercontent.com/OppsNull/t-header-panel/main/install.sh | bash
```

The installer validates that the downloaded script is genuine before installing.

## 🎮 Usage

```bash
theader          # launch the interactive control panel
theader -v       # show version
theader -u       # force update check
theader -l       # view log
theader logo     # change logo directly
theader title    # change title directly
theader keyboard # change keyboard layout directly
theader theme    # change zsh theme directly
```

Shell shortcuts (installed with Zsh setup):

| Command   | Description |
|-----------|-------------|
| `clogo`   | Change logo |
| `ctitle`  | Set custom header title |
| `ctpro`   | Switch `termux.properties` (keyboard layout) |
| `cztheme` | Change ZSH theme |

## 🌐 Language

The panel starts in **Arabic**. To switch to English, choose option **15** in the main menu. Your choice is saved in `~/.config/theader/lang.cfg`.

## 📁 Files & Locations

- Config: `~/.config/theader/`
- Logos: `~/.config/theader/logo/` (put your ASCII-art logo files here)
- Keyboard presets: `~/.config/theader/tpt/`
- Backups: `~/.theader-backups/`
- Log: `~/.config/theader/control-panel.log`

## 🧩 Recommended Plugins

Install from the plugin manager: `zsh-autosuggestions`, `zsh-syntax-highlighting` (kept last in loading order, as its authors recommend), `zsh-completions`, `fzf-tab`, and more.

## 🗑️ Uninstall

Choose option **16** in the menu — it backs everything up first, then removes configs. Backups remain in `~/.theader-backups/`.

Or manually:

```bash
rm -rf ~/.config/theader
sed -i '/theader/d' ~/.zshrc
rm -f $PREFIX/bin/theader $PREFIX/bin/clogo $PREFIX/bin/ctitle $PREFIX/bin/ctpro $PREFIX/bin/cztheme
```

## 📜 Credits

- Original T-Header project: [remo7777/T-Header](https://github.com/remo7777/T-Header)
- This rewrite: OppsNull — MIT License
