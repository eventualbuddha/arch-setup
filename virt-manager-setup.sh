#!/usr/bin/env bash
set -euo pipefail

# Verify KVM hardware support
if ! LC_ALL=C lscpu | grep -q Virtualization; then
    echo "ERROR: CPU virtualization not detected. Enable VT-x/AMD-V in BIOS/UEFI." >&2
    exit 1
fi

# Install packages
sudo pacman -S --needed --noconfirm \
    libvirt virt-manager qemu-full dnsmasq dmidecode edk2-ovmf

# Enable and start services
sudo systemctl enable --now libvirtd.service virtlogd.service

# Add current user to libvirt group
sudo usermod -aG libvirt "$USER"

# Set the default libvirt URI so virsh connects to the system daemon without sudo
mkdir -p ~/.config/libvirt
grep -qxF 'uri_default = "qemu:///system"' ~/.config/libvirt/libvirt.conf 2>/dev/null \
    || echo 'uri_default = "qemu:///system"' >> ~/.config/libvirt/libvirt.conf

# Define the default NAT network if it doesn't already exist
if ! sudo virsh net-info default &>/dev/null; then
    sudo virsh net-define <(cat <<'EOF'
<network>
  <name>default</name>
  <forward mode="nat"/>
  <bridge name="virbr0" stp="on" delay="0"/>
  <ip address="192.168.122.1" netmask="255.255.255.0">
    <dhcp>
      <range start="192.168.122.2" end="192.168.122.254"/>
    </dhcp>
  </ip>
</network>
EOF
    )
fi

sudo virsh net-autostart default

if sudo virsh net-info default | grep -q "Active:.*no"; then
    sudo virsh net-start default
fi

# If UFW is active, allow VM traffic on the libvirt bridge.
# Without these rules, UFW blocks DHCP (port 67) and all forwarded traffic.
if sudo ufw status | grep -q "Status: active"; then
    if ! sudo ufw status | grep -q "virbr0"; then
        sudo ufw allow in  on virbr0
        sudo ufw allow out on virbr0
        sudo ufw route allow in  on virbr0
        sudo ufw route allow out on virbr0
    fi
fi

echo "Setup complete."
if ! id -nG "$USER" | grep -qw libvirt; then
    echo "Log out and back in for libvirt group membership to take effect."
fi
