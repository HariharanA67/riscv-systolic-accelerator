#!/bin/bash
# Runs every family program; fails loudly on any discrepancy.
cd "$(dirname "$0")" || exit 2
EXPECTED_PROGS=30
total=0; bad=0; n=0
for fin in final_addr_*.txt; do
  case "$fin" in final_addr_isa*) continue ;; esac
  tag=${fin#final_addr_}; tag=${tag%.txt}
  n=$((n+1))
  want=$(wc -l < "expect_$tag.txt")
  out=$(vvp tb_isa_family +hex=prog_$tag.hex +exp=expect_$tag.txt +fin=$fin)
  line=$(echo "$out" | grep -E "^FAMILY ")
  if [ -z "$line" ] || echo "$line" | grep -q FAILED; then
    echo "BAD  $tag: no valid result line: $line"; bad=$((bad+1)); continue
  fi
  checks=$(echo "$line" | awk '{print $3}')
  wrong=$(echo "$line" | awk '{print $5}')
  total=$((total+checks))
  if [ "$wrong" != "0" ] || [ "$checks" != "$want" ]; then
    echo "BAD  $tag: checks=$checks expected_lines=$want wrong=$wrong"; bad=$((bad+1))
  fi
done
echo "programs=$n (expected $EXPECTED_PROGS) total_checks=$total bad=$bad"
if [ "$bad" -eq 0 ] && [ "$n" -eq "$EXPECTED_PROGS" ]; then
  echo "RESULT: ALL FAMILY CHECKS PASSED"
else
  echo "RESULT: FAILED"; exit 1
fi
