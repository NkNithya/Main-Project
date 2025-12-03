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
    parameter W_LOAD_ADDR = 0
)
(
    input clk,
    input reset,

    // Router mode
    input [3:0] router_mode,

    // GLB read interface (neutral names)
    output [ADDR_BITWIDTH_GLB-1:0] glb_addr_read_wght,
    output                          glb_req_read_wght,

    // Directional input ports
    input [DATA_BITWIDTH-1:0] north_data_i_wght,
    input                      north_enable_i_wght,

    input [DATA_BITWIDTH-1:0] south_data_i_wght,
    input                      south_enable_i_wght,

    input [DATA_BITWIDTH-1:0] west_data_i_wght,
    input                      west_enable_i_wght,

    input [DATA_BITWIDTH-1:0] east_data_i_wght,
    input                      east_enable_i_wght,

    // Directional output ports
    output reg [DATA_BITWIDTH-1:0] north_data_o_wght,
    output reg                      north_enable_o_wght,

    output reg [DATA_BITWIDTH-1:0] south_data_o_wght,
    output reg                      south_enable_o_wght,

    output     [DATA_BITWIDTH-1:0] west_data_o_wght,
    output                          west_enable_o_wght,

    output reg [DATA_BITWIDTH-1:0] east_data_o_wght,
    output reg                      east_enable_o_wght
);

    // Routing mode definitions (same encoding as other routers)
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

    // 1) Select active input (priority: north, south, west, east)
    reg [DATA_BITWIDTH-1:0] data_out;
    reg load_spad_ctrl_c;

    always @(*) begin
        if (north_enable_i_wght) begin
            data_out = north_data_i_wght;
            load_spad_ctrl_c = 1;
        end
        else if (south_enable_i_wght) begin
            data_out = south_data_i_wght;
            load_spad_ctrl_c = 1;
        end
        else if (west_enable_i_wght) begin
            data_out = west_data_i_wght;
            load_spad_ctrl_c = 1;
        end
        else if (east_enable_i_wght) begin
            data_out = east_data_i_wght;
            load_spad_ctrl_c = 1;
        end
        else begin
            data_out = 0;
            load_spad_ctrl_c = 0;
        end
    end

    // 2) Pulse generator for load_spad_ctrl
    reg load_spad_ctrl_0, load_spad_ctrl_1;
    wire load_spad_ctrl;
    assign load_spad_ctrl = load_spad_ctrl_0 & (~load_spad_ctrl_1);

    always @(posedge clk) begin
        if (reset) begin
            load_spad_ctrl_0 <= 0;
            load_spad_ctrl_1 <= 0;
        end else begin
            load_spad_ctrl_0 <= load_spad_ctrl_c;
            load_spad_ctrl_1 <= load_spad_ctrl_0;
        end
    end

    // 3) Instantiate the actual GLB->SPAD loader for weights (router_weight)
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
    router_weight_0 (
        .clk(clk),
        .reset(reset),

        // assumed router_weight loader ports (matching pattern used for router_iact)
        .r_data_glb_wght(data_out),
        .r_addr_glb_wght(glb_addr_read_wght),
        .read_req_glb_wght(glb_req_read_wght),

        // loader outputs drive the local SPAD write interface (kept as west-named outputs for compatibility)
        .w_data_spad(west_data_o_wght),
        .load_en_spad(west_enable_o_wght),

        .load_spad_ctrl(load_spad_ctrl)
    );

    // 4) Output routing logic based on router_mode
    always @(*) begin
        // default outputs
        north_data_o_wght  = 0;
        south_data_o_wght  = 0;
        east_data_o_wght   = 0;
        north_enable_o_wght = 0;
        south_enable_o_wght = 0;
        east_enable_o_wght  = 0;

        case (router_mode)
            ALL: begin
                north_data_o_wght  = data_out;
                south_data_o_wght  = data_out;
                east_data_o_wght   = data_out;
                north_enable_o_wght = 1;
                south_enable_o_wght = 1;
                east_enable_o_wght  = 1;
            end

            NORTH: begin
                north_data_o_wght  = data_out;
                north_enable_o_wght = 1;
            end

            SOUTH: begin
                south_data_o_wght  = data_out;
                south_enable_o_wght = 1;
            end

            WEST: begin
                // west handled by loader outputs (west_data_o_wght / west_enable_o_wght)
            end

            EAST: begin
                east_data_o_wght   = data_out;
                east_enable_o_wght = 1;
            end

            EASTNORTH: begin
                east_data_o_wght   = data_out;
                north_data_o_wght  = data_out;
                east_enable_o_wght = 1;
                north_enable_o_wght = 1;
            end

            EASTSOUTH: begin
                east_data_o_wght   = data_out;
                south_data_o_wght  = data_out;
                east_enable_o_wght = 1;
                south_enable_o_wght = 1;
            end

            EASTWEST: begin
                // west handled by loader outputs
                east_data_o_wght   = data_out;
                east_enable_o_wght = 1;
            end

            WESTNORTH: begin
                north_data_o_wght  = data_out;
                north_enable_o_wght = 1;
            end

            WESTSOUTH: begin
                south_data_o_wght  = data_out;
                south_enable_o_wght = 1;
            end

            WESTEAST: begin
                east_data_o_wght   = data_out;
                east_enable_o_wght = 1;
            end

            CLOSED: begin
                // all zeroed
            end

            default: begin
                // defaults already set
            end
        endcase
    end

endmodule

