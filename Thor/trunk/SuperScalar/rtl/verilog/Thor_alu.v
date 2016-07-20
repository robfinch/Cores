// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2016  Robert Finch, Stratford
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
// Thor SuperScaler
// ALU
//
// ============================================================================
//
`include "Thor_defines.v"

module Thor_alu(corenum, rst, clk, alu_ld, alu_abort, alu_op, alu_fn, alu_argA, alu_argB, alu_argC, alu_argI, alu_pc, insnsz, o, alu_done, alu_idle, alu_divByZero);
parameter DBW=64;
parameter BIG=1;
parameter FEATURES = 0;
parameter SEGMODEL = 2;
input [63:0] corenum;
input rst;
input clk;
input alu_ld;
input alu_abort;
input [7:0] alu_op;
input [5:0] alu_fn;
input [DBW-1:0] alu_argA;
input [DBW-1:0] alu_argB;
input [DBW-1:0] alu_argC;
input [DBW-1:0] alu_argI;
input [DBW-1:0] alu_pc;
input [3:0] insnsz;
output reg [DBW-1:0] o;
output reg alu_done;
output reg alu_idle;
output alu_divByZero;

wire signed [DBW-1:0] alu_argAs = alu_argA;
wire signed [DBW-1:0] alu_argBs = alu_argB;
wire signed [DBW-1:0] alu_argIs = alu_argI;
wire [DBW-1:0] andi_res = alu_argA & alu_argI;
wire [127:0] alu_prod;
wire [63:0] alu_divq;
wire [63:0] alu_rem;
wire [7:0] bcdao,bcdso;
wire [15:0] bcdmo;
wire [DBW-1:0] bf_out;
wire [DBW-1:0] shfto;
wire alu_mult_done,alu_div_done;
wire alu_mult_idle,alu_div_idle;
wire [DBW-1:0] p_out;
reg [3:0] o1;

integer n;

Thor_multiplier #(DBW) umult1
(
	.rst(rst),
	.clk(clk),
	.ld(alu_ld && ((alu_op==`RR && (alu_fn==`MUL || alu_fn==`MULU)) || alu_op==`MULI || alu_op==`MULUI)),
	.abort(alu_abort),
	.sgn((alu_op==`RR && alu_op==`MUL) || alu_op==`MULI),
	.isMuli(alu_op==`MULI || alu_op==`MULUI),
	.a(alu_argA),
	.b(alu_argB),
	.imm(alu_argI),
	.o(alu_prod),
	.done(alu_mult_done),
	.idle(alu_mult_idle)
);

Thor_divider #(DBW) udiv1
(
	.rst(rst),
	.clk(clk),
	.ld(alu_ld && ((alu_op==`RR && (alu_fn==`DIV || alu_fn==`DIVU || alu_fn==`MOD || alu_fn==`MODU))
	   || alu_op==`DIVI || alu_op==`DIVUI || alu_op==`MODI || alu_op==`MODUI)),
	.abort(alu_abort),
	.sgn((alu_op==`RR && (alu_fn==`DIV || alu_fn==`MOD)) || alu_op==`DIVI || alu_op==`MODI),
	.isDivi(alu_op==`DIVI || alu_op==`DIVUI || alu_op==`MODI || alu_op==`MODUI),
	.a(alu_argA),
	.b(alu_argB),
	.imm(alu_argI),
	.qo(alu_divq),
	.ro(alu_rem),
	.dvByZr(alu_divByZero),
	.done(alu_div_done),
	.idle(alu_div_idle)
);

Thor_shifter #(DBW) ushft0
(
	.func(alu_fn),
	.a(alu_argA),
	.b(alu_argB),
	.o(shfto)
);

BCDAdd ubcda
(
	.ci(1'b0),
	.a(alu_argA[7:0]),
	.b(alu_argB[7:0]),
	.o(bcdao),
	.c()
);

BCDSub ubcds
(
	.ci(1'b0),
	.a(alu_argA[7:0]),
	.b(alu_argB[7:0]),
	.o(bcdso),
	.c()
);

BCDMul2 ubcdm
(
	.a(alu_argA),
	.b(alu_argB),
	.o(bcdmo)
);

Thor_bitfield #(DBW) ubf1
(
	.op(alu_fn),
	.a(alu_argA),
	.b(alu_argB),
	.m(alu_argI[11:0]),
	.o(bf_out),
	.masko()
);

Thor_P #(DBW) upr1
(
    .fn(alu_fn),
    .ra(alu_argI[5:0]),
    .rb(alu_argI[11:6]),
    .rt(alu_argI[17:12]),
    .pregs_i(alu_argA),
    .pregs_o(p_out)
);

wire [DBW-1:0] cntlzo;
wire [DBW-1:0] cntloo;
wire [DBW-1:0] cntpopo;

generate
begin : clzg
if (DBW==64) begin
cntlz64 u12 ( .i(alu_argA),  .o(cntlzo) );
cntlo64 u13 ( .i(alu_argA),  .o(cntloo) );
cntpop64 u14 ( .i(alu_argA), .o(cntpopo) );
end
else begin
cntlz32 u12 ( .i(alu_argA),  .o(cntlzo) );
cntlo32 u13 ( .i(alu_argA),  .o(cntloo) );
cntpop32 u14 ( .i(alu_argA), .o(cntpopo) );
end
end
endgenerate

wire faz = alu_argA[DBW-2:0]==63'd0;
wire fbz = alu_argB[DBW-2:0]==63'd0;
wire feq = (faz & fbz) || (alu_argA==alu_argB);	// special test for zero
wire fgt1 = alu_argA[DBW-2:0] > alu_argB[DBW-2:0];
wire flt1 = alu_argA[DBW-2:0] < alu_argB[DBW-2:0];
wire flt = alu_argA[DBW-1] ^ alu_argB[DBW-1] ? alu_argA[DBW-1] & !(faz & fbz): alu_argA[DBW-1] ? fgt1 : flt1;
wire nanA = DBW==32 ? alu_argA[30:23]==8'hFF && (alu_argA[22:0]!=23'd0) : alu_argA[62:52]==11'h7FF && (alu_argA[51:0]!=52'd0);
wire nanB = DBW==32 ? alu_argB[30:23]==8'hFF && (alu_argB[22:0]!=23'd0) : alu_argB[62:52]==11'h7FF && (alu_argB[51:0]!=52'd0);

wire fsaz = alu_argA[30:0]==31'd0;
wire fsbz = alu_argB[30:0]==31'd0;
wire fseq = (fsaz & fsbz) || (alu_argA[31:0]==alu_argB[31:0]);	// special test for zero
wire fsgt1 = alu_argA[30:0] > alu_argB[30:0];
wire fslt1 = alu_argA[30:0] < alu_argB[30:0];
wire fslt = alu_argA[31] ^ alu_argB[31] ? alu_argA[31] & !(fsaz & fsbz): alu_argA[31] ? fsgt1 : fslt1;
wire snanA = alu_argA[30:23]==8'hFF && (alu_argA[22:0]!=23'd0);
wire snanB = alu_argB[30:23]==8'hFF && (alu_argB[22:0]!=23'd0);

always @*
begin
case(alu_op)
`LDI,`LDIS:			o <= alu_argI;
`RR:
	case(alu_fn)
	`ADD,`ADDU:		o <= alu_argA + alu_argB;
	`SUB,`SUBU:		o <= alu_argA - alu_argB;
	`_2ADDU:		o <= {alu_argA[DBW-2:0],1'b0} + alu_argB;
	`_4ADDU:		o <= {alu_argA[DBW-3:0],2'b0} + alu_argB;
	`_8ADDU:		o <= {alu_argA[DBW-4:0],3'b0} + alu_argB;
	`_16ADDU:		o <= {alu_argA[DBW-5:0],4'b0} + alu_argB;
	`MIN:           o <= BIG ? (alu_argA < alu_argB ? alu_argA : alu_argB) : 64'hDEADDEADDEADDEAD; 
	`MAX:           o <= BIG ? (alu_argA < alu_argB ? alu_argB : alu_argA) : 64'hDEADDEADDEADDEAD;
	`MUL,`MULU:     o <= BIG ? alu_prod[63:0] : 64'hDEADDEADDEADDEAD;
	`DIV,`DIVU:     o <= BIG ? alu_divq : 64'hDEADDEADDEADDEAD;  
    `MOD,`MODU:     o <= BIG ? alu_rem : 64'hDEADDEADDEADDEAD;
    `CHK,`CHKX:     o <= ($signed(alu_argC) >= $signed(alu_argA)) && ($signed(alu_argC) < $signed(alu_argB));
	default:   o <= 64'hDEADDEADDEADDEAD;
	endcase
`MULI,`MULUI:   o <= BIG ? alu_prod[63:0] : 64'hDEADDEADDEADDEAD;
`DIVI,`DIVUI:   o <= BIG ? alu_divq : 64'hDEADDEADDEADDEAD;
`MODI,`MODUI:   o <= BIG ? alu_rem : 64'hDEADDEADDEADDEAD;
`_2ADDUI:		o <= {alu_argA[DBW-2:0],1'b0} + alu_argI;
`_4ADDUI:		o <= {alu_argA[DBW-3:0],2'b0} + alu_argI;
`_8ADDUI:		o <= {alu_argA[DBW-4:0],3'b0} + alu_argI;
`_16ADDUI:		o <= {alu_argA[DBW-5:0],4'b0} + alu_argI;
`R:
    case(alu_fn[3:0])
    `MOV:       o <= alu_argA;
    `NEG:		o <= -alu_argA;
    `NOT:       o <= |alu_argA ? 64'd0 : 64'd1;
    `ABS:       o <= BIG ? (alu_argA[DBW-1] ? -alu_argA : alu_argA) : 64'hDEADDEADDEADDEAD;
    `SGN:       o <= BIG ? (alu_argA[DBW-1] ? 64'hFFFFFFFFFFFFFFFF : alu_argA==64'd0 ? 64'd0 : 64'd1) : 64'hDEADDEADDEADDEAD;
    `CNTLZ:     o <= BIG ? cntlzo : 64'hDEADDEADDEADDEAD;
    `CNTLO:     o <= BIG ? cntloo : 64'hDEADDEADDEADDEAD;
    `CNTPOP:    o <= BIG ? cntpopo : 64'hDEADDEADDEADDEAD;
    `ZXB:       o <= BIG ? {56'd0,alu_argA[7:0]} : 64'hDEADDEADDEADDEAD;
    `ZXC:       o <= BIG ? {48'd0,alu_argA[15:0]} : 64'hDEADDEADDEADDEAD;
    `ZXH:       o <= BIG ? {32'd0,alu_argA[31:0]} : 64'hDEADDEADDEADDEAD;
    `COM:       o <= ~alu_argA;
    `SXB:       o <= BIG ? {{56{alu_argA[7]}},alu_argA[7:0]} : 64'hDEADDEADDEADDEAD;
    `SXC:       o <= BIG ? {{48{alu_argA[15]}},alu_argA[15:0]} : 64'hDEADDEADDEADDEAD;
    `SXH:       o <= BIG ? {{32{alu_argA[31]}},alu_argA[31:0]} : 64'hDEADDEADDEADDEAD;
    default:    o <= 64'hDEADDEADDEADDEAD;
    endcase
`R2:
    case(alu_fn)
    `CPUID:
        if (BIG)
        case(alu_argA[4:0])
        5'd0:       o <= corenum;
        5'd2:       o <= "Finitron";
        5'd3:       o <= "";        // vendor ID
        5'd4:       o <= "64BitSS"; // class
        5'd6:       o <= "Thor";    // Name
        5'd8:       o <= "M1";      // model 
        5'd9:       o <= "1234";    // serial num
        5'd10:      o <= FEATURES;
        5'd11:      o <= {32'd16384,32'd32768}; // Cache D,I
        default:    o <= 64'hDEADDEADDEADDEAD;
        endcase
        else    o <= 64'hDEADDEADDEADDEAD;
    `REDOR:     o <= BIG ? |alu_argA : 64'hDEADDEADDEADDEAD;
    `REDAND:    o <= BIG ? &alu_argA : 64'hDEADDEADDEADDEAD;
    `PAR:       o <= BIG ? ^alu_argA : 64'hDEADDEADDEADDEAD;
    default:    o <= 64'hDEADDEADDEADDEAD;
    endcase
`P: o <= p_out;
/*
`DOUBLE:
    if (BIG) begin
        if (alu_fn[5:4]==2'b00)
            case (alu_fn)
            `FMOV:      o <= alu_argA;
            `FNEG:		o <= {~alu_argA[DBW-1],alu_argA[DBW-2:0]};
            `FABS:		o <= {1'b0,alu_argA[DBW-2:0]};
            `FSIGN:			if (DBW==64)
                                o <= alu_argA[DBW-2:0]==0 ? {DBW{1'b0}} : {alu_argA[DBW-1],1'b0,{10{1'b1}},{52{1'b0}}};
                            else
                                o <= alu_argA[DBW-2:0]==0 ? {DBW{1'b0}} : {alu_argA[DBW-1],1'b0,{7{1'b1}},{23{1'b0}}};
            `FMAN:      o <= alu_argA[(DBW==64?51:22):0];
            default:	o <= 64'hDEADDEADDEADDEAD;
            endcase
        else
            case (alu_fn)
            `FMOV:      o <= alu_argA;
            `FSNEG:     o <= {~alu_argA[31],alu_argA[30:0]};
            `FSABS:     o <= {1'b0,alu_argA[30:0]};
            `FSSIGN:    o <= alu_argA[30:0]==0 ? {DBW{1'b0}} : {alu_argA[31],1'b0,{7{1'b1}},{23{1'b0}}};
            `FSMAN:     o <= alu_argA[22:0];
            default:    o <= 64'hDEADDEADDEADDEAD;
            endcase
    end
    else
        o <= 64'hDEADDEADDEADDEAD;
 */

`ADDI,`ADDUI,`ADDUIS:
                o <= alu_argA + alu_argI;
`SUBI,`SUBUI:
            	o <= alu_argA - alu_argI;
`ANDI:			o <= alu_argA & alu_argI;
`ORI:			o <= alu_argA | alu_argI;
`EORI:			o <= alu_argA ^ alu_argI;
`LOGIC,`MLO:
	case(alu_fn)
	`AND:			o <= alu_argA & alu_argB;
	`ANDC:			o <= alu_argA & ~alu_argB;
	`OR:			o <= alu_argA | alu_argB;
	`ORC:			o <= alu_argA | ~alu_argB;
	`EOR:			o <= alu_argA ^ alu_argB;
	`NAND:			o <= ~(alu_argA & alu_argB);
	`NOR:			o <= ~(alu_argA | alu_argB);
	`ENOR:			o <= ~(alu_argA ^ alu_argB);
	default:       o <= 64'd0;
	endcase
`BITI:
    begin
        o1[0] = andi_res==64'd0;
        o1[1] = andi_res[DBW-1];
    	o1[2] = andi_res[0];
        o1[3] = 1'b0;
        o <= {16{o1}};
    end
// TST
8'h00,8'h01,8'h02,8'h03,8'h04,8'h05,8'h06,8'h07,8'h08,8'h09,8'h0A,8'h0B,8'h0C,8'h0D,8'h0E,8'h0f:
	case(alu_fn)
	6'd0:	// TST - integer
		begin
			o1[0] = alu_argA == 64'd0;
			o1[1] = alu_argA[DBW-1];
			o1[2] = 1'b0;
			o1[3] = 1'b0;
			o <= {16{o1}};
		end
`ifdef FLOATING_POINT
	6'd1:	// FSTST - float single
		begin
			o1[0] = alu_argA[30:0]==31'd0;	// + or - zero
			o1[1] = alu_argA[31];			// signed less than
			o1[2] = alu_argA[31];
			// unordered
			o1[3] = alu_argA[30:23]==8'hFF && alu_argA[22:0]!=23'd0;	// NaN
			o <= {16{o1}};
		end
	6'd2:	// FTST - float double
		begin
			o1[0] = alu_argA[DBW-2:0]==63'd0;	// + or - zero
			o1[1] = alu_argA[DBW-1];			// signed less than
			o1[2] = alu_argA[DBW-1];
			// unordered
			if (DBW==64)
				o1[3] = alu_argA[62:52]==11'h7FF && alu_argA[51:0]!=52'd0;	// NaN
			else
				o1[3] = 1'b0;
			o <= {16{o1}};
		end
`endif
	default:	o <= 64'd0;
	endcase
// CMP
8'h10,8'h11,8'h12,8'h13,8'h14,8'h15,8'h16,8'h17,8'h18,8'h19,8'h1A,8'h1B,8'h1C,8'h1D,8'h1E,8'h1f:
    begin
            case(alu_fn)
            2'd0: begin     // ICMP
                o1[0] = alu_argA == alu_argB;
                o1[1] = ($signed(alu_argA) < $signed(alu_argB));
                o1[2] = alu_argA < alu_argB;
                o1[3] = 1'b0;
    			o <= {16{o1}};
                end
`ifdef FLOATING_POINT
            2'd1: begin     // FSCMP
                o1[0] = fseq;
                o1[1] = fslt;
                o1[2] = fslt1;
                o1[3] = snanA | snanB;
    			o <= {16{o1}};
                end
            2'd2: begin     // FCMP
                o1[0] = feq;
                o1[1] = flt;
                o1[2] = flt1;
                o1[3] = nanA | nanB;
    			o <= {16{o1}};
                end
`endif
            default: o <= 64'hDEADDEADDEADDEAD;
            endcase
		end
// CMPI
8'h20,8'h21,8'h22,8'h23,8'h24,8'h25,8'h26,8'h27,8'h28,8'h29,8'h2A,8'h2B,8'h2C,8'h2D,8'h2E,8'h2f:
	begin
			o1[0] = alu_argA == alu_argI;
			o1[1] = ($signed(alu_argA) < $signed(alu_argI));
			o1[2] = alu_argA < alu_argI;
			o1[3] = 1'b0;
			o <= {16{o1}};
		end
`LLA,
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`SB,`SC,`SH,`SW,`CAS,`LVB,`LVC,`LVH,`LVW,`STI,
`LWS,`SWS,`STS,`STFND,`STCMP,`PUSH:
            begin
              if (SEGMODEL==2)
				        o <= {alu_argA[DBW-1:DBW-3],alu_argA[DBW-4:0] + alu_argI[DBW-4:0]};
				     else
				        o <= alu_argA + alu_argC + alu_argI;
		    end
`JMPI:      if (SEGMODEL==2)
              o <= {alu_argA[DBW-1:DBW-3],{alu_argA[DBW-6:0] << alu_fn[1:0]} + alu_argI[DBW-4:0]};
            else
              o <= {alu_argA << alu_fn[1:0]} + alu_argC + alu_argI;
`LBX,`LBUX,`SBX,
`LCX,`LCUX,`SCX,
`LHX,`LHUX,`SHX,
`LWX,`SWX,`LLAX,
`JMPIX:	
            if (SEGMODEL==2) begin
              case(alu_fn[1:0])
              2'd0:   o <= {alu_argA[DBW-1:DBW-3],alu_argA[DBW-4:0] + alu_argB[DBW-4:0]};
              2'd1:   o <= {alu_argA[DBW-1:DBW-3],alu_argA[DBW-4:0] + {alu_argB[DBW-5:0],1'b0}};
              2'd2:   o <= {alu_argA[DBW-1:DBW-3],alu_argA[DBW-4:0] + {alu_argB[DBW-6:0],2'b0}};
              2'd3:   o <= {alu_argA[DBW-1:DBW-3],alu_argA[DBW-4:0] + {alu_argB[DBW-7:0],3'b0}};
              endcase
            end
            else begin
              case(alu_fn[1:0])
              2'd0:   o <= alu_argA + alu_argC + alu_argB;
              2'd1:   o <= alu_argA + alu_argC + {alu_argB,1'b0};
              2'd2:   o <= alu_argA + alu_argC + {alu_argB,2'b0};
              2'd3:   o <= alu_argA + alu_argC + {alu_argB,3'b0};
              endcase
            end
