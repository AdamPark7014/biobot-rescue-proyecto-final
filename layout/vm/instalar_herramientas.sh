#!/usr/bin/env bash
# instalar_herramientas.sh - Se corre una vez DENTRO de la VM Ubuntu 24.04 (usuario adam).
# Deja: escritorio Ubuntu minimo, Docker, LibreLane (sucesor de OpenLane 2) en un venv,
# la PDK sky130A (via ciel) y Magic + KLayout para ver el layout.
set -euo pipefail

LIBRELANE_VERSION="${LIBRELANE_VERSION:-3.0.17}"

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker.io python3-venv python3-pip git zstd \
    magic klayout \
    ubuntu-desktop-minimal open-vm-tools-desktop

# El paquete network-manager trae /usr/lib/netplan/00-network-manager-all.yaml: la tarjeta
# pasa a NetworkManager, pero queda «unmanaged» y sin IP hasta reaplicar netplan.
sudo netplan apply
sleep 5

# Docker sin sudo (LibreLane corre las herramientas dentro de su contenedor)
sudo usermod -aG docker "$USER"

# Inicio de sesion automatico en el escritorio (VM local de practica)
sudo tee /etc/gdm3/custom.conf >/dev/null <<EOF
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=$USER
WaylandEnable=false
EOF
sudo systemctl set-default graphical.target

# LibreLane en un entorno de Python aparte
python3 -m venv "$HOME/librelane-venv"
"$HOME/librelane-venv/bin/pip" install --upgrade pip
"$HOME/librelane-venv/bin/pip" install "librelane==${LIBRELANE_VERSION}"
grep -q librelane-venv "$HOME/.bashrc" || echo 'source "$HOME/librelane-venv/bin/activate"' >> "$HOME/.bashrc"

echo
echo "Listo. Cierra la sesion (o reinicia) para que el grupo docker aplique y luego:"
echo "  sg docker -c 'librelane --dockerized --smoke-test'   # baja la imagen y la PDK sky130A y prueba"
