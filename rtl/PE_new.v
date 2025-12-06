`timescale 1ns / 1ps

module PE_new 
#(
    parameter DATA_BITWIDTH = 16,
    parameter ADDR_BITWIDTH = 9,

    parameter W_READ_ADDR = 0,      // Weights READ address
    parameter A_READ_ADDR = 100,    // Activations READ address

    parameter W_LOAD_ADDR = 0,      // Weights LOAD address
    parameter A_LOAD_ADDR = 100,    // Activations LOAD address

    parameter PSUM_ADDR = 500,

    parameter kernel_size = 3,
    parameter act_size    = 5
)
(
    input clk,
    input reset,

    input [DATA_BITWIDTH-1:0] act_in,
    input [DATA_BITWIDTH-1:0] filt_in,

    input load_en_wght,
    input load_en_act,

    input start,

    output [DATA_BITWIDTH-1:0] pe_out,
    output reg compute_done,
    output reg load_done
);

    // --------------------------------------------------------------------
    //  STATE MACHINE
    // --------------------------------------------------------------------
    reg [2:0] state;
    localparam IDLE    = 3'b000;
    localparam READ_W  = 3'b001;
    localparam READ_A  = 3'b010;
    localparam COMPUTE = 3'b011;
    localparam WRITE   = 3'b100;
    localparam LOAD_W  = 3'b101;
    localparam LOAD_A  = 3'b110;

    // --------------------------------------------------------------------
    //  SCRATCHPAD MEMORY
    // --------------------------------------------------------------------
    reg read_en, write_en;
    reg [ADDR_BITWIDTH-1:0] w_addr, r_addr;
    reg [DATA_BITWIDTH-1:0] w_data;

    wire [DATA_BITWIDTH-1:0] r_data;

    SPad #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH(ADDR_BITWIDTH)
    ) 
    spad_pe0 (
        .clk(clk),
        .reset(reset),
        .read_req(read_en),
        .write_en(write_en),
        .r_addr(r_addr),
        .w_addr(w_addr),
        .w_data(w_data),
        .r_data(r_data)
    );

    // --------------------------------------------------------------------
    //  MAC + SUM MUX
    // --------------------------------------------------------------------
    wire [DATA_BITWIDTH-1:0] psum_reg;
    wire [DATA_BITWIDTH-1:0] sum_in;

    reg sum_in_mux_sel;

    reg [DATA_BITWIDTH-1:0] act_in_reg;
    reg [DATA_BITWIDTH-1:0] filt_in_reg;

    reg mac_en;

    MAC #(
        .IN_BITWIDTH(DATA_BITWIDTH),
        .OUT_BITWIDTH(DATA_BITWIDTH)
    ) 
    mac_0 (
        .a_in(act_in_reg),
        .w_in(filt_in_reg),
        .sum_in(sum_in),
        .en(mac_en),
        .clk(clk),
        .out(psum_reg)
    );

    mux2 #(.WIDTH(DATA_BITWIDTH)) mux_sum (
        .a_in(psum_reg),
        .b_in({DATA_BITWIDTH{1'b0}}),
        .sel(sum_in_mux_sel),
        .out(sum_in)
    );

    // --------------------------------------------------------------------
    //  INTERNAL COUNTERS
    // --------------------------------------------------------------------
    reg [7:0] filt_count;
    reg [2:0] iter;

    // --------------------------------------------------------------------
    //  FSM
    // --------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            filt_count <= 0;
            sum_in_mux_sel <= 0;

            w_addr <= W_READ_ADDR;
            r_addr <= W_READ_ADDR;
            w_data <= 0;

            write_en <= 0;
            read_en  <= 0;

            compute_done <= 0;
            load_done    <= 0;

            mac_en <= 0;
            iter <= 0;

            state <= IDLE;
        end 
        else begin
            case (state)

            // -------------------------------------------------------------
            //  MAIN LOOP OR LOAD REQUEST
            // -------------------------------------------------------------
            IDLE: begin
                compute_done <= 0;
                load_done    <= 0;
                write_en     <= 0;
                read_en      <= 0;

                if (start) begin
                    if (iter == (act_size - kernel_size + 1)) begin
                        iter <= 0;
                        state <= IDLE;
                    end 
                    else begin
                        r_addr <= A_READ_ADDR + iter * act_size;
                        filt_count <= 0;
                        sum_in_mux_sel <= 0;
                        read_en <= 1;
                        state <= READ_W;
                    end
                end 
                else if (load_en_wght) begin
                    // Begin weight loading
                    w_addr <= W_LOAD_ADDR;
                    w_data <= filt_in;
                    write_en <= 1;
                    filt_count <= 0;
                    state <= LOAD_W;
                end
                else if (load_en_act) begin
                    // Begin activation loading
                    w_addr <= A_LOAD_ADDR;
                    w_data <= act_in;
                    write_en <= 1;
                    filt_count <= 0;
                    state <= LOAD_A;
                end
            end

            // -------------------------------------------------------------
            //  READ WEIGHT
            // -------------------------------------------------------------
            READ_W: begin
                filt_in_reg <= r_data;
                read_en <= 1;
                filt_count <= filt_count + 1;
                state <= READ_A;
            end

            // -------------------------------------------------------------
            //  READ ACTIVATION
            // -------------------------------------------------------------
            READ_A: begin
                act_in_reg <= r_data;
                read_en <= 1;

                r_addr <= W_READ_ADDR + filt_count;
                mac_en <= 1;

                state <= COMPUTE;
            end

            // -------------------------------------------------------------
            //  COMPUTE USING MAC
            // -------------------------------------------------------------
            COMPUTE: begin
                mac_en <= 0;

                if (filt_count == kernel_size) begin
                    read_en <= 0;
                    w_addr <= PSUM_ADDR + iter;
                    write_en <= 1;
                    state <= WRITE;
                end 
                else begin
                    sum_in_mux_sel <= (filt_count != 0);
                    r_addr <= A_READ_ADDR + filt_count + iter * act_size;
                    state <= READ_W;
                end
            end

            // -------------------------------------------------------------
            //  WRITE PSUM OUT
            // -------------------------------------------------------------
            WRITE: begin
                w_data <= psum_reg;
                r_addr <= W_READ_ADDR;
                read_en <= 1;

                iter <= iter + 1;
                compute_done <= 1;
                state <= IDLE;
            end

            // -------------------------------------------------------------
            //  LOAD WEIGHTS
            // -------------------------------------------------------------
            LOAD_W: begin
                if (filt_count == (kernel_size*kernel_size - 1)) begin
                    load_done <= 1;
                    write_en <= 0;
                    state <= IDLE;
                end 
                else begin
                    w_addr <= w_addr + 1;
                    w_data <= filt_in;
                    filt_count <= filt_count + 1;
                    write_en <= 1;
                    state <= LOAD_W;
                end
            end

            // -------------------------------------------------------------
            //  LOAD ACTIVATIONS
            // -------------------------------------------------------------
            LOAD_A: begin
                if (filt_count == (act_size*act_size - 1)) begin
                    write_en <= 0;
                    read_en <= 1;
                    r_addr <= W_READ_ADDR;

                    load_done <= 1;
                    state <= IDLE;
                end 
                else begin
                    w_addr <= w_addr + 1;
                    w_data <= act_in;
                    filt_count <= filt_count + 1;
                    write_en <= 1;
                    state <= LOAD_A;
                end
            end

            endcase
        end
    end

    assign pe_out = psum_reg;

endmodule

