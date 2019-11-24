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
//		- parameterized FPWIDth
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

`include "fpConfig.sv"

`define FLOAT   4'h1
`define FLT1		8'hE1
`define FLT2		8'hE2
`define FLT2S		8'hE8

// FLT1
`define FMOV    5'h00
`define FNEG    5'h04
`define FABS    5'h05
`define FSIGN   5'h06
`define FMAN    5'h07
`define FNABS   5'h08
`define FCVTSD  5'h09
`define F32TO64	5'h0A
`define ISNAN		5'h0E
`define F64TO32	5'h19
// FLT2
`define FMAX		5'h02
`define FMIN		5'h03
`define FCMP    5'h06
`define FCMPM		5'h07
`define SGNOP		5'h0F	// FLT2
`define FINITE	5'h0F	// FLT1
`define CPYSGN	5'h18
`define SGNINV	5'h19
`define SGNAND	5'h1A
`define SGNOR		5'h1B
`define SGNXOR	5'h1C
`define SGNXNOR	5'h1D
`define FCLASS	5'h1E
//`define FCVTSQ  6'h1B
`define FCVTDS  5'h19
`define FSLT		5'h10
`define FSGE		5'h11
`define FSLE		5'h12
`define FSGT		5'h13
`define FSEQ		5'h14
`define FSNE		5'h15
`define FSUN		5'h16
`define UNORD		5'h1F

module fpZLUnit
#(parameter FPWID=128)
(
  input [3:0] op4,
  input [4:0] func5,
  input [39:0] ir,
	input [FPWID-1:0] a,
	input [FPWID-1:0] b,	// for fcmp
	input [FPWID-1:0] c,	// for fcmp
	output reg [FPWID-1:0] o,
	output reg nanx
);
`include "fpSize.sv"

//wire [1:0] prec = ir[25:24];
wire [7:0] opcode = ir[7:0];

wire nanxab,nanxac,nanxbc;
wire nana;
wire [EMSB:0] expa;
wire [FMSB:0] ma;
wire xinfa;
wire a_inf;
wire a_xz, a_vz;
wire a_qnan, a_snan;
wire [4:0] cmp_o, cmpac_o, cmpbc_o;

// Zero is being passed for b in some cases so the NaN must come from a if
// present.
fpCompare #(FPWID) u1 (.a(a), .b(b), .o(cmp_o), .nanx(nanxab) );
fpCompare #(FPWID) u2 (.a(a), .b(c), .o(cmpac_o), .nanx(nanxac) );
fpCompare #(FPWID) u3 (.a(b), .b(c), .o(cmpbc_o), .nanx(nanxbc) );
fpDecomp #(FPWID) u4 (.i(a), .sgn(), .exp(expa), .man(ma), .fract(), .xz(a_xz), .mz(), .vz(a_vz), .inf(a_inf), .xinf(xinfa), .qnan(a_qnan), .snan(a_snan), .nan(nana));
wire [127:0] sq_o;
//fcvtsq u2 (a[31:0], sq_o);
wire [63:0] sdo;
F32ToF64 u5 (a[31:0], sdo);
wire [31:0] dso;
wire [63:0] f32to64o;
wire [31:0] f64to32o;
F32ToF80 u7 (a[31:0], f32to80o);
generate begin : f32to64code
if (FPWID >= 64)
F64ToF32 u8 (a[63:0], f32to64o);
F64ToF32 u6 (a, dso);
end
endgenerate

