`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FT816Float.v
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
// 1700 LUTs 400 FF's
// 140 MHz
// ============================================================================
//
module FT816Float(rst, clk, vda, rw, ad, db, rdy);
parameter pIOAddress = 24'hFEA200;
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
parameter IDLE = 8'd62;
parameter RESET = 8'd63;

input rst;
input clk;
input vda;
input rw;
input [23:0] ad;
inout tri [7:0] db;
output rdy;

reg [7:0] cmd;
reg [7:0] state;
reg [5:0] state_stk [63:0];
reg [5:0] sp;
reg [3:0] sign;
reg [15:0] acc;
reg [7:0] y;
reg [95:0] FAC1;
reg [95:0] FAC2;
reg [79:0] E;
wire [15:0] FAC1_exp = FAC1[95:80];
wire [79:0] FAC1_man = FAC1[79:0];
wire [15:0] FAC2_exp = FAC2[95:80];
wire [79:0] FAC2_man = FAC2[79:0];

wire [80:0] sum = FAC1_man + FAC2_man;
wire [80:0] dif = FAC2_man - E;
wire [80:0] neg = 80'h0 - FAC1_man;
// Note the carry flag must be extended manually!
wire [16:0] exp_sum = acc + FAC1_exp + {15'd0,cf};	// FMUL
wire [16:0] exp_dif = acc - FAC1_exp - {15'd0,~cf};	// FDIV
reg [79:0] rem;

reg cf,vf,nf,zf;
reg busy;
reg [7:0] dbo;

wire cs = vda && (ad[23:8]==pIOAddress[23:8]);
reg rdy1;
always @(posedge clk)
if (rst)
	rdy1 <= 1'b1;
else
	rdy1 <= cs & ~rdy1;
assign rdy = cs ? (rw ? rdy1 : 1'b1) : 1'b1;
assign db = cs & rw ? dbo : {8{1'bz}};

always @(posedge clk)
if (rst) begin
	next_state(RESET);
end
else begin
	cmd <= 8'h00;
	if (cs & ~rw)
		case(ad[7:0])
		8'h00:	FAC1[7:0] <= db;
		8'h01:	FAC1[15:8] <= db;
		8'h02:	FAC1[23:16] <= db;
		8'h03:	FAC1[31:24] <= db;
		8'h04:	FAC1[39:32] <= db;
		8'h05:	FAC1[47:40] <= db;
		8'h06:	FAC1[55:48] <= db;
		8'h07:	FAC1[63:56] <= db;
		8'h08:	FAC1[71:64] <= db;
		8'h09:	FAC1[79:72] <= db;
		8'h0A:	FAC1[87:80] <= db;
		8'h0B:	FAC1[95:88] <= db;
		8'h0F:	cmd <= db;
		8'h10:	FAC2[7:0] <= db;
		8'h11:	FAC2[15:8] <= db;
		8'h12:	FAC2[23:16] <= db;
		8'h13:	FAC2[31:24] <= db;
		8'h14:	FAC2[39:32] <= db;
		8'h15:	FAC2[47:40] <= db;
		8'h16:	FAC2[55:48] <= db;
		8'h17:	FAC2[63:56] <= db;
		8'h18:	FAC2[71:64] <= db;
		8'h19:	FAC2[79:72] <= db;
		8'h1A:	FAC2[87:80] <= db;
		8'h1B:	FAC2[95:88] <= db;
		endcase

	case(ad[7:0])
	8'h00:	dbo <= FAC1[7:0];
	8'h01:	dbo <= FAC1[15:8];
	8'h02:	dbo <= FAC1[23:16];
	8'h03:	dbo <= FAC1[31:24];
	8'h04:	dbo <= FAC1[39:32];
	8'h05:	dbo <= FAC1[47:40];
	8'h06:	dbo <= FAC1[55:48];
	8'h07:	dbo <= FAC1[63:56];
	8'h08:	dbo <= FAC1[71:64];
	8'h09:	dbo <= FAC1[79:72];
	8'h0A:	dbo <= FAC1[87:80];
	8'h0B:	dbo <= FAC1[95:88];
	8'h0F:	dbo <= {busy,5'h00,zf,vf};
	8'h10:	dbo <= FAC2[7:0];
	8'h11:	dbo <= FAC2[15:8];
	8'h12:	dbo <= FAC2[23:16];
	8'h13:	dbo <= FAC2[31:24];
	8'h14:	dbo <= FAC2[39:32];
	8'h15:	dbo <= FAC2[47:40];
	8'h16:	dbo <= FAC2[55:48];
	8'h17:	dbo <= FAC2[63:56];
	8'h18:	dbo <= FAC2[71:64];
	8'h19:	dbo <= FAC2[79:72];
	8'h1A:	dbo <= FAC2[87:80];
	8'h1B:	dbo <= FAC2[95:88];
	endcase

case(state)
RESET:
	begin
		sp <= 6'h00;
		next_state(IDLE);
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

IDLE:
	begin
		busy <= 1'b0;
		sp <= 6'h00;
		case(cmd)
		FADD:	begin push_state(IDLE); next_state(FADD); busy <= 1'b1; end
		FSUB:	begin push_state(IDLE); next_state(FSUB); busy <= 1'b1; end
		FMUL:	begin push_state(IDLE); next_state(FMUL); busy <= 1'b1; end
		FDIV:	begin push_state(IDLE); next_state(FDIV); busy <= 1'b1; end
		FIX2FLT:	begin push_state(IDLE); next_state(FIX2FLT); busy <= 1'b1; end
		FLT2FIX:	begin push_state(IDLE); next_state(FLT2FIX); busy <= 1'b1; end
		FNEG:		begin push_state(IDLE); next_state(FCOMPL); busy <= 1'b1; end
		SWAP:		begin push_state(IDLE); next_state(SWAP); busy <= 1'b1; end
		endcase
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

MD1:
	begin
		$display("MD1");
		sign <= {sign[2:0],1'b0};
		next_state(ABSSWP);
		push_state(ABSSWP);
	end
ABSSWP:
	begin
		if (~FAC1_man[79]) begin
			next_state(ABSSWP1);
		end
		else begin
			push_state(ABSSWP1);
			sign <= sign + 4'd1;
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
	FAC1[95:80] <= FAC1[95:80] - 16'd1;
	FAC1[79:0] <= {FAC1[78:0],1'b0};
	next_state(NORM);
	end
NORM:
	begin
	$display("Normalize");
	if (FAC1_exp==16'h0000)
		zf <= 1'b1;
	else
		zf <= 1'b0;
	if (FAC1[79]!=FAC1[78] || FAC1_exp==16'h0000) begin
		$display("Normal: %h",FAC1);
		pop_state();
	end
	// If the mantissa is zero, set the the exponent to zero. Otherwise 
	// normalization could spin for thousands of clock cycles decrementing
	// the exponent to zero.
	else if (~|FAC1_man) begin
		FAC1[95:80] <= 16'h0;
		zf <= 1'b1;
		pop_state();
	end
	else
		next_state(NORM1);
	end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

ADD:
	begin
		FAC1[79:0] <= sum[79:0];
		cf <= sum[80];
		vf <= (sum[79] ^ FAC2[79]) & (1'b1 ^ FAC1[79] ^ FAC2[79]);
		pop_state();
	end

//-----------------------------------------------------------------------------
// Negate
//-----------------------------------------------------------------------------

// Complement FAC1
FCOMPL:
	begin
		$display("FCOMPL");
		FAC1[79:0] <= neg[79:0];
		cf <= ~neg[80];
		vf <= neg[79]==FAC1[79];
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
		E <= FAC2[79:0];
		acc <= FAC1_exp;
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
		if (FAC1_exp != FAC2_exp)
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
		else
			next_state(RTLOG);
	end
ALGNSW:
	begin
		if (!cf)
			next_state(SWAP);
		else
			next_state(RTAR);
	end
RTAR:
	begin
		cf <= FAC1_man[79];
		next_state(RTLOG);
	end
RTLOG:
	begin
		FAC1[95:80] <= FAC1[95:80] + 16'd1;
		if (FAC1[95:80]==16'hFFFF)
			next_state(OVFL);
		else
			next_state(RTLOG1);
	end
RTLOG1:
	begin
		FAC1[79:0] <= {FAC1[79],FAC1[79:1]};
		E[79:0] <= {FAC1[0],E[78:1]};
		cf <= E[0];
		pop_state();
	end

//-----------------------------------------------------------------------------
// Mulyiply
//-----------------------------------------------------------------------------

FMUL:
	begin
		next_state(MD1);
		push_state(FMUL1);
	end
FMUL1:
	begin
		acc <= exp_sum[15:0];
		cf <= exp_sum[16];
		push_state(FMUL2);
		next_state(MD2);
	end
FMUL2:
	begin
		cf <= 1'b0;
		next_state(MUL1);
	end
MUL1:
	begin
		push_state(FMUL3);
		next_state(RTLOG1);
	end
FMUL3:
	begin
		if (!cf)
			next_state(MUL2);
		else begin
			push_state(MUL2);
			next_state(ADD);
		end
	end
MUL2:
	begin
		y <= y - 8'd1;
		if (y!=8'd0)
			next_state(MUL1);
		else
			next_state(MDEND);
	end
MDEND:
	begin
		sign <= {1'b0,sign[3:1]};
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
		acc <= exp_dif[15:0];
		cf <= ~exp_dif[16];
		$display("acc=%h %h %h", exp_dif, acc, FAC1_exp);
		push_state(DIV1);
		next_state(MD2);
	end
DIV1:
	begin
		$display("FAC1=%h, FAC2=%h, E=%h", FAC1, FAC2, E);
		y <= y - 8'd1;
		FAC1[79:0] <= {FAC1[79:0],~dif[80]};
		if (dif[80]) begin
			FAC2[79:0] <= {FAC2[78:0],1'b0};
			if (FAC2[79]) begin
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
			FAC2[79:0] <= {dif[78:0],1'b0};
			if (dif[79]) begin
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
		FAC1[79:0] <= 80'h0;
		if (cf)
			next_state(OVCHK);
		else if (acc[15])
			next_state(MD3);
		else begin
			pop_state();
			next_state(NORM);
		end
	end
MD3:
	begin
		acc[15] <= ~acc[15];
		FAC1[95:80] <= {~acc[15],acc[14:0]};
		y <= 8'h4F;
		pop_state();
	end
OVCHK:
	begin
		if (~acc[15])
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
		FAC1[95:80] <= 16'h803E;	// exponent = 62
		FAC1[15:0] <= 16'h0000;
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
			next_state(RTAR);
		end
	end
endcase
end

/*
DIVBY10:
	begin
		FAC2[95:80] <= 16'h8003;
		FAC2[79] <= 1'b0;		// +ve
		FAC2[78:75] <= 4'hA;	// 10
		FAC2[74:0] <= 75'd0;
		next_state(FDIV);
	end
*/
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
task push_state;
input [5:0] st;
begin
	state_stk[sp-6'd1] <= st;
	sp <= sp - 6'd1;
end
endtask

task pop_state;
begin
	next_state(state_stk[sp]);
	sp <= sp + 6'd1;
end
endtask

task next_state;
input [7:0] st;
begin
	state <= st;
end
endtask

endmodule
