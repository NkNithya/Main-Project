`timescale 1ns/1ps
module uart_bram_interface #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 115200,
    parameter BRAM_ADDR_WIDTH = 8,
    parameter BRAM_DATA_WIDTH = 8
)(
    input  wire clk,
    input  wire reset,
    input  wire rx,
    output wire tx
);
    // -------------------------------------------------------------------------
    // UART wiring
    // -------------------------------------------------------------------------
    wire        rx_done;
    wire [7:0]  rx_data;
    wire        tx_busy;
    reg         tx_start;
    reg  [7:0]  tx_data;

    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_rx (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .data_out(rx_data),
        .done(rx_done)
    );

    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_tx (
        .clk(clk),
        .reset(reset),
        .data_in(tx_data),
        .start(tx_start),
        .busy(tx_busy),
        .tx(tx)
    );

    // -------------------------------------------------------------------------
    // Simple BRAM (behavioral)
    // -------------------------------------------------------------------------
    reg [BRAM_DATA_WIDTH-1:0] bram [0:(1<<BRAM_ADDR_WIDTH)-1];

    // -------------------------------------------------------------------------
    // Packet decoder FSM
    // -------------------------------------------------------------------------
    localparam S_IDLE = 0, S_RECV = 1, S_EXEC = 2;
    reg [1:0]  state;
    reg [7:0]  packet [0:2];  // only 3 data bytes (CMD, ADDR, DATA)
    reg [1:0]  byte_cnt;

    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= S_IDLE;
            byte_cnt  <= 0;
            tx_start  <= 0;
            tx_data   <= 0;
            for (i=0;i<(1<<BRAM_ADDR_WIDTH);i=i+1)
                bram[i] <= 0;
        end else begin
            tx_start <= 0;

            case (state)
                S_IDLE: begin
                    if (rx_done && rx_data == 8'hAA) begin
                        state    <= S_RECV;
                        byte_cnt <= 0;
                    end
                end

                S_RECV: begin
                    if (rx_done) begin
                        packet[byte_cnt] <= rx_data;
                        byte_cnt <= byte_cnt + 1;
                        if (byte_cnt == 2)
                            state <= S_EXEC;
                    end
                end

                S_EXEC: begin
                    case (packet[0])
                        8'h01: begin // WRITE
                            bram[packet[1]] <= packet[2];
                            $display("[%0t ns] WRITE addr=%0h data=%0h",
                                     $time, packet[1], packet[2]);
                            state <= S_IDLE;
                            byte_cnt <= 0;
                        end
                        8'h02: begin // READ
                            tx_data  <= bram[packet[1]];
                            if (!tx_busy) begin
                                tx_start <= 1;
                                $display("[%0t ns] READ addr=%0h -> data=%0h",
                                         $time, packet[1], bram[packet[1]]);
                                state    <= S_IDLE;
                                byte_cnt <= 0;
                            end
                        end
                        default: begin
                            state <= S_IDLE;
                            byte_cnt <= 0;
                        end
                    endcase
                end
            endcase
        end
    end
endmodule
