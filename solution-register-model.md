# Solution register model

Version 2.11, 9 September 2026. Owner: Adam Moyes.

This file describes how we track the artifacts of solution architecture on a project where we are the design authority and a vendor builds the platform. It is tool-agnostic. It says what the item types are, how they relate, how each one moves, and what a healthy register looks like. It does not say how to build the registers in any particular tool; that is in `solution-register-runner.md`.

Diagrams in `diagrams/` show the same model: `day-in-the-life` (six things that happen on the project and how each runs through the registers), `management-flow` (one requirement followed through the registers) and `artifact-workflow` (the open item queue and the limitation disposition). The day-in-the-life diagram is generated from `diagrams/src/day_in_the_life_gen.py`.

---

## 1. Purpose and context

We specify a solution. The solution is ours and is wider than the vendor's platform: some of it is designed and built internally. The vendor architects, designs and builds their platform in collaboration with us and is consulted on our decisions; our own stakeholder groups and SMEs are consulted too. Approval always sits with us.

Our architects produce solution design documents and need to track, from our perspective:

- requirements
- decisions
- limitations
- risks
- open items
- change requests

The vendor keeps their own registers with their own ids, costs and timelines. We do not mirror those. We hold our view and reference theirs.

The goal is a set of registers that a person can open during a meeting and see what is outstanding, and that can be maintained by hand with a few minutes of effort per item.

## 2. Principles

**Open items are the working queue. Everything else is a record.**
An open item closes only by creating or changing a record: a decision gets accepted, a limitation gets dispositioned, a change request gets raised, a requirement gets clarified, a risk gets retired. In a meeting we review one filtered list of open items. The registers behind them stay stable.

**A limitation must be dispositioned, and each disposition links to a record.**
A limitation leaves "Under assessment" by exactly one path, and each path names the record that carries the outcome.

**Registers and narrative are separate.**
Registers hold items. Solution design documents hold narrative and reference items by id. A design document never holds the master copy of an item. This is what lets design documents be split per service, per customer service, or combined, without changing how tracking works.

**Every item traces to a source.**
Not every item begins with a requirement. Each item records where it came from, and that is enough.

## 3. Entry points

Five kinds of thing come in, and the question beside each one picks the type.

| Entry | Question | Usually becomes |
|---|---|---|
| Requirement | We need the solution to do X. | REQ |
| Discovery | The platform does, or does not, do X. | LIM if a need is now unmet; DEC if we must now design a certain way; OI first if uncertain |
| Ask | A stakeholder wants X changed. | OI, then CR or REQ |
| Event | A risk lands, an assumption fails, a review finds a gap. | OI, then whatever record the work produces |
| Current practice | This is how we do X today. | PRC |

Asks and events are work first and record later. Requirements, discoveries and current practice can go straight to a record.

## 4. Item types

### 4.1 Header fields (every item)

| Field | Rule |
|---|---|
| ID | Type prefix plus zero-padded number, e.g. REQ-014, DEC-003, LIM-021, RSK-007, OI-045, CR-002. Never reused. |
| Title | One line, specific. |
| Status | One of the values for the type (4.2). |
| Owner | A named person on our side, or "Vendor" plus a named vendor contact, or "Joint". Required on every requirement and open item that is not in a terminal state. Not used on decisions, limitations, risks, change requests or processes, which carry Raised by instead. While a decision is Proposed, a limitation is Under assessment or a change request is not yet Approved, the open item driving it carries the owner. Risks have no standing owner; they are reviewed on their review date by the routine in section 10, and a realised risk raises an open item. |
| Scope | One value from the scope taxonomy (6). |
| Implemented by | Vendor, Internal or Both. Whose build the item lands in. Required on requirements, decisions, limitations and change requests. Optional on risks and open items. Not used on processes. |
| Vendor ref | The vendor's id for the corresponding item, if one exists. Otherwise blank. Not used on decisions; a vendor document reference goes in Source. Not used on processes. |
| Links | Ids of related items, with the relationship word (5). |
| Next action | Required on open items that are not Closed. Not used on any other type; the open item driving a record carries it. |
| Due | Date for the next action, on open items. On a risk, Due is the date the risk is next reviewed, and is required while the risk is not in a terminal state. Not used on other types. |
| Source | Where the item came from: a design document and section, a knowledge base claim id, a meeting date, a vendor document reference. Not used on open items, where Raised on and Raised by carry it. |
| Updated | Date of last change. |

