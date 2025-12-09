`timescale 1ns/1ps

module router_cluster_wpsum_generic
    #(
        parameter DATA_BITWIDTH      = 16,
        parameter ADDR_BITWIDTH      = 10,   // used for PSUM addr out
        parameter ADDR_BITWIDTH_GLB  = 10,
        parameter ADDR_BITWIDTH_SPAD = 9,

        parameter A_READ_ADDR  = 100,
        parameter A_LOAD_ADDR  = 0,

        parameter X_dim        = 5,
        parameter Y_dim        = 3,
        parameter kernel_size  = 3,
        parameter act_size     = 5,

        parameter W_READ_ADDR  = 0,
        parameter W_LOAD_ADDR  = 0,

        parameter PSUM_READ_ADDR = 0,
        parameter PSUM_LOAD_ADDR = 0,

        // --------- Direction parameters ----------
        // For generic_iact (string-based COMPUTE_DIR)
        // "NORTH", "SOUTH", "WEST", "EAST"
        parameter IACT_COMPUTE_DIR_STR = "WEST",

        // For generic_wght & generic_psum (integer-coded)
        // 0 = NORTH, 1 = SOUTH, 2 = WEST, 3 = EAST
        parameter integer WGHT_COMPUTE_DIR = 2,
        parameter integer PSUM_COMPUTE_DIR = 2
    )
    (
        input clk,
        input reset,

        ///////////////      ROUTER IACT      ///////////////////////////////////
        output [ADDR_BITWIDTH_GLB-1:0] west_0_addr_read_iact,
        output                         west_0_req_read_iact,
        input  [3:0]                   router_mode_west_0_iact,

        // Interface with West (IACT)
        input  [DATA_BITWIDTH-1:0]     west_data_i_west_0_iact,
        input                          west_enable_i_west_0_iact,
        output [DATA_BITWIDTH-1:0]     west_data_o_west_0_iact,
        output                         west_enable_o_west_0_iact,

        ///////////////      ROUTER WGHT      ///////////////////////////////////
        output [ADDR_BITWIDTH_GLB-1:0] west_0_addr_read_wght,
        output                         west_0_req_read_wght,
        input  [3:0]                   router_mode_west_0_wght,

        // Interface with West (WGHT)
        input  [DATA_BITWIDTH-1:0]     west_data_i_west_0_wght,
        input                          west_enable_i_west_0_wght,
        output [DATA_BITWIDTH-1:0]     west_data_o_west_0_wght,
        output                         west_enable_o_west_0_wght,

        /////////////  IACT interports with other directions   ////////////
        // North
        input  [DATA_BITWIDTH-1:0]     north_data_i_iact,
        input                          north_enable_i_iact,
        output [DATA_BITWIDTH-1:0]     north_data_o_iact,
        output                         north_enable_o_iact,

        // South
        input  [DATA_BITWIDTH-1:0]     south_data_i_iact,
        input                          south_enable_i_iact,
        output [DATA_BITWIDTH-1:0]     south_data_o_iact,
        output                         south_enable_o_iact,

        // East
        input  [DATA_BITWIDTH-1:0]     east_data_i_iact,
        input                          east_enable_i_iact,
        output [DATA_BITWIDTH-1:0]     east_data_o_iact,
        output                         east_enable_o_iact,

        /////////////  WGHT interports with other directions   ////////////
        // North
        input  [DATA_BITWIDTH-1:0]     north_data_i_wght,
        input                          north_enable_i_wght,
        output [DATA_BITWIDTH-1:0]     north_data_o_wght,
        output                         north_enable_o_wght,

        // South
        input  [DATA_BITWIDTH-1:0]     south_data_i_wght,
        input                          south_enable_i_wght,
        output [DATA_BITWIDTH-1:0]     south_data_o_wght,
        output                         south_enable_o_wght,

        // East
        input  [DATA_BITWIDTH-1:0]     east_data_i_wght,
        input                          east_enable_i_wght,
        output [DATA_BITWIDTH-1:0]     east_data_o_wght,
        output                         east_enable_o_wght,

        //////////////  ROUTER PSUM   /////////////////////
        input  [3:0]                   router_mode_west_0_psum,

        // North (wide bus)
        input  [DATA_BITWIDTH*X_dim-1:0] north_data_i_psum,
        input                            north_enable_i_psum,

        // South (wide bus)
        output [DATA_BITWIDTH*X_dim-1:0] south_data_o_psum,
        output                           south_enable_o_psum,

        // West (wide in, narrow out)
        input  [DATA_BITWIDTH*X_dim-1:0] west_data_i_west_0_psum,
        input                            west_enable_i_west_0_psum,
        output [DATA_BITWIDTH-1:0]       west_data_o_west_0_psum,
        output                           west_enable_o_west_0_psum,

        // East (wide in/out)
        input  [DATA_BITWIDTH*X_dim-1:0] east_data_i_west_0_psum,
        input                            east_enable_i_west_0_psum,
        output [DATA_BITWIDTH*X_dim-1:0] east_data_o_west_0_psum,
        // output east_enable_o_west_0_psum, // original commented out

        // PSUM write address (narrow)
        output [ADDR_BITWIDTH-1:0]      west_addr_o_west_0_psum
    );

    // ============================================================
    //  IACT ROUTER (generic)
    // ============================================================
    router_generic_iact #(
        .DATA_BITWIDTH     (DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB (ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),
        .X_dim             (X_dim),
        .Y_dim             (Y_dim),
        .kernel_size       (kernel_size),
        .act_size          (act_size),
        .A_READ_ADDR       (A_READ_ADDR),
        .A_LOAD_ADDR       (A_LOAD_ADDR),
        .COMPUTE_DIR       (IACT_COMPUTE_DIR_STR)   // string param
    ) u_router_iact (
        .clk               (clk),
        .reset             (reset),
        .router_mode       (router_mode_west_0_iact),

        // GLB read side
        .glb_addr_read     (west_0_addr_read_iact),
        .glb_req_read      (west_0_req_read_iact),

        // Directional inputs
        .north_data_i      (north_data_i_iact),
        .north_enable_i    (north_enable_i_iact),

        .south_data_i      (south_data_i_iact),
        .south_enable_i    (south_enable_i_iact),

        .west_data_i       (west_data_i_west_0_iact),
        .west_enable_i     (west_enable_i_west_0_iact),

        .east_data_i       (east_data_i_iact),
        .east_enable_i     (east_enable_i_iact),

        // Directional outputs
        .north_data_o      (north_data_o_iact),
        .north_enable_o    (north_enable_o_iact),

        .south_data_o      (south_data_o_iact),
        .south_enable_o    (south_enable_o_iact),

        .west_data_o       (west_data_o_west_0_iact),
        .west_enable_o     (west_enable_o_west_0_iact),

        .east_data_o       (east_data_o_iact),
        .east_enable_o     (east_enable_o_iact)
    );

    // ============================================================
    //  WGHT ROUTER (generic)
    // ============================================================
    router_generic_wght #(
        .DATA_BITWIDTH      (DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB  (ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD (ADDR_BITWIDTH_SPAD),
        .X_dim              (X_dim),
        .Y_dim              (Y_dim),
        .kernel_size        (kernel_size),
        .act_size           (act_size),
        .W_READ_ADDR        (W_READ_ADDR),
        .W_LOAD_ADDR        (W_LOAD_ADDR),
        .COMPUTE_DIR        (WGHT_COMPUTE_DIR)   // integer param: 0=N,1=S,2=W,3=E
    ) u_router_wght (
        .clk                (clk),
        .reset              (reset),
        .router_mode        (router_mode_west_0_wght),

        // Directional inputs
        .north_data_i       (north_data_i_wght),
        .north_enable_i     (north_enable_i_wght),

        .south_data_i       (south_data_i_wght),
        .south_enable_i     (south_enable_i_wght),

        .west_data_i        (west_data_i_west_0_wght),
        .west_enable_i      (west_enable_i_west_0_wght),

        .east_data_i        (east_data_i_wght),
        .east_enable_i      (east_enable_i_wght),

        // Directional outputs (routing)
        .north_data_o       (north_data_o_wght),
        .north_enable_o     (north_enable_o_wght),

        .south_data_o       (south_data_o_wght),
        .south_enable_o     (south_enable_o_wght),

        .east_data_o        (east_data_o_wght),
        .east_enable_o      (east_enable_o_wght),

        .west_data_o_routed (),          // not externally used in original cluster
        .west_enable_o_routed(),

        // SPAD write (these correspond to original west_data_o / west_enable_o)
        .spad_wdata_o       (west_data_o_west_0_wght),
        .spad_wenable_o     (west_enable_o_west_0_wght),

        // GLB read interface
        .glb_addr_read_wght (west_0_addr_read_wght),
        .glb_req_read_wght  (west_0_req_read_wght)
    );

    // ============================================================
    //  PSUM ROUTER (generic)
    // ============================================================
    // Internal wires for west wide outputs (not in original interface)
    wire [DATA_BITWIDTH*X_dim-1:0] west_data_o_psum_wide;
    wire                           west_enable_o_psum_wide;

    // Narrow PSUM writeback signals from FSM
    wire [DATA_BITWIDTH-1:0]       psum_data_o_int;
    wire                           psum_enable_o_int;
    wire [ADDR_BITWIDTH_GLB-1:0]   psum_addr_int;

    router_generic_psum #(
        .DATA_BITWIDTH      (DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB  (ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD (ADDR_BITWIDTH_SPAD),
        .X_dim              (X_dim),
        .Y_dim              (Y_dim),
        .kernel_size        (kernel_size),
        .act_size           (act_size),
        .PSUM_READ_ADDR     (PSUM_READ_ADDR),
        .PSUM_LOAD_ADDR     (PSUM_LOAD_ADDR),
        .COMPUTE_DIR        (PSUM_COMPUTE_DIR)   // integer param: 0=N,1=S,2=W,3=E
    ) u_router_psum (
        .clk                (clk),
        .reset              (reset),
        .router_mode        (router_mode_west_0_psum),

        // directional wide inputs
        .north_data_i       (north_data_i_psum),
        .north_enable_i     (north_enable_i_psum),

        .south_data_i       (), // no wide south input in original cluster
        .south_enable_i     (1'b0),

        .west_data_i        (west_data_i_west_0_psum),
        .west_enable_i      (west_enable_i_west_0_psum),

        .east_data_i        (east_data_i_west_0_psum),
        .east_enable_i      (east_enable_i_west_0_psum),

        // directional wide outputs
        .north_data_o       (), // not used in original cluster
        .north_enable_o     (),

        .south_data_o       (south_data_o_psum),
        .south_enable_o     (south_enable_o_psum),

        .east_data_o        (east_data_o_west_0_psum),
        .east_enable_o      (), // original also didn't expose east_enable

        .west_data_o_wide   (west_data_o_psum_wide),
        .west_enable_o_wide (west_enable_o_psum_wide),

        // narrow PSUM outputs (to GLB)
        .psum_data_o        (psum_data_o_int),
        .psum_enable_o      (psum_enable_o_int),
        .psum_write_addr    (psum_addr_int)
    );

    // Map narrow PSUM outputs to original WEST narrow interface
    assign west_data_o_west_0_psum  = psum_data_o_int;
    assign west_enable_o_west_0_psum = psum_enable_o_int;
    assign west_addr_o_west_0_psum  = psum_addr_int[ADDR_BITWIDTH-1:0];

endmodule

