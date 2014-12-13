`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// Table888Float.v
//  - Triple precision floating point accelerator
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
// 1600 LUTs 350 FF's
// 150 MHz
// ============================================================================
//
module Table888Float(rst_i, clk_i, cyc_i, stb_i, ack_o, we_i, adr_i, dat_i, dat_o, ldFAC, FAC1_i, FAC1_o);
parameter pIOAddress = 32'hFFDEA200;
parameter EMSB = 15;
parameter FMSB = 79;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter CMD_ADD = 8'd1;
parameter CMD_SUB = 8'd2;
parameter CMD_CMP = 8'd3;
parameter CMD_MUL = 8'd4;
parameter CMD_DIV = 8'd5;
parameter CMD_NEG = 8'd6;
parameter CMD_FIX2FLT = 8'd8;
parameter CMD_FLT2FIX = 8'd9;
parameter CMD_READREG = 8'd10;
parameter CMD_WRITEREG = 8'd11;
parameter CMD_STAT = 8'd12;
parameter CMD_MOVE = 8'd13;
parameter FADD = 8'd1;
parameter FSUB = 8'd2;
parameter FMUL = 8'd3;
parameter FDIV = 8'd4;
parameter FIX2FLT = 8'd5;
parameter FLT2FIX = 8'd6;
parameter MD1 = 8'd10;
parameter ABSSWP = 8'd11;
parameter ABSSWP1 = 8'd12;
parameter NORM1 = 8'd13;
parameter NORM = 8'd14;
parameter ADD = 8'd15;
parameter FCOMPL = 8'd16;
parameter FNEG = 8'd16;
parameter SWAP = 8'd17;
parameter SWPALG = 8'd18;
parameter ADDEND = 8'd19;
parameter ALGNSW = 8'd20;
parameter RTAR = 8'd21;
parameter RTLOG = 8'd22;
parameter RTLOG1 = 8'd23;
parameter FMUL1 = 8'd24;
parameter FMUL2 = 8'd25;
parameter MUL1 = 8'd26;
parameter FMUL3 = 8'd27;
parameter MUL2 = 8'd28;
parameter MDEND = 8'd29;
parameter FDIV1 = 8'd30;
parameter MD2 = 8'd31;
parameter MD3 = 8'd32;
parameter OVCHK = 8'd34;
parameter OVFL = 8'd35;
parameter DIV1 = 8'd36;
parameter STEP1 = 8'd37;
parameter IDLE = 8'd62;
parameter RESET = 8'd63;

input rst_i;
input clk_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [31:0] adr_i;
input [31:0] dat_i;
output reg [31:0] dat_o;
input ldFAC;
output [95:0] FAC1_o;
input [95:0] FAC1_i;

reg [31:0] cmd;
reg [7:0] opcode;
reg [7:0] Ra;
reg [7:0] Rb;
reg [7:0] Rt;
reg [7:0] state;
reg [5:0] state_stk [15:0];
reg [3:0] sp;
reg [1:0] sign;
reg [EMSB:0] acc;
reg [7:0] y;
reg wrrf;
reg [EMSB+FMSB+1:0] fpregs [255:0];
reg [EMSB+FMSB+1:0] FAC1;
reg [EMSB+FMSB+1:0] FAC2;
reg [FMSB:0] E;
wire [EMSB:0] FAC1_exp = FAC1[EMSB+FMSB+1:FMSB+1];
wire [FMSB:0] FAC1_man = FAC1[FMSB:0];
wire [EMSB:0] FAC2_exp = FAC2[EMSB+FMSB+1:FMSB+1];
wire [FMSB:0] FAC2_man = FAC2[FMSB:0];

wire [FMSB+1:0] sum = FAC1_man + FAC2_man;
wire [FMSB+1:0] dif = FAC2_man - E;
wire [FMSB+1:0] neg = {FMSB+1{1'b0}} - FAC1_man;
wire [EMSB+1:0] expdif = FAC2_exp - FAC1_exp;
// Note the carry flag must be extended manually!
wire [EMSB+1:0] exp_sum = acc + FAC1_exp + {15'd0,cf};	// FMUL
wire [EMSB+1:0] exp_dif = acc - FAC1_exp - {15'd0,~cf};	// FDIV
reg [FMSB:0] rem;

reg cf,vf;
reg busy;
reg isRTAR;
reg [7:0] dbo;

wire eq = FAC1==FAC2;
wire gt = (FAC1[FMSB]^FAC2[FMSB]) ? FAC2[FMSB] : // If the signs are different, whichever one is positive
		   FAC1_exp==FAC2_exp ? (FAC1_man > FAC2_man) :	// if exponents are equal check mantissa
		   FAC1_exp > FAC2_exp;	// else compare exponents
wire lt = !(gt|eq);
wire zf = ~|FAC1;
wire nf = FAC1[FMSB];

wire cs = cyc_i && stb_i && (adr_i[31:8]==pIOAddress[31:8]);
reg rdy1,rdy2,rdy3;
always @(posedge clk_i)
if (rst_i) begin
	rdy1 <= 1'b0;
	rdy2 <= 1'b0;
	rdy3 <= 1'b0;
end
else begin
	rdy1 <= cs & ~rdy1;
	rdy2 <= cs & rdy1;
	rdy3 <= cs & rdy2;
end
assign ack_o = cs ? (~we_i ? (opcode==`CMD_CMP ? rdy3 : rdy1) : 1'b1) : 1'b0;
assign FAC1_o = FAC1;

