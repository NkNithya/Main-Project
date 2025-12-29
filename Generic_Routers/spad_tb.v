`timescale 1ns/1ps
module SPad_ref #(
    parameter DATA_BITWIDTH = 16,
    parameter ADDR_BITWIDTH = 4
)(
    input clk,
    input reset,
    input write_en,
    input read_en,
    input [ADDR_BITWIDTH-1:0] w_addr,
    input [ADDR_BITWIDTH-1:0] r_addr,
    input [DATA_BITWIDTH-1:0] w_data,
    output reg [DATA_BITWIDTH-1:0] r_data
);
    localparam DEPTH = 1 << ADDR_BITWIDTH;
    reg [DATA_BITWIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_BITWIDTH-1:0] r_addr_q;

    integer i;
    always @(posedge clk) begin
        if (reset) begin
            r_data <= 0;
            r_addr_q <= 0;
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= 0;
        end else begin
            if (write_en)
                mem[w_addr] <= w_data;
            if (read_en)
                r_addr_q <= r_addr;
            r_data <= mem[r_addr_q];
        end
    end
endmodule

