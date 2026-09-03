# LLM週次調査 2026-08-27 (rev.2 / 訂正版)

> **rev.2 訂正 (2026-08-30)**: 初版で **Qwen3.8-Flash-Next (8/26公開) を完全に取りこぼしていました**。
> 初版の結論「96GB枠でQwen3.8-27Bを上回る候補は今週出ていない」は**誤りです**。
> GLM-5.3-Flash と同日公開でありながら、当機にとってはFlash-Nextの方が本命でした。
> TL;DR・新モデル表・ランタイム・無検閲枠・推奨アクションの全節を書き換えています。
>
> ⚠️ 本来 joe-yama/dotfiles に Issue として起票する予定でしたが、このセッションのGitHubトークンに
> Issue書き込み権限がなく (403 Resource not accessible by integration) 起票できませんでした。
> ラベル「LLM週次調査」も未作成のため、手動起票時に併せて作成してください。

調査期間: **2026-08-20 〜 2026-08-27** / 対象機: MacBook Pro M4 Max (40c GPU, 128GB UMA, 実用GPUメモリ上限 約96GB, メモリ帯域 546GB/s)

---

## (a) TL;DR

### 🟡 乗り換え推奨: **条件付きであり。ただし即時の既定差し替えはせず、併載して実測してください。**

今週は当機にとって**当たり週**でした。8/26 に2本のフロンティア級が同時公開され、明暗が分かれています。

