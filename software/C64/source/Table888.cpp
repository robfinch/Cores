// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Stratford
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
#include "stdafx.h"

extern int     breaklab;
extern int     contlab;
extern int     retlab;
extern int		throwlab;

extern int lastsph;
extern char *semaphores[20];

extern TYP              stdfunc;

void GenerateTable888Return(SYM *sym, Statement *stmt);
int TempInvalidate();
void TempRevalidate(int);
void ReleaseTempRegister(AMODE *ap);
AMODE *GetTempRegister();


// ----------------------------------------------------------------------------
// AllocateRegisterVars will allocate registers for the expressions that have
// a high enough desirability.
// ----------------------------------------------------------------------------

int AllocateTable888RegisterVars()
{
	CSE *csp;
    ENODE *exptr;
    int reg, mask, rmask;
	int brreg, brmask, brrmask;
	int fpreg, fpmask;
    AMODE *ap, *ap2;
	int nn;
	int cnt;
	int size;

	reg = 11;
	brreg = 19;
	fpreg = 256+11;
    mask = 0;
	rmask = 0;
	brmask = 0;
	fpmask = 0;
	brrmask = 0;
    while( bsort(&olist) );         /* sort the expression list */
    csp = olist;
    while( csp != NULL ) {
        if( OptimizationDesireability(csp) < 3 )	// was < 3
            csp->reg = -1;
//        else if( csp->duses > csp->uses / 4 && reg < 18 )
		else {
			if ((csp->exp->nodetype==en_clabcon || csp->exp->nodetype==en_cnacon)) {
				if (brreg < 21)
					csp->reg = brreg++;
				else
					csp->reg = -1;
			}
			else if (csp->exp->etype==bt_triple)
			{
				if( csp->duses > csp->uses / 4 && reg < 256+18 )
//				if( reg < 18 )	// was / 4
					csp->reg = reg++;
				else
					csp->reg = -1;
			}
			else
			{
				if( csp->duses > csp->uses / 4 && reg < 18 )
//				if( reg < 18 )	// was / 4
					csp->reg = reg++;
				else
					csp->reg = -1;
			}
		}
        if( csp->reg != -1 && csp->reg < 256)
		{
			rmask = rmask | (1 << (31 - csp->reg));
			mask = mask | (1 << csp->reg);
		}
        csp = csp->next;
    }
	if( mask != 0 ) {
		cnt = 0;
		//GenerateTriadic(op_subui,0,makereg(SP),makereg(SP),make_immed(bitsset(rmask)*8));
		for (nn = 0; nn < 32; nn++) {
			if (rmask & (0x80000000 >> nn)) {
				GenerateMonadic(op_push,0,makereg(nn&31));//,make_indexed(cnt,SP),NULL);
				//GenerateDiadic(op_sw,0,makereg(nn&31),make_indexed(cnt,SP));
				cnt+=8;
			}
		}
	}
    save_mask = mask;
    csp = olist;
    while( csp != NULL ) {
            if( csp->reg != -1 )
                    {               /* see if preload needed */
                    exptr = csp->exp;
                    if( !IsLValue(exptr) || (exptr->p[0]->i > 0) )
                            {
                            initstack();
                            ap = GenerateExpression(exptr,F_ALL,8);
							ap2 = makereg(csp->reg);
							if (ap->mode==am_immed)
								GenerateDiadic(op_ldi,0,ap2,ap);
							else if (ap->mode==am_reg)
								GenerateDiadic(op_mov,0,ap2,ap);
							else {
								size = GetNaturalSize(exptr);
								if (exptr->isUnsigned) {
									switch(size) {
									case 1:	GenerateDiadic(op_lbu,0,ap2,ap); break;
									case 2:	GenerateDiadic(op_lcu,0,ap2,ap); break;
									case 4:	GenerateDiadic(op_lhu,0,ap2,ap); break;
									case 8:	GenerateDiadic(op_lw,0,ap2,ap); break;
									}
								}
								else {
									switch(size) {
									case 1:	GenerateDiadic(op_lb,0,ap2,ap); break;
									case 2:	GenerateDiadic(op_lc,0,ap2,ap); break;
									case 4:	GenerateDiadic(op_lh,0,ap2,ap); break;
									case 8:	GenerateDiadic(op_lw,0,ap2,ap); break;
									}
								}
							}
                            ReleaseTempRegister(ap);
                            }
                    }
            csp = csp->next;
            }
	return popcnt(mask);
}

