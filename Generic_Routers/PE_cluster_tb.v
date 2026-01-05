`timescale 1ns / 1ps

module PE_cluster_2window_laplacian_tb;

    localparam DATA_BITWIDTH = 16;
    localparam X_dim = 3;
    localparam Y_dim = 3;
    localparam kernel_size = 3;
    localparam TOTAL_MACS = 9;

    reg clk, reset, start;

    reg signed [DATA_BITWIDTH-1:0] iact_data;
    reg                            iact_valid;

    reg signed [DATA_BITWIDTH-1:0] wght_data;
    reg                            wght_valid;

    wire signed [DATA_BITWIDTH*X_dim*Y_dim-1:0] psum_data;
    wire                                        psum_valid;

    integer i;

    // Laplacian kernel
    reg signed [DATA_BITWIDTH-1:0] kernel [0:8];
    initial begin
        kernel[0]=0;  kernel[1]=-1; kernel[2]=0;
        kernel[3]=-1; kernel[4]=4;  kernel[5]=-1;
        kernel[6]=0;  kernel[7]=-1; kernel[8]=0;
    end

    // Window activations
    reg signed [DATA_BITWIDTH-1:0] win0 [0:8];
    reg signed [DATA_BITWIDTH-1:0] win1 [0:8];

    initial begin
        // Window 0
        win0[0]=1; win0[1]=2; win0[2]=3;
        win0[3]=4; win0[4]=5; win0[5]=6;
        win0[6]=7; win0[7]=8; win0[8]=9;

        // Window 1
        win1[0]=2; win1[1]=3; win1[2]=4;
        win1[3]=5; win1[4]=6; win1[5]=7;
        win1[6]=8; win1[7]=9; win1[8]=10;
    end

    // DUT
    PE_cluster_new #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .X_dim(X_dim),
        .Y_dim(Y_dim),
        .kernel_size(kernel_size)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .iact_data_i(iact_data),
        .iact_valid_i(iact_valid),
        .wght_data_i(wght_data),
        .wght_valid_i(wght_valid),
        .psum_data_o(psum_data),
        .psum_valid_o(psum_valid)
    );

    // Clock
    always #5 clk = ~clk;

    task run_window;
        input integer win_id;
        input signed [DATA_BITWIDTH-1:0] expected;
        begin
            $display("\n=== RUN WINDOW %0d ===", win_id);

            start <= 1;
            @(posedge clk);
            start <= 0;

            @(posedge clk); // alignment gap

            for (i = 0; i < TOTAL_MACS; i = i + 1) begin
                @(posedge clk);
                iact_data  <= (win_id == 0) ? win0[i] : win1[i];
                wght_data  <= kernel[i];
                iact_valid <= 1;
                wght_valid <= 1;
            end

            @(posedge clk);
            iact_valid <= 0;
            wght_valid <= 0;

            wait (psum_valid);
            $display("[TB] PSUM = %0d EXPECTED = %0d",
                     psum_data[0 +: DATA_BITWIDTH], expected);

            if (psum_data[0 +: DATA_BITWIDTH] !== expected)
                $fatal(1, "❌ CONV MISMATCH");

            @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("PE_cluster_2window_laplacian_tb.vcd");
        $dumpvars(0, PE_cluster_2window_laplacian_tb);

        clk = 0;
        reset = 1;
        start = 0;
        iact_valid = 0;
        wght_valid = 0;
        iact_data = 0;
        wght_data = 0;

        repeat (3) @(posedge clk);
        reset = 0;

        // Expected:
        // win0 = 0*(1)+(-1*2)+0*(3)+(-1*4)+4*5+(-1*6)+0*(7)+(-1*8)+0*(9) = 0
        // win1 = same pattern on shifted window = 0

        run_window(0, 0);
        run_window(1, 0);

        $display("\n====================================");
        $display("✅ 2-WINDOW LAPLACIAN TEST PASSED");
        $display("====================================");

        #20;
        $finish;
    end

endmodule

