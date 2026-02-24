# =========================
# Paths
# =========================
set DESIGN HMNOC_4cluster_wpsum_bias_relu_top
set NETLIST Clock_Gated_Architecture_RTL/synth.v
set LIB skywater-pdk/libraries/sky130_fd_sc_lp/latest/timing/sky130_fd_sc_lp__ss_100C_1v60.lib

# =========================
# Read Library
# =========================
read_liberty $LIB

# =========================
# Read Netlist
# =========================
read_verilog $NETLIST
link_design $DESIGN

# =========================
# Create Clock
# =========================
create_clock -name clk -period 60 clk

# Optional but safe
set_clock_uncertainty 0.1 clk

# =========================
# Timing Reports
# =========================

puts "========== SETUP ANALYSIS =========="
report_checks -path_delay max

puts "========== HOLD ANALYSIS =========="
report_checks -path_delay min

puts "========== WNS =========="
report_wns

puts "========== TNS =========="
report_tns

report_checks -path_delay max -digits 3


exit

