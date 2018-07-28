// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// CC64 - 'C' derived language compiler
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
#include "stdafx.h"

extern char *TraceName(SYM *);
void put_mask(int mask);
void align(int n);
void roseg();
bool renamed = false; 

/*      variable initialization         */

enum e_gt { nogen, bytegen, chargen, halfgen, wordgen, longgen };
//enum e_sg { noseg, codeseg, dataseg, bssseg, idataseg };

int	       gentype = nogen;
int	       curseg = noseg;
int        outcol = 0;

struct oplst {
        char    *s;
        int     ov;
        };

Instruction opl[] =
{   
	{"mov", op_mov,1,true},
	{"move",op_move,1,true},
	{"add",op_add,1,true},
	{"addu", op_addu,1,true},
	{"ldi",op_ldi,1,true},
	{"addi",op_addi,1,true},
	{"lw", op_lw,4,true,true},
	{"sw", op_sw,4,false,true},
	{"call", op_call,4,true,true},
	{"ret", op_ret,1,false},
	{"sub",op_sub,1,true},
	{"subu", op_subu,1,true},
	{"subi",op_subi,1,true},
	{"and",op_and,1,true},
	{"andi", op_andi,1,true},
	{"or",op_or,1,true},
	{"ori",op_ori,1,true},
	{"eor",op_eor,1,true},
	{"eori", op_eori,1,true},
	{"xor",op_xor,1,true},
	{"xori", op_xori,1,true},
	{"divi", op_divi,68,true},
	{"modi", op_modi,68,true},
	{"modui", op_modui,68,true},
	{"div", op_div,68,true}, 
	{"subui",op_subui},
	{"shru", op_shru,2,true},
	{"divsi", op_divsi,68,true},
	{"not", op_not,2,true},
	{"addui",op_addui,1,true},
	{"dw", op_dw},
	{"bfext", op_bfext,2,true},
	{"bfextu", op_bfextu,2,true},
	{"bfins", op_bfins,2,true},
	{"lh", op_lh,4,true,true},
	{"lc", op_lc,4,true,true},
	{"lb", op_lb,4,true,true},
	{"lbu", op_lbu,4,true,true},
	{"lcu", op_lcu,4,true,true},
	{"lhu", op_lhu,4,true,true},
	{"sti", op_sti},
	{"lft", op_lft},
	{"sft", op_sft},

	{"lws", op_lws}, {"sws", op_sws},
	{"lm", op_lm}, {"sm",op_sm},
	{"sb",op_sb,4,false,true},
	{"sc",op_sc,4,false,true},
	{"sh",op_sh,4,false,true},
	{"loop", op_loop},
	{"jal", op_jal,1,true},

	{"cmp",op_cmp,1,true},
	{"cmpu",op_cmpu,1,true},
	// Branches
	// Branches weighted as 3 because they might cause a pipeline flush
	{"beq", op_beq,3,false},
	{"bne", op_bne,3,false},
	{"blt", op_blt,3,false},
	{"ble", op_ble,3,false},
	{"bgt", op_bgt,3,false},
	{"bge", op_bge,3,false},
	{"bltu", op_bltu,3,false},
	{"bleu", op_bleu,3,false},
	{"bgtu", op_bgtu,3,false},
	{"bgeu", op_bgeu,3,false},
	{"bbs", op_bbs,3,false},
	{"bbc", op_bbc,3,false},
	{"bor", op_bor,3,false},
	{"beqi", op_beqi,3,false},

	{"rtd", op_rtd},
	{"lwr", op_lwr,4,true,true},
	{"swc", op_swc,4,false,true},
	{"cache",op_cache},
	{"iret", op_iret,2},
	{"mul",op_mul,18,true}, {"muli", op_muli,18,true}, {"mului", op_mului,18,true}, 
		
		{"fmul", op_fdmul}, {"fdiv", op_fddiv}, {"fadd", op_fdadd}, {"fsub", op_fdsub}, {"fcmp", op_fcmp},
		{"fmul.s", op_fsmul}, {"fdiv.s", op_fsdiv}, {"fadd.s", op_fsadd}, {"fsub.s", op_fssub},
		{"fs2d", op_fs2d}, {"fi2d", op_i2d}, {"fneg", op_fneg}, 

		{"divs",op_divs,68,true}, {"swap",op_swap,1,true}, {"mod", op_mod,68,true}, {"modu", op_modu,68,true},
		{"eq",op_eq}, {"bnei", op_bnei}, {"sei", op_sei,1},
		{"ltu", op_ltu}, {"leu",op_leu}, {"gtu",op_gtu}, {"geu", op_geu},
                {"bhi",op_bhi}, {"bhs",op_bhs}, {"blo",op_blo}, {"bun", op_bun},
                {"bls",op_bls}, {"mulu",op_mulu}, {"divu",op_divu},
                {"ne",op_ne}, {"lt",op_lt}, {"le",op_le},
		{"gt",op_gt}, {"ge",op_ge}, {"neg",op_neg}, {"nr", op_nr},
	{"not",op_not,2,true},
	{"com", op_com,2,true},
	{"ext",op_ext}, 
	{"jmp",op_jmp,1,false},
	{"lea",op_lea,1,true},

                {"link",op_link,4,true,true}, {"unlink",op_unlk,4,true,true},
                {"br",op_br,3,false}, {"bra",op_bra,3,false}, {"pea",op_pea},
				{"cmpi",op_cmpi,1,true}, {"tst",op_tst,1,true},
		{"stop", op_stop}, {"movs", op_movs},
		{"bmi", op_bmi},
				{"dc",op_dc},
		{"push",op_push,4,true,true}, {"pop", op_pop,4,true,true}, {"pea", op_pea},
		// Set
		{"seq", op_seq,1,true}, {"sne",op_sne,1,true},
		{"slt", op_slt,1,true}, {"sle",op_sle,1,true},{"sgt",op_sgt,1,true}, {"sge",op_sge,1,true},
		{"sltu", op_sltu,1,true}, {"sleu",op_sleu,1,true},{"sgtu",op_sgtu,1,true}, {"sgeu",op_sgeu,1,true},

		{"",op_empty}, {"",op_asm,100}, {"", op_fnname},
		{"ftadd", op_ftadd}, {"ftsub", op_ftsub}, {"ftmul", op_ftmul}, {"ftdiv", op_ftdiv},
		{"inc", op_inc}, {"dec", op_dec},

		{"bsr", op_bsr},

	// Shifts
	// Shifts are weighted as 2 because they can only execute on one ALU
	{"asr",op_asr,2,true}, {"asri", op_asri,2,true },
	{"shl", op_shl,2,true}, {"shr", op_shr,2,true}, {"shru", op_shru,2,true},
	{"shlu", op_shlu,2,true}, {"shlui", op_shlui,2,true},
	{"shli", op_shli,2,true}, {"shri", op_shri,2,true}, {"shrui", op_shrui,2,true},
	{"ror", op_ror,2,true}, {"rori", op_rori,2,true}, {"rol", op_rol,2,true}, {"roli", op_roli,2,true},
	{"sll", op_sll,2,true}, {"slli", op_slli,2,true}, {"srl", op_srl,2,true}, {"srli", op_srli,2,true},
	{"sra", op_sra,2,true}, {"srai", op_srai,2,true},
	{"asl", op_asl,2,true}, {"asli", op_asli,2,true}, {"lsr", op_lsr,2,true}, {"lsri", op_lsri,2,true},
		
		{"chk", op_chk }, {"chki",op_chki}, {";", op_rem},

		{"fbeq", op_fbeq,3}, {"fbne", op_fbne,3}, {"fbor", op_fbor,3}, {"fbun", op_fbun,3},
		{"fblt", op_fblt,3}, {"fble", op_fble,3}, {"fbgt", op_fbgt,3}, {"fbge", op_fbge,3},

		{"fcvtsq", op_fcvtsq},
		{"sf", op_sf}, {"lf", op_lf},
		{"sfd", op_sfd}, {"lfd", op_lfd}, {"fmov.d", op_fdmov}, {"fmov", op_fmov},
		{"fadd", op_fadd}, {"fsub", op_fsub}, {"fmul", op_fmul}, {"fdiv", op_fdiv},
		{"ftoi", op_ftoi}, {"itof", op_itof},
		{"fix2flt", op_fix2flt}, {"mtfp", op_mtfp}, {"flt2fix",op_flt2fix}, {"mffp",op_mffp},
		{"mv2fix",op_mv2fix}, {"mv2flt", op_mv2flt},
		{"csrrw", op_csrrw}, {"nop", op_nop},
		{"tgt", op_calltgt,1},
		{"hint", op_hint,0}, {"hint2",op_hint2,0},
		{"abs", op_abs,2},
	// Vector operations
	{"lv", op_lv,256,true}, {"sv", op_sv,256,true},
	{"vadd", op_vadd,10}, {"vsub", op_vsub,10}, {"vmul", op_vmul,10}, {"vdiv", op_vdiv,100},
	{"vseq", op_vseq,10}, {"vsne", op_vsne,10},
	{"vslt", op_vslt,10}, {"vsge", op_vsge,10}, {"vsle", op_vsle,10}, {"vsgt", op_vsgt,10},
	{"vadds", op_vadds,10}, {"vsubs", op_vsubs,10}, {"vmuls", op_vmuls,10}, {"vdivs", op_vdivs,100},
	{"vex", op_vex,10}, {"veins",op_veins,10},
	{"redor", op_redor,2,true},
	{"rti", op_rti,2,false},
	{"rte", op_rte,2,false},
	{"bex", op_bex,0,false},
	{"phi", op_phi},
                {0,0} };

