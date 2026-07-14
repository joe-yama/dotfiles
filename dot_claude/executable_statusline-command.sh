#!/bin/sh
# Claude Code statusLine (最大3行表示。文脈で2〜3行目の内容が変化)
# 1行目: モデル名 / 消費トークン数(K単位) / コンテキスト残量% / セッション変更行数(+追加/-削除。Claudeが編集した行数でありgit diffではない)
# 2行目(git内のみ): 📦 リポジトリ名 / 🌿 ブランチ名(+dirty ✗ / upstreamとの ahead↑・behind↓)
# 3行目: worktree内なら 🌳 worktree名(リポ名接頭辞は除去)、git外なら 📁 フォルダ名(fish風短縮、$HOMEは~)
#        通常のgitチェックアウトでは3行目は出さない(フォルダ名は冗長なため)
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')

# $HOME を ~ に短縮
dir="$cwd"
case "$cwd" in
  "$HOME") dir="~" ;;
  "$HOME"/*) dir="~${cwd#"$HOME"}" ;;
esac

# fish風パス短縮: 末尾ディレクトリはフル、それより上の親は頭1文字に。
# 隠しディレクトリ(.config 等)は "." + 頭1文字。~ と先頭スラッシュは維持。
if [ -n "$dir" ]; then
  prefix=""
  case "$dir" in
    /*) prefix="/"; dir="${dir#/}" ;;
  esac
  dir=$(printf '%s' "$dir" | awk -v pfx="$prefix" -F/ '{
    n=NF; out=""
    for (i=1; i<n; i++) {
      c=$i
      if (c=="~") seg="~"
      else if (substr(c,1,1)=="." && length(c)>1) seg=substr(c,1,2)
      else seg=substr(c,1,1)
      out=(out=="")?seg:out"/"seg
    }
    if (n<=1) print pfx $0
    else print pfx out "/" $n
  }')
fi

# git情報(取得できる場合のみ)。lock取得はスキップする
# repo=リポジトリ名 / branch=ブランチ(detached時は @短縮SHA) / dirty / ahead・behind
# is_worktree=linked worktree判定 / wtname=worktree名(リポ名接頭辞を除去)
repo=""
branch=""
dirty=""
ahead=""
behind=""
is_worktree=""
wtname=""
if [ -n "$cwd" ]; then
  git_common=$(git --no-optional-locks -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  if [ -n "$git_common" ]; then
    # リポジトリ名 = git-common-dir(=<repo>/.git)の親のbasename。通常/worktree共通。
    repo=$(basename "$(dirname "$git_common")")

    # linked worktree判定: git-dir が git-common-dir と異なれば worktree
    git_dir=$(git --no-optional-locks -C "$cwd" rev-parse --path-format=absolute --git-dir 2>/dev/null)
    if [ -n "$git_dir" ] && [ "$git_dir" != "$git_common" ]; then
      is_worktree=1
      top=$(git --no-optional-locks -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
      wtname=$(basename "$top")
      # 先頭の "<repo><区切り>" を除去(区切りは . - _ /)。リポ名は📦で別途出るため。
      case "$wtname" in
        "$repo".*|"$repo"-*|"$repo"_*|"$repo"/*) wtname="${wtname#"$repo"?}" ;;
      esac
    fi

    branch=$(git --no-optional-locks -C "$cwd" branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then
      # detached HEAD: 短縮SHAをブランチ枠に表示
      sha=$(git --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>/dev/null)
      [ -n "$sha" ] && branch="@${sha}"
    fi

    if [ -n "$(git --no-optional-locks -C "$cwd" status --porcelain 2>/dev/null)" ]; then
      dirty=" ✗"
    fi
    # upstream との差分。左=upstream(=behind)、右=HEAD(=ahead)。upstream未設定なら空。
    ab=$(git --no-optional-locks -C "$cwd" rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null)
    if [ -n "$ab" ]; then
      behind=$(printf '%s' "$ab" | awk '{print $1}')
      ahead=$(printf '%s' "$ab" | awk '{print $2}')
    fi
  fi
fi

# 消費トークン数(K単位、取得できる場合のみ)
# total_input_tokens = input + cache_creation + cache_read の合計。remaining_percentage の算出分子と同一。
tokens_k=$(echo "$input" | jq -r '(.context_window.total_input_tokens // empty) | (./1000)' 2>/dev/null)
tok=""
if [ -n "$tokens_k" ]; then
  tok=$(printf "%.1fK" "$tokens_k" 2>/dev/null)
fi

# コンテキスト残量%(取得できる場合のみ)
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
ctx=""
if [ -n "$remaining" ]; then
  ctx=$(printf "%.0f" "$remaining" 2>/dev/null)
fi

# 消費トークン数と残量%をまとめる(例: "45.2K 73% left")
ctxpart=""
[ -n "$tok" ] && ctxpart="$tok"
if [ -n "$ctx" ]; then
  if [ -n "$ctxpart" ]; then
    ctxpart="${ctxpart} ${ctx}% left"
  else
    ctxpart="${ctx}% left"
  fi
fi

# セッション変更行数(Claudeが編集した行数。git diff の作業ツリー差分ではない)
added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# 色定義 (ANSI)
RESET=$(printf '\033[0m')
BOLD=$(printf '\033[1m')
DIM=$(printf '\033[2m')
CYAN=$(printf '\033[36m')
GREEN=$(printf '\033[1;32m')
BLUE=$(printf '\033[1;34m')
RED=$(printf '\033[31m')
YELLOW=$(printf '\033[33m')

# --- 1行目: モデル名 / トークン・残量% / セッション変更行数 ---
line1="${BOLD}${model}${RESET}"
if [ -n "$ctxpart" ]; then
  line1="${line1} ${DIM}${ctxpart}${RESET}"
fi
diffpart=""
if [ "$added" -gt 0 ] 2>/dev/null; then
  diffpart="${GREEN}+${added}${RESET}"
fi
if [ "$removed" -gt 0 ] 2>/dev/null; then
  if [ -n "$diffpart" ]; then
    diffpart="${diffpart} ${RED}-${removed}${RESET}"
  else
    diffpart="${RED}-${removed}${RESET}"
  fi
fi
[ -n "$diffpart" ] && line1="${line1} ${diffpart}"

# --- 2行目(git内のみ): 📦 リポジトリ名 / 🌿 ブランチ(+dirty +ahead/behind) ---
line2=""
if [ -n "$repo" ]; then
  line2="${BOLD}📦 ${repo}${RESET}"
  if [ -n "$branch" ]; then
    abpart=""
    if [ -n "$ahead" ] && [ "$ahead" -gt 0 ] 2>/dev/null; then
      abpart="↑${ahead}"
    fi
    if [ -n "$behind" ] && [ "$behind" -gt 0 ] 2>/dev/null; then
      abpart="${abpart}↓${behind}"
    fi
    branchseg="${GREEN}🌿 ${branch}${RESET}${YELLOW}${dirty}${RESET}"
    [ -n "$abpart" ] && branchseg="${branchseg} ${CYAN}${abpart}${RESET}"
    line2="${line2}  ${branchseg}"
  fi
fi

# --- 3行目: worktree内→🌳 worktree名 / git外→📁 フォルダ名 / 通常gitチェックアウト→なし ---
line3=""
if [ -n "$is_worktree" ] && [ -n "$wtname" ]; then
  line3="${CYAN}🌳 ${wtname}${RESET}"
elif [ -z "$repo" ] && [ -n "$dir" ]; then
  line3="${CYAN}📁 ${dir}${RESET}"
fi

# 出力(空行はスキップ)
printf '%s\n' "$line1"
[ -n "$line2" ] && printf '%s\n' "$line2"
[ -n "$line3" ] && printf '%s\n' "$line3"

exit 0
