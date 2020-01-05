// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
//
// ============================================================================
//
module delay1
	#(parameter WID = 1)
	(
	input rst,
	input clk,
	input ce,
	input [WID:1] i,
	output reg [WID:1] o
	);

	always @(posedge clk)
	if (rst)
		o <= {WID{1'b0}};
	else begin
		if (ce)
			o <= i;
	end

endmodule


module delay2
	#(parameter WID = 1)
	(
	input rst,
	input clk,
	input ce,
	input [WID:1] i,
	output reg [WID:1] o
	);


	reg	[WID:1]	r1;
	
	always @(posedge clk)
	if (rst)
		r1 <= {WID{1'b0}};
	else begin
		if (ce)
			r1 <= i;
	end
	
	always @(posedge clk)
	if (rst)
		o <= {WID{1'b0}};
	else begin
		if (ce)
			o <= r1;
	end
	
endmodule


module delay3
	#(parameter WID = 1)
	(
	input clk,
	input ce,
	input [WID:1] i,
	output reg [WID:1] o
	);

	reg	[WID:1] r1, r2;
	
	always @(posedge clk)
		if (ce)
			r1 <= i;
	
	always @(posedge clk)
		if (ce)
			r2 <= r1;
	
	always @(posedge clk)
		if (ce)
			o <= r2;
			
endmodule
	
module delay4
	#(parameter WID = 1)
	(
	input clk,
	input ce,
	input [WID-1:0] i,
	output reg [WID-1:0] o
	);

	reg	[WID:1] r1, r2, r3;
	
	always @(posedge clk)
		if (ce)
			r1 <= i;
	
	always @(posedge clk)
		if (ce)
			r2 <= r1;
	
	always @(posedge clk)
		if (ce)
			r3 <= r2;
	
	always @(posedge clk)
		if (ce)
			o <= r3;

endmodule

	
module delay5
#(parameter WID = 1)
(
	input clk,
	input ce,
	input [WID:1] i,
	output reg [WID:1] o
);

	reg	[WID:1] r1, r2, r3, r4;
	
	always @(posedge clk)
		if (ce) r1 <= i;
	
	always @(posedge clk)
		if (ce) r2 <= r1;
	
	always @(posedge clk)
		if (ce) r3 <= r2;
	
	always @(posedge clk)
		if (ce) r4 <= r3;
	
	always @(posedge clk)
		if (ce) o <= r4;
	
endmodule