AMODE *GenTable888Set(ENODE *node)
{
	AMODE *ap1,*ap2,*ap3;
	int op;
	int size;

	switch(node->nodetype) {
	case en_eq:		op = op_seq;	break;
	case en_ne:		op = op_sne;	break;
	case en_lt:		op = op_slt;	break;
	case en_ult:	op = op_sltu;	break;
	case en_le:		op = op_sle;	break;
	case en_ule:	op = op_sleu;	break;
	case en_gt:		op = op_sgt;	break;
	case en_ugt:	op = op_sgtu;	break;
	case en_ge:		op = op_sge;	break;
	case en_uge:	op = op_sgeu;	break;
	}
	size = GetNaturalSize(node);
	ap3 = GetTempRegister();
	ap1 = GenerateExpression(node->p[0],F_REG, size);
	ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
	GenerateTriadic(op,0,ap3,ap1,ap2);
	ReleaseTempRegister(ap2);
	ReleaseTempRegister(ap1);
	return ap3;
}

void GenerateTable888Cmp(ENODE *node, int op, int label, int predreg)
{
	int size;
	AMODE *ap1, *ap2;

	size = GetNaturalSize(node);
	ap1 = GenerateExpression(node->p[0],F_REG, size);
	ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
	// Optimize CMP to zero and branch into BRZ/BRNZ
	if (ap2->mode == am_immed && ap2->offset->i==0 && op==op_eq) {
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		GenerateDiadic(op_brz,0,ap1,make_clabel(label));
		return;
	}
	if (ap2->mode == am_immed && ap2->offset->i==0 && op==op_ne) {
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		GenerateDiadic(op_brnz,0,ap1,make_clabel(label));
		return;
	}
	GenerateTriadic(op_cmp,0,makereg(244),ap1,ap2);
	switch(op)
	{
	case op_eq:	op = op_beq; break;
	case op_ne:	op = op_bne; break;
	case op_lt: op = op_blt; break;
	case op_le: op = op_ble; break;
	case op_gt: op = op_bgt; break;
	case op_ge: op = op_bge; break;
	case op_ltu: op = op_bltu; break;
	case op_leu: op = op_bleu; break;
	case op_gtu: op = op_bgtu; break;
	case op_geu: op = op_bgeu; break;
	}
	ReleaseTempRegister(ap2);
	ReleaseTempRegister(ap1);
	GenerateDiadic(op,0,makereg(244),make_clabel(label));
}

void GenerateTable888StackLink(SYM *sym)
{
	if (lc_auto || sym->NumParms > 0) {
		//GenerateMonadic(op_link,0,make_immed(24));
		GenerateTriadic(op_subui,0,makereg(regSP),makereg(regSP),make_immed(24));
		GenerateDiadic(op_sw,0,makereg(regBP),make_indirect(regSP));
		GenerateDiadic(op_mov,0,makereg(regBP),makereg(regSP));
	}
	else
		GenerateTriadic(op_subui,0,makereg(regSP),makereg(regSP),make_immed(24));
}

