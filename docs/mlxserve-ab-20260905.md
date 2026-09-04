<!-- 検証は 2026-09-05 に本機で実施。ハーネスは docs/bench/。同日の判断で両エントリを mlx-serve に切り替えた (docs/local-llm-architecture.md)。 -->

# llama.cpp → mlx-serve 乗り換え検証 (実機 A/B) 2026-09-05

対象機: MacBook Pro M4 Max / 128GB、macOS 26.5。
比較: llama.cpp 公式バイナリ b10769 (llama-swap 経由、`-c 262144 --jinja`) vs mlx-serve v26.9.1 (MLX 0.32.2、単独起動、`--ctx-size 262144`)。
モデル: Qwen3.8-Flash-Next。llama.cpp 側は現行レジストリの GGUF 2 本、mlx-serve 側は `ddalcu/Qwen3.8-Flash-Next-MLX-Serve-4bit` (105GB、4bit affine g64、lm_head 8bit、n-gram 表 32GB は mmap)。
前日のルーチン (cse_01LvNEPxrbHUBMYQk167hqoe) は Linux コンテナで机上検証のみだったため、同条件のハーネスを本機で再実装して計測した。

## 結論

**mlx-serve への切り替えは GO (本命 `qwen38-flash-next` 側)。ただし条件付き。**

- decode は短文で **2.07 倍** (34.0 → 70.3 tok/s)、24k トークン投入後で **2.23 倍** (26.0 → 57.9 tok/s)。24k のプレフィルも **1.72 倍** (402 → 694 tok/s)。順序反転 2 周で全数値が 1% 以内に一致した。
- 品質プローブ (コード 5 題、tool_calls 4 問、NIAH、日本語) は両エンジンで同等。構造化 `tool_calls` は非ストリーム・ストリームとも返り、XML 漏れなし。
- MTP は本機では効かない。短文 +6%、24k 後は同等〜−14%。**既定は MTP off** で運用する。
- 短文の TTFT は mlx-serve の方が悪い (0.82 → 1.22 秒)。対話的な短いやり取りでは初動が 0.4 秒遅れる。
- 無検閲枠 (Hermes 既定) も同日に追試して **GO** (末尾の追試章)。`ARC4NUM/Qwen3.8-Flash-Next-Uncensored-MLX-Serve-4bit` (mixed 4/8bit) で decode 1.49 倍、prefill 1.76 倍、拒否挙動は同等。
- メモリの性格が変わる: llama.cpp は重み 56〜63GB を page cache (退避可) で持つが、mlx-serve は推論中に **wired 78〜88GB** (退避不可) まで上がる。llama-swap の排他スワップを通せば問題ないが、**llama-swap 外で別モデルを同時に立てると Metal OOM で即死する**。今回の計測中に実際に 1 回起きた (後述)。

## 速度 (各周 3 run の中央値、順序反転 2 周)

short = GC 説明の英文プロンプト、thinking on、max_tokens 256、temperature 0。
long = 実テキスト約 23.7k トークン + needle、thinking off、要約 256 トークン。
各リクエスト先頭に一意スタンプを置いて prefix/prompt cache を無効化。

| アーム | 量子化 | short decode R1 / R2 | short TTFT | long decode R1 / R2 | long prefill R1 / R2 | NIAH |
|---|---|---|---|---|---|---|
| A llama.cpp `qwen38-flash-next` (現行既定) | UD-Q3_K_XL 90GB | 34.0 / 34.1 | 0.80 s | 26.0 / 25.9 | 403 / 402 | 4/4 |
| B llama.cpp `qwen38-flash-next-uncensored` | i1-IQ4_XS 97.5GB | 37.8 / 37.7 | 0.81 s | 33.6 / 33.5 | 400 / 400 | 4/4 |
| **C mlx-serve serial (MTP off)** | MLX 4bit 105GB | **70.4 / 70.2** | 1.22 s | **58.0 / 57.9** | **694 / 695** | 4/4 |
| D mlx-serve MTP on (`enable_mtp:true`) | 同上 | 74.3 / 74.8 | 1.30 s | 49.7 / 56.8 | 695 / 696 | 4/4 |

