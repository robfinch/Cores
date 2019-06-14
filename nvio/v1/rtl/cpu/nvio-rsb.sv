// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2019  Robert Finch, Waterloo
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
`include "nvio-defines.sv"
`include "nvio-config.sv"

// Return address stack predictor is updated during the fetch stage on the 
// assumption that previous flow controls (branches) predicted correctly.
// Otherwise many small routines wouldn't predict the return address
// correctly because they hit the RET before the CALL reaches the 
// commit stage.

module RSB(rst, clk, clk2x, clk4x, regLR, queuedOn,
	jal, Ra, Rd,
	call, ret,
	ip, ra,
	stompedRets, stompedRet
);
parameter AMSB = 79;
parameter DEPTH = 16;
parameter QSLOTS = `QSLOTS;
input rst;
input clk;
input clk2x;
input clk4x;
input [5:0] regLR;
input [QSLOTS-1:0] queuedOn;
input [QSLOTS-1:0] jal;
input [6:0] Ra [0:QSLOTS-1];
input [6:0] Rd [0:QSLOTS-1];
input [QSLOTS-1:0] call;
input [QSLOTS-1:0] ret;
input [AMSB:0] ip;
input [2:0] stompedRets;
input stompedRet;
output [AMSB:0] ra;

parameter RSTPC = 80'hFFFFFFFFFFFFFFFC0100;
integer n;
reg [AMSB:0] ras [0:DEPTH-1];
reg [3:0] rasp;
assign ra = ras[rasp];

function [AMSB:0] ip_plus_one;
input [AMSB:0] ip;
case(ip[3:2])
2'b00:	ip_plus_one = {ip[AMSB:4],4'h5};
2'b01:	ip_plus_one = {ip[AMSB:4],4'hA};
2'b10:	ip_plus_one = {ip[AMSB:4]+2'd1,4'h0};
2'b11:	ip_plus_one = {ip[AMSB:4]+2'd1,4'h0};
endcase
endfunction

wire slot0_mod = queuedOn[0] && (((jal[0] && Rd[0][5:0]==6'd61) || call[0]) || ((jal[0] && Ra[0][5:0]==6'd61) || ret[0]));
wire slot1_mod = queuedOn[1] && (((jal[1] && Rd[1][5:0]==6'd61) || call[1]) || ((jal[1] && Ra[1][5:0]==6'd61) || ret[1]));

always @(posedge clk4x)
if (rst) begin
  for (n = 0; n < DEPTH; n = n + 1)
    ras[n] <= RSTPC;
  rasp <= 4'd0;
end
else begin
	case({clk,clk2x})
	2'b00:	
		if (queuedOn[0]) begin
			if ((jal[0] && Rd[0][5:0]==6'd61) || call[0]) begin
        ras[((rasp-2'd1)&(DEPTH-1))] <= ip_plus_one(ip);
        rasp <= rasp - 4'd1;
      end
      else if ((jal[0] && Ra[0][5:0]==6'd61) || ret[0]) begin
        rasp <= rasp + 4'd1;
      end
		end
	2'b01:
		if (queuedOn[1] && !slot0_mod) begin
			if ((jal[1] && Rd[1][5:0]==6'd61) || call[1]) begin
        ras[((rasp-2'd1)&(DEPTH-1))] <= ip_plus_one({ip[AMSB:4],4'h5});
        rasp <= rasp - 4'd1;
      end
      else if ((jal[1] && Ra[1][5:0]==6'd61) || ret[1]) begin
        rasp <= rasp + 4'd1;
      end
		end
	2'b10:
		if (queuedOn[2] && !slot0_mod && !slot1_mod) begin
			if ((jal[2] && Rd[2][5:0]==6'd61) || call[2]) begin
        ras[((rasp-2'd1)&(DEPTH-1))] <= ip_plus_one({ip[AMSB:4],4'hA});
        rasp <= rasp - 4'd1;
      end
      else if ((jal[2] && Ra[2][5:0]==6'd61) || ret[2]) begin
        rasp <= rasp + 4'd1;
      end
		end
	default:	;
	endcase
/*        
    if (stompedRets > 4'd0) begin
    	$display("Stomped Rets: %d", stompedRets);
    	rasp <= rasp - stompedRets;
    end
    else if (stompedRet) begin
    	$display("Stomped Ret");
    	rasp <= rasp - 5'd1;
    end
*/
end

endmodule
