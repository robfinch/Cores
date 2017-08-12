// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2017  Robert Finch, Waterloo
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
{       {"add",op_add}, {"adc",op_adc}, {"mov", op_mov},
		{"ld", op_ld}, 	{"sto", op_sto},
		{"addi",op_addi}, {"sub",op_sub}, {"sbc", op_sbc},
		{"subi",op_subi}, {"and",op_and},
		{"not", op_not},
		{"ror", op_ror}, {"rori", op_rori}, {"asr", op_asr}, {"lsr", op_lsr},
		{"jsr", op_jsr},
		{"rti", op_rti},
		{"or",op_or}, {"ori",op_ori}, {"andi", op_andi},
		{"xor",op_xor}, {"xori", op_xori},
		{"cmp",op_cmp},	{"cmpi",op_cmpi}, {"cmpc", op_cmpc},
		{"out", op_out}, {"in", op_in},
		{"push",op_push}, {"pop", op_pop},
		{"",op_empty}, {"",op_asm}, {"", op_fnname},
		{"inc", op_inc}, {"dec", op_dec},
		{"#", op_rem}, {"putpsr", op_putpsr},
		{"nop", op_nop},
		{"hint", op_hint},
		{"preload", op_preload},
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

void putpop(int pop)
{
	switch(pop) {
	case pop_always: ofs.write("   "); break;
	case pop_nop: ofs.write(" 0."); break;
	case pop_z: ofs.write(" z."); break;
	case pop_nz: ofs.write("nz."); break;
	case pop_c:	ofs.write(" c."); break;
	case pop_nc: ofs.write("nc."); break;
	case pop_mi: ofs.write("mi."); break;
	case pop_pl: ofs.write("pl."); break;
	}
}

void putop(int op, int len)
{    
	int     i;
	char buf[100];

    i = 0;
    while( opl[i].s )
    {
		if( opl[i].ov == (op & 0x1FF))
		{
			//seg = op & 0xFF00;
			//if (seg != 0) {
			//	fprintf(output, "%s:", segstr(op));
			//}
			if (len) {
				if (len <= 16) {
					switch(len) {
					case 1:	sprintf_s(buf, sizeof(buf), "%s.b", opl[i].s); break;
					case 2:	sprintf_s(buf, sizeof(buf), "%s.c", opl[i].s); break;
					case 4:	sprintf_s(buf, sizeof(buf), "%s.h", opl[i].s); break;
					case 8:	sprintf_s(buf, sizeof(buf), "%s.w", opl[i].s); break;
					}
				}
				else
					sprintf_s(buf, sizeof(buf), "%s.%c", opl[i].s, len);
			}
			else
				sprintf_s(buf, sizeof(buf), "%s", opl[i].s);
			ofs.write(pad(buf));
			return;
		}
		++i;
    }
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
            	sprintf_s(buf,sizeof(buf),"%ld",offset->i);
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
			if (offset->sp)
				ofs.write((char *)offset->sp->c_str());
            if (rshift > 0) {
                sprintf_s(buf, sizeof(buf), ">>%d", rshift);
				ofs.write(buf);
			}
			break;
	case en_clabcon:
			sprintf_s(buf,sizeof(buf),"%s_%ld",GetNamespace(),offset->i);
			ofs.write(buf);
			if (offset->sp)
				ofs.write((char *)offset->sp->c_str());
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
 //   if (regno==regBP)
	//	sprintf_s(&buf[n][0], 20, "bp");
 //   else if (regno==regGP)
	//	sprintf_s(&buf[n][0], 20, "gp");
	//else if (regno==regXLR)
	//	sprintf_s(&buf[n][0], 20, "xlr");
	//else if (regno==regPC)
	//	sprintf_s(&buf[n][0], 20, "pc");
	//else if (regno==regSP)
	//	sprintf_s(&buf[n][0], 20, "sp");
	//else if (regno==regLR)
	//	sprintf_s(&buf[n][0], 20, "lr");
	//else
		sprintf_s(&buf[n][0], 20, "r%d", regno);
	return &buf[n][0];
}

void PutAddressMode(AMODE *ap)
{
	switch( ap->mode )
    {
    case am_immed:
			ofs.write("");
            PutConstant(ap->offset,ap->lowhigh,ap->rshift);
            break;
    case am_direct:
			//ofs.printf("r0,");
            PutConstant(ap->offset,ap->lowhigh,ap->rshift);
            break;
    case am_reg:
			ofs.write(RegMoniker(ap->preg));
            break;
    case am_fpreg:
            ofs.printf("fp%d", (int)ap->preg);
            break;
    case am_ind:
			ofs.printf("%s",RegMoniker(ap->preg));
			break;
    case am_indx:
			// It's not known the function is a leaf routine until code
			// generation time. So the parameter offsets can't be determined
			// until code is being output. This bit of code first adds onto
			// parameter offset the size of the return block, then later
			// subtracts it off again.
			ofs.printf("%s,",RegMoniker(ap->preg));
			if (ap->offset) {
				if (ap->preg==regBP) {
					if (ap->offset->sym) {
						if (ap->offset->sym->IsParameter) {	// must be an parameter
							ap->offset->i += GetReturnBlockSize();//-(currentFn->IsLeaf  ? sizeOfWord : 0);
						}
					}
				}
           		PutConstant(ap->offset,0,0);
				if (ap->preg==regBP) {
					if (ap->offset->sym) {
						if (ap->offset->sym->IsParameter) {
							ap->offset->i -= GetReturnBlockSize();//-(currentFn->IsLeaf  ? sizeOfWord : 0);
						}
					}
				}
			}
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
	int op = p->opcode;
	int pop = p->predop;
	AMODE *aps,*apd,*ap3,*ap4;
	ENODE *ep;
	int predreg = p->pregreg;
	int len = p->length;
	aps = p->oper1;
	apd = p->oper2;
	ap3 = p->oper3;
	ap4 = p->oper4;

	if (p->comment) {
		ofs.printf("\t# %s\n", (char *)p->comment->oper1->offset->sp->c_str());
	}
	if( op == op_dc )
		{
		switch( len )
			{
			case 1: ofs.printf("\tdh"); break;
			case 2: ofs.printf("\tWORD"); break;
			}
		}
	else if (op != op_fnname)
		{
			ofs.printf("\t");
			ofs.printf("%6.6s\t", "");
			putpop(pop);
			putop(op,len);
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
							ofs.printf(",");
							if (op==op_cmp && apd->mode != am_reg)
								printf("aha\r\n");
                       		PutAddressMode(apd);
							if (ap3 != NULL) {
								ofs.printf(",");
								PutAddressMode(ap3);
								if (ap4 != NULL) {
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
		ofs.printf("%s:	# %s\n",buf,nm);
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
        ofs.printf("\tWORD\t%d",val & 0x00ff);
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
        ofs.printf("\tWORD\t%d",val & 0xffff);
        gentype = chargen;
        outcol = 21;
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
        ofs.printf("\tWORD\t%ld",val);
        gentype = wordgen;
        outcol = 33;
    }
}

void GenerateLong(int val)
{ 
	if( gentype == longgen && outcol < 56) {
                ofs.printf(",%ld",val);
                outcol += 10;
                }
        else    {
                nl();
                ofs.printf("\tdWORD\t%ld",val);
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
			ofs.printf("\tWORD\t%s",GetNamespace());
			ofs.printf("_%ld",sp->value.i);
			ofs.putch(sign);
			ofs.printf("%d",offset);
//            fprintf(output,"\tdw\t%s_%ld%c%d",GetNamespace(),sp->value.i,sign,offset);
		}
        else if(sp->storage_class == sc_thread) {
//            fprintf(output,"\tdw\t%s_%ld%c%d",GetNamespace(),sp->value.i,sign,offset);
			ofs.printf("\tWORD\t%s",GetNamespace());
			ofs.printf("_%ld",sp->value.i);
			ofs.putch(sign);
			ofs.printf("%d",offset);
		}
		else {
			if (offset==0) {
				ofs.printf("\tWORD\t%s",(char *)sp->name->c_str());
			}
			else {
				ofs.printf("\tWORD\t%s",(char *)sp->name->c_str());
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
	int nn;

	nl();
	if (nbytes < 1000)
		for (nn = 0; nn < nbytes; nn++)
			ofs.printf("\tWORD\t0\n");
	else
		ofs.printf("\tfill.w\t%d,0x00\n",(nbytes+1)/2);
}

void GenerateLabelReference(int n)
{ 
	if( gentype == longgen && outcol < 58) {
        ofs.printf(",%s_%d",GetNamespace(),n);
        outcol += 6;
    }
    else {
        nl();
        ofs.printf("\tWORD\t%s_%d",GetNamespace(),n);
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

int caselit(struct scase *cases, int num)
{
	struct clit *lp;

	lp = (struct clit *)allocx(sizeof(struct clit));
	lp->label = nextlabel++;
	lp->nmspace = my_strdup(GetNamespace());
	lp->cases = (struct scase *)allocx(sizeof(struct scase)*num);
	lp->num = num;
	memcpy(lp->cases, cases, num * sizeof(struct scase));
	lp->next = casetab;
	casetab = lp;
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
	ofs.printf("#\talign\t%d\n",n);
}

void cseg()
{
	if( curseg != codeseg) {
		nl();
		ofs.printf("#\tcode\n");
		curseg = codeseg;
    }
}

void dseg()
{    
	nl();
	if( curseg != dataseg) {
		ofs.printf("#\tdata\n");
		curseg = dataseg;
    }
}

void tseg()
{    
	if( curseg != tlsseg) {
		nl();
		ofs.printf("#\ttls\n");
		ofs.printf("#\talign\t8\n");
		curseg = tlsseg;
    }
}

void roseg()
{
	if( curseg != rodataseg) {
		nl();
		ofs.printf("#\trodata\n");
		curseg = rodataseg;
    }
}

void seg(int sg, int algn)
{    
	nl();
	if( curseg != sg) {
		switch(sg) {
		case bssseg:
			ofs.printf("#\tbss\n");
			break;
		case dataseg:
			ofs.printf("#\tdata\n");
			break;
		case tlsseg:
			ofs.printf("#\ttls\n");
			break;
		case idataseg:
			ofs.printf("#\tidata\n");
			break;
		case codeseg:
			ofs.printf("#\tcode\n");
			break;
		case rodataseg:
			ofs.printf("#\trodata\n");
			break;
		}
		curseg = sg;
    }
 	//ofs.printf("\talign\t%d\n", algn);
}
