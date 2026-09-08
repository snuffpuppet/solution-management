#!/usr/bin/env bash
set -u
f="$(dirname "$0")/../transcript-runner.md"
fail=0
need() { grep -qF -- "$1" "$f" && echo "ok   $1" || { echo "FAIL $1"; fail=1; }; }
need "# Transcript runner"
need "## 1. Inputs and outputs"
need "## 2. Operating rules"
need "## 3. Checkpoint protocol"
need "## 4. Local work folder"
need "tools/vtt-to-passages.sh"
need "Approve stage T"
need "work/transcripts/state.md"
need "## 5. Phases"
need "### T0. Register"
need "### T1. Passages and topics"
need "### T2. Classify"
need "### T3. Assemble claims"
need "### T4. Write claims"
need "## 6. Claim record"
need '"source_kind": "transcript"'
need "step-of"
need "retain no;"
need "## 7. Session summary"
exit $fail
