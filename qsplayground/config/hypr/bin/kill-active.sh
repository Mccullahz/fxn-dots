#!/usr/bin/env bash
# Kill the active window's process outright — the escalation from
# SUPER+Q, for windows that ignore a close request.
set -euo pipefail

pid=$(hyprctl -j activewindow | jq -r '.pid // empty')
[[ -n $pid && $pid != "null" && $pid -gt 1 ]] || exit 0

name=$(ps -p "$pid" -o comm= 2>/dev/null || echo "process $pid")

kill -TERM "$pid" 2>/dev/null || exit 0
notify-send -a Hyprland "Killed $name" "PID $pid"

# Escalate if it is still alive a moment later.
sleep 3
kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true
