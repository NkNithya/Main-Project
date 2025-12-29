`timescale 1ns/1ps

module router_iact_generic #(
    parameter DATA_BITWIDTH     = 16,
    parameter ADDR_BITWIDTH_GLB = 10,

    parameter act_size    = 5,
    parameter A_READ_ADDR = 0,

    // topology (kept for compatibility / agnosticism)
    parameter HAS_NORTH = 1,
    parameter HAS_SOUTH = 1,
    parameter HAS_WEST  = 1,
    parameter HAS_EAST  = 1
)(
    input  wire clk,
    input  wire reset,
    input  wire [3:0] router_mode,

    // ---------- GLB Interface ----------
    output reg  [ADDR_BITWIDTH_GLB-1:0] glb_addr_read,
    output reg                          glb_req_read,
    input  wire [DATA_BITWIDTH-1:0]     glb_rdata,

    // ---------- Mesh Inputs (unused for IA) ----------
    input  wire [DATA_BITWIDTH-1:0] north_data_i,
    input  wire north_enable_i,
    input  wire [DATA_BITWIDTH-1:0] south_data_i,
    input  wire south_enable_i,
    input  wire [DATA_BITWIDTH-1:0] west_data_i,
    input  wire west_enable_i,
    input  wire [DATA_BITWIDTH-1:0] east_data_i,
    input  wire east_enable_i,

    // ---------- Local Output ----------
    output reg  [DATA_BITWIDTH-1:0] local_data_o,
    output reg                      local_enable_o
);

    // ---------------- Modes ----------------
    localparam MODE_IDLE = 4'd0;
    localparam MODE_LOAD = 4'd1;

    // ---------------- State ----------------
    reg [$clog2(act_size):0] act_cnt;
    reg [3:0]                router_mode_d;

    reg [DATA_BITWIDTH-1:0] iact_reg;
    reg                     iact_valid;

    // =====================================================
    // MODE REGISTER (detect transitions)
    // =====================================================
    always @(posedge clk) begin
        if (reset)
            router_mode_d <= MODE_IDLE;
        else
            router_mode_d <= router_mode;
    end

    // =====================================================
    // COUNTER (RESET ONLY ON MODE ENTRY)
    // =====================================================
    always @(posedge clk) begin
        if (reset) begin
            act_cnt <= 0;
        end
        else begin
            // reset counter ONLY when entering LOAD
            if (router_mode == MODE_LOAD && router_mode_d != MODE_LOAD) begin
                act_cnt <= 0;
            end
            else if (router_mode == MODE_LOAD && act_cnt < act_size) begin
                act_cnt <= act_cnt + 1'b1;
            end
        end
    end

    // =====================================================
    // GLB REQUEST / ADDRESS
    // =====================================================
    always @(posedge clk) begin
        if (reset) begin
            glb_req_read  <= 1'b0;
            glb_addr_read <= A_READ_ADDR;
        end
        else begin
            glb_req_read <= 1'b0;

            if (router_mode == MODE_LOAD && act_cnt < act_size) begin
                glb_req_read  <= 1'b1;
                glb_addr_read <= A_READ_ADDR + act_cnt;
            end
        end
    end

    // =====================================================
    // GLB DATA CAPTURE (SAME-CYCLE, REQ-GATED)
    // =====================================================
    always @(posedge clk) begin
        if (reset) begin
            iact_reg   <= '0;
            iact_valid <= 1'b0;
        end
        else begin
            iact_valid <= 1'b0;

            if (glb_req_read) begin
                iact_reg   <= glb_rdata;
                iact_valid <= 1'b1;
            end
        end
    end

    // =====================================================
    // LOCAL CONSUME (STREAMING IA)
    // =====================================================
    always @(posedge clk) begin
        if (reset) begin
            local_data_o   <= '0;
            local_enable_o <= 1'b0;
        end
        else begin
            local_enable_o <= 1'b0;

            if (iact_valid) begin
                local_data_o   <= iact_reg;
                local_enable_o <= 1'b1;
            end
        end
    end

endmodule

