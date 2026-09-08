#!/usr/bin/env bash
# Parse a WebVTT transcript into numbered passages.
# Usage: tools/vtt-to-passages.sh <file.vtt> [gap_seconds]
# Consecutive cues from the same speaker with a gap of gap_seconds or less merge into one passage.
# Speaker is read from <v Name> tags or a leading "Name: " and is Unattributed otherwise.
# Output ends with: <!-- cues: N passages: M last: <start of last cue> -->
set -eu
f="${1:?usage: vtt-to-passages.sh <file.vtt> [gap_seconds]}"
gap="${2:-5}"
if ! head -c 9 "$f" | sed '1s/^\xEF\xBB\xBF//' | grep -q '^WEBVTT'; then
  echo "error: $f does not start with WEBVTT" >&2
  exit 2
fi
sed '1s/^\xEF\xBB\xBF//' "$f" | tr -d '\r' | awk -v gap="$gap" '
function tosec(t,   a, n) {
  gsub(/,/, ".", t)
  n = split(t, a, ":")
  if (n == 3) return a[1] * 3600 + a[2] * 60 + a[3]
  if (n == 2) return a[1] * 60 + a[2]
  return 0
}
function normtime(t,   a, n) {
  n = split(t, a, ":")
  if (n == 2) return "00:" t
  return t
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
!inbody && /^NOTE/ { skipnote = 1; next }
/^[[:space:]]*$/ { skipnote = 0; inbody = 0; next }
skipnote { next }
/-->/ {
  ncue++
  split($0, p, " --> ")
  cs = tosec(p[1])
  split(p[2], q, " ")
  ce = tosec(q[1])
  rawstart = normtime(p[1])
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
  } else if (match(line, /^[^: <>][^:<>]*: /)) {
    spk = substr(line, 1, RLENGTH - 2)
    line = substr(line, RLENGTH + 1)
  }
  sub(/<\/v>[[:space:]]*$/, "", line)
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
