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

extern int     breaklab;
extern int     contlab;
extern int     retlab;
extern int		throwlab;

extern int lastsph;
extern char *semaphores[20];

extern TYP              stdfunc;

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
    int reg, mask, rmask;
    int fpreg, fpmask, fprmask;
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
    				if( csp->duses > csp->uses / 4 && fpreg < 18 )
    					csp->reg = fpreg++;
    				else
    					csp->reg = -1;
                }
                else {
    				if( csp->duses > csp->uses / 4 && reg < 18 )
    					csp->reg = reg++;
    				else
    					csp->reg = -1;
                }
			}
		}
		if (csp->isfp) {
            if( csp->reg != -1 )
    		{
    			fprmask = fprmask | (1 << (31 - csp->reg));
    			fpmask = fpmask | (1 << csp->reg);
    		}
        }
        else {
            if( csp->reg != -1 )
    		{
    			rmask = rmask | (1 << (31 - csp->reg));
    			mask = mask | (1 << csp->reg);
    		}
        }
        csp = csp->next;
    }
	if( mask != 0 ) {
		cnt = 0;
		//GenerateTriadic(op_subui,0,makereg(regSP),makereg(regSP),make_immed(bitsset(rmask)*8));
		for (nn = 0; nn < 32; nn++) {
			if (rmask & (0x80000000 >> nn)) {
				//GenerateDiadic(op_sw,0,makereg(nn&31),make_indexed(cnt,regSP));
				GenerateMonadic(op_push,0,makereg(nn&31));
				cnt+=8;
			}
		}
	}
	if( fpmask != 0 ) {
		cnt = 0;
		for (nn = 0; nn < 32; nn++) {
			if (fprmask & (0x80000000 >> nn)) {
				GenerateMonadic(op_push,0,makefpreg(nn&31));
				cnt+=8;
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
                                ap = GenerateExpression(exptr,F_FPREG,2);
    							ap2 = makefpreg(csp->reg);
  								GenerateDiadic(op_fdmov,0,ap2,ap);
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
	return popcnt(mask);
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
    GenerateDiadic(op_ldi,0,ap1,make_immed(1));
    GenerateMonadic(op_bra,0,make_label(lab1));
    GenerateLabel(lab0);
    GenerateDiadic(op_ldi,0,ap1,make_immed(0));
    GenerateLabel(lab1);
    return ap1;
}

void GenerateCmp(ENODE *node, int op, int label, int predreg)
{
	int size;
	AMODE *ap1, *ap2, *ap3;

	size = GetNaturalSize(node);
    if (op==op_flt || op==op_fle || op==op_fgt || op==op_fge || op==op_feq || op==op_fne) {
    	ap1 = GenerateExpression(node->p[0],F_FPREG,size);
	    ap2 = GenerateExpression(node->p[1],F_FPREG,size);
    }
    else {
    	ap1 = GenerateExpression(node->p[0],F_REG, size);
	    ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
    }
	ap3 = GetTempRegister();
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
	case op_feq:
         op = op_beq;
         break;
	case op_fne:
         op = op_bne;
         break;
	case op_flt:
         op = op_blt;
         break;
	case op_fle:
         op = op_ble;
         break;
	case op_fgt:
         op = op_bgt;
         break;
	case op_fge:
         op = op_bge;
         break;
	}
	GenerateTriadic(op,0,ap1,ap2,make_clabel(label));
	ReleaseTempReg(ap3);
   	ReleaseTempReg(ap2);
   	ReleaseTempReg(ap1);
}


// Generate a function body.
//
void GenerateFunction(SYM *sym, Statement *stmt)
{
	char buf[200];
	AMODE *ap;
    int defcatch;
 
	throwlab = retlab = contlab = breaklab = -1;
	lastsph = 0;
	memset(semaphores,0,sizeof(semaphores));
	throwlab = nextlabel++;
	defcatch = nextlabel++;
	while( lc_auto & 1 )	/* round frame size to word */
		++lc_auto;
	if (sym->IsInterrupt) {
       if (sym->stkname)
           GenerateDiadic(op_lea,0,makereg(SP),make_string(sym->stkname));
       GenerateMonadic(op_push,0,makereg(1));
       GenerateMonadic(op_push,0,makereg(2));
       GenerateMonadic(op_push,0,makereg(3));
       GenerateMonadic(op_push,0,makereg(4));
       GenerateMonadic(op_push,0,makereg(5));
       GenerateMonadic(op_push,0,makereg(6));
       GenerateMonadic(op_push,0,makereg(7));
       GenerateMonadic(op_push,0,makereg(8));
       GenerateMonadic(op_push,0,makereg(9));
       GenerateMonadic(op_push,0,makereg(10));
       GenerateMonadic(op_push,0,makereg(11));
       GenerateMonadic(op_push,0,makereg(12));
       GenerateMonadic(op_push,0,makereg(13));
       GenerateMonadic(op_push,0,makereg(14));
       GenerateMonadic(op_push,0,makereg(15));
       GenerateMonadic(op_push,0,makereg(16));
       GenerateMonadic(op_push,0,makereg(17));
       GenerateMonadic(op_push,0,makereg(18));
       GenerateMonadic(op_push,0,makereg(19));
       GenerateMonadic(op_push,0,makereg(20));
       GenerateMonadic(op_push,0,makereg(21));
       GenerateMonadic(op_push,0,makereg(22));
       GenerateMonadic(op_push,0,makereg(23));
       GenerateMonadic(op_push,0,makereg(25));
       GenerateMonadic(op_push,0,makereg(26));
       GenerateMonadic(op_push,0,makereg(27));
       GenerateMonadic(op_push,0,makereg(28));
       GenerateMonadic(op_push,0,makereg(29));
       GenerateMonadic(op_push,0,makereg(31));
	}
	if (sym->prolog) {
       if (optimize)
           opt1(sym->prolog);
	   GenerateStatement(sym->prolog);
    }
	if (!sym->IsNocall) {
		// For a leaf routine don't bother to store the link register or exception link register.
		if (sym->IsLeaf) {
    		//GenerateTriadic(op_addi,0,makereg(regSP),makereg(regSP),make_immed(-4));
			GenerateMonadic(op_push,0,makereg(regBP));
        }
		else {
			GenerateMonadic(op_push, 0, makereg(regLR));
			if (exceptions)
				GenerateMonadic(op_push, 0, makereg(regXLR));
			GenerateMonadic(op_push, 0, makereg(regBP));
			ap = make_label(throwlab);
			ap->mode = am_immed;
			if (exceptions)
				GenLdi(makereg(regXLR),ap);
		}
		GenerateDiadic(op_mov,0,makereg(regBP),makereg(regSP));
		//if (lc_auto)
		//	GenerateTriadic(op_subui,0,makereg(regSP),makereg(regSP),make_immed(lc_auto));
		snprintf(buf, sizeof(buf), "#%sSTKSIZE_",sym->mangledName->c_str());
		GenerateTriadic(op_subi,0,makereg(regSP),makereg(regSP),make_string(my_strdup(buf)));
	}
	if (optimize)
		opt1(stmt);
    GenerateStatement(stmt);
    GenerateReturn(0);
	// Generate code for the hidden default catch
	if (exceptions) {
		GenerateLabel(throwlab);
		if (sym->IsLeaf){
			if (sym->DoesThrow) {
				GenerateDiadic(op_mov,0,makereg(regLR),makereg(regXLR));
				GenerateDiadic(op_bra,0,make_label(retlab),NULL);				// goto regular return cleanup code
			}
		}
		else {
			GenerateDiadic(op_lw,0,makereg(regLR),make_indexed(2,regBP));		// load throw return address from stack into LR
			GenerateDiadic(op_sw,0,makereg(regLR),make_indexed(4,regBP));		// and store it back (so it can be loaded with the lm)
			GenerateDiadic(op_bra,0,make_label(retlab),NULL);				// goto regular return cleanup code
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
                GenerateMonadic(op_call,0,make_string("memcpy_"));
                GenerateTriadic(op_addi,0,makereg(regSP),makereg(regSP),make_immed(12));                                                                
            }
            else

			    GenerateDiadic(op_mov, 0, makereg(1),ap);
        }
		else if (ap->mode == am_fpreg)
			GenerateDiadic(op_fdmov, 0, makefpreg(1),ap);
		else
		    GenLoad(makereg(1),ap,2,2);
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
		
        if (sym->IsNocall) {	// nothing to do for nocall convention
			return;
        }
		// Restore fp registers used as register variables.
		if( fpsave_mask != 0 ) {
			cnt2 = cnt = (bitsset(fpsave_mask)-1)*2;
			for (nn = 31; nn >=1 ; nn--) {
				if (fpsave_mask & (1 << nn)) {
					GenerateDiadic(op_lw,0,makefpreg(nn),make_indexed(cnt,regSP));
					cnt -= 2;
				}
			}
			GenerateTriadic(op_addi,0,makereg(regSP),makereg(regSP),make_immed(cnt2));
		}
		// Restore registers used as register variables.
		if( save_mask != 0 ) {
			cnt2 = cnt = (bitsset(save_mask)-1)*2;
			for (nn = 31; nn >=1 ; nn--) {
				if (save_mask & (1 << nn)) {
					GenerateDiadic(op_lw,0,makereg(nn),make_indexed(cnt,regSP));
					cnt -= 2;
				}
			}
			GenerateTriadic(op_addi,0,makereg(regSP),makereg(regSP),make_immed(cnt2));
		}
		// Unlink the stack
		// For a leaf routine the link register and exception link register doesn't need to be saved/restored.
		GenerateDiadic(op_mov,0,makereg(regSP),makereg(regBP));
		if (sym->IsLeaf) {
			GenerateDiadic(op_lw,0,makereg(regBP),make_indirect(regSP));
			toAdd = 2;
        }
		else {
			GenerateDiadic(op_lw,0,makereg(regBP),make_indirect(regSP));
			if (exceptions)
				GenerateDiadic(op_lw,0,makereg(regXLR),make_indexed(2,regSP));
			GenerateDiadic(op_lw,0,makereg(regLR),make_indexed(exceptions ?4:2,regSP));
			toAdd = GetReturnBlockSize();
		}
		    if (sym->epilog) {
               if (optimize)
                  opt1(sym->epilog);
		       GenerateStatement(sym->epilog);
		       return;
           }
        
		// Generate the return instruction. For the Pascal calling convention pop the parameters
		// from the stack.
		if (sym->IsInterrupt) {
            GenerateMonadic(op_pop,0,makereg(31));
            GenerateMonadic(op_pop,0,makereg(29));
            GenerateMonadic(op_pop,0,makereg(28));
            GenerateMonadic(op_pop,0,makereg(27));
            GenerateMonadic(op_pop,0,makereg(26));
            GenerateMonadic(op_pop,0,makereg(25));
            GenerateMonadic(op_pop,0,makereg(23));
            GenerateMonadic(op_pop,0,makereg(22));
            GenerateMonadic(op_pop,0,makereg(21));
            GenerateMonadic(op_pop,0,makereg(20));
            GenerateMonadic(op_pop,0,makereg(19));
            GenerateMonadic(op_pop,0,makereg(18));
            GenerateMonadic(op_pop,0,makereg(17));
            GenerateMonadic(op_pop,0,makereg(16));
            GenerateMonadic(op_pop,0,makereg(15));
            GenerateMonadic(op_pop,0,makereg(14));
            GenerateMonadic(op_pop,0,makereg(13));
            GenerateMonadic(op_pop,0,makereg(12));
            GenerateMonadic(op_pop,0,makereg(11));
            GenerateMonadic(op_pop,0,makereg(10));
            GenerateMonadic(op_pop,0,makereg(9));
            GenerateMonadic(op_pop,0,makereg(8));
            GenerateMonadic(op_pop,0,makereg(7));
            GenerateMonadic(op_pop,0,makereg(6));
            GenerateMonadic(op_pop,0,makereg(5));
            GenerateMonadic(op_pop,0,makereg(4));
            GenerateMonadic(op_pop,0,makereg(3));
            GenerateMonadic(op_pop,0,makereg(2));
            GenerateMonadic(op_pop,0,makereg(1));
			GenerateMonadic(op_rti,0,NULL);
			return;
		}
		if (sym->IsPascal) {
			GenerateTriadic(op_addi,0,makereg(regSP),makereg(regSP),make_immed(toAdd+sym->NumParms * 2));
		}
		else {
			if (toAdd != 0)
				GenerateTriadic(op_addi,0,makereg(regSP),makereg(regSP),make_immed(toAdd));
		}
        GenerateZeradic(op_ret,0);
    }
	// Just branch to the already generated stack cleanup code.
	else {
		GenerateMonadic(op_bra,0,make_label(retlab));
	}
}

