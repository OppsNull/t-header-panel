#!/data/data/com.termux/files/usr/bin/bash

echo -e "\e[1;36m[*] Installing T-Header Control Panel...\e[0m"

# Download the main script from OppsNull's repository
if curl -fsSL https://raw.githubusercontent.com/OppsNull/t-header-panel/main/theader-panel.sh -o "$PREFIX/bin/theader"; then
    chmod +x "$PREFIX/bin/theader"
    echo -e "\e[1;32m[✓] Installed successfully!\e[0m"
    echo -e "\e[1;33m[*] Type 'theader' to start the control panel.\e[0m"
else
    echo -e "\e[1;31m[✗] Installation failed. Could not download the script (404).\e[0m"
    echo -e "\e[1;33m[*] Make sure the file name is exactly 'theader-panel.sh' on GitHub.\e[0m"
    rm -f "$PREFIX/bin/theader"
fi