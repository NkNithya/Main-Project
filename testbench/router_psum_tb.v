`timescale 1ns/1ps

module router_psum_tb;

    // =============================================================
    // PARAMETERS
    // =============================================================
    localparam DATA_W     = 16;
    localparam ADDR_GLB   = 10;
    localparam X_dim      = 5;      // number of psums in one row
    localparam TOTAL_PS   = X_dim;  // router_psum writes X_dim words

    // Use base address 0 to match DUT default
    localparam PSUM_LOAD_ADDR = 0;

    localparam [3:0] CLOSED = 11;


    // =============================================================
    // CLOCK + RESET
    // =============================================================
    reg clk = 0;
    always #5 clk = ~clk;

    reg reset;
    reg [3:0] router_mode;


    // =============================================================
    // TEST VECTOR: ONE PSUM ROW (wide)
    // =============================================================
    reg [DATA_W-1:0] exp_vals [0:TOTAL_PS-1];
    reg [DATA_W*X_dim-1:0] wide_psums;

    integer i;
    initial begin
        for (i = 0; i < TOTAL_PS; i = i + 1)
            exp_vals[i] = 16'h9000 + i;

        // pack into wide vector (MSB = last word)
        wide_psums = {
            exp_vals[4], exp_vals[3], exp_vals[2],
            exp_vals[1], exp_vals[0]
        };
    end


    // =============================================================
    // PER-DIRECTION SIGNAL SETS
    // =============================================================

    // -------- NORTH DUT --------
    reg  [DATA_W*X_dim-1:0] nN, sN, wN, eN;
    reg en_nN, en_sN, en_wN, en_eN;

    wire [DATA_W*X_dim-1:0] oN_nN, oN_sN, oN_eN, oN_wN;
    wire oeN_nN, oeN_sN, oeN_eN, oeN_wN;

    wire [DATA_W-1:0] psumN_data;
    wire              psumN_en;
    wire [ADDR_GLB-1:0] psumN_addr;

    // -------- SOUTH DUT --------
    reg  [DATA_W*X_dim-1:0] nS, sS, wS, eS;
    reg en_nS, en_sS, en_wS, en_eS;

    wire [DATA_W*X_dim-1:0] oS_nS, oS_sS, oS_eS, oS_wS;
    wire oeS_nS, oeS_sS, oeS_eS, oeS_wS;

    wire [DATA_W-1:0] psumS_data;
    wire              psumS_en;
    wire [ADDR_GLB-1:0] psumS_addr;

    // -------- WEST DUT --------
    reg  [DATA_W*X_dim-1:0] nW, sW, wW, eW;
    reg en_nW, en_sW, en_wW, en_eW;

    wire [DATA_W*X_dim-1:0] oW_nW, oW_sW, oW_eW, oW_wW;
    wire oeW_nW, oeW_sW, oeW_eW, oeW_wW;

    wire [DATA_W-1:0] psumW_data;
    wire              psumW_en;
    wire [ADDR_GLB-1:0] psumW_addr;

    // -------- EAST DUT --------
    reg  [DATA_W*X_dim-1:0] nE, sE, wE, eE;
    reg en_nE, en_sE, en_wE, en_eE;

    wire [DATA_W*X_dim-1:0] oE_nE, oE_sE, oE_eE, oE_wE;
    wire oeE_nE, oeE_sE, oeE_eE, oeE_wE;

    wire [DATA_W-1:0] psumE_data;
    wire              psumE_en;
    wire [ADDR_GLB-1:0] psumE_addr;


    // =============================================================
    // DUT INSTANCES
    // =============================================================

    // NORTH compute (0)
    router_generic_psum #(.COMPUTE_DIR(0)) dutN (
        .clk(clk), .reset(reset),
        .router_mode(router_mode),

        .north_data_i(nN), .north_enable_i(en_nN),
        .south_data_i(sN), .south_enable_i(en_sN),
        .west_data_i(wN),  .west_enable_i(en_wN),
        .east_data_i(eN),  .east_enable_i(en_eN),

        .north_data_o(oN_nN), .north_enable_o(oeN_nN),
        .south_data_o(oN_sN), .south_enable_o(oeN_sN),
        .east_data_o(oN_eN),  .east_enable_o(oeN_eN),
        .west_data_o_wide(oN_wN), .west_enable_o_wide(oeN_wN),

        .psum_data_o(psumN_data),
        .psum_enable_o(psumN_en),
        .psum_write_addr(psumN_addr)
    );

    // SOUTH compute (1)
    router_generic_psum #(.COMPUTE_DIR(1)) dutS (
        .clk(clk), .reset(reset),
        .router_mode(router_mode),

        .north_data_i(nS), .north_enable_i(en_nS),
        .south_data_i(sS), .south_enable_i(en_sS),
        .west_data_i(wS),  .west_enable_i(en_wS),
        .east_data_i(eS),  .east_enable_i(en_eS),

        .north_data_o(oS_nS), .north_enable_o(oeS_nS),
        .south_data_o(oS_sS), .south_enable_o(oeS_sS),
        .east_data_o(oS_eS),  .east_enable_o(oeS_eS),
        .west_data_o_wide(oS_wS), .west_enable_o_wide(oeS_wS),

        .psum_data_o(psumS_data),
        .psum_enable_o(psumS_en),
        .psum_write_addr(psumS_addr)
    );

    // WEST compute (2)
    router_generic_psum #(.COMPUTE_DIR(2)) dutW (
        .clk(clk), .reset(reset),
        .router_mode(router_mode),

        .north_data_i(nW), .north_enable_i(en_nW),
        .south_data_i(sW), .south_enable_i(en_sW),
        .west_data_i(wW),  .west_enable_i(en_wW),
        .east_data_i(eW),  .east_enable_i(en_eW),

        .north_data_o(oW_nW), .north_enable_o(oeW_nW),
        .south_data_o(oW_sW), .south_enable_o(oeW_sW),
        .east_data_o(oW_eW),  .east_enable_o(oeW_eW),
        .west_data_o_wide(oW_wW), .west_enable_o_wide(oeW_wW),

        .psum_data_o(psumW_data),
        .psum_enable_o(psumW_en),
        .psum_write_addr(psumW_addr)
    );

    // EAST compute (3)
    router_generic_psum #(.COMPUTE_DIR(3)) dutE (
        .clk(clk), .reset(reset),
        .router_mode(router_mode),

        .north_data_i(nE), .north_enable_i(en_nE),
        .south_data_i(sE), .south_enable_i(en_sE),
        .west_data_i(wE),  .west_enable_i(en_wE),
        .east_data_i(eE),  .east_enable_i(en_eE),

        .north_data_o(oE_nE), .north_enable_o(oeE_nE),
        .south_data_o(oE_sE), .south_enable_o(oeE_sE),
        .east_data_o(oE_eE),  .east_enable_o(oeE_eE),
        .west_data_o_wide(oE_wE), .west_enable_o_wide(oeE_wE),

        .psum_data_o(psumE_data),
        .psum_enable_o(psumE_en),
        .psum_write_addr(psumE_addr)
    );


    // =============================================================
    // MAIN TEST PROCEDURE (N → S → W → E)
    // =============================================================
    integer idx;

    task run_test;
        input integer dir; // 0=N,1=S,2=W,3=E

        begin
            $display("Testing compute direction %0d", dir);

            // reset DUT
            reset = 1;
            nN=0;sN=0;wN=0;eN=0;
            nS=0;sS=0;wS=0;eS=0;
            nW=0;sW=0;wW=0;eW=0;
            nE=0;sE=0;wE=0;eE=0;
            en_nN=0; en_sN=0; en_wN=0; en_eN=0;
            en_nS=0; en_sS=0; en_wS=0; en_eS=0;
            en_nW=0; en_sW=0; en_wW=0; en_eW=0;
            en_nE=0; en_sE=0; en_wE=0; en_eE=0;
            repeat(3) @(posedge clk);
            reset = 0;
            repeat(2) @(posedge clk);

            // enable correct direction input
            case(dir)
                0: begin nN = wide_psums; en_nN = 1; end
                1: begin sS = wide_psums; en_sS = 1; end
                2: begin wW = wide_psums; en_wW = 1; end
                3: begin eE = wide_psums; en_eE = 1; end
            endcase

            idx = 0;

            // Wait for 5 outputs
            while (idx < TOTAL_PS) begin
                @(posedge clk);

                case(dir)
                    0: if (psumN_en) begin
                           if (psumN_data !== exp_vals[idx])
                               $display("N idx=%0d got=%h exp=%h",
                               idx, psumN_data, exp_vals[idx]);
                           idx++;
                       end
                    1: if (psumS_en) begin
                           if (psumS_data !== exp_vals[idx])
                               $display("S idx=%0d got=%h exp=%h",
                               idx, psumS_data, exp_vals[idx]);
                           idx++;
                       end
                    2: if (psumW_en) begin
                           if (psumW_data !== exp_vals[idx])
                               $display("W idx=%0d got=%h exp=%h",
                               idx, psumW_data, exp_vals[idx]);
                           idx++;
                       end
                    3: if (psumE_en) begin
                           if (psumE_data !== exp_vals[idx])
                               $display("E idx=%0d got=%h exp=%h",
                               idx, psumE_data, exp_vals[idx]);
                           idx++;
                       end
                endcase
            end

            $display("Direction %0d PASS\n", dir);
        end
    endtask


    // =============================================================
    // TEST SEQUENCE
    // =============================================================
    initial begin

        $display("PSUM ROUTER – ALL 4 DIRECTIONS");


        router_mode = CLOSED;

        run_test(0); // NORTH
        run_test(1); // SOUTH
        run_test(2); // WEST
        run_test(3); // EAST


        $display("ALL PSUM ROUTES PASSED SUCCESSFULLY");

        $finish;
    end

endmodule

