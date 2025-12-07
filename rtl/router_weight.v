`timescale 1ns / 1ps

module router_weight #(
    parameter DATA_BITWIDTH      = 16,
    parameter ADDR_BITWIDTH_GLB  = 10,
    parameter ADDR_BITWIDTH_SPAD = 9,

    parameter X_dim       = 5,
    parameter Y_dim       = 3,
    parameter kernel_size = 3,
    parameter act_size    = 5,   // unused but kept for compatibility

    parameter W_READ_ADDR = 0, 
    parameter W_LOAD_ADDR = 0    // currently unused (SPAD addr handled elsewhere)
)
(
    input clk,
    input reset,

    // for reading GLB
    input  [DATA_BITWIDTH-1:0]          r_data_glb_wght,
    output reg [ADDR_BITWIDTH_GLB-1:0]  r_addr_glb_wght,
    output reg                          read_req_glb_wght,

    // for writing to SPAD
    output reg [DATA_BITWIDTH-1:0]      w_data_spad,
    output reg                          load_en_spad,

    // control: start loading weights to SPAD
    input                               load_spad_ctrl
);

    // FSM states
    reg [2:0] state;
    localparam IDLE       = 3'b000;
    localparam READ_GLB   = 3'b001;
    localparam WRITE_SPAD = 3'b010;

    // total weights in one kernel block
    localparam integer TOTAL_WEIGHTS = kernel_size * kernel_size;

    // counter for how many weights processed
    reg [5:0] filt_count;  // enough for up to 64 weights; grow if needed

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            read_req_glb_wght <= 1'b0;
            r_addr_glb_wght   <= {ADDR_BITWIDTH_GLB{1'b0}};
            load_en_spad      <= 1'b0;
            w_data_spad       <= {DATA_BITWIDTH{1'b0}};
            filt_count        <= 6'd0;
            state             <= IDLE;
        end else begin
            // default
            load_en_spad <= 1'b0;

            case (state)

                //--------------------------------------------------
                // IDLE – wait for load_spad_ctrl pulse
                //--------------------------------------------------
                IDLE: begin
                    read_req_glb_wght <= 1'b0;
                    filt_count        <= 6'd0;

                    if (load_spad_ctrl) begin
                        read_req_glb_wght <= 1'b1;
                        r_addr_glb_wght   <= W_READ_ADDR[ADDR_BITWIDTH_GLB-1:0];
                        state             <= READ_GLB;
                    end
                end

                //--------------------------------------------------
                // READ_GLB – latch GLB data into local buffer
                //--------------------------------------------------
                READ_GLB: begin
                    w_data_spad <= r_data_glb_wght;  // combinational GLB
                    state       <= WRITE_SPAD;
                end

                //--------------------------------------------------
                // WRITE_SPAD – pulse write enable, advance or finish
                //--------------------------------------------------
                WRITE_SPAD: begin
                    load_en_spad <= 1'b1;

                    if (filt_count == (TOTAL_WEIGHTS - 1)) begin
                        // last weight written
                        read_req_glb_wght <= 1'b0;
                        filt_count        <= 6'd0;
                        state             <= IDLE;
                    end else begin
                        // more weights to go
                        filt_count      <= filt_count + 6'd1;
                        r_addr_glb_wght <= r_addr_glb_wght + 1'b1;
                        state           <= READ_GLB;
                    end
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule

