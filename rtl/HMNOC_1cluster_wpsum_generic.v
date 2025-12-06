`timescale 1ns / 1ps

module HMNOC_1cluster_wpsum_generic
#(
    // GLB / SPAD / data widths
    parameter ADDR_BITWIDTH_GLB  = 10,
    parameter ADDR_BITWIDTH_SPAD = 9,
    parameter DATA_BITWIDTH      = 16,
    parameter ADDR_BITWIDTH      = 10,

    // Base addresses
    parameter A_READ_ADDR   = 100,
    parameter A_LOAD_ADDR   = 100,
    parameter W_READ_ADDR   = 0,
    parameter W_LOAD_ADDR   = 0,
    parameter PSUM_READ_ADDR = 0,
    parameter PSUM_LOAD_ADDR = 0,
    parameter PSUM_ADDR      = 500,

    // Geometry
    parameter X_dim       = 3,
    parameter Y_dim       = 3,
    parameter kernel_size = 3,
    parameter act_size    = 5,

    // GLB multiplicity
    parameter NUM_GLB_IACT = 1,
    parameter NUM_GLB_PSUM = 1,
    parameter NUM_GLB_WGHT = 1,

    // Direction of compute interface for each router
    // (0=N,1=S,2=W,3=E) – you can change these later if needed
    parameter integer IACT_COMP_DIR = 3,  // use EAST for PE interface
    parameter integer WGHT_COMP_DIR = 3,  // use EAST for PE interface
    parameter integer PSUM_COMP_DIR = 3   // use EAST for PE interface
)
(
    // ------------------------------------------------------------
    // Global control
    // ------------------------------------------------------------
    input clk,
    input reset,
    input start,

    output compute_done,
    output load_done,

    // ------------------------------------------------------------
    // GLB Interports (external TB/controller <-> GLB)
    // ------------------------------------------------------------
    input                     write_en_iact,
    input                     write_en_wght,

    input  [DATA_BITWIDTH-1:0] w_data_iact,
    input  [ADDR_BITWIDTH-1:0] w_addr_iact,

    input  [DATA_BITWIDTH-1:0] w_data_wght,
    input  [ADDR_BITWIDTH-1:0] w_addr_wght,

    input  [ADDR_BITWIDTH-1:0] r_addr_psum,
    input  [ADDR_BITWIDTH-1:0] r_addr_psum_inter,

    // TB/controller driven read enables for intermediate psum
    input                      west_0_req_read_psum_inter,
    input                      west_0_req_read_psum,  // kept for compatibility, unused internally

    output [DATA_BITWIDTH-1:0] r_data_psum,

    // ------------------------------------------------------------
    // ROUTER Interports (mode + west-side enables from TB/NoC)
    // ------------------------------------------------------------
    input west_enable_i_west_0_wght,
    input west_enable_i_west_0_iact,

    input [3:0] router_mode_west_0_wght,
    input [3:0] router_mode_west_0_iact,

    // ------------------------------------------------------------
    // IACT interports with other directions
    // ------------------------------------------------------------
    input  [DATA_BITWIDTH-1:0] north_data_i_iact,
    input                      north_enable_i_iact,
    output [DATA_BITWIDTH-1:0] north_data_o_iact,
    output                     north_enable_o_iact,

    input  [DATA_BITWIDTH-1:0] south_data_i_iact,
    input                      south_enable_i_iact,
    output [DATA_BITWIDTH-1:0] south_data_o_iact,
    output                     south_enable_o_iact,

    input  [DATA_BITWIDTH-1:0] east_data_i_iact,
    input                      east_enable_i_iact,
    output [DATA_BITWIDTH-1:0] east_data_o_iact,
    output                     east_enable_o_iact,

    // ------------------------------------------------------------
    // WGHT interports with other directions
    // ------------------------------------------------------------
    input  [DATA_BITWIDTH-1:0] north_data_i_wght,
    input                      north_enable_i_wght,
    output [DATA_BITWIDTH-1:0] north_data_o_wght,
    output                     north_enable_o_wght,

    input  [DATA_BITWIDTH-1:0] south_data_i_wght,
    input                      south_enable_i_wght,
    output [DATA_BITWIDTH-1:0] south_data_o_wght,
    output                     south_enable_o_wght,

    input  [DATA_BITWIDTH-1:0] east_data_i_wght,
    input                      east_enable_i_wght,
    output [DATA_BITWIDTH-1:0] east_data_o_wght,
    output                     east_enable_o_wght,

    // ------------------------------------------------------------
    // PSUM router north/south interface
    // ------------------------------------------------------------
    input  [3:0]                   router_mode_west_0_psum,
    input  [DATA_BITWIDTH*X_dim-1:0] north_data_i_psum,
    input                            north_enable_i_psum,
    output [DATA_BITWIDTH*X_dim-1:0] south_data_o_psum,
    output                           south_enable_o_psum

    // (West/East psum directions are internal only: GLB + PE)
);

    // ============================================================
    // Internal wires between generic router cluster, GLB, and PE
    // ============================================================

    // ---- IACT GLB read interface ----
    wire [ADDR_BITWIDTH_GLB-1:0] iact_glb_addr_read;
    wire                         iact_glb_req_read;
    wire [DATA_BITWIDTH-1:0]     r_data_iact;

    // ---- WGHT GLB read interface ----
    wire [ADDR_BITWIDTH_GLB-1:0] wght_glb_addr_read;
    wire                         wght_glb_req_read;
    wire [DATA_BITWIDTH-1:0]     r_data_wght;

    // ---- PSUM intermediate GLB read interface ----
    wire [DATA_BITWIDTH*X_dim-1:0] r_data_psum_inter;
    wire                          read_en_psum_inter;

    // ---- PSUM GLB write-back from router ----
    wire [DATA_BITWIDTH-1:0]     psum_data_o;
    wire                         psum_enable_o;
    wire [ADDR_BITWIDTH_GLB-1:0] psum_addr_o;

    // ---- PSUM east (PE side) link ----
    wire [DATA_BITWIDTH*X_dim-1:0] east_data_i_psum;
    wire                           east_enable_i_psum;   // PE -> router (valid)
    wire [DATA_BITWIDTH*X_dim-1:0] east_data_o_psum;     // router -> PE
    wire                           east_enable_o_psum;   // router -> neighbor (unused here)

    // ---- PSUM west (GLB/intermediate) link ----
    wire [DATA_BITWIDTH*X_dim-1:0] west_data_i_psum;
    wire                           west_enable_i_psum;
    wire [DATA_BITWIDTH*X_dim-1:0] west_data_o_psum;
    wire                           west_enable_o_psum;
    
    wire [DATA_BITWIDTH-1:0] pe_wght_in;
    wire                     pe_load_en_wght;

    // Map GLB psum_inter signals to west side of PSUM router
    assign west_data_i_psum  = r_data_psum_inter;
    assign west_enable_i_psum = read_en_psum_inter;

    // compute_done comes from PE's "east" output valid into router
    assign compute_done = east_enable_i_psum;

    // ============================================================
    // GENERIC ROUTER CLUSTER
    // ============================================================
    router_cluster_wpsum_generic #(
        .DATA_BITWIDTH     (DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB (ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),

        .A_READ_ADDR   (A_READ_ADDR),
        .A_LOAD_ADDR   (A_LOAD_ADDR),
        .W_READ_ADDR   (W_READ_ADDR),
        .W_LOAD_ADDR   (W_LOAD_ADDR),
        .PSUM_READ_ADDR(PSUM_READ_ADDR),
        .PSUM_LOAD_ADDR(PSUM_LOAD_ADDR),

        .X_dim       (X_dim),
        .Y_dim       (Y_dim),
        .kernel_size (kernel_size),
        .act_size    (act_size),

        .IACT_COMP_DIR(IACT_COMP_DIR),
        .WGHT_COMP_DIR(WGHT_COMP_DIR),
        .PSUM_COMP_DIR(PSUM_COMP_DIR)
    ) router_cluster_0 (
        .clk  (clk),
        .reset(reset),

        // ---------------- IACT router ----------------
        .router_mode_iact      (router_mode_west_0_iact),

        .north_data_i_iact     (north_data_i_iact),
        .north_enable_i_iact   (north_enable_i_iact),

        .south_data_i_iact     (south_data_i_iact),
        .south_enable_i_iact   (south_enable_i_iact),

        // GLB feeds IACT data on west input, enable from TB/neighbor
        .west_data_i_iact      (r_data_iact),
        .west_enable_i_iact    (west_enable_i_west_0_iact),

        .east_data_i_iact      (east_data_i_iact),
        .east_enable_i_iact    (east_enable_i_iact),

        .north_data_o_iact     (north_data_o_iact),
        .north_enable_o_iact   (north_enable_o_iact),

        .south_data_o_iact     (south_data_o_iact),
        .south_enable_o_iact   (south_enable_o_iact),

        .west_data_o_iact      (/* unused or to west neighbor */),
        .west_enable_o_iact    (/* unused or to west neighbor */),

        .east_data_o_iact      (/* used below for PE act_in via wire */),
        .east_enable_o_iact    (/* used below for PE load_en_act via wire */),

        .iact_glb_addr_read    (iact_glb_addr_read),
        .iact_glb_req_read     (iact_glb_req_read),

        // ---------------- WGHT router ----------------
        .router_mode_wght      (router_mode_west_0_wght),

        .north_data_i_wght     (north_data_i_wght),
        .north_enable_i_wght   (north_enable_i_wght),

        .south_data_i_wght     (south_data_i_wght),
        .south_enable_i_wght   (south_enable_i_wght),

        .west_data_i_wght      (r_data_wght),
        .west_enable_i_wght    (west_enable_i_west_0_wght),

        .east_data_i_wght      (east_data_i_wght),
        .east_enable_i_wght    (east_enable_i_wght),

        .north_data_o_wght     (north_data_o_wght),
        .north_enable_o_wght   (north_enable_o_wght),

        .south_data_o_wght     (south_data_o_wght),
        .south_enable_o_wght   (south_enable_o_wght),

        .west_data_o_wght      (/* unused or to west neighbor */),
        .west_enable_o_wght    (/* unused or to west neighbor */),

        .east_data_o_wght      (/* used below for PE filt_in via wire */),
        .east_enable_o_wght    (/* used below for PE load_en_wght via wire */),

        .wght_glb_addr_read    (wght_glb_addr_read),
        .wght_glb_req_read     (wght_glb_req_read),
        
        .wght_comp_data_o   (pe_wght_in),
        .wght_comp_enable_o (pe_load_en_wght),

        // ---------------- PSUM router ----------------
        .router_mode_psum      (router_mode_west_0_psum),

        .north_data_i_psum     (north_data_i_psum),
        .north_enable_i_psum   (north_enable_i_psum),

        .south_data_i_psum     ({DATA_BITWIDTH*X_dim{1'b0}}), // no south input into this cluster
        .south_enable_i_psum   (1'b0),

        .west_data_i_psum      (west_data_i_psum),
        .west_enable_i_psum    (west_enable_i_psum),

        .east_data_i_psum      (east_data_i_psum),
        .east_enable_i_psum    (east_enable_i_psum),

        .north_data_o_psum     (/* if you want to forward north, wire here */),
        .north_enable_o_psum   (/* optional */),

        .south_data_o_psum     (south_data_o_psum),
        .south_enable_o_psum   (south_enable_o_psum),

        .west_data_o_psum      (west_data_o_psum),
        .west_enable_o_psum    (west_enable_o_psum),

        .east_data_o_psum      (east_data_o_psum),
        .east_enable_o_psum    (east_enable_o_psum),

        .psum_data_o           (psum_data_o),
        .psum_enable_o         (psum_enable_o),
        .psum_addr_o           (psum_addr_o)
    );

    // ============================================================
    // GLB CLUSTER
    // ============================================================
    GLB_cluster_wpsum #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH(ADDR_BITWIDTH),
        .X_dim(X_dim),
        .Y_dim(Y_dim),
        .NUM_GLB_IACT(NUM_GLB_IACT),
        .NUM_GLB_PSUM(NUM_GLB_PSUM),
        .NUM_GLB_WGHT(NUM_GLB_WGHT)
    ) GLB_cluster_0 (
        .clk  (clk),
        .reset(reset),

        // ---- IACT GLB read side ----
        .read_req_iact (iact_glb_req_read),
        .r_data_iact   (r_data_iact),
        .r_addr_iact   (iact_glb_addr_read),

        // ---- PSUM GLB read (final result) ----
        .read_req_psum (west_0_req_read_psum),  // kept for compatibility
        .r_data_psum   (r_data_psum),
        .r_addr_psum   (r_addr_psum),

        // ---- WGHT GLB read side ----
        .read_req_wght (wght_glb_req_read),
        .r_data_wght   (r_data_wght),
        .r_addr_wght   (wght_glb_addr_read),

        // ---- PSUM_INTER GLB read side ----
        .read_req_psum_inter (west_0_req_read_psum_inter),
        .r_data_psum_inter   (r_data_psum_inter),
        .read_en_psum_inter  (read_en_psum_inter),
        .r_addr_psum_inter   (r_addr_psum_inter),

        // ---- Write side into GLB ----
        .w_addr_iact  (w_addr_iact),
        .w_data_iact  (w_data_iact),
        .write_en_iact(write_en_iact),

        .w_addr_wght  (w_addr_wght),
        .w_data_wght  (w_data_wght),
        .write_en_wght(write_en_wght),

        // PSUM write-back from generic PSUM router
        .w_addr_psum  (psum_addr_o[ADDR_BITWIDTH-1:0]), // truncate if GLB is narrower
        .w_data_psum  (psum_data_o),
        .write_en_psum(psum_enable_o)
    );

    // ============================================================
    // PE CLUSTER
    // ============================================================
    // We need wires for the east outputs of IACT/WGHT routers to PE
    wire [DATA_BITWIDTH-1:0] pe_act_in;

    // Tap the east outputs of generic IACT/WGHT routers
    // NOTE: if you want these signals explicitly, change router_cluster_wpsum_generic
    // to expose them through named wires, or use separate wires instead of comments above.
    assign pe_act_in      = east_data_o_iact;
    assign pe_load_en_act = east_enable_o_iact;

    assign pe_wght_in      = east_data_o_wght;
    assign pe_load_en_wght = east_enable_o_wght;

    PE_cluster_new #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH(ADDR_BITWIDTH),

        .kernel_size(kernel_size),
        .act_size   (act_size),

        .X_dim(X_dim),
        .Y_dim(Y_dim),

        .W_READ_ADDR(W_READ_ADDR),
        .W_LOAD_ADDR(W_LOAD_ADDR),
        .A_READ_ADDR(A_READ_ADDR),
        .A_LOAD_ADDR(A_LOAD_ADDR),
        .PSUM_ADDR  (PSUM_ADDR)
    ) pe_cluster_0 (
        .clk  (clk),
        .reset(reset),

        .act_in (pe_act_in),
        .filt_in(pe_wght_in),

        // psum from router into PE
        .pe_before(east_data_o_psum),

        // load enables from router
        .load_en_wght(pe_load_en_wght),
        .load_en_act (pe_load_en_act),

        .start(start),

        // psum back into router
        .pe_out      (east_data_i_psum),
        .compute_done(east_enable_i_psum),
        .load_done   (load_done)
    );

endmodule

