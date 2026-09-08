# Transcript Runner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a transcript runner that turns WebVTT discovery-session transcripts into atomic claims for the register runner, add the PRC (process) item type and the reworked change request lifecycle to the model, and wire the register runner to consume transcript claims.

**Architecture:** Three markdown documents carry the behaviour: `solution-register-model.md` (what items are), `solution-register-runner.md` (how the register runner works) and a new `transcript-runner.md` (how transcripts become claims). One shell script parses WebVTT into passages deterministically; everything after that is LLM work directed by the runner document and gated by checkpoints. Claims are JSON files under `transcripts/claims/`.

**Tech Stack:** Markdown, POSIX shell, awk, sed, grep. No new software on the host. Git for commits.

**Spec:** `docs/superpowers/specs/2026-09-08-transcript-runner-design.md`

## Global Constraints

- Australian English. No em dashes anywhere in prose or documents.
- No new software on the host. Scripts use only bash, awk, sed, grep, cut, head, tail.
- Model changes go in the model file; runner behaviour goes in the runner files (README rule).
- Existing model and runner are version 2.10. Every edited file bumps to 2.11 with today's date, 9 September 2026.
- `work/` and `transcripts/input/` are git-ignored. `transcripts/claims/` and `transcripts/processed/` are committed.
- Commit after every task. Commit messages end with the Claude co-author trailer used in this repo's recent commits.
- Documents are checked with `grep` assertions; the parser is checked with a shell test script. Run the check before committing.

## File structure

| File | Responsibility |
|---|---|
| `solution-register-model.md` | Modify: PRC type, CR lifecycle, links, layouts, views, integrity rules |
| `solution-register-runner.md` | Modify: transcript claims as input, classification steps 0 and 0a, CR status mapping, Register: Processes page, run note |
| `transcript-runner.md` | Create: the transcript runner instructions and worked examples |
| `tools/vtt-to-passages.sh` | Create: WebVTT to passages parser |
| `tools/test-vtt-to-passages.sh` | Create: parser test |
| `tools/fixtures/sample.vtt`, `tools/fixtures/not-vtt.txt` | Create: fixtures |
| `transcripts/claims/.gitkeep`, `transcripts/processed/.gitkeep`, `transcripts/input/.gitkeep` | Create: folder scaffolding |
| `README.md` | Modify: new rows and a line on running order |

---

### Task 1: PRC item type in the model

**Files:**
- Modify: `solution-register-model.md` (lines 3, 46-51, 78-85, 87-96, 98-105, 130-142, 162-169, 177-184, 196-219)

**Interfaces:**
- Produces: the strings `| Process | PRC |`, `Register: Processes` columns, link words `replaces`, `preserves`, `clarifies`, `superseded by`, rule `I17`. Task 3 and Task 6 refer to these by name.

- [ ] **Step 1: Write the check script**

Create `tools/check-model-prc.sh`:

```bash
#!/usr/bin/env bash
set -u
f="$(dirname "$0")/../solution-register-model.md"
fail=0
need() { grep -qF -- "$1" "$f" && echo "ok   $1" || { echo "FAIL $1"; fail=1; }; }
need "Version 2.11, 9 September 2026"
need "| Current practice | This is how we do X today. | PRC |"
need "| Process | PRC | Draft, Confirmed, Superseded*, Retired* |"
need "| Process | An SME describes work performed today."
need "- Process: Draft on extraction."
need "| REQ | replaces | PRC-nnn/step n |"
need "| REQ | preserves | PRC-nnn/step n |"
need "| LIM | constrains | PRC |"
need "| OI | clarifies | PRC |"
need "| PRC | superseded by | PRC |"
need "| Processes | ID, Title, Status, Trigger, Steps, Systems, Frequency, Described on, Raised by, Scope, Links, Source, Updated |"
need "7. Processes in Draft older than 14 days, measured from Described on."
need "| I17 Process steps |"
need "a PRC in Draft"
exit $fail
```

- [ ] **Step 2: Run it to see it fail**

Run: `chmod +x tools/check-model-prc.sh && tools/check-model-prc.sh`
Expected: every line `FAIL`, exit 1.

- [ ] **Step 3: Bump the version line**

Line 3 of `solution-register-model.md` becomes:

```
Version 2.11, 9 September 2026. Owner: Adam Moyes.
```

- [ ] **Step 4: Add the entry point**

After the `| Event |` row in section 3 add:

```
| Current practice | This is how we do X today. | PRC |
```

Change the sentence "Four kinds of thing come in" to "Five kinds of thing come in". Change the closing sentence to: "Asks and events are work first and record later. Requirements, discoveries and current practice can go straight to a record."

- [ ] **Step 5: Add the PRC row to 4.2**

After the `| Change request |` row in the 4.2 table add:

```
| Process | PRC | Draft, Confirmed, Superseded*, Retired* | Trigger (what starts the process, one line), Steps (numbered list; each step is `n. <step> [Retain: Yes/No/Unknown] [Actor: <role or person>]`, and a Retain of No carries the SME's reason after a semicolon inside the brackets), Systems (touched today, comma separated), Frequency (as stated by the SME, blank if not stated), Described on (date of the session), Raised by (the SMEs who described it, from transcript attribution; "Unattributed" if none) |
```

