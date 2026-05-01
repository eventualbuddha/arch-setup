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
| `arch-cli-tools-setup.sh` | fish shell, bat (`cat` alias), ripgrep, fd, rustup (stable + rust-analyzer), mise, Node.js LTS |
| `arch-neovim-setup.sh` | Neovim, LazyVim, language extras (Rust, TypeScript, JSON, TOML, YAML, Markdown) |
| `arch-git-config.sh` | Global git config (identity, sane defaults) |
| `arch-fido-pam-setup.sh` | YubiKey FIDO2 auth for sudo and polkit (GUI) via pam-u2f |
| `arch-virt-manager-setup.sh` | libvirt/QEMU/virt-manager with a default NAT network |

## Notes

- All scripts require `sudo` for package installation.
- `arch-cli-tools-setup.sh` will install `paru` from the AUR if no AUR helper is present.
- `arch-neovim-setup.sh` skips cloning LazyVim if `~/.config/nvim` already exists.
- After running, set **JetBrainsMono Nerd Font** as your terminal font for Neovim icons to render correctly.
- Log out and back in after the first run for the fish default shell change to take effect.
- `arch-fido-pam-setup.sh` requires the YubiKey to be plugged in during the key registration step. Keep your current terminal open and verify sudo works in a new terminal before closing it.
