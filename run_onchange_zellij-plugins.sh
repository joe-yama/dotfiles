#!/bin/bash
set -euo pipefail

PLUGIN_DIR="${HOME}/.config/zellij/plugins"
mkdir -p "${PLUGIN_DIR}"

PLUGINS="
zellij-attention.wasm|https://github.com/KiryuuLight/zellij-attention/releases/latest/download/zellij-attention.wasm
ghost.wasm|https://github.com/vdbulcke/ghost/releases/latest/download/ghost.wasm
zellij-autolock.wasm|https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm
monocle.wasm|https://github.com/imsnif/monocle/releases/download/v0.100.2/monocle.wasm
zellij_forgot.wasm|https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm
room.wasm|https://github.com/rvcas/room/releases/download/v1.2.1/room.wasm
harpoon.wasm|https://github.com/Nacho114/harpoon/releases/download/v0.3.0/harpoon.wasm
multitask.wasm|https://github.com/leakec/multitask/releases/download/v0.44.2/multitask.wasm
zj-docker.wasm|https://github.com/dj95/zj-docker/releases/latest/download/zj-docker.wasm
zellaude.wasm|https://github.com/ishefi/zellaude/releases/latest/download/zellaude.wasm
zjstatus.wasm|https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm
zellij-newtab-plus.wasm|https://github.com/AlexZasorin/zellij-newtab-plus/releases/download/v0.6.0/zellij-newtab-plus.wasm
"

failed=0
while IFS='|' read -r name url; do
  [ -z "${name}" ] && continue
  dest="${PLUGIN_DIR}/${name}"
  if [ -f "${dest}" ]; then
    echo "Already exists: ${name}"
    continue
  fi
  echo "Downloading ${name}..."
  if curl -fSL "${url}" -o "${dest}"; then
    echo "  OK ($(du -h "${dest}" | cut -f1))"
  else
    echo "  FAILED: ${name}" >&2
    rm -f "${dest}"
    failed=$((failed + 1))
  fi
done <<< "${PLUGINS}"

if [ "${failed}" -gt 0 ]; then
  echo "${failed} plugin(s) failed to download" >&2
  exit 1
fi
echo "All zellij plugins ready."
