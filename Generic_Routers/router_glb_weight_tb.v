`timescale 1ns / 1ps

module router_weight_full_generic_tb;

    localparam DATA_BITWIDTH      = 16;
    localparam ADDR_BITWIDTH_GLB  = 10;
    localparam kernel_size        = 3;
    localparam TOTAL_W            = kernel_size * kernel_size;
    localparam W_BASE             = 16;

    reg clk, reset;
    reg [3:0] router_mode;

    wire [ADDR_BITWIDTH_GLB-1:0] glb_addr;
    wire                         glb_req;
    reg  [DATA_BITWIDTH-1:0]     glb_rdata;

    wire [DATA_BITWIDTH-1:0] spad_data_o;
    wire spad_en_o;

    integer recv_count;
    integer cycle;

    reg [DATA_BITWIDTH-1:0] expected [0:TOTAL_W-1];
    reg [DATA_BITWIDTH-1:0] glb_mem  [0:1023];

    localparam MODE_IDLE = 0;
    localparam MODE_LOAD = 1;

    // Clock
    always #5 clk = ~clk;

    // DUT
    router_weight_full_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .kernel_size(kernel_size),
        .W_READ_ADDR(W_BASE),
        .HAS_GLB(1),
        .INJECT_DIR(3),
        .HAS_WEST(0)
    ) dut (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_read(glb_addr),
        .glb_req_read(glb_req),
        .glb_rdata(glb_rdata),

        .north_data_i('0), .north_enable_i(1'b0),
        .south_data_i('0), .south_enable_i(1'b0),
        .west_data_i ('0), .west_enable_i (1'b0),
        .east_data_i ('0), .east_enable_i (1'b0),

        .north_data_o(), .north_enable_o(),
        .south_data_o(), .south_enable_o(),
        .west_data_o (), .west_enable_o (),
        .east_data_o (),
        .east_enable_o(),

        .spad_data_o(spad_data_o),
        .spad_en_o(spad_en_o)
    );

    // Synchronous GLB model (correct)
    always @(posedge clk) begin
        if (reset)
            glb_rdata <= '0;
        else if (glb_req)
            glb_rdata <= glb_mem[glb_addr];
        else
            glb_rdata <= '0;
    end

    // Init
    initial begin
        clk = 0;
        reset = 1;
        router_mode = MODE_IDLE;
        recv_count = 0;
        cycle = 0;

        for (int i = 0; i < TOTAL_W; i++) begin
            expected[i] = 16'hA000 + i;
            glb_mem[W_BASE + i] = expected[i];
        end

        repeat (3) @(posedge clk);
        reset = 0;
        $display("=== RESET DEASSERTED ===");

        @(posedge clk);
        router_mode = MODE_LOAD;
        $display("=== WEIGHT LOAD START ===");

        // ✅ CORRECT timeout control
        fork : LOAD_CHECK
            begin : TIMEOUT
                repeat (500) @(posedge clk);
                $fatal(1, "[TIMEOUT] Weight load did not complete");
            end
            begin : DONE
                wait (recv_count == TOTAL_W);
                disable TIMEOUT;
            end
        join

        repeat (5) @(posedge clk);
        if (spad_en_o)
            $fatal(1, "[ERROR] SPAD active after completion");

        $display("=== PASS: FULL GENERIC WEIGHT ROUTER VERIFIED ===");
        $finish;
    end

    always @(posedge clk)
        cycle++;

    always @(posedge clk) begin
        if (glb_req)
            $display("[C%0d][GLB_REQ ] addr=%0d data=0x%h",
                     cycle, glb_addr, glb_rdata);
    end

    always @(posedge clk) begin
        if (spad_en_o) begin
            if (spad_data_o !== expected[recv_count])
                $fatal(1,
                    "[ERROR] SPAD mismatch idx=%0d exp=0x%h got=0x%h",
                    recv_count, expected[recv_count], spad_data_o);

            $display("[C%0d][SPAD_WR ] idx=%0d data=0x%h OK",
                     cycle, recv_count, spad_data_o);

            recv_count++;
        end
    end

endmodule

