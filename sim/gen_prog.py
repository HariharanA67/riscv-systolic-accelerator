import random

random.seed(7)
A = [random.randint(-128, 127) for _ in range(16)]
B = [random.randint(-128, 127) for _ in range(16)]

def enc_i(op, f3, rd, rs1, imm):
    return ((imm & 0xfff) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op

def enc_s(f3, rs1, rs2, imm):
    imm &= 0xfff
    return (((imm >> 5) & 0x7f) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | ((imm & 0x1f) << 7) | 0x23

def enc_u(op, rd, imm20):
    return ((imm20 & 0xfffff) << 12) | (rd << 7) | op

def enc_b(f3, rs1, rs2, off):
    off &= 0x1fff
    return (((off >> 12) & 1) << 31) | (((off >> 5) & 0x3f) << 25) | (rs2 << 20) | (rs1 << 15) \
         | (f3 << 12) | (((off >> 1) & 0xf) << 8) | (((off >> 11) & 1) << 7) | 0x63

prog = []
prog.append(enc_u(0x37, 1, 0x80000))              # lui x1, 0x80000  -> x1 = 0x8000_0000
for k in range(16):                                # copy A: RAM 0x200+4k -> accel 0x100+4k
    prog.append(enc_i(0x03, 2, 2, 0, 0x200 + 4*k))  # lw x2, off(x0)
    prog.append(enc_s(2, 1, 2, 0x100 + 4*k))        # sw x2, off(x1)
for k in range(16):                                # copy B: RAM 0x240+4k -> accel 0x200+4k
    prog.append(enc_i(0x03, 2, 2, 0, 0x240 + 4*k))
    prog.append(enc_s(2, 1, 2, 0x200 + 4*k))
prog.append(enc_i(0x13, 0, 3, 0, 1))               # addi x3, x0, 1
prog.append(enc_s(2, 1, 3, 0))                     # sw x3, 0(x1)   start
poll = len(prog)
prog.append(enc_i(0x03, 2, 4, 1, 4))               # lw x4, 4(x1)   status
prog.append(enc_i(0x13, 7, 5, 4, 1))               # andi x5, x4, 1 done bit
idx = len(prog)
prog.append(enc_b(0, 5, 0, (poll - idx) * 4))      # beq x5, x0, poll
for k in range(16):                                # copy C: accel 0x300+4k -> RAM 0x400+4k
    prog.append(enc_i(0x03, 2, 6, 1, 0x300 + 4*k))
    prog.append(enc_s(2, 0, 6, 0x400 + 4*k))
prog.append(0x0000006f)                            # j .

assert len(prog) < 0x80, "program overlaps data region"

with open("prog.hex", "w") as f:
    f.write("@0\n")
    for w in prog:
        f.write(f"{w & 0xffffffff:08x}\n")
    f.write("@80\n")                               # word 0x80 = byte 0x200 (A)
    for v in A:
        f.write(f"{v & 0xff:08x}\n")
    f.write("@90\n")                               # word 0x90 = byte 0x240 (B)
    for v in B:
        f.write(f"{v & 0xff:08x}\n")
print(f"wrote prog.hex: {len(prog)} instructions")
