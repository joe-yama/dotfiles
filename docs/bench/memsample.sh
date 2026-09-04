#!/bin/zsh
# 5 秒ごとに wired / compressor / swap / mlx-serve RSS を記録
out=$1
echo "time wired_gb compressor_gb swap_used_mb free_pct mlx_rss_gb llama_rss_gb" > $out
while true; do
  w=$(vm_stat | awk '/wired down/{gsub("\\.","",$4); printf "%.1f",$4*16384/1e9}')
  c=$(vm_stat | awk '/occupied by compressor/{gsub("\\.","",$5); printf "%.1f",$5*16384/1e9}')
  s=$(sysctl -n vm.swapusage | awk '{print $6}' | tr -d M)
  f=$(memory_pressure 2>/dev/null | awk '/free percentage/{print $5}')
  m=$(ps -axo rss,comm | awk '/mlx-serve-macos-arm64\/mlx-serve$/{s+=$1} END{printf "%.1f",s/1048576}')
  l=$(ps -axo rss,comm | awk '/llama-server$/{s+=$1} END{printf "%.1f",s/1048576}')
  echo "$(date +%H:%M:%S) $w $c $s $f $m $l" >> $out
  sleep 5
done
