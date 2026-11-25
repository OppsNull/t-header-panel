#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO_URL="https://raw.githubusercontent.com/OppsNull/t-header-panel/main/theader-panel.sh"

echo -e "\e[1;36m[*] Installing T-Header Control Panel...\e[0m"

# 1) Make sure we're actually inside Termux
if [[ -z "${TERMUX_VERSION:-}" ]]; then
    echo -e "\e[1;31m[✗] This installer is for Termux (Android) only.\e[0m"
    echo -e "\e[1;33m[*] Detected PREFIX: ${PREFIX:-none}\e[0m"
    exit 1
fi

# 2) Download to a temp file first — never pipe straight to a privileged location
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

if ! curl -fsSL --max-time 30 "$REPO_URL" -o "$TMP_FILE"; then
    echo -e "\e[1;31m[✗] Download failed (network issue, or wrong URL/branch name).\e[0m"
    echo -e "\e[1;33m[*] Check that the file exists at: $REPO_URL\e[0m"
    exit 1
fi

# 3) Sanity check: the downloaded file must be the real script, not an HTML error page
if ! grep -q "T-HEADER CONTROL PANEL" "$TMP_FILE" || ! grep -q '^readonly VERSION=' "$TMP_FILE"; then
    echo -e "\e[1;31m[✗] Downloaded file is not a valid script (404 page or redirect?).\e[0m"
    echo -e "\e[1;33m[*] Make sure the branch is 'main' and the file is 'theader-panel.sh'.\e[0m"
    exit 1
fi

chmod +x "$TMP_FILE"
mkdir -p "$PREFIX/bin"
mv "$TMP_FILE" "$PREFIX/bin/theader"

echo -e "\e[1;32m[✓] Installed successfully!\e[0m"
echo -e "\e[1;33m[*] Type 'theader' to start the control panel.\e[0m"
