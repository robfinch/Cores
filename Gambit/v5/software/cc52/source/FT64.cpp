// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2019  Robert Finch, Waterloo
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

Operand *FT64CodeGenerator::GenExpr(ENODE *node)
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
		ap1 = cg.GenerateExpression(node->p[0],am_reg,size);
		ap2 = cg.GenerateExpression(node->p[1],am_reg,size);
		GenerateTriadic(op_vseq,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	case en_vne:
		size = GetNaturalSize(node);
		ap3 = GetTempVectorRegister();         
		ap1 = cg.GenerateExpression(node->p[0],am_reg,size);
		ap2 = cg.GenerateExpression(node->p[1],am_reg,size);
		GenerateTriadic(op_vsne,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	case en_vlt:
		size = GetNaturalSize(node);
		ap3 = GetTempVectorRegister();         
		ap1 = cg.GenerateExpression(node->p[0],am_reg,size);
		ap2 = cg.GenerateExpression(node->p[1],am_reg,size);
		GenerateTriadic(op_vslt,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	case en_vle:
		size = GetNaturalSize(node);
		ap3 = GetTempVectorRegister();         
		ap1 = cg.GenerateExpression(node->p[0],am_reg,size);
		ap2 = cg.GenerateExpression(node->p[1],am_reg,size);
		GenerateTriadic(op_vsle,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	case en_vgt:
		size = GetNaturalSize(node);
		ap3 = GetTempVectorRegister();         
		ap1 = cg.GenerateExpression(node->p[0],am_reg,size);
		ap2 = cg.GenerateExpression(node->p[1],am_reg,size);
		GenerateTriadic(op_vsgt,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	case en_vge:
		size = GetNaturalSize(node);
		ap3 = GetTempVectorRegister();         
		ap1 = cg.GenerateExpression(node->p[0],am_reg,size);
		ap2 = cg.GenerateExpression(node->p[1],am_reg,size);
		GenerateTriadic(op_vsge,0,ap3,ap1,ap2);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		return (ap3);
	case en_land_safe:
		ap3 = GetTempRegister();
		ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
		ap2 = cg.GenerateExpression(node->p[1], am_reg, size);
		GenerateTriadic(op_and, 0, ap3, ap1, ap2);
		ap3->isBool = ap1->isBool && ap2->isBool;
		if (!ap3->isBool)
			ENODE::GenRedor(ap3, ap3);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		ap3->isBool = true;
		return(ap3);
	case en_lor_safe:
		ap3 = GetTempRegister();
		ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
		ap2 = cg.GenerateExpression(node->p[1], am_reg, size);
		GenerateTriadic(op_or, 0, ap3, ap1, ap2);
		ap3->isBool = ap1->isBool && ap2->isBool;
		if (!ap3->isBool)
			ENODE::GenRedor(ap3, ap3);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		ap3->isBool = true;
		return(ap3);
	default:	// en_land, en_lor
		//ap1 = GetTempRegister();
		//ap2 = cg.GenerateExpression(node,am_reg,8);
		//GenerateDiadic(op_redor,0,ap1,ap2);
		//ReleaseTempReg(ap2);
		GenerateFalseJump(node,lab0,0);
		ap1 = GetTempRegister();
		GenerateDiadic(op_ldi,0,ap1,MakeImmediate(1));
		GenerateMonadic(op_bra,0,MakeDataLabel(lab1));
		GenerateLabel(lab0);
		GenerateDiadic(op_ldi,0,ap1,MakeImmediate(0));
		GenerateLabel(lab1);
		ap1->isBool = true;
		return (ap1);
	}

	switch (node->nodetype) {
	case en_eq:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = cg.GenerateExpression(node->p[0], am_reg, node->p[0]->GetNaturalSize());
		ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm8, node->p[1]->GetNaturalSize());
		GenerateTriadic(op_seq, 0, ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		ap3->isBool = true;
		return (ap3);
	case en_ne:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = cg.GenerateExpression(node->p[0], am_reg, node->p[0]->GetNaturalSize());
		ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm8, node->p[1]->GetNaturalSize());
		GenerateTriadic(op_sne, 0, ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		ap3->isBool = true;
		return (ap3);
	case en_lt:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
		ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm8, size);
		GenerateTriadic(op_slt, 0, ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		//		GenerateDiadic(op_slt,0,ap3,ap3);
		ap3->isBool = true;
		return (ap3);
	case en_le:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
		ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm8, size);
		GenerateTriadic(op_sle, 0, ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		//		GenerateDiadic(op_sle,0,ap3,ap3);
		ap3->isBool = true;
		return (ap3);
	case en_gt:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
		ap2 = cg.GenerateExpression(node->p[1], am_reg, size);
		if (ap2->mode == am_reg)
			GenerateTriadic(op_slt, 0, ap3, ap2, ap1);
		else
			GenerateTriadic(op_sgt, 0, ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		//		GenerateDiadic(op_sgt,0,ap3,ap3);
		ap3->isBool = true;
		return (ap3);
	case en_ge:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
		ap2 = cg.GenerateExpression(node->p[1], am_reg, size);
		if (ap2->mode == am_reg)
			GenerateTriadic(op_sle, 0, ap3, ap2, ap1);
		else
			GenerateTriadic(op_sge, 0, ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		//		GenerateDiadic(op_sge,0,ap3,ap3);
		ap3->isBool = true;
		return (ap3);
	case en_ult:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
		ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm8, size);
		GenerateTriadic(op_sltu, 0, ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		//		GenerateDiadic(op_slt,0,ap3,ap3);
		ap3->isBool = true;
		return (ap3);
	case en_ule:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
		ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm8, size);
		GenerateTriadic(op_sleu, 0, ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		//		GenerateDiadic(op_sle,0,ap3,ap3);
		ap3->isBool = true;
		return (ap3);
	case en_ugt:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
		ap2 = cg.GenerateExpression(node->p[1], am_reg, size);
		if (ap2->mode == am_reg)
			GenerateTriadic(op_sltu, 0, ap3, ap2, ap1);
		else
			GenerateTriadic(op_sgtu, 0, ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		//		GenerateDiadic(op_sgt,0,ap3,ap3);
		ap3->isBool = true;
		return (ap3);
	case en_uge:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
		ap2 = cg.GenerateExpression(node->p[1], am_reg, size);
		if (ap2->mode == am_reg)
			GenerateTriadic(op_sleu, 0, ap3, ap2, ap1);
		else {
			GenerateTriadic(op_sgeu, 0, ap3, ap1, ap2);
		}
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
//		GenerateDiadic(op_sge,0,ap3,ap3);
		ap3->isBool = true;
		return (ap3);
	case en_flt:
	case en_fle:
	case en_fgt:
	case en_fge:
	case en_feq:
	case en_fne:
		size = GetNaturalSize(node);
		ap3 = GetTempRegister();
		ap1 = cg.GenerateExpression(node->p[0], am_fpreg, size);
		ap2 = cg.GenerateExpression(node->p[1], am_fpreg, size);
		GenerateTriadic(op, ap1->fpsize(), ap3, ap1, ap2);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
		ap3->isBool = true;
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
		ap1 = cg.GenerateExpression(node->p[0],am_reg, size);
		ap2 = cg.GenerateExpression(node->p[1],am_reg|am_imm,size);
		GenerateTriadic(op,0,ap1,ap1,ap2);
		ReleaseTempRegister(ap2);
		return ap1;
*/
	case en_chk:
		size = GetNaturalSize(node);
        ap4 = GetTempRegister();         
		ap1 = cg.GenerateExpression(node->p[0],am_reg,size);
		ap2 = cg.GenerateExpression(node->p[1],am_reg,size);
		ap3 = cg.GenerateExpression(node->p[2],am_reg|am_imm0,size);
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
	ap1 = cg.GenerateExpression(node->p[0],am_reg,size);
	ap2 = cg.GenerateExpression(node->p[1],am_reg|am_imm,size);
	GenerateTriadic(op,0,ap3,ap1,ap2);
  ReleaseTempRegister(ap2);
  ReleaseTempRegister(ap1);
	ap3->isBool = true;
	return (ap3);
	/*
    GenerateFalseJump(node,lab0,0);
    ap1 = GetTempRegister();
    GenerateDiadic(op_ld,0,ap1,MakeImmediate(1));
    GenerateMonadic(op_bra,0,MakeDataLabel(lab1));
    GenerateLabel(lab0);
    GenerateDiadic(op_ld,0,ap1,MakeImmediate(0));
    GenerateLabel(lab1);
    return ap1;
	*/
}

bool FT64CodeGenerator::GenerateBranch(ENODE *node, int op, int label, int predreg, unsigned int prediction, bool limit)
{
	int size, sz;
	Operand *ap1, *ap2, *ap3, *ap4, *ap5;
	OCODE *ip;
	static int cr = 0;

	if ((op == op_nand || op == op_nor || op == op_and || op == op_or) && (node->p[0]->HasCall() || node->p[1]->HasCall()))
		return (false);
	size = GetNaturalSize(node);
	ip = currentFn->pl.tail;
  if (op==op_flt || op==op_fle || op==op_fgt || op==op_fge || op==op_feq || op==op_fne) {
    ap1 = cg.GenerateExpression(node->p[0],am_fpreg,size);
	  ap2 = cg.GenerateExpression(node->p[1],am_fpreg,size);
  }
  else {
  }
	if (limit && currentFn->pl.Count(ip) > 10) {
		currentFn->pl.tail = ip;
		currentFn->pl.tail->fwd = nullptr;
		return (false);
	}

	cr++;
	cr &= 3;
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
		GenerateDiadic(op,0,ap1,MakeCodeLabel(label));
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
	case op_nand:	op = op_bnand; break;
	case op_nor:	op = op_bnor; break;
	case op_and:	op = op_band; break;
	case op_or:	op = op_bor; break;
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
		GenerateTriadic(op_bbs,0,ap3,MakeImmediate(0),MakeCodeLabel(label));
		goto xit;
	case op_fne:
		GenerateTriadic(op_fcmp,'q',ap3,ap1,ap2);
		GenerateTriadic(op_bbc,0,ap3,MakeImmediate(0),MakeCodeLabel(label));
		goto xit;
	case op_flt:
		GenerateTriadic(op_fcmp,'q',ap3,ap1,ap2);
		GenerateTriadic(op_bbs,0,ap3,MakeImmediate(1),MakeCodeLabel(label));
		goto xit;
	case op_fle:
		GenerateTriadic(op_fcmp,'q',ap3,ap1,ap2);
		GenerateTriadic(op_bbs,0,ap3,MakeImmediate(2),MakeCodeLabel(label));
		goto xit;
	case op_fgt:
		GenerateTriadic(op_fcmp,'q',ap3,ap1,ap2);
		GenerateTriadic(op_bbc,0,ap3,MakeImmediate(2),MakeCodeLabel(label));
		goto xit;
	case op_fge:
		GenerateTriadic(op_fcmp,'q',ap3,ap1,ap2);
		GenerateTriadic(op_bbc,0,ap3,MakeImmediate(1),MakeCodeLabel(label));
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
				GenerateTriadic(op_fbne,sz,ap1,ap3,MakeCodeLabel(label));
			}
			else
				GenerateTriadic(op_fbne,sz,ap1,ap2,MakeCodeLabel(label));
			break;
		case op_fbeq:
			if (ap2->mode==am_imm) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_fbeq,sz,ap1,ap3,MakeCodeLabel(label));
			}
			else
				GenerateTriadic(op_fbeq,sz,ap1,ap2,MakeCodeLabel(label));
			break;
		case op_fblt:
			if (ap2->mode==am_imm) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_fblt,sz,ap1,ap3,MakeCodeLabel(label));
			}
			else
				GenerateTriadic(op_fblt,sz,ap1,ap2,MakeCodeLabel(label));
			break;
		case op_fble:
			if (ap2->mode==am_imm) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_fbge,sz,ap3,ap1,MakeCodeLabel(label));
			}
			else
				GenerateTriadic(op_fbge,sz,ap2,ap1,MakeCodeLabel(label));
			break;
		case op_fbgt:
			if (ap2->mode==am_imm) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_fblt,sz,ap3,ap1,MakeCodeLabel(label));
			}
			else
				GenerateTriadic(op_fblt,sz,ap2,ap1,MakeCodeLabel(label));
			break;
		case op_fbge:
			if (ap2->mode==am_imm) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_ldi,0,ap3,ap2);
				ReleaseTempRegister(ap3);
				GenerateTriadic(op_fbge,sz,ap1,ap3,MakeCodeLabel(label));
			}
			else
				GenerateTriadic(op_fbge,sz,ap1,ap2,MakeCodeLabel(label));
			break;
		}
	}
	else {
		switch(op) {
		case op_band:
			ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
			ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm8, size);
			ap3 = GetTempRegister();
			ap4 = GetTempRegister();
			if (!ap1->isBool)
				ENODE::GenRedor(ap4, ap1);
			else
				GenerateDiadic(op_mov, 0, ap4, ap1);
			if (ap2->mode == am_imm || ap2->mode == am_imm8) {
				if (ap2->offset->i < 0 || ap2->offset->i > 1)
					ENODE::GenRedor(ap3, ap2);
				else
					GenerateDiadic(op_ldi, 0, ap3, ap2);
			}
			else {
				if (!ap2->isBool)
					ENODE::GenRedor(ap3, ap2);
				else
					GenerateDiadic(op_mov, 0, ap3, ap2);
			}
			GenerateTriadic(op_bit, 0, makecreg(cr), ap4, ap3);
			ReleaseTempRegister(ap4);
			ReleaseTempRegister(ap3);
			GenerateDiadic(op_bne, 0, makecreg(cr), MakeCodeLabel(label));
			break;
		case op_bor:
			ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
			ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm8, size);
			ap3 = GetTempRegister();
			ap4 = GetTempRegister();
			if (!ap1->isBool)
				ENODE::GenRedor(ap4, ap1);
			else
				GenerateDiadic(op_mov, 0, ap4, ap1);
			if (ap2->mode == am_imm || ap2->mode == am_imm8) {
				if (ap2->offset->i < 0 || ap2->offset->i > 1)
					ENODE::GenRedor(ap3, ap2);
				else
					GenerateDiadic(op_ldi, 0, ap3, ap2);
			}
			else {
				if (!ap2->isBool)
					ENODE::GenRedor(ap3, ap2);
				else
					GenerateDiadic(op_mov, 0, ap3, ap2);
			}
			ap5 = GetTempRegister();
			GenerateTriadic(op_or, 0, ap5, ap4, ap3);
			ENODE::GenRedor(ap5, ap5);
			GenerateTriadic(op_bit, 0, makecreg(0), ap5, ap5);
			ReleaseTempRegister(ap5);
			ReleaseTempRegister(ap4);
			ReleaseTempRegister(ap3);
			GenerateDiadic(op_bne, 0, makecreg(0), MakeCodeLabel(label));
			break;
		case op_bnand:
			ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
			ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm8, size);
			ap3 = GetTempRegister();
			ap4 = GetTempRegister();
			if (!ap1->isBool)
				ENODE::GenRedor(ap4, ap1);
			else
				GenerateDiadic(op_mov, 0, ap4, ap1);
			if (ap2->mode == am_imm || ap2->mode == am_imm8) {
				if (ap2->offset->i < 0 || ap2->offset->i > 1)
					ENODE::GenRedor(ap3, ap2);
				else
					GenerateDiadic(op_ldi, 0, ap3, ap2);
			}
			else {
				if (!ap2->isBool)
					ENODE::GenRedor(ap3, ap2);
				else
					GenerateDiadic(op_mov, 0, ap3, ap2);
			}
			GenerateTriadic(op_bit, 0, makecreg(0), ap4, ap3);
			ReleaseTempRegister(ap4);
			ReleaseTempRegister(ap3);
			GenerateDiadic(op_beq, 0, makecreg(0), MakeCodeLabel(label));
			break;
		case op_bnor:
			ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
			ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm8, size);
			ap3 = GetTempRegister();
			ap4 = GetTempRegister();
			if (!ap1->isBool)
				ENODE::GenRedor(ap4, ap1);
			else
				GenerateDiadic(op_mov, 0, ap4, ap1);
			if (ap2->mode == am_imm || ap2->mode == am_imm8) {
				if (ap2->offset->i < 0 || ap2->offset->i > 1)
					ENODE::GenRedor(ap3, ap2);
				else
					GenerateDiadic(op_ldi, 0, ap3, ap2);
			}
			else {
				if (!ap2->isBool)
					ENODE::GenRedor(ap3, ap2);
				else
					GenerateDiadic(op_mov, 0, ap3, ap2);
			}
			ap5 = GetTempRegister();
			GenerateTriadic(op_or, 0, ap5, ap4, ap3);
			ENODE::GenRedor(ap5, ap5);
			GenerateTriadic(op_bit, 0, makecreg(0), ap5, ap5);
			ReleaseTempRegister(ap5);
			ReleaseTempRegister(ap4);
			ReleaseTempRegister(ap3);
			GenerateDiadic(op_beq, 0, makecreg(0), MakeCodeLabel(label));
			break;
		case op_beq:
			ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
			ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm, size);
			GenerateTriadic(op_cmp, 0, makecreg(cr), ap1, ap2);
			GenerateDiadic(op_beq, 0, makecreg(cr), MakeCodeLabel(label));
			break;
		case op_bne:
			ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
			ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm, size);
			GenerateTriadic(op_cmp, 0, makecreg(cr), ap1, ap2);
			GenerateDiadic(op_bne, 0, makecreg(cr), MakeCodeLabel(label));
			break;
		case op_blt:
			ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
			ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm, size);
			GenerateTriadic(op_cmp, 0, makecreg(cr), ap1, ap2);
			GenerateDiadic(op_blt, 0, makecreg(cr), MakeCodeLabel(label));
			break;
		case op_ble:
			ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
			ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm, size);
			GenerateTriadic(op_cmp, 0, makecreg(cr), ap1, ap2);
			GenerateDiadic(op_ble, 0, makecreg(cr), MakeCodeLabel(label));
			break;
		case op_bgt:
			ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
			ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm, size);
			GenerateTriadic(op_cmp, 0, makecreg(cr), ap1, ap2);
			GenerateDiadic(op_bgt, 0, makecreg(cr), MakeCodeLabel(label));
			break;
		case op_bge:
			ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
			ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm, size);
			GenerateTriadic(op_cmp, 0, makecreg(cr), ap1, ap2);
			GenerateDiadic(op_bge, 0, makecreg(cr), MakeCodeLabel(label));
			break;
		case op_bltu:
			ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
			ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm, size);
			GenerateTriadic(op_cmpu, 0, makecreg(cr), ap1, ap2);
			GenerateDiadic(op_blt, 0, makecreg(cr), MakeCodeLabel(label));
			break;
			if (ap2->mode==am_imm) {
				// Don't generate any code if testing against unsigned zero.
				// An unsigned number can't be less than zero so the branch will
				// always be false. Spit out a warning, its probably coded wrong.
				if (ap2->offset->i == 0)
					error(ERR_UBLTZ);	//GenerateDiadic(op_bltu,0,ap1,makereg(0),MakeCodeLabel(label));
				else {
					GenerateTriadic(op_sltu, 0, makecreg(cr), ap1, ap2);
					GenerateDiadic(op_bne, 0, makecreg(cr), MakeCodeLabel(label));
					break;
				}
			}
			else {
				GenerateTriadic(op_sltu, 0, makecreg(cr), ap1, ap2);
				GenerateDiadic(op_bne, 0, makecreg(cr), MakeCodeLabel(label));
			}
			break;
		case op_bleu:
			ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
			ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm, size);
			GenerateTriadic(op_cmpu, 0, makecreg(cr), ap1, ap2);
			GenerateDiadic(op_ble, 0, makecreg(cr), MakeCodeLabel(label));
			break;
		case op_bgtu:
			ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
			ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm, size);
			GenerateTriadic(op_cmpu, 0, makecreg(cr), ap1, ap2);
			GenerateDiadic(op_bgt, 0, makecreg(cr), MakeCodeLabel(label));
			break;
		case op_bgeu:
			ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
			ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm, size);
			GenerateTriadic(op_cmpu, 0, makecreg(cr), ap1, ap2);
			GenerateDiadic(op_bge, 0, makecreg(cr), MakeCodeLabel(label));
			break;
			if (ap2->mode == am_imm) {
				if (ap2->offset->i == 0) {
					// This branch is always true
					error(ERR_UBGEQ);
					GenerateMonadic(op_bra, 0, MakeCodeLabel(label));
				}
				else {
					GenerateTriadic(op_sgeu, 0, makecreg(0), ap1, ap2);
					GenerateDiadic(op_bne, 0, makecreg(0), MakeCodeLabel(label));
				}
			}
			else {
				GenerateTriadic(op_sgeu, 0, makecreg(0), ap1, ap2);
				GenerateDiadic(op_bne, 0, makecreg(0), MakeCodeLabel(label));
			}
			break;
		}
		//GenerateDiadic(op,sz,ap1,ap2,MakeCodeLabel(label));
	}
  ReleaseTempReg(ap2);
  ReleaseTempReg(ap1);
	return (true);
}


