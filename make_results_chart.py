import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# Values from simulation runs in this repo (seed 7 unless noted).
# Fixed-count firmwares: same count across all 100 seeds and extreme modes.
# Shift-and-add: range across 100 seeds (mode 0) plus extreme modes 1-3.
labels = ["Accelerator\ncompiled C", "Accelerator\noptimized C",
          "Software\nhardware MUL", "Software\nshift-and-add"]
cycles = [1512, 1327, 5382, 25838]
sw_lo, sw_hi = 22103, 32238

fig, ax = plt.subplots(figsize=(8, 5), dpi=150)
colors = ["#2e7d32", "#1b5e20", "#78909c", "#455a64"]
bars = ax.bar(labels, cycles, color=colors)
ax.errorbar(3, 25838, yerr=[[25838 - sw_lo], [sw_hi - 25838]],
            fmt="none", ecolor="black", capsize=6)

for b, c in zip(bars, cycles):
    ax.text(b.get_x() + b.get_width() / 2, c + 600, f"{c:,}",
            ha="center", va="bottom", fontsize=10)

ax.set_ylabel("Whole-program cycles (PicoRV32, simulation)")
ax.set_title("4x4 INT8 matmul on PicoRV32: cycles per run\n"
             "seed 7 (error bar: shift-and-add range over 100 seeds + extreme modes)",
             fontsize=10)
ax.set_ylim(0, 36000)
ax.spines[["top", "right"]].set_visible(False)
fig.text(0.5, 0.01, "Simulation only (Icarus Verilog). No hardware run.",
         ha="center", fontsize=8, color="#555")
plt.tight_layout(rect=[0, 0.03, 1, 1])
plt.savefig("docs/results_cycles.png")
print("wrote docs/results_cycles.png")
