#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════════════
#  T-HEADER CONTROL PANEL
# ═══════════════════════════════════════════════════════════════════════
#  Version : 4.4.0 (Bilingual Bulletproof Edition)
#  Based on: remo7777/T-Header — rewritten as a unified control panel
#  License : MIT
# ═══════════════════════════════════════════════════════════════════════

set -euo pipefail
shopt -s inherit_errexit

readonly VERSION="4.4.0"
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

# ─── Language (AR/EN) ────────────────────────────────────────────────
LANG_MODE="ar"
[[ -s "$CONFIG_DIR/lang.cfg" ]] && LANG_MODE="$(cat "$CONFIG_DIR/lang.cfg" 2>/dev/null || echo ar)"
[[ "$LANG_MODE" == "en" ]] || LANG_MODE="ar"

declare -A TR_AR=(
  [banner_sub]="لوحة تحكم موحدة لمشروع T-Header"
  [m_setup]="الإعداد"
  [m_custom]="التخصيص"
  [m_maint]="الصيانة"
  [m_pkgs]="تثبيت الحزم"
  [m_zsh]="إعداد Zsh"
  [m_plugins]="إدارة الإضافات"
  [m_logo]="تغيير الشعار"
  [m_title]="تغيير العنوان"
  [m_kb]="تغيير الكيبورد"
  [m_theme]="تغيير الثيم"
  [m_upd]="تحديث اللوحة"
  [m_chk]="فحص التحديثات"
  [m_backup]="نسخة احتياطية"
  [m_all]="تثبيت الكل"
  [m_hdr_on]="إخفاء هيدر الترمينال"
  [m_hdr_off]="تشغيل هيدر الترمينال"
  [m_lang]="Switch to English"
  [m_remove]="إزالة T-Header"
  [m_exit]="خروج"
  [p_ext]="تثبيت إضافات خارجية"
  [p_bi]="تفعيل إضافات داخلية"
  [p_list]="عرض الإضافات المفعلة"
  [p_rm]="إزالة إضافة"
  [p_back]="رجوع"
  [q_back]="العودة للقائمة الرئيسية؟ (Y/n)"
  [q_all]="تثبيت كل شيء (حزم + Zsh + ثيم + إضافات)؟"
  [q_rm]="إزالة T-Header بالكامل؟"
  [q_upd]="هل تريد تطبيق التحديث؟"
  [q_del_folder]="حذف مجلد الإضافة أيضاً؟"
  [u_avail]="يوجد تحديث جديد"
  [u_err]="فشل فحص التحديثات."
  [bye]="وداعاً 👋"
)
declare -A TR_EN=(
  [banner_sub]="Unified control panel for T-Header"
  [m_setup]="Setup"
  [m_custom]="Customize"
  [m_maint]="Maintenance"
  [m_pkgs]="Install Packages"
  [m_zsh]="Setup Zsh"
  [m_plugins]="Manage Plugins"
  [m_logo]="Change Logo"
  [m_title]="Change Title"
  [m_kb]="Change Keyboard"
  [m_theme]="Change Theme"
  [m_upd]="Update Tool"
  [m_chk]="Check Updates"
  [m_backup]="Backup"
  [m_all]="Install Everything"
  [m_hdr_on]="Disable Terminal Header"
  [m_hdr_off]="Enable Terminal Header"
  [m_lang]="التبديل للعربية"
  [m_remove]="Remove T-Header"
  [m_exit]="Exit"
  [p_ext]="Install External Plugins"
  [p_bi]="Enable Built-in Plugins"
  [p_list]="List Active Plugins"
  [p_rm]="Remove Plugin"
  [p_back]="Back"
  [q_back]="Return to main menu? (Y/n)"
  [q_all]="Install EVERYTHING (packages + Zsh + theme + plugins)?"
  [q_rm]="Remove T-Header completely?"
  [q_upd]="Apply the update?"
  [q_del_folder]="Delete the plugin folder too?"
  [u_avail]="New update available"
  [u_err]="Failed to check for updates."
  [bye]="Goodbye 👋"
)

