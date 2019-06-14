// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rtfItanium_dcache.v
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
`define TRUE    1'b1
`define FALSE   1'b0

// -----------------------------------------------------------------------------
// Small, 64 line cache memory (2kiB) made from distributed RAM. Access is
// within a single clock cycle.
// -----------------------------------------------------------------------------

module L1_dcache_mem(clk, wr, sel, lineno, i, o);
parameter pLines = 128;
parameter pLineWidth = 331;
localparam pLNMSB = pLines==128 ? 6 : 5;
input clk;
input wr;
input [40:0] sel;
input [pLNMSB:0] lineno;
input [pLineWidth-1:0] i;
output [pLineWidth-1:0] o;

integer n;

(* ram_style="distributed" *)
reg [pLineWidth-1:0] mem [0:pLines-1];

initial begin
	for (n = 0; n < pLines; n = n + 1)
		mem[n] <= {pLineWidth{1'b0}};
end

genvar v;

generate begin : mupd
for (v = 0; v < 41; v = v + 1)
begin : mw
always  @(posedge clk)
	if (wr & sel[v])  mem[lineno][v*8+7:v*8] <= i[v*8+7:v*8];
end
end
endgenerate

assign o = mem[lineno];

endmodule

// -----------------------------------------------------------------------------
// Four way set associative tag memory for L1 cache.
// -----------------------------------------------------------------------------

module L1_dcache_cmptag4way(rst, clk, nxt, wr, invline, invall, adr, lineno, hit);
parameter pLines = 128;
parameter AMSB = 79;
localparam pLNMSB = pLines==128 ? 6 : 5;
localparam pMSB = pLines==128 ? 9 : 8;
input rst;
input clk;
input nxt;
input wr;
input invline;
input invall;
input [AMSB:0] adr;
output reg [pLNMSB:0] lineno;
output hit;

(* ram_style="distributed" *)
reg [AMSB-5:0] mem0 [0:pLines/4-1];
reg [AMSB-5:0] mem1 [0:pLines/4-1];
reg [AMSB-5:0] mem2 [0:pLines/4-1];
reg [AMSB-5:0] mem3 [0:pLines/4-1];
reg [AMSB:0] rradr;
reg [pLines/4-1:0] mem0v;
reg [pLines/4-1:0] mem1v;
reg [pLines/4-1:0] mem2v;
reg [pLines/4-1:0] mem3v;
integer n;
initial begin
  for (n = 0; n < pLines/4; n = n + 1)
  begin
    mem0[n] = 0;
    mem1[n] = 0;
    mem2[n] = 0;
    mem3[n] = 0;
    mem0v[n] = 0;
    mem1v[n] = 0;
    mem2v[n] = 0;
    mem3v[n] = 0;
  end
end

wire [21:0] lfsro;
lfsr #(22,22'h0ACE3) u1 (rst, clk, nxt, 1'b0, lfsro);
reg [pLNMSB:0] wlineno;
always @(posedge clk)
if (rst)
	wlineno <= 6'h00;
else begin
	if (wr) begin
		case(lfsro[1:0])
		2'b00:	begin  mem0[adr[pMSB:5]] <= adr[AMSB:5];  wlineno <= {2'b00,adr[pMSB:5]}; end
		2'b01:	begin  mem1[adr[pMSB:5]] <= adr[AMSB:5];  wlineno <= {2'b01,adr[pMSB:5]}; end
		2'b10:	begin  mem2[adr[pMSB:5]] <= adr[AMSB:5];  wlineno <= {2'b10,adr[pMSB:5]}; end
		2'b11:	begin  mem3[adr[pMSB:5]] <= adr[AMSB:5];  wlineno <= {2'b11,adr[pMSB:5]}; end
		endcase
	end
end

always @(posedge clk)
if (rst) begin
	mem0v <= 1'd0;
	mem1v <= 1'd0;
	mem2v <= 1'd0;
	mem3v <= 1'd0;
