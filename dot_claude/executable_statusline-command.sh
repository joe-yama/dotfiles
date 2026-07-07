#!/bin/sh
# Claude Code statusLine - Oh My Zsh robbyrussell 風
# 表示項目: モデル名 / カレントディレクトリ($HOMEは~に短縮) / gitブランチ(色付き矢印付き、取得できる場合のみ) / 消費トークン数(K単位) / コンテキスト残量%
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')

# $HOME を ~ に短縮
dir="$cwd"
case "$cwd" in
  "$HOME") dir="~" ;;
  "$HOME"/*) dir="~${cwd#"$HOME"}" ;;
esac

# gitブランチ(取得できる場合のみ)。lock取得はスキップする
branch=""
dirty=""
if [ -n "$cwd" ]; then
  git_branch=$(git --no-optional-locks -C "$cwd" branch --show-current 2>/dev/null)
  if [ -n "$git_branch" ]; then
    branch="$git_branch"
    if [ -n "$(git --no-optional-locks -C "$cwd" status --porcelain 2>/dev/null)" ]; then
      dirty=" ✗"
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

# 色定義 (ANSI)
RESET=$(printf '\033[0m')
BOLD=$(printf '\033[1m')
DIM=$(printf '\033[2m')
CYAN=$(printf '\033[36m')
GREEN=$(printf '\033[1;32m')
BLUE=$(printf '\033[1;34m')
RED=$(printf '\033[31m')
YELLOW=$(printf '\033[33m')

out="${BOLD}${model}${RESET}"
[ -n "$dir" ] && out="${out} ${CYAN}${dir}${RESET}"

if [ -n "$branch" ]; then
  out="${out} ${GREEN}➜${RESET} ${BLUE}git:(${RED}${branch}${BLUE})${YELLOW}${dirty}${RESET}"
fi

if [ -n "$ctxpart" ]; then
  out="${out} ${DIM}${ctxpart}${RESET}"
fi

printf '%s\n' "$out"
