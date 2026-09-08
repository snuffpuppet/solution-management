# Log

A chronological record of changes to this project, for traceability. One entry per change worth knowing about later: what changed, why, and the commit. Newest at the bottom. Append; never rewrite an entry.

Format: `YYYY-MM-DD | commit | kind | what | why`. Kind is `change` (something in the repo changed), `decision` (the owner decided something), or `ruling` (the agent decided on the owner's behalf; say what it costs if wrong).

| Date | Commit | Kind | What | Why |
|---|---|---|---|---|
| 2026-09-07 | 6f3d619 | change | Initial commit: model 2.10, runner 2.10, README, diagrams. | Starting point. |
| 2026-09-08 | a18f4d9 | change | Transcript runner design spec. | Consultants will interview SMEs; we need current processes and needs distilled without legacy practice becoming requirements. |
| 2026-09-09 | 9471c95 | change | Spec: change request lifecycle rework. | CRs need options with impact, stakeholder approval, deferral to a named phase, and a workaround outcome that keeps its design. |
| 2026-09-09 | 50efbe7 | change | Implementation plan, eight tasks. | Executed by subagent-driven development with a review per task. |
| 2026-09-09 | 852b4b3, 7a7aa3e | change | Model 2.11: PRC process type. | Current practice becomes a register so the current state is knowable. Review found 4.1 header rules omitted processes; fixed. |
| 2026-09-09 | e1b2ca6, dfaca02 | change | Model 2.11: CR lifecycle. | States Proposed to Delivered plus terminal Deferred, Workaround accepted, Rejected; Impact assessment removed; I18 added. |
| 2026-09-09 | 4bb4a69 | change | Runner 2.11: consumes transcript claims. | Classification steps 0 to 0b read the claim class; CR status mapping updated. |
| 2026-09-09 | c157724, 301eb06 | change | WebVTT parser and tests. | Deterministic passages from Teams and Webex exports. Review found apostrophe and non-ASCII names dropped and closing v tags leaking; fixed. |
| 2026-09-09 | 491493d, 718d56e, 147db48, 4a6c4b8 | change | Transcript runner 1.0. | Rules, checkpoints, stages T0 to T4, claim record, classification guide, worked examples. Review widened passage splitting and tightened the current trigger. |
| 2026-09-09 | 78314d0 | change | Spec: role field allows unknown. | Unattributed passages need a role value; the spec had a gap. |
| 2026-09-09 | 8071370 | change | Transcripts folders, README rows, check-all.sh. | Aggregate check guards every document rule. |
| 2026-09-09 | b2a8d6f, 9fadd27 | change | Final review fix wave. | Fable review found a critical drift: a present-tense obligation ("has to go to finance") would become a Must requirement. Also multi-statement splits, MoSCoW on claims, BOM and NOTE parser defects, speaker table from parser, open item per Draft PRC. |
| 2026-09-09 | 3b203d1 | change | Merge to main. | All tasks reviewed, final review clean after fixes. |
| 2026-09-09 | 0e8d835, 49b2ec6 | change | Transcript runner 1.1: model awareness. | Opus 5 first, Fable later. Model and mode recorded per session and stage, strict mode for non-Fable, T2 self-check, Audit table, runner_model on claims. |
| 2026-09-09 | 96e3feb | change | Skills /ingest-transcript and /ingestion-report, report script. | Launchers only; the report script makes the numbers deterministic. Each skill tested by a live subagent run. |
| 2026-09-09 | 26520a2 | change | ARCHITECTURE.md 1.0 and project CLAUDE.md. | Principles P1 to P10, decisions D1 to D9 including D7 (no subagent orchestration in the runners), compliance check. |
| 2026-09-09 | 44edd3a | change | README rewritten for newcomers. | What, why, how; the deeper table points at single sources and repeats nothing. |
| 2026-09-09 | 8ac4b61 | change | ARCHITECTURE.md 1.1 pipeline and runbook design; LOG.md; ENHANCEMENTS.md. | Traceability and a home for deferred work. |
| 2026-09-09 | 4e6ea71 | ruling | Worked on a branch in place rather than a worktree. | Docs-only repo, no build. Cost if wrong: none. |
| 2026-09-09 | 852b4b3 | ruling | Task reviews on Sonnet, final review on Fable with a goals lens. | User asked mid-run for a Fable review. Cost: one review pass. |
| 2026-09-09 | 7a7aa3e | ruling | Added processes to model 4.1 header rules, which the plan omitted. | Spec 3.2 says Owner, Implemented by and Vendor ref are not used on PRC. Cost: three words. |
| 2026-09-09 | e1b2ca6 | ruling | Accepted a check line adjusted to match the mandated link row text. | Plan check and plan text contradicted; intent preserved. Cost: none. |
| 2026-09-09 | dfaca02 | ruling | Next-phase exclusion sentence covers Deferred change requests. | CR next-phase membership is by status now. Cost: none. |
| 2026-09-09 | 718d56e | ruling | same-as folds into the existing PRC candidate while no row is published; after that a new PRC and Superseded. | Reconciles runner step 0a with model 4.4. Cost: one sentence. |
| 2026-09-09 | 78314d0 | ruling | Spec amended so role allows unknown. | Unattributed passages need a value; the document was right and the spec had a gap. Cost: none. |
| 2026-09-09 | 4a6c4b8 | ruling | Widened the passage split rule and tightened the "we do" trigger. | Appendix rows were unreachable by a literal reader. Cost: none. |
| 2026-09-09 | b2a8d6f | ruling | Each Draft PRC gets an open item "Confirm PRC-pnnn" with a blank owner and one question per session. | Satisfies I3 without inventing an owner; open items are the work queue. Cost: a few rows to close. |
| 2026-09-09 | 9fadd27 | ruling | Applied three residual wording edits directly rather than a second fix wave. | Three-word edits, checks green. Cost: none. |
| 2026-09-09 | 26520a2 | decision | No subagent orchestration inside the runners (ARCHITECTURE D7). | Owner asked for push-back if quality would suffer; it would. |
| 2026-09-09 | 5d0cfbc | decision | Inputs and outputs are persisted in git; only scratch is ignored. HANDOVER.md is transient. A Stop hook enforces the handover. | Owner: no important files gitignored; handover must not grow; user needs a mechanism, not a reminder. |
| 2026-09-09 | 5d0cfbc | change | `work/` and `transcripts/input/` committed; T4 commits session records; runners 2.12 and 1.2; LOG gains Kind; HANDOVER.md; `tools/handover-check.sh` Stop hook; CLAUDE.md session checklists; ARCHITECTURE 1.2. | Traceability items 1 to 3. |
| 2026-09-09 | f9e0ed6 | decision | Handover is user-controlled: a `/handover` skill and on-demand check, not a Stop hook. Hook stays available per user in settings.local.json. | Owner: the user keeps control of when to hand over. |
| 2026-09-09 | b90106c | change | README: session start, handover and persistence added to the usage section. | Reflects the user-controlled handover workflow. |
| 2026-09-09 | 78614d4 | decision | Ignore `.obsidian/`. | Editor state, not project content. |
| 2026-09-09 | 1cd099b | change | README 1.1: quickstart section at the top covering export, command, stages and their questions, and where output lands and why session ids cannot clash. | User asked for a quickstart first. |
| 2026-09-09 | a581428 | change | README 1.2: quickstart tables moved out of the numbered list so Obsidian renders them. | Tables nested in list items do not render in Obsidian. |
| 2026-09-09 | a06b7f6 | change | README 1.3: quickstart gains the register runner half: launch instruction, phase table, and how current, need and legacy claims become PRC, REQ or nothing. | User: quickstart did not mention creating requirements, decisions and existing processes. |
| 2026-09-09 | ac181ce | change | ENHANCEMENTS E10: learning loop that reduces questions over time, a candidate principle pending an ARCHITECTURE check. | User proposed reducing the human in the loop via a self-improvement stage; recorded, not applied. |
| 2026-09-09 | 81882d3 | decision | ARCHITECTURE 1.4: P12, fewer questions over time, never at the cost of quality. Overturn rate outranks question count; findings are human-approved document edits; checkpoints unchanged. Compliance check: PROCEED, no violations. E10 now implements P12. | Owner: reduce human in the loop only where the outcome improves, quality first. |
| 2026-09-09 | 0d07d49 | change | Audit rows carry a Runner column: the transcript runner document version that ran the stage. Runner 1.3, report groups by model, mode and runner, fixture and tests updated, check gains an assertion, ARCHITECTURE 1.5 D6. Compliance check: PROCEED. | P12 needs overturn rates comparable before and after a document edit. |
| 2026-09-09 | 4351935 | change | ENHANCEMENTS E11: runner version on each claim record, deferred until the first data-driven guide edit. | Kept off the P7 interface until needed. |
| 2026-09-09 | 0049c03 | change | Transcript runner 1.4: speaker roles consultant, sme, vendor, architect (guide step 1a; vendor and architect never yield current, legacy or need). Stakeholder registry at transcripts/stakeholders.md read at T0, appended on approval, checked by tools/check-stakeholders.sh. Register runner 2.13 reads role for Raised by and Consulted; the D2 interface now includes role. README 1.4, ARCHITECTURE 1.6, ENHANCEMENTS E12 expertise. Compliance check: PROCEED. | Vendor professional services are SMEs for their platform, never for our processes or needs; decisions stay ours. Kept simple: no new class, no expertise yet. |
