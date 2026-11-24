<div align="center">

# ⚡ T-Header Control Panel

**A professional, unified control panel for the T-Header project in Termux.**

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()
[![Platform](https://img.shields.io/badge/platform-Termux-orange.svg)]()

</div>

## 📖 About
**T-Header Control Panel** is a complete rewrite of the T-Header script. It transforms the scattered commands into a single, elegant, and interactive menu with full Arabic support (RTL fix).

## ✨ Features
- 🎨 **Interactive UI**: Built with `gum` for a smooth experience.
- 🌍 **Arabic Support**: Uses `fribidi` to fix the reversed Arabic text in Termux.
- 🐚 **Zsh & Oh-my-zsh Setup**: Fully automated setup with error handling.
- ⌨️ **Keyboard Layouts**: Pre-built `termux.properties` for standard, programmer, and numbers layouts.
- 💾 **Backup System**: Automatically backs up your configs before making changes.
- 🛠️ **Self-Healing**: Detects missing dependencies and installs them automatically.

## 🚀 Installation
Run the following command in Termux:

```bash
curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/t-header-panel/main/install.sh | bash