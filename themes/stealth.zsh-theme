#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  Theme: stealth — Monochrome with a single accent color      ║
# ║  For when you want focus, not decoration                     ║
# ╚══════════════════════════════════════════════════════════════╝

setopt PROMPT_SUBST

_stealth_git() {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  [[ -z "$branch" ]] && return
  local dirty=$(git diff --quiet 2>/dev/null || echo "•")
  echo " %F{243}[${branch}${dirty}]%f"
}

PROMPT='%F{243}%2~%f$(_stealth_git) %F{255}λ%f '
RPROMPT='%(?.%F{236}%T%f.%F{196}%? ✕%f)'
