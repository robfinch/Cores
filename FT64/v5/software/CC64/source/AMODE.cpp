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

AMODE *AMODE::Clone()
{
	AMODE *newap;

	if (this == NULL)
		return NULL;
	newap = allocAmode();
	memcpy(newap, this, sizeof(AMODE));
	return (newap);
}


//      compare two address nodes and return true if they are
//      equivalent.

bool AMODE::IsEqual(AMODE *ap1, AMODE *ap2)
{
	if (ap1 == nullptr || ap2 == nullptr)
		return (false);
	if (ap1->mode != ap2->mode && !((ap1->mode == am_ind && ap2->mode == am_indx) || (ap1->mode == am_indx && ap2->mode == am_ind)))
		return (false);
	switch (ap1->mode)
	{
	case am_immed:
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

char AMODE::fpsize()
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

void AMODE::GenZeroExtend(int isize, int osize)
{
	if (isize == osize)
		return;
	MakeLegalAmode(this, F_REG, isize);
	switch (osize)
	{
	case 1:	GenerateDiadic(op_zxb, 0, this, this); break;
	case 2:	GenerateDiadic(op_zxc, 0, this, this); break;
	case 4:	GenerateDiadic(op_zxh, 0, this, this); break;
	}
}

void AMODE::GenSignExtend(int isize, int osize, int flags)
{
	AMODE *ap1;
	AMODE *ap = this;

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
		//MakeLegalAmode(ap,flags & (F_REG|F_FPREG),isize);
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
