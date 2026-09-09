# How and What Repository Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split this repository so the method lives in `ingester/` and each engagement's sources and artefacts live in `engagements/<name>/`, with no engagement able to write outside its own folder.

**Architecture:** Claude runs with an engagement as the working directory, which makes the roughly 78 existing data-path references resolve unchanged. The 26 references pointing the other way, from a how-document to machinery, gain a `<HOW>/` prefix bound once in `ingester/CLAUDE.md`. Four tools that open engagement files change from `$0`-relative anchoring to a root argument defaulting to the working directory, and `check-all.sh` splits into a how-check and an engagement-check.

**Tech Stack:** bash, awk, sed, grep only (P8). Markdown documents. No test framework: the check scripts are the tests.

**Spec:** `docs/superpowers/specs/2026-09-09-how-what-split-design.md`

## Global Constraints

- **The owner runs every git command.** Never run `git add`, `git commit`, `git mv`, `git checkout`, `git reset`, `git merge` or `git push`. Reading git state with `git status`, `git log`, `git diff` or `git check-ignore` is permitted. Every commit step in this plan is an instruction to hand to the owner, not a command to run.
- **Move files with `mv`, not `git mv`.** Git detects the renames when the owner stages them.
- Australian English. No em dashes in any document.
- Bump the version line of any document whose content changes (D9).
- Append one line to the relevant `LOG.md` per commit, kind `change`, `decision` or `ruling`.
- Record deferred work in `ENHANCEMENTS.md`, not in conversation.
- Every rule another document or tool depends on gains an assertion in the same commit (P10).
- `tools/check-all.sh` must be all ok before any commit.
- Baseline to protect: **220 `ok` assertions**, captured 9 September 2026. No assertion label may disappear.
- Scratch lives in `work/tmp/`, which is gitignored by `work/**/tmp/`.
- **`engagements/` is gitignored in the outer repository and each engagement is its own nested git repository** (owner ruling, 9 September 2026; spec 2.1). Engagement data must never reach `origin`. This makes write isolation structural rather than checked.
- **Hazard:** `git clean -fdx` in the outer repository destroys an ignored engagement, `.git` included (spec 2.2). Never run it, and never suggest it.
- **The four skills STAY at the repository root** (owner ruling, 9 September 2026; spec 3.2). The sandbox protects `.claude/skills` from agent modification. They still load for an engagement session because the root is an ancestor. One set of root launchers serves both contexts; no ingester-specific skill is created.
- **The spec and this plan now live at `ingester/docs/superpowers/`**, moved by Task 8.

---

## Phase 0: Precondition, owner action

**This is not an implementable task. Phase 1 does not start until it is done.**

As of 9 September 2026 the repository holds 2 local commits, 6 remote commits, unreconciled, and about 30 uncommitted files including the `roles.md` restore, the E13 deletion and the E17 addition. A large file move across a divergent history loses work.

- [ ] Owner reconciles `main` with `origin/main`
- [ ] Owner commits the working tree, including the three `LOG.md` lines whose Commit column currently reads `pending`, and fills those hashes
- [ ] Confirm `git status --short` is empty and `tools/check-all.sh` exits 0 before starting Task 1

---

## Phase 1: Behaviour-preserving changes in the current layout

Every task here leaves the checks green. In the flat layout the engagement root and the working directory are the same directory, so a tool defaulting its root to `.` behaves exactly as it does today.

### Task 1: Capture the regression guard

**Files:**
- Create: `work/tmp/baseline-labels.txt` (gitignored scratch)
- Create: `work/tmp/guard.sh` (gitignored scratch)
- Create: `work/tmp/now-labels.txt` (gitignored scratch, written by the guard on every run)

**Interfaces:**
- Produces: `work/tmp/baseline-labels.txt`, one assertion label per line, sorted and unique. Every later task in phases 1 and 2 checks its own run against this file.

- [ ] **Step 1: Capture the baseline**

```bash
mkdir -p work/tmp
tools/check-all.sh 2>&1 | grep '^ok' | sed 's/^ok  *//' | sort -u > work/tmp/baseline-labels.txt
wc -l < work/tmp/baseline-labels.txt
```

Expected: `219` (220 assertions, 219 distinct labels, one label appearing twice).

- [ ] **Step 2: Write the guard script**

Create `work/tmp/guard.sh`:

```bash
#!/usr/bin/env bash
# Fails if any baseline assertion label has disappeared. Scratch, not committed.
set -u
tools/check-all.sh 2>&1 | grep '^ok' | sed 's/^ok  *//' | sort -u > work/tmp/now-labels.txt
lost=$(comm -23 work/tmp/baseline-labels.txt work/tmp/now-labels.txt)
if [ -n "$lost" ]; then
  echo "LOST ASSERTIONS:"; echo "$lost" | sed 's/^/  /'; exit 1
fi
echo "ok   no baseline assertion lost ($(wc -l < work/tmp/now-labels.txt) labels now)"
```

```bash
chmod +x work/tmp/guard.sh
```

- [ ] **Step 3: Verify the guard passes against an unchanged tree**

Run: `work/tmp/guard.sh`
Expected: `ok   no baseline assertion lost (219 labels now)`

- [ ] **Step 4: No commit**

Nothing here is tracked. `work/tmp/` is gitignored.

---

### Task 2: `check-stakeholders.sh` takes an engagement root and absorbs the registry assertion

`check-roles.sh:24` currently opens `transcripts/stakeholders.md` to assert the registry points at `roles.md`. That assertion belongs to the engagement, not the how, because validating the how must never require an engagement to exist.

**Files:**
- Modify: `tools/check-stakeholders.sh` (whole file)
- Modify: `tools/check-roles.sh:24`

**Interfaces:**
- Produces: `tools/check-stakeholders.sh [engagement root]`, default `.`. Reads `<root>/transcripts/stakeholders.md`. Exit 0 on pass, 1 on failure, 1 immediately if the file is missing.

- [ ] **Step 1: Write the failing test**

Assert the new label exists. It does not yet, so this must fail:

```bash
tools/check-stakeholders.sh | grep -q 'registry references roles.md' \
  && echo UNEXPECTED-PASS || echo "expected fail: label absent"
```

Expected: `expected fail: label absent`

- [ ] **Step 2: Confirm the current cross-boundary assertion exists in the wrong place**

```bash
grep -n 'transcripts/stakeholders.md' tools/check-roles.sh
```

Expected: line 24, inside the `for d in ...` loop.

- [ ] **Step 3: Rewrite `tools/check-stakeholders.sh`**

```bash
#!/usr/bin/env bash
# Integrity checks over one engagement's stakeholder registry.
# Usage: tools/check-stakeholders.sh [engagement root]   default: .
set -u
root="${1:-.}"
f="$root/transcripts/stakeholders.md"
fail=0
[ -f "$f" ] && echo "ok   stakeholders file" || { echo "FAIL stakeholders file"; exit 1; }
grep -qF '| Name | Tags | Organisation | Role | Expertise |' "$f" && echo "ok   header" || { echo "FAIL header"; fail=1; }
for r in sme consultant vendor architect; do
  grep -qF "\`$r\`" "$f" && echo "ok   role $r defined" || { echo "FAIL role $r defined"; fail=1; }
done
bad=$(awk -F'|' '/^\|/ && $2 !~ /Name|---/ { gsub(/ /,"",$5); if ($5 !~ /^(sme|consultant|vendor|architect)$/) print $0 }' "$f")
[ -z "$bad" ] && echo "ok   every row has a valid role" || { echo "FAIL invalid role: $bad"; fail=1; }
# Moved here from check-roles.sh: this opens an engagement file, so it is an engagement check.
grep -qF 'roles.md' "$f" && echo "ok   registry references roles.md" || { echo "FAIL registry references roles.md"; fail=1; }
exit $fail
```

- [ ] **Step 4: Remove the cross-boundary assertion from `check-roles.sh`**

Change line 24 from:

```bash
for d in transcript-runner.md solution-register-runner.md transcripts/stakeholders.md; do grep -qF 'roles.md' "$d" && echo "ok   $d references roles.md" || { echo "FAIL $d references roles.md"; fail=1; }; done
```

to:

```bash
for d in transcript-runner.md solution-register-runner.md; do grep -qF 'roles.md' "$d" && echo "ok   $d references roles.md" || { echo "FAIL $d references roles.md"; fail=1; }; done
```

- [ ] **Step 5: Verify the tests pass**

```bash
tools/check-stakeholders.sh | grep 'registry references roles.md'
tools/check-stakeholders.sh . >/dev/null; echo "explicit root exit=$?"
tools/check-roles.sh | grep -c 'stakeholders'
```

Expected: the label prints; `explicit root exit=0`; the count is `0`.

- [ ] **Step 6: Confirm no assertion was lost**

Run: `work/tmp/guard.sh`
Expected: `ok   no baseline assertion lost`. The label `transcripts/stakeholders.md references roles.md` is replaced by `registry references roles.md`, so if the guard reports it lost, add the old label as an alias in `check-stakeholders.sh` rather than reinstating the cross-boundary read.

- [ ] **Step 7: Commit, owner runs**

