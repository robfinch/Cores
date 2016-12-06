// ============================================================================
// (C) 2016 Robert Finch
// All Rights Reserved.
// robfinch<remove>@finitron.ca
//
// C32 - DSD7 'C' derived language compiler
//  - 32 bit CPU
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

extern int lastsph;
extern char *semaphores[20];
extern int throwlab;
extern int breaklab;
extern int contlab;
extern int retlab;

extern TYP              stdfunc;

extern void scan(Statement *);
extern int GetReturnBlockSize();
void GenerateReturn(Statement *stmt);
int TempFPInvalidate();
int TempInvalidate();
void TempRevalidate(int);
void TempFPRevalidate(int);
void ReleaseTempRegister(AMODE *ap);
AMODE *GetTempRegister();
void GenLdi(AMODE *, AMODE *);
extern AMODE *copy_addr(AMODE *ap);
extern void GenLoad(AMODE *ap1, AMODE *ap3, int ssize, int size);

/*
 *      returns the desirability of optimization for a subexpression.
 */
static int OptimizationDesireability(CSE *csp)
{
	if( csp->voidf || (csp->exp->nodetype == en_icon &&
                       csp->exp->i < 32767 && csp->exp->i >= -32767))
        return 0;
    if (csp->exp->nodetype==en_cnacon)
        return 0;
	if (csp->exp->isVolatile)
		return 0;
    if( IsLValue(csp->exp) )
	    return 2 * csp->uses;
    return csp->uses;
}

/*
 *      exchange will exchange the order of two expression entries
 *      following c1 in the linked list.
 */
static void exchange(CSE **c1)
{
	CSE *csp1, *csp2;

    csp1 = *c1;
    csp2 = csp1->next;
    csp1->next = csp2->next;
    csp2->next = csp1;
    *c1 = csp2;
}

/*
 *      bsort implements a bubble sort on the expression list.
 */
static int bsort(CSE **list)
{
	CSE *csp1, *csp2;
    int i;

    csp1 = *list;
    if( csp1 == NULL || csp1->next == NULL )
        return FALSE;
    i = bsort( &(csp1->next));
    csp2 = csp1->next;
    if( OptimizationDesireability(csp1) < OptimizationDesireability(csp2) ) {
        exchange(list);
        return TRUE;
    }
    return FALSE;
}

// ----------------------------------------------------------------------------
// AllocateRegisterVars will allocate registers for the expressions that have
// a high enough desirability.
// ----------------------------------------------------------------------------

