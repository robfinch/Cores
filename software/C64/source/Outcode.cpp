// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2015  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - 'C' derived language compiler
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
/*
 *	68000 C compiler
 *
 *	Copyright 1984, 1985, 1986 Matthew Brandt.
 *  all commercial rights reserved.
 *
 *	This compiler is intended as an instructive tool for personal use. Any
 *	use for profit without the written consent of the author is prohibited.
 *
 *	This compiler may be distributed freely for non-commercial use as long
 *	as this notice stays intact. Please forward any enhancements or questions
 *	to:
 *
 *		Matthew Brandt
 *		Box 920337
 *		Norcross, Ga 30092
 */
#include "stdafx.h"

extern char *TraceName(SYM *);
void put_mask(int mask);
void align(int n);
void roseg();

/*      variable initialization         */

enum e_gt { nogen, bytegen, chargen, halfgen, wordgen, longgen };
//enum e_sg { noseg, codeseg, dataseg, bssseg, idataseg };

int	       gentype = nogen;
int	       curseg = noseg;
int        outcol = 0;

struct oplst {
        char    *s;
        int     ov;
        }       opl[] =
{       {"move",op_move}, {"addu",op_add}, {"addu", op_addu}, {"mov", op_mov}, {"mtspr", op_mtspr}, {"mfspr", op_mfspr},
		{"ldi",op_ldi},
		{"add",op_addi}, {"subu",op_sub}, {"subu", op_subu},
		{"subi",op_subi}, {"and",op_and}, {"eor",op_eor}, {"eori", op_eori},
		{"divi", op_divi}, {"divui", op_divui}, {"modi", op_modi}, {"modui", op_modui},
		{"sext8",op_sext8}, {"sext16", op_sext16}, {"sext32", op_sext32},
		{"sxb",op_sxb}, {"sxc", op_sxc}, {"sxh", op_sxh},
		{"zxb",op_zxb}, {"zxc", op_zxc}, {"zxh", op_zxh},
		{"subui",op_subui}, {"shru", op_shru}, {"divsi", op_divsi}, {"not", op_not},
		{"addui",op_addui},

		{"shr", op_shr}, {"dw", op_dw}, {"shl", op_shl}, {"shr", op_shr}, {"shru", op_shru},
		{"shlu", op_shlu}, {"shlui", op_shlui},
		{"shli", op_shli}, {"shri", op_shri}, {"shrui", op_shrui},

		{"bfext", op_bfext}, {"bfextu", op_bfextu}, {"bfins", op_bfins},
		{"sw", op_sw}, {"lw", op_lw}, {"lh", op_lh}, {"lc", op_lc}, {"lb", op_lb},
		{"lvb", op_lvb}, {"lvc", op_lvc}, {"lvh", op_lvh}, {"lvw", op_lvw},
		{"lbu", op_lbu}, {"lcu", op_lcu}, {"lhu", op_lhu}, {"sti", op_sti},
		{"lft", op_lft}, {"sft", op_sft},

		{"ldis", op_ldis}, {"lws", op_lws}, {"sws", op_sws},
		{"lm", op_lm}, {"sm",op_sm}, {"sb",op_sb}, {"sc",op_sc}, {"sh",op_sh},
		{"call", op_call}, {"ret", op_ret}, {"loop", op_loop}, {"beqi", op_beqi},
		{"jal", op_jal}, {"jsr", op_jsr}, {"rts", op_rts},
		{"brz", op_brz}, {"brnz", op_brnz},
		{"beq", op_beq}, {"bne", op_bne},
		{"blt", op_blt}, {"ble", op_ble}, {"bgt", op_bgt}, {"bge", op_bge},
		{"bltu", op_bltu}, {"bleu", op_bleu}, {"bgtu", op_bgtu}, {"bgeu", op_bgeu},
		{"rti", op_rti}, {"rtd", op_rtd},
		{"lwr", op_lwr}, {"swc", op_swc}, {"cache",op_cache},
		{"or",op_or}, {"ori",op_ori}, {"iret", op_iret}, {"andi", op_andi},
		{"xor",op_xor}, {"xori", op_xori}, {"mul",op_mul}, {"muli", op_muli}, {"mului", op_mului}, 
		
		{"fmul", op_fdmul}, {"fdiv", op_fddiv}, {"fadd", op_fdadd}, {"fsub", op_fdsub}, {"fcmp", op_fdcmp},
		{"fmul.s", op_fsmul}, {"fdiv.s", op_fsdiv}, {"fadd.s", op_fsadd}, {"fsub.s", op_fssub},
		{"fs2d", op_fs2d}, {"fi2d", op_i2d}, {"fneg", op_fdneg}, 

		{"divs",op_divs}, {"swap",op_swap}, {"mod", op_mod}, {"modu", op_modu},
		{"eq",op_eq}, {"bnei", op_bnei}, {"sei", op_sei},
		{"ltu", op_ltu}, {"leu",op_leu}, {"gtu",op_gtu}, {"geu", op_geu},
                {"bhi",op_bhi}, {"bhs",op_bhs}, {"blo",op_blo}, {"bun", op_bun},
                {"bls",op_bls}, {"mulu",op_mulu}, {"divu",op_divu},
                {"ne",op_ne}, {"lt",op_lt}, {"le",op_le},
		{"gt",op_gt}, {"ge",op_ge}, {"neg",op_neg}, {"nr", op_nr},
		{"not",op_not}, {"com", op_com}, {"cmp",op_cmp}, {"ext",op_ext}, 
		{"jmp",op_jmp},
		{"lea",op_lea}, {"asr",op_asr}, {"asri", op_asri },
                {"clr",op_clr}, {"link",op_link}, {"unlink",op_unlk},
                {"br",op_br}, {"bra",op_bra}, {"pea",op_pea},
				{"cmpi",op_cmpi}, {"tst",op_tst},
		{"stop", op_stop}, {"movs", op_movs},
		{"bmi", op_bmi}, {"outb", op_outb}, {"inb", op_inb}, {"inbu", op_inbu},
				{"dc",op_dc},
		{"push",op_push}, {"pop", op_pop}, {"pea", op_pea},
		{"seq", op_seq}, {"sne",op_sne},
		{"slt", op_slt}, {"sle",op_sle},{"sgt",op_sgt}, {"sge",op_sge},
		{"sltu", op_sltu}, {"sleu",op_sleu},{"sgtu",op_sgtu}, {"sgeu",op_sgeu},
		{"",op_empty}, {"",op_asm}, {"", op_fnname},
		{"ftadd", op_ftadd}, {"ftsub", op_ftsub}, {"ftmul", op_ftmul}, {"ftdiv", op_ftdiv},
		{"inc", op_inc}, {"dec", op_dec},

		{"sec", op_sec}, {"clc", op_clc}, {"lda", op_lda}, {"sta", op_sta}, {"stz", op_stz},
        {"sbc", op_sbc}, {"adc", op_adc}, {"ora", op_ora}, {"eor", op_eor},
		{"ora", op_ora}, {"jsl", op_jsl}, {"rts", op_rts}, {"rtl", op_rtl}, {"rti", op_rti},
		{"ldx", op_ldx}, {"stx", op_stx}, {"php", op_php}, {"plp", op_plp}, {"sei", op_sei},
		{"cli", op_cli}, {"brl", op_brl},
		{"pha", op_pha}, {"phx", op_phx}, {"pla", op_pla}, {"plx", op_plx},
		{"rep", op_rep}, {"sep", op_sep},
		{"bpl", op_bpl}, {"tsa", op_tsa}, {"tas", op_tas},
		
		{"bsr", op_bsr},
		{"cmpu", op_cmpu},
		{"lc0i", op_lc0i}, {"lc1i", op_lc1i}, {"lc2i", op_lc2i}, {"lc3i", op_lc3i},
		{"sll", op_sll}, {"slli", op_slli}, {"srl", op_srl}, {"srli", op_srli}, {"sra", op_sra}, {"srai", op_srai},
		{"asl", op_asl}, {"asli", op_asli}, {"lsr", op_lsr}, {"lsri", op_lsri}, {"chk", op_chk }, {"chki",op_chki}, {";", op_rem},
		{"sfd", op_sfd}, {"lfd", op_lfd}, {"fmov.d", op_fdmov},
		{"fix2flt", op_fix2flt}, {"mtfp", op_mtfp}, {"flt2fix",op_flt2fix}, {"mffp",op_mffp},
		{"mv2fix",op_mv2fix}, {"mv2flt", op_mv2flt},
                {0,0} };

