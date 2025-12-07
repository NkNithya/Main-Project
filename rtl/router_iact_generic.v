`timescale 1ns / 1ps

module router_generic_iact
#(
    parameter DATA_BITWIDTH      = 16,
    parameter ADDR_BITWIDTH_GLB  = 10,
    parameter ADDR_BITWIDTH_SPAD = 9,

    parameter X_dim       = 5,
    parameter Y_dim       = 3,
    parameter kernel_size = 3,
    parameter act_size    = 5,

    parameter A_READ_ADDR = 100,
    parameter A_LOAD_ADDR = 0,

    // Select which direction connects to the SPAD
    // NOTE: many tools accept string params; if not, switch to integer encodings.
    parameter COMPUTE_DIR = "WEST"       // "NORTH", "SOUTH", "EAST", "WEST"
)
(
    input clk,
    input reset,

    // Router mode
    input [3:0] router_mode,

    // GLB read interface (from router_iact)
    output [ADDR_BITWIDTH_GLB-1:0] glb_addr_read,
    output                         glb_req_read,

    // Directional input ports
    input [DATA_BITWIDTH-1:0] north_data_i,
    input                      north_enable_i,

    input [DATA_BITWIDTH-1:0] south_data_i,
    input                      south_enable_i,

    input [DATA_BITWIDTH-1:0] west_data_i,
    input                      west_enable_i,

    input [DATA_BITWIDTH-1:0] east_data_i,
    input                      east_enable_i,

    // Directional output ports
    output reg [DATA_BITWIDTH-1:0] north_data_o,
    output reg                     north_enable_o,

    output reg [DATA_BITWIDTH-1:0] south_data_o,
    output reg                     south_enable_o,

    output reg [DATA_BITWIDTH-1:0] west_data_o,
    output reg                     west_enable_o,

    output reg [DATA_BITWIDTH-1:0] east_data_o,
    output reg                     east_enable_o
);

    //------------------------------------------------------
    // 1. Input direction priority selection
    //------------------------------------------------------
    reg [DATA_BITWIDTH-1:0] data_out;
    reg                     load_spad_ctrl_c;

    always @(*) begin
        if (north_enable_i) begin
            data_out         = north_data_i;
            load_spad_ctrl_c = 1;
        end
        else if (south_enable_i) begin
            data_out         = south_data_i;
            load_spad_ctrl_c = 1;
        end
        else if (west_enable_i) begin
            data_out         = west_data_i;
            load_spad_ctrl_c = 1;
        end
        else if (east_enable_i) begin
            data_out         = east_data_i;
            load_spad_ctrl_c = 1;
        end
        else begin
            data_out         = {DATA_BITWIDTH{1'b0}};
            load_spad_ctrl_c = 0;
        end
    end

    //------------------------------------------------------
    // 2. One-shot pulse generator for SPAD load
    //------------------------------------------------------
    reg load_spad_ctrl_0, load_spad_ctrl_1;
    wire load_spad_ctrl;

    assign load_spad_ctrl = load_spad_ctrl_0 & (~load_spad_ctrl_1);

    always @(posedge clk) begin
        if (reset) begin
            load_spad_ctrl_0 <= 0;
            load_spad_ctrl_1 <= 0;
        end else begin
            load_spad_ctrl_0 <= load_spad_ctrl_c;
            load_spad_ctrl_1 <= load_spad_ctrl_0;
        end
    end

    //------------------------------------------------------
    // 3. SPAD output wires from router_iact
    //------------------------------------------------------
    wire [DATA_BITWIDTH-1:0] spad_data_o;
    wire                     spad_en_o;

    //------------------------------------------------------
    // 4. Instantiate router_iact (unchanged)
    //------------------------------------------------------
    router_iact #(
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .ADDR_BITWIDTH_GLB(ADDR_BITWIDTH_GLB),
        .ADDR_BITWIDTH_SPAD(ADDR_BITWIDTH_SPAD),

        .X_dim(X_dim),
        .Y_dim(Y_dim),
        .kernel_size(kernel_size),
        .act_size(act_size),

        .A_READ_ADDR(A_READ_ADDR),
        .A_LOAD_ADDR(A_LOAD_ADDR)
    )
    router_iact_0 (
        .clk(clk),
        .reset(reset),

        .r_data_glb_iact(data_out),   // here data_out plays the role of "GLB data"
        .r_addr_glb_iact(glb_addr_read),
        .read_req_glb_iact(glb_req_read),

        .w_data_spad(spad_data_o),
        .load_en_spad(spad_en_o),

        .load_spad_ctrl(load_spad_ctrl)
    );

    //------------------------------------------------------
    // 5 & 6 combined:
    // Unified output routing logic:
    //  - When router_mode == CLOSED: SPAD/compute mode
    //  - Else: normal routing mode
    //------------------------------------------------------
    localparam ALL        = 0;
    localparam NORTH      = 1;
    localparam SOUTH      = 2;
    localparam WEST       = 3;
    localparam EAST       = 4;
    localparam EASTNORTH  = 5;
    localparam EASTSOUTH  = 6;
    localparam EASTWEST   = 7;
    localparam WESTNORTH  = 8;
    localparam WESTSOUTH  = 9;
    localparam WESTEAST   = 10;
    localparam CLOSED     = 11;

    always @(*) begin
        // Default outputs
        north_data_o   = {DATA_BITWIDTH{1'b0}};
        south_data_o   = {DATA_BITWIDTH{1'b0}};
        west_data_o    = {DATA_BITWIDTH{1'b0}};
        east_data_o    = {DATA_BITWIDTH{1'b0}};

        north_enable_o = 1'b0;
        south_enable_o = 1'b0;
        west_enable_o  = 1'b0;
        east_enable_o  = 1'b0;

        // ==================================================
        //  Compute/SPAD Mode: router_mode == CLOSED
        // ==================================================
        if (router_mode == CLOSED) begin
            // Drive only the COMPUTE_DIR with SPAD output
            case (COMPUTE_DIR)
                "NORTH": begin
                    north_data_o   = spad_data_o;
                    north_enable_o = spad_en_o;
                end

                "SOUTH": begin
                    south_data_o   = spad_data_o;
                    south_enable_o = spad_en_o;
                end

                "WEST": begin
                    west_data_o    = spad_data_o;
                    west_enable_o  = spad_en_o;
                end

                "EAST": begin
                    east_data_o    = spad_data_o;
                    east_enable_o  = spad_en_o;
                end

                default: begin
                    // no-op if COMPUTE_DIR is invalid
                end
            endcase
        end

        // ==================================================
        //  Normal Routing Mode: router_mode != CLOSED
        //  Outputs now driven by data_out (not SPAD)
        // ==================================================
        else begin
            case (router_mode)

                ALL: begin
                    north_data_o   = data_out; north_enable_o = 1'b1;
                    south_data_o   = data_out; south_enable_o = 1'b1;
                    east_data_o    = data_out; east_enable_o  = 1'b1;
                    west_data_o    = data_out; west_enable_o  = 1'b1;
                end

                NORTH: begin
                    north_data_o   = data_out; north_enable_o = 1'b1;
                end

                SOUTH: begin
                    south_data_o   = data_out; south_enable_o = 1'b1;
                end

                WEST: begin
                    west_data_o    = data_out; west_enable_o  = 1'b1;
                end

                EAST: begin
                    east_data_o    = data_out; east_enable_o  = 1'b1;
                end

                EASTNORTH: begin
                    east_data_o    = data_out; east_enable_o  = 1'b1;
                    north_data_o   = data_out; north_enable_o = 1'b1;
                end

                EASTSOUTH: begin
                    east_data_o    = data_out; east_enable_o  = 1'b1;
                    south_data_o   = data_out; south_enable_o = 1'b1;
                end

                EASTWEST: begin
                    east_data_o    = data_out; east_enable_o  = 1'b1;
                    west_data_o    = data_out; west_enable_o  = 1'b1;
                end

                WESTNORTH: begin
                    west_data_o    = data_out; west_enable_o  = 1'b1;
                    north_data_o   = data_out; north_enable_o = 1'b1;
                end

                WESTSOUTH: begin
                    west_data_o    = data_out; west_enable_o  = 1'b1;
                    south_data_o   = data_out; south_enable_o = 1'b1;
                end

                WESTEAST: begin
                    west_data_o    = data_out; west_enable_o  = 1'b1;
                    east_data_o    = data_out; east_enable_o  = 1'b1;
                end

                default: begin
                    // Outputs remain zero
                end

            endcase
        end
    end

endmodule
		
