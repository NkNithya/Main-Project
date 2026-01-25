# =========================
# Paths
# =========================
set DESIGN HMNOC_4cluster_wpsum_bias_relu_top
set NETLIST Clock_Gated_Architecture_RTL/synth.v
set TIMING_LEF skywater-pdk/libraries/sky130_fd_sc_hd/latest/timing/sky130_fd_sc_hd__tt_025C_1v80.lib 
set TECH_LEF skywater-pdk/libraries/sky130_fd_sc_hd/latest/tech/sky130_fd_sc_hd.tlef
set CELL_LEFS [glob skywater-pdk/libraries/sky130_fd_sc_hd/latest/cells/*/*.lef] 
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

report_power