```bash
git add tools/check-stakeholders.sh tools/check-roles.sh
git commit -m "check-stakeholders takes an engagement root; registry assertion moves out of check-roles

Validating the how must not require an engagement to exist. check-roles.sh
line 24 opened transcripts/stakeholders.md; that assertion is an engagement
concern and moves to check-stakeholders.sh, which now takes a root argument
defaulting to the working directory.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

Then append to `LOG.md`, kind `change`.

---

### Task 3: `check-registers.sh` default becomes working-directory relative

`$1` keeps meaning the registers directory, so the register runner's existing `check-registers.sh work/03-dryrun` call is untouched. Only the default changes.

**Files:**
- Modify: `tools/check-registers.sh:5`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `tools/check-registers.sh [registers dir]`, default `registers` relative to the working directory.

- [ ] **Step 1: Write the failing test**

Prove the current default is `$0`-relative rather than cwd-relative, by running from elsewhere:

```bash
mkdir -p work/tmp/elsewhere
(cd work/tmp/elsewhere && ../../../tools/check-registers.sh >/dev/null 2>&1; echo "from elsewhere exit=$?")
```

Expected: `from elsewhere exit=0`, which is the bug. The tool found the repository's own `registers/` through `$0` while the working directory had none, so it validated the wrong engagement.

- [ ] **Step 2: Change the default**

In `tools/check-registers.sh`, change line 5 from:

```bash
dir="${1:-$(dirname "$0")/../registers}"
```

to:

```bash
dir="${1:-registers}"
```

Leave line 6 alone. `model="$(dirname "$0")/../solution-register-model.md"` is a how-file that travels with the tool, so `$0`-anchoring is correct there.

- [ ] **Step 3: Verify the test now fails correctly from elsewhere**

```bash
(cd work/tmp/elsewhere && ../../../tools/check-registers.sh >/dev/null 2>&1; echo "from elsewhere exit=$?")
```

Expected: non-zero. There is no `registers/` in that directory, which is the correct answer.

- [ ] **Step 4: Verify normal use is unchanged**

```bash
tools/check-registers.sh >/dev/null; echo "from root exit=$?"
tools/check-registers.sh registers >/dev/null; echo "explicit exit=$?"
rm -rf work/tmp/elsewhere
```

Expected: both `exit=0`.

- [ ] **Step 5: Confirm no assertion was lost**

Run: `work/tmp/guard.sh`
Expected: `ok   no baseline assertion lost`

- [ ] **Step 6: Commit, owner runs**

```bash
git add tools/check-registers.sh
git commit -m "check-registers: default the registers dir to the working directory

The \$0-relative default made the tool validate this repository's registers
even when run from a directory that had none. \$1 keeps its meaning, so the
register runner's check-registers.sh work/03-dryrun call is unaffected.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

Then append to `LOG.md`, kind `change`.

---

### Task 4: `handover-check.sh` takes a root

**Files:**
- Modify: `tools/handover-check.sh` (whole file)

**Interfaces:**
- Produces: `tools/handover-check.sh [root]`, default `.`. Reads `<root>/HANDOVER.md`. Exit 0 on pass, 2 to block a Stop hook with the reason on stderr.

- [ ] **Step 1: Write the failing test**

```bash
mkdir -p work/tmp/nohandover
(cd work/tmp/nohandover && ../../../tools/handover-check.sh </dev/null >/dev/null 2>&1; echo "exit=$?")
```

Expected: `exit=0`. That is the bug: the tool `cd`s to its own repository root through `$0` and finds the repository's HANDOVER.md, ignoring the directory it was asked about.

- [ ] **Step 2: Rewrite `tools/handover-check.sh`**

```bash
#!/usr/bin/env bash
# Handover check for one folder. Run by the handover skill, by hand, or as a Stop hook.
# Usage: tools/handover-check.sh [root]   default: .
# Passes when: no uncommitted tracked changes under <root>, and the commit recorded in
# <root>/HANDOVER.md equals the latest commit touching <root> other than that folder's
# own HANDOVER.md and LOG.md. Exit 2 blocks the stop; stderr reaches the agent.
set -u
root="${1:-.}"
case "$root" in .) p="" ;; *) p="${root%/}/" ;; esac
input=$(cat 2>/dev/null || true)
case "$input" in *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;; esac
[ -f "${p}HANDOVER.md" ] || { echo "HANDOVER.md is missing under ${root}. Create it from the template in CLAUDE.md, then commit." >&2; exit 2; }
recorded=$(grep -m1 '^Last commit:' "${p}HANDOVER.md" | awk '{print $3}')
latest=$(git log -1 --format=%h -- "$root" ":!${p}HANDOVER.md" ":!${p}LOG.md" 2>/dev/null)
dirty=$(git status --porcelain --untracked-files=no -- "$root" 2>/dev/null)
msgs=""
[ -n "$dirty" ] && msgs="${msgs}Uncommitted changes exist under ${root}; commit them or discard them. "
[ "$recorded" != "$latest" ] && msgs="${msgs}${p}HANDOVER.md records commit '${recorded:-none}' but the latest work commit under ${root} is '$latest'. Update HANDOVER.md (in flight, next action, blocked, last commit) and LOG.md, then commit. "
if [ -n "$msgs" ]; then
  echo "Before ending the session: $msgs" >&2
  exit 2
fi
exit 0
```

- [ ] **Step 3: Verify the test now fails correctly**

```bash
(cd work/tmp/nohandover && ../../../tools/handover-check.sh </dev/null >/dev/null 2>&1; echo "exit=$?")
rm -rf work/tmp/nohandover
```

Expected: `exit=2`. There is no HANDOVER.md there, which is the correct answer.

- [ ] **Step 4: Verify the Stop-hook escape still works**

```bash
echo '{"stop_hook_active":true}' | tools/handover-check.sh; echo "escape exit=$?"
```

Expected: `escape exit=0`.

- [ ] **Step 5: Verify normal use from the repository root**

```bash
tools/handover-check.sh </dev/null; echo "root exit=$?"
```

Expected: `exit=2` while the tree is dirty from this task, or `exit=0` on a clean committed tree. Either is correct. What must not happen is a crash or an empty `latest`.

- [ ] **Step 6: Commit, owner runs**

```bash
git add tools/handover-check.sh
git commit -m "handover-check: take a root, defaulting to the working directory

Replaces the cd through \$0, so the tool checks the folder it was asked
about rather than its own repository root. Its clean-tree test and its
git log lookup are both scoped to that root.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

Then append to `LOG.md`, kind `change`.

---

### Task 5: Extract `check-handover-shape.sh`

Both the how-check and the engagement-check will assert a HANDOVER.md's shape. The rule is written once.

**Files:**
- Create: `tools/check-handover-shape.sh`

`tools/check-all.sh` keeps its inline handover block until Task 7 replaces the file wholesale. This task does not touch it.

**Interfaces:**
- Produces: `tools/check-handover-shape.sh [root]`, default `.`. Asserts the six required sections and the 25-line cap on `<root>/HANDOVER.md`. Exit 0 on pass, 1 on failure.

- [ ] **Step 1: Write the failing test**

```bash
tools/check-handover-shape.sh 2>/dev/null; echo "exit=$?"
```

Expected: `exit=127` and a "command not found" style error. The tool does not exist.

- [ ] **Step 2: Create `tools/check-handover-shape.sh`**

```bash
#!/usr/bin/env bash
# Shape of one HANDOVER.md: the six required sections and the length cap.
# Usage: tools/check-handover-shape.sh [root]   default: .
set -u
root="${1:-.}"
f="${root%/}/HANDOVER.md"
case "$root" in .) f="HANDOVER.md" ;; esac
fail=0
[ -f "$f" ] || { echo "FAIL handover file $f"; exit 1; }
for h in "^Updated: " "^Last commit: " "^## In flight" "^## Next action" "^## Blocked" "^## Notes for the next session"; do
  grep -q "$h" "$f" && echo "ok   $h" || { echo "FAIL $h"; fail=1; }
done
[ "$(wc -l < "$f")" -le 25 ] && echo "ok   handover under 25 lines" || { echo "FAIL handover under 25 lines"; fail=1; }
exit $fail
```

```bash
chmod +x tools/check-handover-shape.sh
```

- [ ] **Step 3: Verify it passes and produces the same seven labels as the inline block**

```bash
tools/check-handover-shape.sh
tools/check-handover-shape.sh | grep -c '^ok'
```

Expected: 7 `ok` lines, being the six section headers and the line cap. These are the same labels `check-all.sh` prints today under `== handover`.

- [ ] **Step 4: Verify it rejects a bad handover**

```bash
mkdir -p work/tmp/badhandover
printf '# Handover\n\nUpdated: 2026-09-09\n' > work/tmp/badhandover/HANDOVER.md
tools/check-handover-shape.sh work/tmp/badhandover; echo "exit=$?"
rm -rf work/tmp/badhandover
```

Expected: FAIL lines for `^Last commit: `, `^## In flight`, `^## Next action`, `^## Blocked`, `^## Notes for the next session`, and `exit=1`.

