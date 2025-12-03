`timescale 1ns/1ps

module router_generic_wpsum_tb;

    localparam DATA_BITWIDTH = 16;
    localparam X_dim         = 5;
    localparam DW            = DATA_BITWIDTH * X_dim;

    // Routing Modes
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

    //-------------------------------------
    // DUT IO
    //-------------------------------------
    reg clk = 0;
    reg reset = 1;

    reg  [3:0] router_mode;

    reg  [DW-1:0] north_data_i, south_data_i, east_data_i, west_data_i;
    reg           north_enable_i, south_enable_i, east_enable_i, west_enable_i;

    wire [DW-1:0] north_data_o, south_data_o, east_data_o;
    wire          north_enable_o, south_enable_o, east_enable_o;

    wire [15:0]   west_data_o;
    wire          west_enable_o;

    wire [9:0]    psum_write_addr;

    always #5 clk = ~clk;

    //-------------------------------------
    // DUT
    //-------------------------------------
    router_generic_wpsum #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(10),
        .ADDR_BITWIDTH_SPAD(9),
        .X_dim(X_dim),
        .Y_dim(3)
    ) dut (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

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

        .east_data_o(east_data_o),
        .east_enable_o(east_enable_o),

        .west_data_o(west_data_o),
        .west_enable_o(west_enable_o),

        .psum_write_addr(psum_write_addr)
    );

    //-------------------------------------
    // ROUTING CHECKER (N/E/S only)
    //-------------------------------------
    task check_routing;
        input [3:0] mode;
        input expN, expS, expE;
        input [DW-1:0] expData;

        begin
            repeat(2) @(posedge clk);

            if (expN && !(north_enable_o && north_data_o == expData))
                $fatal(1, $sformatf("FAIL mode %0d : NORTH wrong", mode));
            if (!expN && north_enable_o)
                $fatal(1, $sformatf("FAIL mode %0d : unexpected NORTH", mode));

            if (expS && !(south_enable_o && south_data_o == expData))
                $fatal(1, $sformatf("FAIL mode %0d : SOUTH wrong", mode));
            if (!expS && south_enable_o)
                $fatal(1, $sformatf("FAIL mode %0d : unexpected SOUTH", mode));

            if (expE && !(east_enable_o && east_data_o == expData))
                $fatal(1, $sformatf("FAIL mode %0d : EAST wrong", mode));
            if (!expE && east_enable_o)
                $fatal(1, $sformatf("FAIL mode %0d : unexpected EAST", mode));

            $display("PASS routing mode=%0d", mode);
        end
    endtask

    //-------------------------------------
    // PSUM WRITEBACK CHECKER (WEST only)
    //-------------------------------------
    task check_psum;
        input [15:0] expData;

        begin
            @(posedge clk);
            if (!west_enable_o)
                $fatal(1, "FAIL: PSUM expected write but WEST enable is low");

            if (west_data_o !== expData)
                $fatal(1, $sformatf("FAIL: PSUM data mismatch (got=%h expected=%h)",
                                    west_data_o, expData));

            $display("PASS PSUM writeback");
        end
    endtask

    //-------------------------------------
    // TEST SEQUENCE
    //-------------------------------------
    reg [DW-1:0] P;

    initial begin
        north_enable_i = 0;
        south_enable_i = 0;
        east_enable_i  = 0;
        west_enable_i  = 0;

        P = {X_dim{16'hA5A5}};

        #20 reset = 0;

        //-----------------------------------------------------
        // 1. PURE ROUTING TESTS (NO PSUM EXPECTED)
        //-----------------------------------------------------

        router_mode = ALL;
        north_data_i = P; north_enable_i = 1;
        check_routing(ALL, 1,1,1, P);
        north_enable_i = 0;

        router_mode = NORTH;
        north_data_i = P; north_enable_i = 1;
        check_routing(NORTH,1,0,0, P);
        north_enable_i = 0;

        router_mode = SOUTH;
        south_data_i = P; south_enable_i = 1;
        check_routing(SOUTH,0,1,0, P);
        south_enable_i = 0;

        router_mode = EAST;
        east_data_i = P; east_enable_i = 1;
        check_routing(EAST,0,0,1, P);
        east_enable_i = 0;

        router_mode = EASTNORTH;
        north_data_i = P; north_enable_i = 1;
        check_routing(EASTNORTH,1,0,1, P);
        north_enable_i = 0;

        //-----------------------------------------------------
        // 2. PSUM (WEST) WRITEBACK TEST
        //-----------------------------------------------------
        // WEST mode is not actually used by routing block,
        // but input here feeds router_psum correctly.
        router_mode = WEST;

        west_data_i = P;
        west_enable_i = 1;

        check_psum(P[15:0]);   // PSUM output = lower 16 bits

        west_enable_i = 0;

        $display("\n=== ALL TESTS PASSED ===");
        $finish;
    end

    //-------------------------------------
    // WAVES
    //-------------------------------------
    initial begin
        $dumpfile("router_generic_wpsum_tb.vcd");
        $dumpvars(0, router_generic_wpsum_tb);
    end

endmodule
