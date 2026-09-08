# Transcript runner design

Date: 8 September 2026. Owner: Adam Moyes. Status: approved in discussion, awaiting spec review. Written against solution register model and runner version 2.10.

## 1. Purpose

Consultants will run discovery sessions with our business subject matter experts (SMEs). Each session is recorded and produces a WebVTT transcript from Microsoft Teams or Webex. From those transcripts we want:

- the current business processes, so the current state is known
- needs for the new solution, stated by SMEs with commitment language
- decisions, limitations, risks and open items that surface along the way

The transcript runner turns each transcript into atomic claims and adds them to the knowledge base that `solution-register-runner.md` reads. The register runner then extracts items from transcript claims the same way it does from document claims. This fills the transcript gap the register runner names in its section 1, and keeps one extraction path.

Legacy steps that SMEs no longer perform become claims classed as legacy. The register runner treats those as narrative, never as items. Current steps that SMEs say they do not need stay in the process record with a Retain flag of No and the stated reason, and raise no requirement on their own.

## 2. Deliverables

1. `transcript-runner.md`: instructions for the runner, in the style of `solution-register-runner.md`, with numbered sections, operating rules, a checkpoint protocol, a work folder, staged phases and a classification guide for passages.
2. Amendments to `solution-register-model.md`: the PRC item type and its relationships, entry point, register layout, outstanding view section and integrity rules; and the reworked change request lifecycle.
3. Amendments to `solution-register-runner.md`: transcript claims as an input, a classification step for process claims, and a note in section 9 on running the transcript runner first.
4. An appendix in `transcript-runner.md` of worked classification examples.

The README table gains rows for the transcript runner and the transcripts folder.

## 3. Model amendments

### 3.1 Entry point (model section 3)

New row: Current practice. Question: "This is how we do X today." Usually becomes PRC.

### 3.2 PRC item type (model 4.2, 4.3, 4.4)

Prefix PRC. States: Draft, Confirmed, Superseded*, Retired*.

Type-specific fields:

| Field | Rule |
|---|---|
| Trigger | What starts the process, one line. |
| Steps | Numbered list. Each step is written `n. <step> [Retain: Yes/No/Unknown] [Actor: <role or person>]`. A Retain of No carries the SME's reason after a semicolon inside the brackets. |
| Systems | Systems or tools touched today, comma separated. |
| Frequency | How often the process runs, as stated by the SME. Blank if not stated. |
| Described on | Date of the session in which it was described. |
| Raised by | The SMEs who described it, from cue attribution. "Unattributed" if none. |

Header field rules for PRC: Owner is not used; a PRC in Draft must have an open item in Links whose Owner is set, matching the pattern for Proposed decisions. Implemented by is not used. Vendor ref is not used. Source is the transcript file and passage numbers, or the claim ids.

Use it when: an SME describes work performed today. One row per named end-to-end process, with steps inside the row. A step is addressed as `PRC-nnn/step n`. Grain is process, not step, so the register stays readable in a meeting.

Transition rules:

- Draft on extraction. Described on and Raised by are set when the row is created.
- Confirmed when an SME or the owner of the driving open item agrees the description. The open item closes with Resolution = the PRC id.
- Superseded when a later session gives a fuller description. A new PRC is created and the old one carries "superseded by PRC-nnn" in Links.
- Retired when the process turns out not to be performed at all. Needs a one-line reason in Source or Links.

Scope: tagged at Domain or Customer service level.

### 3.3 Relationships (model section 5)

| From | Relationship | To |
|---|---|---|
| REQ | replaces | PRC-nnn/step n |
| REQ | preserves | PRC-nnn/step n |
| LIM | constrains | PRC |
| OI | clarifies | PRC |
| PRC | superseded by | PRC |

### 3.4 Register layout and outstanding view (model sections 7 and 8)

Register: Processes, columns ID, Title, Status, Trigger, Steps, Systems, Frequency, Described on, Raised by, Scope, Links, Source, Updated. Label `register-processes`.

