#!/usr/bin/env bash
set -u
f="$(dirname "$0")/../solution-register-runner.md"
fail=0
need() { grep -qF -- "$1" "$f" && echo "ok   $1" || { echo "FAIL $1"; fail=1; }; }
absent() { grep -qF -- "$1" "$f" && { echo "FAIL still present: $1"; fail=1; } || echo "ok   absent: $1"; }
need "Version 3.1, 9 September 2026"
need "### 7.1 Local target (default)"
need "### 7.2 Confluence target"
need "4a. **Existing rows are the record.**"
need "tools/check-registers.sh"
need "| \`registers/systems.md\` |"
need "target: local | confluence"
need "Local target, no source pages"
need "0a1. **Transcript claim of class system?**"
need "Apply the subject test first"
need "| Register: Systems |"
need "source_kind: transcript"
need "0. **Transcript claim of class legacy or context?**"
need "0a. **Transcript claim of class current or current-not-needed?**"
need "becomes Deferred with a question asking for the phase"
need "becomes Accepted with a question asking for the DEC"
absent "Workaround accepted"
need "| Register: Processes |"
need "transcript-runner.md"
need "transcript claims by class"
absent "at least Submitted. A change request or requirement described as deferred or for a later release gets Phase = next phase"
need "moscow field fills MoSCoW"
need "Confirm PRC-pnnn"
exit $fail
