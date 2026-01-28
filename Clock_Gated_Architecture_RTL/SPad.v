`timescale 1ns / 1ps

module SPad #( parameter DATA_BITWIDTH = 16,
			 parameter ADDR_BITWIDTH = 9 )
		   ( input clk,
			 input reset,
			 input read_req,
			 input write_en,
			 input [ADDR_BITWIDTH-1 : 0] r_addr,
			 input [ADDR_BITWIDTH-1 : 0] w_addr,
			 input [DATA_BITWIDTH-1 : 0] w_data,
			 output  [DATA_BITWIDTH-1 : 0] r_data
    );
	
	reg [DATA_BITWIDTH-1 : 0] mem [0 : (1 << ADDR_BITWIDTH) - 1]; 
		// default - 512(2^9) 16-bit memory. Total size = 1kB 
	reg [DATA_BITWIDTH-1 : 0] data;
	
	always@(posedge clk)
		begin : READ
			if(reset)
				data <= 0;
			else
				if(read_req) begin
					data <= mem[r_addr];
			end
		end
	
	assign r_data = data;
	
	always@(posedge clk)
		begin : WRITE
		
			if(write_en && !reset) begin
				mem[w_addr] <= w_data;
			end
		end
	
endmodule
