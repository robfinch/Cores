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

char AMODE::fpsize()
{
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
