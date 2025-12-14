`timescale 1ns/1ps

module tb_router_generic_iact;

    // -------------------------------------------------
    // Parameters
    // -------------------------------------------------
    localparam DATA_BITWIDTH     = 16;
    localparam ADDR_BITWIDTH_GLB = 10;

    // -------------------------------------------------
    // DUT signals
    // -------------------------------------------------
    reg clk;
    reg reset;
    reg [3:0] router_mode;

    wire [ADDR_BITWIDTH_GLB-1:0] glb_addr_read;
    wire                         glb_req_read;

    reg  [DATA_BITWIDTH-1:0] north_data_i;
    reg                       north_enable_i;
    reg  [DATA_BITWIDTH-1:0] south_data_i;
    reg                       south_enable_i;
    reg  [DATA_BITWIDTH-1:0] west_data_i;
    reg                       west_enable_i;
    reg  [DATA_BITWIDTH-1:0] east_data_i;
    reg                       east_enable_i;

    wire [DATA_BITWIDTH-1:0] north_data_o;
    wire                     north_enable_o;
    wire [DATA_BITWIDTH-1:0] south_data_o;
    wire                     south_enable_o;
    wire [DATA_BITWIDTH-1:0] west_data_o;
    wire                     west_enable_o;
    wire [DATA_BITWIDTH-1:0] east_data_o;
    wire                     east_enable_o;

    // -------------------------------------------------
    // DUT instance
    // COMPUTE_DIR = WEST (drop-in match)
    // -------------------------------------------------
    router_generic_iact #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .COMPUTE_DIR(2) // WEST
    ) dut (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_read(glb_addr_read),
        .glb_req_read(glb_req_read),

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
    // Clock (100 MHz)
    // -------------------------------------------------
    always #5 clk = ~clk;

    // -------------------------------------------------
    // VCD
    // -------------------------------------------------
    initial begin
        $dumpfile("router_generic_iact_tb.vcd");
        $dumpvars(0, tb_router_generic_iact);
    end

    // -------------------------------------------------
    // Helpers
    // -------------------------------------------------
    task clear_inputs;
        begin
            north_enable_i = 0;
            south_enable_i = 0;
            west_enable_i  = 0;
            east_enable_i  = 0;
            north_data_i   = 0;
            south_data_i   = 0;
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
        clk = 0;
        reset = 1;
        router_mode = 0;
        clear_inputs();

        // -------- Reset --------
        wait_clk(3);
        reset = 0;
        wait_clk(2);

        // =================================================
        // TEST 1: Routing ONLY (no SPAD activity)
        // =================================================
        router_mode = 2; // SOUTH
        north_data_i   = 16'hAAAA;
        north_enable_i = 1;

        wait_clk(2);
        clear_inputs();

        // =================================================
        // TEST 2: CLOSED mode blocks routing
        // =================================================
        router_mode = 11; // CLOSED
        north_data_i   = 16'hBBBB;
        north_enable_i = 1;

        wait_clk(2);
        clear_inputs();

        // =================================================
        // TEST 3: SPAD load (isolated)
        // Routing must NOT toggle
        // =================================================
        router_mode = 11; // CLOSED

        west_data_i   = 16'h0101;
        west_enable_i = 1;   // triggers SPAD load

        wait_clk(1);
        west_enable_i = 0;

        // Observe SPAD writes
        wait_clk(10);

        // =================================================
        // TEST 4: Routing + SPAD overlap
        // =================================================
        router_mode = 4; // EAST
        north_data_i   = 16'hCCCC;
        north_enable_i = 1;

        wait_clk(1);
        north_enable_i = 0;

        // Trigger SPAD load again
        west_data_i   = 16'h0202;
        west_enable_i = 1;
        wait_clk(1);
        west_enable_i = 0;

        wait_clk(10);

        // =================================================
        // END
        // =================================================
        wait_clk(5);
        $finish;
    end

endmodule

