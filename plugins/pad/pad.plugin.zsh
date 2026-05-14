#!/usr/bin/env zsh
# ── plugins/pad — Per-directory snippet list ──────────────────
#
# Usage:
#   forge pad              Browse snippets for current dir (fzf or numbered list)
#   forge pad -g           Browse ALL snippets across all directories
#   forge pad add "lbl" "cmd" [-d "desc"]   Add snippet for current dir
#   forge pad add -g "lbl" "cmd"            Add global (dir-independent) snippet
#   forge pad rm           Remove a snippet (fzf or numbered list)
#   forge pad ls           List current dir snippets inline
#   forge pad hint [on|off]  Toggle cd hint — prints count on entering a dir
#   forge pad help         Show usage
#
# DESIGN: Zero startup overhead. The chpwd hint hook returns immediately
# when disabled (flag file absent) — one file-exist test per cd, nothing more.
# Data is stored as tab-separated records in ~/.cache/zshforge/pad.dat
#
# Data format (one record per line):
#   <epoch_id>\t<dir>\t<label>\t<command>\t<desc>
#   dir = $PWD, or "_global_" for non-directory snippets

zmodload zsh/datetime 2>/dev/null

typeset -g PAD_DATA="$ZSHFORGE_CACHE/pad.dat"
typeset -g PAD_HINT_FLAG="$ZSHFORGE_CACHE/pad_hint_enabled"

[[ -f "$PAD_DATA" ]] || : >| "$PAD_DATA"

# ── Add a snippet ──────────────────────────────────────────────
_pad_add() {
  local dir="$PWD" desc=""

  if [[ "${1:-}" == "-g" ]]; then
    dir="_global_"
    shift
  fi

  local label="${1:-}"
  local cmd="${2:-}"

  if [[ -z "$label" || -z "$cmd" ]]; then
    forge::error "Usage: forge pad add [-g] \"label\" \"command\" [-d \"desc\"]"
    return 1
  fi
  shift 2

  if [[ "${1:-}" == "-d" && -n "${2:-}" ]]; then
    desc="$2"
  fi

  local id=$EPOCHSECONDS
  printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$dir" "$label" "$cmd" "$desc" >> "$PAD_DATA"

  local scope
  [[ "$dir" == "_global_" ]] && scope="global" || scope="${dir/#$HOME/~}"
  forge::ok "Added: \033[38;5;255m${label}\033[0m  \033[38;5;243m→  ${cmd}\033[0m"
  forge::log "Scope: ${scope}"
}

# ── Remove a snippet ───────────────────────────────────────────
_pad_rm() {
  if [[ ! -s "$PAD_DATA" ]]; then
    forge::warn "No snippets saved yet"
    return
  fi

  local del_id

  if forge::has fzf; then
    local entry
    entry=$(command awk -F'\t' -v home="$HOME" '{
      dir = $2
      if (dir == "_global_") dir = "[global]"
      else gsub(home, "~", dir)
      print $1 "\t" dir "\t" $3 "\t" $4
    }' "$PAD_DATA" | fzf \
      --height=40% \
      --reverse \
      --prompt="remove → " \
      --delimiter=$'\t' \
      --with-nth=2,3,4 \
      --header="Select snippet to remove  (ESC to cancel)" \
      --color=prompt:196,header:243)

    [[ -z "$entry" ]] && return
    del_id="${entry%%$'\t'*}"
  else
    echo ""
    print -P "%F{81}%B── Remove Snippet ──%b%f"
    echo ""
    local -a ids
    local i=1
    while IFS=$'\t' read -r id dir lbl cmd desc; do
      local short="${dir/#$HOME/~}"
      [[ "$dir" == "_global_" ]] && short="[global]"
      echo "  \033[38;5;141m${i}\033[0m  \033[38;5;255m${lbl}\033[0m  \033[38;5;243m→ ${cmd}\033[0m  \033[38;5;243m(${short})\033[0m"
      ids+=("$id")
      (( i++ ))
    done < "$PAD_DATA"
    echo ""
    echo -n "  \033[38;5;243mSelect [1-$((i-1))], or 0 to cancel:\033[0m "
    read -r choice
    [[ "$choice" == "0" || -z "$choice" ]] && return
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice < i )); then
      del_id="${ids[$choice]}"
    else
      forge::warn "Invalid selection"
      return 1
    fi
  fi

  local tmpfile="${PAD_DATA}.tmp"
  command awk -F'\t' -v id="$del_id" '$1 != id' "$PAD_DATA" >| "$tmpfile" \
    && command mv "$tmpfile" "$PAD_DATA"
  forge::ok "Snippet removed"
}

