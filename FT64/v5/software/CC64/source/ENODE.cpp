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

char ENODE::fsize()
{
	switch (etype) {
	case bt_float:	return ('d');
	case bt_double:	return ('d');
	case bt_triple:	return ('t');
	case bt_quad:	return ('q');
	default:	return ('d');
	}
}

long ENODE::GetReferenceSize()
{
	switch (nodetype)        /* get load size */
	{
	case en_b_ref:
	case en_ub_ref:
	case en_bfieldref:
	case en_ubfieldref:
		return (1);
	case en_c_ref:
	case en_uc_ref:
	case en_cfieldref:
	case en_ucfieldref:
		return (2);
	case en_ref32:
	case en_ref32u:
		return (4);
	case en_h_ref:
	case en_uh_ref:
	case en_hfieldref:
	case en_uhfieldref:
		return (sizeOfWord / 2);
	case en_w_ref:
	case en_uw_ref:
	case en_wfieldref:
	case en_uwfieldref:
		return (sizeOfWord);
	case en_fpregvar:
		return(tp->size);
	case en_tempref:
	case en_regvar:
		return (sizeOfWord);
	case en_dbl_ref:
		return (sizeOfFPD);
	case en_quad_ref:
		return (sizeOfFPQ);
	case en_flt_ref:
		return (sizeOfFPD);
	case en_triple_ref:
		return (sizeOfFPT);
	case en_hp_ref:
		return (sizeOfPtr >> 1);
	case en_wp_ref:
		return (sizeOfPtr);
	case en_vector_ref:
		return (512);
		//			return node->esize;
	}
	return (8);
}

bool ENODE::IsBitfield()
{
	return (nodetype == en_wfieldref
		|| nodetype == en_bfieldref
		|| nodetype == en_cfieldref
		|| nodetype == en_hfieldref
		|| nodetype == en_ubfieldref
		|| nodetype == en_ucfieldref
		|| nodetype == en_uhfieldref
		|| nodetype == en_uwfieldref
		);
}

//
// equalnode will return 1 if the expressions pointed to by
// node1 and node2 are equivalent.
//
bool ENODE::IsEqual(ENODE *node1, ENODE *node2)
{
	if (node1 == nullptr || node2 == nullptr) {
		return (false);
	}
	if (node1->nodetype != node2->nodetype) {
		return (false);
	}
	switch (node1->nodetype) {
	case en_fcon:
		return (Float128::IsEqual(&node1->f128, &node2->f128));
		//			return (node1->f == node2->f);
	case en_regvar:
	case en_fpregvar:
	case en_tempref:
	case en_icon:
	case en_labcon:
	case en_classcon:	// Check type ?
	case en_autocon:
	case en_autovcon:
	case en_autofcon:
	{
		return (node1->i == node2->i);
	}
	case en_nacon: {
		return (node1->sp->compare(*node2->sp) == 0);
	}
	case en_cnacon:
		return (node1->sp->compare(*node2->sp) == 0);
	default:
		if (IsLValue(node1) && IsEqual(node1->p[0], node2->p[0])) {
			//	        if( equalnode(node1->p[0], node2->p[0])  )
			return (true);
		}
	}
	return (false);
}


ENODE *ENODE::Clone()
{
	ENODE *temp;

	if (this == nullptr)
		return (ENODE *)nullptr;
	temp = allocEnode();
	memcpy(temp, this, sizeof(ENODE));	// copy all the fields
	return (temp);
}


