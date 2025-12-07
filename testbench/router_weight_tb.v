`timescale 1ns/1ps

module router_generic_wght_tb;

    // =============================================================
    // PARAMETERS
    // =============================================================
    localparam DATA_W     = 16;
    localparam ADDR_GLB   = 10;
    localparam ADDR_SPAD  = 9;

    localparam X_dim       = 5;
    localparam Y_dim       = 3;
    localparam kernel_size = 3;       // 3x3 weights
    localparam act_size    = 5;

    // *** MUST MATCH DUT ***
    localparam W_READ_ADDR = 0;
    localparam W_LOAD_ADDR = 0;

    localparam TOTAL_WEIGHTS = kernel_size * kernel_size; // 9

    localparam [3:0] CLOSED = 11;      // router mode CLOSED


    // =============================================================
    // CLOCK + RESET
    // =============================================================
    reg clk = 0;
    always #5 clk = ~clk;

    reg reset;
    reg [3:0] router_mode;


    // =============================================================
    // EXPECTED WEIGHT VALUES
    // =============================================================
    reg [DATA_W-1:0] exp_vals [0:TOTAL_WEIGHTS-1];
    integer i;

    initial begin
        for (i = 0; i < TOTAL_WEIGHTS; i = i + 1)
            exp_vals[i] = 16'h7000 + i;
    end


    // =============================================================
    // PER-DIRECTION SIGNAL SETS (N, S, W, E)
    // =============================================================

    // ---------- NORTH DUT ----------
    reg  [DATA_W-1:0] nN, sN, wN, eN;
    reg               en_nN, en_sN, en_wN, en_eN;

    wire [ADDR_GLB-1:0] addrN;
    wire                reqN;
    wire [DATA_W-1:0]   spadN_data;
    wire                spadN_en;

    // ---------- SOUTH DUT ----------
    reg  [DATA_W-1:0] nS, sS, wS, eS;
    reg               en_nS, en_sS, en_wS, en_eS;

    wire [ADDR_GLB-1:0] addrS;
    wire                reqS;
    wire [DATA_W-1:0]   spadS_data;
    wire                spadS_en;

    // ---------- WEST DUT ----------
    reg  [DATA_W-1:0] nW, sW, wW, eW;
    reg               en_nW, en_sW, en_wW, en_eW;

    wire [ADDR_GLB-1:0] addrW;
    wire                reqW;
    wire [DATA_W-1:0]   spadW_data;
    wire                spadW_en;

    // ---------- EAST DUT ----------
    reg  [DATA_W-1:0] nE, sE, wE, eE;
    reg               en_nE, en_sE, en_wE, en_eE;

    wire [ADDR_GLB-1:0] addrE;
    wire                reqE;
    wire [DATA_W-1:0]   spadE_data;
    wire                spadE_en;


    // =============================================================
    // DUT INSTANCES
    // =============================================================

    // NORTH compute (0)
    router_generic_wght #(.COMPUTE_DIR(0)) dutN (
        .clk(clk), .reset(reset),
        .router_mode(router_mode),

        .north_data_i(nN),  .north_enable_i(en_nN),
        .south_data_i(sN),  .south_enable_i(en_sN),
        .west_data_i(wN),   .west_enable_i(en_wN),
        .east_data_i(eN),   .east_enable_i(en_eN),

        .north_data_o(), .north_enable_o(),
        .south_data_o(), .south_enable_o(),
        .east_data_o(),  .east_enable_o(),
        .west_data_o_routed(), .west_enable_o_routed(),

        .spad_wdata_o(spadN_data),
        .spad_wenable_o(spadN_en),

        .glb_addr_read_wght(addrN),
        .glb_req_read_wght(reqN)
    );

    // SOUTH compute (1)
    router_generic_wght #(.COMPUTE_DIR(1)) dutS (
        .clk(clk), .reset(reset),
        .router_mode(router_mode),

        .north_data_i(nS),  .north_enable_i(en_nS),
        .south_data_i(sS),  .south_enable_i(en_sS),
        .west_data_i(wS),   .west_enable_i(en_wS),
        .east_data_i(eS),   .east_enable_i(en_eS),

        .north_data_o(), .north_enable_o(),
        .south_data_o(), .south_enable_o(),
        .east_data_o(),  .east_enable_o(),
        .west_data_o_routed(), .west_enable_o_routed(),

        .spad_wdata_o(spadS_data),
        .spad_wenable_o(spadS_en),

        .glb_addr_read_wght(addrS),
        .glb_req_read_wght(reqS)
    );

    // WEST compute (2)
    router_generic_wght #(.COMPUTE_DIR(2)) dutW (
        .clk(clk), .reset(reset),
        .router_mode(router_mode),

        .north_data_i(nW),  .north_enable_i(en_nW),
        .south_data_i(sW),  .south_enable_i(en_sW),
        .west_data_i(wW),   .west_enable_i(en_wW),
        .east_data_i(eW),   .east_enable_i(en_eW),

        .north_data_o(), .north_enable_o(),
        .south_data_o(), .south_enable_o(),
        .east_data_o(),  .east_enable_o(),
        .west_data_o_routed(), .west_enable_o_routed(),

        .spad_wdata_o(spadW_data),
        .spad_wenable_o(spadW_en),

        .glb_addr_read_wght(addrW),
        .glb_req_read_wght(reqW)
    );

    // EAST compute (3)
    router_generic_wght #(.COMPUTE_DIR(3)) dutE (
        .clk(clk), .reset(reset),
        .router_mode(router_mode),

        .north_data_i(nE),  .north_enable_i(en_nE),
        .south_data_i(sE),  .south_enable_i(en_sE),
        .west_data_i(wE),   .west_enable_i(en_wE),
        .east_data_i(eE),   .east_enable_i(en_eE),

        .north_data_o(), .north_enable_o(),
        .south_data_o(), .south_enable_o(),
        .east_data_o(),  .east_enable_o(),
        .west_data_o_routed(), .west_enable_o_routed(),

        .spad_wdata_o(spadE_data),
        .spad_wenable_o(spadE_en),

        .glb_addr_read_wght(addrE),
        .glb_req_read_wght(reqE)
    );


    // =============================================================
    // GLB EMULATION
    // =============================================================

    always @(*) begin
        nN=0; sN=0; wN=0; eN=0;
        if (reqN) nN = exp_vals[addrN - W_READ_ADDR];
    end

    always @(*) begin
        nS=0; sS=0; wS=0; eS=0;
        if (reqS) sS = exp_vals[addrS - W_READ_ADDR];
    end

    always @(*) begin
        nW=0; sW=0; wW=0; eW=0;
        if (reqW) wW = exp_vals[addrW - W_READ_ADDR];
    end

    always @(*) begin
        nE=0; sE=0; wE=0; eE=0;
        if (reqE) eE = exp_vals[addrE - W_READ_ADDR];
    end


    // =============================================================
    // MAIN TEST
    // =============================================================
    integer idx;

    initial begin
        $display("\n================================================");
        $display("     WEIGHT ROUTER – ALL 4 DIRECTIONS TEST");
        $display("================================================\n");

        router_mode = CLOSED;

        reset = 1;
        en_nN=0; en_sN=0; en_wN=0; en_eN=0;
        en_nS=0; en_sS=0; en_wS=0; en_eS=0;
        en_nW=0; en_sW=0; en_wW=0; en_eW=0;
        en_nE=0; en_sE=0; en_wE=0; en_eE=0;

        repeat(5) @(posedge clk);
        reset = 0;
        repeat(2) @(posedge clk);

        // ---------------- NORTH ----------------
        $display("--- Testing NORTH compute (0) ---");
        idx = 0;
        en_nN = 1;

        while (idx < TOTAL_WEIGHTS) begin
            @(posedge clk);
            if (spadN_en) begin
                if (spadN_data !== exp_vals[idx]) begin
                    $display("❌ FAIL NORTH idx=%0d got=%h exp=%h",
                              idx, spadN_data, exp_vals[idx]);
                    $finish;
                end
                idx++;
            end
        end

        en_nN = 0;
        $display("✔ NORTH PASS\n");

        // ---------------- SOUTH ----------------
        $display("--- Testing SOUTH compute (1) ---");
        reset=1; repeat(3) @(posedge clk); reset=0; repeat(2) @(posedge clk);

        idx=0; en_sS=1;

        while (idx < TOTAL_WEIGHTS) begin
            @(posedge clk);
            if (spadS_en) begin
                if (spadS_data !== exp_vals[idx]) begin
                    $display("❌ FAIL SOUTH idx=%0d got=%h exp=%h",
                              idx, spadS_data, exp_vals[idx]);
                    $finish;
                end
                idx++;
            end
        end

        en_sS=0;
        $display("✔ SOUTH PASS\n");

        // ---------------- WEST ----------------
        $display("--- Testing WEST compute (2) ---");
        reset=1; repeat(3) @(posedge clk); reset=0; repeat(2) @(posedge clk);

        idx=0; en_wW=1;

        while (idx < TOTAL_WEIGHTS) begin
            @(posedge clk);
            if (spadW_en) begin
                if (spadW_data !== exp_vals[idx]) begin
                    $display("❌ FAIL WEST idx=%0d got=%h exp=%h",
                              idx, spadW_data, exp_vals[idx]);
                    $finish;
                end
                idx++;
            end
        end

        en_wW=0;
        $display("✔ WEST PASS\n");

        // ---------------- EAST ----------------
        $display("--- Testing EAST compute (3) ---");
        reset=1; repeat(3) @(posedge clk); reset=0; repeat(2) @(posedge clk);

        idx=0; en_eE=1;

        while (idx < TOTAL_WEIGHTS) begin
            @(posedge clk);
            if (spadE_en) begin
                if (spadE_data !== exp_vals[idx]) begin
                    $display("❌ FAIL EAST idx=%0d got=%h exp=%h",
                              idx, spadE_data, exp_vals[idx]);
                    $finish;
                end
                idx++;
            end
        end

        en_eE=0;
        $display("✔ EAST PASS\n");

        $display("================================================");
        $display("  ALL 4 WEIGHT DIRECTIONS PASSED! 🎉");
        $display("================================================\n");

        $finish;
    end
endmodule

