#!/usr/bin/env bash
set -u
f="$(dirname "$0")/../solution-register-model.md"
fail=0
need() { grep -qF -- "$1" "$f" && echo "ok   $1" || { echo "FAIL $1"; fail=1; }; }
need "Version 2.11, 9 September 2026"
need "| Current practice | This is how we do X today. | PRC |"
need "| Process | PRC | Draft, Confirmed, Superseded*, Retired* |"
need "| Process | An SME describes work performed today."
need "- Process: Draft on extraction."
need "| REQ | replaces | PRC-nnn/step n |"
need "| REQ | preserves | PRC-nnn/step n |"
need "| LIM | constrains | PRC |"
need "| OI | clarifies | PRC |"
need "| PRC | superseded by | PRC |"
need "| Processes | ID, Title, Status, Trigger, Steps, Systems, Frequency, Described on, Raised by, Scope, Links, Source, Updated |"
need "7. Processes in Draft older than 14 days, measured from Described on."
need "| I17 Process steps |"
need "a PRC in Draft"
need "change requests or processes, which carry Raised by instead"
need "Not used on processes."
exit $fail