// ----------------------------------------------------------------------------
// Generate code to evaluate an index node (^+) and return the addressing mode
// of the result. This routine takes no flags since it always returns either
// am_ind or am_indx.
//
// No reason to ReleaseTempReg() because the registers used are transported
// forward.
// ----------------------------------------------------------------------------
AMODE *ENODE::GenIndex()
{
	AMODE *ap1, *ap2;

	if ((p[0]->nodetype == en_tempref || p[0]->nodetype == en_regvar)
		&& (p[1]->nodetype == en_tempref || p[1]->nodetype == en_regvar))
	{       /* both nodes are registers */
			// Don't need to free ap2 here. It is included in ap1.
		GenerateHint(8);
		ap1 = GenerateExpression(p[0], F_REG, 8);
		ap2 = GenerateExpression(p[1], F_REG, 8);
		GenerateHint(9);
		ap1->mode = am_indx2;
		ap1->sreg = ap2->preg;
		ap1->deep2 = ap2->deep2;
		ap1->offset = makeinode(en_icon, 0);
		ap1->scale = scale;
		return (ap1);
	}
	GenerateHint(8);
	ap1 = GenerateExpression(p[0], F_REG | F_IMMED, 8);
	if (ap1->mode == am_immed)
	{
		ap2 = GenerateExpression(p[1], F_REG | F_IMM0, 8);
		if (ap2->mode == am_immed) {	// value is zero
			ap1->mode = am_direct;
			return (ap1);
		}
		GenerateHint(9);
		ap2->mode = am_indx;
		ap2->offset = ap1->offset;
		ap2->isUnsigned = ap1->isUnsigned;
		return (ap2);
	}
	ap2 = GenerateExpression(p[1], F_ALL, 8);   /* get right op */
	GenerateHint(9);
	if (ap2->mode == am_immed && ap1->mode == am_reg) /* make am_indx */
	{
		ap2->mode = am_indx;
		ap2->preg = ap1->preg;
		ap2->deep = ap1->deep;
		return ap2;
	}
	if (ap2->mode == am_ind && ap1->mode == am_reg) {
		ap2->mode = am_indx2;
		ap2->sreg = ap1->preg;
		ap2->deep2 = ap1->deep;
		return ap2;
	}
	if (ap2->mode == am_direct && ap1->mode == am_reg) {
		ap2->mode = am_indx;
		ap2->preg = ap1->preg;
		ap2->deep = ap1->deep;
		return ap2;
	}
	// ap1->mode must be F_REG
	MakeLegalAmode(ap2, F_REG, 8);
	ap1->mode = am_indx2;            /* make indexed */
	ap1->sreg = ap2->preg;
	ap1->deep2 = ap2->deep;
	ap1->offset = makeinode(en_icon, 0);
	ap1->scale = scale;
	return ap1;                     /* return indexed */
}


//
// Generate code to evaluate a condition operator node (?:)
//
AMODE *ENODE::GenHook(int flags, int size)
{
	AMODE *ap1, *ap2, *ap3, *ap4;
	int false_label, end_label;
	OCODE *ip1;
	int n1;
	ENODE *node;

	false_label = nextlabel++;
	end_label = nextlabel++;
	flags = (flags & F_REG) | F_VOL;
	/*
	if (p[0]->constflag && p[1]->constflag) {
	GeneratePredicateMonadic(hook_predreg,op_op_ldi,make_immed(p[0]->i));
	GeneratePredicateMonadic(hook_predreg,op_ldi,make_immed(p[0]->i));
	}
	*/
	ip1 = peep_tail;
	if (!opt_nocgo) {
		ap4 = GetTempRegister();
		ap1 = GenerateExpression(p[0], flags, size);
		ap2 = GenerateExpression(p[1]->p[0], flags, size);
		ap3 = GenerateExpression(p[1]->p[1], flags | F_IMM0, size);
		n1 = PeepCount(ip1);
		if (n1 < 20) {
			Generate4adic(op_cmovenz, 0, ap4, ap1, ap2, ap3);
			ReleaseTempReg(ap3);
			ReleaseTempReg(ap2);
			ReleaseTempReg(ap1);
			return (ap4);
		}
		ReleaseTempReg(ap3);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		ReleaseTempReg(ap4);
		peep_tail = ip1;
		peep_tail->fwd = nullptr;
	}
	ap2 = GenerateExpression(p[1]->p[1], flags, size);
	n1 = PeepCount(ip1);
	if (opt_nocgo)
		n1 = 9999;
	if (n1 > 4) {
		peep_tail = ip1;
		peep_tail->fwd = nullptr;
	}
	GenerateFalseJump(p[0], false_label, 0);
	node = p[1];
	ap1 = GenerateExpression(node->p[0], flags, size);
	if (n1 > 4)
		GenerateDiadicNT(op_bra, 0, make_clabel(end_label), 0);
	else {
		if (!equal_address(ap1, ap2))
		{
			GenerateMonadicNT(op_hint, 0, make_immed(2));
			GenerateDiadic(op_mov, 0, ap2, ap1);
		}
	}
	GenerateLabel(false_label);
	if (n1 > 4) {
		ap2 = GenerateExpression(node->p[1], flags, size);
		if (!equal_address(ap1, ap2))
		{
			GenerateMonadicNT(op_hint, 0, make_immed(2));
			GenerateDiadic(op_mov, 0, ap1, ap2);
		}
	}
	if (n1 > 4) {
		ReleaseTempReg(ap2);
		GenerateLabel(end_label);
		return (ap1);
	}
	else {
		ReleaseTempReg(ap1);
		GenerateLabel(end_label);
		return (ap2);
	}
}


