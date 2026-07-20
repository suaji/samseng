#!/bin/bash

OWNCLOUD_VERSION="10.16.3"
OWNCLOUD_ZIP="owncloud-${OWNCLOUD_VERSION}.zip"
OWNCLOUD_URL="https://download.owncloud.com/server/stable/${OWNCLOUD_ZIP}"
INSTALL_DIR="/var/www/html/owncloud"
DATA_DIR="/media/usb/owncloud_data"

echo "============================================================"
echo "  OwnCloud ${OWNCLOUD_VERSION} Installer"
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
    unzip \
    wget || { echo "GAGAL: install pakej"; exit 1; }

echo "    Semak PHP..."
if ! php8.2 -v > /dev/null 2>&1; then
    echo ""
    echo "  ❌ RALAT: PHP 8.2 tidak serasi dengan ARMv6 (Raspberry Pi 1)."
    echo "     Ini adalah isu build flag dalam Raspbian."
    echo "     Sila cuba: sudo apt update && sudo apt upgrade"
    echo "     kemudian jalankan skrip ini semula."
    echo "     Atau flash semula dengan Bullseye dan guna PHP 7.4."
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

sudo lighty-enable-mod fastcgi    || true
sudo lighty-enable-mod fastcgi-php || true

sudo sed -i 's/^memory_limit = .*/memory_limit = 128M/'         /etc/php/8.2/fpm/php.ini
sudo sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 512M/' /etc/php/8.2/fpm/php.ini
sudo sed -i 's/^post_max_size = .*/post_max_size = 512M/'       /etc/php/8.2/fpm/php.ini

sudo systemctl enable php8.2-fpm
sudo systemctl restart php8.2-fpm || { echo "GAGAL: php8.2-fpm tidak boleh start"; exit 1; }
sudo systemctl enable lighttpd
sudo systemctl restart lighttpd   || { echo "GAGAL: lighttpd tidak boleh start"; exit 1; }

echo "    lighttpd dan PHP-FPM berjaya dikonfigurasi."

echo ""
echo "[4/7] Download OwnCloud ${OWNCLOUD_VERSION}..."
cd /tmp

sudo rm -f "${OWNCLOUD_ZIP}"

sudo wget --progress=bar:force -O "${OWNCLOUD_ZIP}" "${OWNCLOUD_URL}" \
    || { echo "GAGAL: download OwnCloud"; exit 1; }

echo ""
echo "[5/7] Extract OwnCloud ke /var/www/html/..."

sudo rm -rf "${INSTALL_DIR}"

sudo unzip -q "${OWNCLOUD_ZIP}" -d /var/www/html/ \
    || { echo "GAGAL: unzip"; exit 1; }

sudo chown -R www-data:www-data "${INSTALL_DIR}"
sudo chmod -R 755 "${INSTALL_DIR}"

sudo rm -f "/tmp/${OWNCLOUD_ZIP}"

echo "    OwnCloud berjaya di-extract ke ${INSTALL_DIR}"

echo ""
echo "[6/7] Sedia folder data USB..."

if mountpoint -q /media/usb; then
    echo "    USB sudah di-mount di /media/usb"
else
    echo "    Cuba mount /dev/sda1 ke /media/usb..."
    sudo mkdir -p /media/usb

    if sudo mount /dev/sda1 /media/usb 2>/dev/null; then
        echo "    USB berjaya di-mount."
    else
        echo ""
        echo "    AMARAN: Gagal mount /dev/sda1."
        echo "    Data folder akan berada di SD card: ${INSTALL_DIR}/data"
        DATA_DIR="${INSTALL_DIR}/data"
    fi
fi

sudo mkdir -p "${DATA_DIR}"
sudo chown -R www-data:www-data "${DATA_DIR}"
sudo chmod -R 750 "${DATA_DIR}"
echo "    Folder data: ${DATA_DIR}"

echo ""
echo "[7/7] Konfigurasi URL rewrite untuk OwnCloud..."

sudo tee /etc/lighttpd/conf-available/90-owncloud.conf > /dev/null <<'EOF'
# OwnCloud configuration untuk lighttpd
$HTTP["url"] =~ "^/owncloud($|/)" {
    url.rewrite-once = (
        "^/owncloud/(.+\.php)(/.*)?$" => "/owncloud/$1$2",
        "^/owncloud/(.*)$" => "/owncloud/index.php/$1"
    )
    dir-listing.activate = "disable"
}

# Blok akses ke folder sensitif
$HTTP["url"] =~ "^/owncloud/(data|config|\.)" {
    url.access-deny = ("")
}
EOF

sudo lighty-enable-mod rewrite || true

sudo ln -sf /etc/lighttpd/conf-available/90-owncloud.conf \
            /etc/lighttpd/conf-enabled/90-owncloud.conf

sudo systemctl restart lighttpd || { echo "FAILED: lighttpd"; exit 1; }

PI_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "============================================================"
echo "  ✅ OwnCloud ${OWNCLOUD_VERSION} berjaya dipasang!"
echo "============================================================"
echo ""
echo "  🌐 Buka pelayar dan pergi ke:"
echo "     http://${PI_IP}/owncloud"
echo "============================================================"