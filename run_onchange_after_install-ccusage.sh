#!/usr/bin/env bash
set -euo pipefail

if ! command -v pnpm >/dev/null 2>&1; then
  echo "pnpm not found — skip ccusage install"
  exit 0
fi

pnpm add -g ccusage@latest
