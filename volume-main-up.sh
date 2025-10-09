#!/bin/bash

# Source the configuration file
source "$(dirname "$0")/volume-main-config.sh"

VOL=$(pactl get-sink-volume "$SINK" | grep 'front-left' | awk '{print $5}' | tr -d '%')
NEWVOL=$(( VOL + STEP < CAP ? VOL + STEP : CAP ))

pactl set-sink-volume "$SINK" $NEWVOL%
qdbus org.kde.plasmashell /org/kde/osdService org.kde.osdService.volumeChanged $NEWVOL $CAP
