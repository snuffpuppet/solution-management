# Transcript runner

Version 1.7, 9 September 2026. Owner: Adam Moyes. For Claude Opus 5 or Claude Fable 5.1 via Claude Code.

You are the transcript runner. Your job is to turn a WebVTT transcript of a discovery session between consultants and our business subject matter experts (SMEs) into atomic claims that `<HOW>/solution-register-runner.md` can read. Vendor professional services and our own solution architects may also be in the room; section 8 says what their words may become, without inventing anything and without writing a claim before a human has approved it.

Read this whole file, then read `<HOW>/solution-register-model.md` in full. The model is the authority on item types; you do not create items, you create claims that the register runner turns into items. This file is the authority on how you work.

Start at stage T0. Do not skip checkpoints.

---

## 1. Inputs and outputs

Inputs:

- **A transcript.** One `.vtt` file per session in `transcripts/input/`, exported from Microsoft Teams or Webex. The first line is `WEBVTT`. Speaker attribution comes from `<v Name>` tags or a leading `Name:` and is often missing when people share a meeting room.
- **The parser.** `<HOW>/tools/vtt-to-passages.sh`, which turns cues into numbered passages. You run it; you do not rewrite it.
- **Earlier sessions.** `transcripts/claims/*.json`, read so that a process described twice is linked rather than duplicated.
- **The knowledge base.** Its location and form (a graph file, or the claims folder itself) are recorded in `work/transcripts/state.md` at T0.
- **The model.** `<HOW>/solution-register-model.md`, for the PRC type (4.2, 4.4) and the entry points (3).
- **Roles.** `<HOW>/roles.md`, the table of speaker roles and what each may yield. Section 8 steps 1 and 1a apply it.
- **The stakeholder registry.** `transcripts/stakeholders.md`, one row per person with their speaker tags, organisation and role. Read at T0 so that known speakers are not asked about again.

Outputs:

- `transcripts/claims/T<nnn>.json`: the session's claims, committed at T4.
- The transcript moved to `transcripts/processed/` with the session id prefix.
- Optionally, nodes and edges merged into the knowledge base graph at T4 after an approved diff.
- A local `work/transcripts/` folder holding passages, classifications, the claims draft, questions and the session summary.

## 2. Operating rules

These are hard rules. If a rule and a later instruction conflict, the rule wins. If you are unsure whether an action breaks a rule, stop and ask.

1. **Every claim carries a verbatim quote.** No quote, no claim.
2. **Never invent a claim.** A claim states what a passage says. If you are inferring, mark confidence `inferred` and add a question; an inferred claim is not written at T4 until the human has answered.
3. **Only SMEs describe our processes or needs.** `<HOW>/roles.md` says what each speaker role may and may not yield, and it wins over any reading of the words. A consultant passage is always class `context`. The SME answer that follows carries the content. A vendor or architect passage is never `current`, `current-not-needed`, `legacy` or `need`; it may be a decision, limitation, risk or open item about the solution, and is otherwise `context`. Approval of anything a vendor or architect proposes sits with us, so their words never fill Approved by.
4. **Legacy is recorded, never promoted.** A passage that says a step is no longer performed becomes a claim of class `legacy`. The register runner treats legacy as narrative. Do not turn it into a process step or a need.
5. **Not needed is not legacy.** A step still performed but called pointless stays a current step with `retain no; <reason>`. It raises no need on its own.
5a. **A shortfall of today's system is a fact, not a limitation.** "The ledger cannot hold two references" is class `system` when the ledger is in use today. Class `limitation` is reserved for the solution being built or the vendor's platform. Where the passage does not say which system, ask.
6. **Ambiguity goes to the questions list, not to a guess.** Two plausible classes, an unclear tense, or a mixed passage you cannot split cleanly: ask.
7. **The model is not yours to change.** If a passage does not fit any class, it is `context` and, if it seems to matter, a question.
8. **Write only under `work/`, `transcripts/processed/`, `transcripts/claims/`, the approved graph merge, and new rows appended to `transcripts/stakeholders.md` at T0.** Never edit a transcript. Never edit an existing claims file. Never delete anything.
9. **Dry run before write.** T4 shows the claims file and, if there is a graph, the node and edge diff, before writing.
10. **Verify after write.** After T4, read the claims file back and count claims; read the graph back and count nodes. Report any difference.
11. **State survives interruption.** Keep `work/transcripts/state.md` current and commit `work/transcripts/` at every checkpoint, so the Audit table, questions, answers and summaries are in git. On start, read it and resume.
12. **No new software.** Parsing and JSON writing use bash, awk, sed and grep. If the graph format needs more, stop and ask.
13. **Scale stop.** More than 600 passages in one session: stop after T1 and ask whether to split the file.
14. **Secrets stay out of output.** Transcripts can contain personal details. Quote what the claim needs and no more.

## 3. Checkpoint protocol

A checkpoint is a full stop. At each one you:

1. Write the stage files listed for that stage into `work/transcripts/T<nnn>/`.
2. Post a summary in the conversation: counts, what you propose, the open questions, and the exact question "Approve stage Tn and proceed to Tn+1?"
3. Update `work/transcripts/state.md` with the session's stage and `awaiting approval`.
4. End your turn. Do nothing further until the human replies.

Approval is an explicit statement such as "approved", "proceed" or "go to T3". Silence, a question or a partial answer is not approval. If the human answers some questions and not others, record the answers, ask the rest again, and stay at the checkpoint. If the human asks for changes, make them, regenerate the stage files, and present the checkpoint again.

## 4. Local work folder

```
transcripts/
  input/                  drop .vtt files here; committed on arrival
  processed/              transcripts after T4, prefixed with the session id, e.g. T003-discovery-billing.vtt
  claims/                 one JSON file per session, committed
work/
  transcripts/
    state.md              session table, knowledge base location and form, claim counters
    T003/
      00-passages.md      parser output with topic labels filled in
      01-classified.md    passage, class, confidence, reason, split marker
      02-claims-draft.md  claims in table form for review, with relations
      02-questions.md     numbered questions for this session
      03-summary.md       session summary
```

`state.md` format:

```
knowledge_base: <path, or "claims folder">
knowledge_base_form: graph | claims folder
last_update: <ISO date>

| Session | File | Meeting date | Stage | Status | Model | Mode | Last update |
|---|---|---|---|---|---|---|---|
| T001 | discovery-billing.vtt | 2026-09-15 | T4 | complete | claude-opus-5 | strict | 2026-09-16 |
| T002 | discovery-orders.vtt | 2026-09-17 | T2 | awaiting approval | claude-fable-5-1 | standard | 2026-09-17 |

## Audit

| Session | Stage | Model | Mode | Runner | Date | Passages | Claims | Questions raised | Class changed by human |
|---|---|---|---|---|---|---|---|---|---|
| T001 | T2 | claude-opus-5 | strict | 1.2 | 2026-09-16 | 212 | | 31 | 9 |
| T001 | T3 | claude-opus-5 | strict | 1.2 | 2026-09-16 | 212 | 187 | 4 | 1 |

checkpoint_decisions:
  - <date> T002: <decision the human made, verbatim where short>
```

Model and Mode on the session row are the model that ran T0 and the mode chosen there. The Audit table has one row per stage run, so a session whose stages ran under different models shows each. Questions raised is the count of questions the stage produced; Class changed by human is how many of those answers overturned the runner's proposed class. Runner is the version number from this document's version line, for example `1.3`, read at the start of the stage. Comparing questions raised and classes changed across models is how the effect of a model change is measured; comparing them across Runner values is how the effect of an edit to this document is measured (ARCHITECTURE P12).

Mode is `standard` or `strict`. It is derived from the model at T0, standard for Fable and strict for every other model, and the human may override it at the T0 checkpoint. Strict mode changes only T2, as described there.

Session ids are `T` plus a zero-padded three-digit number, assigned from the highest existing id in `work/transcripts/` and `transcripts/claims/` plus one. Claim ids are `T<nnn>-C<nnn>` and number from 001 within a session.

## 5. Phases

Each stage ends at a checkpoint (section 3). Stage files go in `work/transcripts/T<nnn>/`.

### T0. Register

Goal: identify the session, confirm the file is a transcript, and learn who spoke.

1. Read `work/transcripts/state.md` if it exists. If a session is not complete, resume it at its recorded stage and skip the rest of T0.
2. List `transcripts/input/`. If more than one file, ask which to process. Assign the next session id.
3. Confirm the first line of the file is `WEBVTT`, ignoring a byte order mark if present (the parser strips it). If not, stop and report; do not move the file.
4. Record the file name and the meeting date. Take the date from the file name if it holds one in ISO or dd-mm-yyyy form; otherwise ask.
5. List every distinct speaker tag with its passage count (the parser merges consecutive same-speaker cues), using:

   ```
   <HOW>/tools/vtt-to-passages.sh "<file>" | grep '^- Speaker:' | sort | uniq -c | sort -rn
   ```

   Passages with no tag appear as Unattributed.
6. Read `transcripts/stakeholders.md`. For each tag run `grep -i -F "<tag>" transcripts/stakeholders.md` and accept a row only where the tag equals the Name column or one of the `;`-separated entries in the Tags column, ignoring case and surrounding spaces; a match fills the person's name and role from that row. Present matched and unmatched tags separately. For every unmatched tag ask the human for a name, organisation and role, one of `sme`, `consultant`, `vendor` or `architect`. Record the whole mapping in `state.md` under checkpoint decisions. On approval of T0, append one row per newly identified person to the registry as `| <Name> | <tag> | <Organisation> | <role> |  |`, in the order the tags appeared, with `git add transcripts/stakeholders.md` in the checkpoint commit. Never edit or remove an existing row; a correction is the human's to make. Where a tag is not a person at all, for example a short word that happened to precede a colon in the transcript, the human marks it as not a speaker and its passages are treated as Unattributed.
7. If `state.md` does not record the knowledge base location and form, ask, then record it.
8. Record the model you are running as, taken from your own session context (the model id, for example `claude-opus-5` or `claude-fable-5-1`), in the session row's Model column. Derive Mode: standard for Fable, strict for any other model. Present both at the checkpoint; the human may override the mode.

Checkpoint T0. Present: session id, file, meeting date, speaker table with roles and which came from the registry, knowledge base location, model and mode. Ask "Approve stage T0 and proceed to T1?"

Every later stage, on starting, records its own model and the version number from this document's version line in a new Audit row for that stage. If the model differs from the session row, say so at the checkpoint.

### T1. Passages and topics

Goal: a numbered passage list with no cue lost, and a topic label on every passage.

1. Run `<HOW>/tools/vtt-to-passages.sh "<file>" > work/transcripts/T<nnn>/00-passages.md`.
2. Read the last line of the output. Verify: the cue count equals `grep -c -- '-->' "<file>"`, and the last timestamp equals the start of the last cue in the file. If either differs, stop and report.
3. Apply the speaker mapping from T0: replace each mapped tag in the `- Speaker:` lines with the person's name, and add `- Role: <role>` after each speaker line, where role is `consultant`, `sme`, `vendor` or `architect`. Unattributed passages get `- Role: unknown`.
4. Read every passage. Propose a topic list: a short name per subject discussed, with the passage numbers it covers. A subject that returns later reuses its name. A digression gets its own name. Write the topic name into each passage's `- Topic:` line.
5. Apply the scale stop: if there are more than 600 passages, stop and ask whether to split the file.

Checkpoint T1. Present: passage count, cue count check, unattributed share, the topic list with passage ranges. Ask the human to rename or merge topics. Ask "Approve stage T1 and proceed to T2?"

### T2. Classify

Goal: one class per passage, with reasons, and every doubt turned into a question.

1. Apply section 8 to every passage in order. Where step 2 of the guide applies, split the passage into lettered parts, `(a)`, `(b)`, `(c)` and so on, and class each part.
2. Write `01-classified.md` as a table: Passage, Speaker, Role, Class, Confidence, Reason, Notes. Reason is the guide step that matched and the words that triggered it.
3. **Self-check.** Re-read every passage classed `current`, `current-not-needed` or `need` against the appendix rows and the section 8 step 4 subject test. Downgrade to `inferred` any classification you cannot justify from the quote's own words. In strict mode also downgrade to `inferred` every `need` whose modal does not name the solution or the new way of working explicitly, and every split you made at a clause boundary rather than a sentence boundary. Record in the Notes column which classifications the self-check changed.
4. Every passage with confidence `inferred` becomes a numbered question in `02-questions.md`: the passage number, the quote, the proposed class, the alternative, and what would settle it.
5. Present counts per class, and the count of self-check downgrades.

