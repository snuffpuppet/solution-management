# Solution register runner

Version 3.1, 9 September 2026. Owner: Adam Moyes. For Claude Opus 5 or Claude Fable 5.1 via Claude Code.

You are the runner. Your job is to read a knowledge base of atomic claims, extract the items it holds according to the model in `<HOW>/solution-register-model.md`, and produce the design registers, as markdown tables under `registers/` in this repository by default or as pages in a Confluence space when that target is chosen, without inventing anything and without writing before a human has approved what you will write.

Read this whole file, then read `<HOW>/solution-register-model.md` in full. The model file is the authority on what an item is, how types relate, what states exist and what a valid register looks like. This file is the authority on how you work. Where this file says "the model", it means that file and its section numbers.

Start at Phase 0. Do not skip checkpoints.

---

## 1. Inputs and outputs

Inputs:

- **The knowledge base.** By default the claims files under `transcripts/claims/`, one per ingested session. It may also be a set of atomic claims built by ingesting design documents elsewhere. Transcript claims are identified by `source_kind: transcript` on the claim, or by living under `transcripts/claims/`, and carry a `class` field that section 6 steps 0 and 0a use directly. Sessions that have not been ingested leave decisions made verbally, open items raised in meetings and their owners under-represented. Do not compensate for that by guessing; report which sessions are ingested and which are not (Phase 1).
- **The target.** `local` (default): the register files under `registers/`, which are read first on every run because rows already there are the record. `confluence`: the solution design space, reached through the Atlassian MCP tools, read for context and existing register-like pages, written only inside the design register folder.
- **The model.** `<HOW>/solution-register-model.md`.

Outputs:

- Local target: the eight register files, `scope.md`, `outstanding.md` and `next-phase.md` under `registers/` (section 7.1), committed with the work folder.
- Confluence target: register pages in the design register folder, one per type, plus the scope taxonomy, conventions, outstanding and next-phase pages (section 7.2), and superseded notes on source pages whose tables were migrated (Phase 4).
- A local `work/` folder holding every intermediate result, the questions you asked, the answers you were given, and a migration log.

## 2. Operating rules

These are hard rules. If a rule and a later instruction conflict, the rule wins. If you are unsure whether an action breaks a rule, stop and ask.

1. **The knowledge base is read-only, always.** You never modify, annotate or reorganise it.
2. **The target is read-only until Checkpoint 2 is passed.** Phases 0 to 2 change nothing under `registers/` or in Confluence. Not labels, not comments, not page moves.
3. **Write only inside the target until Checkpoint 3 is passed.** Phase 3 writes the files under `registers/`, or creates and edits pages under the design register folder, and nothing else.
4. **Never delete.** No row, file, page, attachment, comment or table is deleted by you at any phase. Superseding content is marked, never removed. If a human asks you to delete, decline and explain that they can do it by hand.
4a. **Existing rows are the record.** On a local run, read every file under `registers/` before Phase 1. A row already there is an input with a final id. It is never rewritten silently: a proposed change to it appears in the dry run as a before and after pair and is approved with the dry run. New rows are appended with the next free id for the type.
5. **Never edit a page outside the design register folder without per-page approval.** Phase 4 lists each proposed edit and waits for a yes on each page individually. "Yes to all" is acceptable only if the human has seen the full list.
6. **Never invent an item.** Every item you create traces to one or more claims, or to an explicit instruction from the human. If you infer an item from narrative with no claim behind it, it goes in the questions list, not the register.
7. **Ambiguity goes to the questions list, not to a guess.** If a claim could be a limitation or a risk, ask. If an owner is a team name, ask. If a claim's confidence is below the threshold in section 6, ask.
8. **Idempotent creation.** Local: a candidate whose title, claim set or `same-as` relation matches an existing row is an update proposal under rule 4a, not a new row. Confluence: before creating any page, search for an existing page with the same title under the folder; if one exists, report it and stop.
9. **Dry run before write.** Every write phase produces a local file showing exactly what will be written. The human approves that file, then you write.
10. **Verify after write.** After writing, read the page back and compare to the dry run. Report any difference.
11. **State survives interruption.** Keep `work/state.md` current (section 4) and commit `work/` at every checkpoint, so the questions, answers and decisions of a run are in git. On start, read it and resume from the recorded phase. Never redo a completed write phase.
12. **Secrets stay out of output.** Never print tokens, cookies or authorisation headers.
13. **No side effects outside the target and the local work folder.** No emails, no Jira tickets, no Slack messages, no calendar entries.
14. **Scale stop.** If the knowledge base has more than 3000 claims, or the space has more than 150 pages, stop after inventory and ask how to narrow the scope.
15. **Vendor perspective stays a reference.** Do not import vendor registers wholesale. Vendor items appear only as a Vendor ref on our items or as a question.
16. **Confluence access, when that target is chosen, is through the Atlassian MCP tools only.** Do not install anything on the host and do not fall back to the REST API. If the tools are not available, stop at Phase 0 and say so. The local target needs no tools beyond the shell.
17. **The model is not yours to change.** If a claim does not fit the model, that is a question for the human, not a reason to add a state, a field or a type.

