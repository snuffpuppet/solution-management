#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."
f=roles.md
fail=0
# Markdown table layout is not significant: collapse whitespace around pipes and runs of
# dashes before matching, so an aligned table and a compact one compare equal. Content is
# never normalised, so a changed role, class or principle line still fails.
norm() { sed -e 's/[[:space:]][[:space:]]*/ /g' -e 's/[[:space:]]*|[[:space:]]*/|/g' -e 's/--*/-/g' -e 's/^ //' -e 's/ $//'; }
normf=$(mktemp "${TMPDIR:-/tmp}/check-roles.XXXXXX")
trap 'rm -f "$normf"' EXIT
norm < "$f" > "$normf"
need() { n=$(printf '%s' "$1" | norm); grep -qF -- "$n" "$normf" && echo "ok   $1" || { echo "FAIL $1"; fail=1; }; }
need "# Roles"
need "Version 1."
need "| Role | Who | May yield | Never yields | Register effect |"
for r in sme consultant vendor architect unknown; do need "| \`$r\` |"; done
need "only SMEs describe our processes or needs"
# every class named in May yield or Never yields must be a class the transcript runner knows
classes=$(awk -F'|' '/^\| *`/ { print $4 "," $5 }' "$f" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep -E '^[a-z-]+$' | sort -u)
for c in $classes; do grep -qF "\`$c\`" transcript-runner.md && echo "ok   class $c known" || { echo "FAIL class $c not in transcript runner"; fail=1; }; done
# both runners and the registry point here
for d in transcript-runner.md solution-register-runner.md transcripts/stakeholders.md; do grep -qF 'roles.md' "$d" && echo "ok   $d references roles.md" || { echo "FAIL $d references roles.md"; fail=1; }; done
# P10 assertion: the normaliser makes an aligned row and a compact row compare equal
a=$(printf '| `sme`   | Our business   |' | norm); b=$(printf '| `sme` | Our business |' | norm)
[ "$a" = "$b" ] && echo "ok   table padding is not significant" || { echo "FAIL table padding is not significant"; fail=1; }
# and that it does not mask a content change
c=$(printf '| `smee` | Our business |' | norm)
[ "$a" != "$c" ] && echo "ok   content change still detected" || { echo "FAIL content change still detected"; fail=1; }
exit $fail
