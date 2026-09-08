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
