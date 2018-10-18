// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Waterloo
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

extern TYP              stdfunc;

extern void DumpCSETable();
extern void scan(Statement *);
extern void GenerateComment(char *);
int TempFPInvalidate();
int TempInvalidate();
void TempRevalidate(int,int);
void TempFPRevalidate(int);
void ReleaseTempRegister(Operand *ap);
Operand *GetTempRegister();
extern void GenLoad(Operand *ap1, Operand *ap3, int ssize, int size);

Operand *GenExpr(ENODE *node)
{
	Operand *ap1,*ap2,*ap3,*ap4;
	int lab0, lab1;
	int size;
	int op;

    lab0 = nextlabel++;
    lab1 = nextlabel++;

	switch(node->nodetype) {
	case en_eq:		op = op_seq;	break;
	case en_ne:		op = op_sne;	break;
	case en_lt:		op = op_slt;	break;
	case en_ult:	op = op_sltu;	break;
	case en_le:		op = op_sle;	break;
	case en_ule:	op = op_sleu;	break;
	case en_gt:		op = op_sgt;	break;
	case en_ugt:	op = op_sgtu;	break;
	case en_ge:		op = op_sge;	break;
	case en_uge:	op = op_sgeu;	break;
	case en_flt:	op = op_fslt;	break;
	case en_fle:	op = op_fsle;	break;
	case en_fgt:	op = op_fsgt;	break;
	case en_fge:	op = op_fsge;	break;
	case en_feq:	op = op_fseq;	break;
	case en_fne:	op = op_fsne;	break;
	case en_veq:
		size = GetNaturalSize(node);
		ap3 = GetTempVectorRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG,size);
		GenerateTriadic(op_vseq,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	case en_vne:
		size = GetNaturalSize(node);
		ap3 = GetTempVectorRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG,size);
		GenerateTriadic(op_vsne,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	case en_vlt:
		size = GetNaturalSize(node);
		ap3 = GetTempVectorRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG,size);
		GenerateTriadic(op_vslt,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	case en_vle:
		size = GetNaturalSize(node);
		ap3 = GetTempVectorRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG,size);
		GenerateTriadic(op_vsle,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	case en_vgt:
		size = GetNaturalSize(node);
		ap3 = GetTempVectorRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG,size);
		GenerateTriadic(op_vsgt,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	case en_vge:
		size = GetNaturalSize(node);
		ap3 = GetTempVectorRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG,size);
		GenerateTriadic(op_vsge,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	default:	// en_land, en_lor
		//ap1 = GetTempRegister();
		//ap2 = GenerateExpression(node,F_REG,8);
		//GenerateDiadic(op_redor,0,ap1,ap2);
		//ReleaseTempReg(ap2);
		GenerateFalseJump(node,lab0,0);
		ap1 = GetTempRegister();
		GenerateDiadic(op_ldi,0,ap1,make_immed(1));
		GenerateMonadic(op_bra,0,make_label(lab1));
		GenerateLabel(lab0);
		GenerateDiadic(op_ldi,0,ap1,make_immed(0));
		GenerateLabel(lab1);
		return ap1;
	}

	switch (node->nodetype) {
	case en_eq:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0], F_REG, size);
		ap2 = GenerateExpression(node->p[1], F_REG | F_IMMED, size);
		GenerateTriadic(op_xnor, 0, ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		GenerateDiadic(op_redor, 0, ap3, ap3);
		return (ap3);
	case en_ne:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0], F_REG, size);
		ap2 = GenerateExpression(node->p[1], F_REG | F_IMMED, size);
		GenerateTriadic(op_xor, 0, ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		GenerateDiadic(op_redor, 0, ap3, ap3);
		return (ap3);
	case en_lt:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0], F_REG, size);
		ap2 = GenerateExpression(node->p[1], F_REG | F_IMMED, size);
		GenerateTriadic(op_slt, 0, ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		//		GenerateDiadic(op_slt,0,ap3,ap3);
		return (ap3);
	case en_le:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0], F_REG, size);
		ap2 = GenerateExpression(node->p[1], F_REG | F_IMMED, size);
		GenerateTriadic(op_sle, 0, ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		//		GenerateDiadic(op_sle,0,ap3,ap3);
		return (ap3);
	case en_gt:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0], F_REG, size);
		ap2 = GenerateExpression(node->p[1], F_REG | F_IMMED, size);
		if (ap2->mode == am_reg)
			GenerateTriadic(op_slt, 0, ap3, ap2, ap1);
		else
			GenerateTriadic(op_sgt, 0, ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		//		GenerateDiadic(op_sgt,0,ap3,ap3);
		return (ap3);
	case en_ge:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0], F_REG, size);
		ap2 = GenerateExpression(node->p[1], F_REG | F_IMMED, size);
		GenerateTriadic(op_slt, 0, ap3, ap1, ap2);
		GenerateDiadic(op_not, 0, ap3, ap3);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		//		GenerateDiadic(op_sge,0,ap3,ap3);
		return (ap3);
	case en_ult:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0], F_REG, size);
		ap2 = GenerateExpression(node->p[1], F_REG | F_IMMED, size);
		GenerateTriadic(op_sltu, 0, ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		//		GenerateDiadic(op_slt,0,ap3,ap3);
		return (ap3);
	case en_ule:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0], F_REG, size);
		ap2 = GenerateExpression(node->p[1], F_REG | F_IMMED, size);
		if (ap2->mode == am_imm) {
			GenerateTriadic(op_sgt, 0, ap3, ap1, ap2);
			GenerateDiadic(op_not, 0, ap3, ap3);
		}
		else
			GenerateTriadic(op_sleu, 0, ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		//		GenerateDiadic(op_sle,0,ap3,ap3);
		return (ap3);
	case en_ugt:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0], F_REG, size);
		ap2 = GenerateExpression(node->p[1], F_REG | F_IMMED, size);
		if (ap2->mode == am_reg)
			GenerateTriadic(op_sleu, 0, ap3, ap2, ap1);
		else
			GenerateTriadic(op_sgtu, 0, ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		//		GenerateDiadic(op_sgt,0,ap3,ap3);
		return (ap3);
	case en_uge:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0], F_REG, size);
		ap2 = GenerateExpression(node->p[1], F_REG | F_IMMED, size);
		if (ap2->mode == am_reg)
			GenerateTriadic(op_sleu, 0, ap3, ap2, ap1);
		else {
			GenerateTriadic(op_sltu, 0, ap3, ap1, ap2);
			GenerateDiadic(op_not, 0, ap3, ap3);
		}
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
//		GenerateDiadic(op_sge,0,ap3,ap3);
		return (ap3);
	case en_flt:
	case en_fle:
	case en_fgt:
	case en_fge:
	case en_feq:
	case en_fne:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0], F_FPREG, size);
		ap2 = GenerateExpression(node->p[1], F_FPREG, size);
		GenerateTriadic(op, ap1->fpsize(), ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		return (ap3);
		/*
	case en_ne:
	case en_lt:
	case en_ult:
	case en_gt:
	case en_ugt:
	case en_le:
	case en_ule:
	case en_ge:
	case en_uge:
		size = GetNaturalSize(node);
		ap1 = GenerateExpression(node->p[0],F_REG, size);
		ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
		GenerateTriadic(op,0,ap1,ap1,ap2);
		ReleaseTempRegister(ap2);
		return ap1;
*/
	case en_chk:
		size = GetNaturalSize(node);
        ap4 = GetTempRegister();         
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG,size);
		ap3 = GenerateExpression(node->p[2],F_REG|F_IMM0,size);
		if (ap3->mode == am_imm) {  // must be a zero
		   ap3->mode = am_reg;
		   ap3->preg = 0;
        }
   		Generate4adic(op_chk,0,ap4,ap1,ap2,ap3);
        ReleaseTempRegister(ap3);
        ReleaseTempRegister(ap2);
        ReleaseTempRegister(ap1);
        return ap4;
	}
	size = GetNaturalSize(node);
    ap3 = GetTempRegister();         
	ap1 = GenerateExpression(node->p[0],F_REG,size);
	ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
	GenerateTriadic(op,0,ap3,ap1,ap2);
    ReleaseTempRegister(ap2);
    ReleaseTempRegister(ap1);
    return ap3;
	/*
    GenerateFalseJump(node,lab0,0);
    ap1 = GetTempRegister();
    GenerateDiadic(op_ld,0,ap1,make_immed(1));
    GenerateMonadic(op_bra,0,make_label(lab1));
    GenerateLabel(lab0);
    GenerateDiadic(op_ld,0,ap1,make_immed(0));
    GenerateLabel(lab1);
    return ap1;
	*/
}

