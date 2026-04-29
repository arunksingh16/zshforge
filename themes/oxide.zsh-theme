#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  Theme: oxide — Minimal single-line, warm tones              ║
# ║  Clean, fast, no-nonsense                                    ║
# ╚══════════════════════════════════════════════════════════════╝

setopt PROMPT_SUBST

_oxide_git() {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  [[ -z "$branch" ]] && return
  local dirty=$(git diff --quiet 2>/dev/null || echo "*")
  echo " %F{208}${branch}${dirty}%f"
}

PROMPT='%F{173}%3~%f$(_oxide_git) %F{208}›%f '
RPROMPT='%(?.%F{243}%T%f.%F{196}✘%?%f)'
