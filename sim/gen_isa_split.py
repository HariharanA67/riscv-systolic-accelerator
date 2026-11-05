SRC = "gen_isa_full.py"
CODE_LIMIT = 1800
CHECK_LIMIT = 200

src = open(SRC).read()
head, sep, _ = src.partition("emit(0x0000006f)\nfinal_addr")
assert sep, "write-out section not found in gen_isa_full.py"

HOOK = "def record(name, v): expect.append((name, u32(v)))"
assert HOOK in head, "record() definition changed; update the hook"
head = head.replace(HOOK, "def record(name, v):\n    expect.append((name, u32(v)))\n    _after_record()")

ns = {}
k = [0]
total = [0]

def write_chunk(prog, expect):
    code = list(prog) + [0x0000006f]
    final = (len(code) - 1) * 4
    assert len(code) * 4 <= ns["RES_BASE"], f"isa{k[0]}: code overlaps results"
    with open(f"prog_isa{k[0]}.hex", "w") as f:
        f.write("@0\n")
        for w in code:
            f.write(f"{w:08x}\n")
    with open(f"expect_isa{k[0]}.txt", "w") as f:
        for i, (name, v) in enumerate(expect):
            addr = ns["RES_BASE"] + ns["BASE_STEP"] * (i // 256) + 4 * (i % 256)
            f.write(f"{addr:x} {v:08x} {name}\n")
    open(f"final_addr_isa{k[0]}.txt", "w").write(f"{final:x}\n")
    print(f"isa{k[0]}: {len(code)} instructions, {len(expect)} checks")
    total[0] += len(expect)
    k[0] += 1

def flush():
    prog, expect = ns["prog"], ns["expect"]
    if not expect:
        return
    write_chunk(prog, expect)
    prog.clear()
    expect.clear()
    ns["slot"][0] = 0
    ns["load_const"](31, ns["RES_BASE"])

def after_record():
    if len(ns["prog"]) * 4 > CODE_LIMIT or len(ns["expect"]) >= CHECK_LIMIT:
        flush()

ns["_after_record"] = after_record
exec(compile(head, SRC, "exec"), ns)
flush()
print(f"total: {k[0]} chunks, {total[0]} checks")
