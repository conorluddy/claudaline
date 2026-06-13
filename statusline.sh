#!/bin/bash
# Reads Claude Code session JSON from stdin, outputs a status line string.
# Phosphor-HUD style: dim labels/separators, bright phosphor values, glyph icons.
# Configure in ~/.claude/settings.json:
#
#   "statusLine": {
#     "type": "command",
#     "command": "/path/to/statusline.sh",
#     "padding": 0
#   }

DATA=$(cat)

# === Palette (256-colour ANSI) ===
DIM=$'\033[38;5;240m'      # labels, separators, glyphs at rest
WHITE=$'\033[1;38;5;255m'  # repo
AMBER=$'\033[38;5;214m'    # branch, warnings
CYAN=$'\033[38;5;44m'      # model
GREEN=$'\033[38;5;48m'     # healthy values, timers
RED=$'\033[38;5;196m'      # critical
RESET=$'\033[0m'
SEP="${DIM} │ ${RESET}"

# === Glyphs (standard Unicode — font-safe; swap ⎇→ if you run a Nerd Font) ===
GLYPH_BRANCH="⎇"
GLYPH_MODEL="⌬"
GLYPH_CTX="▓"
GLYPH_TIMER="◷"

# === Extract ===
REPO=$(echo "$DATA" | jq -r '.workspace.repo.name // (env.PWD | split("/") | last)')
MODEL=$(echo "$DATA" | jq -r '.model.display_name // "unknown"')
EFFORT=$(echo "$DATA" | jq -r '.effort.level // "?"')
CTX_USED=$(echo "$DATA" | jq -r '.context_window.total_input_tokens // 0')
CTX_MAX=$(echo "$DATA" | jq -r '.context_window.context_window_size // 200000')
CTX_PCT=$(echo "$DATA" | jq -r '(.context_window.used_percentage // 0) | if type=="number" then round else . end')
FIVE_H=$(echo "$DATA" | jq -r '(.rate_limits.five_hour.used_percentage // "?") | if type=="number" then round else . end')
SEVEN_D=$(echo "$DATA" | jq -r '(.rate_limits.seven_day.used_percentage // "?") | if type=="number" then round else . end')
FIVE_H_RESET=$(echo "$DATA" | jq -r '.rate_limits.five_hour.resets_at // "?"')
SEVEN_D_RESET=$(echo "$DATA" | jq -r '.rate_limits.seven_day.resets_at // "?"')

BRANCH=$(git -C "${PWD}" branch --show-current 2>/dev/null)