- [ ] **Step 5: Commit, owner runs**

```bash
git add tools/check-handover-shape.sh
git commit -m "Extract check-handover-shape.sh so the handover rule is written once

Both the how-check and the engagement-check will assert a HANDOVER.md's
shape after the split. check-all.sh still holds its inline copy; Task 7
removes it.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

Then append to `LOG.md`, kind `change`.

---

### Task 6: `check-enhancements.sh`, unique enhancement ids

This is the check that would have caught the duplicate E13 found on 9 September 2026, when a session working from a stale local `main` issued an id that `origin/main` had already used.

**Files:**
- Create: `tools/check-enhancements.sh`
- Create: `tools/fixtures/enhancements/dup.md`
- Create: `tools/fixtures/enhancements/ok.md`

**Interfaces:**
- Produces: `tools/check-enhancements.sh [file]`, default `ENHANCEMENTS.md`. Exit 0 on pass, 1 on failure.

- [ ] **Step 1: Write the failing test**

Create a fixture with a duplicate id:

```bash
mkdir -p tools/fixtures/enhancements
cat > tools/fixtures/enhancements/dup.md <<'EOF'
# Enhancements

| Id | Title | Why | Start when | Size |
|---|---|---|---|---|
| E1 | First | reason | trigger | small |
| E2 | Second | reason | trigger | small |
| E2 | Third, colliding id | reason | trigger | small |
EOF
cat > tools/fixtures/enhancements/ok.md <<'EOF'
# Enhancements

| Id | Title | Why | Start when | Size |
|---|---|---|---|---|
| E1 | First | reason | trigger | small |
| E2 | Second | reason | trigger | small |
EOF
tools/check-enhancements.sh tools/fixtures/enhancements/dup.md 2>/dev/null; echo "exit=$?"
```

Expected: `exit=127`. The tool does not exist.

- [ ] **Step 2: Create `tools/check-enhancements.sh`**

```bash
#!/usr/bin/env bash
# Checks over ENHANCEMENTS.md. Ids are the promotion currency for engagement
# findings, so a duplicate id silently merges two unrelated pieces of work.
# Usage: tools/check-enhancements.sh [file]   default: ENHANCEMENTS.md
set -u
f="${1:-ENHANCEMENTS.md}"
fail=0
[ -f "$f" ] || { echo "FAIL enhancements file $f"; exit 1; }
echo "ok   enhancements file"
grep -qF '| Id | Title | Why | Start when | Size |' "$f" && echo "ok   enhancements header" || { echo "FAIL enhancements header"; fail=1; }
dups=$(grep -oE '^\| E[0-9]+ \|' "$f" | sort | uniq -d | tr -d '| ')
[ -z "$dups" ] && echo "ok   enhancement ids unique" || { echo "FAIL duplicate enhancement ids: $(echo $dups)"; fail=1; }
exit $fail
```

```bash
chmod +x tools/check-enhancements.sh
```

- [ ] **Step 3: Verify it catches the duplicate**

```bash
tools/check-enhancements.sh tools/fixtures/enhancements/dup.md; echo "exit=$?"
```

Expected: `FAIL duplicate enhancement ids: E2` and `exit=1`.

- [ ] **Step 4: Verify it passes a clean file and the real one**

```bash
tools/check-enhancements.sh tools/fixtures/enhancements/ok.md; echo "fixture exit=$?"
tools/check-enhancements.sh; echo "real exit=$?"
```

Expected: both `exit=0`. If the real file fails, there is a genuine duplicate id to resolve before continuing.

- [ ] **Step 5: Commit, owner runs**

```bash
git add tools/check-enhancements.sh tools/fixtures/enhancements/
git commit -m "check-enhancements: assert enhancement ids are unique

Ids become the promotion currency for engagement findings after the split,
so a duplicate silently merges two unrelated pieces of work. This is the
check that would have caught the duplicate E13 on 2026-09-09.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

Then append to `LOG.md`, kind `change`.

---

### Task 7: Split `check-all.sh` into a how-check and an engagement-check

**Files:**
- Create: `tools/check-how.sh`
- Create: `tools/check-engagement.sh`
- Modify: `tools/check-all.sh` (whole file)

**Interfaces:**
- Consumes: `tools/check-handover-shape.sh [root]` from Task 5, `tools/check-enhancements.sh [file]` from Task 6, `tools/check-stakeholders.sh [root]` from Task 2, `tools/check-registers.sh [registers dir]` from Task 3.
- Produces: `tools/check-how.sh` taking no arguments; `tools/check-engagement.sh [root]` defaulting to `.`; `tools/check-all.sh [root]` running both. All exit 0 on pass, 1 on failure.

- [ ] **Step 1: Write the failing test**

```bash
tools/check-how.sh 2>/dev/null; echo "how exit=$?"
tools/check-engagement.sh 2>/dev/null; echo "engagement exit=$?"
```

Expected: both `exit=127`. Neither exists.

- [ ] **Step 2: Create `tools/check-how.sh`**

Note the two roots. In this flat layout the how root and the repository root are the same directory; Task 9 separates them.

```bash
#!/usr/bin/env bash
# Validates the how: the method documents, the tools, and the root scaffolding.
# Takes no arguments, and must pass with no engagement present.
set -u
cd "$(dirname "$0")/.."
fail=0
for s in tools/check-model-prc.sh tools/check-model-cr.sh tools/check-runner.sh \
         tools/check-transcript-runner.sh tools/check-roles.sh tools/check-enhancements.sh \
         tools/test-vtt-to-passages.sh tools/test-ingestion-report.sh tools/test-check-registers.sh; do
  echo "== $s"; "$s" || fail=1
done
echo "== README"
grep -qF '`transcript-runner.md`' README.md && echo "ok   README row" || { echo "FAIL README row"; fail=1; }
grep -qF '`transcripts/`' README.md && echo "ok   transcripts row" || { echo "FAIL transcripts row"; fail=1; }
grep -qF '`registers/`' README.md && echo "ok   registers row" || { echo "FAIL registers row"; fail=1; }
echo "== em dash scan"
if grep -l -- '—' solution-register-model.md solution-register-runner.md transcript-runner.md \
   roles.md README.md ARCHITECTURE.md CLAUDE.md LOG.md ENHANCEMENTS.md HANDOVER.md 2>/dev/null; then
  echo "FAIL em dash found"; fail=1
else echo "ok   no em dashes"; fi
echo "== handover"
tools/check-handover-shape.sh . || fail=1
[ -x tools/handover-check.sh ] && echo "ok   handover hook executable" || { echo "FAIL handover hook executable"; fail=1; }
exit $fail
```

```bash
chmod +x tools/check-how.sh
```

- [ ] **Step 3: Create `tools/check-engagement.sh`**

```bash
#!/usr/bin/env bash
# Validates one engagement's data and skills.
# Usage: tools/check-engagement.sh [engagement root]   default: .
set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="${1:-.}"
case "$root" in .) p="" ;; *) p="${root%/}/" ;; esac
fail=0
echo "== stakeholders"; "$here/check-stakeholders.sh" "$root" || fail=1
echo "== registers";    "$here/check-registers.sh" "${p}registers" || fail=1
echo "== folders"
for d in transcripts/input transcripts/processed transcripts/claims; do
  [ -f "${p}$d/.gitkeep" ] && echo "ok   $d" || { echo "FAIL $d"; fail=1; }
done
echo "== gitignore"
git check-ignore -q "${p}transcripts/input/x.vtt" 2>/dev/null \
  && { echo "FAIL transcripts/input must not be ignored"; fail=1; } \
  || echo "ok   transcripts/input persisted"
echo "== skills"
for s in ingest-transcript build-registers ingestion-report handover; do
  grep -q "^name: $s$" "${p}.claude/skills/$s/SKILL.md" 2>/dev/null && echo "ok   skill $s" || { echo "FAIL skill $s"; fail=1; }
done
grep -qF 'registers/' "${p}.claude/skills/ingest-transcript/SKILL.md" 2>/dev/null \
  && echo "ok   ingest skill chains the register runner" \
  || { echo "FAIL ingest skill chains the register runner"; fail=1; }
echo "== em dash scan"
if grep -l -- '—' "${p}transcripts/stakeholders.md" "${p}".claude/skills/*/SKILL.md 2>/dev/null; then
  echo "FAIL em dash found"; fail=1
else echo "ok   no em dashes"; fi
echo "== handover"
"$here/check-handover-shape.sh" "$root" || fail=1
exit $fail
```

```bash
chmod +x tools/check-engagement.sh
```

- [ ] **Step 4: Replace `tools/check-all.sh`**

```bash
#!/usr/bin/env bash
# Runs the how checks, then one engagement's checks.
# Usage: tools/check-all.sh [engagement root]   default: .
set -u
here="$(cd "$(dirname "$0")" && pwd)"
fail=0
echo "###### how ######";        "$here/check-how.sh"        || fail=1
echo "###### engagement ######"; "$here/check-engagement.sh" "${1:-.}" || fail=1
exit $fail
```

- [ ] **Step 5: Verify each entry point passes independently**

