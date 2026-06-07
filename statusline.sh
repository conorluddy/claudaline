#!/bin/bash
# Reads Claude Code session JSON from stdin, outputs a status line string.
# Configure in ~/.claude/settings.json:
#
#   "statusLine": {
#     "type": "command",
#     "command": "/path/to/statusline.sh",
#     "padding": 0
#   }

DATA=$(cat)

REPO=$(echo "$DATA" | jq -r '.workspace.repo.name // (env.PWD | split("/") | last)')
MODEL=$(echo "$DATA" | jq -r '.model.display_name // "unknown"')
EFFORT=$(echo "$DATA" | jq -r '.effort.level // "?"')
CTX_USED=$(echo "$DATA" | jq -r '.context_window.total_input_tokens // 0')
CTX_MAX=$(echo "$DATA" | jq -r '.context_window.context_window_size // 200000')
CTX_PCT=$(echo "$DATA" | jq -r '.context_window.used_percentage // 0')
EXCEEDS=$(echo "$DATA" | jq -r '.exceeds_200k_tokens // false')
FIVE_H=$(echo "$DATA" | jq -r '.rate_limits.five_hour.used_percentage // "?"')
SEVEN_D=$(echo "$DATA" | jq -r '.rate_limits.seven_day.used_percentage // "?"')

BRANCH=$(git -C "${PWD}" branch --show-current 2>/dev/null)

CTX_USED_K=$(echo "$CTX_USED" | awk '{printf "%dk", $1/1000}')
CTX_MAX_K=$(echo "$CTX_MAX" | awk '{printf "%dk", $1/1000}')

CTX_DISPLAY="${CTX_USED_K}/${CTX_MAX_K} (${CTX_PCT}%)"
[ "$CTX_USED" -ge 150000 ] 2>/dev/null && CTX_DISPLAY=$'\033[0;33m'"⚠ ${CTX_DISPLAY}"$'\033[0m'
[ "$CTX_USED" -ge 200000 ] 2>/dev/null && CTX_DISPLAY=$'\033[0;31m'"🚨 ${CTX_DISPLAY}"$'\033[0m'

FIVE_H_DISPLAY="${FIVE_H}%"
[ "$FIVE_H" -ge 80 ] 2>/dev/null && FIVE_H_DISPLAY=$'\033[0;33m'"⚠ ${FIVE_H}%"$'\033[0m'
[ "$FIVE_H" -ge 90 ] 2>/dev/null && FIVE_H_DISPLAY=$'\033[0;31m'"⚠ ${FIVE_H}%"$'\033[0m'

SEVEN_D_DISPLAY="${SEVEN_D}%"
[ "$SEVEN_D" -ge 80 ] 2>/dev/null && SEVEN_D_DISPLAY=$'\033[0;33m'"⚠ ${SEVEN_D}%"$'\033[0m'
[ "$SEVEN_D" -ge 90 ] 2>/dev/null && SEVEN_D_DISPLAY=$'\033[0;31m'"⚠ ${SEVEN_D}%"$'\033[0m'

PARTS="$REPO"
[ -n "$BRANCH" ] && PARTS="$PARTS  $BRANCH"
PARTS="$PARTS  $MODEL:$EFFORT  ctx:$CTX_DISPLAY  5h:$FIVE_H_DISPLAY  7d:$SEVEN_D_DISPLAY"

printf "%b\n" "$PARTS"
