#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════════════
#  T-HEADER CONTROL PANEL
# ═══════════════════════════════════════════════════════════════════════
#  Version : 3.5.0 (Arabic First Edition)
#  License : MIT
#  Platform: Termux (Android)
# ═══════════════════════════════════════════════════════════════════════

set -euo pipefail
shopt -s inherit_errexit

readonly VERSION="3.5.0"
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
    clear
    if has figlet && has lolcat; then
        figlet -f small "T-HEADER" 2>/dev/null | lolcat -f 2>/dev/null || true
    fi
    local update_msg=""
    if [[ "$HAS_UPDATE" == "true" ]]; then
        update_msg="$(arb "🚀 تحديث جديد متوفر: v$REMOTE_VERSION")"
    elif [[ "$UPDATE_ERROR" == "true" ]]; then
        update_msg="$(arb "⚠️ تعذر الاتصال بجيت هب لفحص التحديثات")"
    fi

    gum style \
        --border double --padding "0 3" \
        --foreground "$CLR_PRIMARY" --border-foreground "$CLR_PRIMARY" \
        "⚡  ${APP_NAME}" \
        "$(arb 'لوحة تحكم موحدة لمشروع T-Header')" \
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
    msg "$(arb 'جاري تثبيت الحزم الأساسية...')"
    gum spin --spinner dot --title "$(arb 'تحديث الحزم...')" -- bash -c 'pkg update -y && pkg upgrade -y' >/dev/null 2>&1 || true
    gum spin --spinner dot --title "$(arb 'تثبيت الأدوات...')" -- pkg install -y git zsh curl wget figlet lolcat boxes fzf gum bat eza ncurses-utils fribidi >/dev/null 2>&1 || true
    ok "$(arb 'تم تثبيت الحزم بنجاح')"
}

action_setup_zsh() {
    msg "$(arb 'جاري إعداد Zsh + Oh-my-zsh...')"
    has zsh || pkg install -y zsh >/dev/null 2>&1 || true
    has git || pkg install -y git >/dev/null 2>&1 || true

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        gum spin --spinner globe --title "$(arb 'جاري تحميل Oh-my-zsh...')" -- \
            git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" >/dev/null 2>&1 || true
        if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
            warn "$(arb 'فشل التحميل من GitHub، جاري تجربة رابط بديل...')"
            gum spin --spinner globe --title "$(arb 'جاري التحميل من الرابط البديل...')" -- \
                git clone --depth=1 https://gitee.com/mcornella/ohmyzsh.git "$HOME/.oh-my-zsh" >/dev/null 2>&1 || true
        fi
    fi
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        err "$(arb 'فشل تثبيت Oh-my-zsh. تأكد من اتصالك بالإنترنت.')"
        return 1
    fi
    [[ -f "$HOME/.zshrc" ]] || cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
    ok "$(arb 'تم إعداد Zsh بنجاح')"
}

# ─── Zsh Plugin Manager ──────────────────────────────────────────────
add_plugin_to_zshrc() {
    local plugin="$1"
    local zrc="$HOME/.zshrc"
    if grep -qE "plugins=\(.*\b${plugin}\b.*\)" "$zrc" 2>/dev/null; then
        return 0
    fi
    # الحفاظ على إضافة التلوين في النهاية دائماً
    if grep -q "zsh-syntax-highlighting" "$zrc"; then
        sed -i -E "s/zsh-syntax-highlighting/${plugin} zsh-syntax-highlighting/" "$zrc"
    else
        sed -i -E "s/^plugins=\((.*)\)/plugins=(\1 ${plugin})/" "$zrc"
    fi
    ok "$(arb "تم تفعيل الإضافة: $plugin")"
}

install_omz_plugin() {
    local name="$1" repo="$2"
    local zc="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    mkdir -p "$zc/plugins"
    if [[ ! -d "$zc/plugins/$name" ]]; then
        msg "$(arb "جاري تحميل الإضافة: $name...")"
        if ! git clone -q --depth=1 "$repo" "$zc/plugins/$name" >/dev/null 2>&1; then
            err "$(arb "فشل تحميل الإضافة: $name (تحقق من الإنترنت)")"
            return 1
        fi
    fi
    add_plugin_to_zshrc "$name"
}

