<div align="center">

# ⚡ T-Header Control Panel

**A professional, unified control panel for the T-Header project in Termux.**

[![Version](https://img.shields.io/badge/version-4.3.1-blue.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()
[![Platform](https://img.shields.io/badge/platform-Termux-orange.svg)]()

</div>

## 📖 About
**T-Header Control Panel** is a complete rewrite of the T-Header script. It transforms the scattered commands into a single, elegant, and interactive menu with full Arabic support (RTL fix).

## ✨ Features
- 🎨 **Interactive UI**: Built with `gum` for a smooth experience.
- 🌍 **Arabic Support**: Uses `fribidi` to fix the reversed Arabic text in Termux.
- 🔄 **Auto-Updater**: Automatically checks for new versions from GitHub and updates itself with one click.
- 🐚 **Zsh & Oh-my-zsh Setup**: Fully automated setup with error handling.
- 🧩 **Zsh Plugin Manager**: Easily install, enable, list, and remove external or built-in Zsh plugins right from the menu.
- ⌨️ **Keyboard Layouts**: Pre-built `termux.properties` for standard, programmer, and numbers layouts.
- 💾 **Backup System**: Automatically backs up your configs before making changes.
- 🛠️ **Self-Healing**: Detects missing dependencies and installs them automatically.

## 🚀 Installation
Run the following command in Termux:

```bash
curl -fsSL https://raw.githubusercontent.com/OppsNull/t-header-panel/main/install.sh | bash
