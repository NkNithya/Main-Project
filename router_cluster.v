`timescale 1ns / 1ps

module router_cluster_wpsum #(
    parameter DATA_BITWIDTH      = 16,
    parameter ADDR_BITWIDTH_GLB  = 10,

    parameter X_dim        = 3,
    parameter Y_dim        = 3,
    parameter kernel_size = 3,

    // Base addresses
    parameter A_READ_ADDR        = 0,
    parameter W_READ_ADDR        = 0,
    parameter PSUM_GLB_BASE_ADDR = 0
)(
    input  wire clk,
    input  wire reset,

    // Shared router mode
    input  wire [3:0] router_mode,

    // ---------------- GLB : ACTIVATIONS ----------------
    output wire [ADDR_BITWIDTH_GLB-1:0] iact_glb_addr,
    output wire                         iact_glb_req,
    input  wire [DATA_BITWIDTH-1:0]     iact_glb_rdata,

    // ---------------- GLB : WEIGHTS --------------------
    output wire [ADDR_BITWIDTH_GLB-1:0] wght_glb_addr,
    output wire                         wght_glb_req,
    input  wire [DATA_BITWIDTH-1:0]     wght_glb_rdata,

    // ---------------- GLB : PSUM -----------------------
    output wire [ADDR_BITWIDTH_GLB-1:0] psum_glb_addr,
    output wire                         psum_glb_en,
    output wire [DATA_BITWIDTH-1:0]     psum_glb_data
);

    localparam NUM_PES = X_dim * Y_dim;

    localparam MODE_IDLE  = 4'd0;
    localparam MODE_LOCAL = 4'd1;
    localparam MODE_DRAIN = 4'd3;

    wire [DATA_BITWIDTH-1:0] iact_data;
    wire                     iact_valid;

    wire [DATA_BITWIDTH-1:0] wght_data;
    wire                     wght_valid;

    wire [DATA_BITWIDTH*NUM_PES-1:0] cluster_psum;
    wire                              cluster_psum_valid;

    reg  [DATA_BITWIDTH-1:0] psum_hold;
    reg                      psum_hold_valid;

    router_iact_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .act_size(kernel_size*kernel_size),
        .A_READ_ADDR(A_READ_ADDR)
    ) u_iact_router (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_read(iact_glb_addr),
        .glb_req_read (iact_glb_req),
        .glb_rdata    (iact_glb_rdata),

        .north_data_i ('0), .north_enable_i(1'b0),
        .south_data_i ('0), .south_enable_i(1'b0),
        .west_data_i  ('0), .west_enable_i (1'b0),
        .east_data_i  ('0), .east_enable_i (1'b0),

        .local_data_o  (iact_data),
        .local_enable_o(iact_valid)
    );

    router_weight_full_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .kernel_size(kernel_size),
        .W_READ_ADDR(W_READ_ADDR),
        .HAS_GLB(1),
        .INJECT_DIR(0)
    ) u_wght_router (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_read(wght_glb_addr),
        .glb_req_read (wght_glb_req),
        .glb_rdata    (wght_glb_rdata),

        .north_data_i ('0), .north_enable_i(1'b0),
        .south_data_i ('0), .south_enable_i(1'b0),
        .west_data_i  ('0), .west_enable_i (1'b0),
        .east_data_i  ('0), .east_enable_i (1'b0),

        .north_data_o(), .north_enable_o(),
        .south_data_o(), .south_enable_o(),
        .west_data_o (), .west_enable_o (),
        .east_data_o (), .east_enable_o (),

        .spad_data_o(wght_data),
        .spad_en_o  (wght_valid)
    );

    PE_cluster_new #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .X_dim(X_dim),
        .Y_dim(Y_dim),
        .kernel_size(kernel_size)
    ) u_pe_cluster (
        .clk(clk),
        .reset(reset),

        .iact_data_i (iact_data),
        .iact_valid_i(iact_valid),

        .wght_data_i (wght_data),
        .wght_valid_i(wght_valid),

        .start(router_mode == MODE_LOCAL),

        .psum_data_o (cluster_psum),
        .psum_valid_o(cluster_psum_valid)
    );

    always @(posedge clk) begin
        if (reset) begin
            psum_hold       <= '0;
            psum_hold_valid <= 1'b0;
        end else begin
            if (cluster_psum_valid) begin
                psum_hold       <= cluster_psum[DATA_BITWIDTH-1:0];
                psum_hold_valid <= 1'b1;
            end
            if (router_mode == MODE_DRAIN && psum_glb_en)
                psum_hold_valid <= 1'b0;
        end
    end

    router_psum_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .PSUM_GLB_BASE_ADDR(PSUM_GLB_BASE_ADDR)
    ) u_psum_router (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .local_data_i  (psum_hold),
        .local_enable_i(psum_hold_valid && router_mode == MODE_DRAIN),

        .north_data_i ('0), .north_enable_i(1'b0),
        .south_data_i ('0), .south_enable_i(1'b0),
        .west_data_i  ('0), .west_enable_i (1'b0),
        .east_data_i  ('0), .east_enable_i (1'b0),

        .north_data_o(), .north_enable_o(),
        .south_data_o(), .south_enable_o(),
        .west_data_o (), .west_enable_o (),
        .east_data_o (), .east_enable_o (),

        .spad_data_o(),
        .spad_en_o(),
        .spad_addr_o(),

        .glb_data_o (psum_glb_data),
        .glb_en_o   (psum_glb_en),
        .glb_addr_o (psum_glb_addr)
    );

endmodule

