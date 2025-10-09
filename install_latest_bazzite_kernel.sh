#!/bin/bash

set -euo pipefail

# Configuration
FEDORA_VERSION="fc$(grep -oP '\d+' /etc/fedora-release | head -n 1)"
ARCH=x86_64
GITHUB_REPO="bazzite-org/kernel-bazzite"
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

# Function to clean up temporary directory
cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

echo "Checking for latest Bazzite kernel version..."

# Get the latest release tag
LATEST_TAG=$(curl -s "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [[ -z "$LATEST_TAG" ]]; then
    echo "Failed to determine latest kernel version."
    exit 1
fi

echo "Latest version: $LATEST_TAG"

KERNEL_VERSION="${LATEST_TAG}.bazzite.${FEDORA_VERSION}.${ARCH}"
KERNEL_IMAGE="/boot/vmlinuz-${KERNEL_VERSION}"

# Check if already installed
if [[ -f "$KERNEL_IMAGE" ]]; then
    echo "Bazzite kernel $KERNEL_VERSION is already installed."
    exit 0
fi

# Prompt user
echo -n "Do you want to download and install the Bazzite kernel $KERNEL_VERSION? [Y/n]: "
read -r ANSWER
ANSWER=${ANSWER,,}  # convert to lowercase
ANSWER=${ANSWER:-y}  # default to 'y' if no input is given

if [[ "$ANSWER" != "y" && "$ANSWER" != "yes" ]]; then
    echo "Installation cancelled."
    exit 0
fi

# File names to download
FILES=(
  "kernel-${LATEST_TAG}.bazzite.${FEDORA_VERSION}.${ARCH}.rpm"
  "kernel-core-${LATEST_TAG}.bazzite.${FEDORA_VERSION}.${ARCH}.rpm"
  "kernel-modules-${LATEST_TAG}.bazzite.${FEDORA_VERSION}.${ARCH}.rpm"
  "kernel-modules-core-${LATEST_TAG}.bazzite.${FEDORA_VERSION}.${ARCH}.rpm"
  "kernel-modules-extra-${LATEST_TAG}.bazzite.${FEDORA_VERSION}.${ARCH}.rpm"
  "kernel-devel-${LATEST_TAG}.bazzite.${FEDORA_VERSION}.${ARCH}.rpm"
)

BASE_URL="https://github.com/${GITHUB_REPO}/releases/download/${LATEST_TAG}"

echo "Downloading kernel files for Fedora ${FEDORA_VERSION}..."

for FILE in "${FILES[@]}"; do
  echo "Downloading $FILE..."
  if ! curl -LO "${BASE_URL}/${FILE}"; then
      echo "Failed to download $FILE."
      exit 1
  fi
done

echo "Installing Bazzite kernel $KERNEL_VERSION..."
if ! sudo dnf install -y ./*.rpm; then
    echo "Failed to install the kernel."
    exit 1
fi

echo "Running akmods to prebuild kernel modules..."
if ! sudo akmods --force --kernels "$KERNEL_VERSION"; then
    echo "Failed to run akmods."
    exit 1
fi

echo "Bazzite kernel $KERNEL_VERSION installed successfully!"
echo "🔁 Please reboot your system to use the new kernel."
