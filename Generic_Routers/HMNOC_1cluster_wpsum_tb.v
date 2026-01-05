`timescale 1ns / 1ps

module HMNOC_1cluster_wpsum_tb;

    localparam DATA_BITWIDTH     = 16;
    localparam ADDR_BITWIDTH_GLB = 10;
    localparam kernel_size       = 3;
    localparam TOTAL_MACS        = 9;

    localparam MODE_IDLE  = 4'd0;
    localparam MODE_LOAD  = 4'd1;
    localparam MODE_LOCAL = 4'd2;
    localparam MODE_DRAIN = 4'd3;

    reg clk = 0;
    always #5 clk = ~clk;

    reg reset;
    reg [3:0] router_mode;

    // ---- GLB write ports ----
    reg iact_glb_we;
    reg [ADDR_BITWIDTH_GLB-1:0] iact_glb_waddr;
    reg [DATA_BITWIDTH-1:0]     iact_glb_wdata;

    reg wght_glb_we;
    reg [ADDR_BITWIDTH_GLB-1:0] wght_glb_waddr;
    reg [DATA_BITWIDTH-1:0]     wght_glb_wdata;

    integer i;

    // ==================================================
    // DUT
    // ==================================================
    HMNOC_1cluster_wpsum dut (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .iact_glb_we(iact_glb_we),
        .iact_glb_waddr(iact_glb_waddr),
        .iact_glb_wdata(iact_glb_wdata),

        .wght_glb_we(wght_glb_we),
        .wght_glb_waddr(wght_glb_waddr),
        .wght_glb_wdata(wght_glb_wdata)
    );

    // ==================================================
    // TEST SEQUENCE
    // ==================================================
    initial begin
        $dumpfile("HMNOC_1cluster_wpsum_tb.vcd");
        $dumpvars(0, HMNOC_1cluster_wpsum_tb);

        reset = 1;
        router_mode = MODE_IDLE;

        iact_glb_we = 0;
        wght_glb_we = 0;

        repeat (3) @(posedge clk);
        reset = 0;

        // ==================================================
        // PHASE 1: LOAD GLBs
        // ==================================================
        $display("[TB] Loading Activation GLB");
        for (i = 0; i < TOTAL_MACS; i = i + 1) begin
            iact_glb_we    = 1;
            iact_glb_waddr = i;
            iact_glb_wdata = i + 1; // 1..9
            @(posedge clk);
        end
        iact_glb_we = 0;

        $display("[TB] Loading Weight GLB");
        for (i = 0; i < TOTAL_MACS; i = i + 1) begin
            wght_glb_we    = 1;
            wght_glb_waddr = i;
            wght_glb_wdata = 16'd1;
            @(posedge clk);
        end
        wght_glb_we = 0;

        // dead cycle (important for GLB read alignment)
        @(posedge clk);

        // ==================================================
        // PHASE 2: COMPUTE
        // ==================================================
        $display("[TB] MODE_LOAD");
        router_mode = MODE_LOAD;
        repeat (TOTAL_MACS + 4) @(posedge clk);

        $display("[TB] MODE_LOCAL");
        router_mode = MODE_LOCAL;
        repeat (TOTAL_MACS + 6) @(posedge clk);

        // ==================================================
        // PHASE 3: DRAIN
        // ==================================================
        $display("[TB] MODE_DRAIN");
        router_mode = MODE_DRAIN;

        wait (dut.u_glb_psum.write_en);
		repeat(2) @(posedge clk);
        $display("[TB] PSUM RESULT = %0d", dut.u_glb_psum.mem[0]);

        if (dut.u_glb_psum.mem[0] !== 45) begin
            $display("[TB][ERROR] PSUM mismatch exp=45 got=%0d",
                     dut.u_glb_psum.mem[0]);
            $fatal(1);
        end

        $display("======================================");
        $display("✅ HMNOC FULL SYSTEM TEST PASSED");
        $display("======================================");

        #20;
        $finish;
    end

endmodule

