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
    input  wire d,
    input  wire en,   // latch enable
    output reg  q
);
    always @(d or en) begin
        if (en)
            q = d;
    end
endmodule

