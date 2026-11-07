#!/bin/bash
# PreToolUse permission gate — gh api / op / git push / gh の書き込みを対象。
# allow: 読み取り (GET) / ask: 変更系、または個人リポジトリ (joe-yama) 以外 / 出力なし: 通常フローに defer
#
# hook は ask / deny の方向にしか効かない（settings の ask ルールを hook の allow で覆せない。
# 公式 hooks-guide）。そのため「個人リポジトリでは自動、それ以外は確認」は、
# ~/.claude/settings.json の ask から git push / gh issue create / gh issue comment / gh pr create を外し、
# この hook が個人リポジトリ以外・joe-yama 以外の login を ask に回す形で実現する
# （2026-09-20。portfolio の docs/harness/README.md §4、hooks.md §4）。
set -euo pipefail

input=$(cat)
tool=$(jq -r '.tool_name // ""' <<<"$input")
[ "$tool" = "Bash" ] || exit 0
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
cwd=$(jq -r '.cwd // ""' <<<"$input")
[ -n "$cwd" ] || cwd=$(pwd)

decide() {
  jq -n --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
  exit 0
}

# origin が github.com（SSH エイリアス github-personal を含む）の joe-yama 配下か
personal_origin() {
  local url
  url=$(git -C "$cwd" remote get-url origin 2>/dev/null) || return 1
  grep -Eq '(github\.com|github-personal)[:/]joe-yama/' <<<"$url"
}
login_is_joe_yama() {
  [ "$(gh api user --jq .login 2>/dev/null || true)" = "joe-yama" ]
}

# --- 締める方向（ask）。複合コマンドでも生文字列で見る。ask を返すだけなので安全 ---

# A. git push: origin が個人リポジトリ以外なら確認。
#    main への push などブランチの制約は portfolio 側の .claude/hooks/ask-gate.sh が担う
if grep -Eq '(^|[;&|[:space:]])git[[:space:]]+push([[:space:]]|$)' <<<"$cmd"; then
  personal_origin || decide ask "git push: origin が joe-yama の個人リポジトリではない — 確認が必要"
fi

# B. gh の書き込み（issue create / issue comment / pr create）:
#    対象リポジトリ（--repo / -R があればそれ、無ければ origin）が joe-yama 配下で、
#    かつ gh の現在の login が joe-yama のときだけ通常フロー（allow）に流す
if grep -Eq '(^|[;&|[:space:]])gh[[:space:]]+(issue[[:space:]]+(create|comment)|pr[[:space:]]+create)([[:space:]]|$)' <<<"$cmd"; then
  repo=""
  if m=$(grep -oE '(^|[[:space:]])(-R|--repo)([[:space:]]+|=)[^[:space:]]+' <<<"$cmd"); then
    repo=$(head -1 <<<"$m" | sed -E 's/.*(-R|--repo)([[:space:]]+|=)//')
  fi
  if [ -n "$repo" ]; then
    case "$repo" in
      joe-yama/*|*/joe-yama/*) ;;
      *) decide ask "gh: --repo が joe-yama/ 配下ではない（$repo）— 確認が必要" ;;
    esac
  else
    personal_origin || decide ask "gh: origin が joe-yama の個人リポジトリではない — 確認が必要"
  fi
  login_is_joe_yama || decide ask "gh: 現在の login が joe-yama ではない（gh api user）— 確認が必要。切り替えは gh auth switch -h github.com -u joe-yama"
fi

# --- 緩める方向（allow）。フックはルールと違い複合コマンドを分解前の生文字列で受け取る。
# "gh api x && rm -rf ~" が allow 分岐に入らないよう、メタ文字があれば defer。
case "$cmd" in
  *'&&'*|*'||'*|*';'*|*'|'*|*'$('*|*'`'*|*$'\n'*) exit 0 ;;
esac

case "$cmd" in
  'gh api '*)
    # gh api はフィールド指定 (-f/-F/--field/--input) があると暗黙で POST になる
    if grep -qiE -- '(^| )(-X|--method)[= ]*(POST|PUT|PATCH|DELETE)' <<<"$cmd" \
       || grep -qE  -- '(^| )(-f|-F|--field|--raw-field|--input)' <<<"$cmd"; then
      decide ask "gh api mutation — 確認が必要"
    else
      decide allow "gh api read-only (GET)"
    fi
    ;;
  'op account list'|'op whoami'|'op --version')
    decide allow "op 状態確認 — 秘密を出力しない"
    ;;
  'op inject -i '"$HOME"'/.claude/.env -o '*)
    # 入力を既知の MCP env テンプレートに固定し、出力先が stdout 系なら許可しない。
    # (-i に任意ファイルを渡せると任意の op:// 参照を解決できてしまう)
    case "$cmd" in
      *'/dev/std'*|*'/dev/fd'*|*'/dev/tty'*) exit 0 ;;
    esac
    decide allow "op inject: MCP env テンプレートをファイルへ解決"
    ;;
  # op read / op item / op document / op run は秘密を stdout に出す、
  # または任意コマンドを実行できるため defer (通常の承認フロー) に落とす。
esac
exit 0
