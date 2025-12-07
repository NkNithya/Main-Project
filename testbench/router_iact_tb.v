`timescale 1ns/1ps

module router_generic_iact_tb;

    // --------------------------------------------------------------------
    // Parameters (match DUT)
    // --------------------------------------------------------------------
    localparam DATA_BITWIDTH      = 16;
    localparam ADDR_BITWIDTH_GLB  = 10;
    localparam ADDR_BITWIDTH_SPAD = 9;

    localparam X_dim       = 5;
    localparam Y_dim       = 3;
    localparam kernel_size = 3;
    localparam act_size    = 5;   // 5x5 activations => 25 values

    localparam A_READ_ADDR = 100;
    localparam A_LOAD_ADDR = 0;

    localparam TOTAL_ELEMS = act_size * act_size;

    // router_mode codes
    localparam [3:0] CLOSED = 4'd11;

    // --------------------------------------------------------------------
    // Clock and reset
    // --------------------------------------------------------------------
    reg clk = 0;
    always #5 clk = ~clk;

    reg reset;
    reg [3:0] router_mode;

    // --------------------------------------------------------------------
    // Expected GLB data
    // --------------------------------------------------------------------
    reg [DATA_BITWIDTH-1:0] expected_vals [0:TOTAL_ELEMS-1];

    integer i;
    initial begin
        for (i = 0; i < TOTAL_ELEMS; i = i + 1)
            expected_vals[i] = 16'hC000 + i;
    end

    // ====================================================================
    //  PER-DIRECTION SIGNAL SETS
    // ====================================================================

    // -------- NORTH DUT signals --------
    reg  [DATA_BITWIDTH-1:0] north_data_i_N, south_data_i_N, west_data_i_N, east_data_i_N;
    reg                      north_enable_i_N, south_enable_i_N, west_enable_i_N, east_enable_i_N;
    wire [DATA_BITWIDTH-1:0] north_data_o_N, south_data_o_N, west_data_o_N, east_data_o_N;
    wire                     north_enable_o_N, south_enable_o_N, west_enable_o_N, east_enable_o_N;
    wire [ADDR_BITWIDTH_GLB-1:0] glb_addr_N;
    wire                        glb_req_N;

    // -------- SOUTH DUT signals --------
    reg  [DATA_BITWIDTH-1:0] north_data_i_S, south_data_i_S, west_data_i_S, east_data_i_S;
    reg                      north_enable_i_S, south_enable_i_S, west_enable_i_S, east_enable_i_S;
    wire [DATA_BITWIDTH-1:0] north_data_o_S, south_data_o_S, west_data_o_S, east_data_o_S;
    wire                     north_enable_o_S, south_enable_o_S, west_enable_o_S, east_enable_o_S;
    wire [ADDR_BITWIDTH_GLB-1:0] glb_addr_S;
    wire                        glb_req_S;

    // -------- WEST DUT signals --------
    reg  [DATA_BITWIDTH-1:0] north_data_i_W, south_data_i_W, west_data_i_W, east_data_i_W;
    reg                      north_enable_i_W, south_enable_i_W, west_enable_i_W, east_enable_i_W;
    wire [DATA_BITWIDTH-1:0] north_data_o_W, south_data_o_W, west_data_o_W, east_data_o_W;
    wire                     north_enable_o_W, south_enable_o_W, west_enable_o_W, east_enable_o_W;
    wire [ADDR_BITWIDTH_GLB-1:0] glb_addr_W;
    wire                        glb_req_W;

    // -------- EAST DUT signals --------
    reg  [DATA_BITWIDTH-1:0] north_data_i_E, south_data_i_E, west_data_i_E, east_data_i_E;
    reg                      north_enable_i_E, south_enable_i_E, west_enable_i_E, east_enable_i_E;
    wire [DATA_BITWIDTH-1:0] north_data_o_E, south_data_o_E, west_data_o_E, east_data_o_E;
    wire                     north_enable_o_E, south_enable_o_E, west_enable_o_E, east_enable_o_E;
    wire [ADDR_BITWIDTH_GLB-1:0] glb_addr_E;
    wire                        glb_req_E;

    // --------------------------------------------------------------------
    // Instantiate DUTs for all four directions
    // --------------------------------------------------------------------

    // NORTH compute
    router_generic_iact #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),
        .X_dim(X_dim), .Y_dim(Y_dim),
        .kernel_size(kernel_size),
        .act_size(act_size),
        .A_READ_ADDR(A_READ_ADDR),
        .A_LOAD_ADDR(A_LOAD_ADDR),
        .COMPUTE_DIR("NORTH")
    ) dutN (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_read(glb_addr_N),
        .glb_req_read(glb_req_N),

        .north_data_i(north_data_i_N),
        .north_enable_i(north_enable_i_N),
        .south_data_i(south_data_i_N),
        .south_enable_i(south_enable_i_N),
        .west_data_i(west_data_i_N),
        .west_enable_i(west_enable_i_N),
        .east_data_i(east_data_i_N),
        .east_enable_i(east_enable_i_N),

        .north_data_o(north_data_o_N),
        .north_enable_o(north_enable_o_N),
        .south_data_o(south_data_o_N),
        .south_enable_o(south_enable_o_N),
        .west_data_o(west_data_o_N),
        .west_enable_o(west_enable_o_N),
        .east_data_o(east_data_o_N),
        .east_enable_o(east_enable_o_N)
    );

    // SOUTH compute
    router_generic_iact #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),
        .X_dim(X_dim), .Y_dim(Y_dim),
        .kernel_size(kernel_size),
        .act_size(act_size),
        .A_READ_ADDR(A_READ_ADDR),
        .A_LOAD_ADDR(A_LOAD_ADDR),
        .COMPUTE_DIR("SOUTH")
    ) dutS (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_read(glb_addr_S),
        .glb_req_read(glb_req_S),

        .north_data_i(north_data_i_S),
        .north_enable_i(north_enable_i_S),
        .south_data_i(south_data_i_S),
        .south_enable_i(south_enable_i_S),
        .west_data_i(west_data_i_S),
        .west_enable_i(west_enable_i_S),
        .east_data_i(east_data_i_S),
        .east_enable_i(east_enable_i_S),

        .north_data_o(north_data_o_S),
        .north_enable_o(north_enable_o_S),
        .south_data_o(south_data_o_S),
        .south_enable_o(south_enable_o_S),
        .west_data_o(west_data_o_S),
        .west_enable_o(west_enable_o_S),
        .east_data_o(east_data_o_S),
        .east_enable_o(east_enable_o_S)
    );

    // WEST compute
    router_generic_iact #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),
        .X_dim(X_dim), .Y_dim(Y_dim),
        .kernel_size(kernel_size),
        .act_size(act_size),
        .A_READ_ADDR(A_READ_ADDR),
        .A_LOAD_ADDR(A_LOAD_ADDR),
        .COMPUTE_DIR("WEST")
    ) dutW (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_read(glb_addr_W),
        .glb_req_read(glb_req_W),

        .north_data_i(north_data_i_W),
        .north_enable_i(north_enable_i_W),
        .south_data_i(south_data_i_W),
        .south_enable_i(south_enable_i_W),
        .west_data_i(west_data_i_W),
        .west_enable_i(west_enable_i_W),
        .east_data_i(east_data_i_W),
        .east_enable_i(east_enable_i_W),

        .north_data_o(north_data_o_W),
        .north_enable_o(north_enable_o_W),
        .south_data_o(south_data_o_W),
        .south_enable_o(south_enable_o_W),
        .west_data_o(west_data_o_W),
        .west_enable_o(west_enable_o_W),
        .east_data_o(east_data_o_W),
        .east_enable_o(east_enable_o_W)
    );

    // EAST compute
    router_generic_iact #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),
        .X_dim(X_dim), .Y_dim(Y_dim),
        .kernel_size(kernel_size),
        .act_size(act_size),
        .A_READ_ADDR(A_READ_ADDR),
        .A_LOAD_ADDR(A_LOAD_ADDR),
        .COMPUTE_DIR("EAST")
    ) dutE (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_read(glb_addr_E),
        .glb_req_read(glb_req_E),

        .north_data_i(north_data_i_E),
        .north_enable_i(north_enable_i_E),
        .south_data_i(south_data_i_E),
        .south_enable_i(south_enable_i_E),
        .west_data_i(west_data_i_E),
        .west_enable_i(west_enable_i_E),
        .east_data_i(east_data_i_E),
        .east_enable_i(east_enable_i_E),

        .north_data_o(north_data_o_E),
        .north_enable_o(north_enable_o_E),
        .south_data_o(south_data_o_E),
        .south_enable_o(south_enable_o_E),
        .west_data_o(west_data_o_E),
        .west_enable_o(west_enable_o_E),
        .east_data_o(east_data_o_E),
        .east_enable_o(east_enable_o_E)
    );

    // --------------------------------------------------------------------
    // GLB emulators for each DUT (combinational)
    // --------------------------------------------------------------------
    integer idxN, idxS, idxW, idxE;

    // NORTH: GLB returns data on NORTH input
    always @(*) begin
        north_data_i_N = 0;
        south_data_i_N = 0;
        west_data_i_N  = 0;
        east_data_i_N  = 0;
        if (glb_req_N) begin
            idxN = glb_addr_N - A_READ_ADDR;
            if (idxN >= 0 && idxN < TOTAL_ELEMS)
                north_data_i_N = expected_vals[idxN];
            else
                north_data_i_N = 16'hDEAD;
        end
    end

    // SOUTH: GLB returns data on SOUTH input
    always @(*) begin
        north_data_i_S = 0;
        south_data_i_S = 0;
        west_data_i_S  = 0;
        east_data_i_S  = 0;
        if (glb_req_S) begin
            idxS = glb_addr_S - A_READ_ADDR;
            if (idxS >= 0 && idxS < TOTAL_ELEMS)
                south_data_i_S = expected_vals[idxS];
            else
                south_data_i_S = 16'hDEAD;
        end
    end

    // WEST: GLB returns data on WEST input
    always @(*) begin
        north_data_i_W = 0;
        south_data_i_W = 0;
        west_data_i_W  = 0;
        east_data_i_W  = 0;
        if (glb_req_W) begin
            idxW = glb_addr_W - A_READ_ADDR;
            if (idxW >= 0 && idxW < TOTAL_ELEMS)
                west_data_i_W = expected_vals[idxW];
            else
                west_data_i_W = 16'hDEAD;
        end
    end

    // EAST: GLB returns data on EAST input
    always @(*) begin
        north_data_i_E = 0;
        south_data_i_E = 0;
        west_data_i_E  = 0;
        east_data_i_E  = 0;
        if (glb_req_E) begin
            idxE = glb_addr_E - A_READ_ADDR;
            if (idxE >= 0 && idxE < TOTAL_ELEMS)
                east_data_i_E = expected_vals[idxE];
            else
                east_data_i_E = 16'hDEAD;
        end
    end

    // --------------------------------------------------------------------
    // Main test sequence: test all 4 directions sequentially
    // --------------------------------------------------------------------
    integer idx;

    initial begin
        $display("\n===============================================");
        $display("   TESTING ALL 4 COMPUTE DIRECTIONS");
        $display("===============================================\n");

        router_mode = CLOSED;

        // Global reset
        reset = 1;
        north_enable_i_N = 0; south_enable_i_N = 0; west_enable_i_N = 0; east_enable_i_N = 0;
        north_enable_i_S = 0; south_enable_i_S = 0; west_enable_i_S = 0; east_enable_i_S = 0;
        north_enable_i_W = 0; south_enable_i_W = 0; west_enable_i_W = 0; east_enable_i_W = 0;
        north_enable_i_E = 0; south_enable_i_E = 0; west_enable_i_E = 0; east_enable_i_E = 0;
        repeat(5) @(posedge clk);
        reset = 0;
        repeat(2) @(posedge clk);

        // ===================== NORTH =====================
        $display("--- Testing COMPUTE_DIR = NORTH ---");
        north_enable_i_N = 1;
        idx = 0;
        while (idx < TOTAL_ELEMS) begin
            @(posedge clk);
            if (north_enable_o_N) begin
                if (north_data_o_N !== expected_vals[idx]) begin
                    $display("❌ FAIL NORTH idx=%0d got=%h exp=%h",
                             idx, north_data_o_N, expected_vals[idx]);
                    $finish;
                end
                idx = idx + 1;
            end
        end
        north_enable_i_N = 0;
        $display("✔ NORTH PASS\n");

        // ===================== SOUTH =====================
        $display("--- Testing COMPUTE_DIR = SOUTH ---");
        reset = 1; repeat(3) @(posedge clk); reset = 0; repeat(2) @(posedge clk);
        south_enable_i_S = 1;
        idx = 0;
        while (idx < TOTAL_ELEMS) begin
            @(posedge clk);
            if (south_enable_o_S) begin
                if (south_data_o_S !== expected_vals[idx]) begin
                    $display("❌ FAIL SOUTH idx=%0d got=%h exp=%h",
                             idx, south_data_o_S, expected_vals[idx]);
                    $finish;
                end
                idx = idx + 1;
            end
        end
        south_enable_i_S = 0;
        $display("✔ SOUTH PASS\n");

        // ===================== WEST ======================
        $display("--- Testing COMPUTE_DIR = WEST ---");
        reset = 1; repeat(3) @(posedge clk); reset = 0; repeat(2) @(posedge clk);
        west_enable_i_W = 1;
        idx = 0;
        while (idx < TOTAL_ELEMS) begin
            @(posedge clk);
            if (west_enable_o_W) begin
                if (west_data_o_W !== expected_vals[idx]) begin
                    $display("❌ FAIL WEST idx=%0d got=%h exp=%h",
                             idx, west_data_o_W, expected_vals[idx]);
                    $finish;
                end
                idx = idx + 1;
            end
        end
        west_enable_i_W = 0;
        $display("✔ WEST PASS\n");

        // ===================== EAST ======================
        $display("--- Testing COMPUTE_DIR = EAST ---");
        reset = 1; repeat(3) @(posedge clk); reset = 0; repeat(2) @(posedge clk);
        east_enable_i_E = 1;
        idx = 0;
        while (idx < TOTAL_ELEMS) begin
            @(posedge clk);
            if (east_enable_o_E) begin
                if (east_data_o_E !== expected_vals[idx]) begin
                    $display("❌ FAIL EAST idx=%0d got=%h exp=%h",
                             idx, east_data_o_E, expected_vals[idx]);
                    $finish;
                end
                idx = idx + 1;
            end
        end
        east_enable_i_E = 0;
        $display("✔ EAST PASS\n");

        $display("===============================================");
        $display("   ALL FOUR COMPUTE DIRECTIONS PASSED! 🎉");
        $display("===============================================\n");
        $finish;
    end

endmodule

