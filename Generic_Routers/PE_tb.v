`timescale 1ns / 1ps

module PE_new_tb;

    // -------------------------------------------------
    // Parameters
    // -------------------------------------------------
    localparam DATA_BITWIDTH = 16;
    localparam kernel_size  = 3;
    localparam TOTAL_MACS   = kernel_size * kernel_size;

    // -------------------------------------------------
    // Signals
    // -------------------------------------------------
    reg clk;
    reg reset;
    reg start;

    reg  [DATA_BITWIDTH-1:0] iact_data_i;
    reg                      iact_valid_i;

    reg  [DATA_BITWIDTH-1:0] wght_data_i;
    reg                      wght_valid_i;

    wire [DATA_BITWIDTH-1:0] psum_data_o;
    wire                     psum_valid_o;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------
    PE_new #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .kernel_size(kernel_size)
    ) dut (
        .clk(clk),
        .reset(reset),
        .iact_data_i(iact_data_i),
        .iact_valid_i(iact_valid_i),
        .wght_data_i(wght_data_i),
        .wght_valid_i(wght_valid_i),
        .start(start),
        .psum_data_o(psum_data_o),
        .psum_valid_o(psum_valid_o)
    );

    // -------------------------------------------------
    // Clock (10 ns period)
    // -------------------------------------------------
    always #5 clk = ~clk;

    integer i;
    integer timeout;
    reg [DATA_BITWIDTH-1:0] expected_sum;

    // -------------------------------------------------
    // Test sequence
    // -------------------------------------------------
    initial begin
        // ---------------- VCD ----------------
        $dumpfile("PE_new_tb.vcd");
        $dumpvars(0, PE_new_tb);

        // ---------------- Init ----------------
        clk = 0;
        reset = 1;
        start = 0;
        iact_data_i  = 0;
        iact_valid_i = 0;
        wght_data_i  = 0;
        wght_valid_i = 0;
        expected_sum = 0;

        // ---------------- Reset ----------------
        #20;
        reset = 0;
        $display("[TB] Reset deasserted");

        // ---------------- Start pulse (1 cycle) ----------------
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;

        // ---------------- Guard cycles (router-accurate) ----------------
        @(negedge clk);
        @(negedge clk);

        // ---------------- Feed MAC data ----------------
        for (i = 0; i < TOTAL_MACS; i = i + 1) begin
            @(negedge clk);
            iact_data_i  = i + 1;   // 1..9
            wght_data_i  = 1;
            iact_valid_i = 1;
            wght_valid_i = 1;
            expected_sum = expected_sum + (i + 1);
        end

        // Deassert valids
        @(negedge clk);
        iact_valid_i = 0;
        wght_valid_i = 0;

        // ---------------- Timeout-protected wait ----------------
        timeout = 0;
        while (!psum_valid_o) begin
            @(posedge clk);
            timeout = timeout + 1;
            if (timeout > 50) begin
                $fatal(1, "[TB] TIMEOUT: psum_valid_o never asserted");
            end
        end

        // ---------------- Check result ----------------
        $display("[TB] PSUM valid asserted");
        $display("[TB] PSUM_OUT = %0d", psum_data_o);
        $display("[TB] EXPECTED = %0d", expected_sum);

        if (psum_data_o !== expected_sum)
            $fatal(1, "[TB] FAIL: result mismatch");
        else
            $display("✅ PASS: PE_new computation correct");

        #20;
        $finish;
    end

endmodule

