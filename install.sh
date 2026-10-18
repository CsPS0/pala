#!/bin/bash
set -e

# =====================================================================
# Pala — Modern All-in-One Telepito es Komponens Kezelo Linux & macOS
# Hasznalat:
#   Interaktiv: curl -fsSL https://raw.githubusercontent.com/CsPS0/pala/main/install.sh | bash
#   Flagek:     curl -fsSL https://raw.githubusercontent.com/CsPS0/pala/main/install.sh | bash -s -- --all
#               curl -fsSL https://raw.githubusercontent.com/CsPS0/pala/main/install.sh | bash -s -- --cli
#               curl -fsSL https://raw.githubusercontent.com/CsPS0/pala/main/install.sh | bash -s -- --desktop
# =====================================================================

REPO="CsPS0/pala"
USER_BIN="$HOME/.local/bin"
mkdir -p "$USER_BIN"

# Reconnect stdin to controlling terminal if piped via curl | bash
if [ ! -t 0 ] && [ -e /dev/tty ]; then
    exec < /dev/tty
fi

# Detect OS & Arch
OS="$(uname -s)"
ARCH="$(uname -m)"

if [ "$OS" != "Linux" ] && [ "$OS" != "Darwin" ]; then
    echo "Hiba: Ez a telepito csak Linux es macOS rendszereken futtathato."
    exit 1
fi

# Default component selections
INSTALL_DESKTOP=1
INSTALL_CLI=1
DO_ADD_TO_PATH=1
DO_START_MENU=1
DO_DESKTOP_ICON=0
CUSTOM_FLAGS=0

# Parse CLI flags
for arg in "$@"; do
    case $arg in
        --all)
            INSTALL_DESKTOP=1
            INSTALL_CLI=1
            DO_ADD_TO_PATH=1
            DO_START_MENU=1
            DO_DESKTOP_ICON=1
            CUSTOM_FLAGS=1
            shift
            ;;
        --cli|--tui)
            INSTALL_DESKTOP=0
            INSTALL_CLI=1
            DO_ADD_TO_PATH=1
            DO_START_MENU=0
            DO_DESKTOP_ICON=0
            CUSTOM_FLAGS=1
            shift
            ;;
        --desktop|--gui)
            INSTALL_DESKTOP=1
            INSTALL_CLI=0
            DO_ADD_TO_PATH=0
            DO_START_MENU=1
            DO_DESKTOP_ICON=0
            CUSTOM_FLAGS=1
            shift
            ;;
        --help|-h)
            echo "Hasznalat: install.sh [--all | --cli | --desktop]"
            exit 0
            ;;
    esac
done

echo "============================================================="
echo " Pala — Telepito es Komponens Kezelo ($OS $ARCH)"
echo "============================================================="

