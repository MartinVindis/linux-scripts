#!/bin/bash

# Audio sink configuration
CHATSINK="virtual_chat_audio"
DESKSINK="virtual_desktop_audio"

# Volume control settings
STEP=2
CAP=100

# Function to get current volumes
get_volumes() {
    CHATVOL=$(pactl get-sink-volume "$CHATSINK" | grep 'front-left' | awk '{print $5}' | tr -d '%')
    DESKVOL=$(pactl get-sink-volume "$DESKSINK" | grep 'front-left' | awk '{print $5}' | tr -d '%')
}

# Function to calculate mix volume
calculate_mix_volume() {
    if (( CHATVOL + DESKVOL == 0 )); then
        MIXVOL=0
    else
        MIXVOL=$(( (CHATVOL * 100) / (DESKVOL + CHATVOL) ))
    fi
}

# Function to show OSD notification
show_osd() {
    qdbus org.kde.plasmashell /org/kde/osdService org.kde.osdService.showText "preferences-desktop-sound" "$(( CHATVOL - DESKVOL ))"
    #local DIFF=$(( CHATVOL - DESKVOL ))
    #qdbus org.kde.plasmashell /org/kde/osdService org.kde.osdService.showText "" "$DESKVOL                      $DIFF                       $CHATVOL"
}
