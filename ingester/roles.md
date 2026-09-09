# Roles

Version 1.2, 9 September 2026. Owner: Adam Moyes.

Who can be in a discovery session and what their words may become. Both runners read this file: the transcript runner applies the "May yield" and "Never yields" columns at classification, and the register runner applies the "Register effect" column. `transcripts/stakeholders.md` assigns one of these roles to each person. To change what a role may do, edit this table, bump the version, and add or adjust a worked example in the transcript runner appendix.

Principle: only SMEs describe our processes or needs. Everyone else is a source of questions, constraints, positions or work, never of current practice or requirements. Approval always sits with us.

| Role | Who | May yield | Never yields | Register effect |
|---|---|---|---|---|
| `sme` | Our business subject matter expert. Authoritative on how work is done today and what we need. | current, current-not-needed, legacy, system, need, decision, limitation, risk, open-item, context | nothing excluded | Processes, requirements and their Owner or Raised by come from SMEs. |
| `consultant` | Interviews SMEs on our behalf. Frames questions, never describes our processes or needs. | context | current, current-not-needed, legacy, system, need, decision, limitation, risk, open-item | None. The SME answer that follows carries the content. |
| `vendor` | Vendor professional services: architects or designers of the platform. Authoritative on their platform and on what they build for us, never on our processes or needs. | decision, limitation, risk, open-item, context | current, current-not-needed, legacy, system, need | A decision is Proposed with Raised by = the speaker and Consulted includes "vendor: <name>". A limitation has Raised by = the speaker. Approved by is never filled from a vendor. |
| `architect` | Our solution architect. Holds a view on how the solution should look, not a source of current practice or needs. | decision, limitation, risk, open-item, context | current, current-not-needed, legacy, system, need | A decision is Proposed with Raised by = the speaker. Approved by is never filled from an architect. |
| `unknown` | Unattributed passages. | any class the words support | nothing excluded | Speaker Unattributed; questions rather than guesses where role would have decided the class. |

Adding a role: add a row here, then add it to the role list in `transcripts/stakeholders.md`, the valid-role pattern in `<HOW>/tools/check-stakeholders.sh`, and the transcript runner's section 6 role field. Run the architecture compliance check first.