t() {
    local k="$1"
    if [[ "$LANG_MODE" == "ar" ]]; then
        printf '%s' "${TR_AR[$k]:-$k}" | fribidi --nopad 2>/dev/null || printf '%s' "${TR_AR[$k]:-$k}"
    else
        printf '%s' "${TR_EN[$k]:-$k}"
    fi
}

toggle_language() {
    if [[ "$LANG_MODE" == "ar" ]]; then LANG_MODE="en"; else LANG_MODE="ar"; fi
    printf '%s\n' "$LANG_MODE" > "$CONFIG_DIR/lang.cfg"
    ok "Language switched ($( [[ "$LANG_MODE" == ar ]] && echo العربية || echo English ))"
}

# ─── Utilities ───────────────────────────────────────────────────────
has() { command -v "$1" &>/dev/null; }

confirm_action() {
    local msg="$1"
    local ans
    read -r -p "$(echo -e "\e[1;33m$msg \e[0m")" ans || return 1
    [[ "$ans" =~ ^[Yy]$ ]] || [[ -z "$ans" && "$msg" == *"(Y/n)"* ]]
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
        return 0
    fi
    REMOTE_VERSION=$(printf '%s\n' "$raw_content" | grep -E '^readonly VERSION=' | head -n 1 | cut -d'"' -f2 || true)
    if [[ -n "$REMOTE_VERSION" && "$REMOTE_VERSION" != "$VERSION" ]]; then
        HAS_UPDATE=true
    fi
}

# ─── Branding ────────────────────────────────────────────────────────
banner() {
    printf "\033c"
    if has figlet && has lolcat; then
        figlet -f small "T-HEADER" 2>/dev/null | lolcat -f 2>/dev/null || true
    fi
    local update_msg=""
    if [[ "$HAS_UPDATE" == "true" ]]; then
        update_msg="🚀 $(t u_avail): v$REMOTE_VERSION"
    elif [[ "$UPDATE_ERROR" == "true" ]]; then
        update_msg="⚠️ $(t u_err)"
    fi

    gum style \
        --border double --padding "0 3" \
        --foreground "$CLR_PRIMARY" --border-foreground "$CLR_PRIMARY" \
        "⚡  ${APP_NAME}" \
        "$(t banner_sub)" \
        "v${VERSION}  •  Termux Customization Suite  •  $( [[ "$LANG_MODE" == ar ]] && echo AR || echo EN )" \
        "$update_msg"
    echo
}

# ─── Core Actions ────────────────────────────────────────────────────
generate_keyboards() {
    [[ -f "$TPT_DIR/kb-default.properties" ]] || echo "extra-keys = []" > "$TPT_DIR/kb-default.properties"
    [[ -f "$TPT_DIR/kb-standard.properties" ]] || cat > "$TPT_DIR/kb-standard.properties" <<'EOF'
extra-keys = [ \
 ['ESC','/','-','HOME','UP','END','PGUP'], \
 ['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN'] \
]
EOF
    [[ -f "$TPT_DIR/kb-programmer.properties" ]] || cat > "$TPT_DIR/kb-programmer.properties" <<'EOF'
extra-keys = [ \
 ['ESC','|','/','HOME','UP','END','PGUP','~'], \
 ['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN','|'] \
]
EOF
    [[ -f "$TPT_DIR/kb-numbers.properties" ]] || cat > "$TPT_DIR/kb-numbers.properties" <<'EOF'
extra-keys = [ \
 ['1','2','3','4','5','6','7','8','9','0'], \
 ['ESC','TAB','+','-','/','*','(',')','<','>'] \
]
EOF
}

action_install_packages() {
    msg "Installing basic packages..."
    gum spin --spinner dot --title "Updating packages..." -- bash -c 'yes | pkg update -y' >/dev/null 2>&1 || true
    gum spin --spinner dot --title "Installing tools..." -- pkg install -y git zsh curl wget figlet lolcat boxes fzf gum bat eza ncurses-utils fribidi >/dev/null 2>&1 || true
    ok "Packages installed | تم تثبيت الحزم"
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
                git clone --depth=1 https://gitee.com/mirrors/ohmyzsh.git "$HOME/.oh-my-zsh" >/dev/null 2>&1 || true
        fi
    fi
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        err "Failed to install Oh-my-zsh."
        return 1
    fi
    [[ -f "$HOME/.zshrc" ]] || cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
    create_shortcuts
    write_aliases_block
    ok "Zsh setup completed | تم إعداد Zsh"
}

# ─── Shortcuts (clogo / ctitle / ctpro / cztheme) ────────────────────
create_shortcuts() {
    local pair n a
    for pair in "clogo:logo" "ctitle:title" "ctpro:keyboard" "cztheme:theme"; do
        n="${pair%%:*}"; a="${pair##*:}"
        printf '#!/data/data/com.termux/files/usr/bin/bash\nexec "$PREFIX/bin/theader" %s\n' "$a" > "$PREFIX/bin/$n"
        chmod +x "$PREFIX/bin/$n"
    done
}

# ─── Aliases + Terminal Header blocks in .zshrc ──────────────────────
write_aliases_block() {
    cat > "$CONFIG_DIR/aliases" <<'EOF'
# Modern replacements (only if the tool exists)
command -v eza >/dev/null 2>&1 && alias ls='eza --icons' ll='eza -la --icons' la='eza -a --icons'
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'
alias cls='clear'
alias ports='ss -tulanp 2>/dev/null || netstat -tulanp'
EOF
    local zrc="$HOME/.zshrc"
    [[ -f "$zrc" ]] || return 0
    grep -q "theader aliases >>>" "$zrc" || cat >> "$zrc" <<'EOF'

# >>> theader aliases >>>
[ -f "$HOME/.config/theader/aliases" ] && source "$HOME/.config/theader/aliases"
# <<< theader aliases <<<
EOF
}

generate_header_sh() {
    cat > "$CONFIG_DIR/header.sh" <<'EOF'
# T-Header terminal greeting
TH_CFG="$HOME/.config/theader"
if command -v figlet >/dev/null 2>&1; then
    TH_TITLE="T-Header"
    [[ -s "$TH_CFG/title.cfg" ]] && TH_TITLE="$(cat "$TH_CFG/title.cfg")"
    if command -v lolcat >/dev/null 2>&1; then
        figlet -f small "$TH_TITLE" 2>/dev/null | lolcat -f 2>/dev/null
    else
        figlet -f small "$TH_TITLE" 2>/dev/null
    fi
fi
[[ -s "$TH_CFG/active.logo" ]] && cat "$TH_CFG/active.logo" 2>/dev/null
EOF
}

action_toggle_header() {
    local zrc="$HOME/.zshrc"
    [[ -f "$zrc" ]] || { err ".zshrc not found. Setup Zsh first."; return 1; }
    generate_header_sh
    if grep -q "theader header >>>" "$zrc"; then
        sed -i '/theader header >>>/,/theader header <<</d' "$zrc"
        ok "Terminal header disabled | تم إخفاء الهيدر"
    else
        cat >> "$zrc" <<'EOF'

# >>> theader header >>>
[ -f "$HOME/.config/theader/header.sh" ] && source "$HOME/.config/theader/header.sh"
# <<< theader header <<<
EOF
        ok "Terminal header enabled — open a new session | تم تشغيل الهيدر"
    fi
}

# ─── Zsh Plugin Manager (fixed) ──────────────────────────────────────
get_active_plugins() {
    [[ -f "$HOME/.zshrc" ]] || return 0
    awk '
        /^[[:space:]]*#/ { next }
        inblk {
            if (/^[[:space:]]*\)/) { exit }
            print
            next
        }
        /^[[:space:]]*plugins=\(/ {
            sub(/^[[:space:]]*plugins=\(/, "")
            if (sub(/\)[[:space:]]*(#.*)?$/, "")) {
                gsub(/[[:space:]]+/, "\n"); print; exit
            }
            print
            inblk=1
            next
        }
    ' "$HOME/.zshrc" | tr -s '[:space:]' '\n' | sed '/^$/d' | sort -u
}

update_zshrc_plugins() {
    local action="$1"
    local target_plugin="$2"
    local zrc="$HOME/.zshrc"
    local temp_zrc="${zrc}.tmp"

    cp "$zrc" "$BACKUP_DIR/zshrc.$(date +%s)"

    local plugins=() p
    while IFS= read -r p; do
        [[ -n "$p" ]] && plugins+=("$p")
    done < <(get_active_plugins)

    if [[ "$action" == "add" ]]; then
        for p in ${plugins[@]+"${plugins[@]}"}; do
            if [[ "$p" == "$target_plugin" ]]; then
                warn "Plugin already enabled: $target_plugin | الإضافة مفعلة بالفعل"
                return 0
            fi
        done
        plugins+=("$target_plugin")
    elif [[ "$action" == "remove" ]]; then
        local new_plugins=()
        for p in ${plugins[@]+"${plugins[@]}"}; do
            [[ "$p" != "$target_plugin" ]] && new_plugins+=("$p")
        done
        plugins=(${new_plugins[@]+"${new_plugins[@]}"})
    fi

    # zsh-syntax-highlighting must always be LAST (official recommendation)
    local ordered=()
    for p in ${plugins[@]+"${plugins[@]}"}; do
        [[ "$p" == "zsh-syntax-highlighting" ]] && continue
        ordered+=("$p")
    done
    for p in ${plugins[@]+"${plugins[@]}"}; do
        [[ "$p" == "zsh-syntax-highlighting" ]] && ordered+=("$p")
    done
    plugins=(${ordered[@]+"${ordered[@]}"})

    local plugin_str=""
    for p in ${plugins[@]+"${plugins[@]}"}; do
        plugin_str+="$p "
    done

    # Rebuild the plugins block cleanly:
    #  - replaces every (commented or not) plugins block, single-line or multi-line
    #  - never consumes lines after the block (the old bug)
    #  - if no block exists, inserts the line right BEFORE sourcing oh-my-zsh.sh
    awk -v p_str="plugins=( $plugin_str)" '
        /^[[:space:]]*#/ { print; next }
        in_block {
            if (/^[[:space:]]*\)/) { in_block=0 }
            next
        }
        /^[[:space:]]*plugins=\(/ {
            if (!done) { print p_str; done=1 }
            if ($0 !~ /^[[:space:]]*plugins=\([^)]*\)[[:space:]]*(#.*)?$/) { in_block=1 }
            next
        }
        /^[[:space:]]*source.*oh-my-zsh/ {
            if (!done) { print p_str; print ""; done=1 }
            print
            next
        }
        { print }
    ' "$zrc" > "$temp_zrc"

    if ! grep -q "^[[:space:]]*plugins=(" "$temp_zrc"; then
        echo "plugins=( $plugin_str)" >> "$temp_zrc"
    fi

    mv "$temp_zrc" "$zrc"

    if [[ "$action" == "add" ]]; then
        ok "Plugin enabled: $target_plugin | تم تفعيل الإضافة"
    else
        ok "Plugin removed: $target_plugin | تم إزالة الإضافة"
    fi
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
    update_zshrc_plugins "add" "$name"
}

action_manage_plugins() {
    if [[ ! -f "$HOME/.zshrc" ]]; then
        err ".zshrc not found. Setup Zsh first."
        return 0
    fi

    local choice
    choice=$(printf "%s\n" \
        " 1) Install External | $(t p_ext)" \
        " 2) Enable Built-in  | $(t p_bi)" \
        " 3) List Active      | $(t p_list)" \
        " 4) Remove Plugin    | $(t p_rm)" \
        " 5) Back             | $(t p_back)" | \
        fzf --reverse --height 100% --border --info=inline --prompt "Plugin Manager > " --pointer "▶ ") || return 0

    case "$choice" in
        *"Install External"*)
            local active_list
            active_list=$(get_active_plugins)

            local chk1="[ ]" chk2="[ ]" chk3="[ ]" chk4="[ ]" chk5="[ ]" chk6="[ ]"
            grep -qw "zsh-autosuggestions" <<< "$active_list" && chk1="[✓]"
            grep -qw "zsh-syntax-highlighting" <<< "$active_list" && chk2="[✓]"
            grep -qw "zsh-completions" <<< "$active_list" && chk3="[✓]"
            grep -qw "fzf-tab" <<< "$active_list" && chk4="[✓]"
            grep -qw "zsh-history-substring-search" <<< "$active_list" && chk5="[✓]"
            grep -qw "zsh-you-should-use" <<< "$active_list" && chk6="[✓]"

            local selected
            selected=$(printf "%s\n" \
                " 1) $chk1 zsh-autosuggestions | اقتراحات تلقائية" \
                " 2) $chk2 zsh-syntax-highlighting | تلوين الأوامر" \
                " 3) $chk3 zsh-completions | إكمال إضافي" \
                " 4) $chk4 fzf-tab | بحث تفاعلي بالملفات" \
                " 5) $chk5 zsh-history-substring-search | بحث في الأوامر" \
                " 6) $chk6 zsh-you-should-use | تذكير بالاختصارات" | \
                fzf --multi --reverse --height 100% --border --info=inline --prompt "Select plugins (Tab to multi-select) > " --pointer "▶ ") || return 0

            local line plugin
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                plugin=""
                case "$line" in
                    *zsh-autosuggestions*)          plugin="zsh-autosuggestions" ;;
                    *zsh-syntax-highlighting*)      plugin="zsh-syntax-highlighting" ;;
                    *zsh-completions*)              plugin="zsh-completions" ;;
                    *fzf-tab*)                      plugin="fzf-tab" ;;
                    *zsh-history-substring-search*) plugin="zsh-history-substring-search" ;;
                    *zsh-you-should-use*)           plugin="zsh-you-should-use" ;;
                esac
                if [[ -n "$plugin" ]]; then
                    case "$plugin" in
                        "zsh-autosuggestions")          install_omz_plugin "$plugin" "https://github.com/zsh-users/zsh-autosuggestions" || true ;;
                        "zsh-syntax-highlighting")      install_omz_plugin "$plugin" "https://github.com/zsh-users/zsh-syntax-highlighting" || true ;;
                        "zsh-completions")              install_omz_plugin "$plugin" "https://github.com/zsh-users/zsh-completions" || true ;;
                        "fzf-tab")                      install_omz_plugin "$plugin" "https://github.com/Aloxaf/fzf-tab" || true ;;
                        "zsh-history-substring-search") install_omz_plugin "$plugin" "https://github.com/zsh-users/zsh-history-substring-search" || true ;;
                        "zsh-you-should-use")           install_omz_plugin "$plugin" "https://github.com/MichaelAquilina/zsh-you-should-use" || true ;;
                    esac
                fi
            done <<< "$selected"
            ;;
        *"Enable Built-in"*)
            local selected line plugin
            selected=$(printf "%s\n" \
                " 1) git" " 2) extract" " 3) colored-man-pages" " 4) command-not-found" \
                " 5) sudo" " 6) web-search" " 7) cp" " 8) z" | \
                fzf --multi --reverse --height 100% --border --info=inline --prompt "Select built-in plugins > " --pointer "▶ ") || return 0
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                plugin=$(echo "$line" | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]*//')
                update_zshrc_plugins "add" "$plugin" || true
            done <<< "$selected"
            ;;
        *"List Active"*)
            local active_list plugin output="" count=1
            active_list=$(get_active_plugins)

            if [[ -z "$active_list" ]]; then
                warn "No active plugins found. | لا توجد إضافات مفعلة."
            else
                while IFS= read -r plugin; do
                    [[ -z "$plugin" ]] && continue
                    output+="  $count) $plugin"$'\n'
                    count=$((count + 1))
                done <<< "$active_list"
                gum style --border rounded --padding "1 2" \
                    --foreground "$CLR_SUCCESS" --border-foreground "$CLR_SUCCESS" \
                    "Active Plugins | الإضافات المفعلة" <<< "$output"
            fi
            ;;
        *"Remove Plugin"*)
            local active_list to_remove zc
            active_list=$(get_active_plugins)
            [[ -z "$active_list" ]] && { warn "No plugins registered"; return 0; }

            to_remove=$(echo "$active_list" | fzf --reverse --height 100% --border --info=inline --prompt "Select plugin to remove > " --pointer "▶ ") || return 0
            [[ -z "$to_remove" ]] && return 0

            update_zshrc_plugins "remove" "$to_remove" || true

            # Optional: delete the plugin folder as well (validated name, no path injection)
            if [[ "$to_remove" =~ ^[A-Za-z0-9._-]+$ ]]; then
                zc="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
                if [[ -d "$zc/plugins/$to_remove" ]] && confirm_action "$(t q_del_folder) [$to_remove] (y/N): "; then
                    rm -rf "$zc/plugins/$to_remove"
                fi
            fi
            ;;
    esac
}

