// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2015  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - 'C' derived language compiler
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

static void SignExtendBitfield(ENODE *node, AMODE *ap3, int64_t mask)
{
	AMODE *ap2;
	int64_t umask;

	umask = 0x8000000000000000L | ~(mask >> 1);
	ap2 = GetTempRegister();
	if (isRaptor64)
		GenerateTriadic(op_ori,0,ap2,makereg(0),make_immed(umask));
	else if (isFISA64)
	     FISA64_GenLdi(ap2,make_immed(umask));
	else
		GenerateDiadic(op_ldi,0,ap2,make_immed(umask));
	GenerateTriadic(op_add,0,ap3,ap3,ap2);
	GenerateTriadic(isTable888?op_eor:op_xor,0,ap3,ap3,ap2);
	ReleaseTempRegister(ap2);
}

AMODE *GenerateBitfieldDereference(ENODE *node, int flags, int size)
{
    AMODE *ap, *ap1,*ap2,*ap3;
    long            mask,umask;
    int             width = node->bit_width + 1;
	int isSigned;

	isSigned = node->nodetype==en_wfieldref || node->nodetype==en_hfieldref || node->nodetype==en_cfieldref || node->nodetype==en_bfieldref;
	mask = 0;
	while (--width)	mask = mask + mask + 1;
    ap = GenerateDereference(node, flags, node->esize, isSigned);
    MakeLegalAmode(ap, flags, node->esize);
	ap3 = GetTempRegister();
	if (isRaptor64)
		GenerateTriadic(op_or,0,ap3,ap,makereg(0));
	else
		GenerateDiadic(op_mov,0,ap3,ap);
	ReleaseTempRegister(ap);
	if (isTable888||isRaptor64||isFISA64) {
		if (node->bit_offset > 0)
			GenerateDiadic(isFISA64?op_lsr:op_shru, 0, ap3, make_immed((int64_t) node->bit_offset));
		GenerateDiadic(op_andi, 0, ap3, make_immed(mask));
		if (isSigned)
			SignExtendBitfield(node, ap3, mask);
	}
	else {
//    if (node->bit_offset > 0) {
//		GenerateDiadic(op_shru, 0, ap3, make_immed((__int64) node->bit_offset));
//		GenerateDiadic(op_and, 0, ap3, make_immed(mask));
		//MakeLegalAmode(ap, flags, node->esize);
		if (isSigned)
			Generate4adic(op_bfext,0,ap3,ap,make_immed((int64_t) node->bit_offset),make_immed((int64_t) node->bit_offset+node->bit_width));
		else
			Generate4adic(op_bfextu,0,ap3,ap,make_immed((int64_t) node->bit_offset),make_immed((int64_t) node->bit_offset+node->bit_width));
	}
	MakeLegalAmode(ap3, flags, node->esize);
    return ap3;
}

AMODE *GenerateBitfieldAssign(ENODE *node, int flags, int size)
{
	struct amode    *ap1, *ap2 ,*ap3, *ap4;
        int             ssize;
		ENODE *ep;
		long            mask;
		int             i;

	ap1 = GenerateExpression(node->p[0],F_ALL & ~F_BREG,size);
	ap2 = GenerateExpression(node->p[1],F_REG,size);
	if (ap1->mode == am_reg) {
		Generate4adic(op_bfins,0,ap1,ap2,make_immed((long) node->p[0]->bit_offset),
			make_immed((long)node->p[0]->bit_offset + node->p[0]->bit_width - 1));
		ReleaseTempRegister(ap2);
		return ap1;
	}
	else {
		ap3 = GetTempRegister();
		switch(size) {
		case 1:	GenerateDiadic(op_lb,0,ap3,ap1); break;
		case 2:	GenerateDiadic(op_lc,0,ap3,ap1); break;
		case 4: GenerateDiadic(op_lh,0,ap3,ap1); break;
		case 8:	GenerateDiadic(op_lw,0,ap3,ap1); break;
		}
		Generate4adic(op_bfins,0,ap3,ap2,make_immed((long) node->p[0]->bit_offset),
			make_immed((long)node->p[0]->bit_offset + node->p[0]->bit_width - 1));
		switch(size) {
		case 1:	GenerateDiadic(op_sb,0,ap3,ap1); break;
		case 2:	GenerateDiadic(op_sc,0,ap3,ap1); break;
		case 4: GenerateDiadic(op_sh,0,ap3,ap1); break;
		case 8:	GenerateDiadic(op_sw,0,ap3,ap1); break;
		}
		ReleaseTempRegister(ap3);
		ReleaseTempRegister(ap2);
		return ap1;
	}

	/* get the value */
	ap1 = GenerateExpression(node->p[1],F_REG,size);

//	ap1 = GenerateExpression(node->p[1], F_REG | F_VOL,8);
	if (!(flags & F_NOVALUE)) {
		/*
		* result value needed
		*/
		ap3 = GetTempRegister();
		GenerateDiadic(op_mov, 0, ap3, ap1);
	} else
	ap3 = ap1;
	ep = makenode(en_w_ref, node->p[0]->p[0], (ENODE *)NULL);
	ap2 = GenerateExpression(ep, F_MEM,8);
	if (ap2->mode == am_reg) {
		Generate4adic(op_bfins,0,ap2,ap1,make_immed((long) node->p[0]->bit_offset),
			make_immed((long)node->p[0]->bit_offset + node->p[0]->bit_width - 1));
	}
	else {
		ap4 = GetTempRegister();
		switch(size) {
		case 1:	GenerateDiadic(op_lb,0,ap4,ap2);
		case 2:	GenerateDiadic(op_lc,0,ap4,ap2);
		case 4:	GenerateDiadic(op_lh,0,ap4,ap2);
		case 8: GenerateDiadic(op_lw,0,ap4,ap2);
		}
		Generate4adic(op_bfins,0,ap4,ap1,make_immed((long) node->p[0]->bit_offset),
			make_immed((long)node->p[0]->bit_offset + node->p[0]->bit_width - 1));
		GenStore(ap4,ap2,size);
		ReleaseTempRegister(ap4);
	}
	ReleaseTempRegister(ap2);
	if (!(flags & F_NOVALUE)) {
		ReleaseTempRegister(ap3);
	}
	MakeLegalAmode(ap1, flags, size);
	return ap1;
}