static void SaveRegisterSet(SYM *sym)
{
	int nn, mm;

	if (!cpu.SupportsPush) {
		mm = sym->tp->GetBtp()->type!=bt_void ? 29 : 30;
		GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),cg.MakeImmediate(mm*sizeOfWord));
		mm = 0;
		for (nn = 1 + (sym->tp->GetBtp()->type!=bt_void ? 1 : 0); nn < 31; nn++) {
			GenerateDiadic(op_st,0,makereg(nn),cg.MakeIndexed(mm,regSP));
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
			GenerateDiadic(op_ld,0,makereg(nn),cg.MakeIndexed(mm,regSP));
			mm += sizeOfWord;
		}
		mm = sym->tp->GetBtp()->type!=bt_void ? 29 : 30;
		GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),cg.MakeImmediate(mm*sizeOfWord));
	}
	else
		for (nn = 1 + (sym->tp->GetBtp()->type!=bt_void ? 1 : 0); nn < 31; nn++)
			GenerateMonadic(op_pop,0,makereg(nn));
}


// Push temporaries on the stack.

void SaveRegisterVars(CSet *rmask)
{
	int cnt;
	int nn;

	if( rmask->NumMember() ) {
		cnt = 0;
		GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),cg.MakeImmediate(rmask->NumMember()*8));
		rmask->resetPtr();
		for (nn = rmask->lastMember(); nn >= 0; nn = rmask->prevMember()) {
			// nn = nregs - 1 - regno
			// regno = -(nn - nregs + 1);
			// regno = nregs - 1 - nn
			GenerateDiadic(op_st,0,makereg(nregs-1-nn),cg.MakeIndexed(cnt,regSP));
			cnt+=sizeOfWord;
		}
	}
}

