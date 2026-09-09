#!/usr/bin/env bash
# Report on transcript ingestion effectiveness by session and by model.
# Usage: tools/ingestion-report.sh [state.md] [claims dir]
# Defaults: work/transcripts/state.md and transcripts/claims
# Reads the session and Audit tables from state.md and the claims JSON files.
# Output is markdown on stdout. Exit 2 if the state file is missing.
set -eu
state="${1:-work/transcripts/state.md}"
claims="${2:-transcripts/claims}"
if [ ! -f "$state" ]; then
  echo "error: state file not found: $state" >&2
  exit 2
fi

pct() { awk -v n="$1" -v d="$2" 'BEGIN { if (d == 0) printf "n/a"; else printf "%.1f%%", 100 * n / d }'; }

echo "# Ingestion report"
echo
echo "Generated $(date +%Y-%m-%d) from $state and $claims."
echo
echo "## Sessions"
echo
echo "| Session | File | Meeting date | Stage | Status | Model | Mode |"
echo "|---|---|---|---|---|---|---|"
grep -E '^\| T[0-9]{3} \|' "$state" | awk -F'|' 'NF >= 9 && $5 ~ /T[0-4]/ { printf "|%s|%s|%s|%s|%s|%s|%s|\n", $2, $3, $4, $5, $6, $7, $8 }'
echo

echo "## Audit rows"
echo
echo "| Session | Stage | Model | Mode | Runner | Date | Passages | Claims | Questions raised | Class changed by human |"
echo "|---|---|---|---|---|---|---|---|---|---|"
audit=$(awk '/^## Audit/ { on = 1; next } /^## / { on = 0 } on && /^\| T[0-9][0-9][0-9] \|/' "$state")
printf '%s\n' "$audit"
echo

echo "## By model"
echo
echo "Change rate is classes changed by the human divided by questions raised. A lower rate means the model's proposed classes survived review more often. Questions per passage shows how much the model asked. Rows are per model, mode and runner document version, so an edit to the runner document shows as a new row to compare against the old one."
echo
echo "| Model | Mode | Runner | Sessions | Passages | Questions raised | Class changed by human | Change rate | Questions per 100 passages |"
echo "|---|---|---|---|---|---|---|---|---|"
printf '%s\n' "$audit" | awk -F'|' '
{
  gsub(/^ +| +$/, "", $4); gsub(/^ +| +$/, "", $5); gsub(/^ +| +$/, "", $6); gsub(/^ +| +$/, "", $2)
  key = $4 "|" $5 "|" $6
  if (!(key in seen)) { order[++n] = key; seen[key] = 1 }
  sess[key, $2] = 1
  if ($3 ~ /T2/) pass[key] += $8
  q[key] += $10; ch[key] += $11
}
END {
  for (i = 1; i <= n; i++) {
    k = order[i]; split(k, m, "|")
    s = 0; for (x in sess) { split(x, y, SUBSEP); if (y[1] == k) s++ }
    rate = (q[k] > 0) ? sprintf("%.1f%%", 100 * ch[k] / q[k]) : "n/a"
    per = (pass[k] > 0) ? sprintf("%.1f", 100 * q[k] / pass[k]) : "n/a"
    printf "| %s | %s | %s | %d | %d | %d | %d | %s | %s |\n", m[1], m[2], m[3], s, pass[k], q[k], ch[k], rate, per
  }
}'
echo

echo "## Claims by class"
echo
echo "Inferred share is the fraction of written claims the runner marked inferred before the human answered; it shows how often the model asked rather than asserted."
echo
echo "| Session | Model | Mode | Claims | current | current-not-needed | legacy | system | need | decision | limitation | risk | open-item | context | Inferred share |"
echo "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"
for f in "$claims"/T*.json; do
  [ -f "$f" ] || continue
  sid=$(basename "$f" .json)
  total=$(grep -c '"id": "T' "$f" || true)
  model=$(grep -o '"runner_model": "[^"]*"' "$f" | head -1 | cut -d'"' -f4)
  mode=$(grep -o '"runner_mode": "[^"]*"' "$f" | head -1 | cut -d'"' -f4)
  inferred=$(grep -c '"confidence": "inferred"' "$f" || true)
  row="| $sid | ${model:-unknown} | ${mode:-unknown} | $total |"
  for c in current current-not-needed legacy system need decision limitation risk open-item context; do
    n=$(grep -c "\"class\": \"$c\"" "$f" || true)
    row="$row $n |"
  done
  row="$row $(pct "$inferred" "$total") |"
  echo "$row"
done
echo
