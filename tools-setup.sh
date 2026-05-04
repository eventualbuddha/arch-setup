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

    # starship: official repos
    sudo pacman -S --needed --noconfirm starship
}

# ---------------------------------------------------------------------------
# 3. Fish config
# ---------------------------------------------------------------------------
configure_fish() {
    local fish_conf_dir="$HOME/.config/fish/conf.d"
    mkdir -p "$fish_conf_dir"

    # Source distro-provided fish config if present (e.g. CachyOS)
    local cachyos_config="/usr/share/cachyos-fish-config/cachyos-config.fish"
    local distro_file="$fish_conf_dir/00-distro.fish"
    if [[ -f "$cachyos_config" ]] && ! grep -qF "$cachyos_config" "$distro_file" 2>/dev/null; then
        cat > "$distro_file" <<EOF
source $cachyos_config
EOF
        echo "Distro fish config sourced via $distro_file"
    fi

    # Suppress the greeting (distro configs often set one)
    local greeting_file="$fish_conf_dir/greeting.fish"
    if [[ ! -f "$greeting_file" ]]; then
        cat > "$greeting_file" <<'EOF'
function fish_greeting
end
EOF
        echo "Empty fish greeting written to $greeting_file"
    fi

    # starship prompt
    local starship_file="$fish_conf_dir/starship.fish"
    if [[ ! -f "$starship_file" ]]; then
        cat > "$starship_file" <<'EOF'
if command -q starship
    starship init fish | source
end
EOF
        echo "Starship fish integration written to $starship_file"
    fi

    # cat → bat alias
    local alias_file="$fish_conf_dir/bat-alias.fish"
    if ! grep -qF 'alias cat bat' "$alias_file" 2>/dev/null; then
        cat > "$alias_file" <<'EOF'
if command -q bat
    alias cat bat
end
EOF
        echo "Fish alias 'cat → bat' written to $alias_file"
    fi
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

    local op_file="$HOME/.config/fish/conf.d/1password.fish"
    if [[ ! -f "$op_file" ]]; then
        mkdir -p "$(dirname "$op_file")"
        cat > "$op_file" <<'EOF'
if test -f ~/.config/op/plugins.sh
    source ~/.config/op/plugins.sh
end
EOF
        echo "1Password fish plugin written to $op_file"
    fi
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
