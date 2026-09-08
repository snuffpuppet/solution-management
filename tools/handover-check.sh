#!/usr/bin/env bash
# Handover check. Run by the handover skill, by hand, or optionally as a Claude Code Stop hook.
# Passes when: the working tree has no uncommitted tracked changes, and the commit
# recorded in HANDOVER.md equals the latest commit that touched anything other than
# HANDOVER.md and LOG.md. Exit 2 blocks the stop and the message on stderr reaches the agent.
# Also usable by hand: tools/handover-check.sh
set -u
cd "$(dirname "$0")/.." || exit 0
input=$(cat 2>/dev/null || true)
case "$input" in *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;; esac
[ -f HANDOVER.md ] || { echo "HANDOVER.md is missing. Create it from the template in CLAUDE.md, then commit." >&2; exit 2; }
recorded=$(grep -m1 '^Last commit:' HANDOVER.md | awk '{print $3}')
latest=$(git log -1 --format=%h -- . ':!HANDOVER.md' ':!LOG.md' 2>/dev/null)
dirty=$(git status --porcelain --untracked-files=no 2>/dev/null)
msgs=""
[ -n "$dirty" ] && msgs="${msgs}Uncommitted changes exist; commit them or discard them. "
[ "$recorded" != "$latest" ] && msgs="${msgs}HANDOVER.md records commit '${recorded:-none}' but the latest work commit is '$latest'. Update HANDOVER.md (in flight, next action, blocked, last commit) and LOG.md, then commit. "
if [ -n "$msgs" ]; then
  echo "Before ending the session: $msgs" >&2
  exit 2
fi
exit 0
