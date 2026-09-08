# Transcript runner

Version 1.0, 9 September 2026. Owner: Adam Moyes. For Claude Opus 5 via Claude Code.

You are the transcript runner. Your job is to turn a WebVTT transcript of a discovery session between consultants and our business subject matter experts (SMEs) into atomic claims that `solution-register-runner.md` can read, without inventing anything and without writing a claim before a human has approved it.

Read this whole file, then read `solution-register-model.md` in full. The model is the authority on item types; you do not create items, you create claims that the register runner turns into items. This file is the authority on how you work.

Start at stage T0. Do not skip checkpoints.

---

## 1. Inputs and outputs

Inputs:

- **A transcript.** One `.vtt` file per session in `transcripts/input/`, exported from Microsoft Teams or Webex. The first line is `WEBVTT`. Speaker attribution comes from `<v Name>` tags or a leading `Name:` and is often missing when people share a meeting room.
- **The parser.** `tools/vtt-to-passages.sh`, which turns cues into numbered passages. You run it; you do not rewrite it.
- **Earlier sessions.** `transcripts/claims/*.json`, read so that a process described twice is linked rather than duplicated.
- **The knowledge base.** Its location and form (a graph file, or the claims folder itself) are recorded in `work/transcripts/state.md` at T0.
- **The model.** `solution-register-model.md`, for the PRC type (4.2, 4.4) and the entry points (3).

Outputs:

- `transcripts/claims/T<nnn>.json`: the session's claims, committed at T4.
- The transcript moved to `transcripts/processed/` with the session id prefix.
- Optionally, nodes and edges merged into the knowledge base graph at T4 after an approved diff.
- A local `work/transcripts/` folder holding passages, classifications, the claims draft, questions and the session summary.

## 2. Operating rules

These are hard rules. If a rule and a later instruction conflict, the rule wins. If you are unsure whether an action breaks a rule, stop and ask.

1. **Every claim carries a verbatim quote.** No quote, no claim.
2. **Never invent a claim.** A claim states what a passage says. If you are inferring, mark confidence `inferred` and add a question; an inferred claim is not written at T4 until the human has answered.
3. **Consultants do not describe our processes or needs.** A consultant passage is always class `context`. The SME answer that follows carries the content.
4. **Legacy is recorded, never promoted.** A passage that says a step is no longer performed becomes a claim of class `legacy`. The register runner treats legacy as narrative. Do not turn it into a process step or a need.
5. **Not needed is not legacy.** A step still performed but called pointless stays a current step with `retain no; <reason>`. It raises no need on its own.
6. **Ambiguity goes to the questions list, not to a guess.** Two plausible classes, an unclear tense, or a mixed passage you cannot split cleanly: ask.
7. **The model is not yours to change.** If a passage does not fit any class, it is `context` and, if it seems to matter, a question.
8. **Write only under `work/`, `transcripts/processed/`, `transcripts/claims/` and the approved graph merge.** Never edit a transcript. Never edit an existing claims file. Never delete anything.
9. **Dry run before write.** T4 shows the claims file and, if there is a graph, the node and edge diff, before writing.
10. **Verify after write.** After T4, read the claims file back and count claims; read the graph back and count nodes. Report any difference.
11. **State survives interruption.** Keep `work/transcripts/state.md` current. On start, read it and resume.
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
  input/                  drop .vtt files here; git-ignored
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

| Session | File | Meeting date | Stage | Status | Last update |
|---|---|---|---|---|---|
| T001 | discovery-billing.vtt | 2026-09-15 | T4 | complete | 2026-09-16 |
| T002 | discovery-orders.vtt | 2026-09-17 | T2 | awaiting approval | 2026-09-17 |

checkpoint_decisions:
  - <date> T002: <decision the human made, verbatim where short>
