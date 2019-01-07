// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64v8d_decode.v
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
DECODE:
	begin
		pc <= pc + insn_length;
		goto (EXECUTE);
		cca <= cc >> {ir[10:8],3'd0};
		a <= rfoa;
		b <= rfob;
		c <= rfoc;
		case(ir[7:0])
		`I_ADD6,`I_CMP6,`I_AND6,`I_OR6,`I_EOR6:	imm <= {{58{ir[23]}},ir[23:18]};
		`I_ADD14,`I_CMP14,`I_AND14,`I_OR14,`I_EOR14:	imm <= {{50{ir[31]}},ir[31:18]};
		`I_ADD30,`I_CMP30,`I_AND30,`I_OR30,`I_EOR30:	imm <= {{34{ir[47]}},ir[47:18]};
		`I_STSP3:		imm <= {{58{ir[15]}},ir[15:13],3'd0};
		`I_STSP11:	imm <= {{50{ir[23]}},ir[23:13],3'd0};
		endcase
		case(ir[7:0])
		`I_UBYTE,`I_UHALF,`I_UWORD:
			su <= 1'b0;
		default:	;
		endcase
		case(ir[7:0])
		`I_BYTE,`I_UBYTE:
			begin
				memsize = byt_;
				ir <= ir[63:8];
				Rt <= ir[20:16];
				Ra <= ir[25:21];
				Rb <= ir[30:26];
				Rc <= ir[35:31];
				goto (DECODE);
			end
		`I_HALF,`I_UHALF:
			begin
				memsize = half;
				ir <= ir[63:8];
				Rt <= ir[20:16];
				Ra <= ir[25:21];
				Rb <= ir[30:26];
				Rc <= ir[35:31];
				goto (DECODE);
			end
		`I_WORD,`I_UWORD:
			begin
				memsize = word;
				ir <= ir[63:8];
				Rt <= ir[20:16];
				Ra <= ir[25:21];
				Rb <= ir[30:26];
				Rc <= ir[35:31];
				goto (DECODE);
			end
		`I_BRK:	bat_ndx <= 12'hFFF;
		`I_CLI:	begin status[2:0] <= 3'd0; goto(IFETCH); end
		`I_WAI:	goto(IFETCH);
		`I_NOP:	goto(IFETCH);
		`I_BRA:
			begin
				pc[12:0] <= ir[24:12];
				pc[39:13] <= pc[39:13] + {{16{ir[11]}},ir[11:8],ir[31:25]};
				goto(IFETCH);
			end
		`I_JMP:	begin pc[23:0] <= ir[31:8]; goto (IFETCH); end
		`I_JSL:
			begin
				b <= prog_base;
				call (PUSH, EXECUTE);
			end
		`I_RTS:
			begin
				cyc_o <= `HIGH;
				stb_o <= `HIGH;
				sel_o <= 8'hFF;
				adr_o <= {data_base,13'd0} + sp[ol];
			end
		`I_STSP3,`I_STSP11:
			begin
				Ra <= 5'd31;
				Rb <= Rt;
				Rc <= 5'd0;
			end
		endcase
	end
	