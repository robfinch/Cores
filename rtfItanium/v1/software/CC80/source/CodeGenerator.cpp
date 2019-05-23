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

/*
 *      this module contains all of the code generation routines
 *      for evaluating expressions and conditions.
 */

int hook_predreg=15;

Operand *GenerateExpression();            /* forward ParseSpecifieraration */

extern Operand *GenExpr(ENODE *node);

void GenLoad(Operand *ap3, Operand *ap1, int ssize, int size);

extern int throwlab;
static int nest_level = 0;

static void Enter(char *p)
{
/*
     int nn;
     
     for (nn = 0; nn < nest_level; nn++)
         printf(" ");
     printf("%s: %d ", p, lineno);
     nest_level++;
*/
}
static void Leave(char *p, int n)
{
/*
     int nn;
     
     nest_level--;
     for (nn = 0; nn < nest_level; nn++)
         printf(" ");
     printf("%s (%d) ", p, n);
*/
}


Operand *CodeGenerator::MakeDataLabel(int lab)
{
	return (compiler.of.MakeDataLabel(lab));
}

Operand *CodeGenerator::MakeCodeLabel(int lab)
{
	return (compiler.of.MakeCodeLabel(lab));
}

Operand *CodeGenerator::MakeStringAsNameConst(char *s)
{
	return (compiler.of.MakeStringAsNameConst(s));
}

Operand *CodeGenerator::MakeString(char *s)
{
	return (compiler.of.MakeString(s));
}

Operand *CodeGenerator::MakeImmediate(int64_t i)
{
	return (compiler.of.MakeImmediate(i));
}

Operand *CodeGenerator::MakeIndirect(int i)
{
	return (compiler.of.MakeIndirect(i));
}

Operand *CodeGenerator::MakeIndexed(int64_t o, int i)
{
	return (compiler.of.MakeIndexed(o, i));
}

Operand *CodeGenerator::MakeDoubleIndexed(int i, int j, int scale)
{
	return (compiler.of.MakeDoubleIndexed(i, j, scale));
}

Operand *CodeGenerator::MakeDirect(ENODE *node)
{
	return (compiler.of.MakeDirect(node));
}

Operand *CodeGenerator::MakeIndexed(ENODE *node, int rg)
{
	return (compiler.of.MakeIndexed(node, rg));
}

void CodeGenerator::GenerateHint(int num)
{
	GenerateMonadic(op_hint,0,MakeImmediate(num));
}

void CodeGenerator::GenerateComment(char *cm)
{
	GenerateMonadic(op_rem2,0,MakeStringAsNameConst(cm));
}


void CodeGenerator::GenLoad(Operand *ap3, Operand *ap1, int ssize, int size)
{
	if (ap3->mode == am_fpreg) {
		GenerateDiadic(op_lf, 'd', ap3, ap1);
	}
	else if (ap3->type==stdvector.GetIndex()) {
        GenerateDiadic(op_lv,0,ap3,ap1);
	}
	else if (ap3->type == stdflt.GetIndex()) {
		GenerateDiadic(op_lf, 'd', ap3, ap1);
	}
	else if (ap3->type==stddouble.GetIndex()) {
		GenerateDiadic(op_lf,'d',ap3,ap1);
	}
	else if (ap3->type == stdquad.GetIndex()) {
		GenerateDiadic(op_lf, 'q', ap3, ap1);
	}
	else if (ap3->type == stdtriple.GetIndex()) {
		GenerateDiadic(op_lf, 't', ap3, ap1);
	}
	else if (ap3->isUnsigned) {
		if (ap3->isVolatile) {
			switch (size) {
			case 1:	GenerateDiadic(op_lvbu, 0, ap3, ap1); break;
			case 2:	GenerateDiadic(op_lvcu, 0, ap3, ap1); break;
			case 4:	GenerateDiadic(op_lvhu, 0, ap3, ap1); break;
			case 8: GenerateDiadic(op_lvw, 0, ap3, ap1); break;
			}
		}
		else {
			switch (size) {
			case 1:	GenerateDiadic(op_lbu, 0, ap3, ap1); break;
			case 2:	GenerateDiadic(op_lcu, 0, ap3, ap1); break;
			case 4:	GenerateDiadic(op_lhu, 0, ap3, ap1); break;
			case 8: GenerateDiadic(op_lw, 0, ap3, ap1); break;
			}
		}
    }
    else {
		if (ap3->isVolatile) {
			switch (size) {
			case 1:	GenerateDiadic(op_lvb, 0, ap3, ap1); break;
			case 2:	GenerateDiadic(op_lvc, 0, ap3, ap1); break;
			case 4:	GenerateDiadic(op_lvh, 0, ap3, ap1); break;
			case 8:	GenerateDiadic(op_lvw, 0, ap3, ap1); break;
			}
		}
		else {
			switch (size) {
			case 1:	GenerateDiadic(op_lb, 0, ap3, ap1); break;
			case 2:	GenerateDiadic(op_lc, 0, ap3, ap1); break;
			case 4:	GenerateDiadic(op_lh, 0, ap3, ap1); break;
			case 8:	GenerateDiadic(op_lw, 0, ap3, ap1); break;
			}
		}
    }
}

void CodeGenerator::GenStore(Operand *ap1, Operand *ap3, int size)
{
	//if (ap1->isPtr) {
	//	GenerateDiadic(op_sw, 0, ap1, ap3);
	//}
	//else
	if (ap1->type==stdvector.GetIndex())
	    GenerateDiadic(op_sv,0,ap1,ap3);
	else if (ap1->type == stdflt.GetIndex()) {
		GenerateDiadic(op_sf, 'd', ap1, ap3);
	}
	else if (ap1->type == stddouble.GetIndex()) {
		GenerateDiadic(op_sf, 'd', ap1, ap3);
	}
	else if (ap1->type == stdquad.GetIndex()) {
		GenerateDiadic(op_sf, 'q', ap1, ap3);
	}
	else if (ap1->type == stdtriple.GetIndex()) {
		GenerateDiadic(op_sf, 't', ap1, ap3);
	}
	else if (ap1->mode==am_fpreg)
		GenerateDiadic(op_sf,'d',ap1,ap3);
	else {
		switch (size) {
		case 1: GenerateDiadic(op_sb, 0, ap1, ap3); break;
		case 2: GenerateDiadic(op_sc, 0, ap1, ap3); break;
		case 4: GenerateDiadic(op_sh, 0, ap1, ap3); break;
		case 8: GenerateDiadic(op_sw, 0, ap1, ap3); break;
		default:
			;
		}
	}
}

