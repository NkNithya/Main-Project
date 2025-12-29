`timescale 1ns / 1ps

module router_iact #(
    parameter DATA_BITWIDTH      = 16,
    parameter ADDR_BITWIDTH_GLB  = 10,
    parameter ADDR_BITWIDTH_SPAD = 9,

    parameter act_size = 5,

    parameter A_READ_ADDR = 100
)(
    input  wire clk,
    input  wire reset,

    // GLB interface
    input  wire [DATA_BITWIDTH-1:0] r_data_glb_iact,
    output reg  [ADDR_BITWIDTH_GLB-1:0] r_addr_glb_iact,
    output reg  read_req_glb_iact,

    // SPAD interface
    output reg  [DATA_BITWIDTH-1:0] w_data_spad,
    output reg  load_en_spad,

    // Control
    input  wire load_spad_ctrl
);

    /* -----------------------------
       Local parameters & registers
    ----------------------------- */
    localparam IDLE       = 2'b00;
    localparam READ_GLB   = 2'b01;
    localparam WRITE_SPAD = 2'b10;

    localparam integer ACT_COUNT = act_size * act_size;

    reg [1:0] state;
    reg [$clog2(ACT_COUNT):0] filt_count;

    /* -----------------------------
       Sequential FSM
    ----------------------------- */
    always @(posedge clk) begin
        if (reset) begin
            state             <= IDLE;
            filt_count        <= 0;
            r_addr_glb_iact   <= A_READ_ADDR;
            read_req_glb_iact <= 0;
            load_en_spad      <= 0;
            w_data_spad       <= 0;
        end else begin
            case (state)

                /* ---------------- IDLE ---------------- */
                IDLE: begin
                    read_req_glb_iact <= 0;
                    load_en_spad      <= 0;
                    filt_count        <= 0;

                    if (load_spad_ctrl) begin
                        r_addr_glb_iact   <= A_READ_ADDR;
                        read_req_glb_iact <= 1;
                        state             <= READ_GLB;
                    end
                end

                /* ---------------- READ_GLB ---------------- */
                READ_GLB: begin
                    // Issue read request
                    read_req_glb_iact <= 1;
                    load_en_spad      <= 0;

                    // Prepare next address
                    r_addr_glb_iact <= r_addr_glb_iact + 1;

                    state <= WRITE_SPAD;
                end

                /* ---------------- WRITE_SPAD ---------------- */
                WRITE_SPAD: begin
                    read_req_glb_iact <= 0;
                    load_en_spad      <= 1;

                    // Capture GLB data
                    w_data_spad <= r_data_glb_iact;

                    if (filt_count == ACT_COUNT - 1) begin
                        // Done loading
                        filt_count <= 0;
                        state      <= IDLE;
                    end else begin
                        filt_count <= filt_count + 1;
                        state      <= READ_GLB;
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule

