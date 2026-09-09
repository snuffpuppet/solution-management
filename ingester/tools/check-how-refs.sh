#!/usr/bin/env bash
# Asserts the <HOW> contract over the how-documents (spec section 4).
# Usage: tools/check-how-refs.sh [ingester root]   default: the parent of this script's dir
set -u
how="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
fail=0
docs="transcript-runner.md solution-register-runner.md solution-register-model.md roles.md ARCHITECTURE.md"
pat='(tools/[a-z-]+\.sh|roles\.md|transcript-runner\.md|solution-register-runner\.md|solution-register-model\.md)'
# 1. every how-file reference carries the <HOW>/ prefix
for d in $docs; do
  [ -f "$how/$d" ] || { echo "FAIL $d missing"; fail=1; continue; }
  t=$(grep -oE "$pat" "$how/$d" | wc -l | tr -d ' ')
  n=$(grep -oE "<HOW>/$pat" "$how/$d" | wc -l | tr -d ' ')
  [ "$t" -eq "$n" ] && echo "ok   $d: $n of $t how-refs prefixed" \
    || { echo "FAIL $d: $((t-n)) of $t how-refs unprefixed"; fail=1; }
done
# 2. no double prefix
grep -rq '<HOW>/<HOW>' "$how" 2>/dev/null && { echo "FAIL double <HOW> prefix"; fail=1; } || echo "ok   no double prefixes"
# 3. no how-document contains ../, exempting CLAUDE.md which states the binding
for d in $docs; do
  grep -q '\.\./' "$how/$d" 2>/dev/null && { echo "FAIL $d contains ../"; fail=1; } || echo "ok   $d has no ../"
done
grep -qF '../../ingester' "$how/CLAUDE.md" && echo "ok   CLAUDE.md states the binding" || { echo "FAIL CLAUDE.md states the binding"; fail=1; }
grep -qF '<HOW>' "$how/CLAUDE.md" && echo "ok   CLAUDE.md defines <HOW>" || { echo "FAIL CLAUDE.md defines <HOW>"; fail=1; }
exit $fail