void GenerateCmp(ENODE *node, int op, int label, int predreg, unsigned int prediction)
{
	int size, sz;
	Operand *ap1, *ap2, *ap3;

	size = GetNaturalSize(node);
  if (op==op_flt || op==op_fle || op==op_fgt || op==op_fge || op==op_feq || op==op_fne) {
    ap1 = GenerateExpression(node->p[0],F_FPREG,size);
	  ap2 = GenerateExpression(node->p[1],F_FPREG,size);
  }
  else {
    ap1 = GenerateExpression(node->p[0],F_REG, size);
	  ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
  }
	/*
	// Optimize CMP to zero and branch into plain branch, this works only for
	// signed relational compares.
	if (ap2->mode == am_imm && ap2->offset->i==0 && (op==op_eq || op==op_ne || op==op_lt || op==op_le || op==op_gt || op==op_ge)) {
    	switch(op)
    	{
    	case op_eq:	op = op_beq; break;
    	case op_ne:	op = op_bne; break;
    	case op_lt: op = op_blt; break;
    	case op_le: op = op_ble; break;
    	case op_gt: op = op_bgt; break;
    	case op_ge: op = op_bge; break;
    	}
    	ReleaseTempReg(ap3);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		GenerateDiadic(op,0,ap1,make_clabel(label));
		return;
	}
	*/
	/*
	if (op==op_ltu || op==op_leu || op==op_gtu || op==op_geu)
 	    GenerateTriadic(op_cmpu,0,ap3,ap1,ap2);
    else if (op==op_flt || op==op_fle || op==op_fgt || op==op_fge || op==op_feq || op==op_fne)
        GenerateTriadic(op_fdcmp,0,ap3,ap1,ap2);
	else 
 	    GenerateTriadic(op_cmp,0,ap3,ap1,ap2);
	*/
	sz = 0;
	switch(op)
	{
	case op_bchk:	break;
	case op_eq:	op = op_beq; break;
	case op_ne:	op = op_bne; break;
	case op_lt: op = op_blt; break;
	case op_le: op = op_ble; break;
	case op_gt: op = op_bgt; break;
	case op_ge: op = op_bge; break;
	case op_ltu: op = op_bltu; break;
	case op_leu: op = op_bleu; break;
	case op_gtu: op = op_bgtu; break;
	case op_geu: op = op_bgeu; break;
	case op_feq:	op = op_fbeq; sz = 'd'; break;
	case op_fne:	op = op_fbne; sz = 'd'; break;
	case op_flt:	op = op_fblt; sz = 'd'; break;
	case op_fle:	op = op_fble; sz = 'd'; break;
	case op_fgt:	op = op_fbgt; sz = 'd'; break;
	case op_fge:	op = op_fbge; sz = 'd'; break;
	/*
		GenerateTriadic(op_fcmp,'q',ap3,ap1,ap2);
		GenerateTriadic(op_bbs,0,ap3,make_immed(0),make_clabel(label));
		goto xit;
	case op_fne:
		GenerateTriadic(op_fcmp,'q',ap3,ap1,ap2);
		GenerateTriadic(op_bbc,0,ap3,make_immed(0),make_clabel(label));
		goto xit;
	case op_flt:
		GenerateTriadic(op_fcmp,'q',ap3,ap1,ap2);
		GenerateTriadic(op_bbs,0,ap3,make_immed(1),make_clabel(label));
		goto xit;
	case op_fle:
		GenerateTriadic(op_fcmp,'q',ap3,ap1,ap2);
		GenerateTriadic(op_bbs,0,ap3,make_immed(2),make_clabel(label));
		goto xit;
	case op_fgt:
		GenerateTriadic(op_fcmp,'q',ap3,ap1,ap2);
		GenerateTriadic(op_bbc,0,ap3,make_immed(2),make_clabel(label));
		goto xit;
	case op_fge:
		GenerateTriadic(op_fcmp,'q',ap3,ap1,ap2);
		GenerateTriadic(op_bbc,0,ap3,make_immed(1),make_clabel(label));
		goto xit;
	*/
	}
	if (op==op_fbne || op==op_fbeq || op==op_fblt || op==op_fble || op==op_fbgt || op==op_fbge) {
		switch(op) {
		case op_fbne:
			if (ap2->mode==am_imm) {
				ap3 = GetTempFPRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_fbne,sz,ap1,ap3,make_clabel(label));
			}
			else
				GenerateTriadic(op_fbne,sz,ap1,ap2,make_clabel(label));
			break;
		case op_fbeq:
			if (ap2->mode==am_imm) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_fbeq,sz,ap1,ap3,make_clabel(label));
			}
			else
				GenerateTriadic(op_fbeq,sz,ap1,ap2,make_clabel(label));
			break;
		case op_fblt:
			if (ap2->mode==am_imm) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_fblt,sz,ap1,ap3,make_clabel(label));
			}
			else
				GenerateTriadic(op_fblt,sz,ap1,ap2,make_clabel(label));
			break;
		case op_fble:
			if (ap2->mode==am_imm) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_fbge,sz,ap3,ap1,make_clabel(label));
			}
			else
				GenerateTriadic(op_fbge,sz,ap2,ap1,make_clabel(label));
			break;
		case op_fbgt:
			if (ap2->mode==am_imm) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_fblt,sz,ap3,ap1,make_clabel(label));
			}
			else
				GenerateTriadic(op_fblt,sz,ap2,ap1,make_clabel(label));
			break;
		case op_fbge:
			if (ap2->mode==am_imm) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_fbge,sz,ap1,ap3,make_clabel(label));
			}
			else
				GenerateTriadic(op_fbge,sz,ap1,ap2,make_clabel(label));
			break;
		}
	}
	else {
		switch(op) {
		case op_beq:
			if (ap2->mode==am_imm && ap2->offset->nodetype==en_icon && ap2->offset->i >= -128 && ap2->offset->i <=128) {
				GenerateTriadic(op_beqi,0,ap1,ap2,make_clabel(label));
			}
			else if (ap2->mode==am_imm) {
				ap3 = GetTempRegister();
				GenerateTriadic(op_xor, 0, ap3, ap1, ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_beq,0,ap3,makereg(0),make_clabel(label));
			}
			else {
				ReleaseTempReg(ap2);
				ReleaseTempReg(ap1);
				GenerateTriadic(op_beq, 0, ap1, ap2, make_clabel(label));
				return;
			}
			break;
		case op_bne:
			if (ap2->mode==am_imm) {
				if (ap2->offset->i == 0)
					GenerateTriadic(op_bne,0,ap1,makereg(0),make_clabel(label));
				else {
					ap3 = GetTempRegister();
					GenerateTriadic(op_xor, 0, ap3, ap1, ap2);
					ReleaseTempRegister(ap3);
					GenerateTriadic(op_bne,0,ap3,makereg(0),make_clabel(label));
				}
			}
			else {
				GenerateTriadic(op_bne,0,ap1,ap2,make_clabel(label));
			}
			break;
		case op_blt:
			if (ap2->mode==am_imm) {
				if (ap2->offset->i == 0)
					GenerateTriadic(op_blt,0,ap1,makereg(0),make_clabel(label));
				else {
					ap3 = GetTempRegister();
					GenerateTriadic(op_slt, 0, ap3, ap1, ap2);
					ReleaseTempRegister(ap3);
					GenerateTriadic(op_bne,0,ap3,makereg(0),make_clabel(label));
				}
			}
			else
				GenerateTriadic(op_blt,0,ap1,ap2,make_clabel(label));
			break;
		case op_ble:
			if (ap2->mode==am_imm) {
				if (ap2->offset->i == 0)
					GenerateTriadic(op_bge,0,makereg(0),ap1,make_clabel(label));
				else {
					ap3 = GetTempRegister();
					GenerateTriadic(op_sle , 0, ap3, ap1, ap2);
					ReleaseTempRegister(ap3);
					GenerateTriadic(op_bne,0,makereg(0),ap3,make_clabel(label));
				}
			}
			else
				GenerateTriadic(op_bge,0,ap2,ap1,make_clabel(label));
			break;
		case op_bgt:
			if (ap2->mode==am_imm) {
				if (ap2->offset->i == 0)
					GenerateTriadic(op_blt,0,makereg(0),ap1,make_clabel(label));
				else {
					ap3 = GetTempRegister();
					GenerateTriadic(op_sle, 0, ap3, ap1, ap2);
					ReleaseTempRegister(ap3);
					GenerateTriadic(op_beq,0,makereg(0),ap3,make_clabel(label));
				}
			}
			else
				GenerateTriadic(op_blt,0,ap2,ap1,make_clabel(label));
			break;
		case op_bge:
			if (ap2->mode==am_imm) {
				if (ap2->offset->i==0) {
					GenerateTriadic(op_bge,0,ap1,makereg(0),make_clabel(label));
				}
				else {
					ap3 = GetTempRegister();
					GenerateTriadic(op_slt, 0, ap3, ap1, ap2);
					ReleaseTempRegister(ap3);
					GenerateTriadic(op_beq,0,ap3,makereg(0),make_clabel(label));
				}
			}
			else
				GenerateTriadic(op_bge,0,ap1,ap2,make_clabel(label));
			break;
		case op_bltu:
			if (ap2->mode==am_imm) {
				// Don't generate any code if testing against unsigned zero.
				// An unsigned number can't be less than zero so the branch will
				// always be false. Spit out a warning, its probably coded wrong.
				if (ap2->offset->i == 0)
					error(ERR_UBLTZ);	//GenerateTriadic(op_bltu,0,ap1,makereg(0),make_clabel(label));
				else {
					ap3 = GetTempRegister();
					GenerateTriadic(op_sltu, 0, ap3, ap1, ap2);
					ReleaseTempRegister(ap3);
					GenerateTriadic(op_bne,0,ap3,makereg(0),make_clabel(label));
				}
			}
			else
				GenerateTriadic(op_bltu,0,ap1,ap2,make_clabel(label));
			break;
		case op_bleu:
			if (ap2->mode==am_imm) {
				if (ap2->offset->i == 0)
					GenerateTriadic(op_bgeu,0,makereg(0),ap1,make_clabel(label));
				else {
					ap3 = GetTempRegister();
					GenerateTriadic(op_sleu, 0, ap3, ap1, ap2);
					ReleaseTempRegister(ap3);
					GenerateTriadic(op_bne,0,makereg(0),ap3,make_clabel(label));
				}
			}
			else
				GenerateTriadic(op_bgeu,0,ap2,ap1,make_clabel(label));
			break;
		case op_bgtu:
			if (ap2->mode==am_imm) {
				if (ap2->offset->i == 0)
					GenerateTriadic(op_bltu,0,makereg(0),ap1,make_clabel(label));
				else {
					ap3 = GetTempRegister();
					GenerateTriadic(op_sleu, 0, ap3, ap1, ap2);
					ReleaseTempRegister(ap3);
					GenerateTriadic(op_beq,0,makereg(0),ap3,make_clabel(label));
				}
			}
			else
				GenerateTriadic(op_bltu,0,ap2,ap1,make_clabel(label));
			break;
		case op_bgeu:
			if (ap2->mode==am_imm) {
				if (ap2->offset->i == 0) {
					// This branch is always true
					error(ERR_UBGEQ);
					GenerateTriadic(op_bgeu,0,ap1,makereg(0),make_clabel(label));
				}
				else {
					ap3 = GetTempRegister();
					GenerateTriadic(op_sltu, 0, ap3, ap1, ap2);
					ReleaseTempRegister(ap3);
					GenerateTriadic(op_beq,0,ap3,makereg(0),make_clabel(label));
				}
			}
			else
				GenerateTriadic(op_bgeu,0,ap1,ap2,make_clabel(label));
			break;
		}
		//GenerateTriadic(op,sz,ap1,ap2,make_clabel(label));
	}
   	ReleaseTempReg(ap2);
   	ReleaseTempReg(ap1);
}