Outstanding view gains a section: PRC in Draft older than 14 days.

### 3.5 Integrity rules (model section 9)

- I17 Process steps: every PRC step has a Retain value, and every Retain of No has a reason. Failure.
- I3 extended: a PRC in Draft must have an open item in Links whose Owner is set.
- I15 extended: PRC in Draft older than 14 days listed as a warning.

### 3.6 Change request lifecycle (model 4.2, 4.4, 4.3, 5, 7, 8, 9)

The change request type is reworked so that our own option design and stakeholder approval are visible states, a deferred change becomes a requirement for the named later phase, and a change that is not made but is answered with a workaround keeps its design.

States, in order. Terminal states marked *.

| State | Meaning | Required before leaving |
|---|---|---|
| Proposed | Raised. Reason says what the change buys. | Reason |
| Options | We design the options. Each carries a one-line impact and a target phase. Defer to a later phase and accept a workaround are always valid options. | Options, at least two |
| For approval | Options put to our stakeholders. | Consulted |
| Approved | An option for delivery in this phase was chosen. | Chosen option, Approved by, Approved on, Phase |
| Submitted | Handed to the vendor or the internal team. | Vendor ref when Implemented by is Vendor |
| Delivered* | Built. The requirement it delivers moves. | |
| Deferred* | The chosen option is delivery in a later phase. A requirement is created with Phase = that phase and MoSCoW set, and the CR carries "deferred as REQ-nnn". Any change needed when that phase starts raises a new CR. | Chosen option, Approved by, Approved on, Disposition record = REQ id |
| Workaround accepted* | The change is not made. A decision records the manual process or workaround; where the workaround is a manual process it is also a PRC row. | Chosen option, Approved by, Approved on, Disposition record = DEC id |
| Rejected* | No change and no workaround. The underlying need is Won't or Withdrawn. | Approved by, Approved on |

Type-specific fields: Phase (named phase, set when an option is chosen), Raised on, Raised by, Reason, Options (numbered list, each `n. <option>; impact: <cost and time, or effort and who>; phase: <phase>`), Chosen option (number), Consulted, Approved by, Approved on, Disposition record (REQ id on Deferred, DEC id on Workaround accepted), CR page (optional link to the page holding the full option designs, as for Decision page). The single Impact field is removed; impact lives inside each option. Implemented by, Vendor ref and Source are unchanged. The row carries no Owner, Next action or Due; the driving open item does, and a CR in Proposed, Options, For approval or Submitted must have one in Links.

Vendor impact assessment is no longer a state. A vendor estimate is an input to Options, and waiting for it is the driving open item's next action.

Relationships added to model section 5: `CR deferred as REQ`, `CR dispositioned by DEC`, `REQ triggered by CR` (the reverse of "deferred as", written on either side).

Register layout: Register: Change requests columns become ID, Title, Status, Phase, Reason, Options, Chosen option, Consulted, Approved by, Approved on, Disposition record, CR page, Implemented by, Raised on, Raised by, Scope, Vendor ref, Links, Source, Updated.

Outstanding view section 4 becomes: change requests in Proposed, Options or For approval.

Integrity rules: I2 updated so a CR has Reason once past Proposed, at least two Options once past Options, Consulted once past For approval, Chosen option and Phase once Approved or in a terminal state other than Rejected, and Vendor ref once Submitted with Implemented by = Vendor. I10 updated so Approved by and Approved on are required in Approved, Submitted, Delivered, Deferred, Workaround accepted and Rejected. New I18: every CR in Deferred has a Disposition record naming a REQ whose Phase is a later phase, and every CR in Workaround accepted has a Disposition record naming a DEC in Accepted. Failure.

The "part of" relationship and the rule for a Both change split into two rows are unchanged.

## 4. Transcript claims

### 4.1 Claim record

One claim per atomic statement. Fields:

