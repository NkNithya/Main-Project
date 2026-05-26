# =========================
# Paths
# =========================
set DESIGN HMNOC_4cluster_wpsum_bias_relu_top
set NETLIST Clock_Gated_Architecture_RTL/synth_hd.v
set LIB skywater-pdk/libraries/sky130_fd_sc_hd/latest/timing/sky130_fd_sc_hd__ss_100C_1v60.lib

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
set_clock_uncertainty 0.1 clk

# =========================
# Report
# =========================
set rpt_file "Reports/timing_report_gated_sc_hd.txt"

set fp [open $rpt_file "w"]
puts $fp "=================================================="
puts $fp "   HMNOC 4-Cluster WPSUM + BIAS + RELU - TIMING REPORT (sc_hd)"
puts $fp "=================================================="
puts $fp "Design        : $DESIGN"
puts $fp "Netlist       : $NETLIST"
puts $fp "Library       : $LIB"
puts $fp "Clock Period  : 60 ns"
puts $fp "Generated On  : [clock format [clock seconds]]"
puts $fp "=================================================="
puts $fp ""
close $fp

puts "========== SETUP ANALYSIS =========="
report_checks -path_delay max >> $rpt_file

puts "========== HOLD ANALYSIS =========="
report_checks -path_delay min >> $rpt_file

puts "========== WNS =========="
report_wns >> $rpt_file

puts "========== TNS =========="
report_tns >> $rpt_file

report_checks -path_delay max -digits 3 >> $rpt_file

exit