static void SaveRegisterSet(SYM *sym)
{
	int nn, mm;

	if (!cpu.SupportsPush) {
		mm = sym->tp->GetBtp()->type!=bt_void ? 29 : 30;
		GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(mm*sizeOfWord));
		mm = 0;
		for (nn = 1 + (sym->tp->GetBtp()->type!=bt_void ? 1 : 0); nn < 31; nn++) {
			GenerateDiadic(op_sw,0,makereg(nn),make_indexed(mm,regSP));
			mm += sizeOfWord;
		}
	}
	else
		for (nn = 1 + (sym->tp->GetBtp()->type!=bt_void ? 1 : 0); nn < 31; nn++)
			GenerateMonadic(op_push,0,makereg(nn));
}

static void RestoreRegisterSet(SYM * sym)
{
	int nn, mm;

	if (!cpu.SupportsPop) {
		mm = 0;
		for (nn = 1 + (sym->tp->GetBtp()->type!=bt_void ? 1 : 0); nn < 31; nn++) {
			GenerateDiadic(op_lw,0,makereg(nn),make_indexed(mm,regSP));
			mm += sizeOfWord;
		}
		mm = sym->tp->GetBtp()->type!=bt_void ? 29 : 30;
		GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(mm*sizeOfWord));
	}
	else
		for (nn = 1 + (sym->tp->GetBtp()->type!=bt_void ? 1 : 0); nn < 31; nn++)
			GenerateMonadic(op_pop,0,makereg(nn));
}


