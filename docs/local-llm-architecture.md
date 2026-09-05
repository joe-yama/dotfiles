# このマシンのローカル LLM アーキテクチャ

MacBook Pro (Apple M4 Max 40 コア GPU、ユニファイドメモリ 128GB、帯域 546GB/s、macOS 26.x) を
tailnet 内の OpenAI 互換 LLM サーバーとして運用している。2026-08-27 構築、2026-09-05 に推論ランタイムを
llama.cpp から mlx-serve へ切り替えた (経緯と実測は `mlxserve-ab-20260905.md`)。

## 全体像

```
   tailnet の各端末                            この Mac (josukes-macbook-pro)
 ┌──────────────────┐   HTTPS 443            ┌────────────────────────────────────────────────┐
 │ opencode         │ ─────────────────────▶ │ tailscale serve ──▶ 127.0.0.1:8080 llama-swap  │
 │ DeepSeekHarness  │  …ts.net/v1            │   (LaunchAgent local.llama-swap、排他スワップ)  │
 │ (dsh web :8443)  │                        │        │ model 名で上流を起動/切替                │
 └──────────────────┘                        │        ▼                                         │
 ┌──────────────────┐   127.0.0.1:8080/v1    │  mlx-serve --model ~/.mlx-serve/models/<pack>    │
 │ Hermes Agent     │ ─────────────────────▶ │   (Zig+Metal、MLX 0.32、ポートは llama-swap 採番)│
 │ (gateway/cron)   │                        │        │ 重み 67〜70GB wired + n-gram 表 32GB mmap │
 └──────────────────┘                        │        ▼  Metal GPU                              │
                                             └────────────────────────────────────────────────┘
```

- **入口は llama-swap 一本** (`127.0.0.1:8080`)。`tailscale serve` が 443 をここへ転送し、tailnet 内 (個人 tailnet = 認証境界) から `https://josukes-macbook-pro.tail97ab8.ts.net/v1` で使える。API キーは無し。
- llama-swap はリクエストの `model` 名を見て上流サーバーを**起動・排他スワップ**する。2 モデルが同時に常駐することはない (mlx-serve は wired メモリを使うため、この排他性が安定性の前提)。
- 上流は mlx-serve のみ (2026-09-05 以降)。llama.cpp の公式バイナリも `~/.local/opt/llama.cpp` に残しているが、レジストリからは外した。vllm-mlx (uv tool) も残置しているが未使用。

## モデルレジストリ (`~/.config/llama-swap/config.yaml`)

| エントリ / alias | パック | 用途 | 実測 (M4 Max) |
|---|---|---|---|
| `qwen38-flash-next` (`flash-next`, `default`) | `ddalcu/Qwen3.8-Flash-Next-MLX-Serve-4bit` (105GB、experts/attention 4bit g64、lm_head 8bit) | コーディング主力・日本語チャット。opencode / dsh の既定 | short 70 tok/s、24k 後 58、prefill 694 |
| `qwen38-flash-next-uncensored` (`abliterated`) | `ARC4NUM/Qwen3.8-Flash-Next-Uncensored-MLX-Serve-4bit` (107GB、experts 4bit・attention/GDN/shared expert 8bit、orcarouter 系 abliteration) | **Hermes 既定**。拒否なし | short 56 tok/s、24k 後 48、prefill 700 |

モデルは Qwen3.8-Flash-Next (arch `qwen4_exp`): 125B MoE (512 experts top-10) + 51B n-gram 埋め込み表 + 4B MTP、
アクティブ 6B/token、ネイティブ 262K コンテキスト、QSA スパースアテンション (2k 超は上位 512 ブロックのみ読む)。
両エントリとも `--ctx-size 262144`、MTP off、KV 量子化 off。thinking は mlx-serve のサーバ既定が off で切り替えフラグも無いため、llama-swap の `filters.setParams` で全リクエストに `enable_thinking: true` を注入して常時 on にしている (llama.cpp 時代と同じ挙動)。クライアントの `enable_thinking: false` は上書きされる。

### モデルを入れ替えるときに触る場所 (5 か所)

1. `dot_config/llama-swap/config.yaml` (chezmoi ソース) → `chezmoi apply ~/.config/llama-swap/config.yaml` → `launchctl kickstart -k gui/$UID/local.llama-swap`
2. `dot_hermes/private_config.yaml` の `model.default` / `context_length` / `max_tokens` → apply → `launchctl kickstart -k gui/$UID/ai.hermes.gateway` (plist は `hermes gateway install` 生成で chezmoi 管理外)
3. `dot_config/opencode/opencode.json` の `provider.local-llm.models` と `model` / `small_model`
4. `~/.dsh/settings.yaml` (chezmoi 管理外、ホットリロード) の `llm-pi-ai.providers.local.models` — `/v1/models` を見ないハードコード一覧
5. `docs/llm-benchmarks.md` — 実測記録 (未実測の数字は書かない)

エントリ名を変えずに中身 (パック・ランタイム) だけ差し替えれば 2〜4 は触らずに済む。

## 部品と配置

