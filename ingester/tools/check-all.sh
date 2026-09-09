#!/usr/bin/env bash
# Runs the how checks, then one engagement's checks.
# Usage: tools/check-all.sh [engagement root]   default: .
set -u
here="$(cd "$(dirname "$0")" && pwd)"
fail=0
echo "###### how ######";        "$here/check-how.sh"        || fail=1
echo "###### engagement ######"; "$here/check-engagement.sh" "${1:-.}" || fail=1
exit $fail
