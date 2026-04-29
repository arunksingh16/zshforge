#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  Theme: nebula — Colorful informational two-line prompt      ║
# ║  Features: git branch/status, exit code, load time, path    ║
# ╚══════════════════════════════════════════════════════════════╝

setopt PROMPT_SUBST

# ── Git info (fast — uses porcelain for speed) ─────────────────
_forge_git_info() {
  # Bail fast if not in a git repo
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  [[ -z "$branch" ]] && return

  local dirty=""
  local staged=""
  local untracked=""
  local ahead=""
  local behind=""

  # Use git status porcelain for speed
  local status_output=$(git status --porcelain=v2 --branch 2>/dev/null)

  # Check for changes
  echo "$status_output" | grep -q "^[12]" && dirty="±"
  echo "$status_output" | grep -q "^?" && untracked="…"

  # Ahead/behind
  local ab=$(echo "$status_output" | grep "^# branch.ab" | awk '{print $3, $4}')
  if [[ -n "$ab" ]]; then
    local a=$(echo "$ab" | awk '{print $1}')
    local b=$(echo "$ab" | awk '{print $2}')
    [[ "$a" != "+0" ]] && ahead="%F{114}${a}%f"
    [[ "$b" != "-0" ]] && behind="%F{196}${b}%f"
  fi

  local indicators="${dirty}${untracked}"
  local ab_info=""
  [[ -n "$ahead$behind" ]] && ab_info=" ${ahead}${behind}"

  if [[ -n "$indicators" ]]; then
    echo " %F{208}⎇ ${branch}%f%F{220}${indicators}%f${ab_info}"
  else
    echo " %F{114}⎇ ${branch}%f%F{243}✓%f${ab_info}"
  fi
}

# ── Path shortening ────────────────────────────────────────────
_forge_short_path() {
  local full="${PWD/#$HOME/~}"
  # If path has more than 3 segments, collapse middle ones
  local parts=("${(@s:/:)full}")
  if (( ${#parts} > 4 )); then
    echo "${parts[1]}/${parts[2]}/…/${parts[-2]}/${parts[-1]}"
  else
    echo "$full"
  fi
}

# ── Exit code indicator ───────────────────────────────────────
_forge_exit_code() {
  local code=$?
  if (( code != 0 )); then
    echo "%F{196}✘ ${code}%f "
  fi
}

# ── Prompt construction ───────────────────────────────────────
# Line 1: path + git info
# Line 2: arrow prompt
_forge_prompt() {
  local exit_indicator='$(_forge_exit_code)'
  local path_part='%F{81}$(_forge_short_path)%f'
  local git_part='$(_forge_git_info)'
  local time_part='%F{243}%T%f'

  # Line 1: info bar
  local line1="${path_part}${git_part} ${time_part}"

  # Line 2: prompt arrow (changes color on error)
  local arrow='%(?.%F{141}❯%f.%F{196}❯%f)'

  PROMPT="
${line1}
${exit_indicator}${arrow} "

  # Right prompt: load time on first render, then blank
  RPROMPT='%F{243}${ZSHFORGE_LOAD_MS:+⚡${ZSHFORGE_LOAD_MS}ms}%f'
}

_forge_prompt

# Clear load time after first prompt so it doesn't persist
_forge_clear_loadtime() {
  unset ZSHFORGE_LOAD_MS
  add-zsh-hook -d precmd _forge_clear_loadtime
}
autoload -U add-zsh-hook
add-zsh-hook precmd _forge_clear_loadtime
