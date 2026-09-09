#!/usr/bin/env bash
# Handover check for one folder. Run by the handover skill, by hand, or as a Stop hook.
# Usage: tools/handover-check.sh [root]   default: .
# Passes when: no uncommitted tracked changes under <root>, and the commit recorded in
# <root>/HANDOVER.md equals the latest commit touching <root> other than that folder's
# own HANDOVER.md and LOG.md. Exit 2 blocks the stop; stderr reaches the agent.
set -u
root="${1:-.}"
p="${root%/}/"
input=$(cat 2>/dev/null || true)
case "$input" in *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;; esac
[ -f "${p}HANDOVER.md" ] || { echo "HANDOVER.md is missing under ${root}. Create it from the template in CLAUDE.md, then commit." >&2; exit 2; }
recorded=$(grep -m1 '^Last commit:' "${p}HANDOVER.md" | awk '{print $3}')
latest=$(git log -1 --format=%h -- "$root" ":!${p}HANDOVER.md" ":!${p}LOG.md" 2>/dev/null)
dirty=$(git status --porcelain --untracked-files=no -- "$root" 2>/dev/null)
msgs=""
[ -n "$dirty" ] && msgs="${msgs}Uncommitted changes exist under ${root}; commit them or discard them. "
[ "$recorded" != "$latest" ] && msgs="${msgs}${p}HANDOVER.md records commit '${recorded:-none}' but the latest work commit under ${root} is '$latest'. Update HANDOVER.md (in flight, next action, blocked, last commit) and LOG.md, then commit. "
if [ -n "$msgs" ]; then
  echo "Before ending the session: $msgs" >&2
  exit 2
fi
exit 0
