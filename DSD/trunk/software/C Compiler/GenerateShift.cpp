// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C32 - 'C' derived language compiler
//  - 32 bit CPU
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


// Setup the value to be shifted by sign/zero extending it.
// ToFix: for some reason the op is coming through as signed when it should be
// unsigned according to the type. So there's a fudge jump to fix this.

static void MaskShift(int op, AMODE *ap1, int size)
{
	switch(op) {
	case op_shru:
j1:
		switch (size) {
			case 1:	GenerateTriadic(op_and,0,ap1,ap1,make_immed(0xffff)); break;
			default:	;
		}
		break;
    case op_srl:
    case op_sra:
	case op_asr:
	case op_shr:
		if (isTable888|isFISA64|isThor) {
			if (ap1->isUnsigned)
				goto j1;
			switch (size) {
				case 1:	GenerateDiadic(op_sxc,0,ap1,ap1); break;
				default:	;
			}
		}
		else {
			switch (size) {
				case 1:	GenerateDiadic(op_sext16,0,ap1,ap1); break;
				default:	;
			}
		}
		break;
	}
}

AMODE *GenerateShift(ENODE *node,int flags, int size, int op)
{
	AMODE *ap1, *ap2, *ap3;

    ap3 = GetTempRegister();
    ap1 = GenerateExpression(node->p[0],F_REG,size);
    ap2 = GenerateExpression(node->p[1],F_REG | F_IMMED,2);
	MaskShift(op, ap1, GetNaturalSize(node->p[0]));
	GenerateTriadic(op,0,ap3,ap1,ap2);
	ReleaseTempRegister(ap2);
	ReleaseTempRegister(ap1);
    MakeLegalAmode(ap3,flags,size);
    return ap3;
}


/*
 *      generate shift equals operators.
 */
AMODE *GenerateAssignShift(ENODE *node,int flags,int size,int op)
{
	struct amode    *ap1, *ap2, *ap3;

	ap1 = GetTempRegister();
	//size = GetNaturalSize(node->p[0]);
    ap3 = GenerateExpression(node->p[0],F_ALL,size);
    ap2 = GenerateExpression(node->p[1],F_REG | F_IMMED,size);
	if (ap3->mode==am_reg)
		GenerateDiadic(op_mov,0,ap1,ap3);
	else if (ap3->mode == am_immed) {
		error(ERR_LVALUE);
	    GenerateDiadic(op_ld,0,ap1,ap3);
	}
	else
        GenLoad(ap1,ap3,size,size);
	MaskShift(op, ap1, size);
	if (ap2->mode==am_immed)
		GenerateTriadic(op,0,ap1,ap1,make_immed(ap2->offset->i));
	else
		GenerateTriadic(op,0,ap1,ap1,ap2);
	if (ap3->mode != am_reg)
        GenStore(ap1,ap3,size);
    ReleaseTempRegister(ap2);
    ReleaseTempRegister(ap3);
    MakeLegalAmode(ap1,flags,size);
    return ap1;
}

