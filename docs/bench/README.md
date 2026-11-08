# ローカル LLM ベンチハーネス (2026-09-05)

`docs/mlxserve-ab-20260905.md` の計測に使ったスクリプト。標準ライブラリの Python 3 と zsh だけで動く。

- `bench_ab.py` — 1 エンドポイント (= 1 アーム) を同一条件で計測。short (thinking on) / long 24k+NIAH (thinking off) / tools / ja / code / `--refusal`。
  `--base` `--model` `--arm` `--out` 必須、`--extra` で `cache_prompt` や `enable_mtp` を注入する。
  長文脈用の実テキスト `longctx_source.txt` (英語技術文書 ≈ 3.6 文字/トークン、86k 文字 ≈ 24k トークン) を同じディレクトリに置くこと。
- `run_ab.sh` / `run_unc.sh` — 順序反転 2 周のドライバ。llama.cpp 側は llama-swap 経由、mlx-serve 側は単独起動 (`GET /unload` で先に llama-swap を空にする)。
- `run_unc_iq.sh` — 2026-11-08 の無検閲枠差し替え A/B。両アームとも llama-swap 経由 (本番 cmd のまま、mlx-serve の単独起動なし)。結果は `summary-20261108.md`。
  このとき `longctx_source.txt` は失われていたので `man -P cat zshall | col -bx | tr -s ' '` で作り直した (86k 文字 ≈ 19.8k トークン)。
- `summarize.py` — `results/*_r<N>.json` を Markdown 表にする。
- `memsample.sh` — 5 秒間隔で wired / compressor / swap / RSS を記録。

守ること: run 間 20 秒・アーム間 90 秒のクールダウン、順序反転 2 周、一意スタンプで prefix cache 無効化、
`usage.completion_tokens` でトークンを数える (SSE チャンク数ではない)、Hermes cron (毎日 09:00 JST) と重ねない、
mlx-serve を単独起動している間に llama-swap 側でモデルを立てない (Metal OOM で落ちる)。
