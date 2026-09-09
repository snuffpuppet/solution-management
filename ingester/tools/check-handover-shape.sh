#!/usr/bin/env bash
# Shape of one HANDOVER.md: the six required sections and the length cap.
# Usage: tools/check-handover-shape.sh [root]   default: .
set -u
root="${1:-.}"
f="${root%/}/HANDOVER.md"
fail=0
[ -f "$f" ] || { echo "FAIL handover file $f"; exit 1; }
for h in "^Updated: " "^Last commit: " "^## In flight" "^## Next action" "^## Blocked" "^## Notes for the next session"; do
  grep -q "$h" "$f" && echo "ok   $h" || { echo "FAIL $h"; fail=1; }
done
[ "$(wc -l < "$f")" -le 25 ] && echo "ok   handover under 25 lines" || { echo "FAIL handover under 25 lines"; fail=1; }
exit $fail
