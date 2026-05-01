#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run() {
    echo "==> $1"
    bash "$SCRIPT_DIR/$1"
    echo ""
}

run_optional() {
    echo "==> $1 (optional)"
    bash "$SCRIPT_DIR/$1" || echo "WARNING: $1 failed — skipping."
    echo ""
}

run arch-tools-setup.sh
run arch-neovim-setup.sh
run arch-git-config.sh
run arch-fido-pam-setup.sh
run_optional arch-virt-manager-setup.sh

echo "All done."
