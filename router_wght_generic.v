`timescale 1ns / 1ps

module router_weight_full_generic #(
    // ---------------- Data ----------------
    parameter DATA_BITWIDTH       = 16,
    parameter ADDR_BITWIDTH_GLB   = 10,
    parameter ADDR_BITWIDTH_SPAD  = 9,

    // ---------------- CNN -----------------
    parameter kernel_size         = 3,
    parameter W_READ_ADDR         = 0,

    // ---------------- Role ----------------
    parameter HAS_GLB             = 0,   // exactly ONE router must set this
    parameter INJECT_DIR          = 3,   // 0:N, 1:S, 2:W, 3:E

    // ---------------- Topology ------------
    parameter HAS_NORTH = 1,
    parameter HAS_SOUTH = 1,
    parameter HAS_WEST  = 1,
    parameter HAS_EAST  = 1
)(
    input clk,
    input reset,
    input [3:0] router_mode,

    // ---------------- GLB -----------------
    output reg  [ADDR_BITWIDTH_GLB-1:0] glb_addr_read,
    output reg                          glb_req_read,
    input       [DATA_BITWIDTH-1:0]     glb_rdata,

    // ---------------- Mesh Inputs ---------
    input  [DATA_BITWIDTH-1:0] north_data_i,
    input                       north_enable_i,
    input  [DATA_BITWIDTH-1:0] south_data_i,
    input                       south_enable_i,
    input  [DATA_BITWIDTH-1:0] west_data_i,
    input                       west_enable_i,
    input  [DATA_BITWIDTH-1:0] east_data_i,
    input                       east_enable_i,

    // ---------------- Mesh Outputs --------
    output reg [DATA_BITWIDTH-1:0] north_data_o,
    output reg                      north_enable_o,
    output reg [DATA_BITWIDTH-1:0] south_data_o,
    output reg                      south_enable_o,
    output reg [DATA_BITWIDTH-1:0] west_data_o,
    output reg                      west_enable_o,
    output reg [DATA_BITWIDTH-1:0] east_data_o,
    output reg                      east_enable_o,

    // ---------------- Local SPAD ----------
    output reg [DATA_BITWIDTH-1:0] spad_data_o,
    output reg                      spad_en_o
);

    // ---------------- Modes ----------------
    localparam MODE_IDLE = 4'd0;
    localparam MODE_LOAD = 4'd1;

    localparam TOTAL_W = kernel_size * kernel_size;

    // ---------------- GLB FSM ----------------
    localparam GLB_IDLE = 2'd0;
    localparam GLB_REQ  = 2'd1;
    localparam GLB_WAIT = 2'd2;
    localparam GLB_DATA = 2'd3;

    reg [1:0] glb_state;
    reg [ADDR_BITWIDTH_GLB-1:0] load_idx;

    // registered GLB data
    reg [DATA_BITWIDTH-1:0] glb_rdata_q;
    reg glb_data_valid_q;

    wire glb_active;
    wire inj_valid;
    wire [DATA_BITWIDTH-1:0] inj_data;

    assign glb_active = HAS_GLB && (router_mode == MODE_LOAD);

    // ---------------- GLB FSM (FINAL, CORRECT) ----------------
    always @(posedge clk) begin
        if (reset) begin
            glb_state        <= GLB_IDLE;
            glb_req_read     <= 0;
            glb_addr_read    <= W_READ_ADDR;
            load_idx         <= 0;
            glb_rdata_q      <= '0;
            glb_data_valid_q <= 0;
        end else begin
            glb_req_read     <= 0;
            glb_data_valid_q <= 0;

            case (glb_state)

                GLB_IDLE: begin
                    if (glb_active && load_idx < TOTAL_W)
                        glb_state <= GLB_REQ;
                end

                GLB_REQ: begin
                    glb_req_read  <= 1;
                    glb_addr_read <= W_READ_ADDR + load_idx;
                    glb_state     <= GLB_WAIT;
                end

                GLB_WAIT: begin
                    // wait one full cycle for synchronous GLB
                    glb_state <= GLB_DATA;
                end

                GLB_DATA: begin
                    // GLB data is now valid
                    glb_rdata_q      <= glb_rdata;
                    glb_data_valid_q <= 1;
                    load_idx         <= load_idx + 1;
                    glb_state        <= GLB_IDLE;
                end

            endcase
        end
    end

    // ---------------- Injection Select ----------------
    // GLB load is EXCLUSIVE with mesh injection
    assign inj_valid =
        glb_active ? glb_data_valid_q :
        north_enable_i |
        south_enable_i |
        west_enable_i  |
        east_enable_i;

    assign inj_data =
        glb_active ? glb_rdata_q :
        north_enable_i ? north_data_i :
        south_enable_i ? south_data_i :
        west_enable_i  ? west_data_i  :
        east_data_i;

    // ---------------- Routing Core ----------------
    always @(*) begin
        // defaults
        north_enable_o = 0;
        south_enable_o = 0;
        west_enable_o  = 0;
        east_enable_o  = 0;
        spad_en_o      = 0;

        north_data_o = inj_data;
        south_data_o = inj_data;
        west_data_o  = inj_data;
        east_data_o  = inj_data;
        spad_data_o  = inj_data;

        if (inj_valid && router_mode != MODE_IDLE) begin
            spad_en_o = 1;

            case (INJECT_DIR)
                0: if (HAS_NORTH) north_enable_o = 1;
                1: if (HAS_SOUTH) south_enable_o = 1;
                2: if (HAS_WEST)  west_enable_o  = 1;
                3: if (HAS_EAST)  east_enable_o  = 1;
            endcase
        end
    end

    // ---------------- Safety ----------------
    initial begin
        if (HAS_GLB && (INJECT_DIR > 3)) begin
            $fatal(1, "router_weight_full_generic: invalid INJECT_DIR");
        end
    end

endmodule

