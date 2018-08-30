// ============================================================================
// Currently under construction (not used yet).
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

// Count the length of the peep list from the current position to the end of
// the list. Used during some code generation optimizations.

int PeepList::Count(OCODE *ip)
{
	int cnt;

	for (cnt = 0; ip && ip != peep_tail; cnt++)
		ip = ip->fwd;
	return (cnt);
}

void PeepList::InsertBefore(OCODE *an, OCODE *cd)
{
	cd->fwd = an;
	cd->back = an->back;
	if (an->back)
		an->back->fwd = cd;
	an->back = cd;
}

void PeepList::InsertAfter(OCODE *an, OCODE *cd)
{
	cd->fwd = an->fwd;
	cd->back = an;
	if (an->fwd)
		an->fwd->back = cd;
	an->fwd = cd;
}

void PeepList::Add(OCODE *cd)
{
	if (!dogen)
		return;

	if (head == NULL)
	{
		ArgRegCount = regFirstArg;
		head = tail = cd;
		cd->fwd = nullptr;
		cd->back = nullptr;
	}
	else
	{
		cd->fwd = nullptr;
		cd->back = tail;
		tail->fwd = cd;
		tail = cd;
	}
	if (cd->opcode != op_label) {
		if (cd->oper1 && IsArgumentReg(cd->oper1->preg))
			ArgRegCount = max(ArgRegCount, cd->oper1->preg);
		if (cd->oper2 && IsArgumentReg(cd->oper2->preg))
			ArgRegCount = max(ArgRegCount, cd->oper2->preg);
		if (cd->oper3 && IsArgumentReg(cd->oper3->preg))
			ArgRegCount = max(ArgRegCount, cd->oper3->preg);
		if (cd->oper4 && IsArgumentReg(cd->oper4->preg))
			ArgRegCount = max(ArgRegCount, cd->oper4->preg);
	}
}
