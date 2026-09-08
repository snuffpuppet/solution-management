# Solution management

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

**Ingest a transcript.** Export the meeting from Teams or Webex as a `.vtt` file, then in Claude Code type:

```
/ingest-transcript path/to/meeting.vtt
```

The runner works through five stages and stops at the end of each one to show you what it found and ask for approval: who spoke and their roles, the passages and topics, how each passage was classified, the claims it assembled, and finally the write. Answer its questions and say "approved" to move on. Legacy practice is listed for you to see but never becomes a claim the registers will use.

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
