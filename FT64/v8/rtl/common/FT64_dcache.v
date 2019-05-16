// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_dcache.v
//	- a simple direct mapped cache
//	- three cycle latency
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
module FT64_dcache(rst, dce, wclk, wr, sel, wadr, whit, i, li, rclk, rdsize, radr, o, lo, rhit);
input rst;
input dce;					// data cache enable
input wclk;
input wr;
input [31:0] sel;
input [37:0] wadr;
output whit;
input [255:0] i;
input [255:0] li;		// line input
input rclk;
input [2:0] rdsize;
input [37:0] radr;
output reg [63:0] o;
output reg [255:0] lo;	// line out
output reg rhit;
parameter byt = 3'd0;
parameter wyde = 3'd1;
parameter tetra = 3'd2;
parameter octa = 3'd3;

wire [255:0] dc;
wire [31:0] v;
wire rhita;

dcache_mem u1 (
  .rst(rst),
  .clka(wclk),
  .ena(dce & wr),
  .wea(sel),
  .addra(wadr[13:0]),
  .dina(i),
  .clkb(rclk),
  .enb(dce),
  .addrb(radr[13:0]),
  .doutb(dc),
  .ov(v)
);

FT64_dcache_tag u3
(
  .wclk(wclk),
  .dce(dce),
  .wr(wr),
  .wadr(wadr),
  .rclk(rclk),
  .radr(radr),
  .whit(whit),
  .rhit(rhita)
);

wire [7:0] va = v >> radr[4:0];
always @(posedge rclk)
begin
case(rdsize)
byt:    rhit <= rhita &  va[  0];
wyde:   rhit <= rhita & &va[1:0];
tetra:  rhit <= rhita & &va[3:0];
default:rhit <= rhita & &va[7:0];
endcase
end

// hit is also delayed by a clock already
always @(posedge rclk)
	lo <= dc;
always @(posedge rclk)
  o <= dc >> {radr[4:3],6'b0};

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module dcache_mem(rst, clka, ena, wea, addra, dina, clkb, enb, addrb, doutb, ov);
input rst;
input clka;
input ena;
input [31:0] wea;
input [13:0] addra;
input [255:0] dina;
input clkb;
input enb;
input [13:0] addrb;
output reg [255:0] doutb;
output reg [31:0] ov;

reg [255:0] mem [0:511];
reg [31:0] valid [0:511];
reg [255:0] doutb1;
reg [31:0] ov1;

integer n;

initial begin
  for (n = 0; n < 512; n = n + 1)
    valid[n] = 32'h00;
end

genvar g;
generate begin
for (g = 0; g < 32; g = g + 1)
always @(posedge clka)
begin
  if (ena & wea[g])  mem[addra[13:5]][g*8+7:g*8] <= dina[g*8+7:g*8];
  if (ena & wea[g])  valid[addra[13:5]][g] <= 1'b1;
end
end
endgenerate
always @(posedge clkb)
	if (enb)
		doutb1 <= mem[addrb[13:5]];
always @(posedge clkb)
	if (enb)
		doutb <= doutb1;
always @(posedge clkb)
	if (enb)
		ov1 <= valid[addrb[13:5]];
always @(posedge clkb)
	if (enb)
		ov <= ov1;
endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module FT64_dcache_tag(wclk, dce, wr, wadr, rclk, radr, whit, rhit);
input wclk;
input dce;						// data cache enable
input wr;
input [37:0] wadr;
input rclk;
input [37:0] radr;
output reg whit;			// write hit
output reg rhit;			// read hit

wire [31:0] rtago;
wire [31:0] wtago;

FT64_dcache_tag2 u1 (
  .clka(wclk),
  .ena(dce),
  .wea(wr),
  .addra(wadr[13:5]),
  .dina(wadr[37:14]),
  .douta(wtago),
  .clkb(rclk),
  .web(1'b0),
  .dinb(32'd0),
  .enb(dce),
  .addrb(radr[13:5]),
  .doutb(rtago)
);

always @(posedge rclk)
	rhit <= rtago[23:0]==radr[37:14];
always @(posedge wclk)
	whit <= wtago[23:0]==wadr[37:14];

endmodule

