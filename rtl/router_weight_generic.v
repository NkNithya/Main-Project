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

    // Compute direction:
    // 0 = NORTH, 1 = SOUTH, 2 = WEST, 3 = EAST
    parameter integer COMPUTE_DIR = 2
)
(
    input clk,
    input reset,

    input [3:0] router_mode,

    // GLB read interface
    output [ADDR_BITWIDTH_GLB-1:0] glb_addr_read_wght,
    output                         glb_req_read_wght,

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

    output reg [DATA_BITWIDTH-1:0] west_data_o,
    output reg                     west_enable_o,

    output reg [DATA_BITWIDTH-1:0] east_data_o,
    output reg                     east_enable_o
);

    // --------------------------------------------------
    // 1. Input arbitration (EXACT priority)
    // north > south > west > east
    // --------------------------------------------------
    reg [DATA_BITWIDTH-1:0] data_out;
    reg load_spad_ctrl_c;

    always @(*) begin
        if (north_enable_i) begin
            data_out         = north_data_i;
            load_spad_ctrl_c = 1'b1;
        end else if (south_enable_i) begin
            data_out         = south_data_i;
            load_spad_ctrl_c = 1'b1;
        end else if (west_enable_i) begin
            data_out         = west_data_i;
            load_spad_ctrl_c = 1'b1;
        end else if (east_enable_i) begin
            data_out         = east_data_i;
            load_spad_ctrl_c = 1'b1;
        end else begin
            data_out         = {DATA_BITWIDTH{1'b0}};
            load_spad_ctrl_c = 1'b0;
        end
    end

    // --------------------------------------------------
    // 2. One-shot load pulse (EDGE-triggered)
    // EXACT match to router_west_wght
    // --------------------------------------------------
    reg load_ff0, load_ff1;
    wire load_spad_ctrl;

    assign load_spad_ctrl = load_ff0 & ~load_ff1;

    always @(posedge clk) begin
        if (reset) begin
            load_ff0 <= 1'b0;
            load_ff1 <= 1'b0;
        end else begin
            load_ff0 <= load_spad_ctrl_c;
            load_ff1 <= load_ff0;
        end
    end

    // --------------------------------------------------
    // 3. Weight loader FSM (UNCHANGED)
    // --------------------------------------------------
    wire [DATA_BITWIDTH-1:0] spad_data_o;
    wire                     spad_en_o;

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
    ) router_weight_0 (
        .clk(clk),
        .reset(reset),

        // NOTE: EXACT west behavior — FSM sees data_out
        .r_data_glb_wght(data_out),
        .r_addr_glb_wght(glb_addr_read_wght),
        .read_req_glb_wght(glb_req_read_wght),

        .w_data_spad(spad_data_o),
        .load_en_spad(spad_en_o),

        .load_spad_ctrl(load_spad_ctrl)
    );

    // --------------------------------------------------
    // 4. STRUCTURAL SPAD binding to COMPUTE_DIR
    // SPAD output is NEVER gated by router_mode
    // --------------------------------------------------
    always @(*) begin
        north_data_o   = {DATA_BITWIDTH{1'b0}};
        south_data_o   = {DATA_BITWIDTH{1'b0}};
        west_data_o    = {DATA_BITWIDTH{1'b0}};
        east_data_o    = {DATA_BITWIDTH{1'b0}};

        north_enable_o = 1'b0;
        south_enable_o = 1'b0;
        west_enable_o  = 1'b0;
        east_enable_o  = 1'b0;

        case (COMPUTE_DIR)
            0: begin north_data_o = spad_data_o; north_enable_o = spad_en_o; end
            1: begin south_data_o = spad_data_o; south_enable_o = spad_en_o; end
            2: begin west_data_o  = spad_data_o; west_enable_o  = spad_en_o; end
            3: begin east_data_o  = spad_data_o; east_enable_o  = spad_en_o; end
        endcase
    end

    // --------------------------------------------------
    // 5. Routing logic (EXACT semantics)
    // Routing NEVER blocks SPAD
    // --------------------------------------------------
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
        if (router_mode == CLOSED)
            ; // routing suppressed, SPAD unaffected
        else begin
            case (router_mode)
                ALL: begin
                    north_data_o = data_out; north_enable_o = 1;
                    south_data_o = data_out; south_enable_o = 1;
                    east_data_o  = data_out; east_enable_o  = 1;
                end
                NORTH: begin north_data_o = data_out; north_enable_o = 1; end
                SOUTH: begin south_data_o = data_out; south_enable_o = 1; end
                EAST:  begin east_data_o  = data_out; east_enable_o  = 1; end
                EASTNORTH: begin
                    east_data_o  = data_out; east_enable_o  = 1;
                    north_data_o = data_out; north_enable_o = 1;
                end
                EASTSOUTH: begin
                    east_data_o  = data_out; east_enable_o  = 1;
                    south_data_o = data_out; south_enable_o = 1;
                end
                WESTNORTH: begin
                    west_data_o  = data_out; west_enable_o  = 1;
                    north_data_o = data_out; north_enable_o = 1;
                end
                WESTSOUTH: begin
                    west_data_o  = data_out; west_enable_o  = 1;
                    south_data_o = data_out; south_enable_o = 1;
                end
                WESTEAST: begin
                    west_data_o  = data_out; west_enable_o  = 1;
                    east_data_o  = data_out; east_enable_o  = 1;
                end
            endcase
        end
    end

endmodule