//
// Generate code to evaluate a unary minus or complement.
//
AMODE *ENODE::GenUnary(int flags, int size, int op)
{
	AMODE *ap, *ap2;

	if (IsFloatType()) {
		ap2 = GetTempFPRegister();
		ap = GenerateExpression(p[0], F_FPREG, size);
		if (op == op_neg)
			op = op_fneg;
		GenerateDiadic(op, fsize(), ap2, ap);
	}
	else if (etype == bt_vector) {
		ap2 = GetTempVectorRegister();
		ap = GenerateExpression(p[0], F_VREG, size);
		GenerateDiadic(op, 0, ap2, ap);
	}
	else {
		ap2 = GetTempRegister();
		ap = GenerateExpression(p[0], F_REG, size);
		GenerateHint(3);
		GenerateDiadic(op, 0, ap2, ap);
	}
	ReleaseTempReg(ap);
	MakeLegalAmode(ap2, flags, size);
	return (ap2);
}

// Generate code for a binary expression

AMODE *ENODE::GenBinary(int flags, int size, int op)
{
	AMODE *ap1, *ap2, *ap3, *ap4;

	if (IsFloatType())
	{
		ap3 = GetTempFPRegister();
		ap1 = GenerateExpression(p[0], F_FPREG, size);
		ap2 = GenerateExpression(p[1], F_FPREG, size);
		// Generate a convert operation ?
		if (ap1->fpsize() != ap2->fpsize()) {
			if (ap2->fpsize() == 's')
				GenerateDiadic(op_fcvtsq, 0, ap2, ap2);
		}
		GenerateTriadic(op, ap1->fpsize(), ap3, ap1, ap2);
		ap3->type = ap1->type;
	}
	else if (op == op_vadd || op == op_vsub || op == op_vmul || op == op_vdiv
		|| op == op_vadds || op == op_vsubs || op == op_vmuls || op == op_vdivs
		|| op == op_veins) {
		ap3 = GetTempVectorRegister();
		if (ENODE::IsEqual(p[0], p[1]) && !opt_nocgo) {
			ap1 = GenerateExpression(p[0], F_VREG, size);
			ap2 = GenerateExpression(vmask, F_VMREG, size);
			Generate4adic(op, 0, ap3, ap1, ap1, ap2);
			ReleaseTempReg(ap2);
			ap2 = nullptr;
		}
		else {
			ap1 = GenerateExpression(p[0], F_VREG, size);
			ap2 = GenerateExpression(p[1], F_VREG, size);
			ap4 = GenerateExpression(vmask, F_VMREG, size);
			Generate4adic(op, 0, ap3, ap1, ap2, ap4);
			ReleaseTempReg(ap4);
		}
		// Generate a convert operation ?
		//if (fpsize(ap1) != fpsize(ap2)) {
		//	if (fpsize(ap2)=='s')
		//		GenerateDiadic(op_fcvtsq, 0, ap2, ap2);
		//}
	}
	else if (op == op_vex) {
		ap3 = GetTempRegister();
		ap1 = GenerateExpression(p[0], F_REG, size);
		ap2 = GenerateExpression(p[1], F_REG, size);
		GenerateTriadic(op, 0, ap3, ap1, ap2);
	}
	else {
		ap3 = GetTempRegister();
		if (ENODE::IsEqual(p[0], p[1]) && !opt_nocgo) {
			ap1 = GenerateExpression(p[0], F_REG, size);
			ap2 = nullptr;
			GenerateTriadic(op, 0, ap3, ap1, ap1);
		}
		else {
			ap1 = GenerateExpression(p[0], F_REG, size);
			ap2 = GenerateExpression(p[1], F_REG | F_IMMED, size);
			if (ap2->mode == am_immed) {
				switch (op) {
				case op_and:
					GenerateTriadic(op, 0, ap3, ap1, make_immed(ap2->offset->i));
					/*
					if (ap2->offset->i & 0xFFFF0000LL)
					GenerateDiadic(op_andq1,0,ap3,make_immed((ap2->offset->i >> 16) & 0xFFFFLL));
					if (ap2->offset->i & 0xFFFF00000000LL)
					GenerateDiadic(op_andq2,0,ap3,make_immed((ap2->offset->i >> 32) & 0xFFFFLL));
					if (ap2->offset->i & 0xFFFF000000000000LL)
					GenerateDiadic(op_andq3,0,ap3,make_immed((ap2->offset->i >> 48) & 0xFFFFLL));
					*/
					break;
				case op_or:
					GenerateTriadic(op, 0, ap3, ap1, make_immed(ap2->offset->i));
					/*
					if (ap2->offset->i & 0xFFFF0000LL)
					GenerateDiadic(op_orq1,0,ap3,make_immed((ap2->offset->i >> 16) & 0xFFFFLL));
					if (ap2->offset->i & 0xFFFF00000000LL)
					GenerateDiadic(op_orq2,0,ap3,make_immed((ap2->offset->i >> 32) & 0xFFFFLL));
					if (ap2->offset->i & 0xFFFF000000000000LL)
					GenerateDiadic(op_orq3,0,ap3,make_immed((ap2->offset->i >> 48) & 0xFFFFLL));
					*/
					break;
					// Most ops handle a max 16 bit immediate operand. If the operand is over 16 bits
					// it has to be loaded into a register.
				default:
					if (ap2->offset->i < -32768LL || ap2->offset->i > 32767LL) {
						ap4 = GetTempRegister();
						GenerateTriadic(op_or, 0, ap4, makereg(regZero), make_immed(ap2->offset->i));
						/*
						if (ap2->offset->i & 0xFFFF0000LL)
						GenerateDiadic(op_orq1,0,ap4,make_immed((ap2->offset->i >> 16) & 0xFFFFLL));
						if (ap2->offset->i & 0xFFFF00000000LL)
						GenerateDiadic(op_orq2,0,ap4,make_immed((ap2->offset->i >> 32) & 0xFFFFLL));
						if (ap2->offset->i & 0xFFFF000000000000LL)
						GenerateDiadic(op_orq3,0,ap4,make_immed((ap2->offset->i >> 48) & 0xFFFFLL));
						*/
						GenerateTriadic(op, 0, ap3, ap1, ap4);
						ReleaseTempReg(ap4);
					}
					else
						GenerateTriadic(op, 0, ap3, ap1, ap2);
				}
			}
			else
				GenerateTriadic(op, 0, ap3, ap1, ap2);
		}
	}
	if (ap2)
		ReleaseTempReg(ap2);
	ReleaseTempReg(ap1);
	MakeLegalAmode(ap3, flags, size);
	return (ap3);
}


