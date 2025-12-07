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

    // Compute direction: 0=N, 1=S, 2=W, 3=E
    parameter integer COMPUTE_DIR = 2
)
(
    input  clk,
    input  reset,

    // Mode control
    input  [3:0] router_mode,

    // Directional wide inputs
    input  [DATA_BITWIDTH*X_dim-1:0] north_data_i,
    input                            north_enable_i,

    input  [DATA_BITWIDTH*X_dim-1:0] south_data_i,
    input                            south_enable_i,

    input  [DATA_BITWIDTH*X_dim-1:0] west_data_i,
    input                            west_enable_i,

    input  [DATA_BITWIDTH*X_dim-1:0] east_data_i,
    input                            east_enable_i,

    // Directional wide outputs
    output reg [DATA_BITWIDTH*X_dim-1:0] north_data_o,
    output reg                           north_enable_o,

    output reg [DATA_BITWIDTH*X_dim-1:0] south_data_o,
    output reg                           south_enable_o,

    output reg [DATA_BITWIDTH*X_dim-1:0] east_data_o,
    output reg                           east_enable_o,

    output reg [DATA_BITWIDTH*X_dim-1:0] west_data_o_wide,
    output reg                           west_enable_o_wide,

    // Narrow PSUM outputs (from FSM)
    output [DATA_BITWIDTH-1:0] psum_data_o,
    output                     psum_enable_o,
    output [ADDR_BITWIDTH_GLB-1:0] psum_write_addr
);

    // ------------------------------------------------------------
    // Direction constants
    // ------------------------------------------------------------
    localparam DIR_N = 0;
    localparam DIR_S = 1;
    localparam DIR_W = 2;
    localparam DIR_E = 3;

    // ------------------------------------------------------------
    // Compute-direction input selection (WIDE)
    // ------------------------------------------------------------
    wire [DATA_BITWIDTH*X_dim-1:0] psum_src_wide =
        (COMPUTE_DIR == DIR_N) ? north_data_i :
        (COMPUTE_DIR == DIR_S) ? south_data_i :
        (COMPUTE_DIR == DIR_W) ? west_data_i  :
                                 east_data_i;

    // Compute-direction enable (LEVEL)
    wire psum_trigger_level =
        (COMPUTE_DIR == DIR_N) ? north_enable_i :
        (COMPUTE_DIR == DIR_S) ? south_enable_i :
        (COMPUTE_DIR == DIR_W) ? west_enable_i  :
                                 east_enable_i;

    // ------------------------------------------------------------
    // One-shot pulse generator for PSUM FSM
    // ------------------------------------------------------------
    reg psum_ff0, psum_ff1;
    wire psum_trigger_pulse = psum_ff0 & (~psum_ff1);

    always @(posedge clk) begin
        if (reset) begin
            psum_ff0 <= 0;
            psum_ff1 <= 0;
        end else begin
            psum_ff0 <= psum_trigger_level;
            psum_ff1 <= psum_ff0;
        end
    end

    // ------------------------------------------------------------
    // Instantiate router_psum FSM
    // ------------------------------------------------------------
    wire [DATA_BITWIDTH-1:0] psum_data_int;
    wire                     psum_en_int;
    wire [ADDR_BITWIDTH_GLB-1:0] psum_addr_int;

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
    ) psum_fsm (
        .clk(clk),
        .reset(reset),

        .r_data_spad_psum(psum_src_wide),

        .w_addr_glb_psum(psum_addr_int),
        .write_en_glb_psum(psum_en_int),
        .w_data_glb_psum(psum_data_int),

        .write_psum_ctrl(psum_trigger_pulse)
    );

    assign psum_data_o     = psum_data_int;
    assign psum_enable_o   = psum_en_int;
    assign psum_write_addr = psum_addr_int;

    // ------------------------------------------------------------
    // Routing fanout (priority select for wide routing)
    // ------------------------------------------------------------
    reg [DATA_BITWIDTH*X_dim-1:0] data_out;
    reg data_out_valid;

    always @(*) begin
        if (north_enable_i) begin
            data_out = north_data_i; data_out_valid = 1;
        end else if (south_enable_i) begin
            data_out = south_data_i; data_out_valid = 1;
        end else if (west_enable_i) begin
            data_out = west_data_i; data_out_valid = 1;
        end else if (east_enable_i) begin
            data_out = east_data_i; data_out_valid = 1;
        end else begin
            data_out = 0; data_out_valid = 0;
        end
    end

    // ------------------------------------------------------------
    // Routing based on router_mode
    // ------------------------------------------------------------
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

    always @(*) begin
        // defaults
        north_data_o       = 0; north_enable_o = 0;
        south_data_o       = 0; south_enable_o = 0;
        east_data_o        = 0; east_enable_o  = 0;
        west_data_o_wide   = 0; west_enable_o_wide = 0;

        case (router_mode)

            ALL: begin
                if (COMPUTE_DIR != DIR_N) begin north_data_o   = data_out; north_enable_o = data_out_valid; end
                if (COMPUTE_DIR != DIR_S) begin south_data_o   = data_out; south_enable_o = data_out_valid; end
                if (COMPUTE_DIR != DIR_E) begin east_data_o    = data_out; east_enable_o  = data_out_valid; end
                if (COMPUTE_DIR != DIR_W) begin west_data_o_wide = data_out; west_enable_o_wide = data_out_valid; end
            end

            NORTH: if (COMPUTE_DIR != DIR_N) begin
                north_data_o = data_out; north_enable_o = data_out_valid;
            end

            SOUTH: if (COMPUTE_DIR != DIR_S) begin
                south_data_o = data_out; south_enable_o = data_out_valid;
            end

            EAST: if (COMPUTE_DIR != DIR_E) begin
                east_data_o  = data_out; east_enable_o  = data_out_valid;
            end

            WEST: if (COMPUTE_DIR != DIR_W) begin
                west_data_o_wide = data_out; west_enable_o_wide = data_out_valid;
            end

            EASTNORTH: begin
                if (COMPUTE_DIR != DIR_E) east_data_o  = data_out;
                if (COMPUTE_DIR != DIR_N) north_data_o = data_out;
                east_enable_o  = data_out_valid;
                north_enable_o = data_out_valid;
            end

            EASTSOUTH: begin
                if (COMPUTE_DIR != DIR_E) east_data_o  = data_out;
                if (COMPUTE_DIR != DIR_S) south_data_o = data_out;
                east_enable_o  = data_out_valid;
                south_enable_o = data_out_valid;
            end

            EASTWEST: begin
                if (COMPUTE_DIR != DIR_E) east_data_o  = data_out;
                if (COMPUTE_DIR != DIR_W) west_data_o_wide = data_out;
                east_enable_o  = data_out_valid;
                west_enable_o_wide = data_out_valid;
            end

            WESTNORTH: begin
                if (COMPUTE_DIR != DIR_W) west_data_o_wide = data_out;
                if (COMPUTE_DIR != DIR_N) north_data_o     = data_out;
                west_enable_o_wide = data_out_valid;
                north_enable_o     = data_out_valid;
            end

            WESTSOUTH: begin
                if (COMPUTE_DIR != DIR_W) west_data_o_wide = data_out;
                if (COMPUTE_DIR != DIR_S) south_data_o     = data_out;
                west_enable_o_wide = data_out_valid;
                south_enable_o     = data_out_valid;
            end

            WESTEAST: begin
                if (COMPUTE_DIR != DIR_W) west_data_o_wide = data_out;
                if (COMPUTE_DIR != DIR_E) east_data_o      = data_out;
                west_enable_o_wide = data_out_valid;
                east_enable_o      = data_out_valid;
            end

            CLOSED: begin
                // all stay zero
            end

        endcase
    end

endmodule