static int round4(int n)
{
    while(n & 3) n++;
    return n;
};

// push the operand expression onto the stack.
// Structure variables are represented as an address in a register and arrive
// here as autocon nodes if on the stack. If the variable size is greater than
// 8 we assume a structure variable and we assume we have the address in a reg.
// Returns: number of stack words pushed.
//
static int GeneratePushParameter(ENODE *ep, int regno)
{    
	AMODE *ap;
	int nn;
	
	ap = GenerateExpression(ep,F_REG|F_FPREG|F_IMMED,2);
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
				if (ap->mode==am_immed)
					GenerateDiadic(op_ldi,0,makereg(regno), ap);
				else
					GenerateDiadic(op_mov,0,makereg(regno), ap);
				GenerateTriadic(op_subi,0,makereg(regSP),makereg(regSP),make_immed(2));
			}
			else
          		GenerateMonadic(op_push,0,ap);
          	nn = 1;
//        }
    	break;
    }
	ReleaseTempReg(ap);
	return nn;
}

// push entire parameter list onto stack
//
static int GeneratePushParameterList(SYM *sym, ENODE *plist)
{
	int i;
	int sum;
	TypeArray *ta = nullptr;

    sum = 0;
	if (sym)
		ta = sym->GetProtoTypes();
    for(i = 0; plist != NULL; i++ )
    {
		sum += GeneratePushParameter(plist->p[0],ta ? ta->preg[i] : 0);
		plist = plist->p[1];
    }
    return sum;
}