int AllocateRegisterVars()
{
	CSE *csp;
    ENODE *exptr;
    int reg, fpreg;
	uint64_t mask, rmask;
    uint64_t fpmask, fprmask;
    AMODE *ap, *ap2;
	int64_t nn;
	int cnt;
	int size;

	reg = 11;
	fpreg = 11;
    mask = 0;
	rmask = 0;
	fpmask = 0;
	fprmask = 0;
    while( bsort(&olist) );         /* sort the expression list */
    csp = olist;
    while( csp != NULL ) {
        if( OptimizationDesireability(csp) < 3 )
            csp->reg = -1;
		else {
			{
                if (csp->isfp) {
    				if( csp->duses > csp->uses / 8 && fpreg < 18 )
    					csp->reg = fpreg++;
    				else
    					csp->reg = -1;
                }
                else {
    				if( csp->duses > csp->uses / 8 && reg < 18 )
    					csp->reg = reg++;
    				else
    					csp->reg = -1;
                }
			}
		}
		if (csp->isfp) {
            if( csp->reg != -1 )
    		{
    			fprmask = fprmask | (1LL << (63 - csp->reg));
    			fpmask = fpmask | (1LL << csp->reg);
    		}
        }
        else {
            if( csp->reg != -1 )
    		{
    			rmask = rmask | (1LL << (63 - csp->reg));
    			mask = mask | (1LL << csp->reg);
    		}
        }
        csp = csp->next;
    }
	if( mask != 0 ) {
		cnt = 0;
		//GenerateTriadic(op_subui,0,makereg(regSP),makereg(regSP),make_immed(bitsset(rmask)*8));
		for (nn = 0; nn < 64; nn++) {
			if (rmask & (0x8000000000000000ULL >> nn)) {
				//GenerateDiadic(op_sw,0,makereg(nn&31),make_indexed(cnt,regSP));
				GenerateMonadic(op_push,0,makereg(nn&63));
				cnt+=sizeOfWord;
			}
		}
	}
	if( fpmask != 0 ) {
		cnt = 0;
		for (nn = 0; nn < 64; nn++) {
			if (fprmask & (0x8000000000000000ULL >> nn)) {
				GenerateMonadic(op_push,0,makefpreg(nn&63));
				cnt+=sizeOfWord;
			}
		}
	}
    save_mask = mask;
    fpsave_mask = fpmask;
    csp = olist;
    while( csp != NULL ) {
            if( csp->reg != -1 )
                    {               /* see if preload needed */
                    exptr = csp->exp;
                    if( !IsLValue(exptr) || (exptr->p[0]->i > 0) || (exptr->nodetype==en_struct_ref))
                            {
                            initstack();
                            if (csp->isfp) {
                                ap = GenerateExpression(exptr,F_FPREG,8);
    							ap2 = makefpreg(csp->reg);
  								GenerateDiadic(op_fmov,'q',ap2,ap);
                            }
                            else {
                                ap = GenerateExpression(exptr,F_REG|F_IMMED|F_MEM,2);
    							ap2 = makereg(csp->reg);
    							if (ap->mode==am_immed) {
                                    GenLdi(ap2,ap);
                               }
    							else if (ap->mode==am_reg)
    								GenerateDiadic(op_mov,0,ap2,ap);
    							else {
    								size = GetNaturalSize(exptr);
    								ap->isUnsigned = exptr->isUnsigned;
    								GenLoad(ap2,ap,size,size);
    							}
                            }
                            ReleaseTempReg(ap);
                            }
                    }
            csp = csp->next;
            }
	return (popcnt(mask));
}


AMODE *GenExpr(ENODE *node)
{
	AMODE *ap1,*ap2,*ap3,*ap4;
	int lab0, lab1;
	int size;

    lab0 = nextlabel++;
    lab1 = nextlabel++;
/*
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
*/
	switch(node->nodetype) {
/*
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
		ap1 = GenerateExpression(node->p[0],F_REG, size);
		ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
		GenerateTriadic(op,0,ap1,ap1,ap2);
		ReleaseTempRegister(ap2);
		return ap1;
*/
	case en_chk:
		size = GetNaturalSize(node);
        ap4 = GetTempRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG,size);
		ap3 = GenerateExpression(node->p[2],F_REG|F_IMM0,size);
		if (ap3->mode == am_immed) {  // must be a zero
		   ap3->mode = am_reg;
		   ap3->preg = 0;
        }
   		Generate4adic(op_chk,0,ap4,ap1,ap2,ap3);
        ReleaseTempRegister(ap3);
        ReleaseTempRegister(ap2);
        ReleaseTempRegister(ap1);
        return ap4;
	}
    GenerateFalseJump(node,lab0,0);
    ap1 = GetTempRegister();
    GenerateDiadic(op_ld,0,ap1,make_immed(1));
    GenerateMonadic(op_bra,0,make_label(lab1));
    GenerateLabel(lab0);
    GenerateDiadic(op_ld,0,ap1,make_immed(0));
    GenerateLabel(lab1);
    return ap1;
}

