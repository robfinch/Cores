// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64v8_icache.v
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
// Small, 128 line cache memory (8kiB) made from distributed RAM. Access is
// within a single clock cycle.
// -----------------------------------------------------------------------------

module FT64v8_L1_icache_mem(rst, clk, wr, lineno, i, o, ov, invall, invline);
parameter pLines = 128;
parameter pLineWidth = 553;
localparam pLNMSB = pLines==128 ? 6 : 5;
input rst;
input clk;
input wr;
input [pLNMSB:0] lineno;
input [pLineWidth-1:0] i;
output [pLineWidth-1:0] o;
output ov;
input invall;
input invline;

integer n;

(* ram_style="distributed" *)
reg [pLineWidth-1:0] mem [0:pLines-1];
reg [pLines-1:0] valid;

initial begin
	for (n = 0; n < pLines; n = n + 1)
		mem[n] <= 2'b00;
end

always  @(posedge clk)
    if (wr)  mem[lineno][551:0] <= i[551:0];
always  @(posedge clk)
if (rst) begin
     valid <= 128'd0;
end
else begin
    if (invall) begin
    	valid <= 128'd0;
    end
    else if (invline) begin
    	valid[lineno] <= 1'b0;
	end
    else if (wr) begin
    	valid0[lineno] <= 1'b1;
    end
end

assign o = mem[lineno];
assign ov = valid[lineno];

endmodule

// -----------------------------------------------------------------------------
// Four way set associative tag memory for L1 cache.
// -----------------------------------------------------------------------------

module FT64v8_L1_icache_cmptag4way(rst, clk, nxt, wr, adr, lineno, hit);
parameter pLines = 128;
parameter AMSB = 31;
localparam pLNMSB = pLines==128 ? 6 : 5;
localparam pMSB = pLines==128 ? 9 : 8;
input rst;
input clk;
input nxt;
input wr;
input [AMSB+8:0] adr;
output reg [pLNMSB:0] lineno;
output hit;

(* ram_style="distributed" *)
reg [AMSB+8-5:0] mem0 [0:pLines/4-1];
reg [AMSB+8-5:0] mem1 [0:pLines/4-1];
reg [AMSB+8-5:0] mem2 [0:pLines/4-1];
reg [AMSB+8-5:0] mem3 [0:pLines/4-1];
reg [AMSB+8:0] rradr;
integer n;
initial begin
  for (n = 0; n < pLines/4; n = n + 1)
  begin
    mem0[n] = 0;
    mem1[n] = 0;
    mem2[n] = 0;
    mem3[n] = 0;
  end
end

wire [21:0] lfsro;
lfsr #(22,22'h0ACE3) u1 (rst, clk, nxt, 1'b0, lfsro);
reg [pLNMSB:0] wlineno;
always @(posedge clk)
if (rst)
	wlineno <= 7'h00;
else begin
	if (wr) begin
		case(lfsro[1:0])
		2'b00:	begin  mem0[adr[pMSB:5]] <= adr[AMSB+8:5];  wlineno <= {2'b00,adr[pMSB:5]}; end
		2'b01:	begin  mem1[adr[pMSB:5]] <= adr[AMSB+8:5];  wlineno <= {2'b01,adr[pMSB:5]}; end
		2'b10:	begin  mem2[adr[pMSB:5]] <= adr[AMSB+8:5];  wlineno <= {2'b10,adr[pMSB:5]}; end
		2'b11:	begin  mem3[adr[pMSB:5]] <= adr[AMSB+8:5];  wlineno <= {2'b11,adr[pMSB:5]}; end
		endcase
	end
end

