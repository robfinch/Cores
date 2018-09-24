// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_dcache.v
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
//
// ============================================================================
//
// Cache lines are 8 words long plus one hidden word for pointer tags
// The virtual address is multiplied by 9/8 to generate the physical address
// The tag memory is indexed by the virtual address.

module FT64_dcache(rst, wclk, ld, ldt, wr, sel, adr, i, spt, pti, rclk, o, pto, hit);
input rst;
input wclk;				// write clock
input ld;				// load cache data
input ldt;				// load tagmem
input wr;		
input [7:0] sel;
input [37:0] adr;		// virtual address
input [63:0] i;
input spt;				// write pointer tag
input [7:0] pti;		// pointer tag value to write
input rclk;
output reg [63:0] o;
output reg [7:0] pto;	// pointer tag output
output reg hit;
parameter byt = 3'd0;
parameter wyde = 3'd1;
parameter tetra = 3'd2;
parameter octa = 3'd3;

integer n;

wire [63:0] dc0;
wire [31:0] v0, v1;
wire hit0a, hit1a;

wire [42:0] iadr33 = {adr,3'd0} + adr;	// 9*
wire [37:0] iadr = iadr33[42:3];		// /8
//wire [37:0] itadr = {iadr[42:6],6'd0} + 38'd64;
wire [2:0] itbitndx = {adr[5:3],3'd0};

reg [89:0] tagmem [0:255];
always @(posedge wclk)
if (rst) begin
	for (n = 0; n < 256; n = n + 1)
		tagmem[n][1:0] <= 2'b00;	// clear valid and dirty bits
end
else begin
	casez({ldt,spt})
	2'b1?:	tagmem[adr[13:6]][89:0] <= {adr[37:14],1'b0,i};	// clear dirty bit on cache load
	2'b01:
		if (hit) begin
			tagmem[adr[13:6]][89:64] <= {adr[37:14],1'b1};
			for (n = 0; n < 8; n = n + 1)
			tagmem[adr[13:6]][itbitndx|n] <= pti[n];
		end
	endcase
end

wire hit1 = tagmem[adr[13:6]][89:65]==adr[37:14] && tagmem[adr[13:6]][64]==1'b1;
reg hit2;

dcache_mem u1
(
	.rst(rst),
	.clka(wclk),
	.ena( wr | ld),
	.wea( ld ? 8'hFF: sel),
	.addra(adr[13:3]),
	.dina(i),
	.clkb(rclk),
	.addrb(adr[13:3]),
	.doutb(dc0),
	.ov(v0)
);

always @(posedge rclk)
	o <= dc0;
always @(posedge rclk)
	hit2 <= hit1;
always @(posedge rclk)
	hit <= hit2;
always @(posedge rclk)
begin
	for (n = 0; n < 8; n = n + 1)
	pto[n] <= tagmem[adr[13:6]][{adr[5:3],n[2:0]}];
end

endmodule


module dcache_mem(rst, clka, ena, wea, addra, dina, clkb, addrb, doutb, ov);
input rst;
input clka;
input ena;
input [7:0] wea;
input [13:0] addra;
input [63:0] dina;
input clkb;
input [10:0] addrb;
output reg [63:0] doutb;
output reg [7:0] ov;

reg [63:0] mem [0:2047];
reg [7:0] valid [0:2047];
reg [63:0] doutb1;
reg [7:0] ov1;

integer n;

initial begin
    for (n = 0; n < 2047; n = n + 1)
        valid[n] = 8'h00;
end

always @(posedge clka)
begin
    if (ena & wea[0])  mem[addra[13:3]][7:0] <= dina[7:0];
    if (ena & wea[1])  mem[addra[13:3]][15:8] <= dina[15:8];
    if (ena & wea[2])  mem[addra[13:3]][23:16] <= dina[23:16];
    if (ena & wea[3])  mem[addra[13:3]][31:24] <= dina[31:24];
    if (ena & wea[4])  mem[addra[13:3]][39:32] <= dina[39:32];
    if (ena & wea[5])  mem[addra[13:3]][47:40] <= dina[47:40];
    if (ena & wea[6])  mem[addra[13:3]][55:48] <= dina[55:48];
    if (ena & wea[7])  mem[addra[13:3]][63:56] <= dina[63:56];
    if (ena & wea[0])  valid[addra[13:3]][0] <= 1'b1;
    if (ena & wea[1])  valid[addra[13:3]][1] <= 1'b1;
    if (ena & wea[2])  valid[addra[13:3]][2] <= 1'b1;
    if (ena & wea[3])  valid[addra[13:3]][3] <= 1'b1;
    if (ena & wea[4])  valid[addra[13:3]][4] <= 1'b1;
    if (ena & wea[5])  valid[addra[13:3]][5] <= 1'b1;
    if (ena & wea[6])  valid[addra[13:3]][6] <= 1'b1;
    if (ena & wea[7])  valid[addra[13:3]][7] <= 1'b1;
end

always @(posedge clkb)
     doutb1 <= mem[addrb[13:3]];
always @(posedge clkb)
     doutb <= doutb1;
always @(posedge clkb)
     ov1 <= valid[addrb[13:3]];
always @(posedge clkb)
     ov <= ov1;
endmodule