void SaveFPRegisterVars(CSet *rmask)
{
	int cnt;
	int nn;

	if( rmask->NumMember() ) {
		cnt = 0;
		GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),cg.MakeImmediate(rmask->NumMember()*8));
		for (nn = rmask->lastMember(); nn >= 0; nn = rmask->prevMember()) {
			GenerateDiadic(op_stf, 'd', makefpreg(nregs - 1 - nn), cg.MakeIndexed(cnt, regSP));
			cnt += sizeOfWord;
		}
	}
}

// Restore registers used as register variables.

static void RestoreRegisterVars()
{
	int cnt2, cnt;
	int nn;

	if( save_mask->NumMember()) {
		cnt2 = cnt = save_mask->NumMember()*sizeOfWord;
		cnt = 0;
		save_mask->resetPtr();
		for (nn = save_mask->nextMember(); nn >= 0; nn = save_mask->nextMember()) {
			GenerateDiadic(op_ld,0,makereg(nn),cg.MakeIndexed(cnt,regSP));
			cnt += sizeOfWord;
		}
		GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),cg.MakeImmediate(cnt2));
	}
}

static void RestoreFPRegisterVars()
{
	int cnt2, cnt;
	int nn;

	if( fpsave_mask->NumMember()) {
		cnt2 = cnt = fpsave_mask->NumMember()*sizeOfWord;
		cnt = 0;
		fpsave_mask->resetPtr();
		for (nn = fpsave_mask->nextMember(); nn >= 0; nn = fpsave_mask->nextMember()) {
			GenerateDiadic(op_ldf, 'd', makefpreg(nn), cg.MakeIndexed(cnt, regSP));
			cnt += sizeOfWord;
		}
		GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),cg.MakeImmediate(cnt2));
	}
}