//
//  Return the addressing mode of a dereferenced node.
//
Operand *CodeGenerator::GenerateDereference(ENODE *node,int flags,int size, int su)
{    
	Operand *ap1, *ap2, *ap3;
  int siz1;
	int typ;

  Enter("<Genderef>");
	siz1 = node->GetReferenceSize();
	// When dereferencing a struct or union return a pointer to the struct or
	// union.
	//if (node->tp)
	//	if (node->tp->type==bt_struct || node->tp->type==bt_union) {
	//		return GenerateExpression(node, am_reg | am_mem, size);
	//	}

    if( node->p[0]->nodetype == en_add )
    {
//    ap2 = GetTempRegister();
      ap1 = node->p[0]->GenIndex();
//        GenerateTriadic(op_add,0,ap2,makereg(ap1->preg),makereg(regGP));
			ap1->isUnsigned = !su;//node->isUnsigned;
		// *** may have to fix for stackseg
			ap1->segment = dataseg;
//		ap2->mode = ap1->mode;
//		ap2->segment = dataseg;
//		ap2->offset = ap1->offset;
//		ReleaseTempRegister(ap1);
			if (!node->isUnsigned)
				ap1 = ap1->GenSignExtend(siz1,size,flags);
			else
				ap1->MakeLegal(flags,siz1);
      ap1->MakeLegal(flags,size);
			return (ap1);
		}

  if(node->p[0]->nodetype == en_autocon)
  {
    ap1 = allocOperand();
		ap1->isPtr = node->IsRefType();
		ap1->mode = am_indx;
		ap1->preg = regFP;
		ap1->segment = stackseg;
		ap1->offset = makeinode(en_icon,node->p[0]->i);
		ap1->offset->sym = node->p[0]->sym;
		ap1->isUnsigned = !su;
		if (!node->isUnsigned)
			ap1 = ap1->GenSignExtend(siz1,size,flags);
		else
			ap1->MakeLegal(flags,siz1);
		ap1->MakeLegal(flags,size);
		return (ap1);
  }

    if( node->p[0]->nodetype == en_classcon )
    {
        ap1 = allocOperand();
		ap1->isPtr = node->nodetype == en_wp_ref || node->nodetype == en_hp_ref;
		ap1->mode = am_indx;
        ap1->preg = regCLP;
		ap1->segment = dataseg;
        ap1->offset = makeinode(en_icon,node->p[0]->i);
		ap1->offset->sym = node->p[0]->sym;
		ap1->isUnsigned = !su;
		if (!node->isUnsigned)
	    ap1 = ap1->GenSignExtend(siz1,size,flags);
		else
		  ap1->MakeLegal(flags,siz1);
    ap1->MakeLegal(flags,size);
		goto xit;
    }
    else if( node->p[0]->nodetype == en_autofcon )
    {
    ap1 = allocOperand();
		ap1->isPtr = node->nodetype == en_wp_ref || node->nodetype == en_hp_ref
			|| node->nodetype == en_dbl_ref || node->nodetype == en_flt_ref 
			|| node->nodetype == en_triple_ref || node->nodetype == en_quad_ref;
		ap1->mode = am_indx;
    ap1->preg = regFP;
    ap1->offset = makeinode(en_icon,node->p[0]->i);
		ap1->offset->sym = node->p[0]->sym;
		if (node->p[0]->tp)
			switch(node->p[0]->tp->precision) {
			case 32: ap1->FloatSize = 's'; break;
			case 64: ap1->FloatSize = 'd'; break;
			default: ap1->FloatSize = 'd'; break;
			}
		else
			ap1->FloatSize = 'd';
		ap1->segment = stackseg;
		switch (node->p[0]->tp->type) {
		case bt_float:	ap1->type = stdflt.GetIndex(); break;
		case bt_double:	ap1->type = stddouble.GetIndex(); break;
		case bt_triple:	ap1->type = stdtriple.GetIndex(); break;
		case bt_quad:	ap1->type = stdquad.GetIndex(); break;
		}
//	    ap1->MakeLegal(flags,siz1);
        ap1->MakeLegal(flags,size);
		goto xit;
    }
    else if( node->p[0]->nodetype == en_autovcon )
    {
        ap1 = allocOperand();
		ap1->isPtr = node->nodetype == en_wp_ref || node->nodetype == en_hp_ref;
		ap1->mode = am_indx;
        ap1->preg = regFP;
        ap1->offset = makeinode(en_icon,node->p[0]->i);
		ap1->offset->sym = node->p[0]->sym;
		if (node->p[0]->tp)
			switch(node->p[0]->tp->precision) {
			case 32: ap1->FloatSize = 's'; break;
			case 64: ap1->FloatSize = 'd'; break;
			default: ap1->FloatSize = 'd'; break;
			}
		else
			ap1->FloatSize = 'd';
		ap1->segment = stackseg;
		ap1->type = stdvector.GetIndex();
		//	    ap1->MakeLegal(flags,siz1);
        ap1->MakeLegal(flags,size);
		goto xit;
    }
    else if( node->p[0]->nodetype == en_autovmcon )
    {
        ap1 = allocOperand();
		ap1->isPtr = node->nodetype == en_wp_ref || node->nodetype == en_hp_ref;
		ap1->mode = am_indx;
        ap1->preg = regFP;
        ap1->offset = makeinode(en_icon,node->p[0]->i);
		ap1->offset->sym = node->p[0]->sym;
		if (node->p[0]->tp)
			switch(node->p[0]->tp->precision) {
			case 32: ap1->FloatSize = 's'; break;
			case 64: ap1->FloatSize = 'd'; break;
			default: ap1->FloatSize = 'd'; break;
			}
		else
			ap1->FloatSize = 'd';
		ap1->segment = stackseg;
		ap1->type = stdvectormask->GetIndex();
		//	    ap1->MakeLegal(flags,siz1);
        ap1->MakeLegal(flags,size);
		goto xit;
    }
	else if ((node->p[0]->nodetype == en_labcon) && use_gp)
	{
		ap1 = allocOperand();
		ap1->isPtr = node->nodetype == en_wp_ref || node->nodetype == en_hp_ref;
		ap1->mode = am_indx;
		switch (node->p[0]->segment) {
		case dataseg:	ap1->preg = regGP; break;
		case tlsseg:	ap1->preg = regTP; break;
		default:	ap1->preg = regPP; break;
		}
		ap1->segment = node->p[0]->segment;
		ap1->offset = node->p[0];//makeinode(en_icon,node->p[0]->i);
		ap1->isUnsigned = !su;
		if (!node->isUnsigned)
			ap1 = ap1->GenSignExtend(siz1, size, flags);
		else
			ap1->MakeLegal( flags, siz1);
		ap1->isVolatile = node->isVolatile;
		ap1->MakeLegal( flags, size);
		goto xit;
	}
	else if(( node->p[0]->nodetype==en_nacon ) && use_gp)
    {
        ap1 = allocOperand();
		ap1->isPtr = node->nodetype == en_wp_ref || node->nodetype == en_hp_ref;
		ap1->mode = am_indx;
        ap1->preg = regGP;
		ap1->segment = dataseg;
        ap1->offset = node->p[0];//makeinode(en_icon,node->p[0]->i);
		ap1->isUnsigned = !su;
		if (!node->isUnsigned)
	       ap1 = ap1->GenSignExtend(siz1,size,flags);
		else
		    ap1->MakeLegal(flags,siz1);
        ap1->isVolatile = node->isVolatile;
		switch (node->p[0]->tp->type) {
		case bt_float:	ap1->type = stdflt.GetIndex(); break;
		case bt_double:	ap1->type = stddouble.GetIndex(); break;
		case bt_triple:	ap1->type = stdtriple.GetIndex(); break;
		case bt_quad:	ap1->type = stdquad.GetIndex(); break;
		}
		ap1->MakeLegal(flags,size);
		goto xit;
    }
	else if ((node->p[0]->nodetype == en_labcon) && !use_gp)
	{
		ap1 = allocOperand();
		ap1->isPtr = node->nodetype == en_wp_ref || node->nodetype == en_hp_ref;
		ap1->mode = am_direct;
		ap1->preg = 0;
		ap1->segment = node->p[0]->segment;
		ap1->offset = node->p[0];//makeinode(en_icon,node->p[0]->i);
		ap1->isUnsigned = !su;
		if (!node->isUnsigned)
			ap1 = ap1->GenSignExtend(siz1, size, flags);
		else
			ap1->MakeLegal( flags, siz1);
		ap1->isVolatile = node->isVolatile;
		ap1->MakeLegal( flags, size);
		goto xit;
	}
	else if ((node->p[0]->nodetype == en_nacon) && !use_gp)
	{
		ap1 = allocOperand();
		ap1->isPtr = node->nodetype == en_wp_ref || node->nodetype == en_hp_ref;
		ap1->mode = am_direct;
		ap1->preg = 0;
		ap1->segment = dataseg;
		ap1->offset = node->p[0];//makeinode(en_icon,node->p[0]->i);
		ap1->isUnsigned = !su;
		if (!node->isUnsigned)
			ap1 = ap1->GenSignExtend(siz1, size, flags);
		else
			ap1->MakeLegal( flags, siz1);
		ap1->isVolatile = node->isVolatile;
		switch (node->p[0]->tp->type) {
		case bt_float:	ap1->type = stdflt.GetIndex(); break;
		case bt_double:	ap1->type = stddouble.GetIndex(); break;
		case bt_triple:	ap1->type = stdtriple.GetIndex(); break;
		case bt_quad:	ap1->type = stdquad.GetIndex(); break;
		}
		ap1->MakeLegal( flags, size);
		goto xit;
	}
	else if (node->p[0]->nodetype == en_regvar) {
    ap1 = allocOperand();
		ap1->isPtr = node->nodetype == en_wp_ref || node->nodetype == en_hp_ref;

		// For parameters we want Rn, for others [Rn]
		// This seems like an error earlier in the compiler
		// See setting val_flag in ParseExpressions
		ap1->mode = node->p[0]->rg < regFirstArg ? am_ind : am_reg;
//		ap1->mode = node->p[0]->tp->val_flag ? am_reg : am_ind;
		ap1->preg = node->p[0]->rg;
		ap1->MakeLegal(flags,size);
	    Leave("Genderef",3);
        return ap1;
	}
	else if (node->p[0]->nodetype == en_fpregvar) {
		/*error(ERR_DEREF)*/;
		ap1 = allocOperand();
		ap1->isPtr = node->nodetype == en_wp_ref || node->nodetype == en_hp_ref;
		ap1->mode = node->p[0]->rg < regFirstArg ? am_ind : am_fpreg;
		ap1->preg = node->p[0]->rg;
		switch (node->p[0]->tp->type) {
		case bt_float:	ap1->type = stdflt.GetIndex(); break;
		case bt_double:	ap1->type = stddouble.GetIndex(); break;
		case bt_triple:	ap1->type = stdtriple.GetIndex(); break;
		case bt_quad:	ap1->type = stdquad.GetIndex(); break;
		}
        ap1->MakeLegal(flags,size);
	    Leave("</Genderef>",3);
        return (ap1);
	}
	else if (node->p[0]->nodetype == en_vex) {
		Operand *ap2;
		if (node->p[0]->p[0]->nodetype==en_vector_ref) {
			ap1 = GenerateDereference(node->p[0]->p[0],am_reg,8,0);
			ap2 = GenerateExpression(node->p[0]->p[1],am_reg,8);
			if (ap1->offset && ap2->offset) {
				GenerateTriadic(op_add,0,ap1,makereg(0),MakeImmediate(ap2->offset->i));
			}
			ReleaseTempReg(ap2);
			//ap1->mode = node->p[0]->i < 18 ? am_ind : am_reg;
			//ap1->preg = node->p[0]->i;
			ap1->type = stdvector.GetIndex();
			ap1->MakeLegal(flags,size);
			return (ap1);
		}
	}
	ap1 = GenerateExpression(node->p[0], am_reg | am_imm, 8); // generate address
	ap1->isPtr = node->IsRefType();
	if( ap1->mode == am_reg)
    {
			// This seems a bit of a kludge. If we are dereferencing and there's a
			// pointer in the register, then we want the value at the pointer location.
			if (ap1->isPtr && !IsLValue(node)) {
				int sz = node->GetReferenceSize();
				if (node->nodetype == en_dbl_ref) {
					int rg = ap1->preg;
					ReleaseTempRegister(ap1);
					ap1 = GetTempFPRegister();
					GenLoad(ap1, MakeIndirect(rg), sz, sz);
					ap1->mode = am_fpreg;
				}
				else {
					int rg = ap1->preg;
					ReleaseTempRegister(ap1);
					ap1 = GetTempRegister();
					GenLoad(ap1, MakeIndirect(rg), sz, sz);
					ap1->mode = am_reg;
					ap1->isPtr = node->p[0]->IsRefType();
				}
			}
			else
			{
j1:
				//        ap1->mode = am_ind;
				if (use_gp) {
					ap1->mode = am_indx;
					ap1->sreg = regGP;
				}
				else
					ap1->mode = am_ind;
				if (node->p[0]->constflag == TRUE)
					ap1->offset = node->p[0];
				else
					ap1->offset = nullptr;	// ****
				ap1->isUnsigned = !su | ap1->isPtr;
				if (!node->isUnsigned)
					ap1 = ap1->GenSignExtend(siz1, size, flags);
				else
					ap1->MakeLegal(flags, siz1);
				ap1->isVolatile = node->isVolatile;
			}
        ap1->MakeLegal(flags,size);
		goto xit;
    }
	// Note sure about this, but immediate were being incorrectly
	// dereferenced as direct addresses because it would fall through
	// to the following dead code.
	
	if (ap1->mode == am_imm) {
		ap1->MakeLegal( flags, size);
		goto xit;
	}
	
	// *********************************************************************
	// I think what follows is dead code.
	// am_reg and am_imm the only codes that should be generated are
	// checked for above.
	// *********************************************************************

	// See segments notes
	//if (node->p[0]->nodetype == en_labcon &&
	//	node->p[0]->etype == bt_pointer && node->p[0]->constflag)
	//	ap1->segment = codeseg;
	//else
	//	ap1->segment = dataseg;
	if (use_gp) {
    ap1->mode = am_indx;
    ap1->preg = regGP;
    ap1->segment = dataseg;
  }
  else {
//    ap1->mode = am_direct;
	  ap1->isUnsigned = !su | ap1->isPtr;
  }
	if (ap1->isPtr) {
//		ap3 = GetTempRegister();
		ap2 = GetTempRegister();
		GenerateDiadic(op_lw, 0, ap2, ap1);
//		GenLoad(ap3, MakeIndirect(ap2->preg), size, size);
//		ReleaseTempRegister(ap2);
		ap2->MakeLegal(flags, 8);
		return (ap2);
	}
//    ap1->offset = makeinode(en_icon,node->p[0]->i);
  ap1->isUnsigned = !su | ap1->isPtr;
	if (!node->isUnsigned)
	    ap1 = ap1->GenSignExtend(siz1,size,flags);
	else
		ap1->MakeLegal(flags,siz1);
  ap1->isVolatile = node->isVolatile;
  ap1->MakeLegal(flags,size);
xit:
  Leave("</Genderef>",0);
  return (ap1);
}


