# ⚡ ZshForge

A minimal, fast zsh framework that stays out of your way.

```
forge theme       # pick a theme interactively
forge doctor      # health check
forge bench       # benchmark startup time
j <pattern>       # jump to directories you use often
```

## Philosophy

- **Fast first** — every millisecond counts at shell startup
- **Modular** — only load what you use
- **No magic** — plain zsh, no compilation, no background daemons
- **Growable** — add your own themes and plugins trivially

## Install

```bash
git clone https://github.com/arunksingh16/zshforge ~/.zshforge
cd ~/.zshforge && zsh install.sh
exec zsh
```
<img width="1439" height="280" alt="image" src="https://github.com/user-attachments/assets/6f9f76c4-2080-4982-831a-9b18bc74ad49" />

## Themes

| Theme | Style |
|-------|-------|
| `nebula` | Colorful two-line prompt with git status, time |
| `oxide` | Minimal single-line, warm rust tones |
| `aurora` | Gradient prompt with system vitals |
| `stealth` | Monochrome, distraction-free |

Switch: `forge theme` (interactive) or `forge theme oxide` (direct)

## Plugins

### history
Fixes all common zsh history annoyances:
- No more duplicates (across sessions)
- Shared history across all iTerm tabs
- Prefix a command with a space to keep it private
- `forge::history::dedup` — clean existing duplicates
- `forge::history::scrub` — remove sensitive entries
- `forge::history::stats` — see your top commands

### dirjump
Fast directory jumping with frecency scoring:
- `j project` — jump to best matching directory
- `j` — interactive picker (uses fzf if available)
- `jl` — list all tracked directories with scores
- `jclean` — remove dead directory entries

## Add Your Own Theme

Create `~/.zshforge/themes/mytheme.zsh-theme`:

```zsh
setopt PROMPT_SUBST
PROMPT='%F{cyan}%~%f > '
```

Then: `forge theme mytheme`

## Add Your Own Plugin

Create `~/.zshforge/plugins/myplugin/myplugin.plugin.zsh`:

```zsh
# Your plugin code here
```

Add to config: `forge edit` → add `myplugin` to `ZSHFORGE_PLUGINS`

## Structure

```
~/.zshforge/
├── zshforge.zsh          # Main entry (sourced from .zshrc)
├── lib/
│   └── core.zsh          # Shared utilities
├── themes/
│   ├── nebula.zsh-theme
│   ├── oxide.zsh-theme
│   ├── aurora.zsh-theme
│   └── stealth.zsh-theme
├── plugins/
│   ├── history/
│   └── dirjump/
├── bin/
│   └── forge.zsh          # CLI tool
└── install.sh
```

## Config

Stored at `~/.config/zshforge/config.zsh`. Edit with `forge edit`.

## License

MIT
