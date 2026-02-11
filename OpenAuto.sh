#!/bin/bash
# Skrip pemasangan OpenAuto + shortcut + auto-start

# Kemas kini sistem
sudo apt update && sudo apt upgrade -y

# Pasang kebergantungan
sudo apt install -y cmake g++ qtbase5-dev libqt5multimedia5 \
    libqt5multimedia5-plugins libqt5multimediawidgets5 libqt5multimedia5-dev \
    git

# Klon repositori OpenAuto
git clone https://github.com/f1xpl/openauto.git

# Bina projek
cd openauto
mkdir build && cd build
cmake ..
make -j$(nproc)

# Lokasi binari
OPENAUTO_BIN="$PWD/openauto"

# Buat shortcut desktop
DESKTOP_FILE="$HOME/.local/share/applications/openauto.desktop"
mkdir -p "$(dirname "$DESKTOP_FILE")"

cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=OpenAuto
Exec=$OPENAUTO_BIN
Icon=utilities-terminal
Type=Application
Categories=Utility;
EOF

# Buat systemd service untuk auto-start
SERVICE_FILE="$HOME/.config/systemd/user/openauto.service"
mkdir -p "$(dirname "$SERVICE_FILE")"

cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=OpenAuto Service
After=graphical.target

[Service]
ExecStart=$OPENAUTO_BIN
Restart=always

[Install]
WantedBy=default.target
EOF

# Aktifkan service
systemctl --user daemon-reload
systemctl --user enable openauto.service
systemctl --user start openauto.service

echo "Pemasangan selesai!"
echo "- Shortcut desktop dibuat di $DESKTOP_FILE"
echo "- Auto-start diaktifkan melalui systemd user service"
