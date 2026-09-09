#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."
f=roles.md
fail=0
need() { grep -qF -- "$1" "$f" && echo "ok   $1" || { echo "FAIL $1"; fail=1; }; }
need "# Roles"
need "Version 1.1"
need "legacy, system, need"
need "| Role | Who | May yield | Never yields | Register effect |"
for r in sme consultant vendor architect unknown; do need "| \`$r\` |"; done
need "only SMEs describe our processes or needs"
# every class named in May yield or Never yields must be a class the transcript runner knows
classes=$(awk -F'|' '/^\| `/ { print $4 "," $5 }' "$f" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep -E '^[a-z-]+$' | sort -u)
for c in $classes; do grep -qF "\`$c\`" transcript-runner.md && echo "ok   class $c known" || { echo "FAIL class $c not in transcript runner"; fail=1; }; done
# both runners and the registry point here
for d in transcript-runner.md solution-register-runner.md transcripts/stakeholders.md; do grep -qF 'roles.md' "$d" && echo "ok   $d references roles.md" || { echo "FAIL $d references roles.md"; fail=1; }; done
exit $fail
