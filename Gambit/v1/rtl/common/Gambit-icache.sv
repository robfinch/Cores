// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rtf65004-icache.sv
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
// Small, 64 line cache memory (5kiB) made from distributed RAM. Access is
// within a single clock cycle.
// -----------------------------------------------------------------------------

module L1_icache_mem(clk, wr, lineno, nxt_lineno, i, f, o);
parameter pLines = 128;
parameter pLineWidth = 512;
localparam pLNMSB = pLines==128 ? 6 : 5;
input clk;
input wr;
input [pLNMSB:0] lineno;
input [pLNMSB:0] nxt_lineno;
input [pLineWidth-1:0] i;
input [2:0] f;
output [pLineWidth*2+2:0] o;

integer n;

(* ram_style="distributed" *)
reg [pLineWidth-1:0] mem [0:pLines-1];
reg [2:0] fmem[0:pLines-1];

initial begin
	for (n = 0; n < pLines; n = n + 1) begin
		mem[n] <= {pLineWidth{1'b0}};
		fmem[n] <= 3'd0;
	end
end

always  @(posedge clk)
	if (wr)
		mem[lineno] <= i;
always  @(posedge clk)
	if (wr)
		fmem[lineno] <= f;

assign o = {fmem[nxt_lineno]|fmem[lineno],mem[nxt_lineno],mem[lineno]};

endmodule

// -----------------------------------------------------------------------------
// Four way set associative tag memory for L1 cache.
// -----------------------------------------------------------------------------

module L1_icache_cmptag4way(rst, clk, nxt, wr, invline, invall, adr, lineno, nxt_lineno, hit, missadr);
parameter pLines = 128;
parameter AMSB = 63;
localparam pLNMSB = pLines==128 ? 6 : 5;
localparam pMSB = pLines==128 ? 8 : 7;
input rst;
input clk;
input nxt;
input wr;
input invline;
input invall;
input [AMSB:0] adr;
output reg [pLNMSB:0] lineno;
output reg [pLNMSB:0] nxt_lineno;
output reg hit;
output reg [AMSB:0] missadr;

(* ram_style="distributed" *)
reg [AMSB-5:0] mem0 [0:pLines/4-1];
reg [AMSB-5:0] mem1 [0:pLines/4-1];
reg [AMSB-5:0] mem2 [0:pLines/4-1];
reg [AMSB-5:0] mem3 [0:pLines/4-1];
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

wire [AMSB:0] nxt_adr = adr + 8'd64;

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
wire hit0n = mem0[nxt_adr[pMSB:5]]==nxt_adr[AMSB:5] & mem0v[nxt_adr[pMSB:5]];
wire hit1n = mem1[nxt_adr[pMSB:5]]==nxt_adr[AMSB:5] & mem1v[nxt_adr[pMSB:5]];
wire hit2n = mem2[nxt_adr[pMSB:5]]==nxt_adr[AMSB:5] & mem2v[nxt_adr[pMSB:5]];
wire hit3n = mem3[nxt_adr[pMSB:5]]==nxt_adr[AMSB:5] & mem3v[nxt_adr[pMSB:5]];
always @*
if (adr[5:0] > 6'd43) begin
  if (wr) lineno = {lfsro[1:0],adr[pMSB:5]};
  else if (hit0)  lineno = {2'b00,adr[pMSB:5]};
  else if (hit1)  lineno = {2'b01,adr[pMSB:5]};
  else if (hit2)  lineno = {2'b10,adr[pMSB:5]};
  else  lineno = {2'b11,adr[pMSB:5]};
  if (hit0n)  nxt_lineno = {2'b00,nxt_adr[pMSB:5]};
  else if (hit1n)  nxt_lineno = {2'b01,nxt_adr[pMSB:5]};
  else if (hit2n)  nxt_lineno = {2'b10,nxt_adr[pMSB:5]};
  else  nxt_lineno = {2'b11,nxt_adr[pMSB:5]};
	hit = (hit0 & hit0n) |
				(hit1 & hit1n) | 
				(hit2 & hit2n) |
				(hit3 & hit3n);
end
else begin
  if (wr) lineno = {lfsro[1:0],adr[pMSB:5]};
  else if (hit0)  lineno = {2'b00,adr[pMSB:5]};
  else if (hit1)  lineno = {2'b01,adr[pMSB:5]};
  else if (hit2)  lineno = {2'b10,adr[pMSB:5]};
  else  lineno = {2'b11,adr[pMSB:5]};
	hit = hit0|hit1|hit2|hit3;
end

always @*
if (adr[5:0] > 6'd43)
	missadr = (hit0|hit1|hit2|hit3) ? nxt_adr : adr;
else
	missadr = adr;

endmodule


// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module L1_icache(rst, clk, nxt, wr, wadr, adr, i, o, fault, hit, invall, invline, missadr);
parameter pSize = 2;
parameter AMSB = 63;
localparam pLines = pSize==4 ? 128 : 64;
localparam pLNMSB = pSize==4 ? 6 : 5;
input rst;
input clk;
input nxt;
input wr;
input [AMSB:0] adr;
input [AMSB:0] wadr;
input [514:0] i;
output reg [1023:0] o;
output reg [2:0] fault;
output hit;
input invall;
input invline;
output [AMSB:0] missadr;

wire [1026:0] ic;
reg [514:0] i1, i2;
wire [pLNMSB:0] lineno, nxt_lineno;
wire taghit;
reg wr1,wr2;

wire iclk;
//BUFH ucb1 (.I(clk), .O(iclk));
assign iclk = clk;

// Must update the cache memory on the cycle after a write to the tag memmory.
// Otherwise lineno won't be valid. Tag memory takes two clock cycles to update.
always @(posedge iclk)
	wr1 <= wr;
always @(posedge iclk)
	wr2 <= wr1;
always @(posedge iclk)
	i1 <= i[514:0];
always @(posedge iclk)
	i2 <= i1;

L1_icache_mem #(.pLines(pLines)) u1
(
  .clk(iclk),
  .wr(wr1),
  .i(i1[511:0]),
  .f(i1[514:512]),
  .lineno(lineno),
  .nxt_lineno(nxt_lineno),
  .o(ic)
);

L1_icache_cmptag4way #(.pLines(pLines)) u2
(
	.rst(rst),
	.clk(iclk),
	.nxt(nxt),
	.wr(wr),
	.invline(invline),
	.invall(invall),
	.adr(adr),
	.lineno(lineno),
	.nxt_lineno(nxt_lineno),
	.hit(taghit),
	.missadr(missadr)
);

assign hit = taghit;

//always @(radr or ic0 or ic1)
always @*
	o <= ic[1023:0] >> {adr[5:0],3'b0};
always @*
	fault <= ic[1026:1024];

endmodule

// -----------------------------------------------------------------------------
// 40kB L2 cache
// -----------------------------------------------------------------------------

module L2_icache_mem(clk, wr, lineno, sel, i, fault, o);
input clk;
input wr;
input [8:0] lineno;
input [2:0] sel;
input [127:0] i;
input [1:0] fault;
output [514:0] o;

(* ram_style="block" *)
reg [127:0] mem0 [0:511];
(* ram_style="block" *)
reg [127:0] mem1 [0:511];
(* ram_style="block" *)
reg [127:0] mem2 [0:511];
(* ram_style="block" *)
reg [130:0] mem3 [0:511];
(* ram_style="distributed" *)
reg [8:0] rrcl;

integer n;
initial begin
  for (n = 0; n < 512; n = n + 1) begin
    mem0[n] <= 1'd0;
    mem1[n] <= 1'd0;
    mem2[n] <= 1'd0;
    mem3[n] <= 1'd0;
  end
end

always @(posedge clk)
begin
  if (wr) begin
    case(sel)
    3'd0:   mem0[lineno] <= i;
    3'd1:   mem1[lineno] <= i;
    3'd2:   mem2[lineno] <= i;
    3'd3:   mem3[lineno] <= {fault,i};
    endcase
  end
end

always @(posedge clk)
	rrcl <= lineno;        
    
assign o = {mem3[rrcl],mem2[rrcl],mem1[rrcl],mem0[rrcl]};

endmodule

// -----------------------------------------------------------------------------
// Because the line to update is driven by the output of the cam tag memory,
// the tag write should occur only during the first half of the line load.
// Otherwise the line number would change in the middle of the line. The
// first half of the line load is signified by an even hexibyte address (
// address bit 4).
// -----------------------------------------------------------------------------

module L2_icache(rst, clk, nxt, wr, adr, cnt, exv_i, i, err_i, o, hit, invall, invline);
parameter CAMTAGS = 1'b0;   // 32 way
parameter FOURWAY = 1'b1;
parameter AMSB = 63;
input rst;
input clk;
input nxt;
input wr;
input [AMSB:0] adr;
input [2:0] cnt;
input exv_i;
input [127:0] i;
input err_i;
output [514:0] o;
output hit;
input invall;
input invline;

wire [8:0] lineno;
wire taghit;
reg wr1 = 1'b0,wr2 = 1'b0;
reg [2:0] sel1 = 3'd0,sel2= 3'd0;
reg [127:0] i1 = 64'd0,i2 = 64'd0;
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
	f1 <= {err_i,exv_i};
always @(posedge clk)
	f2 <= f1;
	
always @(posedge clk)
	i1 <= i;
always @(posedge clk)
	i2 <= i1;

wire pe_wr;
edge_det u3 (.rst(rst), .clk(clk), .ce(1'b1), .i(wr && cnt==3'd0), .pe(pe_wr), .ne(), .ee() );

L2_icache_mem u1
(
	.clk(clk),
	.wr(wr2),
	.lineno(lineno),
	.sel(sel2),
	.i(i2),
	.fault(f2),
	.o(o)
);

L2_icache_cmptag4way u2
(
	.rst(rst),
	.clk(clk),
	.nxt(nxt),
	.wr(wr),
	.wr2(wr2),
	.inv(invline),
	.invall(invall),
	.adr(adr),
	.lineno(lineno),
	.hit(taghit)
);

assign hit = taghit;

endmodule

// Four way set associative tag memory
module L2_icache_cmptag4way(rst, clk, nxt, wr, wr2, inv, invall, adr, lineno, hit);
parameter AMSB = 63;
input rst;
input clk;
input nxt;
input wr;
input wr2;
input inv;
input invall;
input [AMSB:0] adr;
output reg [8:0] lineno;
output hit;

(* ram_style="block" *)
reg [AMSB-5:0] mem0 [0:127];
(* ram_style="block" *)
reg [AMSB-5:0] mem1 [0:127];
(* ram_style="block" *)
reg [AMSB-5:0] mem2 [0:127];
(* ram_style="block" *)
reg [AMSB-5:0] mem3 [0:127];
(* ram_style="distributed" *)
reg [511:0] valid;
reg [AMSB:0] rradr;

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
wire hit0, hit1, hit2, hit3;
reg inv2;

always @(posedge clk)
	inv2 <= inv;
always @(posedge clk)
	if (invall)
		valid <= 512'b0;
	else if (inv2) begin
		if (hit0) valid[{2'b00,adr[10:4]}] <= 1'b0;
		if (hit1) valid[{2'b01,adr[10:4]}] <= 1'b0;
		if (hit2) valid[{2'b10,adr[10:4]}] <= 1'b0;
		if (hit3) valid[{2'b11,adr[10:4]}] <= 1'b0;
	end
	else if (wr)
		valid[{lfsro[1:0],adr[10:4]}] <= 1'b1;
always @(posedge clk)
	if (wr)
		case(lfsro[1:0])
		2'b00:	mem0[adr[10:4]] <= adr[AMSB:4];
		2'b01:	mem1[adr[10:4]] <= adr[AMSB:4];
		2'b10:	mem2[adr[10:4]] <= adr[AMSB:4];
		2'b11:	mem3[adr[10:4]] <= adr[AMSB:4];
		endcase
always @(posedge clk)
	rradr <= adr;

assign hit0 = mem0[rradr[10:4]]==rradr[AMSB:4] && valid[{2'b00,adr[10:4]}];
assign hit1 = mem1[rradr[10:4]]==rradr[AMSB:4] && valid[{2'b01,adr[10:4]}];
assign hit2 = mem2[rradr[10:4]]==rradr[AMSB:4] && valid[{2'b10,adr[10:4]}];
assign hit3 = mem3[rradr[10:4]]==rradr[AMSB:4] && valid[{2'b11,adr[10:4]}];
always @*
	if (wr|wr2) lineno = {lfsro[1:0],adr[10:4]};
  else if (hit0)  lineno = {2'b00,adr[10:4]};
  else if (hit1)  lineno = {2'b01,adr[10:4]};
  else if (hit2)  lineno = {2'b10,adr[10:4]};
  else  lineno = {2'b11,adr[10:4]};
assign hit = hit0|hit1|hit2|hit3;
endmodule