`ifdef VECTOROPS
`LV,`SV:      if (SEGMODEL==2)
                o <= {alu_argA[DBW-1:DBW-3],alu_argA[DBW-4:0] + alu_argI[DBW-4:0]}; 
              else
                o <= alu_argA + alu_argC + alu_argI;         
`LVWS,`SVWS:  if (SEGMODEL==2)
                o <= {alu_argA[DBW-1:DBW-3],alu_argA[DBW-4:0] + alu_argB[DBW-10:0] * alu_argI[8:3]}; 
              else 
                o <= alu_argA + alu_argC + alu_argB * alu_argI[8:3];
`LVX,`SVX:    if (SEGMODEL=2)
                o <= {alu_argA[DBW-1:DBW-3],alu_argA[DBW-4:0] + alu_argB[DBW-4:0]}; 
              else
                o <= alu_argA + alu_argC + alu_argB;
`endif
`ifdef STACKOPS
`PEA,`LINK: 
            if (SEGMODEL==2)
              o <= alu_argA - 64'd8;
            else
              o <= alu_argA + alu_argC - 64'd8;
`UNLINK:    if (SEGMODEL==2)
              o <= alu_argA + 64'd8;
            else 
              o <= alu_argA + alu_argC + 64'd8;
`POP:       if (SEGMODEL==2)
              o <= alu_argA;
            else
              o <= alu_argA + alu_argC;
`endif
// should really account for a prefix as well
// insn size += size of prefix
`JSR,`JSRS,`JSRZ,`SYS,`JSF:	o <= alu_pc + insnsz;
`INT:		o <= alu_pc;
`MFSPR,`MTSPR:	begin
                o <= alu_argA;
                end