# Interactive terminal checkbox wizard if running in an interactive terminal without flags
if [ "$CUSTOM_FLAGS" -eq 0 ] && [ -t 0 ]; then
    labels=(
        "Pala Desktop (Grafikus Flutter asztali alkalmazas)"
        "Pala CLI / TUI (Terminalos parancssori kliens)"
        "Hozzaadas a PATH kornyezeti valtozohoz"
        "Start menu / Alkalmazasindito bejegyzes letrehozasa"
        "Asztali parancsikon letrehozasa"
    )
    selected=(1 1 1 1 0)
    cursor=0
    count=${#labels[@]}

    tput civis 2>/dev/null || true

    cleanup_menu() {
        tput cnorm 2>/dev/null || true
        echo ""
    }
    trap cleanup_menu EXIT INT TERM

    render_menu() {
        for ((i=0; i<count+3; i++)); do
            tput cuu1 2>/dev/null || true
            tput el 2>/dev/null || true
        done

        echo -e "\033[1;36mPala Telepito Varazslo — Komponensek kivalasztasa\033[0m"
        echo -e "\033[90mHasznalat: Nyilak [Fel/Le], [SZOKOZ] kijeloles, [ENTER] megerosites\033[0m"
        echo -e "\033[90m-------------------------------------------------------------\033[0m"

        for ((i=0; i<count; i++)); do
            if [ "${selected[$i]}" -eq 1 ]; then
                box="[*]"
            else
                box="[ ]"
            fi

            if [ "$i" -eq "$cursor" ]; then
                echo -e "\033[1;33m > $box ${labels[$i]}\033[0m"
            else
                echo -e "\033[0m   $box \033[90m${labels[$i]}\033[0m"
            fi
        done
    }

    for ((i=0; i<count+3; i++)); do echo ""; done

    while true; do
        render_menu
        IFS= read -rsn1 key
        if [ "$key" = $'\x1b' ]; then
            read -rsn2 -t 0.1 seq
            if [ "$seq" = "[A" ]; then
                if [ "$cursor" -gt 0 ]; then ((cursor--)); else cursor=$((count - 1)); fi
            elif [ "$seq" = "[B" ]; then
                if [ "$cursor" -lt $((count - 1)) ]; then ((cursor++)); else cursor=0; fi
            fi
        elif [ "$key" = " " ]; then
            if [ "${selected[$cursor]}" -eq 1 ]; then
                selected[$cursor]=0
            else
                selected[$cursor]=1
            fi
        elif [ "$key" = "" ]; then
            break
        elif [ "$key" = "q" ] || [ "$key" = "Q" ]; then
            echo -e "\nTelepites megszakitva."
            exit 0
        fi
    done

    cleanup_menu
    trap - EXIT INT TERM

    INSTALL_DESKTOP=${selected[0]}
    INSTALL_CLI=${selected[1]}
    DO_ADD_TO_PATH=${selected[2]}
    DO_START_MENU=${selected[3]}
    DO_DESKTOP_ICON=${selected[4]}
fi

if [ "$INSTALL_DESKTOP" -eq 0 ] && [ "$INSTALL_CLI" -eq 0 ]; then
    echo "Nem valasztottal ki egyetlen komponenst sem a telepiteshez. Kilepes."
    exit 0
fi

# Resolve latest release
echo "Legfrissebb kiadas lekerdezese..."
LATEST_TAG=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$LATEST_TAG" ]; then
    LATEST_TAG="latest"
fi
echo "Telepitendo kiadas: $LATEST_TAG"
echo ""

# Helper to add directory to PATH
add_to_shell_path() {
    if [[ ":$PATH:" != *":$USER_BIN:"* ]]; then
        echo "A $USER_BIN hozzaadasa a PATH kornyezeti valtozohoz..."
        if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
        fi
        if [ -f "$HOME/.bashrc" ]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        fi
        if [ -f "$HOME/.profile" ]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
        fi
        export PATH="$USER_BIN:$PATH"
        echo "    [OK] PATH frissitve: $USER_BIN"
    fi
}

# 1. Desktop Installation
if [ "$INSTALL_DESKTOP" -eq 1 ]; then
    echo "[+] Pala Desktop telepitese..."
    if [ "$OS" = "Linux" ]; then
        DESKTOP_INSTALL_DIR="$HOME/.local/share/pala"
        mkdir -p "$DESKTOP_INSTALL_DIR"
        APPIMAGE_PATH="$DESKTOP_INSTALL_DIR/Pala.AppImage"
        
        APPIMAGE_URL="https://github.com/$REPO/releases/latest/download/Pala-x86_64.AppImage"
        echo "    Letoltes: $APPIMAGE_URL"
        if curl -fsSL -o "$APPIMAGE_PATH" "$APPIMAGE_URL"; then
            chmod +x "$APPIMAGE_PATH"
            ln -sf "$APPIMAGE_PATH" "$USER_BIN/pala-desktop"
            echo "    [OK] Pala AppImage telepitve ide: $APPIMAGE_PATH"
        else
            echo "    [!] Figyelem: Az AppImage letoltese sikertelen."
        fi

        # Download icon
        ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
        mkdir -p "$ICON_DIR"
        curl -fsSL -o "$ICON_DIR/pala.png" "https://raw.githubusercontent.com/$REPO/main/assets/icons/pala_icon_512.png" 2>/dev/null || true

        # Create Desktop launcher file
        if [ "$DO_START_MENU" -eq 1 ]; then
            APP_DIR="$HOME/.local/share/applications"
            mkdir -p "$APP_DIR"
            cat <<EOF > "$APP_DIR/pala.desktop"
[Desktop Entry]
Name=Pala Desktop
Comment=Modern, nyilt forraskodu Kreta kliens
Exec=$APPIMAGE_PATH
Icon=pala
Terminal=false
Type=Application
Categories=Education;Utility;
StartupNotify=true
EOF
            chmod +x "$APP_DIR/pala.desktop"
            echo "    [OK] Alkalmazasindito bejegyzes letrehozva: $APP_DIR/pala.desktop"
            if command -v update-desktop-database >/dev/null 2>&1; then
                update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
            fi
        fi

        if [ "$DO_DESKTOP_ICON" -eq 1 ] && [ -d "$HOME/Desktop" ]; then
            cp "$APP_DIR/pala.desktop" "$HOME/Desktop/pala.desktop" 2>/dev/null || true
            chmod +x "$HOME/Desktop/pala.desktop" 2>/dev/null || true
            echo "    [OK] Asztali parancsikon letrehozva: $HOME/Desktop/pala.desktop"
        fi

    elif [ "$OS" = "Darwin" ]; then
        DMG_URL="https://github.com/$REPO/releases/latest/download/Pala-macOS.dmg"
        TMP_DMG="/tmp/Pala-macOS.dmg"
        echo "    Letoltes: $DMG_URL"
        if curl -fsSL -o "$TMP_DMG" "$DMG_URL"; then
            MOUNT_DIR=$(mktemp -d)
            hdiutil attach "$TMP_DMG" -mountpoint "$MOUNT_DIR" -nobrowse -quiet
            if [ -d "$MOUNT_DIR/Pala.app" ]; then
                DEST_APP="/Applications/Pala.app"
                if [ ! -w "/Applications" ]; then
                    DEST_APP="$HOME/Applications/Pala.app"
                    mkdir -p "$HOME/Applications"
                fi
                rm -rf "$DEST_APP"
                cp -R "$MOUNT_DIR/Pala.app" "$DEST_APP"
                xattr -cr "$DEST_APP" 2>/dev/null || true
                echo "    [OK] Pala.app sikeresen telepitve ide: $DEST_APP"

                if [ "$DO_DESKTOP_ICON" -eq 1 ] && [ -d "$HOME/Desktop" ]; then
                    ln -sf "$DEST_APP" "$HOME/Desktop/Pala.app"
                    echo "    [OK] Asztali parancsikon letrehozva: $HOME/Desktop/Pala.app"
                fi
            fi
            hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true
            rm -rf "$MOUNT_DIR" "$TMP_DMG"
        else
            echo "    [!] Figyelem: A macOS DMG letoltese sikertelen."
        fi
    fi
fi

# 2. CLI Installation
if [ "$INSTALL_CLI" -eq 1 ]; then
    echo "[+] Pala CLI / TUI telepitese..."
    if [ "$OS" = "Linux" ]; then
        CLI_ASSET="pala-linux"
    else
        CLI_ASSET="pala-macos"
    fi

    CLI_URL="https://github.com/$REPO/releases/latest/download/$CLI_ASSET"
    TMP_CLI="/tmp/pala_cli_$$"
    
    echo "    Letoltes: $CLI_URL"
    if curl -fsSL -o "$TMP_CLI" "$CLI_URL"; then
        chmod +x "$TMP_CLI"
        
        TARGET_BIN="$USER_BIN/pala"
        mv "$TMP_CLI" "$TARGET_BIN"
        if [ "$OS" = "Darwin" ]; then
            xattr -d com.apple.quarantine "$TARGET_BIN" 2>/dev/null || true
        fi
        echo "    [OK] Pala CLI sikeresen telepitve ide: $TARGET_BIN"
    else
        echo "    [!] Figyelem: A CLI binaris letoltese sikertelen."
    fi

    if [ "$DO_ADD_TO_PATH" -eq 1 ]; then
        add_to_shell_path
    fi
fi

echo ""
echo "============================================================="
echo " A telepites es beallitas sikeresen befejezodott!"
echo " Inditas: "
if [ "$INSTALL_CLI" -eq 1 ]; then
    echo "   - Terminalban:       pala"
fi
if [ "$INSTALL_DESKTOP" -eq 1 ]; then
    if [ "$OS" = "Linux" ]; then
        echo "   - Alkalmazasbol:    Pala Desktop"
        echo "   - Parancssorbol:     pala-desktop"
    else
        echo "   - Alkalmazasbol:    /Applications/Pala.app"
    fi
fi
echo "============================================================="
