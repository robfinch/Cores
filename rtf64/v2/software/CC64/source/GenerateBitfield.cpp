// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2020  Robert Finch, Waterloo
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

Operand* ENODE::GenerateBitfieldDereference(int flags, int size, int opt)
{
	Operand* ap, * ap3, * ap4;
	int width = bit_width + 1;
	int isSigned;

	isSigned = !isUnsigned;
	ap3 = GetTempRegister();
	ap3->tempflag = TRUE;
	ap = cg.GenerateDereference(this, flags, esize, isSigned);
	ap->MakeLegal(flags, esize);
	ap->offset->bit_offset = bit_offset;
	ap->offset->bit_width = bit_width;
	if (opt)
		return (ap);
	if (ap->mode == am_reg)
		GenerateDiadic(op_mov, 0, ap3, ap);
	else if (ap->mode == am_imm)
		GenerateDiadic(op_ldi, 0, ap3, ap);
	else	// memory
		GenLoad(ap3, ap, esize, esize);
	ap4 = cg.GenerateBitfieldExtract(ap3, MakeImmediate((int64_t)bit_offset), MakeImmediate((int64_t)(bit_width - 1)));
	ReleaseTempReg(ap3);
	ap4->MakeLegal(flags, esize);
	ap4->next = ap;
	ap4->offset = this;
	return (ap4);
}

void ENODE::GenerateBitfieldInsert(Operand* ap1, Operand* ap2, int offset, int width)
{
	cg.GenerateBitfieldInsert(ap1, ap2, offset, width);
}

Operand *ENODE::GenerateBitfieldAssign(int flags, int size)
{
	Operand *ap1, *ap2 ,*ap3;

	// we don't want a bitfield dereference operation here.
	// We want all the bits.
	ap1 = cg.GenerateExpression(p[0],am_reg|am_mem|am_bf_assign,size);
	ap2 = cg.GenerateExpression(p[1],am_reg,size);
	if (ap1->mode == am_reg) {
		GenerateBitfieldInsert(ap1, ap2, p[0]->bit_offset, p[0]->bit_width);
	}
	else {
		ap3 = GetTempRegister();
		GenLoad(ap3,ap1,size,size);
		GenerateBitfieldInsert(ap3, ap2, p[0]->bit_offset, p[0]->bit_width);
		GenStore(ap3,ap1,size);
		ReleaseTempRegister(ap3);
	}
	ReleaseTempRegister(ap2);
	ap1->MakeLegal( flags, size);
	return (ap1);
}

Operand* ENODE::GenerateBitfieldAssignAdd(int flags, int size, int op)
{
	Operand* ap1, * ap2, * ap3, * ap4;
	int ssize;
	bool negf = false;
	bool intreg = false;
	MachineReg* mr;

	ssize = p[0]->GetNaturalSize();
	if (ssize > size)
		size = ssize;
	ap3 = GetTempRegister();
	ap4 = GetTempRegister();
	ap1 = cg.GenerateBitfieldDereference(p[0], am_reg | am_mem, size, 1);
	//		GenerateDiadic(op_mov, 0, ap3, ap1);
	//ap1 = cg.GenerateExpression(p[0], am_reg | am_mem, size);
	ap2 = cg.GenerateExpression(p[1], am_reg | am_imm, size);
	if (ap1->mode == am_reg) {
		GenerateTriadic(op, 0, ap1, ap1, ap2);
		GenerateBitfieldInsert(ap3, ap1, ap1->offset->bit_offset, ap1->offset->bit_width);
	}
	else {
		GenLoad(ap3, ap1, size, size);
		Generate4adic(op_bfext, 0, ap4, ap3, MakeImmediate(ap1->offset->bit_offset), MakeImmediate(ap1->offset->bit_width - 1));
		GenerateTriadic(op, 0, ap4, ap4, ap2);
		GenerateBitfieldInsert(ap3, ap4, ap1->offset->bit_offset, ap1->offset->bit_width);
		GenStore(ap3, ap1, ssize);
	}
	ReleaseTempReg(ap2);
	ReleaseTempReg(ap1);
	ReleaseTempReg(ap4);
	ap3->MakeLegal(flags, size);
	return (ap3);
}

Operand* ENODE::GenerateBitfieldAssignLogic(int flags, int size, int op)
{
	Operand* ap1, * ap2, * ap3;
	int ssize;
	MachineReg* mr;

	ssize = p[0]->GetNaturalSize();
	if (ssize > size)
		size = ssize;
	ap3 = GetTempRegister();
	ap1 = cg.GenerateBitfieldDereference(p[0], am_reg | am_mem, size, 1);
	switch (ap1->mode) {
	case am_ind:
	case am_indx:
	case am_indx2:
		cg.GenerateLoad(ap3, ap1, size, size);
		break;
	case am_reg:
		GenerateDiadic(op_mov, 0, ap3, ap1);
		break;
	}
	ap2 = cg.GenerateExpression(p[1], am_reg | am_imm, size);
	GenerateTriadic(op, 0, ap3, ap3, ap2);
	cg.GenerateBitfieldInsert(ap3, ap3, ap1->offset->bit_offset, ap1->offset->bit_width);
	GenStore(ap3, ap1, ssize);
	ReleaseTempReg(ap2);
	ReleaseTempReg(ap1->next);
	ReleaseTempReg(ap1);
	ap3->MakeLegal(flags, size);
	return (ap3);
}
