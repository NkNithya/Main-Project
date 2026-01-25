# =========================
# Paths
# =========================
set DESIGN HMNOC_4cluster_wpsum_bias_relu_top
set NETLIST Clock_Gated_Architecture_RTL/synth.v

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

# =========================
# Floorplan
# =========================
initialize_floorplan \
  -die_area {0 0 1700 1700} \
  -core_area {20 20 1680 1680} \
  -site unithd
# =========================
# Power nets
# =========================
add_global_connection -net VDD -pin VDD -power
add_global_connection -net VSS -pin VSS -ground
global_connect

# =========================
# Report
# =========================

report_design_area

