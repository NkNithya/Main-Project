`timescale 1ns / 1ps

// ============================================================================
// SRAM MODEL (single-port, synchronous)
// - ASIC-style behavior
// - 1-cycle read latency
// - Write-first semantics
// ============================================================================
module sram_1p_sync #(
    parameter DATA_BITWIDTH = 16,
    parameter ADDR_BITWIDTH = 9
)(
    input  wire                     clk,
    input  wire                     cs,      // chip select
    input  wire                     we,      // write enable
    input  wire [ADDR_BITWIDTH-1:0] addr,
    input  wire [DATA_BITWIDTH-1:0] din,
    output reg  [DATA_BITWIDTH-1:0] dout
);

    reg [DATA_BITWIDTH-1:0] mem [0:(1<<ADDR_BITWIDTH)-1];

    always @(posedge clk) begin
        if (cs) begin
            if (we)
                mem[addr] <= din;
            dout <= mem[addr];
        end
    end

endmodule


// ============================================================================
// SPad WRAPPER (interface preserved exactly)
// - Drop-in replacement
// - No changes needed in PE_new or elsewhere
// ============================================================================
module SPad #(
    parameter DATA_BITWIDTH = 16,
    parameter ADDR_BITWIDTH = 9
)(
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     read_req,
    input  wire                     write_en,
    input  wire [ADDR_BITWIDTH-1:0] r_addr,
    input  wire [ADDR_BITWIDTH-1:0] w_addr,
    input  wire [DATA_BITWIDTH-1:0] w_data,
    output wire [DATA_BITWIDTH-1:0] r_data
);

    // ------------------------------------------------------------------------
    // Address / control mapping
    // ------------------------------------------------------------------------
    wire cs;
    wire we;
    wire [ADDR_BITWIDTH-1:0] addr;

    assign cs   = read_req | write_en;
    assign we   = write_en;
    assign addr = write_en ? w_addr : r_addr;

    // ------------------------------------------------------------------------
    // SRAM instance
    // ------------------------------------------------------------------------
    sram_1p_sync #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH(ADDR_BITWIDTH)
    ) u_sram (
        .clk  (clk),
        .cs   (cs),
        .we   (we),
        .addr (addr),
        .din  (w_data),
        .dout (r_data)
    );

endmodule