// Generate a function body.
//
void GenerateTable888Function(SYM *sym, Statement *stmt)
{
	AMODE *ap;
	ENODE *ep;

	throwlab = retlab = contlab = breaklab = -1;
	lastsph = 0;
	memset(semaphores,0,sizeof(semaphores));
	throwlab = nextlabel++;
	while( lc_auto & 7 )	/* round frame size to word */
		++lc_auto;
	if (sym->IsInterrupt) {
		//GenerateTriadic(op_subui,0,makereg(30),makereg(30),make_immed(30*8));
		//GenerateDiadic(op_sm,0,make_indirect(30), make_mask(0x9FFFFFFE));
	}
	// 24[bp]   return address
	// 16[bp]	flags
	// 8[bp]	catch link register
	// 0[bp]	base pointer
	if (!sym->IsNocall) {
//		GenerateTriadic(op_subui,0,makereg(SP),makereg(SP),make_immed(32));
		GenerateTable888StackLink(sym);
		if (exceptions) {
			GenerateDiadic(op_sw, 0, makereg(regXLR), make_indexed(8,regSP));
			ep = (ENODE *)xalloc(sizeof(ENODE));
			ep->nodetype = en_clabcon;
			ep->i = throwlab;
			ap = allocAmode();
			ap->mode = am_immed;
			ap->offset = ep;
			GenerateDiadic(op_ldi,0, makereg(regXLR), ap);
		}
		if (lc_auto || sym->NumParms > 0) {
//			GenerateDiadic(op_mov,0,makereg(BP),makereg(SP));
			if (lc_auto)
				GenerateTriadic(op_subui,0,makereg(SP),makereg(SP),make_immed(lc_auto));
		}

		// Save registers used as register variables.
		// **** Done in Analyze.c ****
		//if( save_mask != 0 ) {
		//	GenerateTriadic(op_subui,0,makereg(SP),makereg(SP),make_immed(popcnt(save_mask)*8));
		//	cnt = (bitsset(save_mask)-1)*8;
		//	for (nn = 31; nn >=1 ; nn--) {
		//		if (save_mask & (1 << nn)) {
		//			GenerateTriadic(op_sw,0,makereg(nn),make_indexed(cnt,SP),NULL);
		//			cnt -= 8;
		//		}
		//	}
		//}
	}
	if (optimize)
		sym->NumRegisterVars = opt1(stmt);
    GenerateStatement(stmt);
    GenerateTable888Return(sym,0);
	// Generate code for the hidden default catch
	if (exceptions) {
		GenerateLabel(throwlab);
		GenerateDiadic(op_lw,0,makereg(CLR),make_indexed(8,regBP));		// load throw return address from stack into LR
		GenerateDiadic(op_sw,0,makereg(CLR),make_indexed(24,regBP));		// and store it back (so it can be picked up by RTS)
		GenerateDiadic(op_bra,0,make_clabel(retlab),NULL);				// goto regular return cleanup code
	}
}


