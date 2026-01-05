`timescale 1ns / 1ps

module router_wght_generic_tb;

    /* ------------------------------------------------------------
     * Parameters
     * ----------------------------------------------------------*/
    localparam DATA_BITWIDTH     = 16;
    localparam ADDR_BITWIDTH_GLB = 8;
    localparam ADDR_BITWIDTH_SPAD = 8;

    localparam KERNEL_SIZE  = 3;
    localparam KERNEL_ELEMS = KERNEL_SIZE * KERNEL_SIZE;
    localparam W_READ_ADDR = 8'h20;

    localparam MODE_IDLE = 4'd0;
    localparam MODE_LOAD = 4'd1;

    /* ------------------------------------------------------------
     * Clock / Reset
     * ----------------------------------------------------------*/
    reg clk;
    reg reset;

    always #5 clk = ~clk;

    /* ------------------------------------------------------------
     * Shared signals
     * ----------------------------------------------------------*/
    reg  [3:0] router_mode;
    reg  [DATA_BITWIDTH-1:0] glb_rdata;

    integer i;

    /* ------------------------------------------------------------
     * Expected kernel
     * ----------------------------------------------------------*/
    reg [DATA_BITWIDTH-1:0] expected [0:KERNEL_ELEMS-1];

    /* ------------------------------------------------------------
     * Mesh outputs (per DUT)
     * ----------------------------------------------------------*/
    wire [DATA_BITWIDTH-1:0]
        n_data [0:3], s_data [0:3], w_data [0:3], e_data [0:3];

    wire n_en [0:3], s_en [0:3], w_en [0:3], e_en [0:3];

    wire [DATA_BITWIDTH-1:0] spad_data [0:3];
    wire spad_en [0:3];

    /* ------------------------------------------------------------
     * DUTs: one per direction
     * ----------------------------------------------------------*/
    genvar d;
    generate
        for (d = 0; d < 4; d = d + 1) begin : DUTS
            router_weight_full_generic #(
                .DATA_BITWIDTH(DATA_BITWIDTH),
                .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
                .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),
                .kernel_size(KERNEL_SIZE),
                .W_READ_ADDR(W_READ_ADDR),
                .HAS_GLB(1),
                .INJECT_DIR(d)
            ) dut (
                .clk(clk),
                .reset(reset),
                .router_mode(router_mode),

                .glb_addr_read(),
                .glb_req_read(),
                .glb_rdata(glb_rdata),

                .north_data_i('0), .north_enable_i(1'b0),
                .south_data_i('0), .south_enable_i(1'b0),
                .west_data_i ('0), .west_enable_i (1'b0),
                .east_data_i ('0), .east_enable_i (1'b0),

                .north_data_o(n_data[d]), .north_enable_o(n_en[d]),
                .south_data_o(s_data[d]), .south_enable_o(s_en[d]),
                .west_data_o (w_data[d]), .west_enable_o (w_en[d]),
                .east_data_o (e_data[d]), .east_enable_o (e_en[d]),

                .spad_data_o(spad_data[d]),
                .spad_en_o(spad_en[d])
            );
        end
    endgenerate

    /* ------------------------------------------------------------
     * VCD
     * ----------------------------------------------------------*/
    initial begin
        $dumpfile("router_wght_generic_tb.vcd");
        $dumpvars(0, router_wght_generic_tb);
    end

    /* ------------------------------------------------------------
     * GLB model (zero latency)
     * ----------------------------------------------------------*/
    integer glb_cnt;
    always @(*) begin
        glb_rdata = expected[glb_cnt];
    end

    /* ------------------------------------------------------------
     * Test
     * ----------------------------------------------------------*/
    initial begin
        clk = 0;
        reset = 1;
        router_mode = MODE_IDLE;
        glb_cnt = 0;

        for (i = 0; i < KERNEL_ELEMS; i = i + 1)
            expected[i] = 16'hA000 + i;

        #20 reset = 0;

        /* --------------------------------------------------------
         * Test each direction
         * ------------------------------------------------------*/
        for (i = 0; i < 4; i = i + 1) begin
            $display("=== TEST FORWARD DIR = %0d ===", i);

            router_mode = MODE_LOAD;
            glb_cnt = 0;

            while (glb_cnt < KERNEL_ELEMS) begin
                @(posedge clk);
                if (spad_en[i]) glb_cnt = glb_cnt + 1;
            end

            // one extra cycle to observe forwarding
            @(posedge clk);

            case (i)
                0: if (!n_en[i]) $fatal("Expected NORTH enable");
                1: if (!s_en[i]) $fatal("Expected SOUTH enable");
                2: if (!w_en[i]) $fatal("Expected WEST enable");
                3: if (!e_en[i]) $fatal("Expected EAST enable");
            endcase

            // ensure no other direction fires
            if ((n_en[i] + s_en[i] + w_en[i] + e_en[i]) != 1)
                $fatal("Multiple or zero directions fired");

            router_mode = MODE_IDLE;
            @(posedge clk);
        end

        $display("=== ALL DIRECTIONAL TESTS PASSED ===");
        #20;
        $finish;
    end

endmodule