# ─── Customizations & Maintenance ────────────────────────────────────
action_change_logo() {
    if [[ ! -d "$LOGO_DIR" || -z "$(ls -A "$LOGO_DIR" 2>/dev/null)" ]]; then
        err "No logos in: $LOGO_DIR"
        return 1
    fi
    local logo indent
    logo=$(ls "$LOGO_DIR" | fzf --reverse --height 100% --border --info=inline --prompt "Select Logo > " --pointer "▶ ") || return 0
    indent=$(printf "%s\n" 2 3 4 5 6 | fzf --reverse --height 100% --border --info=inline --prompt "Indent > " --pointer "▶ ") || indent=2
    cp "$LOGO_DIR/$logo" "$CONFIG_DIR/active.logo"
    printf '%s\n' "$indent" > "$CONFIG_DIR/indent.cfg"
    ok "Logo applied: $logo"
}

action_change_title() {
    local title
    title=$(gum input --header "Enter new title:" --placeholder "T-Header" --prompt "› ") || return 0
    [[ -z "$title" ]] && return 0
    printf '%s\n' "$title" > "$CONFIG_DIR/title.cfg"
    ok "Title saved: $title"
}

action_change_keyboard() {
    generate_keyboards
    local file
    file=$(ls "$TPT_DIR" 2>/dev/null | fzf --reverse --height 100% --border --info=inline --prompt "Select Layout > " --pointer "▶ ") || return 0
    [[ -z "$file" ]] && return 0
    [[ -f "$HOME/.termux/termux.properties" ]] && cp "$HOME/.termux/termux.properties" "$BACKUP_DIR/termux.$(date +%s)"
    mkdir -p "$HOME/.termux"
    cp "$TPT_DIR/$file" "$HOME/.termux/termux.properties"
    termux-reload-settings 2>/dev/null || true
    ok "Keyboard applied: $file"
}

