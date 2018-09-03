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

// Return true if the instruction has a target register.

bool OCODE::HasTargetReg() const
{
	if (insn)
		return (insn->HasTarget());
	else
		return (false);
}

bool OCODE::HasSourceReg(int regno) const
{
	if (oper1 && !insn->HasTarget()) {
		if (oper1->preg==regno)
			return (true);
		if (oper1->sreg==regno)
			return (true);
	}
	if (oper2 && oper2->preg==regno)
		return (true);
	if (oper2 && oper2->sreg==regno)
		return (true);
	if (oper3 && oper3->preg==regno)
		return (true);
	if (oper3 && oper3->sreg==regno)
		return (true);
	if (oper4 && oper4->preg==regno)
		return (true);
	if (oper4 && oper4->sreg==regno)
		return (true);
	// The call instruction implicitly has register arguments as source registers.
	if (opcode==op_call) {
		if (IsArgumentReg(regno))
			return(true);
	}
	return (false);
}

// Get target reg needs to distinguish floating-point registers from regular
// general purpose registers. It returns a one for floating-point registers or
// a zero for general-purpose registers.

int OCODE::GetTargetReg(int *rg1, int *rg2) const
{
	if (insn==nullptr)
		return(0);
	if (insn->HasTarget()) {
		// Handle implicit targets
		switch(insn->opcode) {
		case op_pop:
		case op_unlk:
		case op_link:
			*rg1 = regSP;
			*rg2 = oper1->preg;
			return(0);
		case op_divmod:
		case op_mul:
		case op_mulu:
		case op_sort:
		case op_demux:
		case op_mov2:
			*rg1 = oper1->preg;
			*rg2 = oper1->sreg;
			return (0);
		case op_pea:
		case op_push:
		case op_ret:
		case op_call:
			*rg1 = regSP;
			*rg2 = 0;
			return (0);
		default:
			if (oper1->mode == am_fpreg) {
				*rg1 = oper1->preg;
				*rg2 = 0;
				return (1);
			}
			else {
				*rg1 = oper1->preg;
				*rg2 = 0;
				return (0);
			}
		}
	}
	else {
		*rg1 = 0;
		*rg2 = 0;
		return (0);
	}
}

OCODE *OCODE::Clone(OCODE *c)
{
	OCODE *cd;
	cd = (OCODE *)xalloc(sizeof(OCODE));
	memcpy(cd, c, sizeof(OCODE));
	return (cd);
}
