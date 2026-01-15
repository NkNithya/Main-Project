module bias_relu #(
    parameter BW = 16
)(
    input  signed [BW-1:0] in,
    input  signed [BW-1:0] bias,
    input                  en,     // for power gating / isolation
    output        [BW-1:0] out
);
    wire signed [BW-1:0] biased;
    assign biased = in + bias;

    // ReLU with enable (when gated → output 0)
    assign out = en ? (biased[BW-1] ? {BW{1'b0}} : biased) : {BW{1'b0}};
endmodule