static char *pad(char *op)
{
	static char buf[20];
	int n;

	n = strlen(op);
	strncpy_s(buf,20,op,19);
	buf[19] = '\0';
	if (n < 5) {
		strcat_s(buf, 20, "     ");
		buf[5] = '\0';
	}
	return buf;
}

Instruction *GetInsn(int op)
{
	int i;

    for(i = 0; opl[i].mnem; i++)
		if( opl[i].opcode == op )
			return (&opl[i]);
	return (nullptr);
}

/*
static char *segstr(int op)
{
	static char buf[20];

	switch(op & 0xff00) {
	case op_cs:
		return "cs";
	case op_ss:
		return "ss";
	case op_ds:
		return "ds";
	case op_bs:
		return "bs";
	case op_ts:
		return "ts";
	default:
		sprintf(buf, "seg%d", op >> 8);
		return buf;
	}
}
*/

void putop(Instruction *insn,int op, int len)
{    
	int     i;
	char buf[100];

    i = 0;
//    while( opl[i].mnem )
//    {
//		if( opl[i].opcode == (op & 0x1FF))
//		{
			//seg = op & 0xFF00;
			//if (seg != 0) {
			//	fprintf(output, "%s:", segstr(op));
			//}
			if (len) {
				if (len <= 16) {
					switch(len) {
					case 1:	sprintf_s(buf, sizeof(buf), "%s.b", insn->mnem); break;
					case 2:	sprintf_s(buf, sizeof(buf), "%s.c", insn->mnem); break;
					case 4:	sprintf_s(buf, sizeof(buf), "%s.h", insn->mnem); break;
					case 8:	sprintf_s(buf, sizeof(buf), "%s", insn->mnem); break;
					}
				}
				else {
					if (len != 'w' && len!='W')
						sprintf_s(buf, sizeof(buf), "%s.%c", insn->mnem, len);
					else
						sprintf_s(buf, sizeof(buf), "%s", insn->mnem);
				}
			}
			else
				sprintf_s(buf, sizeof(buf), "%s", insn->mnem);
			ofs.write(pad(buf));
			return;
//		}
//		++i;
//    }
    printf("DIAG - illegal opcode (%d).\n", op);
}

