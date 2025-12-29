module MAC #(
    parameter IN_BITWIDTH = 16,
    parameter OUT_BITWIDTH = 16
)(
    input clk,
    input reset,
    input en,
    input [IN_BITWIDTH-1:0] a_in,
    input [IN_BITWIDTH-1:0] w_in,
    input [OUT_BITWIDTH-1:0] sum_in,
    output reg [OUT_BITWIDTH-1:0] out
);

always @(posedge clk) begin
    if (reset)
        out <= {OUT_BITWIDTH{1'b0}};
    else if (en)
        out <= (a_in * w_in) + sum_in;
end

endmodule

