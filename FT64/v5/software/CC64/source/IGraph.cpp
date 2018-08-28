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
	vecs = new int *[n];
	memset(vecs, 0, n * sizeof(int *));
	Clear();
}

IGraph::~IGraph()
{
//	Destroy();
}

void IGraph::Destroy()
{
	int n;

	delete[] bitmatrix;
	delete[] degrees;
	for (n = 0; n < size; n++) {
		//if (vecs[n])
		//	delete[] vecs[n];
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
	int n;

	ClearBitmatrix();
	ZeroMemory(degrees, size * sizeof(short int));
	if (vecs) {
		for (n = 0; n < size; n++)
			if (vecs[n])
				vecs[n][0] = 1;
	}
}

// Two passes are made in order to determine the size of 
// the adjacency vector array for the node. The first pass
// just determines the degree.
// The number of adjacency vectors stored is stored in the
// first element of the array.

void IGraph::Add(int x, int y)
{
	int bitndx;
	int intndx;
	bool isSet;

	bitndx = x + (y * y) / 2;
	intndx = bitndx / sizeof(int);
	bitndx %= (sizeof(int) * 8);
	isSet = bitmatrix[intndx] &= ~(1 << bitndx);
	if (!isSet) {
		bitmatrix[intndx] |= (1 << bitndx);
		degrees[x]++;
		degrees[y]++;
		if (pass > 1) {
			if (vecs[x] == nullptr) {
				vecs[x] = new int[degrees[x]+1];
				vecs[x][0] = 1;
			}
			vecs[x][vecs[x][0]] = y;
			vecs[x][0]++;
		}
	}
}

bool IGraph::Remove(int n)
{
	int bitndx;
	int intndx;
	int j, m;
	bool updated = false;

	for (j = 1; j < degrees[n] + 1; j++) {
		m = vecs[n][j];
		if (degrees[m] > 0) {
			degrees[m]--;
			if (degrees[m] == K-1 && !frst->trees[m]->infinite) {
				frst->high.remove(m);
				frst->low.add(m);
				updated = true;
			}
		}
		bitndx = n + (m * m) / 2;
		intndx = bitndx / sizeof(int);
		bitndx %= (sizeof(int) * 8);
		bitmatrix[intndx] &= ~(1 << bitndx);
	}
	vecs[n][0] = 1;
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
	int j;
	int *tmp;

	// Increase the size of the adjacency vector allocation for the father as
	// the son's vectors will be added to them.
	tmp = new int [degrees[father] + degrees[son]];
	if (vecs[father]) {
		memcpy(tmp, vecs[father], (vecs[father][0] + 1) * sizeof(int));
		//delete[] vecs[father];
	}
	else
		tmp[0] = 1;
	vecs[father] = tmp;

	if (vecs[son]) {
		for (j = 1; j < vecs[son][0]; j++) {
			Add(father, vecs[son][j]);
		}
		vecs[son][0] = 1;
	}
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

	pass = 1;
	Clear();
	Fill();

	pass = 2;
	do {
		Clear();
		Fill();
		improved = BasicBlock::Coalesce();
		IRemove();
	} while (improved);
	Destroy();
}
