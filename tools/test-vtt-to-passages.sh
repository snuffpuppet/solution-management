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
fx2=tools/fixtures/edge.vtt
out2=$(tools/vtt-to-passages.sh "$fx2")
check "apostrophe speaker name parsed" 'printf "%s\n" "$out2" | grep -q "^- Speaker: O'"'"'Brien$"'
check "non-ascii speaker name parsed" 'printf "%s\n" "$out2" | grep -q "^- Speaker: José$"'
check "multiline v tag closes without leaking tag" 'printf "%s\n" "$out2" | grep -q "spans several lines before it closes." && ! printf "%s\n" "$out2" | grep -q "</v>"'
check "edge fixture passage count" '[ "$(printf "%s\n" "$out2" | grep -c "^## Passage ")" = 3 ]'
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