action_manage_plugins() {
    if [[ ! -f "$HOME/.zshrc" ]]; then
        err "$(arb '.zshrc غير موجود، قم بإعداد Zsh أولاً')"; return
    fi

    # استخدام الإيموجي في بداية السطر عشان نتفادى مشاكل العرض ونضمن اختيار صح
    local choice
    choice=$(gum choose --header "$(arb 'إدارة إضافات Zsh:')" --cursor "▶ " \
        "$(arb '➕ تثبيت إضافات خارجية')" \
        "$(arb '⚙️ تفعيل إضافات داخلية')" \
        "$(arb '📋 عرض الإضافات المفعلة')" \
        "$(arb '🗑️ إزالة إضافة')" \
        "$(arb '🔙 رجوع')") || return

    case "$choice" in
        "➕"*)
            local selected
            selected=$(gum choose --no-limit --header "$(arb 'اختر الإضافات (مسافة للتحديد، Enter للتأكيد):')" --cursor "▶ " \
                "$(arb '💡 zsh-autosuggestions (اقتراحات تلقائية)')" \
                "$(arb '🎨 zsh-syntax-highlighting (تلوين الأوامر)')" \
                "$(arb '📁 zsh-completions (إكمال إضافي)')" \
                "$(arb '🔍 fzf-tab (بحث تفاعلي بالملفات)')" \
                "$(arb '📜 zsh-history-substring-search (بحث في الأوامر)')" \
                "$(arb '🔔 zsh-you-should-use (تذكير بالاختصارات)')") || return

            # نقرأ كل سطر لوحده عشان نتفادى مشكلة المسافات في العربي
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                case "$line" in
                    "💡"*) install_omz_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions" ;;
                    "🎨"*) install_omz_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting" ;;
                    "📁"*) install_omz_plugin "zsh-completions" "https://github.com/zsh-users/zsh-completions" ;;
                    "🔍"*) install_omz_plugin "fzf-tab" "https://github.com/Aloxaf/fzf-tab" ;;
                    "📜"*) install_omz_plugin "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search" ;;
                    "🔔"*) install_omz_plugin "zsh-you-should-use" "https://github.com/MichaelAquilina/zsh-you-should-use" ;;
                esac
            done <<< "$selected"
            ;;
        "⚙️"*)
            local selected
            selected=$(gum choose --no-limit --header "$(arb 'اختر الإضافات الداخلية:')" --cursor "▶ " \
                "git" "extract" "colored-man-pages" "command-not-found" "sudo" "web-search" "cp" "z") || return
            while IFS= read -r plugin; do
                [[ -z "$plugin" ]] && continue
                add_plugin_to_zshrc "$plugin"
            done <<< "$selected"
            ;;
        "📋"*)
            local active
            active=$(grep -E "^plugins=\(" "$HOME/.zshrc" | sed 's/plugins=(//g; s/)//g')
            gum style --border normal --padding "1 2" --foreground "$CLR_ACCENT" \
                "$(arb 'الإضافات المفعلة حالياً:')" "" "$active"
            ;;
        "🗑️"*)
            local active to_remove
            active=$(grep -E "^plugins=\(" "$HOME/.zshrc" | sed 's/plugins=(//g; s/)//g' | tr ' ' '\n' | grep -v '^$' || true)
            [[ -z "$active" ]] && { warn "$(arb 'لا توجد إضافات مسجلة')"; return; }
            to_remove=$(echo "$active" | gum choose --header "$(arb 'اختر إضافة للإزالة:')") || return
            [[ -z "$to_remove" ]] && return
            sed -i -E "s/ ?\b${to_remove}\b ?//g" "$HOME/.zshrc"
            ok "$(arb "تم إزالة الإضافة: $to_remove")"
            ;;
    esac
}

# ─── Customizations & Maintenance ────────────────────────────────────
action_change_logo() {
    if [[ ! -d "$LOGO_DIR" || -z "$(ls -A "$LOGO_DIR" 2>/dev/null)" ]]; then
        err "$(arb "لا توجد شعارات في: $LOGO_DIR")"; return
    fi
    local logo indent
    logo=$(ls "$LOGO_DIR" | gum choose --header "$(arb 'اختر الشعار:')" --cursor "▶ ") || return
    indent=$(gum choose --header "$(arb 'المسافة البادئة:')" 2 3 4 5 6) || indent=2
    cp "$LOGO_DIR/$logo" "$CONFIG_DIR/active.logo"
    printf '%s\n' "$indent" > "$CONFIG_DIR/indent.cfg"
    ok "$(arb "تم تطبيق الشعار: $logo")"
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
    termux-reload-settings 2>/dev/null || true
    ok "$(arb "تم تطبيق الكيبورد: $file")"
}

action_change_theme() {
    local t="$HOME/.oh-my-zsh/themes" c="$HOME/.oh-my-zsh/custom/themes"
    [[ ! -d "$t" && ! -d "$c" ]] && { err "$(arb 'Oh-my-zsh غير مثبت — شغل إعداد Zsh أولاً')"; return; }
    local themes theme
    themes=$( (ls "$t" 2>/dev/null; ls "$c" 2>/dev/null) | sed 's/\.zsh-theme$//' | sort -u)
    theme=$(printf '%s\n' "$themes" | gum filter --header "$(arb 'ابحث واختر الثيم:')" --height 15) || return
    [[ -z "$theme" ]] && return
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$theme\"/" "$HOME/.zshrc"
    ok "$(arb "تم تغيير الثيم إلى: $theme")"
}

