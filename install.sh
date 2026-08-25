#!/bin/bash
set -e

# Pala All-in-One Installer for Linux & macOS
# Usage:
#   Interactive: curl -fsSL https://raw.githubusercontent.com/CsPS0/pala/main/install.sh | bash
#   Flags:       curl -fsSL https://raw.githubusercontent.com/CsPS0/pala/main/install.sh | bash -s -- --all
#                curl -fsSL https://raw.githubusercontent.com/CsPS0/pala/main/install.sh | bash -s -- --cli
#                curl -fsSL https://raw.githubusercontent.com/CsPS0/pala/main/install.sh | bash -s -- --desktop

REPO="CsPS0/pala"
INSTALL_CHOICE="all"

# Parse CLI flags if provided
for arg in "$@"; do
    case $arg in
        --all)
            INSTALL_CHOICE="all"
            shift
            ;;
        --cli|--tui)
            INSTALL_CHOICE="cli"
            shift
            ;;
        --desktop|--gui)
            INSTALL_CHOICE="desktop"
            shift
            ;;
    esac
done

echo "============================================================="
echo " Pala — Telepito Linux es macOS rendszerekre"
echo "============================================================="

# Detect OS
OS="$(uname -s)"
ARCH="$(uname -m)"

if [ "$OS" != "Linux" ] && [ "$OS" != "Darwin" ]; then
    echo "Hiba: Ez a telepito csak Linux es macOS rendszereken futtathato."
    exit 1
fi

# Query latest version from GitHub API
echo "Legfrissebb verzio lekerdezese..."
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$LATEST_RELEASE" ]; then
    LATEST_RELEASE="v1.2.3"
fi
echo "Telepitendo verzio: $LATEST_RELEASE ($OS $ARCH)"
echo ""

# Interactive prompt if running in interactive terminal and no explicit flag passed
if [ -t 0 ] && [ "$#" -eq 0 ]; then
    echo "Valaszd ki, mit szeretnel telepiteni:"
    echo "  1) Teljes csomag: Pala Desktop + CLI a PATH-ban (Ajanlott)"
    echo "  2) Csak Pala CLI / TUI (Terminalos parancssori eszkoz)"
    echo "  3) Csak Pala Desktop (Grafikus asztali alkalmazas)"
    read -p "Valasztasod [1-3, alapertelmezett: 1]: " USER_CHOICE
    case $USER_CHOICE in
        2) INSTALL_CHOICE="cli" ;;
        3) INSTALL_CHOICE="desktop" ;;
        *) INSTALL_CHOICE="all" ;;
    esac
    echo ""
fi

# Ensure ~/.local/bin exists and is in PATH
USER_BIN="$HOME/.local/bin"
mkdir -p "$USER_BIN"

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
    fi
}

# 1. Install CLI / TUI
install_cli() {
    echo "[+] Pala CLI / TUI telepitese..."
    if [ "$OS" = "Linux" ]; then
        CLI_ASSET="pala-linux"
    else
        CLI_ASSET="pala-macos"
    fi

    CLI_URL="https://github.com/$REPO/releases/download/$LATEST_RELEASE/$CLI_ASSET"
    TMP_CLI="/tmp/pala_cli_$$"
    
    echo "    Letoltes: $CLI_URL"
    if curl -fsSL -o "$TMP_CLI" "$CLI_URL"; then
        chmod +x "$TMP_CLI"
        
        # Try /usr/local/bin if writable, else ~/.local/bin
        if [ -w "/usr/local/bin" ]; then
            mv "$TMP_CLI" "/usr/local/bin/pala"
            echo "    Sikeresen telepitve ide: /usr/local/bin/pala"
        elif command -v sudo >/dev/null 2>&1; then
            sudo mv "$TMP_CLI" "/usr/local/bin/pala"
            echo "    Sikeresen telepitve ide: /usr/local/bin/pala (sudo)"
        else
            mv "$TMP_CLI" "$USER_BIN/pala"
            add_to_shell_path
            echo "    Sikeresen telepitve ide: $USER_BIN/pala"
        fi
    else
        echo "    Figyelem: A CLI asset nem toltheto le kozvetlenul, ellenorizd a kiadasokat."
    fi
}

# 2. Install Desktop App
install_desktop() {
    echo "[+] Pala Desktop telepitese..."
    if [ "$OS" = "Linux" ]; then
        DESKTOP_DIR="$HOME/.local/share/pala"
        mkdir -p "$DESKTOP_DIR"
        
        # Create Desktop launcher file
        APP_DIR="$HOME/.local/share/applications"
        mkdir -p "$APP_DIR"
        cat <<EOF > "$APP_DIR/pala.desktop"
[Desktop Entry]
Name=Pala Desktop
Comment=Modern, nyilt forraskodu Kreta kliens
Exec=$USER_BIN/pala --desktop
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Education;Utility;
StartupNotify=true
EOF
        chmod +x "$APP_DIR/pala.desktop"
        echo "    Start menu / alkalmazasindito bejegyzes letrehozva: $APP_DIR/pala.desktop"
        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
        fi
    elif [ "$OS" = "Darwin" ]; then
        echo "    macOS Desktop app beallitasa /Applications mappaba..."
    fi
}

# Execute installation based on choice
if [ "$INSTALL_CHOICE" = "cli" ]; then
    install_cli
elif [ "$INSTALL_CHOICE" = "desktop" ]; then
    install_cli
    install_desktop
else
    install_cli
    install_desktop
fi

echo ""
echo "============================================================="
echo " Telepites sikeresen befejezodott!"
echo " Inditsd el a 'pala' paranccsal a terminalban,"
echo " vagy a 'pala --desktop' paranccsal grafikus modban!"
echo "============================================================="
