#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# 1. Packages
# ---------------------------------------------------------------------------
install_packages() {
    # yubikey-manager ships udev rules that grant unprivileged access to the
    # YubiKey device node; without them pamu2fcfg can't reach the key.
    sudo pacman -S --needed --noconfirm libfido2 pam-u2f yubikey-manager

    # Apply the new udev rules immediately without a reboot
    sudo udevadm control --reload-rules
    sudo udevadm trigger
}

# ---------------------------------------------------------------------------
# 2. Register the FIDO key → ~/.config/Yubico/u2f_keys
# ---------------------------------------------------------------------------
register_key() {
    local key_dir="$HOME/.config/Yubico"
    local key_file="$key_dir/u2f_keys"

    mkdir -p "$key_dir"

    if [[ -f "$key_file" ]]; then
        echo "Key mapping already exists at $key_file — skipping registration."
        echo "To enrol an additional key: pamu2fcfg -n >> $key_file"
        return 0
    fi

    echo "Insert your FIDO key and touch it when it flashes..."
    # Write to a temp file first — the redirect "> $key_file" would create an
    # empty file before pamu2fcfg runs, making re-registration impossible on
    # a subsequent run if the command fails (key absent, timeout, etc.).
    local tmp_key
    tmp_key=$(mktemp)
    trap "rm -f '$tmp_key'" RETURN
    pamu2fcfg > "$tmp_key"
    mv "$tmp_key" "$key_file"
    chmod 600 "$key_file"
    echo "Key enrolled at $key_file"
}

# ---------------------------------------------------------------------------
# 3. Patch a PAM file to try FIDO first, fall back to password
#
#    'sufficient' means: if the key touch succeeds, grant access immediately.
#    If the key is absent or the touch fails, PAM continues to the next
#    module (password), so the user is never locked out.
#    'nouserok' additionally allows users with no key file to fall through.
#    'cue' prints "Please touch your security key" as a prompt.
# ---------------------------------------------------------------------------
patch_pam_file() {
    local pam_file="$1"
    local insert='auth       sufficient   pam_u2f.so cue nouserok'

    if [[ ! -f "$pam_file" ]]; then
        echo "Warning: $pam_file not found, skipping."
        return 0
    fi

    if grep -q 'pam_u2f' "$pam_file"; then
        echo "$pam_file already configured, skipping."
        return 0
    fi

    # Back up the original
    sudo cp "$pam_file" "${pam_file}.bak"

    # Insert our line before the first 'auth' line
    local tmp
    tmp=$(mktemp)
    trap "rm -f '$tmp'" RETURN
    awk -v line="$insert" '/^auth/ && !done { print line; done=1 } { print }' \
        "$pam_file" > "$tmp"
    sudo cp "$tmp" "$pam_file"

    echo "pam_u2f added to $pam_file (original backed up to ${pam_file}.bak)"
}

configure_pam() {
    patch_pam_file /etc/pam.d/sudo
    patch_pam_file /etc/pam.d/polkit-1
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
install_packages
register_key
configure_pam

echo ""
echo "Setup complete."
echo "  IMPORTANT: keep this terminal open and test sudo in a new terminal"
echo "  before closing this session, in case PAM needs to be rolled back."
echo "  To roll back: sudo cp /etc/pam.d/sudo.bak /etc/pam.d/sudo"
