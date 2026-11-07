# Hermes Agent v0.19.0 (uv tool / PyPI) → v0.23.0 (install.sh / PM) 移行計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** PyPI で更新が止まった Hermes v0.19.0 を上流の install.sh 方式 v0.23.0 に移し、プラグインカタログ (`hermes plugins search/install`) を使える状態にする。Discord gateway・既存設定・プラグインはそのまま動かす。

**Architecture:** 本体は `~/.hermes/hermes-agent/` の git checkout (stable channel) と、PM が管理する Python 3.14 環境。CLI は `~/.local/bin/hermes` の wrapper。chezmoi は `~/.hermes/config.yaml` と `.env` だけを管理し続け、本体の導入は新しい `run_onchange_after_install-hermes.sh` に移す。その後の更新は `hermes update` で行う。pip の `--with` で追加していた依存は、PM extras (`hermes pm install --extra`) とカタログのプラグインに置き換える。

**Tech Stack:** Hermes Agent v0.23.0、PM (`pm/`、uv.lock の hash 検証)、chezmoi、launchd、jj

**Spec:** 調査結果 (2026-11-08 セッション)。要点は下の「前提事実」に転記した。

## 前提事実 (調査で確認済み)

- PyPI の `hermes-agent` は 0.19.0 (2026-07-20) が最終版。上流 GitHub は v0.23.0 (2026-11-05)。
- install.sh は本体を `$HERMES_HOME/hermes-agent` に clone し、PM が Python 3.14.9 (python-build-standalone) を用意する。launcher は `~/.local/bin/hermes`。`--non-interactive` を付けると setup / gateway ステージは飛ばされる。
- Hermes のバージョンは git tag / stamp から読む。pyproject の version は `0.0.0` なので、`uv tool install git+...` 方式は使わない。
- `tools/lazy_deps.py` は廃止された。追加 pip を入れる経路は `hermes pm install --extra NAME` に限る。素の pip / uv で環境に手を入れるのは禁止。使う extras は `discord = discord.py[voice]==2.7.1`、`ddgs = ddgs==9.16.0`、`edge-tts = edge-tts==7.3.1`。
- **holographic は本体同梱から外れ、community プラグイン `holographic` になった** (`itpartypattaya/hermes-plugin-holographic`、`requires_hermes >=0.21.5`)。provider 名・`memory_store.db`・設定キーはそのまま。現在の DB は facts 0 件。
- rtk-rewrite もカタログにある (`kerrz2020/hermes-rtk-rewrite`、community mirror)。PyPI の `rtk-hermes` とは別物だが、entry 名は同じ `rtk-rewrite`。`rtk` が PATH に無いときはコマンドを書き換えずにそのまま通す。
- disk-cleanup / security-guidance / platforms/discord / web/ddgs は引き続き同梱。
- v0.23 の破壊的変更: browser ツールは `browser_exec` だけになった。`hermes mcp serve` は `mcp-serve` プラグインに分離された。config migration v51 で一部キーが消える。**gateway が書き込んだ後の `state.db` は旧版では使えない (ロールバックはバックアップの復元が必要)**。
- install.sh は `~/.zshrc` と `~/.zprofile` に `PATH=.*\.local/bin` 形式の行が無いと PATH 行を追記する。`dot_zshrc:40` は条件を満たすので触られない。**`dot_zprofile` は満たさないので追記される**。
- cron `local-llm-daily-jp` は 2026-11-04 から paused (`hermes cron list` には出てこない)。
- `~/.hermes/plugins/herdr-agent-state` は herdr 由来のユーザープラグインで、chezmoi の管理外。

## Global Constraints

- VCS は `jj` を使う。commit はユーザーの指示があったときだけ行う。
- `chezmoi apply` は対象を明示し、`--force` は使わない。差分が出たら `chezmoi diff <target>` を見せ、ソースとターゲットのどちらを採るかユーザーに確認する。
- install.sh・`uv tool`・`chezmoi apply`・`brew` は sandbox を無効にして実行する (メモリ: sandbox が chezmoi/brew を阻む)。
- `pkill -f` は使わない。プロセスは `launchctl` か `kill $(lsof -ti tcp:PORT)` で止める。
- install.sh は main ではなく **タグ `v0.23.0` の raw URL** から取得する。
- 決定事項 (既定値。実行前に変更可):
  - `--skip-browser --skip-computer-use`: Chromium と cua-driver は入れない。必要になったら `hermes pm install chromium` で追加する。
  - holographic は維持する: カタログから入れ、`memory.provider` は変えない。
  - 更新 channel は `stable`。
