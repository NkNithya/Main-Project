`timescale 1ns / 1ps

module router_psum #(
    parameter DATA_BITWIDTH = 16,
    parameter ADDR_BITWIDTH_GLB = 10,
    parameter ADDR_BITWIDTH_SPAD = 9,

    parameter X_dim = 5,
    parameter Y_dim = 3,
    parameter kernel_size = 3,
    parameter act_size = 5,

    parameter PSUM_READ_ADDR = 0,
    parameter PSUM_LOAD_ADDR = 0
)(
    input  clk,
    input  reset,

    // Incoming PSUM vector
    input  [DATA_BITWIDTH*X_dim-1:0] r_data_spad_psum,

    // GLB write interface
    output reg [ADDR_BITWIDTH_GLB-1:0] w_addr_glb_psum,
    output reg                         write_en_glb_psum,
    output reg [DATA_BITWIDTH-1:0]     w_data_glb_psum,

    // Valid pulse
    input  write_psum_ctrl
);

    // -------------------------------------------------
    // Constants
    // -------------------------------------------------
    localparam TILE_ACCUMS = kernel_size * kernel_size * act_size;

    // -------------------------------------------------
    // Internal registers
    // -------------------------------------------------
    reg [DATA_BITWIDTH*X_dim-1:0] psum_accum;

    // Safe counter widths
    reg [$clog2(TILE_ACCUMS+1)-1:0] accum_count;
    reg [$clog2(X_dim+1)-1:0]       write_count;

    // FSM
    reg state;
    localparam ACCUMULATE = 1'b0;
    localparam WRITE_GLB  = 1'b1;

    // -------------------------------------------------
    // Sequential logic
    // -------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            psum_accum        <= 0;
            accum_count       <= 0;
            write_count       <= 0;
            w_addr_glb_psum   <= PSUM_LOAD_ADDR;
            write_en_glb_psum <= 0;
            w_data_glb_psum   <= 0;
            state             <= ACCUMULATE;
        end else begin
            case (state)

                // -------------------------------------
                // ACCUMULATION
                // -------------------------------------
                ACCUMULATE: begin
                    write_en_glb_psum <= 0;

                    if (write_psum_ctrl) begin
                        psum_accum <= psum_accum + r_data_spad_psum;

                        if (accum_count == TILE_ACCUMS-1) begin
                            accum_count     <= accum_count; // stop
                            write_count     <= 0;
                            w_addr_glb_psum <= PSUM_LOAD_ADDR;
                            state           <= WRITE_GLB;
                        end else begin
                            accum_count <= accum_count + 1;
                        end
                    end
                end

                // -------------------------------------
                // WRITEBACK
                // -------------------------------------
                WRITE_GLB: begin
                    write_en_glb_psum <= 1;

                    w_data_glb_psum <=
                        psum_accum[(write_count+1)*DATA_BITWIDTH-1 -: DATA_BITWIDTH];

                    if (write_count == X_dim-1) begin
                        write_en_glb_psum <= 0;
                        psum_accum        <= 0;
                        accum_count       <= 0;
                        write_count       <= 0;
                        w_addr_glb_psum   <= PSUM_LOAD_ADDR;
                        state             <= ACCUMULATE;
                    end else begin
                        write_count     <= write_count + 1;
                        w_addr_glb_psum <= w_addr_glb_psum + 1;
                    end
                end

            endcase
        end
    end

endmodule

