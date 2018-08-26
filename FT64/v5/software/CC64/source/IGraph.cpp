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
	Destroy();
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

void IGraph::Clear()
{
	int j;

	j = size * size / sizeof(int);
	ZeroMemory(bitmatrix, j);
	ZeroMemory(degrees, size * sizeof(short int));
	ZeroMemory(vecs, size * sizeof(AdjVec));
}

void IGraph::Add(int x, int y)
{
	int bitndx;
	int intndx;
	AdjVec *v;

	bitndx = x + (y * y) / 2;
	intndx = bitndx / sizeof(int);
	bitndx %= (sizeof(int) * 8);
	bitmatrix[intndx] |= (1 << bitndx);
	v = vecs[x];
	vecs[x] = new AdjVec;
	vecs[x]->next = v;
	vecs[x]->node = y;
	degrees[x]++;
	degrees[y]++;
}

bool IGraph::Remove(int n)
{
	int bitndx;
	int intndx;
	AdjVec *j, *k;

	for (j = vecs[n]; j; j = k) {
		if (degrees[j->node] > 0) {
			degrees[j->node]--;
			if (degrees[j->node] == K-1 && !frst->trees[j->node]->infinite) {
				frst->high.remove(j->node);
				frst->low.add(j->node);
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
