// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - 'C' derived language compiler
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

AMODE *GenerateShift(ENODE *node,int flags, int size)
{
	AMODE *ap1, *ap2, *ap3;
	int nn;
	int lab1;
	int op1, op2;

	ap3 = GetTempRegister();
	if (size==2)
		ap3->amode2 = GetTempRegister();
    ap1 = GenerateExpression(node->p[0],F_REG|F_MEM,size);
    ap2 = GenerateExpression(node->p[1],F_REG|F_MEM|F_IMMED,sizeOfWord);
	if (ap1->mode==am_reg) {
		if (ap3->mode==am_reg)
			GenerateDiadic(op_mov,0,ap3,ap1);
		else
			GenerateDiadic(op_sto,0,ap1,ap3);
	}
	else {
		if (ap3->mode==am_reg)
			GenerateDiadic(op_ld,0,ap3,ap1);
		else {
			GenerateDiadic(op_ld,0,makereg(1),ap1);
			GenerateDiadic(op_sto,0,makereg(1),ap3);
		}
	}
	if (size==2) {
		if (ap1->mode==am_reg) {
			if (ap3->mode==am_reg)
				GenerateDiadic(op_mov,0,ap3->amode2,ap1->amode2);
			else
				GenerateDiadic(op_ld,0,ap3->amode2,ap1->amode2);
		}
		else {
			if (ap3->mode==am_reg)
				GenerateDiadic(op_ld,0,ap3->amode2,ap1->amode2);
			else {
				GenerateDiadic(op_ld,0,makereg(1),ap1->amode2);
				GenerateDiadic(op_sto,0,makereg(1),ap3->amode2);
			}
		}
	}

	switch (node->nodetype) {
	case en_shl:
	case en_shlu:
		op1 = op_add;
		op2 = op_adc;
		break;
	case en_shr:
	case en_shru:
		op1 = op_lsr;
		op2 = op_ror;
		break;
	case en_asr:
		op1 = op_asr;
		op2 = op_ror;
		break;
	}

	switch (node->nodetype) {
	case en_shl:
	case en_shlu:
		switch(ap2->mode) {
		case am_immed:
			if (ap3->mode==am_reg) {
				for (nn = 0; nn < ap2->offset->i && nn < 33; nn++) {
					GenerateDiadic(op1,0,ap3,ap3);
					if (size==2)
						GenerateDiadic(op2,0,ap3->amode2,ap3->amode2);
				}
			}
			else {
				GenerateDiadic(op_ld,0,makereg(1),ap3);
				if (size==2)
					GenerateDiadic(op_ld,0,makereg(2),ap3->amode2);
				for (nn = 0; nn < ap2->offset->i && nn < 33; nn++) {
					GenerateDiadic(op1,0,makereg(1),makereg(1));
					if (size==2)
						GenerateDiadic(op2,0,makereg(2),makereg(2));
				}
				GenerateDiadic(op_sto,0,makereg(1),ap3);
				if (size==2)
					GenerateDiadic(op_sto,0,makereg(2),ap3->amode2);
			}
			ReleaseTempRegister(ap2);
			ReleaseTempRegister(ap1);
			MakeLegalAmode(ap3,flags,size);
			return (ap3);
		case am_reg:
			lab1 = nextlabel++;
			if (ap3->mode==am_reg) {
				GenerateLabel(lab1);
				GenerateDiadic(op1,0,ap3,ap3);
				if (size==2)
					GenerateDiadic(op2,0,ap3->amode2,ap3->amode2);
				GenerateTriadic(op_sub,0,ap2,makereg(regZero),make_immed(1));
				GeneratePredicatedTriadic(pop_nz,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab1));
			}
			else {
				GenerateDiadic(op_ld,0,makereg(1),ap3);
				if (size==2)
					GenerateDiadic(op_ld,0,makereg(2),ap3->amode2);
				GenerateLabel(lab1);
				GenerateDiadic(op1,0,makereg(1),makereg(1));
				if (size==2)
					GenerateDiadic(op2,0,makereg(2),makereg(2));
				GenerateTriadic(op_sub,0,ap2,makereg(regZero),make_immed(1));
				GeneratePredicatedTriadic(pop_nz,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab1));
				GenerateDiadic(op_sto,0,makereg(1),ap3);
				if (size==2)
					GenerateDiadic(op_sto,0,makereg(2),ap3->amode2);
			}
			ReleaseTempRegister(ap2);
			ReleaseTempRegister(ap1);
			MakeLegalAmode(ap3,flags,size);
			return (ap3);
		default:	// memory
			lab1 = nextlabel++;
			GenerateMonadic(op_push,0,makereg(3));
			GenerateDiadic(op_ld,0,makereg(3),ap2);
			if (ap3->mode==am_reg) {
				GenerateLabel(lab1);
				GenerateDiadic(op1,0,ap3,ap3);
				if (size==2)
					GenerateDiadic(op2,0,ap3->amode2,ap3->amode2);
				GenerateTriadic(op_sub,0,makereg(3),makereg(regZero),make_immed(1));
				GeneratePredicatedTriadic(pop_nz,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab1));
			}
			else {
				GenerateDiadic(op_ld,0,makereg(1),ap3);
				if (size==2)
					GenerateDiadic(op_ld,0,makereg(2),ap3->amode2);
				GenerateLabel(lab1);
				GenerateDiadic(op1,0,makereg(1),makereg(1));
				if (size==2)
					GenerateDiadic(op2,0,makereg(2),makereg(2));
				GenerateTriadic(op_sub,0,makereg(3),makereg(regZero),make_immed(1));
				GeneratePredicatedTriadic(pop_nz,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab1));
				GenerateDiadic(op_sto,0,makereg(1),ap3);
				if (size==2)
					GenerateDiadic(op_sto,0,makereg(2),ap3->amode2);
			}
			GenerateMonadic(op_pop,0,makereg(3));
			ReleaseTempRegister(ap2);
			ReleaseTempRegister(ap1);
			MakeLegalAmode(ap3,flags,size);
			return (ap3);
		}
		break;
	case en_shru:
	case en_shr:
	case en_asr:
		switch(ap2->mode) {
		case am_immed:
			if (ap3->mode==am_reg) {
				for (nn = 0; nn < ap2->offset->i && nn < 33; nn++) {
					if (size==2) {
						GenerateDiadic(op1,0,ap3->amode2,ap3->amode2);
						GenerateDiadic(op2,0,ap3,ap3);
					}
					else
						GenerateDiadic(op1,0,ap3,ap3);
				}
			}
			else {
				GenerateDiadic(op_ld,0,makereg(1),ap3);
				if (size==2)
					GenerateDiadic(op_ld,0,makereg(2),ap3->amode2);
				for (nn = 0; nn < ap2->offset->i && nn < 33; nn++) {
					if (size==2) {
						GenerateDiadic(op1,0,makereg(2),makereg(2));
						GenerateDiadic(op2,0,makereg(1),makereg(1));
					}
					else
						GenerateDiadic(op1,0,makereg(1),makereg(1));
				}
				GenerateDiadic(op_sto,0,makereg(1),ap3);
				if (size==2)
					GenerateDiadic(op_sto,0,makereg(2),ap3->amode2);
			}
			ReleaseTempRegister(ap2);
			ReleaseTempRegister(ap1);
			MakeLegalAmode(ap3,flags,size);
			return (ap3);
		case am_reg:
			lab1 = nextlabel++;
			if (ap3->mode==am_reg) {
				GenerateLabel(lab1);
				if (size==2) {
					GenerateDiadic(op1,0,ap3->amode2,ap3->amode2);
					GenerateDiadic(op2,0,ap3,ap3);
				}
				else
					GenerateDiadic(op1,0,ap3,ap3);
				GenerateTriadic(op_sub,0,ap2,makereg(regZero),make_immed(1));
				GeneratePredicatedTriadic(pop_nz,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab1));
			}
			else {
				GenerateDiadic(op_ld,0,makereg(1),ap3);
				if (size==2)
					GenerateDiadic(op_ld,0,makereg(2),ap3->amode2);
				GenerateLabel(lab1);
				if (size==2) {
					GenerateDiadic(op1,0,makereg(2),makereg(2));
					GenerateDiadic(op2,0,makereg(1),makereg(1));
				}
				else
					GenerateDiadic(op1,0,makereg(1),makereg(1));
				GenerateTriadic(op_sub,0,ap2,makereg(regZero),make_immed(1));
				GeneratePredicatedTriadic(pop_nz,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab1));
				GenerateDiadic(op_sto,0,makereg(1),ap3);
				if (size==2)
					GenerateDiadic(op_sto,0,makereg(2),ap3->amode2);
			}
			ReleaseTempRegister(ap2);
			ReleaseTempRegister(ap1);
			MakeLegalAmode(ap3,flags,size);
			return (ap3);
		default:	// memory
			lab1 = nextlabel++;
			GenerateMonadic(op_push,0,makereg(3));
			GenerateDiadic(op_ld,0,makereg(3),ap2);
			if (ap3->mode==am_reg) {
				GenerateLabel(lab1);
				if (size==2) {
					GenerateDiadic(op1,0,ap3->amode2,ap3->amode2);
					GenerateDiadic(op2,0,ap3,ap3);
				}
				else
					GenerateDiadic(op1,0,ap3,ap3);
				GenerateTriadic(op_sub,0,makereg(3),makereg(regZero),make_immed(1));
				GeneratePredicatedTriadic(pop_nz,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab1));
			}
			else {
				GenerateDiadic(op_ld,0,makereg(1),ap3);
				if (size==2)
					GenerateDiadic(op_ld,0,makereg(2),ap3->amode2);
				GenerateLabel(lab1);
				if (size==2) {
					GenerateDiadic(op1,0,makereg(2),makereg(2));
					GenerateDiadic(op2,0,makereg(1),makereg(1));
				}
				else
					GenerateDiadic(op1,0,makereg(1),makereg(1));
				GenerateTriadic(op_sub,0,makereg(3),makereg(regZero),make_immed(1));
				GeneratePredicatedTriadic(pop_nz,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab1));
				GenerateDiadic(op_sto,0,makereg(1),ap3);
				if (size==2)
					GenerateDiadic(op_sto,0,makereg(2),ap3->amode2);
			}
			GenerateMonadic(op_pop,0,makereg(3));
			ReleaseTempRegister(ap2);
			ReleaseTempRegister(ap1);
			MakeLegalAmode(ap3,flags,size);
			return (ap3);
		}
		break;
	}
