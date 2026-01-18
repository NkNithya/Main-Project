`timescale 1ns / 1ps

module HMNOC_4cluster_wpsum_bias_relu_pipelined_tb;

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
parameter PSUM_ADDR = 40;
parameter X_dim = 3;
parameter Y_dim = 3;
parameter kernel_size = 3;
parameter act_size = 7;
parameter NUM_GLB_IACT = 1;
parameter NUM_GLB_PSUM = 1;
parameter NUM_GLB_WGHT = 1;

localparam CLOSED = 4'd11;

/* clock / ctrl */
reg clk, reset, start;
wire compute_done, load_done;

/* west 0 */
reg write_en_iact_west_0;
reg [DATA_BITWIDTH-1:0] w_data_iact_west_0;
reg [ADDR_BITWIDTH-1:0] w_addr_iact_west_0;
reg write_en_wght_west_0;
reg [DATA_BITWIDTH-1:0] w_data_wght_west_0;
reg [ADDR_BITWIDTH-1:0] w_addr_wght_west_0;
reg r_req_psum_west_0;
reg r_req_psum_inter_west_0;
reg [ADDR_BITWIDTH-1:0] r_addr_psum_west_0;
reg [ADDR_BITWIDTH-1:0] r_addr_psum_inter_west_0;
wire [DATA_BITWIDTH-1:0] r_data_psum_west_0;

/* west 1 */
reg write_en_iact_west_1;
reg [DATA_BITWIDTH-1:0] w_data_iact_west_1;
reg [ADDR_BITWIDTH-1:0] w_addr_iact_west_1;
reg write_en_wght_west_1;
reg [DATA_BITWIDTH-1:0] w_data_wght_west_1;
reg [ADDR_BITWIDTH-1:0] w_addr_wght_west_1;
reg r_req_psum_west_1;
reg r_req_psum_inter_west_1;
reg [ADDR_BITWIDTH-1:0] r_addr_psum_west_1;
reg [ADDR_BITWIDTH-1:0] r_addr_psum_inter_west_1;
wire [DATA_BITWIDTH-1:0] r_data_psum_west_1;

/* east 0 */
reg write_en_iact_east_0;
reg [DATA_BITWIDTH-1:0] w_data_iact_east_0;
reg [ADDR_BITWIDTH-1:0] w_addr_iact_east_0;
reg write_en_wght_east_0;
reg [DATA_BITWIDTH-1:0] w_data_wght_east_0;
reg [ADDR_BITWIDTH-1:0] w_addr_wght_east_0;
reg r_req_psum_east_0;
reg r_req_psum_inter_east_0;
reg [ADDR_BITWIDTH-1:0] r_addr_psum_east_0;
reg [ADDR_BITWIDTH-1:0] r_addr_psum_inter_east_0;
wire [DATA_BITWIDTH-1:0] r_data_psum_east_0;

/* east 1 */
reg write_en_iact_east_1;
reg [DATA_BITWIDTH-1:0] w_data_iact_east_1;
reg [ADDR_BITWIDTH-1:0] w_addr_iact_east_1;
reg write_en_wght_east_1;
reg [DATA_BITWIDTH-1:0] w_data_wght_east_1;
reg [ADDR_BITWIDTH-1:0] w_addr_wght_east_1;
reg r_req_psum_east_1;
reg r_req_psum_inter_east_1;
reg [ADDR_BITWIDTH-1:0] r_addr_psum_east_1;
reg [ADDR_BITWIDTH-1:0] r_addr_psum_inter_east_1;
wire [DATA_BITWIDTH-1:0] r_data_psum_east_1;

/* router enables */
reg west_enable_i_west_0_wght, west_enable_i_west_0_iact;
reg west_enable_i_west_1_wght, west_enable_i_west_1_iact;
reg west_enable_i_east_0_wght, west_enable_i_east_0_iact;
reg west_enable_i_east_1_wght, west_enable_i_east_1_iact;

/* router modes */
reg [3:0] router_mode_west_0_wght, router_mode_west_0_iact, router_mode_west_0_psum;
reg [3:0] router_mode_west_1_wght, router_mode_west_1_iact, router_mode_west_1_psum;
reg [3:0] router_mode_east_0_wght, router_mode_east_0_iact, router_mode_east_0_psum;
reg [3:0] router_mode_east_1_wght, router_mode_east_1_iact, router_mode_east_1_psum;

/* bias */
reg [DATA_BITWIDTH-1:0] w_bias_west_0, w_bias_west_1;
reg [DATA_BITWIDTH-1:0] w_bias_east_0, w_bias_east_1;

/* L1 weight ports */
reg write_en_wght_west_0_l1, write_en_wght_west_1_l1;
reg write_en_wght_east_0_l1, write_en_wght_east_1_l1;
reg [DATA_BITWIDTH-1:0] w_data_wght_west_0_l1, w_data_wght_west_1_l1;
reg [DATA_BITWIDTH-1:0] w_data_wght_east_0_l1, w_data_wght_east_1_l1;
reg [ADDR_BITWIDTH-1:0] w_addr_wght_west_0_l1, w_addr_wght_west_1_l1;
reg [ADDR_BITWIDTH-1:0] w_addr_wght_east_0_l1, w_addr_wght_east_1_l1;

// ============================================================
// ROUTER MODE ENCODING (MATCH RTL EXPECTATION)
// ============================================================
localparam ALL        = 4'd0;
localparam NORTH      = 4'd1;
localparam SOUTH      = 4'd2;
localparam WEST       = 4'd3;
localparam EAST       = 4'd4;
localparam EASTNORTH  = 4'd5;
localparam EASTSOUTH  = 4'd6;
localparam EASTWEST   = 4'd7;
localparam WESTNORTH  = 4'd8;
localparam WESTSOUTH  = 4'd9;
localparam WESTEAST   = 4'd10;

/* DUT */
HMNOC_4cluster_wpsum_bias_relu_pipelined_top dut (
    .clk(clk), .reset(reset), .start(start),
    .compute_done(compute_done), .load_done(load_done),

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
    .r_data_psum_west_0(r_data_psum_west_0),

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
    .r_data_psum_west_1(r_data_psum_west_1),

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
    .r_data_psum_east_0(r_data_psum_east_0),

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
    .r_data_psum_east_1(r_data_psum_east_1),

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
    .router_mode_east_1_psum(router_mode_east_1_psum),

    .w_bias_west_0(w_bias_west_0),
    .w_bias_west_1(w_bias_west_1),
    .w_bias_east_0(w_bias_east_0),
    .w_bias_east_1(w_bias_east_1),

    .write_en_wght_west_0_l1(write_en_wght_west_0_l1),
    .w_data_wght_west_0_l1(w_data_wght_west_0_l1),
    .w_addr_wght_west_0_l1(w_addr_wght_west_0_l1),
    .write_en_wght_west_1_l1(write_en_wght_west_1_l1),
    .w_data_wght_west_1_l1(w_data_wght_west_1_l1),
    .w_addr_wght_west_1_l1(w_addr_wght_west_1_l1),
    .write_en_wght_east_0_l1(write_en_wght_east_0_l1),
    .w_data_wght_east_0_l1(w_data_wght_east_0_l1),
    .w_addr_wght_east_0_l1(w_addr_wght_east_0_l1),
    .write_en_wght_east_1_l1(write_en_wght_east_1_l1),
    .w_data_wght_east_1_l1(w_data_wght_east_1_l1),
    .w_addr_wght_east_1_l1(w_addr_wght_east_1_l1)
);

// ============================================================
// CLOCK GENERATION
// ============================================================
initial clk = 0;
always #5 clk = ~clk;   // 100 MHz


// ============================================================
// FSM OBSERVABILITY REGISTERS
// ============================================================
integer t_l0_start;
integer t_l0_done;
integer t_l1_start;
integer t_l1_done;

reg seen_l0_done;
reg seen_l1_start;
reg seen_l1_done;


// ============================================================
// FSM MONITOR (NON-INTRUSIVE)
// ============================================================
always @(posedge clk) begin
    if (reset) begin
        seen_l0_done  <= 0;
        seen_l1_start <= 0;
        seen_l1_done  <= 0;
    end else begin
        if (dut.compute_done_l0 && !seen_l0_done) begin
            seen_l0_done <= 1;
            t_l0_done = $time;
            $display("[TB] L0 DONE @ %0t ns", t_l0_done);
        end

        if (dut.start_l1 && !seen_l1_start) begin
            seen_l1_start <= 1;
            t_l1_start = $time;
            $display("[TB] L1 START @ %0t ns", t_l1_start);
        end

        if (dut.compute_done_l1 && !seen_l1_done) begin
            seen_l1_done <= 1;
            t_l1_done = $time;
            $display("[TB] L1 DONE @ %0t ns", t_l1_done);
        end
    end
end


// ============================================================
// TEST SEQUENCE
// ============================================================
initial begin
    // --------------------------------------------------------
    // RESET
    // --------------------------------------------------------
    reset = 1;
    start = 0;

    write_en_iact_west_0 = 0;
    write_en_wght_west_0 = 0;
    r_req_psum_west_0   = 0;

    west_enable_i_west_0_wght = 0;
    west_enable_i_west_0_iact = 0;

    router_mode_west_0_wght = CLOSED;
    router_mode_west_0_iact = CLOSED;

    write_en_wght_west_0_l1 = 0;

    #50;
    reset = 0;
    #20;


    // --------------------------------------------------------
    // LOAD SINGLE WEIGHT INTO L0
    // --------------------------------------------------------
    write_en_wght_west_0 = 1;
    w_data_wght_west_0  = 16'd3;
    w_addr_wght_west_0  = W_LOAD_ADDR;
    #10;
    write_en_wght_west_0 = 0;

    west_enable_i_west_0_wght = 1;
    router_mode_west_0_wght  = ALL;
    #20;
    west_enable_i_west_0_wght = 0;
    router_mode_west_0_wght  = CLOSED;


    // --------------------------------------------------------
    // LOAD SINGLE ACTIVATION INTO L0
    // --------------------------------------------------------
    write_en_iact_west_0 = 1;
    w_data_iact_west_0  = 16'd7;
    w_addr_iact_west_0  = A_LOAD_ADDR;
    #10;
    write_en_iact_west_0 = 0;

    west_enable_i_west_0_iact = 1;
    router_mode_west_0_iact  = ALL;
    #20;
    west_enable_i_west_0_iact = 0;
    router_mode_west_0_iact  = CLOSED;


    // --------------------------------------------------------
    // START L0 COMPUTE
    // --------------------------------------------------------
    r_req_psum_west_0 = 1;

    t_l0_start = $time;
    $display("[TB] L0 START @ %0t ns", t_l0_start);

    start = 1;
    
    #10;
    start = 0;


    // --------------------------------------------------------
    // WAIT FOR FULL PIPELINE COMPLETION
    // --------------------------------------------------------
    wait (seen_l1_done);


    // --------------------------------------------------------
    // ASSERT FSM SEQUENCING
    // --------------------------------------------------------
    if (t_l0_done <= t_l0_start)
        $fatal("[FAIL] L0 finished before it started");

    if (t_l1_start <= t_l0_done)
        $fatal("[FAIL] L1 started before L0 completed");

    if (t_l1_done <= t_l1_start)
        $fatal("[FAIL] L1 finished before it started");

    $display("\n[PASS] FSM 2-STAGE SEQUENCING VERIFIED");
    $display("       L0 : %0t -> %0t", t_l0_start, t_l0_done);
    $display("       L1 : %0t -> %0t\n", t_l1_start, t_l1_done);

    $stop;
end


endmodule

