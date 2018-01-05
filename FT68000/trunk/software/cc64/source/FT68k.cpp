// ============================================================================
// (C) 2017-2018 Robert Finch
// All Rights Reserved.
// robfinch<remove>@finitron.ca
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

extern int lastsph;
extern char *semaphores[20];
extern int throwlab;
extern int breaklab;
extern int contlab;
extern int retlab;

extern TYP              stdfunc;

extern void DumpCSETable();
extern void scan(Statement *);
extern int GetReturnBlockSize();
void GenerateReturn(Statement *stmt);
extern void GenerateComment(char *);
int TempFPInvalidate();
int TempInvalidate();
void TempRevalidate(int);
void TempFPRevalidate(int);
void ReleaseTempRegister(AMODE *ap);
AMODE *GetTempRegister();
void GenLdi(AMODE *, AMODE *);
extern AMODE *copy_addr(AMODE *ap);
extern void GenLoad(AMODE *ap1, AMODE *ap3, int ssize, int size);
extern int rqsort(void *, unsigned int, unsigned int, int (*)(const void *, const void *));
extern void shell_sort(__int8 *base, size_t nel, size_t elsize, int (*cmp)(const void *, const void *));
//
// Returns the desirability of optimization for a subexpression.
//
int OptimizationDesireability(CSE *csp)
{
	if (csp->exp == nullptr)
		return (0);
	if( csp->voidf || (csp->exp->nodetype == en_icon &&
                       csp->exp->i < 32768 && csp->exp->i >= -32768))
        return 0;
    if (csp->exp->nodetype==en_cnacon)
        return 0;
	if (csp->exp->isVolatile)
		return 0;
	// Prevent Inline code from being allocated a pointer in a register.
	if (csp->exp->sym) {
		if (csp->exp->sym->IsInline)
			return (0);
	}
    if( IsLValue(csp->exp) )
	    return 2 * csp->uses;
    return csp->uses;
}

int CSECmp(const void *a, const void *b)
{
	CSE *csp1, *csp2;
	int aa,bb;

	csp1 = (CSE *)a;
	csp2 = (CSE *)b;
	aa = OptimizationDesireability(csp1);
	bb = OptimizationDesireability(csp2);
	if (aa < bb)
		return (1);
	else if (aa == bb)
		return (0);
	else
		return (-1);
}

static void AllocateRegisters()
{
	int nn,csecnt;
	CSE *csp;
	int addrreg;
	int datareg;

	datareg = 3;
	addrreg = 10;
	for (nn = 0; nn < 3; nn++) {
		for (csecnt = 0; csecnt < csendx; csecnt++)	{
			csp = &CSETable[csecnt];
			if (csp->reg==-1) {
				if( OptimizationDesireability(csp) >= 4-nn ) {
					if (csp->duses > csp->uses / 4 && addrreg < 13)
						csp->reg = addrreg++;
    				else if (datareg < 8 )
    					csp->reg = datareg++;
    				else
    					csp->reg = -1;
				}
			}
		}
	}
}

// ----------------------------------------------------------------------------
// AllocateRegisterVars will allocate registers for the expressions that have
// a high enough desirability.
// ----------------------------------------------------------------------------

int AllocateRegisterVars()
{
	CSE *csp;
    ENODE *exptr;
    int reg, vreg;
	uint64_t mask, rmask;
    uint64_t fpmask, fprmask;
	uint64_t vmask, vrmask;
    AMODE *ap, *ap2;
	int64_t nn;
	int cnt;
	int size;
	int csecnt;

	reg = regFirstRegvar;
    mask = 0;
	rmask = 0;
	fpmask = 0;
	fprmask = 0;

	// Sort the CSE table according to desirability of allocating
	// a register.
	dfs.printf("Before QSort:%d\n",csendx);
	DumpCSETable();
	qsort(CSETable,(size_t)csendx,sizeof(CSE),CSECmp);
	dfs.printf("After QSort\n");
	DumpCSETable();

	// Initialize to no allocated registers
	for (csecnt = 0; csecnt < csendx; csecnt++)
		CSETable[csecnt].reg = -1;

	// Make multiple passes over the CSE table in order to use
	// up all temporary registers. Allocates on the progressively
	// less desirable.
	AllocateRegisters();

	// Generate bit masks of allocated registers
	for (csecnt = 0; csecnt < csendx; csecnt++) {
		csp = &CSETable[csecnt];
		if( csp->reg != -1 )
    	{
    		rmask = rmask | (1LL << (63 - csp->reg));
    		mask = mask | (1LL << csp->reg);
    	}
	}

	DumpCSETable();

	// Push temporaries on the stack.
	if( mask != 0 ) {
		cnt = 0;
		for (nn = 0; nn < 64; nn++) {
			if (rmask & (0x8000000000000000ULL >> nn)) {
				GenerateDiadic(op_move,'l',nn > 7 ? make_areg(nn-8) : make_dreg(nn), make_adec(7));
				cnt+=sizeOfWord;
			}
		}
	}

    save_mask = mask;
    fpsave_mask = fpmask;
    csp = olist;

	// Initialize temporaries
	for (csecnt = 0; csecnt < csendx; csecnt++) {
		csp = &CSETable[csecnt];
        if( csp->reg != -1 )
        {               // see if preload needed
            exptr = csp->exp;
            if(1 || !IsLValue(exptr) || (exptr->p[0]->i > 0) || (exptr->nodetype==en_struct_ref))
            {
                initstack();
				{
                    ap = GenerateExpression(exptr,F_AREG|F_DREG|F_IMMED|F_MEM,sizeOfWord);
					if (csp->reg > 7)
						ap2 = make_areg(csp->reg - 8);
					else
    					ap2 = make_dreg(csp->reg);
					/*
    				if (ap->mode==am_immed)
						GenerateDiadic(op_move,'l',ap,ap2);
    				else if (ap->mode==am_areg || ap->mode==am_dreg)
    					GenerateDiadic(op_move,'l',ap,ap2);
    				else
					*/
					{
    					size = GetNaturalSize(exptr);
    					ap->isUnsigned = exptr->isUnsigned;
    					GenLoad(ap,ap2,size,size);
    				}
                }
                ReleaseTempReg(ap);
            }
        }
    }
	return (popcnt(mask));
}


AMODE *GenExpr(ENODE *node)
{
	AMODE *ap1,*ap2,*ap3,*ap4;
	int lab0, lab1;
	int size;
	int op;

    lab0 = nextlabel++;
    lab1 = nextlabel++;

	switch(node->nodetype) {
	case en_eq:		op = op_seq;	break;
	case en_ne:		op = op_sne;	break;
	case en_lt:		op = op_slt;	break;
	case en_ult:	op = op_slo;	break;
	case en_le:		op = op_sle;	break;
	case en_ule:	op = op_sls;	break;
	case en_gt:		op = op_sgt;	break;
	case en_ugt:	op = op_shi;	break;
	case en_ge:		op = op_sge;	break;
	case en_uge:	op = op_shs;	break;
	default:	// en_land, en_lor
		//ap1 = GetTempRegister();
		//ap2 = GenerateExpression(node,F_REG,8);
		//GenerateDiadic(op_redor,0,ap1,ap2);
		//ReleaseTempReg(ap2);
		GenerateFalseJump(node,lab0,0);
		ap1 = GetTempDataReg();
		GenerateDiadic(op_move,'l',make_immed(1),ap1);
		GenerateMonadic(op_bra,0,make_label(lab1));
		GenerateLabel(lab0);
		GenerateDiadic(op_move,'l',make_immed(0),ap1);
		GenerateLabel(lab1);
		return (ap1);
	}

	switch(node->nodetype) {
	case en_eq:
		size = GetNaturalSize(node);
		ap1 = GenerateExpression(node->p[0],F_AREG|F_DREG,size);
		ap2 = GenerateExpression(node->p[1],F_AREG|F_DREG|F_IMMED,size);
		GenerateDiadic(op_cmp,size,ap2,ap1);
		GenerateMonadic(op_seq,0,ap1);
		ReleaseTempRegister(ap2);
		return (ap1);
	case en_ne:
		size = GetNaturalSize(node);
		ap1 = GenerateExpression(node->p[0],F_AREG|F_DREG,size);
		ap2 = GenerateExpression(node->p[1],F_AREG|F_DREG|F_IMMED,size);
		GenerateDiadic(op_cmp,size,ap2,ap1);
		GenerateMonadic(op_sne,0,ap1);
		ReleaseTempRegister(ap2);
		return (ap1);
	case en_lt:
		size = GetNaturalSize(node);
		ap1 = GenerateExpression(node->p[0],F_AREG|F_DREG,size);
		ap2 = GenerateExpression(node->p[1],F_AREG|F_DREG|F_IMMED,size);
		GenerateDiadic(op_cmp,size,ap2,ap1);
		GenerateMonadic(op_slt,0,ap1);
		ReleaseTempRegister(ap2);
		return (ap1);
	case en_le:
		size = GetNaturalSize(node);
		ap1 = GenerateExpression(node->p[0],F_AREG|F_DREG,size);
		ap2 = GenerateExpression(node->p[1],F_AREG|F_DREG|F_IMMED,size);
		GenerateDiadic(op_cmp,size,ap2,ap1);
		GenerateMonadic(op_sle,0,ap1);
		ReleaseTempRegister(ap2);
		return (ap1);
	case en_gt:
		size = GetNaturalSize(node);
		ap1 = GenerateExpression(node->p[0],F_AREG|F_DREG,size);
		ap2 = GenerateExpression(node->p[1],F_AREG|F_DREG|F_IMMED,size);
		GenerateDiadic(op_cmp,size,ap2,ap1);
		GenerateMonadic(op_sgt,0,ap1);
		ReleaseTempRegister(ap2);
		return (ap1);
	case en_ge:
		size = GetNaturalSize(node);
		ap1 = GenerateExpression(node->p[0],F_AREG|F_DREG,size);
		ap2 = GenerateExpression(node->p[1],F_AREG|F_DREG|F_IMMED,size);
		GenerateDiadic(op_cmp,size,ap2,ap1);
		GenerateMonadic(op_sge,0,ap1);
		ReleaseTempRegister(ap2);
		return (ap1);
	case en_ult:
		size = GetNaturalSize(node);
		ap1 = GenerateExpression(node->p[0],F_AREG|F_DREG,size);
		ap2 = GenerateExpression(node->p[1],F_AREG|F_DREG|F_IMMED,size);
		GenerateDiadic(op_cmp,size,ap2,ap1);
		GenerateMonadic(op_slo,0,ap1);
		ReleaseTempRegister(ap2);
		return (ap1);
	case en_ule:
		size = GetNaturalSize(node);
		ap1 = GenerateExpression(node->p[0],F_AREG|F_DREG,size);
		ap2 = GenerateExpression(node->p[1],F_AREG|F_DREG|F_IMMED,size);
		GenerateDiadic(op_cmp,size,ap2,ap1);
		GenerateMonadic(op_sls,0,ap1);
		ReleaseTempRegister(ap2);
		return (ap1);
	case en_ugt:
		size = GetNaturalSize(node);
		ap1 = GenerateExpression(node->p[0],F_AREG|F_DREG,size);
		ap2 = GenerateExpression(node->p[1],F_AREG|F_DREG|F_IMMED,size);
		GenerateDiadic(op_cmp,size,ap2,ap1);
		GenerateMonadic(op_shi,0,ap1);
		ReleaseTempRegister(ap2);
		return (ap1);
	case en_uge:
		size = GetNaturalSize(node);
		ap1 = GenerateExpression(node->p[0],F_AREG|F_DREG,size);
		ap2 = GenerateExpression(node->p[1],F_AREG|F_DREG|F_IMMED,size);
		GenerateDiadic(op_cmp,size,ap2,ap1);
		GenerateMonadic(op_shs,0,ap1);
		ReleaseTempRegister(ap2);
		return (ap1);
/*
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
        ap4 = GetTempDataReg();
		/*
		size = GetNaturalSize(node);
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
		*/
        return (ap4);
	}
	size = GetNaturalSize(node);
	ap1 = GenerateExpression(node->p[0],F_DREG,size);
	ap2 = GenerateExpression(node->p[1],F_DREG|F_IMMED,size);
	GenerateDiadic(op_cmp,size,ap2,ap1);
	GenerateMonadic(op,0,ap1);
    ReleaseTempRegister(ap2);
    return (ap1);
	/*
    GenerateFalseJump(node,lab0,0);
    ap1 = GetTempRegister();
    GenerateDiadic(op_ld,0,ap1,make_immed(1));
    GenerateMonadic(op_bra,0,make_label(lab1));
    GenerateLabel(lab0);
    GenerateDiadic(op_ld,0,ap1,make_immed(0));
    GenerateLabel(lab1);
    return ap1;
	*/
}

