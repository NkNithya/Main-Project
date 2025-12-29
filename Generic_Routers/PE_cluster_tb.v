`timescale 1ns / 1ps

module PE_cluster_new_tb;

    // -------------------------------------------------
    // Parameters
    // -------------------------------------------------
    localparam DATA_BITWIDTH = 16;
    localparam ADDR_BITWIDTH = 9;

    localparam X_dim = 3;
    localparam kernel_size = 3;
    localparam act_size    = 5;

    localparam W_READ_ADDR = 0;
    localparam A_READ_ADDR = 100;
    localparam W_LOAD_ADDR = 0;
    localparam A_LOAD_ADDR = 100;

    // -------------------------------------------------
    // Signals
    // -------------------------------------------------
    reg clk, reset;
    reg start;

    reg load_en_wght, load_en_act;
    reg [DATA_BITWIDTH-1:0] act_in, filt_in;

    reg [DATA_BITWIDTH*X_dim-1:0] pe_before;

    wire [DATA_BITWIDTH*X_dim-1:0] pe_out;
    wire compute_done;
    wire load_done;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------
    PE_cluster_new #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH(ADDR_BITWIDTH),
        .X_dim(X_dim),
        .kernel_size(kernel_size),
        .act_size(act_size),
        .W_READ_ADDR(W_READ_ADDR),
        .A_READ_ADDR(A_READ_ADDR),
        .W_LOAD_ADDR(W_LOAD_ADDR),
        .A_LOAD_ADDR(A_LOAD_ADDR)
    ) dut (
        .clk(clk),
        .reset(reset),
        .act_in(act_in),
        .filt_in(filt_in),
        .pe_before(pe_before),
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

    integer i;

    // -------------------------------------------------
    // Tasks
    // -------------------------------------------------
    task load_weights;
    begin
        load_en_wght = 1;
        for (i = 0; i < kernel_size*kernel_size; i = i + 1) begin
            filt_in = i + 1; // 1..9
            @(posedge clk);
        end
        load_en_wght = 0;
        filt_in = 0;
        wait(load_done);
        @(posedge clk);
    end
    endtask

    task load_activations;
    begin
        load_en_act = 1;
        for (i = 0; i < act_size*act_size; i = i + 1) begin
            act_in = i + 1; // 1..25
            @(posedge clk);
        end
        load_en_act = 0;
        act_in = 0;
        wait(load_done);
        @(posedge clk);
    end
    endtask

    // -------------------------------------------------
    // Test sequence
    // -------------------------------------------------
    initial begin
        $dumpfile("PE_cluster_new_tb.vcd");
        $dumpvars(0, PE_cluster_new_tb);

        // Init
        clk = 0;
        reset = 1;
        start = 0;
        load_en_wght = 0;
        load_en_act = 0;
        act_in = 0;
        filt_in = 0;
        pe_before = 0;

        // Reset
        repeat (4) @(posedge clk);
        reset = 0;
        $display("=== RESET DEASSERTED ===");

        // Load data
        load_weights();
        load_activations();

        // -------------------------------------------------
        // Start cluster compute
        // -------------------------------------------------
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait (compute_done);
        @(posedge clk);

        // -------------------------------------------------
        // Check result (manual expected)
        // -------------------------------------------------
        // For ky accumulation:
        // Each PE computes kernel_size MACs
        // weights: {1,2,3}, activations vary by column
        //
        // Column 0 activations: {1,2,3}
        // Column 1 activations: {2,3,4}
        // Column 2 activations: {3,4,5}
        //
        // PE_new calc per start:
        // col0 = 1*1 + 2*2 + 3*3 = 14
        // col1 = 1*2 + 2*3 + 3*4 = 20
        // col2 = 1*3 + 2*4 + 3*5 = 26

        if (pe_out[DATA_BITWIDTH-1:0] !== 14) begin
            $display("❌ FAIL col0 exp=14 got=%0d",
                     pe_out[DATA_BITWIDTH-1:0]);
            $fatal;
        end

        if (pe_out[2*DATA_BITWIDTH-1:DATA_BITWIDTH] !== 20) begin
            $display("❌ FAIL col1 exp=20 got=%0d",
                     pe_out[2*DATA_BITWIDTH-1:DATA_BITWIDTH]);
            $fatal;
        end

        if (pe_out[3*DATA_BITWIDTH-1:2*DATA_BITWIDTH] !== 26) begin
            $display("❌ FAIL col2 exp=26 got=%0d",
                     pe_out[3*DATA_BITWIDTH-1:2*DATA_BITWIDTH]);
            $fatal;
        end

        $display("✅ PASS: PE_cluster_new correct (CNN control at cluster)");
        #20;
        $finish;
    end

endmodule

