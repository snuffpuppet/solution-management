# Architecture

Version 1.9, 9 September 2026. Owner: Adam Moyes.

This document records the decisions that shape this project and the principles that guide changes to it. Any change to the repository is checked against it first. A decision here stands until the owner explicitly overrides it; a change that conflicts with one is a stop, not a judgement call. Deviations the owner approves are recorded at the end.

---

## 1. What the project is

A set of playbook-style markdown documents, plus a few shell tools, for managing solution architecture registers on a vendor-delivered project and for feeding those registers from discovery-session transcripts. Two AI runners execute the documents inside Claude Code, one human at a time, with a checkpoint at every stage.

| Layer | File | Responsibility |
|---|---|---|
| Model | `solution-register-model.md`, `roles.md` | What items are: types, states, fields, relationships, views, integrity rules. Who speaks in a session and what each role may yield. Tool-agnostic. |
| Register runner | `solution-register-runner.md` | How claims in a knowledge base become register pages in Confluence. |
| Transcript runner | `transcript-runner.md` | How a WebVTT transcript becomes atomic claims for the register runner. |
| Tools | `tools/` | Deterministic shell: the parser, the report script, their tests, and grep checks over the documents. |
| Skills | `.claude/skills/` | Thin slash commands that launch a runner or a tool. They hold no rules of their own. |
| Data | `transcripts/` | Input, processed transcripts, claims and the stakeholder registry (all committed). |
| Working state | `work/` | Per-run state, questions, drafts, summaries and reports. Committed at every checkpoint; only `tmp/` subfolders are scratch. |

---

## 2. Principles

P1. **The document is the program.** Behaviour lives in the markdown the runner reads, not in prompts typed at launch and not in skills. If a runner needs to behave differently, the runner document changes, with a check that proves it.

P2. **Never invent, always trace.** Every claim carries a verbatim quote. Every register item traces to claims or to an explicit human instruction. Ambiguity goes to a questions list. This is the rule that keeps legacy practice out of the registers, and it outranks convenience.

P3. **Humans gate every stage.** A checkpoint is a full stop. Nothing is written to the knowledge base or to Confluence before a human has seen a dry run and said yes. Silence is not approval.

P4. **Deterministic where possible, judgement where necessary.** Anything that can be done with a shell tool is done with one and tested. The LLM does classification and grouping only. When a step could be either, choose the tool.

P5. **One runner holds the whole session.** Classification and grouping depend on context across the entire transcript, so a single agent does T2 and T3 with everything in view. See Decision D7.

P6. **Measure the model, then decide.** The pipeline records which model ran each stage and how often the human overturned it. Changes motivated by model quality or cost are made after the audit table shows the need, not before.

P7. **Separate the ingester from the lifecycle.** The model can be used without the transcript runner, and the transcript runner can change without touching the model. The only coupling is the claim record's class and relation vocabulary.

P8. **No new software on the host.** Tools use bash, awk, sed and grep. Anything else runs in Docker or does not run.

P9. **Australian English, no em dashes, versioned documents.** Every document carries a version and date. The check scripts enforce the em dash rule.

P10. **A check for every rule that matters.** When a document gains a rule another document or tool depends on, `tools/check-all.sh` gains an assertion for it in the same commit.

P11. **Inputs and outputs are persisted.** Transcripts, claims, runner state, questions, answers, summaries and reports are committed. Only scratch is ignored. A file that a later session or a later reader would want is never in `.gitignore`.

P12. **Fewer questions over time, never at the cost of quality.** The human's effort per session should fall as the runners learn, but quality of output outranks question count. Two measures decide, in this order: the rate at which the human overturns a runner's proposal, then the number of questions per hundred passages. A runner document is edited to ask less only when the Audit table shows the change did not raise the overturn rate. Findings come from a learning pass that reads each question and its answer and states what rule, evidence in the source, or human judgement settled it; a finding is a proposal the human approves into the document (P1, P2, P10), never a rule the runner applies to itself. Checkpoints stay as P3 states them; this principle reduces doubt inside a stage, not the gates between stages.

---

## 3. Decisions

### D1. Registers are the record; open items are the work queue
An open item closes only by creating or changing a record. Registers and narrative stay separate. From model section 2. Consequence: no design document holds the master copy of an item, and no runner writes tracking tables into narrative pages.

