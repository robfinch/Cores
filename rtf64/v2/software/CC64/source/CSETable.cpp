// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2020  Robert Finch, Waterloo
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
extern CSet* ru, * rru;

CSETable::CSETable()
{
	ZeroMemory(table, sizeof(table));
	csendx = 0;
	cseiter = 0;
	searchpos = 0;
}

CSETable::~CSETable()
{
}

void CSETable::Assign(CSETable *t)
{
	memcpy(this, t, sizeof(CSETable));
}

static int CSECmp(const void *a, const void *b)
{
	CSE *csp1, *csp2;
	int aa, bb;

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


void CSETable::Sort(int(*cmp)(const void *a, const void *b))
{
	qsort(table, (size_t)csendx, sizeof(CSE), cmp);
}

// InsertNode will enter a reference to an expression node into the
// common expression table. duse is a flag indicating whether or not
// this reference will be dereferenced.
// A given expression in only added once to the table. Other
// instances of the same expression simply increment the usage
// count of the expression in the table.
// The first addition of an expression is flagged and the flag
// returned. This was needed at one point.

CSE *CSETable::InsertNode(ENODE *node, int duse, bool *first)
{
	CSE *csp;

	if ((csp = Search(node)) == nullptr) {   /* add to tree */
		*first = true;
		if (csendx > 499)
			throw new C64PException(ERR_CSETABLE, 0x01);
		csp = &table[csendx];
		ZeroMemory(csp, sizeof(CSE));
		csendx++;
		csp->AccUses(1);
		csp->AccDuses(duse != 0);
		csp->exp = node->Clone();
		csp->isfp = csp->exp->IsFloatType();// && !csp->exp->constflag;
		csp->isPosit = csp->exp->IsPositType();// && !csp->exp->constflag;
		return (csp);
	}
	*first = false;
	csp->AccUses(1);
	csp->AccDuses(1);
	return (csp);
}

//
// SearchCSEList will search the common expression table for an entry
// that matches the node passed and return a pointer to it.
// There should only ever be a single match because of the way nodes
// are inserted into the table.
//
CSE *CSETable::Search(ENODE *node)
{
	int cnt;

	for (cnt = 0; cnt < csendx; cnt++) {
		if (ENODE::IsEqual(node, table[cnt].exp)) {
			searchpos = cnt;
			return (&table[cnt]);
		}
	}
	return ((CSE *)nullptr);
}

// This method present for debugging.

CSE *CSETable::SearchNext(ENODE *node)
{
	int cnt;

	for (cnt = searchpos+1; cnt < csendx; cnt++) {
		if (ENODE::IsEqual(node, table[cnt].exp)) {
			searchpos = cnt;
			return (&table[cnt]);
		}
	}
	return ((CSE *)nullptr);
}

CSE *CSETable::SearchByNumber(ENODE *node)
{
	int cnt;

	for (cnt = 0; cnt < csendx; cnt++) {
		if (node->number == table[cnt].exp->number)
			return (&table[cnt]);
	}
	return ((CSE *)nullptr);
}

// voidauto2 searches the entire CSE table for auto dereferenced node which
// point to the passed node. There might be more than one LValue that matches.
// voidauto will void an auto dereference node which points to
// the same auto constant as node.
//
int CSETable::voidauto2(ENODE *node)
{
	int uses;
	bool voided;
	int cnt;

	uses = 0;
	voided = false;
	for (cnt = 0; cnt < csendx; cnt++) {
		if (IsLValue(table[cnt].exp)) {
			if (ENODE::IsEqual(node, table[cnt].exp->p[0])) {
				table[cnt].voidf = 1;
				voided = true;
				uses += table[cnt].uses;
			}
		}
	}
	return (voided ? uses : -1);
}

// Make multiple passes over the CSE table in order to use
// up all temporary registers. Allocates on the progressively
// less desirable.

int CSETable::AllocateGPRegisters()
{
	CSE *csp;
	bool alloc;
	int pass;
	int reg;

	reg = regFirstRegvar;
	for (pass = 0; pass < 4; pass++) {
		for (csp = First(); csp; csp = Next()) {
			if (csp->OptimizationDesireability() > 0) {
				if (!csp->voidf && csp->reg == -1) {
					if (csp->exp->etype != bt_vector && !csp->isfp && !csp->isPosit) {
						switch (pass)
						{
						case 0:
						case 1:
						case 2:	alloc = (csp->OptimizationDesireability() >= 3) && reg <= regLastRegvar; break;
						case 3: alloc = (csp->OptimizationDesireability() >= 3) && reg <= regLastRegvar; break;
						}
						if (alloc)
							csp->reg = reg++;
						else
							csp->reg = -1;
					}
				}
			}
		}
	}
	return (reg);
}

int CSETable::AllocateFPRegisters()
{
	CSE *csp;
	bool alloc;
	int pass;
	int reg;

	reg = regFirstRegvar;
	for (pass = 0; pass < 4; pass++) {
		for (csp = First(); csp; csp = Next()) {
			if (csp->OptimizationDesireability() > 0) {
				if (!csp->voidf && csp->reg == -1) {
					if (csp->isfp) {
						switch (pass)
						{
						case 0:
						case 1:
						case 2:	alloc = (csp->OptimizationDesireability() >= 4) && reg <= regLastRegvar; break;
						case 3: alloc = (csp->OptimizationDesireability() >= 4) && reg <= regLastRegvar; break;
							//    					if(( csp->duses > csp->uses / (8 << nn)) && reg < regLastRegvar )	// <- address register assignments
						}
						if (alloc) {
							csp->reg = reg++;
							csp->reg |= 0x20;
						}
						else
							csp->reg = -1;
					}
				}
			}
		}
	}
	return (reg);
}

int CSETable::AllocatePositRegisters()
{
	CSE* csp;
	bool alloc;
	int pass;
	int reg;

	reg = regFirstRegvar;
	for (pass = 0; pass < 4; pass++) {
		for (csp = First(); csp; csp = Next()) {
			if (csp->OptimizationDesireability() > 0) {
				if (!csp->voidf && csp->reg == -1) {
					if (csp->isPosit) {
						switch (pass)
						{
						case 0:
						case 1:
						case 2:	alloc = (csp->OptimizationDesireability() >= 4) && reg <= regLastRegvar; break;
						case 3: alloc = (csp->OptimizationDesireability() >= 4) && reg <= regLastRegvar; break;
							//    					if(( csp->duses > csp->uses / (8 << nn)) && reg < regLastRegvar )	// <- address register assignments
						}
						if (alloc) {
							csp->reg = reg++;
							csp->reg |= 0x40;
						}
						else
							csp->reg = -1;
					}
				}
			}
		}
	}
	return (reg);
}

int CSETable::AllocateVectorRegisters()
{
	int nn, vreg;
	CSE *csp;
	bool alloc;

	vreg = regFirstRegvar;
	for (nn = 0; nn < 4; nn++) {
		for (csp = First(); csp; csp = Next()) {
			if (csp->exp) {
				if (csp->exp->etype == bt_vector && csp->reg == -1 && vreg <= regLastRegvar) {
					switch (nn) {
					case 0:
					case 1:
					case 2: alloc = (csp->OptimizationDesireability() >= 4 - nn)
						&& (csp->duses > csp->uses / (8 << nn));
						break;
					case 3:	alloc = (!csp->voidf) && (csp->uses > 3);
						break;
					}
					if (alloc)
						csp->reg = vreg++;
					else
						csp->reg = -1;
				}
			}
		}
	}
	return (vreg);
}

void CSETable::InitializeTempRegs()
{
	Operand *ap, *ap2, *ap3;
	CSE *csp;
	ENODE *exptr;
	int size;

	cg.GenerateHint(begin_regvar_init);
	for (csp = First(); csp; csp = Next()) {
		if (csp->reg != -1)
		{               // see if preload needed
			exptr = csp->exp;
			// A negative reference relative to the frame pointer indicates local variable.
			// Since local vars haven't been initialized yet, there's no point to preloading
			// the register.
			if (exptr->nodetype == en_ref && exptr->p[0]->nodetype == en_autocon && exptr->p[0]->i < 0)
				continue;
			if (1 || !IsLValue(exptr) || (exptr->p[0]->i > 0))
			{
				if (exptr->tp) {
					initstack();
					ap = cg.GenerateExpression(exptr, am_reg | am_imm | am_mem | am_fpreg | am_preg, exptr->tp->size);
					ap2 = csp->isfp ? makefpreg(csp->reg) : csp->isPosit ? compiler.of.makepreg(csp->reg) : makereg(csp->reg);
					if (csp->isfp | csp->isPosit) {
						ap2->type = ap->type;
						ap2->tp = ap->tp;
					}
					ap2->isPtr = ap->isPtr;
					if (ap->mode == am_imm) {
						if (ap2->mode == am_fpreg) {
							ap3 = GetTempRegister();
							ap3->tp = ap->tp;
							GenerateDiadic(op_ldi, 0, ap3, ap);
							GenerateDiadic(op_mov, 0, ap2, ap3);
							ReleaseTempReg(ap3);
						}
						else if (ap2->mode == am_preg) {
							ap3 = GetTempRegister();
							ap3->tp = ap->tp;
							GenerateDiadic(op_ldi, 0, ap3, ap);
							GenerateDiadic(op_mov, 0, ap2, ap3);
							ReleaseTempReg(ap3);
						}
						else {
							cg.GenerateLoadConst(ap, ap2);
						}
					}
					else if (ap->mode == am_reg | ap->mode == am_fpreg || ap->mode == am_preg) {
						GenerateDiadic(op_mov, 0, ap2, ap);
					}
					else {
						size = exptr->GetNaturalSize();
						ap->isUnsigned = exptr->isUnsigned;
						cg.GenerateLoad(ap2, ap, size, size);
					}
					ReleaseTempReg(ap);
				}
			}
		}
	}
	cg.GenerateHint(end_regvar_init);
}

void CSETable::GenerateRegMask(CSE *csp, CSet *msk, CSet *rmsk)
{
	if (csp->reg != -1)
	{
		rmsk->add(nregs - 1 - csp->reg);
		msk->add(csp->reg);
		//*rmask = *rmask | (1LL << (63 - csp->reg));
		//*mask = *mask | (1LL << csp->reg);
	}
}

// ----------------------------------------------------------------------------
// AllocateRegisterVars will allocate registers for the expressions that have
// a high enough desirability.
// ----------------------------------------------------------------------------

int CSETable::AllocateRegisterVars()
{
	CSE *csp;
	CSet *mask;
	CSet *rmask;
	CSet *fpmask;
	CSet *fprmask;
	CSet* pmask;
	CSet* prmask;
	CSet *vmask;
	CSet *vrmask;

	mask = CSet::MakeNew();
	rmask = CSet::MakeNew();
	fpmask = CSet::MakeNew();
	fprmask = CSet::MakeNew();
	pmask = CSet::MakeNew();
	prmask = CSet::MakeNew();
	vmask = CSet::MakeNew();
	vrmask = CSet::MakeNew();

	mask->clear();
	rmask->clear();
	fpmask->clear();
	fprmask->clear();
	pmask->clear();
	prmask->clear();
	vmask->clear();
	vrmask->clear();

	// Sort the CSE table according to desirability of allocating
	// a register.
	if (pass == 1)
		Sort(CSECmp);

	// Initialize to no allocated registers
	for (csp = First(); csp; csp = Next())
		csp->reg = -1;

	AllocateGPRegisters();
	AllocateFPRegisters();
	AllocatePositRegisters();
	AllocateVectorRegisters();

	// Generate bit masks of allocated registers
	for (csp = First(); csp; csp = Next()) {
		if (csp->exp) {
			if (csp->exp->IsFloatType())// && !csp->exp->constflag)
				GenerateRegMask(csp, fpmask, fprmask);
			else if (csp->exp->IsPositType())// && !csp->exp->constflag)
				GenerateRegMask(csp, pmask, prmask);
			else if (csp->exp->etype == bt_vector)
				GenerateRegMask(csp, vrmask, vmask);
			else
				GenerateRegMask(csp, mask, rmask);
		}
		else
			GenerateRegMask(csp, mask, rmask);
	}

	Dump();

	// Push temporaries on the stack.
	cg.GenerateHint(begin_save_regvars);
	SaveRegisterVars(rmask);
	cg.GenerateHint(end_save_regvars);
	SaveFPRegisterVars(fprmask);
	SavePositRegisterVars(prmask);

	save_mask = mask;
	fpsave_mask = fpmask;
	psave_mask = pmask;

	InitializeTempRegs();
	return (mask->NumMember());
}

/*
*      opt1 is the externally callable optimization routine. it will
*      collect and allocate common subexpressions and substitute the
*      tempref for all occurrances of the expression within the block.
*/
int CSETable::Optimize(Statement *block)
{
	int nn;
	int cnt;
	CSE *cse;

	//csendx = 0;
	dfs.printf("<CSETable__Optimize>");
	nn = 0;
	if (pass == 1) {
		if (currentFn->csetbl == nullptr) {
			currentFn->csetbl = new CSETable;
		}
		Clear();
	}
	else if (pass == 2) {
		//Assign(currentFn->csetbl);
	}
	dfs.printf("Pass:%d ", pass);
	if (opt_noregs == FALSE) {
		dfs.printf("===== Before Scan =====");
		block->Dump();
		if (pass == 1)
			block->scan();            /* collect expressions */
		for (cse = First(); cse; cse = Next()) {
			cse->reg = -1;
		}
		nn = AllocateRegisterVars();
		if (pass == 2) {
			block->repcse();          /* replace allocated expressions */
			//block->update();					// available for debugging
			dfs.printf("===== After Update =====");
			block->Dump();
		}
	}
	if (pass == 1)
		;// currentFn->csetbl->Assign(pCSETable);
	else if (pass == 2) {
		if (currentFn->csetbl && !currentFn->IsInline) {
			delete currentFn->csetbl;
			currentFn->csetbl = nullptr;
		}
	}
	dfs.printf("</CSETable__Optimize>\n");
	return (nn);
}

// Immediate constants have low priority.
// Even though their use might be high, they are given a low priority.

void CSETable::Dump()
{
	int nn;
	CSE *csp;

	dfs.printf("<CSETable>For %s\n", (char *)currentFn->sym->name->c_str());
	dfs.printf(
		"*The expression must be used three or more times before it will be allocated\n"
		"to a register.\n");
	dfs.printf("N OD Uses DUses Void Reg Sym\n");
	for (nn = 0; nn < csendx; nn++) {
		csp = &table[nn];
		dfs.printf("%d: ", nn);
		dfs.printf("%d   ", csp->OptimizationDesireability());
		dfs.printf("%d   ", csp->uses);
		dfs.printf("%d   ", csp->duses);
		dfs.printf("%d   ", (int)csp->voidf);
		dfs.printf("%d   ", csp->reg);
		if (csp->exp && csp->exp->sym)
			dfs.printf("%s   ", (char *)csp->exp->sym->name->c_str());
		if (csp->exp && csp->exp->sp)
			dfs.printf("%s   ", (char *)((std::string *)(csp->exp->sp))->c_str());
		dfs.printf("\n");
	}
	dfs.printf("</CSETable>\n");
}

