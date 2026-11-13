#!/bin/bash
# tb_soc_sw sweep: seeds 1-100 x modes 0-3. Each run is recorded once in results.csv.
# Re-running resumes: runs already in results.csv are skipped.
cd "$(dirname "$0")" || exit 2
T=tb_soc_sw
OUT=build_sweep_sw
mkdir -p $OUT
RES=$OUT/results.csv
touch $RES
iverilog -g2009 -o $OUT/$T $T.v ../rtl/soc_mini.v ../rtl/picorv32.v ../rtl/accel_mmio.v ../rtl/systolic_os_4x4.v ../rtl/pe_os.v || exit 1
for mode in 0 1 2 3; do
  for seed in $(seq 1 100); do
    grep -q "^$seed,$mode," $RES && continue
    out=$(vvp $OUT/$T +seed=$seed +mode=$mode 2>&1)
    d=$(echo "$out" | grep -o "done_cycle=[0-9]*" | tail -1 | cut -d= -f2)
    if echo "$out" | grep -q "SW FIRMWARE PASSED" && [ -n "$d" ] && [ "$d" -gt 0 ]; then
      st=PASS
    else
      st=FAIL
    fi
    echo "$seed,$mode,$st,${d:-0}" >> $RES
  done
done
total=$(wc -l < $RES)
pass=$(grep -c ",PASS," $RES)
fail=$(grep -c ",FAIL," $RES)
dmin=$(grep ",PASS," $RES | cut -d, -f4 | sort -n | head -1)
dmax=$(grep ",PASS," $RES | cut -d, -f4 | sort -n | tail -1)
echo "$T: runs=$total passed=$pass failed=$fail done_cycle min=$dmin max=$dmax" | tee $OUT/summary.txt
echo "SWEEP COMPLETE"