AMODE *ENODE::GenAssignAdd(int flags, int size, int op)
{
	AMODE *ap1, *ap2, *ap3;
	int ssize;
	bool negf = false;

	ssize = GetNaturalSize(p[0]);
	if (ssize > size)
		size = ssize;
	if (p[0]->IsBitfield()) {
		ap3 = GetTempRegister();
		ap1 = GenerateBitfieldDereference(p[0], F_REG | F_MEM, size);
		GenerateDiadic(op_mov, 0, ap3, ap1);
		ap2 = GenerateExpression(p[1], F_REG | F_IMMED, size);
		GenerateTriadic(op, 0, ap1, ap1, ap2);
		GenerateBitfieldInsert(ap3, ap1, ap1->offset->bit_offset, ap1->offset->bit_width);
		GenStore(ap3, ap1->next, ssize);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1->next);
		ReleaseTempReg(ap1);
		MakeLegalAmode(ap3, flags, size);
		return (ap3);
	}
	if (IsFloatType()) {
		ap1 = GenerateExpression(p[0], F_FPREG | F_MEM, ssize);
		ap2 = GenerateExpression(p[1], F_FPREG, size);
		if (op == op_add)
			op = op_fadd;
		else if (op == op_sub)
			op = op_fsub;
	}
	else if (etype == bt_vector) {
		ap1 = GenerateExpression(p[0], F_REG | F_MEM, ssize);
		ap2 = GenerateExpression(p[1], F_REG, size);
		if (op == op_add)
			op = op_vadd;
		else if (op == op_sub)
			op = op_vsub;
	}
	else {
		ap1 = GenerateExpression(p[0], F_ALL, ssize);
		ap2 = GenerateExpression(p[1], F_REG | F_IMMED, size);
	}
	if (ap1->mode == am_reg) {
		GenerateTriadic(op, 0, ap1, ap1, ap2);
	}
	else if (ap1->mode == am_fpreg) {
		GenerateTriadic(op, ap1->fpsize(), ap1, ap1, ap2);
		ReleaseTempReg(ap2);
		MakeLegalAmode(ap1, flags, size);
		return (ap1);
	}
	else {
		GenMemop(op, ap1, ap2, ssize);
	}
	ReleaseTempReg(ap2);
	if (ap1->type != stddouble.GetIndex() && !ap1->isUnsigned)
		ap1->GenSignExtend(ssize, size, flags);
	MakeLegalAmode(ap1, flags, size);
	return (ap1);
}

