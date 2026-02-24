# =========================
# Paths
# =========================
set DESIGN HMNOC_4cluster_wpsum_bias_relu_top
set NETLIST Clock_Gated_Architecture_RTL/synth.v
set TIMING_LEF  skywater-pdk/libraries/sky130_fd_sc_lp/latest/timing/sky130_fd_sc_lp__ss_100C_1v60.lib
set TECH_LEF skywater-pdk/libraries/sky130_fd_sc_lp/latest/tech/sky130_fd_sc_lp.tlef
set CELL_LEFS [glob skywater-pdk/libraries/sky130_fd_sc_lp/latest/cells/*/*.lef]

# =========================
# Read LEFs
# =========================
read_lef $TECH_LEF

foreach lef_file $CELL_LEFS {
	if {![string match "*tap*" $lef_file]} {
		read_lef $lef_file
	}
}

# =========================
# Read netlist
# =========================
read_verilog $NETLIST
link_design $DESIGN
read_liberty $TIMING_LEF
# =========================
# Power nets
# =========================
add_global_connection -net VDD -pin VDD -power
add_global_connection -net VSS -pin VSS -ground
global_connect

create_clock -name clk -period 10 [get_ports clk]

read_vcd Simulations/HMNOC_4cluster_wpsum_bias_relu_mf_tb_gated.vcd

# =========================
# Report
# =========================
set rpt_file "Reports/power_report_gated.txt"

# Create file and write heading
set fp [open $rpt_file "w"]
puts $fp "=================================================="
puts $fp "   HMNOC 4-Cluster WPSUM + BIAS + RELU - POWER REPORT"
puts $fp "=================================================="
puts $fp "Design        : $DESIGN"
puts $fp "Netlist       : $NETLIST"
puts $fp "Clock Period  : 10 ns"
puts $fp "Generated On  : [clock format [clock seconds]]"
puts $fp "=================================================="
puts $fp ""
close $fp

# Append OpenROAD power report
report_power >> $rpt_file

exit