| 部品 | 配置 | 導入経路 | 備考 |
|---|---|---|---|
| llama-swap v252 | `/opt/homebrew/bin/llama-swap` | Brewfile (`mostlygeek/llama-swap/llama-swap`) | LaunchAgent `local.llama-swap` (`private_Library/LaunchAgents/`)、ログ `/opt/homebrew/var/log/llama-swap.log` |
| mlx-serve 26.9.1 | `~/.local/opt/mlx-serve/current/mlx-serve-macos-arm64/mlx-serve` | `run_onchange_after_install-mlx-serve.sh` (GitHub Release tarball、sha256 固定) | `lib/` 同梱、rpath は `@executable_path/lib`。Homebrew formula は使わない |
| モデルパック | `~/.mlx-serve/models/<org>/<repo>/` | `mlx-serve pull <org/repo>` または並列 curl (`docs/bench/` 参照) | `ngram_table.bin` 32GB は mmap (page cache)、safetensors 100 shard は wired |
| llama.cpp b10769 (待機) | `~/.local/opt/llama.cpp/current/` | `run_onchange_after_install-llama-cpp.sh` | GGUF は削除済み。戻すときは HF から再取得 (unsloth UD-Q3_K_XL 90GB / mradermacher i1-IQ4_XS 97.5GB) |
| tailscale serve | tailscaled の状態 (dotfiles 外) | `tailscale serve --bg --https=443 8080` | 8443 → 3080 は dsh web。リセットで消える |
| Hermes Agent | `~/.local/bin/hermes` (uv tool、Py3.12) | `run_onchange_after_install-uv-tools.sh` | gateway LaunchAgent `ai.hermes.gateway`。cron `local-llm-daily-jp` が毎日 09:00 JST に既定モデルを叩く |
| opencode / dsh | 各端末 | — | tailnet 経由で 8080 を使う |

## メモリの見取り図 (128GB)

- mlx-serve 起動時に Metal の wired limit を **110,100MB** に引き上げる。推論中はシステム全体の wired が **78〜90GB** に達し、アイドル時は 4GB 前後まで戻る。
- 重み (67〜70GB) は wired = 退避不可。上限を超えると `[METAL] Command buffer execution failed: Insufficient Memory` で**プロセスが即死**する (捕捉不能)。llama.cpp は重みが page cache だったので圧迫時に遅くなるだけだった — 安定性の許容度は下がったが、llama-swap の排他スワップの中にいる限り問題ない。
- n-gram 表 32GB は mmap で page cache 任せ。起動時に warm (約 5 秒) するので初回長文が遅くならない。
- KV: 262K で数 GB。prefix cache は既定 2GB。

**やってはいけないこと**: llama-swap の外で mlx-serve や llama-server を単独起動したまま、llama-swap 側にもリクエストを流す (二重常駐 → OOM)。
ベンチや手動検証は Hermes cron の 09:00〜09:30 を避ける。

## 運用メモ

- ロード: mlx-serve は 16〜18 秒でヘルス到達 (遅延ロード、初回リクエストで実体化)。llama-swap の `healthCheckTimeout` は HF ダウンロードを吸収するための保険。
- 確認コマンド: `curl -s 127.0.0.1:8080/running` (常駐中のモデル)、`curl -s 127.0.0.1:8080/unload` (全アンロード、GET)、`curl -s 127.0.0.1:8080/v1/models`。
- mlx-serve の `/v1/models` の id はディレクトリ名 (`Qwen3.8-Flash-Next-MLX-Serve-4bit`、org 無し)。llama-swap 側は `useModelName` で読み替える。
- mlx-serve はストリーム末尾に `timings` を返し、`/health` を持つ。tool call は Qwen の XML 形式を構造化 `tool_calls` に変換する (Hermes 要件)。
- mlx-serve の MTP (`--mtp`) は本命パックでは効果なし〜負、無検閲パックでは +4〜13%。既定 off で揃えている。
- thinking を一時的に切りたいときは config.yaml の `filters.setParams` をコメントアウトして llama-swap を kickstart する。`--reasoning-budget N` で思考トークン上限だけを絞ることもできる。
- **並列リクエスト (dsh サブエージェント等) の挙動 (2026-09-06 調査)**: mlx-serve は decode は束ねられるが、**prefill 中は他の全リクエストが 1 トークンも進まない** (77k prefill 中の短文は 127 秒待った)。1 本あたりの decode は並列数で割られる (1 本 50 / 3 本 27 / 6 本 18 tok/s)。100k 級プロンプトが 3 本並ぶと順番待ちが 300 秒を超え、mlx-serve の stall timeout (既定 300 秒) と dsh の `streamIdleTimeoutMs` (既定 300000) が同時に発火 → dsh が 5 回リトライして空転していた。対策: config.yaml の cmd に `--timeout 0` と `--prefix-cache-mem 12GB --prefix-cache-entries 64` (既定 2GB は 65k〜82k トークンで頭打ち。拡張後は 102k プロンプトの 2 回目が 172.7 秒 → 0.3 秒)、`~/.dsh/settings.yaml` に `streamIdleTimeoutMs: 1800000`。llama-swap の `concurrencyLimit` は待ち行列ではなく即拒否なので dsh には逆効果。`--prefill-chunk` を下げてもチャンク境目で decode を挟まない。
- 更新: `run_onchange_after_install-mlx-serve.sh` の version / sha256 を書き換えて apply → kickstart。旧 version は `~/.local/opt/mlx-serve/` に残る。
- 過去の経緯 (27B 世代、vllm-mlx、量子化選定、llama.cpp の Homebrew 問題) は `llm-benchmarks.md` と `llmweekly20260827.md`、および 2026-09-05 以前の `config.yaml` (jj 履歴) を参照。
