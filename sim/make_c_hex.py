import random

random.seed(7)
A = [random.randint(-128, 127) for _ in range(16)]
B = [random.randint(-128, 127) for _ in range(16)]

data = open("../firmware/matmul.bin", "rb").read()
assert len(data) <= 0x200, "firmware overlaps data region"
data = data.ljust(0x200, b"\0")
words = [int.from_bytes(data[i:i+4], "little") for i in range(0, 0x200, 4)]

with open("prog_c.hex", "w") as f:
    f.write("@0\n")
    for w in words:
        f.write(f"{w:08x}\n")
    f.write("@80\n")
    for v in A:
        f.write(f"{v & 0xff:08x}\n")
    f.write("@90\n")
    for v in B:
        f.write(f"{v & 0xff:08x}\n")
print(f"wrote prog_c.hex: {len(data)//4} code words")
