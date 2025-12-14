`timescale 1ns / 1ps

module router_generic_iact
#(
    parameter DATA_BITWIDTH      = 16,
    parameter ADDR_BITWIDTH_GLB  = 10,
    parameter ADDR_BITWIDTH_SPAD = 9,

    parameter X_dim       = 5,
    parameter Y_dim       = 3,
    parameter kernel_size = 3,
    parameter act_size    = 5,

    parameter A_READ_ADDR = 100,
    parameter A_LOAD_ADDR = 0,

    // 0=NORTH, 1=SOUTH, 2=WEST, 3=EAST
    parameter integer COMPUTE_DIR = 2
)
(
    input clk,
    input reset,
    input [3:0] router_mode,

    // GLB interface
    output [ADDR_BITWIDTH_GLB-1:0] glb_addr_read,
    output                         glb_req_read,

    // Inputs
    input [DATA_BITWIDTH-1:0] north_data_i,
    input                      north_enable_i,
    input [DATA_BITWIDTH-1:0] south_data_i,
    input                      south_enable_i,
    input [DATA_BITWIDTH-1:0] west_data_i,
    input                      west_enable_i,
    input [DATA_BITWIDTH-1:0] east_data_i,
    input                      east_enable_i,

    // Outputs
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
    // 1. Arbitration (IDENTICAL to west router)
    // north > south > west > east
    // --------------------------------------------------
    reg [DATA_BITWIDTH-1:0] data_out;
    reg load_spad_ctrl_c;

    always @(*) begin
        if (north_enable_i) begin
            data_out = north_data_i;
            load_spad_ctrl_c = 1'b1;
        end else if (south_enable_i) begin
            data_out = south_data_i;
            load_spad_ctrl_c = 1'b1;
        end else if (west_enable_i) begin
            data_out = west_data_i;
            load_spad_ctrl_c = 1'b1;
        end else if (east_enable_i) begin
            data_out = east_data_i;
            load_spad_ctrl_c = 1'b1;
        end else begin
            data_out = {DATA_BITWIDTH{1'b0}};
            load_spad_ctrl_c = 1'b0;
        end
    end

    // --------------------------------------------------
    // 2. Edge-detected load pulse (EXACT match)
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
    // 3. router_iact (UNCHANGED)
    // --------------------------------------------------
    wire [DATA_BITWIDTH-1:0] spad_data;
    wire                     spad_en;

    router_iact #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),
        .X_dim(X_dim),
        .Y_dim(Y_dim),
        .kernel_size(kernel_size),
        .act_size(act_size),
        .A_READ_ADDR(A_READ_ADDR),
        .A_LOAD_ADDR(A_LOAD_ADDR)
    ) router_iact_0 (
        .clk(clk),
        .reset(reset),
        .r_data_glb_iact(data_out),
        .r_addr_glb_iact(glb_addr_read),
        .read_req_glb_iact(glb_req_read),
        .w_data_spad(spad_data),
        .load_en_spad(spad_en),
        .load_spad_ctrl(load_spad_ctrl)
    );

    // --------------------------------------------------
    // 4. Routing logic (PURE, SPAD-INDEPENDENT)
    // --------------------------------------------------
    localparam ALL        = 0,
               NORTH      = 1,
               SOUTH      = 2,
               WEST       = 3,
               EAST       = 4,
               EASTNORTH  = 5,
               EASTSOUTH  = 6,
               EASTWEST   = 7,
               WESTNORTH  = 8,
               WESTSOUTH  = 9,
               WESTEAST   = 10,
               CLOSED     = 11;

    always @(*) begin
        // defaults
        north_data_o = 0; north_enable_o = 0;
        south_data_o = 0; south_enable_o = 0;
        west_data_o  = 0; west_enable_o  = 0;
        east_data_o  = 0; east_enable_o  = 0;

        if (router_mode != CLOSED) begin
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

    // --------------------------------------------------
    // 5. SPAD → COMPUTE direction (STRUCTURAL, SEPARATE)
    // --------------------------------------------------
    generate
        if (COMPUTE_DIR == 0) begin
            always @(*) begin
                north_data_o   = spad_data;
                north_enable_o = spad_en;
            end
        end else if (COMPUTE_DIR == 1) begin
            always @(*) begin
                south_data_o   = spad_data;
                south_enable_o = spad_en;
            end
        end else if (COMPUTE_DIR == 2) begin
            always @(*) begin
                west_data_o    = spad_data;
                west_enable_o  = spad_en;
            end
        end else if (COMPUTE_DIR == 3) begin
            always @(*) begin
                east_data_o    = spad_data;
                east_enable_o  = spad_en;
            end
        end
    endgenerate

endmodule