void CodeGenerator::GenMemop(int op, Operand *ap1, Operand *ap2, int ssize)
{
	Operand *ap3;

	if (ap1->type==stddouble.GetIndex()) {
     	ap3 = GetTempFPRegister();
		GenLoad(ap3,ap1,ssize,ssize);
		GenerateTriadic(op,ap1->FloatSize,ap3,ap3,ap2);
		GenStore(ap3,ap1,ssize);
		ReleaseTempReg(ap3);
		return;
	}
	else if (ap1->type==stdvector.GetIndex()) {
   		ap3 = GetTempVectorRegister();
		GenLoad(ap3,ap1,ssize,ssize);
		GenerateTriadic(op,0,ap3,ap3,ap2);
		GenStore(ap3,ap1,ssize);
		ReleaseTempReg(ap3);
		return;
	}
	//if (ap1->mode != am_indx2)
	// Increment / decrement not supported
	if (0) {
		if (op==op_add && ap2->mode==am_imm && ap2->offset->i >= -16 && ap2->offset->i < 16 && ssize==8) {
			GenerateDiadic(op_inc,0,ap1,ap2);
			return;
		}
		if (op==op_sub && ap2->mode==am_imm && ap2->offset->i >= -15 && ap2->offset->i < 15 && ssize==8) {
			GenerateDiadic(op_dec,0,ap1,ap2);
			return;
		}
	}
   	ap3 = GetTempRegister();
	ap3->isPtr = ap1->isPtr;
    GenLoad(ap3,ap1,ssize,ssize);
	GenerateTriadic(op,0,ap3,ap3,ap2);
	GenStore(ap3,ap1,ssize);
	ReleaseTempReg(ap3);
}

//
//      generate a *= node.
//
Operand *CodeGenerator::GenerateAssignMultiply(ENODE *node,int flags, int size, int op)
{
	Operand *ap1, *ap2, *ap3;
  int ssize;
	MachineReg *mr;

  ssize = GetNaturalSize(node->p[0]);
  if( ssize > size )
    size = ssize;
	if (node->p[0]->IsBitfield()) {
		ap3 = GetTempRegister();
		ap1 = GenerateBitfieldDereference(node->p[0], am_reg | am_mem, size, 1);
		GenerateDiadic(op_mov, 0, ap3, ap1);
		ap2 = GenerateExpression(node->p[1], am_reg | am_imm, size);
		GenerateTriadic(op, 0, ap1, ap1, ap2);
		GenerateBitfieldInsert(ap3, ap1, ap1->offset->bit_offset, ap1->offset->bit_width);
		GenStore(ap3, ap1->next, ssize);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1->next);
		ReleaseTempReg(ap1);
		ap3->MakeLegal( flags, size);
		return (ap3);
	}
	if (node->etype==bt_double || node->etype==bt_quad || node->etype==bt_float || node->etype==bt_triple) {
      ap1 = GenerateExpression(node->p[0],am_fpreg | am_mem,ssize);
      ap2 = GenerateExpression(node->p[1],am_fpreg,size);
      op = op_fmul;
    }
    else if (node->etype==bt_vector) {
      ap1 = GenerateExpression(node->p[0],am_reg | am_mem,ssize);
      ap2 = GenerateExpression(node->p[1],am_reg,size);
			op = ap2->type==stdvector.GetIndex() ? op_vmul : op_vmuls;
    }
    else {
      ap1 = GenerateExpression(node->p[0],am_all & ~am_imm,ssize);
      ap2 = GenerateExpression(node->p[1],am_reg | am_imm,size);
    }
	if (ap1->mode==am_reg) {
	    GenerateTriadic(op,0,ap1,ap1,ap2);
			if (op == op_mulu || op == op_mul) {
				mr = &regs[ap1->preg];
				if (mr->assigned)
					mr->modified = true;
				mr->assigned = true;
				mr->isConst = ap1->isConst && ap2->isConst;
			}
	}
	else if (ap1->mode==am_fpreg) {
	    GenerateTriadic(op,ssize==4?'s':ssize==8?'d':ssize==12?'t':ssize==16 ? 'q' : 'd',ap1,ap1,ap2);
	    ReleaseTempReg(ap2);
	    ap1->MakeLegal(flags,size);
		return (ap1);
	}
	else {
		GenMemop(op, ap1, ap2, ssize);
	}
    ReleaseTempReg(ap2);
    ap1 = ap1->GenSignExtend(ssize,size,flags);
    ap1->MakeLegal(flags,size);
    return (ap1);
}

/*
 *      generate /= and %= nodes.
 */
Operand *CodeGenerator::GenerateAssignModiv(ENODE *node,int flags,int size,int op)
{
	Operand *ap1, *ap2, *ap3;
    int             siz1;
    int isFP;
		MachineReg *mr;
		bool cnst = false;
 
    siz1 = GetNaturalSize(node->p[0]);
	if (node->p[0]->IsBitfield()) {
		ap3 = GetTempRegister();
		ap1 = GenerateBitfieldDereference(node->p[0], am_reg | am_mem, size, 1);
		GenerateDiadic(op_mov, 0, ap3, ap1);
		ap2 = GenerateExpression(node->p[1], am_reg | am_imm, size);
		GenerateTriadic(op, 0, ap1, ap1, ap2);
		GenerateBitfieldInsert(ap3, ap1, ap1->offset->bit_offset, ap1->offset->bit_width);
		GenStore(ap3, ap1->next, siz1);
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1->next);
		ReleaseTempReg(ap1);
		ap3->MakeLegal( flags, size);
		return (ap3);
	}
	isFP = node->etype==bt_double || node->etype==bt_float || node->etype==bt_triple || node->etype==bt_quad;
    if (isFP) {
        if (op==op_div || op==op_divu)
           op = op_fdiv;
        ap1 = GenerateExpression(node->p[0],am_fpreg,siz1);
        ap2 = GenerateExpression(node->p[1],am_fpreg,size);
		GenerateTriadic(op,siz1==4?'s':siz1==8?'d':siz1==12?'t':siz1==16?'q':'d',ap1,ap1,ap2);
	    ReleaseTempReg(ap2);
		ap1->MakeLegal(flags,size);
	    return (ap1);
//        else if (op==op_mod || op==op_modu)
//           op = op_fdmod;
    }
    else {
        ap1 = GetTempRegister();
        ap2 = GenerateExpression(node->p[0],am_all & ~am_imm,siz1);
    }
	if (ap2->mode==am_reg && ap2->preg != ap1->preg)
		GenerateDiadic(op_mov,0,ap1,ap2);
	else if (ap2->mode==am_fpreg && ap2->preg != ap1->preg)
		GenerateDiadic(op_mov,0,ap1,ap2);
	else
        GenLoad(ap1,ap2,siz1,siz1);
    //GenerateSignExtend(ap1,siz1,2,flags);
    if (isFP)
        ap3 = GenerateExpression(node->p[1],am_fpreg,8);
		else {
			// modu doesn't support immediate mode
			ap3 = GenerateExpression(node->p[1], op==op_modu ? am_reg : am_reg | am_imm, 8);
		}
	if (op==op_fdiv) {
		GenerateTriadic(op,siz1==4?'s':siz1==8?'d':siz1==12?'t':siz1==16?'q':'d',ap1,ap1,ap3);
	}
	else {
		GenerateTriadic(op, 0, ap1, ap1, ap3);
		cnst = ap1->isConst && ap3->isConst;
		mr = &regs[ap1->preg];
		if (mr->assigned)
			mr->modified = true;
		mr->assigned = true;
		mr->isConst = cnst;
	}
  ReleaseTempReg(ap3);
  //GenerateDiadic(op_ext,0,ap1,0);
	if (ap2->mode == am_reg) {
		GenerateDiadic(op_mov, 0, ap2, ap1);
		mr = &regs[ap2->preg];
		if (mr->assigned)
			mr->modified = true;
		mr->assigned = true;
		mr->isConst = cnst;
	}
	else if (ap2->mode==am_fpreg)
		GenerateDiadic(op_mov,0,ap2,ap1);
	else
	    GenStore(ap1,ap2,siz1);
    ReleaseTempReg(ap2);
	if (!isFP)
		ap1->MakeLegal(flags,size);
    return (ap1);
}

// This little bit of code a debugging aid.
// Dumps the expression nodes associated with an aggregate assignment.

void DumpStructEnodes(ENODE *node)
{
	ENODE *head;
	TYP *tp;

	lfs.printf("{");
	head = node;
	while (head) {
		tp = head->tp;
		if (tp)
			tp->put_ty();
		if (head->nodetype==en_aggregate) {
			DumpStructEnodes(head->p[0]);
		}
		if (head->nodetype==en_icon)
			lfs.printf("%d", head->i);
		head = head->p[2];
	}
	lfs.printf("}");
}


// Generate an assignment to a structure type. The type passed must be a
// structure type.

