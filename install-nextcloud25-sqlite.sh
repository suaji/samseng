#!/bin/bash
# ==============================================================
# Nextcloud 25 Auto Installer - FULL EDITION (SQLite + Cron + HTTPS)
# Optimized for Raspberry Pi 1 (512MB)
# ==============================================================

if [ "$EUID" -ne 0 ]; then
  echo "❗ Jalankan sebagai root: sudo bash install-nextcloud25-sqlite.sh"
  exit 1
fi

# --------------------------------------------------------------
# 1️⃣ Semak & aktifkan swap (512MB)
# --------------------------------------------------------------
echo "🧠 Semak swap..."
if free | awk '/Swap:/ {exit !$2}'; then
  echo "✅ Swap telah aktif, skip bahagian swap."
else
  echo "⚙️ Tiada swap dikesan, sedang tambah swapfile (512MB)..."
  apt install -y dphys-swapfile >/dev/null 2>&1
  sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=512/' /etc/dphys-swapfile
  systemctl restart dphys-swapfile
fi

# --------------------------------------------------------------
# 2️⃣ Pasang komponen asas
# --------------------------------------------------------------
echo "🛠️ Kemas kini sistem asas..."
apt update -y && apt install -y wget unzip apache2 php php-gd php-json php-xml php-mbstring php-curl php-zip php-intl php-bcmath php-cli php-common php-imagick php-sqlite3 php-apcu cron

# --------------------------------------------------------------
# 3️⃣ Muat turun dan setup Nextcloud
# --------------------------------------------------------------
echo "📁 Muat turun Nextcloud 25.0.10..."
cd /var/www/html || exit
wget -q https://download.nextcloud.com/server/releases/nextcloud-25.0.10.zip
unzip -q nextcloud-25.0.10.zip
rm nextcloud-25.0.10.zip
chown -R www-data:www-data nextcloud
chmod -R 755 nextcloud

# --------------------------------------------------------------
# 4️⃣ Konfigurasi Apache
# --------------------------------------------------------------
echo "🧾 Konfigurasi Apache..."
cat <<EOF >/etc/apache2/sites-available/nextcloud.conf
<VirtualHost *:80>
  ServerAdmin admin@localhost
  DocumentRoot /var/www/html/nextcloud
  <Directory /var/www/html/nextcloud/>
    Options +FollowSymlinks
    AllowOverride All
    Require all granted
    <IfModule mod_dav.c>
      Dav off
    </IfModule>
    SetEnv HOME /var/www/html/nextcloud
    SetEnv HTTP_HOME /var/www/html/nextcloud
  </Directory>
</VirtualHost>
EOF

a2ensite nextcloud.conf
a2enmod rewrite headers env dir mime
systemctl restart apache2

# --------------------------------------------------------------
# 5️⃣ Pasang Nextcloud automatik (SQLite)
# --------------------------------------------------------------
echo "⚙️ Jalankan pemasangan automatik (SQLite, tanpa MariaDB)..."
sudo -u www-data php /var/www/html/nextcloud/occ maintenance:install \
  --database "sqlite" \
  --admin-user "admin" \
  --admin-pass "Password@987" \
  --data-dir "/var/www/html/nextcloud/data"

# --------------------------------------------------------------
# 6️⃣ Konfigurasi asas sistem
# --------------------------------------------------------------
IPADDR=$(hostname -I | awk '{print $1}')
sudo -u www-data php /var/www/html/nextcloud/occ config:system:set trusted_domains 1 --value="$IPADDR"
sudo -u www-data php /var/www/html/nextcloud/occ config:system:set overwrite.cli.url --value="http://$IPADDR/nextcloud"
sudo -u www-data php /var/www/html/nextcloud/occ config:system:set memcache.local --value='\OC\Memcache\APCu'

# --------------------------------------------------------------
# 7️⃣ Tambah Cron job automatik
# --------------------------------------------------------------
echo "🕒 Aktifkan cron background task..."
(crontab -u www-data -l 2>/dev/null | grep -q "nextcloud/cron.php") || \
echo "*/15 * * * * php -f /var/www/html/nextcloud/cron.php >/dev/null 2>&1" | crontab -u www-data -

sudo -u www-data php /var/www/html/nextcloud/occ background:cron

# --------------------------------------------------------------
# 8️⃣ (Opsyenal) HTTPS Let's Encrypt
# --------------------------------------------------------------
echo "🔒 Sediakan HTTPS (optional)..."
read -rp "Masukkan domain anda (kosongkan jika tiada): " DOMAIN

if [ -n "$DOMAIN" ]; then
  echo "🌐 Pasang Certbot untuk HTTPS..."
  apt install -y certbot python3-certbot-apache
  certbot --apache -d "$DOMAIN" --non-interactive --agree-tos -m admin@"$DOMAIN" || echo "⚠️ Gagal dapat sijil, teruskan tanpa HTTPS."
else
  echo "➡️ Tiada domain dimasukkan, skip Let’s Encrypt."
fi

# --------------------------------------------------------------
# 9️⃣ Kemasan akhir
# --------------------------------------------------------------
apt clean
chown -R www-data:www-data /var/www/html/nextcloud

echo ""
echo "✅ SIAP SEPENUHNYA!"
echo "🌐 Akses: http://$IPADDR/nextcloud"
[ -n "$DOMAIN" ] && echo "🔐 HTTPS: https://$DOMAIN"
echo "👤 Akaun admin: admin"
echo "🔑 Kata laluan: Password@987"
echo "💾 Database: SQLite (fail tempatan)"
echo "🕒 Cron: berjalan setiap 15 minit"
echo ""
echo "💡 Gunakan: sudo -u www-data php /var/www/html/nextcloud/occ maintenance:mode --on/off jika perlu servis."
