#!/bin/bash
# Nextcloud Installer - Apache + MariaDB (Optimized for Raspberry Pi 1 / 512MB)

# =========================================
#  Pastikan skrip dijalankan sebagai root
# =========================================
if [ "$EUID" -ne 0 ]; then
  echo "❗ Jalankan sebagai root: sudo bash install-nextcloud-apache-lite.sh"
  exit 1
fi

echo "🧠 Menambah swapfile (512MB) untuk elak Out-of-Memory..."
apt install -y dphys-swapfile >/dev/null 2>&1
sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=512/' /etc/dphys-swapfile
systemctl restart dphys-swapfile

echo "🛠️ Kemas kini sistem asas..."
apt update -y && apt install -y wget unzip apache2 mariadb-server

echo "📦 Pasang PHP versi ringan..."
apt install -y php php-mysql php-gd php-json php-xml php-mbstring php-curl php-zip php-intl php-bcmath php-cli php-common php-imagick

echo "🧹 Bersihkan cache apt..."
apt clean

cd /var/www/html || exit

echo "📁 Muat turun Nextcloud 26.0.6 (lebih ringan dan stabil)..."
wget -q https://download.nextcloud.com/server/releases/nextcloud-26.0.6.zip
unzip -q nextcloud-26.0.6.zip
rm nextcloud-26.0.6.zip
chown -R www-data:www-data nextcloud
chmod -R 755 nextcloud

echo "🧾 Konfigurasi Apache untuk Nextcloud..."
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

echo "🛢️ Konfigurasi MariaDB asas..."
mysql -u root <<EOF
CREATE DATABASE nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER 'ncuser'@'localhost' IDENTIFIED BY 'passwordku';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'ncuser'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "🧩 Optimumkan konfigurasi MariaDB untuk RAM kecil..."
cat <<EOF >/etc/mysql/mariadb.conf.d/60-raspi.cnf
[mysqld]
key_buffer_size = 8M
max_connections = 10
innodb_buffer_pool_size = 32M
innodb_log_file_size = 16M
query_cache_size = 8M
EOF

systemctl restart mariadb

echo "✅ Selesai!"
echo "🌐 Akses dari pelayar: http://$(hostname -I | awk '{print $1}')/nextcloud"
echo "🗝️ Gunakan maklumat berikut semasa pemasangan:"
echo "   Database: nextcloud"
echo "   User:     ncuser"
echo "   Password: passwordku"
echo "💡 Tip: Pilih 'MariaDB' dan jangan aktifkan 'Memcache' atau 'Preview Generator' semasa setup."
