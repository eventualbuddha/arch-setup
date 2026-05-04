# arch-setup

Idempotent setup scripts for Arch Linux.

## Usage

Run everything at once:

```sh
./setup.sh
```

Or run individual scripts:

| Script | What it does |
|---|---|
| `tools-setup.sh` | fish shell, bat (`cat` alias), ripgrep, fd, lazygit, uv, rustup (stable + rust-analyzer), mise, Node.js LTS, Helium browser, 1Password (app + CLI) |
| `neovim-setup.sh` | Neovim, LazyVim, language extras (Rust, TypeScript, JSON, TOML, YAML, Markdown) |
| `git-config.sh` | Global git config (identity, sane defaults) |
| `fido-pam-setup.sh` | YubiKey FIDO2 auth for sudo and polkit (GUI) via pam-u2f |
| `virt-manager-setup.sh` | libvirt/QEMU/virt-manager with a default NAT network |
| `desktop-environment.sh` | niri + DankMaterialShell (DMS), Nautilus, portals, notifications, polkit, NetworkManager |

## Notes

- All scripts require `sudo` for package installation.
- `tools-setup.sh` will install `paru` from the AUR if no AUR helper is present.
- `neovim-setup.sh` skips cloning LazyVim if `~/.config/nvim` already exists.
- After running, set **JetBrainsMono Nerd Font** as your terminal font for Neovim icons to render correctly.
- Log out and back in after the first run for the fish default shell change to take effect.
- `fido-pam-setup.sh` requires the YubiKey to be plugged in during the key registration step. Keep your current terminal open and verify sudo works in a new terminal before closing it.
- `desktop-environment.sh` is optional; after first login to niri, run `dms setup` to generate the niri config with DMS keybinds and layout.
