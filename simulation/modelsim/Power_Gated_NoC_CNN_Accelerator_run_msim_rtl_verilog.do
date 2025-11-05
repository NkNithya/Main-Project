transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/HMNOC_4cluster_wpsum.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/HMNOC_1cluster_wpsum.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/glb_weight.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/glb_psum.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/glb_iact.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/GLB_cluster_wpsum.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/SPad.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/router_west_wght.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/router_west_psum.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/router_west_iact.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/router_weight.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/router_psum.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/router_iact.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/router_cluster_wpsum.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/PE_new.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/PE_cluster_new.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/mux2.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/rtl {/home/abhiram/Projects/Main-Project/rtl/MAC.v}

vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/testbench {/home/abhiram/Projects/Main-Project/testbench/HMNOC_1cluster_wpsum_tb.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/testbench {/home/abhiram/Projects/Main-Project/testbench/HMNOC_4cluster_wpsum_mf_tb.v}
vlog -vlog01compat -work work +incdir+/home/abhiram/Projects/Main-Project/testbench {/home/abhiram/Projects/Main-Project/testbench/HMNOC_4cluster_wpsum_tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  HMNOC_4cluster_wpsum_mf_tb

add wave *
view structure
view signals
run -all
