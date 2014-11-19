// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// A64 - Assembler
//  - 64 bit CPU
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
#ifndef TOKEN_H
#define TOKEN_H

enum {
     tk_eof = -1,
     tk_none = 0,
     tk_comma = ',',
     tk_hash = '#',
     tk_plus = '+',
     tk_eol = '\n',
     tk_add = 128,
     tk_addi,
     tk_addu,
     tk_addui,
     tk_align,
     tk_and,
     tk_andi,
     tk_asr,
     tk_asri,
     tk_beq,
     tk_bge,
     tk_bgeu,
     // 140
     tk_bgt,
     tk_bgtu,
     tk_bits,
     tk_ble,
     tk_bleu,
     tk_blt,
     tk_bltu,
     tk_bmi,
     tk_bne,
     tk_bpl,
     tk_bra,
     // 150
     tk_brk,
     tk_brnz,
     tk_brz,
     tk_bsr,
     tk_bss,
     tk_bvc,
     tk_bvs,
     tk_cli,
     tk_cmp,
     tk_code,
     // 160
     tk_com,
     tk_cs,
     tk_data,
     tk_db,
     tk_dbnz,
     tk_dc,
     tk_dh,
     tk_div,
     tk_divu,
     tk_ds,
     // 170
     tk_dw,
     tk_end,
     tk_endpublic,
     tk_eor,
     tk_eori,
     tk_eq,
     tk_equ,
     tk_extern,
     tk_fill,
     tk_ge,
     // 180
     tk_gran,
     tk_gt,
     tk_id,
     tk_icon,
     tk_jgr,
     tk_jmp,
     tk_jsp,
     tk_jsr,
     tk_land,
     tk_lb,
     tk_lbu,
     tk_lc,
     tk_lcu,
     tk_ldi,
     tk_lea,
     tk_lh,
     tk_lhu,
     tk_le,
     tk_lmr,
     tk_lor,
     tk_lshift,
     tk_lt,
     tk_lw,
     tk_mfspr,
     tk_mod,
     tk_modu,
     tk_mov,
     tk_mtspr,
     tk_mul,
     tk_muli,
     tk_mulu,
     tk_mului,
     tk_ne,
     tk_neg,
     tk_nop,
     tk_not,
     tk_or,
     tk_ori,
     tk_org,
     tk_php,
     tk_plp,
     tk_pop,
     tk_public,
     tk_push,
     tk_rconst,
     tk_rodata,
     tk_rol,
     tk_roli,
     tk_ror,
     tk_rori,
     tk_rshift,
     tk_rti,
     tk_rts,
     tk_sb,
     tk_sc,
     tk_sei,
     tk_seq,
     tk_seqi,
     tk_sgt,
     tk_sgti,
     tk_sgtu,
     tk_sgtui,
     tk_sge,
     tk_sgei,
     tk_sgeu,
     tk_sgeui,
     tk_sh,
     tk_shl,
     tk_shli,
     tk_shru,
     tk_shrui,
     tk_slt,
     tk_slti,
     tk_sltu,
     tk_sltui,
     tk_sle,
     tk_slei,
     tk_sleu,
     tk_sleui,
     tk_smr,
     tk_sne,
     tk_snei,
     tk_ss,
     tk_sub,
     tk_subi,
     tk_subu,
     tk_subui,
     tk_sw,
     tk_swap,
     tk_sxb,
     tk_sxc,
     tk_sxh,
     tk_tls,
     tk_to,
     tk_xor,
     tk_xori
};

extern int token;
extern int isIdentChar(char ch);
extern void ScanToEOL();
extern int NextToken();
extern void SkipSpaces();
extern void prevToken();
extern int need(int);
extern int expect(int);
extern int getRegister();
extern int getSprRegister();

#endif
