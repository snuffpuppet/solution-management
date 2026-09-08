# Solution management

Version 1.4, 9 September 2026.

## Quickstart

1. Export the meeting from Teams or Webex as a `.vtt` file. The first line must be `WEBVTT`.
2. Open Claude Code in this repository and run `/ingest-transcript path/to/meeting.vtt`. The file is copied into `transcripts/input/` unchanged. You can also drop it there yourself and give that path.
3. Approve each stage as the runner stops for it. It asks "Approve stage Tn and proceed to Tn+1?" and waits; silence is not approval.
4. Find the output under the session id, listed below.

The stages and what each asks you:

| Stage | What it does | What it asks you |
|---|---|---|
| T0 Register | Assigns the session id, reads the speakers, records the model | Confirm who spoke and their roles (SME, consultant, vendor or architect), the meeting date, and the mode. Speakers already in `transcripts/stakeholders.md` are filled in for you |
| T1 Passages | Splits the transcript into passages and groups them by topic | Rename or merge topics |
| T2 Classify | Gives every passage one class: current, legacy, need, context and so on | Answer every numbered question where it was unsure; it will not go on until all are answered |
| T3 Assemble | Turns classified passages into claims, with quotes, and links them to earlier sessions | Whether a process seen before is an update or a distinct process |
| T4 Write | Shows a dry run, writes the claims file, commits | Approve the dry run |

Each session gets `T` plus a three-digit number, one higher than any id already present in `work/transcripts/` or `transcripts/claims/`, so a new ingestion can never overwrite an earlier one. T4 also refuses to run if the claims file already exists.

| Path | Contents |
|---|---|
| `transcripts/claims/T<nnn>.json` | The claims, the file the register runner reads |
| `transcripts/processed/T<nnn>-meeting.vtt` | The transcript, moved out of `input/` with the id prefixed |
| `work/transcripts/T<nnn>/` | Passages, classifications, the claims draft, your questions and answers, and the session summary |
| `work/transcripts/state.md` | The session table and audit rows across every ingestion |
| `transcripts/stakeholders.md` | Who may appear in a transcript, with their speaker tags and role; grows as sessions are ingested |

Everything above is committed at each checkpoint, so an interrupted run resumes from its last stage next time you start Claude Code.

### Then build the registers

Claims are not yet requirements. The register runner reads every claims file, plus any design documents in the knowledge base, and turns them into register items: requirements (REQ), decisions (DEC), limitations (LIM), risks (RSK), open items (OI), change requests (CR), and the existing business processes the experts described (PRC). Start Claude Code with the Opus 5 model and give it:

```
Read solution-register-runner.md and solution-register-model.md in full. Execute the runner from Phase 0. The knowledge base is at transcripts/claims/. Stop at every checkpoint and wait for my approval.
```

| Phase | What it does | What it asks you |
|---|---|---|
| Phase 0 Preflight | Checks Confluence access and finds the design register folder | Confirm the space, the folder, the page title prefix and id numbering |
| Phase 1 Inventory | Counts claims by source and lists what Confluence already holds | Which sources or pages to exclude |
| Phase 2 Extract | Proposes one candidate item per claim, with type, relations and scope | Answer its questions: unclear types, duplicate pairs, who implements each item |
| Phase 3 Build | Shows a dry run of every register page, then writes them | Approve the dry run; accept or fix integrity failures such as items with no owner |
| Phase 4 Reconcile | Proposes edits to the source pages that tables came from | Yes or no per page |
| Phase 5 Handover | Summarises what was written and what is left to fill by hand | Nothing |

Nothing is written to Confluence before Phase 3, and only inside the design register folder. A SME claim classified `current` at T2 becomes a PRC row with its steps; a `need` becomes a REQ; a `legacy` claim never reaches a register. Its working files live in `work/`, beside the transcript runner's, and are committed at each checkpoint in the same way.

## What this is

