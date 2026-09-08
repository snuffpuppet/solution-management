# Enhancements

Work agreed for a later session. An entry is an idea with its rationale and the evidence that would justify doing it, not a commitment. When one is done, move its line to `LOG.md` with the commit. When one is dropped, delete it and say why in `LOG.md`.

Format: id, title, why, trigger to start, size.

| Id | Title | Why | Start when | Size |
|---|---|---|---|---|
| E1 | Two-model T2 comparison as a per-session option | Running T2 under two models and turning disagreements into questions raises quality on high-stakes sessions. Permitted by decision D7. | Fable access arrives, and a session is judged high stakes. | Small: a section 9 procedure already sketches it; needs a skill argument and an Audit convention. |
| E2 | Read-only self-check pass under a stronger model | A weaker model classifies, a stronger one re-reads and changes only confidence. Permitted by D7 as the one safe delegation. | The Audit table shows Opus 5 strict has a change rate the owner finds too high. | Medium: a new T2b stage, a dispatch with model parameter, Audit row. |
| E3 | Grow the appendix from real sessions | Every question whose answer overturned a class is a candidate worked example. Opus benefits most. | After the first three real sessions. | Small per row; recurring. |
| E4 | Named phases on requirements | Model 4.2 allows only this phase or next phase on REQ, while a deferred CR names a later phase (I18 says "a later phase"). Model also requires Phase on Workaround accepted where none exists. | Owner decides whether phases are named on REQ. | Small: model 4.2, 4.4, I2, I18. |
| E5 | End-to-end test of register runner Phase 2 on transcript claims | Spec section 10 asks for it; it needs a Confluence session so it was left to first real use. | First real run of the register runner after a transcript session. | Small: run and record in LOG.md. |
| E6 | Pin the knowledge base form | The runner discovers graph versus claims folder at T0. Once the real knowledge base tool is known, pin the T4 merge to its schema. | The knowledge base tool is chosen. | Medium: T4 step 4 and a fixture. |
| E7 | Comma timestamps in parser output | SRT-derived VTT uses `HH:MM:SS,mmm`. The parser normalises commas for arithmetic but prints them as found. | A transcript with comma timestamps appears. | Small: one substitution in awk and a test. |
| E8 | Speaker tag heuristics for other exporters | Zoom and Google Meet exports use other speaker conventions. | A transcript from another tool appears. | Small to medium: parser branch, fixture, test. |
| E9 | Push main to GitHub | Main is local only. | Owner says push. | Trivial. |
| E10 | Learning loop that reduces questions over time | Candidate principle: reduce the human in the loop over time, meaning fewer questions per stage, never fewer checkpoints (P3). A post-T4 pass reads each question and answer and writes what rule, evidence in the transcript, or human judgement would have settled it; the findings go in the session summary and feed a self-improvement stage that proposes runner document edits for human approval (P1, P2, P10), measured by the Audit change rate (P6). Automates E3. | Owner approves the principle after an ARCHITECTURE section 5 check, and at least three real sessions have Audit rows. | Medium: a summary section, a findings file, a proposal procedure, a check. |
