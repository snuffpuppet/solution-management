#!/usr/bin/env bash
# Asserts the engagement is genuinely isolated: its own git repository, ignored by the outer one.
# Write isolation is structural under this arrangement (spec 2.1), so what needs checking is that
# the arrangement is in place, not that writes stayed inside it.
# Usage: tools/check-isolation.sh <engagement root>
# Reads git state only. Never mutates either repository.
set -u
root="${1:?usage: check-isolation.sh <engagement root>}"
fail=0
[ -d "$root" ] || { echo "FAIL no such root: $root"; exit 1; }
abs=$(cd "$root" && pwd)

# 1. The engagement is its own repository, whose toplevel is the engagement root itself.
inner=$(git -C "$root" rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$inner" ]; then
  echo "FAIL $root is not a git repository; run git init inside it"; fail=1
elif [ "$inner" != "$abs" ]; then
  echo "FAIL $root belongs to the repository at $inner, so it is not isolated"; fail=1
else
  echo "ok   engagement is its own repository"
fi

# 2. The outer repository ignores the engagement path.
outer=$(cd "$abs/../.." && git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$outer" ]; then
  echo "FAIL cannot find the outer repository above $root"; fail=1
elif git -C "$outer" check-ignore -q "$abs"; then
  echo "ok   outer repository ignores the engagement"
else
  echo "FAIL outer repository does NOT ignore $abs; engagement data could reach origin"; fail=1
fi

# 3. No file tracked by the outer repository lives under the engagement root.
if [ -n "$outer" ]; then
  rel="${abs#$outer/}"
  leaked=$(git -C "$outer" ls-files -- "$rel" 2>/dev/null || true)
  if [ -n "$leaked" ]; then
    echo "FAIL outer repository tracks files under the engagement:"; echo "$leaked" | sed 's/^/     /'; fail=1
  else
    echo "ok   outer repository tracks nothing under the engagement"
  fi
fi
exit $fail
