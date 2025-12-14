from vcdvcd import VCDVCD

VCD_FILE = "router_generic_iact_clk_safe.vcd"
MIN_SPAD_PULSES = 25   # act_size^2

# --------------------------------------------------
# LOAD VCD
# --------------------------------------------------
vcd = VCDVCD(VCD_FILE, store_tvs=True)

print("=" * 80)
print(f"[INFO] Loaded VCD: {VCD_FILE}")
print(f"[INFO] Total signals: {len(vcd.signals)}")
print("=" * 80)

# --------------------------------------------------
# HELPERS
# --------------------------------------------------
def pick_deepest(matches):
    return max(matches, key=lambda s: s.count("."))

def sig_by_suffix(suffix):
    matches = [s for s in vcd.signals if s.endswith(suffix)]
    if not matches:
        raise KeyError(f"No signal ending with '{suffix}' found")
    sig_name = pick_deepest(matches)
    return vcd.data[vcd.references_to_ids[sig_name]].tv, sig_name

def rising_edges(tv):
    edges = []
    last = "0"
    for t, v in tv:
        if v not in ("0", "1"):
            continue
        if last == "0" and v == "1":
            edges.append(t)
        last = v
    return edges

def vector_values(tv):
    vals = []
    for _, v in tv:
        if v not in ("x", "z"):
            vals.append(int(v, 2))
    return vals

# --------------------------------------------------
# RESOLVE SIGNALS (VECTOR-AWARE)
# --------------------------------------------------
load_c, load_c_name   = sig_by_suffix("load_spad_ctrl_c")
load_p, load_p_name   = sig_by_suffix("load_spad_ctrl")
glb_req, glb_req_name = sig_by_suffix("read_req_glb_iact")
glb_addr, glb_addr_nm = sig_by_suffix("r_addr_glb_iact[9:0]")
west_en, west_en_name = sig_by_suffix("west_enable_o")
west_dt, west_dt_name = sig_by_suffix("west_data_o[15:0]")

print("[INFO] Signal mapping:")
print(f"  load_spad_ctrl_c -> {load_c_name}")
print(f"  load_spad_ctrl   -> {load_p_name}")
print(f"  glb_req_read     -> {glb_req_name}")
print(f"  glb_addr_read    -> {glb_addr_nm}")
print(f"  west_enable_o    -> {west_en_name}")
print(f"  west_data_o      -> {west_dt_name}")

# --------------------------------------------------
# TEST 1: load_spad_ctrl pulses
# --------------------------------------------------
load_pulses = rising_edges(load_p)
assert len(load_pulses) >= 2, \
    f"FAIL: Expected >=2 load pulses, got {len(load_pulses)}"
print(f"[PASS] load_spad_ctrl pulses: {len(load_pulses)}")

# --------------------------------------------------
# TEST 2: pulse follows ctrl_c
# --------------------------------------------------
ctrl_edges = rising_edges(load_c)
for p in load_pulses:
    assert any(c < p for c in ctrl_edges), \
        f"FAIL: load pulse at {p} without prior ctrl_c"
print("[PASS] load_spad_ctrl follows load_spad_ctrl_c")

# --------------------------------------------------
# TEST 3: glb_req_read asserted
# --------------------------------------------------
assert any(v == "1" for _, v in glb_req), \
    "FAIL: glb_req_read never asserted"
print("[PASS] glb_req_read asserted")

# --------------------------------------------------
# TEST 4: GLB address monotonic increment
# --------------------------------------------------
addr_vals = vector_values(glb_addr)
assert len(addr_vals) > 2, "FAIL: insufficient GLB address samples"

for i in range(len(addr_vals) - 1):
    a0, a1 = addr_vals[i], addr_vals[i + 1]
    assert a1 == a0 or a1 == a0 + 1, \
        f"FAIL: address jump {a0} -> {a1}"

print("[PASS] glb_addr_read increments correctly")

# --------------------------------------------------
# TEST 5: SPAD output pulses
# --------------------------------------------------
west_pulses = rising_edges(west_en)
assert len(west_pulses) >= MIN_SPAD_PULSES, \
    f"FAIL: west_enable_o pulses {len(west_pulses)} < {MIN_SPAD_PULSES}"

print(f"[PASS] west_enable_o pulses: {len(west_pulses)}")

# --------------------------------------------------
# TEST 6: Multiple burst data values
# --------------------------------------------------
data_vals = set(vector_values(west_dt))
assert len(data_vals) >= 2, \
    "FAIL: only one west_data_o value seen (expected multiple bursts)"

print(f"[PASS] west_data_o values observed: {data_vals}")

# --------------------------------------------------
# FINAL RESULT
# --------------------------------------------------
print("\n✅ ALL IACT ROUTER CHECKS PASSED SUCCESSFULLY")