## 3. Checkpoint protocol

A checkpoint is a full stop. At each one you:

1. Write the phase output files listed for that phase into `work/`.
2. Post a summary in the conversation: what you found or propose, the counts, the open questions, and the exact question "Approve Phase N and proceed to Phase N+1?"
3. Update `work/state.md` with `phase: N, status: awaiting approval`.
4. End your turn. Do nothing further until the human replies.

Approval is an explicit statement such as "approved", "proceed" or "go to phase 3". Silence, a question or a partial answer is not approval. If the human answers some questions and not others, record the answers, ask the rest again, and stay at the checkpoint. If the human asks for changes, make them, regenerate the phase outputs, and present the checkpoint again.

## 4. Local work folder

All working files go in `work/` next to this file. Create it if missing.

```
work/
  state.md              phase, status, timestamps, knowledge base location, space key, folder id, decisions taken at checkpoints
  00-access.md          Phase 0: tools found, knowledge base location and claim schema, space and folder, target structure confirmed
  01-inventory.md       Phase 1: claim counts, sources represented, existing requirement claims, register-like Confluence pages, coverage gaps
  02-candidates.md      Phase 2: candidate items, one per row, with claim ids and provisional id
  02-questions.md       Phase 2: numbered questions needing a human answer
  02-mapping.md         Phase 2: claim to candidate mapping, including claims that produced no item and why, and a count of transcript claims by class
  03-dryrun/            Phase 3: one file per page to be created, exact content
  03-migration-log.md   Phase 3: what was written, page ids, verification result, provisional to final id map
  04-reconcile.md       Phase 4: per-page proposed superseded notes and approvals
  05-handover.md        Phase 5: summary and pointers
```

`state.md` format:

```
phase: <0-5>
status: in progress | awaiting approval | complete
target: local | confluence
knowledge_base: <path or identifier>
claim_schema: <one line: where id, statement, source and confidence live>
space_key: <key>
register_folder_id: <page id>
register_folder_title: <title>
started: <ISO date>
last_update: <ISO date>
checkpoint_decisions:
  - <date>: <decision the human made, verbatim where short>
```

## 5. Phases

### Phase 0. Preflight and target confirmation

Goal: confirm the target, confirm access to the knowledge base, understand the claim schema, and confirm the target structure. Read-only.

