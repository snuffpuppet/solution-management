#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."
pass=0; fail=0
check() { if eval "$2"; then echo "ok   $1"; pass=$((pass+1)); else echo "FAIL $1"; fail=$((fail+1)); fi; }
good=$(tools/check-registers.sh tools/fixtures/registers-ok); rc_good=$?
bad=$(tools/check-registers.sh tools/fixtures/registers-bad); rc_bad=$?
check "good fixture passes" '[ $rc_good -eq 0 ]'
check "good fixture has no FAIL line" '! printf "%s\n" "$good" | grep -q "^FAIL"'
check "bad fixture fails" '[ $rc_bad -ne 0 ]'
check "I0 header drift" 'printf "%s\n" "$bad" | grep -q "^FAIL requirements.md columns differ"'
check "I1 duplicate id" 'printf "%s\n" "$bad" | grep -q "^FAIL I1 duplicate ids: PRC-001"'
check "I1 wrong prefix" 'printf "%s\n" "$bad" | grep -q "^FAIL I1 processes.md: id \[LIM-002\]"'
check "I2 invalid status" 'printf "%s\n" "$bad" | grep -q "^FAIL I2 SYS-002: status \[Live\]"'
check "I6 missing link target" 'printf "%s\n" "$bad" | grep -q "^FAIL I6 SYS-002: link target REQ-999"'
check "I17 retain no without reason" 'printf "%s\n" "$bad" | grep -q "^FAIL I17 PRC-001: Retain: No without a reason"'
check "I17 step without marker" 'printf "%s\n" "$bad" | grep -q "^FAIL I17 LIM-002: 2 steps but 1 Retain markers"'
check "I19 fate" 'printf "%s\n" "$bad" | grep -q "^FAIL I19 SYS-002: Fate \[Gone\]"'
check "I19 fact without stated by" 'printf "%s\n" "$bad" | grep -q "^FAIL I19 SYS-002: 1 facts but 0 Stated by"'
echo "$pass passed, $fail failed"
[ $fail -eq 0 ]