// Push temporaries on the stack.

void SaveRegisterVars(int64_t mask, int64_t rmask)
{
	int cnt;
	int nn;

	if( mask != 0 ) {
		cnt = 0;
		GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(popcnt(mask)*8));
		for (nn = 0; nn < 64; nn++) {
			if (rmask & (0x8000000000000000ULL >> nn)) {
				GenerateDiadic(op_sw,0,makereg(nn),make_indexed(cnt,regSP));
				cnt+=sizeOfWord;
			}
		}
	}
}

void SaveFPRegisterVars(int64_t mask, int64_t rmask)
{
	int cnt;
	int nn;

	if( mask != 0 ) {
		cnt = 0;
		GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(popcnt(mask)*8));
		for (nn = 0; nn < 64; nn++) {
			if (rmask & (0x8000000000000000ULL >> nn)) {
				GenerateDiadic(op_sf,'d',makefpreg(nn),make_indexed(cnt,regSP));
				cnt+=sizeOfWord;
			}
		}
	}
}

// Restore registers used as register variables.

static void RestoreRegisterVars()
{
	int cnt2, cnt;
	int nn;

	if( save_mask != 0 ) {
		cnt2 = cnt = popcnt(save_mask)*sizeOfWord;
		cnt = 0;
		for (nn = 0; nn < 64; nn++) {
			if (save_mask & (1LL << nn)) {
				GenerateDiadic(op_lw,0,makereg(nn),make_indexed(cnt,regSP));
				cnt += sizeOfWord;
			}
		}
		GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(cnt2));
	}
}

