#!/bin/bash
set -e

# === Moonlight Installer / Uninstaller ===
# Usage:
#   ./moonlight.sh --install  or  ./moonlight.sh -i
#   ./moonlight.sh --uninstall or  ./moonlight.sh -u

show_usage() {
    echo "Usage: $0 [--install|-i | --uninstall|-u]"
    exit 1
}

if [ $# -ne 1 ]; then
    show_usage
fi

MODE="$1"

# --- Paths ---
BINARY="/usr/local/bin/moonlight"
ICON="$HOME/.local/share/icons/hicolor/64x64/apps/moonlight.png"
DESKTOP="$HOME/.local/share/applications/moonlight.desktop"
SRC_DIR="$HOME/Downloads/moonlight-qt"

# --- Detect distro ---
if [ -f /etc/fedora-release ]; then
    DISTRO="fedora"
elif [ -f /etc/debian_version ]; then
    DISTRO="debian"
else
    echo "Unsupported Linux distribution."
    exit 1
fi

# --- Install function ---
install_moonlight() {
    echo "🚀 Installing Moonlight on $DISTRO..."

    # --- Install dependencies ---
    if [ "$DISTRO" = "fedora" ]; then
        echo "Installing dependencies on Fedora..."
        if ! rpm -q rpmfusion-free-release &>/dev/null; then
            sudo dnf install -y \
                https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
                https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
            sudo dnf upgrade --refresh
        fi

        sudo dnf group install -y "development-tools"

        packages=(
        	gcc-c++ make git cmake pkgconfig
        	qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtsvg-devel qt6-qttools-devel
	        ffmpeg-devel libplacebo-devel
	        openssl-devel SDL2-devel SDL2_ttf-devel
	        libva-devel libvdpau-devel opus-devel
	        pulseaudio-libs-devel alsa-lib-devel
	        libdrm-devel wayland-devel
        )
        for pkg in "${packages[@]}"; do
            if ! rpm -q "$pkg" &>/dev/null; then
                sudo dnf install -y "$pkg"
            fi
        done

    elif [ "$DISTRO" = "debian" ]; then
        echo "Installing dependencies on Debian/Ubuntu..."
        sudo apt update
        sudo apt install -y build-essential git cmake pkg-config \
            qt6-base-dev qt6-declarative-dev libqt6svg6-dev \
            qml-module-qtquick-controls2 qml-module-qtquick-layouts qml-module-qtquick-window2 \
            ffmpeg libavcodec-dev libavformat-dev libswscale-dev libva-dev libvdpau-dev \
            libsdl2-dev libsdl2-ttf-dev libopus-dev libssl-dev pulseaudio libasound2-dev \
            libdrm-dev
    fi

    # --- Clone repository ---
    if [ ! -d "$SRC_DIR" ]; then
        echo "Cloning Moonlight repository..."
        git clone https://github.com/moonlight-stream/moonlight-qt.git "$SRC_DIR"
    fi
    cd "$SRC_DIR"
    git submodule update --init --recursive

    # --- Build ---
    echo "Building Moonlight..."
    qmake6 moonlight-qt.pro
    make -j$(nproc)

    # --- Install binary ---
    echo "Installing binary..."
    sudo cp app/moonlight "$BINARY"

    # --- Download icon ---
    echo "Downloading icon..."
    mkdir -p "$(dirname "$ICON")"
    wget -O "$ICON" \
        https://github.com/moonlight-stream/moonlight-qt/blob/master/app/moonlight_wix.png?raw=true

    # --- Create .desktop launcher ---
    echo "Creating launcher..."
    mkdir -p "$(dirname "$DESKTOP")"
    cat << EOF > "$DESKTOP"
[Desktop Entry]
Type=Application
Name=Moonlight
Comment=Stream games and other applications from another PC running Sunshine or GeForce Experience
Exec=$BINARY
Icon=moonlight
Categories=Game;Network;
StartupNotify=true
EOF

    # --- Refresh caches ---
    update-desktop-database ~/.local/share/applications >/dev/null 2>&1
    if command -v kbuildsycoca5 &>/dev/null; then
        kbuildsycoca5 --noincremental >/dev/null 2>&1
    fi
    ICON_DIR="$HOME/.local/share/icons/hicolor"
    if command -v gtk-update-icon-cache &>/dev/null && [ -f "$ICON_DIR/index.theme" ]; then
        gtk-update-icon-cache "$ICON_DIR" >/dev/null 2>&1
    fi

    echo "✅ Moonlight installation complete!"
}

# --- Uninstall function ---
uninstall_moonlight() {
    echo "🧹 Uninstalling Moonlight..."

    if [ -f "$BINARY" ]; then
        sudo rm "$BINARY"
        echo "Removed $BINARY"
    fi

    if [ -f "$ICON" ]; then
        rm "$ICON"
        echo "Removed icon $ICON"
    fi

    if [ -f "$DESKTOP" ]; then
        rm "$DESKTOP"
        echo "Removed launcher $DESKTOP"
    fi

    # Refresh caches
    update-desktop-database ~/.local/share/applications >/dev/null 2>&1
    if command -v kbuildsycoca5 &>/dev/null; then
        kbuildsycoca5 --noincremental >/dev/null 2>&1
    fi
    if command -v gtk-update-icon-cache &>/dev/null && [ -f "$HOME/.local/share/icons/hicolor/index.theme" ]; then
        gtk-update-icon-cache "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1
    fi

    if [ -d "$SRC_DIR" ]; then
        rm -rf "$SRC_DIR"
        echo "Removed source folder $SRC_DIR"
    fi

    echo "✅ Moonlight has been uninstalled!"
}

# --- Main ---
case "$MODE" in
    --install|-i)
        install_moonlight
        ;;
    --uninstall|-u)
        uninstall_moonlight
        ;;
    *)
        show_usage
        ;;
esac
