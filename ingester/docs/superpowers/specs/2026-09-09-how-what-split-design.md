# Split the repository into the how and the what

Version 1.2, 9 September 2026. Owner: Adam Moyes.

## 1. Purpose

The repository currently mixes the method with one engagement's data. The runner documents, model, roles and tools sit beside the transcripts, claims and registers they operate on, all at the same level. That works for one engagement and stops working for two, and it means two people cannot work on the method and on an engagement at the same time without writing to the same files.

This design separates the two. The how holds everything that describes the method and is reusable across engagements. The what holds one engagement's sources and the artefacts distilled from them. The how never learns anything about a particular engagement; an engagement reads the how and runs it inside its own folder.

## 2. The invariant

**No action taken while working in an engagement may write any file outside that engagement's folder.**

Reads across the boundary are expected, because an engagement has to read the how in order to run it. Writes do not cross. This is the load-bearing rule of the design, and it is enforced in two halves: a static check that no engagement skill or CLAUDE.md names a write target outside the engagement, and a dynamic check that no tracked file outside the engagement is modified.

The invariant is what makes concurrent work safe. One person editing a runner document and another ingesting a transcript touch disjoint sets of files.

### 2.1 The invariant is structural, not merely checked

Revised 9 September 2026 (version 1.1), after the owner established that engagement data must never reach `origin`.

`engagements/` is gitignored in the outer repository, and each engagement is its own nested git repository. This changes the invariant from something a check enforces into something the arrangement makes true. From inside an engagement, git operates on that engagement's own repository and cannot see, stage or commit anything outside it. No discipline is required and no assertion can be forgotten.

It also gives each engagement its own history, which plain gitignoring would not: an ignored, unversioned engagement would breach P11, since transcripts, claims and registers are exactly the inputs and outputs that must persist.

Three consequences follow.

The outer repository can be pushed to `origin` carrying only the method. Nothing private is reachable from it, because git never sees the ignored path at all.

The outer repository's history becomes separately fixable. Private data already sits in local commit 4efe64d, which holds the T001 transcript and claims, so moving files forward does not make the outer repository publishable. Because the engagement now lives in its own repository, that history can be rewritten or reset without touching engagement data.

`tools/check-isolation.sh` changes purpose. Asserting that no tracked file outside the engagement is modified becomes vacuous, since the engagement's git has no knowledge of outside files and the check would pass while proving nothing. What can actually go wrong is the nesting being set up incorrectly, so that is what it asserts: that the engagement's git toplevel is the engagement root, and that the outer repository ignores it.

### 2.2 A hazard this design creates

`git clean -fdx` run in the outer repository deletes the ignored `engagements/` directory, its contents and its `.git`, because `-x` targets ignored paths. Verified by experiment: the directory and its data were removed. An engagement's commits are then lost unless mirrored elsewhere.

This is a real cost of the arrangement and is recorded as a named danger in ARCHITECTURE D12. An engagement's repository should have a remote or a backup so the command is survivable. `git clean -fd`, without `-x`, leaves the engagement alone.

## 3. Target layout

```
solution-management/
  CLAUDE.md              universal session rules only. Auto-loaded from
                         either folder as a parent directory.
  README.md              the repository shape
  .gitignore
  .claude/skills/        the four slash commands. AT THE ROOT, not in an
                         engagement: see 3.2.

  ingester/                        the how
    CLAUDE.md            the layout authority. Binds <HOW>, states which
                         paths are engagement-relative, says how to run
                         the pipeline.
    ARCHITECTURE.md
    ENHANCEMENTS.md
    LOG.md
    HANDOVER.md
    transcript-runner.md
    solution-register-runner.md
    solution-register-model.md
    roles.md
    diagrams/
    docs/superpowers/{specs,plans}/
    tools/
    tools/fixtures/

  engagements/abb-nokia/           the what
    CLAUDE.md            thin pointer to ../../ingester/CLAUDE.md, plus
                         this engagement's name, client and phase
    LOG.md
    HANDOVER.md
    FINDINGS.md
    .gitignore
    transcripts/{input,processed,claims}/, stakeholders.md
    registers/
    work/transcripts/
```

### 3.1 Why three CLAUDE.md files

Claude Code auto-loads the CLAUDE.md in the working directory and in every ancestor directory. Running from `engagements/abb-nokia/` therefore loads that engagement's file and the root's, and never the ingester's, because the ingester is a sibling rather than an ancestor. That is why the engagement's file has to point at the ingester's explicitly.

