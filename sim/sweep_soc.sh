#!/bin/bash
# Sweep: seeds 1-100 x modes 0-3 for each firmware testbench (simulation only).
# Counts PASSED/FAILED per testbench and the done_cycle range.
cd "$(dirname "$0")" || exit 2
RTL="../rtl/soc_mini.v ../rtl/picorv32.v ../rtl/accel_mmio.v ../rtl/systolic_os_4x4.v ../rtl/pe_os.v"
OUT=build_sweep
mkdir -p $OUT
: > $OUT/summary.txt
: > $OUT/failures.txt
for t in tb_soc_c tb_soc_swmul tb_soc_opt tb_soc_sw tb_soc_fit; do
  extra=""
  [ "$t" = "tb_soc_fit" ] && extra="../rtl/soc_fit.v"
  if ! iverilog -g2009 -o $OUT/$t $t.v $RTL $extra; then
    echo "$t: COMPILE FAILED" | tee -a $OUT/summary.txt
    continue
  fi
  total=0; pass=0; fail=0; dmin=999999999; dmax=0
  for mode in 0 1 2 3; do
    for seed in $(seq 1 100); do
      total=$((total+1))
      out=$(vvp $OUT/$t +seed=$seed +mode=$mode 2>&1)
      line=$(echo "$out" | grep -E "PASSED|FAILED" | tail -1)
      if echo "$line" | grep -q "PASSED"; then
        pass=$((pass+1))
      else
        fail=$((fail+1))
        echo "$t seed=$seed mode=$mode: ${line:-no result line}" >> $OUT/failures.txt
      fi
      d=$(echo "$out" | grep -o "done_cycle=[0-9]*" | tail -1 | cut -d= -f2)
      if [ -z "$d" ] || [ "$d" -le 0 ]; then
        fail=$((fail+1)); pass=$((pass-1))
        echo "$t seed=$seed mode=$mode: no done_cycle" >> $OUT/failures.txt
      else
        [ "$d" -lt "$dmin" ] && dmin=$d
        [ "$d" -gt "$dmax" ] && dmax=$d
      fi
    done
  done
  echo "$t: runs=$total passed=$pass failed=$fail done_cycle min=$dmin max=$dmax" | tee -a $OUT/summary.txt
done
echo "SWEEP COMPLETE" | tee -a $OUT/summary.txt
