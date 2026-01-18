module feature_map_sram #(
    parameter DATA_BITWIDTH = 16,
    parameter OUT_X = 255,
    parameter OUT_Y = 255,
    parameter DEPTH = OUT_X * OUT_Y   // 65025
)(
    input  wire                      clk,
    input  wire                      reset,

    input  wire                      we,
    input  wire [$clog2(DEPTH)-1:0]  waddr,
    input  wire [DATA_BITWIDTH-1:0]  wdata,

    input  wire                      re,
    input  wire [$clog2(DEPTH)-1:0]  raddr,
    output reg  [DATA_BITWIDTH-1:0]  rdata
);

    reg [DATA_BITWIDTH-1:0] mem [0:DEPTH-1];
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            rdata <= '0;
        end else begin
            if (we)
                mem[waddr] <= wdata;
            if (re)
                rdata <= mem[raddr];
        end
    end

endmodule