void CodeGenerator::GenerateStructAssign(TYP *tp, int64_t offset, ENODE *ep, Operand *base)
{
	SYM *thead, *first;
	Operand *ap1, *ap2;
	int64_t offset2;
	ENODE *node;

	first = thead = SYM::GetPtr(tp->lst.GetHead());
	ep = ep->p[0];
	while (thead) {
		if (ep == nullptr)
			break;
		if (thead->tp->IsAggregateType()) {
			/*
			if (thead->tp->isArray) {
				if (ep->p[2])
					GenerateArrayAssign(thead->tp, offset, ep->p[2], base);
				else if (ep->p[0])
					GenerateArrayAssign(thead->tp, offset, ep->p[0], base);
			}
			else
			*/
			{
				if (ep->p[2])
					GenerateStructAssign(thead->tp, offset, ep->p[2], base);
				else if (ep->p[0])
					GenerateStructAssign(thead->tp, offset, ep->p[0], base);
			}
/*
			else {
				ap1 = GenerateExpression(ep, am_reg, thead->tp->size);
				if (ap1->mode == am_imm) {
					ap2 = GetTempRegister();
					GenLdi(ap2, ap1);
				}
				else {
					ap2 = ap1;
					ap1 = nullptr;
				}
				if (base->offset)
					offset2 = base->offset->i + offset;
				else
					offset2 = offset;
				switch (thead->tp->size)
				{
				case 1:	GenerateDiadic(op_sb, 0, ap2, MakeIndexed(offset, base->preg)); break;
				case 2:	GenerateDiadic(op_sc, 0, ap2, MakeIndexed(offset, base->preg)); break;
				case 4:	GenerateDiadic(op_sh, 0, ap2, MakeIndexed(offset, base->preg)); break;
				case 512:	GenerateDiadic(op_sv, 0, ap2, MakeIndexed(offset, base->preg)); break;
				default:	GenerateDiadic(op_sw, 0, ap2, MakeIndexed(offset, base->preg)); break;
				}
				if (ap2)
					ReleaseTempReg(ap2);
				if (ap1)
					ReleaseTempReg(ap1);
			}
*/
		}
		else {
			ap2 = nullptr;
			if (ep->p[2]==nullptr)
				break;
			ap1 = GenerateExpression(ep->p[2],am_reg,thead->tp->size);
			if (ap1->mode==am_imm) {
				ap2 = GetTempRegister();
				GenLoadConst(ap2, ap1);
			}
			else {
				ap2 = ap1;
				ap1 = nullptr;
			}
			if (base->offset)
				offset2 = base->offset->i + offset;
			else
				offset2 = offset;
			switch(thead->tp->size)
			{
			case 1:	GenerateDiadic(op_sb,0,ap2,MakeIndexed(offset,base->preg)); break;
			case 2:	GenerateDiadic(op_sc,0,ap2,MakeIndexed(offset,base->preg)); break;
			case 4:	GenerateDiadic(op_sh,0,ap2,MakeIndexed(offset,base->preg)); break;
			case 512:	GenerateDiadic(op_sv,0,ap2,MakeIndexed(offset,base->preg)); break;
			default:	GenerateDiadic(op_sw,0,ap2,MakeIndexed(offset,base->preg)); break;
			}
			if (ap2)
				ReleaseTempReg(ap2);
			if (ap1)
				ReleaseTempReg(ap1);
		}
		if (!thead->tp->IsUnion())
			offset += thead->tp->size;
		thead = SYM::GetPtr(thead->next);
		ep = ep->p[2];
	}
	if (!thead && ep)
		error(ERR_TOOMANYELEMENTS);
}



// Generate an assignment to an array.
void CodeGenerator::GenLoadConst(Operand *ap1, Operand *ap2)
{
	Operand *ap3;

	if (ap1->isPtr) {
		ap3 = ap1->Clone();
		ap3->mode = am_direct;
		GenerateDiadic(op_lea, 0, ap2, ap3);
	}
	else
		GenerateDiadic(op_ldi, 0, ap2, ap1);
}

void CodeGenerator::GenerateArrayAssign(TYP *tp, ENODE *node1, ENODE *node2, Operand *base)
{
	ENODE *ep1;
	Operand *ap1, *ap2;
	int size = tp->size;
	int64_t offset, offset2;

	offset = 0;
	if (node1->tp)
		tp = node1->tp->GetBtp();
	else
		tp = nullptr;
	if (tp==nullptr)
		tp = &stdlong;
	if (tp->IsStructType()) {
		ep1 = nullptr;
		ep1 = node2->p[0];
		while (ep1 && offset < size) {
			GenerateStructAssign(tp, offset, ep1->p[2], base);
			if (!tp->IsUnion())
				offset += tp->size;
			ep1 = ep1->p[2];
		}
	}
	else if (tp->IsAggregateType()){
		GenerateAggregateAssign(node1->p[0],node2->p[0]);
	}
	else {
		ep1 = node2->p[0];
		offset = 0;
		if (base->offset)
			offset = base->offset->i;
		ep1 = ep1->p[2];
		while (ep1) {
			ap1 = GenerateExpression(ep1,am_reg|am_imm,sizeOfWord);
			ap2 = GetTempRegister();
			if (ap1->mode == am_imm)
				GenLoadConst(ap1, ap2);
			else {
				if (ap1->offset)
					offset2 = ap1->offset->i;
				else
					offset2 = 0;
				GenerateDiadic(op_mov,0,ap2,ap1);
			}
			switch(tp->GetElementSize())
			{
			case 1:	GenerateDiadic(op_sb,0,ap2,MakeIndexed(offset,base->preg)); break;
			case 2:	GenerateDiadic(op_sc,0,ap2,MakeIndexed(offset,base->preg)); break;
			case 4:	GenerateDiadic(op_sh,0,ap2,MakeIndexed(offset,base->preg)); break;
			case 512:	GenerateDiadic(op_sv,0,ap2,MakeIndexed(offset,base->preg)); break;
			default:	GenerateDiadic(op_sw,0,ap2,MakeIndexed(offset,base->preg)); break;
			}
			offset += tp->GetElementSize();
			ReleaseTempReg(ap2);
			ReleaseTempReg(ap1);
			ep1 = ep1->p[2];
		}
	}
}

Operand *CodeGenerator::GenerateAggregateAssign(ENODE *node1, ENODE *node2)
{
	Operand *base, *base2;
	TYP *tp;
	int64_t offset = 0;

	if (node1==nullptr || node2==nullptr)
		return nullptr;
	//DumpStructEnodes(node2);
	base = GenerateExpression(node1,am_reg,sizeOfWord);
	base2 = GenerateExpression(node2, am_reg, sizeOfWord);
	GenerateDiadic(op_mov, 0, makereg(regFirstArg), base);
	GenerateDiadic(op_mov, 0, makereg(regFirstArg+1), base2);
	GenerateDiadic(op_ldi, 0, makereg(regFirstArg+2), MakeImmediate(node2->esize));
//	GenerateDiadic(op_ldi, 0, makereg(regFirstArg + 2), MakeImmediate(node1->esize));
	GenerateMonadic(op_call, 0, MakeStringAsNameConst("__aacpy"));
	ReleaseTempReg(base2);
	return (base);
	//base = GenerateDereference(node1,am_mem,sizeOfWord,0);
	tp = node1->tp;
	if (tp==nullptr)
		tp = &stdlong;
	if (tp->IsStructType()) {
		if (base->offset)
			offset = base->offset->i;
		else
			offset = 0;
		GenerateStructAssign(tp,offset,node2->p[0],base);
		//GenerateStructAssign(tp,offset2,node2->p[0]->p[0],base);
	}
	// Process Array
	else {
		GenerateArrayAssign(tp, node1, node2, base);
	}
	return base;
}


