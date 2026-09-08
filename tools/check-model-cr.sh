#!/usr/bin/env bash
set -u
f="$(dirname "$0")/../solution-register-model.md"
fail=0
need() { grep -qF -- "$1" "$f" && echo "ok   $1" || { echo "FAIL $1"; fail=1; }; }
absent() { grep -qF -- "$1" "$f" && { echo "FAIL still present: $1"; fail=1; } || echo "ok   absent: $1"; }
need "| Change request | CR | Proposed, Options, For approval, Approved, Submitted, Delivered*, Deferred*, Workaround accepted*, Rejected* |"
need "Options (numbered list"
need "Chosen option"
need "CR page"
need "| CR | deferred as | REQ (the requirement also carries \"triggered by CR-nnn\") |"
need "| CR | dispositioned by | DEC (on Workaround accepted) |"
need "| Change requests | ID, Title, Status, Phase, Reason, Options, Chosen option, Consulted, Approved by, Approved on, Disposition record, CR page, Implemented by, Raised on, Raised by, Scope, Vendor ref, Links, Source, Updated |"
need "4. Change requests in Proposed, Options or For approval."
need "| I18 Change request disposition |"
absent "Impact assessment"
absent "Deferring a change request is a change of Phase"
need "and change requests in Deferred, are excluded from this view"
exit $fail
