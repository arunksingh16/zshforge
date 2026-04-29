#!/usr/bin/env zsh
# ── plugins/dirjump — Fast directory jumping with frecency ────
#
# Usage:
#   j <partial>     Jump to best matching directory
#   j               List top directories (interactive with fzf if available)
#   jl              List all tracked directories with scores
#   jclean          Remove dead directory entries
#
# DESIGN: The chpwd hook (_dirjump_track) uses ZERO external
# commands — pure zsh builtins only. This avoids the macOS/iTerm
# issue where PATH is incomplete during shell hooks, causing
# "command not found" for sort/head/rm etc.

typeset -g DIRJUMP_DATA="$ZSHFORGE_CACHE/dirjump.dat"
typeset -g DIRJUMP_MAX=500

[[ -f "$DIRJUMP_DATA" ]] || : >| "$DIRJUMP_DATA"

# ── Track directory visits (PURE ZSH — no external commands) ──
_dirjump_track() {
  local dir="$PWD"
  [[ "$dir" == "$HOME" || "$dir" == "/" ]] && return

  local now=$EPOCHSECONDS
  # Fallback if EPOCHSECONDS not available (older zsh)
  [[ -z "$now" ]] && now=0

  # Read existing data into an associative array
  typeset -A scores timestamps
  local line
  while IFS='|' read -r _s _t _p; do
    [[ -n "$_p" ]] || continue
    scores[$_p]=$_s
    timestamps[$_p]=$_t
  done < "$DIRJUMP_DATA"

  # Update current directory
  if [[ -n "${scores[$dir]}" ]]; then
    scores[$dir]=$(( scores[$dir] + 1 ))
  else
    scores[$dir]=1
  fi
  timestamps[$dir]=$now

  # Write back — pure zsh, no sort/head/rm
  # Use a temp var to build content, then redirect once
  local output=""
  local key
  for key in ${(k)scores}; do
    output+="${scores[$key]}|${timestamps[$key]}|${key}"$'\n'
  done

  # Write atomically (zsh builtin redirection)
  print -rn -- "$output" >| "$DIRJUMP_DATA"
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _dirjump_track

# ── Frecency scoring (used interactively — external cmds OK) ──
_dirjump_score() {
  local now=$EPOCHSECONDS
  [[ -z "$now" ]] && now=$(command date +%s)

  local -a results
  while IFS='|' read -r score ts path; do
    [[ -d "$path" ]] || continue

    local age=$(( now - ts ))
    local boost
    if   (( age < 3600 ));   then boost=8
    elif (( age < 86400 ));  then boost=4
    elif (( age < 604800 )); then boost=2
    else                          boost=1
    fi

    local final=$(( score * boost ))
    results+=("${final}|${path}")
  done < "$DIRJUMP_DATA"

  # Sort numerically descending using zsh parameter expansion
  # Format: "score|path" — sort by score
  local item
  for item in ${(nO)results}; do
    echo "$item"
  done
}

# ── Jump command ───────────────────────────────────────────────
j() {
  if [[ $# -eq 0 ]]; then
    if forge::has fzf; then
      local target
      target=$(_dirjump_score | command awk -F'|' '{print $2}' | fzf \
        --height=40% \
        --reverse \
        --prompt="jump → " \
        --preview="ls -la --color=always {}" \
        --preview-window=right:40%)
      [[ -n "$target" ]] && cd "$target"
    else
      echo ""
      print -P "%F{81}%B── Top Directories ──%b%f"
      local i=1 score path short_path
      _dirjump_score | command head -15 | while IFS='|' read -r score path; do
        short_path="${path/#$HOME/~}"
        echo "  \033[38;5;114m$(printf '%2d' $i)\033[0m  \033[38;5;243m$(printf '%4d' $score)\033[0m  ${short_path}"
        (( i++ ))
      done
      echo ""
      print -P "%F{243}Usage: j <pattern> to jump%f"
    fi
    return
  fi

  local query="$*"
  local target=""
  local score path
  while IFS='|' read -r score path; do
    if [[ "${path:l}" == *"${query:l}"* ]]; then
      target="$path"
      break
    fi
  done < <(_dirjump_score)

  if [[ -n "$target" ]]; then
    cd "$target"
  else
    forge::warn "No match for '$query'"
  fi
}

# ── List all tracked dirs ──────────────────────────────────────
jl() {
  echo ""
  print -P "%F{81}%B── Tracked Directories ──%b%f"
  local i=1 score path short_path
  _dirjump_score | while IFS='|' read -r score path; do
    short_path="${path/#$HOME/~}"
    echo "  \033[38;5;114m$(printf '%3d' $i)\033[0m  \033[38;5;243m$(printf '%5d' $score) pts\033[0m  ${short_path}"
    (( i++ ))
  done
  echo ""
}

# ── Cleanup dead directories (pure zsh) ───────────────────────
jclean() {
  local output="" removed=0 total=0
  while IFS='|' read -r score ts path; do
    (( total++ ))
    if [[ -d "$path" ]]; then
      output+="${score}|${ts}|${path}"$'\n'
    else
      (( removed++ ))
    fi
  done < "$DIRJUMP_DATA"

  print -rn -- "$output" >| "$DIRJUMP_DATA"
  forge::ok "Cleaned: removed ${removed} dead paths (${total} total)"
}