wire hit0 = mem0[adr[pMSB:5]]==adr[AMSB+8:5];
wire hit1 = mem1[adr[pMSB:5]]==adr[AMSB+8:5];
wire hit2 = mem2[adr[pMSB:5]]==adr[AMSB+8:5];
wire hit3 = mem3[adr[pMSB:5]]==adr[AMSB+8:5];
always @*
    //if (wr2) lineno = wlineno;
    if (hit0)  lineno = {2'b00,adr[pMSB:5]};
    else if (hit1)  lineno = {2'b01,adr[pMSB:5]};
    else if (hit2)  lineno = {2'b10,adr[pMSB:5]};
    else  lineno = {2'b11,adr[pMSB:5]};
assign hit = hit0|hit1|hit2|hit3;
endmodule


// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module FT64v8_L1_icache(rst, clk, nxt, wr, wr_ack, wadr, adr, i, o, fault, hit, invall, invline);
parameter pSize = 8;
parameter AMSB = 31;
localparam pLines = pSize==8 ? 128 : 64;
localparam pLNMSB = pSize==8 ? 6 : 5;
input rst;
input clk;
input nxt;
input wr;
output wr_ack;
input [AMSB+8:0] adr;
input [AMSB+8:0] wadr;
input [553:0] i;
output reg [191:0] o;
output reg [1:0] fault;
output hit;
input invall;
input invline;

wire [553:0] ic;
reg [553:0] i1, i2;
wire lv;				// line valid
wire [pLNMSB:0] lineno;
wire [pLNMSB:0] wlineno;
wire taghit;
reg wr1,wr2;
reg invline1, invline2;

// Must update the cache memory on the cycle after a write to the tag memmory.
// Otherwise lineno won't be valid. Tag memory takes two clock cycles to update.
always @(posedge clk)
	wr1 <= wr;
always @(posedge clk)
	wr2 <= wr1;
always @(posedge clk)
	i1 <= i[553:0];
always @(posedge clk)
	i2 <= i1;
always @(posedge clk)
	invline1 <= invline;
always @(posedge clk)
	invline2 <= invline1;

FT64v8_L1_icache_mem #(.pLines(pLines)) u1
(
  .rst(rst),
  .clk(clk),
  .wr(wr1),
  .i(i1),
  .lineno(lineno),
  .o(ic),
  .ov(lv),
  .invall(invall),
  .invline(invline1)
);

FT64v8_L1_icache_cmptag4way #(.pLines(pLines)) u3
(
	.rst(rst),
	.clk(clk),
	.nxt(nxt),
	.wr(wr),
	.adr(adr),
	.lineno(lineno),
	.hit(taghit)
);

assign hit = taghit & lv;

//always @(radr or ic0 or ic1)
always @(adr or ic)
	o <= ic >> {adr[5:0],3'h0};
always @*
	fault <= ic[553:552];
	

assign wr_ack = wr2;

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module FT64v8_L2_icache_mem(clk, wr, lineno, sel, i, fault, o, ov, invall, invline);
input clk;
input wr;
input [8:0] lineno;
input [2:0] sel;
input [63:0] i;
input [1:0] fault;
output [553:0] o;
output reg ov;
input invall;
input invline;

(* ram_style="block" *)
reg [63:0] mem0 [0:511];
reg [63:0] mem1 [0:511];
reg [63:0] mem2 [0:511];
reg [63:0] mem3 [0:511];
reg [63:0] mem4 [0:511];
reg [63:0] mem5 [0:511];
reg [63:0] mem6 [0:511];
reg [63:0] mem7 [0:511];
reg [39:0] mem8 [0:511];
reg [1:0] memf [0:511];
reg [511:0] valid;
reg [8:0] rrcl;

//  instruction parcels per cache line
wire [8:0] cache_line;
integer n;
initial begin
  for (n = 0; n < 512; n = n + 1) begin
    valid[n] <= 0;
    memf[n] <= 2'b00;
  end
end

always @(posedge clk)
  if (invall)  valid <= 512'd0;
  else if (invline)  valid[lineno] <= 1'b0;
  else if (wr)  valid[lineno] <= 1'b1;

always @(posedge clk)
begin
  if (wr) begin
    case(sel[3:0])
    4'd0:    begin mem0[lineno] <= i; memf[lineno] <= fault; end
    4'd1:    begin mem1[lineno] <= i; memf[lineno] <= memf[lineno] | fault; end
    4'd2:    begin mem2[lineno] <= i; memf[lineno] <= memf[lineno] | fault; end
    4'd3:    begin mem3[lineno] <= i; memf[lineno] <= memf[lineno] | fault; end
    4'd4:    begin mem4[lineno] <= i; memf[lineno] <= memf[lineno] | fault; end
    4'd5:    begin mem5[lineno] <= i; memf[lineno] <= memf[lineno] | fault; end
    4'd6:    begin mem6[lineno] <= i; memf[lineno] <= memf[lineno] | fault; end
    4'd7:    begin mem7[lineno] <= i; memf[lineno] <= memf[lineno] | fault; end
    4'd8:    begin mem8[lineno] <= i[39:0]; memf[lineno] <= memf[lineno] | fault; end
    endcase
  end
end

always @(posedge clk)
     rrcl <= lineno;        
    
always @(posedge clk)
     ov <= valid[lineno];

assign o = {memf[rrcl],mem8[rrcl],mem7[rrcl],mem6[rrcl],mem5[rrcl],
						mem4[rrcl],mem3[rrcl],mem2[rrcl],mem1[rrcl],mem0[rrcl]};

endmodule

// -----------------------------------------------------------------------------
// Because the line to update is driven by the output of the cam tag memory,
// the tag write should occur only during the first half of the line load.
// Otherwise the line number would change in the middle of the line. The
// first half of the line load is signified by an even hexibyte address (
// address bit 4).
// -----------------------------------------------------------------------------

module FT64v8_L2_icache(rst, clk, nxt, wr, wr_ack, rd_ack, xsel, adr, cnt, exv_i, i, err_i, o, hit, invall, invline);
parameter AMSB = 31;
input rst;
input clk;
input nxt;
input wr;
output wr_ack;
output rd_ack;
input xsel;
input [AMSB+8:0] adr;
input [2:0] cnt;
input exv_i;
input [63:0] i;
input err_i;
output [553:0] o;
output hit;
input invall;
input invline;

wire lv;            // line valid
wire [8:0] lineno;
wire taghit;
reg wr1,wr2;
reg [3:0] sel1,sel2;
reg [63:0] i1,i2;
reg [1:0] f1, f2;
reg [AMSB+8:0] last_adr;

// Must update the cache memory on the cycle after a write to the tag memmory.
// Otherwise lineno won't be valid. camTag memory takes two clock cycles to update.
always @(posedge clk)
	wr1 <= wr;
always @(posedge clk)
	wr2 <= wr1;
always @(posedge clk)
	sel1 <= {xsel,adr[5:3]};
always @(posedge clk)
	sel2 <= sel1;
always @(posedge clk)
	last_adr <= adr;
always @(posedge clk)
	f1 <= {err_i,exv_i};
always @(posedge clk)
	f2 <= f1;
	
reg [3:0] rdackx;
always @(posedge clk)
if (rst)
	rdackx <= 4'b0;
else begin
	if (last_adr != adr || wr || wr1 || wr2)
		rdackx <= 4'b0;
	else
		rdackx <= {rdackx,~(wr|wr1|wr2)};
end

assign rd_ack = rdackx[3] & ~(last_adr!=adr || wr || wr1 || wr2);

always @(posedge clk)
     i1 <= i;
always @(posedge clk)
     i2 <= i1;

wire pe_wr;
edge_det u3 (.rst(rst), .clk(clk), .ce(1'b1), .i(wr && cnt==3'd0), .pe(pe_wr), .ne(), .ee() );

FT64v8_L2_icache_mem u1
(
	.clk(clk),
	.wr(wr2),
	.lineno(lineno),
	.sel(sel2),
	.i(i2),
	.fault(f2),
	.o(o),
	.ov(lv),
	.invall(invall),
	.invline(invline)
);

FT64v8_L2_icache_cmptag4way u2
(
	.rst(rst),
	.clk(clk),
	.nxt(nxt),
	.wr(pe_wr),
	.adr(adr),
	.lineno(lineno),
	.hit(taghit)
);

assign hit = taghit & lv;
assign wr_ack = wr2;

endmodule

// Four way set associative tag memory
module FT64v8_L2_icache_cmptag4way(rst, clk, nxt, wr, adr, lineno, hit);
parameter AMSB = 31;
input rst;
input clk;
input nxt;
input wr;
input [AMSB+8:0] adr;
output reg [8:0] lineno;
output hit;

(* ram_style="block" *)
reg [AMSB+8-6:0] mem0 [0:127];
reg [AMSB+8-6:0] mem1 [0:127];
reg [AMSB+8-6:0] mem2 [0:127];
reg [AMSB+8-6:0] mem3 [0:127];
reg [AMSB+8:0] rradr;
integer n;
initial begin
  for (n = 0; n < 128; n = n + 1)
  begin
    mem0[n] = 0;
    mem1[n] = 0;
    mem2[n] = 0;
    mem3[n] = 0;
  end
end

reg wr2;
wire [21:0] lfsro;
lfsr #(22,22'h0ACE3) u1 (rst, clk, nxt, 1'b0, lfsro);
reg [8:0] wlineno;
always @(posedge clk)
if (rst)
	wlineno <= 9'h000;
else begin
     wr2 <= wr;
	if (wr) begin
		case(lfsro[1:0])
		2'b00:	begin  mem0[adr[12:6]] <= adr[AMSB+8:6];  wlineno <= {2'b00,adr[12:6]}; end
		2'b01:	begin  mem1[adr[12:6]] <= adr[AMSB+8:6];  wlineno <= {2'b01,adr[12:6]}; end
		2'b10:	begin  mem2[adr[12:6]] <= adr[AMSB+8:6];  wlineno <= {2'b10,adr[12:6]}; end
		2'b11:	begin  mem3[adr[12:6]] <= adr[AMSB+8:6];  wlineno <= {2'b11,adr[12:6]}; end
		endcase
	end
     rradr <= adr;
end

wire hit0 = mem0[rradr[12:6]]==rradr[AMSB+8:6];
wire hit1 = mem1[rradr[12:6]]==rradr[AMSB+8:6];
wire hit2 = mem2[rradr[12:6]]==rradr[AMSB+8:6];
wire hit3 = mem3[rradr[12:6]]==rradr[AMSB+8:6];
always @*
    if (wr2) lineno = wlineno;
    else if (hit0)  lineno = {2'b00,rradr[12:6]};
    else if (hit1)  lineno = {2'b01,rradr[12:6]};
    else if (hit2)  lineno = {2'b10,rradr[12:6]};
    else  lineno = {2'b11,rradr[12:6]};
assign hit = hit0|hit1|hit2|hit3;
endmodule