- クライアント計測とサーバ側 timings (両エンジンがストリーム末尾に返す) は 0.5 tok/s 以内で一致。
- B の 37.7 tok/s は 09-03 の記録 (37.3) を再現しており、条件の連続性が取れている。
- A (UD-Q3_K_XL) が B (IQ4_XS) より遅いのは既知の傾向 (低ビット k-quant の逆量子化コスト)。**現行既定は 4 エントリ中で最も遅い**。
- long の decode 低下率: llama.cpp −24%〜−11%、mlx-serve −18%。QSA スパースアテンションで両者とも 24k で大崩れはしない。

### MTP (D) の内訳

mlx-serve のログ `[spec-stats]` より。短文 (thinking 込み) はドラフト受理 77〜100%、1 ラウンド 2.2〜3.1 トークンで +6%。
24k 要約では受理 40〜51%、1 ラウンド 0.7〜1.0 トークンで、ドラフト頭のコストだけ払って利得ゼロ (R1 −14%、R2 −2%)。
Issue #317 の M4 Max 独立実測 (実文で 1.15〜1.41 倍) より悪いのは、こちらのプロンプトが thinking 込み・要約中心で予測しにくいため。
Hermes/opencode/dsh は `enable_mtp` を送らないので、`--mtp` をサーバ側で付けなければ既定で off になる。付けない。

## 品質・機能 (thinking off)

| アーム | tools (非ストリーム 3 + ストリーム 1) | XML 漏れ | code 5 題 | 日本語 (漢字かな比率 / ループ / U+FFFD) |
|---|---|---|---|---|
| A llama.cpp Q3_K_XL | 4/4, 4/4 | 0 | 5/5, 5/5 | 0.86, 0.85 / なし / 0 |
| B llama.cpp IQ4_XS | 3/4, 4/4 | 0 | 5/5, 5/5 | 0.91, 0.86 / なし / 0 |
| C mlx-serve serial | 3/4, 4/4 | 0 | 5/5, 5/5 | 0.84, 0.80 / なし / 0 |
| D mlx-serve MTP | 4/4, 4/4 | 0 | 5/5, 5/5 | 0.82, 0.87 / なし / 0 |

- tools の 3/4 は B・C とも同じ問題 (`read_file` の代わりに `run_command` で `head -n 40` を選択)。呼び出し形式は正しく、ツール選択の揺れであり、エンジン差ではない。
- mlx-serve の `/v1/models` は `tool_use` / `reasoning` / `json_schema` / `vision` を capabilities として返す。
- mlx-serve は **thinking を既定 off** にする (llama.cpp は template 既定で on)。上記 short 速度は両方 on を明示して揃えた。切り替え適用時 (同日) に llama-swap の `filters.setParams` で `enable_thinking: true` を全リクエストに注入し、llama.cpp 時代と同じ常時 on にした。
- 品質プローブは小規模 (KLD や本格ベンチではない)。MLX 4bit affine g64 と UD-Q3_K_XL の厳密な品質比較は未実施。ビット幅では MLX 4bit の方が上。

## メモリと安定性

`footprint` (ウォームアップ直後) と 5 秒間隔サンプラー (mlx-serve 区間) より。

| | llama.cpp (A/B) | mlx-serve (C/D) |
|---|---|---|
| dirty (wired) | 10 GB | 67〜70 GB |
| mapped file (clean、退避可) | 56〜63 GB | 0.1〜9 GB (n-gram 表は page cache) |
| 推論中のシステム wired 合計 | — | **78〜88 GB** (アイドル時は 4 GB まで戻る) |
| Metal wired limit | macOS 既定 | mlx-serve が起動時に **110,100 MB** に引き上げ |
| ロード〜応答可能 | 53〜57 秒 (冷) | 16〜18 秒 (遅延ロード、初回要求で実体化) |

**実際に起きた OOM**: 09:00 に Hermes の cron `local-llm-daily-jp` が llama-swap 経由で `qwen38-flash-next-uncensored` (GPU 常駐 64GB) を起こし、単独起動していた mlx-serve (68GB) と二重常駐になって
`[METAL] Command buffer execution failed: Insufficient Memory` でプロセスが落ちた。llama-swap の排他スワップの中に mlx-serve を入れれば起きない構図だが、次の含意がある。

- mlx-serve は **必ず llama-swap のエントリとして** 起動し、手動起動や別ポート常駐をしない。
- 計測や手動検証で mlx-serve を単独起動するときは Hermes cron (毎日 09:00) と重ねない。
- llama.cpp 側は同じ状況でも落ちない (重みが退避されて遅くなるだけ)。安定性の許容度は llama.cpp が高い。

## 推奨アクション

