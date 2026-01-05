`timescale 1ns / 1ps

module PE_cluster_new #(
    parameter DATA_BITWIDTH = 16,
    parameter kernel_size   = 3
)(
    input  wire clk,
    input  wire reset,

    // Activation stream (spatial order)
    input  wire [DATA_BITWIDTH-1:0] iact_data_i,
    input  wire                     iact_valid_i,

    // Weight stream (kernel order)
    input  wire [DATA_BITWIDTH-1:0] wght_data_i,
    input  wire                     wght_valid_i,

    // Control
    input  wire start,

    // Output
    output reg  [DATA_BITWIDTH-1:0] psum_data_o,
    output reg                      psum_valid_o
);

    localparam TOTAL_MACS = kernel_size * kernel_size;
    localparam CNT_W      = $clog2(TOTAL_MACS+1);

    // -----------------------------------
    // Internal registers
    // -----------------------------------
    reg [CNT_W-1:0] mac_cnt;
    reg signed [2*DATA_BITWIDTH-1:0] acc;

    wire signed [DATA_BITWIDTH-1:0] act_s  = iact_data_i;
    wire signed [DATA_BITWIDTH-1:0] wght_s = wght_data_i;

    // -----------------------------------
    // CNN MAC SEQUENCER
    // -----------------------------------
    always @(posedge clk) begin
        if (reset) begin
            mac_cnt       <= 0;
            acc           <= 0;
            psum_data_o   <= 0;
            psum_valid_o  <= 0;
        end else begin
            psum_valid_o <= 0;

            // Start of new window
            if (start) begin
                mac_cnt <= 0;
                acc     <= 0;
            end

            // Valid MAC
            if (iact_valid_i && wght_valid_i) begin
                acc <= acc + (act_s * wght_s);
                mac_cnt <= mac_cnt + 1;

                // Finished full kernel
                if (mac_cnt == TOTAL_MACS-1) begin
                    psum_data_o  <= acc + (act_s * wght_s);
                    psum_valid_o <= 1'b1;
                end
            end
        end
    end

endmodule

