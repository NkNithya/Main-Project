	`timescale 1ns / 1ps

	// ============================================================================
	// 4x4 Max Pooling (Order-Based, TB-Safe)
	// ---------------------------------------------------------------------------
	// - Groups every 16 reads into one pooling window
	// - Outputs pooled max on 16th read
	// - Pass-through otherwise
	// - Designed for HMNOC psum read streams
	// ============================================================================

	module pool_max_4x4_stream #(
		parameter DATA_BITWIDTH = 16
	)(
		input                            clk,
		input                            reset,

		// Read request (from TB)
		input                            r_req,

		// Data after ReLU
		input  signed [DATA_BITWIDTH-1:0] data_in,

		// Output to TB
		output reg signed [DATA_BITWIDTH-1:0] data_out
	);

		// ------------------------------------------------------------------------
		// Internal state
		// ------------------------------------------------------------------------
		reg signed [DATA_BITWIDTH-1:0] max_reg;
		reg [3:0] cnt;   // counts 0..15

		// ------------------------------------------------------------------------
		// Pooling logic
		// ------------------------------------------------------------------------
		always @(posedge clk) begin
		    if (reset) begin
		        max_reg <= 'sd0;
		        cnt     <= 4'd0;
		        data_out<= 'sd0;
		    end
		    else begin
		        // First sample of window
		        if (cnt == 4'd0)
		            max_reg <= data_in;
		        else if (data_in > max_reg)
		            max_reg <= data_in;

		        // Output logic
		        if (cnt == 4'd15) begin
		            data_out <= max_reg;  // pooled output
		            cnt      <= 4'd0;
		        end
		        else begin
		            data_out <= data_in;  // pass-through
		            cnt      <= cnt + 4'd1;
		        end
		    end
		end

	endmodule