Each has a distinct job. The root holds rules that apply wherever you are working, so they are written once and read by both contexts. The ingester holds the method and the layout. The engagement holds its own identity and the pointer.

### 3.2 The skills stay at the repository root

Revised 9 September 2026 (version 1.2). The four skills were to move into the engagement. They stay at the root instead, ruled by the owner after the sandbox refused to move them: this project's `.claude/skills` is deliberately protected from agent modification, and moving them is exactly that.

The pipeline is unaffected. Claude Code loads `.claude/skills` from the working directory and every ancestor, and the repository root is an ancestor of `engagements/<name>/`, so all four load for an engagement session.

One set of root launchers then serves both contexts, which is cleaner than one set per folder. A skill's bare relative paths resolve against the working directory, so `HANDOVER.md` and `LOG.md` mean the engagement's when run from an engagement and the ingester's when run from the ingester. The ingester therefore needs no handover skill of its own, and two skills competing for the name `handover` never arise.

D8 still holds. The skills remain launchers with no rules; the rule stating which check and which log belong to which folder lives in `ingester/CLAUDE.md`, the layout authority.

Write isolation is untouched. From an engagement's point of view the skills are read-only, and everything they write resolves into the working directory.

The consequence accepted with this: a second engagement cannot have engagement-specific launchers. That is consistent with D8, which forbids a launcher from carrying engagement-specific rules anyway.

## 4. The `<HOW>` contract

`ingester/CLAUDE.md` binds `<HOW>` to the ingester root and records that from an engagement it is `../../ingester`. Three rules follow.

1. A how-document referencing machinery or a sibling how-document writes the `<HOW>/` prefix: `<HOW>/tools/vtt-to-passages.sh`, `<HOW>/roles.md`, `<HOW>/solution-register-model.md`. All references take the prefix, including prose cross-references and self-references. A uniform rule is worth slightly heavier prose, because every exception is something a later editor must reason about and a check must encode.

2. A how-document referencing engagement data writes a bare relative path: `transcripts/claims/`, `registers/`, `work/`. These resolve against the working directory, which is always the engagement.

3. No how-document contains `../` anywhere, with one deliberate exception named in 4.1. This is the invariant that keeps the how ignorant of how deeply an engagement sits, and it is checkable.

### 4.1 The placeholder is not a shell variable

`<HOW>/` is a documentation placeholder. It is substituted with the engagement-relative path at the moment a command is constructed, and it is never passed to a shell unsubstituted.

The angle brackets are deliberate. A dollar prefix is exactly what a shell expands, so an unsubstituted `$HOW/tools/vtt-to-passages.sh` would expand to `/tools/vtt-to-passages.sh` and fail with an error pointing nowhere near the cause. An unsubstituted `<HOW>/tools/vtt-to-passages.sh` is instead a redirection the shell cannot satisfy, so it fails immediately and visibly. Where a missed substitution is possible, the spelling that fails loudly is the safer one.

The single exception to rule 3 is `ingester/CLAUDE.md`, which has to contain `../../ingester` in order to state the binding. That gives the design a useful property: exactly one file in the how knows how deep an engagement sits, and it is the file whose job is to know. The check exempts that one file by name and asserts the path appears in no other how-document.

### 4.2 References to rewrite

27 references across four documents:

| Document | References |
|---|---|
| `transcript-runner.md` | 3 to `roles.md`, 3 to `solution-register-model.md`, 1 to `solution-register-runner.md`, 3 to `tools/vtt-to-passages.sh`, 1 self-reference |
| `solution-register-runner.md` | 1 to `roles.md`, 5 to `solution-register-model.md`, 2 self-references, 5 to `tools/check-registers.sh`, 1 to `transcript-runner.md` |
| `solution-register-model.md` | 1 to `solution-register-runner.md` |
| `roles.md` | 1 to `tools/check-stakeholders.sh` |

The roughly 78 references to `transcripts/`, `registers/` and `work/` are already engagement-relative and need no change. This is the reason the working directory must be the engagement.

## 5. Tool changes

Nine tools need no change. They either validate how-documents they travel with, or already take their paths as arguments: `check-model-cr.sh`, `check-model-prc.sh`, `check-runner.sh`, `check-transcript-runner.sh`, `ingestion-report.sh`, `test-vtt-to-passages.sh`, `test-ingestion-report.sh`, `test-check-registers.sh`, `vtt-to-passages.sh`.

`check-runner.sh` and `check-transcript-runner.sh` mention engagement paths only inside `need "..."` string assertions against how-documents, so they never open an engagement file. Verified before this design was written.

