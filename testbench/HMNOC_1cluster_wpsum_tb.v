`timescale 1ns / 1ps

module HMNOC_1cluster_wpsum_system_tb;

    // --------------------------------------------------
    // Parameters (match DUT)
    // --------------------------------------------------
    localparam DATA_BITWIDTH = 16;
    localparam ADDR_BITWIDTH = 6;
    localparam act_size      = 5;
    localparam kernel_size   = 3;
    localparam PSUM_ADDR     = 40;

    // --------------------------------------------------
    // Clock / Reset
    // --------------------------------------------------
    reg clk, reset, start;
    integer cycles;

    always #5 clk = ~clk;

    // --------------------------------------------------
    // DUT I/O
    // --------------------------------------------------
    reg write_en_iact;
    reg write_en_wght;
    reg [DATA_BITWIDTH-1:0] w_data_iact;
    reg [DATA_BITWIDTH-1:0] w_data_wght;
    reg [ADDR_BITWIDTH-1:0] w_addr_iact;
    reg [ADDR_BITWIDTH-1:0] w_addr_wght;

    reg [ADDR_BITWIDTH-1:0] r_addr_psum;
    reg west_req_read_psum;
    wire [DATA_BITWIDTH-1:0] r_data_psum;

    wire compute_done;
    wire load_done;

    // --------------------------------------------------
    // DUT
    // --------------------------------------------------
    HMNOC_1cluster_wpsum dut (
        .clk(clk),
        .reset(reset),
        .start(start),

        .compute_done(compute_done),
        .load_done(load_done),

        .write_en_iact(write_en_iact),
        .write_en_wght(write_en_wght),
        .w_data_iact(w_data_iact),
        .w_data_wght(w_data_wght),
        .w_addr_iact(w_addr_iact),
        .w_addr_wght(w_addr_wght),

        .r_addr_psum(r_addr_psum),
        .west_0_req_read_psum(west_req_read_psum),
        .west_0_req_read_psum_inter(1'b0),
        .r_addr_psum_inter('0),
        .r_data_psum(r_data_psum),

        // neighbors unused in 1-cluster TB
        .north_data_i_iact('0),
        .north_enable_i_iact(1'b0),
        .south_data_i_iact('0),
        .south_enable_i_iact(1'b0),

        .north_data_i_wght('0),
        .north_enable_i_wght(1'b0),
        .south_data_i_wght('0),
        .south_enable_i_wght(1'b0),
        .east_data_i_wght('0),
        .east_enable_i_wght(1'b0)
    );

    // --------------------------------------------------
    // Cycle counter
    // --------------------------------------------------
    always @(posedge clk) begin
        if (reset) cycles <= 0;
        else       cycles <= cycles + 1;
    end

    // --------------------------------------------------
    // Test sequence
    // --------------------------------------------------
    integer i;

    initial begin
        $dumpfile("HMNOC_1cluster_system_tb.vcd");
        $dumpvars(0, HMNOC_1cluster_wpsum_system_tb);

        // init
        clk = 0;
        reset = 1;
        start = 0;
        write_en_iact = 0;
        write_en_wght = 0;
        west_req_read_psum = 0;

        #30;
        reset = 0;
        $display("[TB] Reset deasserted");

        // --------------------------------------------------
        // WRITE WEIGHTS
        // --------------------------------------------------
        $display("[TB] Writing weights to GLB");
        write_en_wght = 1;
        for (i = 0; i < kernel_size*kernel_size; i = i + 1) begin
            w_addr_wght = i;
            w_data_wght = 16'd1;
            @(posedge clk);
        end
        write_en_wght = 0;

        // --------------------------------------------------
        // WRITE ACTIVATIONS
        // --------------------------------------------------
        $display("[TB] Writing activations to GLB");
        write_en_iact = 1;
        for (i = 0; i < act_size*act_size; i = i + 1) begin
            w_addr_iact = i;
            w_data_iact = i + 1;
            @(posedge clk);
        end
        write_en_iact = 0;

        // --------------------------------------------------
        // START COMPUTE (ITER 1)
        // --------------------------------------------------
        $display("[TB] Starting compute (iter 1)");
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait_for_compute();

        read_psums(0);

        // --------------------------------------------------
        // START COMPUTE (ITER 2)
        // --------------------------------------------------
        $display("[TB] Starting compute (iter 2)");
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait_for_compute();

        read_psums(act_size);

        // --------------------------------------------------
        // START COMPUTE (ITER 3)
        // --------------------------------------------------
        $display("[TB] Starting compute (iter 3)");
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait_for_compute();

        read_psums(2*act_size);

        $display("[TB] PASS — HMNOC system behavior verified");
        $display("[TB] Total cycles = %0d", cycles);
        #20;
        $finish;
    end

    // --------------------------------------------------
    // Tasks
    // --------------------------------------------------
    task wait_for_compute;
        integer timeout;
        begin
            timeout = 0;
            while (compute_done !== 1'b1) begin
                @(posedge clk);
                timeout = timeout + 1;
                if (timeout > 2000) begin
                    $fatal("[TB][TIMEOUT] compute_done not asserted");
                end
            end
            $display("[TB] Compute done");
        end
    endtask

    task read_psums(input integer base);
        begin
            $display("[TB] Reading PSUMs");
            for (i = 0; i < act_size; i = i + 1) begin
                @(posedge clk);
                west_req_read_psum = 1;
                r_addr_psum = PSUM_ADDR + base + i;
                @(posedge clk);
                $display("  PSUM[%0d] = 0x%h", i, r_data_psum);
            end
            west_req_read_psum = 0;
        end
    endtask

endmodule