```bash
tools/check-how.sh >/dev/null;        echo "how exit=$?"
tools/check-engagement.sh >/dev/null; echo "engagement exit=$?"
tools/check-all.sh >/dev/null;        echo "all exit=$?"
```

Expected: all three `exit=0`.

- [ ] **Step 6: Confirm no assertion was lost, which is the point of this task**

Run: `work/tmp/guard.sh`
Expected: `ok   no baseline assertion lost`. The label count rises, because the handover shape is now asserted by both checks while the two roots are the same directory. A rise is fine; a loss is not. If anything is reported lost, it is a real gap in the split and must be added to whichever check owns it.

- [ ] **Step 7: Commit, owner runs**

```bash
git add tools/check-how.sh tools/check-engagement.sh tools/check-all.sh
git commit -m "Split check-all into a how-check and an engagement-check

check-how.sh takes no arguments and validates the method documents, the
tools and the root scaffolding. check-engagement.sh takes an engagement
root defaulting to the working directory. check-all.sh runs both. No
assertion from the 220-assertion baseline is lost.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

Then append to `LOG.md`, kind `change`. **This is the known-good point to return to if phase 2 goes wrong.**

---

## Phase 2: The cutover

**One commit for the whole phase.** There is no intermediate state where the checks pass, because the tools cannot be half re-pathed and the documents cannot be half prefixed. Tasks 8 to 16 each verify locally. Task 17 verifies the whole and hands the owner one commit.

### Task 8: Create the skeleton and move the files

**Files:**
- Create: `ingester/`, `engagements/abb-nokia/`, `engagements/abb-nokia/.claude/`
- Move into `ingester/`: `transcript-runner.md`, `solution-register-runner.md`, `solution-register-model.md`, `roles.md`, `ARCHITECTURE.md`, `ENHANCEMENTS.md`, `LOG.md`, `diagrams/`, `tools/`, `docs/`
- Move into `engagements/abb-nokia/`: `transcripts/`, `registers/`, `work/`, `HANDOVER.md`. `.claude/skills/` does NOT move; it stays at the repository root (spec 3.2).

**Interfaces:**
- Produces: the layout in spec section 3. Later tasks in this phase assume it.

- [ ] **Step 1: Create the two folders**

```bash
mkdir -p ingester engagements/abb-nokia
```

- [ ] **Step 2: Move the how**

```bash
mv transcript-runner.md solution-register-runner.md solution-register-model.md roles.md ingester/
mv ARCHITECTURE.md ENHANCEMENTS.md LOG.md ingester/
mv diagrams tools docs ingester/
```

- [ ] **Step 3: Move the what**

```bash
mv transcripts registers work engagements/abb-nokia/
mv HANDOVER.md engagements/abb-nokia/
mv .claude/skills engagements/abb-nokia/.claude-skills-tmp
mkdir -p engagements/abb-nokia/.claude
mv engagements/abb-nokia/.claude-skills-tmp engagements/abb-nokia/.claude/skills
```

- [ ] **Step 4: Verify nothing was left behind and nothing was lost**

```bash
ls -a | grep -v '^\.$\|^\.\.$\|^\.git$\|^\.obsidian$\|^\.DS_Store$'
echo "--- file count, tracked plus untracked, must match the pre-move count ---"
{ git ls-files; git ls-files --others --exclude-standard; } | grep -v '^\.obsidian' | wc -l
```

Expected from the first command: `CLAUDE.md`, `README.md`, `.gitignore`, `ingester`, `engagements`, and `.claude` if it still holds anything. Nothing else.

- [ ] **Step 5: Verify the how-check still passes from its new home**

```bash
ingester/tools/check-how.sh >/dev/null 2>&1; echo "how exit=$?"
```

Expected: non-zero, and that is correct at this point. `check-how.sh` still does `cd "$(dirname "$0")/.."`, which now lands in `ingester/`, where `README.md` and `CLAUDE.md` are not. Task 9 fixes it. Record the failing labels so Task 9 can confirm it fixed exactly those.

- [ ] **Step 6: No commit yet.** Phase 2 commits once, in Task 17.

---

### Task 9: Re-anchor `check-how.sh` for the new geometry

`check-how.sh` now needs two roots: the ingester, which holds the method documents and tools, and the repository, which holds `README.md`, `CLAUDE.md` and `.gitignore`. The `../` here is inside a tool anchored by `$0`, which is permitted; spec rule 3 forbids `../` in how-*documents*, not in tools.

**Files:**
- Modify: `ingester/tools/check-how.sh`

**Interfaces:**
- Consumes: the layout from Task 8.
- Produces: `ingester/tools/check-how.sh`, still taking no arguments, resolving `$how` and `$repo` separately.

- [ ] **Step 1: Confirm the failure from Task 8 Step 5**

```bash
ingester/tools/check-how.sh 2>&1 | grep '^FAIL'
```

Expected: FAIL lines for the three README rows, because `README.md` is not in `ingester/`.

- [ ] **Step 2: Replace the header and the root-scaffolding block of `check-how.sh`**

Change the top from:

```bash
set -u
cd "$(dirname "$0")/.."
fail=0
```

to:

```bash
set -u
how="$(cd "$(dirname "$0")/.." && pwd)"
repo="$(cd "$how/.." && pwd)"
cd "$how"
fail=0
```

Change the README block from:

```bash
grep -qF '`transcript-runner.md`' README.md && echo "ok   README row" || { echo "FAIL README row"; fail=1; }
grep -qF '`transcripts/`' README.md && echo "ok   transcripts row" || { echo "FAIL transcripts row"; fail=1; }
grep -qF '`registers/`' README.md && echo "ok   registers row" || { echo "FAIL registers row"; fail=1; }
```

to:

```bash
grep -qF '`ingester/`' "$repo/README.md" && echo "ok   README row" || { echo "FAIL README row"; fail=1; }
grep -qF '`engagements/`' "$repo/README.md" && echo "ok   transcripts row" || { echo "FAIL transcripts row"; fail=1; }
grep -qF '`registers/`' "$repo/README.md" && echo "ok   registers row" || { echo "FAIL registers row"; fail=1; }
```

The three labels are kept verbatim so the Task 1 guard does not report them lost. Their content now describes the two-folder shape, which is what Task 16 writes into `README.md`.

Change the em dash scan from:

```bash
if grep -l -- '—' solution-register-model.md solution-register-runner.md transcript-runner.md \
   roles.md README.md ARCHITECTURE.md CLAUDE.md LOG.md ENHANCEMENTS.md HANDOVER.md 2>/dev/null; then
```

to:

```bash
if grep -l -- '—' solution-register-model.md solution-register-runner.md transcript-runner.md \
   roles.md ARCHITECTURE.md CLAUDE.md LOG.md ENHANCEMENTS.md HANDOVER.md \
   "$repo/README.md" "$repo/CLAUDE.md" 2>/dev/null; then
```

- [ ] **Step 3: Verify `check-engagement.sh` needs no change**

```bash
(cd engagements/abb-nokia && ../../ingester/tools/check-engagement.sh >/dev/null 2>&1; echo "engagement exit=$?")
```

Expected: `exit=0`. It takes a root defaulting to the working directory and never uses `$0` to find data, which is why Task 2, 3 and 5 were worth doing first.

- [ ] **Step 4: No commit yet.**

---

### Task 10: Rewrite the 26 how-references with `<HOW>/`

**Files:**
- Modify: `ingester/transcript-runner.md` (11 references)
- Modify: `ingester/solution-register-runner.md` (14 references)
- Modify: `ingester/solution-register-model.md` (1 reference)
- Modify: `ingester/roles.md` (1 reference)

**Interfaces:**
- Produces: how-documents in which every how-file reference carries the `<HOW>/` prefix. Task 14 asserts it.

- [ ] **Step 1: Write the failing test**

Count total how-file references against prefixed ones. They must end equal.

```bash
cd ingester
for d in transcript-runner.md solution-register-runner.md solution-register-model.md roles.md; do
  t=$(grep -oE '(tools/[a-z-]+\.sh|roles\.md|transcript-runner\.md|solution-register-runner\.md|solution-register-model\.md)' "$d" | wc -l | tr -d ' ')
  n=$(grep -oE '<HOW>/(tools/[a-z-]+\.sh|roles\.md|transcript-runner\.md|solution-register-runner\.md|solution-register-model\.md)' "$d" | wc -l | tr -d ' ')
  echo "$d: $n of $t prefixed"
done
cd ..
```

Expected: `11 -> 0 of 11`, `14 -> 0 of 14`, `1 -> 0 of 1`, `1 -> 0 of 1`. Nothing is prefixed yet.

- [ ] **Step 2: Apply the prefix**

Longest names first, so `solution-register-runner.md` is not partially matched, and the guard on `<HOW>/` prevents double-prefixing on a re-run.

```bash
cd ingester
for d in transcript-runner.md solution-register-runner.md solution-register-model.md roles.md; do
  perl -pi -e 's{(?<!<HOW>/)(?<![\w./-])(tools/[a-z-]+\.sh|solution-register-runner\.md|solution-register-model\.md|transcript-runner\.md|roles\.md)}{<HOW>/$1}g' "$d"