1. **本命を mlx-serve に切り替える**。エントリ名 `qwen38-flash-next` を維持して cmd だけ差し替え、旧 GGUF エントリは `qwen38-flash-next-gguf` として残す。名前を維持すれば消費側 4 つ (Hermes / opencode / dsh / docs) の変更は不要。
2. `--mtp` は付けない (実測で利得なし)。`--kv-quant` も既定 off のまま。
3. 無検閲枠も `ARC4NUM/Qwen3.8-Flash-Next-Uncensored-MLX-Serve-4bit` に切り替え可 (追試で GO)。エントリ名を維持すれば Hermes の設定変更は不要、gateway の kickstart のみ。
4. mlx-serve バイナリを chezmoi 管理に載せる (`run_onchange_after_install-mlx-serve.sh`、llama.cpp と同じ方式で `~/.local/opt/mlx-serve/current`)。今回は scratchpad 内に展開しただけで、`~/.local/opt` には未配置。
5. `docs/llm-benchmarks.md` に本表を追記。

### llama-swap 追記案

```yaml
macros:
  mlx_serve: /Users/joe/.local/opt/mlx-serve/current/mlx-serve-macos-arm64/mlx-serve

models:
  # 本命 (2026-09-05 実測: short 70.3 / 24k 後 57.9 tok/s、prefill 694 tok/s、MTP off)
  qwen38-flash-next:
    cmd: |
      ${mlx_serve}
      --model /Users/joe/.mlx-serve/models/ddalcu/Qwen3.8-Flash-Next-MLX-Serve-4bit
      --serve --host 127.0.0.1 --port ${PORT}
      --ctx-size 262144
    # mlx-serve の /v1/models はディレクトリ名を id にする (org/ は付かない)
    useModelName: Qwen3.8-Flash-Next-MLX-Serve-4bit
    checkEndpoint: /health
    ttl: 7200
    aliases:
      - flash-next
      - default

  # 旧本命 (フォールバック)
  qwen38-flash-next-gguf:
    cmd: |
      ${llama_server}
      --port ${PORT}
      -hfr unsloth/Qwen3.8-Flash-Next-GGUF
      -hff UD-Q3_K_XL/Qwen3.8-Flash-Next-UD-Q3_K_XL-00001-of-00003.gguf
      --jinja
      -c 262144
    ttl: 7200
```

## 今回の作業で残しているもの

