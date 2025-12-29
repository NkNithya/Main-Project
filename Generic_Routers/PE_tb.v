`timescale 1ns / 1ps

module PE_new_tb;

    // -------------------------------------------------
    // Parameters
    // -------------------------------------------------
    localparam DATA_BITWIDTH = 16;
    localparam ADDR_BITWIDTH = 9;

    localparam kernel_size = 3;
    localparam act_size    = 5;

    localparam W_READ_ADDR = 0;
    localparam A_READ_ADDR = 100;
    localparam W_LOAD_ADDR = 0;
    localparam A_LOAD_ADDR = 100;
    localparam PSUM_ADDR   = 500;

    // -------------------------------------------------
    // Signals
    // -------------------------------------------------
    reg clk;
    reg reset;

    reg  [DATA_BITWIDTH-1:0] act_in;
    reg  [DATA_BITWIDTH-1:0] filt_in;

    reg load_en_wght;
    reg load_en_act;
    reg start;

    wire [DATA_BITWIDTH-1:0] pe_out;
    wire compute_done;
    wire load_done;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------
    PE_new #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH(ADDR_BITWIDTH),
        .kernel_size(kernel_size),
        .act_size(act_size),
        .W_READ_ADDR(W_READ_ADDR),
        .A_READ_ADDR(A_READ_ADDR),
        .W_LOAD_ADDR(W_LOAD_ADDR),
        .A_LOAD_ADDR(A_LOAD_ADDR),
        .PSUM_ADDR(PSUM_ADDR)
    ) dut (
        .clk(clk),
        .reset(reset),
        .act_in(act_in),
        .filt_in(filt_in),
        .load_en_wght(load_en_wght),
        .load_en_act(load_en_act),
        .start(start),
        .pe_out(pe_out),
        .compute_done(compute_done),
        .load_done(load_done)
    );

    // -------------------------------------------------
    // Clock
    // -------------------------------------------------
    always #5 clk = ~clk;

    // -------------------------------------------------
    // Test vectors
    // -------------------------------------------------
    reg [DATA_BITWIDTH-1:0] weights [0:kernel_size-1];
    reg [DATA_BITWIDTH-1:0] acts    [0:kernel_size-1];

    reg [DATA_BITWIDTH-1:0] expected_last_mac;
    reg [DATA_BITWIDTH-1:0] psum_mem;

    integer i;

    // -------------------------------------------------
    // Direct SPAD access (legal for TB)
    // -------------------------------------------------
    wire [DATA_BITWIDTH-1:0] spad_psum =
        dut.spad.mem[PSUM_ADDR];

    // -------------------------------------------------
    // Tasks
    // -------------------------------------------------
    task load_weights;
    begin
        $display("=== LOADING WEIGHTS ===");
        load_en_wght = 1;
        for (i = 0; i < kernel_size*kernel_size; i = i + 1) begin
            filt_in = weights[i % kernel_size];
            @(posedge clk);
        end
        load_en_wght = 0;
        filt_in = 0;

        wait (load_done);
        @(posedge clk);
        $display("[TB] Weight load complete");
    end
    endtask

    task load_activations;
    begin
        $display("=== LOADING ACTIVATIONS ===");
        load_en_act = 1;
        for (i = 0; i < act_size*act_size; i = i + 1) begin
            act_in = acts[i % kernel_size];
            @(posedge clk);
        end
        load_en_act = 0;
        act_in = 0;

        wait (load_done);
        @(posedge clk);
        $display("[TB] Activation load complete");
    end
    endtask

    // -------------------------------------------------
    // Test sequence
    // -------------------------------------------------
    initial begin
        $dumpfile("pe_new_tb.vcd");
        $dumpvars(0, PE_new_tb);

        // Init
        clk = 0;
        reset = 1;
        act_in = 0;
        filt_in = 0;
        load_en_wght = 0;
        load_en_act = 0;
        start = 0;

        // Define vectors
        weights[0] = 1;
        weights[1] = 2;
        weights[2] = 3;

        acts[0] = 1;
        acts[1] = 2;
        acts[2] = 3;

        // Modified PE produces ONLY last MAC
        expected_last_mac = acts[0]*weights[0] + acts[1]*weights[1] + acts[2]*weights[2];  // 3 * 3 = 9

        // Reset
        repeat (4) @(posedge clk);
        reset = 0;
        $display("=== RESET DEASSERTED ===");

        // Load
        load_weights();
        load_activations();

        // -------------------------------------------------
        // START COMPUTE
        // -------------------------------------------------
        $display("=== START COMPUTE ===");
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Wait for compute_done
        wait (compute_done);
        $display("[TB] compute_done asserted");

        // Allow PSUM write-back to settle
        repeat (2) @(posedge clk);

        // -------------------------------------------------
        // CHECK RESULT
        // -------------------------------------------------
        psum_mem = spad_psum;

        $display("PE_OUT (last MAC) = %0d", pe_out);
        $display("PSUM_MEM         = %0d", psum_mem);
        $display("EXPECTED         = %0d", expected_last_mac);

        if (psum_mem !== expected_last_mac) begin
            $display("❌ FAIL: PSUM mismatch");
            $fatal;
        end else begin
            $display("✅ PASS: Modified PE verified");
        end

        #20;
        $finish;
    end

endmodule