done
cd ..
```

- [ ] **Step 3: Verify every reference is prefixed**

Re-run the Step 1 command.

Expected: `11 of 11`, `14 of 14`, `1 of 1`, `1 of 1`.

- [ ] **Step 4: Verify no double prefixes and no stray `../`**

```bash
grep -rn '<HOW>/<HOW>' ingester/ && echo "DOUBLE PREFIX" || echo "ok   no double prefixes"
for d in transcript-runner.md solution-register-runner.md solution-register-model.md roles.md; do
  grep -q '\.\./' "ingester/$d" && echo "FAIL $d contains ../" || echo "ok   $d has no ../"
done
```

Expected: no double prefixes, and no `../` in any of the four.

- [ ] **Step 5: Verify the runner's own command lines read correctly**

```bash
grep -n '<HOW>/tools' ingester/transcript-runner.md ingester/solution-register-runner.md
```

Expected: the parser invocations in the transcript runner and the `check-registers.sh` invocations in the register runner, each now prefixed. Confirm by eye that `<HOW>/tools/check-registers.sh work/03-dryrun` kept its engagement-relative argument unprefixed, because `work/` is engagement data.

- [ ] **Step 6: Bump the version line of all four documents (D9) and no commit yet.**

---

### Task 11: The three CLAUDE.md files

**Files:**
- Create: `ingester/CLAUDE.md`
- Create: `engagements/abb-nokia/CLAUDE.md`
- Modify: `CLAUDE.md` at the repository root

**Interfaces:**
- Produces: `ingester/CLAUDE.md` as the layout authority, containing the string `<HOW>` and the string `../../ingester`. Task 14 asserts both.

- [ ] **Step 1: Write `ingester/CLAUDE.md`**

It must contain the `<HOW>` binding, the engagement-relative path, the rule about which paths resolve where, the commit rule, and the pipeline entry points. It is the only how-file permitted to contain `../`.

Required content, at minimum:

```markdown
# The ingester

Version 1.0, 9 September 2026. Owner: Adam Moyes.

This folder is the how. It holds the method and nothing about any particular
engagement. Read this file before running anything.

## The `<HOW>` binding

`<HOW>` is the ingester root, the folder containing this file. From an
engagement it is `../../ingester`.

`<HOW>` is a documentation placeholder, not a shell variable. Substitute it
when you construct a command. Never pass it to a shell unsubstituted.

This is the only file in the ingester permitted to contain `../`. Every
other how-document writes `<HOW>/` instead, so that exactly one file knows
how deep an engagement sits.

## Which paths resolve where

| Written as | Resolves against | Examples |
|---|---|---|
| `<HOW>/...` | the ingester root | `<HOW>/tools/vtt-to-passages.sh`, `<HOW>/roles.md` |
| a bare relative path | the working directory, always an engagement | `transcripts/claims/`, `registers/`, `work/` |

## Write isolation

No action taken while working in an engagement may write any file outside
that engagement's folder. Reads across the boundary are expected. Writes are
not. `<HOW>/tools/check-isolation.sh <root>` asserts it.

A finding about the method, discovered while working in an engagement, goes
in that engagement's `FINDINGS.md`. An ingester session promotes it into
`<HOW>/ENHANCEMENTS.md` with an id. Ids are issued only here.

## Every commit

Run the check for the folder you are working in, and append one line to that
folder's `LOG.md`.

| Working in | Check | Log |
|---|---|---|
| an engagement | `<HOW>/tools/check-engagement.sh` | that engagement's `LOG.md` |
| the ingester | `<HOW>/tools/check-how.sh` | `<HOW>/LOG.md` |

## The documents

| File | Responsibility |
|---|---|
| `<HOW>/ARCHITECTURE.md` | principles, decisions, the compliance check |
| `<HOW>/solution-register-model.md` | what items are: types, states, fields, relationships |
| `<HOW>/roles.md` | who speaks in a session and what each role may yield |
| `<HOW>/transcript-runner.md` | a WebVTT transcript becomes atomic claims |
| `<HOW>/solution-register-runner.md` | claims become register rows |
| `<HOW>/tools/` | deterministic shell, and the checks over these documents |

## Before any structural change

Read `<HOW>/ARCHITECTURE.md` and run its section 5 compliance check.
```

- [ ] **Step 2: Write `engagements/abb-nokia/CLAUDE.md`**

Thin. Its job is the pointer and this engagement's identity.

```markdown
# Engagement: ABB and Nokia

Version 1.0, 9 September 2026. Owner: Adam Moyes.

This folder is the what. It holds this engagement's transcripts, claims,
registers, stakeholder registry and working state, and nothing about the
method.

**Read `../../ingester/CLAUDE.md` before running anything.** It is the
authority on the layout, on the `<HOW>` binding, and on how to run the
pipeline. Nothing in this file repeats it.

| | |
|---|---|
| Client | Aussie Broadband |
| Vendor | Nokia |
| Phase | Discovery |
| Registers | `registers/` |
| Claims | `transcripts/claims/` |

Nothing done here writes outside this folder. A finding about the method
goes in `FINDINGS.md`, never straight into the ingester.
```

- [ ] **Step 3: Trim the root `CLAUDE.md` to universal rules**

It is auto-loaded from either folder as a parent directory, so it holds only what applies wherever you are working: Australian English, no em dashes, versioned documents, and that the owner runs every git command. Everything about the pipeline, the layout and the commit discipline moves to `ingester/CLAUDE.md`. Remove the sections describing `transcripts/`, `registers/`, `work/`, `tools/check-all.sh`, the handover template and the ARCHITECTURE gate, all of which are now stated in `ingester/CLAUDE.md`.

- [ ] **Step 4: Verify the bindings are present**

```bash
grep -qF '<HOW>' ingester/CLAUDE.md && echo "ok   defines <HOW>" || echo "FAIL defines <HOW>"
grep -qF '../../ingester' ingester/CLAUDE.md && echo "ok   states the binding" || echo "FAIL states the binding"
grep -qF '../../ingester/CLAUDE.md' engagements/abb-nokia/CLAUDE.md && echo "ok   engagement points at the how" || echo "FAIL engagement points at the how"
grep -c -- '—' ingester/CLAUDE.md engagements/abb-nokia/CLAUDE.md CLAUDE.md
```

Expected: three `ok` lines, and `0` em dashes in each file.

- [ ] **Step 5: No commit yet.**

---

### Task 12: Split the governance files and seed the outbox

**Files:**
- Modify: `ingester/LOG.md`
- Create: `engagements/abb-nokia/LOG.md`
- Create: `engagements/abb-nokia/FINDINGS.md`
- Create: `ingester/HANDOVER.md`
- Modify: `ingester/ENHANCEMENTS.md`

**Interfaces:**
- Produces: `FINDINGS.md` with columns `| Id | Title | Observed | State | Enhancement |`. Task 14 asserts the header and that every `promoted` row names an id.

- [ ] **Step 1: Identify the engagement lines in `ingester/LOG.md`**

```bash
grep -n '4efe64d\|f1322ae' ingester/LOG.md
```

Expected: the three T001 lines, being one `change` and two `ruling` entries. Every other line records a method change and stays.

- [ ] **Step 2: Create `engagements/abb-nokia/LOG.md`**

Move those three lines into it under this header, and delete them from `ingester/LOG.md`.

```markdown
# Log: ABB and Nokia

A chronological record of this engagement's ingestions and decisions. One
entry per change worth knowing about later. Newest at the bottom. Append;
never rewrite an entry.

History before the how and what split of 9 September 2026 lives in
`../../ingester/LOG.md`.

Format: `YYYY-MM-DD | commit | kind | what | why`. Kind is `change`,
`decision` or `ruling`.

| Date | Commit | Kind | What | Why |
|---|---|---|---|---|
```

- [ ] **Step 3: Create `engagements/abb-nokia/FINDINGS.md`, seeded from T001**

E14, E15 and E16 were all discovered during the T001 ingestion, which is engagement work. Seeding them gives the mechanism the provenance it would have recorded had it existed.

```markdown
# Findings: ABB and Nokia

Observations about the method, found while working in this engagement. An
engagement cannot write to the ingester, so a finding lands here and an
ingester session promotes it into `../../ingester/ENHANCEMENTS.md` with an
id. Ids are issued only by the ingester.

Format: id, title, what was observed with its evidence, state of `open` or
`promoted`, and the enhancement id once promoted.

| Id | Title | Observed | State | Enhancement |
|---|---|---|---|---|
| F1 | Split claims quote their own clause | Three claims from T001 passage 316 share one 500 character quote that is mostly about a different claim. | promoted | E14 |
| F2 | Trivial context claims inflate the claims file | 384 of 442 T001 claims are context, roughly 87 per cent, many of them backchannels such as "Yeah." and "Correct." | promoted | E15 |
| F3 | Parser leaves HTML entities undecoded | T001 passage 181 carries `S&amp; C tag` into a claim quote verbatim. | promoted | E16 |
```

- [ ] **Step 4: Annotate the three enhancements with their source**

In `ingester/ENHANCEMENTS.md`, add `Source: abb-nokia F1`, `F2` and `F3` to the Why column of E14, E15 and E16 respectively, so the promotion is traceable in both directions.

- [ ] **Step 5: Create `ingester/HANDOVER.md`**

Use the same six-section template the engagement handover uses, so `check-handover-shape.sh` passes on it.

```markdown
# Handover

