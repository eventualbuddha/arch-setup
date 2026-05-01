#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Install an AUR helper (paru) if none is present.
# ---------------------------------------------------------------------------
install_aur_helper() {
    if command -v paru &>/dev/null || command -v yay &>/dev/null; then
        return 0
    fi

    echo "No AUR helper found — building paru from AUR..."
    sudo pacman -S --needed --noconfirm git base-devel

    local tmp
    tmp=$(mktemp -d)
    trap "rm -rf '$tmp'" RETURN
    git clone --depth=1 https://aur.archlinux.org/paru-bin.git "$tmp/paru"
    (cd "$tmp/paru" && makepkg -si --noconfirm)
}

aur_install() {
    if command -v paru &>/dev/null; then
        paru -S --needed --noconfirm "$@"
    else
        yay -S --needed --noconfirm "$@"
    fi
}

# ---------------------------------------------------------------------------
# 1. rustup + stable toolchain
# ---------------------------------------------------------------------------
install_rust() {
    if ! command -v rustup &>/dev/null; then
        echo "Installing rustup..."
        # rustup is in the official repos on Arch
        sudo pacman -S --needed --noconfirm rustup
    fi

    # Ensure the stable toolchain is present and up to date
    rustup toolchain install stable --no-self-update
    rustup default stable
    rustup component add rust-analyzer
    echo "Rust/Cargo (stable): $(rustup run stable cargo --version)"
}

# ---------------------------------------------------------------------------
# 2. Core CLI tools — prefer official repos, fall back to AUR
# ---------------------------------------------------------------------------
install_cli_tools() {
    # fish: official repos
    sudo pacman -S --needed --noconfirm fish

    # bat: official repos
    sudo pacman -S --needed --noconfirm bat

    # ripgrep: official repos
    sudo pacman -S --needed --noconfirm ripgrep

    # fd: official repos (package is fd)
    sudo pacman -S --needed --noconfirm fd

    sudo pacman -S --needed --noconfirm lazygit

    sudo pacman -S --needed --noconfirm uv
}

# ---------------------------------------------------------------------------
# 3. Fish config — alias cat → bat
# ---------------------------------------------------------------------------
configure_fish() {
    local fish_conf_dir="$HOME/.config/fish/conf.d"
    local alias_file="$fish_conf_dir/bat-alias.fish"

    mkdir -p "$fish_conf_dir"

    if [[ -f "$alias_file" ]] && grep -qF 'alias cat bat' "$alias_file" 2>/dev/null; then
        echo "Fish bat alias already configured, skipping."
        return 0
    fi

    cat > "$alias_file" <<'EOF'
# Use bat as a drop-in cat replacement
if command -q bat
    alias cat bat
end
EOF
    echo "Fish alias 'cat → bat' written to $alias_file"
}

# ---------------------------------------------------------------------------
# 4. mise + Node.js LTS
# ---------------------------------------------------------------------------
install_mise() {
    if ! command -v mise &>/dev/null; then
        echo "Installing mise..."
        sudo pacman -S --needed --noconfirm mise
    fi

    # Activate mise in fish via conf.d so PATH is managed in every session
    local mise_file="$HOME/.config/fish/conf.d/mise.fish"
    if [[ ! -f "$mise_file" ]] || ! grep -qF 'mise activate fish' "$mise_file" 2>/dev/null; then
        mkdir -p "$(dirname "$mise_file")"
        cat > "$mise_file" <<'EOF'
if command -q mise
    mise activate fish | source
end
EOF
        echo "mise fish activation written to $mise_file"
    else
        echo "mise fish activation already configured, skipping."
    fi

    # Install and globally pin Node.js LTS (idempotent — mise skips if current)
    mise install node@lts
    mise use --global node@lts
    echo "Node.js (LTS): $(mise exec node@lts -- node --version)"
}

# ---------------------------------------------------------------------------
# 5. Browsers
# ---------------------------------------------------------------------------
install_browsers() {
    # helium-browser-bin is in the CachyOS repo
    sudo pacman -S --needed --noconfirm helium-browser-bin

    xdg-settings set default-web-browser helium.desktop
    echo "Default browser set to Helium."
}

# ---------------------------------------------------------------------------
# 6. 1Password (app + CLI) — AUR
# ---------------------------------------------------------------------------
install_1password() {
    aur_install 1password 1password-cli
}

# ---------------------------------------------------------------------------
# 7. Optionally change the default shell to fish
# ---------------------------------------------------------------------------
set_default_shell() {
    local fish_path
    fish_path=$(command -v fish)

    if [[ "$(basename "$SHELL")" == "fish" ]]; then
        echo "Default shell is already fish."
        return 0
    fi

    # /etc/shells must list fish for chsh to accept it
    if ! grep -qxF "$fish_path" /etc/shells; then
        echo "$fish_path" | sudo tee -a /etc/shells > /dev/null
    fi

    echo "Changing default shell to fish for $USER..."
    chsh -s "$fish_path"
    echo "Log out and back in for the shell change to take effect."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
install_aur_helper
install_rust
install_cli_tools
install_browsers
install_1password
install_mise
configure_fish
set_default_shell

echo ""
echo "Setup complete."
echo "  - Restart your terminal (or run 'fish') to use the new shell."
echo "  - 'cat' will use bat automatically in fish sessions."
echo "  - Node.js LTS is managed by mise; run 'node --version' to confirm."
