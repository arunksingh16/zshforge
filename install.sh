#!/usr/bin/env zsh
# ── ZshForge Installer ────────────────────────────────────────
#
# Usage:
#   git clone https://github.com/arunksingh16/zshforge ~/.zshforge
#   cd ~/.zshforge && ./install.sh
#
# Or one-liner:
#   zsh -c "$(curl -fsSL https://raw.github.com/arunksingh16/zshforge/master/install.sh)"

set -e

ZSHFORGE_HOME="${ZSHFORGE_HOME:-$HOME/.zshforge}"
ZSHFORGE_CONFIG="$HOME/.config/zshforge"

# Colors
RED='\033[38;5;196m'
GREEN='\033[38;5;114m'
CYAN='\033[38;5;81m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;243m'
BOLD='\033[1m'
RESET='\033[0m'

echo ""
echo "${CYAN}${BOLD}╔══════════════════════════════════════╗${RESET}"
echo "${CYAN}${BOLD}║${RESET}  ${BOLD}ZshForge${RESET} ${GRAY}— Installer${RESET}               ${CYAN}${BOLD}║${RESET}"
echo "${CYAN}${BOLD}╚══════════════════════════════════════╝${RESET}"
echo ""

# ── Check prerequisites ───────────────────────────────────────
if [[ ! -f "$ZSHFORGE_HOME/zshforge.zsh" ]]; then
  echo "${RED}Error:${RESET} ZshForge not found at $ZSHFORGE_HOME"
  echo "${GRAY}Clone the repo first:${RESET}"
  echo "  git clone https://github.com/arunksingh16/zshforge $ZSHFORGE_HOME"
  exit 1
fi

# ── Backup existing .zshrc ────────────────────────────────────
if [[ -f "$HOME/.zshrc" ]]; then
  local backup="$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
  cp "$HOME/.zshrc" "$backup"
  echo "${GREEN}✓${RESET} Backed up .zshrc → ${GRAY}${backup}${RESET}"
fi

# ── Create config directory ───────────────────────────────────
mkdir -p "$ZSHFORGE_CONFIG"

# ── Create default config ─────────────────────────────────────
if [[ ! -f "$ZSHFORGE_CONFIG/config.zsh" ]]; then
  cat > "$ZSHFORGE_CONFIG/config.zsh" <<'EOF'
# ZshForge Configuration
# Edit with: forge edit

# Theme: nebula | oxide | aurora | stealth
ZSHFORGE_THEME="nebula"

# Plugins (space-separated)
ZSHFORGE_PLUGINS="history dirjump"
EOF
  echo "${GREEN}✓${RESET} Created config → ${GRAY}${ZSHFORGE_CONFIG}/config.zsh${RESET}"
fi

# ── Add source line to .zshrc ─────────────────────────────────
SOURCE_LINE="source \"$ZSHFORGE_HOME/zshforge.zsh\""

if grep -q "zshforge.zsh" "$HOME/.zshrc" 2>/dev/null; then
  echo "${GRAY}○${RESET} .zshrc already sources ZshForge"
else
  # Add at the TOP of .zshrc (before other stuff that might depend on it)
  echo "" >> "$HOME/.zshrc"
  echo "# ── ZshForge ──────────────────────────────────" >> "$HOME/.zshrc"
  echo "$SOURCE_LINE" >> "$HOME/.zshrc"
  echo "${GREEN}✓${RESET} Added ZshForge to .zshrc"
fi

# ── Done ──────────────────────────────────────────────────────
echo ""
echo "${GREEN}${BOLD}Done!${RESET} Restart your shell or run:"
echo ""
echo "  ${PURPLE}exec zsh${RESET}"
echo ""
echo "Then try:"
echo "  ${PURPLE}forge help${RESET}          ${GRAY}— see all commands${RESET}"
echo "  ${PURPLE}forge theme${RESET}         ${GRAY}— pick a theme${RESET}"
echo "  ${PURPLE}forge doctor${RESET}        ${GRAY}— check everything works${RESET}"
echo ""