- [ ] **Step 6: Add the 4.3 row**

After the `| Change request |` row in the 4.3 "Use it when" table add:

```
| Process | An SME describes work performed today. One row per named end-to-end process, with steps inside the row, so the register stays readable in a meeting. A step is addressed as PRC-nnn/step n. Legacy steps no longer performed are never recorded here; current steps the SME says are not needed are recorded with Retain: No and the reason, and raise no requirement on their own. |
```

- [ ] **Step 7: Add the 4.4 transition rule**

After the `- Change request:` bullet in 4.4 add:

```
- Process: Draft on extraction. Described on and Raised by are set when the row is created. Owner, Implemented by and Vendor ref are not used; a process in Draft must have an open item in Links whose Owner is set, as for a Proposed decision. Confirmed when an SME or the owner of the driving open item agrees the description, and that open item closes with Resolution = the PRC id. Superseded when a later session gives a fuller description: create a new PRC and write "superseded by PRC-nnn" in the old one's Links. Retired when the process turns out not to be performed at all, with a one-line reason in Source or Links. Scope is tagged at Domain or Customer service level.
```

- [ ] **Step 8: Add the links**

After the `| CR | part of |` row in section 5 add:

```
| REQ | replaces | PRC-nnn/step n |
| REQ | preserves | PRC-nnn/step n |
| LIM | constrains | PRC |
| OI | clarifies | PRC |
| PRC | superseded by | PRC |
```

- [ ] **Step 9: Add the register layout**

After the `| Change requests |` row in the section 7 table add:

```
| Processes | ID, Title, Status, Trigger, Steps, Systems, Frequency, Described on, Raised by, Scope, Links, Source, Updated |
```

In the paragraph above the table, change "Only requirements and open items carry an Owner." to "Only requirements and open items carry an Owner. Processes carry neither Owner nor Implemented by nor Vendor ref."

- [ ] **Step 10: Add the outstanding view item**

After item 6 of the meeting view in section 8 add:

```
7. Processes in Draft older than 14 days, measured from Described on.
```

- [ ] **Step 11: Add the integrity rules**

In section 9, change the I3 row's last sentence to end: "...and a change request in Proposed, Submitted or Impact assessment must each have an open item in Links whose Owner is set, and so must a PRC in Draft." Change the I15 row to: "DEC in Proposed, REQ in Draft and PRC in Draft older than 14 days are listed as warnings." After the I16 row add:

```
| I17 Process steps | Every PRC step has a Retain value of Yes, No or Unknown, and every Retain of No has a reason after the semicolon. |
```

Change the closing line to: "I1 to I14 and I17 are failures. I15 and I16 are warnings." Also change "from the six registers" in section 10 item 1 to "from the seven registers".

- [ ] **Step 12: Run the check and commit**

Run: `tools/check-model-prc.sh`
Expected: all `ok`, exit 0.

```bash
git add solution-register-model.md tools/check-model-prc.sh
git commit -m "Model 2.11: add PRC process item type

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EdaDxtjK4PrT5ZSTMU4T3t"
```

---

### Task 2: Change request lifecycle in the model

**Files:**
- Modify: `solution-register-model.md` (4.2 CR row, 4.4 CR bullet, section 5, section 7 CR row, section 8 item 4 and next-phase list, section 9 I2, I10, new I18)

**Interfaces:**
- Produces: CR states `Proposed, Options, For approval, Approved, Submitted, Delivered*, Deferred*, Workaround accepted*, Rejected*`; link words `deferred as`, `dispositioned by`; rule `I18`. Task 3 uses the state names in the status mapping.

- [ ] **Step 1: Write the check script**

Create `tools/check-model-cr.sh`:

```bash
#!/usr/bin/env bash
set -u
f="$(dirname "$0")/../solution-register-model.md"
fail=0
need() { grep -qF -- "$1" "$f" && echo "ok   $1" || { echo "FAIL $1"; fail=1; }; }
absent() { grep -qF -- "$1" "$f" && { echo "FAIL still present: $1"; fail=1; } || echo "ok   absent: $1"; }
need "| Change request | CR | Proposed, Options, For approval, Approved, Submitted, Delivered*, Deferred*, Workaround accepted*, Rejected* |"
need "Options (numbered list"
need "Chosen option"
need "CR page"
need "| CR | deferred as | REQ |"
need "| CR | dispositioned by | DEC |"
need "| Change requests | ID, Title, Status, Phase, Reason, Options, Chosen option, Consulted, Approved by, Approved on, Disposition record, CR page, Implemented by, Raised on, Raised by, Scope, Vendor ref, Links, Source, Updated |"
need "4. Change requests in Proposed, Options or For approval."
need "| I18 Change request disposition |"
absent "Impact assessment"
absent "Deferring a change request is a change of Phase"
exit $fail
```

- [ ] **Step 2: Run it to see it fail**

Run: `chmod +x tools/check-model-cr.sh && tools/check-model-cr.sh`
Expected: the `need` lines FAIL; the two `absent` lines FAIL because the old text is present. Exit 1.

