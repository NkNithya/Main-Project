`timescale 1ns / 1ps

module PE_cluster_new #(
    parameter DATA_BITWIDTH = 16,
    parameter ADDR_BITWIDTH = 9,

    parameter X_dim = 3,
    parameter kernel_size = 3,
    parameter act_size    = 5,

    parameter W_READ_ADDR = 0,
    parameter A_READ_ADDR = 100,
    parameter W_LOAD_ADDR = 0,
    parameter A_LOAD_ADDR = 100
)(
    input clk,
    input reset,

    input [DATA_BITWIDTH-1:0] act_in,
    input [DATA_BITWIDTH-1:0] filt_in,

    input load_en_wght,
    input load_en_act,
    input start,

    input [DATA_BITWIDTH*X_dim-1:0] pe_before,

    output reg [DATA_BITWIDTH*X_dim-1:0] pe_out,
    output reg compute_done,
    output wire load_done
);

    // -------------------------------------------------
    // PE instances
    // -------------------------------------------------
    wire [DATA_BITWIDTH-1:0] pe_partial [0:X_dim-1];
    wire pe_done [0:X_dim-1];
    reg  pe_start [0:X_dim-1];

    // 🔧 NEW: dynamic activation base (ky dependent)
    reg [ADDR_BITWIDTH-1:0] a_read_base;

    genvar i;
    generate
        for (i = 0; i < X_dim; i = i + 1) begin : GEN_PE
            PE_new #(
                .DATA_BITWIDTH(DATA_BITWIDTH),
                .ADDR_BITWIDTH(ADDR_BITWIDTH),
                .kernel_size(kernel_size),
                .act_size(act_size),
                .W_READ_ADDR(W_READ_ADDR),
                .A_READ_ADDR(a_read_base + i),   // 🔧 FIX HERE
                .W_LOAD_ADDR(W_LOAD_ADDR),
                .A_LOAD_ADDR(A_LOAD_ADDR)
            ) pe (
                .clk(clk),
                .reset(reset),
                .act_in(act_in),
                .filt_in(filt_in),
                .load_en_wght(load_en_wght),
                .load_en_act(load_en_act),
                .start(pe_start[i]),
                .pe_out(pe_partial[i]),
                .compute_done(pe_done[i]),
                .load_done(load_done)
            );
        end
    endgenerate

    // -------------------------------------------------
    // Reduce pe_done[] (unpacked array)
    // -------------------------------------------------
    reg all_pe_done;
    integer d;

    always @(*) begin
        all_pe_done = 1'b1;
        for (d = 0; d < X_dim; d = d + 1)
            all_pe_done = all_pe_done & pe_done[d];
    end

    // -------------------------------------------------
    // Cluster controller FSM
    // -------------------------------------------------
    localparam IDLE      = 3'd0,
               START_ROW = 3'd1,
               WAIT_ROW  = 3'd2,
               ACCUM     = 3'd3,
               NEXT_ROW  = 3'd4,
               DONE      = 3'd5;

    reg [2:0] state;
    reg [$clog2(kernel_size)-1:0] ky;

    integer k;

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            ky <= 0;
            compute_done <= 0;
            a_read_base <= A_READ_ADDR;
            for (k = 0; k < X_dim; k = k + 1)
                pe_out[k*DATA_BITWIDTH +: DATA_BITWIDTH] <= 0;
        end else begin
            compute_done <= 0;

            // default: no PE starts
            for (k = 0; k < X_dim; k = k + 1)
                pe_start[k] <= 0;

            case (state)

            IDLE: begin
                if (start) begin
                    ky <= 0;
                    a_read_base <= A_READ_ADDR; // ky = 0
                    for (k = 0; k < X_dim; k = k + 1)
                        pe_out[k*DATA_BITWIDTH +: DATA_BITWIDTH] <=
                            pe_before[k*DATA_BITWIDTH +: DATA_BITWIDTH];
                    state <= START_ROW;
                end
            end

            START_ROW: begin
                // 🔧 update activation base for this ky
                a_read_base <= A_READ_ADDR + ky*act_size;
                for (k = 0; k < X_dim; k = k + 1)
                    pe_start[k] <= 1;
                state <= WAIT_ROW;
            end

            WAIT_ROW: begin
                if (all_pe_done)
                    state <= ACCUM;
            end

            ACCUM: begin
                for (k = 0; k < X_dim; k = k + 1)
                    pe_out[k*DATA_BITWIDTH +: DATA_BITWIDTH] <=
                        pe_out[k*DATA_BITWIDTH +: DATA_BITWIDTH] +
                        pe_partial[k];
                state <= NEXT_ROW;
            end

            NEXT_ROW: begin
                if (ky == kernel_size-1)
                    state <= DONE;
                else begin
                    ky <= ky + 1;
                    state <= START_ROW;
                end
            end

            DONE: begin
                compute_done <= 1;
                state <= IDLE;
            end

            endcase
        end
    end

endmodule

