#!/bin/bash
# install-owncloud10-lite-raspberry.sh
# Optimum untuk Raspberry Pi 1 (512MB)
# Guna SQLite + Nginx-Light + PHP Minimal

# === Pastikan root ===
if [ "$EUID" -ne 0 ]; then
  echo "❌ Jalankan dengan: sudo bash install-owncloud10-lite-raspberry.sh"
  exit 1
fi

echo "🧩 Kemas kini sistem..."
apt update && apt upgrade -y

# === Pasang pakej asas ===
echo "📦 Pasang Nginx-Light + PHP (versi minimum)..."
apt install -y nginx-light php php-fpm php-gd php-sqlite3 php-json php-xml php-mbstring php-zip php-curl unzip wget

# === Muat turun OwnCloud 10.10.0 ===
echo "🌐 Muat turun OwnCloud 10.10.0..."
cd /tmp
wget https://download.owncloud.com/server/stable/owncloud-10.10.0.zip -O owncloud.zip
unzip owncloud.zip -d /var/www/
chown -R www-data:www-data /var/www/owncloud

# === Konfigurasi Nginx ===
echo "⚙️ Konfigurasi Nginx..."
cat <<'EOF' > /etc/nginx/sites-available/owncloud
server {
    listen 80;
    server_name _;
    root /var/www/owncloud;

    index index.php index.html;
    client_max_body_size 512M;

    location / {
        rewrite ^ /index.php$request_uri;
    }

    location ~ \.php(?:$|/) {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(?:css|js|woff2?|svg|gif|map)$ {
        try_files $uri /index.php$request_uri;
        access_log off;
        expires 30d;
        add_header Cache-Control "public";
    }
}
EOF

ln -sf /etc/nginx/sites-available/owncloud /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx php7.4-fpm

# === Papar maklumat ===
IP=$(hostname -I | awk '{print $1}')
echo ""
echo "✅ OwnCloud 10.10.0 (Lite) telah dipasang!"
echo "🌍 Akses melalui pelayar:  http://$IP/"
echo "💾 Database: SQLite (auto dibuat)"
echo ""
echo "📱 Untuk Android: guna aplikasi rasmi 'ownCloud'"
echo "   dan masukkan URL di atas + akaun admin anda semasa setup pertama."
echo ""