- [ ] **Step 3: Replace the 4.2 CR row**

Replace the `| Change request | CR | ...` row with:

```
| Change request | CR | Proposed, Options, For approval, Approved, Submitted, Delivered*, Deferred*, Workaround accepted*, Rejected* | Phase (the named phase the chosen option lands in, set when an option is chosen), Raised on (date), Raised by (person, or the meeting or review it came from), Reason (one line: what the change buys), Options (numbered list, each `n. <option>; impact: <cost and time, or effort and who>; phase: <phase>`; defer to a later phase and accept a workaround are always valid options), Chosen option (the option number), Consulted (vendor, SMEs, stakeholder groups who had input), Approved by, Approved on, Disposition record (REQ id on Deferred, DEC id on Workaround accepted), CR page (optional link to the page holding the full option designs) |
```

- [ ] **Step 4: Replace the 4.4 CR bullet**

Replace the whole `- Change request:` bullet with:

```
- Change request: Raised on and Raised by are set when the row is created. Proposed means ours and being reasoned; Reason must be filled before it leaves Proposed. Options means we are designing the alternatives; at least two Options, each with an impact and a target phase, must be filled before it leaves Options, and a vendor estimate is an input here rather than a state of its own. For approval means the options are with our stakeholders; Consulted must be filled before it leaves. Approved means an option for delivery in this phase was chosen, and needs Chosen option, Approved by, Approved on and Phase. Submitted means handed to whoever will implement it; with Implemented by = Vendor, Submitted needs a Vendor ref. Delivered is set when the change is built and the requirement it delivers moves. Deferred means the chosen option is delivery in a later phase: create a requirement with Phase = that phase and MoSCoW set, write its id in Disposition record and "deferred as REQ-nnn" in Links, and close the change request; a change needed when that phase starts raises a new one. Workaround accepted means the change is not made and a decision records the manual process or workaround: write the DEC id in Disposition record and "dispositioned by DEC-nnn" in Links; where the workaround is a manual process, it is also a PRC row. Rejected means no change and no workaround, and the underlying need is Won't or Withdrawn. Approved, Deferred, Workaround accepted and Rejected each need Approved by and Approved on. A change request in Proposed, Options, For approval or Submitted must have an open item in Links carrying the owner, next action and due date; the row itself has none. The design produced for every option, including a workaround, lives on the CR page or in the design document, never on the row. A change with Implemented by = Both stays one row unless the vendor part and the internal part are approved separately, in which case it is two rows linked "part of".
```

- [ ] **Step 5: Add the links**

After the `| CR | part of |` row (before the PRC rows added in Task 1) add:

```
| CR | deferred as | REQ (the requirement also carries "triggered by CR-nnn") |
| CR | dispositioned by | DEC (on Workaround accepted) |
```

- [ ] **Step 6: Replace the section 7 CR row**

Replace the `| Change requests | ...` row with:

```
| Change requests | ID, Title, Status, Phase, Reason, Options, Chosen option, Consulted, Approved by, Approved on, Disposition record, CR page, Implemented by, Raised on, Raised by, Scope, Vendor ref, Links, Source, Updated |
```

- [ ] **Step 7: Update section 8**

Replace item 4 of the meeting view with:

```
4. Change requests in Proposed, Options or For approval.
```

Replace item 3 of the next-phase view with:

```
3. Change requests in Deferred, with their disposition requirement.
```

- [ ] **Step 8: Update the integrity rules**

In the I2 row replace the sentence beginning "Every change request has Phase, Raised on and Raised by" with: "Every change request has Raised on and Raised by; Reason once past Proposed; at least two Options once past Options; Consulted once past For approval; Chosen option and Phase once Approved or in a terminal state other than Rejected; and Vendor ref once Submitted with Implemented by = Vendor."

In the I3 row replace "a change request in Proposed, Submitted or Impact assessment" with "a change request in Proposed, Options, For approval or Submitted".

Replace the I10 row with:

```
| I10 Change request approval | Every CR in Approved, Submitted, Delivered, Deferred, Workaround accepted or Rejected has Approved by and Approved on. |
```

After I17 add:

```
| I18 Change request disposition | Every CR in Deferred has a Disposition record naming a REQ whose Phase is a later phase, and every CR in Workaround accepted has a Disposition record naming a DEC in Accepted. No CR in another state has one. |
```

Change the closing line to: "I1 to I14, I17 and I18 are failures. I15 and I16 are warnings."

- [ ] **Step 9: Run both checks and commit**

Run: `tools/check-model-cr.sh && tools/check-model-prc.sh`
Expected: all `ok`, exit 0.

```bash
git add solution-register-model.md tools/check-model-cr.sh
git commit -m "Model 2.11: rework change request lifecycle

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EdaDxtjK4PrT5ZSTMU4T3t"
```

---

### Task 3: Register runner amendments

**Files:**
- Modify: `solution-register-runner.md` (line 3, section 1 lines 17, section 4 line 71, Phase 1 step 6 line 119, Phase 2 steps 3 and 4 lines 130-131, section 6 lines 183-191, section 7 table line 208, section 9)

