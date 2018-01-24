// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_AMO_alu.v
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
// ALU for atomic memory operations (AMO)
// AMO ops have their own limited ALU since they can't wait on the usual
// ALU.
// ============================================================================
//
`include "FT64_defines.vh"

module FT64_AMO_alu(instr, a, b, res);
input [31:0] instr;
input [63:0] a;
input [63:0] b;
output reg [63:0] res;

wire [4:0] op = instr[30:26];

always @*
case(op)
`AMO_SWAP:	res <= b;
`AMO_ADD:	case(instr[23:21])
			3'd0,3'd4:
				begin
					res[7:0] <= a[7:0] + b[7:0];
					res[15:8] <= a[15:8] + b[15:8];
					res[23:16] <= a[23:16] + b[23:16];
					res[31:24] <= a[31:24] + b[31:24];
					res[39:32] <= a[39:32] + b[39:32];
					res[47:40] <= a[47:40] + b[47:40];
					res[55:48] <= a[55:48] + b[55:48];
					res[63:56] <= a[63:56] + b[63:56];
				end
			3'd1,3'd5:
				begin
					res[15:0] <= a[15:0] + b[15:0];
					res[31:16] <= a[31:16] + b[31:16];
					res[47:32] <= a[47:32] + b[47:32];
					res[63:48] <= a[63:48] + b[63:48];
				end
			3'd2,3'd6:
				begin
					res[31:0] <= a[31:0] + b[31:0];
					res[63:32] <= a[63:32] + b[63:32];
				end
			3'd3,3'd7:	res <= a + b;
			endcase
`AMO_AND:	res <= a & b;
`AMO_OR:	res <= a | b;
`AMO_XOR:	res <= a ^ b;

`AMO_SHL:	
			case(instr[23:21])
			3'd0,3'd4:
				begin
					res[7:0] <= a[7:0] << b[2:0];
					res[15:8] <= a[15:8] << b[2:0];
					res[23:16] <= a[23:16] << b[2:0];
					res[31:24] <= a[31:24] << b[2:0];
					res[39:32] <= a[39:32] << b[2:0];
					res[47:40] <= a[47:40] << b[2:0];
					res[55:48] <= a[55:48] << b[2:0];
					res[63:56] <= a[63:56] << b[2:0];
				end
			3'd1,3'd5:
				begin
					res[15:0] <= a[15:0] << b[3:0];
					res[31:16] <= a[31:16] << b[3:0];
					res[47:32] <= a[47:32] << b[3:0];
					res[63:48] <= a[63:48] << b[3:0];
				end
			3'd2,3'd6:
				begin
					res[31:0] <= a[31:0] << b[4:0];
					res[63:32] <= a[63:32] << b[4:0];
				end
			3'd3,3'd7:	res <= a << b[5:0];
			endcase			
			
`AMO_SHR:
			case(instr[23:21])
			3'd0,3'd4:
				begin
					res[7:0] <= a[7:0] >> b[2:0];
					res[15:8] <= a[15:8] >> b[2:0];
					res[23:16] <= a[23:16] >> b[2:0];
					res[31:24] <= a[31:24] >> b[2:0];
					res[39:32] <= a[39:32] >> b[2:0];
					res[47:40] <= a[47:40] >> b[2:0];
					res[55:48] <= a[55:48] >> b[2:0];
					res[63:56] <= a[63:56] >> b[2:0];
				end
			3'd1,3'd5:
				begin
					res[15:0] <= a[15:0] >> b[3:0];
					res[31:16] <= a[31:16] >> b[3:0];
					res[47:32] <= a[47:32] >> b[3:0];
					res[63:48] <= a[63:48] >> b[3:0];
				end
			3'd2,3'd6:
				begin
					res[31:0] <= a[31:0] >> b[4:0];
					res[63:32] <= a[63:32] >> b[4:0];
				end
			3'd3,3'd7:	res <= a >> b[5:0];
			endcase			