static void PutConstant(ENODE *offset, unsigned int lowhigh, unsigned int rshift)
{
	// ASM statment text (up to 3500 chars) may be placed in the following buffer.
	static char buf[4000];

	switch( offset->nodetype )
	{
	case en_autofcon:
			sprintf_s(buf,sizeof(buf),"%lld",offset->i);
			ofs.write(buf);
			break;
	case en_fcon:
			goto j1;
			sprintf_s(buf,sizeof(buf),"0x%llx",offset->f);
			ofs.write(buf);
			break;
	case en_autovcon:
	case en_autocon:
	case en_icon:
            if (lowhigh==2) {
	            sprintf_s(buf,sizeof(buf),"%ld",offset->i & 0xffff);
				ofs.write(buf);
			}
            else if (lowhigh==3) {
	            sprintf_s(buf,sizeof(buf),"%ld",(offset->i >> 16) & 0xffff);
				ofs.write(buf);
			}
            else {
            	sprintf_s(buf,sizeof(buf),"%lld",offset->i);
				ofs.write(buf);
			}
           	if (rshift > 0) {
           	    sprintf_s(buf,sizeof(buf), ">>%d", rshift);
				ofs.write(buf);
			}
			break;
	case en_labcon:
j1:
			sprintf_s(buf, sizeof(buf), "%s_%ld",GetNamespace(),offset->i);
			ofs.write(buf);
            if (rshift > 0) {
                sprintf_s(buf, sizeof(buf), ">>%d", rshift);
				ofs.write(buf);
			}
			break;
	case en_clabcon:
			sprintf_s(buf,sizeof(buf),"%s_%ld",GetNamespace(),offset->i);
			ofs.write(buf);
            if (rshift > 0) {
                sprintf_s(buf,sizeof(buf), ">>%d", rshift);
				ofs.write(buf);
			}
			break;
	case en_nacon:
			sprintf_s(buf,sizeof(buf),"%s",(char *)offset->sp->c_str());
			ofs.write(buf);
			if (lowhigh==3) {
			    sprintf_s(buf, sizeof(buf), ">>16");
				ofs.write(buf);
			}
            if (rshift > 0) {
                sprintf_s(buf, sizeof(buf), ">>%d", rshift);
				ofs.write(buf);
			}
			break;
	case en_cnacon:
			sprintf_s(buf,sizeof(buf),"%s",(char *)offset->msp->c_str());
			if (strncmp(buf, "public code",11)==0) {
				printf("pub code\r\n");
			}
			sprintf_s(buf,sizeof(buf), "%s",(char *)offset->msp->c_str());
			ofs.write(buf);
            if (rshift > 0) {
                sprintf_s(buf, sizeof(buf), ">>%d", rshift);
				ofs.write(buf);
			}
			break;
	case en_add:
			PutConstant(offset->p[0],0,0);
			ofs.write("+");
			PutConstant(offset->p[1],0,0);
			break;
	case en_sub:
			PutConstant(offset->p[0],0,0);
			ofs.write("-");
			PutConstant(offset->p[1],0,0);
			break;
	case en_uminus:
			ofs.write("-");
			PutConstant(offset->p[0],0,0);
			break;
	default:
			printf("DIAG - illegal constant node.\n");
			break;
	}
}