AMODE *GenerateFunctionCall(ENODE *node, int flags)
{ 
	AMODE *ap, *result;
	SYM *sym;
    int             i,j;
	int sp = 0;
	int fsp = 0;

	sp = TempInvalidate();
	fsp = TempFPInvalidate();
	sym = NULL;

	// Call the function
	if( node->p[0]->nodetype == en_nacon || node->p[0]->nodetype == en_cnacon ) {
 /*
        ap = GetTempRegister();
        ap2 = make_offset(node->p[0]);
        a1 = copy_addr(ap2);
        a2 = copy_addr(ap2);
        a3 = copy_addr(ap2);
        a4 = copy_addr(ap2);
        a1->rshift = 0;
        a2->rshift = 16;
        a3->rshift = 32;
        a4->rshift = 48;
        a1->mode = am_immed;
        a2->mode = am_immed;
        a3->mode = am_immed;
        a4->mode = am_immed;
        GenerateDiadic(op_lc0i,0,ap,a1);
        GenerateDiadic(op_lc1i,0,ap,a2);
        GenerateDiadic(op_lc2i,0,ap,a3);
        GenerateDiadic(op_lc3i,0,ap,a4);
        //GenerateDiadic(op_jal,0,makereg(regLR),make_offset(node->p[0]));
        GenerateDiadic(op_jal,0,makereg(regLR),make_indirect(ap->preg));
*/
		sym = gsearch(*node->p[0]->sp);
        j = i = 0;
  /*
    	if ((sym->tp->GetBtp()->type==bt_struct || sym->tp->GetBtp()->type==bt_union) && sym->tp->GetBtp()->size > 8) {
            nn = tmpAlloc(sym->tp->GetBtp()->size) + lc_auto + round8(sym->tp->GetBtp()->size);
            GenerateMonadic(op_pea,0,make_indexed(-nn,regBP));
            i = 1;
        }
*/
        i = i + GeneratePushParameterList(sym, node->p[1]);
//		ReleaseTempRegister(ap);
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
		ap = GenerateExpression(node->p[0],F_REG,2);
		if (ap->offset)
			sym = ap->offset->sym;
		i = i + GeneratePushParameterList(sym,node->p[1]);
		ap->mode = am_ind;
		ap->offset = 0;
		GenerateMonadic(op_call,0,ap);
		ReleaseTempRegister(ap);
    }
	// Pop parameters off the stack
	if (i!=0) {
		if (sym) {
			if (!sym->IsPascal)
				GenerateTriadic(op_addi,0,makereg(regSP),makereg(regSP),make_immed(i * 2));
		}
		else
			GenerateTriadic(op_addi,0,makereg(regSP),makereg(regSP),make_immed(i * 2));
	}
	TempFPRevalidate(fsp);
	TempRevalidate(sp);
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
	if (flags & F_NOVALUE)
		;
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
}

void GenLdi(AMODE *ap1, AMODE *ap2)
{
	GenerateDiadic(op_ldi,0,ap1,ap2);
  return;
}

