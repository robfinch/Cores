`timescale 1ns / 1ps
//=============================================================================
//        __
//   \\__/ o\    (C) 2011-2013  Robert Finch
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
//  
//	SimpleMMU.v
//  - maps 32MB into 512 64kB blocks
//  - supports 16 tasks per mmu
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
// 11 block RAMs // 87 LUTs // 42 FF's // 190 MHz
//=============================================================================
//
module SimpleMMU(num, rst_i, clk_i, dma_i, kernel_mode, me, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i, dat_o, ea_i, ea_o);
parameter pIOAddress = 32'hFFDC4000;
input [2:0] num;		// mmu number
input rst_i;			// core reset
input clk_i;			// clock
input dma_i;			// 1=DMA cycle is active
input kernel_mode;		// 1=processor is in kernel mode
input me;				// map enable
input cyc_i;			// bus cycle active
input stb_i;			// data transfer strobe
output ack_o;			// data transfer acknowledge
input we_i;				// write enable
input [33:0] adr_i;		// I/O register address
input [15:0] dat_i;		// data input
output [15:0] dat_o;	// data output
reg [15:0] dat_o;
input [33:0] ea_i;		// effective data address input
output [33:0] ea_o;		// effective data address mapped
reg [33:0] ea_o;

reg map_enable;
reg forceHi;
reg su;					// 1= system
reg [3:0] fuse;
reg ofuse3;
reg [7:0] accessKey;
reg [7:0] operateKey;
reg [2:0] kvmmu;
reg ack1, ack2;

always @(posedge clk_i)
begin
	ack1 <= cs;
	ack2 <= ack1 & cs;
end
assign ack_o = cs ? (we_i ? 1'b1 : ack2) : 1'b0;

wire cs = cyc_i && stb_i && (adr_i[33:14]==pIOAddress[31:12]);
wire [7:0] oKey =
	dma_i ? 8'd1 :
	su ? 8'd0 :
	operateKey
	;
reg [13:0] rmrad;
reg [13:0] rmra;
reg [13:0] rmrb;
wire [13:0] mwa = {accessKey[4:0],adr_i[10:2]};
wire [13:0] mrad = !me ? {accessKey[4:0],adr_i[10:2]} : {oKey[4:0],ea_i[24:16]};
wire [10:0] mro;

wire thisMMU = kvmmu==accessKey[7:5];

wire pe_stb;
wire pe_km;
edge_det u1 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(stb_i), .pe(pe_stb), .ne(), .ee() );
edge_det u2 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(kernel_mode), .pe(pe_km), .ne(), .ee() );

mapram u3
(
	.wclk(clk_i),
	.wr(cs & we_i & su & ~adr_i[13] & thisMMU),
	.wa(mwa),
	.i(dat_i[10:0]),
	.rclk(~clk_i),
	.ra(mrad),
	.o(mro)
);

always @(posedge clk_i)
if (rst_i) begin
	map_enable <= 1'b0;
	kvmmu <= 3'd0;
	su <= 1'b1;
	fuse <= 4'hF;
	ofuse3 <= 1'b1;
	accessKey <= 8'h00;
	operateKey <= 8'h00;
end
else begin
	ofuse3 <= fuse[3];
	if (!fuse[3] && !dma_i && pe_stb)
		fuse <= fuse - 4'd1;
	if (fuse[3] & !ofuse3)
		su <= 1'b0;
	else if (pe_km)
		su <= 1'b1;

	if (cs) begin
		if (we_i) begin
			if (su) begin
				casex(adr_i[13:2])
//				12'b0xxxxxxxxxx:	if (thisMMU) map[mwa] <= dat_i[9:0];
				12'h80x:	if (oKey==8'h00 && (adr_i[4:2]==num))
									kvmmu <= dat_i[2:0];
				12'h811:	fuse <= dat_i[2:0];
				12'h812:	accessKey <= dat_i[7:0];
				12'h813:	operateKey <= dat_i[7:0];
				12'h814:	map_enable <= dat_i[0];
				endcase
			end
		end
		else begin
			if ((adr_i[4:2]==num) && oKey==8'd0 && adr_i[13:6]==8'b10000000)
				dat_o <= {5'd0,kvmmu};
			else if (thisMMU)
				casex(adr_i[13:2])
				12'b00xxxxxxxxxx:	dat_o <= mro;
				12'h810:	dat_o <= su;
				12'h811:	dat_o <= fuse;
				12'h812:	dat_o <= accessKey;
				12'h813:	dat_o <= operateKey;
				12'h814:	dat_o <= map_enable;
				default:	dat_o <= 16'h0000;
				endcase
			else
				dat_o <= 16'h0000;
		end
	end
	else
		dat_o <= 16'h0000;
end

always @(ea_i) ea_o[15:0] <= ea_i[15:0];
always @(ea_i) ea_o[33:27] <= ea_i[33:27];

always @(oKey or kvmmu or mro or ea_i or map_enable or me)
begin
	if (~(map_enable&me))
		ea_o[26:16] <= ea_i[26:16];
	else if (kvmmu==oKey[7:5])
		ea_o[26:16] <= mro;
	else
		ea_o[26:16] <= 11'h0000;
end

endmodule

module mapram(wclk, wr, wa, i, rclk, ra, o);
input wclk;
input wr;
input [13:0] wa;
input [10:0] i;
input rclk;
input [13:0] ra;
output [10:0] o;

reg [10:0] map [0:16383];
reg [13:0] rra;

always @(posedge wclk)
	if (wr) map[wa] <= i;
always @(posedge rclk) rra <= ra;

assign o = map[rra];

endmodule