void GenerateCmp(ENODE *node, int op, int label, int predreg)
{
	int size, sz;
	AMODE *ap1, *ap2;

	size = GetNaturalSize(node);
    if (op==op_flt || op==op_fle || op==op_fgt || op==op_fge || op==op_feq || op==op_fne) {
    	ap1 = GenerateExpression(node->p[0],F_FPREG,size);
	    ap2 = GenerateExpression(node->p[1],F_FPREG|F_IMM0,size);
    }
    else {
    	ap1 = GenerateExpression(node->p[0],F_REG, size);
	    ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
    }
	/*
	// Optimize CMP to zero and branch into plain branch, this works only for
	// signed relational compares.
	if (ap2->mode == am_immed && ap2->offset->i==0 && (op==op_eq || op==op_ne || op==op_lt || op==op_le || op==op_gt || op==op_ge)) {
    	switch(op)
    	{
    	case op_eq:	op = op_beq; break;
    	case op_ne:	op = op_bne; break;
    	case op_lt: op = op_blt; break;
    	case op_le: op = op_ble; break;
    	case op_gt: op = op_bgt; break;
    	case op_ge: op = op_bge; break;
    	}
    	ReleaseTempReg(ap3);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		GenerateDiadic(op,0,ap1,make_clabel(label));
		return;
	}
	*/
	/*
	if (op==op_ltu || op==op_leu || op==op_gtu || op==op_geu)
 	    GenerateTriadic(op_cmpu,0,ap3,ap1,ap2);
    else if (op==op_flt || op==op_fle || op==op_fgt || op==op_fge || op==op_feq || op==op_fne)
        GenerateTriadic(op_fdcmp,0,ap3,ap1,ap2);
	else 
 	    GenerateTriadic(op_cmp,0,ap3,ap1,ap2);
	*/
	sz = 0;
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
	case op_feq:	op = op_fbeq; sz = 'q'; break;
	case op_fne:	op = op_fbne; sz = 'q'; break;
	case op_flt:	op = op_fblt; sz = 'q'; break;
	case op_fle:	op = op_fble; sz = 'q'; break;
	case op_fgt:	op = op_fbgt; sz = 'q'; break;
	case op_fge:	op = op_fbge; sz = 'q'; break;
	/*
		GenerateTriadic(op_fcmp,'q',ap3,ap1,ap2);
		GenerateTriadic(op_bbs,0,ap3,make_immed(0),make_clabel(label));
		goto xit;
	case op_fne:
		GenerateTriadic(op_fcmp,'q',ap3,ap1,ap2);
		GenerateTriadic(op_bbc,0,ap3,make_immed(0),make_clabel(label));
		goto xit;
	case op_flt:
		GenerateTriadic(op_fcmp,'q',ap3,ap1,ap2);
		GenerateTriadic(op_bbs,0,ap3,make_immed(1),make_clabel(label));
		goto xit;
	case op_fle:
		GenerateTriadic(op_fcmp,'q',ap3,ap1,ap2);
		GenerateTriadic(op_bbs,0,ap3,make_immed(2),make_clabel(label));
		goto xit;
	case op_fgt:
		GenerateTriadic(op_fcmp,'q',ap3,ap1,ap2);
		GenerateTriadic(op_bbc,0,ap3,make_immed(2),make_clabel(label));
		goto xit;
	case op_fge:
		GenerateTriadic(op_fcmp,'q',ap3,ap1,ap2);
		GenerateTriadic(op_bbc,0,ap3,make_immed(1),make_clabel(label));
		goto xit;
	*/
	}
	if (op==op_fbne || op==op_fbeq || op==op_fblt || op==op_fble || op==op_fbgt || op==op_fbge) {
		if (ap2->mode==am_immed)
			GenerateTriadic(op,sz,ap1,makefpreg(0),make_clabel(label));
		else
			GenerateTriadic(op,sz,ap1,ap2,make_clabel(label));
	}
	else
		GenerateTriadic(op,sz,ap1,ap2,make_clabel(label));
   	ReleaseTempReg(ap2);
   	ReleaseTempReg(ap1);
}


