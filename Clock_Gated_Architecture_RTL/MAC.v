module mac_unit #(
  parameter BW = 16
)(
  input clk,
  input valid,
  input [BW-1:0] a,
  input [BW-1:0] w,
  input [BW-1:0] sum_in,
  output reg [BW-1:0] sum_out
);

  always @(posedge clk) begin
    if (valid)
      sum_out <= sum_in + a * w;
  end

endmodule

