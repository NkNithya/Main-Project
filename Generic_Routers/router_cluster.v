`timescale 1ns/1ps

module router_cluster_pe_level2 #(
    parameter DATA_BITWIDTH = 16,
    parameter ADDR_BITWIDTH = 10,
    parameter ACT_SIZE      = 5,
    parameter KERNEL_SIZE   = 3,
    parameter X_dim         = 5,   // must match PE_cluster_new
    parameter A_READ_ADDR   = 10,
    parameter W_READ_ADDR   = 16
)(
    input  clk,
    input  reset,
    input  [3:0] router_mode,

    // -------- GLB --------
    output [ADDR_BITWIDTH-1:0] glb_addr_read_iact,
    output                     glb_req_read_iact,

    output [ADDR_BITWIDTH-1:0] glb_addr_read_wght,
    output                     glb_req_read_wght,

    output [ADDR_BITWIDTH-1:0] glb_addr_write_psum,
    output [DATA_BITWIDTH-1:0] glb_data_write_psum,
    output                     glb_we_psum,

    input  [DATA_BITWIDTH-1:0] glb_rdata,

    // -------- Status --------
    output compute_done
);

    // ===================================================
    // IACT router outputs
    // ===================================================
    wire [DATA_BITWIDTH-1:0] iact_local_data;
    wire                     iact_local_en;

    // ===================================================
    // Weight router outputs
    // ===================================================
    wire [DATA_BITWIDTH-1:0] wght_spad_data;
    wire                     wght_spad_en;

    // ===================================================
    // PE outputs (VECTOR)
    // ===================================================
    wire [DATA_BITWIDTH*X_dim-1:0] pe_psum_vec;
    wire [DATA_BITWIDTH-1:0]       pe_psum_lane0;

    // Explicit lane selection
    assign pe_psum_lane0 = pe_psum_vec[DATA_BITWIDTH-1:0];

    // ===================================================
    // PSUM latch (CRITICAL FIX)
    // ===================================================
    reg [DATA_BITWIDTH-1:0] psum_latched;
    reg                     psum_valid;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            psum_latched <= '0;
            psum_valid   <= 1'b0;
        end else begin
            // latch PE output at compute completion
            if (compute_done) begin
                psum_latched <= pe_psum_lane0;
                psum_valid   <= 1'b1;
            end
            // clear after successful drain
            else if (router_mode == 4'd3 && psum_valid) begin
                psum_valid <= 1'b0;
            end
        end
    end

    // ===================================================
    // IACT ROUTER
    // ===================================================
    router_iact_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH),
        .act_size(ACT_SIZE),
        .A_READ_ADDR(A_READ_ADDR)
    ) u_iact (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_read(glb_addr_read_iact),
        .glb_req_read(glb_req_read_iact),
        .glb_rdata(glb_rdata),

        .north_data_i('0), .north_enable_i(1'b0),
        .south_data_i('0), .south_enable_i(1'b0),
        .west_data_i ('0), .west_enable_i (1'b0),
        .east_data_i ('0), .east_enable_i (1'b0),

        .local_data_o(iact_local_data),
        .local_enable_o(iact_local_en)
    );

    // ===================================================
    // WEIGHT ROUTER
    // ===================================================
    router_weight_full_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH),
        .kernel_size(KERNEL_SIZE),
        .W_READ_ADDR(W_READ_ADDR),
        .HAS_GLB(1),
        .HAS_WEST(0),
        .INJECT_DIR(3)
    ) u_wght (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .glb_addr_read(glb_addr_read_wght),
        .glb_req_read(glb_req_read_wght),
        .glb_rdata(glb_rdata),

        .north_data_i('0), .north_enable_i(1'b0),
        .south_data_i('0), .south_enable_i(1'b0),
        .west_data_i ('0), .west_enable_i (1'b0),
        .east_data_i ('0), .east_enable_i (1'b0),

        .north_data_o(), .north_enable_o(),
        .south_data_o(), .south_enable_o(),
        .west_data_o (), .west_enable_o (),
        .east_data_o (), .east_enable_o (),

        .spad_data_o(wght_spad_data),
        .spad_en_o(wght_spad_en)
    );

    // ===================================================
    // PE CLUSTER (VECTOR OUTPUT)
    // ===================================================
    PE_cluster_new #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .kernel_size(KERNEL_SIZE),
        .act_size(ACT_SIZE),
        .X_dim(X_dim)
    ) u_pe (
        .clk(clk),
        .reset(reset),

        .act_in(iact_local_data),
        .filt_in(wght_spad_data),

        .load_en_act(iact_local_en),
        .load_en_wght(wght_spad_en),

        .start(router_mode == 4'd2), // MODE_COMPUTE

        .pe_out(pe_psum_vec),
        .compute_done(compute_done)
    );

    // ===================================================
    // PSUM ROUTER (SCALAR, MODE_DRAIN ONLY)
    // ===================================================
    router_psum_generic #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH)
    ) u_psum (
        .clk(clk),
        .reset(reset),
        .router_mode(router_mode),

        .local_data_i(psum_latched),
        .local_enable_i(psum_valid && router_mode == 4'd3),

        .north_data_i('0), .north_enable_i(1'b0),
        .south_data_i('0), .south_enable_i(1'b0),
        .west_data_i ('0), .west_enable_i (1'b0),
        .east_data_i ('0), .east_enable_i (1'b0),

        .north_data_o(), .north_enable_o(),
        .south_data_o(), .south_enable_o(),
        .west_data_o (), .west_enable_o (),
        .east_data_o (), .east_enable_o (),

        .spad_data_o(),
        .spad_en_o(),
        .spad_addr_o(),

        .glb_data_o(glb_data_write_psum),
        .glb_en_o(glb_we_psum),
        .glb_addr_o(glb_addr_write_psum)
    );

endmodule
	
