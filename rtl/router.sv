`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/10/2019 03:39:07 AM
// Design Name: 
// Module Name: router
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module router
	#(
		parameter DATA_WIDTH = 16
	)
	(
		input [3:0] router_mode,
		
		//Interface with North
		//Source ports
		input [DATA_WIDTH-1:0] north_data_i,
		input north_enable_i,
//		output logic north_ready_o,
		
		//Destination ports
		output logic [DATA_WIDTH-1:0] north_data_o,
		output logic north_enable_o,
//		input north_ready_i,
		
		
		//Interface with South
		//Source ports
		input [DATA_WIDTH-1:0] south_data_i,
		input south_enable_i,
//		output logic south_ready_o,
		
		//Destination ports
		output logic [DATA_WIDTH-1:0] south_data_o,
		output logic south_enable_o,
//		input south_ready_i,
		
		
		//Interface with West
		//Source ports
		input [DATA_WIDTH-1:0] west_data_i,
		input west_enable_i,
//		output logic west_ready_o,
		
		//Destination ports
		output logic [DATA_WIDTH-1:0] west_data_o,
		output logic west_enable_o,
//		input west_ready_i,
		
		
		//Interface with East - Devices
		//Source ports
		input [DATA_WIDTH-1:0] east_data_i,
		input east_enable_i,
//		output logic east_ready_o,
		
		//Destination ports
		output logic [DATA_WIDTH-1:0] east_data_o,
		output logic east_enable_o
//		input east_ready_i
    );
	
	logic [DATA_WIDTH-1:0] data_out;
typedef enum logic [3:0] {
    ALL        = 4'd0,
    NORTH      = 4'd1,
    SOUTH      = 4'd2,
    WEST       = 4'd3,
    EAST       = 4'd4,
    EASTNORTH  = 4'd5,
    EASTSOUTH  = 4'd6,
    EASTWEST   = 4'd7,
    WESTNORTH  = 4'd8,
    WESTSOUTH  = 4'd9,
    WESTEAST   = 4'd10
} direction_t;

direction_t direction;
	
	//Logic for selecting data_out based on enable
	always_comb begin : data_switch
    casez ({north_enable_i, south_enable_i, west_enable_i, east_enable_i})
        4'b1???: data_out = north_data_i;
        4'b01??: data_out = south_data_i;
        4'b001?: data_out = west_data_i;
        4'b0001: data_out = east_data_i;
        default: data_out = 5'b10101; // Default value for verification
    endcase
	end

	
	//Logic for data out in destination ports based on routing_mode
	always_comb
		begin: routing_logic
			case(router_mode)
				ALL:begin
					north_data_o = data_out;
					north_enable_o = 1;
					
					south_data_o = data_out;
					south_enable_o = 1;
					
					west_data_o = data_out;
					west_enable_o = 1;
					
					east_data_o = data_out;
					east_enable_o = 1;
				end
				
				NORTH:begin
					north_data_o = data_out;
					south_data_o = 'X;
					east_data_o = 'X;
					west_data_o = 'X;
					
					north_enable_o = 1;
					south_enable_o = 0;
					west_enable_o = 0;
					east_enable_o = 0;
				end
				
				SOUTH:begin
					south_data_o = data_out;
					north_data_o = 'X;
					east_data_o = 'X;
					west_data_o = 'X;
					
					north_enable_o = 0;
					south_enable_o = 1;
					west_enable_o = 0;
					east_enable_o = 0;
				end
				
				WEST:begin
					west_data_o = data_out;
					south_data_o = 'X;
					east_data_o = 'X;
					north_data_o = 'X;
					
					north_enable_o = 0;
					south_enable_o = 0;
					west_enable_o = 1;
					east_enable_o = 0;
				end
				
				EAST:begin
					east_data_o = data_out;
					south_data_o = 'X;
					north_data_o = 'X;
					west_data_o = 'X;
					
					north_enable_o = 0;
					south_enable_o = 0;
					west_enable_o = 0;
					east_enable_o = 1;
				end
				
				//Two Directions - Used for storing in PE cluster and routing
				//With East as compute unit
				EASTNORTH:begin
					east_data_o = data_out;
					north_data_o = data_out;
					south_data_o = 'X;
					west_data_o = 'X;
					
					north_enable_o = 1;
					south_enable_o = 0;
					west_enable_o = 0;
					east_enable_o = 1;
				end
				
				EASTSOUTH:begin
					east_data_o = data_out;
					south_data_o = data_out;
					north_data_o = 'X;
					west_data_o = 'X;
					
					north_enable_o = 0;
					south_enable_o = 1;
					west_enable_o = 0;
					east_enable_o = 1;
				end
				
				EASTWEST:begin
					east_data_o = data_out;
					west_data_o = data_out;
					south_data_o = 'X;
					north_data_o = 'X;
					
					north_enable_o = 0;
					south_enable_o = 0;
					west_enable_o = 1;
					east_enable_o = 1;
				end
				
				//With West as compute unit
				WESTNORTH:begin
					west_data_o = data_out;
					north_data_o = data_out;
					south_data_o = 'X;
					east_data_o = 'X;
					
					north_enable_o = 1;
					south_enable_o = 0;
					west_enable_o = 1;
					east_enable_o = 0;
				end
				
				WESTSOUTH:begin
					west_data_o = data_out;
					south_data_o = data_out;
					north_data_o = 'X;
					east_data_o = 'X;
					
					north_enable_o = 0;
					south_enable_o = 1;
					west_enable_o = 1;
					east_enable_o = 0;
				end
				
				WESTEAST:begin
					west_data_o = data_out;
					east_data_o = data_out;
					south_data_o = 'X;
					north_data_o = 'X;
					
					north_enable_o = 0;
					south_enable_o = 0;
					west_enable_o = 1;
					east_enable_o = 1;
				end
				
				default: begin
					north_data_o = 'X;
					east_data_o = 'X;
					south_data_o = 'X;
					west_data_o = 'X;
					
					north_enable_o = 0;
					south_enable_o = 0;
					west_enable_o = 0;
					east_enable_o = 0;
				end
			endcase
		end

endmodule
