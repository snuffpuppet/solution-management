#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."
fail=0
for s in tools/check-model-prc.sh tools/check-model-cr.sh tools/check-runner.sh tools/check-transcript-runner.sh tools/check-stakeholders.sh tools/check-roles.sh tools/test-vtt-to-passages.sh tools/test-ingestion-report.sh; do
  echo "== $s"; "$s" || fail=1
done
echo "== README"
grep -qF '`transcript-runner.md`' README.md && echo "ok   README row" || { echo "FAIL README row"; fail=1; }
grep -qF '`transcripts/`' README.md && echo "ok   transcripts row" || { echo "FAIL transcripts row"; fail=1; }
echo "== gitignore"
git check-ignore -q transcripts/input/x.vtt 2>/dev/null && { echo "FAIL transcripts/input must not be ignored"; fail=1; } || echo "ok   transcripts/input persisted"
echo "== folders"
for d in transcripts/input transcripts/processed transcripts/claims; do [ -f "$d/.gitkeep" ] && echo "ok   $d" || { echo "FAIL $d"; fail=1; }; done
echo "== em dash scan"
if grep -l -- '—' solution-register-model.md solution-register-runner.md transcript-runner.md README.md ARCHITECTURE.md transcripts/stakeholders.md roles.md CLAUDE.md LOG.md ENHANCEMENTS.md HANDOVER.md .claude/skills/*/SKILL.md 2>/dev/null; then echo "FAIL em dash found"; fail=1; else echo "ok   no em dashes"; fi
echo "== skills"
for s in ingest-transcript ingestion-report handover; do grep -q "^name: $s$" ".claude/skills/$s/SKILL.md" 2>/dev/null && echo "ok   skill $s" || { echo "FAIL skill $s"; fail=1; }; done
echo "== handover"
for h in "^Updated: " "^Last commit: " "^## In flight" "^## Next action" "^## Blocked" "^## Notes for the next session"; do
  grep -q "$h" HANDOVER.md && echo "ok   $h" || { echo "FAIL $h"; fail=1; }
done
[ -x tools/handover-check.sh ] && echo "ok   handover hook executable" || { echo "FAIL handover hook executable"; fail=1; }
[ "$(wc -l < HANDOVER.md)" -le 25 ] && echo "ok   handover under 25 lines" || { echo "FAIL handover under 25 lines"; fail=1; }
exit $fail