1. Read `work/state.md` if it exists. If a phase is recorded, resume there.
2. Target. Local unless the human or the launching skill says `confluence`. Local: read every file under `registers/`, run `<HOW>/tools/check-registers.sh`, and record the row count per register and the highest id per type in `00-access.md`; a failing check stops the run until the human fixes the file. Confluence: confirm the Atlassian MCP tools are available (tool names starting `mcp__atlassian` or similar, offering Confluence page search and read), test with one read, and stop if missing.
3. Knowledge base. Local default is `transcripts/claims/`; otherwise ask the human where it is if `state.md` does not say. Open it and read a sample of at least 20 claims from different sources. Record the claim schema in `00-access.md`: where the claim id is, where the statement text is, where the provenance is (source document, section or page, location), whether there is a confidence or extraction-type marker, whether there are typed relations between claims, and whether any claims are already tagged as requirements or carry an existing id. If the knowledge base is a graph (for example a `graph.json` with nodes, edges and `rationale_for` relations), say so and record which node kinds look like claims and which edges look like rationale.
4. Confluence only. Ask for the space key or name if not in `state.md`. Find the design register folder by title (case-insensitive match on "design register"). If more than one candidate, list them and ask.
5. Confluence only. Read every page directly under the design register folder. Record titles and a one-line description of each. They are inputs, not targets, until the human says otherwise.
6. Present the target structure (section 7.1 or 7.2) and ask the human to confirm or adjust. Local: ids continue from the highest existing id per type (001 when the register is empty) and the columns are fixed by the files. Confluence: one page per register with a fixed-column table (default) or a Confluence database per register; id numbering start; whether existing requirement ids from the knowledge base must be preserved; page title prefix (default "Register: ").
7. Write `00-access.md` and `state.md`.

Checkpoint 0. Present: target, knowledge base location and schema summary, existing rows per register (local) or space, folder and existing pages (Confluence), confirmed target structure. Ask "Approve Phase 0 and proceed to Phase 1?"

### Phase 1. Inventory

Goal: know what the knowledge base and the space contain before classifying anything. Read-only.

1. Count claims in total and by source document. Apply the scale stop (rule 14).
2. Identify claims already marked as requirements, or carrying an existing id scheme (for example "R-12"). List the schemes found.
3. Identify claims whose source is a table in a design document, as opposed to prose. Tables are the most likely places existing tracking lives; note the table's page and header row where the provenance gives it.
4. Identify relation types between claims if the knowledge base has them, and note which ones look like rationale, dependency or reference.
5. Confluence only. List the Confluence pages in the space with id, title, parent and last modified. Classify each as solution design document, register-like page, meeting notes or other. Note which design documents are represented in the knowledge base and which are not.
6. Record coverage gaps: which transcript sessions under `transcripts/claims/` are present, which of them already appear in the Source column of existing rows (local) so that only new sessions are extracted, which known sessions are not ingested, design documents in Confluence not in the knowledge base (Confluence only), and the item types that suffer when sessions are missing (open items, meeting decisions, owners, due dates).
7. Write `01-inventory.md`.

Checkpoint 1. Present: claim counts by source, sessions already in the registers and sessions to extract, existing requirement claims and id schemes, table-sourced claims, Confluence page counts by class (Confluence only), coverage gaps. Ask which sources or pages, if any, to exclude. Ask "Approve Phase 1 and proceed to Phase 2?"

### Phase 2. Classification and extraction

Goal: turn claims into candidate register items with sources and questions. Read-only. Use the classification guide in section 6.

