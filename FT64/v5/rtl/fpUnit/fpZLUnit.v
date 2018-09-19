`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2007-2018  Robert Finch, Waterloo
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

`define FVECTOR 6'h01
`define VFABS   6'h03
`define VFSxx   6'h06
`define VFSxxS  6'h07
`define VFNEG   6'h16
`define VSEQ        3'd0
`define VSNE        3'd1
`define VSLT        3'd2
`define VSGE        3'd3
`define VSLE        3'd4
`define VSGT        3'd5
`define VSUN        3'd7
`define VFSIGN  6'h26
`define FLOAT   6'h0F
`define FCMP    6'h06
`define FMOV    6'h10
`define FNEG    6'h14
`define FABS    6'h15
`define FSIGN   6'h16
`define FMAN    6'h17
`define FNABS   6'h18
`define FCVTSD  6'h19
`define FCVTSQ  6'h1B
`define FCVTDS  6'h29
`define FSLT		6'h38
`define FSGE		6'h39
`define FSLE		6'h3A
`define FSGT		6'h3B
`define FSEQ		6'h3C
`define FSNE		6'h3D
`define FSUN		6'h3E

module fpZLUnit
#(parameter WID=32)
(
    input [31:0] ir,
	input [WID-1:0] a,
	input [WID-1:0] b,	// for fcmp
	output reg [WID-1:0] o,
	output nanx
);
localparam MSB = WID-1;
localparam EMSB = WID==128 ? 14 :
                  WID==96 ? 14 :
                  WID==80 ? 14 :
                  WID==64 ? 10 :
				  WID==52 ? 10 :
				  WID==48 ? 11 :
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
				  WID==48 ? 34 :
				  WID==44 ? 31 :
				  WID==42 ? 29 :
				  WID==40 ? 28 :
				  WID==32 ? 22 :
				  WID==24 ? 15 : 9;

wire [5:0] op = ir[5:0];
//wire [1:0] prec = ir[25:24];
wire [5:0] fn = ir[31:26];
wire [2:0] sxx = {ir[25],ir[20:19]};

wire [4:0] cmp_o;

fp_cmp_unit #(WID) u1 (.a(a), .b(b), .o(cmp_o), .nanx(nanx) );
wire [127:0] sq_o;
//fcvtsq u2 (a[31:0], sq_o);
wire [63:0] sdo;
fs2d u3 (a[31:0], sdo);
wire [31:0] dso;
fd2s u4 (a, dso);

always @*
    case(op)
    `FLOAT:
        case(fn)
        `FABS:   o <= {1'b0,a[WID-2:0]};        // fabs
        `FNABS:  o <= {1'b1,a[WID-2:0]};        // fnabs
        `FNEG:   o <= {~a[WID-1],a[WID-2:0]};   // fneg
        `FMOV:   o <= a;                        // fmov
        `FSIGN:  o <= (a[WID-2:0]==0) ? 0 : {a[WID-1],1'b0,{EMSB{1'b1}},{FMSB+1{1'b0}}};    // fsign
        `FMAN:   o <= {a[WID-1],1'b0,{EMSB{1'b1}},a[FMSB:0]};    // fman
        //`FCVTSQ:    o <= sq_o;
        `FCVTSD: o <= sdo;
        `FCVTDS: o <= {{32{dso[31]}},dso};
        `FCMP:   o <= cmp_o;
        `FSLT:	 o <=  cmp_o[1];
        `FSGE:	 o <= ~cmp_o[1];
        `FSLE:	 o <=  cmp_o[2];
        `FSGT:	 o <= ~cmp_o[2];
        `FSEQ:	 o <=  cmp_o[0];
        `FSNE:	 o <= ~cmp_o[0];
        `FSUN:	 o <=  cmp_o[4];
        default: o <= 0;
        endcase
    `FVECTOR:
        case(fn)
        `VFABS:  o <= {1'b0,a[WID-2:0]};        // fabs
        `VFSIGN: o <= (a[WID-2:0]==0) ? 0 : {a[WID-1],1'b0,{EMSB{1'b1}},{FMSB+1{1'b0}}};    // fsign
        `VFNEG:  o <= {~a[WID-1],a[WID-2:0]};   // fneg
        `VFSxx,`VFSxxS:
            case(sxx)
            `VSEQ:  o <=  cmp_o[0];
            `VSNE:  o <= ~cmp_o[0];
            `VSLT:  o <=  cmp_o[1];
            `VSGE:  o <= ~cmp_o[1];
            `VSLE:  o <=  cmp_o[2];
            `VSGT:  o <= ~cmp_o[2];
            `VSUN:  o <=  cmp_o[4];
            default:    o <= cmp_o[2];  
            endcase
        default:    o <= 0;
        endcase
	default:	o <= 0;
	endcase

endmodule