`AMO_MIN:
			case(instr[23:21])
			3'd0,3'd4:
				begin
					res[7:0] <= $signed(a[7:0]) < $signed(b[7:0]) ? a[7:0] : b[7:0];
					res[15:8] <= $signed(a[15:8]) < $signed(b[15:8]) ? a[15:8] : b[15:8];
					res[23:16] <= $signed(a[23:16]) < $signed(b[23:16]) ? a[23:16] : b[23:16];
					res[31:24] <= $signed(a[31:24]) < $signed(b[31:24]) ? a[31:24] : b[31:24];
					res[39:32] <= $signed(a[39:32]) < $signed(b[39:32]) ? a[39:32] : b[39:32];
					res[47:40] <= $signed(a[47:40]) < $signed(b[47:40]) ? a[47:40] : b[47:40];
					res[55:48] <= $signed(a[55:48]) < $signed(b[55:48]) ? a[55:48] : b[55:48];
					res[63:56] <= $signed(a[63:56]) < $signed(b[63:56]) ? a[63:56] : b[63:56];
				end
			3'd1,3'd5:
				begin
					res[15:0] <= $signed(a[15:0]) < $signed(b[15:0]) ? a[15:0] : b[15:0];
					res[31:16] <= $signed(a[31:16]) < $signed(b[31:16]) ? a[31:16] : b[31:16];
					res[47:32] <= $signed(a[47:32]) < $signed(b[47:32]) ? a[47:32] : b[47:32];
					res[63:48] <= $signed(a[63:48]) < $signed(b[63:48]) ? a[63:48] : b[63:48];
				end
			3'd2,3'd6:
				begin
					res[31:0] <= $signed(a[31:0]) < $signed(b[31:0]) ? a[31:0] : b[31:0];
					res[63:32] <= $signed(a[63:32]) < $signed(b[63:32]) ? a[63:32] : b[63:32];
				end
			3'd3,3'd7:	res <= $signed(a) < $signed(b) ? a : b;
			endcase
`AMO_MAX:	
			case(instr[23:21])
			3'd0,3'd4:
				begin
					res[7:0] <= $signed(a[7:0]) > $signed(b[7:0]) ? a[7:0] : b[7:0];
					res[15:8] <= $signed(a[15:8]) > $signed(b[15:8]) ? a[15:8] : b[15:8];
					res[23:16] <= $signed(a[23:16]) > $signed(b[23:16]) ? a[23:16] : b[23:16];
					res[31:24] <= $signed(a[31:24]) > $signed(b[31:24]) ? a[31:24] : b[31:24];
					res[39:32] <= $signed(a[39:32]) > $signed(b[39:32]) ? a[39:32] : b[39:32];
					res[47:40] <= $signed(a[47:40]) > $signed(b[47:40]) ? a[47:40] : b[47:40];
					res[55:48] <= $signed(a[55:48]) > $signed(b[55:48]) ? a[55:48] : b[55:48];
					res[63:56] <= $signed(a[63:56]) > $signed(b[63:56]) ? a[63:56] : b[63:56];
				end
			3'd1,3'd5:
				begin
					res[15:0] <= $signed(a[15:0]) > $signed(b[15:0]) ? a[15:0] : b[15:0];
					res[31:16] <= $signed(a[31:16]) > $signed(b[31:16]) ? a[31:16] : b[31:16];
					res[47:32] <= $signed(a[47:32]) > $signed(b[47:32]) ? a[47:32] : b[47:32];
					res[63:48] <= $signed(a[63:48]) > $signed(b[63:48]) ? a[63:48] : b[63:48];
				end
			3'd2,3'd6:
				begin
					res[31:0] <= $signed(a[31:0]) > $signed(b[31:0]) ? a[31:0] : b[31:0];
					res[63:32] <= $signed(a[63:32]) > $signed(b[63:32]) ? a[63:32] : b[63:32];
				end
			3'd3,3'd7:	res <= $signed(a) > $signed(b) ? a : b;
			endcase