/*
	GenerateTriadic(op,size,ap3,ap1,ap2);
	// Shifts automatically sign extend
	// Don't actually need to zero extend on a shift right, but the other shifts
	// need it.
	if (ap2->isUnsigned)
		switch(size) {
		case 1:	GenerateTriadic(op_and,0,ap3,ap3,make_immed(0xFF)); break;	// shorter
		case 2:	Generate4adic(op_bfextu,0,ap3,ap3,make_immed(0),make_immed(15)); break;
		case 4:	Generate4adic(op_bfextu,0,ap3,ap3,make_immed(0),make_immed(31)); break;
		default:	;
		}
	ReleaseTempRegister(ap2);
	ReleaseTempRegister(ap1);
    MakeLegalAmode(ap3,flags,size);
    return ap3;
*/
	ReleaseTempRegister(ap2);
	ReleaseTempRegister(ap1);
	ReleaseTempRegister(ap3);
	ap1 = makereg(1);
	if (size==2)
		ap1->amode2 = makereg(2);
	return (ap1);
}


//
// Generate shift equals ( <<=, >>=) operators.
//
AMODE *GenerateAssignShift(ENODE *node,int flags,int size)
{
	AMODE *ap1, *ap2, *ap3;
	int lab1, nn;

	ap1 = GetTempRegister();
	if (size==2)
		ap1->amode2 = GetTempRegister();
	//size = GetNaturalSize(node->p[0]);
    ap3 = GenerateExpression(node->p[0],F_ALL,size);
    ap2 = GenerateExpression(node->p[1],F_REG|F_MEM|F_IMMED,size);
	if (ap3->mode==am_reg)
		GenerateDiadic(op_mov,0,ap1,ap3);
	else if (ap3->mode == am_immed) {
		error(ERR_LVALUE);
	    GenLdi(ap1,ap3);
	}
	else
        GenLoad(ap1,ap3,size,size);
	//MaskShift(op, ap1, size);
	switch (node->nodetype) {
	case en_shl:
	case en_shlu:
		switch(ap2->mode) {
		case am_immed:
			for (nn = 0; nn < ap2->offset->i && nn < 33; nn++) {
				GenerateDiadic(op_add,0,ap1,ap1);
				if (size==2)
					GenerateDiadic(op_adc,0,ap1->amode2,ap1->amode2);
			}
			ReleaseTempRegister(ap2);
			MakeLegalAmode(ap1,flags,size);
			return (ap1);
		case am_reg:
			lab1 = nextlabel++;
			GenerateLabel(lab1);
			GenerateDiadic(op_add,0,ap1,ap1);
			if (size==2)
				GenerateDiadic(op_adc,0,ap1->amode2,ap1->amode2);
			GenerateTriadic(op_sub,0,ap2,makereg(regZero),make_immed(1));
			GeneratePredicatedTriadic(pop_nz,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab1));
			ReleaseTempRegister(ap2);
			MakeLegalAmode(ap1,flags,size);
			return (ap1);
		default:
			lab1 = nextlabel++;
			GenerateDiadic(op_ld,0,makereg(1),ap2);
			GenerateLabel(lab1);
			GenerateDiadic(op_add,0,ap1,ap1);
			if (size==2)
				GenerateDiadic(op_adc,0,ap1->amode2,ap1->amode2);
			GenerateTriadic(op_sub,0,makereg(1),makereg(regZero),make_immed(1));
			GeneratePredicatedTriadic(pop_nz,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab1));
			ReleaseTempRegister(ap2);
			MakeLegalAmode(ap1,flags,size);
			return (ap1);
		}
		break;

	case en_shru:
	case en_shr:
		switch(ap2->mode) {
		case am_immed:
			for (nn = 0; nn < ap2->offset->i && nn < 33; nn++) {
				if (size==2) {
					GenerateDiadic(op_lsr,0,ap1->amode2,ap1->amode2);
					GenerateDiadic(op_ror,0,ap1,ap1);
				}
				else
					GenerateDiadic(op_lsr,0,ap1,ap1);
			}
			ReleaseTempRegister(ap2);
			MakeLegalAmode(ap1,flags,size);
			return ap1;
		case am_reg:
			lab1 = nextlabel++;
			GenerateLabel(lab1);
			if (size==2) {
				GenerateDiadic(op_lsr,0,ap1->amode2,ap1->amode2);
				GenerateDiadic(op_ror,0,ap1,ap1);
			}
			else
				GenerateDiadic(op_lsr,0,ap1,ap1);
			GenerateTriadic(op_sub,0,ap2,makereg(regZero),make_immed(1));
			GeneratePredicatedTriadic(pop_nz,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab1));
			ReleaseTempRegister(ap2);
			MakeLegalAmode(ap1,flags,size);
			return ap1;
		default:
			lab1 = nextlabel++;
			GenerateDiadic(op_ld,0,makereg(1),ap2);
			GenerateLabel(lab1);
			if (size==2) {
				GenerateDiadic(op_lsr,0,ap1->amode2,ap1->amode2);
				GenerateDiadic(op_ror,0,ap1,ap1);
			}
			else
				GenerateDiadic(op_lsr,0,ap1,ap1);
			GenerateTriadic(op_sub,0,makereg(1),makereg(regZero),make_immed(1));
			GeneratePredicatedTriadic(pop_nz,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab1));
			ReleaseTempRegister(ap2);
			MakeLegalAmode(ap1,flags,size);
			return ap1;
		}
		break;

	case en_asr:
		switch(ap2->mode) {
		case am_immed:
			for (nn = 0; nn < ap2->offset->i && nn < 33; nn++) {
				if (size==2) {
					GenerateDiadic(op_asr,0,ap1->amode2,ap1->amode2);
					GenerateDiadic(op_ror,0,ap1,ap1);
				}
				else
					GenerateDiadic(op_asr,0,ap1,ap1);
			}
			ReleaseTempRegister(ap2);
			MakeLegalAmode(ap1,flags,size);
			return ap1;
		case am_reg:
			lab1 = nextlabel++;
			GenerateLabel(lab1);
			if (size==2) {
				GenerateDiadic(op_asr,0,ap1->amode2,ap1->amode2);
				GenerateDiadic(op_ror,0,ap1,ap1);
			}
			else
				GenerateDiadic(op_asr,0,ap1,ap1);
			GenerateTriadic(op_sub,0,ap2,makereg(regZero),make_immed(1));
			GeneratePredicatedTriadic(pop_nz,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab1));
			ReleaseTempRegister(ap2);
			MakeLegalAmode(ap1,flags,size);
			return (ap1);
		default:
			lab1 = nextlabel++;
			GenerateDiadic(op_ld,0,makereg(1),ap2);
			GenerateLabel(lab1);
			if (size==2) {
				GenerateDiadic(op_asr,0,ap1->amode2,ap1->amode2);
				GenerateDiadic(op_ror,0,ap1,ap1);
			}
			else
				GenerateDiadic(op_asr,0,ap1,ap1);
			GenerateTriadic(op_sub,0,makereg(1),makereg(regZero),make_immed(1));
			GeneratePredicatedTriadic(pop_nz,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab1));
			ReleaseTempRegister(ap2);
			MakeLegalAmode(ap1,flags,size);
			return (ap1);
		}
		break;
	}
	if (ap3->mode != am_reg)
        GenStore(ap1,ap3,size);
    ReleaseTempRegister(ap2);
    ReleaseTempRegister(ap3);
    MakeLegalAmode(ap1,flags,size);
    return (ap1);
}

