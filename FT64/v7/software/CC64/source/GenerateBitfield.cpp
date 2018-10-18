// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Waterloo
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
#define SUPPORT_BITFIELD	false

static void SignExtendBitfield(ENODE *node, Operand *ap3, uint64_t mask)
{
	Operand *ap2;
	uint64_t umask;

	umask = 0x8000000000000000LL | ~(mask >> 1);
	ap2 = GetTempRegister();
	GenerateDiadic(op_ldi,0,ap2,make_immed(umask));
	GenerateTriadic(op_add,0,ap3,ap3,ap2);
	GenerateTriadic(op_xor,0,ap3,ap3,ap2);
	ReleaseTempRegister(ap2);
}

Operand *GenerateBitfieldDereference(ENODE *node, int flags, int size)
{
    Operand *ap, *ap3;
    int width = node->bit_width + 1;
	int isSigned;
	uint64_t mask;

	isSigned = node->nodetype==en_wfieldref || node->nodetype==en_hfieldref || node->nodetype==en_cfieldref || node->nodetype==en_bfieldref;
	mask = 0;
	while (--width)	mask = mask + mask + 1;
	ap3 = GetTempRegister();
	ap3->tempflag = TRUE;
    ap = GenerateDereference(node, flags, node->esize, isSigned);
    ap->MakeLegal(flags, node->esize);
	if (ap->mode == am_reg)
		GenerateDiadic(op_mov, 0, ap3, ap);
	else if (ap->mode == am_imm)
		GenerateDiadic(op_ldi, 0, ap3, ap);
	else	// memory
		GenLoad(ap3, ap, node->esize, node->esize);
//	ReleaseTempRegister(ap);
	if (SUPPORT_BITFIELD) {
		if (isSigned)
			Generate4adic(op_bfext,0,ap3, ap3, make_immed((int) node->bit_offset), make_immed((int)(node->bit_width-1)));
		else
			Generate4adic(op_bfextu,0,ap3, ap3, make_immed((int) node->bit_offset), make_immed((int)(node->bit_width-1)));
	}
	else {
		if (node->bit_offset > 0)
			GenerateTriadic(op_shru, 0, ap3, ap3, make_immed((int) node->bit_offset));
		GenerateTriadic(op_and, 0, ap3, ap3, make_immed(mask));
		if (isSigned)
			SignExtendBitfield(node, ap3, mask);
	}
	ap3->MakeLegal(flags, node->esize);
	ap3->next = ap;
	ap3->offset = node;
    return (ap3);
}

void GenerateBitfieldInsert(Operand *ap1, Operand *ap2, int offset, int width)
{
	int nn;
	uint64_t mask;

	/* Processor doesn't support bitfield insert except for immediates
	if (SUPPORT_BITFIELD)
		Generate4adic(op_bfins,0,ap1,ap2,make_immed(offset), make_immed(width-1));
	else
	*/
	{
		for (mask = nn = 0; nn < width; nn++)
			mask = (mask << 1) | 1;
		mask = ~mask;
		GenerateDiadic(op_and,0,ap2,make_immed(~mask));		// clear unwanted bits in source
		if (offset > 0)
			GenerateTriadic(op_ror,0,ap1,ap1,make_immed(offset));
		GenerateTriadic(op_and,0,ap1,ap1,make_immed(mask));		// clear bits in target field
		GenerateTriadic(op_or,0,ap1,ap1,ap2);
		if (offset > 0)
			GenerateTriadic(op_rol,0,ap1,ap1,make_immed(offset));
	}
}

Operand *GenerateBitfieldAssign(ENODE *node, int flags, int size)
{
	Operand *ap1, *ap2 ,*ap3;

	// we don't want a bitfield dereference operation here.
	// We want all the bits.
	ap1 = GenerateExpression(node->p[0],F_REG|F_MEM|BF_ASSIGN,size);
	ap2 = GenerateExpression(node->p[1],F_REG,size);
	if (ap1->mode == am_reg) {
		GenerateBitfieldInsert(ap1, ap2, node->p[0]->bit_offset, node->p[0]->bit_width);
	}
	else {
		ap3 = GetTempRegister();
		GenLoad(ap3,ap1,size,size);
		GenerateBitfieldInsert(ap3, ap2, node->p[0]->bit_offset, node->p[0]->bit_width);
		GenStore(ap3,ap1,size);
		ReleaseTempRegister(ap3);
	}
	ReleaseTempRegister(ap2);
	ap1->MakeLegal( flags, size);
	return ap1;
}