// Output a friendly register moniker

char *RegMoniker(int regno)
{
	static char buf[4][20];
	static int n;

	n = (n + 1) & 3;
    if (regno==regFP)
		sprintf_s(&buf[n][0], 20, "$fp");
    else if (regno==regGP)
		sprintf_s(&buf[n][0], 20, "$gp");
	else if (regno==regXLR)
		sprintf_s(&buf[n][0], 20, "$xlr");
	else if (regno==regPC)
		sprintf_s(&buf[n][0], 20, "$pc");
	else if (regno==regSP)
		sprintf_s(&buf[n][0], 20, "$sp");
	else if (regno==regLR)
		sprintf_s(&buf[n][0], 20, "$lr");
	else if (regno>=1 && regno<=4)
		sprintf_s(&buf[n][0], 20, "$v%d", regno-1);
	else if (regno >= regFirstArg && regno <= regLastArg)
		sprintf_s(&buf[n][0], 20, "$a%d", regno-regFirstArg);
	else if (regno >= regFirstTemp && regno <= regLastTemp)
		sprintf_s(&buf[n][0], 20, "$t%d", regno-regFirstTemp);
	else if (regno >= regFirstRegvar && regno <= regLastRegvar)
		sprintf_s(&buf[n][0], 20, "$r%d", regno);
	else
		sprintf_s(&buf[n][0], 20, "$r%d", regno);
	return &buf[n][0];
}

