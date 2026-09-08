# Project instructions

## Every session, on start

1. Read `HANDOVER.md`. It says where the last session stopped and what to do next.
2. Run `git status` and `tools/check-all.sh`. Both must be clean before new work.
3. If `work/transcripts/state.md` or `work/state.md` shows an incomplete run, mention it to the user before starting anything else.

## Before any structural change

Read `ARCHITECTURE.md`: creating, moving, renaming or deleting files, adding a tool, changing a runner stage, changing a classification rule, or changing an item type, state, field or relationship. Run its section 5 compliance check and report the result before implementing. A conflict with a principle or decision is a STOP until the user explicitly overrides it; record approved overrides under its Deviations section.

## Every commit

Run `tools/check-all.sh` first. It must be all ok. Append a line to `LOG.md` with Kind `change`, `decision` or `ruling`. A ruling is a judgement call made on the user's behalf; log it when you make it, not later. Record deferred work in `ENHANCEMENTS.md` rather than leaving it in conversation.

## Ending a session

When the user says they are leaving, asks for a handover or handoff, or types `/handover`, run the `handover` skill. It rewrites `HANDOVER.md` from the template below, replacing every section so the file stays transient, commits, and verifies with `tools/handover-check.sh`. The check is on demand, not automatic; a user who wants it enforced can add it as a Stop hook in `.claude/settings.local.json`:

```
{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"tools/handover-check.sh"}]}]}}
```

```
# Handover

Updated: <YYYY-MM-DD>
Last commit: <short hash of the latest commit that is not only HANDOVER.md or LOG.md>

## In flight
<one to three lines, or "Nothing">

## Next action
<one line>

## Blocked
<one line, or "Nothing">

## Notes for the next session
<at most three lines>
```

## Language and versions

Australian English. No em dashes in any document. Bump the version line of any document you change.

Inputs and outputs are persisted in git: transcripts, claims, `work/` state, questions, summaries and reports. Only scratch (`tmp/` folders, `.superpowers/`) is ignored.
