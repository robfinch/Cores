// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2020  Robert Finch, Waterloo
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

extern char irfile[256];
void PrintPeepList();
static void Remove();
static void PeepoptSub(OCODE *ip);
void opt_peep();
void put_ocode(OCODE *p);
void CreateControlFlowGraph();
extern void ComputeLiveVars();
extern void DumpLiveVars();
extern Instruction *GetInsn(int);
void CreateVars();
void ComputeLiveRanges();
void DumpLiveRanges();
void DumpVarForests();
void DumpLiveRegs();
void CreateVarForests();
void DeleteSets();
void RemoveCode();
bool Coalesce();
void ComputeSpillCosts();
extern void CalcDominatorTree();
Var *FindVar(int num);
void ExpandReturnBlocks();
bool RemoveEnabled = true;
unsigned int ArgRegCount;
int count;
Map map;

OCODE *LabelTable[50000];

extern Var *varlist;


IGraph iGraph;
int optimized;	// something got optimized

void GenerateZeradic(int op)
{
	dfs.printf("<GenerateZeradic>");
	OCODE *cd;
	dfs.printf("A");
	cd = (OCODE *)allocx(sizeof(OCODE));
	dfs.printf("B");
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = 0;
	cd->oper1 = NULL;
	dfs.printf("C");
	cd->oper2 = NULL;
	cd->oper3 = NULL;
	cd->oper4 = NULL;
	dfs.printf("D");
	cd->loop_depth = looplevel;
	//AddToPeepList(cd);
	currentFn->pl.Add(cd);
	dfs.printf("</GenerateZeradic>\r\n");
}

void GenerateMonadic(int op, int len, Operand *ap1)
{
	dfs.printf("<GenerateMonadic>");
	OCODE *cd;
	dfs.printf("A");
	cd = (OCODE *)allocx(sizeof(OCODE));
	dfs.printf("B");
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = ap1->Clone();
	dfs.printf("C");
	cd->oper2 = NULL;
	cd->oper3 = NULL;
	cd->oper4 = NULL;
	dfs.printf("D");
	cd->loop_depth = looplevel;
	//AddToPeepList(cd);
	currentFn->pl.Add(cd);
	dfs.printf("</GenerateMonadic>\n");
}

void GenerateDiadic(int op, int len, Operand *ap1, Operand *ap2)
{
	OCODE *cd;
	cd = (OCODE *)xalloc(sizeof(OCODE));
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = ap1->Clone();
	cd->oper2 = ap2->Clone();
	if (ap2) {
		if (ap2->mode == am_ind || ap2->mode==am_indx) {
			//if (ap2->preg==regSP || ap2->preg==regFP)
			//	cd->opcode |= op_ss;
		}
	}
	cd->oper3 = NULL;
	cd->oper4 = NULL;
	cd->loop_depth = looplevel;
	//AddToPeepList(cd);
	currentFn->pl.Add(cd);
}

void GenerateTriadic(int op, int len, Operand *ap1, Operand *ap2, Operand *ap3)
{
	OCODE    *cd;
	cd = (OCODE *)allocx(sizeof(OCODE));
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = ap1->Clone();
	cd->oper2 = ap2->Clone();
	cd->oper3 = ap3->Clone();
	cd->oper4 = NULL;
	cd->loop_depth = looplevel;
	//AddToPeepList(cd);
	currentFn->pl.Add(cd);
}

void Generate4adic(int op, int len, Operand *ap1, Operand *ap2, Operand *ap3, Operand *ap4)
{
	OCODE *cd;
	cd = (OCODE *)allocx(sizeof(OCODE));
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = ap1->Clone();
	cd->oper2 = ap2->Clone();
	cd->oper3 = ap3->Clone();
	cd->oper4 = ap4->Clone();
	cd->loop_depth = looplevel;
	//AddToPeepList(cd);
	currentFn->pl.Add(cd);
}

/*
 *      add a compiler generated label to the peep list.
 */
void GenerateLabel(int labno)
{      
	OCODE *newl;
	newl = (OCODE *)allocx(sizeof(OCODE));
	newl->opcode = op_label;
	newl->oper1 = (Operand *)labno;
	newl->oper2 = (Operand *)my_strdup((char *)currentFn->sym->name->c_str());
	currentFn->pl.Add(newl);
}


static void MergeSubi(OCODE *first, OCODE *last, int64_t amt)
{
	OCODE *ip;

	if (first==nullptr)
		return;

	// First remove all the excess subtracts
	for (ip = first; ip && ip != last; ip = ip->fwd) {
		if (ip->IsSubiSP()) {
			ip->MarkRemove();
			optimized++;
		}
	}
	// Set the amount of the last subtract to the total amount
	if (ip)	 {// there should be one
		ip->oper3->offset->i = amt;
	}
}

// 'subui'
//
/*
static void PeepoptSubSP()
{  
	OCODE *ip;
	OCODE *first_subi = nullptr;
	OCODE *last_subi = nullptr;
	int64_t amt = 0;

	for (ip = peep_head; ip; ip = ip->fwd) {
		if (ip->IsSubiSP()) {
			if (first_subi==nullptr)
				last_subi = first_subi = ip;
			else
				last_subi = ip;
			amt += ip->oper3->offset->i;
		}
		else if (ip->opcode==op_push || ip->insn->IsFlowControl()) {
			MergeSubi(first_subi, last_subi, amt);
			first_subi = last_subi = nullptr;
			amt = 0;
		}
	}
}
*/
void MarkRemove2(OCODE *ip)
{
	ip->remove2 = true;
}