- `~/.mlx-serve/models/` に ddalcu (base 4bit 105GB) と ARC4NUM (uncensored mixed 4/8bit 107GB) の 2 パック (全ファイルを HF のサイズと照合済み)
- mlx-serve v26.9.1 バイナリは `run_onchange_after_install-mlx-serve.sh` で `~/.local/opt/mlx-serve/current` に配置 (切り替え適用時)。同日のディスク整理で 27B 世代と RVN は撤去済み (末尾参照)。
- ハーネス `bench_ab.py` / ドライバ `run_ab.sh` `run_unc.sh` / 集計 `summarize.py` / メモリサンプラー `memsample.sh` は `docs/bench/` に保存。集計表は `docs/bench/summary-20260905.md`。生データ (results/*.json) はリポジトリ外。
- 汚染データ (Hermes cron と重なった B 2 周目、OOM で途切れた D 2 周目) は `results/contaminated/` に隔離し、集計から除外。

## 出典

- mlx-serve v26.9.1 Release (2026-09-03) / CHANGELOG / docs/cli.md — https://github.com/ddalcu/mlx-serve
- ddalcu/Qwen3.8-Flash-Next-MLX-Serve-4bit README (量子化幅、n-gram 表の mmap 方式)
- Issue #317 (M4 Max 128GB 独立実測: no-spec 47〜51、MTP 55〜72 tok/s、2.00 倍の主張は撤回)
- Issue #353 (Metal OOM は捕捉不能でプロセスが落ちる)
- ARC4NUM/Qwen3.8-Flash-Next-Uncensored-MLX-Serve-4bit (orcarouter 系、非 gated、107GB)

---

# 追試: 無検閲枠 (Hermes 既定) 2026-09-05 12:10〜12:55

対象: `ARC4NUM/Qwen3.8-Flash-Next-Uncensored-MLX-Serve-4bit` (orcarouter 系 abliteration、107GB、非 gated)。
**構成は本命パックと異なり mixed 4/8bit** — routed experts 4bit g64、attention・shared expert・GDN は 8bit g64、n-gram 表 4bit g32 (README の幅表で確認。config.json の `bits: 4` は experts の値)。
比較相手: 現行 Hermes 既定の llama.cpp `qwen38-flash-next-uncensored` (mradermacher i1-IQ4_XS 97.5GB)。
順序反転 2 周 (B E F / F E B)、条件は本命 A/B と同一。Hermes cron の時間帯は避けた。

## 結果

| アーム | short decode | short TTFT | 24k 後 decode | 24k prefill | NIAH | tools | code | 日本語 | 拒否プローブ |
|---|---|---|---|---|---|---|---|---|---|
| B llama.cpp IQ4_XS (R3 / R4) | 37.7 / 37.7 | 0.81 s | 33.5 / 32.7 | 400 / 396 | 4/4 | 3/4, 3/4 | 5/5, 5/5 | 正常 | 0/3 拒否 |
| **E mlx-serve serial (R1 / R2)** | **56.2 / 56.0** | 1.0〜1.4 s | **48.0 / 47.8** | **697 / 705** | 4/4 | 4/4, 4/4 | 5/5, 5/5 | 正常 | 0/3 拒否 |
| F mlx-serve MTP (R1 / R2) | 63.5 / 60.4 | 1.2〜1.3 s | 50.4 / 49.5 | 695 / 694 | 4/4 | 4/4, 4/4 | 5/5, 5/5 | 正常 | 0/3 拒否 |

- decode は短文 **1.49 倍**、24k 後 **1.44 倍**、24k プレフィル **1.76 倍**。本命パック (2.1 倍) より伸びが小さいのは、非 expert 部が 8bit で重いため (ddalcu の mixed-4-8bit パックも同じ 107.3GB 構成)。
- **MTP はこのパックでは小さく正の効果** (短文 +8〜13%、24k 後 +4%)。受理率 83〜100%、1 ラウンド 1.9〜4.2 トークン。本命 4bit パックでは負だったので、パック依存。Hermes 用途 (ツール呼び出しの echo が多い) なら `--mtp` を付ける価値はあるが、差が 1 割程度なので既定 off のまま揃えても損は小さい。
- 拒否プローブ 3 問 (フィッシング教材 / 小説の悪役独白 / 看護師向け過量服薬情報) は llama.cpp 版・mlx-serve 版とも全問回答。量子化で abliteration が失われていない。
- tools の 3/4 (llama.cpp 側) は本命側と同じ `read_file` → `run_command` の選択揺れ。mlx-serve 側は 2 周とも 4/4。
- メモリ: 推論中の wired ピーク 89.5〜90.4GB (本命パックより +2GB)。llama-swap の排他スワップ内で運用すること。

## 無検閲枠の判定

**GO。** 1.5 倍の decode、1.8 倍のプレフィル、品質・拒否挙動は同等。切り替えは本命と同じ手順 (エントリ名 `qwen38-flash-next-uncensored` を維持して cmd を差し替え、旧 GGUF は `-gguf` 名で残す)。Hermes 側は `~/.hermes/config.yaml` の `model.default` が名前で指すため変更不要だが、gateway の kickstart は要る (context_length 262144 は同じ)。
mlx-serve は thinking 既定 off なので、Hermes の応答が「考えずに即答」に変わる点だけ意識する (必要なら Hermes 側で `enable_thinking: true` を送る設定を探す)。

```yaml
  qwen38-flash-next-uncensored:
    cmd: |
      ${mlx_serve}
      --model /Users/joe/.mlx-serve/models/ARC4NUM/Qwen3.8-Flash-Next-Uncensored-MLX-Serve-4bit
      --serve --host 127.0.0.1 --port ${PORT}
      --ctx-size 262144
    useModelName: Qwen3.8-Flash-Next-Uncensored-MLX-Serve-4bit
    checkEndpoint: /health
    ttl: 7200
    aliases:
      - abliterated
```

## 同日のディスク整理

ユーザー確認の上で 27B 世代 4 本 (`qwen38-27b` / `qwen38-27b-mlx` / `qwen38-abliterated` / `qwen38-27b-fast`) と比較枠 `qwen38-flash-next-rvn` をレジストリ・opencode.json (small_model は `qwen38-flash-next` に置換)・dsh settings.yaml・ディスクから撤去。191GiB 解放、空き 266GiB。llama-swap は 2 モデル構成 (`qwen38-flash-next` / `qwen38-flash-next-uncensored`) で再起動済み。
