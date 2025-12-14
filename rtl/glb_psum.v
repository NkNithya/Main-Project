`timescale 1ns / 1ps

module glb_psum #(
    parameter DATA_BITWIDTH = 16,
    parameter ADDR_BITWIDTH = 10,
    parameter X_dim = 3,
    parameter Y_dim = 3
)(
    input  clk,
    input  reset,
    input  read_req,
    input  write_en,
    input  [ADDR_BITWIDTH-1 : 0] r_addr,
    input  [ADDR_BITWIDTH-1 : 0] w_addr,
    input  [DATA_BITWIDTH-1 : 0] w_data,
    output [DATA_BITWIDTH-1 : 0] r_data,
    input  [ADDR_BITWIDTH-1 : 0] r_addr_inter,
    input  read_req_inter,
    output [DATA_BITWIDTH*X_dim-1 : 0] r_data_inter,
    output reg read_en_inter
);

    // memory (synthesizable)
    localparam MEM_DEPTH = (1 << ADDR_BITWIDTH);
    reg [DATA_BITWIDTH-1 : 0] mem [0 : MEM_DEPTH-1];

    // registered read outputs
    reg [DATA_BITWIDTH-1 : 0] data;
    reg [DATA_BITWIDTH*X_dim-1 : 0] data_inter;

    // -----------------------
    // Single-word read (clocked)
    // -----------------------
    always @(posedge clk) begin
        if (reset) begin
            data <= {DATA_BITWIDTH{1'b0}};
        end else begin
            if (read_req) begin
                // safe read: if address in range
                if (r_addr < MEM_DEPTH)
                    data <= mem[r_addr];
                else
                    data <= {DATA_BITWIDTH{1'b0}};
            end else begin
                // default when not reading: zero (avoid magic literals)
                data <= {DATA_BITWIDTH{1'b0}};
            end
        end
    end
    assign r_data = data;

    // -----------------------
    // Wide read (read_req_inter) — returns X_dim words concatenated
    // -----------------------
    always @(posedge clk) begin
        if (reset) begin
            data_inter   <= {(DATA_BITWIDTH*X_dim){1'b0}};
            read_en_inter <= 1'b0;
        end else begin
            if (read_req_inter) begin
                // guard against out-of-range addresses for the X_dim block
                if (r_addr_inter <= MEM_DEPTH - X_dim) begin
                    // form concatenation with consistent ordering: highest index leftmost
                    // e.g., data_inter = {mem[r+2], mem[r+1], mem[r]};
                    integer kk;
                    reg [DATA_BITWIDTH*X_dim-1:0] tmp;
                    tmp = {(DATA_BITWIDTH*X_dim){1'b0}};
                    for (kk = 0; kk < X_dim; kk = kk + 1) begin
                        tmp[(X_dim-kk)*DATA_BITWIDTH-1 -: DATA_BITWIDTH] = mem[r_addr_inter + (X_dim-1-kk)];
                    end
                    data_inter <= tmp;
                end else begin
                    // out of bounds: return zeros (safer than x or magic number)
                    data_inter <= {(DATA_BITWIDTH*X_dim){1'b0}};
                end
                read_en_inter <= 1'b1;
            end else begin
                data_inter <= {(DATA_BITWIDTH*X_dim){1'b0}};
                read_en_inter <= 1'b0;
            end
        end
    end
    assign r_data_inter = data_inter;

    // -----------------------
    // Write (synchronous)
    // -----------------------
    always @(posedge clk) begin
        if (!reset) begin
            // write when enabled and address in range
            if (write_en) begin
                if (w_addr < MEM_DEPTH) begin
                    mem[w_addr] <= w_data;
                end
            end
        end
    end

endmodule

