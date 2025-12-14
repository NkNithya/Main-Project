##############################
# Directory Variables
##############################

RTL_DIR    := rtl
TB_DIR     := testbench
BUILD_DIR  := build


##############################
# Router Compile Targets
##############################

# 1) ------- IACT ROUTER -------
iact: ## Compile IACT router
	iverilog -g2012 $(RTL_DIR)/router_iact.v \
		$(RTL_DIR)/router_iact_generic.v

# 2) ------- PSUM ROUTER -------
psum: ## Compile PSUM router
	iverilog -g2012 $(RTL_DIR)/router_psum.v \
		$(RTL_DIR)/router_psum_generic.v

# 3) ------- WEIGHT ROUTER -------
weight: ## Compile WEIGHT router
	iverilog -g2012 $(RTL_DIR)/router_weight.v \
		$(RTL_DIR)/router_weight_generic.v

# 4) ------- WPSUM ROUTER -------
router-wpsum: ## Compile WPSUM cluster router
	iverilog -g2012 $(RTL_DIR)/router_cluster_wpsum_generic.v \
		$(RTL_DIR)/router_iact.v \
		$(RTL_DIR)/router_iact_generic.v \
		$(RTL_DIR)/router_psum.v \
		$(RTL_DIR)/router_psum_generic.v \
		$(RTL_DIR)/router_weight.v \
		$(RTL_DIR)/router_weight_generic.v 
		
hmnoc-1cluster: ##Compile HMNOC 1 cluster
	iverilog -g2012 $(RTL_DIR)/HMNOC_1cluster_wpsum_generic.v \
		$(RTL_DIR)/router_cluster_wpsum_generic.v \
		$(RTL_DIR)/router_iact.v \
		$(RTL_DIR)/router_iact_generic.v \
		$(RTL_DIR)/router_weight.v \
		$(RTL_DIR)/router_weight_generic.v \
		$(RTL_DIR)/router_psum.v \
		$(RTL_DIR)/router_psum_generic.v \
		$(RTL_DIR)/PE_new.v \
		$(RTL_DIR)/PE_cluster_new.v \
		$(RTL_DIR)/GLB_cluster_wpsum.v \
		$(RTL_DIR)/glb_weight.v \
		$(RTL_DIR)/glb_iact.v \
		$(RTL_DIR)/glb_psum.v \
		$(RTL_DIR)/MAC.v \
		$(RTL_DIR)/mux2.v \
		$(RTL_DIR)/SPad.v 



##############################
# Testbench Compile Targets
##############################

test-router-wpsum: ## Build WPSUM router testbench
	iverilog -g2012 -o $(BUILD_DIR)/router_cluster_wpsum.out \
		$(TB_DIR)/router_cluster_wpsum_generic_tb.v \
		$(RTL_DIR)/router_cluster_wpsum_generic.v \
		$(RTL_DIR)/router_iact.v \
		$(RTL_DIR)/router_iact_generic.v \
		$(RTL_DIR)/router_psum.v \
		$(RTL_DIR)/router_psum_generic.v \
		$(RTL_DIR)/router_weight.v \
		$(RTL_DIR)/router_weight_generic.v 

run-router-wpsum: ## Run WPSUM router simulation
	vvp $(BUILD_DIR)/router_cluster_wpsum.out

test-router-iact: ## Build IACT router testbench
	iverilog -g2012 -o $(BUILD_DIR)/router_iact.out \
		$(TB_DIR)/router_iact_tb.v \
		$(RTL_DIR)/router_iact.v \
		$(RTL_DIR)/router_iact_generic.v

run-router-iact: ## Run IACT router simulation
	vvp $(BUILD_DIR)/router_iact.out

test-router-weight: ## Build WEIGHT router testbench
	iverilog -g2012 -o $(BUILD_DIR)/router_weight.out \
		$(TB_DIR)/router_weight_tb.v \
		$(RTL_DIR)/router_weight.v \
		$(RTL_DIR)/router_weight_generic.v

run-router-weight: ## Run WEIGHT router simulation
	vvp $(BUILD_DIR)/router_weight.out

test-router-psum: ## Build PSUM router testbench
	iverilog -g2012 -o $(BUILD_DIR)/router_psum.out \
		$(TB_DIR)/router_psum_tb.v \
		$(RTL_DIR)/router_psum.v \
		$(RTL_DIR)/router_psum_generic.v

run-router-psum: ## Run PSUM router simulation
	vvp $(BUILD_DIR)/router_psum.out
	
test-hmnoc-1cluster: ##Build HMNOC 1cluster testbench
	iverilog -g2012  -o $(BUILD_DIR)/HMNOC_1cluster_wpsum_generic.out \
		$(TB_DIR)/HMNOC_1cluster_wpsum_generic_tb.v \
		$(RTL_DIR)/HMNOC_1cluster_wpsum_generic.v \
		$(RTL_DIR)/router_cluster_wpsum_generic.v \
		$(RTL_DIR)/router_iact.v \
		$(RTL_DIR)/router_iact_generic.v \
		$(RTL_DIR)/router_weight.v \
		$(RTL_DIR)/router_weight_generic.v \
		$(RTL_DIR)/router_psum.v \
		$(RTL_DIR)/router_psum_generic.v \
		$(RTL_DIR)/PE_new.v \
		$(RTL_DIR)/PE_cluster_new.v \
		$(RTL_DIR)/GLB_cluster_wpsum.v \
		$(RTL_DIR)/glb_weight.v \
		$(RTL_DIR)/glb_iact.v \
		$(RTL_DIR)/glb_psum.v \
		$(RTL_DIR)/MAC.v \
		$(RTL_DIR)/mux2.v \
		$(RTL_DIR)/SPad.v 

run-hmnoc-1cluster: ##Run HMNOC 1 cluster simulation
	vvp $(BUILD_DIR)/HMNOC_1cluster_wpsum_generic.out

##############################
# Utility Targets
##############################

clean: ## Remove all build files
	rm -f $(BUILD_DIR)/*.out
	rm -f a.out


##############################
# Help Target
##############################

help: ## Show all available make commands
	@echo ""
	@echo "Available make commands:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?##' Makefile \
		| awk 'BEGIN {FS="##"} {printf " make %-22s %s\n", $$1, $$2}'
	@echo ""

