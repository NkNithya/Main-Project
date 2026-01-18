`timescale 1ns / 1ps

`timescale 1ns / 1ps

module ECG #(
    parameter IN_BITWIDTH = 16
)(
    input  wire [IN_BITWIDTH-1:0] a_in,
    input  wire [IN_BITWIDTH-1:0] w_in,
    input  wire [IN_BITWIDTH-1:0] sum_in,
    input  wire                   en,
    input  wire                   clk,
    input  wire                   reset,
    output wire                   gated_clk
);

    // Register inputs using DFFs (previous values)
    wire [IN_BITWIDTH-1:0] a_ff;
    wire [IN_BITWIDTH-1:0] w_ff;
    wire [IN_BITWIDTH-1:0] sum_ff;

    d_ff #(IN_BITWIDTH) dff_a (
        .clk   (clk),
        .reset (reset),
        .d     (a_in),
        .q     (a_ff)
    );

    d_ff #(IN_BITWIDTH) dff_w (
        .clk   (clk),
        .reset (reset),
        .d     (w_in),
        .q     (w_ff)
    );

    d_ff #(IN_BITWIDTH) dff_sum (
        .clk   (clk),
        .reset (reset),
        .d     (sum_in),
        .q     (sum_ff)
    );

    // XOR current inputs with registered values
    wire a_xor   = |(a_in   ^ a_ff);
    wire w_xor   = |(w_in   ^ w_ff);
    wire sum_xor = |(sum_in ^ sum_ff);

    // OR all XOR outputs (any input change detected)
    wire data_change;
    assign data_change = a_xor | w_xor | sum_xor;

    // AND with external enable
    wire gate_en;
    assign gate_en = data_change & en;

    // Latch: data = clk, enable = gate_en
    wire latch_q;

    d_latch #(1) latch_0 (
        .d  (clk),
        .en (gate_en),
        .q  (latch_q)
    );

    //  Invert latch output
    wire latch_q_n;
    assign latch_q_n = ~latch_q;

    // AND inverted latch output with clk → gated clock
    assign gated_clk = clk & latch_q_n;

endmodule


module d_ff #(
    parameter WIDTH = 16
)(
    input  wire                 clk,
    input  wire                 reset,   // active-high async reset
    input  wire [WIDTH-1:0]     d,
    output reg  [WIDTH-1:0]     q
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            q <= {WIDTH{1'b0}};
        else
            q <= d;
    end

endmodule


module d_latch #(
    parameter WIDTH = 1
)(
    input  wire [WIDTH-1:0] d,
    input  wire             en,   // latch enable
    output reg  [WIDTH-1:0] q
);

    always @(*) begin
        if (en)
            q = d;
        // else: q holds previous value (implicit latch behavior)
    end

endmodule

