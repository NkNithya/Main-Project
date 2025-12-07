`timescale 1ns / 1ps

module router_psum #(
    parameter DATA_BITWIDTH      = 16,
    parameter ADDR_BITWIDTH_GLB  = 10,
    parameter ADDR_BITWIDTH_SPAD = 9,

    parameter X_dim       = 5,
    parameter Y_dim       = 3,
    parameter kernel_size = 3,
    parameter act_size    = 5,

    parameter PSUM_READ_ADDR = 0,   // unused but kept
    parameter PSUM_LOAD_ADDR = 0
)
(
    input clk,
    input reset,

    // from SPAD (wide psum vector from PE cluster)
    input  [DATA_BITWIDTH*X_dim-1 : 0] r_data_spad_psum,

    // to GLB
    output reg [ADDR_BITWIDTH_GLB-1 : 0] w_addr_glb_psum,
    output reg                          write_en_glb_psum,
    output reg [DATA_BITWIDTH-1 : 0]    w_data_glb_psum,

    // control: start writing psums to GLB
    input                               write_psum_ctrl
);

    // FSM
    reg [2:0] state;
    localparam IDLE       = 3'b000;
    localparam READ_PSUM  = 3'b001;
    localparam WRITE_GLB  = 3'b010;

    reg [4:0] psum_count;  // up to X_dim <= 32
    reg [DATA_BITWIDTH*X_dim-1 : 0] pe_psum;
    reg [2:0] iter;         // row index / block index

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            w_addr_glb_psum    <= PSUM_LOAD_ADDR[ADDR_BITWIDTH_GLB-1:0];
            w_data_glb_psum    <= {DATA_BITWIDTH{1'b0}};
            write_en_glb_psum  <= 1'b0;
            psum_count         <= 5'd0;
            pe_psum            <= {DATA_BITWIDTH*X_dim{1'b0}};
            iter               <= 3'd0;
            state              <= IDLE;
        end else begin
            // default
            write_en_glb_psum <= 1'b0;

            case (state)

                IDLE: begin
                    psum_count      <= 5'd0;
                    w_addr_glb_psum <= PSUM_LOAD_ADDR[ADDR_BITWIDTH_GLB-1:0];
                    if (write_psum_ctrl) begin
                        // capture psums next cycle
                        state <= READ_PSUM;
                    end
                end

                READ_PSUM: begin
                    // latch wide SPAD psums
                    pe_psum    <= r_data_spad_psum;
                    psum_count <= 5'd0;
                    state      <= WRITE_GLB;
                end

                WRITE_GLB: begin
                    // write one psum per cycle
                    write_en_glb_psum <= 1'b1;
                    w_data_glb_psum   <= pe_psum[(psum_count+1)*DATA_BITWIDTH-1 -: DATA_BITWIDTH];

                    if (psum_count == 0) begin
                        // starting address for this block / row
                        w_addr_glb_psum <= PSUM_LOAD_ADDR[ADDR_BITWIDTH_GLB-1:0] + iter*X_dim;
                    end else begin
                        w_addr_glb_psum <= w_addr_glb_psum + 1'b1;
                    end

                    if (psum_count == X_dim-1) begin
                        // last element written
                        psum_count <= 5'd0;
                        iter       <= iter + 3'd1;
                        state      <= IDLE;
                    end else begin
                        psum_count <= psum_count + 5'd1;
                        // stay in WRITE_GLB
                    end
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule

