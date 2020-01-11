// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2020  Robert Finch, Waterloo
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
`include "..\inc\Gambit-defines.sv"
`include "..\inc\Gambit-config.sv"
`include "..\inc\Gambit-types.sv"

module extBusArbiter(rst, clk, cyc, ack_i, icyc, wb_has_bus, d0cyc, d1cyc, dcyc, mwhich, mstate);
input rst;
input clk;
input cyc;
input ack_i;
input icyc;
input wb_has_bus;
input d0cyc;
input d1cyc;
input dcyc;
output BusChannel mwhich;
output reg [3:0] mstate;

always @(posedge clk)
if (rst) begin
	mwhich <= BC_NULL;
	mstate <= 1'd0;
end
else begin
	case(mstate)
	4'd0:
	if (~ack_i) begin
		if (icyc) begin
			mwhich <= BC_ICACHE;
			mstate <= 4'd1;
		end
		else if (wb_has_bus) begin
			mwhich <= BC_WRITEBUF;
			mstate <= 4'd1;
		end
		else if (d0cyc) begin
			mwhich <= BC_DCACHE0;
			mstate <= 4'd1;
		end
		else if (d1cyc) begin
			mwhich <= BC_DCACHE1;
			mstate <= 4'd1;
		end
		else if (dcyc) begin
			mwhich <= BC_UNCDATA;
			mstate <= 4'd1;
		end
		else begin
			mwhich <= BC_NULL;
		end
	end
4'd1:
	if (~cyc)
		mstate <= 4'd0;
endcase
end

endmodule
