#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════════════
#  T-HEADER CONTROL PANEL
# ═══════════════════════════════════════════════════════════════════════
#  Professional unified menu for the T-Header project
#  Version : 3.0.0
#  License : MIT
#  Platform: Termux (Android)
# ═══════════════════════════════════════════════════════════════════════

set -o pipefail
readonly VERSION="3.0.0"
readonly APP_NAME="T-Header Control Panel"
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

mkdir -p "$CONFIG_DIR" "$LOGO_DIR" "$TPT_DIR" "$BACKUP_DIR" 2>/dev/null

# ─── Utilities ───────────────────────────────────────────────────────
has() { command -v "$1" &>/dev/null; }

arb() {
    if has fribidi; then
        printf '%s\n' "$1" | fribidi --nopad 2>/dev/null || printf '%s\n' "$1"
    else
        printf '%s\n' "$1"
    fi
}

log() { printf '[%s] [%-5s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" >> "$LOG_FILE" 2>/dev/null; }
msg()  { log INFO  "$*"; gum style --foreground "$CLR_ACCENT"  "  ℹ  $*"; }
ok()   { log OK    "$*"; gum style --foreground "$CLR_SUCCESS" "  ✓  $*"; }
warn() { log WARN  "$*"; gum style --foreground "$CLR_WARN"    "  ⚠  $*"; }
err()  { log ERR   "$*"; gum style --foreground "$CLR_ERROR"   "  ✗  $*"; }
confirm() { gum confirm --default=false "$(arb "$1")"; }

# ─── Branding ────────────────────────────────────────────────────────
banner() {
    clear
    if has figlet && has lolcat; then
        figlet -f small "T-HEADER" 2>/dev/null | lolcat -f 2>/dev/null
    fi
    gum style \
        --border double --padding "0 3" \
        --foreground "$CLR_PRIMARY" --border-foreground "$CLR_PRIMARY" \
        "⚡  ${APP_NAME}" \
        "$(arb 'لوحة تحكم موحدة لمشروع T-Header')" \
        "v${VERSION}  •  Termux Customization Suite"
    echo
}

# ─── Built-in Keyboard Layouts ───────────────────────────────────────
generate_keyboards() {
    [[ -f "$TPT_DIR/kb-default.properties" ]] || echo -e "extra-keys = []" > "$TPT_DIR/kb-default.properties"
    [[ -f "$TPT_DIR/kb-standard.properties" ]] || cat > "$TPT_DIR/kb-standard.properties" <<'EOF'
extra-keys = [ \
 ['ESC','/','-','HOME','UP','END','PGUP'], \
 ['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN'] \
]
EOF
    [[ -f "$TPT_DIR/kb-programmer.properties" ]] || cat > "$TPT_DIR/kb-programmer.properties" <<'EOF'
extra-keys = [ \
 ['ESC','TAB','CTRL','ALT','/','-','|','~','HOME','END'], \
 ['1','2','3','4','5','6','7','8','9','0'], \
 ['!','@','#','$','%','^','&','*','(',')'], \
 ['LEFT','DOWN','UP','RIGHT','PGUP','PGDN','BKSP','ENTER'] \
]
EOF
}

# ─── Actions ─────────────────────────────────────────────────────────
action_install_packages() {
    msg "$(arb 'تثبيت الحزم الأساسية...')"
    gum spin --spinner dot --title "$(arb 'تحديث الحزم...')" -- bash -c 'pkg update -y && pkg upgrade -y' >/dev/null 2>&1
    gum spin --spinner dot --title "$(arb 'تثبيت الأدوات...')" -- pkg install -y git zsh curl wget figlet lolcat boxes fzf gum bat eza ncurses-utils fribidi >/dev/null 2>&1
    ok "$(arb 'تم تثبيت الحزم')"
}

action_setup_zsh() {
    msg "$(arb 'إعداد Zsh + Oh-my-zsh...')"
    has zsh || pkg install -y zsh >/dev/null 2>&1
    has git || pkg install -y git >/dev/null 2>&1

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        gum spin --spinner globe --title "$(arb 'جاري تحميل Oh-my-zsh...')" -- git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" >/dev/null 2>&1
        if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
            warn "$(arb 'فشل التحميل من GitHub، جاري تجربة رابط بديل...')"
            gum spin --spinner globe --title "$(arb 'جاري التحميل من الرابط البديل...')" -- git clone --depth=1 https://gitee.com/mcornella/ohmyzsh.git "$HOME/.oh-my-zsh" >/dev/null 2>&1
        fi
    fi

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        err "$(arb 'فشل تثبيت Oh-my-zsh. تأكد من اتصالك بالإنترنت.')"
        return 1
    fi

    [[ -f "$HOME/.zshrc" ]] || cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"

    local zc="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    [[ -d "$zc/plugins/zsh-autosuggestions" ]] || git clone -q --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$zc/plugins/zsh-autosuggestions" 2>/dev/null
    [[ -d "$zc/plugins/zsh-syntax-highlighting" ]] || git clone -q --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$zc/plugins/zsh-syntax-highlighting" 2>/dev/null

    if ! grep -q "zsh-autosuggestions" "$HOME/.zshrc" 2>/dev/null; then
        sed -i 's/^plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
    fi
    
    chsh -s zsh >/dev/null 2>&1 || true
    ok "$(arb 'تم إعداد Zsh بنجاح')"
}

action_change_logo() {
    if [[ ! -d "$LOGO_DIR" || -z "$(ls -A "$LOGO_DIR" 2>/dev/null)" ]]; then
        err "$(arb "لا توجد شعارات في: $LOGO_DIR")"; return
    fi
    local logo indent
    logo=$(ls "$LOGO_DIR" | gum choose --header "$(arb 'اختر الشعار:')" --cursor "▶ ") || return
    indent=$(gum choose --header "$(arb 'المسافة البادئة:')" 2 3 4 5 6) || indent=2
    cp "$LOGO_DIR/$logo" "$CONFIG_DIR/active.logo"
    printf '%s\n' "$indent" > "$CONFIG_DIR/indent.cfg"
    ok "$(arb "تم تطبيق الشعار: $logo (إزاحة $indent)")"
}

action_change_title() {
    local title
    title=$(gum input --header "$(arb 'اكتب العنوان الجديد:')" --placeholder "T-Header" --prompt "› ") || return
    [[ -z "$title" ]] && return
    printf '%s\n' "$title" > "$CONFIG_DIR/title.cfg"
    ok "$(arb "تم حفظ العنوان: $title")"
}

action_change_keyboard() {
    generate_keyboards
    local file
    file=$(ls "$TPT_DIR" 2>/dev/null | gum choose --header "$(arb 'اختر تخطيط الكيبورد:')" --cursor "▶ ") || return
    [[ -z "$file" ]] && return
    [[ -f "$HOME/.termux/termux.properties" ]] && cp "$HOME/.termux/termux.properties" "$BACKUP_DIR/termux.$(date +%s)"
    mkdir -p "$HOME/.termux"
    cp "$TPT_DIR/$file" "$HOME/.termux/termux.properties"
    termux-reload-settings 2>/dev/null
    ok "$(arb "تم تطبيق تخطيط الكيبورد: $file")"
}

action_change_theme() {
    local t="$HOME/.oh-my-zsh/themes" c="$HOME/.oh-my-zsh/custom/themes"
    [[ ! -d "$t" && ! -d "$c" ]] && { err "$(arb 'Oh-my-zsh غير مثبت — شغّل إعداد Zsh أولاً')"; return; }
    local themes theme
    themes=$( (ls "$t" 2>/dev/null; ls "$c" 2>/dev/null) | sed 's/\.zsh-theme$//' | sort -u)
    theme=$(printf '%s\n' "$themes" | gum filter --header "$(arb 'ابحث واختر الثيم:')" --height 15) || return
    [[ -z "$theme" ]] && return
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$theme\"/" "$HOME/.zshrc"
    ok "$(arb "تم تغيير الثيم إلى: $theme")"
}

action_toggle_autocomplete() {
    local zrc="$HOME/.zshrc"
    [[ ! -f "$zrc" ]] && { err "$(arb '.zshrc غير موجود، قم بإعداد Zsh أولاً')"; return; }
    if grep -q "zsh-autosuggestions" "$zrc"; then
        sed -i 's/ zsh-autosuggestions//g; s/zsh-autosuggestions //g' "$zrc"
        warn "$(arb 'تم تعطيل الإكمال التلقائي')"
    else
        sed -i 's/plugins=(\(.*\))/plugins=(\1 zsh-autosuggestions)/' "$zrc"
        ok "$(arb 'تم تفعيل الإكمال التلقائي')"
    fi
}

action_backup() {
    local ts; ts=$(date +%s)
    [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$BACKUP_DIR/zshrc.$ts"
    [[ -f "$HOME/.termux/termux.properties" ]] && cp "$HOME/.termux/termux.properties" "$BACKUP_DIR/termux.$ts"
    [[ -d "$CONFIG_DIR" ]] && tar -czf "$BACKUP_DIR/theader.$ts.tar.gz" -C "$HOME/.config" theader 2>/dev/null
    ok "$(arb "تم حفظ نسخة احتياطية في: $BACKUP_DIR")"
}

action_install_all() {
    confirm "$(arb 'سيتم تثبيت كل شيء (حزم + Zsh + كيبورد + ثيم). متأكد؟')" || return
    action_install_packages
    action_setup_zsh
    generate_keyboards
    if [[ -d "$LOGO_DIR" && -n "$(ls -A "$LOGO_DIR" 2>/dev/null)" ]]; then
        cp "$LOGO_DIR/$(ls "$LOGO_DIR" | head -1)" "$CONFIG_DIR/active.logo"
        printf '2\n' > "$CONFIG_DIR/indent.cfg"
    fi
    mkdir -p "$HOME/.termux" && cp "$TPT_DIR/kb-standard.properties" "$HOME/.termux/termux.properties"
    termux-reload-settings 2>/dev/null
    [[ -f "$HOME/.zshrc" ]] && sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"agnoster\"/" "$HOME/.zshrc"
    ok "$(arb 'اكتمل التثبيت الكامل — يرجى إعادة تشغيل Termux')"
}

action_remove() {
    confirm "$(arb 'إزالة T-Header بالكامل؟ (سيتم عمل نسخة احتياطية أولاً)')" || return
    action_backup
    rm -rf "$CONFIG_DIR" && rm -f "$HOME/.termux/termux.properties"
    sed -i '/theader/d' "$HOME/.zshrc" 2>/dev/null
    ok "$(arb 'تمت إزالة T-Header')"
}

# ─── Main Menu ────────────────────────────────────────────────────────
main_loop() {
    while true; do
        banner
        local choice
        choice=$(gum choose --header "$(arb 'اختر من القائمة:')" --cursor "▶ " --height 18 \
            "$(arb '──  الإعداد  ──────────────────────────')" \
            "$(arb '📦  تثبيت الحزم               Install Packages')" \
            "$(arb '🐚  إعداد Zsh + Oh-my-zsh       Setup Zsh')" \
            "$(arb '──  التخصيص  ────────────────────────')" \
            "$(arb '🎨  تغيير الشعار                 Change Logo')" \
            "$(arb '📝  تغيير العنوان                Change Title')" \
            "$(arb '⌨️   تغيير الكيبورد             Change Keyboard')" \
            "$(arb '🎭  تغيير ثيم ZSH              Change Theme')" \
            "$(arb '💡  تبديل الإكمال التلقائي     Toggle Autocomplete')" \
            "$(arb '──  الصيانة  ────────────────────────')" \
            "$(arb '💾  نسخة احتياطية               Backup')" \
            "$(arb '🚀  تثبيت الكل                  Install Everything')" \
            "$(arb '🗑️   إزالة T-Header             Remove')" \
            "$(arb '❌  خروج                        Exit')"
        ) || break

        echo
        case "$choice" in
            *"──"*) continue ;;
            *"تثبيت الحزم"*|*"Install Packages"*) action_install_packages ;;
            *"إعداد Zsh"*|*"Setup Zsh"*) action_setup_zsh ;;
            *"تغيير الشعار"*|*"Change Logo"*) action_change_logo ;;
            *"تغيير العنوان"*|*"Change Title"*) action_change_title ;;
            *"تغيير الكيبورد"*|*"Change Keyboard"*) action_change_keyboard ;;
            *"تغيير ثيم"*|*"Change Theme"*) action_change_theme ;;
            *"الإكمال التلقائي"*|*"Toggle Autocomplete"*) action_toggle_autocomplete ;;
            *"نسخة احتياطية"*|*"Backup"*) action_backup ;;
            *"تثبيت الكل"*|*"Install Everything"*) action_install_all ;;
            *"إزالة T-Header"*|*"Remove"*) action_remove ;;
            *"خروج"*|*"Exit"*|"") break ;;
        esac
        echo
        confirm "العودة للقائمة الرئيسية؟" || break
    done
    clear
    gum style --foreground "$CLR_DIM" "$(arb 'وداعاً 👋')"
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
  -l, --log       Open log file
  (no args)       Launch interactive menu
EOF
        exit 0 ;;
    -v|--version) echo "${APP_NAME} v${VERSION}"; exit 0 ;;
    -l|--log)     [[ -f "$LOG_FILE" ]] && less "$LOG_FILE" || echo "No log yet"; exit 0 ;;
esac

# ─── Entrypoint ───────────────────────────────────────────────────────
has gum     || { echo "Installing gum...";     pkg install -y gum     || exit 1; }
has fribidi || pkg install -y fribidi >/dev/null 2>&1 || true

generate_keyboards
log INFO "Session started (v${VERSION})"
main_loop