Checkpoint T2. Present: counts per class, the questions. Ask the human to answer them. When every question has an answer, apply the answers, regenerate `01-classified.md`, count how many answers changed the proposed class, write the Audit row for T2 with questions raised and classes changed, present the final counts, and ask "Approve stage T2 and proceed to T3?" Do not proceed while any question from this stage is unanswered.

### T3. Assemble claims

Goal: the claims for this session, grouped into processes and linked.

1. For each classified passage or split part, write one claim with the fields in section 6. One claim per statement in the part: a sentence that names two steps gives two step claims. `statement` is one sentence in the SME's words, tidied only for grammar. `quote` is the verbatim passage text. Set moscow on need claims from the modal as section 8 step 4 says.
2a. Group claims of class `system` by the system they name. Each carries `about <system name>` with the name as the SME said it; where a process claim's context names the same system, use the same spelling.
2. Group claims of class `current` and `current-not-needed` into processes. Use topic, speaker and passage order as hints. For each group write one process claim: class `current`, statement naming the process and what triggers it, quote taken from the passage that introduces it. Each step claim carries `step-of <process claim id>; step n` in passage order. A `current-not-needed` step claim also carries `retain no; <reason in the SME's words>`.
3. Claims of class `context` that state a system, tool or frequency for a process carry `about <process claim id>`.
4. Each SME claim that answers a consultant question carries `answers <consultant claim id>`.
5. Each `need` claim that keeps a current step carries `preserves <step claim id>`; one that changes a step carries `replaces <step claim id>`.
6. Read every earlier `transcripts/claims/*.json`. Where a new process claim describes the same process as an earlier one (same trigger and the same or overlapping steps), add `same-as <earlier claim id>` and a question asking whether this is an update or a distinct process. The register runner folds a same-as claim into the existing PRC candidate while no PRC row has been published; once a row exists, it proposes a new PRC and marks the old one Superseded, as model 4.4 requires.
7. Write `02-claims-draft.md`: a table with Id, Passage, Speaker, Class, Confidence, Statement, Relations. Below it, list legacy claims with quote and speaker.
8. Write `03-summary.md` (section 7).

Checkpoint T3. Present: claim count by class, process count with step counts and Retain: No counts, need count, legacy count, `same-as` questions, and the summary. When the questions are answered, write the Audit row for T3 with claim count, questions raised and classes changed. Ask "Approve stage T3 and proceed to T4?"

### T4. Write claims

Goal: the claims committed and, where there is a graph, merged.

1. Check that `transcripts/claims/T<nnn>.json` does not exist. If it does, stop and report.
2. Write the claims as a JSON array to that path. Escape quotes, backslashes and newlines in string values. Exclude any claim still marked `inferred` with an unanswered question; there should be none after T2 and T3.
3. Read the file back and count objects (`grep -c '"id": "T'`). It must equal the claim count in the draft.
4. If `knowledge_base_form` is `graph`: build the list of nodes (one per claim, all fields, plus `source_kind: transcript`) and edges (one per relation, from claim id to target id, labelled with the relation word). Present the counts and a sample of five of each. On approval, write the merged graph, read it back, and verify the node count increased by exactly the claim count.
5. Move the transcript with `git mv "<file>" "transcripts/processed/T<nnn>-<file>"`. The original under `transcripts/input/` is committed when it arrives, so the move keeps its history.
6. Commit `transcripts/claims/T<nnn>.json`, `transcripts/processed/T<nnn>-<file>`, `work/transcripts/state.md` and `work/transcripts/T<nnn>/` (and the graph if merged) with the message `Ingest transcript T<nnn>: <file>`.
7. Only after the commit succeeds, set the session to `T4, complete` in `state.md`.

Checkpoint T4. Present: claims file path, claim count, verification result, graph merge result if any, commit hash. Say that the register runner can now be run from Phase 0 or Phase 2.

## 6. Claim record

One JSON object per claim, in a top-level array, one file per session.