always @(posedge clk_i)
if (rst_i) begin
	next_state(RESET);
end
else begin
	if (ldFAC)
		FAC1 <= FAC1_i;
	wrrf <= 1'b0;
	cmd <= 32'h00;
	if (cs & we_i)
		case(adr_i[7:2])
//		6'h00:	FAC1[31:0] <= dat_i;
//		6'h01:	FAC1[63:32] <= dat_i;
//		6'h02:	FAC1[95:64] <= dat_i;
		6'h04:	cmd <= dat_i;
		endcase

	if (cs & ~we_i)
	case(adr_i[7:2])
//	6'h00:	dat_o <= FAC1[31:0];
//	6'h01:	dat_o <= FAC1[63:32];
//	6'h02:	dat_o <= FAC1[95:64];
	6'h03:	dat_o <= 32'h0;
	6'h04:	dat_o <= {busy,23'b0,1'b0,lt,eq,gt,nf,zf,vf,cf};
	endcase
	else 	dat_o <= 32'h0;
	
	if (wrrf)
		fpregs[Rt] <= FAC1;

case(state)
RESET:
	begin
		sp <= 4'h0;
		next_state(IDLE);
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

IDLE:
	begin
		busy <= 1'b0;
		sp <= 4'h0;
		opcode <= cmd[7:0];
		Ra <= cmd[15:8];
		Rb <= cmd[23:16];
		Rt <= cmd[31:24];
		case(cmd[7:0])
		CMD_ADD:	begin busy <= 1'b1; next_state(STEP1); end
		CMD_SUB:	begin busy <= 1'b1; next_state(STEP1); end
		CMD_CMP:	begin busy <= 1'b1; next_state(STEP1); end
		CMD_MUL:	begin busy <= 1'b1; next_state(STEP1); end
		CMD_DIV:	begin busy <= 1'b1; next_state(STEP1); end
		CMD_FIX2FLT:	begin busy <= 1'b1; next_state(STEP1); end
		CMD_FLT2FIX:	begin busy <= 1'b1; next_state(STEP1); end
		CMD_NEG:		begin busy <= 1'b1; next_state(STEP1); end
		CMD_WRITEREG:	wrrf <= 1'b1;
		CMD_READREG:	begin busy <= 1'b1; next_state(STEP1); end
		CMD_MOVE:		begin busy <= 1'b1; next_state(STEP1); end
		endcase
	end

STEP1:
	begin
		FAC1 <= fpregs[Ra];
		FAC2 <= fpregs[Rb];
		case(opcode)
		CMD_ADD:	begin push_state(IDLE); next_state(FADD); end
		CMD_SUB:	begin push_state(IDLE); next_state(FSUB); end
		CMD_CMP:	next_state(IDLE);
		CMD_MUL:	begin push_state(IDLE); next_state(FMUL); end
		CMD_DIV:	begin push_state(IDLE); next_state(FDIV); end
		CMD_FIX2FLT:	begin push_state(IDLE); next_state(FIX2FLT); end
		CMD_FLT2FIX:	begin push_state(IDLE); next_state(FLT2FIX); end
		CMD_NEG:		begin push_state(IDLE); next_state(FCOMPL); end
		CMD_READREG:	next_state(IDLE);
		CMD_MOVE:		begin wrrf <= 1'b1; next_state(IDLE); end
		endcase
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

