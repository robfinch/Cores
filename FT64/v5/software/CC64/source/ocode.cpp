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

//
//      mov r3,r3 removed
//
// Code Like:
//		add		r3,r2,#10
//		mov		r3,r5
// Changed to:
//		mov		r3,r5

void OCODE::OptMove()
{
	if (OCODE::IsEqualOperand(oper1, oper2)) {
		MarkRemove();
		optimized++;
		return;
	}
}

//	   sge		$v1,$r12,$v2
//     redor	$v2,$v1
// Translates to:
//	   sge		$v1,$r12,$v2
//     mov		$v2,$v1
// Because redundant moves will be eliminated by further compiler
// optimizations.

void OCODE::OptRedor()
{
	if (back == nullptr)
		return;
	if (back->insn->IsSetInsn()) {
		if (back->oper1->preg == oper2->preg) {
			opcode = op_mov;
			insn = GetInsn(op_mov);
			optimized++;
		}
	}
}

void OCODE::storeHex(txtoStream& ofs)
{
	ENODE *ep;

	switch (opcode) {
	case op_label:
		ofs.printf("L");
		ofs.printf("%05X", (int)oper1);
		ofs.printf(GetNamespace());
		ofs.printf("\n");
		break;
	case op_fnname:
		ep = (ENODE *)oper1->offset;
		ofs.printf("F%s:\n", (char *)ep->sp->c_str());
		break;
	default:
		ofs.printf("C");
		insn->storeHex(ofs);
		ofs.printf("L%01d", length);
		if (oper1) oper1->storeHex(ofs);
		if (oper2) oper2->storeHex(ofs);
		if (oper3) oper3->storeHex(ofs);
		if (oper4) oper4->storeHex(ofs);
		ofs.printf("\n");
	}
}

OCODE *OCODE::loadHex(std::ifstream& ifs)
{
	OCODE *cd;
	char buf[20];
	int op;

	cd = (OCODE *)allocx(sizeof(OCODE));
	ifs.read(buf, 1);
	if (buf[0] != 'I') {
		while (!ifs.eof() && buf[0] != '\n')
			ifs.read(buf, 1);
		return (nullptr);
	}
	cd->insn = Instruction::loadHex(ifs);
	cd->opcode = cd->insn->opcode;
	ifs.read(buf, 1);
	if (buf[0] == 'L') {
		ifs.read(buf, 1);
		buf[1] = '\0';
		cd->length = atoi(buf);
		ifs.read(buf, 1);
	}
	cd->oper1 = nullptr;
	cd->oper2 = nullptr;
	cd->oper3 = nullptr;
	cd->oper4 = nullptr;
	switch (buf[0]) {
	case '1': cd->oper1 = Operand::loadHex(ifs); break;
	case '2': cd->oper2 = Operand::loadHex(ifs); break;
	case '3': cd->oper3 = Operand::loadHex(ifs); break;
	case '4': cd->oper4 = Operand::loadHex(ifs); break;
	default:
		while (!ifs.eof() && buf[0] != '\n')
			ifs.read(buf, 1);
	}
	return (cd);
}

//
// Output a generic instruction.
//
void OCODE::store(txtoStream& ofs)
{
	static BasicBlock *b = nullptr;
	int op = opcode;
	Operand *ap1, *ap2, *ap3, *ap4;
	ENODE *ep;
	int predreg = pregreg;
	char buf[8];
	int nn;

	ap1 = oper1;
	ap2 = oper2;
	ap3 = oper3;
	ap4 = oper4;

	if (bb != b) {
		ofs.printf(";====================================================\n");
		ofs.printf("; Basic Block %d\n", bb->num);
		ofs.printf(";====================================================\n");
		b = bb;
	}
	if (comment) {
		ofs.printf("; %s\n", (char *)comment->oper1->offset->sp->c_str());
	}
	if (remove)
		ofs.printf(";-1");
	if (remove2)
		ofs.printf(";-2");
	if (op != op_fnname)
	{
		if (op == op_rem2) {
			ofs.printf(";\t");
			ofs.printf("%6.6s\t", "");
			ofs.printf(ap1->offset->sp->c_str());
			ofs.printf("\n");
			return;
		}
		else {
			ofs.printf("\t");
			ofs.printf("%6.6s\t", "");
			nn = insn->store(ofs);
			buf[0] = '\0';
			if (length) {
				if (length <= 16) {
					switch (length) {
					case 1:	sprintf_s(buf, sizeof(buf), ".b"); nn += 2; break;
					case 2:	sprintf_s(buf, sizeof(buf), ".c"); nn += 2; break;
					case 4:	sprintf_s(buf, sizeof(buf), ".h"); nn += 2; break;
					}
				}
				else {
					if (length != 'w' && length != 'W') {
						sprintf_s(buf, sizeof(buf), ".%c", length);
						nn += 2;
					}
				}
			}
			ofs.write(buf);
			// The longest mnemonic is 7 chars
			while (nn < 9) {
				ofs.write(" ");
				nn++;
			}
		}
	}
	if (op == op_fnname) {
		ep = (ENODE *)oper1->offset;
		ofs.printf("%s:", (char *)ep->sp->c_str());
	}
	else if (ap1 != 0)
	{
		ofs.printf("\t");
		ap1->store(ofs);
		if (ap2 != 0)
		{
			if (op == op_push || op == op_pop)
				ofs.printf("/");
			else
				ofs.printf(",");
			if (op == op_cmp && ap2->mode != am_reg)
				printf("aha\r\n");
			ap2->store(ofs);
			if (ap3 != NULL) {
				if (op == op_push || op == op_pop)
					ofs.printf("/");
				else
					ofs.printf(",");
				ap3->store(ofs);
				if (ap4 != NULL) {
					if (op == op_push || op == op_pop)
						ofs.printf("/");
					else
						ofs.printf(",");
					ap4->store(ofs);
				}
			}
		}
	}
	ofs.printf("\n");
}



