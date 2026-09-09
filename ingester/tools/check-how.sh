#!/usr/bin/env bash
# Validates the how: the method documents, the tools, and the root scaffolding.
# Takes no arguments, and must pass with no engagement present.
set -u
how="$(cd "$(dirname "$0")/.." && pwd)"
repo="$(cd "$how/.." && pwd)"
cd "$how"
fail=0
for s in tools/check-model-prc.sh tools/check-model-cr.sh tools/check-runner.sh \
         tools/check-transcript-runner.sh tools/check-roles.sh tools/check-enhancements.sh \
         tools/check-how-refs.sh \
         tools/test-vtt-to-passages.sh tools/test-ingestion-report.sh tools/test-check-registers.sh; do
  echo "== $s"; "$s" || fail=1
done
echo "== README"
grep -qF '`ingester/`' "$repo/README.md" && echo "ok   README row" || { echo "FAIL README row"; fail=1; }
grep -qF '`engagements/`' "$repo/README.md" && echo "ok   transcripts row" || { echo "FAIL transcripts row"; fail=1; }
grep -qF '`registers/`' "$repo/README.md" && echo "ok   registers row" || { echo "FAIL registers row"; fail=1; }
echo "== skills"
for s in ingest-transcript build-registers ingestion-report handover; do
  grep -q "^name: $s$" "$repo/.claude/skills/$s/SKILL.md" 2>/dev/null && echo "ok   skill $s" || { echo "FAIL skill $s"; fail=1; }
done
grep -qF 'registers/' "$repo/.claude/skills/ingest-transcript/SKILL.md" 2>/dev/null \
  && echo "ok   ingest skill chains the register runner" \
  || { echo "FAIL ingest skill chains the register runner"; fail=1; }
echo "== em dash scan"
if grep -l -- '—' solution-register-model.md solution-register-runner.md transcript-runner.md \
   roles.md ARCHITECTURE.md CLAUDE.md LOG.md ENHANCEMENTS.md HANDOVER.md \
   "$repo/README.md" "$repo/CLAUDE.md" "$repo"/.claude/skills/*/SKILL.md 2>/dev/null; then
  echo "FAIL em dash found"; fail=1
else echo "ok   no em dashes"; fi
echo "== handover"
tools/check-handover-shape.sh . || fail=1
[ -x tools/handover-check.sh ] && echo "ok   handover hook executable" || { echo "FAIL handover hook executable"; fail=1; }
echo "== independence"
if [ -n "${CHECK_HOW_INNER:-}" ]; then
  echo "ok   how-check passes with no engagement present (inner run, not re-entered)"
else
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/checkhow.XXXXXX")
  mkdir -p "$tmp/ingester"
  cp -R "$how/." "$tmp/ingester/"
  cp "$repo/README.md" "$repo/CLAUDE.md" "$tmp/" 2>/dev/null || true
  mkdir -p "$tmp/.claude"
  cp -R "$repo/.claude/skills" "$tmp/.claude/" 2>/dev/null || true
  if (cd "$tmp" && CHECK_HOW_INNER=1 ingester/tools/check-how.sh >/dev/null 2>&1); then
    echo "ok   how-check passes with no engagement present"
  else
    echo "FAIL how-check needs an engagement to pass"
    echo "     failing labels from the engagement-free tree:"
    (cd "$tmp" && CHECK_HOW_INNER=1 ingester/tools/check-how.sh 2>&1 | grep '^FAIL' | sed 's/^/       /')
    fail=1
  fi
  rm -rf "$tmp"
fi
exit $fail
