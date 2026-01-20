`timescale 1ns / 1ps

module tb_ECG;

    localparam IN_BITWIDTH = 16;

    reg  [IN_BITWIDTH-1:0] a_in;
    reg  [IN_BITWIDTH-1:0] w_in;
    reg  [IN_BITWIDTH-1:0] sum_in;
    reg                    en;
    reg                    clk;
    reg                    reset;
    wire                   gated_clk;

    // --------------------------------------------------
    // DUT
    // --------------------------------------------------
    ECG #(
        .IN_BITWIDTH(IN_BITWIDTH)
    ) dut (
        .a_in      (a_in),
        .w_in      (w_in),
        .sum_in    (sum_in),
        .en        (en),
        .clk       (clk),
        .reset     (reset),
        .gated_clk (gated_clk)
    );

    // --------------------------------------------------
    // Clock generation
    // --------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // --------------------------------------------------
    // VCD DUMP (THIS IS WHAT CREATES THE FILE)
    // --------------------------------------------------
    initial begin
        $dumpfile("ecg_wave.vcd");   // VCD file name
        $dumpvars(0, tb_ECG);        // dump entire TB + DUT
    end

    // --------------------------------------------------
    // Stimulus
    // --------------------------------------------------
    initial begin
        // Initialize
        reset  = 1;
        en     = 0;
        a_in   = 0;
        w_in   = 0;
        sum_in = 0;

        #20;
        reset = 0;

        // enable = 0 → clock gated
        #20;
        a_in = 16'h0001;

        // enable = 1 → clock allowed
        #20;
        en = 1;

        #20;
        a_in = 16'h0002;

        #40;
        w_in = 16'h00FF;

        #40;
        en = 0;

        #40;
        $display("Simulation finished, VCD generated");
        $finish;
    end

endmodule

