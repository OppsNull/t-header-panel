#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════════════
#  T-HEADER CONTROL PANEL
# ═══════════════════════════════════════════════════════════════════════
#  Version : 4.0.0 (Full Screen & Clean UI)
#  License : MIT
# ═══════════════════════════════════════════════════════════════════════

set -euo pipefail
shopt -s inherit_errexit

readonly VERSION="4.0.0"
readonly APP_NAME="T-Header Control Panel"
readonly REPO_URL="https://raw.githubusercontent.com/OppsNull/t-header-panel/main/theader-panel.sh"
readonly CONFIG_DIR="$HOME/.config/theader"
readonly LOGO_DIR="$CONFIG_DIR/logo"
readonly TPT_DIR="$CONFIG_DIR/tpt"
readonly BACKUP_DIR="$HOME/.theader-backups"
readonly LOG_FILE="$CONFIG_DIR/control-panel.log"

readonly CLR_PRIMARY=212
readonly CLR_ACCENT=141
readonly CLR_SUCCESS=82
readonly CLR_WARN=220
readonly CLR_ERROR=196
readonly CLR_DIM=240

cleanup() { rm -f "${TEMP_FILE:-}" 2>/dev/null || true; }
trap cleanup EXIT SIGINT SIGTERM

mkdir -p "$CONFIG_DIR" "$LOGO_DIR" "$TPT_DIR" "$BACKUP_DIR" 2>/dev/null

# ─── Utilities ───────────────────────────────────────────────────────
has() { command -v "$1" &>/dev/null; }

# دالة عكس النص العربي
arb() {
    if has fribidi; then
        printf '%s' "$1" | fribidi --nopad 2>/dev/null || printf '%s' "$1"
    else
        printf '%s' "$1"
    fi
}

