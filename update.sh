#!/bin/bash

# Flag to track if updates were downloaded
updates_scheduled=false

# Schedule offline updates if any
echo "Checking for system updates..."
output=$(sudo dnf offline-upgrade download --refresh -y)
if [ $? -eq 0 ]; then
  if ! echo "$output" | grep -q "Nothing to do."; then
    updates_scheduled=true
  fi
else
  echo "❌ Failed to run offline-upgrade command."
fi

# Update Flatpaks
if command -v flatpak &> /dev/null; then
  echo ""
  echo "Updating Flatpaks..."
  flatpak update -y
  echo ""
  echo "Uninstalling unused Flatpaks..."
  flatpak uninstall --unused -y
else
  echo ""
  echo "Flatpak not installed. Skipping Flatpak updates."
fi


echo ""
if [ "$updates_scheduled" = true ]; then
  DNF_SYSTEM_UPGRADE_NO_REBOOT=1 dnf5 offline reboot -y &> /dev/null
  echo "🔁 Update check complete. Reboot to apply system updates."
else
  echo "✅ Update check complete."
fi
