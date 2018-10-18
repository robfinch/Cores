`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	CardMemory.v
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
module CardMemory(clk_i, cs_i, ack_o, wr_i, adr_i, dat_i, dat_o, stp, mapno);
input clk_i;
input cs_i;
output reg ack_o;		// acknowledge
input wr_i;
input [31:0] adr_i;
input [63:0] dat_i;
output reg [63:0] dat_o;
input stp;				// store pointer
input [5:0] mapno;

parameter IDLE = 3'd0;
parameter ACC  = 3'd1;
parameter STP1a = 3'd2;
parameter STP1b = 3'd3;
parameter STP1c = 3'd4;
parameter STP2a = 3'd5;
parameter STP2b = 3'd6;

reg [2:0] state = IDLE;
reg wcm;
reg [13:0] ma;
reg  [5:0] bn;
reg [63:0] da;
wire [63:0] memo;
reg [63:0] mem [0:16383];

reg [19:0] stpa, stpb;
reg [1:0] sf;

always @(posedge clk_i)
begin
	case(state)
	IDLE:
		begin
			wcm <= 1'b0;
			ack_o <= 1'b0;
			if (cs_i) begin
				ma <= {mapno,adr_i[10:3]};
				da <= dat_i;
				wcm <= wr_i;
				if (!wr_i)
					state <= ACC;
				else
					ack_o <= 1'b1;
			end
			else if (stp) begin
				ma <= {mapno,adr_i[18:11]};
				bn <= adr_i[10:5];
				state <= STP1a;
			end
		end
	ACC:
		begin
			dat_o <= memo;
			ack_o <= 1'b1;
			state <= IDLE;
		end
	STP1a:
		begin
			da <= memo;
			state <= STP1b;
		end
	STP1b:
		begin
			da <= da | (64'd1 << bn);
			wcm <= 1'b1;
			state <= STP1c;
		end
	STP1c:
		begin
			wcm <= 1'b0;
			ma <= {mapno,6'd0,adr_i[18:17]};
			bn <= adr_i[16:11];
			state <= STP2a;
		end
	STP2a:
		begin
			da <= memo;
			state <= STP2b;
		end
	STP2b:
		begin
			da <= da | (64'd1 << bn);
			wcm <= 1'b1;
			state <= IDLE;
		end
	default:
		state <= IDLE;
	endcase
end

always @(posedge clk_i)
	if (wcm)
		mem[ma] <= da;

assign memo = mem[ma];

endmodule
