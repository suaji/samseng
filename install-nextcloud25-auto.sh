#!/bin/bash
# ==========================================
# Nextcloud 25 Auto Installer for Raspberry Pi 1 (512MB)
# ==========================================

if [ "$EUID" -ne 0 ]; then
  echo "❗ Jalankan sebagai root: sudo bash install-nextcloud25-auto.sh"
  exit 1
fi

echo "🧠 Tambah swapfile (512MB)..."
apt install -y dphys-swapfile >/dev/null 2>&1
sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=512/' /etc/dphys-swapfile
systemctl restart dphys-swapfile

echo "🛠️ Kemas kini sistem minimum..."
apt update -y && apt install -y wget unzip apache2 mariadb-server php php-mysql php-gd php-json php-xml php-mbstring php-curl php-zip php-intl php-bcmath php-cli php-common php-imagick php-igbinary php-gmp

echo "🧩 Optimumkan MariaDB untuk low-RAM..."
cat <<EOF >/etc/mysql/mariadb.conf.d/60-raspi.cnf
[mysqld]
key_buffer_size = 8M
max_connections = 10
innodb_buffer_pool_size = 32M
innodb_log_file_size = 16M
query_cache_size = 8M
EOF
systemctl restart mariadb

echo "🛢️ Setup pangkalan data..."
mysql -u root <<EOF
DROP DATABASE IF EXISTS nextcloud;
CREATE DATABASE nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
DROP USER IF EXISTS 'ncuser'@'localhost';
CREATE USER 'ncuser'@'localhost' IDENTIFIED BY 'Password@987';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'ncuser'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "📁 Muat turun Nextcloud 25.0.10..."
cd /var/www/html || exit
wget -q https://download.nextcloud.com/server/releases/nextcloud-25.0.10.zip
unzip -q nextcloud-25.0.10.zip
rm nextcloud-25.0.10.zip
chown -R www-data:www-data nextcloud
chmod -R 755 nextcloud

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

echo "⚙️ Jalankan pemasangan automatik (tanpa web wizard)..."
sudo -u www-data php /var/www/html/nextcloud/occ maintenance:install \
  --database "mysql" \
  --database-name "nextcloud" \
  --database-user "ncuser" \
  --database-pass "Password@987" \
  --admin-user "admin" \
  --admin-pass "Password@123"

echo "🔧 Set domain trusted & config asas..."
sudo -u www-data php /var/www/html/nextcloud/occ config:system:set trusted_domains 1 --value="$(hostname -I | awk '{print $1}')"
sudo -u www-data php /var/www/html/nextcloud/occ config:system:set overwrite.cli.url --value="http://$(hostname -I | awk '{print $1}')/nextcloud"
sudo -u www-data php /var/www/html/nextcloud/occ config:system:set memcache.local --value='\OC\Memcache\APCu'

echo "🧹 Bersihkan cache & set permission akhir..."
apt clean
chown -R www-data:www-data /var/www/html/nextcloud

echo "✅ Siap sepenuhnya!"
echo "🌐 Akses di pelayar: http://$(hostname -I | awk '{print $1}')/nextcloud"
echo "👤 Akaun admin: admin"
echo "🔑 Kata laluan: Password@123"
echo "🗝️ Database: nextcloud | ncuser | Password@987"
echo "💡 Tip: Untuk Raspberry Pi 1, jangan aktifkan preview generator atau encryption."