AMODE *ENODE::GenAssignLogic(int flags, int size, int op)
{
	AMODE *ap1, *ap2, *ap3;
	int ssize;

	ssize = GetNaturalSize(p[0]);
	if (ssize > size)
		size = ssize;
	if (p[0]->IsBitfield()) {
		ap3 = GetTempRegister();
		ap1 = GenerateBitfieldDereference(p[0], F_REG | F_MEM, size);
		GenerateDiadic(op_mov, 0, ap3, ap1);
		ap2 = GenerateExpression(p[1], F_REG | F_IMMED, size);
		GenerateTriadic(op, 0, ap1, ap1, ap2);
		GenerateBitfieldInsert(ap3, ap1, ap1->offset->bit_offset, ap1->offset->bit_width);
		GenStore(ap3, ap1->next, ssize);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1->next);
		ReleaseTempReg(ap1);
		MakeLegalAmode(ap3, flags, size);
		return (ap3);
	}
	ap1 = GenerateExpression(p[0], F_ALL & ~F_FPREG, ssize);
	ap2 = GenerateExpression(p[1], F_REG | F_IMMED, size);
	if (ap1->mode == am_reg) {
		GenerateTriadic(op, 0, ap1, ap1, ap2);
	}
	else {
		GenMemop(op, ap1, ap2, ssize);
	}
	ReleaseTempRegister(ap2);
	if (!ap1->isUnsigned && !(flags & F_NOVALUE)) {
		if (size > ssize) {
			if (ap1->mode != am_reg) {
				MakeLegalAmode(ap1, F_REG, ssize);
			}
			switch (ssize) {
			case 1:	GenerateDiadic(op_sxb, 0, ap1, ap1); break;
			case 2:	GenerateDiadic(op_sxc, 0, ap1, ap1); break;
			case 4:	GenerateDiadic(op_sxh, 0, ap1, ap1); break;
			}
			MakeLegalAmode(ap1, flags, size);
			return (ap1);
		}
		ap1->GenSignExtend(ssize, size, flags);
	}
	MakeLegalAmode(ap1, flags, size);
	return (ap1);
}

AMODE *ENODE::GenLand(int flags, int op)
{
	AMODE *ap1, *ap2, *ap3, *ap4, *ap5;

	ap3 = GetTempRegister();
	ap1 = GenerateExpression(p[0], flags, 8);
	ap4 = GetTempRegister();
	GenerateDiadic(op_redor, 0, ap4, ap1);
	ap2 = GenerateExpression(p[1], flags, 8);
	ap5 = GetTempRegister();
	GenerateDiadic(op_redor, 0, ap5, ap2);
	GenerateTriadic(op, 0, ap3, ap4, ap5);
	ReleaseTempReg(ap5);
	ReleaseTempReg(ap2);
	ReleaseTempReg(ap4);
	ReleaseTempReg(ap1);
	MakeLegalAmode(ap3, flags, 8);
	return (ap3);
}
