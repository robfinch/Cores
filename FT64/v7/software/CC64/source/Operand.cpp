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

Operand *Operand::Clone()
{
	Operand *newap;

	if (this == NULL)
		return NULL;
	newap = allocOperand();
	memcpy(newap, this, sizeof(Operand));
	return (newap);
}


//      compare two address nodes and return true if they are
//      equivalent.

bool Operand::IsEqual(Operand *ap1, Operand *ap2)
{
	if (ap1 == nullptr || ap2 == nullptr)
		return (false);
	if (ap1->mode != ap2->mode && !((ap1->mode == am_ind && ap2->mode == am_indx) || (ap1->mode == am_indx && ap2->mode == am_ind)))
		return (false);
	switch (ap1->mode)
	{
	case am_imm:
		return (ap1->offset->i == ap2->offset->i);
	case am_fpreg:
	case am_reg:
		return (ap1->preg == ap2->preg);
	case am_ind:
	case am_indx:
		if (ap1->preg != ap2->preg)
			return (false);
		if (ap1->offset == ap2->offset)
			return (true);
		if (ap1->offset == nullptr || ap2->offset == nullptr)
			return (false);
		if (ap1->offset->i != ap2->offset->i)
			return (false);
		return (true);
	}
	return (false);
}

char Operand::fpsize()
{
	if (type == stddouble.GetIndex())
		return 'd';
	if (type == stdquad.GetIndex())
		return 'q';
	if (type == stdflt.GetIndex())
		return 's';
	if (type == stdtriple.GetIndex())
		return 't';

	if (FloatSize)
		return (FloatSize);
	if (offset == nullptr)
		return ('d');
	if (offset->tp == nullptr)
		return ('d');
	switch (offset->tp->precision) {
	case 32:	return ('s');
	case 64:	return ('d');
	case 96:	return ('t');
	case 128:	return ('q');
	default:	return ('d');
	}
}

void Operand::GenZeroExtend(int isize, int osize)
{
	if (isize == osize)
		return;
	MakeLegal(F_REG, isize);
	switch (osize)
	{
	case 1:	GenerateDiadic(op_zxb, 0, this, this); break;
	case 2:	GenerateDiadic(op_zxc, 0, this, this); break;
	case 4:	GenerateDiadic(op_zxh, 0, this, this); break;
	}
}

void Operand::GenSignExtend(int isize, int osize, int flags)
{
	Operand *ap1;
	Operand *ap = this;

	if (isize == osize)
		return;
	if (ap->isUnsigned)
		return;
	if (ap->mode != am_reg && ap->mode != am_fpreg) {
		ap1 = GetTempRegister();
		GenLoad(ap1, ap, isize, isize);
		switch (isize)
		{
		case 1:	GenerateDiadic(op_sxb, 0, ap1, ap1); break;
		case 2:	GenerateDiadic(op_sxc, 0, ap1, ap1); break;
		case 4:	GenerateDiadic(op_sxh, 0, ap1, ap1); break;
		}
		GenStore(ap1, ap, osize);
		ReleaseTempRegister(ap1);
		return;
		//MakeLegalOperand(ap,flags & (F_REG|F_FPREG),isize);
	}
	if (ap->type == stddouble.GetIndex()) {
		switch (isize) {
		case 4:	GenerateDiadic(op_fs2d, 0, ap, ap); break;
		}
	}
	else {
		switch (isize)
		{
		case 1:	GenerateDiadic(op_sxb, 0, ap, ap); break;
		case 2:	GenerateDiadic(op_sxc, 0, ap, ap); break;
		case 4:	GenerateDiadic(op_sxh, 0, ap, ap); break;
		}
	}
}

