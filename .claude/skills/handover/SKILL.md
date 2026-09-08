---
name: handover
description: Use when the user is ending a session, says they are leaving, asks to hand over or hand off to a new session, or types /handover
---

# Handover

Leave the repository in a state a fresh session can pick up from `HANDOVER.md` alone.

## Steps

1. Run `git status --short`. If tracked files are modified, finish or discard that work first: run `tools/check-all.sh`, append the `LOG.md` line, and commit. Do not hand over with uncommitted changes.
2. Rewrite `HANDOVER.md` in full from the template in `CLAUDE.md`. Replace every section; never append. Keep it under 25 lines. `Last commit` is the latest commit that is not only `HANDOVER.md` or `LOG.md`: `git log -1 --format=%h -- . ':!HANDOVER.md' ':!LOG.md'`.
3. Move anything agreed for later into `ENHANCEMENTS.md` with its trigger. Anything decided this session that is not yet in `LOG.md` gets a line now.
4. Commit `HANDOVER.md`, `LOG.md` and `ENHANCEMENTS.md` with the message `Handover <date>`.
5. Run `tools/handover-check.sh` and confirm it prints nothing and exits 0. If it exits 2, fix what it names and repeat.
6. Print the next session's opening line for the user to paste: `Read HANDOVER.md and continue from its next action.`

## Do not

- Summarise the whole session into the handover. Three lines of notes at most; the log has the history.
- Leave a runner mid-stage without saying so under In flight, with the session id and stage.
