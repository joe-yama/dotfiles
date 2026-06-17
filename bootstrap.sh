#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Dotfiles Bootstrap (chezmoi) ==="
echo ""

# Phase 1: Prerequisites
echo "[1/3] Checking prerequisites..."
xcode-select -p &>/dev/null || {
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Please re-run this script after installation completes."
    exit 0
}

if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

brew install chezmoi jj 1password-cli 2>/dev/null || true

# Phase 2: Initialize chezmoi
echo "[2/3] Initializing chezmoi..."
if [ ! -L "$HOME/.local/share/chezmoi" ]; then
    mkdir -p "$HOME/.local/share"
    ln -s "$DOTFILES_DIR" "$HOME/.local/share/chezmoi"
    echo "  Linked $DOTFILES_DIR -> ~/.local/share/chezmoi"
fi

if command -v op &>/dev/null && op account list &>/dev/null 2>&1; then
    chezmoi init --apply
    echo "  Applied dotfiles with 1Password secrets."
else
    echo "  WARN: 1Password CLI not signed in."
    echo "  Applying without templates that require 1Password..."
    echo "  Run later: op signin && chezmoi apply"
fi

# Phase 3: Post-setup
echo "[3/3] Post-setup..."
if [ ! -d "$HOME/.config/nvim" ]; then
    echo "  Neovim config not found. Clone your nvim config repo:"
    echo "    ghq get <your-nvim-config-repo>"
fi

echo ""
echo "=== Bootstrap complete! ==="
echo ""
echo "Next steps:"
echo "  1. Create ~/.zshrc.local with machine-specific settings"
echo "  2. Create ~/.ssh/config.d/proxy.conf if behind a corporate proxy"
echo "  3. Restart your shell"
