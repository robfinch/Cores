// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2020  Robert Finch, Waterloo
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
`include "..\inc\Gambit-config.sv"
`include "..\inc\Gambit-types.sv"

module BTB(rst, clk, clk2x, clk4x,
		wr0, wadr0, wdat0, valid0,
		wr1, wadr1, wdat1, valid1,
		wr2, wadr2, wdat2, valid2,
		rclk, pcA, btgtA, pcB, btgtB,
		hitA, hitB, 
    npcA, npcB );
parameter AMSB = `AMSB;
parameter RSTIP = 52'hFFFFFFFFE0000;
parameter BTBSZ = 512;
localparam BTBAB = $clog2(BTBSZ);
input rst;
input clk;
input clk2x;
input clk4x;
input wr0;
input Address wadr0;
input Address wdat0;
input valid0;
input wr1;
input Address wadr1;
input Address wdat1;
input valid1;
input wr2;
input Address wadr2;
input Address wdat2;
input valid2;
input rclk;
input Address pcA;
output Address btgtA;
input Address pcB;
output Address btgtB;
output hitA;
output hitB;
input Address npcA;
input Address npcB;

integer n;
reg [AMSB+1:0] pcs [0:31];
Address wdats [0:31];
reg [4:0] pcstail,pcshead;
Address pc;
reg takb;
reg wrhist;

(* ram_style="distributed" *)
reg [(AMSB+1)*2:0] mem [0:BTBSZ-1];
reg [BTBAB:0] radrA, radrB, radrC;
initial begin
  for (n = 0; n < BTBSZ; n = n + 1)
    mem[n] <= RSTIP;
end
reg wr;
Address wadr;
reg valid;
Address wdat, wdatx;

// Registeration of input signals.
reg wr0r,wr1r,wr2r;
Address wadr0r,wadr1r,wadr2r;
reg valid0r, valid1r, valid2r;
Address wdat0r, wdat1r, wdat2r;

always @(posedge clk)
begin
		wr0r <= wr0;
		wr1r <= wr1;
		wr2r <= wr2;
		wadr0r <= wadr0;
		wadr1r <= wadr1;
		wadr2r <= wadr2;
		valid0r <= valid0;
		valid1r <= valid1;
		valid2r <= valid2;
		wdat0r <= wdat0;
		wdat1r <= wdat1;
		wdat2r <= wdat2;
end

always @*
case({clk,clk2x})
2'b00:	
	begin
		wr <= wr0r;
		wadr <= wadr0r;
		valid <= valid0r;
		wdat <= wdat0r;
	end
2'b01:
	begin
		wr <= wr1r;
		wadr <= wadr1r;
		valid <= valid1r;
		wdat <= wdat1r;
	end
2'b10:
	begin
		wr <= wr2r;
		wadr <= wadr2r;
		valid <= valid2r;
		wdat <= wdat2r;
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
		pcs[pcstail] <= {valid,wadr[AMSB:0]};
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
		pc <= pcs[pcshead][AMSB:0];
		takb <= pcs[pcshead][AMSB+1];
		wdatx <= wdats[pcshead];
		wrhist <= 1'b1;
		pcshead <= pcshead + 5'd1;
	end
end

always @(posedge clk)
begin
    if (wrhist) #1 mem[pc[BTBAB:0]][AMSB:0] <= wdatx;
    if (wrhist) #1 mem[pc[BTBAB:0]][(AMSB+1)*2-1:AMSB+1] <= pc;
    if (wrhist) #1 mem[pc[BTBAB:0]][(AMSB+1)*2] <= takb;
end

always @*
    #1 radrA <= pcA[BTBAB:0];
always @*
    #1 radrB <= pcB[BTBAB:0];
assign hitA = mem[radrA][(AMSB+1)*2-1:AMSB+1]==pcA && mem[radrA][(AMSB+1)*2];
assign hitB = mem[radrB][(AMSB+1)*2-1:AMSB+1]==pcB && mem[radrB][(AMSB+1)*2];
assign btgtA = hitA ? mem[radrA][AMSB:0] : npcA;
assign btgtB = hitB ? mem[radrB][AMSB:0] : npcB;

endmodule
