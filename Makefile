##############################
# Directory Variables
##############################

RTL_DIR := rtl
TB_DIR  := testbench
BUILD_DIR := build

##############################
# Router Compile Targets
##############################

# 1) ------- IACT ROUTER -------
iact:
	iverilog $(RTL_DIR)/router_iact.v \
		$(RTL_DIR)/router_iact_generic.v


# 2) ------- PSUM ROUTER -------
psum:
	iverilog $(RTL_DIR)/router_psum.v \
		$(RTL_DIR)/router_psum_generic.v


# 3) ------- WEIGHT ROUTER -------
weight:
	iverilog $(RTL_DIR)/router_weight.v \
		$(RTL_DIR)/router_weight_generic.v


# 4) ------- WPSUM ROUTER -------
router-wpsum:
	iverilog $(RTL_DIR)/router_cluster_wpsum_generic.v \
		$(RTL_DIR)/router_iact.v \
		$(RTL_DIR)/router_iact_generic.v \
		$(RTL_DIR)/router_psum.v \
		$(RTL_DIR)/router_psum_generic.v \
		$(RTL_DIR)/router_weight.v \
		$(RTL_DIR)/router_weight_generic.v 
		
HMNOC_1cluster:
	iverilog -g2012 \
		$(RTL_DIR)/HMNOC_1cluster_wpsum_generic.v \
		$(RTL_DIR)/router_cluster_wpsum_generic.v \
		$(RTL_DIR)/router_iact_generic.v \
		$(RTL_DIR)/router_weight_generic.v \
		$(RTL_DIR)/router_psum_generic.v \
		$(RTL_DIR)/router_iact.v \
		$(RTL_DIR)/router_weight.v \
		$(RTL_DIR)/router_psum.v \
		$(RTL_DIR)/GLB_cluster_wpsum.v \
		$(RTL_DIR)/glb_iact.v \
		$(RTL_DIR)/glb_weight.v \
		$(RTL_DIR)/glb_psum.v \
		$(RTL_DIR)/PE_cluster_new.v \
		$(RTL_DIR)/PE_new.v \
		$(RTL_DIR)/mux2.v \
		$(RTL_DIR)/MAC.v \
		$(RTL_DIR)/SPad.v
		
		


##############################
# Testbench Compile Targets
test-wpsum-generic:
	iverilog -o $(BUILD_DIR)/wpsum_generic_tb.out \
		$(TB_DIR)/router_generic_tb.v \
		$(RTL_DIR)/router_cluster_wpsum_generic.v \
		$(RTL_DIR)/router_iact.v \
		$(RTL_DIR)/router_iact_generic.v \
		$(RTL_DIR)/router_psum.v \
		$(RTL_DIR)/router_psum_generic.v \
		$(RTL_DIR)/router_weight.v \
		$(RTL_DIR)/router_weight_generic.v 

run-wpsum-generic:
	vvp $(BUILD_DIR)/wpsum_generic_tb.out

test-router-iact:
	iverilog -g2012 -o $(BUILD_DIR)/router_iact.out \
		$(TB_DIR)/router_iact_tb.v \
		$(RTL_DIR)/router_iact.v \
		$(RTL_DIR)/router_iact_generic.v

run-router-iact:
	vvp $(BUILD_DIR)/router_iact.out

test-router-weight:
	iverilog -g2012 -o $(BUILD_DIR)/router_weight.out \
		$(TB_DIR)/router_weight_tb.v \
		$(RTL_DIR)/router_weight.v \
		$(RTL_DIR)/router_weight_generic.v
		
run-router-weight:
	vvp $(BUILD_DIR)/router_weight.out

test-router-psum:
	iverilog -g2012 -o $(BUILD_DIR)/router_psum.out \
		$(TB_DIR)/router_psum_tb.v \
		$(RTL_DIR)/router_psum.v \
		$(RTL_DIR)/router_psum_generic.v
	
run-router-psum:
	vvp $(BUILD_DIR)/router_psum.out

##############################
# Utility Targets
##############################

clean:
	rm -f $(BUILD_DIR)/*.out
	rm -f a.out
