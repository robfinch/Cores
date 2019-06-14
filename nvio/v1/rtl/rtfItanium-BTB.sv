// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
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
module BTB(rst, clk, clk2x, clk4x,
		wr0, wadr0, wdat0, valid0,
		wr1, wadr1, wdat1, valid1,
		wr2, wadr2, wdat2, valid2,
		rclk, pcA, btgtA, pcB, btgtB,
		pcC, btgtC,
		hitA, hitB, hitC, 
    npcA, npcB, npcC );
parameter AMSB = 31;
parameter RSTIP = 80'hFFFFFFFFFFFFFFFC0100;
input rst;
input clk;
input clk2x;
input clk4x;
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
output hitA;
output hitB;
output hitC;
input [AMSB:0] npcA;
input [AMSB:0] npcB;
input [AMSB:0] npcC;

integer n;
reg [AMSB:0] pcs [0:31];
reg [AMSB:0] wdats [0:31];
reg [4:0] pcstail,pcshead;
reg [AMSB:0] pc;
reg takb;
reg wrhist;

(* ram_style="block" *)
reg [(AMSB+1)*2+1:0] mem [0:1023];
reg [9:0] radrA, radrB, radrC, radrD, radrE, radrF;
initial begin
  for (n = 0; n < 1024; n = n + 1)
    mem[n] <= RSTIP;
end
reg wr;
reg [AMSB:0] wadr;
reg valid;
reg [AMSB:0] wdat, wdatx;

always @*
case({clk,clk2x})
2'b00:	
	begin
		wr <= wr0;
		wadr <= wadr0;
		valid <= valid0;
		wdat <= wdat0;
	end
2'b01:
	begin
		wr <= wr1;
		wadr <= wadr1;
		valid <= valid1;
		wdat <= wdat1;
	end
2'b10:
	begin
		wr <= wr2;
		wadr <= wadr2;
		valid <= valid2;
		wdat <= wdat2;
	end
2'b11:
	begin
		wr <= 1'b0;
		wadr <= 1'd0;
		wdat <= 1'b0;
		valid <= 1'b0;
	end
endcase

always @(posedge clk4x)
if (rst)
	pcstail <= 5'd0;
else begin
	if (wr) begin
		pcs[pcstail] <= {wadr[AMSB:1],valid};
		wdats[pcstail] <= wdat;
		pcstail <= pcstail + 5'd1;
	end	
end

always @(posedge clk)
if (rst)
	pcshead <= 5'd0;
else begin
	wrhist <= 1'b0;
	if (pcshead != pcstail) begin
		pc <= {pcs[pcshead][AMSB:2],pcs[pcshead][3:2]};
		takb <= pcs[pcshead][0];
		wdatx <= wdats[pcshead];
		wrhist <= 1'b1;
		pcshead <= pcshead + 5'd1;
	end
end

always @(posedge clk)
begin
    if (wrhist) #1 mem[pc[11:2]][AMSB:0] <= wdatx;
    if (wrhist) #1 mem[pc[11:2]][(AMSB+1)*2:AMSB+1] <= pc;
    if (wrhist) #1 mem[pc[11:2]][(AMSB+1)*2+1] <= takb;
end

always @(posedge rclk)
    #1 radrA <= pcA[11:2];
always @(posedge rclk)
    #1 radrB <= pcB[11:2];
always @(posedge rclk)
    #1 radrC <= pcC[11:2];
assign hitA = mem[radrA][(AMSB+1)*2:AMSB+1]==pcA && mem[radrA][(AMSB+1)*2+1];
assign hitB = mem[radrB][(AMSB+1)*2:AMSB+1]==pcB && mem[radrB][(AMSB+1)*2+1];
assign hitC = mem[radrC][(AMSB+1)*2:AMSB+1]==pcC && mem[radrC][(AMSB+1)*2+1];
assign btgtA = hitA ? mem[radrA][AMSB:0] : npcA;
assign btgtB = hitB ? mem[radrB][AMSB:0] : npcB;
assign btgtC = hitC ? mem[radrC][AMSB:0] : npcC;

endmodule