- llama-swap (127.0.0.1:8080) が起動していること (Task 5・6 の動作確認で使う)。

## Review Focus

1. **`chezmoi apply` が旧 uv-tools スクリプトを再実行して v0.19 を入れ直し、`~/.local/bin/hermes` を上書きする** → Task 2 で hermes ブロックを消し、Task 3 Step 6 で `chezmoi apply` 後も wrapper が v0.23 のままであることを確かめる。
2. **新規インストールでは holographic が自動移行されない**。その場合、built-in メモリへ黙って切り替わる → Task 3 Step 4 と Task 6 Step 1 で `hermes memory status` に holographic と出ることを確かめる。
3. **discord extra が欠けたまま launchd で gateway が起動し、Discord アダプタだけが無効になる** → Task 5 Step 3 で gateway.log の接続行と、実際の送信を確かめる。
4. **install.sh が `~/.zprofile` に PATH 行を追記し、chezmoi とずれる** → Task 4 Step 3 で diff を解消する。
5. **config migration (v33→v51+) で `config.yaml` が書き換わり、ソースのコメントが失われる** → Task 4 でターゲットの変更を手でソースに取り込み、コメントを残す。

---

### Task 1: 現状の記録・バックアップ・旧 gateway の撤去

**Files:** なし (状態を記録するだけ)

- [ ] **Step 1: 移行前の状態を記録する**

```bash
B=~/hermes-migration-20261108; mkdir -p $B
hermes --version > $B/version.txt
COLUMNS=250 hermes plugins list > $B/plugins.txt
cp ~/.hermes/config.yaml $B/config.yaml.before
cp ~/Library/LaunchAgents/ai.hermes.gateway.plist $B/
cat ~/.local/share/uv/tools/hermes-agent/uv-receipt.toml > $B/uv-receipt.toml
```
期待値: `version.txt` に `v0.19.0`。`plugins.txt` で enabled なのは disk-cleanup / security-guidance / discord-platform / herdr-agent-state / rtk-rewrite。

- [ ] **Step 2: 旧 gateway を launchd から外す (旧 CLI で実行)**

Run: `hermes gateway uninstall`
確認: `launchctl print gui/$UID/ai.hermes.gateway` がエラーを返す (未登録)。`~/Library/LaunchAgents/ai.hermes.gateway.plist` が無い。

- [ ] **Step 3: `~/.hermes` を丸ごとバックアップする (gateway 停止後に行い、SQLite の整合を保つ)**

Run: `tar -czf ~/hermes-migration-20261108/hermes-home.tgz -C ~ .hermes`
確認: `tar -tzf ... | grep -c state.db` が 1 以上。

### Task 2: chezmoi ソースの導入経路を切り替える

**Files:**
- Modify: `run_onchange_after_install-uv-tools.sh:7-9` (hermes の説明コメント)、`:18-35` (hermes の `uv tool install` ブロック)
- Create: `run_onchange_after_install-hermes.sh`

- [ ] **Step 1: uv-tools スクリプトから hermes 関連の行をすべて削除する** (vllm-mlx の行は残す)

確認: `grep -c -i hermes run_onchange_after_install-uv-tools.sh` が `0`。`bash -n run_onchange_after_install-uv-tools.sh` が通る。

- [ ] **Step 2: `run_onchange_after_install-hermes.sh` を作る**

`#!/usr/bin/env bash` + `set -euo pipefail`。PATH には `$HOME/.local/bin:/opt/homebrew/bin` を前置する。冒頭コメントには前提事実のうち「PyPI 停止」「extras は PM 経由」「holographic/rtk-rewrite はカタログ」を 1 行ずつ書く。処理はすべて冪等にし、上から順に:

1. `uv tool list` に `hermes-agent` があれば `uv tool uninstall hermes-agent` (旧方式からの移行)。
2. `~/.hermes/hermes-agent/.git` が無ければ、次を実行する。
   `curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/v0.23.0/scripts/install.sh | bash -s -- --non-interactive --channel stable --skip-browser --skip-computer-use`
   タグは変数 `HERMES_BOOTSTRAP_REF=v0.23.0` にする。初回導入にだけ使い、以降の更新は `hermes update` で行う、とコメントを添える。
