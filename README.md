# Solution management

Registers for tracking the artifacts of solution architecture on a vendor-delivered project: requirements, decisions, limitations, risks, open items and change requests, from our perspective as design authority.

| File | What it is |
|---|---|
| `solution-register-model.md` | The model. Tool-agnostic: item types, states, relationships, scope, register layouts, the outstanding and next-phase views, integrity rules, maintenance routine. The single description of how the registers work. |
| `solution-register-runner.md` | Instructions for Claude Opus 5 to read a knowledge base of atomic claims, extract items according to the model, and build the register pages in the Confluence design register folder, with read-only phases and hard checkpoints. |
| `diagrams/day-in-the-life.png` | Six things that happen on the project and how each runs through the registers. Start here. |
| `diagrams/management-flow.png` | One requirement followed through the registers, with the open item queue across the top. |
| `diagrams/artifact-workflow.png` | The open item queue, the records, and the limitation disposition paths. |
| `diagrams/src/` | Generator for the day-in-the-life diagram. Edit the strip text and re-render. |
| `work/` | Created by the runner. Intermediate results, questions, answers and the migration log for a run. Not committed. |

Changes to the model go in the model file. Changes to how the runner works go in the runner file. The diagrams are re-rendered to match.

Diagrams are hand-written SVG rendered to PNG with macOS tools only (`qlmanage` thumbnail of a square canvas, then `sips` centre crop).
