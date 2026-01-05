`timescale 1ns / 1ps

module router_cluster_wpsum_tb;

    localparam DATA_BITWIDTH     = 16;
    localparam ADDR_BITWIDTH_GLB = 10;
    localparam kernel_size       = 3;
    localparam TOTAL_MACS        = 9;
    localparam EXPECTED_PSUM     = 45; // 1+2+...+9

    localparam MODE_IDLE  = 0;
    localparam MODE_LOAD  = 1;
    localparam MODE_LOCAL = 2;
    localparam MODE_DRAIN = 3;

    reg clk = 0;
    always #5 clk = ~clk;

    reg reset;
    reg [3:0] router_mode;

    wire [ADDR_BITWIDTH_GLB-1:0] iact_glb_addr, wght_glb_addr;
    wire iact_glb_req, wght_glb_req;
    reg  [DATA_BITWIDTH-1:0] iact_glb_rdata, wght_glb_rdata;

    wire [ADDR_BITWIDTH_GLB-1:0] psum_glb_addr;
    wire psum_glb_en;
    wire [DATA_BITWIDTH-1:0] psum_glb_data;

    reg [DATA_BITWIDTH-1:0] iact_mem [0:31];
    reg [DATA_BITWIDTH-1:0] wght_mem [0:31];

    integer i;

    // Init memories
    initial begin
        for (i = 0; i < TOTAL_MACS; i = i + 1) begin
            iact_mem[i] = i + 1;
            wght_mem[i] = 1;
        end
    end

    // GLB read (1-cycle latency)
    always @(posedge clk)
        if (iact_glb_req)
            iact_glb_rdata <= iact_mem[iact_glb_addr];

    always @(posedge clk)
        if (wght_glb_req)
            wght_glb_rdata <= wght_mem[wght_glb_addr];

    router_cluster_wpsum dut (
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

    initial begin
        $dumpfile("router_cluster_wpsum_tb.vcd");
        $dumpvars(0, router_cluster_wpsum_tb);

        reset = 1;
        router_mode = MODE_IDLE;
        repeat (3) @(posedge clk);
        reset = 0;

        // LOAD
        router_mode = MODE_LOAD;
        repeat (TOTAL_MACS + 3) @(posedge clk);

        // COMPUTE
        router_mode = MODE_LOCAL;
        repeat (TOTAL_MACS + 2) @(posedge clk);

        // DRAIN
        router_mode = MODE_DRAIN;
        wait (psum_glb_en);

        $display("PSUM = %0d", psum_glb_data);
        if (psum_glb_data !== EXPECTED_PSUM)
            $fatal(1, "PSUM mismatch");

        $display("✅ router_cluster_wpsum TB PASSED");
        $finish;
    end

endmodule

