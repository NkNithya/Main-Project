`timescale 1ns / 1ps

module PE_new #(
    parameter DATA_BITWIDTH = 16,
    parameter ADDR_BITWIDTH = 9,

    parameter W_READ_ADDR  = 0,
    parameter A_READ_ADDR  = 100,
    parameter W_LOAD_ADDR  = 0,
    parameter A_LOAD_ADDR  = 100,

    parameter kernel_size  = 3,
    parameter act_size     = 5
)(
    input  clk,
    input  reset,

    input  [DATA_BITWIDTH-1:0] act_in,
    input  [DATA_BITWIDTH-1:0] filt_in,

    input  load_en_wght,
    input  load_en_act,
    input  start,

    output reg [DATA_BITWIDTH-1:0] pe_out,
    output reg compute_done,
    output reg load_done
);

    // ==================================================
    // FSM STATES (UNCHANGED)
    // ==================================================
    localparam IDLE        = 5'd0,
               LD_W_ADDR   = 5'd1,
               LD_W_WRITE  = 5'd2,
               LD_A_ADDR   = 5'd3,
               LD_A_WRITE  = 5'd4,

               RD_W_ADDR   = 5'd5,
               RD_W_REQ    = 5'd6,
               RD_W_WAIT   = 5'd7,
               RD_W_LATCH  = 5'd8,

               RD_A_ADDR   = 5'd9,
               RD_A_REQ    = 5'd10,
               RD_A_WAIT   = 5'd11,
               RD_A_LATCH  = 5'd12,

               MAC_FIRE    = 5'd13,
               MAC_WAIT    = 5'd14,
               ACCUM       = 5'd15,
               COMMIT      = 5'd16;

    reg [4:0] state;

    // ==================================================
    // CONTROL
    // ==================================================
    reg busy;

    // ==================================================
    // SPAD INTERFACE
    // ==================================================
    reg read_en, write_en;
    reg [ADDR_BITWIDTH-1:0] r_addr, w_addr;
    reg [DATA_BITWIDTH-1:0] w_data;
    wire [DATA_BITWIDTH-1:0] r_data;

    SPad #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH(ADDR_BITWIDTH)
    ) spad (
        .clk      (clk),
        .reset    (reset),
        .read_req (read_en),
        .write_en (write_en),
        .r_addr   (r_addr),
        .w_addr   (w_addr),
        .w_data   (w_data),
        .r_data   (r_data)
    );

    // ==================================================
    // REGISTERED READ DATA  (FIXED: gated)
    // ==================================================
    reg [DATA_BITWIDTH-1:0] r_data_q;
    always @(posedge clk) begin
        if (reset)
            r_data_q <= {DATA_BITWIDTH{1'b0}};
        else if (read_en)
            r_data_q <= r_data;
    end

    // ==================================================
    // OPERANDS
    // ==================================================
    reg [DATA_BITWIDTH-1:0] act_reg, wgt_reg;

    // ==================================================
    // MAC (REGISTERED OUTPUT)
    // ==================================================
    reg mac_en;
    wire [DATA_BITWIDTH-1:0] psum;

    MAC #(
        .IN_BITWIDTH (DATA_BITWIDTH),
        .OUT_BITWIDTH(DATA_BITWIDTH)
    ) mac (
        .clk   (clk),
        .reset (reset),
        .en    (mac_en),
        .a_in  (act_reg),
        .w_in  (wgt_reg),
        .sum_in({DATA_BITWIDTH{1'b0}}),
        .out   (psum)
    );

    // ==================================================
    // REGISTER MAC OUTPUT
    // ==================================================
    reg [DATA_BITWIDTH-1:0] psum_q;
    always @(posedge clk)
        psum_q <= reset ? {DATA_BITWIDTH{1'b0}} : psum;

    // ==================================================
    // COUNTERS
    // ==================================================
    reg [7:0] load_count;
    reg [7:0] rd_idx;
    reg [7:0] acc_count;

    // ==================================================
    // FSM
    // ==================================================
    always @(posedge clk) begin
        if (reset) begin
            state        <= IDLE;
            load_count   <= 0;
            rd_idx       <= 0;
            acc_count    <= 0;
            pe_out       <= 0;
            busy         <= 0;

            read_en      <= 0;
            write_en     <= 0;
            mac_en       <= 0;

            compute_done <= 0;
            load_done    <= 0;
        end else begin
            read_en      <= 0;
            write_en     <= 0;
            mac_en       <= 0;
            compute_done <= 0;
            load_done    <= 0;

            case (state)

            // ================= IDLE =================
            IDLE: begin
                if (load_en_wght) begin
                    load_count <= 0;
                    state <= LD_W_ADDR;
                end else if (load_en_act) begin
                    load_count <= 0;
                    state <= LD_A_ADDR;
                end else if (start && !busy) begin
                    busy      <= 1;
                    rd_idx    <= 0;
                    acc_count <= 0;
                    pe_out    <= 0;
                    state <= RD_W_ADDR;
                end
            end

            // ================= LOAD WEIGHTS =================
            LD_W_ADDR: begin
                w_addr <= W_LOAD_ADDR + load_count;
                w_data <= filt_in;
                state  <= LD_W_WRITE;
            end

            LD_W_WRITE: begin
                write_en <= 1;
                if (load_count == kernel_size*kernel_size - 1) begin
                    load_done <= 1;
                    state <= IDLE;
                end else begin
                    load_count <= load_count + 1;
                    state <= LD_W_ADDR;
                end
            end

            // ================= LOAD ACTIVATIONS =================
            LD_A_ADDR: begin
                w_addr <= A_LOAD_ADDR + load_count;
                w_data <= act_in;
                state  <= LD_A_WRITE;
            end

            LD_A_WRITE: begin
                write_en <= 1;
                if (load_count == act_size*act_size - 1) begin
                    load_done <= 1;
                    state <= IDLE;
                end else begin
                    load_count <= load_count + 1;
                    state <= LD_A_ADDR;
                end
            end

            // ================= READ WEIGHT =================
            RD_W_ADDR: begin
                r_addr <= W_READ_ADDR + rd_idx;
                state <= RD_W_REQ;
            end

            RD_W_REQ: begin
                read_en <= 1;
                state <= RD_W_WAIT;
            end

            RD_W_WAIT: state <= RD_W_LATCH;

            RD_W_LATCH: begin
                wgt_reg <= r_data_q;
                state <= RD_A_ADDR;
            end

            // ================= READ ACT =================
            RD_A_ADDR: begin
                r_addr <= A_READ_ADDR + rd_idx;
                state <= RD_A_REQ;
            end

            RD_A_REQ: begin
                read_en <= 1;
                state <= RD_A_WAIT;
            end

            RD_A_WAIT: state <= RD_A_LATCH;

            RD_A_LATCH: begin
                act_reg <= r_data_q;
                state <= MAC_FIRE;
            end

            // ================= MAC =================
            MAC_FIRE: begin
                mac_en <= 1;
                state <= MAC_WAIT;
            end

            MAC_WAIT: state <= ACCUM;

            // ================= ACCUMULATE =================
            ACCUM: begin
                pe_out <= pe_out + psum_q;
                acc_count <= acc_count + 1;

                if (acc_count == kernel_size)
                    state <= COMMIT;
                else begin
                    rd_idx <= rd_idx + 1;
                    state <= RD_W_ADDR;
                end
            end

            // ================= COMMIT =================
            COMMIT: begin
                compute_done <= 1;
                busy <= 0;
                state <= IDLE;
            end

            endcase
        end
    end

endmodule

