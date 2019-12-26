// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	Gambit-dcache.v
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

//`define SIM			1'b1

// -----------------------------------------------------------------------------
// Small, 128 line cache memory (4kiB) made from distributed RAM. Access is
// within a single clock cycle.
// -----------------------------------------------------------------------------

module L1_dcache_mem(clk, wr, sel, lineno, i, o);
parameter pLines = 128;
parameter pLineWidth = 476;
localparam pLNMSB = $clog2(pLines)-1;
input clk;
input wr;
input [36:0] sel;
input [pLNMSB:0] lineno;
input [pLineWidth-1:0] i;
output [pLineWidth-1:0] o;

integer n;

`ifdef XILINX_SIMULATOR
(* ram_style="distributed" *)
reg [pLineWidth-1:0] mem [0:pLines-1];

initial begin
	for (n = 0; n < pLines; n = n + 1)
		mem[n] = {pLineWidth{1'b0}};
end

genvar v;

generate begin : mupd
for (v = 0; v < 36; v = v + 1)
begin : mw
always @(posedge clk)
	if (wr & sel[v])  mem[lineno][v*13+:13] <= i[v*13+:13];
end
end
endgenerate

assign o = mem[lineno];

`else

genvar g;

generate begin : mem2
for (g = 0; g < 36; g = g + 1) begin
// 128 lines (32 x 4 way)
L1_dcache_mem2 u1
(
  .a(lineno),
  .d(i[g*13+:13]),
  .clk(clk),
  .we(wr & sel[g]),
  .spo(o[g*13+:13])
);
end
end
endgenerate

`endif

endmodule

// -----------------------------------------------------------------------------
//
// -----------------------------------------------------------------------------

module L1_dcache_tagram(clk, wr, lineno, i, o);
parameter pLines = 32;
parameter AMSB = 51;
localparam pLNMSB = $clog2(pLines)-1;
input clk;
input wr;
input [pLNMSB:0] lineno;
input [AMSB-6:0] i;
output [AMSB-6:0] o;

`ifdef XILINX_SIMULATOR
integer n;
(* ram_style="distributed" *)
reg [AMSB-6:0] mem [0:pLines-1];
initial begin
	for (n = 0; n < pLines; n = n + 1)
		mem[n] = 1'd0;
end

always @(posedge clk)
	if (wr) mem [lineno] <= i;
assign o = mem[lineno];
`else
L1_dcache_tagram2 u1
(
  .a(lineno),
  .d(i),
  .clk(clk),
  .we(wr),
  .spo(o)
);
`endif

endmodule

// -----------------------------------------------------------------------------
// Four way set associative tag memory for L1 cache.
// -----------------------------------------------------------------------------

module L1_dcache_cmptag4way(rst, clk, nxt, wr, invline, invall, adr, lineno, hit);
parameter pLines = 128;
parameter AMSB = 51;
localparam pLNMSB = $clog2(pLines) - 1;
localparam pMSB = $clog2(pLines) - 3 + 6;
input rst;
input clk;
input nxt;
input wr;
input invline;
input invall;
input [AMSB:0] adr;
output reg [pLNMSB:0] lineno;
output hit;


wire [AMSB-6:0] memo0;
wire [AMSB-6:0] memo1;
wire [AMSB-6:0] memo2;
wire [AMSB-6:0] memo3;
reg [pLines/4-1:0] mem0v;
reg [pLines/4-1:0] mem1v;
reg [pLines/4-1:0] mem2v;
reg [pLines/4-1:0] mem3v;
wire hit0, hit1, hit2, hit3;

integer n;
initial begin
  for (n = 0; n < pLines/4; n = n + 1)
  begin
    mem0v[n] = 0;
    mem1v[n] = 0;
    mem2v[n] = 0;
    mem3v[n] = 0;
  end
end

wire [21:0] lfsro;
lfsr #(22,22'h0ACE3) u1 (rst, clk, nxt, 1'b0, lfsro);
wire [pLNMSB:0] wlineno;

assign wlineno = {lfsro[1:0],adr[pMSB:6]};
L1_dcache_tagram #(pLines/4) u2 (.clk(clk), .wr(wr && !hit && lfsro[1:0]==2'b00), .lineno(adr[pMSB:6]), .i(adr[AMSB:6]), .o(memo0));
L1_dcache_tagram #(pLines/4) u3 (.clk(clk), .wr(wr && !hit && lfsro[1:0]==2'b01), .lineno(adr[pMSB:6]), .i(adr[AMSB:6]), .o(memo1));
L1_dcache_tagram #(pLines/4) u4 (.clk(clk), .wr(wr && !hit && lfsro[1:0]==2'b10), .lineno(adr[pMSB:6]), .i(adr[AMSB:6]), .o(memo2));
L1_dcache_tagram #(pLines/4) u5 (.clk(clk), .wr(wr && !hit && lfsro[1:0]==2'b11), .lineno(adr[pMSB:6]), .i(adr[AMSB:6]), .o(memo3));

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
		if (hit0) mem0v[adr[pMSB:6]] <= 1'b0;
		if (hit1) mem1v[adr[pMSB:6]] <= 1'b0;
		if (hit2) mem2v[adr[pMSB:6]] <= 1'b0;
		if (hit3) mem3v[adr[pMSB:6]] <= 1'b0;
	end
	else if (wr & ~hit) begin
		case(lfsro[1:0])
		2'b00:	begin  mem0v[adr[pMSB:6]] <= 1'b1; end
		2'b01:	begin  mem1v[adr[pMSB:6]] <= 1'b1; end
		2'b10:	begin  mem2v[adr[pMSB:6]] <= 1'b1; end
		2'b11:	begin  mem3v[adr[pMSB:6]] <= 1'b1; end
		endcase
	end	