MD1:
	begin
		$display("MD1");
		sign <= {sign[1:0],1'b0};
		next_state(ABSSWP);
		push_state(ABSSWP);
	end
ABSSWP:
	begin
		if (~FAC1_man[FMSB]) begin
			next_state(ABSSWP1);
		end
		else begin
			push_state(ABSSWP1);
			sign <= sign + 2'd1;
			next_state(FCOMPL);
		end
	end
ABSSWP1:
	begin
		cf <= 1'b1;
		next_state(SWAP);
	end

//-----------------------------------------------------------------------------
// Normalize
// - Decrement exponent and shift left
// - Normalization is normally the last step of an operation so it is used
//   to set a couple of result flags.
//-----------------------------------------------------------------------------
NORM1:
	begin
	FAC1[EMSB+FMSB+1:FMSB+1] <= FAC1[EMSB+FMSB+1:FMSB+1] - 16'd1;
	FAC1[FMSB:0] <= {FAC1[FMSB-1:0],1'b0};
	next_state(NORM);
	end
NORM:
	begin
	$display("Normalize");
	if (FAC1[FMSB]!=FAC1[FMSB-1] || FAC1_exp==16'h0000) begin
		$display("Normal: %h",FAC1);
		pop_state();
	end
	// If the mantissa is zero, set the the exponent to zero. Otherwise 
	// normalization could spin for thousands of clock cycles decrementing
	// the exponent to zero.
	else if (~|FAC1_man) begin
		FAC1[EMSB+FMSB+1:FMSB+1] <= 16'h0;
		wrrf <= 1'b1;
		pop_state();
	end
	else
		next_state(NORM1);
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

ADD:
	begin
		FAC1[FMSB:0] <= sum[FMSB:0];
		cf <= sum[FMSB+1];
		vf <= (sum[FMSB] ^ FAC2[FMSB]) & (1'b1 ^ FAC1[FMSB] ^ FAC2[FMSB]);
		pop_state();
	end

//-----------------------------------------------------------------------------
// Negate
//-----------------------------------------------------------------------------

// Complement FAC1
FCOMPL:
	begin
		$display("FCOMPL");
		FAC1[FMSB:0] <= neg[FMSB:0];
		cf <= ~neg[FMSB+1];
		vf <= neg[FMSB]==FAC1[FMSB];
		next_state(ADDEND);
	end

//-----------------------------------------------------------------------------
// Swap FAC1 and FAC2
//-----------------------------------------------------------------------------

SWAP:
	begin
		$display("Swapping FAC1 and FAC2");
		FAC1 <= FAC2;
		FAC2 <= FAC1;
		E <= FAC2[FMSB:0];
		acc <= FAC1_exp;
		wrrf <= 1'b1;
		pop_state();
	end

//-----------------------------------------------------------------------------
// Subtract
//-----------------------------------------------------------------------------

FSUB:
	begin
		push_state(SWPALG);
		next_state(FCOMPL);
	end
SWPALG:
	begin
		push_state(FADD);
		next_state(ALGNSW);
	end

//-----------------------------------------------------------------------------
// Addition
//-----------------------------------------------------------------------------

FADD:
	begin
		cf <= ~expdif[EMSB+1];	// Must set carry flag from compare
		if (|expdif[EMSB:0])
			next_state(SWPALG);
		else begin
			push_state(ADDEND);
			next_state(ADD);
		end
	end
ADDEND:
	begin
		if (!vf)
			next_state(NORM);
		else begin
			isRTAR <= FALSE;
			next_state(RTLOG);
		end
	end
ALGNSW:
	begin
		if (!cf)
			next_state(SWAP);
		else begin
			isRTAR <= TRUE;
			next_state(RTLOG);
		end
	end

//-----------------------------------------------------------------------------
// Right shift, logical or arithmetic.
//-----------------------------------------------------------------------------

RTLOG:
	begin
		FAC1[EMSB+FMSB+1:FMSB+1] <= FAC1[EMSB+FMSB+1:FMSB+1] + 16'd1;
		if (FAC1[EMSB+FMSB+1:FMSB+1]==16'hFFFF)
			next_state(OVFL);
		else begin
			FAC1[FMSB:0] <= {isRTAR ? FAC1_man[FMSB] : cf,FAC1[FMSB:1]};
			E[FMSB:0] <= {FAC1[0],E[FMSB-1:1]};
			cf <= E[0];
			pop_state();
		end
	end

//-----------------------------------------------------------------------------
// Multiply
//-----------------------------------------------------------------------------

FMUL:
	begin
		next_state(MD1);
		push_state(FMUL1);
	end
FMUL1:
	begin
		acc <= exp_sum[EMSB:0];
		cf <= exp_sum[EMSB+1];
		push_state(MUL1);
		next_state(MD2);
	end
MUL1:
	begin
		// inline RTLOG1 code
		FAC1[FMSB:0] <= {1'b0,FAC1[FMSB:1]};
		E[FMSB:0] <= {FAC1[0],E[FMSB-1:1]};
		cf <= E[0];
		next_state(FMUL3);
//		push_state(FMUL3);
//		next_state(RTLOG1);
	end
FMUL3:
	begin
		if (cf) begin
			FAC1[FMSB:0] <= sum[FMSB:0];
			cf <= sum[FMSB+1];
			vf <= (sum[FMSB] ^ FAC2[FMSB]) & (1'b1 ^ FAC1[FMSB] ^ FAC2[FMSB]);
		end
		y <= y - 8'd1;
		if (y==8'd0)
			next_state(MDEND);
		else
			next_state(MUL1);
	end
MDEND:
	begin
		sign <= {1'b0,sign[1]};
		if (~sign[0])
			next_state(NORM);
		else
			next_state(FCOMPL);
	end

//-----------------------------------------------------------------------------
// Divide
//-----------------------------------------------------------------------------
FDIV:
	begin
		push_state(FDIV1);
		next_state(MD1);
	end
FDIV1:
	begin
		acc <= exp_dif[EMSB:0];
		cf <= ~exp_dif[EMSB+1];
		$display("acc=%h %h %h", exp_dif, acc, FAC1_exp);
		push_state(DIV1);
		next_state(MD2);
	end
DIV1:
	begin
		$display("FAC1=%h, FAC2=%h, E=%h", FAC1, FAC2, E);
		y <= y - 8'd1;
		FAC1[FMSB:0] <= {FAC1[FMSB:0],~dif[FMSB+1]};
		if (dif[FMSB+1]) begin
			FAC2[FMSB:0] <= {FAC2[FMSB-1:0],1'b0};
			if (FAC2[FMSB]) begin
				next_state(OVFL);
			end
			else if (y!=8'd1)
				next_state(DIV1);
			else begin
				rem <= dif;
				next_state(MDEND);
			end
		end
		else begin
			FAC2[FMSB:0] <= {dif[FMSB-1:0],1'b0};
			if (dif[FMSB]) begin
				next_state(OVFL);
			end
			else if (y!=8'd1)
				next_state(DIV1);
			else begin
				rem <= dif;
				next_state(MDEND);
			end
		end
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
MD2:
	begin
		FAC1[FMSB:0] <= 80'h0;
		if (cf)
			next_state(OVCHK);
		else if (acc[EMSB])
			next_state(MD3);
		else begin
			pop_state();
			next_state(NORM);
		end
	end
MD3:
	begin
		acc[EMSB] <= ~acc[EMSB];
		FAC1[EMSB+FMSB+1:FMSB+1] <= {~acc[EMSB],acc[EMSB-1:0]};
		y <= 8'h4F;
		pop_state();
	end
OVCHK:
	begin
		if (~acc[EMSB])
			next_state(MD3);
		else
			next_state(OVFL);
	end
OVFL:
	begin
		vf <= 1'b1;
		next_state(IDLE);
	end

//-----------------------------------------------------------------------------
// FIX2FLT
// - convert 64 bit fixed point number to floating point
//-----------------------------------------------------------------------------

FIX2FLT:
	begin
		FAC1[EMSB+FMSB+1:FMSB+1] <= 16'h803E;	// exponent = 62
		FAC1[EMSB:0] <= 16'h0000;
		next_state(NORM);
	end

//-----------------------------------------------------------------------------
// FLT2FIX
// - convert floating point number to fixed point.
//-----------------------------------------------------------------------------

FLT2FIX:
	begin
		if (FAC1_exp==16'h803E)
			pop_state();
		else begin
			push_state(FLT2FIX);
			isRTAR <= TRUE;
			next_state(RTLOG);
		end
	end
endcase
end

/*
DIVBY10:
	begin
		FAC2[EMSB+FMSB+1:FMSB+1] <= 16'h8003;
		FAC2[FMSB] <= 1'b0;		// +ve
		FAC2[FMSB-1:75] <= 4'hA;	// 10
		FAC2[74:0] <= 75'd0;
		next_state(FDIV);
	end
*/
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
task push_state;
input [5:0] st;
begin
	state_stk[sp-4'd1] <= st;
	sp <= sp - 4'd1;
end
endtask

task pop_state;
begin
	next_state(state_stk[sp]);
	sp <= sp + 4'd1;
end
endtask

task next_state;
input [7:0] st;
begin
	state <= st;
end
endtask

endmodule