1. Classify every claim as one of: candidate item of a given type; part of an item already identified from another claim; narrative with no item; or unclear. Record the classification and the reason in `02-mapping.md`. "Narrative with no item" is the expected majority outcome; do not force claims into items.
2. For each candidate item fill every model header field you can from the claims, and the type-specific fields. Give it a provisional id (type prefix plus a sequence, e.g. `LIM-p017`). A candidate that matches an existing row under rule 8 keeps that row's final id and is written to `02-candidates.md` as an update with the fields that change. Source is the claim id or ids plus the claim's own provenance (document, section or page). Where an existing requirement id exists, keep it in Source as "previously R-12" and record it in the id map. Open items have no Source column: put the claim id and provenance in `02-mapping.md` and the migration log, set Raised by to the person if the claim names one and otherwise to the source document title, and set Raised on from a date in the claim or the document.
3. Status. Map any status wording in the claim to the model's vocabulary. Where no status is present, use the earliest non-terminal state for the type (Draft, Proposed, Identified, Open) and add a question only if the claim's wording suggests a later state. A change request that carries a vendor number is at least Submitted. One described as having options or estimates under consideration is Options. One described as deferred or for a later release becomes Deferred with a question asking for the phase; a requirement described that way gets Phase = next phase. A change described as answered by a workaround or manual process is not a change request: the limitation it would have addressed becomes Accepted with a question asking for the DEC, and a described manual process is a PRC candidate. A limitation described as having options or estimates under consideration is Under assessment.
4. Owner, Raised by, Approved by. Fill them only when a claim names a person. Team names and role names leave the field blank and generate one question per distinct group, not per item. On decisions, a document author or a "decided by" phrase fills Raised by or Approved by; Decided on comes from a date in the claim or its source document and is otherwise blank. On requirements, Raised on comes from a date in the claim or, failing that, the source document's date, and the mapping file says which. Identified on for limitations and risks is filled the same way. Trigger on a risk is filled only from wording in the claim that names an observable event; otherwise blank with a question. Raised on and Raised by on a change request, and Raised by on a risk, follow the open item rule. Reason on a change request is filled only from claim wording that says what the change is for; otherwise blank with a question. Options on a change request or a limitation are filled only from claim wording that names alternatives with their impact; otherwise blank with a question. Chosen option is filled only where the claim says which option was chosen. Impact on a limitation is filled only from wording in the claim or an adjacent claim from the same source; never written by you from general knowledge, and left blank with a question otherwise. Expect these to be blank on most items; that is the transcript gap, and the human fills it later.
5. MoSCoW on requirements. Fill from the claim if it carries a priority. Otherwise leave blank and add one question per source document listing the requirements that need a value.
6. Implemented by. Infer Vendor when the source is a vendor design document and Internal when it is ours, mark the inference in `02-mapping.md`, and list every inference for confirmation at the checkpoint.
7. Links. Where the knowledge base relates claims, and both claims became candidates, record the link with the model's relationship words (model section 5). A rationale relation from a claim that became a DEC to a claim that became a REQ is "addresses". A claim that became a LIM whose source discusses a REQ is "constrains". Mitigation on a risk is text on the row, not a link. Unresolvable references go in the questions list.
8. Scope. Propose a scope taxonomy from the document structure and service names in the sources. Tag each candidate at the lowest level you can justify from its source. Where you cannot, tag at Domain and add a question.
9. Deduplication. Where two candidates look like the same item (same title after normalisation, same vendor ref, or the same claim set), keep both, mark the pair, and add a question.
10. Validate every candidate against the model's transition rules (4.4) and integrity rules (9). Record each violation as a question. Do not fix it by inventing data.
11. Write `02-candidates.md` (one table per type), `02-mapping.md` and `02-questions.md` (numbered, each with the candidate ids affected and your proposed answer).

Checkpoint 2. Present: candidate counts per type, claims classified as narrative (count), claims classified as unclear (count), duplicate pairs, Implemented by inferences, proposed scope taxonomy, question count. Ask the human to answer `02-questions.md`. When all questions have an answer, apply them, regenerate the files, present final counts, and ask "Approve Phase 2 and proceed to Phase 3? This is the last read-only checkpoint."

Do not proceed while any question is unanswered.

### Phase 3. Build registers

Goal: write the registers. Writes are limited to `registers/` or to the design register folder.

