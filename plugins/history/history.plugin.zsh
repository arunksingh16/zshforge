#!/usr/bin/env zsh
# ── plugins/history — Fix zsh history once and for all ────────

HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE=50000
SAVEHIST=50000

# ── The holy grail of history options ──────────────────────────
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
setopt HIST_NO_STORE
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY

# ── History search keybindings ─────────────────────────────────
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
bindkey "^P"   up-line-or-beginning-search
bindkey "^N"   down-line-or-beginning-search

# ── One-time dedup of existing history file ────────────────────
forge::history::dedup() {
  if [[ -f "$HISTFILE" ]]; then
    local count_before
    count_before=$(command wc -l < "$HISTFILE")
    local tmpfile
    tmpfile=$(command mktemp)
    command awk '!seen[$0]++' "$HISTFILE" > "$tmpfile" && command mv "$tmpfile" "$HISTFILE"
    local count_after
    count_after=$(command wc -l < "$HISTFILE")
    forge::ok "History deduped: ${count_before// /} → ${count_after// /} entries (removed $(( count_before - count_after )))"
  fi
}

# ── Nuke sensitive patterns from history ───────────────────────
forge::history::scrub() {
  local patterns=("password" "secret" "token" "api_key" "AWS_SECRET" "PRIVATE_KEY")
  local removed=0
  for pat in $patterns; do
    local matches
    matches=$(command grep -ci "$pat" "$HISTFILE" 2>/dev/null || echo 0)
    removed=$(( removed + matches ))
  done
  if (( removed > 0 )); then
    local tmpfile
    tmpfile=$(command mktemp)
    command grep -viE "(password|secret|token|api_key|AWS_SECRET|PRIVATE_KEY)" "$HISTFILE" > "$tmpfile"
    command mv "$tmpfile" "$HISTFILE"
    forge::ok "Scrubbed $removed potentially sensitive entries from history"
  else
    forge::ok "History clean — no sensitive patterns found"
  fi
}

# ── History stats ──────────────────────────────────────────────
forge::history::stats() {
  echo ""
  print -P "%F{81}%B── History Stats ──%b%f"
  print -P "%F{243}File:%f     $HISTFILE"
  print -P "%F{243}Entries:%f  $(command wc -l < "$HISTFILE" 2>/dev/null || echo 0)"
  print -P "%F{243}Size:%f    $(command du -h "$HISTFILE" 2>/dev/null | command cut -f1)"
  echo ""
  print -P "%F{81}%BTop 10 commands:%b%f"
  fc -l 1 | command awk '{print $2}' | command sort | command uniq -c | command sort -rn | command head -10 | while read count cmd; do
    echo "  \033[38;5;114m$(printf '%4d' $count)\033[0m  ${cmd}"
  done
  echo ""
}