void GenCompareI(AMODE *ap1, AMODE *ap2)
{
	AMODE *ap4;

	/*
	if (ap2->offset->i < -32768LL || ap2->offset->i > 32767LL) {
		ap4 = GetTempRegister();
		GenerateDiadic(op_ldi,0,ap4,make_immed(ap2->offset->i));
		
		if (ap2->offset->i & 0xFFFF0000LL)
			GenerateDiadic(op_orq1,0,ap4,make_immed((ap2->offset->i >> 16) & 0xFFFFLL));
		if (ap2->offset->i & 0xFFFF00000000LL)
			GenerateDiadic(op_orq2,0,ap4,make_immed((ap2->offset->i >> 32) & 0xFFFFLL));
		if (ap2->offset->i & 0xFFFF000000000000LL)
			GenerateDiadic(op_orq3,0,ap4,make_immed((ap2->offset->i >> 48) & 0xFFFFLL));
		
		GenerateTriadic(su ? op_cmp : op_cmpu,0,ap3,ap1,ap4);
		ReleaseTempReg(ap4);
	}
	else */
		GenerateDiadic(op_cmp,0,ap1,ap2);
}

void GenerateCmp(ENODE *node, int op, int label, int predreg, unsigned int prediction)
{
	int size, sz;
	AMODE *ap1, *ap2, *ap3;

	size = GetNaturalSize(node);
    if (op==op_flt || op==op_fle || op==op_fgt || op==op_fge || op==op_feq || op==op_fne) {
    	ap1 = GenerateExpression(node->p[0],F_REG,size);
	    ap2 = GenerateExpression(node->p[1],F_REG|F_IMM0,size);
    }
    else {
    	ap1 = GenerateExpression(node->p[0],F_DREG, size);
	    ap2 = GenerateExpression(node->p[1],F_DREG|F_IMMED,size);
    }
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
	case op_feq:	op = op_fbeq; sz = 'd'; break;
	case op_fne:	op = op_fbne; sz = 'd'; break;
	case op_flt:	op = op_fblt; sz = 'd'; break;
	case op_fle:	op = op_fble; sz = 'd'; break;
	case op_fgt:	op = op_fbgt; sz = 'd'; break;
	case op_fge:	op = op_fbge; sz = 'd'; break;
	}
	if (op==op_fbne || op==op_fbeq || op==op_fblt || op==op_fble || op==op_fbgt || op==op_fbge) {
		switch(op) {
		case op_fbne:
			if (ap2->mode==am_immed) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_fbne,sz,ap1,ap3,make_clabel(label));
			}
			else
				GenerateTriadic(op_fbne,sz,ap1,ap2,make_clabel(label));
			break;
		case op_fbeq:
			if (ap2->mode==am_immed) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_fbeq,sz,ap1,ap3,make_clabel(label));
			}
			else
				GenerateTriadic(op_fbeq,sz,ap1,ap2,make_clabel(label));
			break;
		case op_fblt:
			if (ap2->mode==am_immed) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_fblt,sz,ap1,ap3,make_clabel(label));
			}
			else
				GenerateTriadic(op_fblt,sz,ap1,ap2,make_clabel(label));
			break;
		case op_fble:
			if (ap2->mode==am_immed) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_fbge,sz,ap3,ap1,make_clabel(label));
			}
			else
				GenerateTriadic(op_fbge,sz,ap2,ap1,make_clabel(label));
			break;
		case op_fbgt:
			if (ap2->mode==am_immed) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_fblt,sz,ap3,ap1,make_clabel(label));
			}
			else
				GenerateTriadic(op_fblt,sz,ap2,ap1,make_clabel(label));
			break;
		case op_fbge:
			if (ap2->mode==am_immed) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_fbge,sz,ap1,ap3,make_clabel(label));
			}
			else
				GenerateTriadic(op_fbge,sz,ap1,ap2,make_clabel(label));
			break;
		}
	}
	else {
		switch(op) {
		case op_beq:
			GenerateDiadic(op_cmp,'l',ap2,ap1);
			GenerateMonadic(op_beq,0,make_clabel(label));
			break;
		case op_bne:
			GenerateDiadic(op_cmp,'l',ap2,ap1);
			GenerateMonadic(op_bne,0,make_clabel(label));
			break;
		case op_blt:
			GenerateDiadic(op_cmp,'l',ap2,ap1);
			GenerateMonadic(op_blt,0,make_clabel(label));
			break;
		case op_ble:
			GenerateDiadic(op_cmp,'l',ap2,ap1);
			GenerateMonadic(op_bge,0,make_clabel(label));
			break;
		case op_bgt:
			GenerateDiadic(op_cmp,'l',ap2,ap1);
			GenerateMonadic(op_blt,0,make_clabel(label));
			break;
		case op_bge:
			GenerateDiadic(op_cmp,'l',ap2,ap1);
			GenerateMonadic(op_bge,0,make_clabel(label));
			break;
		case op_bltu:
			GenerateDiadic(op_cmp,'l',ap2,ap1);
			GenerateMonadic(op_blo,0,make_clabel(label));
			break;
		case op_bleu:
			GenerateDiadic(op_cmp,'l',ap2,ap1);
			GenerateMonadic(op_bls,0,make_clabel(label));
			break;
		case op_bgtu:
			GenerateDiadic(op_cmp,'l',ap2,ap1);
			GenerateMonadic(op_bhi,0,make_clabel(label));
			break;
		case op_bgeu:
			GenerateDiadic(op_cmp,'l',ap2,ap1);
			GenerateMonadic(op_bhs,0,make_clabel(label));
			break;
		}
		//GenerateTriadic(op,sz,ap1,ap2,make_clabel(label));
	}
   	ReleaseTempReg(ap2);
   	ReleaseTempReg(ap1);
}


