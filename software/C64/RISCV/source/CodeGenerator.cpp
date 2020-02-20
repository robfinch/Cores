// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2020  Robert Finch, Waterloo
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
			case 1:	GenerateDiadic(op_ldbu, 0, ap3, ap1); break;
			case 2:	GenerateDiadic(op_ldwu, 0, ap3, ap1); break;
			case 4:	GenerateDiadic(op_ldtu, 0, ap3, ap1); break;
			case 8: GenerateDiadic(op_ldou, 0, ap3, ap1); break;
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
			case 1:	GenerateDiadic(op_ldb, 0, ap3, ap1); break;
			case 2:	GenerateDiadic(op_ldw, 0, ap3, ap1); break;
			case 4:	GenerateDiadic(op_ldt, 0, ap3, ap1); break;
			case 8:	GenerateDiadic(op_ldo, 0, ap3, ap1); break;
			}
		}
    }
}

void CodeGenerator::GenStore(Operand *ap1, Operand *ap3, int size)
{
	//if (ap1->isPtr) {
	//	GenerateDiadic(op_std, 0, ap1, ap3);
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
		case 1: GenerateDiadic(op_stb, 0, ap1, ap3); break;
		case 2: GenerateDiadic(op_stw, 0, ap1, ap3); break;
		case 4: GenerateDiadic(op_stt, 0, ap1, ap3); break;
		case 8: GenerateDiadic(op_sto, 0, ap1, ap3); break;
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
		ap1->isPtr = node->IsRefType();
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
		ap1->isPtr = node->IsRefType();
		ap1->mode = am_indx;
    ap1->preg = regFP;
    ap1->offset = makeinode(en_icon,node->p[0]->i);
		ap1->offset->sym = node->p[0]->sym;
		if (node->p[0]->tp)
			switch(node->p[0]->tp->precision) {
			case 40: ap1->FloatSize = 's'; break;
			case 80: ap1->FloatSize = 'd'; break;
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
		ap1->isPtr = node->IsRefType();
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
		ap1->isPtr = node->IsRefType();
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
		ap1->isPtr = node->IsRefType();
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
		ap1->isPtr = node->IsRefType();
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
		ap1->isPtr = node->IsRefType();
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
		ap1->isPtr = node->IsRefType();
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
		ap1->isPtr = node->IsRefType();

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
		ap1->isPtr = node->IsRefType();
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
			ap2 = node->p[0]->p[1]->Generate(am_reg,8);
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
	ap1 = node->p[0]->Generate(am_reg | am_imm, 8); // generate address
	ap1->isPtr = node->IsRefType();
	if( ap1->mode == am_reg)
    {
			// This seems a bit of a kludge. If we are dereferencing and there's a
			// pointer in the register, then we want the value at the pointer location.
			if (ap1->isPtr && !IsLValue(node)) {
				int sz = node->GetReferenceSize();
				int rg = ap1->preg;
				ReleaseTempRegister(ap1);
				ap1 = GetTempRegister();
				GenLoad(ap1, MakeIndirect(rg), sz, sz);
				ap1->mode = am_reg;
				ap1->isPtr = node->p[0]->IsRefType();
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
		GenerateDiadic(op_ldd, 0, ap2, ap1);
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
	return (node->GenerateAssignMultiply(flags, size, op));
}

//
//  generate /= and %= nodes.
//
Operand *CodeGenerator::GenerateAssignModiv(ENODE *node,int flags,int size,int op)
{
	return (node->GenerateAssignModiv(flags, size, op));
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
				case 1:	GenerateDiadic(op_stb, 0, ap2, MakeIndexed(offset, base->preg)); break;
				case 2:	GenerateDiadic(op_stw, 0, ap2, MakeIndexed(offset, base->preg)); break;
				case 4:	GenerateDiadic(op_stp, 0, ap2, MakeIndexed(offset, base->preg)); break;
				case 512:	GenerateDiadic(op_sv, 0, ap2, MakeIndexed(offset, base->preg)); break;
				default:	GenerateDiadic(op_std, 0, ap2, MakeIndexed(offset, base->preg)); break;
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
			ap1 = ep->p[2]->Generate(am_reg,thead->tp->size);
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
			case 1:	GenerateDiadic(op_stb,0,ap2,MakeIndexed(offset,base->preg)); break;
			case 2:	GenerateDiadic(op_stw,0,ap2,MakeIndexed(offset,base->preg)); break;
			case 4:	GenerateDiadic(op_stt,0,ap2,MakeIndexed(offset,base->preg)); break;
			case 512:	GenerateDiadic(op_sv,0,ap2,MakeIndexed(offset,base->preg)); break;
			default:	GenerateDiadic(op_sto,0,ap2,MakeIndexed(offset,base->preg)); break;
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
			case 1:	GenerateDiadic(op_stb,0,ap2,MakeIndexed(offset,base->preg)); break;
			case 2:	GenerateDiadic(op_stw,0,ap2,MakeIndexed(offset,base->preg)); break;
			case 4:	GenerateDiadic(op_stt,0,ap2,MakeIndexed(offset,base->preg)); break;
			case 512:	GenerateDiadic(op_sv,0,ap2,MakeIndexed(offset,base->preg)); break;
			default:	GenerateDiadic(op_sto,0,ap2,MakeIndexed(offset,base->preg)); break;
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
		ap1 = node->p[0]->Generate(am_reg | am_fpreg | am_mem | am_vreg | am_vmreg, ssize);
		flg = am_all;
		if (ap1->type == stddouble.GetIndex())
			flg = am_fpreg;
		ap2 = node->p[1]->Generate(flg,size);
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
			if (ssize > 10) {
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
						GenerateDiadic(op_sto,0,ap3,MakeIndexed(2 * sizeOfWord,regSP));
						GenerateDiadic(op_mov,0,ap3,ap2);
						GenerateDiadic(op_sto,0,ap3,MakeIndexed(1 * sizeOfWord,regSP));
						GenerateDiadic(op_mov,0,ap3,ap1);
						GenerateDiadic(op_sto,0,ap3,MakeIndirect(regSP));
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
				GenLoad(ap3, ap2, ssize, size);
//				GenLoad(ap3,ap2, node->p[0]->GetReferenceSize(),node->p[1]->GetReferenceSize());
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
		case 1:	GenerateDiadic(op_stb,0,makereg(0),ap1); break;
		case 2:	GenerateDiadic(op_stw,0,makereg(0),ap1); break;
		case 4: GenerateDiadic(op_stp,0,makereg(0),ap1); break;
		case 8:	GenerateDiadic(op_std,0,makereg(0),ap1); break;
		}
		else
		switch(size) {
		case 1:	GenerateDiadic(op_stb,0,ap2,ap1); break;
		case 2:	GenerateDiadic(op_stw,0,ap2,ap1); break;
		case 4: GenerateDiadic(op_stp,0,ap2,ap1); break;
		case 8:	GenerateDiadic(op_std,0,ap2,ap1); break;
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
	return (node->GenerateAutocon(flags, size, type));
}

//
// General expression evaluation. returns the addressing mode
// of the result.
//
Operand *CodeGenerator::GenerateExpression(ENODE *node, int flags, int size)
{   
	return (node->Generate(flags, size));
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
			*sp = TempInvalidate(fsp, sym->UsesTemps);
			//*fsp = TempFPInvalidate();
	}
	else {
		*sp = TempInvalidate(fsp, 1);
		//*fsp = TempFPInvalidate();
	}
}

void CodeGenerator::RestoreTemporaries(Function *sym, int sp, int fsp)
{
	if (sym) {
		//TempFPRevalidate(fsp);
		TempRevalidate(sp, fsp, sym->UsesTemps);
	}
	else {
		//TempFPRevalidate(fsp);
		TempRevalidate(sp, fsp, 1);
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
