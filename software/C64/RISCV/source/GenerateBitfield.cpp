// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2019  Robert Finch, Waterloo
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
	GenerateDiadic(op_ldi,0,ap2,cg.MakeImmediate((int64_t)umask));
	GenerateTriadic(op_add,0,ap3,ap3,ap2);
	GenerateTriadic(op_xor,0,ap3,ap3,ap2);
	ReleaseTempRegister(ap2);
}

Operand *CodeGenerator::GenerateBitfieldDereference(ENODE *node, int flags, int size, int opt)
{
    Operand *ap, *ap3;
    int width = node->bit_width + 1;
	int isSigned;
	uint64_t mask;

	isSigned = !node->isUnsigned;
	mask = 0;
	while (--width)	mask = mask + mask + 1;
	ap3 = GetTempRegister();
	ap3->tempflag = TRUE;
  ap = GenerateDereference(node, flags, node->esize, isSigned);
  ap->MakeLegal(flags, node->esize);
	ap->offset->bit_offset = node->bit_offset;
	ap->offset->bit_width = node->bit_width;
	if (opt)
		return (ap);
	if (ap->mode == am_reg)
		GenerateDiadic(op_mov, 0, ap3, ap);
	else if (ap->mode == am_imm)
		GenerateDiadic(op_ldi, 0, ap3, ap);
	else	// memory
		GenLoad(ap3, ap, node->esize, node->esize);
//	ReleaseTempRegister(ap);
	if (cpu.SupportsBitfield) {
		if (isSigned)
			Generate4adic(op_bfext,0,ap3, ap3, MakeImmediate((int64_t) node->bit_offset), MakeImmediate((int64_t)(node->bit_width-1)));
		else
			Generate4adic(op_bfextu,0,ap3, ap3, MakeImmediate((int64_t) node->bit_offset), MakeImmediate((int64_t)(node->bit_width-1)));
	}
	else {
		if (node->bit_offset > 0)
			GenerateTriadic(op_stpru, 0, ap3, ap3, MakeImmediate((int64_t) node->bit_offset));
		GenerateTriadic(op_and, 0, ap3, ap3, MakeImmediate((int64_t)mask));
		if (isSigned)
			SignExtendBitfield(node, ap3, mask);
	}
	ap3->MakeLegal(flags, node->esize);
	ap3->next = ap;
	ap3->offset = node;
    return (ap3);
}

void CodeGenerator::GenerateBitfieldInsert(Operand *ap1, Operand *ap2, int offset, int width)
{
	int nn;
	uint64_t mask;

	/* Processor doesn't support bitfield insert except for immediates
	if (SUPPORT_BITFIELD)
		Generate4adic(op_bfins,0,ap1,ap2,MakeImmediate(offset), MakeImmediate(width-1));
	else
	*/
	{
		if (cpu.SupportsBitfield) {
			if (ap2->isConst) {
				if (ap2->offset->nodetype == en_icon) {
					if (ap2->offset->i == 0) {
						Generate4adic(op_bfclr, 0, ap1, ap1, MakeImmediate(offset), MakeImmediate(width - 1));
						return;
					}
					else if (ap2->offset->i == -1) {
						Generate4adic(op_bfset, 0, ap1, ap1, MakeImmediate(offset), MakeImmediate(width - 1));
						return;
					}
				}
			}
		}
		for (mask = nn = 0; nn < width; nn++)
			mask = (mask << 1) | 1;
		mask = ~mask;
		GenerateTriadic(op_and,0,ap2,ap2,MakeImmediate((int64_t)~mask));		// clear unwanted bits in source
		if (cpu.SupportsBitfield)
			Generate4adic(op_bfclr, 0, ap1, ap1, MakeImmediate(offset), MakeImmediate(width - 1));
		if (offset > 0)
			GenerateTriadic(op_ror,0,ap1,ap1,MakeImmediate((int64_t)offset));
		if (!cpu.SupportsBitfield)
			GenerateTriadic(op_and,0,ap1,ap1,MakeImmediate(mask));		// clear bits in target field
		GenerateTriadic(op_or,0,ap1,ap1,ap2);
		if (offset > 0)
			GenerateTriadic(op_rol,0,ap1,ap1,MakeImmediate((int64_t)offset));
	}
}

Operand *CodeGenerator::GenerateBitfieldAssign(ENODE *node, int flags, int size)
{
	Operand *ap1, *ap2 ,*ap3;

	// we don't want a bitfield dereference operation here.
	// We want all the bits.
	ap1 = node->p[0]->Generate(am_reg|am_mem|am_bf_assign,size);
	ap2 = node->p[1]->Generate(am_reg,size);
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
	return (ap1);
}

