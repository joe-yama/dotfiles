# ローカル LLM ベンチマーク

`dot_config/llama-swap/config.yaml` に登録した各モデルの生成スループット実測値。
モデルを入れ替えたら再計測してこの表を更新する。

- 機材: MacBook Pro (M4 Max / 128GB)
- 計測日: 2026-08-27
- エンドポイント: llama-swap (127.0.0.1:8080)

> ⚠️ **この表は 2026-08-30 のモデル入れ替え前の値です（未更新）。**
> 既定が `qwen38-27b` → `qwen38-flash-next` に、無検閲枠が `qwen38-abliterated` →
> `qwen38-flash-next-uncensored` に移行しましたが、**新2モデルは下記の計測条件で
> 測っていないため行を追加していません**。`hermes-43` は 2026-08-27 に
> レジストリから削除済みで、下記の行は履歴として残しているだけです。
> 参考値として Flash-Next は `-c 4096` / 32トークン生成のアドホック計測で
> 32.3 tok/s でしたが、条件が違うため下表とは比較できません。
> 下記「計測条件」の手順で再計測してから表を更新すること。

## Results

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
- 生成: `max_tokens: 256`（全モデルが 256 トークン到達で打ち切り）
- 1 モデルにつきウォームアップ 1 回 + 本計測 3 回、中央値を採用
- モデル間に 90 秒、run 間に 20 秒のクールダウン
- 順序を入れ替えて 2 周し、両者の一致を確認

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
