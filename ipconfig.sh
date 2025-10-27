#!/bin/bash
# ===========================================================
# Raspberry Pi Network Reconfigurator
# Backup + Change IP Address, DNS & Hostname
# ===========================================================

set -e

BACKUP_DIR="/var/backups/network_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "----------------------------------------"
echo "📦 Backing up current network settings..."
sudo cp /etc/dhcpcd.conf "$BACKUP_DIR"/dhcpcd.conf.bak
sudo cp /etc/hostname "$BACKUP_DIR"/hostname.bak
sudo cp /etc/hosts "$BACKUP_DIR"/hosts.bak
echo "✅ Backup saved in: $BACKUP_DIR"

echo "----------------------------------------"
echo "🔧 Current Hostname: $(cat /etc/hostname)"
echo
read -p "Enter new Hostname (or press Enter to keep current): " NEW_HOST
if [ -n "$NEW_HOST" ]; then
    echo "$NEW_HOST" | sudo tee /etc/hostname >/dev/null
    sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$NEW_HOST/" /etc/hosts
    echo "✅ Hostname changed to $NEW_HOST"
else
    echo "➡️  Hostname unchanged."
fi

echo "----------------------------------------"
echo "🧩 Current Network Configuration:"
grep -E 'static ip_address|static routers|static domain_name_servers' /etc/dhcpcd.conf || echo "No static IP found."

echo
read -p "Enter new static IP (e.g. 192.168.0.220/24): " NEW_IP
read -p "Enter new Gateway (e.g. 192.168.0.1): " NEW_GW
read -p "Enter new DNS (e.g. 8.8.8.8 1.1.1.1): " NEW_DNS

if [ -n "$NEW_IP" ]; then
    echo "----------------------------------------"
    echo "🧠 Updating /etc/dhcpcd.conf..."

    # Remove old static entries
    sudo sed -i '/^interface wlan0/,$d' /etc/dhcpcd.conf

    cat <<EOF | sudo tee -a /etc/dhcpcd.conf >/dev/null

interface eth0
static ip_address=$NEW_IP
static routers=$NEW_GW
static domain_name_servers=$NEW_DNS
EOF

    echo "✅ Updated network configuration:"
    tail -n 5 /etc/dhcpcd.conf
else
    echo "➡️  Static IP not modified."
fi

echo "----------------------------------------"
echo "🔁 Restarting network services..."
sudo systemctl restart dhcpcd
sleep 3

echo "----------------------------------------"
echo "✅ New network configuration applied!"
echo
hostname -I
echo "Hostname: $(cat /etc/hostname)"
echo "----------------------------------------"
echo "You may need to reconnect SSH using the new IP address."
echo "----------------------------------------"
