`timescale 1ns / 1ps

module router_cluster_generic #(
    parameter DATA_BITWIDTH      = 16,
    parameter ADDR_BITWIDTH_GLB   = 10,
    parameter ADDR_BITWIDTH_SPAD  = 9,

    /* CNN parameters */
    parameter kernel_size = 3,
    parameter act_size    = 5,

    /* Base addresses */
    parameter W_READ_ADDR     = 10'h20,
    parameter A_READ_ADDR     = 10'h60,
    parameter PSUM_WRITE_ADDR = 10'h40,

    /* Topology */
    parameter HAS_NORTH = 1,
    parameter HAS_SOUTH = 1,
    parameter HAS_WEST  = 1,
    parameter HAS_EAST  = 1
)(
    input  wire clk,
    input  wire reset,
    input  wire [3:0] router_mode,

    /* ---------------- NoC inputs ---------------- */
    input  wire [DATA_BITWIDTH-1:0] north_data_i,
    input  wire north_enable_i,
    input  wire [DATA_BITWIDTH-1:0] south_data_i,
    input  wire south_enable_i,
    input  wire [DATA_BITWIDTH-1:0] west_data_i,
    input  wire west_enable_i,
    input  wire [DATA_BITWIDTH-1:0] east_data_i,
    input  wire east_enable_i,

    /* ---------------- NoC outputs (cluster-level) --------------- */
    output wire [DATA_BITWIDTH-1:0] north_data_o,
    output wire north_enable_o,
    output wire [DATA_BITWIDTH-1:0] south_data_o,
    output wire south_enable_o,
    output wire [DATA_BITWIDTH-1:0] west_data_o,
    output wire west_enable_o,
    output wire [DATA_BITWIDTH-1:0] east_data_o,
    output wire east_enable_o,

    /* ---------------- GLB interfaces ------------ */
    /* Weight */
    output wire [ADDR_BITWIDTH_GLB-1:0] glb_wght_addr,
    output wire glb_wght_req,
    input  wire [DATA_BITWIDTH-1:0] glb_wght_rdata,

    /* IACT */
    output wire [ADDR_BITWIDTH_GLB-1:0] glb_iact_addr,
    output wire glb_iact_req,
    input  wire [DATA_BITWIDTH-1:0] glb_iact_rdata,

    /* PSUM */
    output wire [ADDR_BITWIDTH_GLB-1:0] glb_psum_addr,
    output wire glb_psum_req,
    output wire [DATA_BITWIDTH-1:0] glb_psum_wdata,

    /* ---------------- Local SPAD interfaces ----------- */
    /* Weight */
    output wire [DATA_BITWIDTH-1:0] wght_spad_data,
    output wire wght_spad_en,

    /* IACT (local consume only) */
    output wire [DATA_BITWIDTH-1:0] iact_data_o,
    output wire iact_en_o,

    /* PSUM */
    input  wire [DATA_BITWIDTH-1:0] psum_spad_data,
    output wire psum_spad_en
);

    /* ============================================================
     * Weight router
     * ==========================================================*/
    router_wght_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),
        .kernel_size(kernel_size),
        .W_READ_ADDR(W_READ_ADDR),
        .HAS_NORTH(HAS_NORTH),
        .HAS_SOUTH(HAS_SOUTH),
        .HAS_WEST(HAS_WEST),
        .HAS_EAST(HAS_EAST)
    ) u_wght (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_read(glb_wght_addr),
        .glb_req_read(glb_wght_req),
        .glb_rdata(glb_wght_rdata),

        .north_data_i(north_data_i),
        .north_enable_i(north_enable_i),
        .south_data_i(south_data_i),
        .south_enable_i(south_enable_i),
        .west_data_i(west_data_i),
        .west_enable_i(west_enable_i),
        .east_data_i(east_data_i),
        .east_enable_i(east_enable_i),

        /* weight router does not forward */
        .north_data_o(),
        .north_enable_o(),
        .south_data_o(),
        .south_enable_o(),
        .west_data_o(),
        .west_enable_o(),
        .east_data_o(),
        .east_enable_o(),

        .spad_data_o(wght_spad_data),
        .spad_en_o(wght_spad_en)
    );

    /* ============================================================
     * IACT router (LOCAL CONSUME ONLY)
     * ==========================================================*/
    router_iact_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .act_size(act_size),
        .A_READ_ADDR(A_READ_ADDR),
        .HAS_NORTH(HAS_NORTH),
        .HAS_SOUTH(HAS_SOUTH),
        .HAS_WEST(HAS_WEST),
        .HAS_EAST(HAS_EAST)
    ) u_iact (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_read(glb_iact_addr),
        .glb_req_read(glb_iact_req),
        .glb_rdata(glb_iact_rdata),

        .north_data_i(north_data_i),
        .north_enable_i(north_enable_i),
        .south_data_i(south_data_i),
        .south_enable_i(south_enable_i),
        .west_data_i(west_data_i),
        .west_enable_i(west_enable_i),
        .east_data_i(east_data_i),
        .east_enable_i(east_enable_i),

        /* IACT routers only expose local output */
        .local_data_o(iact_data_o),
        .local_enable_o(iact_en_o)
    );

    /* ============================================================
     * PSUM router (ONLY forwarder)
     * ==========================================================*/
    router_psum_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),
        .PSUM_READ_ADDR(PSUM_WRITE_ADDR),
        .HAS_NORTH(HAS_NORTH),
        .HAS_SOUTH(HAS_SOUTH),
        .HAS_WEST(HAS_WEST),
        .HAS_EAST(HAS_EAST)
    ) u_psum (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_write(glb_psum_addr),
        .glb_req_write(glb_psum_req),
        .glb_wdata(glb_psum_wdata),

        .north_data_i(north_data_i),
        .north_enable_i(north_enable_i),
        .south_data_i(south_data_i),
        .south_enable_i(south_enable_i),
        .west_data_i(west_data_i),
        .west_enable_i(west_enable_i),
        .east_data_i(east_data_i),
        .east_enable_i(east_enable_i),

        /* PSUM is the ONLY NoC forwarder */
        .north_data_o(north_data_o),
        .north_enable_o(north_enable_o),
        .south_data_o(south_data_o),
        .south_enable_o(south_enable_o),
        .west_data_o(west_data_o),
        .west_enable_o(west_enable_o),
        .east_data_o(east_data_o),
        .east_enable_o(east_enable_o),

        .spad_data_i(psum_spad_data),
        .spad_en_o(psum_spad_en)
    );

endmodule