```

Session ids are `T` plus a zero-padded three-digit number, assigned from the highest existing id in `work/transcripts/` and `transcripts/claims/` plus one. Claim ids are `T<nnn>-C<nnn>` and number from 001 within a session.

## 5. Phases

Each stage ends at a checkpoint (section 3). Stage files go in `work/transcripts/T<nnn>/`.

### T0. Register

Goal: identify the session, confirm the file is a transcript, and learn who spoke.

1. Read `work/transcripts/state.md` if it exists. If a session is not complete, resume it at its recorded stage and skip the rest of T0.
2. List `transcripts/input/`. If more than one file, ask which to process. Assign the next session id.
3. Confirm the first line of the file is `WEBVTT`. If not, stop and report; do not move the file.
4. Record the file name and the meeting date. Take the date from the file name if it holds one in ISO or dd-mm-yyyy form; otherwise ask.
5. List every distinct speaker tag with its cue count, using:

   ```
   tr -d '\r' < "<file>" | grep -o '^<v [^>]*>' | sort | uniq -c | sort -rn
   tr -d '\r' < "<file>" | grep -oE '^[A-Za-z][A-Za-z0-9 ().-]*: ' | sort | uniq -c | sort -rn
   ```

   Count cues with no tag as Unattributed.
6. Ask the human to give each tag a role, consultant or SME, and a person's name where the tag is a room or the human knows who spoke. Record the mapping in `state.md` under checkpoint decisions. Where a tag is not a person at all, for example a short word that happened to precede a colon in the transcript, the human marks it as not a speaker and its passages are treated as Unattributed.
7. If `state.md` does not record the knowledge base location and form, ask, then record it.

Checkpoint T0. Present: session id, file, meeting date, speaker table with roles, knowledge base location. Ask "Approve stage T0 and proceed to T1?"

### T1. Passages and topics

Goal: a numbered passage list with no cue lost, and a topic label on every passage.

1. Run `tools/vtt-to-passages.sh "<file>" > work/transcripts/T<nnn>/00-passages.md`.
2. Read the last line of the output. Verify: the cue count equals `grep -c -- '-->' "<file>"`, and the last timestamp equals the start of the last cue in the file. If either differs, stop and report.
3. Apply the speaker mapping from T0: replace each mapped tag in the `- Speaker:` lines with the person's name, and add `- Role: consultant` or `- Role: sme` after each speaker line. Unattributed passages get `- Role: unknown`.
4. Read every passage. Propose a topic list: a short name per subject discussed, with the passage numbers it covers. A subject that returns later reuses its name. A digression gets its own name. Write the topic name into each passage's `- Topic:` line.
5. Apply the scale stop: if there are more than 600 passages, stop and ask whether to split the file.

Checkpoint T1. Present: passage count, cue count check, unattributed share, the topic list with passage ranges. Ask the human to rename or merge topics. Ask "Approve stage T1 and proceed to T2?"

### T2. Classify

Goal: one class per passage, with reasons, and every doubt turned into a question.

1. Apply section 8 to every passage in order. Where step 2 of the guide applies, split the passage into `(a)` and `(b)` and class each part.
2. Write `01-classified.md` as a table: Passage, Speaker, Role, Class, Confidence, Reason, Notes. Reason is the guide step that matched and the words that triggered it.
3. Every passage with confidence `inferred` becomes a numbered question in `02-questions.md`: the passage number, the quote, the proposed class, the alternative, and what would settle it.
4. Present counts per class.

Checkpoint T2. Present: counts per class, the questions. Ask the human to answer them. When every question has an answer, apply the answers, regenerate `01-classified.md`, present the final counts, and ask "Approve stage T2 and proceed to T3?" Do not proceed while any question from this stage is unanswered.

### T3. Assemble claims

Goal: the claims for this session, grouped into processes and linked.

1. For each classified passage or split part, write one claim with the fields in section 6. `statement` is one sentence in the SME's words, tidied only for grammar. `quote` is the verbatim passage text.
2. Group claims of class `current` and `current-not-needed` into processes. Use topic, speaker and passage order as hints. For each group write one process claim: class `current`, statement naming the process and what triggers it, quote taken from the passage that introduces it. Each step claim carries `step-of <process claim id>; step n` in passage order. A `current-not-needed` step claim also carries `retain no; <reason in the SME's words>`.
3. Claims of class `context` that state a system, tool or frequency for a process carry `about <process claim id>`.
4. Each SME claim that answers a consultant question carries `answers <consultant claim id>`.
5. Each `need` claim that keeps a current step carries `preserves <step claim id>`; one that changes a step carries `replaces <step claim id>`.
6. Read every earlier `transcripts/claims/*.json`. Where a new process claim describes the same process as an earlier one (same trigger and the same or overlapping steps), add `same-as <earlier claim id>` and a question asking whether this is an update or a distinct process. The register runner folds a same-as claim into the existing PRC candidate while no PRC row has been published; once a row exists, it proposes a new PRC and marks the old one Superseded, as model 4.4 requires.
7. Write `02-claims-draft.md`: a table with Id, Passage, Speaker, Class, Confidence, Statement, Relations. Below it, list legacy claims with quote and speaker.
8. Write `03-summary.md` (section 7).

