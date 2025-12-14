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

    // 0=N, 1=S, 2=W, 3=E
    parameter integer COMPUTE_DIR = 3
)
(
    // ---------------- EXACT SAME PORTS ----------------
    input  clk,
    input  reset,
    input  [3:0] router_mode,

    input  [DATA_BITWIDTH*X_dim-1:0] north_data_i,
    input                            north_enable_i,

    output reg [DATA_BITWIDTH*X_dim-1:0] south_data_o,
    output reg                           south_enable_o,

    input  [DATA_BITWIDTH*X_dim-1:0] west_data_i,
    input                            west_enable_i,

    output [DATA_BITWIDTH-1:0]       west_data_o,
    output                           west_enable_o,

    input  [DATA_BITWIDTH*X_dim-1:0] east_data_i,
    input                            east_enable_i,

    output reg [DATA_BITWIDTH*X_dim-1:0] east_data_o,

    output [ADDR_BITWIDTH_GLB-1:0]   w_addr_glb_psum
);

    // -------------------------------------------------
    // Direction constants
    // -------------------------------------------------
    localparam DIR_N = 0;
    localparam DIR_S = 1;
    localparam DIR_W = 2;
    localparam DIR_E = 3;

    // -------------------------------------------------
    // Arbitration (IDENTICAL to router_west_psum)
    // -------------------------------------------------
    reg [DATA_BITWIDTH*X_dim-1:0] data_out;

    always @(*) begin
        if (north_enable_i)
            data_out = north_data_i;
        else if (west_enable_i)
            data_out = west_data_i;
        else
            data_out = 0;
    end

    // -------------------------------------------------
    // Routing modes (IDENTICAL behavior)
    // -------------------------------------------------
    localparam SOUTH     = 2;
    localparam EAST      = 4;
    localparam EASTSOUTH = 6;
    localparam CLOSED    = 11;

    always @(*) begin
        south_data_o   = 0;
        south_enable_o = 0;
        east_data_o    = 0;

        case (router_mode)
            SOUTH: begin
                south_data_o   = data_out;
                south_enable_o = north_enable_i | west_enable_i;
            end

            EAST: begin
                east_data_o = data_out;
            end

            EASTSOUTH: begin
                south_data_o   = data_out;
                south_enable_o = north_enable_i | west_enable_i;
                east_data_o    = data_out;
            end

            CLOSED: begin
                // no outputs
            end
        endcase
    end

    // -------------------------------------------------
    // COMPUTE-DIR SELECTED PSUM SOURCE
    // -------------------------------------------------
    wire [DATA_BITWIDTH*X_dim-1:0] psum_data_src =
        (COMPUTE_DIR == DIR_N) ? north_data_i :
        (COMPUTE_DIR == DIR_W) ? west_data_i  :
        (COMPUTE_DIR == DIR_E) ? east_data_i  :
                                 0;

    wire psum_enable_src =
        (COMPUTE_DIR == DIR_N) ? north_enable_i :
        (COMPUTE_DIR == DIR_W) ? west_enable_i  :
        (COMPUTE_DIR == DIR_E) ? east_enable_i  :
                                 1'b0;

    // -------------------------------------------------
    // PSUM MODULE (UNMODIFIED, REUSED)
    // -------------------------------------------------
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
        .r_data_spad_psum(psum_data_src),
        .w_addr_glb_psum(w_addr_glb_psum),
        .write_en_glb_psum(west_enable_o),
        .w_data_glb_psum(west_data_o),
        .write_psum_ctrl(psum_enable_src)
    );

endmodule

