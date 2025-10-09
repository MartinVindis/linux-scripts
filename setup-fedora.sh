#!/bin/bash
#
# Fedora Setup Script
# Installs essential software, enables repositories, and configures system settings.
#

#######################################
# Colors
#######################################
GREEN="\e[32m"
BLUE="\e[34m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

#######################################
# Step counter variables
#######################################
STEP=0
TOTAL_STEPS=8  # Update this if steps change

#######################################
# Logging functions
#######################################
log_info()    { ((STEP++)); echo -e "${BLUE}[Step ${STEP}/${TOTAL_STEPS}]${RESET} $1"; }
log_success() { echo -e "${GREEN}==>${RESET} $1"; }
log_warn()    { echo -e "${YELLOW}==>${RESET} $1"; }
log_error()   { echo -e "${RED}==>${RESET} $1"; }

#######################################
# Function: Confirm before continuing
#######################################
confirm_continue() {
    while true; do
        read -rp "This script will install packages and modify system settings. Continue? [y/n]: " yn
        case $yn in
            [Yy]*) return 0 ;;
            [Nn]*) log_warn "Aborted by user."; exit 1 ;;
            *)     echo "Please answer yes (y) or no (n)." ;;
        esac
    done
}

#######################################
# Function: Ensure script is run as root
#######################################
require_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root (use sudo)"
        exit 1
    fi
}

#######################################
# Script start
#######################################
require_root
confirm_continue

log_info "Updating system packages..."
dnf update -y || { log_error "System update failed."; exit 1; }

#######################################
# Enable Repositories
#######################################
log_info "Enabling RPM Fusion repositories..."
dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

log_info "Adding Negativo17 NVIDIA driver repository..."
dnf config-manager addrepo --from-repofile="https://negativo17.org/repos/fedora-nvidia.repo"

log_info "Enabling Copr repository for Sunshine..."
dnf copr enable -y lizardbyte/stable

#######################################
# Flatpak setup
#######################################
log_info "Configuring Flatpak and adding Flathub repository..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

#######################################
# Install DNF packages
#######################################
log_info "Installing essential system packages..."
dnf install -y \
    akmod-nvidia --repo=negativo17-nvidia \
    xorg-x11-drv-nvidia-cuda --repo=negativo17-nvidia \
    btop \
    ckb-next \
    fastfetch \
    firefox \
    flatpak \
    goverlay \
    heroic-games-launcher \
    lutris \
    obs-studio \
    qbittorrent \
    qpwgraph \
    samba \
    steam \
    sunshine \
    timeshift \
    usbguard

#######################################
# Kernel modules & multimedia codecs
#######################################
log_info "Rebuilding NVIDIA kernel modules..."
akmods --rebuild

log_info "Installing multimedia codecs..."
dnf group install -y multimedia

#######################################
# Install Flatpak applications
#######################################
log_info "Installing Flatpak applications from Flathub..."
flatpak install -y flathub \
    com.discordapp.Discord \
    com.github.wwmm.easyeffects \
    com.github.tchx84.Flatseal \
    tv.kodi.Kodi \
    com.moonlight_stream.Moonlight \
    com.vysp3r.ProtonPlus \
    it.mijorus.gearlever

#######################################
# Finish
#######################################
log_success "Installation complete!"
log_warn "A system reboot is recommended."