static void GenerateDefaultCatch(SYM *sym)
{
	GenerateLabel(throwlab);
	if (sym->IsLeaf){
		if (sym->DoesThrow) {
			GenerateDiadic(op_lw,0,makereg(regLR),make_indexed(2,regBP));		// load throw return address from stack into LR
			GenerateDiadic(op_sw,0,makereg(regLR),make_indexed(4,regBP));		// and store it back (so it can be loaded with the lm)
			GenerateDiadic(op_bra,0,make_label(retlab),NULL);				// goto regular return cleanup code
		}
	}
	else {
		GenerateDiadic(op_lw,0,makereg(regLR),make_indexed(2,regBP));		// load throw return address from stack into LR
		GenerateDiadic(op_sw,0,makereg(regLR),make_indexed(4,regBP));		// and store it back (so it can be loaded with the lm)
		GenerateDiadic(op_bra,0,make_label(retlab),NULL);				// goto regular return cleanup code
	}
}

// Generate a function body.
//
void GenerateFunction(SYM *sym)
{
	char buf[200];
	AMODE *ap;
    int defcatch;
	int nn;
	Statement *stmt = sym->stmt;
	int lab0;
	int o_throwlab, o_retlab, o_contlab, o_breaklab;

	o_throwlab = throwlab;
	o_retlab = retlab;
	o_contlab = contlab;
	o_breaklab = breaklab;

	throwlab = retlab = contlab = breaklab = -1;
	lastsph = 0;
	memset(semaphores,0,sizeof(semaphores));
	throwlab = nextlabel++;
	defcatch = nextlabel++;
	lab0 = nextlabel++;
	while( lc_auto & 1 )	/* round frame size to word */
		++lc_auto;
	if (sym->IsInterrupt) {
       if (sym->stkname)
           GenerateDiadic(op_lea,0,makereg(SP),make_string(sym->stkname));
	   for (nn = 30; nn > 2; nn--)
		   GenerateMonadic(op_push,0,makereg(nn));
	}
	// The prolog code can't be optimized because it'll run *before* any variables
	// assigned to registers are available. About all we can do here is constant
	// optimizations.
	if (sym->prolog) {
		scan(sym->prolog);
	    GenerateStatement(sym->prolog);
	}
	if (!sym->IsNocall) {
		/*
		// For a leaf routine don't bother to store the link register.
		if (sym->IsLeaf) {
    		//GenerateTriadic(op_addi,0,makereg(regSP),makereg(regSP),make_immed(-4));
			if (exceptions)
				GenerateMonadic(op_push, 0, makereg(regXLR));
			GenerateMonadic(op_push,0,makereg(regBP));
        }
		else
		*/
		{
			if (exceptions)
				GenerateMonadic(op_push, 0, makereg(regXLR));
			GenerateMonadic(op_push, 0, makereg(regBP));
			ap = make_label(throwlab);
			ap->mode = am_immed;
			if (sym->IsLeaf && !sym->DoesThrow)
				;
			else if (exceptions)
				GenLdi(makereg(regXLR),ap);
		}
		GenerateDiadic(op_mov,0,makereg(regBP),makereg(regSP));
		//if (lc_auto)
		//	GenerateTriadic(op_subui,0,makereg(regSP),makereg(regSP),make_immed(lc_auto));
		snprintf(buf, sizeof(buf), "#%sSTKSIZE_",sym->mangledName->c_str());
		GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_string(my_strdup(buf)));
	}
	if (optimize)
		opt1(stmt);
    GenerateStatement(stmt);
    GenerateReturn(nullptr);
	if (exceptions && sym->IsInline)
		GenerateMonadic(op_bra,0,make_label(lab0));
	// Generate code for the hidden default catch
	if (exceptions)
		GenerateDefaultCatch(sym);
	if (exceptions && sym->IsInline)
		GenerateLabel(lab0);

	throwlab = o_throwlab;
	retlab = o_retlab;
	contlab = o_contlab;
	breaklab = o_breaklab;
}


// Unlink the stack
// For a leaf routine the link register and exception link register doesn't need to be saved/restored.

