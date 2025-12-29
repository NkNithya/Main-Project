`timescale 1ns/1ps

module PE_cluster_new_diag_tb_fixed;

    parameter DATA_BITWIDTH = 16;
    parameter X_dim = 5;

    reg clk, reset, start;
    reg [DATA_BITWIDTH-1:0] act_in;
    reg [DATA_BITWIDTH-1:0] filt_in;
    reg load_en_act, load_en_wght;

    wire [DATA_BITWIDTH*X_dim-1:0] pe_out;
    wire compute_done;

    integer cycle;

    initial clk = 0;
    always #5 clk = ~clk;

    always @(posedge clk)
        cycle <= cycle + 1;

    PE_cluster_new dut (
        .clk(clk),
        .reset(reset),

        .act_in(act_in),
        .filt_in(filt_in),
        .load_en_act(load_en_act),
        .load_en_wght(load_en_wght),

        .start(start),
        .pe_out(pe_out),
        .compute_done(compute_done)
    );

    initial begin
        $dumpfile("pe_diag_fixed.vcd");
        $dumpvars(0, PE_cluster_new_diag_tb_fixed);

        cycle = 0;
        reset = 1;
        start = 0;
        load_en_act = 0;
        load_en_wght = 0;
        act_in = 0;
        filt_in = 0;

        repeat (5) @(posedge clk);
        reset = 0;

        // LOAD activation
        act_in = 16'd3;
        load_en_act = 1;
        @(posedge clk);
        load_en_act = 0;

        // LOAD weight
        filt_in = 16'd4;
        load_en_wght = 1;
        @(posedge clk);
        load_en_wght = 0;

        // HOLD start high (important)
        start = 1;

        // Timeout-protected wait
        while (!compute_done && cycle < 200) begin
            @(posedge clk);
        end

        if (!compute_done) begin
            $display("❌ TIMEOUT: compute_done never asserted");
            $finish;
        end

        $display("✅ compute_done asserted at cycle %0d", cycle);
        $display("PE_OUT = %h", pe_out);

        $finish;
    end

endmodule

