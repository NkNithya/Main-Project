`timescale 1ns/1ps

module router_generic_tb;

// ============================================================
// PARAMETERS
// ============================================================
localparam DATA_BITWIDTH     = 16;
localparam ADDR_BITWIDTH_GLB = 10;
localparam ADDR_BITWIDTH_SPAD= 9;

localparam X_dim      = 3;
localparam Y_dim      = 3;
localparam kernel_size= 3;
localparam act_size   = 5;

// ============================================================
// CLOCK / RESET
// ============================================================
reg clk = 0;
always #5 clk = ~clk;

reg reset = 1;

// ============================================================
// ROUTER MODES
// ============================================================
reg [3:0] router_mode_iact;
reg [3:0] router_mode_wght;
reg [3:0] router_mode_psum;

// ============================================================
// IACT/WGHT/PSUM directional ports
// ============================================================
reg  [DATA_BITWIDTH-1:0] north_data_i_iact = 0;
reg                      north_enable_i_iact = 0;
wire [DATA_BITWIDTH-1:0] north_data_o_iact;
wire                     north_enable_o_iact;

reg  [DATA_BITWIDTH-1:0] south_data_i_iact = 0;
reg                      south_enable_i_iact = 0;
wire [DATA_BITWIDTH-1:0] south_data_o_iact;
wire                     south_enable_o_iact;

reg  [DATA_BITWIDTH-1:0] west_data_i_iact = 0;
reg                      west_enable_i_iact = 0;
wire [DATA_BITWIDTH-1:0] west_data_o_iact;
wire                     west_enable_o_iact;

reg  [DATA_BITWIDTH-1:0] east_data_i_iact = 0;
reg                      east_enable_i_iact = 0;
wire [DATA_BITWIDTH-1:0] east_data_o_iact;
wire                     east_enable_o_iact;

// ============================================================
// WEIGHTS
// ============================================================
reg  [DATA_BITWIDTH-1:0] north_data_i_wght = 0;
reg                      north_enable_i_wght = 0;
wire [DATA_BITWIDTH-1:0] north_data_o_wght;
wire                     north_enable_o_wght;

reg  [DATA_BITWIDTH-1:0] south_data_i_wght = 0;
reg                      south_enable_i_wght = 0;
wire [DATA_BITWIDTH-1:0] south_data_o_wght;
wire                     south_enable_o_wght;

reg  [DATA_BITWIDTH-1:0] west_data_i_wght = 0;
reg                      west_enable_i_wght = 0;
wire [DATA_BITWIDTH-1:0] west_data_o_wght;
wire                     west_enable_o_wght;

reg  [DATA_BITWIDTH-1:0] east_data_i_wght = 0;
reg                      east_enable_i_wght = 0;
wire [DATA_BITWIDTH-1:0] east_data_o_wght;
wire                     east_enable_o_wght;

// ============================================================
// PSUM
// ============================================================
reg  [DATA_BITWIDTH*X_dim-1:0] north_data_i_psum = 0;
reg                           north_enable_i_psum = 0;

reg  [DATA_BITWIDTH*X_dim-1:0] south_data_i_psum = 0;
reg                           south_enable_i_psum = 0;

reg  [DATA_BITWIDTH*X_dim-1:0] west_data_i_psum = 0;
reg                           west_enable_i_psum = 0;

reg  [DATA_BITWIDTH*X_dim-1:0] east_data_i_psum = 0;
reg                           east_enable_i_psum = 0;

wire [DATA_BITWIDTH*X_dim-1:0] north_data_o_psum;
wire                           north_enable_o_psum;

wire [DATA_BITWIDTH*X_dim-1:0] south_data_o_psum;
wire                           south_enable_o_psum;

wire [DATA_BITWIDTH*X_dim-1:0] west_data_o_psum;
wire                           west_enable_o_psum;

wire [DATA_BITWIDTH*X_dim-1:0] east_data_o_psum;
wire                           east_enable_o_psum;

wire [DATA_BITWIDTH-1:0]       psum_data_o;
wire                            psum_enable_o;
wire [ADDR_BITWIDTH_GLB-1:0]    psum_addr_o;

// ============================================================
// GLB read signals from routers
// ============================================================
wire [ADDR_BITWIDTH_GLB-1:0] iact_glb_addr_read;
wire iact_glb_req_read;

wire [ADDR_BITWIDTH_GLB-1:0] wght_glb_addr_read;
wire wght_glb_req_read;

// ============================================================
// DUT
// ============================================================
router_cluster_wpsum_generic #(
    .DATA_BITWIDTH(DATA_BITWIDTH),
    .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
    .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),
    .X_dim(X_dim),
    .Y_dim(Y_dim),
    .kernel_size(kernel_size),
    .act_size(act_size)
) dut (
    .clk(clk),
    .reset(reset),

    // IACT
    .router_mode_iact(router_mode_iact),

    .north_data_i_iact(north_data_i_iact),
    .north_enable_i_iact(north_enable_i_iact),
    .south_data_i_iact(south_data_i_iact),
    .south_enable_i_iact(south_enable_i_iact),
    .west_data_i_iact(west_data_i_iact),
    .west_enable_i_iact(west_enable_i_iact),
    .east_data_i_iact(east_data_i_iact),
    .east_enable_i_iact(east_enable_i_iact),

    .north_data_o_iact(north_data_o_iact),
    .north_enable_o_iact(north_enable_o_iact),
    .south_data_o_iact(south_data_o_iact),
    .south_enable_o_iact(south_enable_o_iact),
    .west_data_o_iact(west_data_o_iact),
    .west_enable_o_iact(west_enable_o_iact),
    .east_data_o_iact(east_data_o_iact),
    .east_enable_o_iact(east_enable_o_iact),

    .iact_glb_addr_read(iact_glb_addr_read),
    .iact_glb_req_read(iact_glb_req_read),

    // WGHT
    .router_mode_wght(router_mode_wght),

    .north_data_i_wght(north_data_i_wght),
    .north_enable_i_wght(north_enable_i_wght),
    .south_data_i_wght(south_data_i_wght),
    .south_enable_i_wght(south_enable_i_wght),
    .west_data_i_wght(west_data_i_wght),
    .west_enable_i_wght(west_enable_i_wght),
    .east_data_i_wght(east_data_i_wght),
    .east_enable_i_wght(east_enable_i_wght),

    .north_data_o_wght(north_data_o_wght),
    .north_enable_o_wght(north_enable_o_wght),
    .south_data_o_wght(south_data_o_wght),
    .south_enable_o_wght(south_enable_o_wght),
    .west_data_o_wght(west_data_o_wght),
    .west_enable_o_wght(west_enable_o_wght),
    .east_data_o_wght(east_data_o_wght),
    .east_enable_o_wght(east_enable_o_wght),

    .wght_glb_addr_read(wght_glb_addr_read),
    .wght_glb_req_read(wght_glb_req_read),

    // PSUM
    .router_mode_psum(router_mode_psum),

    .north_data_i_psum(north_data_i_psum),
    .north_enable_i_psum(north_enable_i_psum),
    .south_data_i_psum(south_data_i_psum),
    .south_enable_i_psum(south_enable_i_psum),
    .west_data_i_psum(west_data_i_psum),
    .west_enable_i_psum(west_enable_i_psum),
    .east_data_i_psum(east_data_i_psum),
    .east_enable_i_psum(east_enable_i_psum),

    .north_data_o_psum(north_data_o_psum),
    .north_enable_o_psum(north_enable_o_psum),
    .south_data_o_psum(south_data_o_psum),
    .south_enable_o_psum(south_enable_o_psum),
    .west_data_o_psum(west_data_o_psum),
    .west_enable_o_psum(west_enable_o_psum),
    .east_data_o_psum(east_data_o_psum),
    .east_enable_o_psum(east_enable_o_psum),

    .psum_data_o(psum_data_o),
    .psum_enable_o(psum_enable_o),
    .psum_addr_o(psum_addr_o)
);

// ============================================================
// TEST SEQUENCE
// ============================================================
initial begin
    $display("[TB] Starting router generic testbench...");

    // Hold reset
    #30 reset = 0;

    // Set router modes to COMPUTE_DIR = 2 (WEST)
    router_mode_iact = 4'b0010;
    router_mode_wght = 4'b0010;
    router_mode_psum = 4'b0010;

    // ----------------------------------------------------------
    // 1) Inject IACT from NORTH → expect West output
    // ----------------------------------------------------------
    @(posedge clk);
    north_data_i_iact   = 16'h1111;
    north_enable_i_iact = 1;

    @(posedge clk);
    north_enable_i_iact = 0;

    // ----------------------------------------------------------
    // 2) Inject WGHT from EAST → expect West output
    // ----------------------------------------------------------
    @(posedge clk);
    east_data_i_wght    = 16'h2222;
    east_enable_i_wght  = 1;

    @(posedge clk);
    east_enable_i_wght  = 0;

    // ----------------------------------------------------------
    // 3) Inject PSUM and check serialization
    // ----------------------------------------------------------
    @(posedge clk);
    west_data_i_psum    = {16'hAAAA, 16'hBBBB, 16'hCCCC};
    west_enable_i_psum  = 1;

    @(posedge clk);
    west_enable_i_psum  = 0;

    #500;

    $display("[TB] End of stimulus.");
    $finish;
end

// ============================================================
// OUTPUT MONITORING
// ============================================================
always @(posedge clk) begin
    if (psum_enable_o) begin
        if (^psum_data_o === 1'bx) begin
            $display("[TB-ERROR] X DETECTED in psum_data_o at %0t", $time);
            $finish;
        end

        $display("[TB] PSUM WRITE addr=%0d data=%h", psum_addr_o, psum_data_o);
    end
end

// Monitor IACT
always @(posedge clk)
    if (west_enable_o_iact)
        $display("[TB] IACT OUT WEST = %h at %0t", west_data_o_iact, $time);

// Monitor WGHT
always @(posedge clk)
    if (west_enable_o_wght)
        $display("[TB] WGHT OUT WEST = %h at %0t", west_data_o_wght, $time);

// Monitor PSUM
always @(posedge clk)
    if (west_enable_o_psum)
        $display("[TB] PSUM OUT WEST (wide) = %h at %0t", west_data_o_psum, $time);

// ============================================================
initial begin
    $dumpfile("router_generic_tb.vcd");
    $dumpvars(0, router_generic_tb);
end

endmodule

