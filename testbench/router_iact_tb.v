`timescale 1ns/1ps

module router_iact_tb;

    //--------------------------------------------------------------------
    // DUT parameters
    //--------------------------------------------------------------------
    localparam DATA_BITWIDTH      = 16;
    localparam ADDR_BITWIDTH_GLB  = 10;
    localparam ADDR_BITWIDTH_SPAD = 9;

    localparam X_dim       = 5;
    localparam Y_dim       = 3;
    localparam kernel_size = 3;
    localparam act_size    = 5;

    localparam A_READ_ADDR = 100;
    localparam A_LOAD_ADDR = 0;

    localparam TOTAL_ELEMS = act_size * act_size;

    //--------------------------------------------------------------------
    // DUT I/O
    //--------------------------------------------------------------------
    reg clk = 0;
    reg reset = 1;

    reg  [DATA_BITWIDTH-1:0] r_data_glb_iact;
    wire [ADDR_BITWIDTH_GLB-1:0] r_addr_glb_iact;
    wire read_req_glb_iact;

    wire [DATA_BITWIDTH-1:0] w_data_spad;
    wire load_en_spad;

    reg load_spad_ctrl = 0;

    //--------------------------------------------------------------------
    // Instantiate DUT
    //--------------------------------------------------------------------
    router_iact #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),

        .X_dim(X_dim),
        .Y_dim(Y_dim),
        .kernel_size(kernel_size),
        .act_size(act_size),

        .A_READ_ADDR(A_READ_ADDR),
        .A_LOAD_ADDR(A_LOAD_ADDR)
    ) dut (
        .clk(clk),
        .reset(reset),

        .r_data_glb_iact(r_data_glb_iact),
        .r_addr_glb_iact(r_addr_glb_iact),
        .read_req_glb_iact(read_req_glb_iact),

        .w_data_spad(w_data_spad),
        .load_en_spad(load_en_spad),

        .load_spad_ctrl(load_spad_ctrl)
    );

    //--------------------------------------------------------------------
    // Clock
    //--------------------------------------------------------------------
    always #5 clk = ~clk;  // 100 MHz

    //--------------------------------------------------------------------
    // Storage for checking expected output
    //--------------------------------------------------------------------
    reg [DATA_BITWIDTH-1:0] expected_values [0:TOTAL_ELEMS-1];
    reg [DATA_BITWIDTH-1:0] spad_received   [0:TOTAL_ELEMS-1];

    integer write_index;
    integer idx;

    always @(*) begin
        integer idx2;
        if (read_req_glb_iact) begin
            idx2 = r_addr_glb_iact - A_READ_ADDR;
            if (idx2 >= 0 && idx2 < TOTAL_ELEMS)
                r_data_glb_iact = expected_values[idx2];
            else
                r_data_glb_iact = 16'hBEEF;
        end else begin
            r_data_glb_iact = 16'h0000;
        end
    end


    //--------------------------------------------------------------------
    // Task: run a complete test sequence for one "direction"
    // (just for coverage; router_iact itself ignores direction)
    //--------------------------------------------------------------------
    task automatic run_direction_test(input [127:0] dir_name);
        integer i;
    begin
        $display("===============================================");
        $display("   TESTING DIRECTION: %0s", dir_name);
        $display("===============================================");

        // Prepare burst data
        for (i = 0; i < TOTAL_ELEMS; i = i + 1)
            expected_values[i] = 16'h1000 + i;

        write_index = 0;

        // Reset
        reset = 1; repeat(3) @(posedge clk);
        reset = 0; repeat(3) @(posedge clk);

        //----------------------------------------------------------
        // Generate 1-cycle load pulse
        //----------------------------------------------------------
        @(posedge clk);
        load_spad_ctrl = 1;
        @(posedge clk);
        load_spad_ctrl = 0;

        //----------------------------------------------------------
        // Collect SPAD writes
        //----------------------------------------------------------
        while (write_index < TOTAL_ELEMS) begin
            @(posedge clk);

            if (load_en_spad) begin
                spad_received[write_index] = w_data_spad;

                if (w_data_spad !== expected_values[write_index]) begin
                    $display("❌ ERROR at index %0d: expected %h, got %h",
                             write_index, expected_values[write_index], w_data_spad);
                    $finish;
                end

                write_index = write_index + 1;
            end
        end

        $display("✔ Direction %0s PASSED (%0d values OK)", dir_name, TOTAL_ELEMS);
    end
    endtask

    //--------------------------------------------------------------------
    // Main Test Driver
    //--------------------------------------------------------------------
    initial begin
        #20;

        run_direction_test("NORTH");
        run_direction_test("SOUTH");
        run_direction_test("WEST");
        run_direction_test("EAST");

        $display("\n===============================================");
        $display("   ALL DIRECTION TESTS PASSED SUCCESSFULLY! 🎉");
        $display("===============================================");
        $finish;
    end

endmodule

