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
#include <stdio.h>
#include "c.h"
#include "expr.h"
#include "Statement.h"
#include "gen.h"
#include "cglbdec.h"

extern void GenStore(AMODE *, AMODE *, int);

// Setup the value to be shifted by sign/zero extending it.
// ToFix: for some reason the op is coming through as signed when it should be
// unsigned according to the type. So there's a fudge jump to fix this.

static void MaskShift(int op, AMODE *ap1, int size)
{
	switch(op) {
	case op_shru:
j1:
		switch (size) {
			case 1:	GenerateTriadic(op_andi,0,ap1,ap1,make_immed(0xff)); break;
			case 2:	GenerateTriadic(op_andi,0,ap1,ap1,make_immed(0xffff)); break;
			case 4:	GenerateTriadic(op_andi,0,ap1,ap1,make_immed(0xffffffff)); break;
			default:	;
		}
		break;
    case op_srl:
    case op_sra:
	case op_asr:
	case op_shr:
		if (isTable888|isFISA64) {
			if (ap1->isUnsigned)
				goto j1;
			switch (size) {
				case 1:	GenerateDiadic(op_sxb,0,ap1,ap1); break;
				case 2:	GenerateDiadic(op_sxc,0,ap1,ap1); break;
				case 4:	GenerateDiadic(op_sxh,0,ap1,ap1); break;
				default:	;
			}
		}
		else {
			switch (size) {
				case 1:	GenerateDiadic(op_sext8,0,ap1,ap1); break;
				case 2:	GenerateDiadic(op_sext16,0,ap1,ap1); break;
				case 4:	GenerateDiadic(op_sext32,0,ap1,ap1); break;
				default:	;
			}
		}
		break;
	}
}

AMODE *GenerateShift(ENODE *node,int flags, int size, int op)
{
	AMODE *ap1, *ap2;

    ap1 = GenerateExpression(node->p[0],F_REG,size);
    ap2 = GenerateExpression(node->p[1],F_REG | F_IMMED,8);
	MaskShift(op, ap1, GetNaturalSize(node->p[0]));
	if (ap2->mode==am_immed) {
		switch(op)
		{
        case op_asl:    op = op_asli; break;
        case op_sll:    op = op_slli; break;
		case op_shl:	op = op_shli; break;
		case op_shlu:	op = op_shlui; break;
		case op_asr:	op = op_asri; break;
		case op_sra:    op = op_srai; break;
		case op_shr:	op = op_shri; break;
		case op_shru:	op = op_shrui; break;
		case op_srl:    op = op_srli; break;
		case op_lsr:    op = op_lsri; break;
		}
		GenerateTriadic(op,0,ap1,ap1,make_immed(ap2->offset->i));
	}
	else
		GenerateTriadic(op,0,ap1,ap1,ap2);

	ReleaseTempRegister(ap2);
    MakeLegalAmode(ap1,flags,size);
    return ap1;
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
		if (isFISA64)
		    FISA64_GenLdi(ap1,ap2);
        else
		    GenerateDiadic(op_ldi,0,ap1,ap3);
	}
	else
        GenLoad(ap1,ap3,size);
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

