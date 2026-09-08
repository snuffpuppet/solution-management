---
name: ingest-transcript
description: Use when the user wants a WebVTT discovery-session transcript ingested into claims, or types /ingest-transcript with a .vtt path
argument-hint: "<path to .vtt>"
---

# Ingest transcript

Start the transcript runner on one WebVTT file. The runner document is the authority on every stage; this skill only stages the file and launches T0.

## Steps

1. If `$ARGUMENTS` is empty, say `Usage: /ingest-transcript <path to .vtt>` and stop.
2. If the file does not exist, say so and stop. If its first line, ignoring a byte order mark, is not `WEBVTT`, say so and stop.
3. If the file is not already inside `transcripts/input/`, copy it there with `cp`, keeping its name. Never move or edit the original.
4. Read `transcript-runner.md` in full, then `solution-register-model.md` in full.
5. Execute the transcript runner from stage T0 on that file. Follow its checkpoint protocol: stop at every checkpoint and wait for approval. Record the model you are running as at T0, as the runner's T0 step 8 says.
6. If `work/transcripts/state.md` shows a session that is not complete, tell the user before starting a new one and ask whether to resume it or start this file.

## Do not

- Run more than one file per invocation.
- Skip the runner document because the steps look familiar. Read it every time; it changes.
- Classify anything before T1 has produced the passage file.
