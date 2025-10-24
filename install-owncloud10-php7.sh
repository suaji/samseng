#!/bin/bash
# ─────────────────────────────────────────────
# install-owncloud10-php7.sh
# Untuk Raspberry Pi OS (Debian 11 "Bullseye")
# OwnCloud 10.x + PHP 7.4 + SQLite + Nginx
# ─────────────────────────────────────────────

# Semak root
if [ "$EUID" -ne 0 ]; then
  echo "⚠️  Jalankan sebagai root: sudo bash install-owncloud10-php7.sh"
  exit 1
fi

echo "🧠 Tambah swapfile (512MB)..."
apt install -y dphys-swapfile >/dev/null 2>&1
sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=512/' /etc/dphys-swapfile
systemctl restart dphys-swapfile

echo "🧰 Kemas kini sistem..."
apt update -y && apt upgrade -y

echo "📦 Pasang komponen utama (nginx + php7.4)..."
apt install -y nginx unzip wget \
  php7.4 php7.4-fpm php7.4-cli php7.4-common \
  php7.4-xml php7.4-mbstring php7.4-zip php7.4-gd php7.4-curl \
  php7.4-intl php7.4-bcmath php7.4-sqlite3

# ─────────────────────────────────────────────
# Muat turun dan pasang OwnCloud
# ─────────────────────────────────────────────
echo "📁 Muat turun OwnCloud..."
cd /tmp
wget https://download.owncloud.com/server/stable/owncloud-10.10.0.zip -O owncloud.zip

if unzip -tq owncloud.zip >/dev/null 2>&1; then
  unzip -oq owncloud.zip
  mv owncloud /var/www/html/
else
  echo "❌ Gagal unzip owncloud.zip — semak sambungan Internet atau pautan muat turun."
  exit 1
fi

chown -R www-data:www-data /var/www/html/owncloud
chmod -R 755 /var/www/html/owncloud

# ─────────────────────────────────────────────
# Konfigurasi PHP-FPM
# ─────────────────────────────────────────────
echo "⚙️  Konfigurasi PHP-FPM..."
if [ -f /etc/php/7.4/fpm/php.ini ]; then
  sed -i 's|^;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo=0|' /etc/php/7.4/fpm/php.ini
fi
systemctl enable php7.4-fpm
systemctl restart php7.4-fpm

# ─────────────────────────────────────────────
# Konfigurasi Nginx
# ─────────────────────────────────────────────
echo "🧾 Konfigurasi Nginx..."
cat <<'EOF' > /etc/nginx/sites-available/owncloud
server {
    listen 80;
    server_name _;

    root /var/www/html/owncloud;
    index index.php index.html;
    client_max_body_size 512M;
    fastcgi_buffers 64 4K;

    access_log /var/log/nginx/owncloud_access.log;
    error_log  /var/log/nginx/owncloud_error.log;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/owncloud /etc/nginx/sites-enabled/owncloud
rm -f /etc/nginx/sites-enabled/default

echo "🔍 Semak konfigurasi Nginx..."
nginx -t && systemctl restart nginx

# ─────────────────────────────────────────────
# Maklumat Akhir
# ─────────────────────────────────────────────
echo "✅ Siap dipasang!"
echo "🌐 Akses melalui: http://<IP_RaspberryPi>"
echo "➡️  Pada halaman setup OwnCloud:"
echo "   - Pilih **SQLite** (lebih ringan, tiada database server)"
echo "   - Folder data: /var/www/html/owncloud/data"
echo "   - Tetapkan nama pengguna & kata laluan admin sendiri"
echo "💾 Semua fail disimpan di: /var/www/html/owncloud/"
