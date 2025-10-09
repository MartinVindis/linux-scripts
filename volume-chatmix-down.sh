#!/bin/bash

# Source the configuration file
source "$(dirname "$0")/volume-chatmix-config.sh"

# Get current volumes
get_volumes

# Adjust volumes
if ((DESKVOL < CAP)); then
    DESKVOL=$(( DESKVOL + STEP < CAP ? DESKVOL + STEP : CAP ))
    pactl set-sink-volume "$DESKSINK" $DESKVOL%
else
    CHATVOL=$(( CHATVOL - STEP > 0 ? CHATVOL - STEP : 0))
    pactl set-sink-volume "$CHATSINK" $CHATVOL%
fi

# Calculate mix volume and show OSD
calculate_mix_volume
show_osd
