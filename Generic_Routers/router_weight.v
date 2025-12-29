`timescale 1ns / 1ps

module router_weight #(
    parameter DATA_BITWIDTH = 16,
    parameter kernel_size   = 3
)(
    input clk,
    input reset,

    // -------- Kernel control --------
    input  kernel_start_i,     // pulse to start a new kernel
    output reg kernel_done_o,  // pulse when kernel fully loaded

    // -------- Stream input --------
    input  [DATA_BITWIDTH-1:0] data_i,
    input  data_valid_i,

    // -------- SPAD interface --------
    output reg [DATA_BITWIDTH-1:0] spad_data_o,
    output reg spad_en_o
);

    localparam KERNEL_ELEMS = kernel_size * kernel_size;

    // counter width safe for Verilog-2001
    reg [$clog2(KERNEL_ELEMS):0] count;

    always @(posedge clk) begin
        if (reset || kernel_start_i) begin
            count         <= 0;
            spad_en_o     <= 1'b0;
            spad_data_o   <= {DATA_BITWIDTH{1'b0}};
            kernel_done_o <= 1'b0;
        end else begin
            spad_en_o     <= 1'b0;
            kernel_done_o <= 1'b0;

            if (data_valid_i && count < KERNEL_ELEMS) begin
                spad_data_o <= data_i;
                spad_en_o   <= 1'b1;
                count       <= count + 1'b1;

                if (count == KERNEL_ELEMS-1)
                    kernel_done_o <= 1'b1;
            end
        end
    end

endmodule