# ── Browse current directory snippets ─────────────────────────
_pad_pick() {
  if [[ ! -s "$PAD_DATA" ]]; then
    forge::warn "No snippets yet — add one: forge pad add \"label\" \"command\""
    return
  fi

  local dir_entries
  dir_entries=$(command awk -F'\t' -v d="$PWD" '$2 == d' "$PAD_DATA")

  if [[ -z "$dir_entries" ]]; then
    forge::warn "No snippets for \033[38;5;255m${PWD/#$HOME/~}\033[0m"
    forge::log "Add one:     forge pad add \"label\" \"command\""
    forge::log "Browse all:  forge pad -g"
    return
  fi

  local cmd

  if forge::has fzf; then
    # Transform to: id\tlabel\tcmd\tdesc  (drop dir field)
    local selected
    selected=$(echo "$dir_entries" \
      | command awk -F'\t' '{print $1 "\t" $3 "\t" $4 "\t" $5}' \
      | fzf \
          --height=50% \
          --reverse \
          --prompt="pad → " \
          --delimiter=$'\t' \
          --with-nth=2,3 \
          --preview='printf "\033[1;38;5;255m%s\033[0m\n\n\033[38;5;81mCommand:\033[0m\n  %s\n\n\033[38;5;243m%s\033[0m\n" {2} {3} {4}' \
          --preview-window=right:45%:wrap \
          --color=prompt:81,header:243)
    [[ -z "$selected" ]] && return
    cmd=$(echo "$selected" | cut -d$'\t' -f3)
  else
    _pad_numbered_pick "$dir_entries"
    return
  fi

  [[ -n "$cmd" ]] && print -z -- "$cmd"
}

# ── Browse all snippets across all directories ────────────────
_pad_global() {
  if [[ ! -s "$PAD_DATA" ]]; then
    forge::warn "No snippets yet — add one: forge pad add \"label\" \"command\""
    return
  fi

  local cmd

  if forge::has fzf; then
    # Transform to: id\t[~/dir]\tlabel\tcmd\tdesc
    local selected
    selected=$(command awk -F'\t' -v home="$HOME" '{
      dir = $2
      if (dir == "_global_") dir = "[global]"
      else gsub(home, "~", dir)
      print $1 "\t" dir "\t" $3 "\t" $4 "\t" $5
    }' "$PAD_DATA" | fzf \
      --height=60% \
      --reverse \
      --prompt="pad (all) → " \
      --delimiter=$'\t' \
      --with-nth=2,3,4 \
      --preview='printf "\033[38;5;81m%s\033[0m\n\n\033[1;38;5;255m%s\033[0m\n\n\033[38;5;81mCommand:\033[0m\n  %s\n\n\033[38;5;243m%s\033[0m\n" {2} {3} {4} {5}' \
      --preview-window=right:45%:wrap \
      --color=prompt:205,header:243)
    [[ -z "$selected" ]] && return
    cmd=$(echo "$selected" | cut -d$'\t' -f4)
  else
    _pad_numbered_pick "$(<"$PAD_DATA")"
    return
  fi

  [[ -n "$cmd" ]] && print -z -- "$cmd"
}

# ── Numbered list picker — fallback when fzf is absent ────────
# $1 = newline-separated snippet data (full 5-field format)
_pad_numbered_pick() {
  local data="$1"
  echo ""
  print -P "%F{81}%B── Snippets ──%b%f"
  echo ""
  local i=1
  local -a cmds
  while IFS=$'\t' read -r id dir lbl cmd desc; do
    local short="${dir/#$HOME/~}"
    [[ "$dir" == "_global_" ]] && short="[global]"
    echo "  \033[38;5;141m$(printf '%2d' $i)\033[0m  \033[38;5;243m${short}\033[0m"
    echo "      \033[38;5;255m${lbl}\033[0m  \033[38;5;243m→ ${cmd}\033[0m"
    [[ -n "$desc" ]] && echo "      \033[38;5;243m${desc}\033[0m"
    cmds+=("$cmd")
    (( i++ ))
  done <<< "$data"
  echo ""
  echo -n "  \033[38;5;243mSelect [1-$((i-1))], or 0 to cancel:\033[0m "
  read -r choice
  [[ "$choice" == "0" || -z "$choice" ]] && return
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice < i )); then
    print -z -- "${cmds[$choice]}"
  else
    forge::warn "Invalid selection"
  fi
}

