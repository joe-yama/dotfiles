#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

export PATH="${PNPM_HOME:-$HOME/Library/pnpm}:/opt/homebrew/bin:$PATH"

CCUSAGE=$(command -v ccusage)
if [ -z "$CCUSAGE" ]; then
  sketchybar --set claude icon.color=$SURFACE2 label="ERR" \
             --set claude.popup.remaining label="ccusage not installed"
  exit 0
fi

JSON=$("$CCUSAGE" blocks --active --token-limit max --json 2>/dev/null)

LEN=$(printf '%s' "$JSON" | jq -r '.blocks | length // 0')
if [ "$LEN" = "0" ]; then
  sketchybar --set claude icon.color=$SURFACE2 label="--M" \
             --set claude.popup.remaining label="(no active block)" \
             --set claude.popup.input     label="-" \
             --set claude.popup.output    label="-" \
             --set claude.popup.cache     label="-" \
             --set claude.popup.cost      label="-" \
             --set claude.popup.burn      label="-" \
             --set claude.popup.models    label="-"
  exit 0
fi

TOT=$(printf '%s' "$JSON" | jq -r '.blocks[0].totalTokens // 0')
TOT_M=$(awk -v t="$TOT" 'BEGIN { printf "%.1f", t/1000000 }')
PCT=$(printf '%s' "$JSON" | jq -r '(.blocks[0].totalTokens // 0) / ((.blocks[0].tokenLimitStatus.limit // 1) | if . == 0 then 1 else . end) * 100')
PCT_INT=$(printf '%.0f' "$PCT")
IN=$(printf '%s'  "$JSON" | jq -r '.blocks[0].tokenCounts.inputTokens // 0')
OUT=$(printf '%s' "$JSON" | jq -r '.blocks[0].tokenCounts.outputTokens // 0')
CW=$(printf '%s'  "$JSON" | jq -r '.blocks[0].tokenCounts.cacheCreationInputTokens // 0')
CR=$(printf '%s'  "$JSON" | jq -r '.blocks[0].tokenCounts.cacheReadInputTokens // 0')
COST=$(printf '%s' "$JSON" | jq -r '.blocks[0].costUSD // 0')
END=$(printf '%s' "$JSON" | jq -r '.blocks[0].endTime // ""')
BURN=$(printf '%s' "$JSON" | jq -r '.blocks[0].burnRate.tokensPerMinute // 0')
MODELS=$(printf '%s' "$JSON" | jq -r '.blocks[0].models // [] | map(sub("claude-";"") | sub("-[0-9]{8}";"")) | unique | join(", ")')

END_TRIM="${END%.*}"
END_TRIM="${END_TRIM%Z}"
END_EPOCH=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "$END_TRIM" +%s 2>/dev/null || echo 0)
NOW_EPOCH=$(date +%s)
REMAIN=$(( END_EPOCH - NOW_EPOCH ))
[ "$REMAIN" -lt 0 ] && REMAIN=0
RH=$(( REMAIN / 3600 ))
RM=$(( (REMAIN % 3600) / 60 ))

if   [ "$PCT_INT" -ge 95 ]; then COLOR=$RED
elif [ "$PCT_INT" -ge 80 ]; then COLOR=$PEACH
elif [ "$PCT_INT" -ge 50 ]; then COLOR=$YELLOW
else                              COLOR=$TEAL
fi

fmt() { printf "%'d" "${1:-0}" 2>/dev/null || printf "%s" "${1:-0}"; }

sketchybar --set claude icon.color="$COLOR" label="${TOT_M}M" \
  --set claude.popup.remaining label="${RH}h ${RM}m" \
  --set claude.popup.input     label="$(fmt "$IN")" \
  --set claude.popup.output    label="$(fmt "$OUT")" \
  --set claude.popup.cache     label="R:$(fmt "$CR") / W:$(fmt "$CW")" \
  --set claude.popup.cost      label="\$$(printf '%.2f' "$COST")" \
  --set claude.popup.burn      label="$(printf '%.0f' "$BURN") tok/min" \
  --set claude.popup.models    label="${MODELS:--}"
