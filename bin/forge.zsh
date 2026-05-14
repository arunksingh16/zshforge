#!/usr/bin/env zsh
# ── bin/forge.zsh — The ZshForge CLI ──────────────────────────

forge() {
  local cmd="${1:-help}"
  shift 2>/dev/null

  case "$cmd" in
    theme)    _forge_cmd_theme "$@" ;;
    plugins)  _forge_cmd_plugins "$@" ;;
    doctor)   _forge_cmd_doctor "$@" ;;
    bench)    _forge_cmd_bench "$@" ;;
    update)   _forge_cmd_update "$@" ;;
    edit)     _forge_cmd_edit "$@" ;;
    pad)
      if (( $+functions[pad] )); then
        pad "$@"
      else
        forge::error "pad plugin not loaded"
        forge::log "Add 'pad' to ZSHFORGE_PLUGINS in config (run: forge edit)"
      fi
      ;;
    help|*)   _forge_cmd_help "$@" ;;
  esac
}

# ── ANSI color helpers (safe with echo, unlike %F which only works in print -P) ──
_c()  { echo -ne "\033[38;5;${1}m"; }
_cb() { echo -ne "\033[1;38;5;${1}m"; }
_cr() { echo -ne "\033[0m"; }

# ── Theme management ──────────────────────────────────────────
_forge_cmd_theme() {
  local subcmd="${1:-}"

  if [[ -z "$subcmd" ]]; then
    _forge_theme_picker
    return
  fi

  case "$subcmd" in
    preview) _forge_theme_preview ;;
    list)    _forge_theme_list ;;
    *)
      local theme_file="$ZSHFORGE_HOME/themes/${subcmd}.zsh-theme"
      if [[ -f "$theme_file" ]]; then
        _forge_apply_theme "$subcmd"
      else
        forge::error "Theme '${subcmd}' not found"
        _forge_theme_list
      fi
      ;;
  esac
}

