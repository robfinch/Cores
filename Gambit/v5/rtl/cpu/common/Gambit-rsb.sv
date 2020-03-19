// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2020  Robert Finch, Waterloo
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
`include "..\inc\Gambit-defines.sv"
`include "..\inc\Gambit-config.sv"
`include "..\inc\Gambit-types.sv"

// Return address stack predictor is updated during the fetch stage on the 
// assumption that previous flow controls (branches) predicted correctly.
// Otherwise many small routines wouldn't predict the return address
// correctly because they hit the RET before the CALL reaches the 
// commit stage.

module RSB(rst, clk, clk2x, clk4x, queuedOn,
	jal, Rd,
	ret,
	pc, len1, len2, ra,
	stompedRets, stompedRet
);
parameter AMSB = `AMSB;
parameter DEPTH = 16;
parameter QSLOTS = `QSLOTS;
input rst;
input clk;
input clk2x;
input clk4x;
input [QSLOTS-1:0] queuedOn;
input [QSLOTS-1:0] jal;
input [6:0] Rd [0:QSLOTS-1];
input [QSLOTS-1:0] ret;
input Address pc;
input [2:0] len1;
input [2:0] len2;
input [2:0] stompedRets;
input stompedRet;
output Address ra;

parameter RSTPC = 52'hFFFFFFFFE0000;
integer n;
reg [AMSB:0] ras [0:DEPTH-1];
reg [3:0] rasp;
always @(posedge clk)
	ra <= ras[rasp];

wire slot0_mod = queuedOn[0] && (jal[0] && Rd[0]!=7'd96) || (ret[0]);
wire slot1_mod = queuedOn[1] && (jal[1] && Rd[1]!=7'd96) || (ret[1]);

always @(posedge clk2x)
if (rst) begin
  for (n = 0; n < DEPTH; n = n + 1)
    ras[n] <= RSTPC;
  rasp <= 4'd0;
end
else begin
	case(clk)
	1'b0:	
		if (queuedOn[0]) begin
			if (jal[0] && Rd[0]!=7'd96) begin
        ras[((rasp-2'd1)&(DEPTH-1))] <= pc + len1;
        rasp <= rasp - 4'd1;
      end
      else if (ret[0]) begin
        rasp <= rasp + 4'd1;
      end
		end
	1'b1:
		if (queuedOn[1] && !slot0_mod) begin
			if (jal[1] && Rd[1]!=7'd96) begin
        ras[((rasp-2'd1)&(DEPTH-1))] <= pc + len1 + len2;
        rasp <= rasp - 4'd1;
      end
      else if (ret[1]) begin
        rasp <= rasp + 4'd1;
      end
		end
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