// Generate a return statement.
//
void GenerateTable888Return(SYM *sym, Statement *stmt)
{
	AMODE *ap;
	int nn;
	int cnt;
	int sz;

	// Generate code to evaluate the return expression.
    if( stmt != NULL && stmt->exp != NULL )
	{
		initstack();
		sz = GetNaturalSize(stmt->exp);
		ap = GenerateExpression(stmt->exp,F_ALL & ~F_BREG,sz);
		// Force return value into register 1
		if( ap->preg != 1 ) {
			if (ap->mode == am_immed)
				GenerateDiadic(op_ldi, 0, makereg(1),ap);
			else if (ap->mode == am_reg)
				GenerateDiadic(op_mov, 0, makereg(1),ap);
			else {
				if (stmt->exp->isUnsigned) {
					switch(sz) {
					case 1: GenerateDiadic(op_lbu,0,makereg(1),ap); break;
					case 2: GenerateDiadic(op_lcu,0,makereg(1),ap); break;
					case 4: GenerateDiadic(op_lhu,0,makereg(1),ap); break;
					case 8: GenerateDiadic(op_lw,0,makereg(1),ap); break;
					}
				}
				else {
					switch(sz) {
					case 1: GenerateDiadic(op_lb,0,makereg(1),ap); break;
					case 2: GenerateDiadic(op_lc,0,makereg(1),ap); break;
					case 4: GenerateDiadic(op_lh,0,makereg(1),ap); break;
					case 8: GenerateDiadic(op_lw,0,makereg(1),ap); break;
					}
				}
			}
		}
		ReleaseTempRegister(ap);
	}

	// Generate the return code only once. Branch to the return code for all returns.
	if( retlab == -1 )
    {
		retlab = nextlabel++;
		GenerateLabel(retlab);
		// Unlock any semaphores that may have been set
		for (nn = lastsph - 1; nn >= 0; nn--)
			GenerateDiadic(op_sb,0,makereg(0),make_string(semaphores[nn]));
		if (sym->IsNocall)	// nothing to do for nocall convention
			return;
		// Restore registers used as register variables.
		if( bsave_mask != 0 ) {
			cnt = (bitsset(bsave_mask)-1)*8;
			for (nn = 15; nn >=1 ; nn--) {
				if (bsave_mask & (1 << nn)) {
					GenerateTriadic(op_lws,0,makebreg(nn),make_indexed(cnt,SP),NULL);
					cnt -= 8;
				}
			}
			GenerateTriadic(op_addui,0,makereg(SP),makereg(SP),make_immed(popcnt(bsave_mask)*8));
		}
		if( save_mask != 0 ) {
			cnt = (bitsset(save_mask)-1)*8;
			for (nn = 31; nn >=1 ; nn--) {
				if (save_mask & (1 << nn)) {
					//GenerateDiadic(op_lw,0,makereg(nn),make_indexed(cnt,SP));
					GenerateMonadic(op_pop,0,makereg(nn));//,make_indexed(cnt,SP),NULL);
					cnt -= 8;
				}
			}
			//GenerateTriadic(op_addui,0,makereg(SP),makereg(SP),make_immed(popcnt(save_mask)*8));
		}
		// Unlink the stack
		// For a leaf routine the link register and exception link register doesn't need to be saved/restored.
		if (exceptions) {
			if (lc_auto || sym->NumParms > 0) {
				//GenerateMonadic(op_unlk,0,NULL);
				GenerateDiadic(op_mov,0,makereg(255),makereg(regBP));
				GenerateDiadic(op_lw,0,makereg(regBP),make_indirect(255));
			}

			if (exceptions)
				GenerateDiadic(op_lw,0,makereg(CLR),make_indexed(8,255));
			//GenerateDiadic(op_lws,0,make_string("pregs"),make_indexed(24,SP));
			//if (isOscall) {
			//	GenerateDiadic(op_move,0,makereg(0),make_string("_TCBregsave"));
			//	gen_regrestore();
			//}
			GenerateTriadic(op_addui,0,makereg(regSP),makereg(regSP),make_immed(24));
		}
		else {
			if (lc_auto || sym->NumParms > 0) {
				//GenerateMonadic(op_unlk,0,make_immed(24));
				GenerateDiadic(op_mov,0,makereg(regSP),makereg(regBP));
				GenerateDiadic(op_lw,0,makereg(regBP),make_indirect(regSP));
			}
			//GenerateDiadic(op_lws,0,make_string("pregs"),make_indexed(24,SP));
			//if (isOscall) {
			//	GenerateDiadic(op_move,0,makereg(0),make_string("_TCBregsave"));
			//	gen_regrestore();
			//}
			GenerateTriadic(op_addui,0,makereg(regSP),makereg(regSP),make_immed(24));
		}
		// Generate the return instruction. For the Pascal calling convention pop the parameters
		// from the stack.
		if (sym->IsInterrupt) {
			//GenerateTriadic(op_addui,0,makereg(30),makereg(30),make_immed(24));
			//GenerateDiadic(op_lm,0,make_indirect(30),make_mask(0x9FFFFFFE));
			//GenerateTriadic(op_addui,0,makereg(30),makereg(30),make_immed(popcnt(0x9FFFFFFE)*8));
			GenerateMonadic(op_rti,0,NULL);
			return;
		}
		if (sym->IsPascal) {
			GenerateMonadic(op_rts,0,make_immed(sym->NumParms * 8));
		}
		else {
			GenerateMonadic(op_rts,0,make_immed(0));
		}
    }
	// Just branch to the already generated stack cleanup code.
	else {
		GenerateMonadic(op_bra,0,make_clabel(retlab));
	}
}

