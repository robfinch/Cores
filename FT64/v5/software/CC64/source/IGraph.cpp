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

void IGraph::MakeNew(int n)
{
	int bms;

	size = n;
	bms = n * n / sizeof(int);
	bitmatrix = new int[bms];
	degrees = new short int[n];
	ns = new CSet[n];
	Clear();
}

void IGraph::Clear()
{
	int j;

	j = size * size / sizeof(int);
	ZeroMemory(bitmatrix, j);
	ZeroMemory(degrees, size);
	for (j = 0; j < size; j++)
		ns[j].clear();
}

void IGraph::Add(int x, int y)
{
	int bitndx;
	int intndx;

	bitndx = x + (y * y) / 2;
	intndx = bitndx / sizeof(int);
	bitndx %= (sizeof(int) * 8);
	bitmatrix[intndx] |= (1 << bitndx);
	ns[x].add(y);
	degrees[x]++;
}

void IGraph::Remove(int n)
{
	int bitndx;
	int intndx;
	int j;

	ns[n].resetPtr();
	for (j = ns[n].nextMember(); j >= 0; j = ns[n].nextMember()) {
		bitndx = n + (j * j) / 2;
		intndx = bitndx / sizeof(int);
		bitndx %= (sizeof(int) * 8);
		bitmatrix[intndx] &= ~(1 << bitndx);
	}
	ns[n].clear();
	if (degrees[n] > 0)
		degrees[n]--;
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
