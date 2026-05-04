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

run tools-setup.sh
run neovim-setup.sh
run git-config.sh
run fido-pam-setup.sh
run_optional virt-manager-setup.sh
run_optional desktop-environment.sh

echo "All done."
