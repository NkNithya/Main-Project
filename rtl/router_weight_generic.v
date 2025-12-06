`timescale 1ns / 1ps

module router_generic_wght
#(
    parameter DATA_BITWIDTH      = 16,
    parameter ADDR_BITWIDTH_GLB  = 10,
    parameter ADDR_BITWIDTH_SPAD = 9,

    parameter X_dim       = 5,
    parameter Y_dim       = 3,
    parameter kernel_size = 3,
    parameter act_size    = 5,

    parameter W_READ_ADDR = 0,
    parameter W_LOAD_ADDR = 0,

    // Compute direction: 0=NORTH, 1=SOUTH, 2=WEST, 3=EAST
    parameter integer COMPUTE_DIR = 2
)
(
    input clk,
    input reset,

    input [3:0] router_mode,

    // Directional inputs
    input [DATA_BITWIDTH-1:0] north_data_i,
    input                      north_enable_i,

    input [DATA_BITWIDTH-1:0] south_data_i,
    input                      south_enable_i,

    input [DATA_BITWIDTH-1:0] west_data_i,
    input                      west_enable_i,

    input [DATA_BITWIDTH-1:0] east_data_i,
    input                      east_enable_i,

    // Directional outputs
    output reg [DATA_BITWIDTH-1:0] north_data_o,
    output reg                     north_enable_o,

    output reg [DATA_BITWIDTH-1:0] south_data_o,
    output reg                     south_enable_o,

    // *** compute-direction SPAD write ***
    output [DATA_BITWIDTH-1:0] spad_wdata_o,
    output                     spad_wenable_o,

    output reg [DATA_BITWIDTH-1:0] east_data_o,
    output reg                     east_enable_o,

    output reg [DATA_BITWIDTH-1:0] west_data_o_routed,
    output reg                     west_enable_o_routed,

    output [ADDR_BITWIDTH_GLB-1:0] glb_addr_read_wght,
    output                         glb_req_read_wght
);


    // ----------------------------------------------------------------
    // Compute-direction selection:
    //   choose which directional input goes to the local SPAD/PE
    // ----------------------------------------------------------------
    reg [DATA_BITWIDTH-1:0] comp_data;
    reg                     comp_valid;

    always @* begin
        comp_data  = {DATA_BITWIDTH{1'b0}};
        comp_valid = 1'b0;
        case (COMPUTE_DIR)
            0: begin // NORTH
                comp_data  = north_data_i;
                comp_valid = north_enable_i;
            end
            1: begin // SOUTH
                comp_data  = south_data_i;
                comp_valid = south_enable_i;
            end
            2: begin // WEST
                comp_data  = west_data_i;
                comp_valid = west_enable_i;
            end
            3: begin // EAST
                comp_data  = east_data_i;
                comp_valid = east_enable_i;
            end
            default: begin
                comp_data  = {DATA_BITWIDTH{1'b0}};
                comp_valid = 1'b0;
            end
        endcase
    end

    assign spad_wdata_o   = comp_data;
    assign spad_wenable_o = comp_valid;


    //---------------------------------------------------------
    // Routing mode constants
    //---------------------------------------------------------
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

    //---------------------------------------------------------
    // STEP 1 — Compute-direction input selection only
    //---------------------------------------------------------
    wire [DATA_BITWIDTH-1:0] compute_data_i =
           (COMPUTE_DIR == 0) ? north_data_i :
           (COMPUTE_DIR == 1) ? south_data_i :
           (COMPUTE_DIR == 2) ? west_data_i  :
                                east_data_i;

    wire compute_en =
           (COMPUTE_DIR == 0) ? north_enable_i :
           (COMPUTE_DIR == 1) ? south_enable_i :
           (COMPUTE_DIR == 2) ? west_enable_i  :
                                east_enable_i;

    //---------------------------------------------------------
    // STEP 2 — Input priority selector for routing fanout
    //---------------------------------------------------------
    reg [DATA_BITWIDTH-1:0] data_out;
    reg                     data_en_out;

    always @(*) begin
        if (north_enable_i) begin
            data_out    = north_data_i;
            data_en_out = 1;
        end else if (south_enable_i) begin
            data_out    = south_data_i;
            data_en_out = 1;
        end else if (west_enable_i) begin
            data_out    = west_data_i;
            data_en_out = 1;
        end else if (east_enable_i) begin
            data_out    = east_data_i;
            data_en_out = 1;
        end else begin
            data_out    = 0;
            data_en_out = 0;
        end
    end

    //---------------------------------------------------------
    // STEP 3 — Pulse generator for load_spad_ctrl
    //---------------------------------------------------------
    reg load_ff0, load_ff1;
    wire load_spad_ctrl;

    assign load_spad_ctrl = load_ff0 & (~load_ff1);

    always @(posedge clk) begin
        if (reset) begin
            load_ff0 <= 0;
            load_ff1 <= 0;
        end else begin
            load_ff0 <= compute_en;   // ONLY compute direction triggers weight load
            load_ff1 <= load_ff0;
        end
    end

    //---------------------------------------------------------
    // STEP 4 — Instantiate router_weight FSM
    //---------------------------------------------------------
    router_weight #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),
        .X_dim(X_dim),
        .Y_dim(Y_dim),
        .kernel_size(kernel_size),
        .act_size(act_size),
        .W_READ_ADDR(W_READ_ADDR),
        .W_LOAD_ADDR(W_LOAD_ADDR)
    )
    weight_loader (
        .clk(clk),
        .reset(reset),

        .r_data_glb_wght(compute_data_i),
        .r_addr_glb_wght(glb_addr_read_wght),
        .read_req_glb_wght(glb_req_read_wght),

        .w_data_spad(spad_wdata_o),
        .load_en_spad(spad_wenable_o),

        .load_spad_ctrl(load_spad_ctrl)
    );

    //---------------------------------------------------------
    // STEP 5 — Routing fanout (never touch compute-direction SPAD outputs)
    //---------------------------------------------------------
    always @(*) begin
        // defaults
        north_data_o         = 0; north_enable_o = 0;
        south_data_o         = 0; south_enable_o = 0;
        east_data_o          = 0; east_enable_o  = 0;
        west_data_o_routed   = 0; west_enable_o_routed = 0;

        case (router_mode)

            ALL: begin
                if (COMPUTE_DIR != 0) begin north_data_o = data_out; north_enable_o = data_en_out; end
                if (COMPUTE_DIR != 1) begin south_data_o = data_out; south_enable_o = data_en_out; end
                if (COMPUTE_DIR != 3) begin east_data_o  = data_out; east_enable_o  = data_en_out; end
                if (COMPUTE_DIR != 2) begin west_data_o_routed = data_out; west_enable_o_routed = data_en_out; end
            end

            NORTH: if (COMPUTE_DIR != 0) begin north_data_o = data_out; north_enable_o = data_en_out; end
            SOUTH: if (COMPUTE_DIR != 1) begin south_data_o = data_out; south_enable_o = data_en_out; end
            EAST : if (COMPUTE_DIR != 3) begin east_data_o  = data_out; east_enable_o  = data_en_out; end
            WEST : if (COMPUTE_DIR != 2) begin west_data_o_routed = data_out; west_enable_o_routed = data_en_out; end

            EASTNORTH: begin
                if (COMPUTE_DIR != 3) begin east_data_o = data_out; east_enable_o = data_en_out; end
                if (COMPUTE_DIR != 0) begin north_data_o = data_out; north_enable_o = data_en_out; end
            end

            EASTSOUTH: begin
                if (COMPUTE_DIR != 3) begin east_data_o = data_out; east_enable_o = data_en_out; end
                if (COMPUTE_DIR != 1) begin south_data_o = data_out; south_enable_o = data_en_out; end
            end

            EASTWEST: begin
                if (COMPUTE_DIR != 3) begin east_data_o = data_out; east_enable_o = data_en_out; end
                if (COMPUTE_DIR != 2) begin west_data_o_routed = data_out; west_enable_o_routed = data_en_out; end
            end

            WESTNORTH: begin
                if (COMPUTE_DIR != 2) begin west_data_o_routed = data_out; west_enable_o_routed = data_en_out; end
                if (COMPUTE_DIR != 0) begin north_data_o = data_out; north_enable_o = data_en_out; end
            end

            WESTSOUTH: begin
                if (COMPUTE_DIR != 2) begin west_data_o_routed = data_out; west_enable_o_routed = data_en_out; end
                if (COMPUTE_DIR != 1) begin south_data_o = data_out; south_enable_o = data_en_out; end
            end

            WESTEAST: begin
                if (COMPUTE_DIR != 2) begin west_data_o_routed = data_out; west_enable_o_routed = data_en_out; end
                if (COMPUTE_DIR != 3) begin east_data_o = data_out; east_enable_o = data_en_out; end
            end

            CLOSED: begin end
            default: begin end

        endcase
    end

endmodule

