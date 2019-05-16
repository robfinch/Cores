`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
// Register file with two write ports and six read ports.
// ============================================================================
//
`include "FT64_config.vh"

module FT64_regfileRam_sim(clka, ena, wea, addra, dina, addrb, doutb);
parameter WID=64;
parameter RBIT = 11;
input clka;
input ena;
input [7:0] wea;
input [RBIT:0] addra;
input [WID-1:0] dina;
input [RBIT:0] addrb;
output reg [WID-1:0] doutb;

integer n;
(* RAM_STYLE="BLOCK" *)
reg [64:0] mem [0:4095];
reg [RBIT:0] raddrb;

initial begin
	for (n = 0; n < 4096; n = n + 1)
		mem[n] = 0;
end

always @(posedge clka) if (ena & wea[0]) mem[addra][7:0] <= dina[7:0];
always @(posedge clka) if (ena & wea[1]) mem[addra][15:8] <= dina[15:8];
always @(posedge clka) if (ena & wea[2]) mem[addra][23:16] <= dina[23:16];
always @(posedge clka) if (ena & wea[3]) mem[addra][31:24] <= dina[31:24];
always @(posedge clka) if (ena & wea[4]) mem[addra][39:32] <= dina[39:32];
always @(posedge clka) if (ena & wea[5]) mem[addra][47:40] <= dina[47:40];
always @(posedge clka) if (ena & wea[6]) mem[addra][55:48] <= dina[55:48];
always @(posedge clka) if (ena & wea[7]) mem[addra][63:56] <= dina[63:56];

always @(posedge clka)
	raddrb <= addrb;
always @(posedge clka)
	doutb <= mem[raddrb];
	
endmodule

module FT64_regfile1w3r(clk, sourceid, regid, wr0, wa0, i0, ra0, ra1, ra2, o0, o1, o2);
parameter WID=64;
parameter RBIT = 11;
input clk;
input [`QBITS] sourceid;
output reg [`QBITS] regid;
input wr0;
input [RBIT:0] wa0;
input [WID-1:0] i0;
input [RBIT:0] ra0;
input [RBIT:0] ra1;
input [RBIT:0] ra2;
output [WID-1:0] o0;
output [WID-1:0] o1;
output [WID-1:0] o2;

reg wr;
reg [RBIT:0] wa;
reg [WID-1:0] i;
reg [7:0] we;
wire [WID-1:0] o00, o01, o02;

integer n;

`ifdef SIM
FT64_regfileRam_sim urf10 (
  .clka(clk),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .addrb(ra0),
  .doutb(o00)
);

FT64_regfileRam_sim urf11 (
  .clka(clk),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .addrb(ra1),
  .doutb(o01)
);

FT64_regfileRam_sim urf12 (
  .clka(clk),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .addrb(ra2),
  .doutb(o02)
);

`else
FT64_regfileRam urf10 (
  .clka(clk),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .douta(),
  .clkb(clk),
  .enb(1'b1),
  .web(8'b0),
  .addrb(ra0),
  .dinb(64'h00),
  .doutb(o00)
);

FT64_regfileRam urf11 (
  .clka(clk),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .douta(),
  .clkb(clk),
  .enb(1'b1),
  .web(8'b0),
  .addrb(ra1),
  .dinb(64'h00),
  .doutb(o01)
);

FT64_regfileRam urf12 (
  .clka(clk),
  .ena(wr),
  .wea(we),
  .addra(wa),
  .dina(i),
  .douta(),
  .clkb(clk),
  .enb(1'b1),
  .web(8'b0),
  .addrb(ra2),
  .dinb(64'h00),
  .doutb(o02)
);

`endif

reg [`QBITS] id1, id2;
// sourceid is already delayed by one cycle relative to the register address.
always @(posedge clk)
	regid <= sourceid;

// Twos stages of bypassing to allow the block ram a two cycle latency.

reg holdwr0, holdwr0a, holdwr0b;
reg [RBIT:0] holdwa0, holdwa0a, holdwa0b;
reg [WID-1:0] holdi0, holdi0a, holdi0b;

// Record what was written in the previous clock cycle so that read
// forwarding logic may use it.
always @(posedge clk)
	holdwr0 <= wr0;
always @(posedge clk)
	holdwa0 <= wa0;
always @(posedge clk)
	holdi0 <= i0;

// Record what was written in the previous clock cycle so that read
// forwarding logic may use it.
always @(posedge clk)
	holdwr0a <= holdwr0;
always @(posedge clk)
	holdwa0a <= holdwa0;
always @(posedge clk)
	holdi0a <= holdi0;

// Record what was written in the previous clock cycle so that read
// forwarding logic may use it.
always @(posedge clk)
	holdwr0b <= holdwr0a;
always @(posedge clk)
	holdwa0b <= holdwa0a;
always @(posedge clk)
	holdi0b <= holdi0a;

always @*
begin
	wr <= wr0;
	we <= 8'hFF;
	wa <= wa0;
	i <= i0;
end

function [WID-1:0] fwdmux;
input [RBIT:0] ra;
input wr0;
input hwr0;
input hwr0a;
input hwr0b;
input [RBIT:0] wa0;
input [RBIT:0] hwa0;
input [RBIT:0] hwa0a;
input [RBIT:0] hwa0b;
input [WID-1:0] i0;
input [WID-1:0] hi0;
input [WID-1:0] hi0a;
input [WID-1:0] hi0b;
input [WID-1:0] oo;
begin
	if (ra[4:0]==5'd0)					// always bypassed to zero
		fwdmux = 1'd0;
	else if (wr0 && ra==wa0)			// current clock
		fwdmux = i0;
	else if (hwr0 && ra==hwa0)		// one clock back
		fwdmux = hi0;
	else if (hwr0a && ra==hwa0a)	// two clocks back
		fwdmux = hi0a;
	else if (hwr0b && ra==hwa0b)	// three clocks back
		fwdmux = hi0b;
	else
		fwdmux = oo;
end
endfunction

assign o0 = fwdmux(ra0,wr0,holdwr0,holdwr0a,holdwr0b,wa0,holdwa0,holdwa0a,holdwa0b,i0,holdi0,holdi0a,holdi0b,o00);
assign o1 = fwdmux(ra1,wr0,holdwr0,holdwr0a,holdwr0b,wa0,holdwa0,holdwa0a,holdwa0b,i0,holdi0,holdi0a,holdi0b,o01);
assign o2 = fwdmux(ra2,wr0,holdwr0,holdwr0a,holdwr0b,wa0,holdwa0,holdwa0a,holdwa0b,i0,holdi0,holdi0a,holdi0b,o02);

endmodule

