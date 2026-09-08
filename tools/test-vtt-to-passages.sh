#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."
fx=tools/fixtures/sample.vtt
out=$(tools/vtt-to-passages.sh "$fx")
summary=$(printf '%s\n' "$out" | tail -1)
cues=$(grep -c -- '-->' "$fx")
lastcue=$(grep -- '-->' "$fx" | tail -1 | cut -d' ' -f1)
pass=0; fail=0
check() { if eval "$2"; then echo "ok   $1"; pass=$((pass+1)); else echo "FAIL $1"; fail=$((fail+1)); fi; }
check "cue count in summary matches file" '[ "$(printf "%s" "$summary" | sed "s/.*cues: \([0-9]*\).*/\1/")" = "$cues" ]'
check "seven passages" '[ "$(printf "%s\n" "$out" | grep -c "^## Passage ")" = 7 ]'
check "last timestamp equals last cue start" '[ "$(printf "%s" "$summary" | sed "s/.*last: \([^ ]*\).*/\1/")" = "$lastcue" ]'
check "same-speaker cues merge" 'printf "%s\n" "$out" | grep -q "sales team. I key it into the ledger"'
check "gap over five seconds splits" 'printf "%s\n" "$out" | grep -A4 "^## Passage 3$" | grep -q "^- Time: 00:00:30.000$"'
check "colon speaker form parsed" 'printf "%s\n" "$out" | grep -q "^- Speaker: Meeting Room 4$"'
check "no speaker gives Unattributed" 'printf "%s\n" "$out" | grep -q "^- Speaker: Unattributed$"'
check "v tags stripped" '! printf "%s\n" "$out" | grep -q "<v "'
check "rejects non-vtt with exit 2" 'tools/vtt-to-passages.sh tools/fixtures/not-vtt.txt >/dev/null 2>&1; [ $? = 2 ]'
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