**◎ 本命 — Qwen3.8-Flash-Next (Alibaba Qwen, 8/26)**
125B MoE + 51B N-gram埋め込み表(PLE) / アクティブ **6B/token** / ネイティブマルチモーダル / 262K native (YaRNで1M)。**51BのPLE表をGPUメモリではなくホストRAM・SSDに逃がせる**設計のため、96GBのMetal割当上限を持つ当機でも動きます。**llama.cpp 本体に 8/27 マージ済み (PR #27742)**、同型機 (M4 Max 128GB) での実測報告も複数あります。品質は27Bに対し明確に上で、**DeepSWE 1.1 が 58.7 vs 42.2 と大差**。

**✕ 対象外 — GLM-5.3-Flash (Z.ai, 8/26)**
320B-A18B。話題性は最大ですが **96GBに物理的に載りません**(1bitで約223GB、実用下限の2bitで約239〜245GB)。追跡指定のあった llama.cpp PR #27773 / #27754 / #27752 は3本ともDraftのままですが、**マージされても当機では動きません**。週次追跡の打ち切りを提案します。

### Flash-Next を「即時差し替え」にしない3つの理由

1. **MTPがまだ来ていない。** 現行の21.0 tok/s はMTP投機デコード前提ですが、Flash-Next の NextN/MTPドラフトヘッド (`--spec-type draft-mtp`) は **PR #27836 がDraft**(8/27)。llama.cpp側では当面MTPなしの素の速度になります。
2. **ロード時間が運用を壊す。** 84GBの読み込みに**3分以上**という報告があり、llama-swap のオンデマンド切替と相性が最悪です。90GB + 現行27B 29GB は同時常駐できないため、**事実上どちらか一方の常駐**になります。
3. **ライセンスが後退。** Apache 2.0 → **Qwen Community License 1.0**。

### その他の差分

- **llama-swap v251 (8/23) へのアップデート推奨** — vLLM系の投機デコードメトリクスのパースが入りました。
- **無検閲枠にも波及** — `orcarouter/Qwen3.8-Flash-Next-Uncensored-GGUF` / `-MLX` が既に存在。現行の無検閲枠と同一ベンダーです。
- Hermes 4.4 は存在せず、無検閲ニュートラル枠 (Hermes 4.3-36B) は現状維持で問題ありません。

### ⚠️ 前提の齟齬(要対応)

**`dot_config/llama-swap/config.yaml` がこのリポジトリに存在しません。** 全ブランチ・全履歴を確認しましたが (`git log --all -- '*llama-swap*'` が空)、一度もコミットされていません。モデルレジストリが chezmoi 管理外(ローカルのみ)になっており、この週次調査は**現在の実構成を読めないまま**実施しています。下記(e)-5 で対応を提案します。

---

## (b) 新モデル表 (2026-08-20 〜 08-27)

| モデル | 公開日 | 規模 | ライセンス | 96GB可否 | コーディング/エージェント | 日本語 | 判定 |
|---|---|---|---|---|---|---|---|
| **Qwen3.8-Flash-Next** (Alibaba Qwen) | **8/26** | **125B MoE + 51B N-gram(PLE) / アクティブ 6B** / ネイティブマルチモーダル / 262K native・1M (YaRN) | ⚠️ Qwen Community License 1.0 | ✅ **可** (UD-Q3_K_XL 90GB + PLEをCPUへ退避) | **SWE-bench Pro 62.5 / DeepSWE 1.1 58.7 / LiveCodeBench v6 91.9 / Toolathlon Verified 73.5** | SWE-bench Multilingual 81.0 | ⭐ **本命候補**。要実測 |
| **GLM-5.3-Flash** (Z.ai) | 8/26 | 320B-A18B MoE / ネイティブマルチモーダル / 1M ctx | MIT | ❌ **不可** (1bit≈223GB, 2bit≈239-245GB) | フロンティア級 (GLM-5.3系 TB2.1 88.2) | 良好とされる | **対象外** — 256GB級が必要 |
| **LLM-jp-4 33B** (NII/LLMC) | 8/18 | 33B Dense (base / thinking の2種) | Apache 2.0 | ✅ Q5_K_M≈23GB, Q8≈35GB | コーディング特化ではない | **国産・日本語ネイティブ** | 日本語評価枠として候補 |
| MiniMax Text-01 / M1 | llama.cpp対応が 8/27 マージ (#27018) | 456B級 | — | ❌ | — | — | アーキ対応のみ。モデルは規模的に対象外 |
| Nanbeige4.2-3B (dspark) | llama.cpp対応が 8/27 マージ (#27730) | 3B | — | ✅ | 小規模すぎ | — | 対象外 |

### Qwen3.8-Flash-Next vs 現行既定 Qwen3.8-27B

| ベンチ | Flash-Next | Qwen3.8-27B | 差 |
|---|---|---|---|
| **DeepSWE 1.1** | **58.7** | 42.2 | **+16.5** ← 最大の差 |
| SWE-bench Pro | **62.5** (Opus 4.6 Max 53.4 超) | 61.7 | +0.8(ほぼ拮抗) |
| SWE-bench Multilingual | **81.0** | 77.5 | +3.5 |
| LiveCodeBench v6 | 91.9 | — | — |
| CoWorkBench / JobBench / Toolathlon Verified | 73.9 / 55.7 / 73.5 | — | — |
| Terminal-Bench 2.1 | DeepSeek V4 Flash が上位 | 73.0 | ⚠️ ここは非優位 |

llm-stats の集計では **18ベンチで Flash-Next 勝ち・27B 勝ちゼロ**。ただし SWE-bench Pro はほぼ拮抗で、**Terminal-Bench 2.1 は Flash-Next の弱点**です。

### 期間直前だが評価対象に含めたもの

| モデル | 公開日 | 規模 | ライセンス | 96GB可否 | 備考 |
|---|---|---|---|---|---|
| Muse Glimmer 30B (Meta) | 8/10 | 29.6B Dense (内 1.8B 視覚エンコーダ) / 131K ctx / マルチモーダル | Apache 2.0 | ✅ 4bit≈17-20GB | TB2.1 51.7・SWE-bench Verified 76.0 で **Qwen3.6 に劣後** (60.7 / 77.2)。**Flash-Next がネイティブマルチモーダルのため、視覚枠としての存在意義も薄れました** |
| Unsloth Dynamic v3.0 GGUF (Qwen3.8-27B) | 8/20 | 量子化リリース | — | ✅ | 1bitは品質崩壊、4bit以上は品質維持との第三者検証あり |

> ⚠️ **但し書き**: Qwen3.8-Flash-Next / Qwen3.8-27B の公表スコアは**いずれも Qwen 自社公表値**で、独立再現検証は未確認です。Terminal-Bench / SWE-bench の比較値もベンダーハーネスとリーダーボードハーネスが混在しており、**方向性の比較に留めるべき**です。

---

## (c) ランタイム対応状況

### ⭐ llama.cpp — Qwen3.8-Flash-Next: **本体にマージ済み**

| PR | 内容 | 状態 |
|---|---|---|
| **#27742** (danielhanchen / Unsloth) | `model: add Qwen3.8-Flash-Next (qwen4exp)` | ✅ **Merged 8/27** |
| #27836 | `qwen4exp : add NextN/MTP draft head (--spec-type draft-mtp)` | ⚠️ **Draft** (8/27) |

**アーキテクチャ詳細** (PR #27742 より一次確認):
- 内部名 `LLM_ARCH_QWEN4EXP` / HuggingFace model type `qwen4_exp`
- Hyper-connections: 低ランク残差、4x ストリーム幅
- Gated Delta Net: sigmoidゲート、**4層中3層**
- MoE: **512エキスパート、top-10選択**、gated shared expert 付き
- QSA スパースアテンション: budget 2048トークン、圧縮率 4
- Interleaved Rope: 部分回転 (64/256次元)
- Vision: 既存CLIPパス経由で Qwen3-VL ViT をそのまま利用
- **PLE (Per-Layer Embeddings) N-gramハッシュ表: BF16で 97.7 GiB (約512億要素)、4bit量子化モデル全体の約46%**。行列積ではなく `ggml_get_rows` でアクセスし、**mmap経由でRAMまたはディスクにオフロード可能**

**⚠️ 落とし穴 — `qwen4exp` は `qwen3next` とは別物です。** 混同して「masterで読み込めない」と詰まる事例が記事化されるほど頻発しています。**8/27以降のmasterビルドが必須**で、それ以前のリリースはファイルを読み込み拒否します。LM Studio では動かず、対応ブランチのローカルビルドが必要だったという報告があります。

**既知の制約** (PR記載): depthwise convolution が **ubatch間で状態を持たない**ため、**位置0から始まるprefillでのみ厳密**。chunked prefill と decode には追加の状態管理が必要。

### llama.cpp — 今週マージされたその他の関連変更

- **#26647** `ggml-metal: add chunked SSD MMA for Mamba-2 prefill optimization` (8/26) — Apple Metal のprefill最適化
- **#27342** `spec : add DFlash2 support (local convolution + candidate selector)` (8/27) — 投機デコード系
- #27018 MiniMaxText01 / MiniMaxM1 対応、#27730 dspark (Nanbeige4.2-3B) 対応

### MLX 系 — mlx-lm は未マージ、mlx-vlm 経由で回避可能

| リポジトリ | qwen4_exp 対応 | 状態 |
|---|---|---|
| **mlx-lm** | PR **#1788** (eauchs) | ⚠️ **Open**。レビュー承認1件 (BrunoCerberus) 済みだがメンテナが "await verification" ラベルを付与。作者は M3 Max 128GB で検証済みと報告 |
| **mlx-vlm** | ✅ **マージ済み** | コミュニティMLXビルドはこちらを利用 |

**回避策**: コミュニティのMLXリポジトリは独自の `qwen4_exp.py` を同梱し `model_file` で宣言しているため、`trust_remote_code=True` を付ければ公式mlx-lm未対応でも動きます。

PR #1788 が解決した公式チェックポイント互換の問題(参考): RMSNorm のゼロ中心化 (`y * (1 + weight)`)、ネストしたprefixの除去、融合表現からのエキスパート重み分割、位置計算の配列オフセット対応、スパースアテンションの因果性異常(クエリが自身の部分ブロックを含むよう修正)。

**利用可能なMLX量子化**: 4bit / 6bit / 8bit / mixed 4_8bit / mixed 2bit / **oQ3-MTP (MTP付き)** / oQ4

### mlx-lm — MTPの状況(現行既定に直接関係)

**PR #990「Native MTP speculative decoding (Qwen3.5/3.6 reference implementation)」が 2026-03-13 から Open のまま**です。mlx-lm本体には依然としてネイティブMTPがありません。**現行の「速い方は llama.cpp + MTP」という構成判断は、今週時点でも正しいままです。**

### GLM-5.3-Flash 側 (参考: 当機では動かない)

llama.cpp の #27773 / #27752 / #27754 は**3本すべてDraft**で、しかも同一機能の並行実装3本。#27754 はPRテンプレート違反・同時PR上限超過・24コミットの巨大変更・`NVIDIA_TF32_OVERRIDE=0` と `-fa off` が必要、等5点でブロック。mlx-lm には **glm5_next 相当のファイルもPRも存在しません**(`mlx_lm/models/` を一次確認: `glm.py` / `glm4.py` / `glm4_moe.py` / `glm4_moe_lite.py` / `glm_moe_dsa.py` のみ)。

### vllm-mlx v0.4.1 (8/12) — MTP周りが着実に成熟

Qwen pre-norm MTP hidden states (#660) / Standard Qwen MTP shard prefixes (#664) / Native MTP status counters (#656) / Sampled concurrent MLLM MTP decoding (#662) / Native mlx-lm chunked prefill (#648) / Mistral `[ARGS]` tool-call parsing (#631) / Registry and Metal memory budget reconciliation (#696) / Streaming finish-reason preservation (#681, #629)。

### llama-swap v251 (8/23) — **アップデート推奨**

**vLLM投機デコードメトリクスのパース**(MTP運用の可視化に直結)、クライアント切断の正しい記録、バッファ警告のレート制限、OpenAI互換レスポンスのエラーハンドリング改善、ログのANSIカラー表示。v250 (8/14) では Models ページに capability タグ、`/v1/task/run`、統合Dockerに llama-bench 同梱。

---

## (d) 無検閲枠

### Hermes系: **変更なし。Hermes 4.3 が引き続き最新**

**Hermes 4.4 は存在しません。** Nous Research が8月に出したのは **Hermes Agent**(エージェント製品であってモデルではない)の v0.20.0「The Herald Release」(8/3) と v0.20.5。**→ 無検閲ニュートラル枠の Hermes 4.3-36B MLX 8bit は現状維持で問題ありません。**

### abliterated枠: **Flash-Next の無検閲版が既に登場**

| ビルド | 日付 | 形式 |
|---|---|---|
| **orcarouter/Qwen3.8-Flash-Next-Uncensored-GGUF** | 8/末 | GGUF ← **現行無検閲枠と同一ベンダー** |
| **orcarouter/Qwen3.8-Flash-Next-Uncensored-MLX** | 8/末 | MLX |
| Qwen3.8-27B-Uncensored-FP8 | 8/15 | block-FP8 |
| OrcaRouter Qwen3.8-27B Uncensored | 8/17 | MLX 4精度 |
| Pliny the Liberator 版 (27B) | 8/20 | abliterated |

**品質劣化の評判**: Qwen3.8-27B の abliterated ビルドは**ベースモデル比 ±1.3ポイント以内**に収まっており、abliteration としては異例に良好です。

⚠️ **ただし Flash-Next は MoE です。** MoEへの abliteration は依然として危険で、Qwen3-30B-A3B の abliterated 版が非abliteratedの4〜8Bモデルにすら負けた例が報告されています(abliteration後のDPOで概ね回復するが、GSM8K等の数学は戻りにくい)。**Flash-Next-Uncensored は現行27B無検閲枠の置き換え候補になりますが、MoE劣化リスクがあるため品質の実測が27B以上に重要です。**

### 新顔の空白

GLM-5.3-Flash および Muse Glimmer の abliterated / uncensored 版は、今週時点で確認できませんでした。

---

## (e) 推奨アクション

### 1. ⭐【最優先・検証】Qwen3.8-Flash-Next を**併載**して実測

**既定の差し替えではなく、別エントリでの追加**です。品質は明確に上ですが、速度・ロード時間・ライセンスでトレードオフがあります。

**Unsloth GGUF の量子化とサイズ:**

| 量子化 | サイズ | 品質(top-token一致) | 当機での評価 |
|---|---|---|---|
| UD-Q4_K_XL | 111.3GB | 約93% | ⚠️ PLE退避前提でギリギリ |
| UD-IQ4_XS | 93.7GB | 90%超 | ⚠️ 96GB上限に極めて近い |
| **UD-Q3_K_XL** | **90GB** | 90%超 | ✅ **推奨開始点** |
| UD-IQ1_S | 72.5GB | 80% | 品質妥協が大きい |

262Kのフルコンテキストでも **KVキャッシュは約6.5GB** しか食いません(QSAスパースアテンションのおかげ)。

```yaml
  "qwen3.8-flash-next":
    # 要: 2026-08-27 以降の llama.cpp master ビルド (arch: qwen4exp)
    # ⚠️ qwen4exp は qwen3next とは別物。古いビルドはファイルを読み込み拒否する
    # UD-Q3_K_XL ≈ 90GB。51BのPLE表をCPU側へ退避しMetal割当(96GB上限)を圧縮する
    # 想定 tok/s: 短文脈 20-30 / 28k文脈 約15.8 (同型機実測・下記注記参照)
    cmd: |
      ${LLAMA_BIN}/llama-server
      --model ${MODELS_DIR}/Qwen3.8-Flash-Next-UD-Q3_K_XL-00001-of-00003.gguf
      --host 127.0.0.1
      --port ${PORT}
      --ctx-size 262144
      --n-gpu-layers 999
      --override-tensor "per_layer_token_embd=CPU,ple_ngram_embd=CPU"
      --jinja
    # ⚠️ ロードに3分以上かかるため TTL は長めに。頻繁な swap は非現実的
    ttl: 7200
    aliases: ["flash-next"]
```

**実測報告(測定条件がバラバラなため要注意):**

| 環境 | 量子化 | 結果 |
|---|---|---|
| **M4 Max 128GB / llama.cpp** | UD-Q3_K_XL (~90GB) | **28,013トークン時点で decode 15.8 tok/s** |
| M5 Max 128GB / llama.cpp | UD-IQ4_XS / 262K ctx | 新規コンテキスト **33 tok/s**、25万トークン時 **11 tok/s**(オフロード技なし) |
| M4 Max / mlx-serve | — | prefill 約730 tok/s(別計測では25kプロンプトに約400 tok/s) |
| M4 Max / 実効スループット | — | プロンプト処理込み 9.1〜9.8 tok/s、短文テストでは 29 tok/s |
| DGX Spark | UD-Q4_K_XL (PLEをディスクからストリーム) | 約25 tok/s、最大1M context |

> **現行21.0 tok/sとの単純比較はできません。** 15.8は28k消化後の値で、27B側も同じ文脈長なら落ちます。**短文脈では上回り、長文脈で逆転する**というのが妥当な読みです。**同一条件での実測が必須です。**

**検証手順の提案:**
1. llama.cpp を master (8/27以降) からローカルビルド
2. UD-Q3_K_XL を取得、上記フラグで起動しロード時間を計測
3. `llama-bench` で **文脈長別** (0 / 8k / 32k / 128k) の decode tok/s を現行27B Q8+MTP と**同一条件で**比較
4. 日本語チャット品質とツールコーリング(`--tool-call-parser qwen3_xml` 相当)の実タスク評価
5. MTP (PR #27836) のマージ後に再測定 — ここで速度評価が変わる可能性が高い

### 2.【推奨】llama-swap を v251 に更新

投機デコードメトリクスのパースが入ったため、MTP運用の実測が取りやすくなります。上記の検証精度も上がります。

### 3.【要検討】llama-swap のグループ/TTL設計の見直し

Flash-Next (90GB) と現行27B (29GB) は**同時常駐できません**。かつ Flash-Next はロードに3分以上かかります。オンデマンド swap 前提の現構成のままでは体験が破綻するため、**「常駐する重量級1本 + 軽量モデル」という構成に組み替えるか、Flash-Next を明示起動の専用プロファイルに分離する**ことを検討してください。

### 4.【任意】日本語ネイティブ評価枠として LLM-jp-4 33B thinking

```yaml
  "llm-jp-4-33b-thinking":
    # 日本語評価用。想定メモリ: 約23GB (Q5_K_M) / 期待 tok/s: 16-19 (推定・未実測)
    cmd: |
      ${LLAMA_BIN}/llama-server
      --model ${MODELS_DIR}/llm-jp-4-33b-thinking-Q5_K_M.gguf
      --host 127.0.0.1
      --port ${PORT}
      --ctx-size 32768
      --n-gpu-layers 999
      --flash-attn
      --jinja
    ttl: 600
    aliases: ["ja", "japanese"]
```

### 5.【要対応】`llama-swap/config.yaml` を chezmoi 管理下に置く

モデルレジストリがこのリポジトリに一度もコミットされていません。週次調査が実構成を参照できないほか、マシン移行時に手作業復元が必要になります。

```
chezmoi add ~/.config/llama-swap/config.yaml
```

> ※ CLAUDE.md の方針に従い、本調査ではリポジトリのファイルを一切変更していません。実行はご判断ください。

### 6.【取り下げ】Muse Glimmer の視覚枠併載(初版の提案)

**Flash-Next がネイティブマルチモーダルのため、視覚枠としての存在意義が薄れました。** Flash-Next の検証結果が出るまで保留を推奨します。

### 7.【追跡打ち切り提案】GLM-5.3-Flash 関連PR

モデル自体が96GBに載らないため、PR #27773 / #27754 / #27752 の週次追跡は費用対効果がありません。**「GLM-5.3-Flash-Air 等の小型派生が出たら再開」という条件付き監視**に切り替えることを提案します。

### 8.【監視対象】llama.cpp PR #27836 (Flash-Next の MTP)

現行既定の21.0 tok/s はMTP前提です。**Flash-Next のMTPが落ちた時点で速度評価が変わる可能性が高く**、次回以降の最優先追跡項目とします。

---

## (f) 出典リンク

### 一次ソース (GitHub — 直接確認済)
- [llama.cpp PR #27742 — model: add Qwen3.8-Flash-Next (qwen4exp) **(Merged 8/27)**](https://github.com/ggml-org/llama.cpp/pull/27742)
- [llama.cpp PR #27836 — qwen4exp: add NextN/MTP draft head (Draft)](https://github.com/ggml-org/llama.cpp/pull/27836)
- [mlx-lm PR #1788 — Add Qwen3.8-Flash-Next (qwen4_exp) model support (Open)](https://github.com/ml-explore/mlx-lm/pull/1788)
- [llama.cpp PR #27773 — add GLM-5.3-Flash (GLM5-Next) support (Draft)](https://github.com/ggml-org/llama.cpp/pull/27773)
- [llama.cpp PR #27752 — model : add GLM-5.3-Flash (glm5next) (Draft)](https://github.com/ggml-org/llama.cpp/pull/27752)
- [llama.cpp PR #27754 — model: add GLM-5-Next (GLM-5.3-Flash) (Draft)](https://github.com/ggml-org/llama.cpp/pull/27754)
- [llama.cpp 最近マージされたPR一覧](https://github.com/ggml-org/llama.cpp/pulls?q=is%3Apr+is%3Amerged+sort%3Aupdated-desc)
- [mlx-lm `mlx_lm/models/` ファイル一覧 (glm5_next 不在の確認)](https://github.com/ml-explore/mlx-lm/tree/main/mlx_lm/models)
- [mlx-lm Issue #879 — GLM-5 (glm_moe_dsa) 対応 (Closed)](https://github.com/ml-explore/mlx-lm/issues/879)
- [mlx-lm リリース一覧](https://github.com/ml-explore/mlx-lm/releases)
- [vllm-mlx v0.4.1 リリースノート](https://github.com/waybarrios/vllm-mlx/releases/tag/v0.4.1)
- [llama-swap リリース一覧 (v251)](https://github.com/mostlygeek/llama-swap/releases)

### Qwen3.8-Flash-Next 関連(二次)
- [MacBook Pro 128GB でローカル LLM がついに実用になった ─ Qwen3.8 Flash Next 実測 — Zenn (jtechjapan)](https://zenn.dev/jtechjapan_pub/articles/local-llm-qwen-flash-next-eval)
- [Alibaba's Qwen Team Releases Qwen3.8-Flash-Next: A 125B Multimodal MoE With 6B Active Parameters — MarkTechPost](https://www.marktechpost.com/2026/08/26/alibabas-qwen-team-releases-qwen3-8-flash-next-a-125b-multimodal-moe-with-6b-active-parameters-previewing-the-qwen4-architecture/)
- [Qwen/Qwen3.8-Flash-Next — Hugging Face (公式モデルカード)](https://huggingface.co/Qwen/Qwen3.8-Flash-Next)
- [unsloth/Qwen3.8-Flash-Next-GGUF — Hugging Face](https://huggingface.co/unsloth/Qwen3.8-Flash-Next-GGUF)
- [Qwen3.8-Flash-Next: How to Run Locally — Unsloth Documentation](https://unsloth.ai/docs/models/qwen3.8-next)
- [Running Qwen3.8-Flash-Next at Full 262K Context on a 128GB MacBook — heretik.io](https://heretik.io/qwen38-flash-next-262k-macbook/)
- [qwen4exp is not qwen3next: llama.cpp master cannot load Qwen3.8-Flash-Next — Michael Hospedales](https://www.hospedales.com/notes/qwen4exp-qwen3-8-flash-next-llama-cpp-master)
- [Qwen3.8-27B vs Qwen3.8-Flash-Next: Benchmarks, Pricing & Which Is Better — llm-stats](https://llm-stats.com/models/compare/qwen3.8-27b-vs-qwen3.8-flash-next)
- [Qwen3.8-Flash-Next vs Qwen3.8-27B: which open Qwen to run? — OrcaRouter](https://www.orcarouter.ai/blog/qwen-3-8-next-vs-qwen-3-8)
- [Qwen3.8-Flash-Next: 125B MoE Beats Claude Opus 4.6 on SWE-bench (62.5 vs 53.4) — Local AI Zone](https://local-ai-zone.github.io/blog/qwen3-8-flash-next-deep-dive.html)
- [「Qwen3.8-Flash-Next」無償公開、Opus 4.6匹敵でQwen3.8-27B超え — PC Watch](https://pc.watch.impress.co.jp/docs/news/2135941.html)
- [Qwen3.8-Flash-Nextとは？125B/6BアクティブMoEの性能・ローカル実行要件 — AI革命](https://ai-revolution.co.jp/media/what-is-qwen-3-8-flash-next/)
- [Qwen3.8-Flash-Next Runs Locally in 75 GB of RAM — howaiworks.ai](https://howaiworks.ai/blog/alibaba-qwen-3-8-flash-next-local-gguf)
- [How to Run Qwen3.8 Flash Next Locally: GGUF, Hardware and Benchmarks — Atomic Chat](https://atomic.chat/blog/guides/how-to-run-qwen-3-8-flash-next-locally)
- [Run a Qwen3.8-Flash-Next Coding Agent Locally With OpenCode — DataCamp](https://www.datacamp.com/tutorial/run-qwen3-8-flash-next-locally)
- [Qwen/Qwen3.8-Flash-Next | vLLM Recipes (ツール呼び出し設定)](https://recipes.vllm.ai/Qwen/Qwen3.8-Flash-Next)
- [Qwen3.8-Flash-Next (UD-Q4_K_XL GGUF) on DGX Spark with llama.cpp — NVIDIA Developer Forums](https://forums.developer.nvidia.com/t/qwen3-8-flash-next-ud-q4-k-xl-gguf-on-dgx-spark-with-llama-cpp-gpu-experts-ple-n-gram-table-streamed-from-disk-25-tok-s-up-to-1m-context/381720)
- [orcarouter/Qwen3.8-Flash-Next-Uncensored-GGUF — Hugging Face](https://huggingface.co/orcarouter/Qwen3.8-Flash-Next-Uncensored-GGUF)
- [orcarouter/Qwen3.8-Flash-Next-Uncensored-MLX — Hugging Face](https://huggingface.co/orcarouter/Qwen3.8-Flash-Next-Uncensored-MLX)

### その他(二次)
- [Z.ai Releases GLM-5.3-Flash: A 320B-A18B Natively Multimodal MoE — MarkTechPost](https://www.marktechpost.com/2026/08/26/z-ai-releases-glm-5-3-flash-a-320b-a18b-natively-multimodal-moe-with-a-1m-token-context/amp/)
- [GLM-5.3-Flash — Unsloth Documentation (量子化サイズ)](https://unsloth.ai/docs/models/glm-5.3)
- [Run GLM-5.2 Locally: 744B MoE on 256GB Mac or PC — explainx.ai (メモリ要件)](https://explainx.ai/blog/unsloth-studio-glm-5-2-local-ai-setup-2026)
- [Meta Open-Sources Muse Glimmer: a 30B Local Agentic Model — InfoQ](https://www.infoq.com/news/2026/08/meta-muse-glimmer/)
- [Benchmarking Qwen3.8 27B quantizations: 4-bit holds up, 1-bit collapses — Quesma](https://quesma.com/blog/qwen38-27b-quantizations-benchmarked/)
- [Terminal-Bench 2.1 Leaderboard — CodingFleet](https://codingfleet.com/blog/terminal-bench-leaderboard-2026/)
- [国立情報学研究所（NII）、新たなLLM「LLM-jp-4 33B」を公開 — カレントアウェアネス](https://current.ndl.go.jp/car/283665)
- [Qwen Uncensored, Explained: Run the Abliterated 27B — OrcaRouter](https://www.orcarouter.ai/blog/qwen-uncensored-explained)
- [Abliterated Models 2026: The Best Uncensored GGUFs by VRAM — LocallyUncensored](https://locallyuncensored.com/blog/abliterated-models-guide.html)
- [Changelog — Hermes Agent | Nous Research](https://hermes-ai.net/changelog/)

---

## 📋 本調査の制約(次回への申し送り)

1. **初版で重大な取りこぼしが発生しました。** Qwen3.8-Flash-Next (8/26公開) を検出できず、「乗り換え候補なし」という誤った結論を出しました。原因は、タスク指定にあった GLM-5.3-Flash の PR 追跡に探索が引っ張られ、**同日公開の Qwen 本家リリースを独立に確認しなかった**ことです。**次回以降は、主要ベンダー (Qwen / DeepSeek / Z.ai / Moonshot / Meta / Mistral / MiniMax) の公式リリースを、PR追跡とは独立に必ず個別確認する**手順を先に回します。

2. **Issue起票不可**: このセッションのGitHubトークンは joe-yama/dotfiles に対して読み取り専用で、Issue作成が 403 で拒否されました (`gh` CLI もこの環境では利用不可)。週次ジョブとして Issue 起票を継続したい場合、リポジトリへの書き込み権限付与が必要です。

3. **ネットワークエグレス制限**: **github.com 以外のドメインがほぼ全面的にブロック**されています。実測で確認した限り、`huggingface.co` / `unsloth.ai` / `arxiv.org` / `docs.z.ai` / `nii.ac.jp` / `pc.watch.impress.co.jp` / `zenn.dev` / `x.com` はいずれも CONNECT トンネルが 403 で拒否されます。

   **影響**: 「2次情報は必ず1次ソースで裏取り」という方針に対し、**GitHub上の情報(PR状態、リリースノート、ソースツリー)のみ一次確認ができ、Hugging Face のモデルカード・量子化ファイルサイズ・ベンチマーク原典・ご提示のZenn記事本文は一次確認できていません**。(b)のメモリ数値・ベンチマークスコア・(e)の実測tok/sは、複数の二次情報の突き合わせによる推定を含みます。**特に実測tok/sは測定条件(文脈長・量子化・ランタイム)がソースごとにバラバラなため、必ずご自身の環境で再測定してください。**

   **対応案**: この週次ジョブを走らせる環境のネットワークポリシーに、最低限 `huggingface.co` と `zenn.dev` を許可ドメインとして追加することを推奨します。

4. **レジストリ未追跡**: `dot_config/llama-swap/config.yaml` がリポジトリに存在せず、現行構成をタスク記載の情報からのみ推定しています。上記YAMLの変数名 (`${LLAMA_BIN}` / `${MODELS_DIR}`) は仮置きです。
