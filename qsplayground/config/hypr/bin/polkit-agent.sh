#!/usr/bin/env bash
# Start whichever polkit authentication agent is installed.
# Without one, anything needing elevation fails silently.
set -euo pipefail

pgrep -f 'polkit-.*-authentication-agent' >/dev/null && exit 0

candidates=(
  /usr/lib/polkit-kde-authentication-agent-1
  /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
  /usr/libexec/polkit-gnome-authentication-agent-1
  /usr/lib/mate-polkit/polkit-mate-authentication-agent-1
  /usr/bin/lxqt-policykit-agent
  /usr/bin/hyprpolkitagent
)

for agent in "${candidates[@]}"; do
  if [[ -x $agent ]]; then
    exec "$agent"
  fi
done

notify-send -u critical "Polkit" "No authentication agent found. Install hyprpolkitagent."
