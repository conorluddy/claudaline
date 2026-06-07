# claudaline

A minimal status line script for [Claude Code](https://claude.ai/code) that surfaces the session data you actually care about.

```
Grapla  main  Sonnet 4.6:low  ctx:82k/200k (41%)  5h:34%  7d:⚠ 97%
```

<img width="465" height="84" alt="Screenshot 2026-06-07 at 16 06 17" src="https://github.com/user-attachments/assets/9474e0b9-5588-4a2b-8127-f7297886653d" />



## What it shows

| Segment | Source |
|---|---|
| Repo name | `workspace.repo.name` |
| Git branch | `git branch --show-current` |
| Model + effort | `model.display_name` + `effort.level` |
| Context usage | `total_input_tokens / context_window_size` |
| 5-hour rate limit | `rate_limits.five_hour.used_percentage` |
| 7-day rate limit | `rate_limits.seven_day.used_percentage` |

Warnings: `⚠` at 80%+ context or 90%+ on the 7-day limit. `🚨` if the session exceeds 200k tokens.

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
    "padding": 0
  }
}
```

Reload with `/hooks` or restart Claude Code.

## Requirements

- `jq`
- `git` (for branch display)
