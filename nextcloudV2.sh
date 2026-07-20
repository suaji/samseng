#!/bin/bash

NEXTCLOUD_VERSION="28.0.0"
NEXTCLOUD_ZIP="nextcloud-${NEXTCLOUD_VERSION}.zip"
NEXTCLOUD_URL="https://download.nextcloud.com/server/releases/${NEXTCLOUD_ZIP}"
INSTALL_DIR="/var/www/html/nextcloud"
DATA_DIR="/media/usb/owncloud_data"

echo "============================================================"
echo "  Nextcloud ${NEXTCLOUD_VERSION} Installer"
echo "  Raspberry Pi 1 | Bookworm 32-bit | PHP 8.2 | SQLite"
echo "============================================================"

echo ""
echo "[1/7] Update senarai pakej..."
sudo apt update || { echo "GAGAL: apt update"; exit 1; }

echo ""
echo "[2/7] Install lighttpd dan PHP 8.2..."
sudo apt install -y \
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
    php8.2-gmp \
    php8.2-imagick \
    php8.2-bz2 \
    php8.2-sysvsem \
    unzip \
    wget || { echo "GAGAL: install pakej"; exit 1; }

echo "    Semak PHP..."
if ! php8.2 -v > /dev/null 2>&1; then
    echo ""
    echo "  RALAT: PHP 8.2 tidak boleh jalan pada sistem ini."
    echo "  Sila jalankan: sudo apt update && sudo apt upgrade"
    echo "  kemudian cuba skrip ini semula."
    exit 1
fi
echo "    PHP 8.2 OK!"

echo ""
echo "[3/7] Konfigurasi lighttpd + PHP-FPM..."

sudo tee /etc/lighttpd/conf-available/15-fastcgi-php.conf > /dev/null <<'EOF'
fastcgi.server += ( ".php" =>
    ((
        "socket" => "/run/php/php8.2-fpm.sock",
        "broken-scriptfilename" => "enable"
    ))
)
EOF

sudo lighty-enable-mod fastcgi     || true
sudo lighty-enable-mod fastcgi-php || true
sudo lighty-enable-mod rewrite     || true

sudo sed -i 's/^memory_limit = .*/memory_limit = 128M/'               /etc/php/8.2/fpm/php.ini
sudo sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 512M/' /etc/php/8.2/fpm/php.ini
sudo sed -i 's/^post_max_size = .*/post_max_size = 512M/'             /etc/php/8.2/fpm/php.ini
sudo sed -i 's/^max_execution_time = .*/max_execution_time = 300/'    /etc/php/8.2/fpm/php.ini

sudo systemctl enable php8.2-fpm
sudo systemctl restart php8.2-fpm || { echo "GAGAL: php8.2-fpm tidak boleh start"; exit 1; }
sudo systemctl enable lighttpd
sudo systemctl restart lighttpd   || { echo "GAGAL: lighttpd tidak boleh start"; exit 1; }

echo "    lighttpd dan PHP-FPM berjaya dikonfigurasi."

echo ""
echo "[4/7] Download Nextcloud ${NEXTCLOUD_VERSION}..."
cd /tmp
sudo rm -f "${NEXTCLOUD_ZIP}"
sudo wget --progress=bar:force -O "${NEXTCLOUD_ZIP}" "${NEXTCLOUD_URL}" \
    || { echo "GAGAL: download Nextcloud"; exit 1; }

echo ""
echo "[5/7] Extract Nextcloud ke /var/www/html/..."
sudo rm -rf "${INSTALL_DIR}"
sudo unzip -q "${NEXTCLOUD_ZIP}" -d /var/www/html/ \
    || { echo "GAGAL: unzip"; exit 1; }

sudo mkdir -p "${DATA_DIR}"
sudo chown -R www-data:www-data "${INSTALL_DIR}"
sudo chmod -R 755 "${INSTALL_DIR}"
sudo chmod -R 750 "${DATA_DIR}"

sudo rm -f "/tmp/${NEXTCLOUD_ZIP}"
echo "    Nextcloud berjaya di-extract ke ${INSTALL_DIR}"
echo "    Folder data: ${DATA_DIR}"
echo ""
echo "[6/7] Konfigurasi lighttpd untuk Nextcloud..."

sudo tee /etc/lighttpd/conf-available/90-nextcloud.conf > /dev/null <<'EOF'
# Nextcloud configuration untuk lighttpd
$HTTP["url"] =~ "^/nextcloud($|/)" {
    url.rewrite-once = (
        "^/nextcloud/index\.php/.*$"          => "$0",
        "^/nextcloud/remote\.php/.*$"         => "$0",
        "^/nextcloud/public\.php/.*$"         => "$0",
        "^/nextcloud/cron\.php$"              => "$0",
        "^/nextcloud/status\.php$"            => "$0",
        "^/nextcloud/ocs/.*$"                 => "$0",
        "^/nextcloud/ocs-provider/.*$"        => "$0",
        "^/nextcloud/ocm-provider/.*$"        => "$0",
        "^/nextcloud/(.*)$"                   => "/nextcloud/index.php/$1"
    )
    dir-listing.activate = "disable"
}

# Blok akses ke folder sensitif
$HTTP["url"] =~ "^/nextcloud/(data|config|\.)" {
    url.access-deny = ("")
}
EOF

sudo ln -sf /etc/lighttpd/conf-available/90-nextcloud.conf \
            /etc/lighttpd/conf-enabled/90-nextcloud.conf

sudo systemctl restart lighttpd || { echo "GAGAL: lighttpd restart"; exit 1; }

echo ""
echo "[7/7] Setup cron untuk background jobs..."
(sudo crontab -u www-data -l 2>/dev/null | grep -v nextcloud; \
 echo "*/5 * * * * php8.2 -f ${INSTALL_DIR}/cron.php") \
 | sudo crontab -u www-data -

echo "    Cron berjaya dikonfigurasi (setiap 5 minit)."

PI_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "============================================================"
echo "  Nextcloud ${NEXTCLOUD_VERSION} berjaya dipasang!"
echo "============================================================"
echo ""
echo "  Buka pelayar dan pergi ke:"
echo "     http://${PI_IP}/nextcloud"
echo "============================================================"