// ----------------------------------------------------------------------------
// Generate code for an assignment node. If the size of the assignment
// destination is larger than the size passed then everything below this node
// will be evaluated with the assignment size.
// ----------------------------------------------------------------------------
Operand *CodeGenerator::GenerateAssign(ENODE *node, int flags, int size)
{
	Operand *ap1, *ap2 ,*ap3, *ap4, *ap5;
	TYP *tp;
    int ssize;
		MachineReg *mr;
		int flg;

    Enter("GenAssign");

    if (node->p[0]->IsBitfield()) {
      Leave("GenAssign",0);
		return GenerateBitfieldAssign(node, flags, size);
    }

	ssize = node->p[0]->GetReferenceSize();
//	if( ssize > size )
//			size = ssize;
/*
    if (node->tp->type==bt_struct || node->tp->type==bt_union) {
		ap1 = GenerateExpression(node->p[0],am_reg,ssize);
		ap2 = GenerateExpression(node->p[1],am_reg,size);
		GenerateMonadic(op_push,0,MakeImmediate(node->tp->size));
		GenerateMonadic(op_push,0,ap2);
		GenerateMonadic(op_push,0,ap1);
		GenerateMonadic(op_bsr,0,MakeStringAsNameConst("memcpy_"));
		GenerateTriadic(op_addui,0,makereg(regSP),makereg(regSP),MakeImmediate(24));
		ReleaseTempReg(ap2);
		return ap1;
    }
*/
	tp = node->p[0]->tp;
	if (tp) {
		if (node->p[0]->tp->IsAggregateType() || node->p[1]->nodetype==en_list || node->p[1]->nodetype==en_aggregate)
			return GenerateAggregateAssign(node->p[0],node->p[1]);
	}
	//if (size > 8) {
	//	ap1 = GenerateExpression(node->p[0],am_mem,ssize);
	//	ap2 = GenerateExpression(node->p[1],am_mem,size);
	//}
	//else {
		ap1 = GenerateExpression(node->p[0], am_reg | am_fpreg | am_mem | am_vreg | am_vmreg, ssize);
		flg = am_all;
		if (ap1->type == stddouble.GetIndex())
			flg = am_fpreg;
		ap2 = GenerateExpression(node->p[1],flg,size);
		if (node->p[0]->isUnsigned && !node->p[1]->isUnsigned)
		    ap2->GenZeroExtend(size,ssize);
//	}
	if (ap1->mode == am_reg || ap1->mode==am_fpreg) {
		mr = &regs[ap1->preg];
		if (mr->assigned)
			mr->modified = true;
		mr->assigned = true;
		switch(ap2->mode) {
		case am_reg:
			GenerateHint(2);
			if (node->p[0]->IsRefType() && node->p[1]->IsRefType()) {
				ap3 = GetTempRegister();
				GenLoad(ap3, MakeIndirect(ap2->preg),ssize,node->p[1]->GetReferenceSize());
				GenStore(ap3, MakeIndirect(ap1->preg),ssize);
				ReleaseTempRegister(ap3);
			}
			else if (node->p[1]->IsRefType()) {
				ap3 = GetTempRegister();
				GenLoad(ap3, MakeIndirect(ap2->preg), ssize, node->p[1]->GetReferenceSize());
				GenerateDiadic(op_mov, 0, ap1, ap3);
				ReleaseTempRegister(ap3);
				GenerateZeradic(op_setwb);
				ap1->isPtr = TRUE;
			}
			else if (node->p[0]->IsRefType()) {
				GenStore(ap2, MakeIndirect(ap1->preg), ssize);
			}
			else
				GenerateDiadic(op_mov, 0, ap1, ap2);
			mr->val = regs[ap2->preg].val;
			mr->isConst = ap2->isConst;
			break;
		case am_fpreg:
			GenerateHint(2);
			if (ap1->mode==am_fpreg)
				GenerateDiadic(op_fmov,0,ap1,ap2);
			else
				GenerateDiadic(op_mov,0,ap1,ap2);
			mr->modified = true;
			break;
		case am_imm:
			//if (ap2->isPtr)
			//	GenerateZeradic(op_setwb);
			GenLoadConst(ap2, ap1);
			//GenerateDiadic(op_ldi,0,ap1,ap2);
			ap1->isPtr = ap2->isPtr;
			mr->val = ap2->offset->i;
			mr->offset = ap2->offset;
			mr->isConst = true;
			break;
		default:
			GenLoad(ap1,ap2,ssize, node->p[1]->GetReferenceSize());
			ap1->isPtr = ap2->isPtr;
			mr->modified = true;
			break;
		}
	}
	else if (ap1->mode == am_vreg) {
		if (ap2->mode==am_vreg) {
			GenerateDiadic(op_mov,0,ap1,ap2);
		}
		else
			GenLoad(ap1,ap2,ssize,size);
	}
	// ap1 is memory
	else {
		if (ap2->mode == am_reg || ap2->mode == am_fpreg) {
		    GenStore(ap2,ap1,ssize);
        }
		else if (ap2->mode == am_imm) {
            if (ap2->offset->i == 0 && ap2->offset->nodetype != en_labcon) {
                GenStore(makereg(0),ap1,ssize);
            }
            else {
    			ap3 = GetTempRegister();
				//GenerateDiadic(op_ldi,0,ap3,ap2);
				GenLoadConst(ap2, ap3);
				GenStore(ap3,ap1,ssize);
		    	ReleaseTempReg(ap3);
          }
		}
		else {
			if (ap1->type==stddouble.GetIndex() || ap1->type==stdflt.GetIndex()
				|| ap1->type==stdtriple.GetIndex() || ap1->type==stdquad.GetIndex())
				ap3 = GetTempFPRegister();
			else
				ap3 = GetTempRegister();
			// Generate a memory to memory move (struct assignments)
			if (ssize > 8) {
				if (ap1->type==stdvector.GetIndex() && ap2->type==stdvector.GetIndex()) {
					if (ap2->mode==am_reg)
						GenStore(ap2,ap1,ssize);
					else {
						ap3 = GetTempVectorRegister();
						GenLoad(ap3,ap2,ssize,ssize);
						GenStore(ap3,ap1,ssize);
						ReleaseTempRegister(ap3);
					}
				}
				else {
					if (!cpu.SupportsPush) {
						GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),MakeImmediate(3 * sizeOfWord));
						ap3 = GetTempRegister();
						GenerateDiadic(op_ldi,0,ap3,MakeImmediate(size));
						GenerateDiadic(op_sw,0,ap3,MakeIndexed(2 * sizeOfWord,regSP));
						GenerateDiadic(op_mov,0,ap3,ap2);
						GenerateDiadic(op_sw,0,ap3,MakeIndexed(1 * sizeOfWord,regSP));
						GenerateDiadic(op_mov,0,ap3,ap1);
						GenerateDiadic(op_sw,0,ap3,MakeIndirect(regSP));
					}
					else {
						GenerateMonadic(op_push,0,MakeImmediate(size));
						GenerateMonadic(op_push,0,ap2);
						GenerateMonadic(op_push,0,ap1);
					}
					GenerateDiadic(op_jal,0,makereg(regLR),MakeStringAsNameConst("_aacpy"));
				}
			}
			else {
				ap3->isPtr = ap2->isPtr;
        GenLoad(ap3,ap2, node->p[0]->GetReferenceSize(),node->p[1]->GetReferenceSize());
/*                
				if (ap1->isUnsigned) {
					switch(size) {
					case 1:	GenerateDiadic(op_lbu,0,ap3,ap2); break;
					case 2:	GenerateDiadic(op_lcu,0,ap3,ap2); break;
					case 4: GenerateDiadic(op_lhu,0,ap3,ap2); break;
					case 8:	GenerateDiadic(op_lw,0,ap3,ap2); break;
					}
				}
				else {
					switch(size) {
					case 1:	GenerateDiadic(op_lb,0,ap3,ap2); break;
					case 2:	GenerateDiadic(op_lc,0,ap3,ap2); break;
					case 4: GenerateDiadic(op_lh,0,ap3,ap2); break;
					case 8:	GenerateDiadic(op_lw,0,ap3,ap2); break;
					}
					if (ssize > size) {
						switch(size) {
						case 1:	GenerateDiadic(op_sxb,0,ap3,ap3); break;
						case 2:	GenerateDiadic(op_sxc,0,ap3,ap3); break;
						case 4: GenerateDiadic(op_sxh,0,ap3,ap3); break;
						}
					}
				}
*/
				GenStore(ap3,ap1,ssize);
				ReleaseTempRegister(ap3);
			}
		}
	}
/*
	if (ap1->mode == am_reg) {
		if (ap2->mode==am_imm)	// must be zero
			GenerateDiadic(op_mov,0,ap1,makereg(0));
		else
			GenerateDiadic(op_mov,0,ap1,ap2);
	}
	else {
		if (ap2->mode==am_imm)
		switch(size) {
		case 1:	GenerateDiadic(op_sb,0,makereg(0),ap1); break;
		case 2:	GenerateDiadic(op_sc,0,makereg(0),ap1); break;
		case 4: GenerateDiadic(op_sh,0,makereg(0),ap1); break;
		case 8:	GenerateDiadic(op_sw,0,makereg(0),ap1); break;
		}
		else
		switch(size) {
		case 1:	GenerateDiadic(op_sb,0,ap2,ap1); break;
		case 2:	GenerateDiadic(op_sc,0,ap2,ap1); break;
		case 4: GenerateDiadic(op_sh,0,ap2,ap1); break;
		case 8:	GenerateDiadic(op_sw,0,ap2,ap1); break;
		// Do structure assignment
		default: {
			ap3 = GetTempRegister();
			GenerateDiadic(op_ldi,0,ap3,MakeImmediate(size));
			GenerateTriadic(op_push,0,ap3,ap2,ap1);
			GenerateDiadic(op_jal,0,makereg(LR),MakeStringAsNameConst("memcpy"));
			GenerateTriadic(op_addui,0,makereg(SP),makereg(SP),MakeImmediate(24));
			ReleaseTempRegister(ap3);
		}
		}
	}
*/
	ReleaseTempReg(ap2);
    ap1->MakeLegal(flags,size);
    Leave("GenAssign",1);
	return ap1;
}

// autocon and autofcon nodes

Operand *CodeGenerator::GenAutocon(ENODE *node, int flags, int size, int type)
{
	Operand *ap1, *ap2;

	// We always want an address register (GPR) for lea
	ap1 = GetTempRegister();
	ap2 = allocOperand();
	ap2->isPtr = node->etype == bt_pointer;
	ap2->mode = am_indx;
	ap2->preg = regFP;          // frame pointer
	ap2->offset = node;     /* use as constant node */
	ap2->type = type;
	ap1->type = stdint.GetIndex();
	GenerateDiadic(op_lea,0,ap1,ap2);
	ap1->MakeLegal(flags,size);
	return (ap1);             /* return reg */
}