# دالة تأكيد آمنة
confirm_action() {
    local msg="$1"
    local ans
    read -r -p "$(echo -e "\e[1;33m$msg (y/N): \e[0m")" ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

log() { printf '[%s] [%-5s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" >> "$LOG_FILE" 2>/dev/null; }
msg()  { log INFO  "$*"; gum style --foreground "$CLR_ACCENT"  "  ℹ  $*"; }
ok()   { log OK    "$*"; gum style --foreground "$CLR_SUCCESS" "  ✓  $*"; }
warn() { log WARN  "$*"; gum style --foreground "$CLR_WARN"    "  ⚠  $*"; }
err()  { log ERR   "$*"; gum style --foreground "$CLR_ERROR"   "  ✗  $*"; }

# ─── Update Checker ──────────────────────────────────────────────────
REMOTE_VERSION=""
HAS_UPDATE=false
UPDATE_ERROR=false

check_for_updates() {
    UPDATE_ERROR=false
    local raw_content
    if ! raw_content=$(curl -fsSL --max-time 5 "$REPO_URL" 2>/dev/null); then
        UPDATE_ERROR=true
        return
    fi
    REMOTE_VERSION=$(printf '%s\n' "$raw_content" | grep -E '^readonly VERSION=' | head -n 1 | cut -d'"' -f2 || true)
    if [[ -n "$REMOTE_VERSION" && "$REMOTE_VERSION" != "$VERSION" ]]; then
        HAS_UPDATE=true
    fi
}

# ─── Branding ────────────────────────────────────────────────────────
banner() {
    printf "\033c" # مسح الشاشة بالكامل بشكل صارم لمنع التداخل
    if has figlet && has lolcat; then
        figlet -f small "T-HEADER" 2>/dev/null | lolcat -f 2>/dev/null || true
    fi
    local update_msg=""
    if [[ "$HAS_UPDATE" == "true" ]]; then
        update_msg="🚀 New update available: v$REMOTE_VERSION"
    elif [[ "$UPDATE_ERROR" == "true" ]]; then
        update_msg="⚠️ Failed to check for updates."
    fi

    gum style \
        --border double --padding "0 3" \
        --foreground "$CLR_PRIMARY" --border-foreground "$CLR_PRIMARY" \
        "⚡  ${APP_NAME}" \
        "T-Header | $(arb 'لوحة تحكم موحدة لمشروع')" \
        "v${VERSION}  •  Termux Customization Suite" \
        "$update_msg"
    echo
}

# ─── Core Actions ────────────────────────────────────────────────────
generate_keyboards() {
    [[ -f "$TPT_DIR/kb-default.properties" ]] || echo -e "extra-keys = []" > "$TPT_DIR/kb-default.properties"
    [[ -f "$TPT_DIR/kb-standard.properties" ]] || cat > "$TPT_DIR/kb-standard.properties" <<'EOF'
extra-keys = [ \
 ['ESC','/','-','HOME','UP','END','PGUP'], \
 ['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN'] \
]
EOF
}

action_install_packages() {
    msg "Installing basic packages..."
    gum spin --spinner dot --title "Updating packages..." -- bash -c 'pkg update -y && pkg upgrade -y' >/dev/null 2>&1 || true
    gum spin --spinner dot --title "Installing tools..." -- pkg install -y git zsh curl wget figlet lolcat boxes fzf gum bat eza ncurses-utils fribidi >/dev/null 2>&1 || true
    ok "Packages installed | $(arb 'تم تثبيت الحزم')"
}

action_setup_zsh() {
    msg "Setting up Zsh + Oh-my-zsh..."
    has zsh || pkg install -y zsh >/dev/null 2>&1 || true
    has git || pkg install -y git >/dev/null 2>&1 || true

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        gum spin --spinner globe --title "Downloading Oh-my-zsh..." -- \
            git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" >/dev/null 2>&1 || true
        if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
            warn "GitHub failed, trying alternative..."
            gum spin --spinner globe --title "Downloading alternative..." -- \
                git clone --depth=1 https://gitee.com/mcornella/ohmyzsh.git "$HOME/.oh-my-zsh" >/dev/null 2>&1 || true
        fi
    fi
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        err "Failed to install Oh-my-zsh."
        return 1
    fi
    [[ -f "$HOME/.zshrc" ]] || cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
    ok "Zsh setup completed | $(arb 'تم إعداد Zsh')"
}

# ─── Zsh Plugin Manager ──────────────────────────────────────────────
add_plugin_to_zshrc() {
    local plugin="$1"
    local zrc="$HOME/.zshrc"
    
    if grep -qE "plugins=\(.*\b${plugin}\b.*\)" "$zrc" 2>/dev/null; then
        warn "Plugin already enabled: $plugin | $(arb 'الإضافة مفعلة بالفعل')"
        return 0
    fi
    
    if grep -q "zsh-syntax-highlighting" "$zrc"; then
        sed -i -E "s/zsh-syntax-highlighting/${plugin} zsh-syntax-highlighting/" "$zrc"
    else
        sed -i -E "s/^plugins=\((.*)\)/plugins=(\1 ${plugin})/" "$zrc"
    fi
    ok "Plugin enabled: $plugin | $(arb 'تم تفعيل الإضافة')"
}

install_omz_plugin() {
    local name="$1" repo="$2"
    local zc="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    mkdir -p "$zc/plugins"
    
    if [[ ! -d "$zc/plugins/$name" ]]; then
        msg "Downloading plugin: $name..."
        if ! git clone --depth=1 "$repo" "$zc/plugins/$name"; then
            err "Failed to download: $name"
            return 1
        fi
    fi
    add_plugin_to_zshrc "$name"
}

action_manage_plugins() {
    if [[ ! -f "$HOME/.zshrc" ]]; then
        err ".zshrc not found. Setup Zsh first."
        return
    fi

    # استخدام 100% من الشاشة لمنع التداخل
    local choice
    choice=$(printf "%s\n" \
        " 1) Install External | $(arb 'تثبيت إضافات خارجية')" \
        " 2) Enable Built-in  | $(arb 'تفعيل إضافات داخلية')" \
        " 3) List Active      | $(arb 'عرض الإضافات المفعلة')" \
        " 4) Remove Plugin    | $(arb 'إزالة إضافة')" \
        " 5) Back             | $(arb 'رجوع')" | \
        fzf --reverse --height 100% --border --info=inline --prompt "Plugin Manager > " --pointer "▶ ") || return

    case "$choice" in
        " 1)"*)
            local active_list
            active_list=$(grep -E "^plugins=\(" "$HOME/.zshrc" | sed 's/plugins=(//g; s/)//g')

            local chk1="[ ]" chk2="[ ]" chk3="[ ]" chk4="[ ]" chk5="[ ]" chk6="[ ]"
            grep -qw "zsh-autosuggestions" <<< "$active_list" && chk1="[✓]"
            grep -qw "zsh-syntax-highlighting" <<< "$active_list" && chk2="[✓]"
            grep -qw "zsh-completions" <<< "$active_list" && chk3="[✓]"
            grep -qw "fzf-tab" <<< "$active_list" && chk4="[✓]"
            grep -qw "zsh-history-substring-search" <<< "$active_list" && chk5="[✓]"
            grep -qw "zsh-you-should-use" <<< "$active_list" && chk6="[✓]"

            local selected
            selected=$(printf "%s\n" \
                " 1) $chk1 zsh-autosuggestions | $(arb 'اقتراحات تلقائية')" \
                " 2) $chk2 zsh-syntax-highlighting | $(arb 'تلوين الأوامر')" \
                " 3) $chk3 zsh-completions | $(arb 'إكمال إضافي')" \
                " 4) $chk4 fzf-tab | $(arb 'بحث تفاعلي بالملفات')" \
                " 5) $chk5 zsh-history-substring-search | $(arb 'بحث في الأوامر')" \
                " 6) $chk6 zsh-you-should-use | $(arb 'تذكير بالاختصارات')" | \
                fzf --multi --reverse --height 100% --border --info=inline --prompt "Select plugins (Tab to multi-select) > " --pointer "▶ ") || return

            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                local plugin_name
                plugin_name=$(echo "$line" | cut -d'|' -f1 | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]*\[.\][[:space:]]*//' | tr -d ' ')
                
                case "$plugin_name" in
                    "zsh-autosuggestions") install_omz_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions" ;;
                    "zsh-syntax-highlighting") install_omz_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting" ;;
                    "zsh-completions") install_omz_plugin "zsh-completions" "https://github.com/zsh-users/zsh-completions" ;;
                    "fzf-tab") install_omz_plugin "fzf-tab" "https://github.com/Aloxaf/fzf-tab" ;;
                    "zsh-history-substring-search") install_omz_plugin "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search" ;;
                    "zsh-you-should-use") install_omz_plugin "zsh-you-should-use" "https://github.com/MichaelAquilina/zsh-you-should-use" ;;
                esac
            done <<< "$selected"
            ;;
        " 2)"*)
            local selected
            selected=$(printf "%s\n" \
                " 1) git" " 2) extract" " 3) colored-man-pages" " 4) command-not-found" \
                " 5) sudo" " 6) web-search" " 7) cp" " 8) z" | \
                fzf --multi --reverse --height 100% --border --info=inline --prompt "Select built-in plugins > " --pointer "▶ ") || return
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                local plugin
                plugin=$(echo "$line" | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]*//')
                add_plugin_to_zshrc "$plugin"
            done <<< "$selected"
            ;;
        " 3)"*)
            local active
            active=$(grep -E "^plugins=\(" "$HOME/.zshrc" | sed 's/plugins=(//g; s/)//g')
            gum style --border normal --padding "1 2" --foreground "$CLR_ACCENT" \
                "Active Plugins:" "" "$active"
            ;;
        " 4)"*)
            local active to_remove
            active=$(grep -E "^plugins=\(" "$HOME/.zshrc" | sed 's/plugins=(//g; s/)//g' | tr ' ' '\n' | grep -v '^$' || true)
            [[ -z "$active" ]] && { warn "No plugins registered"; return; }
            to_remove=$(echo "$active" | fzf --reverse --height 100% --border --info=inline --prompt "Select plugin to remove > " --pointer "▶ ") || return
            [[ -z "$to_remove" ]] && return
            sed -i -E "s/ ?\b${to_remove}\b ?//g" "$HOME/.zshrc"
            ok "Plugin removed: $to_remove"
            ;;
    esac
}

