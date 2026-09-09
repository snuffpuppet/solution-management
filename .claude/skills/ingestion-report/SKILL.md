---
name: ingestion-report
description: Use when the user asks how well transcript ingestion is going, wants to compare the models that ran it, or types /ingestion-report
argument-hint: "[state.md path] [claims dir]"
---

# Ingestion report

Report on the effectiveness of transcript ingestion and the models that ran it. The numbers come from a script; your job is to run it and interpret the result.

## Steps

1. Run `<HOW>/tools/ingestion-report.sh $ARGUMENTS`. With no arguments it reads `work/transcripts/state.md` and `transcripts/claims/`. If it exits 2, say that no ingestion state exists yet and stop.
2. Read the output. It has four tables: sessions, audit rows per stage, totals by model, and claims by class per session.
3. Write the output to `work/transcripts/reports/report-<today>.md`, with today as an ISO date such as `2026-09-09`, and print the "By model" and "Claims by class" tables in the conversation.
4. Below the tables, give an interpretation in at most six sentences, covering:
   - which model raised more questions per hundred passages, and whether its change rate was lower (asked more, got more right) or higher (asked more and still missed);
   - whether strict mode sessions show a higher inferred share than standard ones;
   - any session where the Claims column in the audit rows differs from the claim count in the claims file, which means the T3 audit row or the claims file is stale;
   - any session whose class counts look unusual for its length, such as no legacy or no current-not-needed claims, which suggests the classification guide was not applied;
   - one concrete suggestion: an appendix row to add, a guide step to tighten, or a session to re-run T2 under the other model.
5. Do not edit any file other than the report you write. Do not change state.md.

## Reading the numbers

| Column | Meaning |
|---|---|
| Questions raised | How often the runner said "inferred" and asked |
| Class changed by human | How often the answer overturned the runner's proposal |
| Change rate | Changed divided by raised. Lower is better once questions are being raised at all |
| Questions per 100 passages | How cautious the model was. Strict mode should be higher |
| Inferred share | Fraction of written claims that were inferred before answers |

A model with a low change rate and few questions is either good or overconfident. Check its sessions for legacy and current-not-needed counts of zero before trusting it.
