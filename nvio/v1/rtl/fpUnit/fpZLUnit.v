`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2007-2019  Robert Finch, Waterloo
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
//  fcmp
//
// ============================================================================

`define FLOAT   4'h1
`define FLT1		4'h1
`define FLT2		4'h2
`define FLT3		4'h3
`define FANDI		4'hE
`define FORI		4'hF

`define FMAX		5'h10
`define FMIN		5'h11
`define FCMP    5'h06
`define FMOV    5'h00
`define FNEG    5'h04
`define FABS    5'h05
`define FSIGN   5'h06
`define FMAN    5'h07
`define FNABS   5'h08
`define FCVTSD  5'h09
`define F32TO80	5'h0A
`define ISNAN		5'h0E
`define CPYSGN	5'h0F	// FLT2
`define FINITE	5'h0F	// FLT1
//`define FCVTSQ  6'h1B
`define FCVTDS  5'h19
`define FSLT		5'h10
`define FSGE		5'h11
`define FSLE		5'h12
`define FSGT		5'h13
`define FSEQ		5'h14
`define FSNE		5'h15
`define FSUN		5'h16
`define F80TO32	5'h1A
`define UNORD		5'h1F

module fpZLUnit
#(parameter WID=80)
(
  input [3:0] op4,
  input [4:0] func5,
  input [39:0] ir,
	input [WID+3:0] a,
	input [WID+3:0] b,	// for fcmp
	input [WID+3:0] c,	// for fcmp
	output reg [WID+3:0] o,
	output reg nanx
);
`include "fpSize.sv"

//wire [1:0] prec = ir[25:24];

wire nanxab,nanxac,nanxbc;
wire nana;
wire [EMSB:0] expa;
wire [FMSB:0] ma;
wire xinfa;
wire [4:0] cmp_o, cmpac_o, cmpbc_o;

// Zero is being passed for b in some cases so the NaN must come from a if
// present.
fp_cmp_unit #(WID+4) u1 (.a(a), .b(b), .o(cmp_o), .nanx(nanxab) );
fp_cmp_unit #(WID+4) u2 (.a(a), .b(c), .o(cmpac_o), .nanx(nanxac) );
fp_cmp_unit #(WID+4) u3 (.a(b), .b(c), .o(cmpbc_o), .nanx(nanxbc) );
fpDecomp #(WID+4) u4 (.i(a), .sgn(), .exp(expa), .man(ma), .fract(), .xz(), .mz(), .vz(), .inf(), .xinf(xinfa), .qnan(), .snan(), .nan(nana));
wire [127:0] sq_o;
//fcvtsq u2 (a[31:0], sq_o);
wire [79:0] sdo;
fs2d u5 (a[43:4], sdo);
wire [39:0] dso;
fd2s u6 (a, dso);
wire [79:0] f32to80o;
wire [31:0] f80to32o;
F32ToF80 u7 (a[35:4], f32to80o);
F80ToF32 u8 (a[WID+3:4], f32to80o);

always @*
  case(op4)
  `FLT1:
    case(func5)
    `FABS:   begin o <= {1'b0,a[WID-2:0]}; nanx <= nanxab; end
    `FNABS:  begin o <= {1'b1,a[WID-2:0]}; nanx <= nanxab; end
    `FNEG:   begin o <= {~a[WID-1],a[WID-2:0]};	nanx <= nanxab; end
    `FMOV:   begin o <= a; nanx <= nanxab; end
    `FSIGN:  begin o <= (a[WID-2:0]==0) ? 0 : {a[WID-1],1'b0,{EMSB{1'b1}},{FMSB+1{1'b0}}}; nanx <= 1'b0; end
    `FMAN:   begin o <= {a[WID-1],1'b0,{EMSB{1'b1}},a[FMSB:0]}; nanx <= 1'b0; end
    //`FCVTSQ:    o <= sq_o;
    `FCVTSD: begin o <= {sdo,4'h0}; nanx <= nanxab; end
    `FCVTDS: begin o <= {{40{dso[39]}},dso,4'h0}; nanx <= nanxab; end
    `F32TO80: begin o <= {f32to80o,4'h0}; nanx <= nanxab; end
    `F80TO32: begin o <= {f80to32o,4'h0}; nanx <= nanxab; end
    `ISNAN:	 begin o <= nana; end
    `FINITE:	begin o <= !xinfa; end
    `UNORD:		begin o <= nanxab; end
    default: o <= 0;
    endcase
  `FLT2:
    case(func5)
    `FCMP:   begin o <= {cmp_o,4'h0}; nanx <= nanxab; end
    `FSLT:	 begin o <=  {cmp_o[1],4'h0}; nanx <= nanxab; end
    `FSGE:	 begin o <= {~cmp_o[1],4'h0}; nanx <= nanxab; end
    `FSLE:	 begin o <=  {cmp_o[2],4'h0}; nanx <= nanxab; end
    `FSGT:	 begin o <= ~{cmp_o[2],4'h0}; nanx <= nanxab; end
    `FSEQ:	 begin o <=  {cmp_o[0],4'h0}; nanx <= nanxab; end
    `FSNE:	 begin o <= ~{cmp_o[0],4'h0}; nanx <= nanxab; end
    `FSUN:	 begin o <=  {cmp_o[4],4'h0}; nanx <= nanxab; end
    `CPYSGN:	begin o <= {b[WID+3],a[WID+2:0]}; end
    default: o <= 0;
    endcase
  `FLT3:
  	case(func5)
	  `FMAX:	
	  	begin
	  	  o <= ~cmp_o[2] & ~cmpac_o[2] ? a : ~cmpbc_o[2] ? b : c;
				nanx <= nanxab|nanxac|nanxbc;
	  	end
	  `FMIN:
	  	begin
	  	 	o <=  cmp_o[1] & cmpac_o[1] ? a : cmpbc_o[2] ? b : c;
				nanx <= nanxab|nanxac|nanxbc;
	  	end
    default: o <= 0;
  	endcase
  `FANDI:
  	begin
  	case(ir[32:31])
  	2'd0:		o <= {a[23: 4] & {{58{1'b1}},ir[39:33],ir[30:16],4'h0}};
  	2'd1:		o <= a[43:24] & {{36{1'b1}},ir[39:33],ir[30:16],{20{1'b1}}};
  	2'd2:		o <= a[63:44] & {{14{1'b1}},ir[39:33],ir[30:16],{40{1'b1}}};
  	2'd3:		o <= a[83:64] & {ir[39:33],ir[30:16],{60{1'b1}}};
  	endcase
  	nanx <= 1'b0;
  	end
  `FORI:
  	begin
  	case(ir[32:31])
  	2'd0:		o <= {a[23: 4] & {{58{1'b0}},ir[39:33],ir[30:16],4'h0}};
  	2'd1:		o <= a[43:24] & {{36{1'b0}},ir[39:33],ir[30:16],{20{1'b0}}};
  	2'd2:		o <= a[63:44] & {{14{1'b0}},ir[39:33],ir[30:16],{40{1'b0}}};
  	2'd3:		o <= a[83:64] & {ir[39:33],ir[30:16],{60{1'b0}}};
  	endcase
  	nanx <= 1'b0;
  	end
	default:	o <= 0;
	endcase

endmodule