static void UnlinkStack(SYM * sym)
{
	GenerateDiadic(op_mov,0,makereg(regSP),makereg(regBP));
	GenerateMonadic(op_pop,0,makereg(regBP));
	if (exceptions)
		GenerateMonadic(op_pop,0,makereg(regXLR));
}


// Restore registers used as register variables.

static void RestoreRegisterVars()
{
	int cnt2, cnt;
	int nn;

	if( save_mask != 0 ) {
		cnt2 = cnt = bitsset(save_mask)*sizeOfWord;
		for (nn = 63; nn >=1 ; nn--) {
			if (save_mask & (1LL << nn)) {
				GenerateMonadic(op_pop,0,makereg(nn));
				cnt -= sizeOfWord;
			}
		}
	}
}

// Generate a return statement.
//
void GenerateReturn(Statement *stmt)
{
	AMODE *ap;
	int nn;
	int cnt,cnt2;
	int toAdd;
	SYM *sym = currentFn;

  // Generate the return expression and force the result into r1.
  if( stmt != NULL && stmt->exp != NULL )
  {
		initstack();
		ap = GenerateExpression(stmt->exp,F_REG|F_FPREG|F_IMMED,2);
		GenerateMonadic(op_hint,0,make_immed(2));
		if (ap->mode == am_immed)
		    GenLdi(makereg(1),ap);
		else if (ap->mode == am_reg) {
            if (sym->tp->GetBtp() && (sym->tp->GetBtp()->type==bt_struct || sym->tp->GetBtp()->type==bt_union)) {
                GenerateDiadic(op_lw,0,makereg(1),make_indexed(sym->parms->value.i,regBP));
                GenerateMonadic(op_push,0,make_immed(sym->tp->GetBtp()->size));
                GenerateMonadic(op_push,0,ap);
                GenerateMonadic(op_push,0,makereg(1));
                GenerateMonadic(op_call,0,make_string("_memcpy"));
                GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(6));
            }
            else
			    GenerateDiadic(op_mov, 0, makereg(1),ap);
        }
		else if (ap->mode == am_fpreg)
			GenerateDiadic(op_fdmov, 0, makefpreg(1),ap);
		else
		    GenLoad(makereg(1),ap,sizeOfWord,sizeOfWord);
		ReleaseTempRegister(ap);
	}

	// Generate the return code only once. Branch to the return code for all returns.
	if (retlab != -1) {
		GenerateMonadic(op_bra,0,make_label(retlab));
		return;
	}
	retlab = nextlabel++;
	GenerateLabel(retlab);
	// Unlock any semaphores that may have been set
	for (nn = lastsph - 1; nn >= 0; nn--)
		GenerateDiadic(op_sb,0,makereg(0),make_string(semaphores[nn]));
		
	// Restore fp registers used as register variables.
	if( fpsave_mask != 0 ) {
		cnt2 = cnt = (bitsset(fpsave_mask)-1)*sizeOfWord;
		for (nn = 63; nn >=1 ; nn--) {
			if (fpsave_mask & (1LL << nn)) {
				GenerateDiadic(op_lw,0,makefpreg(nn),make_indexed(cnt2-cnt,regSP));
				cnt -= sizeOfWord;
			}
		}
		GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(cnt2+2));
	}
	RestoreRegisterVars();
    if (sym->IsNocall) {
		if (sym->epilog) {
			GenerateStatement(sym->epilog);
			return;
		}
		return;
    }
	UnlinkStack(sym);
	toAdd = 2;

	if (sym->epilog) {
		GenerateStatement(sym->epilog);
		return;
	}
        
	// Generate the return instruction. For the Pascal calling convention pop the parameters
	// from the stack.
	if (sym->IsInterrupt) {
		for (nn = 3; nn < 31; nn++)
			GenerateMonadic(op_pop,0,makereg(nn));
		GenerateZeradic(op_iret);
		return;
	}

	// If Pascal calling convention remove parameters from stack by adding to stack pointer
	// based on the number of parameters. However if a non-auto register parameter is
	// present, then don't add to the stack pointer for it. (Remove the previous add effect).
	if (sym->IsPascal) {
		TypeArray *ta;
		int nn;
		ta = sym->GetProtoTypes();
		for (nn = 0; nn < ta->length; nn++) {
			switch(ta->types[nn]) {
			case bt_float:
			case bt_quad:
				if (ta->preg[nn] && (ta->preg[nn] & 0x8000)==0)
					;
				else
					toAdd += sizeOfWord * 4;
				break;
			case bt_double:
				if (ta->preg[nn] && (ta->preg[nn] & 0x8000)==0)
					;
				else
					toAdd += sizeOfWord * 2;
				break;
			case bt_triple:
				if (ta->preg[nn] && (ta->preg[nn] & 0x8000)==0)
					;
				else
					toAdd += sizeOfWord * 3;
				break;
			default:
				if (ta->preg[nn] && (ta->preg[nn] & 0x8000)==0)
					;
				else
					toAdd += sizeOfWord;
			}
		}
	}
	if (!sym->IsInline)
		GenerateMonadic(op_ret,0,make_immed(toAdd));
}