1. Assign final ids in Source order, continuing from the highest existing id per type on a local run and honouring any preserved ids agreed at Checkpoint 0. Record the provisional to final map in `03-migration-log.md`. Rewrite all Links to final ids.
2. Generate the dry run under `03-dryrun/`: one file per register file or page in section 7, content exactly as it will be written. Local: each file is the existing rows unchanged, then approved updates shown as before and after pairs in a companion `03-dryrun/changes.md`, then the new rows; `outstanding.md` and `next-phase.md` apply model section 8 to every row. Confluence: labels listed at the top, and the conventions page condenses model sections 2 to 5 and 8.
3. Run the model's integrity rules (9) on the dry run; on a local run, run `<HOW>/tools/check-registers.sh work/03-dryrun` for the deterministic subset and judge the rest by hand. Any failure blocks the write. Report failures; the human decides whether to fix data or accept the failure as a known gap recorded in the migration log. Expect I3, I4 and I11 failures on items with no owner, next action, raised by or approved by; those are the transcript gap and are usually accepted as known gaps to be filled by hand.
4. Idempotency check. Local: confirm no row id in the dry run collides with a row that appeared in `registers/` after Phase 0 (someone edited by hand mid-run); if one does, stop and re-read. Confluence: search for each target title under the folder; if any exists, stop and ask whether to update it or choose a new title.
5. Checkpoint 3a: "Dry run complete, N new rows and M updated rows across K registers (or N pages), integrity result X. Approve writing to registers/ (or the design register folder)?"
6. On approval, write. Local: copy each dry-run file over its register file, run `<HOW>/tools/check-registers.sh`, and compare row counts and the id column against the dry run; then commit `registers/` and `work/` in one commit named for the sessions extracted. Confluence: create pages one at a time with the folder as parent, read each back and compare row count and the id column against the dry run, record page id and result, and stop on any mismatch before creating the next page.
7. Apply labels (Confluence). Write `03-migration-log.md` and update `state.md`.

Checkpoint 3. Present: files written or pages created, verification results, integrity result, known gaps. Ask "Approve Phase 3 and proceed to Phase 4?"

### Phase 4. Reconcile source documents

Goal: stop tables in the source design documents from drifting away from the registers. Edits outside the folder need per-page approval.

This applies only where a migrated item's Source points at a table on a Confluence page. Items whose source is prose, or a document not in Confluence, are listed in `04-reconcile.md` as "no page edit" and skipped. On a local run over transcript claims there are no source pages: write `04-reconcile.md` with the single line "Local target, no source pages" and go straight to Phase 5.

The action for every such table is the same. The original table stays in place, untouched, and a superseded note is inserted directly above it as an info panel:

> Superseded on <date>. The items in this table are now maintained in Register: <type> (link to the register page). Items: <comma-separated final ids>. Do not edit this table; update the register instead.

Where one table maps to more than one register, list each register with its ids.

1. Write `04-reconcile.md` listing every source page, each table, the registers it maps to, and the exact note text.
2. Present the list and ask for approval per page. Record answers. A declined page is recorded as "Leave".
3. Apply approved edits one page at a time. Insert the note above the table and change nothing else. Read back and verify the table row count is unchanged and the note is present.
4. Update the migration log with each edit and its page version.

Checkpoint 4. Present: edits applied, pages left unchanged and why. Ask "Approve Phase 4 and proceed to handover?"

### Phase 5. Handover

Write `05-handover.md` with: the path of every register file (or a link to every page), the outstanding view and the next-phase view; counts per register and per status; the known gaps list; the list of items with no owner or no next action, grouped by source document, so a human can fill them in one pass; and a pointer to the model's maintenance routine (10). Post the summary. Set `state.md` to `phase: 5, status: complete`.

## 6. Classification guide for claims

Apply in this order to each claim. Stop at the first match. Record the reason.

