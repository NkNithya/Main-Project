`timescale 1ns/1ps
module HMNoC_top #(parameter DATA_WIDTH = 16) (
    input  logic clk,
    input  logic reset
);

    // -----------------------------
    // Inter-router wires (for wght/iact/psum)
    // -----------------------------
    logic [DATA_WIDTH-1:0] east_data_00_wght, east_data_10_wght;
    logic [DATA_WIDTH-1:0] west_data_01_wght, west_data_11_wght;
    logic [DATA_WIDTH-1:0] south_data_00_wght, south_data_01_wght;
    logic [DATA_WIDTH-1:0] north_data_10_wght, north_data_11_wght;

    logic east_en_00_wght, east_en_10_wght;
    logic west_en_01_wght, west_en_11_wght;
    logic south_en_00_wght, south_en_01_wght;
    logic north_en_10_wght, north_en_11_wght;

    // Repeat for iact
    logic [DATA_WIDTH-1:0] east_data_00_iact, east_data_10_iact;
    logic [DATA_WIDTH-1:0] west_data_01_iact, west_data_11_iact;
    logic [DATA_WIDTH-1:0] south_data_00_iact, south_data_01_iact;
    logic [DATA_WIDTH-1:0] north_data_10_iact, north_data_11_iact;

    logic east_en_00_iact, east_en_10_iact;
    logic west_en_01_iact, west_en_11_iact;
    logic south_en_00_iact, south_en_01_iact;
    logic north_en_10_iact, north_en_11_iact;

    // Repeat for psum
    logic [DATA_WIDTH-1:0] east_data_00_psum, east_data_10_psum;
    logic [DATA_WIDTH-1:0] west_data_01_psum, west_data_11_psum;
    logic [DATA_WIDTH-1:0] south_data_00_psum, south_data_01_psum;
    logic [DATA_WIDTH-1:0] north_data_10_psum, north_data_11_psum;

    logic east_en_00_psum, east_en_10_psum;
    logic west_en_01_psum, west_en_11_psum;
    logic south_en_00_psum, south_en_01_psum;
    logic north_en_10_psum, north_en_11_psum;

    // -----------------------------------
    // Cluster [0][0]
    // -----------------------------------
    router_cluster #(.DATA_WIDTH(DATA_WIDTH)) C00 (
        // Weight router
        .router_mode_wght(4'b0001),
        .north_data_i_wght(0), .north_enable_i_wght(0),
        .south_data_i_wght(north_data_10_wght),
        .south_enable_i_wght(north_en_10_wght),
        .west_data_i_wght(0), .west_enable_i_wght(0),
        .east_data_i_wght(west_data_01_wght),
        .east_enable_i_wght(west_en_01_wght),

        .north_data_o_wght(), .north_enable_o_wght(),
        .south_data_o_wght(south_data_00_wght),
        .south_enable_o_wght(south_en_00_wght),
        .west_data_o_wght(), .west_enable_o_wght(),
        .east_data_o_wght(east_data_00_wght),
        .east_enable_o_wght(east_en_00_wght),

        // Similarly repeat all IACT and PSUM sets...
        .router_mode_iact(4'b0001),
        .north_data_i_iact(0), .north_enable_i_iact(0),
        .south_data_i_iact(north_data_10_iact),
        .south_enable_i_iact(north_en_10_iact),
        .west_data_i_iact(0), .west_enable_i_iact(0),
        .east_data_i_iact(west_data_01_iact),
        .east_enable_i_iact(west_en_01_iact),

        .north_data_o_iact(), .north_enable_o_iact(),
        .south_data_o_iact(south_data_00_iact),
        .south_enable_o_iact(south_en_00_iact),
        .west_data_o_iact(), .west_enable_o_iact(),
        .east_data_o_iact(east_data_00_iact),
        .east_enable_o_iact(east_en_00_iact),

        .router_mode_psum(4'b0001),
        .north_data_i_psum(0), .north_enable_i_psum(0),
        .south_data_i_psum(north_data_10_psum),
        .south_enable_i_psum(north_en_10_psum),
        .west_data_i_psum(0), .west_enable_i_psum(0),
        .east_data_i_psum(west_data_01_psum),
        .east_enable_i_psum(west_en_01_psum),

        .north_data_o_psum(), .north_enable_o_psum(),
        .south_data_o_psum(south_data_00_psum),
        .south_enable_o_psum(south_en_00_psum),
        .west_data_o_psum(), .west_enable_o_psum(),
        .east_data_o_psum(east_data_00_psum),
        .east_enable_o_psum(east_en_00_psum)
    );

    // -----------------------------------
    // Cluster [0][1] (connect west<->east of C00)
    // -----------------------------------
    router_cluster #(.DATA_WIDTH(DATA_WIDTH)) C01 (
        .router_mode_wght(4'b0010),
        .north_data_i_wght(0), .north_enable_i_wght(0),
        .south_data_i_wght(north_data_11_wght),
        .south_enable_i_wght(north_en_11_wght),
        .west_data_i_wght(east_data_00_wght),
        .west_enable_i_wght(east_en_00_wght),
        .east_data_i_wght(0), .east_enable_i_wght(0),

        .north_data_o_wght(), .north_enable_o_wght(),
        .south_data_o_wght(south_data_01_wght),
        .south_enable_o_wght(south_en_01_wght),
        .west_data_o_wght(west_data_01_wght),
        .west_enable_o_wght(west_en_01_wght),
        .east_data_o_wght(), .east_enable_o_wght(),

        // repeat iact/psum like above...
        // (for brevity, you can copy the full version later)
        .router_mode_iact(4'b0010),
        .router_mode_psum(4'b0010)
    );

    // Similar pattern for C10, C11 — connect north/south, east/west.
    // -----------------------------------

endmodule