static int round4(int n)
{
    while(n & 3) n++;
    return (n);
};

static void SaveTemporaries(SYM *sym, int *sp, int *fsp)
{
	if (sym) {
		if (sym->UsesTemps) {
			*sp = TempInvalidate();
			*fsp = TempFPInvalidate();
		}
	}
	else {
		*sp = TempInvalidate();
		*fsp = TempFPInvalidate();
	}
}

static void RestoreTemporaries(SYM *sym, int sp, int fsp)
{
	if (sym) {
		if (sym->UsesTemps) {
			TempFPRevalidate(fsp);
			TempRevalidate(sp);
		}
	}
	else {
		TempFPRevalidate(fsp);
		TempRevalidate(sp);
	}
}

// Saves any registers used as parameters in the calling function.

static void SaveRegisterParameters(SYM *sym)
{
	TypeArray *ta;

	if (sym == nullptr)
		return;
	ta = sym->GetProtoTypes();
	if (ta) {
		int nn;
		for (nn = 0; nn < ta->length; nn++) {
			if (ta->preg[nn]) {
				switch(ta->types[nn]) {
				case bt_quad:	GenerateMonadic(op_push,'q',makefpreg(ta->preg[nn]& 0x7fff)); break;
				case bt_float:	GenerateMonadic(op_push,'s',makefpreg(ta->preg[nn]& 0x7fff)); break;
				case bt_double:	GenerateMonadic(op_push,'d',makefpreg(ta->preg[nn]& 0x7fff)); break;
				case bt_triple:	GenerateMonadic(op_push,'t',makefpreg(ta->preg[nn]& 0x7fff)); break;
				default:	GenerateMonadic(op_push,0,makereg(ta->preg[nn]& 0x7fff)); break;
				}
			}
		}
	}
}

static void RestoreRegisterParameters(SYM *sym)
{
	TypeArray *ta;

	if (sym == nullptr)
		return;
	ta = sym->GetProtoTypes();
	if (ta) {
		int nn;
		for (nn = ta->length - 1; nn >= 0; nn--) {
			if (ta->preg[nn]) {
				switch(ta->types[nn]) {
				case bt_quad:	GenerateMonadic(op_pop,'q',makefpreg(ta->preg[nn]& 0x7fff)); break;
				case bt_float:	GenerateMonadic(op_pop,'s',makefpreg(ta->preg[nn]& 0x7fff)); break;
				case bt_double:	GenerateMonadic(op_pop,'d',makefpreg(ta->preg[nn]& 0x7fff)); break;
				case bt_triple:	GenerateMonadic(op_pop,'t',makefpreg(ta->preg[nn]& 0x7fff)); break;
				default:	GenerateMonadic(op_pop,0,makereg(ta->preg[nn]& 0x7fff)); break;
				}
			}
		}
	}
}

