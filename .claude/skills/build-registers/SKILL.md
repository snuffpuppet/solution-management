---
name: build-registers
description: Use when the user wants the registers built or refreshed from every claims file without ingesting a new transcript, or types /build-registers, optionally with confluence
argument-hint: "[confluence]"
---

# Build registers

Start the register runner over the whole knowledge base. The runner document is the authority on every phase; this skill only picks the target and launches Phase 0.

## Steps

1. Target is `local` unless `$ARGUMENTS` is `confluence`. Any other argument: say `Usage: /build-registers [confluence]` and stop.
2. If `work/state.md` shows a register run that is not complete, tell the user and ask whether to resume it or start again.
3. Read `solution-register-runner.md` in full, then `solution-register-model.md` in full.
4. Execute the register runner from Phase 0 with that target and knowledge base `transcripts/claims/`. Follow its checkpoint protocol: stop at every checkpoint and wait for approval.

## Do not

- Skip the runner document because the phases look familiar. Read it every time; it changes.
- Touch `registers/` before Checkpoint 3a has been approved.
