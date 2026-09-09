#!/usr/bin/env bash
# Checks over ENHANCEMENTS.md. Ids are the promotion currency for engagement
# findings, so a duplicate id silently merges two unrelated pieces of work.
# Usage: tools/check-enhancements.sh [file]   default: ENHANCEMENTS.md
set -u
f="${1:-ENHANCEMENTS.md}"
fail=0
[ -f "$f" ] || { echo "FAIL enhancements file $f"; exit 1; }
echo "ok   enhancements file"
grep -qF '| Id | Title | Why | Start when | Size |' "$f" && echo "ok   enhancements header" || { echo "FAIL enhancements header"; fail=1; }
dups=$(grep -oE '^\| E[0-9]+ \|' "$f" | sort | uniq -d | tr -d '| ')
[ -z "$dups" ] && echo "ok   enhancement ids unique" || { echo "FAIL duplicate enhancement ids: $(echo $dups)"; fail=1; }
exit $fail
