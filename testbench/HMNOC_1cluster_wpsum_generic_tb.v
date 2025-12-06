	`timescale 1ns / 1ps

module HMNOC_1cluster_wpsum_tb();
	// parameter DATA_BITWIDTH = 16;
	// parameter ADDR_BITWIDTH = 7;
	parameter ADDR_BITWIDTH_GLB = 6;
	parameter ADDR_BITWIDTH_SPAD = 6;
	parameter DATA_BITWIDTH = 16;
	parameter ADDR_BITWIDTH = 6;
    parameter A_READ_ADDR = 10;
	parameter A_LOAD_ADDR = 10;
	parameter W_READ_ADDR = 0;
	parameter W_LOAD_ADDR = 0;
	parameter PSUM_READ_ADDR = 0;
	parameter PSUM_LOAD_ADDR = 0;
	parameter PSUM_ADDR =40;
    parameter X_dim = 3;
    parameter Y_dim = 3;
    
    parameter kernel_size = 3;
    parameter act_size = 5;
    parameter NUM_GLB_IACT = 1;
    parameter NUM_GLB_PSUM = 1;
    parameter NUM_GLB_WGHT = 1;

    reg clk, reset;
	reg start;

	wire compute_done;
	wire load_done;

	// GLB Interports
	reg write_en_iact;
	reg [DATA_BITWIDTH-1:0] w_data_iact;
	reg [ADDR_BITWIDTH-1:0] w_addr_iact;
	
	reg [DATA_BITWIDTH-1:0] w_data_wght;
	reg [ADDR_BITWIDTH-1:0] w_addr_wght;
	reg write_en_wght;

	reg [ADDR_BITWIDTH-1:0] r_addr_psum;
	wire [DATA_BITWIDTH-1:0] r_data_psum;
	reg r_req_psum;

	reg [ADDR_BITWIDTH-1:0] r_addr_psum_inter;
	reg r_req_psum_inter;

 	reg west_enable_i_west_0_wght;	
	reg west_enable_i_west_0_iact;

	reg [3:0] router_mode_west_0_wght; 
	reg [3:0] router_mode_west_0_iact; 
	reg [3:0] router_mode_west_0_psum;

//   test signal for tb    //
// (left commented as in original)

	HMNOC_1cluster_wpsum_generic
		#(
		 .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
		 .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),
		 .DATA_BITWIDTH(DATA_BITWIDTH),
		 .ADDR_BITWIDTH(ADDR_BITWIDTH),
		 .A_LOAD_ADDR(A_LOAD_ADDR),
		 .A_READ_ADDR(A_READ_ADDR),
		 .W_LOAD_ADDR(W_LOAD_ADDR),
		 .W_READ_ADDR(W_READ_ADDR),
		 .PSUM_ADDR(PSUM_ADDR),
		 .X_dim(X_dim),
		 .Y_dim(Y_dim),
		 .kernel_size(kernel_size),
		 .act_size(act_size),
		 .NUM_GLB_IACT(NUM_GLB_IACT),
		 .NUM_GLB_PSUM(NUM_GLB_PSUM),
		 .NUM_GLB_WGHT(NUM_GLB_WGHT)
	     )
	HMNOC_1cluster_0
		(
		.clk(clk), 
		.reset(reset),
		.start(start),
	  
		.compute_done(compute_done),
		.load_done(load_done),

		// GLB Interports
		.write_en_iact(write_en_iact),
		.w_data_iact(w_data_iact),
		.w_addr_iact(w_addr_iact),

		.west_enable_i_west_0_iact(west_enable_i_west_0_iact),
		.router_mode_west_0_iact(router_mode_west_0_iact),

		.write_en_wght(write_en_wght),
		.w_data_wght(w_data_wght),
		.w_addr_wght(w_addr_wght),

		.west_enable_i_west_0_wght(west_enable_i_west_0_wght),
		.router_mode_west_0_wght(router_mode_west_0_wght),

		.west_0_req_read_psum(r_req_psum),
		.west_0_req_read_psum_inter(r_req_psum_inter),
		.r_addr_psum(r_addr_psum),
		.r_addr_psum_inter(r_addr_psum_inter),
		.r_data_psum(r_data_psum),
		.router_mode_west_0_psum(router_mode_west_0_psum),

		.north_data_i_iact(),
		.north_enable_i_iact(),
		.north_data_o_iact(),
		.north_enable_o_iact(),
		.south_data_i_iact(),
		.south_enable_i_iact(),
		.south_data_o_iact(),
		.south_enable_o_iact(),
		.east_data_i_iact(),
		.east_enable_i_iact(),
		.east_data_o_iact(),
		.east_enable_o_iact(),

		.north_data_i_wght(),
		.north_enable_i_wght(),
		.north_data_o_wght(),
		.north_enable_o_wght(),
		.south_data_i_wght(),
		.south_enable_i_wght(),
		.south_data_o_wght(),
		.south_enable_o_wght(),
		.east_data_i_wght(),
		.east_enable_i_wght(),
		.east_data_o_wght(),
		.east_enable_o_wght(),
	
		.north_data_i_psum(),
		.north_enable_i_psum(),
		.south_data_o_psum(),
		.south_enable_o_psum()
		);

	integer clk_prd = 10;
	integer i,a;
	integer j,k,m,n;
	integer idx;
	integer err_count;

	reg [DATA_BITWIDTH-1:0] cluster_out_1[0:8];

	// Golden model storage
	reg [DATA_BITWIDTH-1:0] act   [0:act_size*act_size-1];
	reg [DATA_BITWIDTH-1:0] wght  [0:kernel_size*kernel_size-1];
	reg [DATA_BITWIDTH-1:0] exp_psum [0:X_dim*X_dim-1];

	always begin
		clk = 0; #(clk_prd/2);
		clk = 1; #(clk_prd/2);
	end
	
	localparam ALL=0;
	localparam NORTH=1;
	localparam SOUTH=2;
	localparam WEST=3;
	localparam EAST=4;
	localparam EASTNORTH=5;
	localparam EASTSOUTH=6;
	localparam EASTWEST=7;
	localparam WESTNORTH=8;
	localparam WESTSOUTH=9;
	localparam WESTEAST = 10;
	localparam CLOSED=11;

	// ------------------------------------------------------------
	// Golden model: compute expected psums for this pattern
	// We mirror the TB pattern:
	//   w_data_wght = 1
	//   w_data_iact = i+1
	// so we don't depend on DUT internals.
	// ------------------------------------------------------------
	initial begin
		// activations: 1..25, row-major
		for (i = 0; i < act_size*act_size; i = i + 1)
			act[i] = i + 1;

		// weights: all ones
		for (i = 0; i < kernel_size*kernel_size; i = i + 1)
			wght[i] = 1;

		// 2D convolution, output size X_dim x X_dim = 3x3
		for (m = 0; m < X_dim; m = m + 1) begin
			for (n = 0; n < X_dim; n = n + 1) begin
				integer sum;
				sum = 0;
				for (j = 0; j < kernel_size; j = j + 1) begin
					for (k = 0; k < kernel_size; k = k + 1) begin
						sum = sum +
							act[(m+j)*act_size + (n+k)] *
							wght[j*kernel_size + k];
					end
				end
				exp_psum[m*X_dim + n] = sum[DATA_BITWIDTH-1:0];
			end
		end
	end
	
	initial begin
		err_count = 0;

		$dumpfile("HMNOC_1cluster_wpsum_tb.vcd");
		$dumpvars(0, HMNOC_1cluster_wpsum_tb);

		reset = 1; #30;
		reset = 0;
		start = 0;
		west_enable_i_west_0_wght = 0;
		west_enable_i_west_0_iact = 0;
		router_mode_west_0_wght = CLOSED;
		router_mode_west_0_iact = CLOSED;
		router_mode_west_0_psum = CLOSED;
		r_req_psum = 0;
		r_req_psum_inter = 0;
		
		#100;

		// --------------------------------------------------------
		// Write weights to GLB (all ones)
		// --------------------------------------------------------
		write_en_wght = 1;		
		for(i=0; i<kernel_size**2;i=i+1) begin
			w_data_wght = 1;
			w_addr_wght = W_LOAD_ADDR + i;
			#(clk_prd);
		end
		write_en_wght = 0;
	
		// --------------------------------------------------------
		// Write activations to GLB (1..25)
		// --------------------------------------------------------
		write_en_iact = 1;
		for(i=0; i<act_size**2;i=i+1) begin
			w_data_iact = i+1;
			w_addr_iact = A_LOAD_ADDR + i;
			#(clk_prd);
		end
		write_en_iact = 0;
		#(clk_prd);

		$display("\n\nLoading Begins: Weights.....\n\n");
		
		#(clk_prd);
		#(clk_prd/2);
		west_enable_i_west_0_wght = 1;
		router_mode_west_0_wght = WEST;

		#(clk_prd);
		#(clk_prd);
		#(clk_prd);
		for(i=1; i<=kernel_size**2; i=i+1) begin
			#(clk_prd);
		end
		
		west_enable_i_west_0_wght = 0; 
		router_mode_west_0_wght = CLOSED;

		wait(load_done==1);

		$display("\n\nLoading Begins: Iacts.....\n\n");

		#(clk_prd);
		west_enable_i_west_0_iact = 1;
		router_mode_west_0_iact = WEST;

		#(clk_prd);
		#(clk_prd);
		#(clk_prd);
		for(i=1; i<=act_size**2; i=i+1) begin
			#(clk_prd);
		end

		west_enable_i_west_0_iact = 0;
		router_mode_west_0_iact = CLOSED;

		wait(load_done==1);	
		#(clk_prd);
		#(clk_prd);

		// --------------------------------------------------------
		// ITERATION 1
		// --------------------------------------------------------
		start = 1; #25; 
		$display("\n\nReading & Computing Begins..... (Iter 1)\n\n");
		start = 0;
		
		wait (compute_done == 1);
		
		$display("\n\nFinal PSUM of Iteration 1");
		for(i=0;i<X_dim;i=i+1)
		begin
			r_req_psum = 1;
			r_addr_psum = PSUM_LOAD_ADDR + i;
			#(clk_prd);
			idx = i;
			$display("Iter1: psum[%0d] @ addr %0d = %0d, expected %0d",
			         idx, r_addr_psum, r_data_psum, exp_psum[idx]);
			if (r_data_psum !== exp_psum[idx]) begin
				$display("  ERROR mismatch in Iter 1!");
				err_count = err_count + 1;
			end
		end
		r_req_psum = 0;

		// --------------------------------------------------------
		// ITERATION 2
		// --------------------------------------------------------
		start = 1; #25; 
		$display("\n\nReading & Computing Begins for iter 2.....\n\n");
		start = 0;

		wait (compute_done == 1);	
		$display("\n\nFinal PSUM of Iteration 2:");
		#10;
		router_mode_west_0_psum = CLOSED;
		r_req_psum_inter = 0;
		#(8*clk_prd);

		for(i=0;i<X_dim;i=i+1)
		begin
			r_req_psum = 1;
			r_addr_psum = PSUM_LOAD_ADDR + X_dim + i;
			#(clk_prd);
			idx = X_dim + i;
			$display("Iter2: psum[%0d] @ addr %0d = %0d, expected %0d",
			         idx, r_addr_psum, r_data_psum, exp_psum[idx]);
			if (r_data_psum !== exp_psum[idx]) begin
				$display("  ERROR mismatch in Iter 2!");
				err_count = err_count + 1;
			end
		end
		r_req_psum = 0;

		// --------------------------------------------------------
		// ITERATION 3
		// --------------------------------------------------------
		#40;
		start = 1; #25; 
		$display("\n\nReading & Computing Begins for iter 3.....\n\n");
		start = 0;
		
		wait (compute_done == 1);	
		#(8*clk_prd);
		for(i=0;i<X_dim;i=i+1)
		begin
			r_req_psum = 1;
			r_addr_psum = PSUM_LOAD_ADDR + 2*X_dim + i;
			#(clk_prd);
			idx = 2*X_dim + i;
			$display("Iter3: psum[%0d] @ addr %0d = %0d, expected %0d",
			         idx, r_addr_psum, r_data_psum, exp_psum[idx]);
			if (r_data_psum !== exp_psum[idx]) begin
				$display("  ERROR mismatch in Iter 3!");
				err_count = err_count + 1;
			end
		end
		r_req_psum = 0;

		$display("\n==========================================");
		if (err_count == 0) begin
			$display("  PASS: All PSUMs match expected values");
		end else begin
			$display("  FAIL: %0d mismatches detected", err_count);
		end
		$display("  Total #cycles taken: %0d", cycles);
		$display("==========================================\n");
		$finish;
	end 
	
	integer cycles;
	// track # of cycles
	always @(posedge clk)
	begin
		if (reset)
			cycles = 0;
		else
			cycles = cycles + 1;
	end
/*	
	always @(posedge clk) begin
    		if (HMNOC_1cluster_0.u_wght.glb_req_read_wght)
	        $display("WGT GLB READ addr = %d", HMNOC_1cluster_0.u_wght.glb_addr_read_wght);
	end

	always @(posedge clk) begin
	    if (HMNOC_1cluster_0.wght_comp_enable_o)
	    $display("WGT compute out = %d", HMNOC_1cluster_0.wght_comp_data_o);
	end
*/


endmodule

