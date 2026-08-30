#!/bin/bash
# PreToolUse permission gate — gh api と op を対象。
# allow: 読み取り (GET) / ask: 変更系 / 出力なし: 通常フローに defer
set -euo pipefail

input=$(cat)
tool=$(jq -r '.tool_name // ""' <<<"$input")
[ "$tool" = "Bash" ] || exit 0
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")

decide() {
  jq -n --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
  exit 0
}

# フックはルールと違い複合コマンドを分解前の生文字列で受け取る。
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