3. `hermes pm install --extra discord`、`--extra ddgs`、`--extra edge-tts` を 1 つずつ実行する (複数指定できるかは未確認)。
4. `~/.hermes/plugins/holographic` が無ければ `hermes plugins install holographic`。`~/.hermes/plugins/rtk-rewrite` が無ければ `hermes plugins install rtk-rewrite`。

確認: `bash -n run_onchange_after_install-hermes.sh` が通る。`chezmoi managed | grep install-hermes` に出る (スクリプトは実行属性なしでも chezmoi が実行するので `executable_` は不要)。

### Task 3: v0.23 を導入する

**Interfaces:**
- Consumes: Task 2 の `run_onchange_after_install-hermes.sh`
- Produces: `~/.hermes/hermes-agent/` (git checkout)、`~/.local/bin/hermes` (v0.23 wrapper)

- [ ] **Step 1: スクリプトを直接実行する (sandbox 無効)**

Run: `bash ~/dotfiles/run_onchange_after_install-hermes.sh 2>&1 | tee ~/hermes-migration-20261108/install.out`
確認: 終了コードが 0。失敗したら `~/.hermes/logs/install.log` の末尾を見る。

- [ ] **Step 2: 本体と launcher を確認する**

Run: `hermes --version; git -C ~/.hermes/hermes-agent describe --tags; file ~/.local/bin/hermes`
期待値: `v0.23.0` (またはそれ以降の stable)。`~/.local/bin/hermes` は uv tools 配下への symlink ではなくなっている。

- [ ] **Step 3: extras を確認する**

Run: `cd ~/.hermes/hermes-agent && source ./activate && python -m pm.cli status` (上流 docs `reference/package-management.md` の手順)
期待値: selected extras に `discord`・`ddgs`・`edge-tts` が含まれる。

- [ ] **Step 4: プラグインとメモリを確認する**

Run: `COLUMNS=250 hermes plugins list; hermes plugins doctor; hermes memory status`
期待値: holographic・rtk-rewrite・disk-cleanup・security-guidance・discord-platform・herdr-agent-state が enabled。doctor にエラーが無い。memory status に `holographic` と出る。holographic が disabled なら `hermes plugins enable holographic` を実行する。herdr-agent-state が manifest 非互換で落ちていたら記録だけ残す (herdr 側の問題として後で対処)。

- [ ] **Step 5: 旧 uv tool が残っていないことを確認する**

Run: `uv tool list | grep -c hermes-agent; ls ~/.local/bin/hermes-acp ~/.local/bin/hermes-agent 2>&1`
期待値: `0`。`hermes-acp` と `hermes-agent` は、無いか、v0.23 の wrapper になっている。

- [ ] **Step 6: 旧スクリプトの再実行で v0.19 に戻らないことを確認する**

Run: `bash ~/dotfiles/run_onchange_after_install-uv-tools.sh && hermes --version`
期待値: vllm-mlx だけが更新され、`hermes --version` は v0.23 のまま。

### Task 4: 設定の migration を chezmoi ソースに取り込む

**Files:**
- Modify: `private_dot_hermes/private_config.yaml`
- Modify: `dot_zprofile` (ユーザーが installer の追記を残すと決めた場合のみ)

- [ ] **Step 1: config の migration を実行する**

Run: `hermes config check; hermes config migrate`
期待値: `_config_version` が 51 以上になる。retired キーについての案内を記録しておく。

- [ ] **Step 2: config の差分をソースに取り込む**

Run: `chezmoi diff ~/.hermes/config.yaml`
ターゲット側で追加・変更されたキーを `private_config.yaml` に手で反映する。既存のコメントは残し、消されたキーはコメントごと削除する。holographic の設定キー (`plugins.hermes-memory-store`) が追加されていれば取り込む。最後に `chezmoi diff ~/.hermes/config.yaml` が空になることを確認する (どちらを採るか迷う差分はユーザーに確認する)。

- [ ] **Step 3: `~/.zprofile` のずれを解消する**

Run: `chezmoi diff ~/.zprofile ~/.zshrc`
期待値: `~/.zprofile` に `# Hermes Agent command` ブロックが追記されている。`~/.zshrc` 側で `~/.local/bin` は既に PATH に入っているので、推奨は `chezmoi apply ~/.zprofile` でソース側に戻すこと。どちらを採るかはユーザーに確認してから適用する。

