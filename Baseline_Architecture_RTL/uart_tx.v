`timescale 1ns/1ps
module uart_tx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire clk,
    input  wire reset,
    input  wire [7:0] data_in,
    input  wire start,
    output reg  busy,
    output reg  tx
);
    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam CTR_WIDTH = $clog2(CLKS_PER_BIT);
    reg [CTR_WIDTH-1:0] clk_cnt;
    reg [3:0] bit_idx;
    reg [9:0] shift;
    localparam IDLE=0, ACTIVE=1;
    reg state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx <= 1'b1;
            busy <= 0;
            clk_cnt <= 0;
            bit_idx <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        shift <= {1'b1, data_in, 1'b0};
                        busy <= 1;
                        state <= ACTIVE;
                        bit_idx <= 0;
                        clk_cnt <= 0;
                    end
                end
                ACTIVE: begin
                    tx <= shift[bit_idx];
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0;
                        bit_idx <= bit_idx + 1;
                        if (bit_idx == 9) begin
                            busy <= 0;
                            state <= IDLE;
                            tx <= 1'b1;
                        end
                    end else clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end
endmodule