### 4.2 Types, states and type-specific fields

Terminal states are marked *.

| Type | Prefix | States | Type-specific fields |
|---|---|---|---|
| Requirement | REQ | Draft, Agreed, Designed, Delivered, Verified*, Deferred*, Withdrawn* | MoSCoW (Must / Should / Could / Won't), Phase (this phase / next phase), Raised on (date the need was stated) |
| Decision | DEC | Proposed, Accepted, Superseded*, Rejected* | Rationale (short, naming the rejected option where there was one), Raised by (who proposed it), Consulted (vendor, SMEs, stakeholder groups who had input), Approved by (the person or forum on our side who made it stick), Decided on (date of acceptance or rejection) |
| Limitation | LIM | Identified, Under assessment, Accepted*, Change requested*, Deferred*, Resolved* | Identified on (date), Impact (one line: what it means for the customer or the operation), Disposition record (id of the DEC, CR or REQ that carries the outcome) |
| Risk | RSK | Identified, Mitigating, Realised*, Retired* | Identified on (date), Raised by (person, or the review it came from), Likelihood (L/M/H), Impact (L/M/H), Trigger (the observable event that says the risk has become real), Mitigation (what is being done, as text) |
| Open item | OI | Open, In progress, Blocked, Closed* | Raised on (date), Raised by (person, or the meeting or review it came from), Blocked by (an id or a short reason, while Blocked), Resolution (id of the record it produced or changed), Closed on (date) |
| Change request | CR | Proposed, Options, For approval, Approved, Submitted, Delivered*, Deferred*, Workaround accepted*, Rejected* | Phase (the named phase the chosen option lands in, set when an option is chosen), Raised on (date), Raised by (person, or the meeting or review it came from), Reason (one line: what the change buys), Options (numbered list, each `n. <option>; impact: <cost and time, or effort and who>; phase: <phase>`; defer to a later phase and accept a workaround are always valid options), Chosen option (the option number), Consulted (vendor, SMEs, stakeholder groups who had input), Approved by, Approved on, Disposition record (REQ id on Deferred, DEC id on Workaround accepted), CR page (optional link to the page holding the full option designs) |
| Process | PRC | Draft, Confirmed, Superseded*, Retired* | Trigger (what starts the process, one line), Steps (numbered list; each step is `n. <step> [Retain: Yes/No/Unknown] [Actor: <role or person>]`, and a Retain of No carries the SME's reason after a semicolon inside the brackets), Systems (touched today, comma separated), Frequency (as stated by the SME, blank if not stated), Described on (date of the session), Raised by (the SMEs who described it, from transcript attribution; "Unattributed" if none) |

### 4.3 Use it when

| Type | Use when |
|---|---|
| Requirement | We need the solution to do something. Owned by whoever stated the need, usually the SME or stakeholder who raised it, because they can say whether it has been met. |
| Decision | We chose how, or accepted a constraint. See 4.5. |
| Limitation | The solution will not do, or does differently, something we need. A fact about the solution, not a piece of work. Title says what the solution does; Impact says why we care. |
| Risk | Something might go wrong, or an assumption is unverified and would hurt if wrong. A record, not a piece of work: it carries who raised it and a review date, and the weekly routine reviews it. Mitigation actions are open items with their own owners. Anyone who sees the trigger happen raises an open item and the risk moves to Realised. |
| Open item | Someone must do something before a record can change. The only thing you work. |
| Change request | Agreed scope or design must change and it costs time, money or effort. One row for the whole life of the change, ours from Proposed, with the vendor's number in Vendor ref once they assign one. Links says what triggered it; Reason says what it buys, for the reader in the approval meeting. |
| Process | An SME describes work performed today. One row per named end-to-end process, with steps inside the row, so the register stays readable in a meeting. A step is addressed as PRC-nnn/step n. Legacy steps no longer performed are never recorded here; current steps the SME says are not needed are recorded with Retain: No and the reason, and raise no requirement on their own. |

### 4.4 Transition rules

- Requirement: the Owner is the person who stated the need, and Raised on is when they stated it. MoSCoW is required from Draft onwards. Won't means agreed as out of this project and is recorded rather than deleted; a need wanted later is Must, Should or Could with Phase = next phase. A requirement row carries no next action: work to get it agreed, designed or verified is an open item in Links, and a requirement in Draft must have one. Designed means a section of a design document, ours or the vendor's, covers it, and Source or Links points at that section. A decision link is needed only where a real choice was made. Most requirements never have a decision.
- Decision: while Proposed, an open item in Links carries the owner, next action and due date; the decision row itself has none. Accepted or Rejected needs Approved by, Decided on and at least one Consulted entry, and Approved by is ours. Accepted is immutable. To change an accepted decision, create a new one, mark the old one Superseded, and write "superseded by DEC-nnn" in the old one's Links.
- Limitation: Identified on is set when the row is created. Under assessment needs an open item in Links carrying the owner and next action, and Impact must be filled before the limitation leaves assessment. From Under assessment, exactly one of Accepted (needs a DEC id), Change requested (needs a CR id), Deferred (needs a REQ id with Phase = next phase), Resolved (needs evidence in Source or Links). The disposition is written once, in Disposition record; Links holds the other relationships (constrains, introduced by, the assessing open item).
- Risk: Identified on and Raised by are set when the row is created. Mitigating needs Trigger and Mitigation filled and a Due date for the next review; the review happens in the weekly routine, and whoever runs it updates Likelihood, Impact, Mitigation and the next Due. Realised is set when the Trigger is observed, and must create an OI. Retired needs a one-line reason in Mitigation. Mitigation is text on the row; there is no "mitigated by" link. Where the mitigation is a decision, Links carries "raised by DEC-nnn" or the DEC carries "raises", and that is enough.
- Open item: Blocked needs Blocked by, either the id of the item it is waiting on or a short reason, and it is cleared when the item leaves Blocked. Closed needs a Resolution id and Closed on. If nothing was produced, the Resolution says "No record: <reason>" and that is acceptable but should be rare.
- Change request: Raised on and Raised by are set when the row is created. Proposed means ours and being reasoned; Reason must be filled before it leaves Proposed. Options means we are designing the alternatives; at least two Options, each with an impact and a target phase, must be filled before it leaves Options, and a vendor estimate is an input here rather than a state of its own. For approval means the options are with our stakeholders; Consulted must be filled before it leaves. Approved means an option for delivery in this phase was chosen, and needs Chosen option, Approved by, Approved on and Phase. Submitted means handed to whoever will implement it; with Implemented by = Vendor, Submitted needs a Vendor ref. Delivered is set when the change is built and the requirement it delivers moves. Deferred means the chosen option is delivery in a later phase: create a requirement with Phase = that phase and MoSCoW set, write its id in Disposition record and "deferred as REQ-nnn" in Links, and close the change request; a change needed when that phase starts raises a new one. Workaround accepted means the change is not made and a decision records the manual process or workaround: write the DEC id in Disposition record and "dispositioned by DEC-nnn" in Links; where the workaround is a manual process, it is also a PRC row. Rejected means no change and no workaround, and the underlying need is Won't or Withdrawn. Approved, Deferred, Workaround accepted and Rejected each need Approved by and Approved on. A change request in Proposed, Options, For approval or Submitted must have an open item in Links carrying the owner, next action and due date; the row itself has none. The design produced for every option, including a workaround, lives on the CR page or in the design document, never on the row. A change with Implemented by = Both stays one row unless the vendor part and the internal part are approved separately, in which case it is two rows linked "part of".
- Process: Draft on extraction. Described on and Raised by are set when the row is created. Owner, Implemented by and Vendor ref are not used; a process in Draft must have an open item in Links whose Owner is set, as for a Proposed decision. Confirmed when an SME or the owner of the driving open item agrees the description, and that open item closes with Resolution = the PRC id. Superseded when a later session gives a fuller description: create a new PRC and write "superseded by PRC-nnn" in the old one's Links. Retired when the process turns out not to be performed at all, with a one-line reason in Source or Links. Scope is tagged at Domain or Customer service level.

### 4.5 When to write a decision

A requirement says what the solution must do. A decision records a choice or an accepted trade-off. Write a decision only when at least one of these is true:

- There was a real choice between viable options, and you picked one.
- It constrains later design, such as a principle or standard other decisions must follow.
- It accepts something: a limitation you live with, a risk you carry knowingly, a vendor constraint you design around.
- Someone will later ask "why did we do it this way?" and the answer is more than "the requirement said so".

Do not write a decision to restate a requirement, to put a requirement in or out of a phase (that is the requirement's Phase and Agreed status), or for the vendor's routine implementation detail (that lives in their design document; add a Vendor ref on our requirement if it matters).

**Discovery: decision or limitation?** Ask one question: after this, is something we need now not going to happen? If yes, it is a limitation, and a decision appears only if the limitation is later accepted. If no, but we must now design a certain way, it is a decision that accepts a constraint. If the discovery is not yet certain, raise an open item to confirm it with the vendor first.

Examples:

- The platform requires an access service to exist before a delivery service is provisioned. Nothing is lost, the ordering is now fixed. Decision: "Provision access before delivery, because the platform enforces it." Consulted: vendor. Implemented by: Both.
- The platform can represent a customer service as a bundle object or as two linked services. Both work. We choose linked services because the bundle hides the access service from support tooling. Decision, recording the rejected option.
- The platform holds one notification channel per customer and a Must requirement needs email and SMS on day one. Limitation constraining that requirement, assessed through an open item. A decision appears only if we accept the shortfall.

## 5. Relationships

Links are written as `<relationship> <ID>`, several per item separated by semicolons. A link only needs to be written on one side; a dashboard derives the reverse.

| From | Relationship | To |
|---|---|---|
| DEC | addresses | REQ (only when a real choice was made) |
| DEC | introduces | LIM |
| DEC | raises | RSK |
| DEC | supersedes | DEC (the old decision also carries "superseded by") |
| LIM | constrains | REQ |
| LIM | dispositioned by | DEC, CR or REQ |
| RSK | realised as | OI |
| OI | resolves into | any |
| CR | triggered by | LIM or REQ |
| CR | delivers | REQ |
| CR | part of | CR (when a Both change is split into a vendor row and an internal row) |
| CR | deferred as | REQ (the requirement also carries "triggered by CR-nnn") |
| CR | dispositioned by | DEC (on Workaround accepted) |
| REQ | replaces | PRC-nnn/step n |
| REQ | preserves | PRC-nnn/step n |
| LIM | constrains | PRC |
| OI | clarifies | PRC |
| PRC | superseded by | PRC |

## 6. Scope taxonomy

Scope is a tree. Each item is tagged once, at the lowest level that applies. There is no programme level: the registers live inside the programme's area, so the programme is implied.

```
Domain (e.g. Services delivered this phase, Billing, Identity)
  Technical service (e.g. Delivery service X, Access service Y)
  Customer service (a named composition of technical services, e.g. Customer service Z = Delivery X + Access Y)
```

A customer service view is the union of items tagged to its component technical services plus items tagged at the customer-service level. Integration issues between two technical services are tagged at the customer-service level.

The taxonomy is kept on its own page and is the single source of allowed Scope values.

## 7. Register layout

One register per type. Every register has the header fields in 4.1 that apply to its type as columns, in this order, with the type-specific fields inserted after Status. Only requirements and open items carry an Owner. Requirements, because it names who can say the need is met; open items, because they are the work. Every other type carries Raised by instead, and the work that moves it lives on an open item. Processes carry neither Owner nor Implemented by nor Vendor ref. Risks carry Due as a review date but no Next action. Decisions carry no Vendor ref. Open items carry no Source; Raised on and Raised by do that job.

| Register | Columns |
|---|---|
| Requirements | ID, Title, Status, MoSCoW, Phase, Raised on, Owner, Scope, Implemented by, Vendor ref, Links, Source, Updated |
| Decisions | ID, Title, Status, Rationale, Raised by, Consulted, Approved by, Decided on, Scope, Implemented by, Links, Source, Updated |
| Limitations | ID, Title, Status, Identified on, Impact, Disposition record, Scope, Implemented by, Vendor ref, Links, Source, Updated |
| Risks | ID, Title, Status, Identified on, Raised by, Likelihood, Impact, Trigger, Mitigation, Scope, Vendor ref, Links, Due, Source, Updated |
| Open items | ID, Title, Status, Owner, Scope, Raised on, Raised by, Blocked by, Vendor ref, Links, Resolution, Next action, Due, Closed on, Updated |
| Change requests | ID, Title, Status, Phase, Reason, Options, Chosen option, Consulted, Approved by, Approved on, Disposition record, CR page, Implemented by, Raised on, Raised by, Scope, Vendor ref, Links, Source, Updated |
| Processes | ID, Title, Status, Trigger, Steps, Systems, Frequency, Described on, Raised by, Scope, Links, Source, Updated |

Two supporting pages sit beside the registers: the scope taxonomy (6) and a conventions page that condenses sections 2 to 5 and 8 for people adding items by hand.

Column values are plain text. Ids in Links are plain text ids so that the table stays editable by hand. Status values are exactly the strings in 4.2.

## 8. What "outstanding" means

The meeting view is:

1. Open items not Closed, sorted by Due, grouped by Owner, with Blocked by shown for any that are Blocked.
2. Limitations in Identified or Under assessment, oldest Identified on first.
3. Risks in Identified or Mitigating with Impact H, and any risk whose review date has passed.
4. Change requests in Proposed, Options or For approval.
5. Decisions in Proposed older than 14 days.
6. Requirements in Draft older than 14 days, measured from Raised on.
7. Processes in Draft older than 14 days, measured from Described on.

Items with Phase = next phase, and change requests in Deferred, are excluded from this view. They appear on a separate next-phase view instead:

1. Limitations in Deferred, with their disposition requirement.
2. Requirements with Phase = next phase.
3. Change requests in Deferred, with their disposition requirement.

This is the chain from a limitation we are living with to its planned fix, and it is reviewed at phase planning rather than in the weekly meeting.

Anything on the outstanding view without an owner, a next action and a due date on it or on its open item is a defect in the register, not a discussion point.

## 9. Integrity rules

Run against a proposed set of registers before writing them, and on request during maintenance. Each rule reports the ids that fail.

| Rule | Check |
|---|---|
| I1 Unique ids | No id appears twice across all registers. |
| I2 Valid status | Every status is an exact 4.2 value for its type. Every requirement has a MoSCoW value and a Raised on date. Every limitation has an Identified on date, and Impact once it is past Identified. Every risk has an Identified on date, and Trigger and Mitigation once it is Mitigating. Every change request has Raised on and Raised by; Reason once past Proposed; at least two Options once past Options; Consulted once past For approval; Chosen option and Phase once Approved or in a terminal state other than Rejected; and Vendor ref once Submitted with Implemented by = Vendor. |
| I3 Owner present | Every non-terminal requirement and open item has an Owner that is a person, "Vendor: <name>" or "Joint". Every decision, limitation, risk, change request and process has Raised by. Decisions, limitations and change requests are exempt from Owner, but a decision in Proposed, a requirement in Draft, a limitation in Under assessment and a change request in Proposed, Options, For approval or Submitted must each have an open item in Links whose Owner is set, and so must a PRC in Draft. |
| I4 Next action present | Every open item not Closed has Next action and Due. Every non-terminal risk has Due as its review date. |
| I5 Scope valid | Every Scope is a value in the taxonomy. |
| I6 Link targets exist | Every id in Links exists in some register. |
| I7 Limitation disposition | Every LIM in a terminal state other than Resolved has a Disposition record id of the right type (Accepted needs DEC, Change requested needs CR, Deferred needs REQ), and no LIM in Identified or Under assessment has one. |
| I8 Decision supersession | Every DEC in Superseded has a "superseded by" link pointing at a DEC in Accepted or Proposed. |
| I9 Open item resolution | Every OI in Closed has a Resolution and a Closed on date. Every OI in Blocked has Blocked by, and no OI in another state does. |
| I10 Change request approval | Every CR in Approved, Submitted, Delivered, Deferred, Workaround accepted or Rejected has Approved by and Approved on. |
| I11 Decision approval | Every DEC in Accepted or Rejected has Approved by, Decided on and at least one Consulted entry. Every DEC has Raised by. |
| I12 Implemented by | Every REQ, DEC, LIM and CR has Implemented by set to Vendor, Internal or Both. |
| I13 Realised risk | Every RSK in Realised has a "realised as OI-nnn" link. |
| I14 Source present | Every item other than an open item has a Source. Every open item has Raised on and Raised by. |
| I15 Stale proposals | DEC in Proposed, REQ in Draft and PRC in Draft older than 14 days are listed as warnings. |
| I16 Decision without requirement | A DEC with no "addresses REQ" link and no "accepts" wording in its Rationale is listed as a warning: it usually means an unstated requirement or an unrecorded constraint. |
| I17 Process steps | Every PRC step has a Retain value of Yes, No or Unknown, and every Retain of No has a reason after the semicolon. |
| I18 Change request disposition | Every CR in Deferred has a Disposition record naming a REQ whose Phase is a later phase, and every CR in Workaround accepted has a Disposition record naming a DEC in Accepted. No CR in another state has one. |

I1 to I14, I17 and I18 are failures. I15 and I16 are warnings.

## 10. Maintenance routine

Before each project meeting:
1. Regenerate the outstanding view (8) from the seven registers.
2. Run the integrity rules. Fix I3 and I4 failures before the meeting, since those are the ones that make the meeting unproductive.

During the meeting:
3. Walk the outstanding view top to bottom. Every open item gets a new Next action and Due, or gets Closed with a Resolution.
4. New items raised in the meeting get an id from the next free number, Source = meeting date, and an owner before the meeting ends.

Weekly:
5. Check Limitations in Under assessment for more than 14 days. Each one either gets dispositioned or the open item that is assessing it gets a new Due.
5a. Review every risk whose Due has passed. Update Likelihood, Impact and Mitigation, set the next Due, or Retire it with a reason. If the Trigger has been seen, move it to Realised and raise an open item.
6. Check vendor refs. Where the vendor has closed or changed an item we reference, update our item and add a note in Source.

When a design document changes:
7. Any new tracking table in a design document is a defect. Move its rows to the register and mark the table as superseded with a link to the register.

---

## Appendix. Source references

- MADR template primer: ozimmer.ch/practices/2022/11/22/MADRTemplatePrimer.html
- arc42 section 11, risks and technical debt: docs.arc42.org/section-11/
- Google Cloud architecture decision records overview: cloud.google.com/architecture/architecture-decision-records
- RAID log guide: smartsheet.com/content/raid-project-management
