`timescale 1ns / 1ps

module PE_new #(
    parameter DATA_BITWIDTH = 16,
    parameter kernel_size   = 3
)(
    input  wire clk,
    input  wire reset,
    input  wire start,

    input  wire signed [DATA_BITWIDTH-1:0] iact_data_i,
    input  wire                            iact_valid_i,

    input  wire signed [DATA_BITWIDTH-1:0] wght_data_i,
    input  wire                            wght_valid_i,

    output reg  signed [DATA_BITWIDTH-1:0] psum_o,
    output reg                             psum_valid_o
);

    localparam TOTAL_MACS = kernel_size * kernel_size;

    reg signed [DATA_BITWIDTH-1:0] acc;
    reg [$clog2(TOTAL_MACS+1)-1:0] mac_cnt;
    reg running;

    always @(posedge clk) begin
        if (reset) begin
            acc           <= 0;
            mac_cnt       <= 0;
            running       <= 0;
            psum_o        <= 0;
            psum_valid_o  <= 0;
        end else begin
            psum_valid_o <= 0;

            if (start) begin
                acc     <= 0;
                mac_cnt <= 0;
                running <= 1;
            end

            if (running && iact_valid_i && wght_valid_i) begin
                acc <= acc + iact_data_i * wght_data_i;
                mac_cnt <= mac_cnt + 1;

                if (mac_cnt == TOTAL_MACS-1) begin
                    psum_o       <= acc + iact_data_i * wght_data_i;
                    psum_valid_o <= 1;
                    running      <= 0;
                end
            end
        end
    end

endmodule

