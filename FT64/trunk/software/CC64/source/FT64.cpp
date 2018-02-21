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
static void SaveRegisterVars(int64_t mask, int64_t rmask);
static void SaveFPRegisterVars(int64_t fpmask, int64_t fprmask);
int TempFPInvalidate();
int TempInvalidate();
void TempRevalidate(int,int);
void TempFPRevalidate(int);
void ReleaseTempRegister(AMODE *ap);
AMODE *GetTempRegister();
void GenLdi(AMODE *, AMODE *);
extern AMODE *copy_addr(AMODE *ap);
extern void GenLoad(AMODE *ap1, AMODE *ap3, int ssize, int size);

static int CSECmp(const void *a, const void *b)
{
	CSE *csp1, *csp2;
	int aa,bb;

	csp1 = (CSE *)a;
	csp2 = (CSE *)b;
	aa = csp1->OptimizationDesireability();
	bb = csp2->OptimizationDesireability();
	if (aa < bb)
		return (1);
	else if (aa == bb)
		return (0);
	else
		return (-1);
}

static int AllocateRegisters1(int *dregr)
{
	int nn,csecnt,reg,dreg;
	CSE *csp;

	reg = regFirstRegvar;
	dreg = regFirstRegvar;
	for (nn = 0; nn < 3; nn++) {
		for (csecnt = 0; csecnt < csendx; csecnt++)	{
			csp = &CSETable[csecnt];
			if (csp->reg==-1) {
				if( csp->OptimizationDesireability() >= 4-nn ) {
					if (csp->isfp) {
						if (dreg <= regLastRegvar)
    						csp->reg = dreg++;
					}
					else if (csp->exp->etype!=bt_vector) {
//    					if(( csp->duses > csp->uses / (8 << nn)) && reg < regLastRegvar )	// <- address register assignments
						if (reg <= regLastRegvar)
    						csp->reg = reg++;
					}
				}
			}
		}
	}
	*dregr = dreg;
	return reg;
}

static int FinalAllocateRegisters(int reg, int dreg)
{
	int csecnt;
	CSE *csp;

	for (csecnt = 0; csecnt < csendx; csecnt++)	{
		csp = &CSETable[csecnt];
		if (csp->OptimizationDesireability() != 0) {
			if (!csp->voidf && csp->reg==-1) {
				if (csp->isfp) {
    				if(( csp->OptimizationDesireability() >= 4) && dreg < regLastRegvar )
    					csp->reg = dreg++;
    				else
    					csp->reg = -1;
				}
				else if (csp->exp->etype!=bt_vector) {
    				if(( csp->OptimizationDesireability() >= 4) && reg < regLastRegvar )
    					csp->reg = reg++;
    				else
    					csp->reg = -1;
				}
			}
		}
	}
	return reg;
}

static int AllocateVectorRegisters1()
{
	int nn,csecnt,vreg;
	CSE *csp;

	vreg = 11;
	for (nn = 0; nn < 3; nn++) {
		for (csecnt = 0; csecnt < csendx; csecnt++)	{
			csp = &CSETable[csecnt];
			if (csp->reg==-1) {
				if( csp->OptimizationDesireability() >= 4-nn ) {
					if (csp->exp->etype==bt_vector) {
    					if(( csp->duses > csp->uses / (8 << nn)) && vreg < 18 )
    						csp->reg = vreg++;
    					else
    						csp->reg = -1;
					}
				}
			}
		}
	}
	return vreg;
}

static int FinalAllocateVectorRegisters(int vreg)
{
	int csecnt;
	CSE *csp;

	vreg = 11;
	for (csecnt = 0; csecnt < csendx; csecnt++)	{
		csp = &CSETable[csecnt];
		if (!csp->voidf && csp->reg==-1) {
			if (csp->exp->etype==bt_vector) {
    			if(( csp->uses > 3) && vreg < 18 )
    				csp->reg = vreg++;
    			else
    				csp->reg = -1;
			}
		}
	}
	return vreg;
}

// ----------------------------------------------------------------------------
// AllocateRegisterVars will allocate registers for the expressions that have
// a high enough desirability.
// ----------------------------------------------------------------------------

int AllocateRegisterVars()
{
	CSE *csp;
    ENODE *exptr;
    int reg, dreg, vreg;
	uint64_t mask, rmask;
    uint64_t fpmask, fprmask;
	uint64_t vmask, vrmask;
    AMODE *ap, *ap2, *ap3;
	int size;
	int csecnt;

	reg = regFirstRegvar;
	dreg = regFirstRegvar;
	vreg = 11;
    mask = 0;
	rmask = 0;
	fpmask = 0;
	fprmask = 0;
	vmask = 0;
	vrmask = 0;

	// Sort the CSE table according to desirability of allocating
	// a register.
	if (pass==1)
		qsort(CSETable,(size_t)csendx,sizeof(CSE),CSECmp);

	// Initialize to no allocated registers
	for (csecnt = 0; csecnt < csendx; csecnt++)
		CSETable[csecnt].reg = -1;

	// Make multiple passes over the CSE table in order to use
	// up all temporary registers. Allocates on the progressively
	// less desirable.
	reg = AllocateRegisters1(&dreg);
	vreg = AllocateVectorRegisters1();
	if (reg < regLastRegvar)
		reg = FinalAllocateRegisters(reg,dreg);
	if (vreg < 18)
		vreg = FinalAllocateVectorRegisters(vreg);

	// Generate bit masks of allocated registers
	for (csecnt = 0; csecnt < csendx; csecnt++) {
		csp = &CSETable[csecnt];
		if (csp->exp->isDouble) {
			if( csp->reg != -1 )
    		{
    			fprmask = fprmask | (1LL << (63 - csp->reg));
    			fpmask = fpmask | (1LL << csp->reg);
    		}
		}
		else if (csp->exp->etype==bt_vector) {
			if( csp->reg != -1 )
    		{
    			vrmask = vrmask | (1LL << (63 - csp->reg));
    			vmask = vmask | (1LL << csp->reg);
    		}
		}
		else {
			if( csp->reg != -1 )
    		{
    			rmask = rmask | (1LL << (63 - csp->reg));
    			mask = mask | (1LL << csp->reg);
    		}
		}
	}

	DumpCSETable();

	// Push temporaries on the stack.
	SaveRegisterVars(mask, rmask);
	SaveFPRegisterVars(fpmask, fprmask);

    save_mask = mask;
    fpsave_mask = fpmask;

	// Initialize temporaries
	for (csecnt = 0; csecnt < csendx; csecnt++) {
		csp = &CSETable[csecnt];
        if( csp->reg != -1 )
        {               // see if preload needed
            exptr = csp->exp;
            if( 1 || !IsLValue(exptr) || (exptr->p[0]->i > 0) || (exptr->nodetype==en_struct_ref))
            {
                initstack();
				{
                    ap = GenerateExpression(exptr,F_REG|F_IMMED|F_MEM|F_FPREG,sizeOfWord);
					ap2 = csp->isfp ? makefpreg(csp->reg) : makereg(csp->reg);
    				if (ap->mode==am_immed) {
						if (ap2->mode==am_fpreg) {
							ap3 = GetTempRegister();
							GenLdi(ap3,ap);
							GenerateDiadic(op_mov,0,ap2,ap3);
							ReleaseTempReg(ap3);
						}
						else
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
	case en_ult:	op = op_sltu;	break;
	case en_le:		op = op_sle;	break;
	case en_ule:	op = op_sleu;	break;
	case en_gt:		op = op_sgt;	break;
	case en_ugt:	op = op_sgtu;	break;
	case en_ge:		op = op_sge;	break;
	case en_uge:	op = op_sgeu;	break;
	case en_veq:
		size = GetNaturalSize(node);
		ap3 = GetTempVectorRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG,size);
		GenerateTriadic(op_vseq,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	case en_vne:
		size = GetNaturalSize(node);
		ap3 = GetTempVectorRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG,size);
		GenerateTriadic(op_vsne,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	case en_vlt:
		size = GetNaturalSize(node);
		ap3 = GetTempVectorRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG,size);
		GenerateTriadic(op_vslt,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	case en_vle:
		size = GetNaturalSize(node);
		ap3 = GetTempVectorRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG,size);
		GenerateTriadic(op_vsle,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	case en_vgt:
		size = GetNaturalSize(node);
		ap3 = GetTempVectorRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG,size);
		GenerateTriadic(op_vsgt,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	case en_vge:
		size = GetNaturalSize(node);
		ap3 = GetTempVectorRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG,size);
		GenerateTriadic(op_vsge,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	default:	// en_land, en_lor
		//ap1 = GetTempRegister();
		//ap2 = GenerateExpression(node,F_REG,8);
		//GenerateDiadic(op_redor,0,ap1,ap2);
		//ReleaseTempReg(ap2);
		GenerateFalseJump(node,lab0,0);
		ap1 = GetTempRegister();
		GenerateDiadic(op_ldi,0,ap1,make_immed(1));
		GenerateMonadicNT(op_bra,0,make_label(lab1));
		GenerateLabel(lab0);
		GenerateDiadic(op_ldi,0,ap1,make_immed(0));
		GenerateLabel(lab1);
		return ap1;
	}

	switch(node->nodetype) {
	case en_eq:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
		GenerateTriadic(op_cmp,0,ap3,ap1,ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		GenerateDiadic(op_not,0,ap3,ap3);
		return (ap3);
	case en_ne:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
		GenerateTriadic(op_cmp,0,ap3,ap1,ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		return (ap3);
	case en_lt:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
		GenerateTriadic(op_cmp,0,ap3,ap1,ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		GenerateDiadic(op_slt,0,ap3,ap3);
		return (ap3);
	case en_le:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
		GenerateTriadic(op_cmp,0,ap3,ap1,ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		GenerateDiadic(op_sle,0,ap3,ap3);
		return (ap3);
	case en_gt:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
		GenerateTriadic(op_cmp,0,ap3,ap1,ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		GenerateDiadic(op_sgt,0,ap3,ap3);
		return (ap3);
	case en_ge:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
		GenerateTriadic(op_cmp,0,ap3,ap1,ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		GenerateDiadic(op_sge,0,ap3,ap3);
		return (ap3);
	case en_ult:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
		GenerateTriadic(op_cmpu,0,ap3,ap1,ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		GenerateDiadic(op_slt,0,ap3,ap3);
		return (ap3);
	case en_ule:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
		GenerateTriadic(op_cmpu,0,ap3,ap1,ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		GenerateDiadic(op_sle,0,ap3,ap3);
		return (ap3);
	case en_ugt:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
		GenerateTriadic(op_cmpu,0,ap3,ap1,ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		GenerateDiadic(op_sgt,0,ap3,ap3);
		return (ap3);
	case en_uge:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
		GenerateTriadic(op_cmpu,0,ap3,ap1,ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		GenerateDiadic(op_sge,0,ap3,ap3);
		return (ap3);
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
	size = GetNaturalSize(node);
    ap3 = GetTempRegister();         
	ap1 = GenerateExpression(node->p[0],F_REG,size);
	ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
	GenerateTriadic(op,0,ap3,ap1,ap2);
    ReleaseTempRegister(ap2);
    ReleaseTempRegister(ap1);
    return ap3;
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

void GenCompareI(AMODE *ap3, AMODE *ap1, AMODE *ap2, int su)
{
	GenerateTriadic(su ? op_cmp : op_cmpu,0,ap3,ap1,ap2);
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
	case op_feq:	op = op_fbeq; sz = 'd'; break;
	case op_fne:	op = op_fbne; sz = 'd'; break;
	case op_flt:	op = op_fblt; sz = 'd'; break;
	case op_fle:	op = op_fble; sz = 'd'; break;
	case op_fgt:	op = op_fbgt; sz = 'd'; break;
	case op_fge:	op = op_fbge; sz = 'd'; break;
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
		switch(op) {
		case op_fbne:
			if (ap2->mode==am_immed) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadicNT(op_fbne,sz,ap1,ap3,make_clabel(label));
			}
			else
				GenerateTriadicNT(op_fbne,sz,ap1,ap2,make_clabel(label));
			break;
		case op_fbeq:
			if (ap2->mode==am_immed) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadicNT(op_fbeq,sz,ap1,ap3,make_clabel(label));
			}
			else
				GenerateTriadicNT(op_fbeq,sz,ap1,ap2,make_clabel(label));
			break;
		case op_fblt:
			if (ap2->mode==am_immed) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadicNT(op_fblt,sz,ap1,ap3,make_clabel(label));
			}
			else
				GenerateTriadicNT(op_fblt,sz,ap1,ap2,make_clabel(label));
			break;
		case op_fble:
			if (ap2->mode==am_immed) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadicNT(op_fbge,sz,ap3,ap1,make_clabel(label));
			}
			else
				GenerateTriadicNT(op_fbge,sz,ap2,ap1,make_clabel(label));
			break;
		case op_fbgt:
			if (ap2->mode==am_immed) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadicNT(op_fblt,sz,ap3,ap1,make_clabel(label));
			}
			else
				GenerateTriadicNT(op_fblt,sz,ap2,ap1,make_clabel(label));
			break;
		case op_fbge:
			if (ap2->mode==am_immed) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadicNT(op_fbge,sz,ap1,ap3,make_clabel(label));
			}
			else
				GenerateTriadicNT(op_fbge,sz,ap1,ap2,make_clabel(label));
			break;
		}
	}
	else {
		switch(op) {
		case op_beq:
			if (ap2->mode==am_immed && ap2->offset->nodetype==en_icon && ap2->offset->i >= -256 && ap2->offset->i <=255) {
				GenerateTriadicNT(op_beqi,0,ap1,ap2,make_clabel(label));
			}
			else if (ap2->mode==am_immed) {
				ap3 = GetTempRegister();
				GenCompareI(ap3,ap1,ap2,1);
				ReleaseTempRegister(ap3);
				Generate4adicNT(op_beq,0,ap3,makereg(0),make_clabel(label),make_immed(prediction));
			}
			else
				Generate4adicNT(op_beq,0,ap1,ap2,make_clabel(label), make_immed(prediction));
			break;
		case op_bne:
			if (ap2->mode==am_immed) {
				if (ap2->offset->i == 0)
					GenerateTriadicNT(op_bne,0,ap1,makereg(0),make_clabel(label));
				else {
					ap3 = GetTempRegister();
					GenCompareI(ap3,ap1,ap2,1);
					ReleaseTempRegister(ap3);
					Generate4adicNT(op_bne,0,ap3,makereg(0),make_clabel(label), make_immed(prediction));
				}
			}
			else {
				Generate4adicNT(op_bne,0,ap1,ap2,make_clabel(label), make_immed(prediction));
			}
			break;
		case op_blt:
			if (ap2->mode==am_immed) {
				if (ap2->offset->i == 0)
					GenerateTriadicNT(op_blt,0,ap1,makereg(0),make_clabel(label));
				else {
					ap3 = GetTempRegister();
					GenCompareI(ap3,ap1,ap2,1);
					ReleaseTempRegister(ap3);
					Generate4adicNT(op_blt,0,ap3,makereg(0),make_clabel(label), make_immed(prediction));
				}
			}
			else
				Generate4adicNT(op_blt,0,ap1,ap2,make_clabel(label), make_immed(prediction));
			break;
		case op_ble:
			if (ap2->mode==am_immed) {
				if (ap2->offset->i == 0)
					GenerateTriadicNT(op_bge,0,makereg(0),ap1,make_clabel(label));
				else {
					ap3 = GetTempRegister();
					GenCompareI(ap3,ap1,ap2,1);
					ReleaseTempRegister(ap3);
					Generate4adicNT(op_bge,0,makereg(0),ap3,make_clabel(label), make_immed(prediction));
				}
			}
			else
				Generate4adicNT(op_bge,0,ap2,ap1,make_clabel(label), make_immed(prediction));
			break;
		case op_bgt:
			if (ap2->mode==am_immed) {
				if (ap2->offset->i == 0)
					GenerateTriadicNT(op_blt,0,makereg(0),ap1,make_clabel(label));
				else {
					ap3 = GetTempRegister();
					GenCompareI(ap3,ap1,ap2,1);
					ReleaseTempRegister(ap3);
					Generate4adicNT(op_blt,0,makereg(0),ap3,make_clabel(label), make_immed(prediction));
				}
			}
			else
				Generate4adicNT(op_blt,0,ap2,ap1,make_clabel(label), make_immed(prediction));
			break;
		case op_bge:
			if (ap2->mode==am_immed) {
				if (ap2->offset->i==0) {
					GenerateTriadicNT(op_bge,0,ap1,makereg(0),make_clabel(label));
				}
				else {
					ap3 = GetTempRegister();
					GenCompareI(ap3,ap1,ap2,1);
					ReleaseTempRegister(ap3);
					Generate4adicNT(op_bge,0,ap3,makereg(0),make_clabel(label), make_immed(prediction));
				}
			}
			else
				Generate4adicNT(op_bge,0,ap1,ap2,make_clabel(label), make_immed(prediction));
			break;
		case op_bltu:
			if (ap2->mode==am_immed) {
				// Don't generate any code if testing against unsigned zero.
				// An unsigned number can't be less than zero so the branch will
				// always be false. Spit out a warning, its probably coded wrong.
				if (ap2->offset->i == 0)
					error(ERR_UBLTZ);	//GenerateTriadic(op_bltu,0,ap1,makereg(0),make_clabel(label));
				else {
					ap3 = GetTempRegister();
					GenCompareI(ap3,ap1,ap2,0);
					ReleaseTempRegister(ap3);
					Generate4adicNT(op_blt,0,ap3,makereg(0),make_clabel(label), make_immed(prediction));
				}
			}
			else
				Generate4adicNT(op_bltu,0,ap1,ap2,make_clabel(label), make_immed(prediction));
			break;
		case op_bleu:
			if (ap2->mode==am_immed) {
				if (ap2->offset->i == 0)
					GenerateTriadicNT(op_bgeu,0,makereg(0),ap1,make_clabel(label));
				else {
					ap3 = GetTempRegister();
					GenCompareI(ap3,ap1,ap2,0);
					ReleaseTempRegister(ap3);
					Generate4adicNT(op_bge,0,makereg(0),ap3,make_clabel(label), make_immed(prediction));
				}
			}
			else
				Generate4adicNT(op_bgeu,0,ap2,ap1,make_clabel(label), make_immed(prediction));
			break;
		case op_bgtu:
			if (ap2->mode==am_immed) {
				if (ap2->offset->i == 0)
					GenerateTriadicNT(op_bltu,0,makereg(0),ap1,make_clabel(label));
				else {
					ap3 = GetTempRegister();
					GenCompareI(ap3,ap1,ap2,0);
					ReleaseTempRegister(ap3);
					Generate4adicNT(op_blt,0,makereg(0),ap3,make_clabel(label), make_immed(prediction));
				}
			}
			else
				Generate4adicNT(op_bltu,0,ap2,ap1,make_clabel(label), make_immed(prediction));
			break;
		case op_bgeu:
			if (ap2->mode==am_immed) {
				if (ap2->offset->i == 0) {
					// This branch is always true
					error(ERR_UBGEQ);
					Generate4adicNT(op_bgeu,0,ap1,makereg(0),make_clabel(label), make_immed(prediction));
				}
				else {
					ap3 = GetTempRegister();
					GenCompareI(ap3,ap1,ap2,0);
					ReleaseTempRegister(ap3);
					Generate4adicNT(op_bge,0,ap3,makereg(0),make_clabel(label), make_immed(prediction));
				}
			}
			else
				GenerateTriadicNT(op_bgeu,0,ap1,ap2,make_clabel(label));
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
			GenerateDiadic(op_lw,0,makereg(regLR),make_indexed(2*sizeOfWord,regFP));		// load throw return address from stack into LR
			GenerateDiadicNT(op_sw,0,makereg(regLR),make_indexed(3*sizeOfWord,regFP));		// and store it back (so it can be loaded with the lm)
//			GenerateDiadic(op_bra,0,make_label(retlab),NULL);				// goto regular return cleanup code
		}
	}
	else {
		GenerateDiadic(op_lw,0,makereg(regLR),make_indexed(2*sizeOfWord,regFP));		// load throw return address from stack into LR
		GenerateDiadicNT(op_sw,0,makereg(regLR),make_indexed(3*sizeOfWord,regFP));		// and store it back (so it can be loaded with the lm)
//		GenerateDiadic(op_bra,0,make_label(retlab),NULL);				// goto regular return cleanup code
	}
}

static void SaveRegisterSet(SYM *sym)
{
	int nn, mm;

	if (!cpu.SupportsPush) {
		mm = sym->tp->GetBtp()->type!=bt_void ? 29 : 30;
		GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(mm*sizeOfWord));
		mm = 0;
		for (nn = 1 + (sym->tp->GetBtp()->type!=bt_void ? 1 : 0); nn < 31; nn++) {
			GenerateDiadicNT(op_sw,0,makereg(nn),make_indexed(mm,regSP));
			mm += sizeOfWord;
		}
	}
	else
		for (nn = 1 + (sym->tp->GetBtp()->type!=bt_void ? 1 : 0); nn < 31; nn++)
			GenerateMonadicNT(op_push,0,makereg(nn));
}

static void RestoreRegisterSet(SYM * sym)
{
	int nn, mm;

	if (!cpu.SupportsPop) {
		mm = 0;
		for (nn = 1 + (sym->tp->GetBtp()->type!=bt_void ? 1 : 0); nn < 31; nn++) {
			GenerateDiadicNT(op_lw,0,makereg(nn),make_indexed(mm,regSP));
			mm += sizeOfWord;
		}
		mm = sym->tp->GetBtp()->type!=bt_void ? 29 : 30;
		GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(mm*sizeOfWord));
	}
	else
		for (nn = 1 + (sym->tp->GetBtp()->type!=bt_void ? 1 : 0); nn < 31; nn++)
			GenerateMonadicNT(op_push,0,makereg(nn));
}

// For a leaf routine don't bother to store the link register.
static void SetupReturnBlock(SYM *sym)
{
	AMODE *ap;

	GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(4 * sizeOfWord));
	if (!sym->IsLeaf)
		GenerateDiadic(op_sw,0,makereg(regLR),make_indexed(3*sizeOfWord,regSP));
	if (exceptions) {
		if (!sym->IsLeaf || sym->DoesThrow)
			GenerateDiadic(op_sw,0,makereg(regXLR),make_indexed(2*sizeOfWord,regSP));
	}
	GenerateDiadic(op_sw,0,makereg(regZero),make_indexed(sizeOfWord,regSP));
	GenerateDiadic(op_sw,0,makereg(regFP),make_indirect(regSP));
	ap = make_label(throwlab);
	ap->mode = am_immed;
	if (exceptions && (!sym->IsLeaf || sym->DoesThrow))
		GenerateDiadic(op_ldi,0,makereg(regXLR),ap);
	GenerateDiadic(op_mov,0,makereg(regFP),makereg(regSP));
	GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(sym->stkspace));
}

// Generate a function body.
//
void GenerateFunction(SYM *sym)
{
    int defcatch;
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

	while( lc_auto % sizeOfWord )	// round frame size to word
		++lc_auto;
	if (sym->IsInterrupt) {
       if (sym->stkname)
           GenerateDiadic(op_lea,0,makereg(SP),make_string(sym->stkname));
	   //SaveRegisterSet(sym);
	}
	// The prolog code can't be optimized because it'll run *before* any variables
	// assigned to registers are available. About all we can do here is constant
	// optimizations.
	if (sym->prolog) {
		scan(sym->prolog);
	    sym->prolog->Generate();
	}
	// Setup the return block.
	if (!sym->IsNocall)
		SetupReturnBlock(sym);
	if (optimize)
		opt1(stmt);
    stmt->Generate();

	if (exceptions) {
		GenerateMonadicNT(op_bra,0,make_label(lab0));
		GenerateDefaultCatch(sym);
		GenerateLabel(lab0);
	}

	GenerateReturn(nullptr);
/*
	// Inline code needs to branch around the default exception handler.
	if (exceptions && sym->IsInline)
		GenerateMonadicNT(op_bra,0,make_label(lab0));
	// Generate code for the hidden default catch
	if (exceptions)
		GenerateDefaultCatch(sym);
	if (exceptions && sym->IsInline)
		GenerateLabel(lab0);
*/
	throwlab = o_throwlab;
	retlab = o_retlab;
	contlab = o_contlab;
	breaklab = o_breaklab;
}


// Unlink the stack

static void UnlinkStack(SYM * sym)
{
	GenerateDiadic(op_mov,0,makereg(regSP),makereg(regFP));
	GenerateDiadic(op_lw,0,makereg(regFP),make_indirect(regSP));
	if (exceptions) {
		if (!sym->IsLeaf || sym->DoesThrow)
			GenerateDiadic(op_lw,0,makereg(regXLR),make_indexed(2*sizeOfWord,regSP));
	}
	if (!sym->IsLeaf)
		GenerateDiadic(op_lw,0,makereg(regLR),make_indexed(3*sizeOfWord,regSP));
//	GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(3*sizeOfWord));
}


// Push temporaries on the stack.

static void SaveRegisterVars(int64_t mask, int64_t rmask)
{
	int cnt;
	int nn;

	if( mask != 0 ) {
		cnt = 0;
		GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(popcnt(mask)*8));
		for (nn = 0; nn < 64; nn++) {
			if (rmask & (0x8000000000000000ULL >> nn)) {
				GenerateDiadicNT(op_sw,0,makereg(nn),make_indexed(cnt,regSP));
				cnt+=sizeOfWord;
			}
		}
	}
}

static void SaveFPRegisterVars(int64_t mask, int64_t rmask)
{
	int cnt;
	int nn;

	if( mask != 0 ) {
		cnt = 0;
		GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(popcnt(mask)*8));
		for (nn = 0; nn < 64; nn++) {
			if (rmask & (0x8000000000000000ULL >> nn)) {
				GenerateDiadicNT(op_sf,'d',makefpreg(nn),make_indexed(cnt,regSP));
				cnt+=sizeOfWord;
			}
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
		cnt = 0;
		for (nn = 0; nn < 64; nn++) {
			if (save_mask & (1LL << nn)) {
				GenerateDiadic(op_lw,0,makereg(nn),make_indexed(cnt,regSP));
				cnt += sizeOfWord;
			}
		}
		GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(cnt2));
	}
}

static void RestoreFPRegisterVars()
{
	int cnt2, cnt;
	int nn;

	if( fpsave_mask != 0 ) {
		cnt2 = cnt = bitsset(fpsave_mask)*sizeOfWord;
		cnt = 0;
		for (nn = 0; nn < 64; nn++) {
			if (fpsave_mask & (1LL << nn)) {
				GenerateDiadic(op_lf,'d',makefpreg(nn),make_indexed(cnt,regSP));
				cnt += sizeOfWord;
			}
		}
		GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(cnt2));
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
	bool isFloat;

  // Generate the return expression and force the result into r1.
  if( stmt != NULL && stmt->exp != NULL )
  {
		initstack();
		isFloat = sym->tp->GetBtp() && sym->tp->GetBtp()->IsFloatType();
		if (isFloat)
			ap = GenerateExpression(stmt->exp,F_FPREG,sizeOfFP);
		else
			ap = GenerateExpression(stmt->exp,F_REG|F_IMMED,sizeOfWord);
		GenerateMonadicNT(op_hint,0,make_immed(2));
		if (ap->mode == am_immed)
		    GenLdi(makereg(1),ap);
		else if (ap->mode == am_reg) {
            if (sym->tp->GetBtp() && (sym->tp->GetBtp()->type==bt_struct || sym->tp->GetBtp()->type==bt_union)) {
				p = sym->params.Find("_pHiddenStructPtr",false);
				if (p) {
					if (p->IsRegister)
						GenerateDiadic(op_mov,0,makereg(1),makereg(p->reg));
					else
						GenerateDiadic(op_lw,0,makereg(1),make_indexed(p->value.i,regFP));
					GenerateMonadicNT(op_push,0,make_immed(sym->tp->GetBtp()->size));
					GenerateMonadicNT(op_push,0,ap);
					GenerateMonadicNT(op_push,0,makereg(1));
					GenerateMonadicNT(op_call,0,make_string("_memcpy"));
					GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(sizeOfWord*3));
				}
				else {
					// ToDo compiler error
				}
            }
            else {
				if (sym->tp->GetBtp()->IsVectorType())
					GenerateDiadic(op_mov, 0, makevreg(1),ap);
				else
					GenerateDiadic(op_mov, 0, makereg(1),ap);
			}
        }
		else if (ap->mode == am_fpreg) {
			if (isFloat)
				GenerateDiadic(op_mov, 0, makefpreg(1),ap);
			else
				GenerateDiadic(op_mov, 0, makereg(1),ap);
		}
		else if (ap->type==stddouble.GetIndex()) {
			if (isFloat)
				GenerateDiadic(op_lf,'d',makefpreg(1),ap);
			else
				GenerateDiadic(op_lw,0,makereg(1),ap);
		}
		else {
			if (sym->tp->GetBtp()->IsVectorType())
				GenLoad(makevreg(1),ap,sizeOfWord,sizeOfWord);
			else
				GenLoad(makereg(1),ap,sizeOfWord,sizeOfWord);
		}
		ReleaseTempRegister(ap);
	}

	// Generate the return code only once. Branch to the return code for all returns.
	if (retlab != -1) {
		GenerateMonadicNT(op_bra,0,make_label(retlab));
		return;
	}
	retlab = nextlabel++;
	GenerateLabel(retlab);

	if (currentFn->UsesNew) {
		GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(8));
		GenerateDiadic(op_sw,0,makereg(regFirstArg),make_indirect(regSP));
		GenerateDiadic(op_lea,0,makereg(regFirstArg),make_indexed(-sizeOfWord,regFP));
		GenerateMonadic(op_call,0,make_string("__AddGarbage"));
		GenerateDiadic(op_lw,0,makereg(regFirstArg),make_indirect(regSP));
		GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(8));
	}

	// Unlock any semaphores that may have been set
	for (nn = lastsph - 1; nn >= 0; nn--)
		GenerateDiadicNT(op_sb,0,makereg(0),make_string(semaphores[nn]));
		
	// Restore fp registers used as register variables.
	if( fpsave_mask != 0 ) {
		cnt2 = cnt = (bitsset(fpsave_mask)-1)*sizeOfFP;
		for (nn = 31; nn >=1 ; nn--) {
			if (fpsave_mask & (1LL << nn)) {
				GenerateDiadic(op_lw,0,makereg(nn),make_indexed(cnt2-cnt,regSP));
				cnt -= sizeOfWord;
			}
		}
		GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(cnt2+sizeOfFP));
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
	toAdd = 4*sizeOfWord;

	if (sym->epilog) {
		sym->epilog->Generate();
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
//	if (toAdd != 0)
//		GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(toAdd));
	// Generate the return instruction. For the Pascal calling convention pop the parameters
	// from the stack.
	if (sym->IsInterrupt) {
		//RestoreRegisterSet(sym);
		GenerateZeradic(op_rti);
		return;
	}

	if (!sym->IsInline) {
		GenerateMonadic(op_ret,0,make_immed(toAdd));
		//GenerateMonadic(op_jal,0,make_indirect(regLR));
	}
	else
		GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(toAdd));
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
			*sp = TempInvalidate(fsp);
			//*fsp = TempFPInvalidate();
		}
	}
	else {
		*sp = TempInvalidate(fsp);
		//*fsp = TempFPInvalidate();
	}
}

static void RestoreTemporaries(SYM *sym, int sp, int fsp)
{
	if (sym) {
		if (sym->UsesTemps) {
			//TempFPRevalidate(fsp);
			TempRevalidate(sp,fsp);
		}
	}
	else {
		//TempFPRevalidate(fsp);
		TempRevalidate(sp,fsp);
	}
}

// Saves any registers used as parameters in the calling function.

static void SaveRegisterArguments(SYM *sym)
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
				case bt_quad:	GenerateMonadicNT(op_push,0,makereg(ta->preg[nn]& 0x7fff)); break;
				case bt_float:	GenerateMonadicNT(op_push,0,makereg(ta->preg[nn]& 0x7fff)); break;
				case bt_double:	GenerateMonadicNT(op_push,0,makereg(ta->preg[nn]& 0x7fff)); break;
				case bt_triple:	GenerateMonadicNT(op_push,0,makereg(ta->preg[nn]& 0x7fff)); break;
				default:	GenerateMonadicNT(op_push,0,makereg(ta->preg[nn]& 0x7fff)); break;
				}
			}
		}
	}
}

static void RestoreRegisterArguments(SYM *sym)
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
				case bt_quad:	GenerateMonadic(op_pop,0,makereg(ta->preg[nn]& 0x7fff)); break;
				case bt_float:	GenerateMonadic(op_pop,0,makereg(ta->preg[nn]& 0x7fff)); break;
				case bt_double:	GenerateMonadic(op_pop,0,makereg(ta->preg[nn]& 0x7fff)); break;
				case bt_triple:	GenerateMonadic(op_pop,0,makereg(ta->preg[nn]& 0x7fff)); break;
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
static int GeneratePushParameter(ENODE *ep, int regno, int stkoffs)
{    
	AMODE *ap, *ap3;
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
			ap = GenerateExpression(ep,F_FPREG,sizeOfFP);
		else
			ap = GenerateExpression(ep,F_REG|F_IMMED,sizeOfWord);
	}
	else if (ep->etype==bt_quad)
		ap = GenerateExpression(ep,F_FPREG,sz);
	else if (ep->etype==bt_double)
		ap = GenerateExpression(ep,F_FPREG,sz);
	else if (ep->etype==bt_triple)
		ap = GenerateExpression(ep,F_FPREG,sz);
	else if (ep->etype==bt_float)
		ap = GenerateExpression(ep,F_FPREG,sz);
	else
		ap = GenerateExpression(ep,F_REG|F_IMMED,sz);
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
				GenerateMonadicNT(op_hint,0,make_immed(1));
				if (ap->mode==am_immed) {
					GenerateDiadic(op_ldi,0,makereg(regno & 0x7fff), ap);
					if (regno & 0x8000) {
						GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(sizeOfWord));
						nn = 1;
					}
				}
				else if (ap->mode==am_fpreg) {
					GenerateDiadic(op_mov,0,makefpreg(regno & 0x7fff), ap);
					if (regno & 0x8000) {
						GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(sz));
						nn = sz/sizeOfWord;
					}
				}
				else {
					//ap->preg = regno & 0x7fff;
					GenerateDiadic(op_mov,0,makereg(regno & 0x7fff), ap);
					if (regno & 0x8000) {
						GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(sizeOfWord));
						nn = 1;
					}
				}
			}
			else {
				if (cpu.SupportsPush) {
					if (ap->mode==am_immed) {	// must have been a zero
						if (ap->offset->i==0)
         					GenerateMonadicNT(op_push,0,makereg(0));
						else {
							ap3 = GetTempRegister();
							GenerateDiadic(op_ldi,0,ap3,ap);
							GenerateMonadic(op_push,0,ap3);
							ReleaseTempReg(ap3);
						}
						nn = 1;
					}
					else {
						if (ap->type=stddouble.GetIndex()) {
							GenerateMonadicNT(op_push,ap->FloatSize,ap);
							nn = sz/sizeOfWord;
						}
						else {
          					GenerateMonadicNT(op_push,0,ap);
							nn = 1;
						}
					}
				}
				else {
					if (ap->mode==am_immed) {	// must have been a zero
						ap3 = nullptr;
						if (ap->offset->i!=0) {
							ap3 = GetTempRegister();
							GenerateDiadic(op_ldi,0,ap3,ap);
	         				GenerateDiadicNT(op_sw,0,ap3,make_indexed(stkoffs,regSP));
							ReleaseTempReg(ap3);
						}
						else
         					GenerateDiadicNT(op_sw,0,makereg(0),make_indexed(stkoffs,regSP));
						nn = 1;
					}
					else {
						if (ap->type==stddouble.GetIndex() || ap->mode==am_fpreg) {
							GenerateDiadicNT(op_sf,'d',ap,make_indexed(stkoffs,regSP));
							nn = sz/sizeOfWord;
						}
						else {
          					GenerateDiadicNT(op_sw,0,ap,make_indexed(stkoffs,regSP));
							nn = 1;
						}
					}
				}
			}