//
//      peephole optimizer. This routine calls the instruction
//      specific optimization routines above for each instruction
//      in the peep list.
//
void Function::PeepOpt()
{
	OCODE *ip;
	int rep;

	pl.Dump("===== Before any peephole optmizations =====");

	// Move the return code pointer past the label which may be removed by
	// optimization.
	if (rcode)
		rcode = rcode->fwd;

	// Remove any dead code identified by the code generator.
	pl.Remove();

	if (!::opt_nopeep) {

		pl.OptBranchToNext();

		// Performing peephole optimizations may lead to further optimizations so do
		// the optimization step a few times.
		optimized = 0;
		pl.OptConstReg();
		for (rep = 0; (rep < 5) || (optimized && rep < 10); rep++)
		{
			// Peephole optimizations might lead to unreferenced labels, which may make
			// further peephole optimizations possible.
			pl.SetLabelReference();
			pl.EliminateUnreferencedLabels();
			pl.Remove();
			pl.OptInstructions();
			pl.Remove();
			pl.OptDoubleTargetRemoval();
		}

		//currentFn->pl.Dump();
		// Remove the link and unlink instructions if no references
		// to BP.
		hasSPReferences = (pl.CountSPReferences() != 0);
		hasBPReferences = (pl.CountBPReferences() != 0);

		if (!hasBPReferences)
			pl.RemoveLinkUnlink();
		if (IsLeaf && !hasSPReferences && !hasBPReferences)
			pl.RemoveStackCode();
		if ((IsLeaf && !hasSPReferences)
			|| (!hasSPReferences && !hasBPReferences))
			pl.RemoveReturnBlock();
		pl.Remove();
	}

	// Get rid of extra labels that clutter up the output
	pl.SetLabelReference();
	pl.EliminateUnreferencedLabels();

	// Remove all the compiler hints that didn't work out.
	pl.RemoveCompilerHints();
	pl.Remove();

	RootBlock = pl.Blockize();
	pl.Dump("===== After peephole optimizations =====");
	forest.func = this;
	//	RootBlock->ExpandReturnBlocks();
	CFG::Create();

	pl.RemoveMoves();
	ComputeLiveVars();
	pl.MarkAllKeep();

	DumpLiveVars();
	CreateVars();
	Var::CreateForests();
	Var::DumpForests(0);
	CFG::CalcDominanceFrontiers();
	CFG::InsertPhiInsns();
	pl.RemoveCompilerHints2();
	CFG::Rename();
	count = 0;
	forest.pass = 0;
	forest.PreColor();
	do {
		forest.pass++;
		if (!opt_vreg)
			return;
		forest.Renumber();
		BasicBlock::ComputeSpillCosts();
		RemoveCode();
		iGraph.workingMoveop = op_mov;
		iGraph.workingRegclass = am_reg;
		iGraph.frst = &forest;
		iGraph.BuildAndCoalesce();
		//iGraph.workingMoveop = op_fmov;
		//iGraph.workingRegclass = am_fpreg;
		//iGraph.frst = &forest;
		//iGraph.BuildAndCoalesce();
		//iGraph.workingMoveop = op_vmov;
		//iGraph.workingRegclass = am_vreg;
		//iGraph.frst = &forest;
		//iGraph.BuildAndCoalesce();
		iGraph.Print(3);
		forest.Simplify();
		iGraph.Print(4);
		forest.Select();
		Var::DumpForests(1);
		forest.SpillCode();
	} while (!forest.IsAllTreesColored() && forest.pass < 32);
	dfs.printf("Loops for color graphing allocator: %d\n", forest.pass);

	// Substitute real registers for virtual ones.
	forest.ColorBlocks();
	pl.MarkAllKeep();
	pl.MarkAllKeep2();
	cpu.SetRealRegisters();
	if (count == 2) {
		dfs.printf("Register allocator max loops.\n");
	}
	Var::DumpForests(2);
	//DumpLiveRegs();

	pl.Dump("===== After all optimizations =====");
}


// Remove useless code where there are no output links from the basic block.

void RemoveCode()
{
	int nn,mm;
	Var *v;
	Tree *t;
	OCODE *p;
	int count;
	int rg1, rg2;
	bool eol;

	count = 0;
	//printf((char *)currentFn->name->c_str());
	//printf("\r\n");
	for (v = currentFn->varlist; v; v = v->next) {
		if (MachineReg::IsCalleeSave(v->num))
			continue;
		if (v->num < 5 || v->num==regLR || v->num==regXLR)
			continue;
		for (mm = 0; mm < v->trees.treecount; mm++) {
			t = v->trees.trees[mm];
			nn = t->blocks->lastMember();
			do {
				eol = false;
				if (!basicBlocks[nn]->isRetBlock) {
					for (p = basicBlocks[nn]->lcode; p && !eol; p = p->back) {
						if (p->opcode == op_label)
							continue;
						if (p->opcode == op_ret)
							continue;
						p->GetTargetReg(&rg1, &rg2);
						if (rg1 == v->num && rg2 == 0) {
							if (p->bb->ohead == nullptr) {
								MarkRemove2(p);
								count++;
							}
						}
						if (!p->remove && p->HasSourceReg(v->num))
							goto j1;
						eol = p == basicBlocks[nn]->code;
					}
				}
			} while((nn = t->blocks->prevMember()) >= 0);
j1:	;
		}
		currentFn->pl.Remove2();
	}
	dfs.printf("<CodeRemove>%d</CodeRemove>\n", count);
}

