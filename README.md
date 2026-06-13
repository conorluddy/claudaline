# claudaline

A minimal status line script for [Claude Code](https://claude.ai/code) that surfaces the session data you actually care about — styled as a phosphor HUD.

```
Grapla │ ⎇ main ↑2 ●3 +120 -40 │ ⌬ opus·low │ ▓ 9% 93k/1M │ ◷ 5h 55% 47m │ ◷ 7d 6% 3d9h
```

> "hey claude, use https://github.com/conorluddy/claudaline and adapt it for my workflow"

Dim-grey labels and separators, bright phosphor values, glyph icons, and colour that shifts **green → amber → red** as each meter fills.

## What it shows

| Segment | Glyph | Source |
|---|---|---|
| Repo name | — | `workspace.repo.name` (falls back to cwd) |
| Git branch | `⎇` | `git branch --show-current` |
| Working-tree stats | `↑↓ ● +-` | ahead/behind, dirty count, LOC churn (see below) |
| Model + effort | `⌬` | `model.display_name` (first word) + `effort.level` |
| Context usage | `▓` | `used_percentage` + `total_input_tokens / context_window_size` |
| 5-hour rate limit | `◷` | `rate_limits.five_hour` — used % + time until reset |
| 7-day rate limit | `◷` | `rate_limits.seven_day` — used % + time until reset |

### Working-tree stats

Appended after the branch name when you're inside a git repo. Each piece is **hidden when there's nothing to report**, so a clean, in-sync tree shows just the branch:

- **`↑N` / `↓N`** — commits ahead of / behind the upstream branch (`git rev-list --count --left-right @{u}...HEAD`). Catches unpushed work or a moved upstream before it bites.
- **`●N`** — dirty file count: modified + untracked (`git status --porcelain`), amber.
- **`+N` / `−N`** — LOC churn vs HEAD (`git diff --shortstat HEAD`), green adds / red deletes.

### Reset timers

The 5h/7d segments show **time until the limit resets**, derived from `rate_limits.*.resets_at` (a Unix timestamp in the session blob). Rendered as a compact `47m` / `4h12m` / `3d9h` hint.

### Colour coding

Each meter (context, 5h, 7d) is coloured independently by fill:

- **green** under 60%
- **amber** 60–84%
- **red** 85%+

Percentages are rounded to whole numbers, and context max auto-formats megas (`1000k` → `1M`). Missing rate-limit data degrades cleanly to `?%` with no broken arithmetic.

## Glyphs & fonts

All glyphs are standard Unicode and render in any monospace font. If you run a [Nerd Font](https://www.nerdfonts.com/), swap the branch glyph for the truer powerline look by editing the top of the script:

```bash
GLYPH_BRANCH=""   # was "⎇"
```

## Install

```bash
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/conorluddy/claudaline/main/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/Users/you/.claude/statusline.sh",
    "padding": 0,
    "refreshInterval": 60
  }
}
```

`refreshInterval` keeps the reset timers ticking down between events. Reload with `/hooks` or restart Claude Code.

## Requirements

- `jq`
- `git` (for branch display)
- a terminal with 256-colour ANSI support (any modern terminal)