| Field | Rule |
|---|---|
| id | `T<nnn>-C<nnn>`. Never reused. |
| statement | One sentence, in the SME's words tidied only for grammar. |
| quote | Verbatim passage text. Mandatory. |
| session | Session id. |
| file | Transcript file name as it was in `transcripts/input/`. |
| passage | Passage number as a string, with a letter suffix when split, e.g. `"12(b)"`. |
| timestamp | Start of the passage, `HH:MM:SS.mmm`. |
| speaker | Mapped person name, or "Unattributed". |
| role | `consultant`, `sme`, `vendor`, `architect` or `unknown`. |
| topic | Topic label from T1. |
| class | `current`, `current-not-needed`, `legacy`, `system`, `need`, `decision`, `limitation`, `risk`, `open-item` or `context`. |
| moscow | On need claims only: Must, Should, Could or Won't, from the step 4 table. Absent on other classes. |
| confidence | `extracted` or `inferred`. |
| relations | Array of strings, each `<relation> <target claim id>` with optional `; <detail>`. Relations: `step-of <id>; step n`, `retain no; <reason>`, `replaces <id>`, `preserves <id>`, `answers <id>`, `about <id>` (or `about <system name>` on a system claim), `same-as <id>`. |
| runner_model | The model id that classified the claim at T2, from the Audit row, for example `"claude-opus-5"`. |
| runner_mode | `standard` or `strict`, from the session row. |
| source_kind | Always `"transcript"`. |

Example:

```json
[
  {
    "id": "T003-C016",
    "statement": "A new customer order is handled from the sales team's email.",
    "quote": "Sure. The order arrives by email from the sales team.",
    "session": "T003",
    "file": "discovery-orders.vtt",
    "passage": "2",
    "timestamp": "00:00:04.000",
    "speaker": "Tom Reilly",
    "role": "sme",
    "topic": "Order intake",
    "class": "current",
    "confidence": "extracted",
    "relations": ["answers T003-C015"],
    "runner_model": "claude-opus-5",
    "runner_mode": "strict",
    "source_kind": "transcript"
  },
  {
    "id": "T003-C017",
    "statement": "The order is keyed into the ledger and the reference copied into the tracking spreadsheet.",
    "quote": "I key it into the ledger and then copy the reference into the tracking spreadsheet.",
    "session": "T003",
    "file": "discovery-orders.vtt",
    "passage": "2",
    "timestamp": "00:00:04.000",
    "speaker": "Tom Reilly",
    "role": "sme",
    "topic": "Order intake",
    "class": "current",
    "confidence": "extracted",
    "relations": ["step-of T003-C016; step 1"],
    "runner_model": "claude-opus-5",
    "runner_mode": "strict",
    "source_kind": "transcript"
  }
]
```

A process is one claim of class `current` naming the process and its trigger, plus one claim per step carrying `step-of`. The register runner builds one PRC per process claim.

## 7. Session summary

`03-summary.md` has these headed sections, in order:

1. **Session.** Id, meeting date, source file, duration (last cue end), speakers with role and the share of passages attributed to a named person, the model and mode per stage from the Audit table, and the self-check downgrade count. A warning line if no speaker tags were present at all.
2. **Topics.** One row per topic: name, passage range, who led it, claim ids produced.
3. **Processes described.** One row per process claim: statement, step count, Retain: No count, speakers.
4. **Needs raised.** One row per need claim: statement, MoSCoW from the modal, the step it replaces or preserves if any.
5. **Legacy passages.** One row per legacy claim: quote, speaker, the words that made it legacy.
5a. **Systems described.** One row per system named by system claims: name, fact count, speakers.
6. **Other claims.** Decision, limitation, risk and open-item claims, one row each with statement and speaker.
7. **Open questions.** Count, and the question numbers still unanswered.

Regenerate the summary whenever claims change at a checkpoint.

## 8. Classification guide for passages

Apply in this order to each passage. Stop at the first match. Record the step and the trigger words as the reason.

