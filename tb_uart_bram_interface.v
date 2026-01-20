`timescale 1ns/1ps
module tb_uart_bram_interface;
    localparam CLK_FREQ = 50_000_000;
    localparam BAUD_RATE = 115200;
    localparam BIT_PERIOD = 1_000_000_000 / BAUD_RATE; // ns

    reg clk = 0;
    reg reset = 0;
    reg uart_rx = 1;
    wire uart_tx;

    uart_bram_interface #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .rx(uart_rx),
        .tx(uart_tx)
    );

    always #10 clk = ~clk; // 50 MHz

    // send byte with UART framing
    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            uart_rx <= 0; #(BIT_PERIOD); // start
            for (i=0;i<8;i=i+1) begin
                uart_rx <= data[i];
                #(BIT_PERIOD);
            end
            uart_rx <= 1; #(BIT_PERIOD); // stop
            #(BIT_PERIOD*2);
        end
    endtask

    // read a byte from TX line
    task uart_read_byte(output [7:0] data);
        integer i;
        begin
            @(negedge uart_tx); // start bit
            #(BIT_PERIOD + BIT_PERIOD/2);
            for (i=0;i<8;i=i+1) begin
                data[i] = uart_tx;
                #(BIT_PERIOD);
            end
            #(BIT_PERIOD);
            $display("[%0t ns] RXed byte = 0x%02h", $time, data);
        end
    endtask

    reg [7:0] rx_byte;

    initial begin
        $dumpfile("uart_bram_interface_tb.vcd");
        $dumpvars(0, tb_uart_bram_interface);

        reset = 1; #(100); reset = 0;
        #(BIT_PERIOD*5);

        $display("---- WRITE CMD ----");
        uart_send_byte(8'hAA);
        uart_send_byte(8'h01);
        uart_send_byte(8'h0A);
        uart_send_byte(8'h55);
        #(BIT_PERIOD*10);

        $display("---- READ CMD ----");
        uart_send_byte(8'hAA);
        uart_send_byte(8'h02);
        uart_send_byte(8'h0A);
        uart_send_byte(8'h00);

        #(BIT_PERIOD*20);
        uart_read_byte(rx_byte);
        $display("Readback value = 0x%02h (expect 0x55)", rx_byte);

        #(BIT_PERIOD*20);
        $finish;
    end
endmodule