**Interfaces:**
- Consumes: claim `class` values from the spec section 4.1: `current, current-not-needed, legacy, need, decision, limitation, risk, open-item, context`; relations `step-of`, `retain no`, `replaces`, `preserves`.
- Produces: the sentence "run with `transcript-runner.md` first" that Task 8's README relies on.

- [ ] **Step 1: Write the check script**

Create `tools/check-runner.sh`:

```bash
#!/usr/bin/env bash
set -u
f="$(dirname "$0")/../solution-register-runner.md"
fail=0
need() { grep -qF -- "$1" "$f" && echo "ok   $1" || { echo "FAIL $1"; fail=1; }; }
absent() { grep -qF -- "$1" "$f" && { echo "FAIL still present: $1"; fail=1; } || echo "ok   absent: $1"; }
need "Version 2.11, 9 September 2026"
need "source_kind: transcript"
need "0. **Transcript claim of class legacy or context?**"
need "0a. **Transcript claim of class current or current-not-needed?**"
need "becomes Deferred with a question asking for the REQ"
need "becomes Workaround accepted with a question asking for the DEC"
need "| Register: Processes |"
need "transcript-runner.md"
need "transcript claims by class"
absent "at least Submitted. A change request or requirement described as deferred or for a later release gets Phase = next phase"
exit $fail
```

- [ ] **Step 2: Run it to see it fail**

Run: `chmod +x tools/check-runner.sh && tools/check-runner.sh`
Expected: `need` lines FAIL, exit 1.

- [ ] **Step 3: Version and inputs**

Line 3 becomes `Version 2.11, 9 September 2026. Owner: Adam Moyes. For Claude Opus 5 via Claude Code.`

Replace the knowledge base bullet in section 1 with:

```
- **The knowledge base.** A set of atomic claims built by ingesting design documents and, where `transcript-runner.md` has been run, discovery-session transcripts. Transcript claims are identified by `source_kind: transcript` on the claim, or by living under `transcripts/claims/`, and carry a `class` field that section 6 steps 0 and 0a use directly. Sessions that have not been ingested leave decisions made verbally, open items raised in meetings and their owners under-represented. Do not compensate for that by guessing; report which sessions are ingested and which are not (Phase 1).
```

- [ ] **Step 4: Work folder and Phase 1**

In section 4 change the `02-mapping.md` line to:

```
  02-mapping.md         Phase 2: claim to candidate mapping, including claims that produced no item and why, and a count of transcript claims by class
```

In Phase 1 step 6 replace "item types the knowledge base is unlikely to hold well because transcripts were not ingested (open items, meeting decisions, owners, due dates)" with "which transcript sessions under `transcripts/claims/` are present and which known sessions are not, and the item types that suffer when sessions are missing (open items, meeting decisions, owners, due dates)".

- [ ] **Step 5: Phase 2 status and field mapping**

In Phase 2 step 3 replace the sentence "A change request that carries a vendor number is at least Submitted. A change request or requirement described as deferred or for a later release gets Phase = next phase, not a terminal state." with:

```
A change request that carries a vendor number is at least Submitted. One described as having options or estimates under consideration is Options. One described as deferred or for a later release becomes Deferred with a question asking for the REQ to create as its disposition; a requirement described that way gets Phase = next phase. One described as answered by a workaround or manual process becomes Workaround accepted with a question asking for the DEC.
```

In Phase 2 step 4, after the sentence about Reason on a change request, add: "Options on a change request are filled only from claim wording that names alternatives with their impact; otherwise blank with a question. Chosen option is filled only where the claim says which option was chosen."

- [ ] **Step 6: Classification guide steps 0 and 0a**

In section 6, after "Apply in this order to each claim. Stop at the first match. Record the reason." and before step 1, insert:

```
0. **Transcript claim of class legacy or context?** Narrative. Never an item. A legacy claim is listed in `02-mapping.md` with the reason "legacy practice" so the discard is traceable.
0a. **Transcript claim of class current or current-not-needed?** Candidate PRC. One PRC per process claim. Its step claims (those carrying `step-of` this process) become the Steps field in `step n` order, with Retain: Yes unless the step claim carries `retain no; <reason>`, in which case Retain: No and the reason. Actor comes from the step claim's wording where it names one. Raised by is the speaker names on the claims; Described on is the session date; Source lists the claim ids. Context claims with an `about` relation to the process fill Systems and Frequency. A process claim with a `same-as` relation to an earlier session's process claim is an update to that PRC candidate, not a new one; record it and add a question.
0b. **Transcript claim of class need, decision, limitation, risk or open-item?** Continue at the step below that matches the class, using the class as the starting proposal. A need claim carrying `replaces` or `preserves` gives the REQ a Links entry "replaces PRC-pnnn/step n" or "preserves PRC-pnnn/step n" once both sides have provisional ids.
```

- [ ] **Step 7: Target structure and run note**

In section 7 after the `| Register: Change requests |` row add:

```
| Register: Processes | Table with the Processes columns |
```

Change "A hand-maintained page with six headed sections" to "seven headed sections".

In section 9, after the resume paragraph, add:

```
Transcript sessions are ingested first with `transcript-runner.md`. Its claims land in `transcripts/claims/` or in the knowledge base graph, and Phase 2 reads them like any other claim.
```

- [ ] **Step 8: Run the check and commit**

Run: `tools/check-runner.sh`
Expected: all `ok`, exit 0.

```bash
git add solution-register-runner.md tools/check-runner.sh
git commit -m "Runner 2.11: consume transcript claims and new CR states

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EdaDxtjK4PrT5ZSTMU4T3t"
```

---

### Task 4: WebVTT parser and test

**Files:**
- Create: `tools/vtt-to-passages.sh`
- Create: `tools/test-vtt-to-passages.sh`
- Create: `tools/fixtures/sample.vtt`, `tools/fixtures/not-vtt.txt`

**Interfaces:**
- Produces: `tools/vtt-to-passages.sh <file.vtt> [gap_seconds]` printing passages to stdout in the block format below, ending with one line `<!-- cues: N passages: M last: HH:MM:SS.mmm -->`. Exit 2 if the file does not start with WEBVTT. Task 6 (stage T1) calls it.

Passage block format:

```
## Passage 3
- Time: 00:00:30.000
- Speaker: Tom Reilly
- Topic: 

We used to fax the confirmation to the depot but that stopped when the depot closed.

```

- [ ] **Step 1: Write the fixtures**

`tools/fixtures/sample.vtt`:

```
WEBVTT

1
00:00:01.000 --> 00:00:03.500
<v Priya Nair (Consultant)>Can you walk me through how a new customer order comes in today?</v>

2
00:00:04.000 --> 00:00:08.000
<v Tom Reilly>Sure. The order arrives by email from the sales team.</v>

3
00:00:08.500 --> 00:00:12.000
<v Tom Reilly>I key it into the ledger and then copy the reference into the tracking spreadsheet.</v>

4
00:00:13.000 --> 00:00:17.000
<v Tom Reilly>We still print a copy for the folder but nobody looks at it, it is just habit.</v>

5
00:00:30.000 --> 00:00:34.000
<v Tom Reilly>We used to fax the confirmation to the depot but that stopped when the depot closed.</v>

6
00:00:35.000 --> 00:00:39.000
<v Priya Nair (Consultant)>And what would you need the new system to do?</v>

7
00:00:40.000 --> 00:00:45.000
<v Tom Reilly>It must pick the order up from email automatically, and we should keep the ledger entry because audit checks it.</v>

8
00:00:46.000 --> 00:00:50.000
Meeting Room 4: We need to check whether finance still wants the spreadsheet.

9
00:00:51.000 --> 00:00:54.000
That is something someone needs to find out.
```

`tools/fixtures/not-vtt.txt`:

```
This is not a transcript.
```

Expected passages from this fixture: 1 Priya (cue 1); 2 Tom (cues 2, 3, 4 merged, gaps under five seconds); 3 Tom (cue 5, thirteen-second gap); 4 Priya (cue 6); 5 Tom (cue 7); 6 Meeting Room 4 (cue 8, colon form); 7 Unattributed (cue 9). Nine cues, seven passages, last cue start `00:00:51.000`.

- [ ] **Step 2: Write the test**

`tools/test-vtt-to-passages.sh`:

```bash
#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."
fx=tools/fixtures/sample.vtt
out=$(tools/vtt-to-passages.sh "$fx")
summary=$(printf '%s\n' "$out" | tail -1)
cues=$(grep -c -- '-->' "$fx")
lastcue=$(grep -- '-->' "$fx" | tail -1 | cut -d' ' -f1)
pass=0; fail=0
check() { if eval "$2"; then echo "ok   $1"; pass=$((pass+1)); else echo "FAIL $1"; fail=$((fail+1)); fi; }
check "cue count in summary matches file" '[ "$(printf "%s" "$summary" | sed "s/.*cues: \([0-9]*\).*/\1/")" = "$cues" ]'
check "seven passages" '[ "$(printf "%s\n" "$out" | grep -c "^## Passage ")" = 7 ]'
check "last timestamp equals last cue start" '[ "$(printf "%s" "$summary" | sed "s/.*last: \([^ ]*\).*/\1/")" = "$lastcue" ]'
check "same-speaker cues merge" 'printf "%s\n" "$out" | grep -q "sales team. I key it into the ledger"'
check "gap over five seconds splits" 'printf "%s\n" "$out" | grep -A4 "^## Passage 3$" | grep -q "^- Time: 00:00:30.000$"'
check "colon speaker form parsed" 'printf "%s\n" "$out" | grep -q "^- Speaker: Meeting Room 4$"'
check "no speaker gives Unattributed" 'printf "%s\n" "$out" | grep -q "^- Speaker: Unattributed$"'
check "v tags stripped" '! printf "%s\n" "$out" | grep -q "<v "'
check "rejects non-vtt with exit 2" 'tools/vtt-to-passages.sh tools/fixtures/not-vtt.txt >/dev/null 2>&1; [ $? = 2 ]'
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
```

- [ ] **Step 3: Run the test to see it fail**

Run: `chmod +x tools/test-vtt-to-passages.sh && tools/test-vtt-to-passages.sh`
Expected: fails because `tools/vtt-to-passages.sh` does not exist.

