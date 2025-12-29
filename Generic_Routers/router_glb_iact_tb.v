`timescale 1ns/1ps

module glb_router_iact_tb;

    localparam ADDR_BITWIDTH_GLB = 8;
    localparam ACT_SIZE          = 5;
    localparam A_READ_ADDR       = 8'd10;

    // ---------------- Clock ----------------
    reg clk = 0;
    always #5 clk = ~clk;

    // ---------------- Control ----------------
    reg reset;
    reg [3:0] router_mode;

    // ---------------- Router <-> GLB ----------------
    wire [ADDR_BITWIDTH_GLB-1:0] glb_addr_read;
    wire                         glb_req_read;

    integer req_cnt;
    integer timeout;
    reg [ADDR_BITWIDTH_GLB-1:0] last_addr;
    reg first_seen;

    // =====================================================
    // DUT
    // =====================================================
    router_iact_generic #(
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .act_size(ACT_SIZE),
        .A_READ_ADDR(A_READ_ADDR)
    ) dut_router (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),
        .glb_addr_read(glb_addr_read),
        .glb_req_read(glb_req_read),
        .glb_rdata('0),
        .north_data_i('0), .north_enable_i(1'b0),
        .south_data_i('0), .south_enable_i(1'b0),
        .west_data_i ('0), .west_enable_i (1'b0),
        .east_data_i ('0), .east_enable_i (1'b0),
        .local_data_o(),
        .local_enable_o()
    );

    // =====================================================
    // Logging (cycle-level visibility)
    // =====================================================
    always @(posedge clk) begin
        if (!reset) begin
            $display(
                "[T=%0t] mode=%0d req=%0b addr=%0d",
                $time, router_mode, glb_req_read, glb_addr_read
            );
        end
    end

    // =====================================================
    // Test
    // =====================================================
    initial begin
        $display("=== IA ROUTER TRUE FINAL TB ===");

        // ---------------- Reset + IDLE ----------------
        reset = 1'b1;
        router_mode = 4'd0;
        repeat (3) @(posedge clk);

        // ---------------- Release reset ----------------
        reset = 1'b0;
        @(posedge clk);

        // ---------------- Enter LOAD ----------------
        $display("[TB] Entering LOAD mode");
        router_mode = 4'd1;

        req_cnt    = 0;
        timeout    = 0;
        first_seen = 0;

        while (req_cnt < ACT_SIZE) begin
            @(posedge clk);
            timeout = timeout + 1;

            if (glb_req_read) begin
                if (!first_seen) begin
                    // First observed address
                    $display(
                        "[REQ %0d] FIRST addr=%0d",
                        req_cnt, glb_addr_read
                    );

                    if (glb_addr_read !== A_READ_ADDR) begin
                        $fatal(1,
                            "[ADDR ERROR] first exp=%0d got=%0d",
                            A_READ_ADDR, glb_addr_read
                        );
                    end

                    last_addr  = glb_addr_read;
                    first_seen = 1;
                    req_cnt    = 1;
                end
                else if (glb_addr_read !== last_addr) begin
                    // Address advanced → new request
                    $display(
                        "[REQ %0d] ADV addr=%0d",
                        req_cnt, glb_addr_read
                    );

                    if (glb_addr_read !== (A_READ_ADDR + req_cnt)) begin
                        $fatal(1,
                            "[ADDR ERROR] req=%0d exp=%0d got=%0d",
                            req_cnt, A_READ_ADDR + req_cnt, glb_addr_read
                        );
                    end

                    last_addr = glb_addr_read;
                    req_cnt   = req_cnt + 1;
                end
                else begin
                    // Address hold
                    $display(
                        "[HOLD   ] addr=%0d",
                        glb_addr_read
                    );
                end
            end

            if (timeout > 100) begin
                $fatal(1, "[TIMEOUT] LOAD did not complete");
            end
        end

        $display("PASS: IA router address sequencing verified (robust)");
        $finish;
    end

endmodule