# ── List current dir snippets inline (no fzf) ─────────────────
_pad_ls() {
  local count=0
  local short_pwd="${PWD/#$HOME/~}"
  echo ""
  print -P "%F{81}%B── Snippets: ${short_pwd} ──%b%f"
  echo ""
  while IFS=$'\t' read -r id dir lbl cmd desc; do
    [[ "$dir" != "$PWD" ]] && continue
    echo "  \033[38;5;141m●\033[0m  \033[38;5;255m${lbl}\033[0m"
    echo "     \033[38;5;81m→\033[0m  ${cmd}"
    [[ -n "$desc" ]] && echo "     \033[38;5;243m${desc}\033[0m"
    echo ""
    (( count++ ))
  done < "$PAD_DATA"
  if (( count == 0 )); then
    forge::warn "No snippets for this directory"
    forge::log "Add one: forge pad add \"label\" \"command\""
  else
    print -P "%F{243}${count} snippet(s) — forge pad to browse%f"
  fi
  echo ""
}

# ── Hint hook (chpwd) — prints snippet count on directory change ──
# Cost when hint is OFF: one [[ -f ]] test per cd. Essentially free.
_pad_hint_hook() {
  [[ -f "$PAD_HINT_FLAG" ]] || return
  [[ -s "$PAD_DATA" ]]       || return
  local count
  count=$(command awk -F'\t' -v d="$PWD" 'BEGIN{c=0} $2==d{c++} END{print c}' "$PAD_DATA" 2>/dev/null)
  (( count > 0 )) && echo "\033[38;5;243m» pad: ${count} snippet(s) here — forge pad to browse\033[0m"
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _pad_hint_hook

# ── Hint toggle ────────────────────────────────────────────────
_pad_hint_toggle() {
  case "${1:-}" in
    on)
      touch "$PAD_HINT_FLAG"
      forge::ok "Pad hint enabled — snippet count shown when entering a directory"
      ;;
    off)
      rm -f "$PAD_HINT_FLAG"
      forge::ok "Pad hint disabled"
      ;;
    *)
      if [[ -f "$PAD_HINT_FLAG" ]]; then
        forge::log "Hint: \033[38;5;114mon\033[0m  (run: forge pad hint off)"
      else
        forge::log "Hint: \033[38;5;243moff\033[0m  (run: forge pad hint on)"
      fi
      ;;
  esac
}

# ── Help ───────────────────────────────────────────────────────
_pad_help() {
  echo ""
  print -P "%F{81}%B── Pad — Directory Snippet List ──%b%f"
  echo ""
  print -P "  %F{141}forge pad%f                         %F{243}Browse snippets for current dir%f"
  print -P "  %F{141}forge pad -g%f                      %F{243}Browse all snippets (all dirs)%f"
  print -P "  %F{141}forge pad add \"lbl\" \"cmd\"%f        %F{243}Add snippet for current directory%f"
  print -P "  %F{141}forge pad add -g \"lbl\" \"cmd\"%f     %F{243}Add global snippet (no dir binding)%f"
  print -P "  %F{141}forge pad add ... -d \"desc\"%f       %F{243}Add snippet with a short description%f"
  print -P "  %F{141}forge pad rm%f                      %F{243}Remove a snippet (fzf picker)%f"
  print -P "  %F{141}forge pad ls%f                      %F{243}List current dir snippets inline%f"
  print -P "  %F{141}forge pad hint [on|off]%f            %F{243}Toggle cd hint (off by default)%f"
  echo ""
  print -P "  %F{243}Snippets are pasted to your prompt — not auto-run%f"
  echo ""
}

# ── Main dispatcher ────────────────────────────────────────────
pad() {
  case "${1:-}" in
    "")              _pad_pick ;;
    -g)              _pad_global ;;
    add)             shift; _pad_add "$@" ;;
    rm|remove)       _pad_rm ;;
    ls|list)         _pad_ls ;;
    hint)            shift; _pad_hint_toggle "${1:-}" ;;
    help|--help|-h)  _pad_help ;;
    *)
      forge::error "Unknown subcommand: pad ${1}"
      _pad_help
      return 1
      ;;
  esac
}
