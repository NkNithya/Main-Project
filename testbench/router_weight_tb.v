`timescale 1ns/1ps

module router_weight_tb;

    //--------------------------------------------------------------------
    // Parameters (match DUT)
    //--------------------------------------------------------------------
    localparam DATA_BITWIDTH      = 16;
    localparam ADDR_BITWIDTH_GLB  = 10;
    localparam ADDR_BITWIDTH_SPAD = 9;

    localparam X_dim       = 5;
    localparam Y_dim       = 3;
    localparam kernel_size = 3;    // 3x3 weight kernel
    localparam act_size    = 5;    // unused in router_weight

    localparam W_READ_ADDR = 200;  // arbitrary
    localparam W_LOAD_ADDR = 0;

    localparam TOTAL_WEIGHTS = kernel_size * kernel_size;

    //--------------------------------------------------------------------
    // DUT signals
    //--------------------------------------------------------------------
    reg  clk = 0;
    reg  reset = 1;

    reg  [DATA_BITWIDTH-1:0] r_data_glb_wght;
    wire [ADDR_BITWIDTH_GLB-1:0] r_addr_glb_wght;
    wire read_req_glb_wght;

    wire [DATA_BITWIDTH-1:0] w_data_spad;
    wire load_en_spad;

    reg load_spad_ctrl = 0;

    //--------------------------------------------------------------------
    // Instantiate DUT
    //--------------------------------------------------------------------
    router_weight #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),

        .X_dim(X_dim),
        .Y_dim(Y_dim),
        .kernel_size(kernel_size),
        .act_size(act_size),

        .W_READ_ADDR(W_READ_ADDR),
        .W_LOAD_ADDR(W_LOAD_ADDR)
    ) dut (
        .clk(clk),
        .reset(reset),

        .r_data_glb_wght(r_data_glb_wght),
        .r_addr_glb_wght(r_addr_glb_wght),
        .read_req_glb_wght(read_req_glb_wght),

        .w_data_spad(w_data_spad),
        .load_en_spad(load_en_spad),

        .load_spad_ctrl(load_spad_ctrl)
    );

    //--------------------------------------------------------------------
    // Clock generator
    //--------------------------------------------------------------------
    always #5 clk = ~clk; // 100MHz

    //--------------------------------------------------------------------
    // Storage for expected and received values
    //--------------------------------------------------------------------
    reg [DATA_BITWIDTH-1:0] expected_values [0:TOTAL_WEIGHTS-1];
    reg [DATA_BITWIDTH-1:0] received_values [0:TOTAL_WEIGHTS-1];

    integer write_index;
    integer idx;

    //--------------------------------------------------------------------
    // Combinational GLB model (router_weight expects this)
    //--------------------------------------------------------------------
    always @(*) begin
        if (read_req_glb_wght) begin
            idx = r_addr_glb_wght - W_READ_ADDR;
            if (idx >= 0 && idx < TOTAL_WEIGHTS)
                r_data_glb_wght = expected_values[idx];
            else
                r_data_glb_wght = 16'hDEAD;
        end else begin
            r_data_glb_wght = 16'h0000;
        end
    end

    //--------------------------------------------------------------------
    // Self-checking test sequence
    //--------------------------------------------------------------------
    initial begin : TEST_SEQUENCE
        integer i;

        $display("\n===============================================");
        $display("   router_weight SELF-CHECKING TEST STARTED");
        $display("===============================================\n");

        //----------------------------------------------------------
        // Prepare expected weight burst: 9 values for 3x3 kernel
        //----------------------------------------------------------
        for (i = 0; i < TOTAL_WEIGHTS; i = i + 1)
            expected_values[i] = 16'h5000 + i;  // unique pattern

        //----------------------------------------------------------
        // Reset
        //----------------------------------------------------------
        reset = 1;
        repeat(3) @(posedge clk);
        reset = 0;
        repeat(2) @(posedge clk);

        //----------------------------------------------------------
        // Trigger one-cycle load pulse
        //----------------------------------------------------------
        @(posedge clk);
        load_spad_ctrl = 1;
        @(posedge clk);
        load_spad_ctrl = 0;

        //----------------------------------------------------------
        // Collect SPAD writes
        //----------------------------------------------------------
        write_index = 0;

        while (write_index < TOTAL_WEIGHTS) begin
            @(posedge clk);

            if (load_en_spad) begin
                received_values[write_index] = w_data_spad;

                // Check value
                if (w_data_spad !== expected_values[write_index]) begin
                    $display("❌ ERROR: At index %0d: expected %h, got %h",
                             write_index, expected_values[write_index], w_data_spad);
                    $finish;
                end

                write_index = write_index + 1;
            end
        end

        //----------------------------------------------------------
        // PASS
        //----------------------------------------------------------
        $display("✔ router_weight PASSED — all %0d weights correct!", TOTAL_WEIGHTS);

        $display("\n===============================================");
        $display("   SELF-CHECK PASSED SUCCESSFULLY! 🎉");
        $display("===============================================\n");

        $finish;
    end

endmodule