static void RestoreFPRegisterVars()
{
	int cnt2, cnt;
	int nn;

	if( fpsave_mask != 0 ) {
		cnt2 = cnt = popcnt(fpsave_mask)*sizeOfWord;
		cnt = 0;
		for (nn = 0; nn < 64; nn++) {
			if (fpsave_mask & (1LL << nn)) {
				GenerateDiadic(op_lf,'d',makefpreg(nn),make_indexed(cnt,regSP));
				cnt += sizeOfWord;
			}
		}
		GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(cnt2));
	}
}

static int round4(int n)
{
    while(n & 3) n++;
    return (n);
};

static void SaveTemporaries(Function *sym, int *sp, int *fsp)
{
	if (sym) {
		if (sym->UsesTemps) {
			*sp = TempInvalidate(fsp);
			//*fsp = TempFPInvalidate();
		}
	}
	else {
		*sp = TempInvalidate(fsp);
		//*fsp = TempFPInvalidate();
	}
}

static void RestoreTemporaries(Function *sym, int sp, int fsp)
{
	if (sym) {
		if (sym->UsesTemps) {
			//TempFPRevalidate(fsp);
			TempRevalidate(sp,fsp);
		}
	}
	else {
		//TempFPRevalidate(fsp);
		TempRevalidate(sp,fsp);
	}
}

