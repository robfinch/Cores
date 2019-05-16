// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_iexpander.v
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
`include ".\FT64_defines.vh"

module FT64_iexpander(cinstr,expand);
input [15:0] cinstr;
output reg [47:0] expand;

// Maps a subset of registers for compressed instructions.
function [4:0] fnRp;
input [2:0] rg;
case(rg)
3'd0:	fnRp = 5'd1;		// return value 0
3'd1:	fnRp = 5'd3;		// temp
3'd2:	fnRp = 5'd4;		// temp
3'd3:	fnRp = 5'd11;		// regvar
3'd4:	fnRp = 5'd12;		// regvar
3'd5:	fnRp = 5'd18;		// arg1
3'd6:	fnRp = 5'd19;		// arg2
3'd7:	fnRp = 5'd20;		// arg3
endcase
endfunction

always @*
casez({cinstr[15:12],cinstr[6]})
5'b00000:	// NOP / ADDI
	case(cinstr[4:0])
	5'd31:	begin
			expand[47:32] = 16'h0000;
 			expand[31:24] = {8{cinstr[11]}};
 			expand[23] = 1'b0;
			expand[22:18] = {cinstr[11],cinstr[5],3'b0};
			expand[17:13] = cinstr[4:0];
			expand[12:8] = cinstr[4:0];
			expand[7:6] = 2'b10;
			expand[5:0] = `ADDI;
			end
	default:
			begin
			expand[47:32] = 16'h0000;
			expand[31:24] = {8{cinstr[11]}};
 			expand[23] = 1'b0;
			expand[22:18] = {cinstr[11:8],cinstr[5]};
			expand[17:13] = cinstr[4:0];
			expand[12:8] = cinstr[4:0];
			expand[7:6] = 2'b10;
			expand[5:0] = `ADDI;
			end
	endcase
5'b00010:	// SYS
			if (cinstr[4:0]==5'd0) begin
				expand[47:32] = 16'h0000;
				expand[5:0] = `BRK;
				expand[7:6] = 2'b10;
				expand[15:8] = {3'd1,cinstr[11:8],cinstr[5]};
				expand[16] = 1'b0;
				expand[20:17] = 4'd0;
				expand[23:21] = 3'd1;
				expand[31:24] = 8'd0;
			end
			// LDI
			else begin
				expand[47:32] = 16'h0000;
				expand[31:24] = {8{cinstr[11]}};
				expand[23] = 1'b0;
				expand[22:18] = {cinstr[11:8],cinstr[5]};
				expand[17:13] = cinstr[4:0];
				expand[12:8] = 5'd0;
				expand[7:6] = 2'b10;
				expand[5:0] = `ADDI;	// ADDI to sign extend
			end
5'b00100:	// RET / ANDI
			if (cinstr[4:0]==5'd0) begin
				expand[47:32] = 16'h0000;
				expand[31:23] = {4'd0,cinstr[11:8],cinstr[5]};
				expand[22:18] = 5'd29;
				expand[17:13] = 5'd31;
				expand[12:8] = 5'd31;
				expand[7:6] = 2'b10;
				expand[5:0] = `RET;
			end
			else begin
				expand[47:32] = 16'h0000;
				expand[31:24] = {8{cinstr[11]}};
				expand[23] = 1'b0;
				expand[22:18] = {cinstr[11:8],cinstr[5]};
				expand[17:13] = cinstr[4:0];
				expand[12:8] = cinstr[4:0];
				expand[7:6] = 2'b10;
				expand[5:0] = `ANDI;
			end
5'b00110:	// SHLI
			begin
			expand[47:32] = 16'h0000;
			expand[31:26] = 6'h0F;	// immediate mode 0-31
			expand[25:23] = 3'd0;	// SHL
			expand[22:18] = {cinstr[11:8],cinstr[5]};	// amount
			expand[17:13] = cinstr[4:0];
			expand[12:8] = cinstr[4:0];
			expand[7:6] = 2'b10;
			expand[5:0] = 8'h02;		// R2 instruction
			end
5'b01000:
			case(cinstr[5:4])
			2'd0:		// SHRI
				begin
				expand[47:32] = 16'h0000;
				expand[31:26] = 6'h0F;		// shift immediate 0-31
				expand[25:23] = 3'd1;		// SHR
				expand[22:18] = {cinstr[11:8],cinstr[3]};	// amount
				expand[17:13] = fnRp(cinstr[2:0]);
				expand[12:8] = fnRp(cinstr[2:0]);
				expand[7:6] = 2'b10;
				expand[5:0] = 8'h02;		// R2 instruction
				end
			2'd1:		// ASRI
				begin
				expand[47:32] = 16'h0000;
				expand[31:26] = 6'h0F;		// shift immediate 0-31
				expand[25:23] = 3'd3;		// ASR
				expand[22:18] = {cinstr[11:8],cinstr[3]};	// amount
				expand[17:13] = fnRp(cinstr[2:0]);
				expand[12:8] = fnRp(cinstr[2:0]);
				expand[7:6] = 2'b10;
				expand[5:0] = 8'h02;		// R2 instruction
				end
			2'd2:		// ORI
				begin
				expand[47:32] = 16'h0000;
				expand[31:24] = {8{cinstr[11]}};
				expand[23] = 1'b0;
				expand[22:18] = {cinstr[11:8],cinstr[3]};
				expand[17:13] = fnRp(cinstr[2:0]);
				expand[12:8] = fnRp(cinstr[2:0]);
				expand[7:6] = 2'b10;
				expand[5:0] = `ORI;
				end
			2'd3:
				case(cinstr[11:10])
				2'd0:	begin
						expand[47:32] = 16'h0000;
						expand[31:26] = `SUB;
						expand[25:23] = 3'b011;	// word size
						expand[22:18] = fnRp({cinstr[9:8],cinstr[3]});
						expand[17:13] = fnRp(cinstr[2:0]);
						expand[12:8] = fnRp(cinstr[2:0]);
						expand[7:6] = 2'b10;
						expand[5:0] = 6'h02;		// R2 instruction
						end
				2'd1:	begin
						expand[47:32] = 16'h0000;
						expand[31:26] = `AND;
						expand[25:23] = 3'b011;	// word size
						expand[22:18] = fnRp({cinstr[9:8],cinstr[3]});
						expand[17:13] = fnRp(cinstr[2:0]);
						expand[12:8] = fnRp(cinstr[2:0]);
						expand[7:6] = 2'b10;
						expand[5:0] = 6'h02;		// R2 instruction
						end
				2'd2:	begin
						expand[47:32] = 16'h0000;
						expand[31:26] = `OR;
						expand[25:23] = 3'b011;	// word size
						expand[22:18] = fnRp({cinstr[9:8],cinstr[3]});
						expand[17:13] = fnRp(cinstr[2:0]);
						expand[12:8] = fnRp(cinstr[2:0]);
						expand[7:6] = 2'b10;
						expand[5:0] = 6'h02;		// R2 instruction
						end
				2'd3:	begin
						expand[47:32] = 16'h0000;
						expand[31:26] = `XOR;
						expand[25:23] = 3'b011;	// word size
						expand[22:18] = fnRp({cinstr[9:8],cinstr[3]});
						expand[17:13] = fnRp(cinstr[2:0]);
						expand[12:8] = fnRp(cinstr[2:0]);
						expand[7:6] = 2'b10;
						expand[5:0] = 6'h02;		// R2 instruction
						end
				endcase
			endcase
5'b01110:
		begin
			expand[47:32] = 16'h0000;
			expand[31:23] = {{1{cinstr[11]}},{cinstr[11:8],cinstr[5:2]}};
			expand[22:18] = 5'd0;		// Rb = 0
			expand[17:16] = cinstr[1:0];
			expand[15:13] = 3'd0;		// BEQ
			expand[12:8] = 5'd0;		// Ra = r0
			expand[7:6] = 2'b10;
			expand[5:0] = `Bcc;		// 0x38
		end
5'b10??0:
		begin
			expand[47:32] = 16'h0000;
			expand[31:23] = {{4{cinstr[13]}},cinstr[13:9]};
			expand[22:18] = 5'd0;			// r0
			expand[17:16] = {cinstr[8],cinstr[5]};
			expand[15:13] = 3'd0;			// BEQ
			expand[12:8] = cinstr[4:0];	// Ra
			expand[7:6] = 2'b10;
			expand[5:0] = `Bcc;
		end
5'b11??0:
		begin
			expand[47:32] = 16'h0000;
			expand[31:23] = {{4{cinstr[13]}},cinstr[13:9]};
			expand[22:18] = 5'd0;			// r0
			expand[17:16] = {cinstr[8],cinstr[5]};
			expand[15:13] = 3'd1;			// BNE
			expand[12:8] = cinstr[4:0];	// Ra
			expand[7:6] = 2'b10;
			expand[5:0] = `Bcc;
		end
5'b00001:
		begin
			expand[47:32] = 16'h0000;
			expand[31:26] = `MOV;			// `MOV is 6'b01001?
			expand[26] = 1'b0;
			expand[25:23] = 3'd7;			// move current to current
			expand[22:18] = 5'd0;			// register set (ignored)
			expand[17:13] = {cinstr[11:8],cinstr[5]};
			expand[12:8] = cinstr[4:0];
			expand[7:6] = 2'b10;
			expand[5:0] = 6'h02;
		end
5'b00011:	// ADD
		begin
			expand[47:32] = 16'h0000;
			expand[31:26] = `ADD;
			expand[27:23] = 3'b011;	// word size
			expand[22:18] = {cinstr[11:8],cinstr[5]};
			expand[17:13] = cinstr[4:0];
			expand[12:8] = cinstr[4:0];
			expand[7:6] = 2'b10;
			expand[5:0] = 6'h02;		// R2 instruction
		end
5'b00101:	// JALR
		begin
			expand[47:32] = 16'h0000;
			expand[31:18] = 14'd0;
			expand[17:13] = {cinstr[11:8],cinstr[5]};
			expand[12:8] = cinstr[4:0];
			expand[7:6] = 2'b10;
			expand[5:0] = `JAL;
		end
5'b00111:
		if ({cinstr[11:8]==4'h1}) begin
			expand[47:32] = 16'h0000;
			expand[31:26] = 6'h36;		// SEG instructions
			expand[22:18] = {2'b0,cinstr[2:0]};
			expand[17:13] = 5'd0;			// no target
			expand[12:8] = 5'd0;
			expand[7:6] = 2'b10;
			expand[5:0] = 6'h02;			
		end
		else if ({cinstr[11:8],cinstr[5]}==5'b0) begin	// PUSH
			expand[47:32] = 16'h0000;
			expand[31:28] = 4'hC;
			expand[27:23] = 5'd0;
			expand[22:18] = cinstr[4:0];
			expand[17:13] = 5'd31;
			expand[12:8] = 5'd31;
			expand[7:6] = 2'b10;
			expand[5:0] = `MEMNDX;
		end
		else begin
			expand[47:8] = 40'd0;
			expand[7:6] = 2'b10;
			expand[5:0] = `NOP;
		end
5'b01001:	// LH Rt,d[SP]
		begin
			expand[47:32] = 16'h0000;
			expand[31:24] = {{6{cinstr[11]}},cinstr[11:10]};
			expand[23] = 1'b0;
			expand[22:18] = {cinstr[9:8],cinstr[5],2'd0};
			expand[17:13] = {cinstr[4:0]};
			expand[12:8] = 5'd31;
			expand[7:6] = 2'b10;
			expand[5:0] = `LH;
		end
5'b01011:	// LW Rt,d[SP]
		begin
			expand[47:32] = 16'h0000;
			expand[31:24] = {{5{cinstr[11]}},cinstr[11:9]};
			expand[22:18] = {cinstr[8],cinstr[5],3'd0};
			expand[23] = 1'b0;
			expand[17:13] = cinstr[4:0];
			expand[12:8] = 5'd31;
			expand[7:6] = 2'b10;
			expand[5:0] = `LW;
		end
5'b01101:	// LH Rt,d[fP]
		begin
			expand[47:32] = 16'h0000;
			expand[31:24] = {{6{cinstr[11]}},cinstr[11:10]};
			expand[22:18] = {cinstr[9:8],cinstr[5],2'b0};
			expand[23] = 1'b0;
			expand[17:13] = cinstr[4:0];
			expand[12:8] = 5'd30;
			expand[7:6] = 2'b10;
			expand[5:0] = `LH;
		end
5'b01111:	// LW Rt,d[FP]
		begin
			expand[47:32] = 16'h0000;
			expand[31:18] = {{5{cinstr[11]}},cinstr[11:9]};
			expand[22:18] = {cinstr[8],cinstr[5],3'b0};
			expand[23] = 1'b0;
			expand[17:13] = cinstr[4:0];
			expand[12:8] = 5'd30;
			expand[7:6] = 2'b10;
			expand[5:0] = `LW;
		end
5'b10001:	// SH Rt,d[SP]
		begin
			expand[47:32] = 16'h0000;
			expand[31:24] = {{6{cinstr[11]}},cinstr[11:10]};
			expand[23] = 1'b0;
			expand[22:18] = cinstr[4:0];
			expand[17:13] = {cinstr[9:8],cinstr[5],2'd0};
			expand[12:8] = 5'd31;
			expand[7:6] = 2'b10;
			expand[5:0] = `SH;
		end
5'b10011:	// SW Rt,d[SP]
		begin
			expand[47:32] = 16'h0000;
			expand[31:24] = {{5{cinstr[11]}},cinstr[11:9]};
			expand[22:18] = cinstr[4:0];
			expand[23] = 1'b1;
			expand[17:13] = {cinstr[8],cinstr[5],3'd0};
			expand[12:8] = 5'd31;
			expand[7:6] = 2'b10;
			expand[5:0] = `SH;
		end
5'b10101:	// SH Rt,d[fP]
		begin
			expand[47:32] = 16'h0000;
			expand[31:24] = {{6{cinstr[11]}},cinstr[11:10]};
			expand[23] = 1'b0;
			expand[22:18] = cinstr[4:0];
			expand[17:13] = {cinstr[9:8],cinstr[5],2'd0};
			expand[12:8] = 5'd30;
			expand[7:6] = 2'b10;
			expand[5:0] = `SH;
		end
5'b10111:	// SW Rt,d[FP]
		begin
			expand[47:32] = 16'h0000;
			expand[31:24] = {{5{cinstr[11]}},cinstr[11:9]};
			expand[23] = 1'b1;
			expand[22:18] = cinstr[4:0];
			expand[17:13] = {cinstr[8],cinstr[5],3'd0};
			expand[12:8] = 5'd30;
			expand[7:6] = 2'b10;
			expand[5:0] = `SH;
		end
5'b11001:
		begin	// LH
			expand[47:32] = 16'h0000;
			expand[31:24] = {{7{cinstr[11]}},cinstr[11]};
			expand[23] = 1'b0;
			expand[22:18] = {cinstr[10],cinstr[4:3],2'd0};
			expand[17:13] = fnRp({cinstr[9:8],cinstr[5]});
			expand[12:8] = fnRp(cinstr[2:0]);
			expand[7:6] = 2'b10;
			expand[5:0] = `LH;
		end
5'b11011:	// LW
		begin
			expand[47:32] = 16'h0000;
			expand[31:18] = {{6{cinstr[11]}},cinstr[11:10]};
			expand[23] = 1'b0;
			expand[22:18] = {cinstr[4:3],3'd0};
			expand[17:13] = fnRp({cinstr[9:8],cinstr[5]});
			expand[12:8] = fnRp(cinstr[2:0]);
			expand[7:6] = 2'b10;
			expand[5:0] = `LW;
		end
5'b11101:	// SH
		begin
			expand[47:32] = 16'h0000;
			expand[31:24] = {{7{cinstr[11]}},cinstr[11]};
			expand[23] = 1'b0;
			expand[22:18] = fnRp({cinstr[9:8],cinstr[5]});
			expand[17:13] = {cinstr[10],cinstr[4:3],2'd0};
			expand[12:8] = fnRp(cinstr[2:0]);
			expand[7:6] = 2'b10;
			expand[5:0] = `SH;
		end
5'b11111:	// SW
		begin
			expand[47:32] = 16'h0000;
			expand[31:24] = {{6{cinstr[11]}},cinstr[11:10]};
			expand[23] = 1'b1;
			expand[22:18] = fnRp({cinstr[9:8],cinstr[5]});
			expand[17:13] = {cinstr[4:3],3'd0};
			expand[12:8] = fnRp(cinstr[2:0]);
			expand[7:6] = 2'b10;
			expand[5:0] = `SH;
		end
default:
		begin
			expand[47:8] = 40'd0;
			expand[7:6] = 2'b10;
			expand[5:0] = `NOP;
		end
endcase

endmodule