//        }
    	break;
    }
//	ReleaseTempReg(ap);
	return nn;
}

// Store entire argumnent list onto stack
//
static int GenerateStoreArgumentList(SYM *sym, ENODE *plist)
{
	TypeArray *ta = nullptr;
	int i,sum;
	OCODE *ip;
	ENODE *p;
	ENODE *pl[100];
	int nn;

	sum = 0;
	if (sym)
		ta = sym->GetProtoTypes();

	ip = peep_tail;
	GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(0));
	// Capture the parameter list. It is needed in the reverse order.
	for (nn = 0, p = plist; p != NULL; p = p->p[1], nn++) {
		pl[nn] = p->p[0];
	}
	for(--nn, i = 0; nn >= 0; --nn,i++ )
    {
//		sum += GeneratePushParameter(pl[nn],ta ? ta->preg[ta->length - i - 1] : 0,sum*8);
		sum += GeneratePushParameter(pl[nn],ta ? ta->preg[i] : 0,sum*8);
//		plist = plist->p[1];
    }
	if (sum==0)
		MarkRemove(ip->fwd);
	else
		ip->fwd->oper3 = make_immed(sum*sizeOfWord);
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
            GenerateMonadic(op_pea,0,make_indexed(-nn,regFP));
            i = 1;
        }
