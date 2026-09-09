# The ingester

Version 1.0, 9 September 2026. Owner: Adam Moyes.

This folder is the how. It holds the method and nothing about any particular
engagement. Read this file before running anything.

## The `<HOW>` binding

`<HOW>` is the ingester root, the folder containing this file. From an
engagement it is `../../ingester`.

`<HOW>` is a documentation placeholder, not a shell variable. Substitute it
when you construct a command. Never pass it to a shell unsubstituted.

This is the only file in the ingester permitted to contain `../`. Every
other how-document writes `<HOW>/` instead, so that exactly one file knows
how deep an engagement sits.

## Which paths resolve where

| Written as | Resolves against | Examples |
|---|---|---|
| `<HOW>/...` | the ingester root | `<HOW>/tools/vtt-to-passages.sh`, `<HOW>/roles.md` |
| a bare relative path | the working directory, always an engagement | `transcripts/claims/`, `registers/`, `work/` |

The four skills in `.claude/skills/` at the repository root are the one set
of launchers for both contexts. A skill's bare relative paths resolve
against the working directory, so run from an engagement, `HANDOVER.md` and
`LOG.md` mean that engagement's; run from the ingester, they mean the
ingester's. Nothing under `.claude/skills/` belongs to this folder or to any
engagement.

An engagement cannot inherit them. Being its own git repository, a session
launched there treats the engagement as the whole project, so the root
`.claude/skills` falls outside it and no slash command is found. Every
engagement therefore carries this symlink, and a new engagement is not
usable until it does:

    engagements/<name>/.claude/skills -> ../../../.claude/skills

`<HOW>/tools/check-engagement.sh` asserts all four skills are reachable, so
a missing symlink fails a check rather than surfacing as an unknown command.

## Write isolation

No action taken while working in an engagement may write any file outside
that engagement's folder. Reads across the boundary are expected. Writes are
not. `<HOW>/tools/check-isolation.sh <root>` asserts it.

A finding about the method, discovered while working in an engagement, goes
in that engagement's `FINDINGS.md`. An ingester session promotes it into
`<HOW>/ENHANCEMENTS.md` with an id. Ids are issued only here.

## Every commit

Run the check for the folder you are working in, and append one line to that
folder's `LOG.md`.

| Working in | Check | Log |
|---|---|---|
| an engagement | `<HOW>/tools/check-engagement.sh` | that engagement's `LOG.md` |
| the ingester | `<HOW>/tools/check-how.sh` | `<HOW>/LOG.md` |

## The documents

| File | Responsibility |
|---|---|
| `<HOW>/ARCHITECTURE.md` | principles, decisions, the compliance check |
| `<HOW>/solution-register-model.md` | what items are: types, states, fields, relationships |
| `<HOW>/roles.md` | who speaks in a session and what each role may yield |
| `<HOW>/transcript-runner.md` | a WebVTT transcript becomes atomic claims |
| `<HOW>/solution-register-runner.md` | claims become register rows |
| `<HOW>/tools/` | deterministic shell, and the checks over these documents |

## Before any structural change

Read `<HOW>/ARCHITECTURE.md` and run its section 5 compliance check.

## Engagements are outside this repository's git history

`engagements/` is gitignored in the outer repository. Each engagement under
it is its own nested git repository with its own history.

Because of this, `git clean -fdx` run at the repository root DELETES an
ignored engagement, its data and its `.git`, since `-x` tells clean to
target ignored paths too. Never run `git clean -fdx` here. If a clean is
needed, use `git clean -fd` without `-x`, which leaves ignored paths alone.