action_change_theme() {
    local t_dir="$HOME/.oh-my-zsh/themes" c_dir="$HOME/.oh-my-zsh/custom/themes"
    [[ ! -d "$t_dir" && ! -d "$c_dir" ]] && { err "Oh-my-zsh not installed."; return 1; }
    local themes theme
    themes=$( (ls "$t_dir" 2>/dev/null; ls "$c_dir" 2>/dev/null) | grep '\.zsh-theme$' | sed 's/\.zsh-theme$//' | sort -u)
    [[ -z "$themes" ]] && { err "No themes found."; return 1; }
    theme=$(printf '%s\n' "$themes" | fzf --reverse --height 100% --border --info=inline --prompt "Search Theme > " --pointer "▶ ") || return 0
    [[ -z "$theme" ]] && return 0
    cp "$HOME/.zshrc" "$BACKUP_DIR/zshrc.$(date +%s)"
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
    if [[ "$UPDATE_ERROR" == "true" ]]; then warn "Failed to connect to GitHub."; return 0; fi
    if [[ "$HAS_UPDATE" == "false" ]]; then ok "You are on the latest version."; return 0; fi

    confirm_action "$(t q_upd) (v$REMOTE_VERSION) (y/N): " || return 0
    msg "Updating tool..."
    TEMP_FILE=$(mktemp)
    if gum spin --spinner globe --title "Downloading..." -- curl -fsSL "$REPO_URL" -o "$TEMP_FILE"; then
        if grep -q "T-HEADER CONTROL PANEL" "$TEMP_FILE"; then
            chmod +x "$TEMP_FILE"
            mv "$TEMP_FILE" "$PREFIX/bin/theader"
            ok "Update successful! Restarting..."
            sleep 2
            exec "$PREFIX/bin/theader"
        else
            err "Downloaded file is invalid. Update aborted."
            rm -f "$TEMP_FILE"
        fi
    else
        err "Update failed. Check internet."
        rm -f "$TEMP_FILE"
    fi
}

