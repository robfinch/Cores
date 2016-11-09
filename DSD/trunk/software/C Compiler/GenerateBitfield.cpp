// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Stratford
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
	int umask;

	umask = 0x80000000 | ~(mask >> 1);
	ap2 = GetTempRegister();
	GenerateDiadic(op_ldi,0,ap2,make_immed(umask));
	GenerateTriadic(op_add,0,ap3,ap3,ap2);
	GenerateTriadic(op_xor,0,ap3,ap3,ap2);
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
	GenerateDiadic(op_mov,0,ap3,ap);
	ReleaseTempRegister(ap);
	if (node->bit_offset > 0)
		GenerateDiadic(op_shru, 0, ap3, make_immed((int) node->bit_offset));
	GenerateDiadic(op_andi, 0, ap3, make_immed(mask));
	if (isSigned)
		SignExtendBitfield(node, ap3, mask);
	MakeLegalAmode(ap3, flags, node->esize);
    return ap3;
}

void GenerateBitfieldInsert(AMODE *ap1, AMODE *ap2, int offset, int width)
{
	int mask;
	int nn;

	for (mask = nn = 0; nn < width; nn++)
		mask = (mask << 1) | 1;
	mask = ~mask;
	GenerateTriadic(op_ror,0,ap1,ap1,make_immed(offset));
	GenerateTriadic(op_andi,0,ap1,ap1,make_immed(mask));
	GenerateTriadic(op_or,0,ap1,ap1,ap2);
	GenerateTriadic(op_rol,0,ap1,ap2,make_immed(offset));
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
		GenerateBitfieldInsert(ap1, ap2, node->p[0]->bit_offset, node->p[0]->bit_width);
		ReleaseTempRegister(ap2);
		return ap1;
	}
	else {
		ap3 = GetTempRegister();
		switch(size) {
		case 1:	GenerateDiadic(op_lh,0,ap3,ap1); break;
		case 2:	GenerateDiadic(op_lw,0,ap3,ap1); break;
		}
		GenerateBitfieldInsert(ap3, ap2, node->p[0]->bit_offset, node->p[0]->bit_width);
		switch(size) {
		case 1:	GenerateDiadic(op_sh,0,ap3,ap1); break;
		case 2:	GenerateDiadic(op_sw,0,ap3,ap1); break;
		}
		ReleaseTempRegister(ap3);
		ReleaseTempRegister(ap2);
		return ap1;
	}

	/* get the value */
	ap1 = GenerateExpression(node->p[1],F_REG,size);

//	ap1 = GenerateExpression(node->p[1], F_REG | F_VOL,2);
	if (!(flags & F_NOVALUE)) {
		/*
		* result value needed
		*/
		ap3 = GetTempRegister();
		GenerateDiadic(op_mov, 0, ap3, ap1);
	} else
	ap3 = ap1;
	ep = makenode(en_w_ref, node->p[0]->p[0], (ENODE *)NULL);
	ap2 = GenerateExpression(ep, F_MEM,2);
	if (ap2->mode == am_reg) {
		GenerateBitfieldInsert(ap2, ap1, node->p[0]->bit_offset, node->p[0]->bit_width);
	}
	else {
		ap4 = GetTempRegister();
		switch(size) {
		case 1:	GenerateDiadic(op_lh,0,ap4,ap2);
		case 2:	GenerateDiadic(op_lw,0,ap4,ap2);
		}
		GenerateBitfieldInsert(ap4, ap1, node->p[0]->bit_offset, node->p[0]->bit_width);
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