//
// General expression evaluation. returns the addressing mode
// of the result.
//
Operand *CodeGenerator::GenerateExpression(ENODE *node, int flags, int size)
{   
	Operand *ap1, *ap2, *ap3;
  int natsize, siz1;
	int lab0, lab1;
	static char buf[4][20];
	static int ndx;
	static int numDiags = 0;

  Enter("<GenerateExpression>"); 
  if( node == (ENODE *)NULL )
  {
		throw new C64PException(ERR_NULLPOINTER, 'G');
		numDiags++;
        printf("DIAG - null node in GenerateExpression.\n");
		if (numDiags > 100)
			exit(0);
        Leave("</GenerateExpression>",2); 
        return (Operand *)NULL;
    }
	//size = node->esize;
  switch( node->nodetype )
  {
	case en_aggregate:
		ap1 = GenerateExpression(node->p[0], flags, size);
		ap2 = allocOperand();
		ap2->mode = am_ind;
		ap2->preg = ap1->preg;
		if (node->tp->IsScalar())
			GenLoad(ap1, ap2, size, size);
		else
			ap1->isPtr = true;
		goto retpt;
		//ap1 = allocOperand();
		//ap1->offset = node;
		//ap1->type = 9999;
		goto retpt;
	case en_fcon:
    ap1 = allocOperand();
		ap1->isPtr = node->IsPtr();
		ap1->mode = am_direct;
    ap1->offset = node;
		if (node)
			DataLabels[node->i] = true;
		ap1->type = stddouble.GetIndex();
		// Don't allow the constant to be loaded into an integer register.
    ap1->MakeLegal(flags & ~am_reg,size);
    Leave("</GenerateExpression>",2); 
		goto retpt;
		/*
            ap1 = allocOperand();
            ap1->mode = am_imm;
            ap1->offset = node;
			ap1->isFloat = TRUE;
            ap1->MakeLegal(flags,size);
         Leave("GenExperssion",2); 
            return ap1;
		*/
  case en_icon:
      ap1 = allocOperand();
      ap1->mode = am_imm;
      ap1->offset = node;
      ap1->MakeLegal(flags,size);
      Leave("GenExpression",3); 
			goto retpt;

	case en_labcon:
    if (use_gp) {
      ap1 = GetTempRegister();
    ap2 = allocOperand();
    ap2->mode = am_indx;
		switch (node->segment) {
		case tlsseg:	ap2->preg = regTP; break;
		case dataseg:	ap2->preg = regGP; break;
		default:	ap2->preg = regPP;
		}
                ap2->offset = node;     // use as constant node
                GenerateDiadic(op_lea,0,ap1,ap2);
				ap1->MakeLegal(flags,size);
         Leave("GenExperssion",4); 
				 goto retpt;
            }
            ap1 = allocOperand();
			ap1->isPtr = node->IsPtr();
			/* this code not really necessary, see segments notes
			if (node->etype==bt_pointer && node->constflag) {
				ap1->segment = codeseg;
			}
			else {
				ap1->segment = dataseg;
			}
			*/
					ap1->mode = am_imm;
          ap1->offset = node;
					ap1->isUnsigned = node->isUnsigned;
          ap1->MakeLegal(flags,size);
					Leave("GenExperssion",5); 
					goto retpt;

    case en_nacon:
            if (use_gp) {
                ap1 = GetTempRegister();
                ap2 = allocOperand();
                ap2->mode = am_indx;
                ap2->preg = regGP;      // global pointer
                ap2->offset = node;     // use as constant node
								if (node)
									DataLabels[node->i] = true;
                GenerateDiadic(op_lea,0,ap1,ap2);
				ap1->MakeLegal(flags,size);
				Leave("GenExpression",6); 
				goto retpt;
						}
            // fallthru
	case en_cnacon:
      ap1 = allocOperand();
			ap1->isPtr = node->IsPtr();
			ap1->mode = am_imm;
      ap1->offset = node;
			if (node->i==0)
				node->i = -1;
			ap1->isUnsigned = node->isUnsigned;
            ap1->MakeLegal(flags,size);
			Leave("GenExpression",7); 
			goto retpt;
	case en_clabcon:
    ap1 = allocOperand();
    ap1->mode = am_imm;
    ap1->offset = node;
		ap1->isUnsigned = node->isUnsigned;
    ap1->MakeLegal(flags,size);
		Leave("GenExpression",7); 
		goto retpt;
	case en_autocon:
		ap1 = GenAutocon(node, flags, size, stdint.GetIndex());
		goto retpt;
  case en_autofcon:	
		switch (node->tp->type)
		{
		case bt_float:
			ap1 = GenAutocon(node, flags, size, stdflt.GetIndex());
			goto retpt;
		case bt_double:
			ap1 = GenAutocon(node, flags, size, stddouble.GetIndex());
			goto retpt;
		case bt_triple:	return GenAutocon(node, flags, size, stdtriple.GetIndex());
		case bt_quad:	return GenAutocon(node, flags, size, stdquad.GetIndex());
		case bt_pointer:
			ap1 = GenAutocon(node, flags, size, stdint.GetIndex());
			goto retpt;
		}
		break;
    case en_autovcon:	return GenAutocon(node, flags, size, stdvector.GetIndex());
    case en_autovmcon:	return GenAutocon(node, flags, size, stdvectormask->GetIndex());
    case en_classcon:
            ap1 = GetTempRegister();
            ap2 = allocOperand();
            ap2->mode = am_indx;
            ap2->preg = regCLP;     /* frame pointer */
            ap2->offset = node;     /* use as constant node */
            GenerateDiadic(op_lea,0,ap1,ap2);
			ap1->MakeLegal(flags,size);
			goto retpt;
		case en_addrof:
			ap1 = GetTempRegister();
			ap2 = GenerateExpression(node->p[0], flags & ~am_fpreg, 8);
			switch (ap2->mode) {
			case am_reg:
				GenerateDiadic(op_mov, 0, ap1, ap2);
				break;
			default:
				GenerateDiadic(op_lea, 0, ap1, ap2);
			}
			ReleaseTempReg(ap2);
			goto retpt;
  case en_ub_ref:
		ap1 = GenerateDereference(node, flags, 1, 0);
		ap1->isPtr = TRUE;
		ap1->isUnsigned = TRUE;
		goto retpt;
	case en_uc_ref:
		ap1 = GenerateDereference(node, flags, 2, 0);
		ap1->isPtr = TRUE;
		ap1->isUnsigned = TRUE;
		goto retpt;
	case en_uh_ref:
		ap1 = GenerateDereference(node, flags, 4, 0);
		ap1->isPtr = TRUE;
		ap1->isUnsigned = TRUE;
		goto retpt;
	case en_uw_ref:
		ap1 = GenerateDereference(node, flags, 8, 0);
		ap1->isPtr = TRUE;
		ap1->isUnsigned = TRUE;
		goto retpt;
	case en_hp_ref:
		ap1 = GenerateDereference(node, flags, 4, 0);
		ap1->isPtr = TRUE;
		ap1->isUnsigned = TRUE;
		goto retpt;
	case en_wp_ref:
		ap1 = GenerateDereference(node,flags,8,0);
		ap1->isPtr = TRUE;
		ap1->isUnsigned = TRUE;
		goto retpt;
	case en_vector_ref:	return GenerateDereference(node,flags,size,0);
	case en_ref32:	return GenerateDereference(node,flags,size,1);
	case en_ref32u:	return GenerateDereference(node,flags,size,0);
  case en_b_ref:
		ap1 = GenerateDereference(node, flags, 1, 1);
		ap1->isPtr = TRUE;
		ap1->isUnsigned = TRUE;
		goto retpt;
	case en_c_ref:
		ap1 = GenerateDereference(node, flags, 2, 1);
		ap1->isPtr = TRUE;
		ap1->isUnsigned = TRUE;
		goto retpt;
	case en_h_ref:
		ap1 = GenerateDereference(node, flags, 4, 1);
		ap1->isPtr = TRUE;
		ap1->isUnsigned = TRUE;
		goto retpt;
	case en_w_ref:
		ap1 = GenerateDereference(node, flags, 8, 1);
		ap1->isPtr = TRUE;
		ap1->isUnsigned = TRUE;
		goto retpt;
	case en_flt_ref:
		ap1 = GenerateDereference(node, flags, size, 1);
		ap1->type = stdflt.GetIndex();
		ap1->MakeLegal(flags, size);
		goto retpt;
	case en_dbl_ref:
		ap1 = GenerateDereference(node, flags, size, 1);
		ap1->type = stddouble.GetIndex();
		ap1->MakeLegal(flags, size);
		goto retpt;
	case en_triple_ref:
		ap1 = GenerateDereference(node, flags, size, 1);
		ap1->type = stdtriple.GetIndex();
		ap1->MakeLegal(flags, size);
		goto retpt;
	case en_quad_ref:
		ap1 = GenerateDereference(node,flags,size,1);
		ap1->type = stdquad.GetIndex();
		ap1->MakeLegal(flags, size);
		goto retpt;
	case en_ubfieldref:
	case en_ucfieldref:
	case en_uhfieldref:
	case en_uwfieldref:
			ap1 = (flags & am_bf_assign) ? GenerateDereference(node,flags & ~am_bf_assign,size,0) : GenerateBitfieldDereference(node,flags,size,0);
			ap1->isUnsigned = TRUE;
			goto retpt;
	case en_wfieldref:
	case en_bfieldref:
	case en_cfieldref:
	case en_hfieldref:
			ap1 = (flags & am_bf_assign) ? GenerateDereference(node,flags & ~am_bf_assign,size,1) : GenerateBitfieldDereference(node,flags,size,0);
			goto retpt;
	case en_regvar:
	case en_tempref:
    ap1 = allocOperand();
		ap1->isPtr = node->IsPtr();
    ap1->mode = am_reg;
    ap1->preg = node->rg;
    ap1->tempflag = 0;      /* not a temporary */
    ap1->MakeLegal(flags,size);
		goto retpt;

	case en_tempfpref:
		ap1 = allocOperand();
		ap1->isPtr = node->IsPtr();
		ap1->mode = node->IsPtr() ? am_reg : am_fpreg;
		ap1->preg = node->rg;
		ap1->tempflag = 0;      /* not a temporary */
		if (node->tp)
			switch (node->tp->type) {
			case bt_float:	ap1->type = stdflt.GetIndex(); break;
			case bt_double:	ap1->type = stddouble.GetIndex(); break;
			case bt_triple:	ap1->type = stdtriple.GetIndex(); break;
			case bt_quad:	ap1->type = stdquad.GetIndex(); break;
			default: ap1->type = stdint.GetIndex(); break;
			}
		else
			ap1->type = stddouble.GetIndex();
		ap1->MakeLegal(flags,size);
		goto retpt;

	case en_fpregvar:
//    case en_fptempref:
    ap1 = allocOperand();
		ap1->isPtr = node->IsPtr();
		ap1->mode = node->IsPtr() ? am_reg : am_fpreg;
    ap1->preg = node->rg;
    ap1->tempflag = 0;      /* not a temporary */
		if (node->tp)
			switch (node->tp->type) {
			case bt_float:	ap1->type = stdflt.GetIndex(); break;
			case bt_double:	ap1->type = stddouble.GetIndex(); break;
			case bt_triple:	ap1->type = stdtriple.GetIndex(); break;
			case bt_quad:	ap1->type = stdquad.GetIndex(); break;
			default: ap1->type = stdint.GetIndex(); break;
			}
		else
			ap1->type = stddouble.GetIndex();
		ap1->MakeLegal(flags,size);
		goto retpt;

	case en_abs:	return node->GenUnary(flags,size,op_abs);
    case en_uminus: 
			ap1 = node->GenUnary(flags, size, op_neg);
			goto retpt;
    case en_compl:
			ap1 = node->GenUnary(flags,size,op_com);
			goto retpt;
	case en_not:	
		ap1 = (node->GenUnary(flags, 8, op_not));
		goto retpt;
	case en_add:    ap1 = node->GenBinary(flags, size, op_add); goto retpt;
	case en_sub:  ap1 = node->GenBinary(flags, size, op_sub); goto retpt;
	case en_ptrdif:  ap1 = node->GenBinary(flags, size, op_ptrdif); goto retpt;
	case en_i2d:
         ap1 = GetTempFPRegister();	
         ap2=GenerateExpression(node->p[0],am_reg,8);
         GenerateDiadic(op_itof,'d',ap1,ap2);
         ReleaseTempReg(ap2);
				 goto retpt;
    case en_i2q:
         ap1 = GetTempFPRegister();	
         ap2 = GenerateExpression(node->p[0],am_reg,8);
		 GenerateTriadic(op_csrrw,0,makereg(0),MakeImmediate(0x18),ap2);
		 GenerateZeradic(op_nop);
		 GenerateZeradic(op_nop);
         GenerateDiadic(op_itof,'q',ap1,makereg(63));
         ReleaseTempReg(ap2);
				 goto retpt;
    case en_i2t:
         ap1 = GetTempFPRegister();	
         ap2 = GenerateExpression(node->p[0],am_reg,8);
		 GenerateTriadic(op_csrrw,0,makereg(0),MakeImmediate(0x18),ap2);
		 GenerateZeradic(op_nop);
		 GenerateZeradic(op_nop);
         GenerateDiadic(op_itof,'t',ap1,makereg(63));
         ReleaseTempReg(ap2);
				 goto retpt;
    case en_d2i:
         ap1 = GetTempRegister();	
         ap2 = GenerateExpression(node->p[0],am_fpreg,8);
         GenerateDiadic(op_ftoi,'d',ap1,ap2);
         ReleaseTempReg(ap2);
				 goto retpt;
    case en_q2i:
         ap1 = GetTempRegister();
         ap2 = GenerateExpression(node->p[0],am_fpreg,8);
         GenerateDiadic(op_ftoi,'q',makereg(63),ap2);
		 GenerateZeradic(op_nop);
		 GenerateZeradic(op_nop);
		 GenerateTriadic(op_csrrw,0,ap1,MakeImmediate(0x18),makereg(0));
         ReleaseTempReg(ap2);
				 goto retpt;
		case en_t2i:
         ap1 = GetTempRegister();
         ap2 = GenerateExpression(node->p[0],am_fpreg,8);
         GenerateDiadic(op_ftoi,'t',makereg(63),ap2);
		 GenerateZeradic(op_nop);
		 GenerateZeradic(op_nop);
		 GenerateTriadic(op_csrrw,0,ap1,MakeImmediate(0x18),makereg(0));
         ReleaseTempReg(ap2);
				 goto retpt;
		case en_s2q:
		ap1 = GetTempFPRegister();
        ap2 = GenerateExpression(node->p[0],am_fpreg,8);
        GenerateDiadic(op_fcvtsq,0,ap1,ap2);
		ap1->type = stdquad.GetIndex();
		ReleaseTempReg(ap2);
		goto retpt;
		case en_d2q:
		ap1 = GetTempFPRegister();
		ap2 = GenerateExpression(node->p[0], am_fpreg, 8);
		GenerateDiadic(op_fcvtdq, 0, ap1, ap2);
		ap1->type = stdquad.GetIndex();
		ReleaseTempReg(ap2);
		goto retpt;
		case en_t2q:
		ap1 = GetTempFPRegister();
		ap2 = GenerateExpression(node->p[0], am_fpreg, 8);
		GenerateDiadic(op_fcvttq, 0, ap1, ap2);
		ap1->type = stdquad.GetIndex();
		ReleaseTempReg(ap2);
		goto retpt;

	case en_vadd:	  return node->GenBinary(flags,size,op_vadd);
	case en_vsub:	  return node->GenBinary(flags,size,op_vsub);
	case en_vmul:	  return node->GenBinary(flags,size,op_vmul);
	case en_vadds:	  return node->GenBinary(flags,size,op_vadds);
	case en_vsubs:	  return node->GenBinary(flags,size,op_vsubs);
	case en_vmuls:	  return node->GenBinary(flags,size,op_vmuls);
	case en_vex:      return node->GenBinary(flags,size,op_vex);
	case en_veins:    return node->GenBinary(flags,size,op_veins);

	case en_fadd:	  ap1 = node->GenBinary(flags, size, op_fadd); goto retpt;
	case en_fsub:	  ap1 = node->GenBinary(flags, size, op_fsub); goto retpt;
	case en_fmul:	  ap1 = node->GenBinary(flags, size, op_fmul); goto retpt;
	case en_fdiv:	  ap1 = node->GenBinary(flags, size, op_fdiv); goto retpt;

	case en_fdadd:    return node->GenBinary(flags,size,op_fdadd);
    case en_fdsub:    return node->GenBinary(flags,size,op_fdsub);
    case en_fsadd:    return node->GenBinary(flags,size,op_fsadd);
    case en_fssub:    return node->GenBinary(flags,size,op_fssub);
    case en_fdmul:    return node->GenMultiply(flags,size,op_fmul);
    case en_fsmul:    return node->GenMultiply(flags,size,op_fmul);
    case en_fddiv:    return node->GenMultiply(flags,size,op_fddiv);
    case en_fsdiv:    return node->GenMultiply(flags,size,op_fsdiv);
	case en_ftadd:    return node->GenBinary(flags,size,op_ftadd);
    case en_ftsub:    return node->GenBinary(flags,size,op_ftsub);
    case en_ftmul:    return node->GenMultiply(flags,size,op_ftmul);
    case en_ftdiv:    return node->GenMultiply(flags,size,op_ftdiv);

	case en_land:
		/*
		lab0 = nextlabel++;
		lab1 = nextlabel++;
		GenerateFalseJump(node, lab0, 0);
		ap1 = GetTempRegister();
		GenerateDiadic(op_ld, 0, ap1, MakeImmediate(1));
		GenerateMonadic(op_bra, 0, MakeDataLabel(lab1));
		GenerateLabel(lab0);
		GenerateDiadic(op_ld, 0, ap1, MakeImmediate(0));
		GenerateLabel(lab1);
		return (ap1);
		*/
		ap1 = (node->GenLand(flags, op_and, false));
		goto retpt;
	case en_lor:
		ap1 = (node->GenLand(flags, op_or, false));
		goto retpt;
	case en_land_safe:
		ap1 = (node->GenLand(flags, op_and, true));
		goto retpt;
	case en_lor_safe:
		ap1 = (node->GenLand(flags, op_or, true));
		goto retpt;

	case en_isnullptr:	ap1 = node->GenUnary(flags, size, op_isnullptr); goto retpt;
	case en_and:    ap1 = node->GenBinary(flags, size, op_and); goto retpt;
    case en_or:     ap1 = node->GenBinary(flags,size,op_or); goto retpt;
	case en_xor:	ap1 = node->GenBinary(flags,size,op_xor); goto retpt;
	case en_mulf:    ap1 = node->GenMultiply(flags, size, op_mulf); goto retpt;
	case en_mul:    ap1 = node->GenMultiply(flags,size,op_mul); goto retpt;
    case en_mulu:   ap1 = node->GenMultiply(flags,size,op_mulu); goto retpt;
    case en_div:    ap1 = node->GenDivMod(flags,size,op_div); goto retpt;
    case en_udiv:   ap1 = node->GenDivMod(flags,size,op_divu); goto retpt;
    case en_mod:    ap1 = node->GenDivMod(flags,size,op_mod); goto retpt;
    case en_umod:   ap1 = node->GenDivMod(flags,size,op_modu); goto retpt;
    case en_asl:    ap1 = node->GenShift(flags,size,op_asl); goto retpt;
    case en_shl:    ap1 = node->GenShift(flags,size,op_shl); goto retpt;
    case en_shlu:   ap1 = node->GenShift(flags,size,op_shl); goto retpt;
    case en_asr:	ap1 = node->GenShift(flags,size,op_asr); goto retpt;
    case en_shr:	ap1 = node->GenShift(flags,size,op_asr); goto retpt;
    case en_shru:   ap1 = node->GenShift(flags,size,op_shru); goto retpt;
	case en_rol:   ap1 = node->GenShift(flags,size,op_rol); goto retpt;
	case en_ror:   ap1 = node->GenShift(flags,size,op_ror); goto retpt;
	/*	
	case en_asfadd: return GenerateAssignAdd(node,flags,size,op_fadd);
	case en_asfsub: return GenerateAssignAdd(node,flags,size,op_fsub);
	case en_asfmul: return GenerateAssignAdd(node,flags,size,op_fmul);
	case en_asfdiv: return GenerateAssignAdd(node,flags,size,op_fdiv);
	*/
    case en_asadd:  
			ap1 = node->GenAssignAdd(flags, size, op_add);
			goto retpt;
    case en_assub:  ap1 = node->GenAssignAdd(flags,size,op_sub); goto retpt;
    case en_asand:  ap1 = node->GenAssignLogic(flags,size,op_and); goto retpt;
    case en_asor:   ap1 = node->GenAssignLogic(flags,size,op_or); goto retpt;
	case en_asxor:  ap1 = node->GenAssignLogic(flags,size,op_xor); goto retpt;
    case en_aslsh:  ap1 = (node->GenAssignShift(flags,size,op_shl)); goto retpt;
    case en_asrsh:  ap1 = (node->GenAssignShift(flags,size,op_asr)); goto retpt;
	case en_asrshu: ap1 = (node->GenAssignShift(flags,size,op_shru)); goto retpt;
    case en_asmul: ap1 = GenerateAssignMultiply(node,flags,size,op_mul); goto retpt;
    case en_asmulu: ap1 = GenerateAssignMultiply(node,flags,size,op_mulu); goto retpt;
    case en_asdiv: ap1 = GenerateAssignModiv(node,flags,size,op_div); goto retpt;
    case en_asdivu: ap1 = GenerateAssignModiv(node,flags,size,op_divu); goto retpt;
    case en_asmod: ap1 = GenerateAssignModiv(node,flags,size,op_mod); goto retpt;
    case en_asmodu: ap1 = GenerateAssignModiv(node,flags,size,op_modu); goto retpt;
    case en_assign:
			ap1 = GenerateAssign(node, flags, size);
			goto retpt;

	case en_chk:
        return (GenExpr(node));
         
    case en_eq:     case en_ne:
    case en_lt:     case en_le:
    case en_gt:     case en_ge:
    case en_ult:    case en_ule:
    case en_ugt:    case en_uge:
    case en_feq:    case en_fne:
    case en_flt:    case en_fle:
    case en_fgt:    case en_fge:
    case en_veq:    case en_vne:
    case en_vlt:    case en_vle:
    case en_vgt:    case en_vge:
			ap1 = GenExpr(node);
			ap1->isBool = true;
			goto retpt;

	case en_cond:
		ap1 = node->GenHook(flags, size);
		goto retpt;
	case en_safe_cond:
		ap1 = (node->GenSafeHook(flags, size));
		goto retpt;
	case en_void:
    natsize = GetNaturalSize(node->p[0]);
		ap1 = GenerateExpression(node->p[0], am_all | am_novalue, natsize);
		ReleaseTempRegister(GenerateExpression(node->p[1], flags, size));
		ap1->isPtr = node->IsPtr();
		goto retpt;

  case en_fcall:
		ap1 = (GenerateFunctionCall(node,flags));
		goto retpt;

	case en_sxb:
		ap1 = GetTempRegister();
		ap2 = GenerateExpression(node->p[0], am_reg, 1);
		GenerateDiadic(op_sxb, 0, ap1, ap2);
		ReleaseTempReg(ap2);
		ap1->MakeLegal( flags, 8);
		goto retpt;
	case en_sxc:
		ap1 = GetTempRegister();
		ap2 = GenerateExpression(node->p[0], am_reg, 2);
		GenerateDiadic(op_sxc, 0, ap1, ap2);
		ReleaseTempReg(ap2);
		ap1->MakeLegal(flags, 8);
		goto retpt;
	case en_sxh:
		ap1 = GetTempRegister();
		ap2 = GenerateExpression(node->p[0], am_reg, 4);
		GenerateDiadic(op_sxh, 0, ap1, ap2);
		ReleaseTempReg(ap2);
		ap1->MakeLegal(flags, 8);
		goto retpt;
	case en_cubw:
	case en_cubu:
	case en_cbu:
			ap1 = GenerateExpression(node->p[0],am_reg,1);
			GenerateTriadic(op_and,0,ap1,ap1,MakeImmediate(0xff));
			goto retpt;
	case en_cucw:
	case en_cucu:
	case en_ccu:
			ap1 = GenerateExpression(node->p[0],am_reg,2);
			GenerateDiadic(op_zxc,0,ap1,ap1);
			goto retpt;
	case en_ccwp:
		ap1 = GenerateExpression(node->p[0], am_reg, 2);
		ap1->isPtr = TRUE;
		GenerateDiadic(op_sxc, 0, ap1, ap1);
		goto retpt;
	case en_cucwp:
		ap1 = GenerateExpression(node->p[0], am_reg, 2);
		ap1->isPtr = TRUE;
		GenerateDiadic(op_zxc, 0, ap1, ap1);
		goto retpt;
	case en_cuhw:
	case en_cuhu:
	case en_chu:
			ap1 = GenerateExpression(node->p[0],am_reg,4);
			GenerateDiadic(op_zxh,0,ap1,ap1);
			goto retpt;
	case en_cbw:
			ap1 = GenerateExpression(node->p[0],am_reg,1);
			//GenerateDiadic(op_sxb,0,ap1,ap1);
			GenerateDiadic(op_sxb,0,ap1,ap1);
			goto retpt;
	case en_ccw:
			ap1 = GenerateExpression(node->p[0],am_reg,2);
			GenerateDiadic(op_sxc,0,ap1,ap1);
			goto retpt;
	case en_chw:
			ap1 = GenerateExpression(node->p[0],am_reg,4);
			GenerateDiadic(op_sxh,0,ap1,ap1);
			goto retpt;
	case en_list:
		ap1 = GetTempRegister();
		GenerateDiadic(op_lea, 0, ap1, MakeDataLabel(node->i));
		ap1->isPtr = true;
		goto retpt;
	case en_object_list:
			ap1 = GetTempRegister();
			GenerateDiadic(op_lea,0,ap1,MakeIndexed(-8,regFP));
			ap1->MakeLegal(flags,sizeOfWord);
			goto retpt;
	default:
    printf("DIAG - uncoded node (%d) in GenerateExpression.\n", node->nodetype);
    return 0;
  }
	return(0);
retpt:
	if (node->pfl) {
		ReleaseTempRegister(cg.GenerateExpression(node->pfl, flags, size));
	}
	return (ap1);
}