action_install_all() {
    confirm_action "$(t q_all) (y/N): " || return 0
    action_install_packages || true
    action_setup_zsh || true
    install_omz_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions" || true
    install_omz_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting" || true
    generate_keyboards
    mkdir -p "$HOME/.termux" && cp "$TPT_DIR/kb-standard.properties" "$HOME/.termux/termux.properties"
    termux-reload-settings 2>/dev/null || true
    [[ -f "$HOME/.zshrc" ]] && sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"agnoster\"/" "$HOME/.zshrc"
    # enable terminal greeting by default
    generate_header_sh
    if [[ -f "$HOME/.zshrc" ]] && ! grep -q "theader header >>>" "$HOME/.zshrc"; then
        cat >> "$HOME/.zshrc" <<'EOF'

# >>> theader header >>>
[ -f "$HOME/.config/theader/header.sh" ] && source "$HOME/.config/theader/header.sh"
# <<< theader header <<<
EOF
    fi
    ok "Full installation complete! Restart Termux. | التثبيت اكتمل — أعد تشغيل الترمينال"
}

action_remove() {
    confirm_action "$(t q_rm) (y/N): " || return 0
    action_backup || true
    rm -rf "$CONFIG_DIR"
    rm -f "$HOME/.termux/termux.properties"
    sed -i '/theader/d' "$HOME/.zshrc" 2>/dev/null || true
    ok "T-Header removed. Backups kept in: $BACKUP_DIR"
}

