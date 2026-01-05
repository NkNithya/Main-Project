`timescale 1ns / 1ps

module PE_cluster_diff_window_tb;

    localparam DATA_BITWIDTH = 16;
    localparam ADDR_BITWIDTH = 9;
    localparam X_dim = 3;
    localparam Y_dim = 3;
    localparam kernel_size = 3;
    localparam act_size = 5;

    reg clk, reset;
    reg start;
    reg load_en_act, load_en_wght;
    reg [DATA_BITWIDTH-1:0] act_in, filt_in;

    wire [DATA_BITWIDTH*X_dim-1:0] pe_out;
    wire compute_done, load_done;

    // ---------------- DUT ----------------
    PE_cluster_new #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH(ADDR_BITWIDTH),
        .X_dim(X_dim),
        .Y_dim(Y_dim),
        .kernel_size(kernel_size),
        .act_size(act_size),
        .A_READ_ADDR(100),
        .W_READ_ADDR(0),
        .A_LOAD_ADDR(100),
        .W_LOAD_ADDR(0),
        .PSUM_ADDR(500)
    ) dut (
        .clk(clk),
        .reset(reset),
        .act_in(act_in),
        .filt_in(filt_in),
        .pe_before(0),
        .load_en_wght(load_en_wght),
        .load_en_act(load_en_act),
        .start(start),
        .pe_out(pe_out),
        .compute_done(compute_done),
        .load_done(load_done)
    );

    // ---------------- Clock ----------------
    always #5 clk = ~clk;

    integer i;

    // ---------------- Test ----------------
    initial begin
        $dumpfile("PE_cluster_diff_window_tb.vcd");
        $dumpvars(0, PE_cluster_diff_window_tb);

        clk = 0;
        reset = 1;
        start = 0;
        load_en_act = 0;
        load_en_wght = 0;
        act_in = 0;
        filt_in = 0;

        repeat (3) @(posedge clk);
        reset = 0;
        $display("[TB] Reset deasserted");

        // ---------------- Load weights (all 1s) ----------------
        load_en_wght = 1;
        for (i = 0; i < kernel_size*kernel_size; i = i + 1) begin
            filt_in = 16'd1;
            @(posedge clk);
        end
        load_en_wght = 0;
        wait (load_done);

        // ---------------- Load activations (NON-LINEAR!) ----------------
        load_en_act = 1;

        // Row 0
        act_in = 1;   @(posedge clk);
        act_in = 2;   @(posedge clk);
        act_in = 3;   @(posedge clk);
        act_in = 4;   @(posedge clk);
        act_in = 5;   @(posedge clk);

        // Row 1
        act_in = 10;  @(posedge clk);
        act_in = 20;  @(posedge clk);
        act_in = 30;  @(posedge clk);
        act_in = 40;  @(posedge clk);
        act_in = 50;  @(posedge clk);

        // Row 2
        act_in = 100; @(posedge clk);
        act_in = 200; @(posedge clk);
        act_in = 300; @(posedge clk);
        act_in = 400; @(posedge clk);
        act_in = 500; @(posedge clk);

        // Row 3
        act_in = 7;   @(posedge clk);
        act_in = 8;   @(posedge clk);
        act_in = 9;   @(posedge clk);
        act_in = 10;  @(posedge clk);
        act_in = 11;  @(posedge clk);

        // Row 4
        act_in = 0;   @(posedge clk);
        act_in = 1;   @(posedge clk);
        act_in = 2;   @(posedge clk);
        act_in = 3;   @(posedge clk);
        act_in = 4;   @(posedge clk);

        load_en_act = 0;
        wait (load_done);

        // ---------------- Start compute ----------------
        start = 1;
        @(posedge clk);
        start = 0;

        wait (compute_done);

        // ---------------- Observe outputs ----------------
        $display("====================================");
        for (i = 0; i < X_dim; i = i + 1) begin
            $display("PE[%0d] output = %0d",
                i,
                pe_out[i*DATA_BITWIDTH +: DATA_BITWIDTH]);
        end
        $display("====================================");

        #20;
        $finish;
    end

endmodule