Four tools change:

| Tool | Change |
|---|---|
| `check-stakeholders.sh` | gains `root="${1:-.}"`, reads `$root/transcripts/stakeholders.md`, and takes over the roles.md-reference assertion described below |
| `check-registers.sh` | `$1` keeps meaning the registers directory, so the register runner's existing `check-registers.sh work/03-dryrun` call is untouched. Only the default changes, from `$(dirname "$0")/../registers` to a cwd-relative `registers` |
| `check-roles.sh` | line 24 currently opens `transcripts/stakeholders.md` to assert the registry points at roles.md. That assertion belongs to the engagement, so it moves to `check-stakeholders.sh`. `check-roles.sh` then validates only roles.md and needs no argument |
| `handover-check.sh` | becomes `handover-check.sh [root]`, defaulting to the working directory. Reads `<root>/HANDOVER.md`, scopes its clean-tree test to `git status --porcelain -- <root>`, and compares the recorded commit against the latest touching `<root>` while excluding that folder's HANDOVER.md and LOG.md. It reads git state and mutates nothing |

`check-roles.sh` losing its cross-boundary assertion generalises to a rule: validating the how must never require an engagement to exist. If it does, the separation is not real.

## 6. The check split

Three entry points:

- `<HOW>/tools/check-how.sh`, no arguments, validates the ingester and the root scaffolding.
- `<HOW>/tools/check-engagement.sh [root]`, validates one engagement, default the working directory.
- `<HOW>/tools/check-all.sh [root]`, runs both.

The commit rule in `ingester/CLAUDE.md` becomes: run the check for the folder you are working in, and append to that folder's `LOG.md`. One sentence that resolves correctly in either context.

### 6.1 Where every current assertion goes

`check-all.sh` today holds 10 sub-tool invocations and 17 inline assertions. None is dropped (P10).

| Current assertion | Destination |
|---|---|
| `check-model-prc`, `check-model-cr`, `check-runner`, `check-transcript-runner`, `check-roles` | how |
| `test-vtt-to-passages`, `test-ingestion-report`, `test-check-registers` | how |
| `check-stakeholders`, `check-registers` | engagement |
| README documents the layers, 3 assertions | how, rewritten for `ingester/` and `engagements/` |
| ingest skill chains the register runner | engagement |
| `transcripts/input` not gitignored | engagement |
| `transcripts/{input,processed,claims}/.gitkeep` | engagement |
| em dash scan | splits by file. How-documents, root scaffolding and the root skills to how; stakeholders and engagement documents to engagement |
| four skills present, and the ingest skill chaining the register runner | how, not engagement, since the skills stay at the root (3.2). No ingester-specific handover skill is created |
| handover shape, 6 headers and the 25-line cap | both, through a shared `<HOW>/tools/check-handover-shape.sh [root]` so the rule is written once |
| `handover-check.sh` executable | how |

### 6.2 New assertions

In `check-how.sh`:

- Every how-file reference in a how-document carries the `<HOW>/` prefix.
- No how-document contains `../`, exempting `ingester/CLAUDE.md`, which states the binding and is the only file permitted to name the path.
- `ingester/CLAUDE.md` defines the `<HOW>` binding.
- Enhancement ids are unique. This is the check that would have caught the duplicate E13 found on 9 September 2026.
- The independence test: `check-how.sh` passes against a tree holding only `ingester/` and the root files, with no engagement present.

In `check-engagement.sh`:

- `FINDINGS.md` has the expected shape.
- Every finding marked promoted names an ingester enhancement id.
- No engagement skill or CLAUDE.md names a write target outside the engagement. This is the static half of the invariant.

In its own tool, `<HOW>/tools/check-isolation.sh <root>`, root required rather than defaulted, because a silent default to the whole repository would let it pass vacuously:

- The engagement's git toplevel is the engagement root, proving it is its own repository rather than part of the outer one.
- The outer repository ignores the engagement path.
- No file tracked by the outer repository lives under the engagement root.

It sits outside the routine check deliberately. During structural work a dirty ingester is correct, and a routine check that failed on it would teach you to ignore the check. The handover skill invokes it.

## 7. Governance and the findings outbox

