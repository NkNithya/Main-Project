`timescale 1ns/1ps

module router_generic_psum_tb;

    // =============================================================
    // PARAMETERS
    // =============================================================
    localparam DATA_W     = 16;
    localparam ADDR_GLB   = 10;
    localparam ADDR_SPAD  = 9;

    localparam X_dim       = 5;   // Number of PSUM lanes
    localparam Y_dim       = 3;
    localparam kernel_size = 3;
    localparam act_size    = 5;

    localparam PSUM_READ_ADDR = 0;
    localparam PSUM_LOAD_ADDR = 20;   // GLB write base addr

    localparam TOTAL_PSUMS = X_dim;

    localparam [3:0] CLOSED = 11;


    // =============================================================
    // CLOCK + RESET
    // =============================================================
    reg clk = 0;
    always #5 clk = ~clk;

    reg reset;
    reg [3:0] router_mode;


    // =============================================================
    // EXPECTED PSUM VECTOR
    // =============================================================
    reg [DATA_W-1:0] exp_vals [0:TOTAL_PSUMS-1];
    integer i;

    initial begin
        for (i = 0; i < TOTAL_PSUMS; i = i + 1)
            exp_vals[i] = 16'h4000 + i;   // arbitrary test pattern
    end

    // Wide PSUM vector that will be fed into compute direction
    // Lane 0 should be at LSB side (bits [DATA_W-1:0])
    wire [DATA_W*X_dim-1:0] psum_vec =
        { exp_vals[4], exp_vals[3], exp_vals[2], exp_vals[1], exp_vals[0] };


    // =============================================================
    // Per-direction DUT INPUT / ENABLE lines
    // Each direction has its own DUT instance
    // =============================================================

    // ---------- NORTH DUT ----------
    reg  enN;
    wire [DATA_W-1:0] psumN_data;
    wire              psumN_en;
    wire [ADDR_GLB-1:0] addrN;

    // ---------- SOUTH DUT ----------
    reg  enS;
    wire [DATA_W-1:0] psumS_data;
    wire              psumS_en;
    wire [ADDR_GLB-1:0] addrS;

    // ---------- WEST DUT ----------
    reg  enW;
    wire [DATA_W-1:0] psumW_data;
    wire              psumW_en;
    wire [ADDR_GLB-1:0] addrW;

    // ---------- EAST DUT ----------
    reg  enE;
    wire [DATA_W-1:0] psumE_data;
    wire              psumE_en;
    wire [ADDR_GLB-1:0] addrE;


    // =============================================================
    // DUT Instantiations – all 4 compute directions
    // =============================================================

    // 0 = NORTH compute
    router_generic_psum #(
        .DATA_BITWIDTH     (DATA_W),
        .ADDR_BITWIDTH_GLB (ADDR_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_SPAD),
        .X_dim             (X_dim),
        .Y_dim             (Y_dim),
        .kernel_size       (kernel_size),
        .act_size          (act_size),
        .PSUM_READ_ADDR    (PSUM_READ_ADDR),
        .PSUM_LOAD_ADDR    (PSUM_LOAD_ADDR),
        .COMPUTE_DIR       (0)        // NORTH
    ) dutN (
        .clk              (clk),
        .reset            (reset),
        .router_mode      (router_mode),

        .north_data_i     (psum_vec),
        .north_enable_i   (enN),

        .south_data_i     ({DATA_W*X_dim{1'b0}}),
        .south_enable_i   (1'b0),

        .west_data_i      ({DATA_W*X_dim{1'b0}}),
        .west_enable_i    (1'b0),

        .east_data_i      ({DATA_W*X_dim{1'b0}}),
        .east_enable_i    (1'b0),

        .north_data_o     (),
        .north_enable_o   (),
        .south_data_o     (),
        .south_enable_o   (),
        .east_data_o      (),
        .east_enable_o    (),
        .west_data_o_wide (),
        .west_enable_o_wide(),

        .psum_data_o      (psumN_data),
        .psum_enable_o    (psumN_en),
        .psum_write_addr  (addrN)
    );

    // 1 = SOUTH compute
    router_generic_psum #(
        .DATA_BITWIDTH     (DATA_W),
        .ADDR_BITWIDTH_GLB (ADDR_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_SPAD),
        .X_dim             (X_dim),
        .Y_dim             (Y_dim),
        .kernel_size       (kernel_size),
        .act_size          (act_size),
        .PSUM_READ_ADDR    (PSUM_READ_ADDR),
        .PSUM_LOAD_ADDR    (PSUM_LOAD_ADDR),
        .COMPUTE_DIR       (1)        // SOUTH
    ) dutS (
        .clk              (clk),
        .reset            (reset),
        .router_mode      (router_mode),

        .north_data_i     ({DATA_W*X_dim{1'b0}}),
        .north_enable_i   (1'b0),

        .south_data_i     (psum_vec),
        .south_enable_i   (enS),

        .west_data_i      ({DATA_W*X_dim{1'b0}}),
        .west_enable_i    (1'b0),

        .east_data_i      ({DATA_W*X_dim{1'b0}}),
        .east_enable_i    (1'b0),

        .north_data_o     (),
        .north_enable_o   (),
        .south_data_o     (),
        .south_enable_o   (),
        .east_data_o      (),
        .east_enable_o    (),
        .west_data_o_wide (),
        .west_enable_o_wide(),

        .psum_data_o      (psumS_data),
        .psum_enable_o    (psumS_en),
        .psum_write_addr  (addrS)
    );

    // 2 = WEST compute
    router_generic_psum #(
        .DATA_BITWIDTH     (DATA_W),
        .ADDR_BITWIDTH_GLB (ADDR_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_SPAD),
        .X_dim             (X_dim),
        .Y_dim             (Y_dim),
        .kernel_size       (kernel_size),
        .act_size          (act_size),
        .PSUM_READ_ADDR    (PSUM_READ_ADDR),
        .PSUM_LOAD_ADDR    (PSUM_LOAD_ADDR),
        .COMPUTE_DIR       (2)        // WEST
    ) dutW (
        .clk              (clk),
        .reset            (reset),
        .router_mode      (router_mode),

        .north_data_i     ({DATA_W*X_dim{1'b0}}),
        .north_enable_i   (1'b0),

        .south_data_i     ({DATA_W*X_dim{1'b0}}),
        .south_enable_i   (1'b0),

        .west_data_i      (psum_vec),
        .west_enable_i    (enW),

        .east_data_i      ({DATA_W*X_dim{1'b0}}),
        .east_enable_i    (1'b0),

        .north_data_o     (),
        .north_enable_o   (),
        .south_data_o     (),
        .south_enable_o   (),
        .east_data_o      (),
        .east_enable_o    (),
        .west_data_o_wide (),
        .west_enable_o_wide(),

        .psum_data_o      (psumW_data),
        .psum_enable_o    (psumW_en),
        .psum_write_addr  (addrW)
    );

    // 3 = EAST compute
    router_generic_psum #(
        .DATA_BITWIDTH     (DATA_W),
        .ADDR_BITWIDTH_GLB (ADDR_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_SPAD),
        .X_dim             (X_dim),
        .Y_dim             (Y_dim),
        .kernel_size       (kernel_size),
        .act_size          (act_size),
        .PSUM_READ_ADDR    (PSUM_READ_ADDR),
        .PSUM_LOAD_ADDR    (PSUM_LOAD_ADDR),
        .COMPUTE_DIR       (3)        // EAST
    ) dutE (
        .clk              (clk),
        .reset            (reset),
        .router_mode      (router_mode),

        .north_data_i     ({DATA_W*X_dim{1'b0}}),
        .north_enable_i   (1'b0),

        .south_data_i     ({DATA_W*X_dim{1'b0}}),
        .south_enable_i   (1'b0),

        .west_data_i      ({DATA_W*X_dim{1'b0}}),
        .west_enable_i    (1'b0),

        .east_data_i      (psum_vec),
        .east_enable_i    (enE),

        .north_data_o     (),
        .north_enable_o   (),
        .south_data_o     (),
        .south_enable_o   (),
        .east_data_o      (),
        .east_enable_o    (),
        .west_data_o_wide (),
        .west_enable_o_wide(),

        .psum_data_o      (psumE_data),
        .psum_enable_o    (psumE_en),
        .psum_write_addr  (addrE)
    );


    // =============================================================
    // MAIN TEST SEQUENCE (NO TASKS)
    // =============================================================
    integer idx;

    initial begin

        $display("     PSUM ROUTER – ALL 4 DIRECTIONS TEST");


        enN = 0; enS = 0; enW = 0; enE = 0;
        reset = 1; router_mode = CLOSED;
        repeat(5) @(posedge clk);
        reset = 0; repeat(5) @(posedge clk);

        // ---------------- NORTH ----------------
        $display("--- Testing NORTH compute (0)");
        reset = 1; repeat(3) @(posedge clk); reset = 0; repeat(2) @(posedge clk);
        router_mode = CLOSED;

        idx = 0;
        enN = 1;

        while (idx < TOTAL_PSUMS) begin
            @(posedge clk);
            if (psumN_en) begin
                if (psumN_data !== exp_vals[idx]) begin
                    $display("FAIL NORTH idx=%0d got=%h exp=%h",
                             idx, psumN_data, exp_vals[idx]);
                    $finish;
                end
                if (addrN !== (PSUM_LOAD_ADDR + idx)) begin
                    $display("ADDR FAIL NORTH idx=%0d addr=%0d exp=%0d",
                             idx, addrN, PSUM_LOAD_ADDR + idx);
                    $finish;
                end
                idx = idx + 1;
            end
        end
        enN = 0;
        $display("NORTH PASS\n");

        // ---------------- SOUTH ----------------
        $display("--- Testing SOUTH compute (1) ---");
        reset = 1; repeat(3) @(posedge clk); reset = 0; repeat(2) @(posedge clk);
        router_mode = CLOSED;

        idx = 0;
        enS = 1;

        while (idx < TOTAL_PSUMS) begin
            @(posedge clk);
            if (psumS_en) begin
                if (psumS_data !== exp_vals[idx]) begin
                    $display("FAIL SOUTH idx=%0d got=%h exp=%h",
                             idx, psumS_data, exp_vals[idx]);
                    $finish;
                end
                if (addrS !== (PSUM_LOAD_ADDR + idx)) begin
                    $display("ADDR FAIL SOUTH idx=%0d addr=%0d exp=%0d",
                             idx, addrS, PSUM_LOAD_ADDR + idx);
                    $finish;
                end
                idx = idx + 1;
            end
        end
        enS = 0;
        $display("SOUTH PASS\n");

        // ---------------- WEST ----------------
        $display("--- Testing WEST compute (2) ---");
        reset = 1; repeat(3) @(posedge clk); reset = 0; repeat(2) @(posedge clk);
        router_mode = CLOSED;

        idx = 0;
        enW = 1;

        while (idx < TOTAL_PSUMS) begin
            @(posedge clk);
            if (psumW_en) begin
                if (psumW_data !== exp_vals[idx]) begin
                    $display("FAIL WEST idx=%0d got=%h exp=%h",
                             idx, psumW_data, exp_vals[idx]);
                    $finish;
                end
                if (addrW !== (PSUM_LOAD_ADDR + idx)) begin
                    $display("ADDR FAIL WEST idx=%0d addr=%0d exp=%0d",
                             idx, addrW, PSUM_LOAD_ADDR + idx);
                    $finish;
                end
                idx = idx + 1;
            end
        end
        enW = 0;
        $display("WEST PASS\n");

        // ---------------- EAST ----------------
        $display("--- Testing EAST compute (3) ---");
        reset = 1; repeat(3) @(posedge clk); reset = 0; repeat(2) @(posedge clk);
        router_mode = CLOSED;

        idx = 0;
        enE = 1;

        while (idx < TOTAL_PSUMS) begin
            @(posedge clk);
            if (psumE_en) begin
                if (psumE_data !== exp_vals[idx]) begin
                    $display("FAIL EAST idx=%0d got=%h exp=%h",
                             idx, psumE_data, exp_vals[idx]);
                    $finish;
                end
                if (addrE !== (PSUM_LOAD_ADDR + idx)) begin
                    $display("ADDR FAIL EAST idx=%0d addr=%0d exp=%0d",
                             idx, addrE, PSUM_LOAD_ADDR + idx);
                    $finish;
                end
                idx = idx + 1;
            end
        end
        enE = 0;
        $display("EAST PASS\n");


        $display("ALL 4 PSUM DIRECTIONS PASSED!");


        $finish;
    end

endmodule

