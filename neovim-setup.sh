#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# 1. Neovim and runtime dependencies
# ---------------------------------------------------------------------------
install_neovim() {
    sudo pacman -S --needed --noconfirm \
        neovim \
        gcc \
        lazygit \
        python-pynvim \
        unzip \
        wl-clipboard \
        xclip \
        ttf-jetbrains-mono-nerd
}

# ---------------------------------------------------------------------------
# 2. LazyVim starter config
# ---------------------------------------------------------------------------
install_lazyvim() {
    local nvim_dir="$HOME/.config/nvim"

    if [[ -d "$nvim_dir" ]]; then
        echo "~/.config/nvim already exists, skipping LazyVim clone."
        return 0
    fi

    echo "Cloning LazyVim starter..."
    git clone --depth=1 https://github.com/LazyVim/starter "$nvim_dir"
    # Detach from the starter repo so the user owns the config
    rm -rf "$nvim_dir/.git"
    echo "LazyVim starter installed to $nvim_dir"
}

# ---------------------------------------------------------------------------
# 3. Language and tooling extras
#    Extras must be imported in lazy.lua between the base lazyvim.plugins
#    spec and { import = "plugins" }. A file under lua/plugins/ is loaded
#    too late and triggers a load-order warning from LazyVim.
# ---------------------------------------------------------------------------
configure_extras() {
    local lazy_config="$HOME/.config/nvim/lua/config/lazy.lua"

    # Remove the incorrectly-placed file produced by earlier versions of this script
    local old_file="$HOME/.config/nvim/lua/plugins/lang-extras.lua"
    [[ -f "$old_file" ]] && rm "$old_file" && echo "Removed $old_file"

    if [[ ! -f "$lazy_config" ]]; then
        echo "Warning: $lazy_config not found, skipping extras configuration."
        return 0
    fi

    # Only match uncommented imports so the starter's example comments don't
    # fool the idempotency check
    if grep -qE '^\s*\{ import = "lazyvim\.plugins\.extras' "$lazy_config"; then
        echo "LazyVim extras already configured in $lazy_config, skipping."
        return 0
    fi

    local tmp
    tmp=$(mktemp)
    trap "rm -f '$tmp'" RETURN
    # Insert extras immediately before the user-plugins import line
    awk '
        /import.*"plugins"/ && !done {
            print "    { import = \"lazyvim.plugins.extras.lang.rust\" },"
            print "    { import = \"lazyvim.plugins.extras.lang.typescript\" },"
            print "    { import = \"lazyvim.plugins.extras.lang.json\" },"
            print "    { import = \"lazyvim.plugins.extras.lang.toml\" },"
            print "    { import = \"lazyvim.plugins.extras.lang.yaml\" },"
            print "    { import = \"lazyvim.plugins.extras.lang.markdown\" },"
            print "    { import = \"lazyvim.plugins.extras.formatting.prettier\" },"
            print "    { import = \"lazyvim.plugins.extras.linting.eslint\" },"
            done=1
        }
        { print }
    ' "$lazy_config" > "$tmp"
    cp "$tmp" "$lazy_config"
    rm "$tmp"

    echo "LazyVim extras added to $lazy_config"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
install_neovim
install_lazyvim
configure_extras

echo ""
echo "Setup complete."
echo "  - Run 'nvim' to launch; LazyVim will bootstrap all plugins on first start."
echo "  - Set 'JetBrainsMono Nerd Font' (or similar) as your terminal font for icons."
echo "  - Mason will install LSP servers/formatters automatically on first open."
