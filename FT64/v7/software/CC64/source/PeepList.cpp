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
extern int optimized;
extern OCODE *LabelTable[50000];

OCODE *PeepList::FindLabel(int64_t i)
{
	if (i >= 50000 || i < 0)
		return (nullptr);
	return (LabelTable[i]);
}


// Count the length of the peep list from the current position to the end of
// the list. Used during some code generation optimizations.

int PeepList::Count(OCODE *ip)
{
	int cnt;

	for (cnt = 0; ip && ip != tail; cnt++)
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

void PeepList::Remove()
{
	OCODE *ip, *ip1, *ip2;

	if (1)//(RemoveEnabled)
		for (ip = head; ip; ip = ip1) {
			ip1 = ip->fwd;
			ip2 = ip->back;
			if (ip->remove) {
				if (ip1 && ip1->comment == nullptr)
					ip1->comment = ip->comment;
				if (ip2)
					ip2->fwd = ip1;
				if (ip1)
					ip1->back = ip2;
			}
		}
}


// Potentially any called routine could throw an exception. So call
// instructions could act like branches to the default catch tacked
// onto the end of a subroutine. This is important to prevent the
// default catch from being optimized away. It's possible that there's
// no other way to reach the catch.
// A bex instruction, which isn't a real instruction, is added to the
// instruction stream so that links are created in the CFG to the
// catch handlers. At a later stage of the compile all the bex
// instructions are removed, since they were there only to aid in
// compiler optimizations.

void PeepList::RemoveCompilerHints2()
{
	OCODE *ip;

	for (ip = head; ip != NULL; ip = ip->fwd)
	{
		if (ip->opcode == op_bex)
			MarkRemove(ip);
	}
	Remove();
}

void PeepList::storeHex(txtoStream& ofs)
{
	OCODE *ip;

	ofs.printf("; CC64 Hex Intermediate Representation File\n");
	ofs.printf("; This is an automatically generated file.\n");
	for (ip = head; ip != NULL; ip = ip->fwd)
	{
		ip->storeHex(ofs);
	}
	ofs.printf("%c", 26);
}

void PeepList::loadHex(std::ifstream& ifs)
{
	char buf[50];
	OCODE *cd;
	int op;

	head = tail = nullptr;
	while (!ifs.eof()) {
		ifs.read(buf, 1);
		switch (buf[0]) {
		case 'O':
			cd = OCODE::loadHex(ifs);
			Add(cd);
			break;
		default:	// ;
			while (buf[0] != '\n' && !ifs.eof())
				ifs.read(buf, 1);
			break;
		}
	}
}
