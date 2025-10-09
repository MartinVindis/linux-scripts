#!/bin/bash

set -euo pipefail

# Set up working directory
WORKDIR="$HOME/Downloads/DLSS"
MANIFEST_URL="https://raw.githubusercontent.com/beeradmoore/dlss-swapper-manifest-builder/refs/heads/main/manifest.json"
MANIFEST_FILE="manifest.json"

# Colors
GREEN="\033[0;32m"
RESET="\033[0m"

cleanup() {
    rm -f "$MANIFEST_FILE"
}
trap cleanup EXIT

mkdir -p "$WORKDIR"
cd "$WORKDIR" || exit 1

# Download the manifest
echo "Downloading manifest..."
if ! curl -s -o "$MANIFEST_FILE" "$MANIFEST_URL"; then
    echo "Error: Failed to download manifest."
    exit 1
fi

# Check if jq and unzip are installed
for cmd in jq unzip; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: '$cmd' is required but not installed. Install it first."
        exit 1
    fi
done

# List available versions
echo "Available DLSS Versions:"
echo

mapfile -t versions < <(jq -r '.dlss[].version' "$MANIFEST_FILE")
mapfile -t download_urls < <(jq -r '.dlss[].download_url' "$MANIFEST_FILE")

for i in "${!versions[@]}"; do
    filename=$(basename "${download_urls[i]}")
    foldername="${filename%.zip}"

    if [[ -d "$foldername" ]]; then
        printf "%3d) %s ${GREEN}✓${RESET}\n" $((i+1)) "${versions[i]}"
    else
        printf "%3d) %s\n" $((i+1)) "${versions[i]}"
    fi
done

# Add "Download all" option
echo
printf "999) Download and extract ALL versions\n"
echo

read -rp "Enter the number of the DLSS version you want to download (or 999 for all): " choice

# Validate input
if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 && choice != 999 )); then
    echo "Invalid selection."
    exit 1
fi

draw_progress_bar() {
    local progress=$1
    local total=$2
    local current=$3
    local bar_width=40

    local percent=$(( progress * 100 / total ))
    local filled=$(( progress * bar_width / total ))
    local empty=$(( bar_width - filled ))

    printf "\r["
    printf "%0.s=" $(seq 1 $filled)
    printf "%0.s " $(seq 1 $empty)
    printf "] %3d%% (%d/%d)" "$percent" "$progress" "$total"
}

download_and_extract() {
    local download_url="$1"
    local filename
    filename=$(basename "$download_url")
    local foldername="${filename%.zip}"

    if [[ ! -d "$foldername" ]]; then
        if [[ ! -f "$filename" ]]; then
            if ! curl -s -LO "$download_url"; then
                echo "Error: Failed to download $filename."
                exit 1
            fi
        fi
        mkdir -p "$foldername"
        if ! unzip -q "$filename" -d "$foldername"; then
            echo "Error: Failed to unzip $filename."
            exit 1
        fi
        rm -f "$filename"
    fi
}

if [[ "$choice" == "999" ]]; then
    echo "Downloading ALL versions"
    total_versions=${#download_urls[@]}
    current=0

    for i in "${!download_urls[@]}"; do
        current=$((i+1))
        download_and_extract "${download_urls[i]}"
        draw_progress_bar "$current" "$total_versions" "$current"
    done
    echo
    echo -e "${GREEN}Done!${RESET} All DLSS versions are ready in $WORKDIR"
elif (( choice >= 1 && choice <= ${#versions[@]} )); then
    selected_version="${versions[choice-1]}"
    download_url="${download_urls[choice-1]}"

    echo "Downloading version $selected_version"
    download_and_extract "$download_url"
    draw_progress_bar 1 1 1
    echo
    echo -e "${GREEN}Done!${RESET} DLSS version $selected_version is ready in $WORKDIR"
else
    echo "Invalid selection."
    exit 1
fi