static void GenerateDefaultCatch(SYM *sym)
{
	GenerateLabel(throwlab);
	if (sym->IsLeaf){
		if (sym->DoesThrow) {
			GenerateDiadic(op_move,'l',make_indexed(sizeOfWord,regBP),make_indexed(sizeOfWord*2,regBP));
			GenerateDiadic(op_bra,0,make_label(retlab),NULL);				// goto regular return cleanup code
		}
	}
	else {
		GenerateDiadic(op_move,'l',make_indexed(sizeOfWord,regBP),make_indexed(sizeOfWord*2,regBP));
		GenerateDiadic(op_bra,0,make_label(retlab),NULL);
	}
}

// Generate a function body.
//
void GenerateFunction(SYM *sym)
{
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
	//GenerateZeradic(op_calltgt);
	while( lc_auto & 1 )	/* round frame size to word */
		++lc_auto;
	if (sym->IsInterrupt) {
       if (sym->stkname)
           GenerateDiadic(op_lea,0,make_areg(regSP),make_string(sym->stkname));
	   if (sym->tp->GetBtp()->type!=bt_void)
		   GenerateDiadic(op_movem,'l',make_immed(0x7FFE),make_adec(regSP));
	   else	// push everything but sp
		   GenerateDiadic(op_movem,'l',make_immed(0xFFFE),make_adec(regSP));
	}
	// The prolog code can't be optimized because it'll run *before* any variables
	// assigned to registers are available. About all we can do here is constant
	// optimizations.
	if (sym->prolog) {
		scan(sym->prolog);
	    sym->prolog->Generate();
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
			if (exceptions) {
				if (!sym->IsLeaf || sym->DoesThrow)
					GenerateDiadic(op_move, 'l', make_areg(regXLR), make_adec(7));
			}
			//GenerateMonadic(op_push, 0, makereg(regBP));
			ap = make_label(throwlab);
			ap->mode = am_immed;
			if (sym->IsLeaf && !sym->DoesThrow)
				;
			else if (exceptions)
				GenLdi(ap,make_areg(regXLR));
		}
		// The stack doesn't need to be linked if there is no stack space in use and there
		// are no parameters passed to the function. Since function parameters are
		// referenced to the BP register the stack needs to be linked if there are any.
		// Stack link/unlink is optimized away by the peephole optimizer if they aren't
		// needed. So they are just always spit out here.
//			snprintf(buf, sizeof(buf), "#-%sSTKSIZE_-8",sym->mangledName->c_str());
		GenerateDiadic(op_link,0,make_areg(regBP),make_immed(sym->stkspace));//make_string(my_strdup(buf)));
	}
	if (optimize)
		opt1(stmt);
    stmt->Generate();
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
	GenerateMonadic(op_unlk,0,make_areg(regBP));
	if (exceptions) {
		if (!sym->IsLeaf || sym->DoesThrow) {
			GenerateDiadic(op_move,'l',make_ainc(7),make_areg(regXLR));
		}
	}
}


