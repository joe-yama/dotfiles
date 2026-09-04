# ローカル LLM ベンチマーク

`dot_config/llama-swap/config.yaml` に登録した各モデルの生成スループット実測値。
モデルを入れ替えたら再計測してこの表を更新する。

- 機材: MacBook Pro (M4 Max / 128GB)
- エンドポイント: llama-swap (127.0.0.1:8080)。構成は `local-llm-architecture.md`

> **2026-09-05 撤去**: `qwen38-27b` / `qwen38-27b-mlx` / `qwen38-abliterated` (27B 世代フォールバック 3 本、計 87GB) と
> `qwen38-flash-next-rvn` (比較枠 91GB) をレジストリとディスクから削除した。下表の該当行は履歴。
> 同日、`qwen38-27b-fast` (15GB) も削除し、opencode の small_model を `qwen38-flash-next` に置き換えた。27B 世代は全撤去。
> 同日、mlx-serve v26.9.1 の実機 A/B (Flash-Next 4bit: short 70.3 / 24k 後 57.9 tok/s、llama.cpp UD-Q3_K_XL の 2.1〜2.2 倍) を
> 実施。詳細は検証レポート (mlxserve-ab-report-20260905.md) を参照。

## Results — mlx-serve 切り替え (2026-09-05)

mlx-serve v26.9.1 (MLX 0.32.2) vs llama.cpp b10769。順序反転 2 周・各周 3 run 中央値、一意スタンプで cache 無効化。
short = 固定英文 (thinking on、256 tok)、long = 実テキスト ≈23.7k tok + needle (thinking off、256 tok)。
詳細・ハーネス: `mlxserve-ab-20260905.md`、`bench/`。**この結果で両エントリを mlx-serve に切り替え、GGUF は削除した。**

| Alias (2026-09-05 以降の実体) | Pack | Quant | On disk | 常駐 | short decode | short TTFT | 24k 後 decode | 24k prefill |
|---|---|---|---|---|---:|---:|---:|---:|
| `qwen38-flash-next` | `ddalcu/Qwen3.8-Flash-Next-MLX-Serve-4bit` | MLX 4bit g64 (lm_head 8bit) | 105 GB | 67 GB wired | **70.3** | 1.22 s | **57.9** | **694** |
| 同 + MTP (`enable_mtp:true`、不採用) | 同上 | 同上 | | 70 GB | 74.5 | 1.3 s | 49.7〜56.8 | 696 |
| `qwen38-flash-next-uncensored` *(Hermes 既定)* | `ARC4NUM/Qwen3.8-Flash-Next-Uncensored-MLX-Serve-4bit` | MLX mixed 4/8bit | 107 GB | 70 GB wired | **56.1** | 1.0〜1.4 s | **47.9** | **700** |
| 同 + MTP (不採用) | 同上 | 同上 | | | 60.4〜63.5 | 1.2 s | 50.0 | 695 |
| *(旧)* `qwen38-flash-next` | `unsloth/Qwen3.8-Flash-Next-GGUF` | UD-Q3_K_XL | 90 GB | 10 GB dirty + 56 GB mapped | 34.0 | 0.80 s | 26.0 | 402 |
| *(旧)* `qwen38-flash-next-uncensored` | `mradermacher/…-Uncensored-i1-GGUF` | i1-IQ4_XS | 97.5 GB | 10 GB dirty + 63 GB mapped | 37.7 | 0.81 s | 33.3 | 398 |

- 品質プローブ (code 5 題 / tools 4 問 / NIAH / 日本語 / 無検閲は拒否 3 問) は全アーム同等。tools の 3/4 はエンジン差ではなくツール選択の揺れ。
- MTP は本命パックで利得なし〜負 (24k 後 −2〜−14%)、無検閲パックで +4〜13%。パック依存なので既定 off で揃えた。
- 短文 TTFT は mlx-serve が 0.4 秒遅い。長文プレフィルは 1.7 倍速い。
- mlx-serve は重みを wired で持つ (退避不可)。推論中のシステム wired は 78〜90GB。llama-swap の排他スワップ外で別モデルを立てると Metal OOM で落ちる (計測中に Hermes cron 09:00 との二重常駐で 1 回発生)。

## Results — Flash-Next 無検閲枠 (2026-09-03、履歴)

llama.cpp 公式バイナリ b10769 / `-c 262144` / `--jinja` / `--override-tensor` なし
(`--lazy-mode auto` が PLE 28.8GB を CPU 側 mmap に置く)。2 周 (順序反転) とも中央値が
一致したので両周の値を併記する。

| Alias | Full model name | Quant | On disk | GPU 常駐 | Decode tok/s (R1 / R2) | Prefill tok/s | TTFT |
|-------|-----------------|-------|--------:|--------:|-----------------------:|--------------:|-----:|
| `qwen38-flash-next-uncensored` *(Hermes 既定)* | `mradermacher/Qwen3.8-Flash-Next-Uncensored-i1-GGUF` | i1-IQ4_XS | 97.5 GB | 64 GB | **37.3 / 37.4** | 158 | 0.76 s |
| `qwen38-flash-next-rvn` | `0bserverx/RVN-Qwen3.8-Flash-Next-Abliterated-Uncensored-GGUF` | IQ4_XS (8 shards) | 97.5 GB | 64 GB | **37.2 / 37.3** | 163 | 0.73 s |
| *(旧)* 同 uncensored | 同上 | i1-IQ3_M | 89.5 GB | 58 GB | **34.6 / 34.2** | 164 | 0.73 s |

