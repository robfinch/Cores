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
int stkp;
int stack[100000];

void push(int n)
{
	if (stkp < 99999) {
		stack[stkp] = n;
		stkp++;
	}
	else
		throw new C64PException(ERR_STACKFULL, 0);
}

int pop()
{
	if (stkp > 0) {
		--stkp;
		return (stack[stkp]);
	}
	throw new C64PException(ERR_STACKEMPTY, 0);
}


Tree *Forest::MakeNewTree(Tree *t) {
	trees[treecount] = t;
	treecount++;
	return (t);
}

Tree *Forest::MakeNewTree() {
	Tree *t;
	t = (Tree*)allocx(sizeof(Tree));
	t->blocks = CSet::MakeNew();
	trees[treecount] = t;
	treecount++;
	return (t);
}

// Summarize costs
void Forest::SummarizeCost()
{
	int r;

	dfs.printf("<TreeCosts>\n");
	for (r = 0; r < treecount; r++) {
		// If alltrees[r].lattice = BOT
		trees[r]->cost = 2.0f * (trees[r]->loads + trees[r]->stores);
		// else
		// alltrees[r]->cost = alltrees[r]->loads - alltrees[r]->stores;
		trees[r]->cost -= trees[r]->copies;
		dfs.printf("Tree:%d ", r);
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

void Forest::Simplify()
{
	int m;
	int K = 24;

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
			//iGraph.Remove(m);
			// remove m from the graph updating low and high
			push(m);
		}
		if (high.NumMember() == 0)
			break;
		// select a spill candidate m from high
		high.remove(m);
		low.add(m);
	}
}


void Forest::Color()
{
	int n;
	int c;
	int k = 24;
	CSet used;
	Tree *t;

	for (c = 0; c < treecount; c++)
		trees[c]->spill = false;
	while (stkp > 0) {
		t = trees[pop()];
		if (!t->infinite && t->cost <= 0.0f)
			t->spill = true;
		else {
			used.clear();
			for (n = t->GetFirstNeighbour(); n >= 0; n = t->GetNextNeighbour())
				used.add(trees[n]->color);
			for (c = 0; used.isMember(c) && c < k; c++);
			if (c < k)
				t->color = c;
			else
				t->spill = true;
		}
	}
}
