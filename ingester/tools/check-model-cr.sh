#!/usr/bin/env bash
set -u
f="$(dirname "$0")/../solution-register-model.md"
fail=0
need() { grep -qF -- "$1" "$f" && echo "ok   $1" || { echo "FAIL $1"; fail=1; }; }
absent() { grep -qF -- "$1" "$f" && { echo "FAIL still present: $1"; fail=1; } || echo "ok   absent: $1"; }
need "| Change request | CR | Proposed, Options, For approval, Approved, Submitted, Deferred, Delivered*, Withdrawn*, Rejected* |"
need "| Limitation | LIM | Identified, Under assessment, Accepted*, Change requested*, Resolved* |"
need "| Limitations | ID, Title, Status, Identified on, Impact, Options, Chosen option, Disposition record,"
absent "Workaround accepted"
absent "deferred as REQ"
need "previously dispositioned by"
need "1. Change requests in Deferred, grouped by Phase"
need "Options (numbered list"
need "Chosen option"
need "CR page"
need "| Change requests | ID, Title, Status, Phase, Reason, Options, Chosen option, Consulted, Approved by, Approved on, CR page, Implemented by, Raised on, Raised by, Scope, Vendor ref, Links, Source, Updated |"
need "4. Change requests in Proposed, Options or For approval."
need "| I18 Deferred change request |"
absent "Impact assessment"
absent "Deferring a change request is a change of Phase"
need "and change requests in Deferred, are excluded from this view"
exit $fail
