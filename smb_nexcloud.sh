#!/bin/bash

# Add trusted domain
# sudo nano /var/snap/nextcloud/current/nextcloud/config/config.php

# Pasang Samba jika belum ada
sudo apt update
sudo apt install -y samba

# Buat pengguna khas untuk akses backup
USERNAME="backupuser"
PASSWORD="Rahsia123"  # Tukar kepada kata laluan sebenar

# Tambah pengguna sistem (jika belum wujud)
sudo useradd -M -s /sbin/nologin $USERNAME
echo -e "$PASSWORD\n$PASSWORD" | sudo smbpasswd -a $USERNAME
sudo smbpasswd -e $USERNAME

# Tetapkan folder yang mahu dikongsi
SHARE_PATH="/var/snap/nextcloud/common/nextcloud/data"
SHARE_NAME="nextcloud_data"

# Backup fail konfigurasi Samba
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

# Tambah konfigurasi perkongsian ke smb.conf
sudo bash -c "cat >> /etc/samba/smb.conf <<EOF

[$SHARE_NAME]
   path = $SHARE_PATH
   browseable = yes
   read only = yes
   valid users = $USERNAME
   guest ok = no
   force user = root
EOF"

# Mulakan semula Samba
sudo systemctl restart smbd

echo "Folder $SHARE_PATH telah dikongsi sebagai '$SHARE_NAME'. Hanya $USERNAME boleh akses."
