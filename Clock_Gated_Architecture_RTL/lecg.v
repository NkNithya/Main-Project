module lecg (
    input  wire clk,   // base clock
    input  wire en,    // enable
    output wire gclk   // gated clock
);

    wire en_latched;

    // Latch samples EN when CLK is LOW
    level_latch u_latch (
        .d  (en),
        .en (~clk),        // latch open when clk = 0
        .q  (en_latched)
    );

    // AND gate for clock gating
    and u_and1 (gclk, clk, en_latched);

endmodule

module level_latch (
    input  d,
    input  en,
    output q
);
    wire nd;
    wire a1, a2;

    not  u0 (nd, d);
    and  u1 (a1, d,  en);
    and  u2 (a2, q, ~en);
    or   u3 (q,  a1, a2);

endmodule

/*
module level_latch (
    input  wire d,
    input  wire en,   // latch enable
    output reg  q
);
    always @(d or en) begin
        if (en)
            q = d;
    end
endmodule
*/
