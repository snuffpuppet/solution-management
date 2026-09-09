#!/usr/bin/env bash
# Shape of one engagement's findings outbox.
# Usage: tools/check-findings.sh [engagement root]   default: .
set -u
root="${1:-.}"
case "$root" in .) f="FINDINGS.md" ;; *) f="${root%/}/FINDINGS.md" ;; esac
fail=0
[ -f "$f" ] || { echo "FAIL findings file $f"; exit 1; }
echo "ok   findings file"
grep -qF '| Id | Title | Observed | State | Enhancement |' "$f" && echo "ok   findings header" || { echo "FAIL findings header"; fail=1; }
dups=$(grep -oE '^\| F[0-9]+ \|' "$f" | sort | uniq -d | tr -d '| ')
[ -z "$dups" ] && echo "ok   finding ids unique" || { echo "FAIL duplicate finding ids: $(echo $dups)"; fail=1; }
bad=$(awk -F'|' '/^\| F[0-9]+ \|/ { s=$5; e=$6; gsub(/ /,"",s); gsub(/ /,"",e);
  if (s != "open" && s != "promoted") { print "bad state on" $2; next }
  if (s == "promoted" && e !~ /^E[0-9]+$/) print "promoted without an enhancement id on" $2 }' "$f")
[ -z "$bad" ] && echo "ok   every promoted finding names an enhancement" || { echo "FAIL $bad"; fail=1; }
exit $fail
