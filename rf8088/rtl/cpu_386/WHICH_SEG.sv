// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// Determine segment register for memory access.
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ============================================================================

always_comb
	case(ir)
	`SCASB: seg_reg <= es_base;
	`SCASW: seg_reg <= es_base;
	default:
		case(prefix1)
		`CS: seg_reg <= cs_base;
		`DS: seg_reg <= ds_base;
		`ES: seg_reg <= es_base;
		`SS: seg_reg <= ss_base;
		`FS: seg_reg <= fs_base;
		`GS: seg_reg <= gs_base;
		default:
			case(prefix2)
			`CS: seg_reg <= cs_base;
			`DS: seg_reg <= ds_base;
			`ES: seg_reg <= es_base;
			`SS: seg_reg <= ss_base;
			`FS: seg_reg <= fs_base;
			`GS: seg_reg <= gs_base;
			default:
				casez(ir)
				`CMPSB: seg_reg <= ds_base;
				`CMPSW: seg_reg <= ds_base;
				`LODSB:	seg_reg <= ds_base;
				`LODSW:	seg_reg <= ds_base;
				`MOVSB: seg_reg <= ds_base;
				`MOVSW: seg_reg <= ds_base;
				`STOSB: seg_reg <= ds_base;
				`STOSW: seg_reg <= ds_base;
				`MOV_AL2M: seg_reg <= ds_base;
				`MOV_AX2M: seg_reg <= ds_base;
				default:
					case(modrm)
					5'b00_000:	seg_reg <= ds_base;
					5'b00_001:	seg_reg <= ds_base;
					5'b00_010:	seg_reg <= ss_base;
					5'b00_011:	seg_reg <= ss_base;
					5'b00_100:	seg_reg <= ds_base;
					5'b00_101:	seg_reg <= ds_base;
					5'b00_110:	seg_reg <= ds_base;
					5'b00_111:	seg_reg <= ds_base;
				
					5'b01_000:	seg_reg <= ds_base;
					5'b01_001:	seg_reg <= ds_base;
					5'b01_010:	seg_reg <= ss_base;
					5'b01_011:	seg_reg <= ss_base;
					5'b01_100:	seg_reg <= ds_base;
					5'b01_101:	seg_reg <= ds_base;
					5'b01_110:	seg_reg <= ss_base;
					5'b01_111:	seg_reg <= ds_base;
				
					5'b10_000:	seg_reg <= ds_base;
					5'b10_001:	seg_reg <= ds_base;
					5'b10_010:	seg_reg <= ss_base;
					5'b10_011:	seg_reg <= ss_base;
					5'b10_100:	seg_reg <= ds_base;
					5'b10_101:	seg_reg <= ds_base;
					5'b10_110:	seg_reg <= ss_base;
					5'b10_111:	seg_reg <= ds_base;
				
					default:	seg_reg <= ds_base;
					endcase
				endcase
			endcase
		endcase
	endcase
	
	always_comb
		case(state)
		rf80386_pkg::IFETCH,rf80386_pkg::XI_FETCH,rf80386_pkg::DECODE,
		rf80386_pkg::FETCH_IMM8,rf80386_pkg::FETCH_IMM16,rf80386_pkg::FETCH_DISP8:
			S43 <= 2'b10;	// code segment
		rf80386_pkg::PUSH,
		rf80386_pkg::POP,rf80386_pkg::POP1,
		rf80386_pkg::IRET1,rf80386_pkg::IRET2,
		rf80386_pkg::IRET3,
		rf80386_pkg::RETFPOP,rf80386_pkg::RETFPOP1,rf80386_pkg::RETFPOP2,
		rf80386_pkg::RETPOP,RETPOP_NACK,rf80386_pkg::RETPOP1:
			S43 <= 2'b01;	// stack
		default:
			case(prefix1)
			`CS: S43 <= 2'b10;
			`DS: S43 <= 2'b11;
			`ES: S43 <= 2'b00;
			`SS: S43 <= 2'b01;
			default:
				case(prefix2)
				`CS: S43 <= 2'b10;
				`DS: S43 <= 2'b11;
				`ES: S43 <= 2'b00;
				`SS: S43 <= 2'b01;
				default:
					casez(ir)
					`CMPSB: S43 <= 2'b11;
					`CMPSW: S43 <= 2'b11;
					`LODSB:	S43 <= 2'b11;
					`LODSW:	S43 <= 2'b11;
					`MOVSB: S43 <= 2'b11;
					`MOVSW: S43 <= 2'b11;
					`STOSB: S43 <= 2'b11;
					`STOSW: S43 <= 2'b11;
					`MOV_AL2M: S43 <= 2'b11;
					`MOV_AX2M: S43 <= 2'b11;
					default:
						case(modrm)
						5'b00_000:	S43 <= 2'b11;
						5'b00_001:	S43 <= 2'b11;
						5'b00_010:	S43 <= 2'b01;
						5'b00_011:	S43 <= 2'b01;
						5'b00_100:	S43 <= 2'b11;
						5'b00_101:	S43 <= 2'b11;
						5'b00_110:	S43 <= 2'b11;
						5'b00_111:	S43 <= 2'b11;
					
						5'b01_000:	S43 <= 2'b11;
						5'b01_001:	S43 <= 2'b11;
						5'b01_010:	S43 <= 2'b01;
						5'b01_011:	S43 <= 2'b01;
						5'b01_100:	S43 <= 2'b11;
						5'b01_101:	S43 <= 2'b11;
						5'b01_110:	S43 <= 2'b01;
						5'b01_111:	S43 <= 2'b11;
					
						5'b10_000:	S43 <= 2'b11;
						5'b10_001:	S43 <= 2'b11;
						5'b10_010:	S43 <= 2'b01;
						5'b10_011:	S43 <= 2'b01;
						5'b10_100:	S43 <= 2'b11;
						5'b10_101:	S43 <= 2'b11;
						5'b10_110:	S43 <= 2'b01;
						5'b10_111:	S43 <= 2'b11;
					
						default:	S43 <= 2'b11;
						endcase // modrm
					endcase // ir
				endcase // prefix2
			endcase // prefix1
		endcase // state

