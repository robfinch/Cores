// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
// ============================================================================
//
module rtfItanium(rst_i, clk_i, );
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

// Different types of instructions
// Table C-3
parameter ITMemmgnt = 5'd0;
parameter ITIntLdReg = 5'd1;
parameter ITIntLdStImm = 5'd2;
parameter ITFpLdStReg = 5'd3;
parameter ITFpLdStImm = 5'd4;
parameter ITALU = 5'd5;
parameter ITAdd = 5'h6;
parameter ITCmp = 5'd7;
parameter ITMisc = 5'd8;
parameter ITDeposit = 5'd9;
parameter ITShift = 5'd10;
parameter ITMovl = 5'd11;
parameter ITMpy = 5'd12;
parameter ITFPMisc = 5'd13;
parameter ITFPCmp = 5'd14;
parameter ITFPClass = 5'd15;
parameter ITFPfma = 5'd16;
parameter ITFPfms = 5'd17;
parameter ITfnma = 5'd18;
parameter ITSelect = 5'd19;
parameter ITIndBranch = 5'd20;
parameter ITIndCall = 5'd21;
parameter ITNop = 5'd22;
parameter ITRelBranch = 5'd23;
parameter ITRelCall = 5'd24;
parameter ITUnimp = 5'd31;


(* ram_style="block" *)
reg [127:0] imem [0:12287];
initial begin
`include "d:/cores6/rtfItanium/v1/software/boot/boot.ve0"
end

reg [63:0] ip, rip;
reg [1:0] slot;
wire [127:0] ir = imem[rip];
wire [4:0] template = ir[127:123];
reg [40:0] ir41;
wire [7:0] Rt = ir41[12:6];
reg [4:0] state;
reg [127:0] ir;
reg [7:0] cnt;
reg r1IsFp,r2IsFp,r3IsFp;

function IsMUnit;
input [4:0] tmp;
input [1:0] slt;
case(tmp)
5'h0A,5'h0B:
	IsMUnit = slt==2'd0 || slt==2'd1;
5'h0C,5'h0D:
	IsMUnit = slt==2'd0;
5'h0E,5'h0F:
	IsMUnit = slt==2'd0 || slt==2'd1;
5'h10,5'h11,5'h12,5'h13:
	IsMUnit = slt==2'd0;
5'h18,5'h19:
	IsMUnit = slt==2'd0 || slt==2'd1;
5'h1C,5'h1D:
	IsMUnit = slt==2'd0;
default:
	IsMUnit = FALSE;
endcase
endfunction

function IsFUnit;
input [4:0] tmp;
input [1:0] slt;
case(tmp)
5'h0C,5'h0D:
	IsFUnit = slt==2'd1;
5'h0E,5'h0F:
	IsFUnit = slt==2'd2;
5'h1C,5'h1D:
	IsFUnit = slt==2'd1;
default:	IsFUnit = FALSE;
endcase
endfunction

function IsIUnit;
input [4:0] tmp;
input [1:0] slt;
case(tmp)
5'h0A,5'h0B,5'h0C,5'h0D:
	IsIUnit = slt==2'd2;
5'h10,5'h11:
	IsIUnit = slt==2'd1;
default:	IsIUnit = FALSE;
endcase
endfunction

function IsBUnit;
input [4:0] tmp;
input [1:0] slt;
case(tmp)
5'h10,5'h11:
	IsBUnit = slt==2'd2;
5'h12,5'h13:
	IsBUnit = slt==2'd1 || slt==2'd2;
5'h16,5'h17:
	IsBUnit = TRUE;
5'h18,5'h19:
	IsBUnit = slt==2'd2;
5'h1C,5'h1D:
	IsBUnit = slt==2'd2;
default:	IsBUnit = FALSE;
endcase
endfunction

function IsFpLoad;
input [40:0] ins;
if (ins[40:37]==4'h6) begin
	case({ins[36],ins[27]})
	2'b00:
		case(ins[35:30])
		6'h00,6'h01,6'h02,6'h03,
		6'h04,6'h05,6'h06,6'h07,
		6'h08,6'h09,6'h0A,6'h0B,
		6'h0C,6'h0D,6'h0E,6'h0F:
			IsFpLoad = TRUE;
		6'h1B:
			IsFpLoad = TRUE;
		6'h20,6'h21,6'h22,6'h23,
		6'h24,6'h25,6'h26,6'h27:
			IsFpLoad = TRUE;
		default:	IsFpLoad = FALSE;
		endcase
	2'b01:
		case(ins[35:30])
		6'h01,6'h02,6'h03,
		6'h05,6'h06,6'h07,
		6'h09,6'h0A,6'h0B,
		6'h0D,6'h0E,6'h0F:
			IsFpLoad = TRUE;
		6'h1C,6'h1D,6'h1E,6'h1F:
			IsFpLoad = TRUE;
		6'h21,6'h22,6'h23,
		6'h25,6'h26,6'h27:
			IsFpLoad = TRUE;
		default:	IsFpLoad = FALSE;
		endcase
	2'b10:
		case(ins[35:30])
		6'h00,6'h01,6'h02,6'h03,
		6'h04,6'h05,6'h06,6'h07,
		6'h08,6'h09,6'h0A,6'h0B,
		6'h0C,6'h0D,6'h0E,6'h0F:
			IsFpLoad = TRUE;
		6'h1B:
			IsFpLoad = TRUE;
		6'h20,6'h21,6'h22,6'h23,
		6'h24,6'h25,6'h26,6'h27:
			IsFpLoad = TRUE;
		6'h2C,6'h2D,6'h2E,6'h2F:
			IsFpLoad = TRUE;
		default:	IsFpLoad = FALSE;
		endcase
	2'b11:
		case(ins[35:30])
		6'h01,6'h02,6'h03,
		6'h05,6'h06,6'h07,
		6'h09,6'h0A,6'h0B,
		6'h0D,6'h0E,6'h0F:
			IsFpLoad = TRUE;
		6'h21,6'h22,6'h23,
		6'h25,6'h26,6'h27:
			IsFpLoad = TRUE;
		default:	IsFpLoad = FALSE;
		endcase
	end
end
endfunction

function [6:0] InstType;
input [4:0] tmp;
input [40:0] ins;
if (IsMUnit(tmp)) begin
	case(ins[40:37])
	4'h0:	InstType = ITMemmgnt;
	4'h1: InstType = ITMemmgnt;
	4'h4:	InstType = ITIntLdReg;
	4'h5:	InstType = ITIntLdStImm;
	4'h6:	InstType = ITFpLdStReg;
	4'h7:	InstType = ITFPLdStImm;
	4'h8:	InstType = ITALU;
	4'h9: InstType = ITAdd;
	4'hC:	InstType = ITCmp;
	4'hD:	InstType = ITCmp;
	4'hE:	InstType = ITCmp;
	default:	InstType = ITUnimp;
	endcase
end
else if (IsIUnit(tmp)) begin
	case(ins[40:37])
	4'h0:	InstType = ITMisc;
	4'h4:	InstType = ITDeposit;
	4'h5:	InstType = ITShift;
	4'h6:	InstType = ITMovl;
	4'h7:	InstType = ITMpy;
	4'h8:	InstType = ITALU;
	4'h9: InstType = ITAdd;
	4'hC:	InstType = ITCmp;
	4'hD:	InstType = ITCmp;
	4'hE:	InstType = ITCmp;
	default:	InstType = ITUnimp;
	endcase
end
else if (IsFUnit(tmp)) begin
	case(ins[40:37])
	4'h0:	InstType = ITFPMisc;
	4'h1:	InstType = ITFPMisc;
	4'h4:	InstType = ITFPCmp;
	4'h5:	InstType = ITFPClass;
	4'h8:	InstType = ITFPfma;
	4'h9:	InstType = ITFPfma;
	4'hA:	InstType = ITFPfms;
	4'hB:	InstType = ITFPfms;
	4'hC:	InstType = ITFPfnma;
	4'hD:	InstType = ITFPfnma;
	4'hE:	InstType = ITFPSelect;
	default:	InstType = ITUnimp;
	endcase
end
else if (IsBUnit(tmp)) begin
	case(ins[40:37])
	4'h0:	InstType = ITIndBranch;
	4'h1:	InstType = ITIndCall;
	4'h2:	InstType = ITNop;
	4'h4:	InstType = ITRelBranch;
	4'h5:	InstType = ITRelCall;
	default:	InstType = ITUnimp;
	endcase
end
endfunction

always @(posedge clk_i)
if (rst_i) begin
	cnt <= 8'd0;
	ircnt <= 2'd0;
	ip <= RST_ADDR;
end
else begin
case (state)
RESET:
	begin
		rip <= ip[63:4];
		cnt <= cnt + 2'd1;
		if (cnt[2])
			state <= IFETCH;
	end
IFETCH:
	begin
		selFpReg <= 1'b0;
		fpLdSt <= 1'b0;
		slot <= slot + 2'd1;
		case(slot)
		2'd0:	begin ir41 <= ir[40:0]; state <= DCRF; end
		2'd1:	begin ir41 <= ir[81:41]; state <= DCRF; end
		2'd2:	begin ir41 <= ir[122:82]; state <= DCRF; end
		2'd3:
			begin
				rip <= ip[63:4] + 2'd1;
				ip <= ip + 8'd16;
			end
		endcase
	end
DCRF:
	begin
		if ((template==5'h0C || template==5'h0D) && slot==2'd1)
			selFp <= 1'b1;
		else if ((template==5'h0E || template==5'h0F) && slot==2'd2)
			selFp <= 1'b1;
		else if ((template==5'h1C || template==5'h1D) && slot==2'd1)
			selFp <= 1'b1;
		if ((template==))
	end
endcase
end

endmodule

module Regfile(clk, wr, wa, i, ra0, ra1, o0, o1);
input clk;
input wr;
input [7:0] wa;
input [79:0] i;
input [7:0] ra0;
input [7:0] ra1;
output [79:0] o0;
output [79:0] o1;

reg [7:0] rra0, rra1;
reg [79:0] mem [0:255];

always @(posedge clk)
	rra0 <= ra0;
always @(posedge clk)
	rra1 <= ra1;
always @(posedge clk)
	if (wr) mem[wa] <= i;

assign o0 = mem[rra0];
assign o1 = mem[rra1];

endmodule
