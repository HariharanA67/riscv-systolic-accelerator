import random
random.seed(7)
# Nonzero signed INT8 values only, so a broken datapath can't hide behind zeros
A = [random.choice([v for v in range(-128, 128) if v != 0]) for _ in range(16)]
B = [random.choice([v for v in range(-128, 128) if v != 0]) for _ in range(16)]
data = open("../firmware/matmul_opt.bin", "rb").read()
assert len(data) <= 0x200, "firmware overlaps data region"
data = data.ljust(0x200, b"\0")
words = [int.from_bytes(data[i:i+4], "little") for i in range(0, 0x200, 4)]
with open("prog_opt.hex", "w") as f:
    f.write("@0\n")
    for w in words: f.write(f"{w:08x}\n")
    f.write("@80\n")          # word 0x80 = byte 0x200 (A)
    for v in A: f.write(f"{v & 0xffffffff:08x}\n")
    f.write("@90\n")          # word 0x90 = byte 0x240 (B)
    for v in B: f.write(f"{v & 0xffffffff:08x}\n")
print(f"wrote prog_opt.hex: {len(data)//4} code words, A={A}, B={B}")
