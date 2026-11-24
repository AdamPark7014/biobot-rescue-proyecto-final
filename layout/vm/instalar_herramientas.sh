#!/usr/bin/env bash
set -euo pipefail

LIBRELANE_VERSION="${LIBRELANE_VERSION:-3.0.17}"

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker.io python3-venv python3-pip git zstd \
    magic klayout \
    ubuntu-desktop-minimal open-vm-tools-desktop

sudo netplan apply
sleep 5

# docker sin sudo
sudo usermod -aG docker "$USER"

sudo tee /etc/gdm3/custom.conf >/dev/null <<EOF
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=$USER
WaylandEnable=false
EOF
sudo systemctl set-default graphical.target

python3 -m venv "$HOME/librelane-venv"
"$HOME/librelane-venv/bin/pip" install --upgrade pip
"$HOME/librelane-venv/bin/pip" install "librelane==${LIBRELANE_VERSION}"
grep -q librelane-venv "$HOME/.bashrc" || echo 'source "$HOME/librelane-venv/bin/activate"' >> "$HOME/.bashrc"

echo
echo "Listo. Cierra la sesion (o reinicia) para que el grupo docker aplique y luego:"
echo "  sg docker -c 'librelane --dockerized --smoke-test'   # baja la imagen y la PDK sky130A y prueba"