static int round4(int n)
{
    while(n & 3) n++;
    return (n);
};

// push the operand expression onto the stack.
// Structure variables are represented as an address in a register and arrive
// here as autocon nodes if on the stack. If the variable size is greater than
// 8 we assume a structure variable and we assume we have the address in a reg.
// Returns: number of stack words pushed.
//
int FT64CodeGenerator::PushArgument(ENODE *ep, int regno, int stkoffs, bool *isFloat)
{    
	Operand *ap, *ap3;
	int nn = 0;
	int sz;

	*isFloat = false;
	switch(ep->etype) {
	case bt_quad:	sz = sizeOfFPD; break;
	case bt_triple:	sz = sizeOfFPT; break;
	case bt_double:	sz = sizeOfFPD; break;
	case bt_float:	sz = sizeOfFPD; break;
	default:	sz = sizeOfWord; break;
	}
	if (ep->tp) {
		if (ep->tp->IsFloatType())
			ap = cg.GenerateExpression(ep,am_reg,sizeOfFP);
		else
			ap = cg.GenerateExpression(ep,am_reg|am_imm,GetNaturalSize(ep));
	}
	else if (ep->etype==bt_quad)
		ap = cg.GenerateExpression(ep,am_reg,sz);
	else if (ep->etype==bt_double)
		ap = cg.GenerateExpression(ep,am_reg,sz);
	else if (ep->etype==bt_triple)
		ap = cg.GenerateExpression(ep,am_reg,sz);
	else if (ep->etype==bt_float)
		ap = cg.GenerateExpression(ep,am_reg,sz);
	else
		ap = cg.GenerateExpression(ep,am_reg|am_imm,GetNaturalSize(ep));
	switch(ap->mode) {
	case am_fpreg:
		*isFloat = true;
	case am_reg:
  case am_imm:
/*
        nn = round8(ep->esize); 
        if (nn > 8) {// && (ep->tp->type==bt_struct || ep->tp->type==bt_union)) {           // structure or array ?
            ap2 = GetTempRegister();
            GenerateTriadic(op_subui,0,makereg(regSP),makereg(regSP),MakeImmediate(nn));
            GenerateDiadic(op_mov, 0, ap2, makereg(regSP));
            GenerateMonadic(op_push,0,MakeImmediate(ep->esize));
            GenerateMonadic(op_push,0,ap);
            GenerateMonadic(op_push,0,ap2);
            GenerateMonadic(op_bsr,0,MakeStringAsNameConst("memcpy_"));
            GenerateTriadic(op_addui,0,makereg(regSP),makereg(regSP),MakeImmediate(24));
          	GenerateMonadic(op_push,0,ap2);
            ReleaseTempReg(ap2);
            nn = nn >> 3;
        }
        else {
*/
			if (regno) {
				GenerateMonadic(op_hint,0,MakeImmediate(1));
				if (ap->mode==am_imm) {
					GenerateDiadic(op_ldi,0,makereg(regno & 0x7fff), ap);
					if (regno & 0x8000) {
						GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),MakeImmediate(sizeOfWord));
						nn = 1;
					}
				}
				else if (ap->mode==am_fpreg) {
					*isFloat = true;
					GenerateDiadic(op_mov,0,makefpreg(regno & 0x7fff), ap);
					if (regno & 0x8000) {
						GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),MakeImmediate(sz));
						nn = sz/sizeOfWord;
					}
				}
				else {
					//ap->preg = regno & 0x7fff;
					GenerateDiadic(op_mov,0,makereg(regno & 0x7fff), ap);
					if (regno & 0x8000) {
						GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),MakeImmediate(sizeOfWord));
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
							GenerateMonadic(op_push,0,ap);
						}
						nn = 1;
					}
					else {
						if (ap->type==stddouble.GetIndex()) 
						{
							*isFloat = true;
							GenerateMonadic(op_push,ap->FloatSize,ap);
							nn = sz/sizeOfWord;
						}
						else {
							regs[ap->preg].IsArg = true;
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
							regs[ap3->preg].IsArg = true;
							GenLoadConst(ap, ap3);
	         				GenerateDiadic(op_st,0,ap3,MakeIndexed(stkoffs,regSP));
							ReleaseTempReg(ap3);
						}
						else {
							GenerateDiadic(op_st, 0, makereg(0), MakeIndexed(stkoffs, regSP));
						}
						nn = 1;
					}
					else {
						if (ap->type==stddouble.GetIndex() || ap->mode==am_fpreg) {
							*isFloat = true;
							GenerateDiadic(op_stf,'d',ap,MakeIndexed(stkoffs,regSP));
							nn = sz/sizeOfWord;
						}
						else {
							regs[ap->preg].IsArg = true;
							GenerateDiadic(op_st,0,ap,MakeIndexed(stkoffs,regSP));
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
int FT64CodeGenerator::PushArguments(Function *sym, ENODE *plist)
{
	TypeArray *ta = nullptr;
	int i,sum,offs;
	OCODE *ip;
	ENODE *p;
	ENODE *pl[100];
	int nn, maxnn;
	bool isFloat;
	bool sumFloat;
	bool o_supportsPush;

	sum = 0;
	if (sym)
		ta = sym->GetProtoTypes();

	sumFloat = false;
	ip = currentFn->pl.tail;
	GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),MakeImmediate(0));
	// Capture the parameter list. It is needed in the reverse order.
	for (nn = 0, p = plist; p != NULL; p = p->p[1], nn++) {
		pl[nn] = p->p[0];
	}
	maxnn = nn;
	for(--nn, i = 0; nn >= 0; --nn,i++ )
  {
		if (pl[nn]->etype == bt_pointer)
			if (pl[nn]->tp->GetBtp()->type == bt_ichar || pl[nn]->tp->GetBtp()->type == bt_iuchar)
				continue;
				//		sum += GeneratePushParameter(pl[nn],ta ? ta->preg[ta->length - i - 1] : 0,sum*8);
		// Variable argument list functions may cause the type array values to be
		// exhausted before all the parameters are pushed. So, we check the parm number.
		sum += PushArgument(pl[nn],ta ? (i < ta->length ? ta->preg[i] : 0) : 0,sum*sizeOfWord, &isFloat);
		sumFloat |= isFloat;
//		plist = plist->p[1];
  }
	if (sum==0)
		ip->fwd->MarkRemove();
	else
		ip->fwd->oper3 = MakeImmediate(sum*sizeOfWord);
	if (!sumFloat) {
		o_supportsPush = cpu.SupportsPush;
		//cpu.SupportsPush = true;
		currentFn->pl.tail = ip;
		currentFn->pl.tail->fwd = nullptr;
		i = maxnn-1;
		offs = 0;
		GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), MakeImmediate(sum * sizeOfWord));
		for (nn = 0; nn < maxnn; nn++, i--) {
			if (pl[nn]->etype == bt_pointer)
				if (pl[nn]->tp->GetBtp()->type == bt_ichar || pl[nn]->tp->GetBtp()->type == bt_iuchar)
					continue;
			offs += sizeOfWord;
			PushArgument(pl[nn], ta ? (i < ta->length ? ta->preg[i] : 0) : 0, sum * sizeOfWord-offs, &isFloat);
		}
		cpu.SupportsPush = o_supportsPush;
	}
	if (ta)
		delete ta;
    return (sum);
}

