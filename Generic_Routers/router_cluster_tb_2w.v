`timescale 1ns / 1ps

module router_cluster_wpsum_tb;

    localparam DATA_BITWIDTH     = 16;
    localparam ADDR_BITWIDTH_GLB = 10;
    localparam kernel_size       = 3;
    localparam TOTAL_MACS        = kernel_size * kernel_size;

    localparam MODE_IDLE  = 4'd0;
    localparam MODE_LOAD  = 4'd1;
    localparam MODE_LOCAL = 4'd2;
    localparam MODE_DRAIN = 4'd3;

    reg clk, reset;
    reg [3:0] router_mode;

    wire [ADDR_BITWIDTH_GLB-1:0] iact_glb_addr;
    wire                         iact_glb_req;
    reg  [DATA_BITWIDTH-1:0]     iact_glb_rdata;

    wire [ADDR_BITWIDTH_GLB-1:0] wght_glb_addr;
    wire                         wght_glb_req;
    reg  [DATA_BITWIDTH-1:0]     wght_glb_rdata;

    wire [ADDR_BITWIDTH_GLB-1:0] psum_glb_addr;
    wire                         psum_glb_en;
    wire [DATA_BITWIDTH-1:0]     psum_glb_data;

    integer timeout;

    // Clock
    always #5 clk = ~clk;

    // Mock GLB reads (1-cycle latency, defined)
    always @(posedge clk) begin
        if (reset) begin
            iact_glb_rdata <= 0;
            wght_glb_rdata <= 0;
        end else begin
            iact_glb_rdata <= iact_glb_req ? iact_glb_addr + 1 : 0;
            wght_glb_rdata <= wght_glb_req ? 16'd1 : 0;
        end
    end

    // DUT
    router_cluster_wpsum #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
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

    // Test
    initial begin
        $dumpfile("router_cluster_wpsum_tb.vcd");
        $dumpvars(0, router_cluster_wpsum_tb);

        clk = 0;
        reset = 1;
        router_mode = MODE_IDLE;

        repeat (3) @(posedge clk);
        reset = 0;
        @(posedge clk);

        // LOAD
        router_mode = MODE_LOAD;
        repeat (TOTAL_MACS + 3) @(posedge clk);

        // COMPUTE
        router_mode = MODE_LOCAL;
        repeat (TOTAL_MACS + 3) @(posedge clk);

        // Flush
        @(posedge clk);

        // DRAIN
        router_mode = MODE_DRAIN;

        timeout = 0;
        while (!psum_glb_en) begin
            @(posedge clk);
            timeout++;
            if (timeout > 100)
                $fatal(1, "[TIMEOUT] psum_glb_en never asserted");
        end

        $display("[TB] PSUM = %0d", psum_glb_data);

        if (psum_glb_data !== 45)
            $fatal(1, "[FAIL] Expected PSUM = 45");

        $display("✅ router_cluster_wpsum TB PASSED");
        $finish;
    end

endmodule