1. **Consultant speaker?** Class `context`. Consultant passages never yield `current`, `current-not-needed`, `legacy` or `need`. Record the question so that the SME answer can carry `answers`.
1a. **Vendor or architect speaker?** Apply the Never yields column of `<HOW>/roles.md`: never `current`, `current-not-needed`, `legacy` or `need`. Continue at step 7 with only the decision, limitation, risk and open item entry points; a vendor stating what the platform does, does not do or requires is a limitation or a constraint-accepting decision, and an architect stating how the solution should be shaped is a decision. Anything else, including their account of our processes or what we need, is `context`. A question from a vendor or architect is recorded like a consultant question so the SME answer can carry `answers`.
2. **Mixed passage?** A passage that contains two statements of different classes, or two commitment-modal statements with different MoSCoW values, is split at sentence or clause boundaries into as many lettered parts as there are statements, `(a)`, `(b)`, `(c)` and so on. Typical mixes are a description of work done today with a stated need, a legacy statement with a current one, a limitation with the current step that works around it, and a Must beside a Should. Each part continues from step 3. If you cannot find a clean boundary, class the whole passage with confidence `inferred` and ask.
3. **Explicit past or cessation?** Wording such as "we used to", "before the migration", "that stopped when", "we no longer", "back when we had". Class `legacy`. Legacy beats current when the passage names a system or team that other passages in the session confirm is gone, even if the verb is present tense.
4. **Commitment modal about the solution or the new way of working?** must, shall, has to, need to, will, should, could, may, will not, won't, out of scope. Class `need`. MoSCoW from the modal: must, shall, has to, need to, will give Must; should gives Should; could, may give Could; will not, won't, out of scope give Won't. The modal must be about the solution or the new way of working. A modal that states an obligation within today's process, such as "the invoice has to go to finance before I key it" or "we need to get sign-off before we post it", is a current step under step 6, not a need. Where the subject of the modal is unclear, class the passage with confidence `inferred` and ask. Need beats current only when the modal is present. A need that keeps a current step carries `preserves`; one that changes a step carries `replaces`. "Need to check" and "need to find out" are open items, not needs; see step 7.
5. **Present tense plus stated redundancy?** Wording such as "we still do this but", "nobody uses that", "we only do it because", "it is just habit", "pointless". Class `current-not-needed`. The step claim carries `retain no; <reason>`. No need is raised from it; a separate commitment about removing it is its own `need` under step 4.
6. **Present tense description of work performed?** Wording such as "we do this", "I check", "it goes to", "every month we", "then I". Class `current`. This is a step claim, or the process claim if it introduces the process. A negated or conditional clause such as "we do not" or "if that happens" is not a description of work performed; continue to step 7.
7. **Model entry points.** Decision: "we agreed", "we decided", "we went with", or an explicit unresolved disagreement; apply model 4.5 first, and a restated need is not a decision. Limitation: "we cannot because", "the platform does not let us", "there is no way to", where the subject is the solution or the vendor's platform. System: the same wording, or any statement of what a system does or holds, where the subject is a system in use today; class `system`, `about <system name>`. Subject unclear: `inferred`, and a question. Risk: "the danger is", "if that happens", "we are worried that", "assumes". Open item: "someone needs to find out", "we need to check", "I will come back on that", "to be confirmed". Class accordingly.
8. **Otherwise `context`.** Facts, volumes, roles, systems, frequencies, small talk. Context claims that name a system or frequency for a process carry `about`.

Confidence is `extracted` when the trigger words are in the quote. It is `inferred` when you relied on surrounding passages, tone or your own judgement, and every inferred classification is a question.

## 9. Running this runner

From the project folder, with the model you have access to:

```
claude --model claude-opus-5
```

or

```
claude --model claude-fable-5-1
```

Then:

```
Read <HOW>/transcript-runner.md and <HOW>/solution-register-model.md in full. Execute the transcript runner from stage T0 on the file in transcripts/input/. Stop at every checkpoint and wait for my approval.
```

The runner records its model at T0 and at the start of every later stage, and derives the mode from it (section 4). To force a mode regardless of model, say so in the instruction: "Run in strict mode." To resume after an interruption, give the same instruction; the runner reads `work/transcripts/state.md` and continues from the recorded stage, under whatever model the new session has, and records the change in the Audit table.

To compare models, run T2 for the same session under each model in turn without approving the checkpoint, and compare the Audit rows and the `01-classified.md` files. Only one run is approved and carried into T3.

## Appendix. Worked examples

Each row is one passage from an SME unless stated. The expected class and relations are what T2 and T3 must produce.

