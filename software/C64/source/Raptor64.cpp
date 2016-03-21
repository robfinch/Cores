// ============================================================================
// (C) 2012-2016 Robert Finch
// All Rights Reserved.
// robfinch<remove>@finitron.ca
//
// C64 - Raptor64 'C' derived language compiler
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

void GenerateRaptor64Return(SYM *sym, Statement *stmt);
int TempInvalidate();
void TempRevalidate(int);
void ReleaseTempRegister(AMODE *ap);
AMODE *GetTempRegister();

// ----------------------------------------------------------------------------
// AllocateRegisterVars will allocate registers for the expressions that have
// a high enough desirability.
// ----------------------------------------------------------------------------

int AllocateRaptor64RegisterVars()
{
	CSE *csp;
    ENODE *exptr;
    int reg, mask, rmask;
    AMODE *ap, *ap2, *ap3;
	int nn;
	int cnt;
	int size;

	reg = 11;
    mask = 0;
	rmask = 0;
    while( bsort(&olist) );         /* sort the expression list */
    csp = olist;
    while( csp != NULL ) {
        if( OptimizationDesireability(csp) < 3 )	// was < 3
            csp->reg = -1;
//        else if( csp->duses > csp->uses / 4 && reg < 18 )
		else {
			{
				if( csp->duses > csp->uses / 4 && reg < 18 )
//				if( reg < 18 )	// was / 4
					csp->reg = reg++;
				else
					csp->reg = -1;
			}
		}
        if( csp->reg != -1 )
		{
			rmask = rmask | (1 << (31 - csp->reg));
			mask = mask | (1 << csp->reg);
		}
        csp = csp->next;
    }
	if( mask != 0 ) {
		cnt = 0;
		GenerateTriadic(op_subui,0,makereg(regSP),makereg(regSP),make_immed(bitsset(rmask)*8));
		for (nn = 0; nn < 32; nn++) {
			if (rmask & (0x80000000 >> nn)) {
				GenerateDiadic(op_sw,0,makereg(nn&31),make_indexed(cnt,regSP));
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


AMODE *GenExprRaptor64(ENODE *node)
{
	AMODE *ap1,*ap2,*ap3;
	int lab0, lab1;
	int op;
	int size;

    lab0 = nextlabel++;
    lab1 = nextlabel++;
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
	switch(node->nodetype) {
	case en_eq:
	case en_ne:
	case en_lt:
	case en_ult:
	case en_gt:
	case en_ugt:
	case en_le:
	case en_ule:
	case en_ge:
	case en_uge:
		size = GetNaturalSize(node);
	    ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0],F_REG, size);
		ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED18,size);
		GenerateTriadic(op,0,ap3,ap1,ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		return ap3;
	}
    GenerateFalseJump(node,lab0,0);
    ap1 = GetTempRegister();
    GenerateTriadic(op_ori,0,ap1,makereg(0),make_immed(1));
    GenerateTriadic(op_bra,0,make_label(lab1),NULL,NULL);
    GenerateLabel(lab0);
    GenerateTriadic(op_ori,0,ap1,makereg(0),make_immed(0));
    GenerateLabel(lab1);
    return ap1;
}

void GenerateRaptor64Cmp(ENODE *node, int op, int label, int predreg)
{
	int size;
	AMODE *ap1, *ap2;

	size = GetNaturalSize(node);
	ap1 = GenerateExpression(node->p[0],F_REG, size);
	ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED18,size);
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
	GenerateTriadic(op,0,ap1,ap2,make_label(label));
	ReleaseTempRegister(ap2);
	ReleaseTempRegister(ap1);
}

// Generate a function body.
//
void GenerateRaptor64Function(SYM *sym, Statement *stmt)
{
	char buf[20];
	char *bl;

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
	if (!sym->IsNocall) {
		GenerateTriadic(op_subui,0,makereg(regSP),makereg(regSP),make_immed(24));
		// For a leaf routine don't bother to store the link register or exception link register.
		if (sym->IsLeaf)
			GenerateDiadic(op_sw,0,makereg(regBP),make_indirect(regSP));
		else {
			GenerateDiadic(op_sw, 0, makereg(regBP), make_indexed(0,regSP));
			GenerateDiadic(op_sw, 0, makereg(regXLR), make_indexed(8,regSP));
			GenerateDiadic(op_sw, 0, makereg(regLR), make_indexed(16,regSP));
			GenerateDiadic(op_lea,0,makereg(regXLR),make_label(throwlab));
		}
		GenerateDiadic(op_mov,0,makereg(regBP),makereg(regSP));
		if (lc_auto)
			GenerateTriadic(op_subui,0,makereg(regSP),makereg(regSP),make_immed(lc_auto));
	}
	if (optimize)
		opt1(stmt);
    GenerateStatement(stmt);
    GenerateRaptor64Return(sym,0);
	// Generate code for the hidden default catch
	GenerateLabel(throwlab);
	if (sym->IsLeaf){
		if (sym->DoesThrow) {
			GenerateDiadic(op_mov,0,makereg(regLR),makereg(regXLR));
			GenerateDiadic(op_bra,0,make_label(retlab),NULL);				// goto regular return cleanup code
		}
	}
	else {
		GenerateDiadic(op_lw,0,makereg(regLR),make_indexed(8,regBP));		// load throw return address from stack into LR
		GenerateDiadic(op_sw,0,makereg(regLR),make_indexed(16,regBP));		// and store it back (so it can be loaded with the lm)
		GenerateDiadic(op_bra,0,make_label(retlab),NULL);				// goto regular return cleanup code
	}
}


// Generate a return statement.
//
void GenerateRaptor64Return(SYM *sym, Statement *stmt)
{
	AMODE *ap;
	int nn;
	int lab1;
	int cnt;

    if( stmt != NULL && stmt->exp != NULL )
	{
		initstack();
		ap = GenerateExpression(stmt->exp,F_REG|F_IMMED,8);
		// Force return value into register 1
		if( ap->preg != 1 ) {
			if (ap->mode == am_immed)
				GenerateTriadic(op_ori, 0, makereg(1),makereg(0),ap);
			else
				GenerateDiadic(op_mov, 0, makereg(1),ap);
		}
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
		if( save_mask != 0 ) {
			cnt = (bitsset(save_mask)-1)*8;
			for (nn = 31; nn >=1 ; nn--) {
				if (save_mask & (1 << nn)) {
					GenerateTriadic(op_lw,0,makereg(nn),make_indexed(cnt,regSP),NULL);
					cnt -= 8;
				}
			}
			GenerateTriadic(op_addui,0,makereg(regSP),makereg(regSP),make_immed(popcnt(save_mask)*8));
		}
		// Unlink the stack
		// For a leaf routine the link register and exception link register doesn't need to be saved/restored.
		GenerateDiadic(op_mov,0,makereg(regSP),makereg(regBP));
		if (sym->IsLeaf)
			GenerateDiadic(op_lw,0,makereg(regBP),make_indirect(regSP));
		else {
			GenerateDiadic(op_lw,0,makereg(regBP),make_indirect(regSP));
			GenerateDiadic(op_lw,0,makereg(regXLR),make_indexed(8,regSP));
			GenerateDiadic(op_lw,0,makereg(regLR),make_indexed(16,regSP));
		}
		//if (isOscall) {
		//	GenerateDiadic(op_move,0,makereg(0),make_string("_TCBregsave"));
		//	gen_regrestore();
		//}
		// Generate the return instruction. For the Pascal calling convention pop the parameters
		// from the stack.
		if (sym->IsInterrupt) {
			//GenerateTriadic(op_addui,0,makereg(30),makereg(30),make_immed(24));
			//GenerateDiadic(op_lm,0,make_indirect(30),make_mask(0x9FFFFFFE));
			//GenerateTriadic(op_addui,0,makereg(30),makereg(30),make_immed(popcnt(0x9FFFFFFE)*8));
			GenerateMonadic(op_iret,0,NULL);
			return;
		}
		if (sym->IsPascal)
			GenerateDiadic(op_ret,0,make_immed(24+sym->NumParms * 8),NULL);
		else
			GenerateDiadic(op_ret,0,make_immed(24),NULL);
    }
	// Just branch to the already generated stack cleanup code.
	else {
		GenerateDiadic(op_bra,0,make_label(retlab),0);
	}
}

// push the operand expression onto the stack.
//
static void GeneratePushParameter(ENODE *ep, int i, int n)
{    
	AMODE *ap;
	ap = GenerateExpression(ep,F_REG,8);
	GenerateDiadic(op_sw,0,ap,make_indexed((n-i)*8-8,regSP));
	ReleaseTempRegister(ap);
}

// push entire parameter list onto stack
//
static int GeneratePushParameterList(ENODE *plist)
{
	ENODE *st = plist;
	int i,n;
	// count the number of parameters
	for(n = 0; plist != NULL; n++ )
		plist = plist->p[1];
	// move stack pointer down by number of parameters
	if (st)
		GenerateTriadic(op_subui,0,makereg(regSP),makereg(regSP),make_immed(n*8));
	plist = st;
    for(i = 0; plist != NULL; i++ )
    {
		GeneratePushParameter(plist->p[0],i,n);
		plist = plist->p[1];
    }
    return i;
}

AMODE *GenerateRaptor64FunctionCall(ENODE *node, int flags)
{ 
	AMODE *ap, *result;
	SYM *sym;
    int             i;
	int msk;
	int sp;

	sp = TempInvalidate();
	sym = NULL;
    i = GeneratePushParameterList(node->p[1]);
	// Call the function
	if( node->p[0]->nodetype == en_nacon ) {
        GenerateDiadic(op_call,0,make_offset(node->p[0]),NULL);
		sym = gsearch(*node->p[0]->sp);
	}
    else
    {
		ap = GenerateExpression(node->p[0],F_REG,8);
		ap->mode = am_ind;
		ap->offset = 0;
		GenerateDiadic(op_jal,0,makereg(regLR),ap);
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
