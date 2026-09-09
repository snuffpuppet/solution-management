#!/usr/bin/env bash
# Validates one engagement's data and skills.
# Usage: tools/check-engagement.sh [engagement root]   default: .
set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="${1:-.}"
p="${root%/}/"
fail=0
echo "== stakeholders"; "$here/check-stakeholders.sh" "$root" || fail=1
echo "== registers";    "$here/check-registers.sh" "${p}registers" || fail=1
echo "== folders"
for d in transcripts/input transcripts/processed transcripts/claims; do
  [ -f "${p}$d/.gitkeep" ] && echo "ok   $d" || { echo "FAIL $d"; fail=1; }
done
echo "== gitignore"
git check-ignore -q "${p}transcripts/input/x.vtt" 2>/dev/null \
  && { echo "FAIL transcripts/input must not be ignored"; fail=1; } \
  || echo "ok   transcripts/input persisted"
echo "== em dash scan"
if grep -l -- '—' "${p}transcripts/stakeholders.md" 2>/dev/null; then
  echo "FAIL em dash found"; fail=1
else echo "ok   no em dashes"; fi
echo "== findings"; "$here/check-findings.sh" "$root" || fail=1
echo "== write isolation, static"
if grep -n '\.\./' "${p}CLAUDE.md" 2>/dev/null | grep -v '\.\./\.\./ingester/CLAUDE\.md' | grep -q .; then
  echo "FAIL an engagement file names a path outside the engagement"; fail=1
else
  echo "ok   no engagement file names a path outside the engagement"
fi
echo "== handover"
"$here/check-handover-shape.sh" "$root" || fail=1
exit $fail