// ----------------------------------------------------------------------------
// MakeLegal will coerce the addressing mode in ap1 into a mode that is
// satisfactory for the flag word.
// ----------------------------------------------------------------------------
void Operand::MakeLegal(int flags, int size)
{
	Operand *ap2, *ap1;
	int64_t i;

	if (this == nullptr)
		return;

	//	if (flags & F_NOVALUE) return;
	if (((flags & F_VOL) == 0) || tempflag)
	{
		switch (mode) {
		case am_imm:
			i = ((ENODE *)(offset))->i;
			if (flags & F_IMM8) {
				if (i < 256 && i >= 0)
					return;
			}
			else if (flags & F_IMM6) {
				if (i < 64 && i >= 0)
					return;
			}
			else if (flags & F_IMM0) {
				if (i == 0)
					return;
			}
			else if (flags & F_IMMED)
				return;         /* mode ok */
			break;
		case am_reg:
			if (flags & F_REG)
				return;
			break;
		case am_fpreg:
			if (flags & F_FPREG)
				return;
			break;
		case am_ind:
		case am_indx:
		case am_indx2:
		case am_direct:
			if (flags & F_MEM)
				return;
			break;
		}
	}

	if (flags & F_REG)
	{
		if (mode == am_reg)	// Might get this if F_VOL specified
			return;
		ReleaseTempRegister(this);      // maybe we can use it...
		if (this)
			ap2 = GetTempRegister();// GetTempReg(ap->type);
		else
			ap2 = GetTempReg(stdint.GetIndex());
		switch (mode) {
		case am_ind:
		case am_indx:
			GenLoad(ap2, this, size, size);
			break;
		case am_imm:
			GenerateDiadic(op_ldi, 0, ap2, this);
			break;
		case am_reg:
			GenerateDiadic(op_mov, 0, ap2, this);
			break;
		case am_fpreg:
			GenerateDiadic(op_ftoi, fpsize(), ap2, this);
			break;
		default:
			GenLoad(ap2, this, size, size);
			break;
		}
		mode = am_reg;
		type = stdint.GetIndex();
		preg = ap2->preg;
		deep = ap2->deep;
		pdeep = ap2->pdeep;
		tempflag = 1;
		return;
	}
	if (flags & F_FPREG)
	{
		if (mode == am_fpreg)
			return;
		ReleaseTempReg(this);      /* maybe we can use it... */
		ap2 = GetTempFPRegister();
		switch (mode) {
		case am_ind:
		case am_indx:
			GenLoad(ap2, this, size, size);
			break;
		case am_imm:
			ap1 = GetTempRegister();
			GenerateDiadic(op_ldi, 0, ap1, this);
			GenerateDiadic(op_mov, 0, ap2, ap1);
			ReleaseTempReg(ap1);
			break;
		case am_reg:
			GenerateDiadic(op_itof, ap2->fpsize(), ap2, this);
			break;
		default:
			GenLoad(ap2, this, size, size);
			break;
		}
		mode = am_fpreg;
		switch (ap2->fpsize()) {
		case 'd':	type = stddouble.GetIndex(); break;
		case 's': type = stddouble.GetIndex(); break;
		case 't': type = stdtriple.GetIndex(); break;
		case 'q':	type = stdquad.GetIndex(); break;
		default:	type = stddouble.GetIndex(); break;
		}
		preg = ap2->preg;
		deep = ap2->deep;
		pdeep = ap2->pdeep;
		tempflag = 1;
		return;
	}
	// Here we wanted the mode to be non-register (memory/immed)
	// Should fix the following to place the result in memory and
	// not a register.
	if (size == 1)
	{
		ReleaseTempRegister(this);
		ap2 = GetTempRegister();
		GenerateDiadic(op_mov, 0, ap2, this);
		if (isUnsigned)
			GenerateTriadic(op_and, 0, ap2, ap2, make_immed(255));
		else {
			GenerateDiadic(op_sext8, 0, ap2, ap2);
		}
		mode = ap2->mode;
		preg = ap2->preg;
		deep = ap2->deep;
		pdeep = ap2->pdeep;
		size = 2;
	}
	ap2 = GetTempRegister();
	switch (mode) {
	case am_ind:
	case am_indx:
		GenLoad(ap2, this, size, size);
		break;
	case am_imm:
		GenerateDiadic(op_ldi, 0, ap2, this);
		break;
	case am_reg:
		GenerateDiadic(op_mov, 0, ap2, this);
		break;
	default:
		GenLoad(ap2, this, size, size);
	}
	mode = am_reg;
	preg = ap2->preg;
	deep = ap2->deep;
	pdeep = ap2->pdeep;
	tempflag = 1;
	//     Leave("MkLegalOperand",0);
}

void Operand::storeHex(txtoStream& ofs)
{
	ofs.printf("O");
	switch (mode) {
	case am_imm:
		ofs.printf("#");
	}
}

Operand *Operand::loadHex(std::ifstream& ifs)
{
	Operand *oper;

	oper = allocOperand();
	return (oper);
}


void Operand::store(txtoStream& ofs)
{
	if (mode == 0)
		mode = am_reg;
	switch (mode)
	{
	case am_imm:
		ofs.write("#");
		// Fall through
	case am_direct:
		offset->PutConstant(ofs, lowhigh, rshift);
		break;
	case am_reg:
		if (type == stdvector.GetIndex())
			ofs.printf("v%d", (int)preg);
		else if (type == stdvectormask->GetIndex())
			ofs.printf("vm%d", (int)preg);
		else if (type == stddouble.GetIndex())
			ofs.printf("$fp%d", (int)preg);
		else {
			ofs.write(RegMoniker(preg));
			//if (renamed)
			//	ofs.printf(".%d", (int)pregs);
		}
		break;
	case am_vmreg:
		ofs.printf("vm%d", (int)preg);
		break;
	case am_fpreg:
		ofs.printf("$fp%d", (int)preg);
		break;
	case am_ind:
		ofs.printf("[%s]", RegMoniker(preg));
		break;
	case am_indx:
		// It's not known the function is a leaf routine until code
		// generation time. So the parameter offsets can't be determined
		// until code is being output. This bit of code first adds onto
		// parameter offset the size of the return block, then later
		// subtracts it off again.
		if (offset) {
			if (preg == regFP) {
				if (offset->sym) {
					if (offset->sym->IsParameter) {	// must be an parameter
						offset->i += Compiler::GetReturnBlockSize();
					}
				}
			}
			offset->PutConstant(ofs, 0, 0);
			if (preg == regFP) {
				if (offset->sym) {
					if (offset->sym->IsParameter) {
						offset->i -= Compiler::GetReturnBlockSize();
					}
				}
			}
		}
		ofs.printf("[%s]", RegMoniker(preg));
		break;

	case am_indx2:
		if (scale == 1 || scale == 0)
			ofs.printf("[%s+%s]", RegMoniker(sreg), RegMoniker(preg));
		else
			ofs.printf("[%s+%s*%d]", RegMoniker(sreg), RegMoniker(preg), scale);
		break;

//	case am_mask:
//		put_mask((int)offset);
//		break;
	default:
		printf("DIAG - illegal address mode.\n");
		break;
	}
}

