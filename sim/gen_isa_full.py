# Fuller instruction-coverage program for PicoRV32 (RV32IM). Standalone.
# Writes prog_full.hex, expect_full.txt, final_addr_full.txt.
# Results are stored through x31, which is advanced by 1024 every 256 results,
# so every store offset stays within the 12-bit S-type immediate.
import random

RES_BASE  = 0x940
SUB_ADDR  = 0xb00
BASE_STEP = 1024
random.seed(11)

def s32(x): return x - (1 << 32) if x & 0x80000000 else x
def u32(x): return x & 0xffffffff

prog, expect = [], []
def emit(w): prog.append(u32(w))

def enc_r(f7, rs2, rs1, f3, rd, op): return (f7<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op
def enc_i(imm, rs1, f3, rd, op):     return ((imm & 0xfff)<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op
def enc_s(imm, rs2, rs1, f3):        return (((imm>>5)&0x7f)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|((imm&0x1f)<<7)|0x23
def enc_u(imm20, rd, op):            return ((imm20 & 0xfffff)<<12)|(rd<<7)|op
def enc_b(off, rs2, rs1, f3):
    off &= 0x1fff
    return (((off>>12)&1)<<31)|(((off>>5)&0x3f)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(((off>>1)&0xf)<<8)|(((off>>11)&1)<<7)|0x63
def enc_j(off, rd):
    off &= 0x1fffff
    return (((off>>20)&1)<<31)|(((off>>1)&0x3ff)<<21)|(((off>>11)&1)<<20)|(((off>>12)&0xff)<<12)|(rd<<7)|0x6f

def load_const(rd, v):
    v = u32(v)
    hi = ((v + 0x800) >> 12) & 0xfffff
    lo = v - (((v + 0x800) >> 12) << 12)
    emit(enc_u(hi, rd, 0x37))
    emit(enc_i(lo, rd, 0, rd, 0x13))

load_const(31, RES_BASE)
slot = [0]
def store_result(rd):
    if slot[0] and slot[0] % 256 == 0:
        emit(enc_i(BASE_STEP, 31, 0, 31, 0x13))      # addi x31, x31, 1024
    emit(enc_s(4*(slot[0] % 256), rd, 31, 2))
    slot[0] += 1

def record(name, v): expect.append((name, u32(v)))

def case_r(name, f7, f3, fn, a, b):
    load_const(1, a); load_const(2, b)
    emit(enc_r(f7, 2, 1, f3, 3, 0x33)); store_result(3)
    record(name, fn(a, b))

def case_i(name, f3, fn, a, imm):
    load_const(1, a)
    emit(enc_i(imm, 1, f3, 3, 0x13)); store_result(3)
    record(name, fn(a, imm))

def case_shift(name, f3, f7, fn, a, sh):
    load_const(1, a)
    emit((f7<<25)|(sh<<20)|(1<<15)|(f3<<12)|(3<<7)|0x13); store_result(3)
    record(name, fn(a, sh))

def case_branch(name, f3, a, b, taken):
    load_const(1, a); load_const(2, b)
    emit(enc_i(0, 0, 0, 4, 0x13))
    emit(enc_b(8, 2, 1, f3))
    emit(enc_i(1, 0, 0, 4, 0x13))
    store_result(4)
    record(name, 0 if taken else 1)

def case_jal():
    pc = len(prog)*4
    emit(enc_j(8, 5))
    emit(enc_i(0x7ff, 0, 0, 6, 0x13))
    store_result(5)
    record("jal_link", pc + 4)

def case_auipc():
    pc = len(prog)*4
    emit(enc_u(0x12345, 7, 0x17))
    store_result(7)
    record("auipc", pc + (0x12345 << 12))

def case_loads():
    load_const(8, SUB_ADDR)
    for off in range(4):
        v = (0x5a + off*0x11) & 0xff
        load_const(1, 0x80f1c2a3)
        emit(enc_s(0, 1, 8, 2))
        emit(enc_i(v, 0, 0, 9, 0x13))
        emit(enc_s(off, 9, 8, 0))
        emit(enc_i(off, 8, 0, 10, 0x03)); store_result(10)
        word = (0x80f1c2a3 & ~(0xff << (8*off))) | (v << (8*off))
        byte = (word >> (8*off)) & 0xff
        record(f"lb_off{off}", byte - 0x100 if byte & 0x80 else byte)
        emit(enc_i(off, 8, 4, 11, 0x03)); store_result(11)
        record(f"lbu_off{off}", byte)
    for off in (0, 2):
        h = 0x8123 if off == 0 else 0x7fe4
        load_const(12, h)
        load_const(1, 0x80f1c2a3)
        emit(enc_s(0, 1, 8, 2))
        emit(enc_s(off, 12, 8, 1))
        emit(enc_i(off, 8, 1, 13, 0x03)); store_result(13)
        record(f"lh_off{off}", h - 0x10000 if h & 0x8000 else h)
        emit(enc_i(off, 8, 5, 14, 0x03)); store_result(14)
        record(f"lhu_off{off}", h)

ARITH = [("add",0,0,lambda a,b:a+b),("sub",0x20,0,lambda a,b:a-b),
         ("xor",0,4,lambda a,b:a^b),("or",0,6,lambda a,b:a|b),("and",0,7,lambda a,b:a&b),
         ("slt",0,2,lambda a,b:int(s32(a)<s32(b))),("sltu",0,3,lambda a,b:int(u32(a)<u32(b)))]
EDGE = [0, 1, 0xffffffff, 0x80000000, 0x7fffffff, 0x8000, 0x7fff, 0xff, 0x100]
for name,f7,f3,fn in ARITH:
    for a in EDGE:
        for b in EDGE:
            case_r(name, f7, f3, lambda x,y,fn=fn: u32(fn(x,y)), a, b)
for _ in range(20):
    case_r("add_rand", 0, 0, lambda x,y: x+y, random.randint(0,0xffffffff), random.randint(0,0xffffffff))

for s in range(32):
    for a in (0x80000001, 0x7fffffff, 0xdeadbeef, 0x00000001):
        case_shift("slli", 1, 0, lambda x,y: u32(x<<y), a, s)
        case_shift("srli", 5, 0, lambda x,y: u32(x)>>y, a, s)
        case_shift("srai", 5, 0x20, lambda x,y: u32(s32(x)>>y), a, s)

BR = [("beq",0,lambda a,b:a==b),("bne",1,lambda a,b:a!=b),
      ("blt",4,lambda a,b:s32(a)<s32(b)),("bge",5,lambda a,b:s32(a)>=s32(b)),
      ("bltu",6,lambda a,b:u32(a)<u32(b)),("bgeu",7,lambda a,b:u32(a)>=u32(b))]
PAIRS = [(0,0),(1,1),(0,1),(1,0),(0x80000000,1),(1,0x80000000),(0xffffffff,0),(0,0xffffffff),(5,9),(9,5)]
for name,f3,cond in BR:
    for a,b in PAIRS:
        case_branch(name, f3, a, b, cond(u32(a),u32(b)))

case_jal()
case_auipc()
case_loads()

emit(0x0000006f)
final_addr = (len(prog)-1)*4
assert len(prog)*4 <= RES_BASE, "code overlaps result area"
last_window_base = RES_BASE + BASE_STEP*((len(expect)-1)//256)
assert last_window_base + 4*256 <= 0x1000, "results overflow RAM"
with open("prog_full.hex","w") as f:
    f.write("@0\n")
    for w in prog: f.write(f"{w:08x}\n")
with open("expect_full.txt","w") as f:
    for i,(name,v) in enumerate(expect):
        addr = RES_BASE + BASE_STEP*(i//256) + 4*(i%256)
        f.write(f"{addr:x} {u32(v):08x} {name}\n")
open("final_addr_full.txt","w").write(f"{final_addr:x}\n")
print(f"wrote prog_full.hex: {len(prog)} instructions, {len(expect)} checks")