void PutAddressMode(AMODE *ap)
{
	switch( ap->mode )
    {
    case am_immed:
			ofs.write("#");
			// Fall through
    case am_direct:
            PutConstant(ap->offset,ap->lowhigh,ap->rshift);
            break;
    case am_reg:
			if (ap->type==stdvector.GetIndex())
				ofs.printf("v%d", (int)ap->preg);
			else if (ap->type==stdvectormask->GetIndex())
				ofs.printf("vm%d", (int)ap->preg);
			else if (ap->type==stddouble.GetIndex())
				ofs.printf("$fp%d", (int)ap->preg);
			else {
				ofs.write(RegMoniker(ap->preg));
				if (renamed)
					ofs.printf(".%d", (int)ap->pregs);
			}
            break;
    case am_vmreg:
			ofs.printf("vm%d", (int)ap->preg);
            break;
    case am_fpreg:
            ofs.printf("$fp%d", (int)ap->preg);
            break;
    case am_ind:
			ofs.printf("[%s]",RegMoniker(ap->preg));
			break;
    case am_indx:
			// It's not known the function is a leaf routine until code
			// generation time. So the parameter offsets can't be determined
			// until code is being output. This bit of code first adds onto
			// parameter offset the size of the return block, then later
			// subtracts it off again.
			if (ap->offset) {
				if (ap->preg==regFP) {
					if (ap->offset->sym) {
						if (ap->offset->sym->IsParameter) {	// must be an parameter
							ap->offset->i += GetReturnBlockSize()-(currentFn->IsLeaf  ? sizeOfWord : 0);
						}
					}
				}
           		PutConstant(ap->offset,0,0);
				if (ap->preg==regFP) {
					if (ap->offset->sym) {
						if (ap->offset->sym->IsParameter) {
							ap->offset->i -= GetReturnBlockSize()-(currentFn->IsLeaf  ? sizeOfWord : 0);
						}
					}
				}
			}
			ofs.printf("[%s]",RegMoniker(ap->preg));
			break;

	case am_indx2:
			if (ap->scale==1 || ap->scale==0)
	            ofs.printf("[%s+%s]",RegMoniker(ap->sreg),RegMoniker(ap->preg));
			else
		        ofs.printf("[%s+%s*%d]",RegMoniker(ap->sreg),RegMoniker(ap->preg),ap->scale);
            break;

	case am_indx3:
            ofs.printf("[%s+%s]",RegMoniker(ap->sreg),RegMoniker(ap->preg));
            break;

	case am_mask:
            put_mask((int)ap->offset);
            break;
    default:
            printf("DIAG - illegal address mode.\n");
            break;
    }
}

/*
 *      output a generic instruction.
 */
