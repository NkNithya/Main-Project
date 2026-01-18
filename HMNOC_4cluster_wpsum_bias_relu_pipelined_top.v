`timescale 1ns / 1ps

module HMNOC_4cluster_wpsum_bias_relu_pipelined_top
#(
    parameter ADDR_BITWIDTH_GLB = 6,
    parameter ADDR_BITWIDTH_SPAD = 6,
    parameter DATA_BITWIDTH = 16,
    parameter ADDR_BITWIDTH = 6,
    parameter A_READ_ADDR = 10,
    parameter A_LOAD_ADDR = 10,
    parameter W_READ_ADDR = 0,
    parameter W_LOAD_ADDR = 0,
    parameter PSUM_READ_ADDR = 0,
    parameter PSUM_LOAD_ADDR = 0,
    parameter PSUM_ADDR = 40,
    parameter X_dim = 3,
    parameter Y_dim = 3,
    parameter kernel_size = 3,
    parameter act_size = 7,
    parameter NUM_GLB_IACT = 1,
    parameter NUM_GLB_PSUM = 1,
    parameter NUM_GLB_WGHT = 1
)(
    /* ===== CLOCK / CTRL ===== */
    input clk,
    input reset,
    input start,
    output compute_done,
    output load_done,

    /* ===== WEST 0 ===== */
    input write_en_iact_west_0,
    input [DATA_BITWIDTH-1:0] w_data_iact_west_0,
    input [ADDR_BITWIDTH-1:0] w_addr_iact_west_0,

    input write_en_wght_west_0,
    input [DATA_BITWIDTH-1:0] w_data_wght_west_0,
    input [ADDR_BITWIDTH-1:0] w_addr_wght_west_0,

    input r_req_psum_west_0,
    input r_req_psum_inter_west_0,
    input [ADDR_BITWIDTH-1:0] r_addr_psum_west_0,
    input [ADDR_BITWIDTH-1:0] r_addr_psum_inter_west_0,
    output [DATA_BITWIDTH-1:0] r_data_psum_west_0,

    /* ===== WEST 1 ===== */
    input write_en_iact_west_1,
    input [DATA_BITWIDTH-1:0] w_data_iact_west_1,
    input [ADDR_BITWIDTH-1:0] w_addr_iact_west_1,

    input write_en_wght_west_1,
    input [DATA_BITWIDTH-1:0] w_data_wght_west_1,
    input [ADDR_BITWIDTH-1:0] w_addr_wght_west_1,

    input r_req_psum_west_1,
    input r_req_psum_inter_west_1,
    input [ADDR_BITWIDTH-1:0] r_addr_psum_west_1,
    input [ADDR_BITWIDTH-1:0] r_addr_psum_inter_west_1,
    output [DATA_BITWIDTH-1:0] r_data_psum_west_1,

    /* ===== EAST 0 ===== */
    input write_en_iact_east_0,
    input [DATA_BITWIDTH-1:0] w_data_iact_east_0,
    input [ADDR_BITWIDTH-1:0] w_addr_iact_east_0,

    input write_en_wght_east_0,
    input [DATA_BITWIDTH-1:0] w_data_wght_east_0,
    input [ADDR_BITWIDTH-1:0] w_addr_wght_east_0,

    input r_req_psum_east_0,
    input r_req_psum_inter_east_0,
    input [ADDR_BITWIDTH-1:0] r_addr_psum_east_0,
    input [ADDR_BITWIDTH-1:0] r_addr_psum_inter_east_0,
    output [DATA_BITWIDTH-1:0] r_data_psum_east_0,

    /* ===== EAST 1 ===== */
    input write_en_iact_east_1,
    input [DATA_BITWIDTH-1:0] w_data_iact_east_1,
    input [ADDR_BITWIDTH-1:0] w_addr_iact_east_1,

    input write_en_wght_east_1,
    input [DATA_BITWIDTH-1:0] w_data_wght_east_1,
    input [ADDR_BITWIDTH-1:0] w_addr_wght_east_1,

    input r_req_psum_east_1,
    input r_req_psum_inter_east_1,
    input [ADDR_BITWIDTH-1:0] r_addr_psum_east_1,
    input [ADDR_BITWIDTH-1:0] r_addr_psum_inter_east_1,
    output [DATA_BITWIDTH-1:0] r_data_psum_east_1,

    /* ===== ROUTER CTRL ===== */
    input west_enable_i_west_0_wght,
    input west_enable_i_west_0_iact,
    input west_enable_i_west_1_wght,
    input west_enable_i_west_1_iact,
    input west_enable_i_east_0_wght,
    input west_enable_i_east_0_iact,
    input west_enable_i_east_1_wght,
    input west_enable_i_east_1_iact,

    input [3:0] router_mode_west_0_wght,
    input [3:0] router_mode_west_0_iact,
    input [3:0] router_mode_west_0_psum,
    input [3:0] router_mode_west_1_wght,
    input [3:0] router_mode_west_1_iact,
    input [3:0] router_mode_west_1_psum,
    input [3:0] router_mode_east_0_wght,
    input [3:0] router_mode_east_0_iact,
    input [3:0] router_mode_east_0_psum,
    input [3:0] router_mode_east_1_wght,
    input [3:0] router_mode_east_1_iact,
    input [3:0] router_mode_east_1_psum,
    
    input [DATA_BITWIDTH-1:0]w_bias_west_0,
    input [DATA_BITWIDTH-1:0]w_bias_west_1,
    input [DATA_BITWIDTH-1:0]w_bias_east_0,
    input [DATA_BITWIDTH-1:0]w_bias_east_1,
    
    /* ===== L1 WEIGHT PORTS ===== */

	// west 0
	input write_en_wght_west_0_l1,
	input [DATA_BITWIDTH-1:0] w_data_wght_west_0_l1,
	input [ADDR_BITWIDTH-1:0] w_addr_wght_west_0_l1,

	// west 1
	input write_en_wght_west_1_l1,
	input [DATA_BITWIDTH-1:0] w_data_wght_west_1_l1,
	input [ADDR_BITWIDTH-1:0] w_addr_wght_west_1_l1,

	// east 0
	input write_en_wght_east_0_l1,
	input [DATA_BITWIDTH-1:0] w_data_wght_east_0_l1,
	input [ADDR_BITWIDTH-1:0] w_addr_wght_east_0_l1,

	// east 1
	input write_en_wght_east_1_l1,
	input [DATA_BITWIDTH-1:0] w_data_wght_east_1_l1,
	input [ADDR_BITWIDTH-1:0] w_addr_wght_east_1_l1

	// Debug signals
	output start_l1_dbg;
	output sram_rd_en_dbg;
	output [15:0] sram_rd_addr_dbg;


);

    /* ===== RAW PSUM WIRES FROM HMNOC ===== */
    wire [DATA_BITWIDTH-1:0] psum_west_0_raw;
    wire [DATA_BITWIDTH-1:0] psum_west_1_raw;
    wire [DATA_BITWIDTH-1:0] psum_east_0_raw;
    wire [DATA_BITWIDTH-1:0] psum_east_1_raw;
    wire signed [DATA_BITWIDTH-1:0] relu_out_west_0;
    wire signed [DATA_BITWIDTH-1:0] relu_out_west_1;
    wire signed [DATA_BITWIDTH-1:0] relu_out_east_0;
    wire signed [DATA_BITWIDTH-1:0] relu_out_east_1;
    
    // ===== SRAM write address counters =====
	reg [DATA_BITWIDTH-1:0] sram_wr_addr_w0;
	reg [DATA_BITWIDTH-1:0] sram_wr_addr_w1;
	reg [DATA_BITWIDTH-1:0] sram_wr_addr_e0;
	reg [DATA_BITWIDTH-1:0] sram_wr_addr_e1;

	// ===== SRAM write enables =====
	wire sram_we_w0 = r_req_psum_west_0;
	wire sram_we_w1 = r_req_psum_west_1;
	wire sram_we_e0 = r_req_psum_east_0;
	wire sram_we_e1 = r_req_psum_east_1;
	
	/* ================= L1 CONTROL ================= */
	reg start_l1;
	wire compute_done_l0;
	wire compute_done_l1;

	/* ================= L1 IA (from SRAM) ================= */
	wire write_en_iact_west_0_l1;
	wire write_en_iact_west_1_l1;
	wire write_en_iact_east_0_l1;
	wire write_en_iact_east_1_l1;

	wire [DATA_BITWIDTH-1:0] w_data_iact_west_0_l1;
	wire [DATA_BITWIDTH-1:0] w_data_iact_west_1_l1;
	wire [DATA_BITWIDTH-1:0] w_data_iact_east_0_l1;
	wire [DATA_BITWIDTH-1:0] w_data_iact_east_1_l1;

	wire [ADDR_BITWIDTH-1:0] w_addr_iact_west_0_l1;
	wire [ADDR_BITWIDTH-1:0] w_addr_iact_west_1_l1;
	wire [ADDR_BITWIDTH-1:0] w_addr_iact_east_0_l1;
	wire [ADDR_BITWIDTH-1:0] w_addr_iact_east_1_l1;

	/* ================= L1 PSUM OUTPUTS ================= */
	wire [DATA_BITWIDTH-1:0] psum_west_0_l1;
	wire [DATA_BITWIDTH-1:0] psum_west_1_l1;
	wire [DATA_BITWIDTH-1:0] psum_east_0_l1;
	wire [DATA_BITWIDTH-1:0] psum_east_1_l1;
	
	/* ===== SRAM READ DATA (L0 → L1) ===== */
	wire [DATA_BITWIDTH-1:0] sram_l0_w0_rdata;
	wire [DATA_BITWIDTH-1:0] sram_l0_w1_rdata;
	wire [DATA_BITWIDTH-1:0] sram_l0_e0_rdata;
	wire [DATA_BITWIDTH-1:0] sram_l0_e1_rdata;

	
	/* ===== SRAM READ CONTROL (L1 FEED) ===== */
	reg        sram_rd_en;
	reg [15:0] sram_rd_addr;   // enough for 65025

	
	assign write_en_iact_west_0_l1 = sram_rd_en;
	assign w_data_iact_west_0_l1  = sram_l0_w0_rdata;
	assign w_addr_iact_west_0_l1  = A_LOAD_ADDR + sram_rd_addr;

	assign write_en_iact_west_1_l1 = sram_rd_en;
	assign w_data_iact_west_1_l1  = sram_l0_w1_rdata;
	assign w_addr_iact_west_1_l1  = A_LOAD_ADDR + sram_rd_addr;

	assign write_en_iact_east_0_l1 = sram_rd_en;
	assign w_data_iact_east_0_l1  = sram_l0_e0_rdata;
	assign w_addr_iact_east_0_l1  = A_LOAD_ADDR + sram_rd_addr;

	assign write_en_iact_east_1_l1 = sram_rd_en;
	assign w_data_iact_east_1_l1  = sram_l0_e1_rdata;
	assign w_addr_iact_east_1_l1  = A_LOAD_ADDR + sram_rd_addr;
	
	assign compute_done = compute_done_l1;
	
	//Debugging system assignments
	assign start_l1_dbg   = start_l1;
	assign sram_rd_en_dbg = sram_rd_en;
	assign sram_rd_addr_dbg = sram_rd_addr;

	
	
	localparam ST_IDLE = 3'd0;
	localparam ST_RUN_L0 = 3'd1;
	localparam ST_FEED_L1 = 3'd2;
	localparam ST_RUN_L1 = 3'd3;
	
	reg [2:0] state;


	always @(posedge clk) begin
		if (reset) begin
		    state      <= ST_IDLE;
		    sram_rd_en <= 0;
		    start_l1   <= 0;
		end else begin
		    start_l1 <= 0;  // default

		    case (state)
		        ST_IDLE: begin
		            if (start)
		                state <= ST_RUN_L0;
		        end

		        ST_RUN_L0: begin
		            if (compute_done) begin
		                sram_rd_en <= 1;
		                state <= ST_FEED_L1;
		            end
		        end

		        ST_FEED_L1: begin
		            if (sram_rd_addr == 65024) begin
		                sram_rd_en <= 0;
		                start_l1   <= 1;
		                state <= ST_RUN_L1;
		            end
		        end

		        ST_RUN_L1: begin
		            if (compute_done_l1)
		                state <= ST_IDLE;
		        end
		        
		         default: begin
		            state <= ST_IDLE;
		         end
		    endcase
		end
	end


    /* ===== HMNOC INSTANCE (UNCHANGED INTERFACE) ===== */
    HMNOC_4cluster_wpsum #(
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH(ADDR_BITWIDTH),
        .A_READ_ADDR(A_READ_ADDR),
        .A_LOAD_ADDR(A_LOAD_ADDR),
        .W_READ_ADDR(W_READ_ADDR),
        .W_LOAD_ADDR(W_LOAD_ADDR),
        .PSUM_ADDR(PSUM_ADDR),
        .X_dim(X_dim),
        .Y_dim(Y_dim),
        .kernel_size(kernel_size),
        .act_size(act_size),
        .NUM_GLB_IACT(NUM_GLB_IACT),
        .NUM_GLB_PSUM(NUM_GLB_PSUM),
        .NUM_GLB_WGHT(NUM_GLB_WGHT)
    ) u_hmnoc (
        .clk(clk),
        .reset(reset),
        .start(start),
        .compute_done(compute_done_l0),
        .load_done(load_done),

        /* all ports forwarded 1:1 */
        .write_en_iact_west_0(write_en_iact_west_0),
        .w_data_iact_west_0(w_data_iact_west_0),
        .w_addr_iact_west_0(w_addr_iact_west_0),
        .write_en_wght_west_0(write_en_wght_west_0),
        .w_data_wght_west_0(w_data_wght_west_0),
        .w_addr_wght_west_0(w_addr_wght_west_0),
        .r_req_psum_west_0(r_req_psum_west_0),
        .r_req_psum_inter_west_0(r_req_psum_inter_west_0),
        .r_addr_psum_west_0(r_addr_psum_west_0),
        .r_addr_psum_inter_west_0(r_addr_psum_inter_west_0),
        .r_data_psum_west_0(psum_west_0_raw),

        .write_en_iact_west_1(write_en_iact_west_1),
        .w_data_iact_west_1(w_data_iact_west_1),
        .w_addr_iact_west_1(w_addr_iact_west_1),
        .write_en_wght_west_1(write_en_wght_west_1),
        .w_data_wght_west_1(w_data_wght_west_1),
        .w_addr_wght_west_1(w_addr_wght_west_1),
        .r_req_psum_west_1(r_req_psum_west_1),
        .r_req_psum_inter_west_1(r_req_psum_inter_west_1),
        .r_addr_psum_west_1(r_addr_psum_west_1),
        .r_addr_psum_inter_west_1(r_addr_psum_inter_west_1),
        .r_data_psum_west_1(psum_west_1_raw),

        .write_en_iact_east_0(write_en_iact_east_0),
        .w_data_iact_east_0(w_data_iact_east_0),
        .w_addr_iact_east_0(w_addr_iact_east_0),
        .write_en_wght_east_0(write_en_wght_east_0),
        .w_data_wght_east_0(w_data_wght_east_0),
        .w_addr_wght_east_0(w_addr_wght_east_0),
        .r_req_psum_east_0(r_req_psum_east_0),
        .r_req_psum_inter_east_0(r_req_psum_inter_east_0),
        .r_addr_psum_east_0(r_addr_psum_east_0),
        .r_addr_psum_inter_east_0(r_addr_psum_inter_east_0),
        .r_data_psum_east_0(psum_east_0_raw),

        .write_en_iact_east_1(write_en_iact_east_1),
        .w_data_iact_east_1(w_data_iact_east_1),
        .w_addr_iact_east_1(w_addr_iact_east_1),
        .write_en_wght_east_1(write_en_wght_east_1),
        .w_data_wght_east_1(w_data_wght_east_1),
        .w_addr_wght_east_1(w_addr_wght_east_1),
        .r_req_psum_east_1(r_req_psum_east_1),
        .r_req_psum_inter_east_1(r_req_psum_inter_east_1),
        .r_addr_psum_east_1(r_addr_psum_east_1),
        .r_addr_psum_inter_east_1(r_addr_psum_inter_east_1),
        .r_data_psum_east_1(psum_east_1_raw),

        .west_enable_i_west_0_wght(west_enable_i_west_0_wght),
        .west_enable_i_west_0_iact(west_enable_i_west_0_iact),
        .west_enable_i_west_1_wght(west_enable_i_west_1_wght),
        .west_enable_i_west_1_iact(west_enable_i_west_1_iact),
        .west_enable_i_east_0_wght(west_enable_i_east_0_wght),
        .west_enable_i_east_0_iact(west_enable_i_east_0_iact),
        .west_enable_i_east_1_wght(west_enable_i_east_1_wght),
        .west_enable_i_east_1_iact(west_enable_i_east_1_iact),

        .router_mode_west_0_wght(router_mode_west_0_wght),
        .router_mode_west_0_iact(router_mode_west_0_iact),
        .router_mode_west_0_psum(router_mode_west_0_psum),
        .router_mode_west_1_wght(router_mode_west_1_wght),
        .router_mode_west_1_iact(router_mode_west_1_iact),
        .router_mode_west_1_psum(router_mode_west_1_psum),
        .router_mode_east_0_wght(router_mode_east_0_wght),
        .router_mode_east_0_iact(router_mode_east_0_iact),
        .router_mode_east_0_psum(router_mode_east_0_psum),
        .router_mode_east_1_wght(router_mode_east_1_wght),
        .router_mode_east_1_iact(router_mode_east_1_iact),
        .router_mode_east_1_psum(router_mode_east_1_psum)
    );

    /* ===== RELU ONLY (BIAS = 0) ===== */
    bias_relu #(.BW(DATA_BITWIDTH)) relu_w0 (.in(psum_west_0_raw), .bias(w_bias_west_0), .en(1'b1), .out(relu_out_west_0));
    bias_relu #(.BW(DATA_BITWIDTH)) relu_w1 (.in(psum_west_1_raw), .bias(w_bias_west_1), .en(1'b1), .out(relu_out_west_1));
    bias_relu #(.BW(DATA_BITWIDTH)) relu_e0 (.in(psum_east_0_raw), .bias(w_bias_east_0), .en(1'b1), .out(relu_out_east_0));
    bias_relu #(.BW(DATA_BITWIDTH)) relu_e1 (.in(psum_east_1_raw), .bias(w_bias_east_1), .en(1'b1), .out(relu_out_east_1));

    pool_max_4x4_stream #(
        .DATA_BITWIDTH(DATA_BITWIDTH)
    ) pool_w0 (
        .clk      (clk),
        .reset    (reset),

        // use SAME read request TB already drives
        .r_req    (r_req_psum_west_0),

        // feed ReLU output
       .data_in  (relu_out_west_0),

        // drive SAME output TB already reads
        .data_out (r_data_psum_west_0)
    );

    pool_max_4x4_stream #(
        .DATA_BITWIDTH(DATA_BITWIDTH)
    ) pool_e0 (
        .clk      (clk),
        .reset    (reset),

        // use SAME read request TB already drives
        .r_req    (r_req_psum_east_0),

        // feed ReLU output
       .data_in  (relu_out_east_0),

        // drive SAME output TB already reads
        .data_out (r_data_psum_east_0)
    );
    
    pool_max_4x4_stream #(
        .DATA_BITWIDTH(DATA_BITWIDTH)
    ) pool_w1 (
        .clk      (clk),
        .reset    (reset),

        // use SAME read request TB already drives
        .r_req    (r_req_psum_west_1),

        // feed ReLU output
       .data_in  (relu_out_west_1),

        // drive SAME output TB already reads
        .data_out (r_data_psum_west_1)
    );

    pool_max_4x4_stream #(
        .DATA_BITWIDTH(DATA_BITWIDTH)
    ) pool_e1 (
        .clk      (clk),
        .reset    (reset),

        // use SAME read request TB already drives
        .r_req    (r_req_psum_east_1),

        // feed ReLU output
       .data_in  (relu_out_east_1),

        // drive SAME output TB already reads
        .data_out (r_data_psum_east_1)
    );
    
    always @(posedge clk) begin
		if (reset) begin
		    sram_wr_addr_w0 <= 0;
		    sram_wr_addr_w1 <= 0;
		    sram_wr_addr_e0 <= 0;
		    sram_wr_addr_e1 <= 0;
		end 
		else begin
		    if (sram_we_w0) sram_wr_addr_w0 <= sram_wr_addr_w0 + 1;
		    if (sram_we_w1) sram_wr_addr_w1 <= sram_wr_addr_w1 + 1;
		    if (sram_we_e0) sram_wr_addr_e0 <= sram_wr_addr_e0 + 1;
		    if (sram_we_e1) sram_wr_addr_e1 <= sram_wr_addr_e1 + 1;
		end
	end
	
	
	always @(posedge clk) begin
		if (reset) begin
		    sram_rd_addr <= 0;
		end else if (sram_rd_en) begin
		    sram_rd_addr <= sram_rd_addr + 1;
		end else begin
		    sram_rd_addr <= 0;
		end
	end

	feature_map_sram #(
		.DATA_BITWIDTH(DATA_BITWIDTH),
		.DEPTH(65025)
	) sram_l0_w0 (
		.clk   (clk),
		.reset (reset),

		// WRITE from L0
		.we    (sram_we_w0),
		.waddr (sram_wr_addr_w0),
		.wdata (r_data_psum_west_0),

		// READ to L1
		.re    (sram_rd_en),
		.raddr (sram_rd_addr),
		.rdata (sram_l0_w0_rdata)
	);

	feature_map_sram #(
		.DATA_BITWIDTH(DATA_BITWIDTH),
		.DEPTH(65025)
	) sram_l0_w1 (
		.clk   (clk),
		.reset (reset),

		// WRITE from L0
		.we    (sram_we_w1),
		.waddr (sram_wr_addr_w1),
		.wdata (r_data_psum_west_1),

		// READ to L1
		.re    (sram_rd_en),
		.raddr (sram_rd_addr),
		.rdata (sram_l0_w1_rdata)
	);

	feature_map_sram #(
		.DATA_BITWIDTH(DATA_BITWIDTH),
		.DEPTH(65025)
	) sram_l0_e0 (
		.clk   (clk),
		.reset (reset),

		// WRITE from L0
		.we    (sram_we_e0),
		.waddr (sram_wr_addr_e0),
		.wdata (r_data_psum_east_0),

		// READ to L1
		.re    (sram_rd_en),
		.raddr (sram_rd_addr),
		.rdata (sram_l0_e0_rdata)
	);

	feature_map_sram #(
		.DATA_BITWIDTH(DATA_BITWIDTH),
		.DEPTH(65025)
	) sram_l0_e1 (
		.clk   (clk),
		.reset (reset),

		// WRITE from L0
		.we    (sram_we_e1),
		.waddr (sram_wr_addr_e1),
		.wdata (r_data_psum_east_0),

		// READ to L1
		.re    (sram_rd_en),
		.raddr (sram_rd_addr),
		.rdata (sram_l0_e1_rdata)
	);

	HMNOC_4cluster_wpsum #(
		.ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
		.ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),
		.DATA_BITWIDTH(DATA_BITWIDTH),
		.ADDR_BITWIDTH(ADDR_BITWIDTH),
		.A_READ_ADDR(A_READ_ADDR),
		.A_LOAD_ADDR(A_LOAD_ADDR),
		.W_READ_ADDR(W_READ_ADDR),
		.W_LOAD_ADDR(W_LOAD_ADDR),
		.PSUM_ADDR(PSUM_ADDR),
		.X_dim(X_dim),
		.Y_dim(Y_dim),
		.kernel_size(kernel_size),
		.act_size(act_size),
		.NUM_GLB_IACT(NUM_GLB_IACT),
		.NUM_GLB_PSUM(NUM_GLB_PSUM),
		.NUM_GLB_WGHT(NUM_GLB_WGHT)
	) u_hmnoc_l1 (
		.clk(clk),
		.reset(reset),
		.start(start_l1),
		.compute_done(compute_done_l1),
		.load_done(),   // unused for L1

		/* ===== IA FROM SRAM ===== */
		.write_en_iact_west_0(write_en_iact_west_0_l1),
		.w_data_iact_west_0 (w_data_iact_west_0_l1),
		.w_addr_iact_west_0 (w_addr_iact_west_0_l1),

		.write_en_iact_west_1(write_en_iact_west_1_l1),
		.w_data_iact_west_1 (w_data_iact_west_1_l1),
		.w_addr_iact_west_1 (w_addr_iact_west_1_l1),

		.write_en_iact_east_0(write_en_iact_east_0_l1),
		.w_data_iact_east_0 (w_data_iact_east_0_l1),
		.w_addr_iact_east_0 (w_addr_iact_east_0_l1),

		.write_en_iact_east_1(write_en_iact_east_1_l1),
		.w_data_iact_east_1 (w_data_iact_east_1_l1),
		.w_addr_iact_east_1 (w_addr_iact_east_1_l1),

		/* ===== WEIGHTS (FROM TB OR WEIGHT SRAM) ===== */
		.write_en_wght_west_0(write_en_wght_west_0_l1),
		.w_data_wght_west_0 (w_data_wght_west_0_l1),
		.w_addr_wght_west_0 (w_addr_wght_west_0_l1),

		.write_en_wght_west_1(write_en_wght_west_1_l1),
		.w_data_wght_west_1 (w_data_wght_west_1_l1),
		.w_addr_wght_west_1 (w_addr_wght_west_1_l1),

		.write_en_wght_east_0(write_en_wght_east_0_l1),
		.w_data_wght_east_0 (w_data_wght_east_0_l1),
		.w_addr_wght_east_0 (w_addr_wght_east_0_l1),

		.write_en_wght_east_1(write_en_wght_east_1_l1),
		.w_data_wght_east_1 (w_data_wght_east_1_l1),
		.w_addr_wght_east_1 (w_addr_wght_east_1_l1),


		/* ===== PSUM OUTPUTS ===== */
		.r_req_psum_west_0(r_req_psum_west_0),
		.r_req_psum_inter_west_0(r_req_psum_inter_west_0),
		.r_addr_psum_west_0(r_addr_psum_west_0),
		.r_addr_psum_inter_west_0(r_addr_psum_inter_west_0),
		.r_data_psum_west_0(psum_west_0_l1),

		.r_req_psum_west_1(r_req_psum_west_1),
		.r_req_psum_inter_west_1(r_req_psum_inter_west_1),
		.r_addr_psum_west_1(r_addr_psum_west_1),
		.r_addr_psum_inter_west_1(r_addr_psum_inter_west_1),
		.r_data_psum_west_1(psum_west_1_l1),

		.r_req_psum_east_0(r_req_psum_east_0),
		.r_req_psum_inter_east_0(r_req_psum_inter_east_0),
		.r_addr_psum_east_0(r_addr_psum_east_0),
		.r_addr_psum_inter_east_0(r_addr_psum_inter_east_0),
		.r_data_psum_east_0(psum_east_0_l1),

		.r_req_psum_east_1(r_req_psum_east_1),
		.r_req_psum_inter_east_1(r_req_psum_inter_east_1),
		.r_addr_psum_east_1(r_addr_psum_east_1),
		.r_addr_psum_inter_east_1(r_addr_psum_inter_east_1),
		.r_data_psum_east_1(psum_east_1_l1),

		/* ===== ROUTER CTRL (CAN BE TIED SAME AS L0) ===== */
		.west_enable_i_west_0_wght(west_enable_i_west_0_wght),
		.west_enable_i_west_0_iact(1'b1),
		.west_enable_i_west_1_wght(west_enable_i_west_1_wght),
		.west_enable_i_west_1_iact(1'b1),
		.west_enable_i_east_0_wght(west_enable_i_east_0_wght),
		.west_enable_i_east_0_iact(1'b1),
		.west_enable_i_east_1_wght(west_enable_i_east_1_wght),
		.west_enable_i_east_1_iact(1'b1),

		.router_mode_west_0_wght(router_mode_west_0_wght),
		.router_mode_west_0_iact(router_mode_west_0_iact),
		.router_mode_west_0_psum(router_mode_west_0_psum),

		.router_mode_west_1_wght(router_mode_west_1_wght),
		.router_mode_west_1_iact(router_mode_west_1_iact),
		.router_mode_west_1_psum(router_mode_west_1_psum),

		.router_mode_east_0_wght(router_mode_east_0_wght),
		.router_mode_east_0_iact(router_mode_east_0_iact),
		.router_mode_east_0_psum(router_mode_east_0_psum),

		.router_mode_east_1_wght(router_mode_east_1_wght),
		.router_mode_east_1_iact(router_mode_east_1_iact),
		.router_mode_east_1_psum(router_mode_east_1_psum)
);





endmodule

