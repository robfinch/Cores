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

	K = 17;
	size = n;
	bms = n * n / sizeof(int);
	bitmatrix = new int[bms];
	degrees = new short int[n];
	vecs = new int *[n];
	ZeroMemory(vecs, n * sizeof(int *));
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
	ClearBitmatrix();
	ZeroMemory(degrees, size * sizeof(short int));
}


// Called after the first fill pass to allocate storage for vectors.

void IGraph::AllocVecs()
{
	int x;

	for (x = 0; x < size; x++) {
		vecs[x] = new int[degrees[x]];
	}
}

int IGraph::BitIndex(int x, int y, int *intndx, int *bitndx)
{
	if (x > y)
		throw new C64PException(ERR_IGNODES, 1);
	*bitndx = x + (y * y + 1) / 2;
	*intndx = *bitndx / sizeof(int);
	*bitndx %= (sizeof(int) * 8);
	return (x + (y * y + 1) / 2);
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

	if (x == y)
		return;
	BitIndex(x,y,&intndx,&bitndx);
	bitmatrix[intndx] |= (1 << bitndx);
	AddToVec(x, y);
	AddToVec(y, x);
}


// Used to update the vector table.

void IGraph::AddToVec(int x, int y)
{
	int nn;

	if (pass > 1) {
		// ensure the y isn't already in the table
		for (nn = 0; nn < degrees[x]; nn++) {
			if (vecs[x][nn] == y)
				break;
		}
		if (nn >= degrees[x]) {
			vecs[x][degrees[x]] = y;
			degrees[x]++;
		}
	}
	else
		degrees[x]++;
}

// A slightly faster version of Add used when father and son nodes are united.
// We don't want to add back to the son's.

void IGraph::Add2(int x, int y)
{
	int bitndx;
	int intndx;
	int x1, y1;

	if (x == y)
		return;
	x1 = min(x, y);
	y1 = max(x, y);
	BitIndex(x1, y1, &intndx, &bitndx);
	bitmatrix[intndx] |= (1 << bitndx);
	AddToVec(x1, y1);
}

bool IGraph::Remove(int n)
{
	int bitndx;
	int intndx;
	int j, m, nn, mm, n1, m1;
	bool updated = false;

	for (j = 0; j < degrees[n]; j++) {
		m = vecs[n][j];
		if (degrees[m] > 0) {
			for (mm = nn = 0; nn < degrees[m]; nn++) {
				if (vecs[m][nn] != n) {
					vecs[m][mm] = vecs[m][nn];
					mm++;
				}
			}
			degrees[m]--;
			if (degrees[m] == K-1 && !frst->trees[m]->infinite) {
				frst->high.remove(m);
				frst->low.add(m);
				updated = true;
			}
		}
		//n1 = min(n, m);
		//m1 = max(n, m);
		//BitIndex(n1, m1, &intndx, &bitndx);
		//bitmatrix[intndx] &= ~(1 << bitndx);
	}
	return (updated);
}

bool IGraph::DoesInterfere(int x, int y)
{
	int bitndx;
	int intndx;

	if (x == y) return (true);
	//return !(frst->trees[x]->blocks->isDisjoint(*frst->trees[y]->blocks));
	bitndx = BitIndex(x, y, &intndx, &bitndx);
	return (((bitmatrix[intndx] >> bitndx) & 1)==1);
}


// Move adjacency vectors across graph from son to father.

void IGraph::Unite(int father, int son)
{
	int j;
	int *tmp;

	if (father > son)
		throw new C64PException(ERR_IGNODES, 2);

	// Increase the size of the adjacency vector allocation for the father as
	// the son's vectors will be added to them.
	tmp = new int [degrees[father] + degrees[son] + 1];
	ZeroMemory(tmp, (degrees[father] + degrees[son] + 1) * sizeof(int));
	if (vecs[father]) {
		memcpy(tmp, vecs[father], degrees[father] * sizeof(int));
		//delete[] vecs[father];
	}
	vecs[father] = tmp;

	if (vecs[son]) {
		for (j = 0; j < degrees[son]; j++) {
			Add2(father, vecs[son][j]);
		}
		degrees[son] = 0;
	}
}

