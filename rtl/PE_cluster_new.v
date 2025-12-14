`timescale 1ns / 1ps

module PE_cluster_new #(
    parameter DATA_BITWIDTH = 16,
    parameter ADDR_BITWIDTH = 9,

    parameter X_dim = 5,
    parameter Y_dim = 3,

    parameter kernel_size = 3,
    parameter act_size = 5,

    parameter W_READ_ADDR = 0,
    parameter A_READ_ADDR = 100,

    parameter W_LOAD_ADDR = 0,
    parameter A_LOAD_ADDR = 100,

    parameter PSUM_ADDR = 500
)
(
    input clk, reset,
    input [DATA_BITWIDTH-1:0] act_in,
    input [DATA_BITWIDTH-1:0] filt_in,
    input [DATA_BITWIDTH*X_dim-1:0] pe_before,
    input load_en_wght, load_en_act,
    input start,
    output reg [DATA_BITWIDTH*X_dim-1:0] pe_out,
    output compute_done,
    output load_done
);

    // per-element psum outputs (unpacked array as before)
    wire [DATA_BITWIDTH-1:0] psum_out[0 : X_dim*Y_dim-1];

    // per-element done flags from each PE
    wire cluster_done[0 : X_dim*Y_dim-1];
    wire cluster_load_done[0 : X_dim*Y_dim-1];

    // Instantiate PEs
    generate
        genvar i;
        for (i = 0; i < X_dim; i = i + 1) begin : gen_X
            genvar j;
            for (j = 0; j < Y_dim; j = j + 1) begin : gen_Y

                PE_new #(
                    .DATA_BITWIDTH(DATA_BITWIDTH),
                    .ADDR_BITWIDTH(ADDR_BITWIDTH),
                    .kernel_size(kernel_size),
                    .act_size(act_size),
                    .W_READ_ADDR(W_READ_ADDR + kernel_size*j),
                    .A_READ_ADDR(A_READ_ADDR + act_size*j + i),
                    .W_LOAD_ADDR(W_LOAD_ADDR),
                    .A_LOAD_ADDR(A_LOAD_ADDR),
                    .PSUM_ADDR(PSUM_ADDR)
                ) pe (
                    .clk(clk),
                    .reset(reset),
                    .act_in(act_in),
                    .filt_in(filt_in),
                    .load_en_wght(load_en_wght),
                    .load_en_act(load_en_act),
                    .start(start),
                    .pe_out(psum_out[i*Y_dim + j]),
                    .compute_done(cluster_done[i*Y_dim + j]),
                    .load_done(cluster_load_done[i*Y_dim + j])
                );

            end
        end
    endgenerate

    // Build wide pe_out from the per-PE psum_out[] values
    always @(posedge clk) begin
        if (reset) begin
            pe_out <= {DATA_BITWIDTH*X_dim{1'b0}};
        end else begin
            // For X_dim columns, each column sums its Y_dim partials plus pe_before column
            // Indexing follows your original code semantics for X_dim=3 example
            // Generalized loop could be used, but explicit assignment keeps same behavior
            integer xi;
            // zero the wide vector first (avoid X propagation)
            pe_out <= {DATA_BITWIDTH*X_dim{1'b0}};

            // compute each column sum and place into pe_out slice
            for (xi = 0; xi < X_dim; xi = xi + 1) begin
                // sum over Y_dim entries for column xi
                integer yk;
                reg [DATA_BITWIDTH-1:0] col_sum;
                col_sum = {DATA_BITWIDTH{1'b0}};
                for (yk = 0; yk < Y_dim; yk = yk + 1) begin
                    col_sum = col_sum + psum_out[xi*Y_dim + yk];
                end
                // add corresponding pe_before slice (assumes pe_before arranged in same column order)
                col_sum = col_sum + pe_before[(xi+1)*DATA_BITWIDTH-1 -: DATA_BITWIDTH];
                // place into pe_out
                pe_out[(xi+1)*DATA_BITWIDTH-1 -: DATA_BITWIDTH] <= col_sum;
            end
        end
    end

    //----------------------------------------------------------------
    // IMPORTANT: compute_done / load_done should represent the whole cluster
    // Convert the unpacked cluster_done and cluster_load_done arrays into packed
    // vectors and reduce them with bitwise AND so 'done' is true only when all PEs done.
    //----------------------------------------------------------------

    // packed vectors (width = number of PEs)
    localparam integer NUM_PES = X_dim * Y_dim;
    wire [NUM_PES-1:0] cluster_done_vec;
    wire [NUM_PES-1:0] cluster_load_done_vec;

    // map unpacked arrays to packed vectors
    genvar gid;
    generate
        for (gid = 0; gid < NUM_PES; gid = gid + 1) begin : gen_map
            assign cluster_done_vec[gid] = cluster_done[gid];
            assign cluster_load_done_vec[gid] = cluster_load_done[gid];
        end
    endgenerate

    // reduction: all ones -> all PEs done
    wire cluster_done_all  = &cluster_done_vec;
    wire cluster_load_all  = &cluster_load_done_vec;

    assign compute_done = cluster_done_all;
    assign load_done    = cluster_load_all;

endmodule

