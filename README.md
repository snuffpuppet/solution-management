# Solution management

Registers for tracking the artifacts of solution architecture on a vendor-delivered project: requirements, decisions, limitations, risks, open items, change requests and current business processes, from our perspective as design authority.

| File | What it is |
|---|---|
| `solution-register-model.md` | The model. Tool-agnostic: item types, states, relationships, scope, register layouts, the outstanding and next-phase views, integrity rules, maintenance routine. The single description of how the registers work. |
| `solution-register-runner.md` | Instructions for Claude Opus 5 to read a knowledge base of atomic claims, extract items according to the model, and build the register pages in the Confluence design register folder, with read-only phases and hard checkpoints. |
| `transcript-runner.md` | Instructions for Claude Opus 5 to turn a WebVTT discovery-session transcript into atomic claims for the register runner: passages, topics, a classification guide that keeps legacy practice out of the registers, and staged checkpoints. Run before the register runner. |
| `tools/` | The WebVTT parser, the ingestion report script, their tests and fixtures, and grep checks that the model, runner and transcript runner documents still say what the checks expect. Run `tools/check-all.sh`. |
| `ARCHITECTURE.md` | The principles and decisions every change is checked against, with the compliance procedure and approved deviations. Read first. |
| `.claude/skills/` | Two slash commands: `/ingest-transcript <file.vtt>` starts the transcript runner on one file; `/ingestion-report` reports on ingestion effectiveness and the models that ran it. |
| `transcripts/` | `input/` for new transcripts (not committed), `processed/` for ingested ones, `claims/` for the JSON claims each session produced. |
| `diagrams/day-in-the-life.png` | Six things that happen on the project and how each runs through the registers. Start here. |
| `diagrams/management-flow.png` | One requirement followed through the registers, with the open item queue across the top. |
| `diagrams/artifact-workflow.png` | The open item queue, the records, and the limitation disposition paths. |
| `diagrams/src/` | Generator for the day-in-the-life diagram. Edit the strip text and re-render. |
| `work/` | Created by the runners. Intermediate results, questions, answers, session summaries and the migration log. Not committed. |

Changes to the model go in the model file. Changes to how the runner works go in the runner file. Changes to how transcripts become claims go in the transcript runner file. The diagrams are re-rendered to match.

Diagrams are hand-written SVG rendered to PNG with macOS tools only (`qlmanage` thumbnail of a square canvas, then `sips` centre crop).
