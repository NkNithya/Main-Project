`timescale 1ns / 1ps

module HMNOC_1cluster_debug_tb;

    // -------------------------------------------------
    // Parameters
    // -------------------------------------------------
    localparam DATA_BITWIDTH = 16;
    localparam ADDR_BITWIDTH = 10;
    localparam ACT_SIZE      = 5;
    localparam KERNEL_SIZE   = 3;
    localparam PSUM_BASE     = 40;

    // -------------------------------------------------
    // Clock / Reset
    // -------------------------------------------------
    reg clk = 0;
    always #5 clk = ~clk;

    reg reset, start;
    integer cycle;

    always @(posedge clk)
        cycle <= reset ? 0 : cycle + 1;

    // -------------------------------------------------
    // GLB write interface
    // -------------------------------------------------
    reg write_en_iact, write_en_wght;
    reg [DATA_BITWIDTH-1:0] w_data_iact, w_data_wght;
    reg [ADDR_BITWIDTH-1:0] w_addr_iact, w_addr_wght;

    // -------------------------------------------------
    // GLB read interface
    // -------------------------------------------------
    reg [ADDR_BITWIDTH-1:0] r_addr_psum;
    reg west_req_read_psum;
    wire [DATA_BITWIDTH-1:0] r_data_psum;

    // -------------------------------------------------
    // Status
    // -------------------------------------------------
    wire compute_done, load_done;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------
    HMNOC_1cluster dut (
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
        .west_req_read_psum(west_req_read_psum),
        .west_req_read_psum_inter(1'b0),
        .r_addr_psum_inter('0),
        .r_data_psum(r_data_psum)
    );

    // -------------------------------------------------
    // VCD
    // -------------------------------------------------
    initial begin
        $dumpfile("HMNOC_debug.vcd");
        $dumpvars(0, HMNOC_1cluster_debug_tb);
    end

    // =================================================
    // 🔍 DEBUG PROBES (CORE OF THIS TB)
    // =================================================

    // --- PE output probe ---
    always @(posedge clk) begin
        if (dut.psum_vec_valid) begin
            $display(
                "[C%0d][DBG][PE] psum_vec=%h lane0=%h",
                cycle,
                dut.psum_vec_from_pe,
                dut.psum_lane0
            );
        end
    end

    // --- Router → PE enable alignment ---
    always @(posedge clk) begin
        $display(
            "[C%0d][DBG][EN] iact_en=%b wght_en=%b",
            cycle,
            dut.iact_local_en,
            dut.wght_spad_en
        );
    end

    // --- PSUM FSM probe ---
    always @(posedge clk) begin
        $display(
            "[C%0d][DBG][FSM] valid=%b active=%b cnt=%0d addr=%0d we=%b",
            cycle,
            dut.psum_vec_valid,
            dut.psum_active,
            dut.psum_cnt,
            dut.psum_addr,
            dut.psum_we
        );
    end

    // --- GLB write probe ---
    always @(posedge clk) begin
        if (dut.u_glb.write_en_psum) begin
            $display(
                "[C%0d][DBG][GLB_WRITE] addr=%0d data=%h",
                cycle,
                dut.u_glb.w_addr_psum,
                dut.u_glb.w_data_psum
            );
        end
    end

    // --- GLB read probe ---
    always @(posedge clk) begin
        if (west_req_read_psum) begin
            $display(
                "[C%0d][DBG][GLB_READ] addr=%0d data=%h",
                cycle,
                r_addr_psum,
                r_data_psum
            );
        end
    end

    // =================================================
    // Test sequence (minimal)
    // =================================================
    integer i;

    initial begin
        reset = 1;
        start = 0;
        write_en_iact = 0;
        write_en_wght = 0;
        west_req_read_psum = 0;

        repeat (4) @(posedge clk);
        reset = 0;
        $display("[C%0d] RESET DEASSERTED", cycle);

        // ---- Load weights ----
        for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1) begin
            @(posedge clk);
            write_en_wght = 1;
            w_addr_wght   = i;
            w_data_wght   = 16'd1;
        end
        @(posedge clk) write_en_wght = 0;

        // ---- Load activations ----
        for (i = 0; i < ACT_SIZE*ACT_SIZE; i = i + 1) begin
            @(posedge clk);
            write_en_iact = 1;
            w_addr_iact   = i;
            w_data_iact   = i + 1;
        end
        @(posedge clk) write_en_iact = 0;

        // ---- Start compute ----
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait (compute_done);
        $display("[C%0d] COMPUTE DONE", cycle);

        // ---- Read PSUMs ----
        for (i = 0; i < ACT_SIZE; i = i + 1) begin
            r_addr_psum = PSUM_BASE + i;
            west_req_read_psum = 1;
            @(posedge clk);
            @(posedge clk);
        end
        west_req_read_psum = 0;

        #50;
        $finish;
    end

endmodule