action_backup() {
    local ts; ts=$(date +%s)
    [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$BACKUP_DIR/zshrc.$ts"
    [[ -f "$HOME/.termux/termux.properties" ]] && cp "$HOME/.termux/termux.properties" "$BACKUP_DIR/termux.$ts"
    [[ -d "$CONFIG_DIR" ]] && tar -czf "$BACKUP_DIR/theader.$ts.tar.gz" -C "$HOME/.config" theader 2>/dev/null
    ok "$(arb "تم حفظ نسخة احتياطية في: $BACKUP_DIR")"
}

action_update_tool() {
    check_for_updates
    if [[ "$UPDATE_ERROR" == "true" ]]; then warn "$(arb 'فشل الاتصال بجيت هب.')"; return; fi
    if [[ "$HAS_UPDATE" == "false" ]]; then ok "$(arb 'أنت تستخدم أحدث إصدار بالفعل.')"; return; fi
    
    gum confirm --default=false "$(arb 'هل تريد تحديث اللوحة الآن؟')" || return
    msg "$(arb 'جاري تحديث اللوحة...')"
    TEMP_FILE=$(mktemp)
    if gum spin --spinner globe --title "$(arb 'جاري التحميل...')" -- curl -fsSL "$REPO_URL" -o "$TEMP_FILE"; then
        chmod +x "$TEMP_FILE"
        mv "$TEMP_FILE" "$PREFIX/bin/theader"
        ok "$(arb 'تم التحديث بنجاح! سيتم إعادة تشغيل اللوحة.')"
        sleep 2
        exec "$PREFIX/bin/theader"
    else
        err "$(arb 'فشل التحديث. تحقق من الإنترنت.')"
        rm -f "$TEMP_FILE"
    fi
}

action_install_all() {
    gum confirm --default=false "$(arb 'سيتم تثبيت كل شيء (حزم + Zsh + كيبورد + ثيم + إضافات). متأكد؟')" || return
    action_install_packages
    action_setup_zsh
    install_omz_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
    install_omz_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"
    generate_keyboards
    mkdir -p "$HOME/.termux" && cp "$TPT_DIR/kb-standard.properties" "$HOME/.termux/termux.properties"
    termux-reload-settings 2>/dev/null || true
    [[ -f "$HOME/.zshrc" ]] && sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"agnoster\"/" "$HOME/.zshrc"
    ok "$(arb 'اكتمل التثبيت الكامل — يرجى إعادة تشغيل Termux')"
}

action_remove() {
    gum confirm --default=false "$(arb 'إزالة T-Header بالكامل؟ (سيتم عمل نسخة احتياطية أولاً)')" || return
    action_backup
    rm -rf "$CONFIG_DIR" && rm -f "$HOME/.termux/termux.properties"
    sed -i '/theader/d' "$HOME/.zshrc" 2>/dev/null || true
    ok "$(arb 'تمت إزالة T-Header')"
}

# ─── Main Menu ────────────────────────────────────────────────────────
main_loop() {
    while true; do
        banner
        local choice
        local update_opt=""
        
        if [[ "$HAS_UPDATE" == "true" ]]; then update_opt="$(arb '🔄 تحديث اللوحة')"; else update_opt="$(arb '🔄 التحقق من التحديثات')"; fi

        choice=$(gum choose --header "$(arb 'اختر من القائمة:')" --cursor "▶ " --height 20 \
            "$(arb '── الإعداد ──────────────────────────')" \
            "$(arb '📦 تثبيت الحزم')" \
            "$(arb '🐚 إعداد Zsh + Oh-my-zsh')" \
            "$(arb '── التخصيص ────────────────────────')" \
            "$(arb '🧩 إدارة إضافات Zsh')" \
            "$(arb '🎨 تغيير الشعار')" \
            "$(arb '📝 تغيير العنوان')" \
            "$(arb '⌨️  تغيير الكيبورد')" \
            "$(arb '🎭 تغيير ثيم ZSH')" \
            "$(arb '── الصيانة ────────────────────────')" \
            "$update_opt" \
            "$(arb '💾 نسخة احتياطية')" \
            "$(arb '🚀 تثبيت الكل')" \
            "$(arb '🗑️  إزالة T-Header')" \
            "$(arb '❌ خروج')"
        ) || break

        echo
        case "$choice" in
            "──"*) continue ;;
            "📦"*) action_install_packages ;;
            "🐚"*) action_setup_zsh ;;
            "🧩"*) action_manage_plugins ;;
            "🎨"*) action_change_logo ;;
            "📝"*) action_change_title ;;
            "⌨️"*) action_change_keyboard ;;
            "🎭"*) action_change_theme ;;
            "🔄"*) action_update_tool ;;
            "💾"*) action_backup ;;
            "🚀"*) action_install_all ;;
            "🗑️"*) action_remove ;;
            "❌"*|"") break ;;
        esac
        echo
        gum confirm --default=false "$(arb 'العودة للقائمة الرئيسية؟')" || break
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
has fribidi || pkg install -y fribidi >/dev/null 2>&1 || true

generate_keyboards
log INFO "Session started (v${VERSION})"
msg "$(arb 'جاري فحص التحديثات...')"
check_for_updates

main_loop