Updated: 2026-09-09
Last commit: <short hash of the phase 2 commit>

## In flight
Nothing

## Next action
Phase 3 of docs/superpowers/plans/2026-09-09-how-what-split.md: run
/build-registers from engagements/abb-nokia as the cutover smoke test.

## Blocked
Nothing

## Notes for the next session
The how and what split landed. Read ingester/CLAUDE.md first.
```

- [ ] **Step 6: Verify both handovers pass and the outbox is consistent**

```bash
ingester/tools/check-handover-shape.sh ingester
ingester/tools/check-handover-shape.sh engagements/abb-nokia
ingester/tools/check-enhancements.sh ingester/ENHANCEMENTS.md
awk -F'|' '/^\| F[0-9]+ \|/ { gsub(/ /,"",$5); gsub(/ /,"",$6); if ($5=="promoted" && $6 !~ /^E[0-9]+$/) print "FAIL unpromoted id: " $2 }' engagements/abb-nokia/FINDINGS.md
```

Expected: 7 `ok` lines from each handover check, a clean enhancements check, and no FAIL from the awk.

- [ ] **Step 7: No commit yet.**

---

### Task 13: The skills

**Files:**
- Modify: `engagements/abb-nokia/.claude/skills/ingest-transcript/SKILL.md`
- Modify: `engagements/abb-nokia/.claude/skills/build-registers/SKILL.md`
- Modify: `engagements/abb-nokia/.claude/skills/ingestion-report/SKILL.md`
- Modify: `engagements/abb-nokia/.claude/skills/handover/SKILL.md`
- Create: `ingester/.claude/skills/handover/SKILL.md`

**Interfaces:**
- Consumes: the `<HOW>` binding from Task 11.
- Produces: engagement skills that reference how-files as `<HOW>/...` and engagement files bare. D8 still holds: they stay launchers and hold no rules.

- [ ] **Step 1: Write the failing test**

```bash
grep -rn 'solution-register-runner.md\|transcript-runner.md\|solution-register-model.md\|tools/' \
  engagements/abb-nokia/.claude/skills/ | grep -v '<HOW>/' | grep -v 'registers/'
```

Expected: several lines. Each is a how-reference in a skill that has no prefix yet.

- [ ] **Step 2: Prefix the how-references in all four engagement skills**

Leave `registers/`, `transcripts/` and `work/` bare, since those are engagement data. Only machinery and sibling how-documents take the prefix.

```bash
cd engagements/abb-nokia/.claude/skills
for d in ingest-transcript/SKILL.md build-registers/SKILL.md ingestion-report/SKILL.md handover/SKILL.md; do
  perl -pi -e 's{(?<!<HOW>/)(?<![\w./-])(tools/[a-z-]+\.sh|solution-register-runner\.md|solution-register-model\.md|transcript-runner\.md|roles\.md)}{<HOW>/$1}g' "$d"
done
cd ../../../..
```

- [ ] **Step 3: Point the handover skill at the right files**

In `engagements/abb-nokia/.claude/skills/handover/SKILL.md`, the handover it writes is this engagement's, so `HANDOVER.md` and `LOG.md` stay bare, and `<HOW>/tools/handover-check.sh` and `<HOW>/tools/check-engagement.sh` take the prefix. Add a step running `<HOW>/tools/check-isolation.sh .` before the commit, per spec section 6.2.

- [ ] **Step 4: Create `ingester/.claude/skills/handover/SKILL.md`**

A session spent on the method has to hand over too. Same shape as the engagement's, except it runs `check-how.sh` rather than `check-engagement.sh`, writes `ingester/HANDOVER.md` and `ingester/LOG.md`, and adds a step reading the engagement outboxes for findings worth promoting.

- [ ] **Step 5: Verify**

```bash
grep -rn 'solution-register-runner.md\|transcript-runner.md\|solution-register-model.md\|tools/' \
  engagements/abb-nokia/.claude/skills/ | grep -v '<HOW>/' | grep -v 'registers/' \
  && echo "FAIL unprefixed how-refs remain" || echo "ok   all how-refs prefixed"
grep -q '^name: handover$' ingester/.claude/skills/handover/SKILL.md && echo "ok   ingester handover skill" || echo "FAIL ingester handover skill"
(cd engagements/abb-nokia && ../../ingester/tools/check-engagement.sh >/dev/null 2>&1; echo "engagement exit=$?")
```

Expected: `ok` on both greps and `engagement exit=0`.

- [ ] **Step 6: No commit yet.**

---

### Task 14: The new checks

**Files:**
- Create: `ingester/tools/check-how-refs.sh`
- Create: `ingester/tools/check-isolation.sh`
- Create: `ingester/tools/check-findings.sh`
- Modify: `ingester/tools/check-how.sh` (wire in `check-how-refs.sh`, add the independence test)
- Modify: `ingester/tools/check-engagement.sh` (wire in `check-findings.sh` and the static isolation assertion)

**Interfaces:**
- Produces: `check-how-refs.sh [ingester root]`, default the parent of the script's directory. `check-isolation.sh <root>`, root required. `check-findings.sh [engagement root]`, default `.`. All exit 0 on pass, 1 on failure.

- [ ] **Step 1: Create `ingester/tools/check-how-refs.sh`**

```bash
#!/usr/bin/env bash
# Asserts the <HOW> contract over the how-documents (spec section 4).
# Usage: tools/check-how-refs.sh [ingester root]   default: the parent of this script's dir
set -u
how="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
fail=0
docs="transcript-runner.md solution-register-runner.md solution-register-model.md roles.md ARCHITECTURE.md"
pat='(tools/[a-z-]+\.sh|roles\.md|transcript-runner\.md|solution-register-runner\.md|solution-register-model\.md)'
# 1. every how-file reference carries the <HOW>/ prefix
for d in $docs; do
  [ -f "$how/$d" ] || { echo "FAIL $d missing"; fail=1; continue; }
  t=$(grep -oE "$pat" "$how/$d" | wc -l | tr -d ' ')
  n=$(grep -oE "<HOW>/$pat" "$how/$d" | wc -l | tr -d ' ')
  [ "$t" -eq "$n" ] && echo "ok   $d: $n of $t how-refs prefixed" \
    || { echo "FAIL $d: $((t-n)) of $t how-refs unprefixed"; fail=1; }
done
# 2. no double prefix
grep -rq '<HOW>/<HOW>' "$how" 2>/dev/null && { echo "FAIL double <HOW> prefix"; fail=1; } || echo "ok   no double prefixes"
# 3. no how-document contains ../, exempting CLAUDE.md which states the binding
for d in $docs; do
  grep -q '\.\./' "$how/$d" 2>/dev/null && { echo "FAIL $d contains ../"; fail=1; } || echo "ok   $d has no ../"
done
grep -qF '../../ingester' "$how/CLAUDE.md" && echo "ok   CLAUDE.md states the binding" || { echo "FAIL CLAUDE.md states the binding"; fail=1; }
grep -qF '<HOW>' "$how/CLAUDE.md" && echo "ok   CLAUDE.md defines <HOW>" || { echo "FAIL CLAUDE.md defines <HOW>"; fail=1; }
exit $fail
```

- [ ] **Step 2: Create `ingester/tools/check-isolation.sh`**

REDESIGNED against the original plan, following the owner's ruling that each engagement is its own nested git repository (spec 2.1). The originally planned assertion, that no tracked file outside the engagement is modified, is now vacuous: the engagement's git cannot see outside files, so it would pass while proving nothing. What can actually go wrong is the nesting being set up wrongly, so that is what this asserts.

```bash
#!/usr/bin/env bash
# Asserts the engagement is genuinely isolated: its own git repository, ignored by the outer one.
# Write isolation is structural under this arrangement (spec 2.1), so what needs checking is that
# the arrangement is in place, not that writes stayed inside it.
# Usage: tools/check-isolation.sh <engagement root>
# Reads git state only. Never mutates either repository.
set -u
root="${1:?usage: check-isolation.sh <engagement root>}"
fail=0
[ -d "$root" ] || { echo "FAIL no such root: $root"; exit 1; }
abs=$(cd "$root" && pwd)