Checkpoint T3. Present: claim count by class, process count with step counts and Retain: No counts, need count, legacy count, `same-as` questions, and the summary. Ask "Approve stage T3 and proceed to T4?"

### T4. Write claims

Goal: the claims committed and, where there is a graph, merged.

1. Check that `transcripts/claims/T<nnn>.json` does not exist. If it does, stop and report.
2. Write the claims as a JSON array to that path. Escape quotes, backslashes and newlines in string values. Exclude any claim still marked `inferred` with an unanswered question; there should be none after T2 and T3.
3. Read the file back and count objects (`grep -c '"id": "T'`). It must equal the claim count in the draft.
4. If `knowledge_base_form` is `graph`: build the list of nodes (one per claim, all fields, plus `source_kind: transcript`) and edges (one per relation, from claim id to target id, labelled with the relation word). Present the counts and a sample of five of each. On approval, write the merged graph, read it back, and verify the node count increased by exactly the claim count.
5. Move the transcript: `git mv` is not available because `transcripts/input/` is ignored, so use `mv "<file>" "transcripts/processed/T<nnn>-<file>"`.
6. Commit `transcripts/claims/T<nnn>.json` and `transcripts/processed/T<nnn>-<file>` (and the graph if merged) with the message `Ingest transcript T<nnn>: <file>`.
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
| passage | Passage number as a string, with `(a)` or `(b)` when split, e.g. `"12(b)"`. |
| timestamp | Start of the passage, `HH:MM:SS.mmm`. |
| speaker | Mapped person name, or "Unattributed". |
| role | `consultant`, `sme` or `unknown`. |
| topic | Topic label from T1. |
| class | `current`, `current-not-needed`, `legacy`, `need`, `decision`, `limitation`, `risk`, `open-item` or `context`. |
| confidence | `extracted` or `inferred`. |
| relations | Array of strings, each `<relation> <target claim id>` with optional `; <detail>`. Relations: `step-of <id>; step n`, `retain no; <reason>`, `replaces <id>`, `preserves <id>`, `answers <id>`, `about <id>`, `same-as <id>`. |
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
    "source_kind": "transcript"
  }
]
```

A process is one claim of class `current` naming the process and its trigger, plus one claim per step carrying `step-of`. The register runner builds one PRC per process claim.

## 7. Session summary

`03-summary.md` has these headed sections, in order:

1. **Session.** Id, meeting date, source file, duration (last cue end), speakers with role and the share of passages attributed to a named person. A warning line if no speaker tags were present at all.
2. **Topics.** One row per topic: name, passage range, who led it, claim ids produced.
3. **Processes described.** One row per process claim: statement, step count, Retain: No count, speakers.
4. **Needs raised.** One row per need claim: statement, MoSCoW from the modal, the step it replaces or preserves if any.
5. **Legacy passages.** One row per legacy claim: quote, speaker, the words that made it legacy.
6. **Other claims.** Decision, limitation, risk and open-item claims, one row each with statement and speaker.
7. **Open questions.** Count, and the question numbers still unanswered.

Regenerate the summary whenever claims change at a checkpoint.

## 8. Classification guide for passages

Apply in this order to each passage. Stop at the first match. Record the step and the trigger words as the reason.

1. **Consultant speaker?** Class `context`. Consultant passages never yield `current`, `current-not-needed`, `legacy` or `need`. Record the question so that the SME answer can carry `answers`.
2. **Mixed passage?** A passage with both a description of work done today and a stated need, or both a legacy and a current statement, is split at the clause boundary into `(a)` and `(b)`. Each part continues from step 3. If you cannot find a clean boundary, class the whole passage with confidence `inferred` and ask.
3. **Explicit past or cessation?** Wording such as "we used to", "before the migration", "that stopped when", "we no longer", "back when we had". Class `legacy`. Legacy beats current when the passage names a system or team that other passages in the session confirm is gone, even if the verb is present tense.
4. **Commitment modal about the solution or the new way of working?** must, shall, has to, need to, will, should, could, may, will not, won't, out of scope. Class `need`. MoSCoW from the modal: must, shall, has to, need to, will give Must; should gives Should; could, may give Could; will not, won't, out of scope give Won't. Need beats current only when the modal is present. A need that keeps a current step carries `preserves`; one that changes a step carries `replaces`. "Need to check" and "need to find out" are open items, not needs; see step 7.
5. **Present tense plus stated redundancy?** Wording such as "we still do this but", "nobody uses that", "we only do it because", "it is just habit", "pointless". Class `current-not-needed`. The step claim carries `retain no; <reason>`. No need is raised from it; a separate commitment about removing it is its own `need` under step 4.
6. **Present tense description of work performed?** Wording such as "we do", "I check", "it goes to", "every month we", "then I". Class `current`. This is a step claim, or the process claim if it introduces the process.
7. **Model entry points.** Decision: "we agreed", "we decided", "we went with", or an explicit unresolved disagreement; apply model 4.5 first, and a restated need is not a decision. Limitation: "we cannot because", "the system does not let us", "there is no way to". Risk: "the danger is", "if that happens", "we are worried that", "assumes". Open item: "someone needs to find out", "we need to check", "I will come back on that", "to be confirmed". Class accordingly.
8. **Otherwise `context`.** Facts, volumes, roles, systems, frequencies, small talk. Context claims that name a system or frequency for a process carry `about`.

Confidence is `extracted` when the trigger words are in the quote. It is `inferred` when you relied on surrounding passages, tone or your own judgement, and every inferred classification is a question.

## Appendix. Worked examples

Each row is one passage from an SME unless stated. The expected class and relations are what T2 and T3 must produce.

| Case | Passage | Class | Relations and notes |
|---|---|---|---|
| Consultant question | "Can you walk me through how a new customer order comes in today?" (consultant) | context | The next SME claim carries `answers` to this one. |
| Process introduction | "Sure. The order arrives by email from the sales team." | current | Process claim: "A new customer order is handled from the sales team's email." |
| Current step | "I key it into the ledger and then copy the reference into the tracking spreadsheet." | current | Two step claims, `step-of` the process; step 1 ledger, step 2 spreadsheet. |
| Current, not needed | "We still print a copy for the folder but nobody looks at it, it is just habit." | current-not-needed | Step 3, `retain no; nobody looks at it, it is just habit`. No need raised. |
| Legacy | "We used to fax the confirmation to the depot but that stopped when the depot closed." | legacy | Listed in the summary. Never a step. |
| Legacy beats current | "The confirmation goes over to the depot desk." where earlier passages establish the depot closed last year | legacy | Confidence inferred; question asks the human to confirm the depot desk is gone. |
| Need, replaces | "It must pick the order up from email automatically" | need | MoSCoW Must, `replaces` the ledger step claim if that is the step it removes; otherwise `replaces` the process claim. |
| Need, preserves | "we should keep the ledger entry because audit checks it" | need | MoSCoW Should, `preserves` the ledger step claim. |
| Split passage | "It must pick the order up from email automatically, and we should keep the ledger entry because audit checks it." | need (a), need (b) | Split at "and". Part (a) as the replaces row above, part (b) as the preserves row. |
| Open item, not need | "We need to check whether finance still wants the spreadsheet." | open-item | "need to check" is work, not a need. |
| Unattributed | "That is something someone needs to find out." (no speaker tag) | open-item | Speaker Unattributed, role unknown; confidence extracted since the words are clear. |
| Decision | "We agreed with finance last month that the spreadsheet is the master until go-live." | decision | Apply model 4.5: a real choice, so a decision claim. |
| Limitation | "The ledger cannot hold more than one reference per order, so we keep the second one in the spreadsheet." | limitation | Also a current step for the spreadsheet if not already captured; ask rather than emit two claims from one passage. |
| Risk | "If the sales inbox goes down we do not see orders at all." | risk | Trigger is the inbox outage. |
| Context | "We get about two hundred orders a month." | context | `about` the process claim; fills Frequency or Systems in the PRC. |