# ─── Main Menu ────────────────────────────────────────────────────────
main_loop() {
    while true; do
        banner
        local choice update_opt hdr_opt

        if [[ "$HAS_UPDATE" == "true" ]]; then
            update_opt="11) 🔄 $(t m_upd)"
        else
            update_opt="11) 🔄 $(t m_chk)"
        fi

        if grep -q "theader header >>>" "$HOME/.zshrc" 2>/dev/null; then
            hdr_opt="14) 🖥️  $(t m_hdr_on)"
        else
            hdr_opt="14) 🖥️  $(t m_hdr_off)"
        fi

        choice=$(printf "%s\n" \
            " 1) ── $(t m_setup) ──────────────────────────" \
            " 2) 📦 $(t m_pkgs)" \
            " 3) 🐚 $(t m_zsh)" \
            " 4) ── $(t m_custom) ──────────────────────────" \
            " 5) 🧩 $(t m_plugins)" \
            " 6) 🎨 $(t m_logo)" \
            " 7) 📝 $(t m_title)" \
            " 8) ⌨️  $(t m_kb)" \
            " 9) 🎭 $(t m_theme)" \
            "10) ── $(t m_maint) ──────────────────────────" \
            "$update_opt" \
            "12) 💾 $(t m_backup)" \
            "13) 🚀 $(t m_all)" \
            "$hdr_opt" \
            "15) 🌐 $(t m_lang)" \
            "16) 🗑️  $(t m_remove)" \
            "17) ❌ $(t m_exit)" | \
            fzf --reverse --height 100% --border --info=inline --prompt "Select (number or arrows) > " --pointer "▶ ") || break

        echo
        case "$choice" in
            *"──"*) continue ;;
            *"Install Packages"*|*"تثبيت الحزم"*)      action_install_packages || true ;;
            *"Setup Zsh"*|*"إعداد Zsh"*)               action_setup_zsh || true ;;
            *"Manage Plugins"*|*"إدارة الإضافات"*)     action_manage_plugins || true ;;
            *"Change Logo"*|*"تغيير الشعار"*)          action_change_logo || true ;;
            *"Change Title"*|*"تغيير العنوان"*)        action_change_title || true ;;
            *"Change Keyboard"*|*"تغيير الكيبورد"*)    action_change_keyboard || true ;;
            *"Change Theme"*|*"تغيير الثيم"*)          action_change_theme || true ;;
            *"Update Tool"*|*"تحديث اللوحة"*|*"Check Updates"*|*"فحص التحديثات"*) action_update_tool || true ;;
            *"Backup"*|*"نسخة احتياطية"*)              action_backup || true ;;
            *"Install Everything"*|*"تثبيت الكل"*)     action_install_all || true ;;
            *"Terminal Header"*|*"هيدر الترمينال"*)    action_toggle_header || true ;;
            *"Switch to English"*|*"للعربية"*)         toggle_language || true ;;
            *"Remove T-Header"*|*"إزالة T-Header"*)    action_remove || true ;;
            *"Exit"*|*"خروج"*|"")                      break ;;
        esac
        echo
        confirm_action "$(t q_back) " || break
    done
    clear
    gum style --foreground "$CLR_DIM" "$(t bye)"
}

