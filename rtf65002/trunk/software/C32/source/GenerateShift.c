// ============================================================================
// (C) 2012,2013 Robert Finch
// All Rights Reserved.
// robfinch<remove>@opencores.org
//
// C32 - RTF65002 'C' derived language compiler
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
#include <stdio.h>
#include "c.h"
#include "expr.h"
#include "Statement.h"
#include "gen.h"
#include "cglbdec.h"


AMODE *GenerateShift(ENODE *node,int flags, int size, int op)
{
	AMODE *ap1, *ap2, *ap3;

 	ap3 = GetTempRegister();
    ap1 = GenerateExpression(node->p[0],F_REG,size);
    ap2 = GenerateExpression(node->p[1],F_REG | F_IMMED,1);

	if (ap2->mode==am_immed)
		GenerateTriadic(op,0,ap3,ap1,make_immed(ap2->offset->i));
	else
		GenerateTriadic(op,0,ap3,ap1,ap2);
	validate(ap1);
    ReleaseTempRegister(ap2);
    ReleaseTempRegister(ap1);
    return MakeLegalAmode(ap3,flags,size);
}


/*
 *      generate shift equals operators.
 */
AMODE *GenerateAssignShift(ENODE *node,int flags,int size,int op)
{
	struct amode    *ap1, *ap2, *ap3;

    ap3 = GenerateExpression(node->p[0],F_ALL,size);
    ap2 = GenerateExpression(node->p[1],F_REG | F_IMMED,size);
	if (ap3->mode != am_reg) {
		ap1 = GetTempRegister();
		GenerateDiadic(op_ld,0,ap1,ap3);
	}
	else
		ap1 = ap3;
	if (ap2->mode==am_immed)
		GenerateTriadic(op,0,ap1,ap1,make_immed(ap2->offset->i));
	else
		GenerateTriadic(op,0,ap1,ap1,ap2);
	if (ap3->mode != am_reg) {
		GenerateDiadic(op_st,0,ap1,ap3);
	}
  	validate(ap3);
	ReleaseTempRegister(ap2);
    return MakeLegalAmode(ap1,flags,size);
}

