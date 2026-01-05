`timescale 1ns / 1ps

module PE_cluster_new #(
    parameter DATA_BITWIDTH = 16,
    parameter X_dim         = 3,
    parameter Y_dim         = 3,
    parameter kernel_size  = 3
)(
    input  wire clk,
    input  wire reset,

    input  wire [DATA_BITWIDTH-1:0] iact_data_i,
    input  wire                     iact_valid_i,
    input  wire [DATA_BITWIDTH-1:0] wght_data_i,
    input  wire                     wght_valid_i,

    input  wire start,

    output reg  [DATA_BITWIDTH*X_dim*Y_dim-1:0] psum_data_o,
    output reg                                  psum_valid_o
);

    localparam NUM_PES = X_dim * Y_dim;

    wire [DATA_BITWIDTH-1:0] pe_psum  [0:NUM_PES-1];
    wire                     pe_valid [0:NUM_PES-1];

    // ---------------------------------------------
    // PE instances
    // ---------------------------------------------
    genvar i;
    generate
        for (i = 0; i < NUM_PES; i = i + 1) begin : GEN_PE
            PE_new #(
                .DATA_BITWIDTH(DATA_BITWIDTH),
                .kernel_size(kernel_size)
            ) pe (
                .clk(clk),
                .reset(reset),
                .iact_data_i (iact_data_i),
                .iact_valid_i(iact_valid_i),
                .wght_data_i (wght_data_i),
                .wght_valid_i(wght_valid_i),
                .start(start),
                .psum_data_o (pe_psum[i]),
                .psum_valid_o(pe_valid[i])
            );
        end
    endgenerate

    // ---------------------------------------------
    // Detect all PEs done (combinational)
    // ---------------------------------------------
    reg all_done;
    integer k;

    always @(*) begin
        all_done = 1'b1;
        for (k = 0; k < NUM_PES; k = k + 1)
            if (!pe_valid[k])
                all_done = 1'b0;
    end

    // ---------------------------------------------
    // REGISTER cluster output (CRITICAL FIX)
    // ---------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            psum_data_o  <= '0;
            psum_valid_o <= 1'b0;
        end
        else begin
            psum_valid_o <= 1'b0;

            if (all_done) begin
                for (k = 0; k < NUM_PES; k = k + 1)
                    psum_data_o[k*DATA_BITWIDTH +: DATA_BITWIDTH]
                        <= pe_psum[k];

                psum_valid_o <= 1'b1;
            end
        end
    end

endmodule

