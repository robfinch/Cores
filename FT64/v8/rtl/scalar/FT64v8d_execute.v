// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64v8d_execute.v
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
//
// ============================================================================
//
EXECUTE:
	begin
		goto(IFETCH);
		case(ir[7:0])
		`I_BRK:	goto(BRK1);
		`I_MOV:
			begin
				rfwr <= `TRUE;
				res <= a;
			end
		`I_SEI:
			begin
				rfwr <= `TRUE;
				res <= status[2:0];
				status[2:0] <= a[2:0] | ir[20:18];
			end
		`I_ADD:
			begin
				rfwr <= `TRUE;
				res <= a + b;
			end
		`I_ADD6,`I_ADD14,`I_ADD30:
			begin
				rfwr <= `TRUE;
				res <= a + imm;
			end
		`I_AND:
			begin
				rfwr <= `TRUE;
				res <= a & b;
			end
		`I_AND6,`I_AND14,`I_AND30:
			begin
				rfwr <= `TRUE;
				res <= a & imm;
			end
		`I_OR:
			begin
				rfwr <= `TRUE;
				res <= a | b;
			end
		`I_OR6,`I_OR14,`I_OR30:
			begin
				rfwr <= `TRUE;
				res <= a | imm;
			end
		`I_EOR:
			begin
				rfwr <= `TRUE;
				res <= a ^ b;
			end
		`I_EOR6,`I_EOR14,`I_EOR30:
			begin
				rfwr <= `TRUE;
				res <= a ^ imm;
			end
		`I_CMP6,`I_CMP14,`I_CMP30:
			begin
				ccrfwr_all <= 1'b1;
				ccRt <= Rt[2:0];
				ccres[0] <= difi==64'd0;
				ccres[1] <= difi[63];
				ccres[4] <= difi[0];
				ccres[5] <= ^difi;
				ccres[7:6] <= 2'b00;
			end
		`I_SUB:
			begin
				rfwr <= `TRUE;
				res <= a - b;
			end
		`I_BEQ,`I_BNE,`I_BMI,`I_BPL,`I_BVC,`I_BVS:
			if (takb) begin
				pc[12:0] <= ir[24:12];
				pc[39:13] <= pc[39:13] + {{20{ir[31]}},ir[31:25]};
			end
		`I_BSR:
			begin
				b <= {4'h0,20'h0,pc[39:0]} + 40'd4;
				pc[12:0] <= ir[24:12];
				pc[39:13] <= pc[39:13] + {{16{ir[11]}},ir[11:8],ir[31:25]};
				call (PUSH, IFETCH);
			end
		`I_JML:
			if (ihit) begin
				pc <= ir[47:8];
				prog_base <= bat_o;
			end
			else
				goto(EXECUTE);
		`I_JSR:
			begin
				b <= {4'h0,20'h0,pc[39:0]} + 40'd6;
				pc[39:0] <= ir[47:8];
				call (PUSH, IFETCH);
			end
		`I_JSL:
			begin
				b <= {4'h1,20'h0,pc[39:0]} + 40'd8;
				pc <= ir[47:8];
				prog_base <= bat_o;
				call(PUSH,IFETCH);
			end
		`I_RTS:
			begin
				goto(EXECUTE);	// stay in exec state until ack
				if (ack_i) begin
					if (dat_i[63:60]==4'h0) begin
						cyc_o <= `LOW;
						sel_o <= 8'h00;
						sp[ol] <= sp[ol] + 64'd8;
						goto(IFETCH);
					end
					else
						goto (EXECUTE2);
					stb_o <= `LOW;
					pc[39:0] <= dat_i[39:0];
				end
			end
		`I_PUSH3:
			begin
				b <= rfoa;
				ir <= {5'h00,ir[22:13],ir[7:0]};
				if (ir[22:8]!=15'h0)
					call(PUSH, EXECUTE);
			end
		`I_PUSH6:
			begin
				b <= rfoa;
				ir <= {5'h00,ir[63:13],ir[7:0]};
				if (ir[37:8]!=30'h0)
					call(PUSH, EXECUTE);
			end
		`I_PHP:
			begin
				b <= cc;
				if (ol < 2'd3)
					call (PUSH, EXECUTE2);
				else
					call (PUSH, IFETCH);
			end
		`I_STSP3,`I_STSP11:
			begin
				a <= rfoa;
				b <= rfob;
				c <= rfoc;
				call (STORE, IFETCH);
			end
		endcase
	end
EXECUTE2:
	begin
		case(ir[7:0])
		`I_JSL:
			begin
				b <= {4'h1,20'h0,pc[39:0]} + 40'd14;
				pc <= pc + 40'd6;
				call(PUSH,EXECUTE3);
			end
		`I_RTS:
			if (~ack_i) begin
				stb_o <= `HIGH;
				adr_o <= adr_o + 8'd8;
				goto(EXECUTE3);
			end
		`I_PHP:
			begin
				b <= status;
				call (PUSH, IFETCH);
			end
		endcase
	end
EXECUTE3:
	begin
		case(ir[7:0])
		`I_RTS:
			if (ack_i) begin
				cyc_o <= `LOW;
				stb_o <= `LOW;
				sel_o <= `LOW;
				prog_base <= dat_i;
				sp[ol] <= sp[ol] + 64'd16;
				goto (IFETCH);
			end
		endcase
	end
