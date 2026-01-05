`timescale 1ns / 1ps

module router_cluster_wpsum_tb;

    // -------------------------------------------------
    // Parameters
    // -------------------------------------------------
    localparam DATA_BITWIDTH     = 16;
    localparam ADDR_BITWIDTH_GLB = 10;

    localparam X_dim        = 3;
    localparam Y_dim        = 3;
    localparam kernel_size = 3;

    localparam TOTAL_MACS = kernel_size * kernel_size;
    localparam EXPECTED_PSUM = 45;

    // Router modes
    localparam MODE_IDLE  = 4'd0;
    localparam MODE_LOAD  = 4'd1;
    localparam MODE_LOCAL = 4'd2;
    localparam MODE_DRAIN = 4'd3;

    // -------------------------------------------------
    // Signals
    // -------------------------------------------------
    reg clk;
    reg reset;
    reg [3:0] router_mode;

    // ---- GLB activation ----
    wire [ADDR_BITWIDTH_GLB-1:0] iact_glb_addr;
    wire                         iact_glb_req;
    reg  [DATA_BITWIDTH-1:0]     iact_glb_rdata;

    // ---- GLB weight ----
    wire [ADDR_BITWIDTH_GLB-1:0] wght_glb_addr;
    wire                         wght_glb_req;
    reg  [DATA_BITWIDTH-1:0]     wght_glb_rdata;

    // ---- GLB psum ----
    wire [ADDR_BITWIDTH_GLB-1:0] psum_glb_addr;
    wire                         psum_glb_en;
    wire [DATA_BITWIDTH-1:0]     psum_glb_data;

    // -------------------------------------------------
    // GLB memories (INITIALIZED!)
    // -------------------------------------------------
    reg [DATA_BITWIDTH-1:0] iact_mem [0:1023];
    reg [DATA_BITWIDTH-1:0] wght_mem [0:1023];

    integer i;

    initial begin
        // clear memories to avoid X
        for (i = 0; i < 1024; i = i + 1) begin
            iact_mem[i] = 0;
            wght_mem[i] = 0;
        end

        // activations: 1..9
        for (i = 0; i < TOTAL_MACS; i = i + 1)
            iact_mem[i] = i + 1;

        // weights: all 1
        for (i = 0; i < TOTAL_MACS; i = i + 1)
            wght_mem[i] = 16'd1;
    end

    // -------------------------------------------------
    // GLB synchronous read (1-cycle latency)
    // -------------------------------------------------
    always @(posedge clk) begin
        if (iact_glb_req)
            iact_glb_rdata <= iact_mem[iact_glb_addr];
    end

    always @(posedge clk) begin
        if (wght_glb_req)
            wght_glb_rdata <= wght_mem[wght_glb_addr];
    end

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------
    router_cluster_wpsum #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .X_dim(X_dim),
        .Y_dim(Y_dim),
        .kernel_size(kernel_size),
        .A_READ_ADDR(0),
        .W_READ_ADDR(0),
        .PSUM_GLB_BASE_ADDR(0)
    ) dut (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .iact_glb_addr (iact_glb_addr),
        .iact_glb_req  (iact_glb_req),
        .iact_glb_rdata(iact_glb_rdata),

        .wght_glb_addr (wght_glb_addr),
        .wght_glb_req  (wght_glb_req),
        .wght_glb_rdata(wght_glb_rdata),

        .psum_glb_addr (psum_glb_addr),
        .psum_glb_en   (psum_glb_en),
        .psum_glb_data (psum_glb_data)
    );

    // -------------------------------------------------
    // Clock
    // -------------------------------------------------
    always #5 clk = ~clk;

    // -------------------------------------------------
    // Test sequence
    // -------------------------------------------------
    initial begin
        $dumpfile("router_cluster_wpsum_tb.vcd");
        $dumpvars(0, router_cluster_wpsum_tb);

        clk = 0;
        reset = 1;
        router_mode = MODE_IDLE;

        // reset
        repeat (3) @(posedge clk);
        reset = 0;
        $display("[TB] Reset deasserted");

        // DEAD CYCLE (CRITICAL)
        @(posedge clk);

        // ---------------------------------------------
        // LOAD phase (activations + weights)
        // ---------------------------------------------
        router_mode = MODE_LOAD;
        $display("[TB] MODE_LOAD");

        repeat (TOTAL_MACS + 4) @(posedge clk);

        // ---------------------------------------------
        // COMPUTE phase
        // ---------------------------------------------
        router_mode = MODE_LOCAL;
        $display("[TB] MODE_LOCAL");

        // allow compute to finish
        repeat (TOTAL_MACS + 6) @(posedge clk);

        // ---------------------------------------------
        // DRAIN phase
        // ---------------------------------------------
        router_mode = MODE_DRAIN;
        $display("[TB] MODE_DRAIN");

        wait (psum_glb_en);

        $display("[TB] PSUM drained = %0d", psum_glb_data);

        if (psum_glb_data !== EXPECTED_PSUM) begin
            $display("[ERROR] PSUM mismatch: got %0d expected %0d",
                     psum_glb_data, EXPECTED_PSUM);
            $fatal;
        end

        $display("======================================");
        $display("✅ router_cluster_wpsum TB PASSED");
        $display("======================================");

        #20;
        $finish;
    end

endmodule