// push the operand expression onto the stack.
// Structure variables are represented as an address in a register and arrive
// here as autocon nodes if on the stack. If the variable size is greater than
// 8 we assume a structure variable and we assume we have the address in a reg.
// Returns: number of stack words pushed.
//
static int GeneratePushParameter(ENODE *ep, int regno)
{    
	AMODE *ap;
	int nn = 0;
	
	if (ep->tp) {
		if (ep->tp->IsFloatType())
			ap = GenerateExpression(ep,F_FPREG,sizeOfWord);
		else
			ap = GenerateExpression(ep,F_REG|F_IMMED,sizeOfWord);
	}
	else if (ep->etype==bt_quad || ep->etype==bt_double || ep->etype==bt_float || ep->etype==bt_triple)
		ap = GenerateExpression(ep,F_FPREG,sizeOfWord);
	else
		ap = GenerateExpression(ep,F_REG|F_IMMED,sizeOfWord);
	switch(ap->mode) {
    case am_reg:
    case am_fpreg:
    case am_immed:
/*
        nn = round8(ep->esize); 
        if (nn > 8) {// && (ep->tp->type==bt_struct || ep->tp->type==bt_union)) {           // structure or array ?
            ap2 = GetTempRegister();
            GenerateTriadic(op_subui,0,makereg(regSP),makereg(regSP),make_immed(nn));
            GenerateDiadic(op_mov, 0, ap2, makereg(regSP));
            GenerateMonadic(op_push,0,make_immed(ep->esize));
            GenerateMonadic(op_push,0,ap);
            GenerateMonadic(op_push,0,ap2);
            GenerateMonadic(op_bsr,0,make_string("memcpy_"));
            GenerateTriadic(op_addui,0,makereg(regSP),makereg(regSP),make_immed(24));
          	GenerateMonadic(op_push,0,ap2);
            ReleaseTempReg(ap2);
            nn = nn >> 3;
        }
        else {
*/
			if (regno) {
				GenerateMonadic(op_hint,0,make_immed(1));
				if (ap->mode==am_immed) {
					GenerateDiadic(op_ld,0,makereg(regno & 0x7fff), ap);
					if (regno & 0x8000) {
						GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(sizeOfWord));
						nn = 1;
					}
				}
				else if (ap->mode==am_fpreg) {
					GenerateDiadic(op_fmov,0,makefpreg(regno & 0x7fff), ap);
					if (regno & 0x8000) {
						GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(sizeOfWord*4));
						nn = 4;
					}
				}
				else {
					GenerateDiadic(op_mov,0,makereg(regno & 0x7fff), ap);
					if (regno & 0x8000) {
						GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(sizeOfWord));
						nn = 1;
					}
				}
			}
			else {
				if (ap->isFloat) {
          			GenerateMonadic(op_push,'q',ap);
					nn = 4;
				}
				else {
          			GenerateMonadic(op_push,0,ap);
					nn = 1;
				}
			}
//        }
    	break;
    }
//	ReleaseTempReg(ap);
	return nn;
}

// push entire parameter list onto stack
//
static int GeneratePushParameterList(SYM *sym, ENODE *plist)
{
	TypeArray *ta = nullptr;
	int i,sum;

	sum = 0;
	if (sym)
		ta = sym->GetProtoTypes();

	for(i = 0; plist != NULL; i++ )
    {
		sum += GeneratePushParameter(plist->p[0],ta ? ta->preg[ta->length - i - 1] : 0);
		plist = plist->p[1];
    }
	if (ta)
		delete ta;
    return sum;
}