`MUX:	begin
			for (n = 0; n < DBW; n = n + 1)
				o[n] <= alu_argA[n] ? alu_argB[n] : alu_argC[n];
		end
`BCD:
        if (BIG)
            case(alu_fn)
            `BCDADD:	o <= bcdao;
            `BCDSUB:	o <= bcdso;
            `BCDMUL:	o <= bcdmo;
            default:	o <= 64'hDEADDEADDEADDEAD;
            endcase
        else
            o <= 64'hDEADDEADDEADDEAD;
`SHIFT:	    o <= BIG ? shfto : 64'hDEADDEADDEADDEAD;
`ifdef BITFIELDOPS
`BITFIELD:	o <= BIG ? bf_out : 64'hDEADDEADDEADDEAD;
`endif
`LOOP:      o <= alu_argA > 0 ? alu_argA - 64'd1 : alu_argA;
`CHKXI:   o <= ($signed(alu_argB) >= $signed(alu_argA)) && ($signed(alu_argB) < $signed(alu_argI));
`CHKI:
    begin
        o1[0] = ($signed(alu_argB) >= $signed(alu_argA)) && ($signed(alu_argB) < $signed(alu_argI));
        o1[1] = 1'b0;
        o1[2] = 1'b0;
        o1[3] = 1'b0;
        o <= {16{o1}};
    end
default:	o <= 64'hDEADDEADDEADDEAD;
endcase
end

// Generate done signal
always @*
case(alu_op)
`RR:
    case(alu_fn)
    `MUL,`MULU: alu_done <= alu_mult_done;
    `DIV,`DIVU,`MOD,`MODU: alu_done <= alu_div_done;
    default:    alu_done <= `TRUE;
    endcase
`MULI,`MULUI:   alu_done <= alu_mult_done;
`DIVI,`DIVUI,`MODI,`MODUI:   alu_done <= alu_div_done;
default:    alu_done <= `TRUE;
endcase

// Generate idle signal
always @*
case(alu_op)
`RR:
    case(alu_fn)
    `MUL,`MULU: alu_idle <= alu_mult_idle;
    `DIV,`DIVU,`MOD,`MODU: alu_idle <= alu_div_idle;
    default:    alu_idle <= `TRUE;
    endcase
`MULI,`MULUI:   alu_idle <= alu_mult_idle;
`DIVI,`DIVUI,`MODI,`MODUI:   alu_idle <= alu_div_idle;
default:    alu_idle <= `TRUE;
endcase

endmodule