# Git working-tree stats (only when inside a repo). Clean state shows nothing extra.
GIT_EXTRA=""
if [ -n "$BRANCH" ]; then
  # Ahead/behind upstream: "↑2↓1" (omitted when no upstream or in sync).
  AB=$(git -C "${PWD}" rev-list --count --left-right '@{u}...HEAD' 2>/dev/null)
  if [ -n "$AB" ]; then
    BEHIND=$(printf '%s' "$AB" | awk '{print $1}')
    AHEAD=$(printf '%s' "$AB" | awk '{print $2}')
    [ "$AHEAD" -gt 0 ] 2>/dev/null && GIT_EXTRA="${GIT_EXTRA} ${AMBER}↑${AHEAD}${RESET}"
    [ "$BEHIND" -gt 0 ] 2>/dev/null && GIT_EXTRA="${GIT_EXTRA} ${AMBER}↓${BEHIND}${RESET}"
  fi
  # Dirty file count: "●3" (modified + untracked), amber, hidden when clean.
  DIRTY=$(git -C "${PWD}" status --porcelain 2>/dev/null | grep -c .)
  [ "$DIRTY" -gt 0 ] 2>/dev/null && GIT_EXTRA="${GIT_EXTRA} ${AMBER}●${DIRTY}${RESET}"
  # LOC churn vs HEAD: "+120 -40", hidden when no change.
  SHORTSTAT=$(git -C "${PWD}" diff --shortstat HEAD 2>/dev/null)
  INS=$(printf '%s' "$SHORTSTAT" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+')
  DEL=$(printf '%s' "$SHORTSTAT" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+')
  [ -n "$INS" ] && [ "$INS" -gt 0 ] 2>/dev/null && GIT_EXTRA="${GIT_EXTRA} ${GREEN}+${INS}${RESET}"
  [ -n "$DEL" ] && [ "$DEL" -gt 0 ] 2>/dev/null && GIT_EXTRA="${GIT_EXTRA} ${RED}-${DEL}${RESET}"
fi

# Short model token: first word, lowercased ("Opus 4.8 (1M context)" → "opus").
MODEL_SHORT=$(echo "$MODEL" | awk '{print tolower($1)}')

# Format seconds-until-reset as a compact "4d12h" / "4h12m" / "8m" hint.
format_reset() {
  local target="$1"
  [ "$target" = "?" ] && { printf '?'; return; }
  local now remaining
  now=$(date +%s)
  remaining=$((target - now))
  [ "$remaining" -lt 0 ] && remaining=0
  local days=$((remaining / 86400))
  local hours=$(((remaining % 86400) / 3600))
  local mins=$(((remaining % 3600) / 60))
  if [ "$days" -gt 0 ]; then
    printf '%dd%dh' "$days" "$hours"
  elif [ "$hours" -gt 0 ]; then
    printf '%dh%dm' "$hours" "$mins"
  else
    printf '%dm' "$mins"
  fi
}

# Pick a colour by fill percentage: <60 green, <85 amber, else red.
colour_for_pct() {
  local pct="$1"
  if ! [ "$pct" -eq "$pct" ] 2>/dev/null; then printf '%s' "$DIM"; return; fi
  if [ "$pct" -ge 85 ]; then printf '%s' "$RED"
  elif [ "$pct" -ge 60 ]; then printf '%s' "$AMBER"
  else printf '%s' "$GREEN"; fi
}

FIVE_H_REMAIN=$(format_reset "$FIVE_H_RESET")
SEVEN_D_REMAIN=$(format_reset "$SEVEN_D_RESET")

CTX_USED_K=$(echo "$CTX_USED" | awk '{printf "%dk", $1/1000}')
CTX_MAX_K=$(echo "$CTX_MAX" | awk '{if ($1>=1000000) printf "%dM", $1/1000000; else printf "%dk", $1/1000}')

# === Build segments ===
CTX_COL=$(colour_for_pct "$CTX_PCT")
FIVE_COL=$(colour_for_pct "$FIVE_H")
SEVEN_COL=$(colour_for_pct "$SEVEN_D")

SEG_REPO="${WHITE}${REPO}${RESET}"
SEG_BRANCH=""
[ -n "$BRANCH" ] && SEG_BRANCH="${DIM}${GLYPH_BRANCH} ${AMBER}${BRANCH}${RESET}${GIT_EXTRA}"
SEG_MODEL="${DIM}${GLYPH_MODEL} ${CYAN}${MODEL_SHORT}${DIM}·${CYAN}${EFFORT}${RESET}"
SEG_CTX="${DIM}${GLYPH_CTX} ${CTX_COL}${CTX_PCT}% ${DIM}${CTX_USED_K}/${CTX_MAX_K}${RESET}"
SEG_5H="${DIM}${GLYPH_TIMER} 5h ${FIVE_COL}${FIVE_H}% ${DIM}${FIVE_H_REMAIN}${RESET}"
SEG_7D="${DIM}${GLYPH_TIMER} 7d ${SEVEN_COL}${SEVEN_D}% ${DIM}${SEVEN_D_REMAIN}${RESET}"

PARTS="$SEG_REPO"
[ -n "$SEG_BRANCH" ] && PARTS="${PARTS}${SEP}${SEG_BRANCH}"
PARTS="${PARTS}${SEP}${SEG_MODEL}${SEP}${SEG_CTX}${SEP}${SEG_5H}${SEP}${SEG_7D}"

printf "%b\n" "$PARTS"
