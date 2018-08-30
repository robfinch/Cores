// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
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

Forest forest;
int Forest::treeno = 0;

Tree *Forest::MakeNewTree(Tree *t) {
	trees[treecount] = t;
	treecount++;
	return (t);
}

Tree *Forest::MakeNewTree() {
	Tree *t;
	t = (Tree*)allocx(sizeof(Tree));
	t->blocks = CSet::MakeNew();
	t->num = treeno;
	treeno++;
	trees[treecount] = t;
	treecount++;
	return (t);
}

void Forest::CalcRegclass()
{
	int n;
	Tree *t;
	int j;
	BasicBlock *b;
	OCODE *ip;

	for (n = 0; n < treecount; n++) {
		t = trees[n];
		t->regclass = 0;
		t->blocks->resetPtr();
		for (j = t->blocks->nextMember(); j >= 0; j = t->blocks->nextMember()) {
			b = basicBlocks[j];
			for (ip = b->code; !ip->leader && ip; ip = ip->fwd) {
				t->regclass |= ip->insn->regclass1;
				t->regclass |= ip->insn->regclass2;
				t->regclass |= ip->insn->regclass3;
				t->regclass |= ip->insn->regclass4;
			}
		}
	}
}


// Summarize costs
void Forest::SummarizeCost()
{
	int r;

	dfs.printf("<TreeCosts>\n");
	for (r = 0; r < treecount; r++) {
		if (trees[r]->lattice < 2)
			trees[r]->cost = 2.0f * (trees[r]->loads + trees[r]->stores);
		else
			trees[r]->cost = trees[r]->loads - trees[r]->stores;
		trees[r]->cost += trees[r]->others;
		trees[r]->cost -= trees[r]->copies;
		dfs.printf("Tree(%d):%d ", trees[r]->lattice,r);
		dfs.printf("cost = %d\n", (int)trees[r]->cost);
	}
	dfs.printf("</TreeCosts>\n");
}

// Renumber the registers according to the tree (live range) numbers.
void Forest::Renumber()
{
	OCODE *ip;
	Tree *t;
	int tt;
	BasicBlock *b;
	int bb;
	bool eol;

	for (tt = 0; tt < treecount; tt++) {
		t = trees[tt];
		t->blocks->resetPtr();
		for (bb = t->blocks->nextMember(); bb >= 0; bb = t->blocks->nextMember()) {
			b = basicBlocks[bb];
			eol = false;
			for (ip = b->code; ip && !eol; ip = ip->fwd) {
				if (ip->opcode == op_label)
					continue;
				if (ip->oper1 && ip->oper1->preg == t->var)
					ip->oper1->lrpreg = t->num;
				if (ip->oper1 && ip->oper1->sreg == t->var)
					ip->oper1->lrsreg = t->num;
				if (ip->oper2 && ip->oper2->preg == t->var)
					ip->oper2->lrpreg = t->num;
				if (ip->oper2 && ip->oper2->sreg == t->var)
					ip->oper2->lrsreg = t->num;
				if (ip->oper3 && ip->oper3->preg == t->var)
					ip->oper3->lrpreg = t->num;
				if (ip->oper3 && ip->oper3->sreg == t->var)
					ip->oper3->lrsreg = t->num;
				if (ip->oper4 && ip->oper4->preg == t->var)
					ip->oper4->lrpreg = t->num;
				if (ip->oper4 && ip->oper4->sreg == t->var)
					ip->oper4->lrsreg = t->num;
				if (ip == b->lcode)
					eol = true;
			}
		}
	}
}


// Consider all nodes in the high set as candidates for a spill.
// Based on the lowest cost to degree ratio.

int Forest::SelectSpillCandidate()
{
	int n;
	float ratio, rt;
	bool ratioSet = false;
	int s = -1;

	high.resetPtr();
	for (n = high.nextMember(); n >= 0; n = high.nextMember()) {
		rt = trees[n]->SelectRatio();
		if (!ratioSet) {
			s = n;
			ratio = rt;
			ratioSet = true;
		}
		else {
			if (rt < ratio) {
				ratio = rt;
				s = n;
			}
		}
	}
	return (s);
}