### D2. Claims are the interface between ingestion and registers
The transcript runner produces atomic claims in JSON under `transcripts/claims/`, one file per session, with a `class` field and a fixed relation vocabulary. The register runner reads them like any other claim. Neither runner reads the other's working files. Consequence: a new input type (email, document) is a new claims producer, not a change to the register runner.

### D3. Legacy is recorded, never promoted
A passage saying a step is no longer performed becomes a claim of class `legacy`, listed in the session summary and treated as narrative by the register runner. A step still performed but called unnecessary is a process step with Retain: No and raises no requirement on its own. A requirement comes only from commitment language about the solution or the new way of working. Consequence: the classification guide's step 4 subject test is load-bearing and every change to it needs a worked example.

### D4. Processes are a register type
Current practice is recorded as PRC rows, one per end-to-end process with numbered steps, so the current state is knowable from Register: Processes and requirements can link to the step they replace or preserve.

### D5. Whether to change is decided on the limitation; a change request is the change's whole life
Revised 9 September 2026 (version 1.8), replacing the earlier form in which the CR carried the defer and workaround options and ended Workaround accepted. A limitation's Options hold the choice between living with it, working around it, and asking for a change now or in a named later phase; the decision that accepts it records the option chosen and the ones it beat. A change request is raised only when the chosen option asks for a change, in Proposed for this phase or straight into Deferred for a later one, and it carries the change until Delivered, Withdrawn or Rejected. Deferred is a waiting state reviewed at phase planning, not a terminal one, and no requirement is created to stand in for a deferred change. A CR's own Options are alternatives for making the change; impact lives inside each option, and vendor estimates are inputs, not states. A CR that ends Withdrawn or Rejected returns its limitation to Under assessment for a second disposition. Consequence: the next-phase view is deferred CRs by phase, and a CR whose chosen option would have been "do nothing" cannot exist.

### D6. The runner records its model and derives a mode
At T0 and at every later stage the transcript runner writes its model id to the state file. Mode is standard for Fable and strict for every other model, overridable by the human. Only T2 differs by mode: strict mode downgrades more classifications to inferred. Each claim carries `runner_model` and `runner_mode`. The Audit table's questions raised and classes changed columns are the measure of a model's effect. Each Audit row also carries the runner document version, so the same columns measure the effect of a document edit (P12).

### D7. No subagent orchestration inside the runners
Assessed 9 September 2026. The cost of ingestion sits in T2 and T3, which are also where quality is at risk. Delegating T2 to a cheaper model with a stronger checker does not pay: the failure mode is a confident misclassification the weak model never flags, so the checker must re-read every passage, which is the same work as classifying. Splitting T2 across parallel subagents loses whole-session context that the guide's rules depend on (legacy beats current, consultant question framing, topic continuity, same-as matching), and T3 grouping needs the whole session by definition. T0, T1 and T4 are shell work where a cheaper model saves nothing worth having.

What remains permissible:
- Running T2 for one session under two models independently and turning every disagreement into a question. This raises quality at double the T2 cost and is a per-session choice, not the default.
- A separate read-only self-check pass under a stronger model after a weaker model's T2, changing only confidence. To be built only if the audit table shows the need.

Changing this decision requires audit data from real sessions showing that Opus 5 in strict mode has a change rate the human considers unacceptable, or a cost constraint the owner states.

### D8. Skills are launchers
A skill validates arguments, stages files, and hands off to a runner document or a tool. Rules and behaviour never live in a skill.

### D10. Systems are a register type, and a limitation is about the solution
Added 9 September 2026 (version 1.9). Facts about a system in use today, including what it cannot do, are recorded as SYS rows with numbered facts, the D4 pattern applied to systems. The limitation register is reserved for the solution being built and the vendor's platform, so the disposition queue never carries the defects of a system being replaced. The transcript runner gains the claim class `system`, a deliberate widening of the D2 vocabulary, and both runners apply a subject test before classing anything a limitation; an unnamed subject is a question. Consequence: a current system shortfall reaches the requirements register only through commitment language, as D3 already requires for process steps.

### D9. Version bump on every document change
Model and runner share a version line; the transcript runner has its own. A change to any of them bumps the version and date in the same commit.

---

## 4. Pipeline and runbook design

This section describes the shape of the pipeline: what flows between which parts, where the human sits, and what survives interruption. The stage-by-stage instructions live in the runner documents and are not repeated here.

### 4.1 Flow

