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
| `qwen38-flash-next-uncensored` (`abliterated`) | `AinsleyMarkov/Qwen3.8-Flash-Next-Uncensored-MLX-Serve-iQ-MLX-4.7bpw` (107GB、experts/embed 4bit・他 8bit + imatrix、orcarouter 系 abliteration。2026-11-08 に ARC4NUM mixed 4/8bit から差し替え) | **Hermes 既定**。拒否なし | short 71〜75 tok/s、24k 後 66〜68、prefill 700 (26.11.2・MTP on、2026-11-08) |

モデルは Qwen3.8-Flash-Next (arch `qwen4_exp`): 125B MoE (512 experts top-10) + 51B n-gram 埋め込み表 + 4B MTP、
アクティブ 6B/token、ネイティブ 262K コンテキスト、QSA スパースアテンション (2k 超は上位 512 ブロックのみ読む)。
両エントリとも `--ctx-size 262144`、MTP は mlx-serve 既定 (26.10.1 から on)、KV 量子化 off。thinking は mlx-serve のサーバ既定が off で切り替えフラグも無いため、llama-swap の `filters.setParams` で `enable_thinking?: true` (v255 の set-if-undefined、キー末尾 `?`) を注入し、クライアントが指定しないときだけ on にしている (llama.cpp 時代と同じ挙動)。クライアントの `enable_thinking: false` は尊重される。2026-09-05〜09-11 は `?` 無しの hard 上書きだった。

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
| llama-swap v270 | `/opt/homebrew/bin/llama-swap` | Brewfile (`mostlygeek/llama-swap/llama-swap`) | LaunchAgent `local.llama-swap` (`private_Library/LaunchAgents/`)、ログ `/opt/homebrew/var/log/llama-swap.log` |
| mlx-serve 26.11.2 | `~/.local/opt/mlx-serve/current/mlx-serve-macos-arm64/mlx-serve` | `run_onchange_after_install-mlx-serve.sh` (GitHub Release tarball、sha256 固定) | `lib/` 同梱、rpath は `@executable_path/lib`。Homebrew formula は使わない |
| モデルパック | `~/.mlx-serve/models/<org>/<repo>/` | `mlx-serve pull <org/repo>` または並列 curl (`docs/bench/` 参照) | `ngram_table.bin` 32GB は mmap (page cache)、safetensors 100 shard は wired。**NAS バックアップ**: `smb://192.168.0.214/personal_folder/localllm/mlx-serve/models/<org>/<repo>/` (2026-09-17、各パックに `SHA256SUMS` 併置、`releases/` に mlx-serve tarball)。`ddalcu/…-MLX-Serve-4bit` は 2026-09-17 時点で HF から消滅しており (ddalcu org には `mixed-4-8bit` と `iQ-MLX-3.3bpw` のみ)、**NAS が唯一の再取得元** |
| llama.cpp b10769 (待機) | `~/.local/opt/llama.cpp/current/` | `run_onchange_after_install-llama-cpp.sh` | GGUF は削除済み。戻すときは HF から再取得 (unsloth UD-Q3_K_XL 90GB / mradermacher i1-IQ4_XS 97.5GB) |
| tailscale serve | tailscaled の状態 (dotfiles 外) | `tailscale serve --bg --https=443 8080` | 8443 → 3080 は dsh web、9119 → 9119 は Hermes dashboard (`tailscale serve --bg --https=9119 http://127.0.0.1:9119`)。リセットで消える |
| Hermes Agent v0.23 | `~/.hermes/hermes-agent/` (git checkout、stable channel、PM 管理の Python 3.14) + `~/.local/bin/hermes` wrapper | `run_onchange_after_install-hermes.sh` (初回のみ install.sh、更新は `hermes update`。PyPI 版は 0.19.0 で停止) | gateway LaunchAgent `ai.hermes.gateway`、dashboard LaunchAgent `local.hermes-dashboard` (127.0.0.1:9119、ID/パスワード認証、`hermes update` 後は `launchctl kickstart -k gui/$UID/local.hermes-dashboard`)。cron `local-llm-daily-jp` (毎日 09:00 JST) は 2026-11-04 から一時停止中 |
| opencode / dsh | 各端末 | — | tailnet 経由で 8080 を使う |

## メモリの見取り図 (128GB)

- mlx-serve 起動時に Metal の wired limit を **110,100MB** に引き上げる。推論中はシステム全体の wired が **78〜91GB** に達し (2026-11-08 の A/B で最大 91.1GB)、アイドル時は 4GB 前後まで戻る。
- 重み (67〜70GB) は wired = 退避不可。上限を超えると `[METAL] Command buffer execution failed: Insufficient Memory` で**プロセスが即死**する (捕捉不能)。mlx-serve 26.9.2 からは単一プロセス内の長文プロンプト起因 OOM は当該リクエストのエラーに留まりサーバは生き残るとされる (CHANGELOG、実機未確認)。二重常駐は依然として不可。26.9.3 からは Flash-Next の prefill が 8192 トークン刻みになり (メモリが許す場合)、ピークが約 +3GB 増えるとされる (CHANGELOG)。llama.cpp は重みが page cache だったので圧迫時に遅くなるだけだった — 安定性の許容度は下がったが、llama-swap の排他スワップの中にいる限り問題ない。
- n-gram 表 32GB は mmap で page cache 任せ。起動時に warm (約 5 秒) するので初回長文が遅くならない。
- KV: 262K で数 GB。prefix cache は既定 2GB。

