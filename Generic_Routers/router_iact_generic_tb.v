`timescale 1ns/1ps

module router_iact_generic_tb;

    // --------------------------------------------------
    // Parameters
    // --------------------------------------------------
    localparam DATA_BITWIDTH     = 16;
    localparam ADDR_BITWIDTH_GLB = 10;
    localparam act_size          = 5;
    localparam A_READ_ADDR       = 0;

    // --------------------------------------------------
    // Clock / Control
    // --------------------------------------------------
    reg clk;
    reg reset;
    reg [3:0] router_mode;

    // --------------------------------------------------
    // GLB Interface
    // --------------------------------------------------
    wire [ADDR_BITWIDTH_GLB-1:0] glb_addr_read;
    wire glb_req_read;
    wire [DATA_BITWIDTH-1:0] glb_rdata;

    // --------------------------------------------------
    // Directional Inputs
    // --------------------------------------------------
    reg [DATA_BITWIDTH-1:0] north_data_i;
    reg north_enable_i;
    reg [DATA_BITWIDTH-1:0] south_data_i;
    reg south_enable_i;
    reg [DATA_BITWIDTH-1:0] west_data_i;
    reg west_enable_i;
    reg [DATA_BITWIDTH-1:0] east_data_i;
    reg east_enable_i;

    // --------------------------------------------------
    // Outputs
    // --------------------------------------------------
    wire [DATA_BITWIDTH-1:0] local_data_o;
    wire local_enable_o;
    wire [DATA_BITWIDTH-1:0] east_data_o;
    wire east_enable_o;

    // --------------------------------------------------
    // Fake GLB (combinational SRAM)
    // --------------------------------------------------
    reg [DATA_BITWIDTH-1:0] glb_mem [0:255];
    assign glb_rdata = glb_mem[glb_addr_read];

    // --------------------------------------------------
    // DUT
    // --------------------------------------------------
    router_iact_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .act_size(act_size),
        .A_READ_ADDR(A_READ_ADDR),
        .HAS_NORTH(1),
        .HAS_SOUTH(1),
        .HAS_WEST(1),
        .HAS_EAST(1)
    ) dut (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_read(glb_addr_read),
        .glb_req_read(glb_req_read),
        .glb_rdata(glb_rdata),

        .north_data_i(north_data_i),
        .north_enable_i(north_enable_i),
        .south_data_i(south_data_i),
        .south_enable_i(south_enable_i),
        .west_data_i(west_data_i),
        .west_enable_i(west_enable_i),
        .east_data_i(east_data_i),
        .east_enable_i(east_enable_i),

        .local_data_o(local_data_o),
        .local_enable_o(local_enable_o),
        .east_data_o(east_data_o),
        .east_enable_o(east_enable_o)
    );

    // --------------------------------------------------
    // Clock
    // --------------------------------------------------
    always #5 clk = ~clk;

    // --------------------------------------------------
    // Counters / indices (DECLARE HERE!)
    // --------------------------------------------------
    integer cycle;
    integer glb_req_cnt;
    integer local_out_cnt;
    integer i;

    // --------------------------------------------------
    // VCD
    // --------------------------------------------------
    initial begin
        $dumpfile("router_iact_generic_tb.vcd");
        $dumpvars(0, router_iact_generic_tb);
    end

    // --------------------------------------------------
    // Cycle counter
    // --------------------------------------------------
    always @(posedge clk)
        cycle <= cycle + 1;

    // --------------------------------------------------
    // Main test
    // --------------------------------------------------
    initial begin
        clk = 0;
        cycle = 0;
        reset = 1;
        router_mode = 0;

        north_enable_i = 0;
        south_enable_i = 0;
        west_enable_i  = 0;
        east_enable_i  = 0;

        glb_req_cnt   = 0;
        local_out_cnt = 0;

        // Initialize GLB
        for (i = 0; i < act_size; i = i + 1)
            glb_mem[A_READ_ADDR + i] = 16'hA000 + i;

        $display("=== RESET ASSERTED ===");
        #20;
        reset = 0;
        $display("=== RESET DEASSERTED @ cycle %0d ===", cycle);

        // ---------------- LOAD ----------------
        $display("=== TEST 1: LOAD MODE ===");
        router_mode = 4'd1;

        while (local_out_cnt < act_size) begin
            @(posedge clk);

            if (glb_req_read) begin
                glb_req_cnt = glb_req_cnt + 1;
                $display("[C%0d][GLB_REQ ] addr=%0d",
                         cycle, glb_addr_read);
            end

            if (local_enable_o) begin
                $display("[C%0d][LOCAL_RX] data=0x%h",
                         cycle, local_data_o);

                if (local_data_o !== (16'hA000 + local_out_cnt))
                    $fatal(1,
                        "[ERROR] LOAD mismatch idx=%0d exp=0x%h got=0x%h",
                        local_out_cnt,
                        16'hA000 + local_out_cnt,
                        local_data_o);

                local_out_cnt = local_out_cnt + 1;
            end
        end

        if (glb_req_cnt != act_size)
            $fatal(1, "[ERROR] GLB request count mismatch");

        // ---------------- IDLE ----------------
        $display("=== TEST 2: IDLE MODE ===");
        router_mode = 4'd0;
        repeat (3) begin
            @(posedge clk);
            if (glb_req_read || local_enable_o)
                $fatal(1, "[ERROR] Activity in IDLE");
        end

        // ---------------- FORWARD ----------------
        $display("=== TEST 3: FORWARD MODE ===");
        router_mode = 4'd2;

        @(posedge clk);
        north_data_i   = 16'hB001;
        north_enable_i = 1'b1;

        @(posedge clk);
        north_enable_i = 0;

        @(posedge clk);
        if (!local_enable_o || local_data_o !== 16'hB001)
            $fatal(1, "[ERROR] NORTH->LOCAL forward failed");

        $display("[C%0d][FWD ] north->local data=0x%h",
                 cycle, local_data_o);

        // ---------------- DONE ----------------
        $display("==============================================");
        $display(" PASS: router_iact_generic standard NoC test");
        $display(" GLB requests : %0d", glb_req_cnt);
        $display(" Local outputs: %0d", local_out_cnt);
        $display("==============================================");

        #20;
        $finish;
    end

endmodule

