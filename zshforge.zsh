#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════╗
# ║  ZshForge — A minimal, fast zsh framework                   ║
# ║  https://github.com/arunksingh16/zshforge                       ║
# ╚══════════════════════════════════════════════════════════════╝

export ZSHFORGE_HOME="${ZSHFORGE_HOME:-${0:A:h}}"
export ZSHFORGE_CACHE="${ZSHFORGE_CACHE:-$HOME/.cache/zshforge}"
export ZSHFORGE_CONFIG="${ZSHFORGE_CONFIG:-$HOME/.config/zshforge}"

# Create dirs if missing
[[ -d "$ZSHFORGE_CACHE" ]]  || mkdir -p "$ZSHFORGE_CACHE"
[[ -d "$ZSHFORGE_CONFIG" ]] || mkdir -p "$ZSHFORGE_CONFIG"

# ── Startup timer (measures framework load time) ───────────────
typeset -g ZSHFORGE_START_MS
if (( $+commands[perl] )); then
  ZSHFORGE_START_MS=$(perl -MTime::HiRes=time -e 'printf "%.0f", time*1000')
elif (( $+commands[python3] )); then
  ZSHFORGE_START_MS=$(python3 -c 'import time; print(int(time.time()*1000))')
else
  ZSHFORGE_START_MS=$EPOCHREALTIME
fi

# ── Load config ────────────────────────────────────────────────
[[ -f "$ZSHFORGE_CONFIG/config.zsh" ]] && source "$ZSHFORGE_CONFIG/config.zsh"

# Defaults
: ${ZSHFORGE_THEME:=nebula}
: ${ZSHFORGE_PLUGINS:=history dirjump}

# ── Load core library ──────────────────────────────────────────
for _lib_file in "$ZSHFORGE_HOME"/lib/*.zsh(N); do
  source "$_lib_file"
done
unset _lib_file

# ── Load plugins ───────────────────────────────────────────────
for _plugin in ${(s: :)ZSHFORGE_PLUGINS}; do
  _plugin_file="$ZSHFORGE_HOME/plugins/${_plugin}/${_plugin}.plugin.zsh"
  if [[ -f "$_plugin_file" ]]; then
    source "$_plugin_file"
  fi
done
unset _plugin _plugin_file

# ── Load theme ─────────────────────────────────────────────────
_theme_file="$ZSHFORGE_HOME/themes/${ZSHFORGE_THEME}.zsh-theme"
if [[ -f "$_theme_file" ]]; then
  source "$_theme_file"
else
  echo "\033[33m[zshforge]\033[0m theme '$ZSHFORGE_THEME' not found, falling back to nebula"
  source "$ZSHFORGE_HOME/themes/nebula.zsh-theme"
fi
unset _theme_file

# ── Load the forge CLI ─────────────────────────────────────────
source "$ZSHFORGE_HOME/bin/forge.zsh"

# ── Startup time report ────────────────────────────────────────
if (( $+commands[perl] )); then
  _end_ms=$(perl -MTime::HiRes=time -e 'printf "%.0f", time*1000')
elif (( $+commands[python3] )); then
  _end_ms=$(python3 -c 'import time; print(int(time.time()*1000))')
else
  _end_ms=$EPOCHREALTIME
fi
typeset -g ZSHFORGE_LOAD_MS=$(( _end_ms - ZSHFORGE_START_MS ))
unset _end_ms
# ── Startup banner ─────────────────────────────────────────────
() {
  local v="0.2.0"
  local c1="\033[38;5;81m"  c2="\033[38;5;141m"  c3="\033[38;5;114m"
  local d="\033[38;5;243m"  b="\033[1m"  r="\033[0m"

  echo ""
  echo "${c1}${b}⚡ zshforge${r} ${d}v${v}${r}  ${d}─${r}  ${c2}${ZSHFORGE_THEME}${r} ${d}theme${r}  ${d}·${r}  ${c3}${ZSHFORGE_LOAD_MS}ms${r}"
  echo "${d}  plugins: ${r}${ZSHFORGE_PLUGINS// / · }  ${d}│${r}  ${d}forge help${r}"
  echo ""
}