AMODE *GenerateFunctionCall(ENODE *node, int flags)
{ 
	AMODE *ap;
	SYM *sym;
	SYM *o_fn;
    int             i;
	int sp = 0;
	int fsp = 0;
	TypeArray *ta = nullptr;
	int64_t mask,fmask;

	sym = nullptr;

	// Call the function
	if( node->p[0]->nodetype == en_nacon || node->p[0]->nodetype == en_cnacon ) {
 		sym = gsearch(*node->p[0]->sp);
        i = 0;
		SaveTemporaries(sym, &sp, &fsp);
  /*
    	if ((sym->tp->GetBtp()->type==bt_struct || sym->tp->GetBtp()->type==bt_union) && sym->tp->GetBtp()->size > 8) {
            nn = tmpAlloc(sym->tp->GetBtp()->size) + lc_auto + round8(sym->tp->GetBtp()->size);
            GenerateMonadic(op_pea,0,make_indexed(-nn,regBP));
            i = 1;
        }
*/
		SaveRegisterParameters(sym);
        i = i + GeneratePushParameterList(sym,node->p[1]);
//		ReleaseTempRegister(ap);
		if (sym && sym->IsInline) {
			o_fn = currentFn;
			mask = save_mask;
			fmask = fpsave_mask;
			currentFn = sym;
			GenerateFunction(sym);
			currentFn = o_fn;
			fpsave_mask = fmask;
			save_mask = mask;
		}
		else
			GenerateMonadic(op_call,0,make_offset(node->p[0]));
	}
    else
    {
        i = 0;
    /*
    	if ((node->p[0]->tp->GetBtp()->type==bt_struct || node->p[0]->tp->GetBtp()->type==bt_union) && node->p[0]->tp->GetBtp()->size > 8) {
            nn = tmpAlloc(node->p[0]->tp->GetBtp()->size) + lc_auto + round8(node->p[0]->tp->GetBtp()->size);
            GenerateMonadic(op_pea,0,make_indexed(-nn,regBP));
            i = 1;
        }
     */
		ap = GenerateExpression(node->p[0],F_REG,sizeOfWord);
		if (ap->offset)
			sym = ap->offset->sym;
		SaveTemporaries(sym, &sp, &fsp);
		SaveRegisterParameters(sym);
        i = i + GeneratePushParameterList(sym,node->p[1]);
		ap->mode = am_ind;
		ap->offset = 0;
		if (sym && sym->IsInline) {
			o_fn = currentFn;
			mask = save_mask;
			fmask = fpsave_mask;
			currentFn = sym;
			GenerateFunction(sym);
			currentFn = o_fn;
			fpsave_mask = fmask;
			save_mask = mask;
		}
		else
			GenerateMonadic(op_call,0,ap);
		ReleaseTempRegister(ap);
    }
	// Pop parameters off the stack
	if (i!=0) {
		if (sym) {
			if (!sym->IsPascal)
				GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(i * sizeOfWord));
		}
		else
			GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(i * sizeOfWord));
	}
	RestoreRegisterParameters(sym);
	RestoreTemporaries(sym, sp, fsp);
	/*
	if (sym) {
	   if (sym->tp->type==bt_double)
           result = GetTempFPRegister();
	   else
           result = GetTempRegister();
    }
    else {
        if (node->etype==bt_double)
            result = GetTempFPRegister();
        else
            result = GetTempRegister();
    }
	*/
	if (flags & F_NOVALUE)
		;
	return (makereg(1));
	/*
	else {
		if( result->preg != 1 || (flags & F_REG) == 0 ) {
			if (sym) {
				if (sym->tp->GetBtp()->type==bt_void)
					;
				else {
                    if (sym->tp->type==bt_double)
					    GenerateDiadic(op_fdmov,0,result,makefpreg(1));
                    else
					    GenerateDiadic(op_mov,0,result,makereg(1));
                }
			}
			else {
                if (node->etype==bt_double)
      				GenerateDiadic(op_fdmov,0,result,makereg(1));
                else
		     		GenerateDiadic(op_mov,0,result,makereg(1));
            }
		}
	}
    return result;
	*/
}

void GenLdi(AMODE *ap1, AMODE *ap2)
{
	GenerateDiadic(op_ld,0,ap1,ap2);
  return;
}

