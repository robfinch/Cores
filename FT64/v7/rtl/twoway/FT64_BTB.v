// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_BTB.v
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
module FT64_BTB(rst, wclk,
		wr0, wadr0, wdat0, valid0,
		wr1, wadr1, wdat1, valid1,
		wr2, wadr2, wdat2, valid2,
		rclk, pcA, btgtA, pcB, btgtB,
		pcC, btgtC, pcD, btgtD, pcE, btgtE, pcF, btgtF,
		hitA, hitB, hitC, hitD, hitE, hitF,
    npcA, npcB, npcC, npcD, npcE, npcF);
parameter AMSB = 63;
parameter RSTPC = 64'hFFFFFFFFFFFC0100;
input rst;
input wclk;
input wr0;
input [AMSB:0] wadr0;
input [AMSB:0] wdat0;
input valid0;
input wr1;
input [AMSB:0] wadr1;
input [AMSB:0] wdat1;
input valid1;
input wr2;
input [AMSB:0] wadr2;
input [AMSB:0] wdat2;
input valid2;
input rclk;
input [AMSB:0] pcA;
output [AMSB:0] btgtA;
input [AMSB:0] pcB;
output [AMSB:0] btgtB;
input [AMSB:0] pcC;
output [AMSB:0] btgtC;
input [AMSB:0] pcD;
output [AMSB:0] btgtD;
input [AMSB:0] pcE;
output [AMSB:0] btgtE;
input [AMSB:0] pcF;
output [AMSB:0] btgtF;
output hitA;
output hitB;
output hitC;
output hitD;
output hitE;
output hitF;
input [AMSB:0] npcA;
input [AMSB:0] npcB;
input [AMSB:0] npcC;
input [AMSB:0] npcD;
input [AMSB:0] npcE;
input [AMSB:0] npcF;

integer n;
reg [AMSB:0] pcs [0:31];
reg [AMSB:0] wdats [0:31];
reg [AMSB:0] wdat;
reg [4:0] pcstail,pcshead;
reg [AMSB:0] pc;
reg takb;
reg wrhist;

reg [(AMSB+1)*2+1:0] mem [0:1023];
reg [9:0] radrA, radrB, radrC, radrD, radrE, radrF;
initial begin
    for (n = 0; n < 1024; n = n + 1)
        mem[n] <= RSTPC;
end

always @(posedge wclk)
if (rst)
	pcstail <= 5'd0;
else begin
	case({wr0,wr1,wr2})
	3'b000:	;
	3'b001:
		begin
		pcs[pcstail] <= {wadr2[31:1],valid2};
		wdats[pcstail] <= wdat2;
		pcstail <= pcstail + 5'd1;
		end
	3'b010:
		begin
		pcs[pcstail] <= {wadr1[31:1],valid1};
		wdats[pcstail] <= wdat1;
		pcstail <= pcstail + 5'd1;
		end
	3'b011:
		begin
		pcs[pcstail] <= {wadr1[31:1],valid1};
		pcs[pcstail+1] <= {wadr2[31:1],valid2};
		wdats[pcstail] <= wdat1;
		wdats[pcstail+1] <= wdat2;
		pcstail <= pcstail + 5'd2;
		end
	3'b100:
		begin
		pcs[pcstail] <= {wadr0[31:1],valid0};
		wdats[pcstail] <= wdat0;
		pcstail <= pcstail + 5'd1;
		end
	3'b101:
		begin
		pcs[pcstail] <= {wadr0[31:1],valid0};
		pcs[pcstail+1] <= {wadr2[31:1],valid2};
		wdats[pcstail] <= wdat0;
		wdats[pcstail+1] <= wdat2;
		pcstail <= pcstail + 5'd2;
		end
	3'b110:
		begin
		pcs[pcstail] <= {wadr0[31:1],valid0};
		pcs[pcstail+1] <= {wadr1[31:1],valid1};
		wdats[pcstail] <= wdat0;
		wdats[pcstail+1] <= wdat1;
		pcstail <= pcstail + 5'd2;
		end
	3'b111:
		begin
		pcs[pcstail] <= {wadr0[31:1],valid0};
		pcs[pcstail+1] <= {wadr1[31:1],valid1};
		pcs[pcstail+2] <= {wadr2[31:1],valid2};
		wdats[pcstail] <= wdat0;
		wdats[pcstail+1] <= wdat1;
		wdats[pcstail+2] <= wdat2;
		pcstail <= pcstail + 5'd3;
		end
	endcase
end

always @(posedge wclk)
if (rst)
	pcshead <= 5'd0;
else begin
	wrhist <= 1'b0;
	if (pcshead != pcstail) begin
		pc <= pcs[pcshead];
		takb <= pcs[pcshead][0];
		wdat <= wdats[pcshead];
		wrhist <= 1'b1;
		pcshead <= pcshead + 5'd1;
	end
end


always @(posedge wclk)
begin
    if (wrhist) #1 mem[pc[9:0]][AMSB:0] <= wdat;
    if (wrhist) #1 mem[pc[9:0]][(AMSB+1)*2:AMSB+1] <= pc;
    if (wrhist) #1 mem[pc[9:0]][(AMSB+1)*2+1] <= takb;
end

always @(posedge rclk)
    #1 radrA <= pcA[11:2];
always @(posedge rclk)
    #1 radrB <= pcB[11:2];
always @(posedge rclk)
    #1 radrC <= pcC[11:2];
always @(posedge rclk)
    #1 radrD <= pcD[11:2];
always @(posedge rclk)
    #1 radrE <= pcE[11:2];
always @(posedge rclk)
    #1 radrF <= pcF[11:2];
assign hitA = mem[radrA][(AMSB+1)*2:AMSB+1]==pcA && mem[radrA][(AMSB+1)*2+1];
assign hitB = mem[radrB][(AMSB+1)*2:AMSB+1]==pcB && mem[radrB][(AMSB+1)*2+1];
assign hitC = mem[radrC][(AMSB+1)*2:AMSB+1]==pcC && mem[radrC][(AMSB+1)*2+1];
assign hitD = mem[radrD][(AMSB+1)*2:AMSB+1]==pcD && mem[radrD][(AMSB+1)*2+1];
assign hitE = mem[radrE][(AMSB+1)*2:AMSB+1]==pcE && mem[radrE][(AMSB+1)*2+1];
assign hitF = mem[radrF][(AMSB+1)*2:AMSB+1]==pcF && mem[radrF][(AMSB+1)*2+1];
assign btgtA = hitA ? mem[radrA][AMSB:0] : npcA;
assign btgtB = hitB ? mem[radrB][AMSB:0] : npcB;
assign btgtC = hitC ? mem[radrC][AMSB:0] : npcC;
assign btgtD = hitD ? mem[radrD][AMSB:0] : npcD;
assign btgtE = hitE ? mem[radrE][AMSB:0] : npcE;
assign btgtF = hitF ? mem[radrF][AMSB:0] : npcF;

endmodule