//
// Generate a jump to label if the node passed evaluates to
// a true condition.
//
void CodeGenerator::GenerateTrueJump(ENODE *node, int label, unsigned int prediction)
{ 
	Operand  *ap1, *ap2, *ap3;
	int lab0;
	int siz1;

	if( node == 0 )
		return;
	switch( node->nodetype )
	{
	case en_bchk:	break;
	case en_eq:	GenerateBranch(node, op_eq, label, 0, prediction, false); break;
	case en_ne: GenerateBranch(node, op_ne, label, 0, prediction, false); break;
	case en_lt: GenerateBranch(node, op_lt, label, 0, prediction, false); break;
	case en_le:	GenerateBranch(node, op_le, label, 0, prediction, false); break;
	case en_gt: GenerateBranch(node, op_gt, label, 0, prediction, false); break;
	case en_ge: GenerateBranch(node, op_ge, label, 0, prediction, false); break;
	case en_ult: GenerateBranch(node, op_ltu, label, 0, prediction, false); break;
	case en_ule: GenerateBranch(node, op_leu, label, 0, prediction, false); break;
	case en_ugt: GenerateBranch(node, op_gtu, label, 0, prediction, false); break;
	case en_uge: GenerateBranch(node, op_geu, label, 0, prediction, false); break;
	case en_feq: GenerateBranch(node, op_feq, label, 0, prediction, false); break;
	case en_fne: GenerateBranch(node, op_fne, label, 0, prediction, false); break;
	case en_flt: GenerateBranch(node, op_flt, label, 0, prediction, false); break;
	case en_fle: GenerateBranch(node, op_fle, label, 0, prediction, false); break;
	case en_fgt: GenerateBranch(node, op_fgt, label, 0, prediction, false); break;
	case en_fge: GenerateBranch(node, op_fge, label, 0, prediction, false); break;
	case en_veq: GenerateBranch(node, op_vseq, label, 0, prediction, false); break;
	case en_vne: GenerateBranch(node, op_vsne, label, 0, prediction, false); break;
	case en_vlt: GenerateBranch(node, op_vslt, label, 0, prediction, false); break;
	case en_vle: GenerateBranch(node, op_vsle, label, 0, prediction, false); break;
	case en_vgt: GenerateBranch(node, op_vsgt, label, 0, prediction, false); break;
	case en_vge: GenerateBranch(node, op_vsge, label, 0, prediction, false); break;
	case en_lor_safe:
		if (GenerateBranch(node, op_or, label, 0, prediction, true))
			break;
	case en_lor:
		GenerateTrueJump(node->p[0], label, prediction);
		GenerateTrueJump(node->p[1], label, prediction);
		break;
	case en_land_safe:
		if (GenerateBranch(node, op_and, label, 0, prediction, true))
			break;
	case en_land:
		lab0 = nextlabel++;
		GenerateFalseJump(node->p[0], lab0, prediction);
		GenerateTrueJump(node->p[1], label, prediction ^ 1);
		GenerateLabel(lab0);
		break;
	default:
		siz1 = GetNaturalSize(node);
		ap1 = GenerateExpression(node,am_reg|am_fpreg,siz1);
		//                        GenerateDiadic(op_tst,siz1,ap1,0);
		ReleaseTempRegister(ap1);
		if (ap1->mode == am_fpreg)
			GenerateTriadic(op_fbne, 0, ap1, makefpreg(0), MakeDataLabel(label));
		else
			GenerateTriadic(op_bne,0,ap1,makereg(0),MakeDataLabel(label));
		break;
	}
}