end
else begin
	if (invall) begin
		mem0v <= 1'd0;
		mem1v <= 1'd0;
		mem2v <= 1'd0;
		mem3v <= 1'd0;
	end
	else if (invline) begin
		if (hit0) mem0v[adr[pMSB:5]] <= 1'b0;
		if (hit1) mem1v[adr[pMSB:5]] <= 1'b0;
		if (hit2) mem2v[adr[pMSB:5]] <= 1'b0;
		if (hit3) mem3v[adr[pMSB:5]] <= 1'b0;
	end
	else if (wr) begin
		case(lfsro[1:0])
		2'b00:	begin  mem0v[adr[pMSB:5]] <= 1'b1; end
		2'b01:	begin  mem1v[adr[pMSB:5]] <= 1'b1; end
		2'b10:	begin  mem2v[adr[pMSB:5]] <= 1'b1; end
		2'b11:	begin  mem3v[adr[pMSB:5]] <= 1'b1; end
		endcase
	end	
end


wire hit0 = mem0[adr[pMSB:5]]==adr[AMSB:5] & mem0v[adr[pMSB:5]];
wire hit1 = mem1[adr[pMSB:5]]==adr[AMSB:5] & mem1v[adr[pMSB:5]];
wire hit2 = mem2[adr[pMSB:5]]==adr[AMSB:5] & mem2v[adr[pMSB:5]];
wire hit3 = mem3[adr[pMSB:5]]==adr[AMSB:5] & mem3v[adr[pMSB:5]];
always @*
  if (wr) lineno = {lfsro[1:0],adr[pMSB:5]};
  else if (hit0)  lineno = {2'b00,adr[pMSB:5]};
  else if (hit1)  lineno = {2'b01,adr[pMSB:5]};
  else if (hit2)  lineno = {2'b10,adr[pMSB:5]};
  else  lineno = {2'b11,adr[pMSB:5]};
assign hit = hit0|hit1|hit2|hit3;
endmodule


// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module L1_dcache(rst, clk, nxt, wr, sel, wadr, adr, i, o, fault, hit, invall, invline);
parameter pSize = 2;
parameter AMSB = 79;
localparam pLines = pSize==4 ? 128 : 64;
localparam pLNMSB = pSize==4 ? 6 : 5;
input rst;
input clk;
input nxt;
input wr;
input [40:0] sel;
input [AMSB:0] adr;
input [AMSB:0] wadr;
input [330:0] i;
output reg [199:0] o;
output reg [1:0] fault;
output hit;
input invall;
input invline;

wire [330:0] ic;
reg [330:0] i1;
wire [pLNMSB:0] lineno;
wire taghit;
reg wr1;
reg [40:0] sel1;

wire iclk;
//BUFH ucb1 (.I(clk), .O(iclk));
assign iclk = clk;

// Must update the cache memory on the cycle after a write to the tag memmory.
// Otherwise lineno won't be valid. Tag memory takes two clock cycles to update.
always @(posedge iclk)
	wr1 <= wr;
always @(posedge iclk)
	sel1 <= sel;
always @(posedge iclk)
	i1 <= i;

L1_dcache_mem #(.pLines(pLines)) u1
(
  .clk(iclk),
  .wr(wr1),
  .sel(sel1),
  .i(i1),
  .lineno(lineno),
  .o(ic)
);

L1_dcache_cmptag4way #(.pLines(pLines)) u2
(
	.rst(rst),
	.clk(iclk),
	.nxt(nxt),
	.wr(wr),
	.invline(invline),
	.invall(invall),
	.adr(adr),
	.lineno(lineno),
	.hit(taghit)
);

assign hit = taghit;

//always @(radr or ic0 or ic1)
always @(adr or ic)
	o <= ic >> {adr[4],7'b0};
always @*
	fault <= ic[329:328];

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module L2_dcache_mem(clk, wr, sel, wlineno, rlineno, i, fault, o);
input clk;
input wr;
input [40:0] sel;
input [8:0] wlineno;
input [8:0] rlineno;
input [330:0] i;
input [2:0] fault;
output [330:0] o;

(* ram_style="block" *)
reg [330:0] mem [0:511];
(* ram_style="distributed" *)
reg [8:0] rrcl;

integer n;
initial begin
  for (n = 0; n < 512; n = n + 1) begin
    mem[n] <= 1'd0;
  end
end

genvar v;
generate begin : memupd
for (v = 0; v < 41; v = v + 1)
always @(posedge clk)
begin
	if (wr & sel[v])
		mem[wlineno][v*8+7:v*8] <= i[v*8+7:v*8];
	if (wr)
		mem[wlineno][330:328] <= fault;
end
end
endgenerate

always @(posedge clk)
	rrcl <= rlineno;        
    
assign o = mem[rrcl];

endmodule

// -----------------------------------------------------------------------------
// Because the line to update is driven by the output of the cam tag memory,
// the tag write should occur only during the first half of the line load.
// Otherwise the line number would change in the middle of the line. The
// first half of the line load is signified by an even hexibyte address (
// address bit 4).
// -----------------------------------------------------------------------------

module L2_dcache(rst, clk, nxt, wr, sel, wadr, radr, rdv_i, wrv_i, i, err_i, o, whit, rhit, invall, invline);
parameter AMSB = 79;
input rst;
input clk;
input nxt;
input wr;
input [40:0] sel;
input [AMSB:0] wadr;
input [AMSB:0] radr;
input rdv_i;
input wrv_i;
input [330:0] i;
input err_i;
output [335:0] o;
output whit;
output rhit;
input invall;
input invline;

wire [8:0] wlineno,rlineno;
wire taghit;
reg wr1 = 1'b0,wr2 = 1'b0;
reg [40:0] sel1 = 3'd0,sel2= 3'd0;
reg [330:0] i1 = 64'd0,i2 = 64'd0;
reg [1:0] f1=2'b0, f2=2'b0;

// Must update the cache memory on the cycle after a write to the tag memmory.
// Otherwise lineno won't be valid. camTag memory takes two clock cycles to update.
always @(posedge clk)
	wr1 <= wr;
always @(posedge clk)
	wr2 <= wr1;
always @(posedge clk)
	sel1 <= cnt;
always @(posedge clk)
	sel2 <= sel1;
always @(posedge clk)
	f1 <= {err_i,rdv_i,wrv_i};
always @(posedge clk)
	f2 <= f1;
	
always @(posedge clk)
	i1 <= i;
always @(posedge clk)
	i2 <= i1;

wire pe_wr;
edge_det u3 (.rst(rst), .clk(clk), .ce(1'b1), .i(wr && cnt==3'd0), .pe(pe_wr), .ne(), .ee() );

L2_dcache_ram u1 (
  .clka(clk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr2),      // input wire [41 : 0] wea
  .addra(wlineno),  // input wire [8 : 0] addra
  .dina(i2),    // input wire [335 : 0] dina
  .clkb(clk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .addrb(rlineno),  // input wire [8 : 0] addrb
  .doutb(o)  // output wire [335 : 0] doutb
);
/*
L2_dcache_mem u1
(
	.clk(clk),
	.wr(wr2),
	.wlineno(wlineno),
	.rlineno(rlineno),
	.sel(sel2),
	.i(i2),
	.fault(f2),
	.o(o)
);
*/
L2_dcache_cmptag4way u2
(
	.rst(rst),
	.clk(clk),
	.nxt(nxt),
	.wr(wr),
	.wr2(wr2),
	.inv(invline),
	.invall(invall),
	.wadr(wadr),
	.radr(radr),
	.wlineno(wlineno),
	.rlineno(rlineno),
	.whit(wtaghit),
	.rhit(rtaghit)
);

assign whit = wtaghit;
assign rhit = rtaghit;

endmodule

// Four way set associative tag memory
module L2_dcache_cmptag4way(rst, clk, nxt, wr, wr2, inv, invall, wadr, radr, wlineno, rlineno, whit, rhit);
parameter AMSB = 63;
input rst;
input clk;
input nxt;
input wr;
input wr2;
input inv;
input invall;
input [AMSB+8:0] wadr;
output reg [8:0] wlineno;
input [AMSB+8:0] radr;
output reg [8:0] rlineno;
output whit;
output rhit;

(* ram_style="block" *)
reg [AMSB+8-5:0] mem0 [0:127];
(* ram_style="block" *)
reg [AMSB+8-5:0] mem1 [0:127];
(* ram_style="block" *)
reg [AMSB+8-5:0] mem2 [0:127];
(* ram_style="block" *)
reg [AMSB+8-5:0] mem3 [0:127];
(* ram_style="distributed" *)
reg [511:0] valid;
reg [AMSB+8:0] rradr, rwadr;

integer n;
initial begin
	valid <= 512'b0;
  for (n = 0; n < 128; n = n + 1)
  begin
    mem0[n] = 0;
    mem1[n] = 0;
    mem2[n] = 0;
    mem3[n] = 0;
  end
end

wire [21:0] lfsro;
lfsr #(22,22'h0ACE3) u1 (rst, clk, nxt, 1'b0, lfsro);
wire whit0, whit1, whit2, whit3;
wire rhit0, rhit1, rhit2, rhit3;
reg inv2;

always @(posedge clk)
	inv2 <= inv;
always @(posedge clk)
	if (invall)
		valid <= 512'b0;
	else if (inv2) begin
		if (whit0) valid[{2'b00,wadr[11:5]}] <= 1'b0;
		if (whit1) valid[{2'b01,wadr[11:5]}] <= 1'b0;
		if (whit2) valid[{2'b10,wadr[11:5]}] <= 1'b0;
		if (whit3) valid[{2'b11,wadr[11:5]}] <= 1'b0;
	end
	else if (wr)
		valid[{lfsro[1:0],wadr[11:5]}] <= 1'b1;
always @(posedge clk)
	if (wr)
		case(lfsro[1:0])
		2'b00:	mem0[wadr[11:5]] <= wadr[AMSB+8:5];
		2'b01:	mem1[wadr[11:5]] <= wadr[AMSB+8:5];
		2'b10:	mem2[wadr[11:5]] <= wadr[AMSB+8:5];
		2'b11:	mem3[wadr[11:5]] <= wadr[AMSB+8:5];
		endcase
always @(posedge clk)
	rradr <= radr;
always @(posedge clk)
	rwadr <= wadr;

assign whit0 = mem0[rwadr[11:5]]==rwadr[AMSB+8:5] && valid[{2'b00,wadr[11:5]}];
assign whit1 = mem1[rwadr[11:5]]==rwadr[AMSB+8:5] && valid[{2'b01,wadr[11:5]}];
assign whit2 = mem2[rwadr[11:5]]==rwadr[AMSB+8:5] && valid[{2'b10,wadr[11:5]}];
assign whit3 = mem3[rwadr[11:5]]==rwadr[AMSB+8:5] && valid[{2'b11,wadr[11:5]}];
assign rhit0 = mem0[rradr[11:5]]==rradr[AMSB+8:5] && valid[{2'b00,radr[11:5]}];
assign rhit1 = mem1[rradr[11:5]]==rradr[AMSB+8:5] && valid[{2'b01,radr[11:5]}];
assign rhit2 = mem2[rradr[11:5]]==rradr[AMSB+8:5] && valid[{2'b10,radr[11:5]}];
assign rhit3 = mem3[rradr[11:5]]==rradr[AMSB+8:5] && valid[{2'b11,radr[11:5]}];
always @*
	if (wr|wr2) wlineno = {lfsro[1:0],wadr[11:5]};
  else if (whit0)  wlineno = {2'b00,wadr[11:5]};
  else if (whit1)  wlineno = {2'b01,wadr[11:5]};
  else if (whit2)  wlineno = {2'b10,wadr[11:5]};
  else  wlineno = {2'b11,wadr[11:5]};
always @*
  if (rhit0)  rlineno = {2'b00,radr[11:5]};
  else if (rhit1)  rlineno = {2'b01,radr[11:5]};
  else if (rhit2)  rlineno = {2'b10,radr[11:5]};
  else  rlineno = {2'b11,radr[11:5]};
assign whit = whit0|whit1|whit2|whit3;
assign rhit = rhit0|rhit1|rhit2|rhit3;
endmodule