A way of keeping track of a solution design when a vendor builds most of it and we are the design authority. It tracks seven kinds of thing: requirements, decisions, limitations, risks, open items, change requests, and the business processes people follow today. Each kind lives in its own register, a table you can open in a meeting and see what is outstanding.

Two AI runners, executed inside Claude Code with a human approving every stage, do the heavy lifting:

- the **register runner** reads a knowledge base of claims and builds the registers in Confluence;
- the **transcript runner** turns a recorded discovery session between consultants and our business experts into those claims.

## Why it exists

Design documents drift. Decisions get made in meetings and lost. Vendor limitations are discovered late and nobody records what was done about them. And when consultants interview business experts, the experts describe how things work today, how they used to work, and what they want, all in one breath. We want the current state captured faithfully, the wants captured as requirements, and the old ways left out of the requirements entirely.

The registers give every item one home, one owner and one next action. The transcript runner makes sure what reaches them came from someone's words, with a quote to prove it, and that a human agreed before anything was written.

## How to use it

You need Claude Code and a checkout of this repository. Nothing else is installed.

**Start a session.** Open Claude Code in the repository and say:

```
Read HANDOVER.md and continue from its next action.
```

The handover file says where the last session stopped. The agent also checks that nothing is uncommitted and that the document checks pass before it starts. If a runner was left mid-stage, it tells you and resumes from that stage rather than starting again.

**Ingest a transcript.** See the quickstart above. Legacy practice is listed for you to see but never becomes a claim the registers will use.

**Build or refresh the registers.** Once transcripts and design documents have been ingested into the knowledge base, launch Claude Code and give it the instruction at the end of `solution-register-runner.md`. It reads the knowledge base, proposes register items with their sources, asks you the questions it cannot answer, shows you a dry run, and only then writes to the Confluence design register folder.

**See how ingestion is going.** Type:

```
/ingestion-report
```

It shows, per session and per model, how many questions the runner asked and how often you overturned its answer, so you can judge whether a given model is doing the job.

**Maintain the registers by hand.** The rules for adding an item, closing an open item and running the weekly routine are in the model document, section 10. They take a few minutes per item.

**End a session.** Say "hand over" or type:

```
/handover
```

The agent commits finished work, rewrites `HANDOVER.md` with what is in flight and the next action, records anything deferred in `ENHANCEMENTS.md`, and gives you the line to paste next time. You choose when this happens; nothing runs automatically. If you want it enforced, `CLAUDE.md` shows the one-line hook to add to your own settings.

**Everything is in git.** Transcripts, claims, the runners' state and questions, your answers, session summaries and reports are all committed, so any session can be reconstructed later. `LOG.md` records what changed and why, including the judgement calls the agent made on your behalf.

## Going deeper

Each file below is the single source for its subject. This README does not repeat their content.

| Read | For |
|---|---|
| `ARCHITECTURE.md` | The principles and decisions behind the design, and the check every change must pass. Read this before changing anything. |
| `HANDOVER.md` | Where the last session stopped and what to do next. Transient, rewritten every session. |
| `LOG.md` | What changed, when and why, with commits, and the rulings made along the way. |
| `ENHANCEMENTS.md` | Work agreed for a later session, with the trigger to start it. |
| `solution-register-model.md` | The item types, states, fields, relationships, views and integrity rules. |
| `solution-register-runner.md` | How the register runner works, stage by stage. |
| `transcript-runner.md` | How the transcript runner works, its classification guide and worked examples. |
| `docs/superpowers/specs/` | The design specification the transcript runner was built from. |
| `tools/` | The parser, the report script, their tests, and `check-all.sh`, which verifies the documents still say what the tools expect. |
| `.claude/skills/` | The slash commands: ingest a transcript, report on ingestion, hand over a session. They only launch the runners and tools. |
| `transcripts/` | Where transcripts go in and where processed transcripts and claims come out. |
| `diagrams/` | Pictures of the model: a day in the life, one requirement through the registers, and the open item queue. |

`work/` holds the runners' state, questions and summaries and is committed at every checkpoint.
