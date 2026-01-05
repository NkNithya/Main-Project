`timescale 1ns / 1ps

module router_psum_generic #(
    // ---------------- Data ----------------
    parameter DATA_BITWIDTH     = 16,
    parameter ADDR_BITWIDTH_GLB  = 10,
    parameter ADDR_BITWIDTH_SPAD = 9,

    // ---------------- Addressing ----------
    parameter PSUM_GLB_BASE_ADDR  = 0,
    parameter PSUM_SPAD_BASE_ADDR = 0,

    // ---------------- Forwarding ----------
    // 0 = NORTH, 1 = SOUTH, 2 = WEST, 3 = EAST
    parameter FWD_DIR = 3,

    // ---------------- Topology ------------
    parameter HAS_NORTH = 1,
    parameter HAS_SOUTH = 1,
    parameter HAS_WEST  = 1,
    parameter HAS_EAST  = 1
)(
    input  wire clk,
    input  wire reset,
    input  wire [3:0] router_mode,

    // -------- Local --------
    input  wire [DATA_BITWIDTH-1:0] local_data_i,
    input  wire                     local_enable_i,

    // -------- Inputs --------
    input  wire [DATA_BITWIDTH-1:0] north_data_i,
    input  wire                     north_enable_i,
    input  wire [DATA_BITWIDTH-1:0] south_data_i,
    input  wire                     south_enable_i,
    input  wire [DATA_BITWIDTH-1:0] west_data_i,
    input  wire                     west_enable_i,
    input  wire [DATA_BITWIDTH-1:0] east_data_i,
    input  wire                     east_enable_i,

    // -------- Outputs --------
    output reg  [DATA_BITWIDTH-1:0] north_data_o,
    output reg                      north_enable_o,
    output reg  [DATA_BITWIDTH-1:0] south_data_o,
    output reg                      south_enable_o,
    output reg  [DATA_BITWIDTH-1:0] west_data_o,
    output reg                      west_enable_o,
    output reg  [DATA_BITWIDTH-1:0] east_data_o,
    output reg                      east_enable_o,

    // -------- SPAD --------
    output reg  [DATA_BITWIDTH-1:0] spad_data_o,
    output reg                      spad_en_o,
    output reg  [ADDR_BITWIDTH_SPAD-1:0] spad_addr_o,

    // -------- GLB --------
    output reg  [DATA_BITWIDTH-1:0] glb_data_o,
    output reg                      glb_en_o,
    output reg  [ADDR_BITWIDTH_GLB-1:0] glb_addr_o
);

    // ---------------- Modes ----------------
    localparam MODE_IDLE  = 4'd0;
    localparam MODE_LOCAL = 4'd1;
    localparam MODE_FWD   = 4'd2;
    localparam MODE_DRAIN = 4'd3;

    // ---------------- Selected PSUM --------
    reg [DATA_BITWIDTH-1:0] selected_data;
    reg                     selected_valid;

    // ---------------- Address counters -----
    reg [ADDR_BITWIDTH_GLB-1:0]  glb_addr_cnt;
    reg [ADDR_BITWIDTH_SPAD-1:0] spad_addr_cnt;

    // ---------------- Arbitration ----------
    // EXACTLY SAME AS BEFORE (unchanged)
    always @(*) begin
        selected_valid = 1'b0;
        selected_data  = '0;

        if (local_enable_i) begin
            selected_valid = 1'b1;
            selected_data  = local_data_i;
        end else if (HAS_NORTH && north_enable_i) begin
            selected_valid = 1'b1;
            selected_data  = north_data_i;
        end else if (HAS_SOUTH && south_enable_i) begin
            selected_valid = 1'b1;
            selected_data  = south_data_i;
        end else if (HAS_WEST && west_enable_i) begin
            selected_valid = 1'b1;
            selected_data  = west_data_i;
        end else if (HAS_EAST && east_enable_i) begin
            selected_valid = 1'b1;
            selected_data  = east_data_i;
        end
    end

    // ---------------- Sequential logic -----
    always @(posedge clk) begin
        if (reset) begin
            north_enable_o <= 1'b0;
            south_enable_o <= 1'b0;
            west_enable_o  <= 1'b0;
            east_enable_o  <= 1'b0;
            spad_en_o      <= 1'b0;
            glb_en_o       <= 1'b0;

            glb_addr_cnt  <= PSUM_GLB_BASE_ADDR;
            spad_addr_cnt <= PSUM_SPAD_BASE_ADDR;
        end else begin
            // default one-cycle pulses
            north_enable_o <= 1'b0;
            south_enable_o <= 1'b0;
            west_enable_o  <= 1'b0;
            east_enable_o  <= 1'b0;
            spad_en_o      <= 1'b0;
            glb_en_o       <= 1'b0;

            case (router_mode)

                // -------- LOCAL → SPAD --------
                MODE_LOCAL: begin
                    if (selected_valid) begin
                        spad_en_o     <= 1'b1;
                        spad_data_o   <= selected_data;
                        spad_addr_o   <= spad_addr_cnt;
                        spad_addr_cnt <= spad_addr_cnt + 1'b1;
                    end
                end

                // -------- FORWARD → MESH (directional) --------
                MODE_FWD: begin
                    if (selected_valid) begin
                        case (FWD_DIR)
                            0: if (HAS_NORTH) begin
                                   north_enable_o <= 1'b1;
                                   north_data_o   <= selected_data;
                               end
                            1: if (HAS_SOUTH) begin
                                   south_enable_o <= 1'b1;
                                   south_data_o   <= selected_data;
                               end
                            2: if (HAS_WEST) begin
                                   west_enable_o <= 1'b1;
                                   west_data_o   <= selected_data;
                               end
                            3: if (HAS_EAST) begin
                                   east_enable_o <= 1'b1;
                                   east_data_o   <= selected_data;
                               end
                        endcase
                    end
                end

                // -------- DRAIN → GLB --------
                MODE_DRAIN: begin
                    if (selected_valid) begin
                        glb_en_o     <= 1'b1;
                        glb_data_o   <= selected_data;
                        glb_addr_o   <= glb_addr_cnt;
                        glb_addr_cnt <= glb_addr_cnt + 1'b1;
                    end
                end
            endcase
        end
    end

    // ---------------- Safety ----------------
    initial begin
        if (FWD_DIR > 3) begin
            $fatal(1, "router_psum_generic: invalid FWD_DIR");
        end
    end

endmodule

