# Dotfiles

chezmoi + 1Password CLI で管理する macOS 設定ファイル群。シェル、ターミナル、ウィンドウ管理、エディタ、バージョン管理、開発ツールなどの設定を一元管理し、新しい Mac を一発でセットアップできるようにする。

## 管理しているツールと設定

### ターミナル環境

| ツール | 用途 | 設定ファイル |
|--------|------|-------------|
| **[Ghostty](https://ghostty.org/)** | メインのターミナルエミュレータ。GPU アクセラレーション対応、フォントは PlemolJP Console NF（日本語等幅） | `dot_config/ghostty/config` |
| **[Zellij](https://zellij.dev/)** | ターミナルマルチプレクサ。ペイン分割・タブ管理・WASM プラグインによる拡張が可能 | `dot_config/zellij/` |
| **tmux** | ターミナルマルチプレクサ（最小構成、passthrough のみ有効） | `dot_tmux.conf` |

### シェル

| ツール | 用途 |
|--------|------|
| **Zsh + [Oh My Zsh](https://ohmyz.sh/)** | メインシェル。プラグイン（補完、シンタックスハイライト、autosuggestions 等）で拡張 |
| **[bat](https://github.com/sharkdp/bat)** | `cat` の代替。シンタックスハイライト付きでファイルを表示 |
| **[fd](https://github.com/sharkdp/fd)** | `find` の代替。高速なファイル検索 |
| **[ripgrep](https://github.com/BurntSushi/ripgrep)** | `grep` の代替。高速な全文検索 |
| **[eza](https://eza.rocks/)** | `ls` / `tree` の代替。アイコン・色付きのファイル一覧表示 |
| **[zoxide](https://github.com/ajeetdsouza/zoxide)** | `cd` の代替。訪問履歴ベースのスマートディレクトリジャンプ |
| **[fzf](https://github.com/junegunn/fzf)** | 汎用ファジーファインダー。ファイル選択・ブランチ切り替え・リポジトリ移動などに使用 |
| **[delta](https://github.com/dandavison/delta)** | Git diff のページャー。シンタックスハイライト・side-by-side 表示対応 |
| **[direnv](https://direnv.net/)** | ディレクトリ単位の環境変数自動ロード |

### ウィンドウ管理・UI

| ツール | 用途 | 設定ファイル |
|--------|------|-------------|
| **[AeroSpace](https://github.com/nikitabobko/AeroSpace)** | タイル型ウィンドウマネージャ。Alt キーベースのキーバインドでウィンドウ配置を管理 | `dot_config/aerospace/aerospace.toml` |
| **[SketchyBar](https://github.com/FelixKratz/SketchyBar)** | カスタムメニューバー。ワークスペース、バッテリー、時計、Wi-Fi、VPN、IME 等を表示（Catppuccin Mocha テーマ） | `dot_config/sketchybar/` |
| **[Borders](https://github.com/FelixKratz/JankyBorders)** | アクティブウィンドウにグロー付きボーダーを表示 | `dot_config/borders/executable_bordersrc` |

### バージョン管理

| ツール | 用途 | 設定ファイル |
|--------|------|-------------|
| **Git** | メインの VCS。delta によるリッチな diff、1Password による SSH 署名、rerere による競合解決の記憶 | `dot_gitconfig` |
| **[Jujutsu (jj)](https://github.com/jj-vcs/jj)** | Git 互換の次世代 VCS。Git と colocated で運用し、日常の操作は jj を使用 | `dot_config/jj/config.toml.tmpl` |
| **[lazygit](https://github.com/jesseduffield/lazygit)** | Git の TUI クライアント | — |
| **[ghq](https://github.com/x-motemen/ghq)** | リポジトリのローカル管理。`~/repo/` 以下に統一的に配置 | — |
| **[GitHub CLI (gh)](https://cli.github.com/)** | GitHub の操作を CLI から実行 | `dot_config/gh/` |

### ファイル管理

| ツール | 用途 | 設定ファイル |
|--------|------|-------------|
| **[Yazi](https://yazi-rs.github.io/)** | ターミナルベースのファイルマネージャ。非同期 I/O で高速に動作 | `dot_config/yazi/yazi.toml` |

### 開発ツール

| ツール | 用途 | 設定ファイル |
|--------|------|-------------|
| **[Worktrunk](https://github.com/nicois/worktrunk)** | Git worktree ベースのブランチ管理。Claude Code (haiku) によるコミットメッセージ自動生成 | `dot_config/worktrunk/config.toml` |

### エディタ

| ツール | 用途 | 設定ファイル |
|--------|------|-------------|
| **[Neovim](https://neovim.io/)** | メインエディタ（設定は[別リポジトリ](https://github.com/joe-yama/nvim)で管理） | — |
| **[Helix](https://helix-editor.com/)** | モーダルエディタ。Tree-sitter / LSP ネイティブ対応、Catppuccin Mocha テーマ | `dot_config/helix/` |
| **VS Code** | サブエディタ。拡張機能は `dot_Brewfile` の `vscode` セクションで管理 | — |

### AI・生産性ツール

| ツール | 用途 |
|--------|------|
| **[Claude Code](https://docs.anthropic.com/en/docs/claude-code)** | AI コーディングアシスタント。権限・フック・MCP サーバー（Atlassian 等）を設定。Zellij フック統合、`run_onchange_after_claude-mcp.sh.tmpl` で MCP サーバーを自動同期 |
| **[Gemini CLI](https://github.com/google-gemini/gemini-cli)** | Google の AI CLI ツール。VS Code 拡張（Gemini Code Assist）と連携 |
| **GitHub Copilot** | AI コード補完。VS Code 拡張として導入 |
| **[Raycast](https://www.raycast.com/)** | ランチャー・生産性ツール |
| **[Obsidian](https://obsidian.md/)** | ナレッジベース・メモ管理 |

### セキュリティ

| ツール | 用途 |
|--------|------|
| **[1Password](https://1password.com/)** | パスワード管理、SSH Agent（秘密鍵の一元管理）、chezmoi テンプレートへのシークレット注入 |
| **[git-secrets](https://github.com/awslabs/git-secrets)** | コミット前に AWS キーや GitHub PAT のリークを自動検出 |
| **[gitleaks](https://github.com/gitleaks/gitleaks)** | リポジトリ全体のシークレットスキャン |

### macOS システム設定

`run_once_macos-defaults.sh` で以下を設定：

- **キーボード**: 高速キーリピート（KeyRepeat=2）、短い初期遅延
- **Finder**: 拡張子表示、パスバー、ステータスバー、リスト表示
- **Dock**: 自動非表示、最近使ったアプリ非表示（SketchyBar を代替として使用）
- **スクリーンショット**: `~/Screenshots` に PNG 保存、影なし
- **トラックパッド**: タップでクリック
- **メニューバー**: 自動非表示（SketchyBar との併用）

## Quick Start

```bash
# 新しいMacのセットアップ
git clone https://github.com/joe-yama/dotfiles.git ~/repo/github-personal/joe-yama/dotfiles
cd ~/repo/github-personal/joe-yama/dotfiles
./bootstrap.sh
```

## Structure

chezmoi のソースディレクトリ。ファイル名のプレフィックスで配置先とパーミッションを制御。

| Source Path | Target | Notes |
|-------------|--------|-------|
| `dot_zshrc`, `dot_zprofile`, `dot_zshenv` | `~/.zsh*` | Shell config |
| `dot_gitconfig` | `~/.gitconfig` | Git base config with includeIf |
| `dot_gitconfig.local.tmpl` | `~/.gitconfig.local` | Work identity (1Password) |
| `dot_gitconfig-personal.tmpl` | `~/.gitconfig-personal` | Personal identity (1Password) |
| `private_dot_ssh/` | `~/.ssh/` | SSH config (dir 0700, `private_` files 0600) |
| `dot_config/` | `~/.config/` | ghostty, aerospace, borders, sketchybar, jj, gh, yazi, helix, worktrunk |
| `dot_config/zellij/` | `~/.config/zellij/` | Zellij config + layouts (`default.kdl`, `dev.kdl`, `quad.kdl`) |
| `dot_config/jj/config.toml.tmpl` | `~/.config/jj/config.toml` | jj identity (1Password) |
| `dot_claude/` | `~/.claude/` | Claude Code settings + env |
| `.claude/rules/` | — | Claude Code ツール固有ルール（パススコープで自動読み込み） |
| `dot_tmux.conf` | `~/.tmux.conf` | tmux config |
| `dot_Brewfile` | `~/.Brewfile` | Homebrew packages |
| `run_once_macos-defaults.sh` | (run script) | macOS defaults (run once) |
| `run_onchange_brew-bundle.sh.tmpl` | (run script) | brew bundle (on Brewfile change) |
| `run_onchange_after_claude-mcp.sh.tmpl` | (run script) | Claude MCP servers sync (on settings.json change) |
| `run_onchange_zellij-plugins.sh` | (run script) | Zellij plugin download |

## Secrets Management

シークレットは chezmoi テンプレート + 1Password CLI で管理。`.tmpl` ファイル内で `onepasswordRead` 関数を使用：

```
# テンプレート内の記法
{{ onepasswordRead "op://work/Git Identity TMC/name" }}
```

`chezmoi apply` 時に 1Password から値が自動解決される。別途 `op inject` を実行する必要はない。

## Multi-GitHub Account

会社用（EMU）とプライベート用のGitHubアカウントを同一マシンから使い分け：

- **SSH**: `private_dot_ssh/config.d/github.conf` でホストエイリアス定義（`github.com` = 会社、`github-personal` = 個人）
- **Git**: `includeIf gitdir:` でディレクトリベースのID切り替え（`~/repo/github-personal/joe-yama/` 等）
- **URL書き換え**: `url.insteadOf` で ghq の通常フローを維持しつつ自動的に正しいSSHホストを使用
- **1Password SSH Agent**: 各鍵の公開鍵を `~/.ssh/*.pub` に配置し、Agentへのヒントとして使用

```bash
# 接続テスト
ssh -T github.com            # 会社アカウント
ssh -T github-personal       # プライベートアカウント
```

## Machine-Specific Config

マシン固有の設定は `.local` ファイルに分離（chezmoi 管理外、Git管理外）：

- `~/.zshrc.local` — プロキシ、マシン固有export
- `~/.ssh/config.d/proxy.conf` — 社内プロキシ
- `~/.Brewfile.local` — マシン固有パッケージ

## Neovim

Neovim設定は独立したリポジトリで管理：

```bash
ghq get <nvim-config-repo-url>
# or: git clone <url> ~/.config/nvim
```

## Homebrew Package Management

### パッケージの追加（全マシン共通）

```bash
# 1. dot_Brewfile にパッケージを追加
vi dot_Brewfile
# brew "ripgrep"   ← CLI ツール
# cask "firefox"   ← GUI アプリ

# 2. chezmoi apply で自動的に brew bundle が実行される
make apply
```

`run_onchange_brew-bundle.sh.tmpl` が `dot_Brewfile` のハッシュ変更を検知し、自動で `brew bundle --global` を実行する。

### パッケージの削除（全マシン共通）

```bash
# 1. dot_Brewfile から該当行を削除
vi dot_Brewfile

# 2. chezmoi apply を実行（Brewfile 更新を反映）
make apply

# 3. Brewfile に記載のないパッケージを確認・削除
brew bundle cleanup --global          # 対象パッケージの確認（dry-run）
brew bundle cleanup --global --force  # 実際に削除
```

`chezmoi apply` 後に orphaned packages が表示されるので、確認してから `--force` で削除する。

### マシン固有パッケージの管理（Brewfile.local）

`~/.Brewfile.local` はchezmoi管理外・Git管理外のため、マシンごとに手動で管理する。

```bash
# 1. ~/.Brewfile.local を作成・編集
vi ~/.Brewfile.local
# brew "mysql"     ← このマシンでのみ必要なパッケージ
# cask "wireshark"

# 2. chezmoi apply でグローバル Brewfile と一緒にインストールされる
make apply

# または Brewfile.local のみ単独で実行
brew bundle --file="$HOME/.Brewfile.local"
```

`chezmoi apply` 時に `~/.Brewfile.local` が存在すれば自動で `brew bundle` が実行される。削除する場合は `~/.Brewfile.local` から該当行を削除し、`brew uninstall <pkg>` で手動削除する。

## Zellij

プラグインはプロキシ環境下で Zellij が直接ダウンロードできないため、`run_onchange_zellij-plugins.sh` で事前ダウンロードし `~/.config/zellij/plugins/` に配置。config/layout からは `file:` で参照。

### プラグインのバージョン更新

```bash
# 1. run_onchange_zellij-plugins.sh 内の URL を更新
# 2. 古い .wasm を削除
rm ~/.config/zellij/plugins/<plugin>.wasm
# 3. スクリプト再実行
bash run_onchange_zellij-plugins.sh
```

## Commands

```bash
make apply     # chezmoi apply -v (deploy dotfiles, verbose)
make diff      # chezmoi diff (preview changes)
make doctor    # chezmoi doctor (health check)
make macos     # Apply macOS defaults (run_once_macos-defaults.sh)
```
