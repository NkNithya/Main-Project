`timescale 1ns / 1ps

module router_cluster_wpsum #(
    parameter DATA_BITWIDTH     = 16,
    parameter ADDR_BITWIDTH_GLB = 10,
    parameter kernel_size       = 3,

    parameter A_READ_ADDR        = 0,
    parameter W_READ_ADDR        = 0,
    parameter PSUM_GLB_BASE_ADDR = 0
)(
    input  wire clk,
    input  wire reset,
    input  wire [3:0] router_mode,

    // -------- IACT GLB --------
    output wire [ADDR_BITWIDTH_GLB-1:0] iact_glb_addr,
    output wire                         iact_glb_req,
    input  wire [DATA_BITWIDTH-1:0]     iact_glb_rdata,

    // -------- WGHT GLB --------
    output wire [ADDR_BITWIDTH_GLB-1:0] wght_glb_addr,
    output wire                         wght_glb_req,
    input  wire [DATA_BITWIDTH-1:0]     wght_glb_rdata,

    // -------- PSUM GLB --------
    output wire [ADDR_BITWIDTH_GLB-1:0] psum_glb_addr,
    output wire                         psum_glb_en,
    output wire [DATA_BITWIDTH-1:0]     psum_glb_data
);

    localparam MODE_IDLE  = 4'd0;
    localparam MODE_LOAD  = 4'd1;
    localparam MODE_LOCAL = 4'd2;
    localparam MODE_DRAIN = 4'd3;

    wire window_reset = reset || (router_mode == MODE_IDLE);

    // -------------------------------------------------
    // Activation router → PE
    // -------------------------------------------------
    wire [DATA_BITWIDTH-1:0] iact_data;
    wire                     iact_valid;

    router_iact_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .act_size(kernel_size * kernel_size),
        .A_READ_ADDR(A_READ_ADDR)
    ) u_iact (
        .clk(clk),
        .reset(window_reset),
        .router_mode(router_mode),

        .glb_addr_read(iact_glb_addr),
        .glb_req_read (iact_glb_req),
        .glb_rdata    (iact_glb_rdata),

        .north_data_i('0), .north_enable_i(1'b0),
        .south_data_i('0), .south_enable_i(1'b0),
        .west_data_i ('0), .west_enable_i (1'b0),
        .east_data_i ('0), .east_enable_i (1'b0),

        .local_data_o  (iact_data),
        .local_enable_o(iact_valid)
    );

    // -------------------------------------------------
    // Weight router → PE
    // -------------------------------------------------
    wire [DATA_BITWIDTH-1:0] wght_data;
    wire                     wght_valid;

    router_weight_full_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .kernel_size(kernel_size),
        .W_READ_ADDR(W_READ_ADDR),
        .HAS_GLB(1)
    ) u_wght (
        .clk(clk),
        .reset(window_reset),
        .router_mode(router_mode),

        .glb_addr_read(wght_glb_addr),
        .glb_req_read (wght_glb_req),
        .glb_rdata    (wght_glb_rdata),

        .north_data_i('0), .north_enable_i(1'b0),
        .south_data_i('0), .south_enable_i(1'b0),
        .west_data_i ('0), .west_enable_i (1'b0),
        .east_data_i ('0), .east_enable_i (1'b0),

        .north_data_o(), .north_enable_o(),
        .south_data_o(), .south_enable_o(),
        .west_data_o (), .west_enable_o (),
        .east_data_o (), .east_enable_o (),

        .spad_data_o(wght_data),
        .spad_en_o  (wght_valid)
    );

    // -------------------------------------------------
    // PE (true CNN kernel)
    // -------------------------------------------------
    wire [DATA_BITWIDTH-1:0] psum;
    wire                     psum_valid;

    PE_cluster_new #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .kernel_size(kernel_size)
    ) u_pe (
        .clk(clk),
        .reset(window_reset),
        .start(router_mode == MODE_LOCAL),

        .iact_data_i (iact_data),
        .iact_valid_i(iact_valid),
        .wght_data_i (wght_data),
        .wght_valid_i(wght_valid),

        .psum_data_o (psum),
        .psum_valid_o(psum_valid)
    );

    // -------------------------------------------------
    // PSUM router → GLB
    // -------------------------------------------------
    router_psum_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .PSUM_GLB_BASE_ADDR(PSUM_GLB_BASE_ADDR)
    ) u_psum (
        .clk(clk),
        .reset(window_reset),
        .router_mode(router_mode),

        .local_data_i  (psum),
        .local_enable_i(psum_valid && router_mode == MODE_DRAIN),

        .north_data_i('0), .north_enable_i(1'b0),
        .south_data_i('0), .south_enable_i(1'b0),
        .west_data_i ('0), .west_enable_i (1'b0),
        .east_data_i ('0), .east_enable_i (1'b0),

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

