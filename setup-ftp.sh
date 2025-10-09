#!/bin/bash

set -e

# Prompt for FTP username
read -p "Enter FTP username: " FTP_USER

# Prompt for password and confirm it
while true; do
    read -s -p "Enter FTP password: " FTP_PASS
    echo
    read -s -p "Confirm FTP password: " FTP_PASS_CONFIRM
    echo

    if [ "$FTP_PASS" = "$FTP_PASS_CONFIRM" ]; then
        break
    else
        echo "❌ Passwords do not match. Please try again."
    fi
done

FTP_DIR="/home/$FTP_USER/Public"

echo "[1/6] Installing vsftpd..."
sudo dnf install -y vsftpd

echo "[2/6] Creating FTP directory and setting permissions..."
sudo mkdir -p "$FTP_DIR"
sudo chmod -R 755 "$FTP_DIR"
sudo chown -R "$FTP_USER:$FTP_USER" "$FTP_DIR"

echo "[3/6] Configuring vsftpd for local user login only..."

sudo tee /etc/vsftpd/vsftpd.conf > /dev/null <<EOF
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
allow_writeable_chroot=YES
user_sub_token=\$USER
local_root=$FTP_DIR
pam_service_name=vsftpd
pasv_enable=YES
pasv_min_port=30000
pasv_max_port=31000
EOF

echo "[4/6] Opening firewall for FTP..."
sudo firewall-cmd --permanent --add-service=ftp
sudo firewall-cmd --reload

echo "[5/6] Enabling and starting vsftpd..."
sudo systemctl enable --now vsftpd

echo "[6/6] Done!"
echo "✅ FTP server is up and running"
echo "➡️  FTP user: $FTP_USER"
echo "➡️  Password: $FTP_PASS"
echo "➡️  FTP root directory: $FTP_DIR"
echo "➡️  Access via: ftp://<your_local_ip>"