// Restore registers used as register variables.

static void RestoreRegisterVars()
{
	int cnt2, cnt;
	int nn;

	if( save_mask != 0 ) {
		cnt2 = cnt = bitsset(save_mask)*sizeOfWord;
		for (nn = 31; nn >=1 ; nn--) {
			if (save_mask & (1LL << nn)) {
				GenerateDiadic(op_move,'l',make_ainc(7),nn > 7 ? make_areg(nn-8):make_dreg(nn));
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
	SYM *p;

  // Generate the return expression and force the result into d0.
  if( stmt != NULL && stmt->exp != NULL )
  {
		initstack();
		if (sym->tp->GetBtp() && sym->tp->GetBtp()->IsFloatType())
			ap = GenerateExpression(stmt->exp,F_REG,sizeOfFP);
		else
			ap = GenerateExpression(stmt->exp,F_DREG|F_IMMED,sizeOfWord);
		GenerateMonadic(op_hint,0,make_immed(2));
		if (ap->mode == am_immed)
			GenerateDiadic(op_move,'l',ap,make_dreg(0));
		else if (ap->mode == am_areg) {
            if (sym->tp->GetBtp() && (sym->tp->GetBtp()->type==bt_struct || sym->tp->GetBtp()->type==bt_union)) {
				p = sym->params.Find("_pHiddenStructPtr",false);
				if (p) {
					if (p->IsRegister)
						GenerateDiadic(op_move,'l',p->reg > 7 ? make_areg(p->reg& 7) : make_dreg(p->reg),make_dreg(0));
					else
						GenerateDiadic(op_move,'l',make_indexed(p->value.i,regBP),make_dreg(0));
					GenerateDiadic(op_move,'l',make_immed(sym->tp->GetBtp()->size),make_adec(7));
					GenerateDiadic(op_move,'l',ap,make_adec(7));
					GenerateDiadic(op_move,'l',make_dreg(0),make_adec(7));	// push d0
					GenerateMonadic(op_jsr,0,make_string("_memcpy"));
					GenerateDiadic(op_add,'l',make_immed(sizeOfWord*3),make_areg(regSP));
				}
				else {
					// ToDo compiler error
				}
            }
            else {
				GenerateDiadic(op_move, 'l', ap, make_dreg(0));
			}
        }
		else if (ap->mode == am_fpreg)
			GenerateDiadic(op_move, 'l', ap, make_dreg(0));
		else if (ap->type==stddouble.GetIndex()) {
			GenerateDiadic(op_move,'l',ap,make_dreg(0));
		}
		else {
			GenLoad(make_dreg(0),ap,sizeOfWord,sizeOfWord);
		}
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
		GenerateMonadic(op_clr,'b',make_string(semaphores[nn]));
		
	// Restore fp registers used as register variables.
	if( fpsave_mask != 0 ) {
		cnt2 = cnt = (bitsset(fpsave_mask)-1)*sizeOfFP;
		for (nn = 31; nn >=1 ; nn--) {
			if (fpsave_mask & (1LL << nn)) {
				//GenerateDiadic(op_lw,0,makereg(nn),make_indexed(cnt2-cnt,regSP));
				cnt -= sizeOfWord;
			}
		}
		GenerateDiadic(op_adda,'l',make_immed(cnt2+sizeOfFP),make_areg(regSP));
	}
	RestoreRegisterVars();
    if (sym->IsNocall) {
		if (sym->epilog) {
			sym->epilog->Generate();
			return;
		}
		return;
    }
	UnlinkStack(sym);
	toAdd = sizeOfWord;

	if (sym->epilog) {
		sym->epilog->Generate();
		return;
	}
        
	// Generate the return instruction. For the Pascal calling convention pop the parameters
	// from the stack.
	if (sym->IsInterrupt) {
		if (sym->tp->GetBtp()->type!=bt_void)	// pop everything but d0,a7
			GenerateDiadic(op_movem,'l',make_ainc(7),make_immed(0x7FFE));
		else	// pop everything but a7
			GenerateDiadic(op_movem,'l',make_ainc(7),make_immed(0x7FFF));
		GenerateZeradic(op_rte);
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
					toAdd += sizeOfFPQ;
				break;
			case bt_double:
				if (ta->preg[nn] && (ta->preg[nn] & 0x8000)==0)
					;
				else
					toAdd += sizeOfFPD;
				break;
			case bt_triple:
				if (ta->preg[nn] && (ta->preg[nn] & 0x8000)==0)
					;
				else
					toAdd += sizeOfFPT;
				break;
			default:
				if (ta->preg[nn] && (ta->preg[nn] & 0x8000)==0)
					;
				else
					toAdd += sizeOfWord;
			}
		}
	}
	if (!sym->IsInline) {
		if (toAdd != 4) {
			GenerateDiadic(op_move,'l',make_indirect(7),make_indexed(toAdd,7));
		}
		GenerateZeradic(op_rts);
	}
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
			//*fsp = TempFPInvalidate();
		}
	}
	else {
		*sp = TempInvalidate();
		//*fsp = TempFPInvalidate();
	}
}