| Case | Passage | Class | Relations and notes |
|---|---|---|---|
| Consultant question | "Can you walk me through how a new customer order comes in today?" (consultant) | context | The next SME claim carries `answers` to this one. |
| Vendor limitation | "The platform only holds one reference per order, that is not configurable." (vendor) | limitation | Step 1a then step 7. Register runner: LIM candidate, Raised by the vendor speaker. |
| Vendor constraint | "You will have to provision the access service before the delivery one, the platform enforces that order." (vendor) | decision | Step 1a then step 7. A constraint-accepting decision, Proposed, Consulted: vendor; never a need, since a vendor cannot state our needs. |
| Vendor on our process | "Normally our customers key the order straight into the portal." (vendor) | context | Step 1a. Not our current process and not our need. |
| Architect position | "The integration should go through the middleware rather than point to point." (architect) | decision | Step 1a then step 7. Proposed decision, Raised by the architect; the "should" is a design position, not a need. |
| Process introduction | "Sure. The order arrives by email from the sales team." | current | Process claim: "A new customer order is handled from the sales team's email." |
| Current step | "I key it into the ledger and then copy the reference into the tracking spreadsheet." | current | Two step claims, `step-of` the process; step 1 ledger, step 2 spreadsheet. |
| Current, not needed | "We still print a copy for the folder but nobody looks at it, it is just habit." | current-not-needed | Step 3, `retain no; nobody looks at it, it is just habit`. No need raised. |
| Legacy | "We used to fax the confirmation to the depot but that stopped when the depot closed." | legacy | Listed in the summary. Never a step. |
| Legacy beats current | "The confirmation goes over to the depot desk." where earlier passages establish the depot closed last year | legacy | Confidence inferred; question asks the human to confirm the depot desk is gone. |
| Need, replaces | "It must pick the order up from email automatically" | need | MoSCoW Must, `replaces` the ledger step claim if that is the step it removes; otherwise `replaces` the process claim. |
| Need, preserves | "we should keep the ledger entry because audit checks it" | need | MoSCoW Should, `preserves` the ledger step claim. |
| Obligation inside today's process | "The invoice has to go to finance before I key it." | current | "has to" is about today's process, not the solution; step claim, Retain: Yes. |
| Split passage | "It must pick the order up from email automatically, and we should keep the ledger entry because audit checks it." | need (a), need (b) | Split at "and". Part (a) as the replaces row above, part (b) as the preserves row. |
| Open item, not need | "We need to check whether finance still wants the spreadsheet." | open-item | "need to check" is work, not a need. |
| Unattributed | "That is something someone needs to find out." (no speaker tag) | open-item | Speaker Unattributed, role unknown; confidence extracted since the words are clear. |
| Decision | "We agreed with finance last month that the spreadsheet is the master until go-live." | decision | Apply model 4.5: a real choice, so a decision claim. |
| Current system shortfall | "The ledger cannot hold more than one reference per order, so we keep the second one in the spreadsheet." | system | Step 7 subject test: the ledger is in use today. `about ledger`. Also a current step for the spreadsheet if not already captured; ask rather than emit two claims from one passage. |
| Current system fact | "The ledger holds every customer's billing address, going back to 2009." | system | `about ledger`. A fact, not a need and not a limitation. |
| Limitation | "The new portal only lets us attach one document per order." | limitation | Step 7: the subject is the solution. |
| Subject unclear | "The system will not let us change the address once the order is placed." where no system is named nearby | limitation or system | Confidence inferred; the question asks which system. |
| Risk | "If the sales inbox goes down we do not see orders at all." | risk | Trigger is the inbox outage. |
| Context | "We get about two hundred orders a month." | context | `about` the process claim; fills Frequency or Systems in the PRC. |
| Merged multi-sentence passage | "Sure. The order arrives by email from the sales team. I key it into the ledger and then copy the reference into the tracking spreadsheet. We still print a copy for the folder but nobody looks at it, it is just habit." | current (a), current (b), current (c), current-not-needed (d) | Split at sentence or clause boundaries; (a) is the process claim, (b) and (c) are step claims for the ledger and the spreadsheet, (d) is step 3 with `retain no; nobody looks at it, it is just habit`. |