void Forest::Simplify()
{
	int m;
	int K = 24;

	iGraph.frst = this;
	low.clear();
	high.clear();
	for (m = 0; m < treecount; m++) {
		if (iGraph.degrees[m] < K)
			low.add(m);
		else if (!trees[m]->infinite)
			high.add(m);
	}

	while (true) {
		low.resetPtr();
		while ((m = low.nextMember()) >= 0) {
			low.remove(m);
			// remove m from the graph updating low and high
			iGraph.Remove(m);
			push(m);
		}
		if (high.NumMember() == 0)
			break;
		// select a spill candidate m from high
		m = SelectSpillCandidate();	// there should always be an m >= 0
		if (m >= 0) {
			high.remove(m);
			low.add(m);
		}
	}
}


void Forest::Color()
{
	int m;
	int c;
	int j, k = 17;
	int *p;
	CSet used;
	Tree *t;
	Var *v;

	for (c = 0; c < treecount; c++) {
		trees[c]->spill = false;
		trees[c]->color = k;
		if (trees[c]->var >= regFirstArg && trees[c]->var <= regLastArg) {
			trees[c]->color = trees[c]->var;
		}
		if (trees[c]->var == 30 || trees[c]->var == 31) {
			trees[c]->color = trees[c]->var;
		}
	}
	while (!stk->IsEmpty()) {
		t = trees[m=pop()];
		if (!t->infinite && t->cost < 0.0f)	// was <= 0.0f
			t->spill = true;
		else {
			used.clear();
			used.add(0);	// reg0 is a constant 0
			used.add(1);	// these two are return value
			used.add(2);
			p = iGraph.GetNeighbours(m);
			for (j = 1; j < p[0]; j++)
				used.add(trees[p[j]]->color);
			for (c = 0; used.isMember(c) && c < k; c++);
			if (c < k && t->color==k)	// The tree may have been colored already
				t->color = c;
			else if (t->color <= k)		// Don't need to spill args
				t->spill = true;
		}
	}
}


// Count the number of trees requiring spills.

int Forest::GetSpillCount()
{
	int c;
	int spillCount;
	CSet ts;
	char buf[2000];

	ts.clear();
	for (spillCount = c = 0; c < treecount; c++) {
		if (trees[c]->spill) {
			spillCount++;
			ts.add(c);
		}
	}
	dfs.printf("<SpillCount>%d</SpillCount>\n", spillCount);
	ts.sprint(buf, sizeof(buf));
	dfs.printf("<TreesSpilled>%s</TreesSpilled>\n", buf);
	return (spillCount);
}

void Forest::GenSpillCode()
{
	int c, m, n;
	int spillCount;
	Var *v;
	Tree *t;
	BasicBlock *bb;
	int spillOffset;
	OCODE *cd;
	CSet spilled;

	cd = currentFn->spAdjust;
	if (cd == nullptr)
		return;
	spillOffset = cd->oper3->offset->i;	// start at -8
	spilled.clear();
	for (c = 0; c < treecount; c++) {
		t = trees[c];	// convenience
		// Tree couldn't be colored that means there are no available registers.
		// So, spill one of the registers. The register to spill should be one
		// that isn't live at the same time as this tree.
		if (t->spill) {
			v = Var::Find(t->var);
			v = v->GetVarToSpill();
			// The var is spilled at the head of the tree, and restored later
			t->blocks->resetPtr();
			m = t->blocks->nextMember();
			if (m >= 0) {	// should always be true, otherwise no code
				bb = basicBlocks[m];
				if (!spilled.isMember(v->num)) {
					v->spillOffset = spillOffset;
					spillOffset += sizeOfWord;
					spilled.add(v->num);
				}
				bb->InsertSpillCode(v->num, -v->spillOffset);
				while(1) {
					n = m;
					m = t->blocks->nextMember();
					if (m < 0)
						break;
					// Detect when a different branch is present. The node
					// number will jump by more than 1 between branches.
					if (m - n > 1) {
						bb = basicBlocks[n];
						bb->InsertFillCode(v->num, -v->spillOffset);
					}
				}
				bb = basicBlocks[n];
				bb->InsertFillCode(v->num, -v->spillOffset);
			}
		}
	}
	cd->oper3->offset->i = spillOffset;
}