```
transcripts/input/*.vtt
      |
      v
[Transcript runner]  T0 register -> T1 passages -> T2 classify -> T3 assemble -> T4 write
      |                                                                      |
      |  work/transcripts/T<nnn>/ (passages, classifications, questions, summary)
      v
transcripts/claims/T<nnn>.json  (claims with class, relations, model, mode)
      |
      v
[Knowledge base]  claims folder, or a graph file the claims are merged into
      |
      v
[Register runner]  Phase 0 preflight -> 1 inventory -> 2 classify and extract -> 3 build -> 4 reconcile -> 5 handover
      |
      v
Confluence design register folder: eight registers, taxonomy, conventions, outstanding and next-phase views
```

Design documents enter the knowledge base by a separate ingestion outside this repository. Transcripts enter through the transcript runner. Both meet at the claim.

### 4.2 Runbook shape

Every runner document has the same skeleton, and a new runner must keep it:

1. **Inputs and outputs.** What it reads, what it writes, and nothing else.
2. **Operating rules.** Hard rules that win over any later instruction: read-only phases, never invent, never delete, dry run before write, verify after write, state survives interruption, no new software, a scale stop.
3. **Checkpoint protocol.** Write the stage files, post a summary with counts and questions, ask the fixed approval question, update state, end the turn.
4. **Work folder.** A state file plus one folder per unit of work, with numbered files per stage.
5. **Stages.** Each with a goal, numbered steps, and a checkpoint that names what to present.
6. **A record format.** The claim record for the transcript runner; the register columns, from the model, for the register runner.
7. **A classification guide.** Ordered steps, stop at the first match, record the reason. Worked examples in an appendix.
8. **Running this runner.** The launch command and the resume instruction.

### 4.3 Human gates

| Gate | What the human sees | What approval releases |
|---|---|---|
| T0 | Speakers, roles (prefilled from the stakeholder registry), meeting date, model and mode | Parsing, and the registry rows for new speakers |
| T1 | Passage count, cue check, topics | Classification |
| T2 | Counts per class, every inferred classification as a question | Claim assembly, once every question is answered |
| T3 | Claims table, processes with Retain flags, legacy list, summary | The write |
| T4 | Claims file, graph diff if any | Commit and move |
| Register Phase 2 | Candidate items, questions, scope taxonomy | Building pages |
| Register Phase 3a | Dry run of every page | Writing to Confluence |
| Register Phase 4 | Each source page edit, individually | That one edit |

No stage writes outside the work folder before its gate. The questions list is how doubt reaches the human; a runner never resolves doubt by guessing.

### 4.4 State and resumption

Each runner keeps one state file in `work/`. On start it reads the file and resumes the first incomplete unit at its recorded stage. Stage advances are written only after the commit or write that the stage produces has succeeded, so a failure leaves the unit at the earlier stage and the next run repeats the write rather than skipping it. The transcript runner's state file also holds the Audit table (Decision D6).

### 4.5 Auditability

Three records let a later reader reconstruct what happened and why:

- `LOG.md`, a chronological record of changes, decisions and rulings, one line each with its commit.
- `HANDOVER.md`, a transient statement of where the last session stopped, rewritten by the `handover` skill when the user ends a session and verified by `tools/handover-check.sh`. Enforcement as a Stop hook is optional and per user.
- The Audit table in `work/transcripts/state.md` and the `runner_model` and `runner_mode` fields on every claim, for what model did what.
- The questions files and checkpoint decisions in the state files, for what the human decided.

`ENHANCEMENTS.md` holds work agreed for a later session. An entry there is not a commitment; it is a place to keep the idea and its rationale so the next session does not rediscover it.

## 5. Compliance check

Before creating, moving, renaming or deleting a file, adding a tool, changing a runner stage, changing a classification rule, or changing an item type, state, field or relationship:

1. Read this document.
2. State the change in one sentence.
3. Check it against every principle and decision above and report:

```
## Compliance check: <change>
Compliant: <principles and decisions satisfied>
Not applicable: <those that do not bear on the change>
Violations: <each one, naming the principle or decision>
Decision: PROCEED | PROCEED WITH MODIFICATIONS | STOP
```

4. On STOP, do not implement. Explain the conflict and ask the owner whether to change the approach or to override the decision here. An override is recorded under Deviations, or by editing the decision with a new version line.
5. On PROCEED, run `tools/check-all.sh` before and after, and add assertions for any new rule (P10).

Layer placement, for the file location question: rules about items go in the model; rules about how a runner works go in that runner; anything deterministic goes in `tools/` with a test; slash commands go in `.claude/skills/` and stay thin.

---

## 6. Deviations

None recorded.
