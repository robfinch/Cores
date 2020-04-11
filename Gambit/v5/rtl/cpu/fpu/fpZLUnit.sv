// ============================================================================
//        __
//   \\__/ o\    (C) 2007-2020  Robert Finch, Waterloo
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

`include "..\inc\Gambit-config.sv"
`include "..\inc\Gambit-defines.sv"
`include "..\inc\Gambit-types.sv"
`include "fpConfig.sv"

module fpZLUnit
#(parameter FPWID=52)
(
  input [3:0] op4,
  input [4:0] func5,
  input Instruction ir,
	input [FPWID-1:0] a,
	input [FPWID-1:0] b,	// for fcmp
	output reg [FPWID-1:0] o,
	output reg nanx
);
`include "fpSize.sv"

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
fpDecomp #(FPWID) u4 (.i(a), .sgn(), .exp(expa), .man(ma), .fract(), .xz(a_xz), .mz(), .vz(a_vz), .inf(a_inf), .xinf(xinfa), .qnan(a_qnan), .snan(a_snan), .nan(nana));

always @*
case(ir.gen.opcode)
`FLT1:
  case(ir.flt1.func5)
  `FABS:   begin o <= {1'b0,a[FPWID-2:0]}; nanx <= nanxab; end
  `FNABS:  begin o <= {1'b1,a[FPWID-2:0]}; nanx <= nanxab; end
  `FNEG:   begin o <= {~a[FPWID-1],a[FPWID-2:0]};	nanx <= nanxab; end
  `FMOV:   begin o <= a; nanx <= nanxab; end
  `FSIGN:  begin 
  					if (ir.flt1.zero)
  						o <= (a[FPWID-2:0]==0) ? 2'b00 : a[FPWID-1] ? 2'b11 : 2'b01;	// Setting cr target
  					else
  						o <= (a[FPWID-2:0]==0) ? 0 : {a[FPWID-1],1'b0,{EMSB{1'b1}},{FMSB+1{1'b0}}}; nanx <= 1'b0; end
  `FMAN:   begin o <= {a[FPWID-1],1'b0,{EMSB{1'b1}},a[FMSB:0]}; nanx <= 1'b0; end
  `ISNAN:	 begin o <= {nana}; end
  `FINITE:	begin o <= {!xinfa}; end
  `UNORD:		begin o <= {nanxab}; end
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
			o[FPWID-2:10] <= 1'd0;
			o[FPWID-1] <= a[FPWID-1];
  	end
  default: o <= 0;
  endcase
`FCMP:   begin
						if (cmp_o[0])	//  zero?
							o <= 2'b00;
						else if (cmp_o[1])	// less than zero?
							o <= 2'b11;
						else
							o <= 2'b01;
						nanx <= nanxab;
				end
`FSLT:	 begin o <=  {cmp_o[1]}; nanx <= nanxab; end
`FSLE:	 begin o <=  {cmp_o[2]}; nanx <= nanxab; end
`FSEQ:	 begin o <=  {cmp_o[0]}; nanx <= nanxab; end
`FSNE:	 begin o <= ~{cmp_o[0]}; nanx <= nanxab; end
default:	o <= 0;
endcase

endmodule
