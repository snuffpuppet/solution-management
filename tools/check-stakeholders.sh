#!/usr/bin/env bash
set -u
f="$(dirname "$0")/../transcripts/stakeholders.md"
fail=0
[ -f "$f" ] && echo "ok   stakeholders file" || { echo "FAIL stakeholders file"; exit 1; }
grep -qF '| Name | Tags | Organisation | Role | Expertise |' "$f" && echo "ok   header" || { echo "FAIL header"; fail=1; }
for r in sme consultant vendor architect; do grep -qF "\`$r\`" "$f" && echo "ok   role $r defined" || { echo "FAIL role $r defined"; fail=1; }; done
bad=$(awk -F'|' '/^\|/ && $2 !~ /Name|---/ { gsub(/ /,"",$5); if ($5 !~ /^(sme|consultant|vendor|architect)$/) print $0 }' "$f")
[ -z "$bad" ] && echo "ok   every row has a valid role" || { echo "FAIL invalid role: $bad"; fail=1; }
exit $fail
