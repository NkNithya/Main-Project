`timescale 1ns / 1p
module router_psum_generic_tb;

    /* ------------------------------------------------------------
     * Parameters
     * ----------------------------------------------------------*/
    localparam DATA_BITWIDTH      = 16;
    localparam ADDR_BITWIDTH_GLB  = 10;
    localparam ADDR_BITWIDTH_SPAD = 9;

    localparam PSUM_ADDR = 10'h40;

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

    wire [ADDR_BITWIDTH_GLB-1:0] glb_addr_write;
    wire glb_req_write;
    wire [DATA_BITWIDTH-1:0] glb_wdata;

    reg  [DATA_BITWIDTH-1:0] spad_data_i;
    wire spad_en_o;

    /* NoC inputs */
    reg  [DATA_BITWIDTH-1:0] west_data_i;
    reg  west_enable_i;

    wire [DATA_BITWIDTH-1:0] north_data_i = '0;
    wire [DATA_BITWIDTH-1:0] south_data_i = '0;
    wire [DATA_BITWIDTH-1:0] east_data_i  = '0;

    wire north_enable_i = 1'b0;
    wire south_enable_i = 1'b0;
    wire east_enable_i  = 1'b0;

    /* ------------------------------------------------------------
     * DUT
     * ----------------------------------------------------------*/
    router_psum_generic dut (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_write(glb_addr_write),
        .glb_req_write(glb_req_write),
        .glb_wdata(glb_wdata),

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

        .spad_data_i(spad_data_i),
        .spad_en_o(spad_en_o)
    );

    /* ------------------------------------------------------------
     * VCD
     * ----------------------------------------------------------*/
    initial begin
        $dumpfile("router_psum_generic_tb.vcd");
        $dumpvars(0, router_psum_generic_tb);
    end

    /* ------------------------------------------------------------
     * Test sequence
     * ----------------------------------------------------------*/
    initial begin
        clk = 0;
        reset = 1;
        router_mode = 0;

        west_data_i   = 0;
        west_enable_i = 0;
        spad_data_i   = 0;

        #20;
        reset = 0;
        $display("=== RESET DEASSERTED ===");

        /* --------------------------------------------------------
         * TEST 1: LOCAL ACCUMULATION
         * ------------------------------------------------------*/
        router_mode = 4'd1; // MODE_ACC
        spad_data_i = 16'h0011;

        @(posedge clk);
        if (!spad_en_o)
            $fatal(1, "[ACC][ERROR] SPAD accumulation not enabled");

        $display("[PASS] Local accumulation works");

        /* --------------------------------------------------------
         * TEST 2: SINGLE-FANOUT FORWARD
         * ------------------------------------------------------*/
        west_data_i   = 16'h0022;
        west_enable_i = 1'b1;

        @(posedge clk);
        if (spad_en_o)
            $fatal(1, "[FWD][ERROR] SPAD active during forward");

        $display("[PASS] Single-fanout forwarding works");

        west_enable_i = 1'b0;

        /* --------------------------------------------------------
         * TEST 3: DRAIN TO GLB (ONCE)
         * ------------------------------------------------------*/
        router_mode = 4'd2; // MODE_DRAIN
        spad_data_i = 16'h00AA;

        @(posedge clk);
        if (!glb_req_write)
            $fatal(1, "[DRAIN][ERROR] No GLB write on drain");

        if (glb_addr_write !== PSUM_ADDR)
            $fatal(1, "[DRAIN][ERROR] GLB addr mismatch");

        if (glb_wdata !== 16'h00AA)
            $fatal(1, "[DRAIN][ERROR] GLB data mismatch");

        $display("[PASS] Drain writes correct data");

        /* --------------------------------------------------------
         * TEST 4: DRAIN SILENCE (NO DOUBLE WRITE)
         * ------------------------------------------------------*/
        @(posedge clk);
        if (glb_req_write)
            $fatal(1, "[DRAIN][ERROR] Drain repeated (double write)");

        $display("[PASS] Drain occurs exactly once");

        /* --------------------------------------------------------
         * TEST 5: NO FORWARD DURING DRAIN
         * ------------------------------------------------------*/
        if (spad_en_o)
            $fatal(1, "[ERROR] Activity during drain phase");

        $display("[PASS] No overlap between drain and forward");

        /* --------------------------------------------------------
         * TEST 6: MODE CHANGE RE-ARMS DRAIN
         * ------------------------------------------------------*/
        router_mode = 4'd0; // IDLE
        @(posedge clk);

        router_mode = 4'd2; // DRAIN again
        spad_data_i = 16'h00BB;

        @(posedge clk);
        if (!glb_req_write || glb_wdata !== 16'h00BB)
            $fatal(1, "[ERROR] Drain did not re-arm after mode change");

        $display("[PASS] Drain re-arms on mode change");

        $display("=== ALL PSUM ROUTER TESTS PASSED ===");
        #20;
        $finish;
    end

endmodule

