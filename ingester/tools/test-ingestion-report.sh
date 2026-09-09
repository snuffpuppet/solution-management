#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."
out=$(tools/ingestion-report.sh tools/fixtures/report/state.md tools/fixtures/report/claims)
pass=0; fail=0
check() { if eval "$2"; then echo "ok   $1"; pass=$((pass+1)); else echo "FAIL $1"; fail=$((fail+1)); fi; }
check "sessions section lists both sessions" 'printf "%s\n" "$out" | grep -q "^| T001 |" && printf "%s\n" "$out" | grep -q "^| T002 |"'
check "per-model row for opus with change rate" 'printf "%s\n" "$out" | grep "^| claude-opus-5 | strict | 1.2 |" | grep -q "| 35 | 10 | 28.6% |"'
check "per-model row for fable with change rate" 'printf "%s\n" "$out" | grep "^| claude-fable-5-1 | standard | 1.2 |" | grep -q "| 14 | 2 | 14.3% |"'
check "claims by class for T001" 'printf "%s\n" "$out" | grep "^| T001 | claude-opus-5 |" | grep -q "| 3 | 1 | 0 | 1 | 0 | 1 |"'
check "inferred share for T001" 'printf "%s\n" "$out" | grep "^| T001 | claude-opus-5 |" | grep -q "| 33.3% |"'
check "audit rows carry the runner column" 'printf "%s\n" "$out" | grep -q "^| Session | Stage | Model | Mode | Runner | Date |"'
check "missing state file exits 2" 'tools/ingestion-report.sh /nonexistent tools/fixtures/report/claims >/dev/null 2>&1; [ $? = 2 ]'
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
