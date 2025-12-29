`timescale 1ns / 1ps

module SPad #(
    parameter DATA_BITWIDTH = 16,
    parameter ADDR_BITWIDTH = 9
)(
    input  clk,
    input  reset,
    input  read_req,
    input  write_en,
    input  [ADDR_BITWIDTH-1:0] r_addr,
    input  [ADDR_BITWIDTH-1:0] w_addr,
    input  [DATA_BITWIDTH-1:0] w_data,
    output reg [DATA_BITWIDTH-1:0] r_data
);

    // Memory array
    reg [DATA_BITWIDTH-1:0] mem [0:(1<<ADDR_BITWIDTH)-1];

    // ---------------- READ ----------------
    // Synchronous read
    always @(posedge clk) begin
        if (reset) begin
            r_data <= {DATA_BITWIDTH{1'b0}};
        end else if (read_req) begin
            r_data <= mem[r_addr];
        end else
        	r_data <= mem[r_addr];
        // else: HOLD last value (DO NOTHING)
    end

    // ---------------- WRITE ----------------
    always @(posedge clk) begin
        if (!reset && write_en) begin
            mem[w_addr] <= w_data;
        end
    end

endmodule