**やってはいけないこと**: llama-swap の外で mlx-serve や llama-server を単独起動したまま、llama-swap 側にもリクエストを流す (二重常駐 → OOM)。
ベンチや手動検証は Hermes cron の 09:00〜09:30 を避ける。

## 運用メモ

- ロード: mlx-serve は 16〜18 秒でヘルス到達 (遅延ロード、初回リクエストで実体化)。llama-swap の `healthCheckTimeout` は HF ダウンロードを吸収するための保険。
- 確認コマンド: `curl -s 127.0.0.1:8080/running` (常駐中のモデル)、`curl -s 127.0.0.1:8080/unload` (全アンロード、GET)、`curl -s 127.0.0.1:8080/v1/models`。
- mlx-serve の `/v1/models` の id はディレクトリ名 (`Qwen3.8-Flash-Next-MLX-Serve-4bit`、org 無し)。llama-swap 側は `useModelName` で読み替える。
- mlx-serve はストリーム末尾に `timings` を返し、`/health` を持つ。tool call は Qwen の XML 形式を構造化 `tool_calls` に変換する (Hermes 要件)。
- mlx-serve の MTP は 26.10.1 から**既定 on** (MTP ヘッド同梱パックは自動ロード、`--no-mtp` で無効)。26.11.1 で cmd を変えずに更新した 2026-11-04 の簡易計測 (1024 トークン生成、thinking off) は本命 87〜93 tok/s・無検閲 89 tok/s で、26.9.1 時代の MTP off (70 / 56) を上回ったため既定 on のまま運用 (順序反転 2 周の正式ベンチは未実施)。
- **ロード前メモリチェック (preflight)**: mlx-serve は重み + 約 7GB の空きが無いと `Insufficient memory to load model` で起動を拒否し、llama-swap 側は `upstream command exited prematurely` になる。2026-11-03〜04 に Adobe Lightroom (21GB) と Docker Desktop VM (8GB) の常駐で空き判定が 45〜75GB に落ち、Hermes cron を含めて起動に失敗していた。原因は `~/.mlx-serve/logs/mlx-serve-<port>.log` の `[preflight]` 行で確認できる。大物アプリを閉じれば通る (`--skip-mem-preflight` は Metal OOM 即死のリスクがあるので付けていない)。
- 26.9.5〜26.11.1 は `reasoning_effort` を指定しない thinking リクエストが low 扱いで思考予算 2048 トークンに切られていた。**26.11.2 からは `reasoning_effort` はチャットテンプレートに渡るだけで思考を打ち切らず、上限は `--reasoning-budget` (未設定) と `max_tokens` のみ** (ログの `reasoning budget 2048: enforced in-stream` 行が消えたことで確認)。思考が長くなりすぎるようなら `--reasoning-budget N` を cmd に足す。
- thinking を一時的に切りたいときは config.yaml の `filters.setParams` をコメントアウトして llama-swap を kickstart する。`--reasoning-budget N` で思考トークン上限だけを絞ることもできる。
- **並列リクエスト (dsh サブエージェント等) の挙動 (2026-09-06 調査)**: mlx-serve は decode は束ねられるが、**prefill 中は他の全リクエストが 1 トークンも進まない** (77k prefill 中の短文は 127 秒待った)。1 本あたりの decode は並列数で割られる (1 本 50 / 3 本 27 / 6 本 18 tok/s)。100k 級プロンプトが 3 本並ぶと順番待ちが 300 秒を超え、mlx-serve の stall timeout (既定 300 秒) と dsh の `streamIdleTimeoutMs` (既定 300000) が同時に発火 → dsh が 5 回リトライして空転していた。対策: config.yaml の cmd に `--timeout 0` と `--prefix-cache-mem 12GB --prefix-cache-entries 64` (既定 2GB は 65k〜82k トークンで頭打ち。拡張後は 102k プロンプトの 2 回目が 172.7 秒 → 0.3 秒)、`~/.dsh/settings.yaml` に `streamIdleTimeoutMs: 1800000`。llama-swap の `concurrencyLimit` は待ち行列ではなく即拒否なので dsh には逆効果。`--prefill-chunk` を下げてもチャンク境目で decode を挟まない。
- **スワップ直後の preflight 競合 (2026-11-08)**: llama-swap は旧プロセスの終了を待ってから次を起動するが、旧プロセスの wired 70GB がカーネルに戻りきる前に新プロセスが空きを読むと 74〜77GB しか見えず、閾値 (重み + 約 7GB) を割って起動を拒否する (26.11.2 更新直後に本命⇄無検閲の切替で成否が揺れた。アイドル時の判定は約 99GB)。mlx-serve 自身の解放待ちは同一プロセス内のアンロードにしか効かないので、config.yaml の macro `settle` (`/bin/sh -c 'sleep 3; exec "$0" "$@"'`) を両 cmd の先頭に挟んでいる。対策後は 5 連続スワップがすべて成功し、判定は 99GB 台。
- 更新: `run_onchange_after_install-mlx-serve.sh` の version / sha256 を書き換えて apply → kickstart。旧 version は `~/.local/opt/mlx-serve/` に残る。
- 過去の経緯 (27B 世代、vllm-mlx、量子化選定、llama.cpp の Homebrew 問題) は `llm-benchmarks.md` と `llmweekly20260827.md`、および 2026-09-05 以前の `config.yaml` (jj 履歴) を参照。