static char *pad(char *op)
{
	static char buf[20];
	int n;

	n = strlen(op);
	strncpy(buf,op,19);
	buf[19] = '\0';
	if (n < 5) {
		strcat(buf, "     ");
		buf[5] = '\0';
	}
	return buf;
}

char *opstr(int op)
{
	int     i;
    i = 0;
    while( opl[i].s )
    {
		if( opl[i].ov == op )
		{
			return (opl[i].s);
		}
		++i;
    }
	return (char *)NULL;
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

void putop(int op)
{    
	int     i;
	int seg;

    i = 0;
    while( opl[i].s )
    {
		if( opl[i].ov == (op & 255))
		{
			//seg = op & 0xFF00;
			//if (seg != 0) {
			//	fprintf(output, "%s:", segstr(op));
			//}
			ofs.write(pad(opl[i].s));
			return;
		}
		++i;
    }
    printf("DIAG - illegal opcode.\n");
}

static void PutConstant(ENODE *offset, unsigned int lowhigh, unsigned int rshift)
{
	// ASM statment text (up to 3500 chars) may be placed in the following buffer.
	static char buf[4000];

	switch( offset->nodetype )
	{
	case en_autofcon:
			sprintf(buf,"%lld",offset->i);
			ofs.write(buf);
			break;
	case en_fcon:
			sprintf(buf,"0x%llx",offset->f);
			ofs.write(buf);
			break;
	case en_autocon:
	case en_icon:
            if (lowhigh==2) {
	            sprintf(buf,"%lld",offset->i & 0xffff);
				ofs.write(buf);
			}
            else if (lowhigh==3) {
	            sprintf(buf,"%lld",(offset->i >> 16) & 0xffff);
				ofs.write(buf);
			}
            else {
            	sprintf(buf,"%lld",offset->i);
				ofs.write(buf);
			}
           	if (rshift > 0) {
           	    sprintf(buf, ">>%d", rshift);
				ofs.write(buf);
			}
			break;
	case en_labcon:
			sprintf(buf, "%s_%lld",GetNamespace(),offset->i);
			ofs.write(buf);
            if (rshift > 0) {
                sprintf(buf, ">>%d", rshift);
				ofs.write(buf);
			}
			break;
	case en_clabcon:
			sprintf(buf,"%s_%lld",GetNamespace(),offset->i);
			ofs.write(buf);
            if (rshift > 0) {
                sprintf(buf, ">>%d", rshift);
				ofs.write(buf);
			}
			break;
	case en_nacon:
			sprintf(buf,"%s",(char *)offset->sp->c_str());
			ofs.write(buf);
			if (lowhigh==3) {
			    sprintf(buf, ">>16");
				ofs.write(buf);
			}
            if (rshift > 0) {
                sprintf(buf, ">>%d", rshift);
				ofs.write(buf);
			}
			break;
	case en_cnacon:
			sprintf(buf,"%s",(char *)offset->msp->c_str());
			if (strncmp(buf, "public code",11)==0) {
				printf("pub code\r\n");
			}
			sprintf(buf,"%s",(char *)offset->msp->c_str());
			ofs.write(buf);
            if (rshift > 0) {
                sprintf(buf, ">>%d", rshift);
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
	if (is816) {
        sprintf(&buf[n][0], "$%02X", regno);
    }
    else if (isFISA64) {
        if (regno==regBP)
		    sprintf(&buf[n][0], "bp");
        else if (regno==regGP)
		    sprintf(&buf[n][0], "gp");
	    else if (regno==regXLR)
		    sprintf(&buf[n][0], "xlr");
	    else if (regno==regPC)
		    sprintf(&buf[n][0], "pc");
	    else if (regno==regSP)
		    sprintf(&buf[n][0], "sp");
	    else if (regno==regLR)
		    sprintf(&buf[n][0], "lr");
	    else
		    sprintf(&buf[n][0], "r%d", regno);
    }
	else if (isTable888) {
		switch(regno) {
		case 244:	sprintf(&buf[n][0], "flg0"); break;
		case 249:   sprintf(&buf[n][0], "gp"); break;
		case 250:	sprintf(&buf[n][0], "lr"); break;
		case 251:	sprintf(&buf[n][0], "xlr"); break;
		case 252:	sprintf(&buf[n][0], "tr"); break;
		case 253:	sprintf(&buf[n][0], "bp"); break;
		case 254:	sprintf(&buf[n][0], "pc"); break;
		case 255:	sprintf(&buf[n][0], "sp"); break;
		default:
                  if (regno > 255) {
                      sprintf(&buf[n][0],"fp%d", regno); break;
                  }	
                  else
                      sprintf(&buf[n][0], "r%d", regno); break;
		}
	}
	else if (isThor) {
		switch(regno) {
		case 26:	sprintf(&buf[n][0], "bp"); break;
		//case 251:	sprintf(&buf[n], "xlr"); break;
		//case 254:	sprintf(&buf[n], "pc"); break;
		case 27:	sprintf(&buf[n][0], "sp"); break;
		default:	sprintf(&buf[n][0], "r%d", regno); break;
		}
	}
	else {
		switch(regno) {
		case 27:	sprintf(&buf[n][0], "bp"); break;
		case 28:	sprintf(&buf[n][0], "xlr"); break;
		case 29:	sprintf(&buf[n][0], "pc"); break;
		case 30:	sprintf(&buf[n][0], "sp"); break;
		case 31:	sprintf(&buf[n][0], "lr"); break;
		default:	sprintf(&buf[n][0], "r%d", regno); break;
		}
	}
	return &buf[n][0];
}

char *BrRegMoniker(int regno)
{
	static char buf[4][20];
	static int n;

	n = (n + 1) & 3;
	switch(regno) {
	case  1:	sprintf(&buf[n][0], "c1"); break;
	case 11:	sprintf(&buf[n][0], "c11"); break;
	case 15:	sprintf(&buf[n][0], "c15"); break;
	default:	sprintf(&buf[n][0], "c%d", regno); break;
	}
	return &buf[n][0];
}

char *PredRegMoniker(int regno)
{
	static char buf[4][20];
	static int n;

	n = (n + 1) & 3;
	sprintf(&buf[n][0], "p%d", regno);
	return &buf[n][0];
}

char *PredOpStr(int op)
{
	switch(op)
	{
	case 2: return "eq";
	case 3: return "ne";
	case 4: return "le";
	case 5: return "gt";
	case 6: return "ge";
	case 7: return "lt";
	case 8: return "leu";
	case 9: return "gtu";
	case 10: return "geu";
	case 11: return "ltu";
	}
	return "<bad op>";
}

int PredOp(int op)
{
	switch(op) {
//		case op_f:	return 0;
//		case op_t:	return 1;
		case op_eq:	return 2;
		case op_ne:	return 3;
		case op_le: return 4;
		case op_gt: return 5;
		case op_ge: return 6;
		case op_lt: return 7;
		case op_leu:	return 8;
		case op_gtu:	return 9;
		case op_geu:	return 10;
		case op_ltu:	return 11;
		default: return 1;
	}
}

int InvPredOp(int op)
{
	switch(op) {
//		case op_f:	return 0;
//		case op_t:	return 1;
		case 2:	return 3;
		case 3:	return 2;
		case 4: return 5;
		case 5: return 4;
		case 6: return 7;
		case 7: return 6;
		case 8:	return 9;
		case 9:	return 8;
		case 10:	return 11;
		case 11:	return 10;
		default: return 1;
	}
}

void PutAddressMode(AMODE *ap)
{
	switch( ap->mode )
    {
    case am_immed:
		ofs.write("#");
    case am_direct:
            PutConstant(ap->offset,ap->lowhigh,ap->rshift);
            break;
    case am_breg:
			ofs.write(BrRegMoniker(ap->preg));
            break;
    case am_reg:
			ofs.write(RegMoniker(ap->preg));
            break;
    case am_fpreg:
            ofs.printf("fp%d", (int)ap->preg);
            break;
    case am_predreg:
			ofs.write(PredRegMoniker(ap->preg));
            break;
    case am_ind:
    case am_indx:
			//if (ap->offset != NULL) {
			//	if (ap->offset->i != 0)
			//		fprintf(output, "%I64d[r%d]", ap->offset->i, ap->preg);
			//	else
			//		fprintf(output,"[r%d]",ap->preg);
			//}
			//else
			if (ap->offset != NULL && !is816) {
//                if (ap->offset->i)
                	PutConstant(ap->offset,0,0);
           }
//				if (ap->offset->i)
//					fprintf(output, "%I64d", ap->offset->i);
				ofs.printf("[%s]",RegMoniker(ap->preg));
				if (is816)
				   ofs.write(",y");
			break;
	case am_brind:
			ofs.printf("[%s]",BrRegMoniker(ap->preg));
			break;
    case am_ainc:
            ofs.printf("******[r%d]", (int)ap->preg);
			ofs.printf("addui\ta%d,a%d,#",ap->preg,ap->preg);
            break;
    case am_adec:
			ofs.printf("subui\ta%d,a%d,#",ap->preg,ap->preg);
            ofs.printf("******[a%d]",(int)ap->preg);
            break;
/*
    case am_indx:
			if (ap->offset != 0)
				PutConstant(ap->offset,0);
            fprintf(output,"[%s]",RegMoniker(ap->preg));
            break;
*/
    case am_indx2:
//			if (ap->offset != 0)
//				PutConstant(ap->offset,0,0);
			if (ap->scale==1 || ap->scale==0)
	            ofs.printf("[%s+%s]",RegMoniker(ap->sreg),RegMoniker(ap->preg));
			else
		        ofs.printf("[%s+%s*%d]",RegMoniker(ap->sreg),RegMoniker(ap->preg),ap->scale);
            break;
    case am_indx3:
//			if (ap->offset->i != 0)
//	            PutConstant(ap->offset,0,0);
            ofs.printf("[%s+%s]",RegMoniker(ap->sreg),RegMoniker(ap->preg));
            break;
    case am_mask:
            put_mask((int64_t)ap->offset);
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
void put_code(struct ocode *p)
{
	int op = p->opcode;
	AMODE *aps,*apd,*ap3,*ap4;
	ENODE *ep;
	int pop = p->predop;
	int predreg = p->pregreg;
	int len = p->length;
	aps = p->oper1;
	apd = p->oper2;
	ap3 = p->oper3;
	ap4 = p->oper4;

	if( op == op_dc )
		{
		switch( len )
			{
			case 1: ofs.printf("\tdb"); break;
			case 2: ofs.printf("\tdc"); break;
			case 4: ofs.printf("\tdh"); break;
			case 8: ofs.printf("\tdw"); break;
			}
		}
	else if (op != op_fnname)
		{
			ofs.printf("\t");
			if (pop!=1)
				ofs.printf("p%d.%s\t",predreg,PredOpStr(pop));
			else
				ofs.printf("%6.6s\t", "");
			if (is816 && aps) {
                if (aps->mode==am_ind || aps->mode==am_indx) {
        			if (aps->offset != NULL) {
                        ofs.printf("%s\t#", pad("ldy"));
                        PutConstant(aps->offset,0,0);
    				    ofs.printf("\n\t      \t");
                   }
                }
            }
			putop(op);
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

  sprintf(buf, "%.400s_%d", ns, lab);
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

void GenerateWord(int64_t val)
{
	if( gentype == wordgen && outcol < 58) {
        ofs.printf(",%ld",val);
        outcol += 18;
    }
    else {
        nl();
        ofs.printf("\tdh\t%ld",val);
        gentype = wordgen;
        outcol = 33;
    }
}

void GenerateLong(int64_t val)
{ 
	if( gentype == longgen && outcol < 56) {
                ofs.printf(",%ld",val);
                outcol += 10;
                }
        else    {
                nl();
                ofs.printf("\tdw\t%ld",val);
                gentype = longgen;
                outcol = 25;
                }
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
    if( gentype == longgen && outcol < 55 - sp->name->length()) {
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
{       nl();
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


//     Dump the string literal pool.

void dumplits()
{
	char *cp;

  dfs.printf("Enter Dumplits\n");
  roseg();
  nl();
	align(8);
  nl();
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
  dfs.printf("Leave Dumplits\n");
}

void nl()
{       if(outcol > 0) {
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