//void put_code(int op, int len,AMODE *aps,AMODE *apd,AMODE *ap3,AMODE *ap4)
void put_code(OCODE *p)
{
	static BasicBlock *b = nullptr;
	int op = p->opcode;
	AMODE *aps,*apd,*ap3,*ap4;
	ENODE *ep;
	int predreg = p->pregreg;
	int len = p->length;
	aps = p->oper1;
	apd = p->oper2;
	ap3 = p->oper3;
	ap4 = p->oper4;

	if (p->bb != b) {
		ofs.printf(";====================================================\n");
		ofs.printf("; Basic Block %d\n", p->bb->num);
		ofs.printf(";====================================================\n");
		b = p->bb;
	}
	if (p->comment) {
		ofs.printf("; %s\n", (char *)p->comment->oper1->offset->sp->c_str());
	}
	if (p->remove)
		ofs.printf(";-1");
	if (p->remove2)
		ofs.printf(";-2");
	if( op == op_dc )
		{
		switch( len )
			{
			case 1: ofs.printf("\tdh"); break;
			case 2: ofs.printf("\tdw"); break;
			}
		}
	else if (op != op_fnname)
		{
			if (op==op_rem2) {
				ofs.printf(";\t");
				ofs.printf("%6.6s\t", "");
				ofs.printf(aps->offset->sp->c_str());
		        ofs.printf("\n");
				return;
			}
			else {
				ofs.printf("\t");
				ofs.printf("%6.6s\t", "");
				putop(p->insn,op,len);
			}
		}
	if (op==op_fnname) {
		ep = (ENODE *)p->oper1->offset;
		ofs.printf("%s:", (char *)ep->sp->c_str());
	}
	else if( aps != 0 )
        {
                ofs.printf("\t");
					PutAddressMode(aps);
					if( apd != 0 )
					{
						if (op==op_push || op==op_pop)
							ofs.printf("/");
						else
							ofs.printf(",");
							if (op==op_cmp && apd->mode != am_reg)
								printf("aha\r\n");
                       		PutAddressMode(apd);
							if (ap3 != NULL) {
								if (op==op_push || op==op_pop)
									ofs.printf("/");
								else
									ofs.printf(",");
								PutAddressMode(ap3);
								if (ap4 != NULL) {
									if (op==op_push || op==op_pop)
										ofs.printf("/");
									else
										ofs.printf(",");
									PutAddressMode(ap4);
								}
					}
                }
        }
        ofs.printf("\n");
}

/*
 *      generate a register mask for restore and save.
 */
void put_mask(int mask)
{
	int nn;
	int first = 1;

	for (nn = 0; nn < 32; nn++) {
		if (mask & (1<<nn)) {
			if (!first)
				ofs.printf("/");
			ofs.printf("r%d",nn);
			first = 0;
		}
	}
//	fprintf(output,"#0x%04x",mask);

}

/*
 *      generate a register name from a tempref number.
 */
void putreg(int r)
{
	ofs.printf("r%d", r);
}

/*
 *      generate a named label.
 */
void gen_strlab(char *s)
{       ofs.printf("%s:\n",s);
}

/*
 *      output a compiler generated label.
 */
char *put_label(int lab, char *nm, char *ns, char d)
{
  static char buf[500];

  sprintf_s(buf, sizeof(buf), "%.400s_%d", ns, lab);
	if (nm==NULL)
		ofs.printf("%s:\n",buf);
	else if (strlen(nm)==0)
		ofs.printf("%s:\n",buf);
	else
		ofs.printf("%s:	; %s\n",buf,nm);
	return buf;
}


void GenerateByte(int val)
{
	if( gentype == bytegen && outcol < 60) {
        ofs.printf(",%d",val & 0x00ff);
        outcol += 4;
    }
    else {
        nl();
        ofs.printf("\tdb\t%d",val & 0x00ff);
        gentype = bytegen;
        outcol = 19;
    }
}

void GenerateChar(int val)
{
	if( gentype == chargen && outcol < 60) {
        ofs.printf(",%d",val & 0xffff);
        outcol += 6;
    }
    else {
        nl();
        ofs.printf("\tdc\t%d",val & 0xffff);
        gentype = chargen;
        outcol = 21;
    }
}

void genhalf(int val)
{
	if( gentype == halfgen && outcol < 60) {
        ofs.printf(",%d",(int)(val & 0xffffffff));
        outcol += 10;
    }
    else {
        nl();
        ofs.printf("\tdh\t%d",(int)(val & 0xffffffff));
        gentype = halfgen;
        outcol = 25;
    }
}

void GenerateWord(int val)
{
	if( gentype == wordgen && outcol < 58) {
        ofs.printf(",%ld",val);
        outcol += 18;
    }
    else {
        nl();
        ofs.printf("\tdw\t%ld",val);
        gentype = wordgen;
        outcol = 33;
    }
}

void GenerateLong(int64_t val)
{ 
	if( gentype == longgen && outcol < 56) {
                ofs.printf(",%lld",val);
                outcol += 10;
                }
        else    {
                nl();
                ofs.printf("\tdw\t%lld",val);
                gentype = longgen;
                outcol = 25;
                }
}

void GenerateFloat(Float128 *val)
{ 
	if (val==nullptr)
		return;
	ofs.printf("\r\n\talign 8\r\n");
	ofs.printf("\tdh\t%s",val->ToString(64));
    gentype = longgen;
    outcol = 65;
}