// push the operand expression onto the stack.
// Structure variables are represented as an address in a register and arrive
// here as autocon nodes if on the stack. If the variable size is greater than
// 8 we assume a structure variable and we assume we have the address in a reg.
// Returns: number of stack words pushed.
//
static int GeneratePushParameter(ENODE *ep, int regno, int stkoffs)
{    
	Operand *ap, *ap3;
	int nn = 0;
	int sz;
	
	switch(ep->etype) {
	case bt_quad:	sz = sizeOfFPD; break;
	case bt_triple:	sz = sizeOfFPT; break;
	case bt_double:	sz = sizeOfFPD; break;
	case bt_float:	sz = sizeOfFPD; break;
	default:	sz = sizeOfWord; break;
	}
	if (ep->tp) {
		if (ep->tp->IsFloatType())
			ap = GenerateExpression(ep,F_REG,sizeOfFP);
		else
			ap = GenerateExpression(ep,F_REG|F_IMMED,sizeOfWord);
	}
	else if (ep->etype==bt_quad)
		ap = GenerateExpression(ep,F_REG,sz);
	else if (ep->etype==bt_double)
		ap = GenerateExpression(ep,F_REG,sz);
	else if (ep->etype==bt_triple)
		ap = GenerateExpression(ep,F_REG,sz);
	else if (ep->etype==bt_float)
		ap = GenerateExpression(ep,F_REG,sz);
	else
		ap = GenerateExpression(ep,F_REG|F_IMMED,sz);
	switch(ap->mode) {
    case am_reg:
    case am_fpreg:
    case am_imm:
/*
        nn = round8(ep->esize); 
        if (nn > 8) {// && (ep->tp->type==bt_struct || ep->tp->type==bt_union)) {           // structure or array ?
            ap2 = GetTempRegister();
            GenerateTriadic(op_subui,0,makereg(regSP),makereg(regSP),make_immed(nn));
            GenerateDiadic(op_mov, 0, ap2, makereg(regSP));
            GenerateMonadic(op_push,0,make_immed(ep->esize));
            GenerateMonadic(op_push,0,ap);
            GenerateMonadic(op_push,0,ap2);
            GenerateMonadic(op_bsr,0,make_string("memcpy_"));
            GenerateTriadic(op_addui,0,makereg(regSP),makereg(regSP),make_immed(24));
          	GenerateMonadic(op_push,0,ap2);
            ReleaseTempReg(ap2);
            nn = nn >> 3;
        }
        else {
*/
			if (regno) {
				GenerateMonadic(op_hint,0,make_immed(1));
				if (ap->mode==am_imm) {
					GenerateDiadic(op_ldi,0,makereg(regno & 0x7fff), ap);
					if (regno & 0x8000) {
						GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(sizeOfWord));
						nn = 1;
					}
				}
				else if (ap->mode==am_fpreg) {
					GenerateDiadic(op_mov,0,makefpreg(regno & 0x7fff), ap);
					if (regno & 0x8000) {
						GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(sz));
						nn = sz/sizeOfWord;
					}
				}
				else {
					//ap->preg = regno & 0x7fff;
					GenerateDiadic(op_mov,0,makereg(regno & 0x7fff), ap);
					if (regno & 0x8000) {
						GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(sizeOfWord));
						nn = 1;
					}
				}
			}
			else {
				if (cpu.SupportsPush) {
					if (ap->mode==am_imm) {	// must have been a zero
						if (ap->offset->i==0)
         					GenerateMonadic(op_push,0,makereg(0));
						else {
							ap3 = GetTempRegister();
							GenerateDiadic(op_ldi,0,ap3,ap);
							GenerateMonadic(op_push,0,ap3);
							ReleaseTempReg(ap3);
						}
						nn = 1;
					}
					else {
						if (ap->type=stddouble.GetIndex()) {
							GenerateMonadic(op_push,ap->FloatSize,ap);
							nn = sz/sizeOfWord;
						}
						else {
          					GenerateMonadic(op_push,0,ap);
							nn = 1;
						}
					}
				}
				else {
					if (ap->mode==am_imm) {	// must have been a zero
						ap3 = nullptr;
						if (ap->offset->i!=0) {
							ap3 = GetTempRegister();
							GenerateDiadic(op_ldi,0,ap3,ap);
	         				GenerateDiadic(op_sw,0,ap3,make_indexed(stkoffs,regSP));
							ReleaseTempReg(ap3);
						}
						else
         					GenerateDiadic(op_sw,0,makereg(0),make_indexed(stkoffs,regSP));
						nn = 1;
					}
					else {
						if (ap->type==stddouble.GetIndex() || ap->mode==am_fpreg) {
							GenerateDiadic(op_sf,'d',ap,make_indexed(stkoffs,regSP));
							nn = sz/sizeOfWord;
						}
						else {
          					GenerateDiadic(op_sw,0,ap,make_indexed(stkoffs,regSP));
							nn = 1;
						}
					}
				}
			}
