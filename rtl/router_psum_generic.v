`timescale 1ns / 1ps

module router_generic_psum
#(
    parameter DATA_BITWIDTH      = 16,
    parameter ADDR_BITWIDTH_GLB  = 10,
    parameter ADDR_BITWIDTH_SPAD = 9,

    parameter X_dim       = 5,
    parameter Y_dim       = 3,
    parameter kernel_size = 3,
    parameter act_size    = 5,

    parameter PSUM_READ_ADDR = 0,
    parameter PSUM_LOAD_ADDR = 0,

    // Select compute/PSUM direction:
    // 0 = NORTH, 1 = SOUTH, 2 = WEST, 3 = EAST
    parameter integer COMPUTE_DIR = 2
)
(
    input  clk,
    input  reset,

    // Mode control
    input  [3:0] router_mode,

    // Directional inputs (wide vectors: DATA_BITWIDTH * X_dim)
    input  [DATA_BITWIDTH*X_dim-1:0] north_data_i,
    input                            north_enable_i,

    input  [DATA_BITWIDTH*X_dim-1:0] south_data_i,
    input                            south_enable_i,

    input  [DATA_BITWIDTH*X_dim-1:0] west_data_i,
    input                            west_enable_i,

    input  [DATA_BITWIDTH*X_dim-1:0] east_data_i,
    input                            east_enable_i,

    // Directional wide outputs (for routing / broadcast)
    output reg [DATA_BITWIDTH*X_dim-1:0] north_data_o,
    output reg                           north_enable_o,

    output reg [DATA_BITWIDTH*X_dim-1:0] south_data_o,
    output reg                           south_enable_o,

    output reg [DATA_BITWIDTH*X_dim-1:0] east_data_o,
    output reg                           east_enable_o,

    // NOTE: We keep a wide west output for compatibility with routing fanout.
    // PSUM write data is narrow (DATA_BITWIDTH) and provided separately as psum_data_o.
    output reg [DATA_BITWIDTH*X_dim-1:0] west_data_o_wide,
    output reg                           west_enable_o_wide,

    // --- PSUM outputs (narrow) ---
    // These are the actual outputs from the PSUM FSM (one element at a time).
    output [DATA_BITWIDTH-1:0] psum_data_o,
    output                     psum_enable_o,
    output [ADDR_BITWIDTH_GLB-1:0] psum_write_addr
);

    // Mode encoding (match other routers if needed)
    localparam ALL        = 0;
    localparam NORTH      = 1;
    localparam SOUTH      = 2;
    localparam WEST       = 3;
    localparam EAST       = 4;
    localparam EASTNORTH  = 5;
    localparam EASTSOUTH  = 6;
    localparam EASTWEST   = 7;
    localparam WESTNORTH  = 8;
    localparam WESTSOUTH  = 9;
    localparam WESTEAST   = 10;
    localparam CLOSED     = 11;

    // ------------------------------------------------------------
    // 1) Select active wide input for routing fanout (priority: north, south, west, east)
    //    BUT DO NOT FEED the PSUM FSM with this generic selected value.
    //    The PSUM FSM gets the selected direction explicitly below.
    // ------------------------------------------------------------
    reg [DATA_BITWIDTH*X_dim-1:0] data_out;
    reg load_spad_ctrl_c; // used only for indicating presence of an active input for pulse gen (not for PSUM trigger)

    always @(*) begin
        if (north_enable_i) begin
            data_out = north_data_i;
            load_spad_ctrl_c = 1;
        end else if (south_enable_i) begin
            data_out = south_data_i;
            load_spad_ctrl_c = 1;
        end else if (west_enable_i) begin
            data_out = west_data_i;
            load_spad_ctrl_c = 1;
        end else if (east_enable_i) begin
            data_out = east_data_i;
            load_spad_ctrl_c = 1;
        end else begin
            data_out = {DATA_BITWIDTH*X_dim{1'b0}};
            load_spad_ctrl_c = 0;
        end
    end

    // ------------------------------------------------------------
    // 2) One-shot pulse generator for general load_spad_ctrl (kept for compatibility)
    // ------------------------------------------------------------
    reg load_spad_ctrl_0, load_spad_ctrl_1;
    wire load_spad_ctrl;
    assign load_spad_ctrl = load_spad_ctrl_0 & (~load_spad_ctrl_1);

    always @(posedge clk) begin
        if (reset) begin
            load_spad_ctrl_0 <= 1'b0;
            load_spad_ctrl_1 <= 1'b0;
        end else begin
            load_spad_ctrl_0 <= load_spad_ctrl_c;
            load_spad_ctrl_1 <= load_spad_ctrl_0;
        end
    end

    // ------------------------------------------------------------
    // 3) Select PSUM source and trigger based on COMPUTE_DIR
    //    Only the chosen direction's wide data and enable are passed to router_psum.
    // ------------------------------------------------------------
    wire [DATA_BITWIDTH*X_dim-1:0] psum_source_wide;
    wire                          psum_trigger; // single-cycle enable to router_psum
    // default
    assign psum_source_wide = (COMPUTE_DIR == 0) ? north_data_i :
                              (COMPUTE_DIR == 1) ? south_data_i :
                              (COMPUTE_DIR == 2) ? west_data_i  :
                                                   east_data_i;
    assign psum_trigger     = (COMPUTE_DIR == 0) ? north_enable_i :
                              (COMPUTE_DIR == 1) ? south_enable_i :
                              (COMPUTE_DIR == 2) ? west_enable_i  :
                                                   east_enable_i;

    // ------------------------------------------------------------
    // 4) Instantiate router_psum (your existing module)
    //
    //    router_psum expects: r_data_spad_psum (wide), and outputs
    //    w_addr_glb_psum, write_en_glb_psum, w_data_glb_psum (narrow).
    // ------------------------------------------------------------
    wire [DATA_BITWIDTH-1:0] w_data_glb_psum_from_psum;
    wire                     write_en_glb_psum_from_psum;
    wire [ADDR_BITWIDTH_GLB-1:0] w_addr_glb_psum_from_psum;

    router_psum #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),
        .X_dim(X_dim),
        .Y_dim(Y_dim),
        .kernel_size(kernel_size),
        .act_size(act_size),
        .PSUM_READ_ADDR(PSUM_READ_ADDR),
        .PSUM_LOAD_ADDR(PSUM_LOAD_ADDR)
    ) router_psum_0 (
        .clk(clk),
        .reset(reset),

        // feed only the selected direction's wide vector into the psum module:
        .r_data_spad_psum(psum_source_wide),

        // outputs from router_psum
        .w_addr_glb_psum(w_addr_glb_psum_from_psum),
        .write_en_glb_psum(write_en_glb_psum_from_psum),
        .w_data_glb_psum(w_data_glb_psum_from_psum),

        // trigger from the selected compute direction
        .write_psum_ctrl(psum_trigger)
    );

    // Expose PSUM outputs (narrow) to top-level (user can connect them to whichever direction they want)
    assign psum_data_o      = w_data_glb_psum_from_psum;
    assign psum_enable_o    = write_en_glb_psum_from_psum;
    assign psum_write_addr  = w_addr_glb_psum_from_psum;

    // ------------------------------------------------------------
    // 5) Routing fanout: distribute `data_out` to neighbor wide outputs
    //    IMPORTANT: never assign to the compute direction's wide outputs
    //               (those are reserved for PSUM FSM usage).
    // ------------------------------------------------------------
    always @(*) begin
        // default zeros
        north_data_o   = {DATA_BITWIDTH*X_dim{1'b0}}; north_enable_o = 1'b0;
        south_data_o   = {DATA_BITWIDTH*X_dim{1'b0}}; south_enable_o = 1'b0;
        east_data_o    = {DATA_BITWIDTH*X_dim{1'b0}}; east_enable_o  = 1'b0;
        west_data_o_wide= {DATA_BITWIDTH*X_dim{1'b0}}; west_enable_o_wide = 1'b0;

        case (router_mode)
            ALL: begin
                // assign to all directions *except* the compute direction
                if (COMPUTE_DIR != 0) begin north_data_o   = data_out; north_enable_o = 1'b1; end
                if (COMPUTE_DIR != 1) begin south_data_o   = data_out; south_enable_o = 1'b1; end
                if (COMPUTE_DIR != 3) begin east_data_o    = data_out; east_enable_o  = 1'b1; end
                if (COMPUTE_DIR != 2) begin west_data_o_wide= data_out; west_enable_o_wide = 1'b1; end
            end

            NORTH: begin
                if (COMPUTE_DIR != 0) begin north_data_o = data_out; north_enable_o = 1'b1; end
            end

            SOUTH: begin
                if (COMPUTE_DIR != 1) begin south_data_o = data_out; south_enable_o = 1'b1; end
            end

            EAST: begin
                if (COMPUTE_DIR != 3) begin east_data_o = data_out; east_enable_o = 1'b1; end
            end

            WEST: begin
                if (COMPUTE_DIR != 2) begin west_data_o_wide = data_out; west_enable_o_wide = 1'b1; end
            end

            EASTNORTH: begin
                if (COMPUTE_DIR != 3) begin east_data_o     = data_out; east_enable_o   = 1'b1; end
                if (COMPUTE_DIR != 0) begin north_data_o    = data_out; north_enable_o  = 1'b1; end
            end

            EASTSOUTH: begin
                if (COMPUTE_DIR != 3) begin east_data_o     = data_out; east_enable_o   = 1'b1; end
                if (COMPUTE_DIR != 1) begin south_data_o    = data_out; south_enable_o  = 1'b1; end
            end

            EASTWEST: begin
                if (COMPUTE_DIR != 3) begin east_data_o     = data_out; east_enable_o   = 1'b1; end
                if (COMPUTE_DIR != 2) begin west_data_o_wide = data_out; west_enable_o_wide = 1'b1; end
            end

            WESTNORTH: begin
                if (COMPUTE_DIR != 2) begin west_data_o_wide = data_out; west_enable_o_wide = 1'b1; end
                if (COMPUTE_DIR != 0) begin north_data_o    = data_out; north_enable_o  = 1'b1; end
            end

            WESTSOUTH: begin
                if (COMPUTE_DIR != 2) begin west_data_o_wide = data_out; west_enable_o_wide = 1'b1; end
                if (COMPUTE_DIR != 1) begin south_data_o    = data_out; south_enable_o  = 1'b1; end
            end

            WESTEAST: begin
                if (COMPUTE_DIR != 2) begin west_data_o_wide = data_out; west_enable_o_wide = 1'b1; end
                if (COMPUTE_DIR != 3) begin east_data_o     = data_out; east_enable_o   = 1'b1; end
            end

            CLOSED: begin
                // all zero (defaults cover this)
            end

            default: begin
                // defaults already applied
            end
        endcase
    end

endmodule