void GenerateQuad(Float128 *val)
{ 
	if (val==nullptr)
		return;
	ofs.printf("\r\n\talign 8\r\n");
	ofs.printf("\tdh\t%s",val->ToString(128));
    gentype = longgen;
    outcol = 65;
}

void GenerateReference(SYM *sp,int offset)
{
	char    sign;
    if( offset < 0) {
        sign = '-';
        offset = -offset;
    }
    else
        sign = '+';
    if( gentype == longgen && outcol < 55 - (int)sp->name->length()) {
        if( sp->storage_class == sc_static) {
			ofs.printf(",");
			ofs.printf(GetNamespace());
			ofs.printf("_%ld", sp->value.i);
			ofs.putch(sign);
			ofs.printf("%d", offset);
//                fprintf(output,",%s_%ld%c%d",GetNamespace(),sp->value.i,sign,offset);
		}
        else if( sp->storage_class == sc_thread) {
			ofs.printf(",");
			ofs.printf(GetNamespace());
			ofs.printf("_%ld", sp->value.i);
			ofs.putch(sign);
			ofs.printf("%d", offset);
//                fprintf(output,",%s_%ld%c%d",GetNamespace(),sp->value.i,sign,offset);
		}
		else {
			if (offset==0) {
                ofs.printf(",%s",(char *)sp->name->c_str());
			}
			else {
                ofs.printf(",%s",(char *)sp->name->c_str());
				ofs.putch(sign);
				ofs.printf("%d",offset);
			}
		}
        outcol += (11 + sp->name->length());
    }
    else {
        nl();
        if(sp->storage_class == sc_static) {
			ofs.printf("\tdw\t%s",GetNamespace());
			ofs.printf("_%ld",sp->value.i);
			ofs.putch(sign);
			ofs.printf("%d",offset);
//            fprintf(output,"\tdw\t%s_%ld%c%d",GetNamespace(),sp->value.i,sign,offset);
		}
        else if(sp->storage_class == sc_thread) {
//            fprintf(output,"\tdw\t%s_%ld%c%d",GetNamespace(),sp->value.i,sign,offset);
			ofs.printf("\tdw\t%s",GetNamespace());
			ofs.printf("_%ld",sp->value.i);
			ofs.putch(sign);
			ofs.printf("%d",offset);
		}
		else {
			if (offset==0) {
				ofs.printf("\tdw\t%s",(char *)sp->name->c_str());
			}
			else {
				ofs.printf("\tdw\t%s",(char *)sp->name->c_str());
				ofs.putch(sign);
				ofs.printf("%d", offset);
//				fprintf(output,"\tdw\t%s%c%d",sp->name,sign,offset);
			}
		}
        outcol = 26 + sp->name->length();
        gentype = longgen;
    }
}

void genstorage(int nbytes)
{       
	nl();
	ofs.printf("\tfill.b\t%d,0x00\n",nbytes);
}

void GenerateLabelReference(int n)
{ 
	if( gentype == longgen && outcol < 58) {
        ofs.printf(",%s_%d",GetNamespace(),n);
        outcol += 6;
    }
    else {
        nl();
        ofs.printf("\tdw\t%s_%d",GetNamespace(),n);
        outcol = 22;
        gentype = longgen;
    }
}

/*
 *      make s a string literal and return it's label number.
 */
int stringlit(char *s)
{      
	struct slit *lp;

	lp = (struct slit *)allocx(sizeof(struct slit));
	lp->label = nextlabel++;
	lp->str = my_strdup(s);
	lp->nmspace = my_strdup(GetNamespace());
	lp->next = strtab;
	strtab = lp;
	return lp->label;
}

int caselit(struct scase *cases, int64_t num)
{
	struct clit *lp;

	lp = (struct clit *)allocx(sizeof(struct clit));
	lp->label = nextlabel++;
	lp->nmspace = my_strdup(GetNamespace());
	lp->cases = (struct scase *)allocx(sizeof(struct scase)*(int)num);
	lp->num = (int)num;
	memcpy(lp->cases, cases, (int)num * sizeof(struct scase));
	lp->next = casetab;
	casetab = lp;
	return lp->label;
}

