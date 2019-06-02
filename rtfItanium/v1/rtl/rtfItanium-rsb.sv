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
`include "rtfItanium-defines.sv"
`include "rtfItanium-config.sv"

// Return address stack predictor is updated during the fetch stage on the 
// assumption that previous flow controls (branches) predicted correctly.
// Otherwise many small routines wouldn't predict the return address
// correctly because they hit the RET before the CALL reaches the 
// commit stage.

module RSB(rst, clk, clk2x, clk4x, regLR, queued0, queued1, queued2,
	sn0, sn1, sn2,
	jal0, jal1, jal2, Ra0, Ra1, Ra2, Rd0, Rd1, Rd2,
	call0, call1, call2, ret0, ret1, ret2,
	ip,
	stompedRets, stompedRet
);
parameter AMSB = 79;
parameter DEPTH = 16;
input rst;
input clk;
input clk2x;
input clk4x;
input [4:0] regLR;
input [`QBITS] sn0;
input [`QBITS] sn1;
input [`QBITS] sn2;
input queued0;
input queued1;
input queued2;
input jal0;
input jal1;
input jal2;
input [5:0] Ra0;
input [5:0] Ra1;
input [5:0] Ra2;
input [5:0] Rd0;
input [5:0] Rd1;
input [5:0] Rd2;
input call0;
input call1;
input call2;
input ret0;
input ret1;
input ret2;
input [AMSB:0] ip;
input [2:0] stompedRets;
input stompedRet;

parameter RSTPC = 80'hFFFFFFFFFFFFFFFC0100;
integer n;
reg [AMSB:0] ras [0:DEPTH-1];
reg [3:0] rasp;
assign pc = ras[rasp];
reg [`SNBITS] lsn0, lsn1, lsn2;

function [AMSB:0] ip_plus_one;
input [AMSB:0] ip;
case(ip[3:2])
2'b00:	ip_plus_one = {ip[AMSB:4],4'h5};
2'b01:	ip_plus_one = {ip[AMSB:4],4'hA};
2'b10:	ip_plus_one = {ip[AMSB:4]+2'd1,4'h0};
2'b11:	ip_plus_one = {ip[AMSB:4]+2'd1,4'h0};
endcase
endfunction

wire slot0_mod = queued0 && (((jal0 && Rd0==6'd61) || call0) || ((jal0 && Ra0==6'd61) || ret0));
wire slot1_mod = queued1 && (((jal1 && Rd1==6'd61) || call1) || ((jal1 && Ra1==6'd61) || ret1));

always @(posedge clk4x)
if (rst) begin
  for (n = 0; n < DEPTH; n = n + 1)
     ras[n] <= RSTPC;
  rasp <= 4'd0;
end
else begin
	case({clk,clk2x})
	2'b00:	
		if (queued0 && lsn0 != sn0) begin
			if ((jal0 && Rd0==6'd61) || call0) begin
				lsn0 <= sn0;
        ras[((rasp-2'd1)&(DEPTH-1))] <= ip_plus_one(ip);
        rasp <= rasp - 4'd1;
      end
      else if ((jal0 && Ra0==6'd61) || ret0) begin
				lsn0 <= sn0;
        rasp <= rasp + 4'd1;
      end
		end
	2'b01:
		if (queued1 && !slot0_mod && lsn1 != sn1) begin
			if ((jal1 && Rd1==6'd61) || call1) begin
				lsn1 <= sn1;
        ras[((rasp-2'd1)&(DEPTH-1))] <= ip_plus_one({ip[AMSB:4],4'h5});
        rasp <= rasp - 4'd1;
      end
      else if ((jal1 && Ra1==6'd61) || ret1) begin
				lsn1 <= sn1;
        rasp <= rasp + 4'd1;
      end
		end
	2'b10:
		if (queued2 && !slot0_mod && !slot1_mod && lsn2 != sn2) begin
			if ((jal2 && Rd2==6'd61) || call2) begin
				lsn2 <= sn2;
        ras[((rasp-2'd1)&(DEPTH-1))] <= ip_plus_one({ip[AMSB:4],4'hA});
        rasp <= rasp - 4'd1;
      end
      else if ((jal2 && Ra2==6'd61) || ret2) begin
				lsn2 <= sn2;
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