| Field | Rule |
|---|---|
| id | `T<session>-C<nnn>`, e.g. `T003-C017`. Never reused. |
| statement | One sentence, in the SME's words tidied only for grammar. |
| quote | Verbatim passage text. Mandatory. |
| session | Session id. |
| file | Transcript file name. |
| passage | Passage number, with `(a)` or `(b)` when split. |
| timestamp | Start of the passage. |
| speaker | Cue speaker name, or "Unattributed". |
| role | consultant or sme, from the T0 mapping. |
| topic | Topic label. |
| class | One of: current, current-not-needed, legacy, need, decision, limitation, risk, open-item, context. |
| confidence | extracted or inferred. Inferred means the class or a relation was the runner's judgement rather than the passage's wording. |
| relations | List of `<relation> <target>` where target is a claim id. Relations: `step-of` (a step claim to its process claim, with `step n`), `retain no; <reason>` on a step claim, `replaces` and `preserves` (a need claim to a step claim), `answers` (an SME claim to the consultant question claim before it), `about` (a context claim to a process claim), `same-as` (a process claim to an earlier session's process claim). |

A process is represented as one claim of class current with `statement` naming the process and its trigger, and one claim per step carrying `step-of` and `step n`. Systems and frequency, when stated, are claims of class context with an `about` relation to the process claim.

### 4.2 Storage

Claims for a session are written to `transcripts/claims/T003.json` as a JSON array. This is the transcript runner's output and is committed. If the knowledge base is a graph file, a merge step at T4 adds each claim as a node with `source_kind: transcript` and each relation as an edge, after showing the diff and getting approval. If the knowledge base is another form, the register runner's Phase 0 reads the claims folder as a second knowledge base and records its schema in `00-access.md`.

The register runner keeps its rule 1: it never modifies the knowledge base. Only the transcript runner writes claims, and only at T4.

## 5. Passages and topics

### 5.1 Passages

The runner parses WebVTT cues with shell tools only. Consecutive cues from the same speaker with a gap of five seconds or less are merged into one passage. Each passage carries a sequence number from 1, the start timestamp of its first cue, the speaker name as it appears in the cue or "Unattributed", and the verbatim text.

### 5.2 Speaker roles

At registration the human maps each detected speaker to consultant or SME, and to a person's name where the tag is a room or blank and the human knows who spoke. Room-tagged passages stay Unattributed unless assigned.

### 5.3 Topics

A topic is a soft label on each passage naming the subject under discussion. Topics are names, not spans, so a recurring subject reuses the label and a digression gets its own. The runner proposes the topic list with passage ranges after passages are written, and the human adjusts at the checkpoint. Topics are hints for grouping step claims into processes and for the session summary. Classification does not depend on topic.

## 6. Classification guide for passages

Apply in order to each passage. Stop at the first match. Record the reason.

1. **Consultant speaker?** Class context. Consultant passages never yield current, current-not-needed, legacy or need. Their questions frame the SME answer that follows, recorded with an `answers` relation.
2. **Mixed passage?** A passage with both a current description and a stated need is split at the clause into `(a)` and `(b)`, and each part continues from step 3.
3. **Explicit past or cessation?** "we used to", "before the migration", "that stopped when", "we no longer". Class legacy. Legacy beats current when the passage names a system or team that other passages in the session confirm is gone.
4. **Commitment modal about the solution or the new way of working?** must, shall, has to, need to, will, should, could, may, will not, won't, out of scope. Class need. MoSCoW from the modal: must, shall, has to, need to, will give Must; should gives Should; could, may give Could; will not, won't, out of scope give Won't. Need beats current only when the modal is present. A need that keeps a current step carries `preserves`; one that changes a step carries `replaces`.
5. **Present tense plus stated redundancy?** "we still do this but", "nobody uses that", "we only do it because". Class current-not-needed. The step claim carries `retain no; <reason>`. No need claim is raised from it; a separate commitment about removing it is its own need claim under step 4.
6. **Present tense description of work performed?** "we do", "I check", "it goes to", "every month we". Class current, as a step claim or a process claim.
7. **Model entry points.** Decision ("we agreed", "we decided", "we went with", or explicit unresolved disagreement), limitation ("we cannot because", "the system does not let us"), risk ("the danger is", "if that happens", "we are worried that"), open item ("someone needs to find out", "we need to check", "I will come back on that"). Class accordingly. Apply model 4.5 before classing a decision.
8. **Otherwise context.** Facts, volumes, roles, small talk.

Ambiguity: where two classes are plausible or tense is unclear, the runner records its proposed class with confidence inferred and adds a question. Inferred claims are not written at T4 until the human has answered.

Hard rules carried over: no claim without a verbatim quote, no inference from silence, ambiguity goes to the questions list, the model is not the runner's to change.

## 7. Phases

### 7.1 Folder layout

```
transcripts/
  input/                  drop .vtt files here (git-ignored)
  processed/              moved after T4, prefixed with session id, e.g. T003-discovery-billing.vtt
  claims/                 one JSON file per session, committed
work/
  transcripts/
    state.md              per-session stage table and claim counter
    T003/
      00-passages.md      number, timestamp, speaker, role, topic, text
      01-classified.md    passage, class, confidence, reason, split marker
      02-claims-draft.md  claims in table form for review, with relations
      02-questions.md     numbered questions for this session
      03-summary.md       per-session summary
```

`work/` stays git-ignored as in the register runner. `transcripts/input/` is git-ignored.

### 7.2 State file

`work/transcripts/state.md` holds one row per session: id, file name, meeting date, stage (T0 to T4), status (in progress, awaiting approval, complete), last update. Below the table: the location of the knowledge base and its form (graph file or other), and the last claim number per session. On start the runner reads the file and resumes the first session that is not complete.

### 7.3 Checkpoint protocol

As register runner section 3: write the stage files, post a summary with counts and questions, ask "Approve stage Tn and proceed to Tn+1?", update state, end the turn. Silence, a question or a partial answer is not approval.

### 7.4 Stages

**T0 Register.** Assign the next session id by listing `work/transcripts/`. Confirm the file's first line is `WEBVTT`; otherwise stop. Record file name and meeting date. List detected speaker tags with cue counts. Ask the human to assign each a role and, where needed, a name. Confirm the knowledge base location and form if state does not hold it. Checkpoint.

**T1 Passages and topics.** Parse cues and merge into passages. Write `00-passages.md`. Verify no cue is lost: cue count in the file equals cues consumed, and the last passage timestamp equals the last cue timestamp. Propose the topic list with passage ranges and write topic labels into the passage file. Scale stop at 600 passages. Checkpoint reports passage count, unattributed share, and the topic list.

**T2 Classify.** Apply section 6 to every passage. Write `01-classified.md`. Every inferred classification becomes a numbered question in `02-questions.md` with the proposed class. Checkpoint reports counts per class and the questions. Approval requires every question from this stage answered; answers are applied and the file regenerated before the checkpoint is presented again.

**T3 Assemble claims.** Write one claim per classified passage or split part, with the fields in 4.1. Group current and current-not-needed step claims into processes using topic and speaker as hints, and write a process claim per group with `step-of` relations in passage order. Attach `answers`, `replaces`, `preserves` and `about` relations. Where a process claim matches an existing process claim in `transcripts/claims/` by statement, record a `same-as` relation and add a question rather than a second process. Write `02-claims-draft.md` and `03-summary.md`. Checkpoint presents the claims table, the legacy list and the summary.

**T4 Write claims.** Check that no claim id collides with an existing file in `transcripts/claims/`. Write `transcripts/claims/T003.json`. If the knowledge base is a graph file, produce a diff of nodes and edges to add, present it, and on approval apply it and read the file back to verify the node count. Move the VTT to `transcripts/processed/` with the session id prefix. Commit the claims file and the moved transcript. Set the session complete only after the commit succeeds.

### 7.5 Session summary

`03-summary.md` contains:

- Header: session id, meeting date, source file, duration, speakers with role and attribution rate, and a warning line if no speaker tags were present.
- Topics: one row per topic with passage range, who led it, and claim ids produced.
- Processes described: each process claim with a one-line description, step count and count of Retain: No steps.
- Needs raised: each need claim with MoSCoW and the step it replaces or preserves.
- Legacy passages: each legacy claim with speaker and reason.
- Other claims: decision, limitation, risk and open-item claims by class.
- Open questions: count and question numbers.

## 8. Register runner amendments

1. Section 1, inputs: the knowledge base may include transcript claims produced by `transcript-runner.md`, identified by `source_kind: transcript` or by living under `transcripts/claims/`. Their `class` field is authoritative for steps 0 and 0a below.
2. Section 6, classification guide, new first steps:
   - 0. **Transcript claim of class legacy or context?** Narrative. Never an item. A legacy claim is listed in `02-mapping.md` with reason "legacy practice".
   - 0a. **Transcript claim of class current or current-not-needed?** Candidate PRC. One PRC per process claim; step claims become the Steps field in `step n` order with Retain from the `retain` relation. Raised by from speaker names. Described on from the session date. Source lists the claim ids.
   - Transcript claims of class need, decision, limitation, risk and open-item enter the existing steps 1 to 5 with their class as the starting proposal. `replaces` and `preserves` relations become Links on the REQ once both sides have provisional ids.
3. Section 4, work folder: `02-mapping.md` gains a count of transcript claims by class.
4. Section 5, Phase 1: coverage gaps now say which sessions have been ingested rather than that transcripts are absent.
5. Section 7, target structure: Register: Processes row from 3.4.
6. Section 9: note that transcript sessions are run with `transcript-runner.md` first, and that their claims land in `transcripts/claims/` or the graph for Phase 2 to read.
7. Section 5, Phase 2, step 3 (status): a change request carrying a vendor number is at least Submitted; one described as having options or estimates under consideration is Options; one described as deferred or for a later release becomes Deferred with a question asking for the REQ to create, not a Phase change; one described as answered by a workaround or manual process becomes Workaround accepted with a question asking for the DEC. Step 4 (fields): Options are filled only from claim wording that names alternatives; otherwise blank with a question. Chosen option is filled only where the claim says which was chosen.

## 9. Error handling

- File not starting with `WEBVTT`: stop at T0.
- No speaker tags anywhere: proceed with every passage Unattributed and a warning in the summary.
- Over 600 passages: stop after T1 and ask whether to split.
- Claim id collision or knowledge base write failure at T4: stop and report; the session stays at T4 in progress.
- The runner never edits a processed VTT, never deletes a file, never modifies existing claims, and writes only under `work/`, `transcripts/processed/`, `transcripts/claims/` and the approved graph merge.
- No new software is installed. VTT parsing and JSON writing use awk, sed, grep and shell built-ins; the graph merge uses the same, or stops and asks if the graph format needs more.

## 10. Testing

- Parser: run T1 over the example VTT. Pass is the cue count and last timestamp checks.
- Classification and assembly: a walkthrough of the example VTT with the human at each checkpoint.
- Worked examples: an appendix in `transcript-runner.md` with one sentence per step of section 6, plus one split passage and one legacy-beats-current case, each with the expected class and relations. Re-run by hand when rules change.
- End to end: after T4 on the example, run the register runner's Phase 2 against the claims and confirm a PRC candidate with Retain flags and a REQ candidate linking `replaces` appear in `02-candidates.md`.

## 11. Out of scope

- Emails, documents and chat as inputs.
- Speaker identification beyond the cue tag and the human mapping.
- Writing to Confluence from the transcript runner.
- Merging PRC rows across sessions beyond the `same-as` relation and question at T3.

## 12. Open assumption

The form of the knowledge base is not fixed in the runner; it is discovered at Phase 0. This spec assumes either a graph file with nodes and edges or a folder of claim files. If the knowledge base is produced by a tool with its own claim schema, the 4.1 record maps onto it at T4 and the field names in 4.1 become the transcript runner's internal names.
