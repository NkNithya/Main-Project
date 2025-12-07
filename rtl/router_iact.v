`timescale 1ns / 1ps

module router_iact #(
    parameter DATA_BITWIDTH      = 16,
    parameter ADDR_BITWIDTH_GLB  = 10,
    parameter ADDR_BITWIDTH_SPAD = 9,

    parameter X_dim       = 5,
    parameter Y_dim       = 3,
    parameter kernel_size = 3,
    parameter act_size    = 5,

    parameter A_READ_ADDR = 100,
    parameter A_LOAD_ADDR = 0   // currently unused, kept for compatibility
)
(
    input clk,
    input reset,

    // for reading GLB
    input  [DATA_BITWIDTH-1:0]      r_data_glb_iact,
    output reg [ADDR_BITWIDTH_GLB-1:0] r_addr_glb_iact,
    output reg                      read_req_glb_iact,

    // for writing to SPAD
    output reg [DATA_BITWIDTH-1:0]  w_data_spad,
    output reg                      load_en_spad,

    // Input from control unit to load to SPAD
    input                           load_spad_ctrl
);

    // FSM states
    reg [2:0] state;
    localparam IDLE      = 3'b000;
    localparam READ_GLB  = 3'b001;
    localparam WRITE_SPAD= 3'b010;

    // Total number of activations to load
    localparam integer TOTAL_ELEMS = act_size * act_size;

    // Counter for how many elements have been processed
    reg [5:0] filt_count;   // 6 bits → up to 64 elems; adjust if act_size^2 > 64

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            read_req_glb_iact <= 1'b0;
            r_addr_glb_iact   <= {ADDR_BITWIDTH_GLB{1'b0}};
            load_en_spad      <= 1'b0;
            w_data_spad       <= {DATA_BITWIDTH{1'b0}};
            filt_count        <= 6'd0;
            state             <= IDLE;
        end else begin
            // default: no write to SPAD this cycle unless in WRITE_SPAD
            load_en_spad <= 1'b0;

            case (state)

                //--------------------------------------------------
                // IDLE: Wait for load_spad_ctrl to start a burst
                //--------------------------------------------------
                IDLE: begin
                    read_req_glb_iact <= 1'b0;
                    filt_count        <= 6'd0;

                    if (load_spad_ctrl) begin
                        read_req_glb_iact <= 1'b1;
                        r_addr_glb_iact   <= A_READ_ADDR[ADDR_BITWIDTH_GLB-1:0];
                        state             <= READ_GLB;
                    end
                end

                //--------------------------------------------------
                // READ_GLB: Address is already on r_addr_glb_iact
                //           r_data_glb_iact is assumed valid now
                //--------------------------------------------------
                READ_GLB: begin
                    // Capture GLB data to be written to SPAD next
                    w_data_spad <= r_data_glb_iact;
                    state       <= WRITE_SPAD;
                end

                //--------------------------------------------------
                // WRITE_SPAD: Pulse load_en_spad with current word
                //--------------------------------------------------
                WRITE_SPAD: begin
                    load_en_spad <= 1'b1;  // write current w_data_spad

                    if (filt_count == (TOTAL_ELEMS-1)) begin
                        // Last element written
                        read_req_glb_iact <= 1'b0;
                        filt_count        <= 6'd0;
                        state             <= IDLE;
                    end else begin
                        // More elements to read/write
                        filt_count      <= filt_count + 6'd1;
                        r_addr_glb_iact <= r_addr_glb_iact + 1'b1;
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

