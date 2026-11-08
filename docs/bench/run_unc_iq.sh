#!/bin/zsh
# run_unc_iq.sh — 無検閲枠の A/B (2026-11-08): G=現行 ARC4NUM / H=AinsleyMarkov iQ-MLX-4.7bpw
#   どちらも llama-swap 経由 (本番と同じ cmd・settle・MTP 既定 on)。1 周目 G H、2 周目 H G、拒否プローブ付き。
#   llama-swap の排他スワップに任せるので mlx-serve の単独起動はしない。全区間でメモリサンプラーを回す。
#   使い方: BENCH_DIR=<作業dir> zsh run_unc_iq.sh  (作業dir に bench_ab.py / summarize.py / memsample.sh /
#           longctx_source.txt を置く。結果は <作業dir>/results/)
set -u
S=${BENCH_DIR:-$HOME/bench}
SWAP=http://127.0.0.1:8080
COOL=${COOL:-90}
RUNS=${RUNS:-3}
OUT=$S/results
mkdir -p "$OUT"
cd "$S"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$OUT/run_ab.log"; }
swap_unload() { curl -s -m 30 "$SWAP/unload" >/dev/null; log "llama-swap unloaded: $(curl -s -m 5 $SWAP/running)"; }
cool() { log "cooldown ${COOL}s"; sleep $COOL; }
armr() { # name model round
  local name=$1 model=$2 round=$3
  log "=== arm $name round $round ==="
  python3 bench_ab.py --base "$SWAP" --model "$model" --arm "$name" --out "$OUT/${name}_r${round}.json" \
    --extra '{}' --runs $RUNS --mem-pgrep 'mlx-serve --model' --refusal 2>&1 | tee -a "$OUT/run_ab.log"
}
G() { armr G_unc_arc4num qwen38-flash-next-uncensored    $1; }
H() { armr H_unc_iq      qwen38-flash-next-uncensored-iq $1; }

nohup "$S/memsample.sh" "$OUT/memsample_unc_iq.txt" > /dev/null 2>&1 &
MEM_PID=$!
trap 'kill $MEM_PID 2>/dev/null' EXIT

swap_unload; cool
G 1; cool
H 1; swap_unload; cool   # 周をまたぐ同一アームもプロセスを立て直す
H 2; cool
G 2
swap_unload
log "ALL DONE (unc-iq)"