| File | Lands | Written by |
|---|---|---|
| `ingester/ARCHITECTURE.md` | the how | ingester work only |
| `ingester/ENHANCEMENTS.md` | the how | ingester work only |
| `ingester/LOG.md` | the how | ingester work only |
| `ingester/HANDOVER.md` | the how | an ingester session |
| `engagements/<n>/LOG.md` | that engagement | that engagement only |
| `engagements/<n>/HANDOVER.md` | that engagement | that engagement's session |
| `engagements/<n>/FINDINGS.md` | that engagement | that engagement only |
| `engagements/<n>/.gitignore` | that engagement | that engagement's scratch patterns |
| root `CLAUDE.md`, `README.md`, `.gitignore` | root | structural work only |
| root `.claude/skills/` | root | structural work only; see 3.2 |

There is no root `LOG.md`. Structural changes are logged in `ingester/LOG.md`, because the scaffolding exists to serve the method.

An engagement's `LOG.md`, `HANDOVER.md` and `FINDINGS.md` are committed to that engagement's own repository, not the outer one. The outer repository never tracks them, so the two records never contend.

`ENHANCEMENTS.md` is purely a how-artefact, and D1 is the reason: it already establishes that open items are the work queue, so an engagement's deferred work is an open item in its register rather than an enhancement.

### 7.1 The outbox

Engagement work discovers how-findings. Session T001 is the proof: it produced E14, E15 and E16, all of them changes to the method, being a quote rule in the runner document, a T3 rule about trivial context claims, and an entity bug in the parser.

Under the invariant an engagement cannot write `ingester/ENHANCEMENTS.md`. So it writes its own `FINDINGS.md`, and an ingester session later reads the open outboxes and promotes entries into `ENHANCEMENTS.md` with a real id, marking the outbox entry promoted and citing the finding as its source.

The promotion is the ingester maintainer's judgement, which is the right place for it: an engagement observes one symptom, and whether that symptom justifies a rule change is a question about the method. It also gives enhancement ids a single issuer, which is what would have prevented the duplicate E13.

`FINDINGS.md` format: id, title, what was observed with its evidence, state of `open` or `promoted`, and for a promoted entry the ingester enhancement id.

### 7.2 Splitting the existing LOG.md

The current `LOG.md` covers both sides. Almost every line is a how-change, being document versions, tool fixes and decisions about the method. The three lines recording the T001 ingestion are engagement events.

`ingester/LOG.md` takes the file as it stands, less those three lines. `engagements/abb-nokia/LOG.md` takes the three T001 lines under a header noting that history before the split lives in `ingester/LOG.md`.

Optionally, and worth doing for provenance, `FINDINGS.md` is seeded with three entries marked promoted, pointing at E14, E15 and E16, so the mechanism carries the history it would have recorded had it existed.

## 8. ARCHITECTURE.md changes

Bring it to version 1.11:

- **Amend P7's wording.** It is titled "Separate the ingester from the lifecycle" and uses "ingester" to mean the transcript runner as distinct from the model and register runner. The `ingester/` folder holds all three, so the word would carry two meanings in one project. Replace "ingester" with "transcript runner" throughout the principle. The substance is unchanged.
- **Rewrite its own section 1 layer table** for the two-folder shape, so the Data, Registers and Working state rows name engagement-relative paths and the Model, Runner and Tools rows name the ingester.
- **Reword D11.** It says registers are built in "`registers/` in this repository", which stops being precise once one repository holds an ingester and several engagements. It should name the engagement.
- **Add D12**, recording the how and what split, the write-isolation invariant, the `<HOW>` contract, the findings outbox with its single-issuer rule for enhancement ids, and the nested-repository arrangement of 2.1 with the `git clean -fdx` hazard of 2.2 named as an accepted danger.

Nothing goes under ARCHITECTURE.md's section 6 Deviations, because every conflict is resolved by amending the principle or decision rather than overriding it.

## 9. Migration

### Precondition

Nothing moves until the repository is reconciled and committed. As of 9 September 2026 it holds 2 local commits, 6 remote commits, unreconciled, and about 30 uncommitted files. A large file move across a divergent history is how work gets lost. This is the owner's to clear, since the owner runs all git operations.

### Phase 1, in the current layout

Every step is behaviour-preserving, because in the flat layout the engagement root and the working directory are the same directory, so a tool defaulting its root to `.` behaves exactly as it does today. The checks stay green throughout.

1. Re-anchor `check-stakeholders.sh` and `handover-check.sh` to take a root defaulting to the working directory.
2. Change `check-registers.sh`'s default to cwd-relative.
3. Move `check-roles.sh`'s stakeholders assertion into `check-stakeholders.sh`.
4. Extract `check-handover-shape.sh`.
5. Split `check-all.sh` into `check-how.sh`, `check-engagement.sh` and a `check-all.sh` that runs both.
6. Add the enhancement-id uniqueness check.

