`timescale 1ns/1ps

module tb_router_generic_wght;

    // -------------------------------------------------
    // Parameters
    // -------------------------------------------------
    localparam DATA_BITWIDTH = 16;
    localparam ADDR_BITWIDTH_GLB = 10;
    localparam DIR_W = 2;  // COMPUTE_DIR = WEST

    // -------------------------------------------------
    // DUT signals
    // -------------------------------------------------
    reg clk;
    reg reset;
    reg [3:0] router_mode;

    reg [DATA_BITWIDTH-1:0] north_data_i;
    reg north_enable_i;

    reg [DATA_BITWIDTH-1:0] south_data_i;
    reg south_enable_i;

    reg [DATA_BITWIDTH-1:0] west_data_i;
    reg west_enable_i;

    reg [DATA_BITWIDTH-1:0] east_data_i;
    reg east_enable_i;

    wire [ADDR_BITWIDTH_GLB-1:0] glb_addr_read_wght;
    wire glb_req_read_wght;

    wire [DATA_BITWIDTH-1:0] north_data_o;
    wire north_enable_o;

    wire [DATA_BITWIDTH-1:0] south_data_o;
    wire south_enable_o;

    wire [DATA_BITWIDTH-1:0] west_data_o;
    wire west_enable_o;

    wire [DATA_BITWIDTH-1:0] east_data_o;
    wire east_enable_o;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------
    router_generic_wght #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .kernel_size(3),
        .W_READ_ADDR(10'h040),
        .COMPUTE_DIR(DIR_W)
    ) dut (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_read_wght(glb_addr_read_wght),
        .glb_req_read_wght(glb_req_read_wght),

        .north_data_i(north_data_i),
        .north_enable_i(north_enable_i),

        .south_data_i(south_data_i),
        .south_enable_i(south_enable_i),

        .west_data_i(west_data_i),
        .west_enable_i(west_enable_i),

        .east_data_i(east_data_i),
        .east_enable_i(east_enable_i),

        .north_data_o(north_data_o),
        .north_enable_o(north_enable_o),

        .south_data_o(south_data_o),
        .south_enable_o(south_enable_o),

        .west_data_o(west_data_o),
        .west_enable_o(west_enable_o),

        .east_data_o(east_data_o),
        .east_enable_o(east_enable_o)
    );

    // -------------------------------------------------
    // Clock
    // -------------------------------------------------
    always #5 clk = ~clk;

    // -------------------------------------------------
    // Wave dump
    // -------------------------------------------------
    initial begin
        $dumpfile("router_generic_wght.vcd");
        $dumpvars(0, tb_router_generic_wght);
    end

    // -------------------------------------------------
    // Stimulus
    // -------------------------------------------------
    initial begin
        clk = 0;
        reset = 1;

        router_mode = 0;

        north_data_i = 0; north_enable_i = 0;
        south_data_i = 0; south_enable_i = 0;
        west_data_i  = 0; west_enable_i  = 0;
        east_data_i  = 0; east_enable_i  = 0;

        #20 reset = 0;

        // -------------------------------------------------
        // TEST 1: Routing only (north -> south)
        // -------------------------------------------------
        $display("TEST 1: routing north to south");
        router_mode = 4'd2; // SOUTH

        north_data_i   = 16'h1111;
        north_enable_i = 1;
        #10;
        north_enable_i = 0;

        #40;

        // -------------------------------------------------
        // TEST 2: Weight load triggered from EAST
        // Routing continues in parallel
        // -------------------------------------------------
        $display("TEST 2: weight load + routing");
        router_mode = 4'd1; // NORTH

        east_data_i   = 16'hAAAA;
        east_enable_i = 1;
        #10;
        east_enable_i = 0;

        #120;

        // -------------------------------------------------
        // TEST 3: Second kernel load
        // -------------------------------------------------
        $display("TEST 3: second kernel");
        east_data_i   = 16'h5555;
        east_enable_i = 1;
        #10;
        east_enable_i = 0;

        #120;

        $display("Simulation complete");
        $finish;
    end

endmodule

