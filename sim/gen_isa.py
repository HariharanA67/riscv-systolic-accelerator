# Instruction-coverage program for PicoRV32 (RV32IM).
# Each check: operands loaded with lui/addi, one instruction under test, result stored
# at RES_BASE + 4*i. Expected values computed here with 32-bit wraparound semantics.
import random

RES_BASE = 0x940
OPS_BASE = 0x200
random.seed(5)

def s32(x): return x - (1 << 32) if x & 0x80000000 else x
def u32(x): return x & 0xffffffff

prog = []
expect = []
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

slot = [0]
def store_result(rd):
    emit(enc_s(4*slot[0], rd, 31, 2))
    slot[0] += 1

load_const(31, RES_BASE)

def case_r(name, f7, f3, fn, a, b):
    load_const(1, a); load_const(2, b)
    emit(enc_r(f7, 2, 1, f3, 3, 0x33)); store_result(3)
    expect.append((name, fn(a, b)))

def case_i(name, f3, fn, a, imm):
    load_const(1, a)
    emit(enc_i(imm, 1, f3, 3, 0x13)); store_result(3)
    expect.append((name, fn(a, imm)))

def case_shift_imm(name, f3, f7, fn, a, sh):
    load_const(1, a)
    emit((f7<<25)|(sh<<20)|(1<<15)|(f3<<12)|(3<<7)|0x13); store_result(3)
    expect.append((name, fn(a, sh)))

# Branch: x4 = 0; x1 = a, x2 = b; if (a OP b) skip the "x4 = 1" instruction.
# So x4 ends as 1 only when the branch is NOT taken.
def case_branch(name, f3, a, b, taken):
    load_const(1, a); load_const(2, b)
    emit(enc_i(0, 0, 0, 4, 0x13))            # x4 = 0
    emit(enc_b(8, 2, 1, f3))                 # taken -> skip next instruction
    emit(enc_i(1, 0, 0, 4, 0x13))            # x4 = 1 (only if not taken)
    store_result(4)
    expect.append((name, 0 if taken else 1))

# jal: jump over one instruction; x5 holds the return address, store it.
def case_jal():
    jal_pc = len(prog)*4
    emit(enc_j(8, 5))                        # jal x5, +8 (skip next)
    emit(enc_i(0x7ff, 0, 0, 6, 0x13))        # skipped instruction: x6 = 2047
    store_result(5)                          # x5 = PC of jal + 4
    expect.append(("jal_link", jal_pc + 4))  # link register = jal address + 4

def case_auipc():
    auipc_pc = len(prog)*4
    emit(enc_u(0x12345, 7, 0x17))            # auipc x7, 0x12345
    store_result(7)
    expect.append(("auipc", auipc_pc + (0x12345 << 12)))

# sub-word store then load: store a word, read bytes/halves back with each load width.
SUB_ADDR = 0xb00
def case_subword():
    load_const(8, SUB_ADDR)
    word = 0x80f1c2a3
    load_const(1, word)
    emit(enc_s(0, 1, 8, 2))                         # sw x1, 0(x8)
    emit(enc_i(0x66, 0, 0, 9, 0x13))                # x9 = 0x66
    emit(enc_s(1, 9, 8, 0))                         # sb x9, 1(x8)  -> byte1 = 0x66
    emit(enc_i(1, 8, 0, 10, 0x03))                  # lb x10, 1(x8)
    store_result(10)
    expect.append(("lb_after_sb", 0x00000066))
    emit(enc_i(0, 8, 4, 11, 0x03))                  # lbu x11, 0(x8)
    store_result(11)
    expect.append(("lbu_byte0", 0x000000a3))
    load_const(12, 0x8123)
    emit(enc_s(2, 12, 8, 1))                        # sh x12, 2(x8)
    emit(enc_i(2, 8, 1, 13, 0x03))                  # lh x13, 2(x8)
    store_result(13)
    expect.append(("lh_after_sh", 0xffff8123))
    emit(enc_i(2, 8, 5, 14, 0x03))                  # lhu x14, 2(x8)
    store_result(14)
    expect.append(("lhu_after_sh", 0x00008123))

