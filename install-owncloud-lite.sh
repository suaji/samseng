# Semak root
if [ "$EUID" -ne 0 ]; then
  echo "⚠️  Jalankan sebagai root: sudo bash install-owncloud-lite.sh"
  exit 1
fi

echo "📦 Pasang komponen utama..."
apt install -y nginx php8.2 php8.2-fpm php8.2-xml php8.2-mbstring php8.2-zip php8.2-gd php8.2-curl php8.2-intl php8.2-bcmath php8.2-sqlite3 unzip wget

echo "📁 Muat turun OwnCloud..."
cd /tmp
wget https://download.owncloud.org/community/owncloud-complete-20210721.zip -O owncloud.zip
unzip owncloud.zip
mv owncloud /var/www/html/
chown -R www-data:www-data /var/www/html/owncloud
chmod -R 755 /var/www/html/owncloud

echo "⚙️  Konfigurasi PHP-FPM..."
sed -i 's|^;cgi.fix_pathinfo=.*|cgi.fix_pathinfo=0|' /etc/php/8.2/fpm/php.ini
systemctl enable php8.2-fpm
systemctl restart php8.2-fpm

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
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/owncloud /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default 2>/dev/null

nginx -t && systemctl restart nginx

echo "✅ Siap dipasang!"
echo "🌐 Akses melalui: http://<IP_RaspberryPi>:8181"
echo "➡️  Pada halaman setup OwnCloud:"
echo "   - Pilih 'SQLite' (lebih ringan, tiada database server)"
echo "   - Folder data: /var/www/html/owncloud/data"
echo "   - Admin user/password: anda tetapkan sendiri"
echo "💾 Semua fail disimpan di dalam: /var/www/html/owncloud/"
