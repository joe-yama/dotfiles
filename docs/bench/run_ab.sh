#!/bin/zsh
# run_ab.sh — llama.cpp (llama-swap 経由) と mlx-serve (単独起動) を順序反転 2 周で A/B 計測する。
#   アーム: A=llama.cpp flash-next (UD-Q3_K_XL)  B=llama.cpp uncensored (IQ4_XS)
#           C=mlx-serve serial (MTP off)         D=mlx-serve MTP on (enable_mtp:true)
#   1 周目 A B C D / 2 周目 D C B A。アーム間 90 秒クールダウン。
#   llama-swap 側は各 mlx-serve 起動前に GET /unload で降ろし、2 モデル同時常駐を避ける。
set -u
S=${S:-${BENCH_DIR:-$HOME/bench}}
MLX="${MLX:-$HOME/.local/opt/mlx-serve/current/mlx-serve-macos-arm64/mlx-serve}"
MODEL_DIR="$HOME/.mlx-serve/models/ddalcu/Qwen3.8-Flash-Next-MLX-Serve-4bit"
MLX_PORT=11234
SWAP=http://127.0.0.1:8080
MLXB=http://127.0.0.1:$MLX_PORT
COOL=${COOL:-90}
RUNS=${RUNS:-3}
OUT=$S/results
mkdir -p "$OUT"
cd "$S"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$OUT/run_ab.log"; }

mlx_start() {
  log "mlx-serve start"
  nohup "$MLX" --model "$MODEL_DIR" --serve --host 127.0.0.1 --port $MLX_PORT --ctx-size 262144 \
    --log-level info > "$OUT/mlx-serve.$1.log" 2>&1 &
  echo $! > "$OUT/mlx.pid"
  for i in $(seq 1 600); do
    if curl -s -m 2 "$MLXB/health" >/dev/null 2>&1; then log "mlx-serve healthy after ${i}s"; return 0; fi
    sleep 1
  done
  log "mlx-serve did not become healthy"; return 1
}
mlx_stop() {
  if [[ -f "$OUT/mlx.pid" ]]; then kill "$(cat "$OUT/mlx.pid")" 2>/dev/null; sleep 5; kill -9 "$(cat "$OUT/mlx.pid")" 2>/dev/null; rm -f "$OUT/mlx.pid"; fi
  pkill -f "[m]lx-serve-macos-arm64/mlx-serve --model" 2>/dev/null
  log "mlx-serve stopped"
}
swap_unload() { curl -s -m 30 "$SWAP/unload" >/dev/null; log "llama-swap unloaded: $(curl -s -m 5 $SWAP/running)"; }

arm() { # name base model extra pgrep round
  local name=$1 base=$2 model=$3 extra=$4 pg=$5 round=$6
  log "=== arm $name round $round ==="
  python3 bench_ab.py --base "$base" --model "$model" --arm "$name" --out "$OUT/${name}_r${round}.json" \
    --extra "$extra" --runs $RUNS --mem-pgrep "$pg" 2>&1 | tee -a "$OUT/run_ab.log"
}
cool() { log "cooldown ${COOL}s"; sleep $COOL; }

A() { arm A_llamacpp_q3kxl   $SWAP qwen38-flash-next            '{"cache_prompt":false}' 'llama-server' $1; }
B() { arm B_llamacpp_iq4xs_unc $SWAP qwen38-flash-next-uncensored '{"cache_prompt":false}' 'llama-server' $1; }
C() { arm C_mlxserve_serial  $MLXB "$MLX_MODEL_ID" '{"enable_mtp":false}' 'mlx-serve --model' $1; }
D() { arm D_mlxserve_mtp     $MLXB "$MLX_MODEL_ID" '{"enable_mtp":true}'  'mlx-serve --model' $1; }

# ---- round 1: A B | C D ----
mlx_stop; swap_unload
A 1; cool
B 1; cool
swap_unload
mlx_start r1 || exit 1
MLX_MODEL_ID=$(curl -s "$MLXB/v1/models" | python3 -c 'import sys,json; print(json.load(sys.stdin)["data"][0]["id"])')
log "mlx model id: $MLX_MODEL_ID"
C 1; cool
D 1
mlx_stop; cool

# ---- round 2: D C | B A ----
mlx_start r2 || exit 1
D 2; cool
C 2
mlx_stop; cool
B 2; cool
A 2
swap_unload
log "ALL DONE"
