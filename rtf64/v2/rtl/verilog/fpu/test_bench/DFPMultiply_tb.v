`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DFPMultiply_tb.v
//		- decimal floating point multiplier test bench
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
//	Floating Point Multiplier / Divider
//
//	This multiplier/divider handles denormalized numbers.
//	The output format is of an internal expanded representation
//	in preparation to be fed into a normalization unit, then
//	rounding. Basically, it's the same as the regular format
//	except the mantissa is doubled in size, the leading two
//	bits of which are assumed to be whole bits.
//
//
// ============================================================================

module DFPMultiply_tb();
reg rst;
reg clk;
reg [15:0] adr;
reg [127:0] a,b;
wire [127:0] o;
reg [127:0] ad,bd;
wire [127:0] od;
reg [3:0] rm;

integer n;
reg [127:0] a1, b1;
wire [63:0] doubleA = {a[31], a[30], {3{~a[30]}}, a[29:23], a[22:0], {29{1'b0}}};
wire [63:0] doubleB = {b[31], b[30], {3{~b[30]}}, b[29:23], b[22:0], {29{1'b0}}};
wire done;
reg ld;

integer outfile;

initial begin
	rst = 1'b0;
	clk = 1'b0;
	adr = 0;
	a = $urandom(1);
	#20 rst = 1;
	#50 rst = 0;
	#1000000  $fclose(outfile);
	#10 $finish;
end

always #5
	clk = ~clk;

genvar g;
generate begin : gRand
	for (g = 0; g < 128; g = g + 4) begin
		always @(posedge clk) begin
			a1[g+3:g] <= $urandom() % 10;
			b1[g+3:g] <= $urandom() % 10;
		end
	end
end
endgenerate

reg [9:0] count;
always @(posedge clk)
if (rst) begin
	adr <= 0;
	count <= 0;
end
else
begin
	ld <= 1'b0;
  if (adr==0) begin
    outfile = $fopen("d:/cores2020/rtf64/v2/rtl/verilog/cpu/fpu/test_bench/DFPMultiply_tvo.txt", "wb");
    $fwrite(outfile, "rm ------ A ------  ------- B ------  - DUT Product -  - SIM Product -\n");
  end
	count <= count + 1;
	if (count > 600)
		count <= 1'd1;
	if (count==2) begin	
		a[127:0] <= a1;
		b[127:0] <= b1;
		a[127:124] <= 4'h5;
		b[127:124] <= 4'h5;
		ld <= 1'b1;
		rm <= adr[15:13];
		//ad <= memd[adr][63: 0];
		//bd <= memd[adr][127:64];
	end
	if (adr==1 && count==2) begin
		a <= 127'h50000700000000000000000000000000;
		b <= 127'h50000200000000000000000000000000;
	end
	if (adr==1 && count==2) begin
		a <= 127'h40001333333333333333333333333333;
		b <= 127'h50000300000000000000000000000000;
	end
	if (adr==2 && count==2) begin
		a <= 127'h50000900000000000000000000000000;
		b <= 127'h50000200000000000000000000000000;
	end
	if (adr==3 && count==2) begin
		a <= 127'h50000000000000000000000000000000;
		b <= 127'h50000000000000000000000000000000;
	end
	if (adr==4 && count==2) begin
		a <= 127'h50001100000000000000000000000000;
		b <= 127'h50001100000000000000000000000000;
	end
	if (count==600) begin
	  $fwrite(outfile, "%h\t%h\t%h\t%h\n", rm, a, b, o);
		adr <= adr + 1;
	end
end

//fpMulnr #(64) u1 (clk, 1'b1, a, b, o, rm);//, sign_exe, inf, overflow, underflow);
DFPMultiplynr u6 (clk, 1'b1, ld, a, b, o, rm, done);//, sign_exe, inf, overflow, underflow);

endmodule
