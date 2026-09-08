#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."
fail=0
for s in tools/check-model-prc.sh tools/check-model-cr.sh tools/check-runner.sh tools/check-transcript-runner.sh tools/test-vtt-to-passages.sh tools/test-ingestion-report.sh; do
  echo "== $s"; "$s" || fail=1
done
echo "== README"
grep -qF '`transcript-runner.md`' README.md && echo "ok   README row" || { echo "FAIL README row"; fail=1; }
grep -qF '`transcripts/`' README.md && echo "ok   transcripts row" || { echo "FAIL transcripts row"; fail=1; }
echo "== gitignore"
grep -qx 'transcripts/input/\*' .gitignore && echo "ok   input ignored" || { echo "FAIL input ignored"; fail=1; }
echo "== folders"
for d in transcripts/input transcripts/processed transcripts/claims; do [ -f "$d/.gitkeep" ] && echo "ok   $d" || { echo "FAIL $d"; fail=1; }; done
echo "== em dash scan"
if grep -l -- '—' solution-register-model.md solution-register-runner.md transcript-runner.md README.md 2>/dev/null; then echo "FAIL em dash found"; fail=1; else echo "ok   no em dashes"; fi
echo "== skills"
for s in ingest-transcript ingestion-report; do grep -q "^name: $s$" ".claude/skills/$s/SKILL.md" 2>/dev/null && echo "ok   skill $s" || { echo "FAIL skill $s"; fail=1; }; done
exit $fail