// Only consider adding trees that have not yet been colored to the live set.

void IGraph::AddToLive(BasicBlock *b, Operand *ap, OCODE *ip)
{
	int v;

	v = FindTreeno(ap->preg, ip->bb->num);
	if (v >= 0) {
		if (frst->trees[v]->color == K)
			b->live->add(v);
	}
	if (ap->sreg) {
		v = FindTreeno(ap->sreg, ip->bb->num);
		if (v >= 0) {
			if (frst->trees[v]->color == K)
				b->live->add(v);
		}
	}
}

void IGraph::Fill()
{
	int n, n1;
	BasicBlock *b;
	int v, v1;
	OCODE *ip;
	bool eol;
	int K = 17;

	// For each block 
	for (b = currentFn->RootBlock; b; b = b->next) {
		b->BuildLivesetFromLiveout();
		eol = false;
		for (ip = b->lcode; ip && !eol; ip = ip->back) {
			if (ip->opcode != op_label) {
				// examine instruction ip and update graph and live
				if (ip->opcode == op_mov) {
					v = FindTreeno(ip->oper1->preg, ip->bb->num);
					if (v >= 0 && frst->trees[v]->color == K) {
						b->live->remove(v);
					}
				}
				if (ip->insn->HasTarget()) {
					v = FindTreeno(ip->oper1->preg, ip->bb->num);
					if (v >= 0 && frst->trees[v]->color==K) {
						b->live->resetPtr();
						for (n = b->live->nextMember(); n >= 0; n = b->live->nextMember()) {
							n1 = min(n, v);
							v1 = max(n, v);
							iGraph.Add(n1, v1);
						}
						b->live->remove(v);
					}
				}
				// Unrolled loop
				// while (p < ik->uses)
				if (!ip->insn->HasTarget() && ip->oper1)
					AddToLive(b, ip->oper1, ip);
				if (ip->oper2)
					AddToLive(b, ip->oper2, ip);
				if (ip->oper3)
					AddToLive(b, ip->oper3, ip);
				if (ip->oper4)
					AddToLive(b, ip->oper4, ip);
			}
			eol = ip == b->code;
		}
	}
}


void IGraph::InsertArgumentMoves()
{
	int nn, mm, blk;
	Var *v;
	Tree *t;

	for (nn = regFirstArg; nn <= regLastArg; nn++) {
		mm = map.newnums[nn];
		if (mm >= 0) {
			if (v = Var::Find2(mm)) {				// find the forest
				for (mm = 0; mm < v->trees.treecount; mm++) {	// search the trees
					t = v->trees.trees[mm];
					t->blocks->resetPtr();
					blk = t->blocks->nextMember();	// The lowest block # will be the head of the tree
					if (blk >= 0)
						BasicBlock::InsertMove(map.newnums[nn], t->var, blk);
				}
			}
		}
	}
}

void IGraph::BuildAndCoalesce()
{
	bool improved = false;

	MakeNew(frst->treecount);
	frst->CalcRegclass();

	// Insert move operations to handle register parameters. We want to do this
	// only once.
	if (forest.pass == 1)
		InsertArgumentMoves();

	// Vist high-priority blocks (blocks in nested loops) first, so sort the
	// blocks according to depth.
	BasicBlock::DepthSort();

	// On the first pass we just want to determine the degree of the nodes so
	// that storage for vectors can be allocated.
	pass = 1;
	Clear();
	Fill();
	AllocVecs();

	pass = 2;
	do {
		Clear();
		Fill();
		Print(2);
		improved = BasicBlock::Coalesce();
		//improved = Var::Coalesce2();
		//IRemove();
	} while (improved);
	//Destroy();	// needed in Simplify()
}

void IGraph::Print(int n)
{
	int nn, mm;

	dfs.printf("<IGraph>%d\n", n);
	for (nn = 0; nn < size; nn++) {
		dfs.printf("Degrees[%d]=%d ", nn, degrees[nn]);
		dfs.printf("Neighbours are: ");
		for (mm = 0; mm < degrees[nn]; mm++) {
			dfs.printf("%d ", vecs[nn][mm]);
		}
		dfs.printf("\n");
	}
	dfs.printf("</IGraph>\n");
}