//
// Generate code to execute a jump to label if the expression
// passed is false.
//
void CodeGenerator::GenerateFalseJump(ENODE *node,int label, unsigned int prediction)
{
	Operand *ap, *ap1, *ap2, *ap3;
	int siz1;
	int lab0;

	if( node == (ENODE *)NULL )
		return;
	switch( node->nodetype )
	{
	case en_bchk:	break;
	case en_eq:	GenerateBranch(node, op_ne, label, 0, prediction, false); break;
	case en_ne: GenerateBranch(node, op_eq, label, 0, prediction, false); break;
	case en_lt: GenerateBranch(node, op_ge, label, 0, prediction, false); break;
	case en_le: GenerateBranch(node, op_gt, label, 0, prediction, false); break;
	case en_gt: GenerateBranch(node, op_le, label, 0, prediction, false); break;
	case en_ge: GenerateBranch(node, op_lt, label, 0, prediction, false); break;
	case en_ult: GenerateBranch(node, op_geu, label, 0, prediction, false); break;
	case en_ule: GenerateBranch(node, op_gtu, label, 0, prediction, false); break;
	case en_ugt: GenerateBranch(node, op_leu, label, 0, prediction, false); break;
	case en_uge: GenerateBranch(node, op_ltu, label, 0, prediction, false); break;
	case en_feq: GenerateBranch(node, op_fne, label, 0, prediction, false); break;
	case en_fne: GenerateBranch(node, op_feq, label, 0, prediction, false); break;
	case en_flt: GenerateBranch(node, op_fge, label, 0, prediction, false); break;
	case en_fle: GenerateBranch(node, op_fgt, label, 0, prediction, false); break;
	case en_fgt: GenerateBranch(node, op_fle, label, 0, prediction, false); break;
	case en_fge: GenerateBranch(node, op_flt, label, 0, prediction, false); break;
	case en_veq: GenerateBranch(node, op_vsne, label, 0, prediction, false); break;
	case en_vne: GenerateBranch(node, op_vseq, label, 0, prediction, false); break;
	case en_vlt: GenerateBranch(node, op_vsge, label, 0, prediction, false); break;
	case en_vle: GenerateBranch(node, op_vsgt, label, 0, prediction, false); break;
	case en_vgt: GenerateBranch(node, op_vsle, label, 0, prediction, false); break;
	case en_vge: GenerateBranch(node, op_vslt, label, 0, prediction, false); break;
	case en_land_safe:
		if (GenerateBranch(node, op_nand, label, 0, prediction, true))
			break;
	case en_land:
		GenerateFalseJump(node->p[0],label,prediction^1);
		GenerateFalseJump(node->p[1],label,prediction^1);
		break;
	case en_lor_safe:
		if (GenerateBranch(node, op_nor, label, 0, prediction,true))
			break;
	case en_lor:
		lab0 = nextlabel++;
		GenerateTrueJump(node->p[0],lab0,prediction);
		GenerateFalseJump(node->p[1],label,prediction^1);
		GenerateLabel(lab0);
		break;
	case en_not:
		GenerateTrueJump(node->p[0],label,prediction);
		break;
	default:
		siz1 = GetNaturalSize(node);
		ap = GenerateExpression(node,am_reg|am_fpreg,siz1);
		//                        GenerateDiadic(op_tst,siz1,ap,0);
		ReleaseTempRegister(ap);
		if (ap->mode==am_fpreg)
			GenerateTriadic(op_fbeq, 0, ap, makefpreg(0), MakeDataLabel(label));
		else
			GenerateTriadic(op_beq,0,ap,makereg(0),MakeDataLabel(label));
		break;
	}
}

void CodeGenerator::SaveTemporaries(Function *sym, int *sp, int *fsp)
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

void CodeGenerator::RestoreTemporaries(Function *sym, int sp, int fsp)
{
	if (sym) {
		if (sym->UsesTemps) {
			//TempFPRevalidate(fsp);
			TempRevalidate(sp, fsp);
		}
	}
	else {
		//TempFPRevalidate(fsp);
		TempRevalidate(sp, fsp);
	}
}


// Store entire argument list onto stack
//
int CodeGenerator::GenerateInlineArgumentList(Function *sym, ENODE *plist)
{
	Operand *ap;
	TypeArray *ta = nullptr;
	int i, sum;
	OCODE *ip;
	ENODE *p;
	ENODE *pl[100];
	int nn, maxnn;
	struct slit *st;
	char *cp;

	sum = 0;
	if (sym)
		ta = sym->GetProtoTypes();

	// Capture the parameter list. It is needed in the reverse order.
	for (nn = 0, p = plist; p != NULL; p = p->p[1], nn++) {
		pl[nn] = p->p[0];
	}
	maxnn = nn;
	for (--nn, i = 0; nn >= 0; --nn, i++)
	{
		if (pl[nn]->etype == bt_pointer) {
			if (pl[nn]->tp->GetBtp()->type == bt_ichar || pl[nn]->tp->GetBtp()->type == bt_iuchar) {
				for (st = strtab; st; st = st->next) {
					if (st->label == pl[nn]->i) {
						cp = st->str;
						break;
					}
				}
				ap = MakeString(cp);
				GenerateMonadic(op_string, 0, ap);
			}
		}
	}
	if (ta)
		delete ta;
	return (sum);
}