// push the operand expression onto the stack.
// Complicated by the fact that Table888 allows up to four registers to be
// pushed with a single instruction. And we make use of it.
//
static void GenerateTable888PushParameter(ENODE *ep, int i, int n)
{    
	//static AMODE *ap[4];
	AMODE *ap;

	if (ep==NULL)
		return;
	ap = GenerateExpression(ep,F_REG|F_IMMED,8);
	GenerateMonadic(op_push,0,ap);
/*	ap[i % 4] = GenerateExpression(ep,F_REG,8);
	if (n-1==i) {
		switch(i % 3) {
		case 0:	GenerateMonadic(op_push,0,ap[0]);
				ReleaseTempRegister(ap[0]);
				break;
		case 1: GenerateDiadic(op_push,0,ap[0],ap[1]);
				ReleaseTempRegister(ap[1]);
				ReleaseTempRegister(ap[0]);
				break;
		case 2: GenerateTriadic(op_push,0,ap[0],ap[1],ap[2]);
				ReleaseTempRegister(ap[2]);
				ReleaseTempRegister(ap[1]);
				ReleaseTempRegister(ap[0]);
				break;
		case 3: Generate4adic(op_push,0,ap[0],ap[1],ap[2],ap[3]);
				ReleaseTempRegister(ap[3]);
				ReleaseTempRegister(ap[2]);
				ReleaseTempRegister(ap[1]);
				ReleaseTempRegister(ap[0]);
				break;
		}
	}
	else {
		if ((i % 4)==3) {
			Generate4adic(op_push,0,ap[0],ap[1],ap[2],ap[3]);
			ReleaseTempRegister(ap[3]);
			ReleaseTempRegister(ap[2]);
			ReleaseTempRegister(ap[1]);
			ReleaseTempRegister(ap[0]);
		}
	}*/
}

// push entire parameter list onto stack
//
static int GenerateTable888PushParameterList(ENODE *plist)
{
	ENODE *st = plist;
	int i,n;
	// count the number of parameters
	for(n = 0; plist != NULL; n++ )
		plist = plist->p[1];
	plist = st;
    for(i = 0; plist != NULL; i++ )
    {
		GenerateTable888PushParameter(plist->p[0],i,n);
		plist = plist->p[1];
    }
    return i;
}

AMODE *GenerateTable888FunctionCall(ENODE *node, int flags)
{ 
	AMODE *ap, *result;
	SYM *sym;
    int             i;
	int sp;

	sp = TempInvalidate();
	sym = NULL;
    i = GenerateTable888PushParameterList(node->p[1]);
	// Call the function
	if( node->p[0]->nodetype == en_cnacon ) {
        if (use_gp)
            GenerateMonadic(op_jsr,0,make_indx(node->p[0],regGP));//make_offset(node->p[0]));
        else
            GenerateMonadic(op_jsr,0,make_offset(node->p[0]));
		sym = gsearch(*node->p[0]->sp);
	}
    else
    {
		ap = GenerateExpression(node->p[0],F_REG,8);
		if (node->p[0]->sp->length())
			sym = gsearch(*node->p[0]->sp);
		if (use_gp) {
    		ap->mode = am_indx2;
    		ap->offset = 0;
    		ap->sreg = regGP;
        }
        else {
    		ap->mode = am_indx;
    		ap->offset = 0;
        }
		GenerateMonadic(op_jsr,0,ap);
		ReleaseTempRegister(ap);
    }
	// Pop parameters off the stack
	if (i!=0) {
		if (sym) {
			if (!sym->IsPascal)
				GenerateTriadic(op_addui,0,makereg(regSP),makereg(regSP),make_immed(i * 8));
		}
		else
			GenerateTriadic(op_addui,0,makereg(regSP),makereg(regSP),make_immed(i * 8));
	}
	TempRevalidate(sp);
    result = GetTempRegister();
	if (flags & F_NOVALUE)
		;
	else {
		if( result->preg != 1 || (flags & F_REG) == 0 ) {
			if (sym) {
				if (sym->tp->GetBtp()->type==bt_void)
					;
				else
					GenerateDiadic(op_mov,0,result,makereg(1));
			}
			else
				GenerateDiadic(op_mov,0,result,makereg(1));
		}
	}
    return result;
}

