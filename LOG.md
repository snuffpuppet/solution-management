# Log

A chronological record of changes to this project, for traceability. One entry per change worth knowing about later: what changed, why, and the commit. Newest at the bottom. Append; never rewrite an entry.

Format: `YYYY-MM-DD | commit | what | why`

| Date | Commit | What | Why |
|---|---|---|---|
| 2026-09-07 | 6f3d619 | Initial commit: model 2.10, runner 2.10, README, diagrams. | Starting point. |
| 2026-09-08 | a18f4d9 | Transcript runner design spec. | Consultants will interview SMEs; we need current processes and needs distilled without legacy practice becoming requirements. |
| 2026-09-09 | 9471c95 | Spec: change request lifecycle rework. | CRs need options with impact, stakeholder approval, deferral to a named phase, and a workaround outcome that keeps its design. |
| 2026-09-09 | 50efbe7 | Implementation plan, eight tasks. | Executed by subagent-driven development with a review per task. |
| 2026-09-09 | 852b4b3, 7a7aa3e | Model 2.11: PRC process type. | Current practice becomes a register so the current state is knowable. Review found 4.1 header rules omitted processes; fixed. |
| 2026-09-09 | e1b2ca6, dfaca02 | Model 2.11: CR lifecycle. | States Proposed to Delivered plus terminal Deferred, Workaround accepted, Rejected; Impact assessment removed; I18 added. |
| 2026-09-09 | 4bb4a69 | Runner 2.11: consumes transcript claims. | Classification steps 0 to 0b read the claim class; CR status mapping updated. |
| 2026-09-09 | c157724, 301eb06 | WebVTT parser and tests. | Deterministic passages from Teams and Webex exports. Review found apostrophe and non-ASCII names dropped and closing v tags leaking; fixed. |
| 2026-09-09 | 491493d, 718d56e, 147db48, 4a6c4b8 | Transcript runner 1.0. | Rules, checkpoints, stages T0 to T4, claim record, classification guide, worked examples. Review widened passage splitting and tightened the current trigger. |
| 2026-09-09 | 78314d0 | Spec: role field allows unknown. | Unattributed passages need a role value; the spec had a gap. |
| 2026-09-09 | 8071370 | Transcripts folders, README rows, check-all.sh. | Aggregate check guards every document rule. |
| 2026-09-09 | b2a8d6f, 9fadd27 | Final review fix wave. | Fable review found a critical drift: a present-tense obligation ("has to go to finance") would become a Must requirement. Also multi-statement splits, MoSCoW on claims, BOM and NOTE parser defects, speaker table from parser, open item per Draft PRC. |
| 2026-09-09 | 3b203d1 | Merge to main. | All tasks reviewed, final review clean after fixes. |
| 2026-09-09 | 0e8d835, 49b2ec6 | Transcript runner 1.1: model awareness. | Opus 5 first, Fable later. Model and mode recorded per session and stage, strict mode for non-Fable, T2 self-check, Audit table, runner_model on claims. |
| 2026-09-09 | 96e3feb | Skills /ingest-transcript and /ingestion-report, report script. | Launchers only; the report script makes the numbers deterministic. Each skill tested by a live subagent run. |
| 2026-09-09 | 26520a2 | ARCHITECTURE.md 1.0 and project CLAUDE.md. | Principles P1 to P10, decisions D1 to D9 including D7 (no subagent orchestration in the runners), compliance check. |
| 2026-09-09 | 44edd3a | README rewritten for newcomers. | What, why, how; the deeper table points at single sources and repeats nothing. |
| 2026-09-09 | (this commit) | ARCHITECTURE.md 1.1 pipeline and runbook design; LOG.md; ENHANCEMENTS.md. | Traceability and a home for deferred work. |
