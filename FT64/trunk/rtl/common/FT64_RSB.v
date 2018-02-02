// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_RSB.v
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
`include "FT64_defines.vh"

// Return address stack predictor is updated during the fetch stage on the 
// assumption that previous flow controls (branches) predicted correctly.
// Otherwise many small routines wouldn't predict the return address
// correctly because they hit the RET before the CALL reaches the 
// commit stage.

module FT64_RSB(rst, clk, regLR, queued1, queued2,
	fetchbuf0_v, fetchbuf0_pc, fetchbuf0_instr,
	fetchbuf1_v, fetchbuf1_pc, fetchbuf1_instr,
	stompedRets, stompedRet,
	pc
);
parameter AMSB = 31;
parameter DEPTH = 32;
input rst;
input clk;
input [4:0] regLR;
input queued1;
input queued2;
input fetchbuf0_v;
input [31:0] fetchbuf0_instr;
input [AMSB:0] fetchbuf0_pc;
input fetchbuf1_v;
input [31:0] fetchbuf1_instr;
input [AMSB:0] fetchbuf1_pc;
input [3:0] stompedRets;
input stompedRet;
output [AMSB:0] pc;

parameter RSTPC = 32'hFFFC0100;
integer n;
reg [AMSB:0] ras [0:DEPTH-1];
reg [4:0] rasp;
assign pc = ras[rasp];

always @(posedge clk)
if (rst) begin
    for (n = 0; n < 32; n = n + 1)
         ras[n] <= RSTPC;
     rasp <= 5'd0;
end
else begin
	if (fetchbuf0_v && fetchbuf1_v && (queued1 || queued2)) begin
        case(fetchbuf0_instr[`INSTRUCTION_OP])
        `JAL:
        	begin
	        	// JAL LR,xxxx	assume call
	        	if (fetchbuf0_instr[`INSTRUCTION_RB]==regLR) begin
	                ras[((rasp-6'd1)&31)] <= fetchbuf0_pc + 32'd4;
	                rasp <= rasp - 4'd1;
	        	end
	        	// JAL r0,[r29]	assume a ret
	        	else if (fetchbuf0_instr[`INSTRUCTION_RB]==5'd00 &&
	        			 fetchbuf0_instr[`INSTRUCTION_RA]==regLR) begin
	        		rasp <= rasp + 4'd1;
	        	end
        	end
        `CALL:
            begin
                 ras[((rasp-6'd1)&31)] <= fetchbuf0_pc + 32'd4;
                 rasp <= rasp - 4'd1;
            end
        `RET:   begin 
        		$display("RSP: Added 1");
        		rasp <= rasp + 4'd1;
        		end
        default:	;
        endcase
	end
    else if (fetchbuf1_v && queued1)
        case(fetchbuf1_instr[`INSTRUCTION_OP])
        `JAL:
        	if (fetchbuf1_instr[`INSTRUCTION_RB]==regLR) begin
                 ras[((rasp-6'd1)&31)] <= fetchbuf1_pc + 32'd4;
                 rasp <= rasp - 4'd1;
        	end
        	else if (fetchbuf1_instr[`INSTRUCTION_RB]==5'd00 &&
        			 fetchbuf1_instr[`INSTRUCTION_RA]==regLR) begin
        		rasp <= rasp + 4'd1;
        	end
        `CALL:
            begin
                 ras[((rasp-6'd1)&31)] <= fetchbuf1_pc + 32'd4;
                 rasp <= rasp - 4'd1;
            end
        `RET:   begin
        		rasp <= rasp + 4'd1;
        		$display("RSP: Added 1");
        		end
        default:	;
        endcase
    else if (fetchbuf0_v && queued1)
        case(fetchbuf0_instr[`INSTRUCTION_OP])
        `JAL:
        	if (fetchbuf0_instr[`INSTRUCTION_RB]==regLR) begin
                 ras[((rasp-6'd1)&31)] <= fetchbuf0_pc + 32'd4;
                 rasp <= rasp - 4'd1;
        	end
        	else if (fetchbuf0_instr[`INSTRUCTION_RB]==5'd00 &&
        			 fetchbuf0_instr[`INSTRUCTION_RA]==regLR) begin
        		rasp <= rasp + 4'd1;
        	end
        `CALL:
            begin
                 ras[((rasp-6'd1)&31)] <= fetchbuf0_pc + 32'd4;
                 rasp <= rasp - 4'd1;
            end
        `RET:   begin 
        		$display("RSP: Added 1");
        		rasp <= rasp + 4'd1;
        		end
        default:	;
        endcase
    if (stompedRets > 4'd0) begin
    	$display("Stomped Rets: %d", stompedRets);
    	rasp <= rasp - stompedRets;
    end
    else if (stompedRet) begin
    	$display("Stomped Ret");
    	rasp <= rasp - 5'd1;
    end
end

endmodule