//        }
    	break;
    }
	ReleaseTempReg(ap);
	return nn;
}

// Store entire argument list onto stack
//
static int GenerateStoreArgumentList(Function *sym, ENODE *plist)
{
	TypeArray *ta = nullptr;
	int i,sum;
	OCODE *ip;
	ENODE *p;
	ENODE *pl[100];
	int nn;

	sum = 0;
	if (sym)
		ta = sym->GetProtoTypes();

	ip = peep_tail;
	GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(0));
	// Capture the parameter list. It is needed in the reverse order.
	for (nn = 0, p = plist; p != NULL; p = p->p[1], nn++) {
		pl[nn] = p->p[0];
	}
	for(--nn, i = 0; nn >= 0; --nn,i++ )
  {
//		sum += GeneratePushParameter(pl[nn],ta ? ta->preg[ta->length - i - 1] : 0,sum*8);
		// Variable argument list functions may cause the type array values to be
		// exhausted before all the parameters are pushed. So, we check the parm number.
		sum += GeneratePushParameter(pl[nn],ta ? (i < ta->length ? ta->preg[i] : 0) : 0,sum*8);
//		plist = plist->p[1];
  }
	if (sum==0)
		MarkRemove(ip->fwd);
	else
		ip->fwd->oper3 = make_immed(sum*sizeOfWord);
	if (ta)
		delete ta;
    return sum;
}

