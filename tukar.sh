#!/bin/bash
# ==============================================================
# 🧭 OwnCloud Network Configurator for Raspberry Pi
# Lighttpd + PHP7.3 + HTTPS + Custom Port + Backup
# ==============================================================

set -e

BACKUP_DIR="/var/backups/owncloud_network_$(date +%Y%m%d_%H%M%S)"
CONFIG_OC="/var/www/html/owncloud/config/config.php"
CONFIG_LTP="/etc/lighttpd/lighttpd.conf"
CONFIG_NET="/etc/dhcpcd.conf"

# --------------------------------------------------------------
# 1️⃣ Backup files
# --------------------------------------------------------------
echo "----------------------------------------------"
echo "📦 Creating backup directory..."
sudo mkdir -p "$BACKUP_DIR"

echo "💾 Backing up important configs..."
for FILE in "$CONFIG_OC" "$CONFIG_LTP" "$CONFIG_NET"; do
  if [ -f "$FILE" ]; then
    sudo cp "$FILE" "$BACKUP_DIR/"
    echo "✅ Backed up: $FILE"
  else
    echo "⚠️  Not found: $FILE"
  fi
done

echo "📁 Backup location: $BACKUP_DIR"

# --------------------------------------------------------------
# 2️⃣ Change Server IP (optional)
# --------------------------------------------------------------
echo "----------------------------------------------"
read -p "🖧 Do you want to change the static IP? (y/n): " ipchange
if [[ "$ipchange" == "y" ]]; then
    echo
    read -p "Enter new IP address (e.g. 192.168.0.216): " newip
    read -p "Enter router gateway (e.g. 192.168.0.1): " gateway
    read -p "Enter subnet mask (default 255.255.255.0): " mask
    mask=${mask:-255.255.255.0}
    echo
    echo "🧾 Updating /etc/dhcpcd.conf ..."
    sudo bash -c "cat >> /etc/dhcpcd.conf <<EOF

# --- Added by OwnCloud Config Script ---
interface eth0
static ip_address=${newip}/24
static routers=${gateway}
static domain_name_servers=${gateway}
# ----------------------------------------
EOF"
    echo "✅ IP updated. Will take effect after reboot."
fi

# --------------------------------------------------------------
# 3️⃣ Enable HTTPS
# --------------------------------------------------------------
echo "----------------------------------------------"
read -p "🔒 Enable HTTPS for OwnCloud? (y/n): " enablehttps
if [[ "$enablehttps" == "y" ]]; then
    read -p "Use Let's Encrypt (1) or Self-Signed (2)? [1/2]: " httpsmode

    if [[ "$httpsmode" == "1" ]]; then
        echo "🌍 Installing Certbot for Let's Encrypt..."
        sudo apt install -y certbot python3-certbot-lighttpd
        read -p "Enter your domain name (e.g. yourname.ddns.net): " domain
        read -p "Enter your email for SSL renewal notice: " email
        sudo certbot --agree-tos --email "$email" --lighttpd -d "$domain"
        echo "✅ HTTPS enabled via Let's Encrypt."
    else
        echo "🔧 Creating self-signed certificate..."
        sudo apt install -y openssl
        sudo mkdir -p /etc/lighttpd/certs
        sudo openssl req -x509 -newkey rsa:2048 -keyout /etc/lighttpd/certs/owncloud.key \
        -out /etc/lighttpd/certs/owncloud.crt -days 365 -nodes -subj "/CN=raspberrypi"
        
        sudo bash -c "cat >/etc/lighttpd/conf-available/10-ssl.conf <<EOF
\$SERVER[\"socket\"] == \":443\" {
    ssl.engine = \"enable\"
    ssl.pemfile = \"/etc/lighttpd/certs/owncloud.crt\"
    ssl.privkey = \"/etc/lighttpd/certs/owncloud.key\"
    server.document-root = \"/var/www/html\"
}
EOF"
        sudo lighty-enable-mod ssl
        echo "✅ HTTPS (self-signed) enabled."
    fi
fi

# --------------------------------------------------------------
# 4️⃣ Change HTTP/HTTPS ports
# --------------------------------------------------------------
echo "----------------------------------------------"
read -p "⚙️  Change HTTP/HTTPS port? (y/n): " changeport
if [[ "$changeport" == "y" ]]; then
    read -p "Enter new HTTP port (default 80): " newhttp
    read -p "Enter new HTTPS port (default 443): " newhttps
    newhttp=${newhttp:-80}
    newhttps=${newhttps:-443}

    echo "🧾 Updating Lighttpd config..."
    sudo sed -i "s/^server.port.*/server.port = $newhttp/" "$CONFIG_LTP"

    # Update SSL conf if exists
    if [ -f /etc/lighttpd/conf-available/10-ssl.conf ]; then
        sudo sed -i "s/^\$SERVER\[\"socket\"\].*/\$SERVER[\"socket\"] == \":$newhttps\" {/" /etc/lighttpd/conf-available/10-ssl.conf
    fi

    echo "✅ Ports updated (HTTP:$newhttp, HTTPS:$newhttps)"
fi

# --------------------------------------------------------------
# 5️⃣ Restart Services
# --------------------------------------------------------------
echo "----------------------------------------------"
echo "🔁 Restarting Lighttpd & PHP-FPM..."
sudo systemctl restart php7.3-fpm
sudo systemctl restart lighttpd
echo "✅ Done!"

# --------------------------------------------------------------
# ✅ Summary
# --------------------------------------------------------------
echo
echo "=============================================="
echo "🎉 Configuration Complete!"
echo "Backup folder: $BACKUP_DIR"
echo
echo "Access URLs:"
echo "  - HTTP : http://$(hostname -I | awk '{print $1}'):$newhttp/owncloud"
echo "  - HTTPS: https://$(hostname -I | awk '{print $1}'):$newhttps/owncloud"
echo
echo "⚠️  If IP changed, please reboot for it to apply:"
echo "     sudo reboot"
echo "=============================================="