- [ ] **Step 4: Write the parser**

`tools/vtt-to-passages.sh`:

```bash
#!/usr/bin/env bash
# Parse a WebVTT transcript into numbered passages.
# Usage: tools/vtt-to-passages.sh <file.vtt> [gap_seconds]
# Consecutive cues from the same speaker with a gap of gap_seconds or less merge into one passage.
# Speaker is read from <v Name> tags or a leading "Name: " and is Unattributed otherwise.
# Output ends with: <!-- cues: N passages: M last: <start of last cue> -->
set -eu
f="${1:?usage: vtt-to-passages.sh <file.vtt> [gap_seconds]}"
gap="${2:-5}"
if ! head -c 6 "$f" | grep -q '^WEBVTT'; then
  echo "error: $f does not start with WEBVTT" >&2
  exit 2
fi
tr -d '\r' < "$f" | awk -v gap="$gap" '
function tosec(t,   a, n) {
  gsub(/,/, ".", t)
  n = split(t, a, ":")
  if (n == 3) return a[1] * 3600 + a[2] * 60 + a[3]
  if (n == 2) return a[1] * 60 + a[2]
  return 0
}
function flush() {
  if (text != "") {
    np++
    printf "## Passage %d\n- Time: %s\n- Speaker: %s\n- Topic: \n\n%s\n\n", np, pstart, pspk, text
  }
  text = ""
}
BEGIN { np = 0; ncue = 0; inbody = 0; skipnote = 0; text = ""; pspk = ""; pend = -1000; rawstart = "" }
/^WEBVTT/ { next }
/^NOTE/ { skipnote = 1; next }
/^[[:space:]]*$/ { skipnote = 0; inbody = 0; next }
skipnote { next }
/-->/ {
  ncue++
  split($0, p, " --> ")
  cs = tosec(p[1])
  split(p[2], q, " ")
  ce = tosec(q[1])
  rawstart = p[1]
  inbody = 1
  cuespk = ""
  next
}
!inbody { next }
{
  line = $0
  spk = ""
  if (match(line, /^<v[^>]*>/)) {
    spk = substr(line, 4, RLENGTH - 4)
    sub(/^<v[^>]*>/, "", line)
    sub(/<\/v>[[:space:]]*$/, "", line)
  } else if (match(line, /^[A-Za-z][A-Za-z0-9 ().-]*: /)) {
    spk = substr(line, 1, RLENGTH - 2)
    line = substr(line, RLENGTH + 1)
  }
  if (spk == "") spk = (cuespk != "" ? cuespk : "Unattributed")
  cuespk = spk
  if (spk == pspk && cs - pend <= gap) {
    text = text " " line
  } else {
    flush()
    pspk = spk
    pstart = rawstart
    text = line
  }
  pend = ce
}
END {
  flush()
  printf "<!-- cues: %d passages: %d last: %s -->\n", ncue, np, rawstart
}
'
```

- [ ] **Step 5: Run the test to see it pass**

Run: `chmod +x tools/vtt-to-passages.sh && tools/test-vtt-to-passages.sh`
Expected: `9 passed, 0 failed`, exit 0. If "gap over five seconds splits" fails, check that the awk `pend` update happens after the merge decision (it must be the last statement in the body block).

- [ ] **Step 6: Commit**

```bash
git add tools/vtt-to-passages.sh tools/test-vtt-to-passages.sh tools/fixtures
git commit -m "Add WebVTT to passages parser with test

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EdaDxtjK4PrT5ZSTMU4T3t"
```

---

### Task 5: Transcript runner, sections 1 to 4

**Files:**
- Create: `transcript-runner.md` (sections 1 to 4 in this task; sections 5 to 8 and the appendix in Tasks 6 and 7)
- Create: `tools/check-transcript-runner.sh`

**Interfaces:**
- Produces: the section numbering that Tasks 6 and 7 append to: 1 Inputs and outputs, 2 Operating rules, 3 Checkpoint protocol, 4 Local work folder, 5 Phases (Task 6), 6 Claim record (Task 6), 7 Session summary (Task 6), 8 Classification guide for passages (Task 7), Appendix (Task 7).

- [ ] **Step 1: Write the check script for this task's sections**

`tools/check-transcript-runner.sh`:

```bash
#!/usr/bin/env bash
set -u
f="$(dirname "$0")/../transcript-runner.md"
fail=0
need() { grep -qF -- "$1" "$f" && echo "ok   $1" || { echo "FAIL $1"; fail=1; }; }
need "# Transcript runner"
need "## 1. Inputs and outputs"
need "## 2. Operating rules"
need "## 3. Checkpoint protocol"
need "## 4. Local work folder"
need "tools/vtt-to-passages.sh"
need "Approve stage T"
need "work/transcripts/state.md"
exit $fail
```

- [ ] **Step 2: Run it to see it fail**

Run: `chmod +x tools/check-transcript-runner.sh && tools/check-transcript-runner.sh`
Expected: FAIL (file missing), exit 1.

- [ ] **Step 3: Write sections 1 to 4**

Create `transcript-runner.md` with exactly this content:

````markdown
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
````

- [ ] **Step 4: Run the check and commit**

Run: `tools/check-transcript-runner.sh`
Expected: all `ok`, exit 0.

```bash
git add transcript-runner.md tools/check-transcript-runner.sh
git commit -m "Transcript runner: inputs, rules, checkpoints, work folder

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EdaDxtjK4PrT5ZSTMU4T3t"
```

---

### Task 6: Transcript runner, stages, claim record and summary

**Files:**
- Modify: `transcript-runner.md` (append sections 5, 6, 7)
- Modify: `tools/check-transcript-runner.sh`

**Interfaces:**
- Consumes: parser output format from Task 4; section numbering from Task 5.
- Produces: the claim JSON shape below, which Task 3's runner steps 0, 0a and 0b read; section 8 heading reserved for Task 7.

Claim JSON shape (one object per claim, in a top-level array):

```json
{
  "id": "T003-C017",
  "statement": "The order arrives by email from the sales team.",
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
  "relations": ["step-of T003-C016; step 1"],
  "source_kind": "transcript"
}
```

- [ ] **Step 1: Extend the check script**

Append to `tools/check-transcript-runner.sh` before `exit $fail`:

```bash
need "## 5. Phases"
need "### T0. Register"
need "### T1. Passages and topics"
need "### T2. Classify"
need "### T3. Assemble claims"
need "### T4. Write claims"
need "## 6. Claim record"
need '"source_kind": "transcript"'
need "step-of"
need "retain no;"
need "## 7. Session summary"
```

- [ ] **Step 2: Run it to see the new lines fail**

Run: `tools/check-transcript-runner.sh`
Expected: the eleven new lines FAIL, exit 1.

- [ ] **Step 3: Append sections 5 to 7**

Append to `transcript-runner.md`:

````markdown

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
6. Ask the human to give each tag a role, consultant or SME, and a person's name where the tag is a room or the human knows who spoke. Record the mapping in `state.md` under checkpoint decisions.
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
6. Read every earlier `transcripts/claims/*.json`. Where a new process claim describes the same process as an earlier one (same trigger and the same or overlapping steps), add `same-as <earlier claim id>` and a question asking whether this is an update or a distinct process.
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
````

- [ ] **Step 4: Run the check and commit**

Run: `tools/check-transcript-runner.sh`
Expected: all `ok`, exit 0.

```bash
git add transcript-runner.md tools/check-transcript-runner.sh
git commit -m "Transcript runner: stages, claim record, session summary

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EdaDxtjK4PrT5ZSTMU4T3t"
```

---

### Task 7: Transcript runner, classification guide and worked examples

**Files:**
- Modify: `transcript-runner.md` (append section 8 and the appendix)
- Modify: `tools/check-transcript-runner.sh`

**Interfaces:**
- Consumes: class names and relation words from Task 6 section 6.
- Produces: section 8, which T2 in Task 6 cites.

- [ ] **Step 1: Extend the check script**

Append before `exit $fail`:

```bash
need "## 8. Classification guide for passages"
need "1. **Consultant speaker?**"
need "3. **Explicit past or cessation?**"
need "4. **Commitment modal"
need "5. **Present tense plus stated redundancy?**"
need "## Appendix. Worked examples"
need "| Legacy beats current |"
need "| Split passage |"
```

- [ ] **Step 2: Run it to see the new lines fail**

Run: `tools/check-transcript-runner.sh`
Expected: the eight new lines FAIL, exit 1.

- [ ] **Step 3: Append section 8 and the appendix**

Append to `transcript-runner.md`:

````markdown

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
````

- [ ] **Step 4: Run the check and commit**

Run: `tools/check-transcript-runner.sh`
Expected: all `ok`, exit 0.

```bash
git add transcript-runner.md tools/check-transcript-runner.sh
git commit -m "Transcript runner: classification guide and worked examples

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EdaDxtjK4PrT5ZSTMU4T3t"
```

---

### Task 8: Folder scaffolding, README and end-to-end dry run

**Files:**
- Create: `transcripts/input/.gitkeep`, `transcripts/processed/.gitkeep`, `transcripts/claims/.gitkeep`
- Modify: `README.md` (lines 3, 5-13, 15) and `.gitignore`
- Create: `tools/check-all.sh`

**Interfaces:**
- Consumes: every check script from Tasks 1 to 7 and the parser test from Task 4.

- [ ] **Step 1: Write the aggregate check**

`tools/check-all.sh`:

```bash
#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."
fail=0
for s in tools/check-model-prc.sh tools/check-model-cr.sh tools/check-runner.sh tools/check-transcript-runner.sh tools/test-vtt-to-passages.sh; do
  echo "== $s"; "$s" || fail=1
done
echo "== README"
grep -qF '`transcript-runner.md`' README.md && echo "ok   README row" || { echo "FAIL README row"; fail=1; }
grep -qF '`transcripts/`' README.md && echo "ok   transcripts row" || { echo "FAIL transcripts row"; fail=1; }
echo "== gitignore"
grep -qx 'transcripts/input/' .gitignore && echo "ok   input ignored" || { echo "FAIL input ignored"; fail=1; }
echo "== folders"
for d in transcripts/input transcripts/processed transcripts/claims; do [ -f "$d/.gitkeep" ] && echo "ok   $d" || { echo "FAIL $d"; fail=1; }; done
echo "== em dash scan"
if grep -l -- '—' solution-register-model.md solution-register-runner.md transcript-runner.md README.md 2>/dev/null; then echo "FAIL em dash found"; fail=1; else echo "ok   no em dashes"; fi
exit $fail
```

