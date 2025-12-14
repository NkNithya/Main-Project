`timescale 1ns/1ps

module tb_router_generic_psum;

    // -------------------------------------------------
    // Parameters (match DUT)
    // -------------------------------------------------
    localparam DATA_BITWIDTH     = 16;
    localparam X_dim             = 5;
    localparam ADDR_BITWIDTH_GLB = 10;

    // -------------------------------------------------
    // DUT signals (EXACT drop-in interface)
    // -------------------------------------------------
    reg clk;
    reg reset;
    reg [3:0] router_mode;

    reg  [DATA_BITWIDTH*X_dim-1:0] north_data_i;
    reg                            north_enable_i;

    wire [DATA_BITWIDTH*X_dim-1:0] south_data_o;
    wire                           south_enable_o;

    reg  [DATA_BITWIDTH*X_dim-1:0] west_data_i;
    reg                            west_enable_i;

    wire [DATA_BITWIDTH-1:0]       west_data_o;
    wire                           west_enable_o;

    reg  [DATA_BITWIDTH*X_dim-1:0] east_data_i;
    reg                            east_enable_i;

    wire [DATA_BITWIDTH*X_dim-1:0] east_data_o;

    wire [ADDR_BITWIDTH_GLB-1:0]   w_addr_glb_psum;

    // -------------------------------------------------
    // DUT instance
    // COMPUTE_DIR = EAST (drop-in match)
    // -------------------------------------------------
    router_generic_psum #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .X_dim(X_dim),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .COMPUTE_DIR(3) // EAST
    ) dut (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .north_data_i(north_data_i),
        .north_enable_i(north_enable_i),

        .south_data_o(south_data_o),
        .south_enable_o(south_enable_o),

        .west_data_i(west_data_i),
        .west_enable_i(west_enable_i),

        .west_data_o(west_data_o),
        .west_enable_o(west_enable_o),

        .east_data_i(east_data_i),
        .east_enable_i(east_enable_i),

        .east_data_o(east_data_o),

        .w_addr_glb_psum(w_addr_glb_psum)
    );

    // -------------------------------------------------
    // Clock (100 MHz)
    // -------------------------------------------------
    always #5 clk = ~clk;

    // -------------------------------------------------
    // VCD dump
    // -------------------------------------------------
    initial begin
        $dumpfile("router_generic_psum_tb.vcd");
        $dumpvars(0, tb_router_generic_psum);
    end

    // -------------------------------------------------
    // Helpers
    // -------------------------------------------------
    task clear_inputs;
        begin
            north_enable_i = 0;
            west_enable_i  = 0;
            east_enable_i  = 0;
            north_data_i   = 0;
            west_data_i    = 0;
            east_data_i    = 0;
        end
    endtask

    task wait_clk(input integer n);
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    // -------------------------------------------------
    // Test sequence
    // -------------------------------------------------
    initial begin
        clk   = 0;
        reset = 1;
        router_mode = 0;
        clear_inputs();

        // -------- Reset --------
        wait_clk(3);
        reset = 0;
        wait_clk(2);

        // =================================================
        // TEST 1: NORTH priority over WEST → SOUTH
        // =================================================
        router_mode = 2; // SOUTH
        north_data_i   = {X_dim{16'hAAAA}};
        west_data_i    = {X_dim{16'hBBBB}};
        north_enable_i = 1;
        west_enable_i  = 1;

        wait_clk(2);
        clear_inputs();

        // =================================================
        // TEST 2: WEST only → SOUTH
        // =================================================
        router_mode = 2; // SOUTH
        west_data_i   = {X_dim{16'hCCCC}};
        west_enable_i = 1;

        wait_clk(2);
        clear_inputs();

        // =================================================
        // TEST 3: EASTSOUTH broadcast
        // =================================================
        router_mode = 6; // EASTSOUTH
        north_data_i   = {X_dim{16'hDDDD}};
        north_enable_i = 1;

        wait_clk(2);
        clear_inputs();

        // =================================================
        // TEST 4: CLOSED mode
        // =================================================
        router_mode = 11; // CLOSED
        north_data_i   = {X_dim{16'hEEEE}};
        north_enable_i = 1;

        wait_clk(2);
        clear_inputs();

        // =================================================
        // TEST 5: PSUM drain (single trigger)
        // =================================================
        east_data_i = {
            16'h0005,
            16'h0004,
            16'h0003,
            16'h0002,
            16'h0001
        };

        east_enable_i = 1;
        wait_clk(1);
        east_enable_i = 0;

        wait_clk(12);

        // =================================================
        // TEST 6: Back-to-back PSUM triggers
        // =================================================
        east_data_i = {
            16'h0015,
            16'h0014,
            16'h0013,
            16'h0012,
            16'h0011
        };

        east_enable_i = 1;
        wait_clk(1);
        east_enable_i = 0;

        wait_clk(8);

        east_data_i = {
            16'h0025,
            16'h0024,
            16'h0023,
            16'h0022,
            16'h0021
        };

        east_enable_i = 1;
        wait_clk(1);
        east_enable_i = 0;

        wait_clk(15);

        $finish;
    end

endmodule

