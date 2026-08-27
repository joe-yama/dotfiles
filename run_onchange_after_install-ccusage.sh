#!/usr/bin/env bash
set -euo pipefail

# chezmoi runs scripts under a non-interactive bash, so the PNPM_HOME exported
# from .zshrc is absent and pnpm cannot write to its global bin directory.
export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
export PATH="$PNPM_HOME/bin:$PATH"

if ! command -v pnpm >/dev/null 2>&1; then
  echo "pnpm not found — skip ccusage install"
  exit 0
fi

pnpm add -g ccusage@latest
