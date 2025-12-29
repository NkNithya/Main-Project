`timescale 1ns / 1ps

module router_wght_generic_tb;

    /* ------------------------------------------------------------
     * Parameters
     * ----------------------------------------------------------*/
    localparam DATA_BITWIDTH     = 16;
    localparam ADDR_BITWIDTH_GLB = 8;
    localparam ADDR_BITWIDTH_SPAD = 8;

    localparam KERNEL_SIZE  = 3;
    localparam KERNEL_ELEMS = KERNEL_SIZE * KERNEL_SIZE;
    localparam W_READ_ADDR = 8'h20;

    /* ------------------------------------------------------------
     * Clock / Reset
     * ----------------------------------------------------------*/
    reg clk;
    reg reset;

    always #5 clk = ~clk;

    /* ------------------------------------------------------------
     * DUT interface
     * ----------------------------------------------------------*/
    reg  [3:0] router_mode;

    wire [ADDR_BITWIDTH_GLB-1:0] glb_addr_read;
    wire glb_req_read;
    reg  [DATA_BITWIDTH-1:0] glb_rdata;

    wire [DATA_BITWIDTH-1:0] spad_data_o;
    wire spad_en_o;

    /* ------------------------------------------------------------
     * NoC inputs (quiet by default)
     * ----------------------------------------------------------*/
    reg  [DATA_BITWIDTH-1:0] west_data_i;
    reg  west_enable_i;

    wire [DATA_BITWIDTH-1:0] north_data_i = '0;
    wire [DATA_BITWIDTH-1:0] south_data_i = '0;
    wire [DATA_BITWIDTH-1:0] east_data_i  = '0;

    wire north_enable_i = 1'b0;
    wire south_enable_i = 1'b0;
    wire east_enable_i  = 1'b0;

    /* ------------------------------------------------------------
     * Scoreboarding
     * ----------------------------------------------------------*/
    integer cycle;
    integer glb_cnt;
    integer spad_cnt;

    reg [DATA_BITWIDTH-1:0] expected [0:KERNEL_ELEMS-1];

    /* ------------------------------------------------------------
     * DUT
     * ----------------------------------------------------------*/
    router_wght_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),
        .HAS_NORTH(1),
        .HAS_SOUTH(1),
        .HAS_WEST(1),
        .HAS_EAST(1)
    ) dut (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_read(glb_addr_read),
        .glb_req_read(glb_req_read),
        .glb_rdata(glb_rdata),

        .north_data_i(north_data_i),
        .north_enable_i(north_enable_i),
        .south_data_i(south_data_i),
        .south_enable_i(south_enable_i),
        .east_data_i(east_data_i),
        .east_enable_i(east_enable_i),
        .west_data_i(west_data_i),
        .west_enable_i(west_enable_i),

        .north_data_o(),
        .north_enable_o(),
        .south_data_o(),
        .south_enable_o(),
        .east_data_o(),
        .east_enable_o(),
        .west_data_o(),
        .west_enable_o(),

        .spad_data_o(spad_data_o),
        .spad_en_o(spad_en_o)
    );

    /* ------------------------------------------------------------
     * VCD
     * ----------------------------------------------------------*/
    initial begin
        $dumpfile("router_wght_generic_tb.vcd");
        $dumpvars(0, router_wght_generic_tb);
    end

    /* ------------------------------------------------------------
     * Zero-latency GLB model
     * ----------------------------------------------------------*/
    always @(*) begin
        if (glb_req_read)
            glb_rdata = expected[glb_cnt];
        else
            glb_rdata = '0;
    end

    /* ------------------------------------------------------------
     * Test sequence
     * ----------------------------------------------------------*/
    initial begin
        clk = 0;
        reset = 1;
        router_mode = 4'd0;

        west_data_i   = '0;
        west_enable_i = 1'b0;

        cycle    = 0;
        glb_cnt  = 0;
        spad_cnt = 0;

        /* Initialize kernel */
        begin : init_kernel
            integer i;
            for (i = 0; i < KERNEL_ELEMS; i = i + 1)
                expected[i] = 16'hA000 + i;
        end

        #20;
        reset = 0;
        $display("=== RESET DEASSERTED ===");

        /* --------------------------------------------------------
         * TEST 1: LOAD MODE (GLB → SPAD)
         * ------------------------------------------------------*/
        router_mode = 4'd1; // MODE_LOAD
        $display("=== TEST 1: WEIGHT LOAD MODE ===");

        while (spad_cnt < KERNEL_ELEMS) begin
            @(posedge clk);
            cycle = cycle + 1;

            if (glb_req_read) begin
                if (glb_addr_read !== (W_READ_ADDR + glb_cnt)) begin
                    $fatal(1,
                        "[LOAD][ERROR] GLB addr mismatch @cycle=%0d exp=%0h got=%0h",
                        cycle, W_READ_ADDR + glb_cnt, glb_addr_read);
                end
                glb_cnt = glb_cnt + 1;
            end

            if (spad_en_o) begin
                if (spad_data_o !== expected[spad_cnt]) begin
                    $fatal(1,
                        "[LOAD][ERROR] SPAD data mismatch idx=%0d exp=%0h got=%0h",
                        spad_cnt, expected[spad_cnt], spad_data_o);
                end
                spad_cnt = spad_cnt + 1;
            end

            if (spad_cnt > glb_cnt) begin
                $fatal(1, "[LOAD][ERROR] SPAD write without GLB request");
            end
        end

        $display("[PASS] Weight load completed successfully");

        /* --------------------------------------------------------
         * TEST 2: END-OF-LOAD QUIESCENCE
         * ------------------------------------------------------*/
        @(posedge clk);
        if (glb_req_read || spad_en_o) begin
            $fatal(1, "[ERROR] Activity detected after load completion");
        end
        $display("[PASS] Clean end-of-load behavior");

        /* --------------------------------------------------------
         * TEST 3: MODE TRANSITION RESET
         * ------------------------------------------------------*/
        router_mode = 4'd0; // IDLE
        @(posedge clk);
        router_mode = 4'd1; // LOAD again

        glb_cnt  = 0;
        spad_cnt = 0;

        @(posedge clk);
        if (glb_addr_read !== W_READ_ADDR) begin
            $fatal(1, "[ERROR] GLB address did not reset on mode change");
        end
        $display("[PASS] Mode change resets internal sequencing");

        /* --------------------------------------------------------
         * TEST 4: FORWARD MODE (NO GLB / NO SPAD)
         * ------------------------------------------------------*/
        router_mode = 4'd2; // MODE_FWD
        repeat (5) @(posedge clk);

        if (glb_req_read || spad_en_o) begin
            $fatal(1, "[ERROR] GLB/SPAD activity in FORWARD mode");
        end
        $display("[PASS] Forward mode is GLB/SPAD silent");

        $display("=== ALL TESTS PASSED ===");
        #20;
        $finish;
    end

endmodule

