`timescale 1ns / 1ps

// ============================================================================
// ECG : Event-Controlled Clock Gating
// ============================================================================

module ECG #(
    parameter IN_BITWIDTH = 16
)(
    input  wire [IN_BITWIDTH-1:0] a_in,
    input  wire [IN_BITWIDTH-1:0] w_in,
    input  wire [IN_BITWIDTH-1:0] sum_in,
    input  wire                   en,
    input                     clk,
    input  wire                   reset,
    output wire                   gated_clk	
);

    // Previous-value registers
    wire [IN_BITWIDTH-1:0] a_ff, w_ff, sum_ff;

    d_ff #(IN_BITWIDTH) dff_a (clk, reset, a_in,   a_ff);
    d_ff #(IN_BITWIDTH) dff_w (clk, reset, w_in,   w_ff);
    d_ff #(IN_BITWIDTH) dff_s (clk, reset, sum_in, sum_ff);

    // Bitwise XOR using bus_xor primitives
    wire [IN_BITWIDTH-1:0] a_x, w_x, s_x;

    bus_xor #(IN_BITWIDTH) xor_a (a_in,   a_ff,   a_x);
    bus_xor #(IN_BITWIDTH) xor_w (w_in,   w_ff,   w_x);
    bus_xor #(IN_BITWIDTH) xor_s (sum_in, sum_ff, s_x);

    // OR-reduce buses using structural OR trees
    wire a_chg, w_chg, s_chg;

    bus_or_reduce #(IN_BITWIDTH) red_a (a_x, a_chg);
    bus_or_reduce #(IN_BITWIDTH) red_w (w_x, w_chg);
    bus_or_reduce #(IN_BITWIDTH) red_s (s_x, s_chg);


    // Combine change flags
    wire data_change;
    or (data_change, a_chg, w_chg, s_chg);


    // Gate request
    wire gate_req;
    and (gate_req, en, data_change);

    // Clock-gating latch
   	wire clk_en;

    icg_latch latch0 (
        .gate_req (gate_req),
        .clk      (clk),
        .reset    (reset),
        .clk_en   (clk_en)
    );

    // Final gated clock
    and2 and1(.a(clk), .b(clk_en), .y(gated_clk));

endmodule


module icg (
    input  clk,
    input  en,
    output gclk
);
    reg en_latched;

    always @(negedge clk)
        en_latched <= en;

    assign gclk = clk & en_latched;
endmodule

module bus_or_reduce #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] a,
    output wire             y
);
    wire [WIDTH-1:0] or_chain;

    assign or_chain[0] = a[0];

    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : OR_REDUCE
            or (or_chain[i], or_chain[i-1], a[i]);
        end
    endgenerate

    assign y = or_chain[WIDTH-1];
endmodule


module and2 (
    input  wire a,
    input  wire b,
    output wire y
);
    and (y, a, b);
endmodule

module bus_xor #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] y
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : BUS_XOR
            xor (y[i], a[i], b[i]);
        end
    endgenerate
endmodule


module and_gate 
 (
 	input reg a,
 	input  reg b,
 	output wire c
 );
 
		assign c = a & b;

 
endmodule

module icg_latch (
    input  wire gate_req,
    input  reg clk,
    input  wire reset,
    output reg  clk_en
);
    initial clk_en = 1'b1;

    always @(*) begin
        if (reset)
            clk_en = 1'b1;
        else if (clk == 1'b0)
            clk_en = gate_req;
        // else hold
    end
endmodule


module d_ff #(
    parameter WIDTH = 16
)(
    input  wire                 clk,
    input  wire                 reset,
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

