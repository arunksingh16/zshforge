#!/usr/bin/env zsh
# ── lib/core.zsh — Shared utilities ───────────────────────────

# Color helpers (256-color)
typeset -gA FORGE_COLORS
FORGE_COLORS=(
  reset    $'\033[0m'
  bold     $'\033[1m'
  dim      $'\033[2m'
  red      $'\033[38;5;196m'
  orange   $'\033[38;5;208m'
  yellow   $'\033[38;5;220m'
  green    $'\033[38;5;114m'
  cyan     $'\033[38;5;81m'
  blue     $'\033[38;5;69m'
  purple   $'\033[38;5;141m'
  pink     $'\033[38;5;205m'
  gray     $'\033[38;5;243m'
  white    $'\033[38;5;255m'
  bg_dark  $'\033[48;5;235m'
)

# Logging
forge::log()   { print -P "%F{81}[forge]%f $1" }
forge::warn()  { print -P "%F{220}[forge]%f $1" }
forge::error() { print -P "%F{196}[forge]%f $1" }
forge::ok()    { print -P "%F{114}[forge]%f $1" }

# Check if command exists
forge::has() { (( $+commands[$1] )) }

# Benchmark a command
forge::bench() {
  local start end
  start=$(perl -MTime::HiRes=time -e 'printf "%.0f", time*1000' 2>/dev/null || echo 0)
  eval "$@"
  end=$(perl -MTime::HiRes=time -e 'printf "%.0f", time*1000' 2>/dev/null || echo 0)
  forge::log "⏱  $(( end - start ))ms"
}
