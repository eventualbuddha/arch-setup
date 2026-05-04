#!/usr/bin/env bash
set -euo pipefail

sudo pacman -S --needed --noconfirm \
  dms-shell-niri \
  nautilus \
  matugen \
  cava \
  qt6-multimedia \
  wtype \
  power-profiles-daemon \
  xdg-desktop-portal-gtk \
  xdg-desktop-portal-gnome \
  gnome-keyring \
  xwayland-satellite \
  mako \
  polkit-gnome \
  networkmanager \
  jq

sudo systemctl enable --now NetworkManager

systemctl --user enable dms
systemctl --user add-wants niri.service dms

echo ""
echo "NOTE: After first login, run 'dms setup' to generate the niri config with DMS keybinds and layout."
echo ""

DMS_SETTINGS="$HOME/.config/DankMaterialShell/settings.json"
mkdir -p "$(dirname "$DMS_SETTINGS")"
if [[ -f "$DMS_SETTINGS" ]]; then
  tmp=$(mktemp)
  jq '.lockBeforeSuspend = true' "$DMS_SETTINGS" > "$tmp"
  mv "$tmp" "$DMS_SETTINGS"
else
  printf '{"lockBeforeSuspend": true}\n' > "$DMS_SETTINGS"
fi