# --- R-type ALU and M extension, random plus edge operands ---
R = [("add",0,0,lambda a,b:u32(a+b)),("sub",0x20,0,lambda a,b:u32(a-b)),
     ("sll",0,1,lambda a,b:u32(a<<(b&31))),("slt",0,2,lambda a,b:int(s32(a)<s32(b))),
     ("sltu",0,3,lambda a,b:int(u32(a)<u32(b))),("xor",0,4,lambda a,b:u32(a^b)),
     ("srl",0,5,lambda a,b:u32(a)>>(b&31)),("sra",0x20,5,lambda a,b:u32(s32(a)>>(b&31))),
     ("or",0,6,lambda a,b:u32(a|b)),("and",0,7,lambda a,b:u32(a&b))]
EDGE = [0, 1, 0xffffffff, 0x80000000, 0x7fffffff]
for name,f7,f3,fn in R:
    for _ in range(2):
        b = random.randint(0,31) if name in ("sll","srl","sra") else random.randint(-2**31,2**31-1)&0xffffffff
        case_r(name, f7, f3, fn, random.randint(-2**31,2**31-1)&0xffffffff, b)
    case_r(name, f7, f3, fn, 0x80000000, 0xffffffff if name not in ("sll","srl","sra") else 31)

M = [("mul",1,0,lambda a,b:u32(s32(a)*s32(b))),("mulh",1,1,lambda a,b:u32((s32(a)*s32(b))>>32)),
     ("mulhsu",1,2,lambda a,b:u32((s32(a)*u32(b))>>32)),("mulhu",1,3,lambda a,b:u32((u32(a)*u32(b))>>32))]
for name,f7,f3,fn in M:
    for _ in range(2):
        case_r(name, f7, f3, fn, random.randint(-2**31,2**31-1)&0xffffffff, random.randint(-2**31,2**31-1)&0xffffffff)
    case_r(name, f7, f3, fn, 0x80000000, 0xffffffff)

I = [("addi",0,lambda a,i:u32(a+i)),("slti",2,lambda a,i:int(s32(a)<i)),
     ("sltiu",3,lambda a,i:int(u32(a)<u32(i))),("xori",4,lambda a,i:u32(a^u32(i))),
     ("ori",6,lambda a,i:u32(a|u32(i))),("andi",7,lambda a,i:u32(a&u32(i)))]
for name,f3,fn in I:
    for _ in range(2):
        case_i(name, f3, fn, random.randint(-2**31,2**31-1)&0xffffffff, random.randint(-2048,2047))
    case_i(name, f3, fn, 0, -1)

SH = [("slli",1,0,lambda a,s:u32(a<<s)),("srli",5,0,lambda a,s:u32(a)>>s),
      ("srai",5,0x20,lambda a,s:u32(s32(a)>>s))]
for name,f3,f7,fn in SH:
    for s in (1, 7, 31):
        case_shift_imm(name, f3, f7, fn, random.randint(-2**31,2**31-1)&0xffffffff, s)

BR = [("beq",0,lambda a,b:a==b),("bne",1,lambda a,b:a!=b),
      ("blt",4,lambda a,b:s32(a)<s32(b)),("bge",5,lambda a,b:s32(a)>=s32(b)),
      ("bltu",6,lambda a,b:u32(a)<u32(b)),("bgeu",7,lambda a,b:u32(a)>=u32(b))]
for name,f3,cond in BR:
    for a,b in ((5,5),(5,9),(0xffffffff,1),(1,0xffffffff)):
        case_branch(name, f3, a, b, cond(u32(a),u32(b)))

case_jal()
case_auipc()
case_subword()


emit(0x0000006f)                              # final j .
final_addr = (len(prog)-1)*4
open("final_addr.txt","w").write(f"{final_addr:x}\n")
assert len(prog)*4 <= RES_BASE, f"code ({len(prog)*4:#x} bytes) overlaps result area at {RES_BASE:#x}"
with open("prog_isa.hex","w") as f:
    f.write("@0\n")
    for w in prog: f.write(f"{w:08x}\n")
with open("expect_isa.txt","w") as f:
    for i,(name,v) in enumerate(expect):
        if v is None:
            continue
        f.write(f"{RES_BASE+4*i:x} {u32(v):08x} {name}\n")
print(f"wrote prog_isa.hex: {len(prog)} instructions, {sum(1 for _,v in expect if v is not None)} checks")
