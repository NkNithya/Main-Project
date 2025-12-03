`timescale 1ns / 1ps

module router_generic_wpsum
#(
    parameter DATA_BITWIDTH      = 16,
    parameter ADDR_BITWIDTH_GLB  = 10,
    parameter ADDR_BITWIDTH_SPAD = 9,

    parameter X_dim       = 5,
    parameter Y_dim       = 3,
    parameter kernel_size = 3,
    parameter act_size    = 5,

    parameter PSUM_READ_ADDR = 0,
    parameter PSUM_LOAD_ADDR = 0
)
(
    input clk,
    input reset,

    // Mode control
    input [3:0] router_mode,

    // Directional Inputs
    input  [DATA_BITWIDTH*X_dim-1:0] north_data_i,
    input                            north_enable_i,

    input  [DATA_BITWIDTH*X_dim-1:0] south_data_i,
    input                            south_enable_i,

    input  [DATA_BITWIDTH*X_dim-1:0] west_data_i,
    input                            west_enable_i,

    input  [DATA_BITWIDTH*X_dim-1:0] east_data_i,
    input                            east_enable_i,

    // Directional Outputs
    output reg [DATA_BITWIDTH*X_dim-1:0] north_data_o,
    output reg                           north_enable_o,

    output reg [DATA_BITWIDTH*X_dim-1:0] south_data_o,
    output reg                           south_enable_o,

    // PSUM write (WEST output)
    output     [DATA_BITWIDTH-1:0]       west_data_o,
    output                                west_enable_o,

    output reg [DATA_BITWIDTH*X_dim-1:0] east_data_o,
    output reg                           east_enable_o,

    output [ADDR_BITWIDTH_GLB-1:0] psum_write_addr
);

    // -----------------------------
    // Mode Encoding
    // -----------------------------
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

    // -----------------------------
    // 1) Input Arbiter
    // -----------------------------
    reg [DATA_BITWIDTH*X_dim-1:0] data_out;
    reg source_valid_c;

    always @(*) begin
        if (north_enable_i) begin
            data_out = north_data_i;
            source_valid_c = 1'b1;
        end
        else if (south_enable_i) begin
            data_out = south_data_i;
            source_valid_c = 1'b1;
        end
        else if (west_enable_i) begin
            data_out = west_data_i;
            source_valid_c = 1'b1;
        end
        else if (east_enable_i) begin
            data_out = east_data_i;
            source_valid_c = 1'b1;
        end
        else begin
            data_out = {DATA_BITWIDTH*X_dim{1'b0}};
            source_valid_c = 1'b0;
        end
    end

    // -----------------------------
    // 2) Synchronous level (VALID) → write_psum_ctrl
    // -----------------------------
    reg source_valid_d;

    always @(posedge clk) begin
        if (reset)
            source_valid_d <= 1'b0;
        else
            source_valid_d <= source_valid_c;
    end

    // -----------------------------
    // 3) router_psum
    // -----------------------------
    wire [DATA_BITWIDTH-1:0]      w_data_psum;
    wire                          write_en_psum;
    wire [ADDR_BITWIDTH_GLB-1:0]  w_addr_psum;

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
    )
    router_psum_0 (
        .clk(clk),
        .reset(reset),

        .r_data_spad_psum(data_out),
        .w_addr_glb_psum(w_addr_psum),
        .write_en_glb_psum(write_en_psum),
        .w_data_glb_psum(w_data_psum),

        // FIXED CONTROL: sampled level instead of edge pulse
        .write_psum_ctrl(source_valid_d)
    );

    assign psum_write_addr = w_addr_psum;
    assign west_data_o     = w_data_psum;
    assign west_enable_o   = write_en_psum;

    // -----------------------------
    // 4) Output Routing Logic (unchanged)
    // -----------------------------
    always @(*) begin
        north_data_o   = 0;
        south_data_o   = 0;
        east_data_o    = 0;

        north_enable_o = 0;
        south_enable_o = 0;
        east_enable_o  = 0;

        case (router_mode)
            ALL: begin
                north_data_o = data_out;
                south_data_o = data_out;
                east_data_o  = data_out;

                north_enable_o = 1;
                south_enable_o = 1;
                east_enable_o  = 1;
            end

            NORTH: begin
                north_data_o   = data_out;
                north_enable_o = 1;
            end

            SOUTH: begin
                south_data_o   = data_out;
                south_enable_o = 1;
            end

            EAST: begin
                east_data_o   = data_out;
                east_enable_o = 1;
            end

            // WEST handled only by router_psum (write_en_psum)
            WEST: begin end

            EASTNORTH: begin
                east_data_o    = data_out;
                north_data_o   = data_out;
                east_enable_o  = 1;
                north_enable_o = 1;
            end

            EASTSOUTH: begin
                east_data_o    = data_out;
                south_data_o   = data_out;
                east_enable_o  = 1;
                south_enable_o = 1;
            end

            EASTWEST: begin
                east_data_o   = data_out;
                east_enable_o = 1;
            end

            WESTNORTH: begin
                north_data_o   = data_out;
                north_enable_o = 1;
            end

            WESTSOUTH: begin
                south_data_o   = data_out;
                south_enable_o = 1;
            end

            WESTEAST: begin
                east_data_o   = data_out;
                east_enable_o = 1;
            end

            CLOSED: begin end
        endcase
    end

endmodule