- [ ] **Step 4: 全体の同期を確認する**

Run: `chezmoi verify; echo $?`
期待値: `0`。

### Task 5: gateway を再登録して Discord を確認する

- [ ] **Step 1: launchd に登録する**

Run: `hermes gateway install`
確認: `plutil -p ~/Library/LaunchAgents/ai.hermes.gateway.plist | grep -c 'uv/tools'` が `0`。ProgramArguments が `~/.hermes/hermes-agent` 配下を指している。PATH に `/opt/homebrew/bin` を含む (rtk のため)。

- [ ] **Step 2: 起動状態を確認する**

Run: `launchctl print gui/$UID/ai.hermes.gateway | grep -E 'state|pid'`
期待値: `state = running`。

- [ ] **Step 3: Discord の疎通を確認する**

Run: `hermes send -t 'discord:#一般' 'Hermes v0.23 移行テスト'` を実行し、`tail -50 ~/.hermes/logs/gateway.log` を見る。
期待値: Discord にメッセージが届く。ログに Discord 接続済みの行があり、`ImportError` / `discord` 関連のエラーが無い。

- [ ] **Step 4: cron ジョブが残っていることを確認する**

Run: `python3 -c 'import json;print([(j["name"],j["state"]) for j in json.load(open("'$HOME'/.hermes/cron/jobs.json"))["jobs"]])'`
期待値: `('local-llm-daily-jp', 'paused')`。再開するかどうかはユーザーが決める。

### Task 6: 機能を確認する

- [ ] **Step 1: holographic で書き込みと読み出しができる**

Run: `hermes -z 'fact_store に「移行テスト: 2026-11-08 に v0.23 へ移行」を保存し、続けて検索して結果を返して' -t memory` (toolset 名は `hermes tools list` で確認する)
確認: `sqlite3 ~/.hermes/memory_store.db 'select count(*) from facts'` が 1 以上。確認後、テスト用の fact は `forget` で消す。

- [ ] **Step 2: ddgs で検索できる**

Run: `hermes -z '"mlx-serve" を web 検索して上位1件の URL だけ返して' -t web`
期待値: URL が返る (web_search が登録されている)。

- [ ] **Step 3: rtk で書き換わる**

Run: `hermes -z 'terminal で git -C ~/dotfiles status を実行して' -t coding` を実行してから、`grep -i rtk ~/.hermes/logs/*.log | tail -5` を見る。
期待値: コマンドが `rtk git ...` に書き換えられた形跡がある。

- [ ] **Step 4: プラグインカタログに届く**

Run: `hermes plugins search memory | head; hermes plugins info hermes-memory-wiki`
期待値: 一覧と詳細が表示される。これが本移行の目的。

### Task 7: ドキュメントとメモリを更新する

**Files:**
- Modify: `docs/local-llm-architecture.md:57` (Hermes 行: 配置 `~/.hermes/hermes-agent/` + `~/.local/bin/hermes` wrapper、Python 3.14 (PM)、導入経路 `run_onchange_after_install-hermes.sh`、更新は `hermes update`)
- Modify: `~/.claude/projects/-Users-joe-dotfiles/memory/hermes-agent-setup.md` (導入方法・`--with` の記述を PM extras と catalog に置き換える。brew 版 3.14 クラッシュの記述は「旧 brew 版の話」と明記する)

- [ ] **Step 1: 上の 2 ファイルを更新する**
- [ ] **Step 2: 差分をユーザーに見せ、commit するかどうかの指示を待つ** (`jj diff --stat`)

### ロールバック (Task 3 以降で失敗した場合)

1. `hermes gateway uninstall` (v0.23 CLI)
2. `mv ~/.hermes ~/.hermes.v023-failed` で退避してから、`tar -xzf ~/hermes-migration-20261108/hermes-home.tgz -C ~` で戻す (v0.23 が書いた `state.db` は旧版で使えないので、上書きせずに丸ごと差し替える)
3. `rm ~/.local/bin/hermes` を実行してから、`uv tool install --python 3.12 hermes-agent==0.19.0` に `uv-receipt.toml` の `--with` 群を付けて入れ直す
4. `jj restore --from @- run_onchange_after_install-uv-tools.sh` を実行し、`run_onchange_after_install-hermes.sh` を削除する
5. `hermes gateway install` を実行し、Task 5 Step 3 と同じ方法で疎通を確認する
