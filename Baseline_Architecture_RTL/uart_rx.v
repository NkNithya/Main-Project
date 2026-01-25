`timescale 1ns/1ps
module uart_rx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire clk,
    input  wire reset,
    input  wire rx,
    output reg  [7:0] data_out,
    output reg  done
);
    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam CTR_WIDTH = $clog2(CLKS_PER_BIT);
    reg [CTR_WIDTH-1:0] clk_cnt;
    reg [2:0] bit_idx;
    reg [7:0] rx_shift;
    reg [1:0] state;

    localparam IDLE=0, START=1, DATA=2, STOP=3;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            done  <= 0;
            clk_cnt <= 0;
            bit_idx <= 0;
        end else begin
            done <= 0;
            case (state)
                IDLE: if (!rx) begin
                    state <= START; clk_cnt <= 0;
                end
                START: begin
                    if (clk_cnt == CLKS_PER_BIT/2) begin
                        if (!rx) begin
                            clk_cnt <= 0;
                            bit_idx <= 0;
                            state   <= DATA;
                        end else state <= IDLE;
                    end else clk_cnt <= clk_cnt + 1;
                end
                DATA: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0;
                        rx_shift[bit_idx] <= rx;
                        if (bit_idx == 7) state <= STOP;
                        else bit_idx <= bit_idx + 1;
                    end else clk_cnt <= clk_cnt + 1;
                end
                STOP: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        data_out <= rx_shift;
                        done <= 1;
                        state <= IDLE;
                    end else clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end
endmodule
