#!/usr/bin/env bash
# Integrity checks over the local registers (model section 9, the deterministic subset).
# Usage: tools/check-registers.sh [registers dir]   default: registers/
set -u
dir="${1:-registers}"
model="$(dirname "$0")/../solution-register-model.md"
fail=0
ok()   { echo "ok   $1"; }
bad()  { echo "FAIL $1"; fail=1; }
warn() { echo "warn $1"; }

# register name -> file, prefix, allowed statuses
regs="Requirements:requirements.md:REQ:Draft,Agreed,Designed,Delivered,Verified,Deferred,Withdrawn
Decisions:decisions.md:DEC:Proposed,Accepted,Superseded,Rejected
Limitations:limitations.md:LIM:Identified,Under assessment,Accepted,Change requested,Resolved
Risks:risks.md:RSK:Identified,Mitigating,Realised,Retired
Open items:open-items.md:OI:Open,In progress,Blocked,Closed
Change requests:change-requests.md:CR:Proposed,Options,For approval,Approved,Submitted,Deferred,Delivered,Withdrawn,Rejected
Processes:processes.md:PRC:Draft,Confirmed,Superseded,Retired
Systems:systems.md:SYS:Draft,Confirmed,Superseded,Retired"

# rows of a register file: table body lines after the header and separator
rows() { awk 'BEGIN{h=0} /^\|/{ if(h==0){h=1;next} if(h==1){h=2;next} print }' "$1"; }
header() { awk '/^\|/{print; exit}' "$1"; }
col() { # col <file> <column name> -> 1-based index, 0 if absent
  header "$1" | awk -F'|' -v n="$2" '{for(i=2;i<NF;i++){gsub(/^ +| +$/,"",$i); if($i==n){print i-1; exit}} print 0}'
}
field() { echo "$1" | awk -F'|' -v i="$2" '{v=$(i+1); gsub(/^ +| +$/,"",v); print v}'
}

# I0 headers match model section 7
while IFS=: read -r name file prefix statuses; do
  f="$dir/$file"
  [ -f "$f" ] || { bad "$file missing"; continue; }
  expected=$(grep -F "| $name | ID, " "$model" | head -1 | awk -F'|' '{print $3}' | sed 's/^ *//; s/ *$//')
  got=$(header "$f" | sed 's/^| *//; s/ *|$//; s/ *| */, /g')
  [ "$got" = "$expected" ] && ok "$file columns match model" || bad "$file columns differ from model: got [$got]"
done <<< "$regs"

# collect ids
ids=$(while IFS=: read -r name file prefix statuses; do f="$dir/$file"; [ -f "$f" ] && rows "$f" | awk -F'|' '{v=$2; gsub(/^ +| +$/,"",v); print v}'; done <<< "$regs")
# I1 unique ids
dups=$(printf "%s\n" "$ids" | grep -v '^$' | sort | uniq -d)
[ -z "$dups" ] && ok "I1 ids unique" || bad "I1 duplicate ids: $(echo $dups)"

tmp=$(mktemp "${TMPDIR:-/tmp}/check-registers.XXXXXX")
while IFS=: read -r name file prefix statuses; do
  f="$dir/$file"; [ -f "$f" ] || continue
  sc=$(col "$f" Status); lc=$(col "$f" Links)
  rows "$f" | while IFS= read -r row; do
    id=$(field "$row" 1); st=$(field "$row" "$sc"); links=$(field "$row" "$lc")
    case "$id" in "$prefix"-[0-9][0-9][0-9]*) ;; *) bad "I1 $file: id [$id] does not match $prefix-nnn";; esac
    printf ",%s," "$statuses" | grep -qF ",$st," || bad "I2 $id: status [$st] not valid for $name"
    for ref in $(echo "$links" | grep -oE '(REQ|DEC|LIM|RSK|OI|CR|PRC|SYS)-[0-9]{3}'); do
      printf "%s\n" "$ids" | grep -qx "$ref" || bad "I6 $id: link target $ref does not exist"
    done
    if [ "$prefix" = PRC ]; then
      steps=$(field "$row" "$(col "$f" Steps)")
      echo "$steps" | grep -oE '\[Retain: [^]]*\]' | while IFS= read -r r; do
        case "$r" in "[Retain: Yes"*|"[Retain: Unknown"*) ;; "[Retain: No;"*) ;; "[Retain: No"*) bad "I17 $id: Retain: No without a reason";; *) bad "I17 $id: bad Retain value $r";; esac
      done
      n=$(echo "$steps" | grep -oE '(^|<br>)[0-9]+\. ' | wc -l | tr -d ' '); m=$(echo "$steps" | grep -oE '\[Retain:' | wc -l | tr -d ' ')
      [ "$n" = "$m" ] || bad "I17 $id: $n steps but $m Retain markers"
    fi
    if [ "$prefix" = SYS ]; then
      fate=$(field "$row" "$(col "$f" Fate)")
      printf ",Replaced,Retained,Integrated,Unknown," | grep -qF ",$fate," || bad "I19 $id: Fate [$fate] invalid"
      facts=$(field "$row" "$(col "$f" Facts)")
      n=$(echo "$facts" | grep -oE '(^|<br>)[0-9]+\. ' | wc -l | tr -d ' '); m=$(echo "$facts" | grep -oE '\[Stated by: [^]]+\]' | wc -l | tr -d ' ')
      [ "$n" = "$m" ] || bad "I19 $id: $n facts but $m Stated by markers"
    fi
  done
done <<< "$regs" > "$tmp"
cat "$tmp"; grep -q '^FAIL' "$tmp" && fail=1
rm -f "$tmp"
[ $fail -eq 0 ] && ok "registers integrity" || bad "registers integrity"
exit $fail
