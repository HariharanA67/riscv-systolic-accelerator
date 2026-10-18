# Splits ISA coverage into small programs. Each program has at most CODE_MAX
# instructions and CHECK_MAX checks, so code stays below the result area (0x400)
# and all results fit in one window (0x400..0x7e8). Writes:
#   prog_<tag>.hex, expect_<tag>.txt, final_addr_<tag>.txt
import random

RES_BASE, SUB_ADDR = 0x400, 0x900
CODE_MAX, CHECK_MAX = 240, 250     # instructions incl. final j ., checks per program
random.seed(11)

def s32(x): return x - (1 << 32) if x & 0x80000000 else x
def u32(x): return x & 0xffffffff

def enc_r(f7, rs2, rs1, f3, rd, op): return (f7<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op
def enc_i(imm, rs1, f3, rd, op):     return ((imm & 0xfff)<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op
def enc_s(imm, rs2, rs1, f3):        return (((imm>>5)&0x7f)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|((imm&0x1f)<<7)|0x23
def enc_u(imm20, rd, op):            return ((imm20 & 0xfffff)<<12)|(rd<<7)|op
def enc_b(off, rs2, rs1, f3):
    off &= 0x1fff
    return (((off>>12)&1)<<31)|(((off>>5)&0x3f)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(((off>>1)&0xf)<<8)|(((off>>11)&1)<<7)|0x63

class Prog:
    def __init__(self):
        self.code, self.expect, self.slot = [], [], 0
        self.load_const(31, RES_BASE)          # x31 = result base
    def emit(self, w): self.code.append(u32(w))
    def load_const(self, rd, v):
        v = u32(v)
        hi = ((v + 0x800) >> 12) & 0xfffff
        lo = v - (((v + 0x800) >> 12) << 12)
        self.emit(enc_u(hi, rd, 0x37)); self.emit(enc_i(lo, rd, 0, rd, 0x13))
    def store(self, rd):
        self.emit(enc_s(4*self.slot, rd, 31, 2)); self.slot += 1
    def record(self, name, v): self.expect.append((name, u32(v)))

class Fam:
    def __init__(self, name):
        self.name, self.k, self.p = name, 0, Prog()
    def ensure(self, ni, nc):
        # ni = instructions this case will add, nc = checks it adds
        if len(self.p.code) + ni + 1 > CODE_MAX or len(self.p.expect) + nc > CHECK_MAX:
            self.flush()
    def flush(self):
        if not self.p.expect: return
        tag = f"{self.name}{self.k}"; self.k += 1
        self.p.emit(0x0000006f)                              # final j .
        final = (len(self.p.code)-1)*4
        assert len(self.p.code)*4 <= RES_BASE, f"{tag}: code overflows into results"
        with open(f"prog_{tag}.hex","w") as f:
            f.write("@0\n")
            for w in self.p.code: f.write(f"{w:08x}\n")
        with open(f"expect_{tag}.txt","w") as f:
            for i,(n,v) in enumerate(self.p.expect):
                f.write(f"{RES_BASE+4*i:x} {v:08x} {n}\n")
        open(f"final_addr_{tag}.txt","w").write(f"{final:x}\n")
        print(f"{tag}: {len(self.p.code)} instructions, {len(self.p.expect)} checks")
        self.p = Prog()
    def close(self): self.flush()

# Family: shifts, all 32 amounts, 3 ops, 2 operands
f = Fam("shift")
for s in range(32):
    for a in (0x80000001, 0xdeadbeef):
        f.ensure(11, 3); p = f.p
        p.load_const(1, a)
        p.emit(enc_i(s, 1, 1, 3, 0x13)); p.store(3); p.record("slli", u32(a<<s))
        p.emit(enc_i(s, 1, 5, 3, 0x13)); p.store(3); p.record("srli", u32(a)>>s)
        p.emit(enc_i((0x20<<5)|s, 1, 5, 3, 0x13)); p.store(3); p.record("srai", u32(s32(a)>>s))
f.close()

# Family: branches, 6 kinds x 10 operand pairs
BR = [("beq",0,lambda a,b:a==b),("bne",1,lambda a,b:a!=b),
      ("blt",4,lambda a,b:s32(a)<s32(b)),("bge",5,lambda a,b:s32(a)>=s32(b)),
      ("bltu",6,lambda a,b:u32(a)<u32(b)),("bgeu",7,lambda a,b:u32(a)>=u32(b))]
PAIRS = [(0,0),(1,1),(0,1),(1,0),(0x80000000,1),(1,0x80000000),
         (0xffffffff,0),(0,0xffffffff),(5,9),(9,5)]
f = Fam("branch")
for name,f3,cond in BR:
    for a,b in PAIRS:
        f.ensure(9, 1); p = f.p
        p.load_const(1, a); p.load_const(2, b)
        p.emit(enc_i(0,0,0,4,0x13))            # x4 = 0
        p.emit(enc_b(8, 2, 1, f3))             # taken -> skip next
        p.emit(enc_i(1,0,0,4,0x13))            # x4 = 1 (only if not taken)
        p.store(4); p.record(name, 0 if cond(u32(a),u32(b)) else 1)
f.close()

# Family: sub-word loads/stores at every offset
f = Fam("load")
for off in range(4):
    f.ensure(16, 2); p = f.p
    p.load_const(8, SUB_ADDR)
    v = (0x5a + off*0x11) & 0xff
    p.load_const(1, 0x80f1c2a3); p.emit(enc_s(0,1,8,2))
    p.emit(enc_i(v,0,0,9,0x13)); p.emit(enc_s(off,9,8,0))
    p.emit(enc_i(off,8,0,10,0x03)); p.store(10)
    word = (0x80f1c2a3 & ~(0xff << (8*off))) | (v << (8*off)); byte = (word>>(8*off))&0xff
    p.record(f"lb_off{off}", byte-0x100 if byte&0x80 else byte)
    p.emit(enc_i(off,8,4,11,0x03)); p.store(11); p.record(f"lbu_off{off}", byte)
for off in (0,2):
    f.ensure(16, 2); p = f.p
    p.load_const(8, SUB_ADDR)
    h = 0x8123 if off==0 else 0x7fe4
    p.load_const(12, h); p.load_const(1, 0x80f1c2a3); p.emit(enc_s(0,1,8,2))
    p.emit(enc_s(off,12,8,1))
    p.emit(enc_i(off,8,1,13,0x03)); p.store(13); p.record(f"lh_off{off}", h-0x10000 if h&0x8000 else h)
    p.emit(enc_i(off,8,5,14,0x03)); p.store(14); p.record(f"lhu_off{off}", h)
f.close()

# Family: arithmetic over edge operands (7 ops x 81 pairs)
ARITH = [("add",0,0,lambda a,b:a+b),("sub",0x20,0,lambda a,b:a-b),
         ("xor",0,4,lambda a,b:a^b),("or",0,6,lambda a,b:a|b),("and",0,7,lambda a,b:a&b),
         ("slt",0,2,lambda a,b:int(s32(a)<s32(b))),("sltu",0,3,lambda a,b:int(u32(a)<u32(b)))]
EDGE = [0,1,0xffffffff,0x80000000,0x7fffffff,0x8000,0x7fff,0xff,0x100]
for name,f7,f3,fn in ARITH:
    f = Fam(f"arith_{name}_")
    for a in EDGE:
        for b in EDGE:
            f.ensure(7, 1); p = f.p
            p.load_const(1, a); p.load_const(2, b)
            p.emit(enc_r(f7,2,1,f3,3,0x33)); p.store(3); p.record(name, u32(fn(a,b)))
    f.close()

# Family: random add pairs
f = Fam("rand_")
for _ in range(40):
    f.ensure(7, 1); p = f.p
    a, b = random.getrandbits(32), random.getrandbits(32)
    p.load_const(1, a); p.load_const(2, b)
    p.emit(enc_r(0,2,1,0,3,0x33)); p.store(3); p.record("add_rand", a+b)
f.close()
