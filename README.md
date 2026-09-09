# Solution management

Version 1.6, 9 September 2026.

## What this repository is

This repository holds the method, not any one project's data. `ingester/` is the how: the item model, the two AI runners, the tools and the architecture document. `engagements/<name>/` is the what: one engagement's transcripts, claims, registers and working state. A working session runs with an engagement as its working directory, so the how-documents in `ingester/` resolve their own paths with a `<HOW>/` prefix while the engagement's own data (`transcripts/`, `registers/`, `work/`) stays bare.

`engagements/` is gitignored here and each engagement under it is its own, separately versioned repository, so this repository can be shared or pushed carrying only the method, with nothing of any client's or vendor's data reachable from it.

Start at `ingester/CLAUDE.md`. It is the authority on the layout, on the `<HOW>` placeholder, and on how to run the pipeline from an engagement.

## What the method does

A way of keeping track of a solution design when a vendor builds most of it and we are the design authority. It tracks eight kinds of thing: requirements, decisions, limitations, risks, open items, change requests, the business processes people follow today, and the systems those processes use today. Each kind lives in its own register, a table you can open in a meeting and see what is outstanding.

Two AI runners, executed inside Claude Code with a human approving every stage, do the heavy lifting:

- the **register runner** reads an engagement's claims and builds its registers as markdown tables under `registers/`, or in Confluence when asked;
- the **transcript runner** turns a recorded discovery session between consultants and our business experts into those claims.

## Why it exists

Design documents drift. Decisions get made in meetings and lost. Vendor limitations are discovered late and nobody records what was done about them. And when consultants interview business experts, the experts describe how things work today, how they used to work, and what they want, all in one breath. We want the current state captured faithfully, the wants captured as requirements, and the old ways left out of the requirements entirely.

The registers give every item one home, one owner and one next action. The transcript runner makes sure what reaches them came from someone's words, with a quote to prove it, and that a human agreed before anything was written.

## How to use it

You need Claude Code and a checkout of this repository, with an engagement folder to work in. Nothing else is installed.

**Start a session.** Open Claude Code with an engagement as the working directory and say:

```
Read HANDOVER.md and continue from its next action.
```

The handover file says where the last session stopped. The agent also checks that nothing is uncommitted and that the document checks pass before it starts. If a runner was left mid-stage, it tells you and resumes from that stage rather than starting again.

**Ingest a transcript.** Export the meeting from Teams or Webex as a `.vtt` file, then run `/ingest-transcript path/to/meeting.vtt` from the engagement. It stages the file, runs the transcript runner's five stages with a checkpoint at each, then chains straight into the register runner so the engagement's registers are updated in the same pass. Legacy practice is listed for you to see but never becomes a claim the registers will use.

**Build or refresh the registers.** Every ingestion does this on its own. To do it without a new transcript, type `/build-registers` from the engagement; add `confluence` to write to a Confluence design register folder instead of `registers/`.

**See how ingestion is going.** Type `/ingestion-report` from the engagement. It shows, per session and per model, how many questions the runner asked and how often you overturned its answer, so you can judge whether a given model is doing the job.

**Maintain the registers by hand.** The rules for adding an item, closing an open item and running the weekly routine are in `ingester/solution-register-model.md`, section 10.

**End a session.** Say "hand over" or type `/handover` from wherever you are working. The skill rewrites that folder's `HANDOVER.md` with what is in flight and the next action, and, in an engagement, records anything found about the method in `FINDINGS.md` rather than the ingester's own `ENHANCEMENTS.md`.

## Layout

| Folder | Holds |
|---|---|
| `ingester/` | The method: the model, the roles document, both runner documents, `tools/`, `diagrams/`, `docs/` and `ARCHITECTURE.md`. Read `ingester/CLAUDE.md` first. |
| `engagements/<name>/` | One engagement's `transcripts/`, `registers/`, `work/`, `FINDINGS.md`, `HANDOVER.md`, `LOG.md` and `CLAUDE.md`. Gitignored here; each is its own git repository. |
| `.claude/skills/` | The four slash commands, at the repository root, that launch a runner or a tool. One set of launchers serves both the ingester and any engagement, since a skill's relative paths resolve against the working directory. |

`registers/` is always the engagement's, never the repository's own: this repository carries the method only, and every register lives inside the engagement that produced it.

## Going deeper

`ingester/ARCHITECTURE.md` records the principles and decisions behind the design, including how the method and engagements stay separate, and is the place to check before any structural change. `ingester/CLAUDE.md` covers the `<HOW>` placeholder and the write-isolation rule in full.
