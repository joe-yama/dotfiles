#!/bin/zsh
# run_unc.sh — 無検閲枠の A/B: B=llama.cpp IQ4_XS (llama-swap) / E=mlx-serve ARC4NUM serial / F=同 MTP
#   1 周目 B E F、2 周目 F E B。mlx-serve 区間はメモリサンプラー稼働。
set -u
S=${BENCH_DIR:-$HOME/bench}
eval "$(sed -n '/^MLX=/,/^cool()/p' "$S/run_ab.sh")"
MODEL_DIR="$HOME/.mlx-serve/models/ARC4NUM/Qwen3.8-Flash-Next-Uncensored-MLX-Serve-4bit"
cd "$S"
armr() { # name base model extra pgrep round  (拒否プローブ付き)
  local name=$1 base=$2 model=$3 extra=$4 pg=$5 round=$6
  log "=== arm $name round $round ==="
  python3 bench_ab.py --base "$base" --model "$model" --arm "$name" --out "$OUT/${name}_r${round}.json" \
    --extra "$extra" --runs $RUNS --mem-pgrep "$pg" --refusal 2>&1 | tee -a "$OUT/run_ab.log"
}
B() { armr B_llamacpp_iq4xs_unc $SWAP qwen38-flash-next-uncensored '{"cache_prompt":false}' 'llama-server' $1; }
E() { armr E_mlxserve_unc_serial $MLXB "$MLX_MODEL_ID" '{"enable_mtp":false}' 'mlx-serve --model' $1; }
F() { armr F_mlxserve_unc_mtp    $MLXB "$MLX_MODEL_ID" '{"enable_mtp":true}'  'mlx-serve --model' $1; }
mlx_up() {
  swap_unload
  nohup "$S/memsample.sh" "$OUT/memsample_unc_$1.txt" > /dev/null 2>&1 &
  echo $! > "$OUT/memsample.pid"
  mlx_start "$1" || exit 1
  MLX_MODEL_ID=$(curl -s "$MLXB/v1/models" | python3 -c 'import sys,json; print(json.load(sys.stdin)["data"][0]["id"])')
  log "mlx model id: $MLX_MODEL_ID"
}
mlx_down() { mlx_stop; kill "$(cat "$OUT/memsample.pid")" 2>/dev/null; }

mlx_stop; swap_unload
# round 1: B | E F
B 3; cool
mlx_up unc1
E 1; cool
F 1
mlx_down; cool
# round 2: F E | B
mlx_up unc2
F 2; cool
E 2
mlx_down; cool
B 4
swap_unload
log "ALL DONE (unc)"