# 1. The engagement is its own repository, whose toplevel is the engagement root itself.
inner=$(git -C "$root" rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$inner" ]; then
  echo "FAIL $root is not a git repository; run git init inside it"; fail=1
elif [ "$inner" != "$abs" ]; then
  echo "FAIL $root belongs to the repository at $inner, so it is not isolated"; fail=1
else
  echo "ok   engagement is its own repository"
fi

# 2. The outer repository ignores the engagement path.
outer=$(cd "$abs/../.." && git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$outer" ]; then
  echo "FAIL cannot find the outer repository above $root"; fail=1
elif git -C "$outer" check-ignore -q "$abs"; then
  echo "ok   outer repository ignores the engagement"
else
  echo "FAIL outer repository does NOT ignore $abs; engagement data could reach origin"; fail=1
fi

# 3. No file tracked by the outer repository lives under the engagement root.
if [ -n "$outer" ]; then
  rel="${abs#$outer/}"
  leaked=$(git -C "$outer" ls-files -- "$rel" 2>/dev/null || true)
  if [ -n "$leaked" ]; then
    echo "FAIL outer repository tracks files under the engagement:"; echo "$leaked" | sed 's/^/     /'; fail=1
  else
    echo "ok   outer repository tracks nothing under the engagement"
  fi
fi
exit $fail
```

- [ ] **Step 3: Create `ingester/tools/check-findings.sh`**

```bash
#!/usr/bin/env bash
# Shape of one engagement's findings outbox.
# Usage: tools/check-findings.sh [engagement root]   default: .
set -u
root="${1:-.}"
case "$root" in .) f="FINDINGS.md" ;; *) f="${root%/}/FINDINGS.md" ;; esac
fail=0
[ -f "$f" ] || { echo "FAIL findings file $f"; exit 1; }
echo "ok   findings file"
grep -qF '| Id | Title | Observed | State | Enhancement |' "$f" && echo "ok   findings header" || { echo "FAIL findings header"; fail=1; }
dups=$(grep -oE '^\| F[0-9]+ \|' "$f" | sort | uniq -d | tr -d '| ')
[ -z "$dups" ] && echo "ok   finding ids unique" || { echo "FAIL duplicate finding ids: $(echo $dups)"; fail=1; }
bad=$(awk -F'|' '/^\| F[0-9]+ \|/ { s=$5; e=$6; gsub(/ /,"",s); gsub(/ /,"",e);
  if (s != "open" && s != "promoted") { print "bad state on" $2; next }
  if (s == "promoted" && e !~ /^E[0-9]+$/) print "promoted without an enhancement id on" $2 }' "$f")
[ -z "$bad" ] && echo "ok   every promoted finding names an enhancement" || { echo "FAIL $bad"; fail=1; }
exit $fail
```

- [ ] **Step 4: `chmod` and wire the three tools in**

```bash
chmod +x ingester/tools/check-how-refs.sh ingester/tools/check-isolation.sh ingester/tools/check-findings.sh
```

In `check-how.sh`, add `tools/check-how-refs.sh` to the `for s in ...` loop.

In `check-engagement.sh`, add before the handover block:

```bash
echo "== findings"; "$here/check-findings.sh" "$root" || fail=1
echo "== write isolation, static"
if grep -rn '\.\./' "${p}.claude/skills/" "${p}CLAUDE.md" 2>/dev/null | grep -v '\.\./\.\./ingester/CLAUDE\.md' | grep -q .; then
  echo "FAIL an engagement file names a path outside the engagement"; fail=1
else
  echo "ok   no engagement file names a path outside the engagement"
fi
```

The one permitted `../` in an engagement is the pointer to `../../ingester/CLAUDE.md` in its own CLAUDE.md.

- [ ] **Step 5: Verify each new check passes, and prove each one can fail**

```bash
ingester/tools/check-how-refs.sh
ingester/tools/check-findings.sh engagements/abb-nokia
ingester/tools/check-isolation.sh engagements/abb-nokia; echo "isolation exit=$?"
```

Expected: the first two all `ok`. The third reports FAIL right now, correctly, because Task 16 has not yet gitignored `engagements/` and the owner has not yet run `git init` inside the engagement. Its three assertions are the to-do list for Task 16; all three turn `ok` once that task and the owner's `git init` are done.

Prove `check-how-refs.sh` catches an unprefixed reference:

```bash
cp ingester/roles.md work/tmp/roles.bak
printf '\nSee tools/check-stakeholders.sh for the registry check.\n' >> ingester/roles.md
ingester/tools/check-how-refs.sh | grep 'roles.md:'
cp work/tmp/roles.bak ingester/roles.md && rm work/tmp/roles.bak
ingester/tools/check-how-refs.sh | grep 'roles.md:'
```

Expected: a FAIL line first, then an `ok` line after the restore.

- [ ] **Step 6: Add the independence test to `check-how.sh`**

Append before `exit $fail`:

The copied tree runs `check-how.sh` again, so without a guard this recurses forever. `CHECK_HOW_INNER` is that guard: the outer run sets it for the inner invocation, and the inner run sees it set and skips the block.

```bash
echo "== independence"
if [ -n "${CHECK_HOW_INNER:-}" ]; then
  echo "ok   how-check passes with no engagement present (inner run, not re-entered)"
else
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/checkhow.XXXXXX")
  mkdir -p "$tmp/ingester"
  cp -R "$how/." "$tmp/ingester/"
  cp "$repo/README.md" "$repo/CLAUDE.md" "$tmp/" 2>/dev/null || true
  if (cd "$tmp" && CHECK_HOW_INNER=1 ingester/tools/check-how.sh >/dev/null 2>&1); then
    echo "ok   how-check passes with no engagement present"
  else
    echo "FAIL how-check needs an engagement to pass"
    echo "     failing labels from the engagement-free tree:"
    (cd "$tmp" && CHECK_HOW_INNER=1 ingester/tools/check-how.sh 2>&1 | grep '^FAIL' | sed 's/^/       /')
    fail=1
  fi
  rm -rf "$tmp"
fi
```

Note that the inner run prints the same label as the outer one, so the Task 1 guard sees no difference either way.

- [ ] **Step 7: Verify the independence test**

```bash
time ingester/tools/check-how.sh 2>&1 | tail -5
```

Expected: `ok   how-check passes with no engagement present`, and the command terminates in seconds rather than recursing.

- [ ] **Step 8: No commit yet.**

---

### Task 15: `ARCHITECTURE.md` to version 1.11

**Files:**
- Modify: `ingester/ARCHITECTURE.md`

**Interfaces:**
- Consumes: nothing. Documentation only.
- Produces: an architecture document whose section 1, P7, D11 and new D12 describe the split. `check-how.sh`'s em dash scan and `check-how-refs.sh` both cover it.

- [ ] **Step 1: Bump the version line**

`Version 1.10` becomes `Version 1.11, 9 September 2026. Owner: Adam Moyes.`

- [ ] **Step 2: Amend P7's wording**

P7 is titled "Separate the ingester from the lifecycle" and uses "ingester" to mean the transcript runner. The `ingester/` folder holds the model and both runners, so the word would carry two meanings. Replace "ingester" with "transcript runner" in the title and the body. The substance is unchanged: the model can still be used without the transcript runner, and the only coupling is still the claim record's class and relation vocabulary.

- [ ] **Step 3: Rewrite the section 1 layer table**

The Model, Register runner, Transcript runner and Tools rows name `<HOW>/` paths. The Skills, Data, Registers and Working state rows name engagement-relative paths. Add a sentence saying the repository holds one ingester and any number of engagements.

- [ ] **Step 4: Reword D11**

Its phrase "`registers/` in this repository" becomes "`registers/` in the engagement", since one repository now holds several.

- [ ] **Step 5: Add D12**

```markdown
### D12. The method and the engagements are separate folders, and engagements never write outward
Added 9 September 2026 (version 1.11). `ingester/` holds the method: the model, `roles.md`, both runners, the tools and this document. `engagements/<name>/` holds one engagement's transcripts, claims, registers, stakeholder registry, working state and skills. Claude runs with an engagement as the working directory, so a bare relative path in a how-document resolves against the engagement, and a reference to machinery carries the `<HOW>/` prefix bound in `ingester/CLAUDE.md`. `ingester/CLAUDE.md` is the only how-file permitted to contain `../`, so exactly one file knows how deep an engagement sits.

No action taken while working in an engagement may write any file outside that engagement's folder. Reads across the boundary are expected. This is structural rather than merely a rule: `engagements/` is gitignored in this repository and each engagement is its own nested git repository, so from inside an engagement git cannot see, stage or commit anything outside it. That is also what lets this repository be pushed carrying only the method, since nothing private is reachable from it. Each engagement keeps its own history, so P11 still holds.

Danger, accepted knowingly: `git clean -fdx` at this repository's root deletes an ignored engagement, its data and its `.git`, because `-x` targets ignored paths. Use `git clean -fd` without `-x`, and give an engagement's repository a remote or a backup.

