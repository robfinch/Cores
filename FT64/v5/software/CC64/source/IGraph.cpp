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


// This interference graph uses a bit set to represent the adjacency vectors.
// Unless doing whole program optimizations the number of basic blocks 
// encountered in any function is likely to be a small number (< 100).
// 

void IGraph::MakeNew(int n)
{
	int bms;

	K = 24;
	size = n;
	bms = n * n / sizeof(int);
	bitmatrix = new int[bms];
	degrees = new short int[n];
	vecs = new AdjVec *[n];
	Clear();
}

IGraph::~IGraph()
{
//	Destroy();
}

void IGraph::Destroy()
{
	int n;
	AdjVec *j, *k;

	delete[] bitmatrix;
	delete[] degrees;
	for (n = 0; n < size; n++) {
		for (j = vecs[n]; j; j = k) {
			k = j->next;
			delete j;
		}
	}
	delete[] vecs;
}

void IGraph::ClearBitmatrix()
{
	int j;

	j = size * size / sizeof(int);
	ZeroMemory(bitmatrix, j);
}

void IGraph::Clear()
{
	ClearBitmatrix();
	ZeroMemory(degrees, size * sizeof(short int));
	ZeroMemory(vecs, size * sizeof(AdjVec *));
}

void IGraph::Add(int x, int y)
{
	int bitndx;
	int intndx;
	AdjVec *v;
	bool isSet;

	bitndx = x + (y * y) / 2;
	intndx = bitndx / sizeof(int);
	bitndx %= (sizeof(int) * 8);
	isSet = bitmatrix[intndx] &= ~(1 << bitndx);
	if (!isSet) {
		bitmatrix[intndx] |= (1 << bitndx);
		degrees[x]++;
		degrees[y]++;
		v = vecs[x];
		vecs[x] = new AdjVec;
		vecs[x]->next = v;
		vecs[x]->node = y;
	}
}

bool IGraph::Remove(int n)
{
	int bitndx;
	int intndx;
	AdjVec *j, *k;
	bool updated = false;

	for (j = vecs[n]; j; j = k) {
		if (degrees[j->node] > 0) {
			degrees[j->node]--;
			if (degrees[j->node] == K-1 && !frst->trees[j->node]->infinite) {
				frst->high.remove(j->node);
				frst->low.add(j->node);
				updated = true;
			}
		}
		bitndx = n + (j->node * j->node) / 2;
		intndx = bitndx / sizeof(int);
		bitndx %= (sizeof(int) * 8);
		bitmatrix[intndx] &= ~(1 << bitndx);
		k = j->next;
		delete j;
		vecs[n] = k;
	}
	degrees[n] = 0;
	return (updated);
}

bool IGraph::DoesInterfere(int x, int y)
{
	int bitndx;
	int intndx;

	bitndx = x + (y * y) / 2;
	intndx = bitndx / sizeof(int);
	bitndx %= (sizeof(int) * 8);
	return (((bitmatrix[intndx] >> bitndx) & 1)==1);
}


// Move adjacency vectors across graph from son to father.

void IGraph::Unite(int father, int son)
{
	AdjVec *j, *k;

	for (j = vecs[son]; j; j = k) {
		Add(father, j->node);
		k = j->next;
		delete j;
	}
	vecs[son] = nullptr;
}


void IGraph::Fill()
{
	int n;
	BasicBlock *b;
	int v;
	OCODE *ip;
	bool eol;

	// For each block 
	for (b = RootBlock; b; b = b->next) {
		b->BuildLivesetFromLiveout();
		eol = false;
		for (ip = b->lcode; ip && !eol; ip = ip->back) {
			// examine instruction ip and update graph and live
			if (ip->opcode == op_mov) {
				v = FindTreeno(ip->oper1->preg,ip->bb->num);
				if (v >= 0) b->live->remove(v);
			}
			if (ip->insn->HasTarget) {
				v = FindTreeno(ip->oper1->preg,ip->bb->num);
				if (v >= 0) {
					for (n = b->live->nextMember(); n >= 0; n = b->live->nextMember()) {
						iGraph.Add(n, v);
					}
					b->live->remove(v);
				}
			}
			// Unrolled loop
			// while (p < ik->uses)
			if (!ip->insn->HasTarget && ip->oper1) {
				v = FindTreeno(ip->oper1->preg,ip->bb->num);
				if (v>=0) b->live->add(v);
				v = FindTreeno(ip->oper1->sreg,ip->bb->num);
				if (v>=0) b->live->add(v);
			}
			if (ip->oper2) {
				v = FindTreeno(ip->oper2->preg, ip->bb->num);
				if (v >= 0) b->live->add(v);
				v = FindTreeno(ip->oper2->sreg, ip->bb->num);
				if (v >= 0) b->live->add(v);
			}
			if (ip->oper3) {
				v = FindTreeno(ip->oper3->preg, ip->bb->num);
				if (v >= 0) b->live->add(v);
				v = FindTreeno(ip->oper3->sreg, ip->bb->num);
				if (v >= 0) b->live->add(v);
			}
			if (ip->oper4) {
				v = FindTreeno(ip->oper4->preg, ip->bb->num);
				if (v >= 0) b->live->add(v);
				v = FindTreeno(ip->oper4->sreg, ip->bb->num);
				if (v >= 0) b->live->add(v);
			}
			eol = ip == b->lcode;
		}
	}

	//Destroy();
}


void IGraph::BuildAndCoalesce()
{
	Var *v;
	Tree *t;
	int nn, mm, blk;
	bool improved = false;

	MakeNew(Var::nvar);
	frst->CalcRegclass();

	// Insert move operations to handle register parameters.
	for (nn = regFirstArg; nn <= regLastArg; nn++) {
		if (v = Var::Find2(nn)) {				// find the forest
			for (mm = 0; mm < v->trees.treecount; mm++) {	// search the trees
				t = v->trees.trees[mm];
				t->blocks->resetPtr();
				blk = t->blocks->nextMember();	// The lowest block # will be the head of the tree
				if (blk >= 0)
					BasicBlock::InsertMove(nn, t->var, blk);
			}
		}
	}

	// Vist high-priority blocks (blocks in nested loops) first, so sort the
	// blocks according to depth.
	BasicBlock::DepthSort();

	do {
		Clear();
		Fill();
		improved = BasicBlock::Coalesce();
		IRemove();
	} while (improved);
	Destroy();
}