# ─── Customizations & Maintenance ────────────────────────────────────
action_change_logo() {
    if [[ ! -d "$LOGO_DIR" || -z "$(ls -A "$LOGO_DIR" 2>/dev/null)" ]]; then
        err "No logos in: $LOGO_DIR"; return
    fi
    local logo indent
    logo=$(ls "$LOGO_DIR" | fzf --reverse --height 100% --border --info=inline --prompt "Select Logo > " --pointer "▶ ") || return
    indent=$(printf "%s\n" 2 3 4 5 6 | fzf --reverse --height 100% --border --info=inline --prompt "Indent > " --pointer "▶ ") || indent=2
    cp "$LOGO_DIR/$logo" "$CONFIG_DIR/active.logo"
    printf '%s\n' "$indent" > "$CONFIG_DIR/indent.cfg"
    ok "Logo applied: $logo"
}

action_change_title() {
    local title
    title=$(gum input --header "Enter new title:" --placeholder "T-Header" --prompt "› ") || return
    [[ -z "$title" ]] && return
    printf '%s\n' "$title" > "$CONFIG_DIR/title.cfg"
    ok "Title saved: $title"
}

action_change_keyboard() {
    generate_keyboards
    local file
    file=$(ls "$TPT_DIR" 2>/dev/null | fzf --reverse --height 100% --border --info=inline --prompt "Select Layout > " --pointer "▶ ") || return
    [[ -z "$file" ]] && return
    [[ -f "$HOME/.termux/termux.properties" ]] && cp "$HOME/.termux/termux.properties" "$BACKUP_DIR/termux.$(date +%s)"
    mkdir -p "$HOME/.termux"
    cp "$TPT_DIR/$file" "$HOME/.termux/termux.properties"
    termux-reload-settings 2>/dev/null || true
    ok "Keyboard applied: $file"
}