*/
		if (currentFn->HasRegisterParameters())
			SaveRegisterArguments(sym);
        i = i + GenerateStoreArgumentList(sym,node->p[1]);
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
		else {
			GenerateMonadicNT(op_call,0,make_offset(node->p[0]));
			GenerateMonadicNT(op_bex,0,make_label(throwlab));
		}
	}
    else
    {
        i = 0;
    /*
    	if ((node->p[0]->tp->GetBtp()->type==bt_struct || node->p[0]->tp->GetBtp()->type==bt_union) && node->p[0]->tp->GetBtp()->size > 8) {
            nn = tmpAlloc(node->p[0]->tp->GetBtp()->size) + lc_auto + round8(node->p[0]->tp->GetBtp()->size);
            GenerateMonadic(op_pea,0,make_indexed(-nn,regFP));
            i = 1;
        }
     */
		ap = GenerateExpression(node->p[0],F_REG,sizeOfWord);
		if (ap->offset)
			sym = ap->offset->sym;
		SaveTemporaries(sym, &sp, &fsp);
		if (currentFn->HasRegisterParameters())
			SaveRegisterArguments(sym);
        i = i + GenerateStoreArgumentList(sym,node->p[1]);
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
		else {
			GenerateMonadicNT(op_call,0,ap);
			GenerateMonadicNT(op_bex,0,make_label(throwlab));
		}
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
	if (currentFn->HasRegisterParameters())
		RestoreRegisterArguments(sym);
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
		return (makefpreg(1));
	if (sym && sym->tp->IsVectorType())
		return (makevreg(1));
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
	GenerateDiadic(op_ldi,0,ap1,ap2);
  return;
}