_forge_theme_list() {
  echo ""
  print -P "%F{81}%B── Available Themes ──%b%f"
  echo ""
  local i=1 name marker
  for theme_file in "$ZSHFORGE_HOME"/themes/*.zsh-theme(N); do
    name="${${theme_file:t}%.zsh-theme}"
    marker=""
    [[ "$name" == "$ZSHFORGE_THEME" ]] && marker=" \033[38;5;114m◀ active\033[0m"
    echo "  \033[38;5;141m${i}\033[0m  \033[38;5;255m${name}\033[0m${marker}"
    (( i++ ))
  done
  echo ""
}

_forge_theme_preview() {
  echo ""
  print -P "%F{81}%B── Theme Previews ──%b%f"

  local name marker
  for theme_file in "$ZSHFORGE_HOME"/themes/*.zsh-theme(N); do
    name="${${theme_file:t}%.zsh-theme}"
    echo ""
    echo "\033[1;38;5;220m${name}\033[0m \033[38;5;243m─────────────────\033[0m"

    command sed -n '/^# ║/s/^# ║  //p' "$theme_file" | command head -2 | while read -r line; do
      echo "  \033[38;5;243m${line}\033[0m"
    done

    marker=""
    [[ "$name" == "$ZSHFORGE_THEME" ]] && marker=" \033[38;5;114m(active)\033[0m"
    echo "  \033[38;5;141mforge theme ${name}\033[0m${marker}"
  done
  echo ""
}

_forge_theme_picker() {
  echo ""
  print -P "%F{81}%B── Pick a Theme ──%b%f"
  echo ""

  local -a themes
  local i=1
  local name color desc active
  for theme_file in "$ZSHFORGE_HOME"/themes/*.zsh-theme(N); do
    name="${${theme_file:t}%.zsh-theme}"
    themes+=("$name")
    active=""
    [[ "$name" == "$ZSHFORGE_THEME" ]] && active=" \033[38;5;114m◀\033[0m"

    case "$name" in
      nebula)   color=81  ;;
      oxide)    color=208 ;;
      aurora)   color=205 ;;
      stealth)  color=243 ;;
      *)        color=255 ;;
    esac

    case "$name" in
      nebula)   desc="Colorful two-line with git + time" ;;
      oxide)    desc="Minimal single-line, warm tones" ;;
      aurora)   desc="Gradient with system vitals" ;;
      stealth)  desc="Monochrome, distraction-free" ;;
      *)        desc="Custom theme" ;;
    esac

    echo "  \033[1;38;5;${color}m${i}\033[0m  \033[38;5;${color}m${name}\033[0m  \033[38;5;243m─ ${desc}\033[0m${active}"
    (( i++ ))
  done

  echo ""
  echo -n "  \033[38;5;243mSelect [1-${#themes}]:\033[0m "
  read -r choice

  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#themes} )); then
    _forge_apply_theme "${themes[$choice]}"
  else
    forge::warn "Invalid selection"
  fi
}

_forge_apply_theme() {
  local name="$1"
  local theme_file="$ZSHFORGE_HOME/themes/${name}.zsh-theme"

  ZSHFORGE_THEME="$name"
  source "$theme_file"
  _forge_save_config

  forge::ok "Switched to theme: \033[1;38;5;255m${name}\033[0m"
}

# ── Plugin management ─────────────────────────────────────────
_forge_cmd_plugins() {
  echo ""
  print -P "%F{81}%B── Active Plugins ──%b%f"
  echo ""
  local plugin_file name
  for plugin in ${(s: :)ZSHFORGE_PLUGINS}; do
    plugin_file="$ZSHFORGE_HOME/plugins/${plugin}/${plugin}.plugin.zsh"
    if [[ -f "$plugin_file" ]]; then
      echo "  \033[38;5;114m●\033[0m  \033[38;5;255m${plugin}\033[0m"
    else
      echo "  \033[38;5;196m○\033[0m  \033[38;5;243m${plugin} (not found)\033[0m"
    fi
  done
  echo ""

  print -P "%F{243}Available plugins:%f"
  for dir in "$ZSHFORGE_HOME"/plugins/*(N/); do
    name="${dir:t}"
    if [[ " $ZSHFORGE_PLUGINS " == *" $name "* ]]; then
      continue
    fi
    echo "  \033[38;5;243m○  ${name}\033[0m"
  done
  echo ""
}

# ── Doctor — health check ─────────────────────────────────────
_forge_cmd_doctor() {
  echo ""
  print -P "%F{81}%B── ZshForge Doctor ──%b%f"
  echo ""

  print -P "  %F{243}zsh version:%f    ${ZSH_VERSION}"
  print -P "  %F{243}forge home:%f     ${ZSHFORGE_HOME}"
  print -P "  %F{243}theme:%f          ${ZSHFORGE_THEME}"
  print -P "  %F{243}plugins:%f        ${ZSHFORGE_PLUGINS}"

  if [[ -f "$HISTFILE" ]]; then
    local hist_count=$(command wc -l < "$HISTFILE" | command tr -d ' ')
    local hist_dupes=$(command sort "$HISTFILE" | command uniq -d | command wc -l | command tr -d ' ')
    if (( hist_dupes > 0 )); then
      print -P "  %F{220}history:%f        ${hist_count} entries (%F{220}${hist_dupes} dupes%f — run %F{141}forge::history::dedup%f)"
    else
      print -P "  %F{114}history:%f        %F{114}${hist_count} entries, clean ✓%f"
    fi
  fi

  echo ""
  print -P "%F{81}%BChecks:%b%f"

  if [[ -o SHARE_HISTORY ]]; then
    print -P "  %F{114}✓%f  SHARE_HISTORY enabled"
  else
    print -P "  %F{196}✘%f  SHARE_HISTORY disabled — history won't sync across tabs"
  fi

  if [[ -o HIST_IGNORE_ALL_DUPS ]]; then
    print -P "  %F{114}✓%f  HIST_IGNORE_ALL_DUPS enabled"
  else
    print -P "  %F{196}✘%f  HIST_IGNORE_ALL_DUPS disabled — duplicates will accumulate"
  fi

  if forge::has fzf; then
    print -P "  %F{114}✓%f  fzf found — enhanced dir jumping active"
  else
    print -P "  %F{220}○%f  fzf not found — install for better %F{141}j%f experience"
  fi

  if forge::has git; then
    print -P "  %F{114}✓%f  git found"
  else
    print -P "  %F{196}✘%f  git not found"
  fi

  echo ""
}

# ── Benchmark ─────────────────────────────────────────────────
_forge_cmd_bench() {
  echo ""
  print -P "%F{81}%B── Startup Benchmark (5 runs) ──%b%f"
  echo ""

  local total=0
  for i in {1..5}; do
    local ms
    ms=$(zsh -c '
      start=$(perl -MTime::HiRes=time -e "printf \"%.0f\", time*1000" 2>/dev/null)
      zsh -i -c exit 2>/dev/null
      end=$(perl -MTime::HiRes=time -e "printf \"%.0f\", time*1000" 2>/dev/null)
      echo $(( end - start ))
    ' 2>/dev/null)
    [[ -z "$ms" || "$ms" == "0" ]] && ms="?"
    echo "  run ${i}: \033[38;5;114m${ms}ms\033[0m"
    [[ "$ms" != "?" ]] && total=$(( total + ms ))
  done

  if (( total > 0 )); then
    local avg=$(( total / 5 ))
    echo ""
    echo "  avg: \033[38;5;220m${avg}ms\033[0m"
    if (( avg < 50 )); then
      print -P "  %F{114}Lightning fast ⚡%f"
    elif (( avg < 150 )); then
      print -P "  %F{220}Good, room to improve%f"
    else
      print -P "  %F{196}Slow — check plugins and .zshrc%f"
    fi
  fi
  echo ""
}

# ── Update ────────────────────────────────────────────────────
_forge_cmd_update() {
  if [[ -d "$ZSHFORGE_HOME/.git" ]]; then
    forge::log "Updating ZshForge..."
    (cd "$ZSHFORGE_HOME" && git pull --rebase)
    forge::ok "Updated. Restart shell to apply."
  else
    forge::warn "Not a git repo — update manually"
  fi
}

# ── Edit config ───────────────────────────────────────────────
_forge_cmd_edit() {
  local config_file="$ZSHFORGE_CONFIG/config.zsh"
  if [[ ! -f "$config_file" ]]; then
    _forge_save_config
  fi
  ${EDITOR:-vim} "$config_file"
  forge::ok "Config saved. Run 'exec zsh' to reload."
}

# ── Save config ───────────────────────────────────────────────
_forge_save_config() {
  cat > "$ZSHFORGE_CONFIG/config.zsh" <<EOF
# ZshForge Configuration
# Generated on $(date)

# Theme: nebula | oxide | aurora | stealth
ZSHFORGE_THEME="${ZSHFORGE_THEME}"

# Plugins (space-separated)
ZSHFORGE_PLUGINS="${ZSHFORGE_PLUGINS}"
EOF
}

# ── Help ──────────────────────────────────────────────────────
_forge_cmd_help() {
  echo ""
  print -P "%F{81}%B╔══════════════════════════════════════╗%b%f"
  print -P "%F{81}%B║%b%f  %F{255}%BZshForge%b%f %F{243}— minimal zsh framework%f  %F{81}%B║%b%f"
  print -P "%F{81}%B╚══════════════════════════════════════╝%b%f"
  echo ""
  print -P "  %F{141}forge theme%f            %F{243}Interactive theme picker%f"
  print -P "  %F{141}forge theme <name>%f     %F{243}Switch theme directly%f"
  print -P "  %F{141}forge theme preview%f    %F{243}Preview all themes%f"
  print -P "  %F{141}forge plugins%f          %F{243}List plugins%f"
  print -P "  %F{141}forge doctor%f           %F{243}Health check + diagnostics%f"
  print -P "  %F{141}forge bench%f            %F{243}Benchmark startup time%f"
  print -P "  %F{141}forge edit%f             %F{243}Edit config in \$EDITOR%f"
  print -P "  %F{141}forge update%f           %F{243}Update framework (git)%f"
  echo ""
  print -P "  %F{81}Plugins:%f"
  print -P "  %F{141}j <pattern>%f            %F{243}Jump to directory%f"
  print -P "  %F{141}jl%f                     %F{243}List tracked directories%f"
  print -P "  %F{141}jclean%f                 %F{243}Remove dead directory entries%f"
  print -P "  %F{141}forge::history::dedup%f   %F{243}Remove duplicate history entries%f"
  print -P "  %F{141}forge::history::scrub%f   %F{243}Remove sensitive entries from history%f"
  print -P "  %F{141}forge::history::stats%f   %F{243}Show history statistics%f"
  print -P "  %F{141}forge pad%f              %F{243}Browse per-directory command snippets%f"
  print -P "  %F{141}forge pad add%f          %F{243}Add a snippet for current directory%f"
  print -P "  %F{141}forge pad help%f         %F{243}Full pad usage%f"
  echo ""
  print -P "  %F{243}Tip: prefix a command with a space to keep it out of history%f"
  echo ""
}