always @*
case(opcode)
`FLT1:
  case(func5)
  `FABS:   begin o <= {1'b0,a[FPWID-2:0]}; nanx <= nanxab; end
  `FNABS:  begin o <= {1'b1,a[FPWID-2:0]}; nanx <= nanxab; end
  `FNEG:   begin o <= {~a[FPWID-1],a[FPWID-2:0]};	nanx <= nanxab; end
  `FMOV:   begin o <= a; nanx <= nanxab; end
  `FSIGN:  begin o <= (a[FPWID-2:0]==0) ? 0 : {a[FPWID-1],1'b0,{EMSB{1'b1}},{FMSB+1{1'b0}}}; nanx <= 1'b0; end
  `FMAN:   begin o <= {a[FPWID-1],1'b0,{EMSB{1'b1}},a[FMSB:0]}; nanx <= 1'b0; end
  //`FCVTSQ:    o <= sq_o;
  `FCVTSD: begin o <= {sdo}; nanx <= nanxab; end
  `FCVTDS: begin o <= {{40{dso[39]}},dso}; nanx <= nanxab; end
  `F32TO64: begin o <= {f32to64o}; nanx <= nanxab; end
  `F64TO32: begin o <= {f64to32o}; nanx <= nanxab; end
  `ISNAN:	 begin o <= {nana}; end
  `FINITE:	begin o <= {!xinfa}; end
  `UNORD:		begin o <= {nanxab}; end
  default: o <= 0;
  endcase
`FLT2,`FLT2S:
  case(func5)
  `FCMP:   begin o <= {cmp_o}; nanx <= nanxab; end
  `FSLT:	 begin o <=  {cmp_o[1]}; nanx <= nanxab; end
  `FSGE:	 begin o <= {~cmp_o[1]}; nanx <= nanxab; end
  `FSLE:	 begin o <=  {cmp_o[2]}; nanx <= nanxab; end
  `FSGT:	 begin o <= ~{cmp_o[2]}; nanx <= nanxab; end
  `FSEQ:	 begin o <=  {cmp_o[0]}; nanx <= nanxab; end
  `FSNE:	 begin o <= ~{cmp_o[0]}; nanx <= nanxab; end
  `FSUN:	 begin o <=  {cmp_o[4]}; nanx <= nanxab; end
	`CPYSGN:	o <= { b[FPWID-1],a[FPWID-2:0]};
	`SGNINV:	o <= {~b[FPWID-1],a[FPWID-2:0]};
	`SGNAND:	o <= {a[FPWID-1] & b[FPWID-1],a[FPWID-2:0]};
	`SGNOR:		o <= {a[FPWID-1] | b[FPWID-1],a[FPWID-2:0]};
	`SGNXOR:	o <= {a[FPWID-1] ^ b[FPWID-1],a[FPWID-2:0]};
	`SGNXNOR:	o <= {~(a[FPWID-1] ^ b[FPWID-1]),a[FPWID-2:0]};
  `FCLASS:
  	begin
			o[0] <= a[FPWID-1] & a_inf;		// -Inf
			o[1] <= a[FPWID-1] & !a_xz;		// -
			o[2] <= a[FPWID-1] &  a_xz;		// -subnormal
			o[3] <= a[FPWID-1] &  a_vz;		// -0
			o[4] <= ~a[FPWID-1] &  a_vz;	// +0
			o[5] <= ~a[FPWID-1] &  a_xz;	// +subnormal
			o[6] <= ~a[FPWID-1] & !a_xz;	// +
			o[7] <= ~a[FPWID-1] & a_inf;	// +Inf
			o[8] <= a_snan;
			o[9] <= a_qnan;
			o[FPWID-1:10] <= 1'd0;
  	end
  `FMAX:	
  	begin
  	  o <= ~cmp_o[2] ? a : b;
			nanx <= nanxab;
  	end
  `FMIN:
  	begin
  	 	o <=  cmp_o[1] ? a : b;
			nanx <= nanxab;
  	end
  default: o <= 0;
  endcase
// ToDo: add extra bits
/*
`FANDI:
	begin
	case(ir[32:31])
	2'd0:		o <= {a[15:0] & {{58{1'b1}},ir[39:33],ir[30:16]}};
	2'd1:		o <= a[31:16] & {{36{1'b1}},ir[39:33],ir[30:16],{20{1'b1}}};
	2'd2:		o <= a[47:32] & {{14{1'b1}},ir[39:33],ir[30:16],{40{1'b1}}};
	2'd3:		o <= a[63:48] & {ir[39:33],ir[30:16],{60{1'b1}}};
	endcase
	nanx <= 1'b0;
	end
`FORI:
	begin
	case(ir[32:31])
	2'd0:		o <= {a[19:0] & {{58{1'b0}},ir[39:33],ir[30:16]}};
	2'd1:		o <= a[39:20] & {{36{1'b0}},ir[39:33],ir[30:16],{20{1'b0}}};
	2'd2:		o <= a[59:40] & {{14{1'b0}},ir[39:33],ir[30:16],{40{1'b0}}};
	2'd3:		o <= a[79:60] & {ir[39:33],ir[30:16],{60{1'b0}}};
	endcase
	nanx <= 1'b0;
	end
*/
default:	o <= 0;
endcase

endmodule