A finding about the method, discovered while working in an engagement, goes in that engagement's `FINDINGS.md`, and an ingester session promotes it into `ENHANCEMENTS.md` with an id; ids are issued only by the ingester, so two engagements cannot collide. Consequence: two people can work on the method and on an engagement at once, and the method can be read by a second engagement without being copied.
```

- [ ] **Step 6: Verify**

```bash
grep -n 'Version 1.11' ingester/ARCHITECTURE.md
grep -c 'ingester' ingester/ARCHITECTURE.md
grep -n '### D12' ingester/ARCHITECTURE.md
grep -c -- '—' ingester/ARCHITECTURE.md
ingester/tools/check-how-refs.sh | grep ARCHITECTURE
```

Expected: the version line, a D12 heading, `0` em dashes, and `ok` from the refs check on ARCHITECTURE.md.

- [ ] **Step 7: Nothing goes under section 6 Deviations.** Every conflict was resolved by amending the principle or decision, not by overriding it. Leave it reading `None recorded`.

- [ ] **Step 8: No commit yet.**

---

### Task 16: `.gitignore` files and the README

**Files:**
- Modify: `.gitignore` at the repository root
- Create: `engagements/abb-nokia/.gitignore`
- Modify: `README.md` at the repository root

**Interfaces:**
- Produces: a README containing the literal strings `` `ingester/` ``, `` `engagements/` `` and `` `registers/` ``, which are the three labels `check-how.sh` asserts after Task 9.

- [ ] **Step 1: Update the root `.gitignore`**

```
.DS_Store
.superpowers/
.obsidian/
```

The `work/**/tmp/` line moves to the engagement, since `work/` is engagement data now.

- [ ] **Step 2: Create `engagements/abb-nokia/.gitignore`**

```
work/**/tmp/
```

- [ ] **Step 3: Verify scratch is still ignored and inputs are still persisted**

```bash
mkdir -p engagements/abb-nokia/work/tmp && touch engagements/abb-nokia/work/tmp/probe
git check-ignore -v engagements/abb-nokia/work/tmp/probe && echo "ok   scratch ignored" || echo "FAIL scratch not ignored"
rm -f engagements/abb-nokia/work/tmp/probe
git check-ignore -q engagements/abb-nokia/transcripts/input/x.vtt && echo "FAIL input ignored" || echo "ok   input persisted"
```

Expected: `ok   scratch ignored` and `ok   input persisted`.

- [ ] **Step 4: Rewrite `README.md` for the two-folder shape**

It must contain `` `ingester/` ``, `` `engagements/` `` and `` `registers/` ``, describe the split in a sentence or two, state that a session runs from an engagement, and point at `ingester/CLAUDE.md` as the place to start.

- [ ] **Step 5: Verify**

```bash
for s in '`ingester/`' '`engagements/`' '`registers/`'; do
  grep -qF "$s" README.md && echo "ok   README mentions $s" || echo "FAIL README mentions $s"
done
grep -c -- '—' README.md
```

Expected: three `ok` lines and `0` em dashes.

- [ ] **Step 6: No commit yet.**

---

### Task 17: Verify the whole cutover and commit once

**Files:**
- Create: `engagements/abb-nokia/work/tmp/now-labels.txt` (gitignored scratch)

Verification and handoff otherwise. No tracked file changes in this task.

- [ ] **Step 1: Run the how-check**

```bash
ingester/tools/check-how.sh; echo "how exit=$?"
```

Expected: `exit=0`, including `ok   how-check passes with no engagement present`.

- [ ] **Step 2: Run the engagement check from the engagement**

```bash
(cd engagements/abb-nokia && ../../ingester/tools/check-engagement.sh; echo "engagement exit=$?")
```

Expected: `exit=0`.

- [ ] **Step 3: Run the combined check from the engagement**

```bash
(cd engagements/abb-nokia && ../../ingester/tools/check-all.sh; echo "all exit=$?")
```

Expected: `exit=0`.

- [ ] **Step 4: Confirm no baseline assertion was lost**

```bash
(cd engagements/abb-nokia && ../../ingester/tools/check-all.sh 2>&1) | grep '^ok' | sed 's/^ok  *//' | sort -u > engagements/abb-nokia/work/tmp/now-labels.txt
comm -23 engagements/abb-nokia/work/tmp/baseline-labels.txt engagements/abb-nokia/work/tmp/now-labels.txt
```

Expected: no output. Every one of the 219 baseline labels still appears. Any line printed is a lost assertion and a P10 violation that must be fixed before the commit.

- [ ] **Step 5: Confirm nothing was lost from the tree**

```bash
{ git ls-files; git ls-files --others --exclude-standard; } | grep -v '^\.obsidian' | wc -l
git status --short | grep '^ D' || echo "ok   no tracked deletions outside renames"
```

Expected: a file count at or above the pre-move count, and every `D` line paired with a matching new path. Renames appear as a delete plus an add until the owner stages them.

- [ ] **Step 6: Verify the runners' own command lines resolve**

Pick the parser invocation out of the transcript runner and run it for real, substituting `<HOW>`:

```bash
(cd engagements/abb-nokia && ../../ingester/tools/vtt-to-passages.sh \
   transcripts/processed/T001-ABB-NokiaTechnicalSyncUp-2026-09-08.vtt | tail -1)
```

Expected: the trailing `<!-- cues: N passages: M last: ... -->` comment, with 417 passages, matching the T001 audit row.

- [ ] **Step 7: Commit, owner runs**

```bash
git add -A
git commit -m "Split the repository into the how and the what (D12)

ingester/ holds the method: the model, roles.md, both runners, the tools
and ARCHITECTURE.md. engagements/abb-nokia/ holds the transcripts, claims,
registers, stakeholder registry, working state and skills. A session runs
from an engagement, so the roughly 78 data-path references resolve
unchanged; the 26 references to machinery carry a <HOW>/ prefix bound in
ingester/CLAUDE.md, the only how-file permitted to contain ../.

No action in an engagement writes outside its folder. Findings about the
method go to engagements/<n>/FINDINGS.md and an ingester session promotes
them into ENHANCEMENTS.md, so ids have a single issuer.

ARCHITECTURE 1.11: P7 reworded to say transcript runner rather than
ingester, section 1 layer table rewritten, D11 reworded, D12 added.
New checks: check-how-refs.sh, check-isolation.sh, check-findings.sh, the
independence test, and unique enhancement ids. All 219 baseline assertion
labels retained.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

Then append to `ingester/LOG.md`: one `change` line for the split and one `decision` line for D12. Fill the `Last commit` line of `ingester/HANDOVER.md` with the resulting hash.

---

## Phase 3: Smoke test

### Task 18: Run the register build from the engagement

This is the task that was outstanding when the design began, and it exercises everything the split touches: `<HOW>` resolution, engagement-relative data paths, the register runner reading `transcripts/claims/`, and `check-registers.sh` against both a dry run and the real target.

**Files:**
- Modify: `engagements/abb-nokia/registers/*.md`, `engagements/abb-nokia/work/state.md` (written by the register runner)

- [ ] **Step 1: Confirm the precondition the skill checks**

```bash
cd engagements/abb-nokia
git status --short | head
../../ingester/tools/check-all.sh >/dev/null; echo "exit=$?"
```

Expected: a clean tree and `exit=0`.

- [ ] **Step 2: Run the skill**

From `engagements/abb-nokia`, invoke `/build-registers`. Follow the register runner's checkpoint protocol: stop at every checkpoint and wait for approval. Do not touch `registers/` before Checkpoint 3a is approved.

- [ ] **Step 3: Verify `<HOW>` resolved correctly at every invocation**

While the run proceeds, confirm that no command was constructed with a literal unsubstituted `<HOW>`, and that `check-registers.sh` was found and run at Phase 3a on the dry run.

- [ ] **Step 4: Verify isolation held**

```bash
../../ingester/tools/check-isolation.sh .
```

Expected: `ok   no writes outside engagements/abb-nokia`. A register build must not have touched the ingester. This is the first real test of the invariant.

- [ ] **Step 5: Verify the registers and the checks**

```bash
../../ingester/tools/check-engagement.sh; echo "exit=$?"
```

Expected: `exit=0`.

- [ ] **Step 6: Commit, owner runs**

The register runner's own Phase 5 handover states what to commit. Append one `change` line to `engagements/abb-nokia/LOG.md` recording the build and the fact that it was the cutover smoke test.

---

## Self-review

**Spec coverage.** Section 2 invariant, Tasks 14 and 18. Section 3 layout, Task 8. Section 3.1 the three CLAUDE.md files, Task 11. Section 4 contract and 4.1 placeholder, Tasks 10, 11, 14. Section 4.2 the 26 references, Task 10. Section 5 tool changes, Tasks 2, 3, 4. Section 6 entry points, Task 7. Section 6.1 assertion mapping, Task 7 with the guard from Task 1. Section 6.2 new assertions, Task 14. Section 7 governance, Tasks 11, 12, 16. Section 7.1 outbox, Task 12. Section 7.2 log split, Task 12. Section 8 ARCHITECTURE, Task 15. Section 9 migration, the phase structure. Section 10 compliance check, recorded in the spec and cited in the Task 17 commit message.

**Known gaps, deliberate.** The spec's open question about the engagement folder name is resolved in this plan as `abb-nokia`. If the owner prefers another name, change it in Task 8 Step 1 and Step 3 and everywhere `abb-nokia` appears; nothing else depends on it.

**Interface consistency.** `[root]` defaults to `.` in `check-stakeholders.sh`, `check-engagement.sh`, `check-handover-shape.sh`, `check-findings.sh` and `handover-check.sh`. `check-isolation.sh` requires its root, because a silent default to the whole repository would make it pass vacuously. `check-registers.sh` alone takes a registers directory rather than an engagement root, which is deliberate and preserves the register runner's existing `work/03-dryrun` call.
