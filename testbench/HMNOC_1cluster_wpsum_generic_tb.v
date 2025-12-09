`timescale 1ns/1ps

module tb_hmnoc_1cluster_wpsum_generic;

    // ============================================================
    // Parameters
    // ============================================================
    localparam DATA_W     = 16;
    localparam ADDR_W     = 10;
    localparam ADDR_GLB   = 10;
    localparam ADDR_SPAD  = 9;

    localparam X_dim       = 3;
    localparam Y_dim       = 3;
    localparam kernel_size = 3;
    localparam act_size    = 5;

    localparam A_READ_ADDR  = 100;
    localparam A_LOAD_ADDR  = 100;
    localparam W_READ_ADDR  = 0;
    localparam W_LOAD_ADDR  = 0;

    localparam PSUM_READ_ADDR = 0;
    localparam PSUM_LOAD_ADDR = 0;

    localparam CLOSED = 4'd11;


    // ============================================================
    // CLOCK
    // ============================================================
    reg clk = 0;
    always #5 clk = ~clk;


    // ============================================================
    // Testbench-driven control signals (all REG)
    // ============================================================
    reg reset;
    reg start;

    reg write_en_iact;
    reg write_en_wght;

    reg [DATA_W-1:0] w_data_iact;
    reg [ADDR_W-1:0] w_addr_iact;

    reg [DATA_W-1:0] w_data_wght;
    reg [ADDR_W-1:0] w_addr_wght;

    reg [ADDR_W-1:0] r_addr_psum;
    reg [ADDR_W-1:0] r_addr_psum_inter;
    reg req_psum_inter;

    reg [3:0] router_mode_iact;
    reg [3:0] router_mode_wght;
    reg [3:0] router_mode_psum;

    // NoC ports — must be reg (driven by TB)
    reg [DATA_W-1:0] north_i_iact, south_i_iact, east_i_iact, west_i_iact;
    reg              north_en_iact, south_en_iact, east_en_iact, west_en_iact;

    reg [DATA_W-1:0] north_i_wght, south_i_wght, east_i_wght, west_i_wght;
    reg              north_en_wght, south_en_wght, east_en_wght, west_en_wght;

    reg  [DATA_W*X_dim-1:0] north_i_psum;
    reg                     north_en_psum;


    // ============================================================
    // DUT OUTPUTS — ALWAYS wire
    // ============================================================
    wire compute_done_orig, compute_done_gen;
    wire load_done_orig,    load_done_gen;

    wire [DATA_W-1:0] r_data_psum_orig;
    wire [DATA_W-1:0] r_data_psum_gen;

    wire [DATA_W*X_dim-1:0] south_o_psum_orig;
    wire [DATA_W*X_dim-1:0] south_o_psum_gen;

    wire south_en_psum_orig;
    wire south_en_psum_gen;


    // ============================================================
    // ORIGINAL CLUSTER
    // ============================================================
    HMNOC_1cluster_wpsum uut_orig (
        .clk(clk), .reset(reset), .start(start),

        .compute_done(compute_done_orig),
        .load_done(load_done_orig),

        .write_en_iact(write_en_iact),
        .write_en_wght(write_en_wght),

        .w_data_iact(w_data_iact),
        .w_addr_iact(w_addr_iact),

        .w_data_wght(w_data_wght),
        .w_addr_wght(w_addr_wght),

        .r_addr_psum(r_addr_psum),
        .r_addr_psum_inter(r_addr_psum_inter),
        .west_0_req_read_psum_inter(req_psum_inter),
        .west_0_req_read_psum(1'b0),
        .r_data_psum(r_data_psum_orig),

        .west_enable_i_west_0_wght(west_en_wght),
        .west_enable_i_west_0_iact(west_en_iact),

        .router_mode_west_0_wght(router_mode_wght),
        .router_mode_west_0_iact(router_mode_iact),

        .north_data_i_iact(north_i_iact),
        .north_enable_i_iact(north_en_iact),
        .north_data_o_iact(),

        .south_data_i_iact(south_i_iact),
        .south_enable_i_iact(south_en_iact),
        .south_data_o_iact(),

        .east_data_i_iact(east_i_iact),
        .east_enable_i_iact(east_en_iact),
        .east_data_o_iact(),

        .north_data_i_wght(north_i_wght),
        .north_enable_i_wght(north_en_wght),
        .north_data_o_wght(),

        .south_data_i_wght(south_i_wght),
        .south_enable_i_wght(south_en_wght),
        .south_data_o_wght(),

        .east_data_i_wght(east_i_wght),
        .east_enable_i_wght(east_en_wght),
        .east_data_o_wght(),

        .router_mode_west_0_psum(router_mode_psum),
        .north_data_i_psum(north_i_psum),
        .north_enable_i_psum(north_en_psum),

        .south_data_o_psum(south_o_psum_orig),
        .south_enable_o_psum(south_en_psum_orig)
    );


    // ============================================================
    // GENERIC CLUSTER
    // ============================================================
    HMNOC_1cluster_wpsum_generic uut_gen (
        .clk(clk), .reset(reset), .start(start),

        .compute_done(compute_done_gen),
        .load_done(load_done_gen),

        .write_en_iact(write_en_iact),
        .write_en_wght(write_en_wght),

        .w_data_iact(w_data_iact),
        .w_addr_iact(w_addr_iact),

        .w_data_wght(w_data_wght),
        .w_addr_wght(w_addr_wght),

        .r_addr_psum(r_addr_psum),
        .r_addr_psum_inter(r_addr_psum_inter),
        .west_0_req_read_psum_inter(req_psum_inter),
        .west_0_req_read_psum(1'b0),
        .r_data_psum(r_data_psum_gen),

        .west_enable_i_west_0_wght(west_en_wght),
        .west_enable_i_west_0_iact(west_en_iact),

        .router_mode_west_0_wght(router_mode_wght),
        .router_mode_west_0_iact(router_mode_iact),

        .north_data_i_iact(north_i_iact),
        .north_enable_i_iact(north_en_iact),
        .north_data_o_iact(),

        .south_data_i_iact(south_i_iact),
        .south_enable_i_iact(south_en_iact),
        .south_data_o_iact(),

        .east_data_i_iact(east_i_iact),
        .east_enable_i_iact(east_en_iact),
        .east_data_o_iact(),

        .north_data_i_wght(north_i_wght),
        .north_enable_i_wght(north_en_wght),
        .north_data_o_wght(),

        .south_data_i_wght(south_i_wght),
        .south_enable_i_wght(south_en_wght),
        .south_data_o_wght(),

        .east_data_i_wght(east_i_wght),
        .east_enable_i_wght(east_en_wght),
        .east_data_o_wght(),

        .router_mode_west_0_psum(router_mode_psum),
        .north_data_i_psum(north_i_psum),
        .north_enable_i_psum(north_en_psum),

        .south_data_o_psum(south_o_psum_gen),
        .south_enable_o_psum(south_en_psum_gen)
    );


    // ============================================================
    // SELF-CHECK TASK
    // ============================================================
    task compare;
        input [1023:0] name;
        input [1023:0] a, b;
        begin
            if (a !== b) begin
                $display("❌ FAIL %s @ %t  orig=%h  gen=%h",
                          name, $time, a, b);
                $finish;
            end
        end
    endtask


    // ============================================================
    // TEST SEQUENCE
    // ============================================================
    integer i;

    initial begin
        $display("\n==============================================");
        $display("      STARTING WPSUM CLUSTER GENERIC TB");
        $display("==============================================\n");

        // RESET
        reset = 1;
        start = 0;
        router_mode_iact = CLOSED;
        router_mode_wght = CLOSED;
        router_mode_psum = CLOSED;

        write_en_iact = 0;
        write_en_wght = 0;

        north_en_iact = south_en_iact = east_en_iact = west_en_iact = 0;
        north_en_wght = south_en_wght = east_en_wght = west_en_wght = 0;
        north_en_psum = 0;

        req_psum_inter = 0;

        repeat(5) @(posedge clk);
        reset = 0;

        // LOAD WEIGHTS
        $display("Loading weights...");
        for (i=0; i<9; i++) begin
            @(posedge clk);
            write_en_wght = 1;
            w_addr_wght = W_READ_ADDR + i;
            w_data_wght = 16'h7000 + i;
        end
        @(posedge clk);
        write_en_wght = 0;

        // LOAD ACTIVATIONS
        $display("Loading activations...");
        for (i=0; i<9; i++) begin
            @(posedge clk);
            write_en_iact = 1;
            w_addr_iact = A_LOAD_ADDR + i;
            w_data_iact = 16'h5000 + i;
        end
        @(posedge clk);
        write_en_iact = 0;

        // START COMPUTE
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Feed ACT
        for (i=0; i<9; i++) begin
            @(posedge clk);
            north_en_iact = 1;
            north_i_iact = 16'h6000 + i;
        end
        @(posedge clk)
        north_en_iact = 0;

        // Feed WGHT
        for (i=0; i<9; i++) begin
            @(posedge clk);
            west_en_wght = 1;
            west_i_wght = 16'h7000 + i;
        end
        @(posedge clk)
        west_en_wght = 0;

        // Feed PSUM
        for (i=0; i<X_dim; i++) begin
            @(posedge clk);
            north_en_psum = 1;
            north_i_psum = {X_dim{16'h9000+i}};
        end
        @(posedge clk)
        north_en_psum = 0;

        // RUN & COMPARE
        for (i=0; i<2000; i++) begin
            @(posedge clk);

            compare("compute_done", compute_done_orig, compute_done_gen);
            compare("load_done",    load_done_orig,    load_done_gen);

            compare("r_data_psum",  r_data_psum_orig,  r_data_psum_gen);

            compare("south_psum_data", south_o_psum_orig, south_o_psum_gen);
            compare("south_psum_en",   south_en_psum_orig, south_en_psum_gen);
        end

        $display("\n==============================================");
        $display("   ✅ GENERIC CLUSTER MATCHES ORIGINAL CLUSTER");
        $display("==============================================\n");

        $finish;
    end

endmodule