action_change_theme() {
    local t="$HOME/.oh-my-zsh/themes" c="$HOME/.oh-my-zsh/custom/themes"
    [[ ! -d "$t" && ! -d "$c" ]] && { err "Oh-my-zsh not installed."; return; }
    local themes theme
    themes=$( (ls "$t" 2>/dev/null; ls "$c" 2>/dev/null) | sed 's/\.zsh-theme$//' | sort -u)
    theme=$(printf '%s\n' "$themes" | fzf --reverse --height 100% --border --info=inline --prompt "Search Theme > " --pointer "▶ ") || return
    [[ -z "$theme" ]] && return
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$theme\"/" "$HOME/.zshrc"
    ok "Theme changed to: $theme"
}

action_backup() {
    local ts; ts=$(date +%s)
    [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$BACKUP_DIR/zshrc.$ts"
    [[ -f "$HOME/.termux/termux.properties" ]] && cp "$HOME/.termux/termux.properties" "$BACKUP_DIR/termux.$ts"
    [[ -d "$CONFIG_DIR" ]] && tar -czf "$BACKUP_DIR/theader.$ts.tar.gz" -C "$HOME/.config" theader 2>/dev/null
    ok "Backup saved in: $BACKUP_DIR"
}

action_update_tool() {
    check_for_updates
    if [[ "$UPDATE_ERROR" == "true" ]]; then warn "Failed to connect to GitHub."; return; fi
    if [[ "$HAS_UPDATE" == "false" ]]; then ok "You are on the latest version."; return; fi
    
    confirm_action "Update to v$REMOTE_VERSION? | $(arb 'هل تريد التحديث الآن؟')" || return
    msg "Updating tool..."
    TEMP_FILE=$(mktemp)
    if gum spin --spinner globe --title "Downloading..." -- curl -fsSL "$REPO_URL" -o "$TEMP_FILE"; then
        chmod +x "$TEMP_FILE"
        mv "$TEMP_FILE" "$PREFIX/bin/theader"
        ok "Update successful! Restarting..."
        sleep 2
        exec "$PREFIX/bin/theader"
    else
        err "Update failed. Check internet."
        rm -f "$TEMP_FILE"
    fi
}

action_install_all() {
    confirm_action "Install EVERYTHING (Packages + Zsh + Theme + Plugins)? | $(arb 'تثبيت الكل؟')" || return
    action_install_packages
    action_setup_zsh
    install_omz_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
    install_omz_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"
    generate_keyboards
    mkdir -p "$HOME/.termux" && cp "$TPT_DIR/kb-standard.properties" "$HOME/.termux/termux.properties"
    termux-reload-settings 2>/dev/null || true
    [[ -f "$HOME/.zshrc" ]] && sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"agnoster\"/" "$HOME/.zshrc"
    ok "Full installation complete! Restart Termux."
}

action_remove() {
    confirm_action "Remove T-Header completely? | $(arb 'إزالة T-Header؟')" || return
    action_backup
    rm -rf "$CONFIG_DIR" && rm -f "$HOME/.termux/termux.properties"
    sed -i '/theader/d' "$HOME/.zshrc" 2>/dev/null || true
    ok "T-Header removed."
}

# ─── Main Menu ────────────────────────────────────────────────────────
main_loop() {
    while true; do
        banner
        local choice
        local update_opt=""
        
        if [[ "$HAS_UPDATE" == "true" ]]; then 
            update_opt="11) 🔄 Update Tool      | $(arb 'تحديث اللوحة')"
        else 
            update_opt="11) 🔄 Check Updates    | $(arb 'فحص التحديثات')"
        fi

        # استخدام 100% من الشاشة
        choice=$(printf "%s\n" \
            " 1) ── Setup       | $(arb 'الإعداد') ──────────────────────────" \
            " 2) 📦 Install Packages  | $(arb 'تثبيت الحزم')" \
            " 3) 🐚 Setup Zsh         | $(arb 'إعداد Zsh')" \
            " 4) ── Customize   | $(arb 'التخصيص') ────────────────────────" \
            " 5) 🧩 Manage Plugins    | $(arb 'إدارة الإضافات')" \
            " 6) 🎨 Change Logo       | $(arb 'تغيير الشعار')" \
            " 7) 📝 Change Title      | $(arb 'تغيير العنوان')" \
            " 8) ⌨️  Change Keyboard   | $(arb 'تغيير الكيبورد')" \
            " 9) 🎭 Change Theme      | $(arb 'تغيير الثيم')" \
            "10) ── Maintenance | $(arb 'الصيانة') ────────────────────────" \
            "$update_opt" \
            "12) 💾 Backup            | $(arb 'نسخة احتياطية')" \
            "13) 🚀 Install Everything| $(arb 'تثبيت الكل')" \
            "14) 🗑️  Remove T-Header   | $(arb 'إزالة')" \
            "15) ❌ Exit              | $(arb 'خروج')" | \
            fzf --reverse --height 100% --border --info=inline --prompt "Select (type number or use arrows) > " --pointer "▶ ") || break

        echo
        case "$choice" in
            *"──"*) continue ;;
            *"Install Packages"*) action_install_packages ;;
            *"Setup Zsh"*) action_setup_zsh ;;
            *"Manage Plugins"*) action_manage_plugins ;;
            *"Change Logo"*) action_change_logo ;;
            *"Change Title"*) action_change_title ;;
            *"Change Keyboard"*) action_change_keyboard ;;
            *"Change Theme"*) action_change_theme ;;
            *"Update Tool"*|*"Check Updates"*) action_update_tool ;;
            *"Backup"*) action_backup ;;
            *"Install Everything"*) action_install_all ;;
            *"Remove T-Header"*) action_remove ;;
            *"Exit"*|"") break ;;
        esac
        echo
        confirm_action "Return to main menu? | $(arb 'العودة للقائمة الرئيسية؟')" || break
    done
    clear
    gum style --foreground "$CLR_DIM" "وداعاً 👋"
}

# ─── CLI ──────────────────────────────────────────────────────────────
case "${1:-}" in
    -h|--help)
        cat <<EOF
${APP_NAME} v${VERSION}
Usage: $(basename "$0") [OPTION]
Options:
  -h, --help      Show this help
  -v, --version   Show version
  -u, --update    Force update to latest version
  -l, --log       Open log file
  (no args)       Launch interactive menu
EOF
        exit 0 ;;
    -v|--version) echo "${APP_NAME} v${VERSION}"; exit 0 ;;
    -u|--update)  check_for_updates; action_update_tool; exit 0 ;;
    -l|--log)     [[ -f "$LOG_FILE" ]] && less "$LOG_FILE" || echo "No log yet"; exit 0 ;;
esac

# ─── Entrypoint ───────────────────────────────────────────────────────
has gum     || { echo "Installing gum...";     pkg install -y gum     || exit 1; }
has fzf     || { echo "Installing fzf...";     pkg install -y fzf     || exit 1; }
has fribidi || pkg install -y fribidi >/dev/null 2>&1 || true

generate_keyboards
log INFO "Session started (v${VERSION})"
msg "Checking for updates..."
check_for_updates

main_loop