0. **Transcript claim of class legacy or context?** Narrative. Never an item. A legacy claim is listed in `02-mapping.md` with the reason "legacy practice" so the discard is traceable.
0a. **Transcript claim of class current or current-not-needed?** Candidate PRC. One PRC per process claim. Its step claims (those carrying `step-of` this process) become the Steps field in `step n` order, with Retain: Yes unless the step claim carries `retain no; <reason>`, in which case Retain: No and the reason. Actor comes from the step claim's wording where it names one, or is the speaker when the step is in the first person. Raised by is the speaker names on the claims; Described on is the session date; Source lists the claim ids. Context claims with an `about` relation to the process fill Systems and Frequency. A process claim with a `same-as` relation to an earlier session's process claim is an update to that PRC candidate, not a new one; record it and add a question. Raise one open item per PRC candidate titled "Confirm PRC-pnnn with <SME names>", Raised on the session date, Raised by the transcript runner session id, Owner blank, and add one question per session asking who owns confirmation. This satisfies I3 without inventing an owner.
0a1. **Transcript claim of class system?** Candidate SYS, one per system named in the claims' `about` relation or statement. Each claim becomes one fact in the Facts field in passage order, with Stated by = the speaker. Used by lists the PRC candidates whose Systems name it. Fate is Unknown unless a claim states what the solution does with the system. Raised by, Described on, Source and the confirming open item follow the PRC rule. A system claim whose wording is a shortfall is still a fact, never a LIM candidate.
0b. **Transcript claim of class need, decision, limitation, risk or open-item?** Continue at the step below that matches the class, using the class as the starting proposal. A need claim carrying `replaces` or `preserves` gives the REQ a Links entry "replaces PRC-pnnn/step n" or "preserves PRC-pnnn/step n" once both sides have provisional ids. A need claim's moscow field fills MoSCoW on the REQ.

1. **Is it an existing requirement claim, or does it state a need?** Wording such as "must", "shall", "needs to", "is required to", or a requirement id. Candidate REQ. Owner is the person who stated it if the claim says who; otherwise blank.
2. **Does it record a choice between options, a principle other design must follow, or an accepted constraint?** Wording such as "we chose", "instead of", "will use X rather than Y", "must always", "because the platform requires". Candidate DEC. Apply model 4.5: a claim that merely restates a requirement or describes routine vendor implementation is narrative, not a decision. A transcript claim whose role is `vendor` or `architect` follows the Register effect column of `<HOW>/roles.md`: a Proposed DEC with Raised by = the speaker; where the role is `vendor`, Consulted includes "vendor: <name>". Approved by is never filled from a vendor or architect claim, because approval sits with us.
3. **Does it say the solution will not do, or does differently, something needed?** Wording such as "does not support", "is limited to", "cannot", "only one", "not available in this phase". Apply the subject test first: if the system named is one in use today, or the claim is a transcript claim of class `system`, it is a SYS fact under 0a1 and not a LIM, whatever the wording. Otherwise candidate LIM. If the claim also names the need, that need is a REQ candidate if not already present, and the LIM constrains it. A transcript claim of role `vendor` is the usual source: Raised by = the speaker, Source = the claim id. Where the subject cannot be told from the claim, ask.
4. **Does it describe something that might go wrong, or an unverified assumption with consequences?** Wording such as "risk", "may fail", "assumes", "depends on", "to be confirmed". Candidate RSK. "To be confirmed" with a clear action and no consequence is an OI instead.
5. **Does it describe work someone must do?** Wording such as "action", "to do", "follow up", "confirm with", "raise with vendor". Candidate OI. Owner blank unless named.
6. **Does it describe a change to agreed scope or design with a cost, effort or time implication?** Wording such as "change request", "CR-", "additional scope", "estimate", "quote". Candidate CR.
7. **Otherwise it is narrative.** Description of components, flows, data, interfaces and context. No item. This should be most claims.

Confidence. If the knowledge base marks extraction confidence, treat claims marked as extracted or equivalent as usable directly. Treat inferred or ambiguous claims as questions: list them with your proposed classification and do not make them candidates until the human confirms.

Granularity. One claim can produce one item. Several claims about the same thing produce one item with all their ids in Source. One claim can produce two items only in the LIM plus REQ case in step 3; anything else that seems to need two items is a question.

## 7. Target structure

### 7.1 Local target (default)

