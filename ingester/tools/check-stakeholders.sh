#!/usr/bin/env bash
# Integrity checks over one engagement's stakeholder registry.
# Usage: tools/check-stakeholders.sh [engagement root]   default: .
set -u
root="${1:-.}"
f="$root/transcripts/stakeholders.md"
fail=0
[ -f "$f" ] && echo "ok   stakeholders file" || { echo "FAIL stakeholders file"; exit 1; }
grep -qF '| Name | Tags | Organisation | Role | Expertise |' "$f" && echo "ok   header" || { echo "FAIL header"; fail=1; }
for r in sme consultant vendor architect; do
  grep -qF "\`$r\`" "$f" && echo "ok   role $r defined" || { echo "FAIL role $r defined"; fail=1; }
done
bad=$(awk -F'|' '/^\|/ && $2 !~ /Name|---/ { gsub(/ /,"",$5); if ($5 !~ /^(sme|consultant|vendor|architect)$/) print $0 }' "$f")
[ -z "$bad" ] && echo "ok   every row has a valid role" || { echo "FAIL invalid role: $bad"; fail=1; }
# Moved here from check-roles.sh: this opens an engagement file, so it is an engagement check.
grep -qF 'roles.md' "$f" && echo "ok   registry references roles.md" || { echo "FAIL registry references roles.md"; fail=1; }
exit $fail