static void RestoreTemporaries(SYM *sym, int sp, int fsp)
{
	if (sym) {
		if (sym->UsesTemps) {
			//TempFPRevalidate(fsp);
			TempRevalidate(sp);
		}
	}
	else {
		//TempFPRevalidate(fsp);
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
				default:	GenerateDiadic(op_move,'l',ta->preg[nn]& 0x7fff > 7 ? make_areg(ta->preg[nn]& 0x7) : make_dreg(ta->preg[nn] & 7),make_adec(7)); break;
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
				//case bt_quad:	GenerateMonadic(op_pop,0,makereg(ta->preg[nn]& 0x7fff)); break;
				//case bt_float:	GenerateMonadic(op_pop,0,makereg(ta->preg[nn]& 0x7fff)); break;
				//case bt_double:	GenerateMonadic(op_pop,0,makereg(ta->preg[nn]& 0x7fff)); break;
				//case bt_triple:	GenerateMonadic(op_pop,0,makereg(ta->preg[nn]& 0x7fff)); break;
				default:	GenerateDiadic(op_move,'l',make_ainc(7),
								ta->preg[nn] & 0x7fff > 7 ? make_areg(ta->preg[nn] & 7) :
								make_dreg(ta->preg[nn]& 0x7)); break;
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
static int GeneratePushParameter(ENODE *ep, int regno, int stkoffs)
{    
	AMODE *ap;
	int nn = 0;
	int sz;
	
	switch(ep->etype) {
	case bt_quad:	sz = sizeOfFPD; break;
	case bt_triple:	sz = sizeOfFPT; break;
	case bt_double:	sz = sizeOfFPD; break;
	case bt_float:	sz = sizeOfFPD; break;
	default:	sz = sizeOfWord; break;
	}
	if (ep->tp) {
		if (ep->tp->IsFloatType())
			ap = GenerateExpression(ep,F_REG,sizeOfFP);
		else
			ap = GenerateExpression(ep,F_AREG|F_DREG|F_IMMED,sizeOfWord);
	}
	else if (ep->etype==bt_quad)
		ap = GenerateExpression(ep,F_REG,sz);
	else if (ep->etype==bt_double)
		ap = GenerateExpression(ep,F_REG,sz);
	else if (ep->etype==bt_float)
		ap = GenerateExpression(ep,F_REG,sz);
	else
		ap = GenerateExpression(ep,F_AREG|F_DREG|F_IMMED,sz);
	switch(ap->mode) {
    //case am_reg:
	case am_areg:
	case am_dreg:
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
					GenerateDiadic(op_move,'l',ap,regno&0x7fff >7 ? make_areg(regno & 0x7): make_dreg(regno & 7));
					if (regno & 0x8000) {
						GenerateDiadic(op_sub,0,make_immed(sizeOfWord),make_areg(regSP));
						nn = 1;
					}
				}
				else if (ap->mode==am_fpreg) {
					GenerateDiadic(op_move,'l',ap,regno&0x7fff >7 ? make_areg(regno & 0x7): make_dreg(regno & 7));
					if (regno & 0x8000) {
						GenerateDiadic(op_sub,0,make_immed(sz),make_areg(regSP));
						nn = sz/sizeOfWord;
					}
				}
				else {
					//ap->preg = regno & 0x7fff;
					GenerateDiadic(op_move,'l',ap,regno&0x7fff >7 ? make_areg(regno & 0x7): make_dreg(regno & 7));
					if (regno & 0x8000) {
						GenerateDiadic(op_sub,0,make_immed(sizeOfWord),make_areg(regSP));
						nn = 1;
					}
				}
			}
			else {
				if (ap->mode==am_immed) {	// must have been a zero
         			GenerateDiadic(op_move,'l',ap,make_adec(7));
					nn = 1;
				}
				else {
					if (ap->type==stddouble.GetIndex()) {
						GenerateMonadic(op_move,ap->FloatSize,ap);
						nn = sz/sizeOfWord;
					}
					else {
						GenerateDiadic(op_move,'l',ap,make_adec(7));
          				//GenerateMonadic(op_push,0,ap);
						nn = 1;
					}
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
	struct ocode *ip;

	sum = 0;
	if (sym)
		ta = sym->GetProtoTypes();

	ip = peep_tail;
	for(i = 0; plist != NULL; i++ )
    {
		sum += GeneratePushParameter(plist->p[0],ta ? ta->preg[ta->length - i - 1] : 0,sum*sizeOfWord);
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
		if (currentFn->HasRegisterParameters())
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
			GenerateMonadic(op_jsr,0,make_offset(node->p[0]));
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
		ap = GenerateExpression(node->p[0],F_DREG,sizeOfWord);
		if (ap->offset)
			sym = ap->offset->sym;
		SaveTemporaries(sym, &sp, &fsp);
		if (currentFn->HasRegisterParameters())
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
			GenerateMonadic(op_jsr,0,ap);
		ReleaseTempRegister(ap);
    }
	// Pop parameters off the stack
	if (i!=0) {
		if (sym) {
			if (!sym->IsPascal)
				GenerateDiadic(op_adda,'l',make_immed(i * sizeOfWord),make_areg(regSP));
		}
		else
			GenerateDiadic(op_adda,'l',make_immed(i * sizeOfWord),make_areg(regSP));
	}
	if (currentFn->HasRegisterParameters())
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
	if (sym && sym->tp && sym->tp->GetBtp()->IsFloatType() && (flags & F_FPREG))
		return (make_dreg(0));
	return (make_dreg(0));
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
	GenerateDiadic(op_move,'l',ap1,ap2);
	return;
}