`AMO_MINU:	
			case(instr[23:21])
			3'd0,3'd4:
				begin
					res[7:0] <= $unsigned(a[7:0]) < $unsigned(b[7:0]) ? a[7:0] : b[7:0];
					res[15:8] <= $unsigned(a[15:8]) < $unsigned(b[15:8]) ? a[15:8] : b[15:8];
					res[23:16] <= $unsigned(a[23:16]) < $unsigned(b[23:16]) ? a[23:16] : b[23:16];
					res[31:24] <= $unsigned(a[31:24]) < $unsigned(b[31:24]) ? a[31:24] : b[31:24];
					res[39:32] <= $unsigned(a[39:32]) < $unsigned(b[39:32]) ? a[39:32] : b[39:32];
					res[47:40] <= $unsigned(a[47:40]) < $unsigned(b[47:40]) ? a[47:40] : b[47:40];
					res[55:48] <= $unsigned(a[55:48]) < $unsigned(b[55:48]) ? a[55:48] : b[55:48];
					res[63:56] <= $unsigned(a[63:56]) < $unsigned(b[63:56]) ? a[63:56] : b[63:56];
				end
			3'd1,3'd5:
				begin
					res[15:0] <= $unsigned(a[15:0]) < $unsigned(b[15:0]) ? a[15:0] : b[15:0];
					res[31:16] <= $unsigned(a[31:16]) < $unsigned(b[31:16]) ? a[31:16] : b[31:16];
					res[47:32] <= $unsigned(a[47:32]) < $unsigned(b[47:32]) ? a[47:32] : b[47:32];
					res[63:48] <= $unsigned(a[63:48]) < $unsigned(b[63:48]) ? a[63:48] : b[63:48];
				end
			3'd2,3'd6:
				begin
					res[31:0] <= $unsigned(a[31:0]) < $unsigned(b[31:0]) ? a[31:0] : b[31:0];
					res[63:32] <= $unsigned(a[63:32]) < $unsigned(b[63:32]) ? a[63:32] : b[63:32];
				end
			3'd3,3'd7:	res <= $unsigned(a) < $unsigned(b) ? a : b;
			endcase
`AMO_MAXU:	
			case(instr[23:21])
			3'd0,3'd4:
				begin
					res[7:0] <= $unsigned(a[7:0]) > $unsigned(b[7:0]) ? a[7:0] : b[7:0];
					res[15:8] <= $unsigned(a[15:8]) > $unsigned(b[15:8]) ? a[15:8] : b[15:8];
					res[23:16] <= $unsigned(a[23:16]) > $unsigned(b[23:16]) ? a[23:16] : b[23:16];
					res[31:24] <= $unsigned(a[31:24]) > $unsigned(b[31:24]) ? a[31:24] : b[31:24];
					res[39:32] <= $unsigned(a[39:32]) > $unsigned(b[39:32]) ? a[39:32] : b[39:32];
					res[47:40] <= $unsigned(a[47:40]) > $unsigned(b[47:40]) ? a[47:40] : b[47:40];
					res[55:48] <= $unsigned(a[55:48]) > $unsigned(b[55:48]) ? a[55:48] : b[55:48];
					res[63:56] <= $unsigned(a[63:56]) > $unsigned(b[63:56]) ? a[63:56] : b[63:56];
				end
			3'd1,3'd5:
				begin
					res[15:0] <= $unsigned(a[15:0]) > $unsigned(b[15:0]) ? a[15:0] : b[15:0];
					res[31:16] <= $unsigned(a[31:16]) > $unsigned(b[31:16]) ? a[31:16] : b[31:16];
					res[47:32] <= $unsigned(a[47:32]) > $unsigned(b[47:32]) ? a[47:32] : b[47:32];
					res[63:48] <= $unsigned(a[63:48]) > $unsigned(b[63:48]) ? a[63:48] : b[63:48];
				end
			3'd2,3'd6:
				begin
					res[31:0] <= $unsigned(a[31:0]) > $unsigned(b[31:0]) ? a[31:0] : b[31:0];
					res[63:32] <= $unsigned(a[63:32]) > $unsigned(b[63:32]) ? a[63:32] : b[63:32];
				end
			3'd3,3'd7:	res <= $unsigned(a) > $unsigned(b) ? a : b;
			endcase
default:	res <= 64'hDEADDEADDEADDEAD;
endcase


endmodule