int quadlit(Float128 *f128)
{
	Float128 *lp;
	lp = quadtab;
	// First search for the same literal constant and it's label if found.
	while(lp) {
		if (Float128::IsEqual(lp,Float128::Zero())) {
			if (Float128::IsEqualNZ(lp,f128))
				return lp->label;
		}
		else if (Float128::IsEqual(lp,f128))
			return lp->label;
		lp = lp->next;
	}
	lp = (Float128 *)allocx(sizeof(Float128));
	lp->label = nextlabel++;
	Float128::Assign(lp,f128);
	lp->nmspace = my_strdup(GetNamespace());
	lp->next = quadtab;
	quadtab = lp;
	return lp->label;
}


char *strip_crlf(char *p)
{
     static char buf[2000];
     int nn;

     for (nn = 0; *p && nn < 1998; p++) {
         if (*p != '\r' && *p!='\n') {
            buf[nn] = *p;
            nn++;
         }
     }
     buf[nn] = '\0';
	 return buf;
}


// Dump the literal pools.

void dumplits()
{
	char *cp;
	int nn;

	dfs.printf("<Dumplits>\n");
	roseg();
	if (casetab) {
		nl();
		align(8);
		nl();
	}
	while(casetab != nullptr) {
		nl();
		put_label(casetab->label,"",casetab->nmspace,'D');
		for (nn = 0; nn < casetab->num; nn++)
			GenerateLabelReference(casetab->cases[nn].label);
		casetab = casetab->next;
	}
	if (quadtab) {
		nl();
		align(8);
		nl();
	}
	while(quadtab != nullptr) {
		nl();
		put_label(quadtab->label,"",quadtab->nmspace,'D');
		ofs.printf("\tdh\t");
		quadtab->Pack(64);
		ofs.printf("%s",quadtab->ToString(64));
		outcol += 35;
		quadtab = quadtab->next;
	}
	if (strtab) {
		nl();
		align(2);
		nl();
	}
	while( strtab != NULL) {
		dfs.printf(".");
		nl();
		put_label(strtab->label,strip_crlf(strtab->str),strtab->nmspace,'D');
		cp = strtab->str;
		while(*cp)
			GenerateChar(*cp++);
		GenerateChar(0);
		strtab = strtab->next;
	}
	nl();
	dfs.printf("</Dumplits>\n");
}

void nl()
{       
	if(outcol > 0) {
		ofs.printf("\n");
		outcol = 0;
		gentype = nogen;
	}
}

void align(int n)
{
	ofs.printf("\talign\t%d\n",n);
}

void cseg()
{
	if( curseg != codeseg) {
		nl();
		ofs.printf("\tcode\n");
		ofs.printf("\talign\t16\n");
		curseg = codeseg;
    }
}

void dseg()
{    
	nl();
	if( curseg != dataseg) {
		ofs.printf("\tdata\n");
		curseg = dataseg;
    }
	ofs.printf("\talign\t8\n");
}

void tseg()
{    
	if( curseg != tlsseg) {
		nl();
		ofs.printf("\ttls\n");
		ofs.printf("\talign\t8\n");
		curseg = tlsseg;
    }
}

void roseg()
{
	if( curseg != rodataseg) {
		nl();
		ofs.printf("\trodata\n");
		ofs.printf("\talign\t16\n");
		curseg = rodataseg;
    }
}

void seg(int sg, int algn)
{    
	nl();
	if( curseg != sg) {
		switch(sg) {
		case bssseg:
			ofs.printf("\tbss\n");
			break;
		case dataseg:
			ofs.printf("\tdata\n");
			break;
		case tlsseg:
			ofs.printf("\ttls\n");
			break;
		case idataseg:
			ofs.printf("\tidata\n");
			break;
		case codeseg:
			ofs.printf("\tcode\n");
			break;
		case rodataseg:
			ofs.printf("\trodata\n");
			break;
		}
		curseg = sg;
    }
 	ofs.printf("\talign\t%d\n", algn);
}
