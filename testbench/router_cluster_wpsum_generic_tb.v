`timescale 1ns/1ps

module tb_router_cluster_generic_wpsum;

    // ============================================================
    // Parameters
    // ============================================================
    localparam DATA_BITWIDTH = 16;
    localparam X_dim         = 5;
    localparam ADDR_GLB      = 10;

    // ============================================================
    // Clock / Reset
    // ============================================================
    reg clk;
    reg reset;

    always #5 clk = ~clk;

    // ============================================================
    // IACT plane
    // ============================================================
    wire [ADDR_GLB-1:0] west_0_addr_read_iact;
    wire                west_0_req_read_iact;
    reg  [3:0]          router_mode_west_0_iact;

    reg  [DATA_BITWIDTH-1:0] west_data_i_west_0_iact;
    reg                       west_enable_i_west_0_iact;
    wire [DATA_BITWIDTH-1:0] west_data_o_west_0_iact;
    wire                      west_enable_o_west_0_iact;

    reg  [DATA_BITWIDTH-1:0] north_data_i_iact;
    reg                       north_enable_i_iact;
    wire [DATA_BITWIDTH-1:0] north_data_o_iact;
    wire                      north_enable_o_iact;

    reg  [DATA_BITWIDTH-1:0] south_data_i_iact;
    reg                       south_enable_i_iact;
    wire [DATA_BITWIDTH-1:0] south_data_o_iact;
    wire                      south_enable_o_iact;

    reg  [DATA_BITWIDTH-1:0] east_data_i_iact;
    reg                       east_enable_i_iact;
    wire [DATA_BITWIDTH-1:0] east_data_o_iact;
    wire                      east_enable_o_iact;

    // ============================================================
    // WGHT plane
    // ============================================================
    wire [ADDR_GLB-1:0] west_0_addr_read_wght;
    wire                west_0_req_read_wght;
    reg  [3:0]          router_mode_west_0_wght;

    reg  [DATA_BITWIDTH-1:0] west_data_i_west_0_wght;
    reg                       west_enable_i_west_0_wght;
    wire [DATA_BITWIDTH-1:0] west_data_o_west_0_wght;
    wire                      west_enable_o_west_0_wght;

    wire [DATA_BITWIDTH-1:0] north_data_o_wght;
    wire                      north_enable_o_wght;
    wire [DATA_BITWIDTH-1:0] south_data_o_wght;
    wire                      south_enable_o_wght;
    wire [DATA_BITWIDTH-1:0] east_data_o_wght;
    wire                      east_enable_o_wght;

    // ============================================================
    // PSUM plane
    // ============================================================
    reg  [3:0] router_mode_west_0_psum;

    reg  [DATA_BITWIDTH*X_dim-1:0] north_data_i_psum;
    reg                             north_enable_i_psum;
    wire [DATA_BITWIDTH*X_dim-1:0] south_data_o_psum;
    wire                            south_enable_o_psum;

    reg  [DATA_BITWIDTH*X_dim-1:0] west_data_i_west_0_psum;
    reg                             west_enable_i_west_0_psum;
    wire [DATA_BITWIDTH-1:0]        west_data_o_west_0_psum;
    wire                             west_enable_o_west_0_psum;

    reg  [DATA_BITWIDTH*X_dim-1:0] east_data_i_west_0_psum;
    reg                             east_enable_i_west_0_psum;
    wire [DATA_BITWIDTH*X_dim-1:0] east_data_o_west_0_psum;

    wire [ADDR_GLB-1:0] west_addr_o_west_0_psum;

    // ============================================================
    // DUT
    // ============================================================
    router_cluster_generic_wpsum dut (
    .clk(clk),
    .reset(reset),

    // IACT
    .west_0_addr_read_iact(west_0_addr_read_iact),
    .west_0_req_read_iact(west_0_req_read_iact),
    .router_mode_west_0_iact(router_mode_west_0_iact),
    .west_data_i_west_0_iact(west_data_i_west_0_iact),
    .west_enable_i_west_0_iact(west_enable_i_west_0_iact),
    .west_data_o_west_0_iact(west_data_o_west_0_iact),
    .west_enable_o_west_0_iact(west_enable_o_west_0_iact),
    .north_data_i_iact(north_data_i_iact),
    .north_enable_i_iact(north_enable_i_iact),
    .south_data_i_iact(south_data_i_iact),
    .south_enable_i_iact(south_enable_i_iact),
    .east_data_i_iact(east_data_i_iact),
    .east_enable_i_iact(east_enable_i_iact),
    .north_data_o_iact(north_data_o_iact),
    .north_enable_o_iact(north_enable_o_iact),
    .south_data_o_iact(south_data_o_iact),
    .south_enable_o_iact(south_enable_o_iact),
    .east_data_o_iact(east_data_o_iact),
    .east_enable_o_iact(east_enable_o_iact),

    // WGHT
    .west_0_addr_read_wght(west_0_addr_read_wght),
    .west_0_req_read_wght(west_0_req_read_wght),
    .router_mode_west_0_wght(router_mode_west_0_wght),
    .west_data_i_west_0_wght(west_data_i_west_0_wght),
    .west_enable_i_west_0_wght(west_enable_i_west_0_wght),
    .west_data_o_west_0_wght(west_data_o_west_0_wght),
    .west_enable_o_west_0_wght(west_enable_o_west_0_wght),
    .north_data_o_wght(north_data_o_wght),
    .north_enable_o_wght(north_enable_o_wght),
    .south_data_o_wght(south_data_o_wght),
    .south_enable_o_wght(south_enable_o_wght),
    .east_data_o_wght(east_data_o_wght),
    .east_enable_o_wght(east_enable_o_wght),

    // PSUM
    .router_mode_west_0_psum(router_mode_west_0_psum),
    .north_data_i_psum(north_data_i_psum),
    .north_enable_i_psum(north_enable_i_psum),
    .south_data_o_psum(south_data_o_psum),
    .south_enable_o_psum(south_enable_o_psum),
    .west_data_i_west_0_psum(west_data_i_west_0_psum),
    .west_enable_i_west_0_psum(west_enable_i_west_0_psum),
    .west_data_o_west_0_psum(west_data_o_west_0_psum),
    .west_enable_o_west_0_psum(west_enable_o_west_0_psum),
    .east_data_i_west_0_psum(east_data_i_west_0_psum),
    .east_enable_i_west_0_psum(east_enable_i_west_0_psum),
    .east_data_o_west_0_psum(east_data_o_west_0_psum),
    .west_addr_o_west_0_psum(west_addr_o_west_0_psum)
);


    // ============================================================
    // VCD
    // ============================================================
    initial begin
        $dumpfile("router_cluster_generic_wpsum_tb.vcd");
        $dumpvars(0, tb_router_cluster_generic_wpsum);
    end

    // ============================================================
    // Logging & checking utilities (IVERILOG SAFE)
    // ============================================================
    integer errors = 0;

    task LOG_INFO(input string msg);
        $display("[INFO ] %0t ns : %s", $time, msg);
    endtask

    task LOG_PASS(input string msg);
        $display("[PASS ] %0t ns : %s", $time, msg);
    endtask

    task LOG_FAIL(input string msg);
        begin
            $display("[FAIL ] %0t ns : %s", $time, msg);
            errors = errors + 1;
        end
    endtask

    task CHECK(input bit cond, input string msg);
        if (!cond) LOG_FAIL(msg);
    endtask

    task wait_clk(input int n);
        repeat (n) @(posedge clk);
    endtask

    // ============================================================
    // Test sequence (UNCHANGED LOGIC)
    // ============================================================
    integer seen_psum_write;

    initial begin
        clk = 0;
        reset = 1;

        router_mode_west_0_iact = 11;
        router_mode_west_0_wght = 11;
        router_mode_west_0_psum = 2;

        wait_clk(3);
        reset = 0;
        LOG_INFO("Reset deasserted; beginning functional verification");
        wait_clk(2);

        // ---- TEST 1: IACT isolation ----
        LOG_INFO("TEST 1: IACT SPAD isolation");

        west_data_i_west_0_iact = 16'h1234;
        west_enable_i_west_0_iact = 1;
        wait_clk(1);
        west_enable_i_west_0_iact = 0;
        wait_clk(2);

        LOG_INFO($sformatf(
            "Observed IACT north_enable_o = %0b (expected 0)",
            north_enable_o_iact
        ));
        CHECK(north_enable_o_iact == 0,
              "IACT routing enable asserted during SPAD load");
        LOG_PASS("IACT SPAD isolation verified");

        // ---- TEST 2: WGHT isolation ----
        LOG_INFO("TEST 2: WGHT SPAD isolation");

        west_data_i_west_0_wght = 16'h5678;
        west_enable_i_west_0_wght = 1;
        wait_clk(1);
        west_enable_i_west_0_wght = 0;
        wait_clk(2);

        LOG_INFO($sformatf(
            "Observed WGHT north_enable_o = %0b (expected 0)",
            north_enable_o_wght
        ));
        CHECK(north_enable_o_wght == 0,
              "WGHT routing enable asserted during SPAD load");
        LOG_PASS("WGHT SPAD isolation verified");

        // ---- TEST 3: PSUM FSM ----
        LOG_INFO("TEST 3: PSUM FSM activation");

        seen_psum_write = 0;
        east_data_i_west_0_psum = {
            16'h0005,16'h0004,16'h0003,16'h0002,16'h0001
        };
        east_enable_i_west_0_psum = 1;
        wait_clk(1);
        east_enable_i_west_0_psum = 0;

        repeat (6) begin
            @(posedge clk);
            LOG_INFO($sformatf(
                "PSUM write_en=%0b addr=%0d data=0x%h",
                west_enable_o_west_0_psum,
                west_addr_o_west_0_psum,
                west_data_o_west_0_psum
            ));
            if (west_enable_o_west_0_psum)
                seen_psum_write = 1;
        end

        CHECK(seen_psum_write,
              "PSUM write did not start within expected latency");
        LOG_PASS("PSUM FSM activation verified");

        // ---- TEST 4: PSUM routing ----
        LOG_INFO("TEST 4: PSUM routing during write");

        north_data_i_psum   = {X_dim{16'hAAAA}};
        north_enable_i_psum = 1;
        wait_clk(1);

        LOG_INFO($sformatf(
            "Observed south_enable_o=%0b south_data[15:0]=0x%h",
            south_enable_o_psum,
            south_data_o_psum[15:0]
        ));
        CHECK(south_enable_o_psum == 1,
              "PSUM routing enable missing");
        CHECK(south_data_o_psum[15:0] == 16'hAAAA,
              "PSUM routing data mismatch");

        LOG_PASS("PSUM routing during write verified");

        wait_clk(3);

        if (errors == 0)
            $display("\n[RESULT] TEST PASSED : All checks successful\n");
        else
            $display("\n[RESULT] TEST FAILED : %0d error(s) detected\n", errors);

        $finish;
    end

endmodule

