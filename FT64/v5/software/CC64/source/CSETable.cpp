// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
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

void CSETable::Assign(CSETable *t)
{
	memcpy(this, t, sizeof(CSETable));
}

void CSETable::Sort(int(*cmp)(const void *a, const void *b))
{
	qsort(table, (size_t)csendx, sizeof(CSE), cmp);
}

// InsertNodeIntoCSEList will enter a reference to an expression node into the
// common expression table. duse is a flag indicating whether or not
// this reference will be dereferenced.

CSE *CSETable::InsertNode(ENODE *node, int duse)
{
	CSE *csp;

	if ((csp = Search(node)) == nullptr) {   /* add to tree */
		if (csendx > 499)
			throw new C64PException(ERR_CSETABLE, 0x01);
		csp = &table[csendx];
		csendx++;
		if (loop_active > 1) {
			csp->uses = (loop_active - 1) * 5;
			csp->duses = (duse != 0) * ((loop_active - 1) * 5);
		}
		else {
			csp->uses = 1;
			csp->duses = (duse != 0);
		}
		csp->exp = node->Clone();
		csp->voidf = 0;
		csp->reg = 0;
		csp->isfp = csp->exp->IsFloatType();
		return (csp);
	}
	if (loop_active < 2) {
		(csp->uses)++;
		if (duse)
			(csp->duses)++;
	}
	else {
		(csp->uses) += ((loop_active - 1) * 5);
		if (duse)
			(csp->duses) += ((loop_active - 1) * 5);
	}
	return (csp);
}

//
// SearchCSEList will search the common expression table for an entry
// that matches the node passed and return a pointer to it.
//
CSE *CSETable::Search(ENODE *node)
{
	int cnt;

	for (cnt = 0; cnt < csendx; cnt++) {
		if (ENODE::IsEqual(node, table[cnt].exp))
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
		if (IsLValue(table[cnt].exp) && ENODE::IsEqual(node, table[cnt].exp->p[0])) {
			table[cnt].voidf = 1;
			voided = true;
			uses += table[cnt].uses;
		}
	}
	return (voided ? uses : -1);
}