Verification: `check-all.sh` green, and each new entry point green independently. Commit, giving a known-good point to return to.

### Phase 2, the cutover, one commit

It has to be one commit. There is no intermediate state where the checks pass, because the tools cannot be half re-pathed and the documents cannot be half prefixed.

7. Create the two folders and move the files as section 3 sets out, `docs/superpowers/` included.
8. Rewrite the 27 references with `<HOW>/`.
9. Split the governance files as section 7 sets out.
10. Write `ingester/CLAUDE.md` as the layout authority. Trim the root `CLAUDE.md` to universal rules. Add the engagement pointer.
11. Update the four root skills for `<HOW>` and for resolving their log and handover against the working directory. No ingester-specific skill is created (3.2).
13. Add the new checks from section 6.2, including `check-isolation.sh`.
14. Bring `ARCHITECTURE.md` to 1.11 as section 8 sets out.
15. Add per-folder `.gitignore` files.

Verification: `check-engagement.sh` green, `check-isolation.sh` green, and `check-how.sh` green against a temporary tree holding only `ingester/` and the root files.

### Phase 3, smoke test

16. Run `/build-registers` from the engagement.

It exercises everything the split touches: `<HOW>` resolution, engagement-relative data paths, the register runner reading `transcripts/claims/`, and `check-registers.sh` against both a dry run and the real target. A green run is evidence rather than an assertion. It is also the task that was outstanding when this design began.

## 10. Compliance check

Recorded as required by ARCHITECTURE.md section 5.

```
## Compliance check: split the repository into ingester/ for process
documents, model, roles and tools, and engagements/<name>/ for
transcripts, claims, registers, stakeholders, working state and skills,
with write isolation, run from the engagement, and how-references
written as <HOW>/

Compliant: P1, behaviour stays in markdown and the <HOW> binding is
  itself a documented rule. P2 and P11, verified: claims store a bare
  filename, and no register, claim or state file contains a
  path-shaped string, so the move cannot break traceability, and
  nothing is deleted or newly ignored. P4, the <HOW> convention and
  argument-anchored tools are deterministic, which is why prose
  resolution was rejected. P8, no symlinks and no new runtimes. P9,
  Australian English and versioned documents carry over. D1, D2, D6,
  D7, D8, D10, registers stay the record, claims stay the interface,
  the claim format and state file are unchanged, no orchestration
  changes, skills stay thin.
Not applicable: P3, P5, P6, P12, D3, D4, D5. Gates, session scope,
  model measurement and item-type rules are untouched by a file move.
Violations: P7 as written, whose use of "ingester" for the transcript
  runner collides with the folder name. P10, since the <HOW> rule and
  the write-isolation invariant become load-bearing and need
  assertions in the same commit, and the check split must lose no
  coverage. D9, every document whose content changes needs a version
  and date bump. D11 as written, whose "in this repository" stops
  being precise.
Decision: PROCEED WITH MODIFICATIONS. The modifications are section 8
  of this design, plus the new assertions in section 6.2.
```

## 11. Decisions taken during design

- One git repository with two top-level folders, rather than two repositories or a submodule. The owner weighed cross-repo reuse against a single history and chose the single history.
- `roles.md` is part of the how. ARCHITECTURE.md section 1 already places it in the Model layer and describes that layer as tool-agnostic. It defines the role vocabulary and what each role may yield, which are classification rules, and it names no person. `transcripts/stakeholders.md` is the what, assigning real people to those roles.
- How-references use a named `<HOW>/` placeholder bound once, rather than a symlink, prose resolution, or literal `../../ingester/` paths. The placeholder keeps the how free of engagement depth and is the only option a check can enforce.
- The placeholder is spelled `<HOW>/` rather than `$HOW/`, ruled by the owner on 9 September 2026. Reasoning in 4.1: a missed substitution fails loudly instead of silently.
- `engagements/` is gitignored in the outer repository and each engagement is its own nested git repository, ruled by the owner on 9 September 2026 after establishing that engagement data must never reach `origin`. Reasoning and consequences in 2.1, hazard in 2.2.
- Write isolation, rather than a single root log. Reached after the owner raised concurrent work by two people as a requirement.
- How-findings from engagement work go to a per-engagement outbox, promoted by an ingester session, rather than allowing one write across the boundary.

## 12. Open questions

None outstanding. The engagement folder is named `abb-nokia`, and the arrangement for keeping engagements off `origin` is settled in 2.1.