# ─── CLI ──────────────────────────────────────────────────────────────
case "${1:-}" in
    -h|--help)
        cat <<EOF
${APP_NAME} v${VERSION}
Usage: $(basename "$0") [OPTION|COMMAND]
Options:
  -h, --help      Show this help
  -v, --version   Show version
  -u, --update    Force update to latest version
  -l, --log       Open log file
Commands (direct):
  logo, title, keyboard, theme   Open the corresponding action
  (no args)                      Launch interactive menu
EOF
        exit 0 ;;
    -v|--version) echo "${APP_NAME} v${VERSION}"; exit 0 ;;
    -u|--update)  check_for_updates; action_update_tool || true; exit 0 ;;
    -l|--log)     [[ -f "$LOG_FILE" ]] && less "$LOG_FILE" || echo "No log yet"; exit 0 ;;
    logo)         action_change_logo || true; exit 0 ;;
    title)        action_change_title || true; exit 0 ;;
    keyboard)     action_change_keyboard || true; exit 0 ;;
    theme)        action_change_theme || true; exit 0 ;;
esac

# ─── Entrypoint ───────────────────────────────────────────────────────
has gum     || { echo "Installing gum...";     pkg install -y gum     || exit 1; }
has fzf     || { echo "Installing fzf...";     pkg install -y fzf     || exit 1; }
has fribidi || pkg install -y fribidi >/dev/null 2>&1 || true

generate_keyboards
log INFO "Session started (v${VERSION}) | lang=$LANG_MODE"
msg "Checking for updates..."
check_for_updates

main_loop
