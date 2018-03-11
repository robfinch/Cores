// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
// FAL6567_PaletteInit.v
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
`define HIGH	1'b1
`define LOW		1'b0

module FAL6567_PaletteInit(rst, clk, rst_pal, req, ack, adr, dat);
input rst;
input clk;
input rst_pal;
output reg req;
input ack;
output reg [7:0] adr;
output reg [7:0] dat;
parameter IDLE = 6'd0;
parameter WRADR = 6'd1;
parameter WRADR_ACK = 6'd2;
parameter WRRED = 6'd3;
parameter WRRED_ACK = 6'd4;
parameter WRGREEN = 6'd5;
parameter WRGREEN_ACK = 6'd6;
parameter WRBLUE = 6'd7;
parameter WRBLUE_ACK = 6'd8;
parameter WRMASK = 6'd9;
parameter WRMASK_ACK = 6'd10;

reg [5:0] state;
reg [3:0] cnt;
reg [17:0] tbl [0:15];
initial begin
	tbl[0] = 18'h04_04_04; // black			000100_000100_000100
	tbl[1] = 18'h3f_3f_3f; // white			111111_111111_111111
	tbl[2] = 18'h38_10_10; // red			111000_010000_010000
	tbl[3] = 18'h18_3f_3f; // cyan			011000_111111_111111
	tbl[4] = 18'h38_18_38; // purple		111000_011000_111000
	tbl[5] = 18'h10_38_10; // green			010000_111000_010000
	tbl[6] = 18'h10_10_38; // blue			010000_010000_111000
	tbl[7] = 18'h3f_3f_10; // yellow		111111_111111_010000
	tbl[8] = 18'h38_28_10; // orange		111000_101000_010000
	tbl[9] = 18'h27_1e_12; // brown			100111_011110_010010
	tbl[10] = 18'h3f_28_28; // pink			111111_101000_101000
	tbl[11] = 18'h16_16_16; // dark grey	010110_010110_010110
	tbl[12] = 18'h22_22_22; // medium grey	100010_100010_100010
	tbl[13] = 18'h28_3f_28; // light green	101000_111111_101000
	tbl[14] = 18'h28_28_3f; // light blue	101000_101000_111111
	tbl[15] = 18'h30_30_30; // light grey	110000_110000_110000
end

always @(posedge clk)
if (rst) begin
	req <= `LOW;
	state <= WRADR;
	cnt <= 4'h0;
end
else begin
case(state)
IDLE:
	if (rst_pal)
		state <= WRADR;
WRADR:
	begin
		req <= `HIGH;
		adr <= 8'h3C;
		dat <= {4'h0,cnt};
		state <= WRADR_ACK;
	end
WRADR_ACK:
	if (ack) begin
		req <= `LOW;
		state <= WRRED;
	end
WRRED:
	begin
		req <= `HIGH;
		adr <= 8'h3D;
		dat <= {2'b0,tbl[cnt][17:12]};
		state <= WRRED_ACK;
	end
WRRED_ACK:
	if (ack) begin
		req <= `LOW;
		state <= WRGREEN;
	end
WRGREEN:
	begin
		req <= `HIGH;
		adr <= 8'h3D;
		dat <= {2'b0,tbl[cnt][11:6]};
		state <= WRGREEN_ACK;
	end
WRGREEN_ACK:
	if (ack) begin
		req <= `LOW;
		state <= WRBLUE;
	end
WRBLUE:
	begin
		req <= `HIGH;
		adr <= 8'h3D;
		dat <= {2'b0,tbl[cnt][5:0]};
		state <= WRBLUE_ACK;
	end
WRBLUE_ACK:
	if (ack) begin
		cnt <= cnt + 4'd1;
		req <= `LOW;
		if (cnt==4'hF)
			state <= WRMASK;
		else
			state <= WRADR;		
	end
WRMASK:
	begin
		req <= `HIGH;
		adr <= 8'h3E;
		dat <= 8'h0F;
		state <= WRMASK_ACK;
	end
WRMASK_ACK:
	if (ack) begin
		req <= `LOW;
		state <= IDLE;
	end
default:
	begin
		req <= `LOW;
		state <= IDLE;
	end
endcase
end

endmodule
