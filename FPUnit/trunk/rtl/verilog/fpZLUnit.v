`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2007, 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpZLUnit.v
//		- zero latency floating point unit
//		- instructions can execute in a single cycle without
//		  a clock
//		- parameterized width
//		- IEEE 754 representation
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
//	fabs	- get absolute value of number
//	fnabs	- get negative absolute value of number
//	fneg	- negate number
//	fmov	- copy input to output
//	fsign	- get sign of number (set number to +1,0, or -1)
//	fman	- get mantissa (set exponent to zero)
//
//	fclt	- less than
//	fcle	- less than or equal
//	fcgt	- greater than
//	fcge	- greater than or equal
//	fceq	- equal
//	fcne	- not equal
//	fcor	- ordered
//	fcun	- unordered
//
//	Ref: Webpack 8.1i  Spartan3-4 xc3s1000 4ft256
//	160 LUTS / 80 slices / 21 ns
// ============================================================================

`define FABS	6'd8
`define FNABS	6'd9
`define FNEG	6'd10
`define FMOV	6'd11
`define FSIGN	6'd12
`define FMAN	6'd13

module fpZLUnit
#(parameter WID=32)
(
	input [5:0] op,
	input [WID:1] a,
	input [WID:1] b,	// for fcmp
	output reg [WID:1] o,
	output nanx
);
localparam MSB = WID-1;
localparam EMSB = WID==128 ? 14 :
				  WID==96 ? 14 :
				  WID==80 ? 14 :
                  WID==64 ? 10 :
				  WID==52 ? 10 :
				  WID==48 ? 10 :
				  WID==44 ? 10 :
				  WID==42 ? 10 :
				  WID==40 ?  9 :
				  WID==32 ?  7 :
				  WID==24 ?  6 : 4;
localparam FMSB = WID==128 ? 111 :
                  WID==96 ? 79 :
				  WID==80 ? 63 :
                  WID==64 ? 51 :
				  WID==52 ? 39 :
				  WID==48 ? 35 :
				  WID==44 ? 31 :
				  WID==42 ? 29 :
				  WID==40 ? 28 :
				  WID==32 ? 22 :
				  WID==24 ? 15 : 9;

wire az = a[WID-1:1]==0;
wire cmp_o;

fp_cmp_unit #(WID) u1 (.op(op[3:0]), .a(a), .b(b), .o(cmp_o), .nanx(nanx) );

always @(op,a,cmp_o,az)
	case (op)
	`FABS:	o <= {1'b0,a[WID-1:1]};		// fabs
	`FNABS:	o <= {1'b1,a[WID-1:1]};		// fnabs
	`FNEG:	o <= {~a[WID],a[WID-1:1]};	// fneg
	`FMOV:	o <= a;						// fmov
	`FSIGN:	o <= az ? 0 : {a[WID],1'b0,{EMSB{1'b1}},{FMSB+1{1'b0}}};	// fsign
	`FMAN:	o <= {a[WID],1'b0,{EMSB{1'b1}},a[FMSB:1]};	// fman
	default:	o <= cmp_o;
	endcase

endmodule
