#!/bin/bash
# install-owncloud-lite.sh — versi PHP 8.4 untuk Raspberry Pi (Trixie)

# Semak root
if [ "$EUID" -ne 0 ]; then
  echo "⚠️  Jalankan sebagai root: sudo bash install-owncloud-lite.sh"
  exit 1
fi

echo "📦 Pasang komponen utama..."
apt update -y
apt install -y nginx php8.4 php8.4-fpm php8.4-cli php8.4-common \
  php8.4-xml php8.4-mbstring php8.4-zip php8.4-gd php8.4-curl \
  php8.4-intl php8.4-bcmath php8.4-sqlite3 unzip wget

echo "📁 Muat turun OwnCloud..."
cd /tmp
wget https://download.owncloud.com/server/stable/owncloud-10.10.0.zip -O owncloud.zip
if unzip -tq owncloud.zip >/dev/null 2>&1; then
  unzip -oq owncloud.zip
  mv owncloud /var/www/html/
else
  echo "❌ Gagal unzip owncloud.zip. Semak sambungan Internet atau pautan muat turun."
  exit 1
fi

chown -R www-data:www-data /var/www/html/owncloud
chmod -R 755 /var/www/html/owncloud

echo "⚙️  Konfigurasi PHP-FPM..."
if [ -f /etc/php/8.4/fpm/php.ini ]; then
  sed -i 's|^;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo=0|' /etc/php/8.4/fpm/php.ini
fi
systemctl enable php8.4-fpm
systemctl restart php8.4-fpm

echo "🧾 Konfigurasi Nginx..."
cat <<'EOF' > /etc/nginx/sites-available/owncloud
server {
    listen 8181;
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
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
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

echo "✅ Siap dipasang!"
echo "🌐 Akses melalui: http://<IP_RaspberryPi>:8181"
echo "➡️  Pada halaman setup OwnCloud:"
echo "   - Pilih 'SQLite' (lebih ringan, tiada database server)"
echo "   - Folder data: /var/www/html/owncloud/data"
echo "   - Admin user/password: anda tetapkan sendiri"
echo "💾 Semua fail disimpan di dalam: /var/www/html/owncloud/"
