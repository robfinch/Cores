// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
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
// ============================================================================
//
module Timeouter(rst_i, clk_i, dec_i, set_i, qry_i, tid_i, timeout_i, timeout_o, zeros_o, done_o);
parameter MAX_TID = 63;
parameter LOG_MAX_TID = 5;
input rst_i;
input clk_i;
input dec_i;
input set_i;
input qry_i;
input [LOG_MAX_TID:0] tid_i;
input [63:0] timeout_i;
output reg [63:0] timeout_o;
output reg [63:0] zeros_o;
output reg done_o;

reg [47:0] tmo [0:MAX_TID];
reg [LOG_MAX_TID:0] ndx;
reg [2:0] state;
parameter IDLE = 3'd0;
parameter DEC1 = 3'd1;
parameter SET1 = 3'd2;
parameter QRY1 = 3'd3;

always @(posedge clk_i)
if (rst_i) begin
	zeros_o <= {MAX_TID+1{1'b1}};
	done_o <= 1'b1;
	goto (IDLE);
end
else begin
case(state)
IDLE:
	begin
		if (dec_i) begin
			ndx <= 1'd0;
			goto (DEC1);
		end
		else if (set_i) begin
			ndx <= tid_i;
			done_o <= 1'b0;
			goto (SET1);
		end
		else if (qry_i) begin
			ndx <= tid_i;
			done_o <= 1'b0;
			goto (QRY1);
		end		
	end
DEC1:
	begin
		ndx <= ndx + 1;
		if (tmo[ndx] > 48'd0) begin
			tmo[ndx] <= tmo[ndx] - 2'd1;
			zeros_o[ndx] <= 1'b0;
		end
		else
			zeros_o[ndx] <= 1'b1;
		if (&ndx) begin
			goto (IDLE);
		end
	end
SET1:
	begin
		tmo[ndx] <= timeout_i[47:0];
		done_o <= 1'b1;
		goto (IDLE);
	end
QRY1:
	begin
		timeout_o <= {{16{tmo[ndx][47]}},tmo[ndx]};
		done_o <= 1'b1;
		goto (IDLE);
	end
endcase
end

task goto;
input [2:0] nst;
begin
	state <= nst;
end
endtask

endmodule