Operand *GenerateFunctionCall(ENODE *node, int flags)
{ 
	Operand *ap;
	Function *sym;
	Function *o_fn;
	SYM *s;
    int i;
	int sp = 0;
	int fsp = 0;
	int ps;
	TypeArray *ta = nullptr;
	int64_t mask,fmask;
	CSETable *csetbl;

	sym = nullptr;

	// Call the function
	if( node->p[0]->nodetype == en_nacon || node->p[0]->nodetype == en_cnacon ) {
		s = gsearch(*node->p[0]->sp);
 		sym = s->fi;
        i = 0;
  /*
    	if ((sym->tp->GetBtp()->type==bt_struct || sym->tp->GetBtp()->type==bt_union) && sym->tp->GetBtp()->size > 8) {
            nn = tmpAlloc(sym->tp->GetBtp()->size) + lc_auto + round8(sym->tp->GetBtp()->size);
            GenerateMonadic(op_pea,0,make_indexed(-nn,regFP));
            i = 1;
        }
*/
		if (currentFn->HasRegisterParameters())
			sym->SaveRegisterArguments();
    i = i + GenerateStoreArgumentList(sym,node->p[1]);
//		ReleaseTempRegister(ap);
		sym->SaveTemporaries(&sp, &fsp);
		if (sym && sym->IsInline) {
			o_fn = currentFn;
			mask = save_mask;
			fmask = fpsave_mask;
			currentFn = sym;
			ps = pass;
			sym->Gen();
			pass = ps;
			currentFn = o_fn;
			fpsave_mask = fmask;
			save_mask = mask;
		}
		else {
			GenerateMonadic(op_call,0,make_offset(node->p[0]));
			GenerateMonadic(op_bex,0,make_label(throwlab));
		}
	}
    else
    {
        i = 0;
    /*
    	if ((node->p[0]->tp->GetBtp()->type==bt_struct || node->p[0]->tp->GetBtp()->type==bt_union) && node->p[0]->tp->GetBtp()->size > 8) {
            nn = tmpAlloc(node->p[0]->tp->GetBtp()->size) + lc_auto + round8(node->p[0]->tp->GetBtp()->size);
            GenerateMonadic(op_pea,0,make_indexed(-nn,regFP));
            i = 1;
        }
     */
		ap = GenerateExpression(node->p[0],F_REG,sizeOfWord);
		if (ap->offset)
			sym = ap->offset->sym->fi;
		if (currentFn->HasRegisterParameters())
			sym->SaveRegisterArguments();
    i = i + GenerateStoreArgumentList(sym,node->p[1]);
		sym->SaveTemporaries(&sp, &fsp);
		ap->mode = am_ind;
		ap->offset = 0;
		if (sym && sym->IsInline) {
			o_fn = currentFn;
			mask = save_mask;
			fmask = fpsave_mask;
			currentFn = sym;
			ps = pass;
			sym->Gen();
			pass = ps;
			currentFn = o_fn;
			fpsave_mask = fmask;
			save_mask = mask;
		}
		else {
			GenerateMonadic(op_call,0,ap);
			GenerateMonadic(op_bex,0,make_label(throwlab));
		}
		ReleaseTempRegister(ap);
    }
	// Pop parameters off the stack
	if (i!=0) {
		if (sym) {
			if (!sym->IsPascal)
				GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(i * sizeOfWord));
		}
		else
			GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(i * sizeOfWord));
	}
	sym->RestoreTemporaries(sp, fsp);
	if (currentFn->HasRegisterParameters())
		sym->RestoreRegisterArguments();
	/*
	if (sym) {
	   if (sym->tp->type==bt_double)
           result = GetTempFPRegister();
	   else
           result = GetTempRegister();
    }
    else {
        if (node->etype==bt_double)
            result = GetTempFPRegister();
        else
            result = GetTempRegister();
    }
	*/
	if (sym
		&& sym->sym
		&& sym->sym->tp 
		&& sym->sym->tp->GetBtp()
		&& sym->sym->tp->GetBtp()->IsFloatType()) {
		return (makefpreg(1));
	}
	if (sym 
		&& sym->sym
		&& sym->sym->tp
		&& sym->sym->tp->GetBtp()
		&& sym->sym->tp->GetBtp()->IsVectorType())
		return (makevreg(1));
	ap = makereg(1);
	if (sym 
		&& sym->sym
		&& sym->sym->tp
		&& sym->sym->tp->GetBtp()
		)
		ap->isPtr = sym->sym->tp->GetBtp()->type == bt_pointer;
	return (ap);
	/*
	else {
		if( result->preg != 1 || (flags & F_REG) == 0 ) {
			if (sym) {
				if (sym->tp->GetBtp()->type==bt_void)
					;
				else {
                    if (sym->tp->type==bt_double)
					    GenerateDiadic(op_fdmov,0,result,makefpreg(1));
                    else
					    GenerateDiadic(op_mov,0,result,makereg(1));
                }
			}
			else {
                if (node->etype==bt_double)
      				GenerateDiadic(op_fdmov,0,result,makereg(1));
                else
		     		GenerateDiadic(op_mov,0,result,makereg(1));
            }
		}
	}
    return result;
	*/
}

void GenLdi(Operand *ap1, Operand *ap2)
{
	GenerateDiadic(op_ldi,0,ap1,ap2);
  return;
}

