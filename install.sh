#!/data/data/com.termux/files/usr/bin/bash

echo -e "\e[1;36m[*] Installing T-Header Control Panel...\e[0m"

# Download the main script
curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/t-header-panel/main/theader-panel.sh -o "$PREFIX/bin/theader"

# Make it executable
chmod +x "$PREFIX/bin/theader"

# Check if installation was successful
if command -v theader &>/dev/null; then
    echo -e "\e[1;32m[✓] Installed successfully!\e[0m"
    echo -e "\e[1;33m[*] Type 'theader' to start the control panel.\e[0m"
else
    echo -e "\e[1;31m[✗] Installation failed. Check your internet connection.\e[0m"
fi