// Pop parameters off the stack

void FT64CodeGenerator::PopArguments(Function *fnc, int howMany, bool isPascal)
{
	if (howMany != 0) {
		if (fnc) {
			if (!fnc->IsPascal)
				GenerateTriadic(op_add, 0, makereg(regSP), makereg(regSP), MakeImmediate(howMany * sizeOfWord));
		}
		else {
			if (!isPascal)
				GenerateTriadic(op_add, 0, makereg(regSP), makereg(regSP), MakeImmediate(howMany * sizeOfWord));
		}
	}
}


// Return true if the expression tree has isPascal set anywhere.
// Only needed for indirect function calls.
extern int defaultcc;
bool FT64CodeGenerator::IsPascal(ENODE *ep)
{
	if (ep == nullptr)
		return (defaultcc==1);
	if (ep->isPascal)
		return (true);
	if (IsPascal(ep->p[0]) || IsPascal(ep->p[1]) || IsPascal(ep->p[2]))
		return (true);
	return (false);
}

void FT64CodeGenerator::LinkAutonew(ENODE *node)
{
	if (node->isAutonew) {
		currentFn->hasAutonew = true;
	}
}

Operand *FT64CodeGenerator::GenerateFunctionCall(ENODE *node, int flags)
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
	CSet *mask, *fmask;

	sym = nullptr;

	// Call the function
	if( node->p[0]->nodetype == en_nacon || node->p[0]->nodetype == en_cnacon ) {
		s = gsearch(*node->p[0]->sp);
 		sym = s->fi;
        i = 0;
  /*
    	if ((sym->tp->GetBtp()->type==bt_struct || sym->tp->GetBtp()->type==bt_union) && sym->tp->GetBtp()->size > 8) {
            nn = tmpAlloc(sym->tp->GetBtp()->size) + lc_auto + round8(sym->tp->GetBtp()->size);
            GenerateMonadic(op_pea,0,MakeIndexed(-nn,regFP));
            i = 1;
        }
*/
//		ReleaseTempRegister(ap);
		sym->SaveTemporaries(&sp, &fsp);
		if (currentFn->HasRegisterParameters())
			sym->SaveRegisterArguments();
		// If the symbol is unknown, assume a throw is present
		if (sym) {
			if (sym->DoesThrow)
				currentFn->DoesThrow = true;
		}
		else
			currentFn->DoesThrow = true;
		i = i + PushArguments(sym, node->p[1]);
		if (sym && sym->IsInline) {
			o_fn = currentFn;
			mask = save_mask;
			fmask = fpsave_mask;
			currentFn = sym;
			ps = pass;
			// Each function has it's own peeplist. The generated peeplist for an
			// inline function must be appended onto the peeplist of the current
			// function.
			sym->pl.head = sym->pl.tail = nullptr;
			sym->Gen();
			pass = ps;
			currentFn = o_fn;
			currentFn->pl.tail->fwd = sym->pl.head;
			currentFn->pl.tail = sym->pl.tail;
			LinkAutonew(node);
			fpsave_mask = fmask;
			save_mask = mask;
		}
		else {
			GenerateDiadic(op_jal,0,makelreg(1),MakeDirect(node->p[0]));
			GenerateMonadic(op_bex,0,MakeDataLabel(throwlab));
			LinkAutonew(node);
		}
		GenerateInlineArgumentList(sym, node->p[1]);
		PopArguments(sym, i);
		if (currentFn->HasRegisterParameters())
			if (sym)
				sym->RestoreRegisterArguments();
		if (sym)
			sym->RestoreTemporaries(sp, fsp);
	}
    else
    {
        i = 0;
    /*
    	if ((node->p[0]->tp->GetBtp()->type==bt_struct || node->p[0]->tp->GetBtp()->type==bt_union) && node->p[0]->tp->GetBtp()->size > 8) {
            nn = tmpAlloc(node->p[0]->tp->GetBtp()->size) + lc_auto + round8(node->p[0]->tp->GetBtp()->size);
            GenerateMonadic(op_pea,0,MakeIndexed(-nn,regFP));
            i = 1;
        }
     */
		ap = cg.GenerateExpression(node->p[0],am_reg,sizeOfWord);
		if (ap->offset) {
			if (ap->offset->sym)
				sym = ap->offset->sym->fi;
		}
		if (sym)
			sym->SaveTemporaries(&sp, &fsp);
		if (currentFn->HasRegisterParameters())
			if (sym)
				sym->SaveRegisterArguments();
		i = i + PushArguments(sym, node->p[1]);
		// If the symbol is unknown, assume a throw is present
		if (sym) {
			if (sym->DoesThrow)
				currentFn->DoesThrow = true;
		}
		else
			currentFn->DoesThrow = true;
		ap->mode = am_ind;
		ap->offset = 0;
		if (sym && sym->IsInline) {
			o_fn = currentFn;
			mask = save_mask;
			fmask = fpsave_mask;
			currentFn = sym;
			ps = pass;
			sym->pl.head = sym->pl.tail = nullptr;
			sym->Gen();
			pass = ps;
			currentFn = o_fn;
			currentFn->pl.tail->fwd = sym->pl.head;
			currentFn->pl.tail = sym->pl.tail;
			LinkAutonew(node);
			fpsave_mask = fmask;
			save_mask = mask;
		}
		else {
			GenerateDiadic(op_jal,0,makelreg(1),ap);
			GenerateMonadic(op_bex,0,MakeDataLabel(throwlab));
			LinkAutonew(node);
		}
		GenerateInlineArgumentList(sym, node->p[1]);
		PopArguments(sym, i, IsPascal(node));
		if (currentFn->HasRegisterParameters())
			if (sym)
				sym->RestoreRegisterArguments();
		if (sym)
			sym->RestoreTemporaries(sp, fsp);
		ReleaseTempRegister(ap);
	}
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
		if (!(flags & am_novalue))
			return (makefpreg(1));
		else
			return (makefpreg(0));
	}
	if (sym
		&& sym->sym
		&& sym->sym->tp
		&& sym->sym->tp->GetBtp()
		&& sym->sym->tp->GetBtp()->IsVectorType()) {
		if (!(flags & am_novalue))
			return (makevreg(1));
		else
			return (makevreg(0));
	}
	if (sym
		&& sym->sym
		&& sym->sym->tp
		&& sym->sym->tp->GetBtp()
		) {
		if (!(flags & am_novalue)) {
			if (sym->sym->tp->GetBtp()->type != bt_void) {
				ap = GetTempRegister();
				GenerateDiadic(op_mov, 0, ap, makereg(1));
				regs[1].modified = true;
			}
			else
				ap = makereg(0);
			ap->isPtr = sym->sym->tp->GetBtp()->type == bt_pointer;
		}
		else
			return(makereg(0));
	}
	else {
		if (!(flags & am_novalue)) {
			ap = GetTempRegister();
			GenerateDiadic(op_mov, 0, ap, makereg(1));
			regs[1].modified = true;
		}
		else
			return(makereg(0));
	}
	return (ap);
	/*
	else {
		if( result->preg != 1 || (flags & am_reg) == 0 ) {
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
