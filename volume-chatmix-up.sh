#!/bin/bash

# Source the configuration file
source "$(dirname "$0")/volume-chatmix-config.sh"

# Get current volumes
get_volumes

# Adjust volumes
if ((CHATVOL < CAP)); then
    CHATVOL=$(( CHATVOL + STEP < CAP ? CHATVOL + STEP : CAP ))
    pactl set-sink-volume "$CHATSINK" $CHATVOL%
else
    DESKVOL=$(( DESKVOL - STEP > 0 ? DESKVOL - STEP : 0 ))
    pactl set-sink-volume "$DESKSINK" $DESKVOL%
fi

# Calculate mix volume and show OSD
calculate_mix_volume
show_osd
