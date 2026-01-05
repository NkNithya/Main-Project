`timescale 1ns / 1ps

module HMNOC_1cluster_wpsum #(
    parameter DATA_BITWIDTH      = 16,
    parameter ADDR_BITWIDTH_GLB  = 10,

    parameter X_dim        = 3,
    parameter Y_dim        = 3,
    parameter kernel_size = 3,

    parameter A_READ_ADDR        = 0,
    parameter W_READ_ADDR        = 0,
    parameter PSUM_GLB_BASE_ADDR = 0
)(
    input  wire clk,
    input  wire reset,

    // ---------------- Global control ----------------
    input  wire [3:0] router_mode,

    // ================= GLB WRITE INTERFACE =================
    // ---- Activation GLB ----
    input  wire                         iact_glb_we,
    input  wire [ADDR_BITWIDTH_GLB-1:0] iact_glb_waddr,
    input  wire [DATA_BITWIDTH-1:0]     iact_glb_wdata,

    // ---- Weight GLB ----
    input  wire                         wght_glb_we,
    input  wire [ADDR_BITWIDTH_GLB-1:0] wght_glb_waddr,
    input  wire [DATA_BITWIDTH-1:0]     wght_glb_wdata
);

    // ==================================================
    // GLB ↔ Router wires
    // ==================================================

    wire [ADDR_BITWIDTH_GLB-1:0] iact_glb_addr;
    wire                         iact_glb_req;
    wire [DATA_BITWIDTH-1:0]     iact_glb_rdata;

    wire [ADDR_BITWIDTH_GLB-1:0] wght_glb_addr;
    wire                         wght_glb_req;
    wire [DATA_BITWIDTH-1:0]     wght_glb_rdata;

    wire [ADDR_BITWIDTH_GLB-1:0] psum_glb_addr;
    wire                         psum_glb_en;
    wire [DATA_BITWIDTH-1:0]     psum_glb_data;

    // ==================================================
    // GLOBAL BUFFERS
    // ==================================================

    glb_iact #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH(ADDR_BITWIDTH_GLB)
    ) u_glb_iact (
        .clk(clk),
        .reset(reset),

        .read_req (iact_glb_req),
        .r_addr   (iact_glb_addr),
        .r_data   (iact_glb_rdata),

        .write_en (iact_glb_we),
        .w_addr   (iact_glb_waddr),
        .w_data   (iact_glb_wdata)
    );

    glb_weight #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH(ADDR_BITWIDTH_GLB)
    ) u_glb_wght (
        .clk(clk),
        .reset(reset),

        .read_req (wght_glb_req),
        .r_addr   (wght_glb_addr),
        .r_data   (wght_glb_rdata),

        .write_en (wght_glb_we),
        .w_addr   (wght_glb_waddr),
        .w_data   (wght_glb_wdata)
    );

    glb_psum #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH(ADDR_BITWIDTH_GLB)
    ) u_glb_psum (
        .clk(clk),
        .reset(reset),

        .read_req (1'b0),
        .r_addr   ({ADDR_BITWIDTH_GLB{1'b0}}),
        .r_data   (),

        .write_en (psum_glb_en),
        .w_addr   (psum_glb_addr),
        .w_data   (psum_glb_data),

        .r_addr_inter({ADDR_BITWIDTH_GLB{1'b0}}),
        .read_req_inter(1'b0),
        .r_data_inter(),
        .read_en_inter()
    );

    // ==================================================
    // ROUTER + PE CLUSTER
    // ==================================================

    router_cluster_wpsum #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .X_dim(X_dim),
        .Y_dim(Y_dim),
        .kernel_size(kernel_size),
        .A_READ_ADDR(A_READ_ADDR),
        .W_READ_ADDR(W_READ_ADDR),
        .PSUM_GLB_BASE_ADDR(PSUM_GLB_BASE_ADDR)
    ) u_cluster (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .iact_glb_addr (iact_glb_addr),
        .iact_glb_req  (iact_glb_req),
        .iact_glb_rdata(iact_glb_rdata),

        .wght_glb_addr (wght_glb_addr),
        .wght_glb_req  (wght_glb_req),
        .wght_glb_rdata(wght_glb_rdata),

        .psum_glb_addr (psum_glb_addr),
        .psum_glb_en   (psum_glb_en),
        .psum_glb_data (psum_glb_data)
    );

endmodule