- GPU 常駐は `footprint` の mapped-file clean 値 (Metal マップ範囲はファイル全域だが PLE ページは触られない)。
  KV は f16 で 6144 MiB + QSA 用 2304 MiB = 約 8.4 GB @262K。
- **IQ4_XS は IQ3_M より約 9% 速い**。27B の Q6_K vs Q8_0 と同じ傾向で、M4 Max では
  低ビット量子化の逆量子化コストが帯域削減の利得を上回る。IQ4_XS は品質 (KLD 0.080 vs
  IQ3_S 0.163) でも速度でも IQ3_M の上位。
- RVN と orcarouter 系は同じ IQ4_XS で速度差なし (0.1 tok/s 以内)。差は系譜 (拒否/迂回の
  振る舞い) だけ。
- Load (ページキャッシュ冷): IQ4_XS 単一ファイル約 60 秒、RVN 8 シャード約 35 秒。温まっていれば 3 秒。
- ツール呼び出し: 3 モデルとも `--jinja` で構造化 `tool_calls` を返し、`content` に XML は漏れない
  (Hermes 要件)。thinking は 50-70 トークンで終端し無限ループ症状なし。
- 旧 IQ3_M の R2 は llama-swap 側に IQ4_XS が常駐したままの計測 (合計 mmap 146GB) だが
  R1 (単独) と 1% 差で一致したため採用。

## Results — 2026-08-27 (27B 世代、履歴)

> `qwen38-27b` → `qwen38-flash-next` への既定移行 (2026-08-30) 以降、`qwen38-flash-next`
> (base、UD-Q3_K_XL) は上記条件でまだ測っていない。`hermes-43` は 2026-08-27 に
> レジストリから削除済み。プロンプト本文は 08-27 と 09-03 で異なるため両表の直接比較は
> 目安に留めること。

Decode 速度は TTFT を除いた純粋な生成速度（3 回計測の中央値）。

| Alias | Full model name | Backend | Quant | On disk | Decode tok/s | TTFT | Load |
|-------|-----------------|---------|-------|---------|-------------:|-----:|-----:|
| `qwen38-27b-fast` | `mlx-community/Qwen3.8-27B-4bit` | vllm-mlx | 4-bit | 15 GB | **29.1** | 0.60 s | 8.9 s |
| `qwen38-27b` *(当時の既定)* | `unsloth/Qwen3.8-27B-GGUF:Q8_0` + MTP draft head | llama.cpp | Q8_0 | 28 GB | **18.3** | 0.19 s | 17.7 s |
| `qwen38-abliterated` | `chimingw/Qwen3.8-27B-Uncensored-OrcaRouter-GGUF` + MTP draft head | llama.cpp | Q8_0 | 30 GB | **17.9** | 0.20 s | 4.3 s |
| `qwen38-27b-mlx` | `mlx-community/Qwen3.8-27B-8bit` | vllm-mlx | 8-bit | 28 GB | **16.5** | 0.75 s | 10.2 s |
| `hermes-43` | `alexcovo/Hermes-4.3-36B-mlx-8Bit` | vllm-mlx | 8-bit | 36 GB | **12.5** | 1.10 s | 13.3 s |

Load はモデルのロード完了までの時間。ページキャッシュの温まり具合に強く依存するため参考値。

## 計測条件

- プロンプト: 固定の英文 1 件（75 トークン）、`temperature: 0`
- 生成: `max_tokens: 256`（08-27 は全モデルが 256 到達で打ち切り。09-03 は IQ4_XS のみ 238 トークンで EOS、他は 254-256）
- 1 モデルにつきウォームアップ 1 回 + 本計測 3 回、中央値を採用
- モデル間に 90 秒、run 間に 20 秒のクールダウン
- 順序を入れ替えて 2 周し、両者の一致を確認

09-03 のプロンプト本文 (Flash-Next テンプレ込みで `prompt_n` = 120):

> You are helping a software engineer. Explain, in plain English and in a single well-structured paragraph, how a garbage collector decides which objects in memory are still reachable, why reference cycles are a problem for simple reference counting, and how generational collection reduces the cost of scanning long-lived objects. Keep the explanation concrete and avoid bullet points.

## 落とし穴

**熱ダレで計測順序バイアスが出る。** クールダウンなしで連続計測すると、後半のモデルが最大 -42% の不当な低評価を受ける（`hermes-43` は 8.0 → 12.5 tok/s、`qwen38-abliterated` は 12.6 → 17.9 tok/s）。モデル間にクールダウンを挟み、順序を逆にした 2 周目で数値が一致することを確認すること。

**SSE のチャンク数はトークン数ではない。** MLX バックエンドは 1 チャンクに複数トークンを載せてくるため、チャンクを数えると速度を約半分に見誤る。`stream_options.include_usage` を付けて `usage.completion_tokens` で数える。

**abliterated 版に速度上の代償はない。** 本家 Q8_0+MTP とほぼ同速。llama.cpp の `timings` で確認した MTP ドラフト受理率も 51%（abliterated）対 53%（本家）でほぼ同等だった。

## 再現方法

llama.cpp バックエンドは非ストリーミングのレスポンスに `timings` を含むため、投機デコードの受理率まで確認できる。

```bash
curl -s -X POST http://127.0.0.1:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen38-27b","messages":[{"role":"user","content":"..."}],
       "max_tokens":256,"temperature":0}' \
  | jq '.timings'
# => predicted_per_second, draft_n, draft_n_accepted
```

MLX バックエンドは `timings` を返さないので、ストリーミングでチャンク到着時刻を記録し
`usage.completion_tokens` と突き合わせて算出する。
