`timescale 1ns / 1ps

module router_glb_psum_tb;

    // -------------------------------------------------
    // Parameters
    // -------------------------------------------------
    localparam DATA_BITWIDTH = 16;
    localparam ADDR_BITWIDTH = 10;

    localparam MODE_IDLE  = 4'd0;
    localparam MODE_LOCAL = 4'd1;
    localparam MODE_FWD   = 4'd2;
    localparam MODE_DRAIN = 4'd3;

    // -------------------------------------------------
    // Clock / Reset
    // -------------------------------------------------
    reg clk = 0;
    always #5 clk = ~clk;

    reg reset;

    integer cycle;
    always @(posedge clk) cycle <= cycle + 1;

    // -------------------------------------------------
    // Router inputs
    // -------------------------------------------------
    reg  [3:0] router_mode;
    reg  [DATA_BITWIDTH-1:0] local_data_i;
    reg  local_enable_i;

    reg  [DATA_BITWIDTH-1:0] north_data_i, south_data_i, west_data_i, east_data_i;
    reg  north_enable_i, south_enable_i, west_enable_i, east_enable_i;

    // -------------------------------------------------
    // Router → GLB wires
    // -------------------------------------------------
    wire [DATA_BITWIDTH-1:0] glb_w_data;
    wire [ADDR_BITWIDTH-1:0] glb_w_addr;
    wire                     glb_write_en;

    // -------------------------------------------------
    // GLB read side (unused)
    // -------------------------------------------------
    reg                      read_req;
    reg  [ADDR_BITWIDTH-1:0] r_addr;
    reg  [ADDR_BITWIDTH-1:0] r_addr_inter;
    wire [DATA_BITWIDTH-1:0] r_data;

    // -------------------------------------------------
    // DUT: PSUM Router
    // -------------------------------------------------
    router_psum_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH)
    ) dut_router (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .local_data_i(local_data_i),
        .local_enable_i(local_enable_i),

        .north_data_i(north_data_i),
        .north_enable_i(north_enable_i),
        .south_data_i(south_data_i),
        .south_enable_i(south_enable_i),
        .west_data_i(west_data_i),
        .west_enable_i(west_enable_i),
        .east_data_i(east_data_i),
        .east_enable_i(east_enable_i),

        .north_data_o(),
        .north_enable_o(),
        .south_data_o(),
        .south_enable_o(),
        .west_data_o(),
        .west_enable_o(),
        .east_data_o(),
        .east_enable_o(),

        .spad_data_o(),
        .spad_en_o(),
        .spad_addr_o(),

        .glb_data_o(glb_w_data),
        .glb_en_o(glb_write_en),
        .glb_addr_o(glb_w_addr)
    );

    // -------------------------------------------------
    // DUT: GLB PSUM
    // -------------------------------------------------
    glb_psum #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH(ADDR_BITWIDTH)
    ) dut_glb (
        .clk(clk),
        .reset(reset),

        .read_req(read_req),
        .write_en(glb_write_en),

        .r_addr(r_addr),
        .w_addr(glb_w_addr),
        .w_data(glb_w_data),

        .r_data(r_data),
        .r_addr_inter(r_addr_inter)
    );

    // -------------------------------------------------
    // Scoreboard
    // -------------------------------------------------
    integer exp_addr;

    task log_mode;
        begin
            case (router_mode)
                MODE_IDLE:  $display("[C%0d][MODE] IDLE",  cycle);
                MODE_LOCAL: $display("[C%0d][MODE] LOCAL", cycle);
                MODE_FWD:   $display("[C%0d][MODE] FWD",   cycle);
                MODE_DRAIN: $display("[C%0d][MODE] DRAIN", cycle);
                default:    $display("[C%0d][MODE] UNKNOWN", cycle);
            endcase
        end
    endtask

    task check_glb_write(input [DATA_BITWIDTH-1:0] exp_data);
        begin
            #1; // allow NBA updates

            if (!glb_write_en)
                $fatal(1, "[C%0d][GLB] Expected write enable not asserted", cycle);

            $display("[C%0d][GLB_WRITE] addr=%0d data=0x%0h",
                     cycle, glb_w_addr, glb_w_data);

            if (glb_w_addr !== exp_addr[ADDR_BITWIDTH-1:0])
                $fatal(1, "[C%0d][GLB] Addr mismatch exp=%0d got=%0d",
                       cycle, exp_addr, glb_w_addr);

            if (glb_w_data !== exp_data)
                $fatal(1, "[C%0d][GLB] Data mismatch exp=0x%0h got=0x%0h",
                       cycle, exp_data, glb_w_data);

            exp_addr = exp_addr + 1;

            @(posedge clk);
            #1;
            if (glb_write_en)
                $fatal(1, "[C%0d][GLB] Write enable held high >1 cycle", cycle);
        end
    endtask

    // -------------------------------------------------
    // Test sequence
    // -------------------------------------------------
    initial begin
        cycle = 0;
        exp_addr = 0;

        $display("=== ROUTER + GLB PSUM TB START ===");

        reset = 1;
        router_mode = MODE_IDLE;
        local_enable_i = 0;

        north_enable_i = 0;
        south_enable_i = 0;
        west_enable_i  = 0;
        east_enable_i  = 0;

        read_req = 0;
        r_addr = 0;
        r_addr_inter = 0;

        repeat (4) @(posedge clk);
        reset = 0;
        $display("[C%0d] RESET DEASSERTED", cycle);

        // -------------------------------------------------
        // TEST 1
        // -------------------------------------------------
        $display("=== TEST 1: MODE_DRAIN basic writes ===");
        router_mode = MODE_DRAIN;
        log_mode();

        local_data_i = 16'h0011;
        local_enable_i = 1;
        $display("[C%0d][INJECT] local_psum=0x0011", cycle);
        @(posedge clk);
        local_enable_i = 0;
        check_glb_write(16'h0011);

        local_data_i = 16'h0022;
        local_enable_i = 1;
        $display("[C%0d][INJECT] local_psum=0x0022", cycle);
        @(posedge clk);
        local_enable_i = 0;
        check_glb_write(16'h0022);

        local_data_i = 16'h0033;
        local_enable_i = 1;
        $display("[C%0d][INJECT] local_psum=0x0033", cycle);
        @(posedge clk);
        local_enable_i = 0;
        check_glb_write(16'h0033);

        $display("[PASS] TEST 1: MODE_DRAIN writes");

        // -------------------------------------------------
        // TEST 2
        // -------------------------------------------------
        $display("=== TEST 2: MODE_IDLE blocks writes ===");
        router_mode = MODE_IDLE;
        log_mode();

        local_data_i = 16'hFFFF;
        local_enable_i = 1;
        $display("[C%0d][INJECT] local_psum=0xFFFF (should be blocked)", cycle);
        @(posedge clk);
        local_enable_i = 0;

        #1;
        if (glb_write_en)
            $fatal(1, "[C%0d][ERROR] GLB write occurred in MODE_IDLE", cycle);

        $display("[PASS] TEST 2: MODE_IDLE safety");

        // -------------------------------------------------
        // TEST 3
        // -------------------------------------------------
        $display("=== TEST 3: Arbitration priority ===");
        router_mode = MODE_DRAIN;
        log_mode();

        local_data_i = 16'hAAAA;
        north_data_i = 16'hBBBB;

        local_enable_i = 1;
        north_enable_i = 1;
        $display("[C%0d][INJECT] local=0xAAAA north=0xBBBB", cycle);

        @(posedge clk);
        local_enable_i = 0;
        north_enable_i = 0;

        check_glb_write(16'hAAAA);
        $display("[PASS] TEST 3: Arbitration");

        // -------------------------------------------------
        // DONE
        // -------------------------------------------------
        $display("=== ALL TESTS PASSED ===");
        $finish;
    end

endmodule