One markdown file per register under `registers/`, committed to git. Each file is a title line, a two-line note, then one table whose header is exactly the column list for that register in model section 7; `<HOW>/tools/check-registers.sh` fails when a header drifts from the model. Numbered-list cells (Steps, Facts, Options) separate items with `<br>` so a row stays on one line. Ids are final and never reused; the next free id for a type is one more than the highest in its file. Column values are plain text and ids in Links are plain text, so a person can edit a row by hand between runs.

| File | Content |
|---|---|
| `registers/requirements.md` | Table with the Requirements columns |
| `registers/decisions.md` | Table with the Decisions columns |
| `registers/limitations.md` | Table with the Limitations columns |
| `registers/risks.md` | Table with the Risks columns |
| `registers/open-items.md` | Table with the Open items columns |
| `registers/change-requests.md` | Table with the Change requests columns |
| `registers/processes.md` | Table with the Processes columns. One row per process; Steps holds `n. <step> [Retain: Yes/No/Unknown] [Actor: <role or person>]` items joined by `<br>` |
| `registers/systems.md` | Table with the Systems columns. One row per system; Facts holds `n. <fact> [Stated by: <person>]` items joined by `<br>` |
| `registers/scope.md` | The scope tree (model section 6) as an indented list inside a code block |
| `registers/outstanding.md` | The meeting view (model section 8), regenerated at every Phase 3 write and by the register routine |
| `registers/next-phase.md` | The next-phase view (model section 8), regenerated with the outstanding view |

There is no conventions file: the model document is the conventions.

### 7.2 Confluence target

All pages live directly under the design register folder. Titles use the confirmed prefix.

| Page | Content |
|---|---|
| Register: Requirements | Table with the Requirements columns from model section 7 |
| Register: Decisions | Table with the Decisions columns |
| Register: Limitations | Table with the Limitations columns |
| Register: Risks | Table with the Risks columns |
| Register: Open items | Table with the Open items columns |
| Register: Change requests | Table with the Change requests columns |
| Register: Processes | Table with the Processes columns |
| Register: Systems | Table with the Systems columns |
| Register: Scope taxonomy | The scope tree (model section 6) as a nested list. The allowed Scope values. |
| Register: Conventions | Model sections 2 to 5 and 8, condensed for people adding items by hand. |
| Register: Outstanding | The meeting view (model section 8). A hand-maintained page with seven headed sections, regenerated by the runner on request. |
| Register: Next phase | The next-phase view (model section 8): deferred change requests grouped by phase with what triggered each, then next-phase requirements. Regenerated with the outstanding page. |

Each register page carries the labels `solution-register` and `register-<type>` (e.g. `register-limitations`). Each page starts with a two-line note: what the register holds and a link to Register: Conventions.

## 8. Maintenance runs

When asked to "run the register routine": read the eight registers (files or pages), regenerate the outstanding and next-phase views using model section 8, run the integrity rules (`<HOW>/tools/check-registers.sh` first on a local target, then the rest by hand) and report failures and warnings. This is read-only except for those two views, which are inside the target and need no per-page approval; report the diff.

## 9. Running this runner

The usual way is the end of an ingestion: `/ingest-transcript` runs this runner on the local target as soon as T4 has committed the session's claims, so one ingestion ends with claims and registers both committed. To run it alone, over every claims file, type `/build-registers`; add `confluence` to choose that target.

By hand, from the project folder:

```
claude --model claude-opus-5
```

Then:

```
Read <HOW>/solution-register-runner.md and <HOW>/solution-register-model.md in full. Execute the runner from Phase 0 on the local target. The knowledge base is at transcripts/claims/. Stop at every checkpoint and wait for my approval.
```

To resume after an interruption, give the same instruction. The runner reads `work/state.md` and continues from the recorded phase.

Transcript sessions are ingested first with `<HOW>/transcript-runner.md`. Its claims land in `transcripts/claims/` or in the knowledge base graph, and Phase 2 reads them like any other claim.

To run maintenance only:

```
Read <HOW>/solution-register-runner.md and <HOW>/solution-register-model.md. Run the register routine in section 8 against the registers in the design register folder.
```
