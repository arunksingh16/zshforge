#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  Theme: aurora — Gradient prompt with system vitals          ║
# ║  Shows: user@host, git, battery/load, colorful separators   ║
# ╚══════════════════════════════════════════════════════════════╝

setopt PROMPT_SUBST

_aurora_git() {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  [[ -z "$branch" ]] && return

  if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
    echo "%F{114}● ${branch}%f"
  else
    echo "%F{220}● ${branch}%f"
  fi
}

_aurora_sysinfo() {
  # Load average (1 min) — works on macOS and Linux
  local load
  if [[ -f /proc/loadavg ]]; then
    load=$(cut -d' ' -f1 /proc/loadavg)
  else
    load=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')
  fi
  [[ -n "$load" ]] && echo "%F{243}⊙${load}%f"
}

_aurora_jobs() {
  local j=$(jobs -l 2>/dev/null | wc -l | tr -d ' ')
  (( j > 0 )) && echo " %F{205}⚙${j}%f"
}

# Gradient-style separators using different colors
local sep1="%F{69}─%f"
local sep2="%F{141}─%f"
local sep3="%F{205}─%f"

PROMPT='
%F{69}┌%f %F{81}%n%f%F{243}@%f%F{141}%m%f ${sep1}${sep2}${sep3} %F{205}%~%f $(_aurora_git)$(_aurora_jobs)
%F{69}└%f %(?.%F{114}▸%f.%F{196}▸%f) '

RPROMPT='$(_aurora_sysinfo) %F{243}%D{%H:%M:%S}%f'
