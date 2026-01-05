`timescale 1ns / 1ps

module PE_new #(
    parameter DATA_BITWIDTH = 16,
    parameter kernel_size   = 3
)(
    input  wire clk,
    input  wire reset,

    input  wire [DATA_BITWIDTH-1:0] iact_data_i,
    input  wire                     iact_valid_i,
    input  wire [DATA_BITWIDTH-1:0] wght_data_i,
    input  wire                     wght_valid_i,

    input  wire start,

    output wire [DATA_BITWIDTH-1:0] psum_data_o,
    output wire                     psum_valid_o
);

    localparam TOTAL_MACS = kernel_size * kernel_size;

    // FSM
    localparam S_IDLE    = 2'd0;
    localparam S_LOAD    = 2'd1;
    localparam S_COMPUTE = 2'd2;
    localparam S_DONE    = 2'd3;

    reg [1:0] state;

    reg [DATA_BITWIDTH-1:0] act_reg;
    reg [DATA_BITWIDTH-1:0] wgt_reg;
    reg [DATA_BITWIDTH-1:0] psum_reg;

    reg [$clog2(TOTAL_MACS+1)-1:0] mac_cnt;
    reg psum_valid_r;

    // --------------------------------------------------
    // FSM
    // --------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            state   <= S_IDLE;
            mac_cnt <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    mac_cnt <= 0;
                    if (start)
                        state <= S_LOAD;
                end

                S_LOAD: begin
                    // wait for FIRST valid operands
                    if (iact_valid_i && wght_valid_i)
                        state <= S_COMPUTE;
                end

                S_COMPUTE: begin
                    if (mac_cnt == TOTAL_MACS-1)
                        state <= S_DONE;
                    else
                        mac_cnt <= mac_cnt + 1'b1;
                end

                S_DONE: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

    // --------------------------------------------------
    // Operand capture (ONLY in LOAD or COMPUTE)
    // --------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            act_reg <= '0;
            wgt_reg <= '0;
        end else begin
            if (iact_valid_i)
                act_reg <= iact_data_i;
            if (wght_valid_i)
                wgt_reg <= wght_data_i;
        end
    end

    // --------------------------------------------------
    // MAC enable (STRICT)
    // --------------------------------------------------
    wire mac_en = (state == S_COMPUTE);

    // --------------------------------------------------
    // Sum input
    // --------------------------------------------------
    wire [DATA_BITWIDTH-1:0] sum_in =
        (mac_cnt == 0) ? {DATA_BITWIDTH{1'b0}} : psum_reg;

    // --------------------------------------------------
    // Registered MAC
    // --------------------------------------------------
    MAC #(
        .IN_BITWIDTH(DATA_BITWIDTH),
        .OUT_BITWIDTH(DATA_BITWIDTH)
    ) mac_0 (
        .clk    (clk),
        .en     (mac_en),
        .a_in   (act_reg),
        .w_in   (wgt_reg),
        .sum_in (sum_in),
        .out    (psum_reg)
    );

    // --------------------------------------------------
    // PSUM valid (ONE cycle only)
    // --------------------------------------------------
    always @(posedge clk) begin
        if (reset)
            psum_valid_r <= 1'b0;
        else
            psum_valid_r <= (state == S_DONE);
    end

    assign psum_data_o  = psum_reg;
    assign psum_valid_o = psum_valid_r;

endmodule

