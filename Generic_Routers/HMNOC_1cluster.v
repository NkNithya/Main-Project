`timescale 1ns / 1ps

// ------------------------------------------------------------
// Debug-only GLB stub (for TB hierarchy compatibility)
// ------------------------------------------------------------
module glb_debug_stub (
    input write_en_psum
);
endmodule


module HMNOC_1cluster #(
    parameter DATA_BITWIDTH = 16,
    parameter ADDR_BITWIDTH = 10,

    parameter A_READ_ADDR = 100,
    parameter W_READ_ADDR = 0,
    parameter PSUM_ADDR   = 40,

    parameter kernel_size = 3,
    parameter act_size    = 5,
    parameter X_dim       = 5,
    parameter Y_dim       = 1
)(
    input  clk,
    input  reset,
    input  start,

    // ---------------- Status ----------------
    output compute_done,
    output load_done,

    // ---------------- TB → GLB writes ----------------
    input write_en_iact,
    input write_en_wght,
    input [DATA_BITWIDTH-1:0] w_data_iact,
    input [DATA_BITWIDTH-1:0] w_data_wght,
    input [ADDR_BITWIDTH-1:0] w_addr_iact,
    input [ADDR_BITWIDTH-1:0] w_addr_wght,

    // ---------------- TB ← GLB reads ----------------
    input  [ADDR_BITWIDTH-1:0] r_addr_psum,
    input  west_req_read_psum,
    input  west_req_read_psum_inter,
    input  [ADDR_BITWIDTH-1:0] r_addr_psum_inter,
    output reg [DATA_BITWIDTH-1:0] r_data_psum,

    // ---------------- DEBUG EXPORTS ----------------
    output psum_vec_valid,
    output iact_local_en,
    output wght_spad_en,
    output psum_active,

    output [DATA_BITWIDTH*X_dim*Y_dim-1:0] psum_vec_from_pe,
    output [DATA_BITWIDTH-1:0] psum_lane0,
    output [ADDR_BITWIDTH-1:0] psum_addr,
    output psum_we
);

    // =========================================================
    // Router modes
    // =========================================================
    localparam MODE_IDLE  = 4'd0;
    localparam MODE_LOAD  = 4'd1;
    localparam MODE_DRAIN = 4'd3;

    reg [3:0] router_mode;

    always @(posedge clk or posedge reset) begin
        if (reset)
            router_mode <= MODE_IDLE;
        else if (write_en_iact || write_en_wght)
            router_mode <= MODE_LOAD;
        else if (psum_vec_valid)
            router_mode <= MODE_DRAIN;
        else
            router_mode <= MODE_IDLE;
    end

    // =========================================================
    // Stub GLB memories (TB-style synchronous)
    // =========================================================
    reg [DATA_BITWIDTH-1:0] glb_mem_iact [0:(1<<ADDR_BITWIDTH)-1];
    reg [DATA_BITWIDTH-1:0] glb_mem_wght [0:(1<<ADDR_BITWIDTH)-1];
    reg [DATA_BITWIDTH-1:0] glb_mem_psum [0:(1<<ADDR_BITWIDTH)-1];

    always @(posedge clk) begin
        if (write_en_iact)
            glb_mem_iact[w_addr_iact] <= w_data_iact;
        if (write_en_wght)
            glb_mem_wght[w_addr_wght] <= w_data_wght;
    end

    // =========================================================
    // GLB read channels (1-cycle latency)
    // =========================================================
    reg [DATA_BITWIDTH-1:0] glb_rdata_iact;
    reg [DATA_BITWIDTH-1:0] glb_rdata_wght;

    wire [ADDR_BITWIDTH-1:0] glb_addr_iact;
    wire [ADDR_BITWIDTH-1:0] glb_addr_wght;
    wire glb_req_iact;
    wire glb_req_wght;

    always @(posedge clk) begin
        if (glb_req_iact)
            glb_rdata_iact <= glb_mem_iact[glb_addr_iact];
        if (glb_req_wght)
            glb_rdata_wght <= glb_mem_wght[glb_addr_wght];
        if (west_req_read_psum)
            r_data_psum <= glb_mem_psum[r_addr_psum];
    end

    // =========================================================
    // IACT router
    // =========================================================
    wire [DATA_BITWIDTH-1:0] iact_data;

    router_iact_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH),
        .act_size(act_size),
        .A_READ_ADDR(A_READ_ADDR)
    ) u_iact (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_read(glb_addr_iact),
        .glb_req_read(glb_req_iact),
        .glb_rdata(glb_rdata_iact),

        .north_data_i('0), .north_enable_i(1'b0),
        .south_data_i('0), .south_enable_i(1'b0),
        .west_data_i ('0), .west_enable_i (1'b0),
        .east_data_i ('0), .east_enable_i (1'b0),

        .local_data_o(iact_data),
        .local_enable_o(iact_local_en)
    );

    // =========================================================
    // Weight router
    // =========================================================
    wire [DATA_BITWIDTH-1:0] wght_data;

    router_weight_full_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH),
        .kernel_size(kernel_size),
        .W_READ_ADDR(W_READ_ADDR)
    ) u_wght (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_read(glb_addr_wght),
        .glb_req_read(glb_req_wght),
        .glb_rdata(glb_rdata_wght),

        .north_data_i('0), .north_enable_i(1'b0),
        .south_data_i('0), .south_enable_i(1'b0),
        .west_data_i ('0), .west_enable_i (1'b0),
        .east_data_i ('0), .east_enable_i (1'b0),

        .north_data_o(), .north_enable_o(),
        .south_data_o(), .south_enable_o(),
        .west_data_o (), .west_enable_o (),
        .east_data_o (),
        .east_enable_o(),

        .spad_data_o(wght_data),
        .spad_en_o(wght_spad_en)
    );

    // =========================================================
    // Operand alignment
    // =========================================================
    reg [DATA_BITWIDTH-1:0] act_reg, wgt_reg;
    reg act_v, wgt_v;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            act_v <= 0;
            wgt_v <= 0;
        end else begin
            if (iact_local_en) begin act_reg <= iact_data; act_v <= 1; end
            if (wght_spad_en) begin wgt_reg <= wght_data; wgt_v <= 1; end
            if (act_v && wgt_v) begin act_v <= 0; wgt_v <= 0; end
        end
    end

    wire pe_fire = act_v && wgt_v;

    // =========================================================
    // PE cluster
    // =========================================================
    wire [DATA_BITWIDTH*X_dim*Y_dim-1:0] psum_vec;

    PE_cluster_new #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .kernel_size(kernel_size),
        .act_size(act_size),
        .X_dim(X_dim),
        .Y_dim(Y_dim)
    ) u_pe (
        .clk(clk),
        .reset(reset),
        .start(start),
        .act_in(act_reg),
        .filt_in(wgt_reg),
        .load_en_act(pe_fire),
        .load_en_wght(pe_fire),
        .pe_out(psum_vec),
        .compute_done(psum_vec_valid),
        .load_done(load_done)
    );

    assign compute_done     = psum_vec_valid;
    assign psum_vec_from_pe = psum_vec;
    assign psum_lane0       = psum_vec[DATA_BITWIDTH-1:0];

    // =========================================================
    // PSUM write-back
    // =========================================================
    reg [$clog2(act_size+1)-1:0] psum_cnt;
    reg [ADDR_BITWIDTH-1:0] psum_addr_r;

    assign psum_addr   = psum_addr_r;
    assign psum_active = (psum_cnt != 0);
    assign psum_we     = (psum_cnt != 0);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            psum_cnt    <= 0;
            psum_addr_r <= PSUM_ADDR;
        end else begin
            if (psum_vec_valid) begin
                psum_cnt    <= act_size;
                psum_addr_r <= PSUM_ADDR;
            end else if (psum_cnt != 0) begin
                glb_mem_psum[psum_addr_r] <= psum_lane0;
                psum_addr_r <= psum_addr_r + 1;
                psum_cnt    <= psum_cnt - 1;
            end
        end
    end

    // =========================================================
    // Legacy GLB debug hierarchy (TB expects dut.u_glb.write_en_psum)
    // =========================================================
    glb_debug_stub u_glb (
        .write_en_psum(psum_we)
    );

endmodule