end


assign hit0 = memo0==adr[AMSB:6] & mem0v[adr[pMSB:6]];
assign hit1 = memo1==adr[AMSB:6] & mem1v[adr[pMSB:6]];
assign hit2 = memo2==adr[AMSB:6] & mem2v[adr[pMSB:6]];
assign hit3 = memo3==adr[AMSB:6] & mem3v[adr[pMSB:6]];
always @*
  if (wr & ~hit) lineno = wlineno;
  else if (hit0)  lineno = {2'b00,adr[pMSB:6]};
  else if (hit1)  lineno = {2'b01,adr[pMSB:6]};
  else if (hit2)  lineno = {2'b10,adr[pMSB:6]};
  else  lineno = {2'b11,adr[pMSB:6]};
assign hit = hit0|hit1|hit2|hit3;
endmodule


// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module L1_dcache(rst, clk, nxt, wr, sel, adr, i, o, fault, hit, invall, invline);
parameter pSize = 2;
parameter AMSB = 51;
localparam pLines = pSize==4 ? 128 : 64;
localparam pLNMSB = $clog2(pLines) - 1;
input rst;
input clk;
input nxt;
input wr;
input [36:0] sel;
input [AMSB:0] adr;
input [475:0] i;
output reg [51:0] o;
output reg [2:0] fault;
output hit;
input invall;
input invline;

wire [475:0] ic;
reg [475:0] i1;
wire [pLNMSB:0] lineno;
wire taghit;
reg wr1;
reg [36:0] sel1;

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
	o <= ic >> (adr[4:0] * 13);
always @*
	fault <= ic[475:473];

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module L2_dcache_mem(clk, wr, sel, wlineno, rlineno, i, fault, o);
input clk;
input wr;
input [35:0] sel;
input [8:0] wlineno;
input [8:0] rlineno;
input [418:0] i;
input [3:0] fault;
output [418:0] o;

// Block ram must be a multiple of eight bits wide to use byte write enables.
(* ram_style="block" *)
reg [575:0] mem [0:511];
(* ram_style="distributed" *)
reg [8:0] rrcl;

integer n;
initial begin
  for (n = 0; n < 512; n = n + 1) begin
    mem[n] = 1'd0;
  end
end

genvar v;
generate begin : memupd
for (v = 0; v < 36; v = v + 1)
always @(posedge clk)
begin
	if (wr & sel[v])
		mem[wlineno][v*16+:16] <= {3'b0,i[v*13+:13]};
end
end
endgenerate

always @(posedge clk)
	rrcl <= rlineno;        

generate begin : memrd
for (v = 0; v < 36; v = v + 1)
assign o[v*13+:13] = mem[rrcl][v*16+:13];
end
endgenerate

endmodule

// -----------------------------------------------------------------------------
// Because the line to update is driven by the output of the cam tag memory,
// the tag write should occur only during the first half of the line load.
// Otherwise the line number would change in the middle of the line. The
// first half of the line load is signified by an even hexibyte address (
// address bit 4).
// -----------------------------------------------------------------------------

module L2_dcache(rst, clk, nxt, wr, sel, wadr, radr, tlbmiss_i, rdv_i, wrv_i, i, err_i, o, whit, rhit, invall, invline);
parameter AMSB = 51;
input rst;
input clk;
input nxt;
input wr;
input [35:0] sel;
input [AMSB:0] wadr;
input [AMSB:0] radr;
input tlbmiss_i;
input rdv_i;
input wrv_i;
input err_i;
input [475:0] i;
output [475:0] o;
output whit;
output rhit;
input invall;
input invline;

wire [9:0] wlineno,rlineno;
wire taghit;
reg wr1 = 1'b0,wr2 = 1'b0;
reg [35:0] sel1 = 3'd0,sel2= 3'd0;
reg [475:0] i1 = 64'd0,i2 = 64'd0;

// Must update the cache memory on the cycle after a write to the tag memmory.
// Otherwise lineno won't be valid. camTag memory takes two clock cycles to update.
always @(posedge clk)
	wr1 <= wr;
always @(posedge clk)
	wr2 <= wr1;
always @(posedge clk)
	sel1 <= sel;
always @(posedge clk)
	sel2 <= sel1;
	
always @(posedge clk)
	i1 <= {4'h0,tlbmiss_i,err_i,rdv_i,wrv_i,i};
always @(posedge clk)
	i2 <= i1;

wire pe_wr;
edge_det u3 (.rst(rst), .clk(clk), .ce(1'b1), .i(wr && cnt==3'd0), .pe(pe_wr), .ne(), .ee() );

genvar g;
generate begin : dmem
for (g = 0; g < 36; g = g + 1)
L2_dcache_ram u1 (
  .clka(clk),    // input wire clka
  .ena(wr2),      // input wire ena
  .wea(sel2[g]),      // input wire [41 : 0] wea
  .addra(wlineno),  // input wire [8 : 0] addra
  .dina({3'b0,i2[g*13+:13]}),    // input wire [335 : 0] dina
  .clkb(clk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .addrb(rlineno),  // input wire [8 : 0] addrb
  .doutb(o[g*13+:13])  // output wire [335 : 0] doutb
);
end
endgenerate

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
parameter AMSB = 51;
input rst;
input clk;
input nxt;
input wr;
input wr2;
input inv;
input invall;
input [AMSB+8:0] wadr;
output reg [9:0] wlineno;
input [AMSB+8:0] radr;
output reg [9:0] rlineno;
output whit;
output rhit;

(* ram_style="block" *)
reg [AMSB+8-5:0] mem0 [0:255];
(* ram_style="block" *)
reg [AMSB+8-5:0] mem1 [0:255];
(* ram_style="block" *)
reg [AMSB+8-5:0] mem2 [0:255];
(* ram_style="block" *)
reg [AMSB+8-5:0] mem3 [0:255];
(* ram_style="distributed" *)
reg [1023:0] valid;
reg [AMSB+8:0] rradr, rwadr;
reg rwr;

integer n;
initial begin
	valid <= 1024'b0;
  for (n = 0; n < 256; n = n + 1)
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
		valid <= 1024'b0;
	else if (inv2) begin
		if (whit0) valid[{2'b00,wadr[12:5]}] <= 1'b0;
		if (whit1) valid[{2'b01,wadr[12:5]}] <= 1'b0;
		if (whit2) valid[{2'b10,wadr[12:5]}] <= 1'b0;
		if (whit3) valid[{2'b11,wadr[12:5]}] <= 1'b0;
	end
	else if (wr)
		valid[{lfsro[1:0],wadr[12:5]}] <= 1'b1;
// Don't update the tag (select a new line) if there's a write hit.
always @(posedge clk)
	if (whit0|whit1|whit2|whit3)
		;
	else if (rwr)
		case(lfsro[1:0])
		2'b00:	mem0[rwadr[12:5]] <= rwadr[AMSB+8:5];
		2'b01:	mem1[rwadr[12:5]] <= rwadr[AMSB+8:5];
		2'b10:	mem2[rwadr[12:5]] <= rwadr[AMSB+8:5];
		2'b11:	mem3[rwadr[12:5]] <= rwadr[AMSB+8:5];
		endcase
always @(posedge clk)
	rwr <= wr;
always @(posedge clk)
	rradr <= radr;
always @(posedge clk)
	rwadr <= wadr;

assign whit0 = mem0[rwadr[12:5]]==rwadr[AMSB+8:5] && valid[{2'b00,wadr[12:5]}];
assign whit1 = mem1[rwadr[12:5]]==rwadr[AMSB+8:5] && valid[{2'b01,wadr[12:5]}];
assign whit2 = mem2[rwadr[12:5]]==rwadr[AMSB+8:5] && valid[{2'b10,wadr[12:5]}];
assign whit3 = mem3[rwadr[12:5]]==rwadr[AMSB+8:5] && valid[{2'b11,wadr[12:5]}];
assign rhit0 = mem0[rradr[12:5]]==rradr[AMSB+8:5] && valid[{2'b00,radr[12:5]}];
assign rhit1 = mem1[rradr[12:5]]==rradr[AMSB+8:5] && valid[{2'b01,radr[12:5]}];
assign rhit2 = mem2[rradr[12:5]]==rradr[AMSB+8:5] && valid[{2'b10,radr[12:5]}];
assign rhit3 = mem3[rradr[12:5]]==rradr[AMSB+8:5] && valid[{2'b11,radr[12:5]}];
always @*
       if (whit0)  wlineno = {2'b00,wadr[12:5]};
  else if (whit1)  wlineno = {2'b01,wadr[12:5]};
  else if (whit2)  wlineno = {2'b10,wadr[12:5]};
  else if (whit3)  wlineno = {2'b11,wadr[12:5]};
	else if (rwr|wr2) wlineno = {lfsro[1:0],rwadr[12:5]};
always @*
  if (rhit0)  rlineno = {2'b00,radr[12:5]};
  else if (rhit1)  rlineno = {2'b01,radr[12:5]};
  else if (rhit2)  rlineno = {2'b10,radr[12:5]};
  else  rlineno = {2'b11,radr[12:5]};
assign whit = whit0|whit1|whit2|whit3;
assign rhit = rhit0|rhit1|rhit2|rhit3;
endmodule
