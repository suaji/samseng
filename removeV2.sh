# 1. Hentikan servis
sudo systemctl stop lighttpd php8.2-fpm 2>/dev/null || true
sudo systemctl disable lighttpd php8.2-fpm 2>/dev/null || true

# 2. Purge lighttpd dan PHP 8.2 semua pakej
sudo apt purge -y \
    lighttpd \
    php8.2 \
    php8.2-fpm \
    php8.2-gd \
    php8.2-sqlite3 \
    php8.2-zip \
    php8.2-xml \
    php8.2-mbstring \
    php8.2-curl \
    php8.2-intl \
    php8.2-bcmath \
    php8.2-gmp

# 3. Buang dependency yang tidak perlu
sudo apt autoremove -y
sudo apt autoclean

# 4. Padam folder OwnCloud dan config lighttpd
sudo rm -rf /var/www/html/owncloud
sudo rm -f /etc/lighttpd/conf-available/15-fastcgi-php.conf
sudo rm -f /etc/lighttpd/conf-available/90-owncloud.conf
sudo rm -f /etc/lighttpd/conf-enabled/90-owncloud.conf

# 5. Padam zip yang mungkin ada dalam /tmp
sudo rm -f /tmp/owncloud-*.zip

echo "✅ Selesai! Sistem sudah bersih."