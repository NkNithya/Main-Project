`timescale 1ns/1ps

module router_cluster_wpsum_generic
#(
    parameter DATA_BITWIDTH      = 16,
    parameter ADDR_BITWIDTH_GLB  = 10,
    parameter ADDR_BITWIDTH_SPAD = 9,

    parameter A_READ_ADDR   = 100,
    parameter A_LOAD_ADDR   = 0,

    parameter W_READ_ADDR   = 0,
    parameter W_LOAD_ADDR   = 0,

    parameter PSUM_READ_ADDR = 0,
    parameter PSUM_LOAD_ADDR = 0,

    parameter X_dim       = 5,
    parameter Y_dim       = 3,
    parameter kernel_size = 3,
    parameter act_size    = 5,

    // Per-router compute direction (0=N,1=S,2=W,3=E)
    parameter integer IACT_COMP_DIR = 2,
    parameter integer WGHT_COMP_DIR = 2,
    parameter integer PSUM_COMP_DIR = 2
)
(
    input clk,
    input reset,

    // ============================================================
    // IACT Router External Interface
    // ============================================================
    input  [3:0] router_mode_iact,

    input  [DATA_BITWIDTH-1:0] north_data_i_iact,
    input                      north_enable_i_iact,

    input  [DATA_BITWIDTH-1:0] south_data_i_iact,
    input                      south_enable_i_iact,

    input  [DATA_BITWIDTH-1:0] west_data_i_iact,
    input                      west_enable_i_iact,

    input  [DATA_BITWIDTH-1:0] east_data_i_iact,
    input                      east_enable_i_iact,

    output [DATA_BITWIDTH-1:0] north_data_o_iact,
    output                     north_enable_o_iact,

    output [DATA_BITWIDTH-1:0] south_data_o_iact,
    output                     south_enable_o_iact,

    output [DATA_BITWIDTH-1:0] west_data_o_iact,
    output                     west_enable_o_iact,

    output [DATA_BITWIDTH-1:0] east_data_o_iact,
    output                     east_enable_o_iact,

    output [ADDR_BITWIDTH_GLB-1:0] iact_glb_addr_read,
    output                         iact_glb_req_read,

    // ============================================================
    // WGHT Router External Interface
    // ============================================================
    input  [3:0] router_mode_wght,

    input  [DATA_BITWIDTH-1:0] north_data_i_wght,
    input                      north_enable_i_wght,

    input  [DATA_BITWIDTH-1:0] south_data_i_wght,
    input                      south_enable_i_wght,

    input  [DATA_BITWIDTH-1:0] west_data_i_wght,
    input                      west_enable_i_wght,

    input  [DATA_BITWIDTH-1:0] east_data_i_wght,
    input                      east_enable_i_wght,

    output [DATA_BITWIDTH-1:0] north_data_o_wght,
    output                     north_enable_o_wght,

    output [DATA_BITWIDTH-1:0] south_data_o_wght,
    output                     south_enable_o_wght,

    output [DATA_BITWIDTH-1:0] west_data_o_wght,
    output                     west_enable_o_wght,

    output [DATA_BITWIDTH-1:0] east_data_o_wght,
    output                     east_enable_o_wght,

    output [ADDR_BITWIDTH_GLB-1:0] wght_glb_addr_read,
    output                         wght_glb_req_read,
    
    output [DATA_BITWIDTH-1:0]     wght_comp_data_o,
    output                         wght_comp_enable_o,

    // ============================================================
    // PSUM Router External Interface
    // ============================================================
    input  [3:0] router_mode_psum,

    input  [DATA_BITWIDTH*X_dim-1:0] north_data_i_psum,
    input                            north_enable_i_psum,

    input  [DATA_BITWIDTH*X_dim-1:0] south_data_i_psum,
    input                            south_enable_i_psum,

    input  [DATA_BITWIDTH*X_dim-1:0] west_data_i_psum,
    input                            west_enable_i_psum,

    input  [DATA_BITWIDTH*X_dim-1:0] east_data_i_psum,
    input                            east_enable_i_psum,

    output [DATA_BITWIDTH*X_dim-1:0] north_data_o_psum,
    output                           north_enable_o_psum,

    output [DATA_BITWIDTH*X_dim-1:0] south_data_o_psum,
    output                           south_enable_o_psum,

    output [DATA_BITWIDTH*X_dim-1:0] west_data_o_psum,
    output                           west_enable_o_psum,

    output [DATA_BITWIDTH*X_dim-1:0] east_data_o_psum,
    output                           east_enable_o_psum,

    output [DATA_BITWIDTH-1:0]        psum_data_o,
    output                             psum_enable_o,
    output [ADDR_BITWIDTH_GLB-1:0]     psum_addr_o
);

    // ============================================================
    // Instantiate GENERIC IACT Router
    // ============================================================
    router_generic_iact #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),

        .X_dim(X_dim),
        .Y_dim(Y_dim),
        .kernel_size(kernel_size),
        .act_size(act_size),

        .A_READ_ADDR(A_READ_ADDR),
        .A_LOAD_ADDR(A_LOAD_ADDR),

        .COMPUTE_DIR(IACT_COMP_DIR)
    ) u_iact (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode_iact),

        .glb_addr_read(iact_glb_addr_read),
        .glb_req_read(iact_glb_req_read),

        .north_data_i(north_data_i_iact),
        .north_enable_i(north_enable_i_iact),

        .south_data_i(south_data_i_iact),
        .south_enable_i(south_enable_i_iact),

        .west_data_i(west_data_i_iact),
        .west_enable_i(west_enable_i_iact),

        .east_data_i(east_data_i_iact),
        .east_enable_i(east_enable_i_iact),

        .north_data_o(north_data_o_iact),
        .north_enable_o(north_enable_o_iact),

        .south_data_o(south_data_o_iact),
        .south_enable_o(south_enable_o_iact),

        .west_data_o(west_data_o_iact),
        .west_enable_o(west_enable_o_iact),

        .east_data_o(east_data_o_iact),
        .east_enable_o(east_enable_o_iact)
    );
    
    wire [DATA_BITWIDTH-1:0] wght_spad_wdata;
    wire                     wght_spad_wenable;

    // ============================================================
    // Instantiate GENERIC WGHT Router
    // ============================================================
    router_generic_wght #(
        .DATA_BITWIDTH     (DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB (ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),
        .X_dim             (X_dim),
        .Y_dim             (Y_dim),
        .kernel_size       (kernel_size),
        .act_size          (act_size),
        .W_READ_ADDR       (W_READ_ADDR),
        .W_LOAD_ADDR       (W_LOAD_ADDR),
        .COMPUTE_DIR       (WGHT_COMP_DIR)
    ) u_wght (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode_wght),

        .north_data_i(north_data_i_wght),
        .north_enable_i(north_enable_i_wght),

        .south_data_i(south_data_i_wght),
        .south_enable_i(south_enable_i_wght),

        .west_data_i(west_data_i_wght),
        .west_enable_i(west_enable_i_wght),

        .east_data_i(east_data_i_wght),
        .east_enable_i(east_enable_i_wght),

        .north_data_o(north_data_o_wght),
        .north_enable_o(north_enable_o_wght),

        .south_data_o(south_data_o_wght),
        .south_enable_o(south_enable_o_wght),

        // *** THIS IS THE REAL COMPUTE PATH ***
        .spad_wdata_o  (wght_spad_wdata),
        .spad_wenable_o(wght_spad_wenable),

        .east_data_o(east_data_o_wght),
        .east_enable_o(east_enable_o_wght),

        // routing-only west output (if you still want to use it on NoC)
        .west_data_o_routed  (west_data_o_wght),
        .west_enable_o_routed(west_enable_o_wght),

        .glb_addr_read_wght(wght_glb_addr_read),
        .glb_req_read_wght (wght_glb_req_read)
    );

    assign wght_comp_data_o   = wght_spad_wdata;
    assign wght_comp_enable_o = wght_spad_wenable;

    // ============================================================
    // Instantiate GENERIC PSUM Router
    // ============================================================
    router_generic_psum #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),

        .X_dim(X_dim),
        .Y_dim(Y_dim),
        .kernel_size(kernel_size),
        .act_size(act_size),

        .PSUM_READ_ADDR(PSUM_READ_ADDR),
        .PSUM_LOAD_ADDR(PSUM_LOAD_ADDR),

        .COMPUTE_DIR(PSUM_COMP_DIR)
    ) u_psum (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode_psum),

        .north_data_i(north_data_i_psum),
        .north_enable_i(north_enable_i_psum),

        .south_data_i(south_data_i_psum),
        .south_enable_i(south_enable_i_psum),

        .west_data_i(west_data_i_psum),
        .west_enable_i(west_enable_i_psum),

        .east_data_i(east_data_i_psum),
        .east_enable_i(east_enable_i_psum),

        .north_data_o(north_data_o_psum),
        .north_enable_o(north_enable_o_psum),

        .south_data_o(south_data_o_psum),
        .south_enable_o(south_enable_o_psum),

        .west_data_o_wide(west_data_o_psum),       // FIXED
        .west_enable_o_wide(west_enable_o_psum),   // FIXED

        .east_data_o(east_data_o_psum),
        .east_enable_o(east_enable_o_psum),

        .psum_data_o(psum_data_o),
        .psum_enable_o(psum_enable_o),
        .psum_write_addr(psum_addr_o)
    );

endmodule