- [ ] **Step 2: Run it to see the README and folder lines fail**

Run: `chmod +x tools/check-all.sh && tools/check-all.sh`
Expected: earlier checks ok; README rows, folders FAIL. Exit 1.

- [ ] **Step 3: Create folders and ignore rule**

```bash
mkdir -p transcripts/input transcripts/processed transcripts/claims
touch transcripts/input/.gitkeep transcripts/processed/.gitkeep transcripts/claims/.gitkeep
```

Replace the `transcripts/input/` line in `.gitignore` with these two lines so the `.gitkeep` survives:

```
transcripts/input/*
!transcripts/input/.gitkeep
```

Then change the `check-all.sh` gitignore assertion to `grep -qx 'transcripts/input/\*' .gitignore`.

- [ ] **Step 4: Update the README**

Line 3 becomes:

```
Registers for tracking the artifacts of solution architecture on a vendor-delivered project: requirements, decisions, limitations, risks, open items, change requests and current business processes, from our perspective as design authority.
```

After the `solution-register-runner.md` row add:

```
| `transcript-runner.md` | Instructions for Claude Opus 5 to turn a WebVTT discovery-session transcript into atomic claims for the register runner: passages, topics, a classification guide that keeps legacy practice out of the registers, and staged checkpoints. Run before the register runner. |
| `tools/` | The WebVTT parser, its test, fixtures, and grep checks that the model, runner and transcript runner documents still say what the checks expect. Run `tools/check-all.sh`. |
| `transcripts/` | `input/` for new transcripts (not committed), `processed/` for ingested ones, `claims/` for the JSON claims each session produced. |
```

Change the `work/` row to: "Created by the runners. Intermediate results, questions, answers, session summaries and the migration log. Not committed."

After "Changes to the model go in the model file. Changes to how the runner works go in the runner file." add: "Changes to how transcripts become claims go in the transcript runner file."

- [ ] **Step 5: Run all checks**

Run: `tools/check-all.sh`
Expected: every line ok, exit 0.

- [ ] **Step 6: Dry run the transcript runner on the fixture**

Copy the fixture and walk T0 and T1 by hand to confirm the instructions are followable:

```bash
cp tools/fixtures/sample.vtt transcripts/input/discovery-orders-2026-09-09.vtt
mkdir -p work/transcripts/T001
tools/vtt-to-passages.sh transcripts/input/discovery-orders-2026-09-09.vtt > work/transcripts/T001/00-passages.md
tail -1 work/transcripts/T001/00-passages.md
grep -c -- '-->' transcripts/input/discovery-orders-2026-09-09.vtt
```

Expected: the summary line reads `cues: 9 passages: 7 last: 00:00:51.000` and the grep prints `9`. Then compare the seven passages against the appendix table in `transcript-runner.md`: each SME passage should map to a row. If any passage has no matching row or the row's class does not follow from section 8, fix the guide or the appendix and re-run `tools/check-all.sh`.

Clean up:

```bash
rm -rf work/transcripts transcripts/input/discovery-orders-2026-09-09.vtt
```

- [ ] **Step 7: Commit**

```bash
git add README.md .gitignore transcripts tools/check-all.sh
git commit -m "Add transcripts folders, README rows and aggregate checks

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EdaDxtjK4PrT5ZSTMU4T3t"
```

---

## Self-review against the spec

- Spec 3.1 to 3.5 (PRC): Task 1. Spec 3.6 (CR lifecycle, links, layout, view, I2, I10, I18): Task 2.
- Spec 4.1 claim record and 4.2 storage: Task 6 sections 5 (T4) and 6.
- Spec 5 passages, roles, topics: Task 4 parser, Task 6 T0 and T1.
- Spec 6 classification guide: Task 7 section 8.
- Spec 7 phases, folder, state, checkpoints, summary: Tasks 5 and 6.
- Spec 8 register runner amendments items 1 to 7: Task 3.
- Spec 9 error handling: parser exit 2 (Task 4), rules 8 to 13 and T0 step 3, T1 step 2 and 5, T4 step 1 (Tasks 5 and 6).
- Spec 10 testing: parser test (Task 4), appendix (Task 7), fixture walkthrough (Task 8 step 6). The end-to-end register runner Phase 2 run needs a Confluence session and is left to the first real use.
- Spec 12 open assumption: state.md `knowledge_base_form` and T4 step 4 (Tasks 5 and 6).
- README rows: Task 8.

Names used consistently: `tools/vtt-to-passages.sh`, `work/transcripts/state.md`, `transcripts/claims/T<nnn>.json`, class names and relation words match between Task 3 (runner steps 0 to 0b), Task 6 (section 6) and Task 7 (section 8 and appendix).
