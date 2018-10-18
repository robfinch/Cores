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

/*
 *      this module contains all of the code generation routines
 *      for evaluating expressions and conditions.
 */

int hook_predreg=15;

Operand *GenerateExpression();            /* forward ParseSpecifieraration */

extern Operand *copy_addr(Operand *);
extern Operand *GenExpr(ENODE *node);
extern Operand *GenerateFunctionCall(ENODE *node, int flags);
extern void GenLdi(Operand*,Operand *);
extern void GenerateCmp(ENODE *node, int op, int label, int predreg, unsigned int prediction);

void GenerateRaptor64Cmp(ENODE *node, int op, int label, int predreg);
void GenerateTable888Cmp(ENODE *node, int op, int label, int predreg);
void GenerateThorCmp(ENODE *node, int op, int label, int predreg);
void GenLoad(Operand *ap3, Operand *ap1, int ssize, int size);
void GenerateZeroExtend(Operand *ap, int isize, int osize);
void GenerateSignExtend(Operand *ap, int isize, int osize, int flags);

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


/*
 *      construct a reference node for an internal label number.
 */
Operand *make_label(int lab)
{
	ENODE *lnode;
	Operand *ap;

	lnode = allocEnode();
	lnode->nodetype = en_labcon;
	lnode->i = lab;
	ap = allocOperand();
	ap->mode = am_direct;
	ap->offset = lnode;
	ap->isUnsigned = TRUE;
	return ap;
}

Operand *make_clabel(int lab)
{
	ENODE *lnode;
    Operand *ap;

    lnode = allocEnode();
    lnode->nodetype = en_clabcon;
    lnode->i = lab;
	if (lab==-1)
		printf("-1\r\n");
    ap = allocOperand();
    ap->mode = am_direct;
    ap->offset = lnode;
	ap->isUnsigned = TRUE;
    return ap;
}

Operand *make_string(char *s)
{
	ENODE *lnode;
	Operand *ap;

	lnode = allocEnode();
	lnode->nodetype = en_nacon;
	lnode->sp = new std::string(s);
	ap = allocOperand();
	ap->mode = am_direct;
	ap->offset = lnode;
	return ap;
}

/*
 *      make a node to reference an immediate value i.
 */
Operand *make_immed(int64_t i)
{
	Operand *ap;
    ENODE *ep;
    ep = allocEnode();
    ep->nodetype = en_icon;
    ep->i = i;
    ap = allocOperand();
    ap->mode = am_imm;
    ap->offset = ep;
    return ap;
}

Operand *make_indirect(int i)
{
	Operand *ap;
    ENODE *ep;
    ep = allocEnode();
    ep->nodetype = en_uw_ref;
    ep->i = 0;
    ap = allocOperand();
	ap->mode = am_ind;
	ap->preg = i;
    ap->offset = 0;//ep;	//=0;
    return ap;
}

Operand *make_indexed(int64_t o, int i)
{
	Operand *ap;
    ENODE *ep;
    ep = allocEnode();
    ep->nodetype = en_icon;
    ep->i = o;
    ap = allocOperand();
	ap->mode = am_indx;
	ap->preg = i;
    ap->offset = ep;
    return ap;
}

/*
 *      make a direct reference to a node.
 */
Operand *make_offset(ENODE *node)
{
	Operand *ap;
	ap = allocOperand();
	ap->mode = am_direct;
	ap->offset = node;
	return ap;
}
        
Operand *make_indx(ENODE *node, int rg)
{
	Operand *ap;
    ap = allocOperand();
    ap->mode = am_indx;
    ap->offset = node;
    ap->preg = rg;
    return ap;
}

void GenerateHint(int num)
{
	GenerateMonadic(op_hint,0,make_immed(num));
}

void GenerateComment(char *cm)
{
	GenerateMonadic(op_rem2,0,make_string(cm));
}


void GenLoad(Operand *ap3, Operand *ap1, int ssize, int size)
{
	if (ap3->type==stdvector.GetIndex()) {
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

void GenStore(Operand *ap1, Operand *ap3, int size)
{
	if (ap1->isPtr) {
		GenerateDiadic(op_sw, 0, ap1, ap3);
	}
	else if (ap1->type==stdvector.GetIndex())
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
		default:;
		}
	}
}

//
//  Return the addressing mode of a dereferenced node.
//
Operand *GenerateDereference(ENODE *node,int flags,int size, int su)
{    
	Operand *ap1;
  int siz1;

  Enter("<Genderef>");
	siz1 = node->GetReferenceSize();
	// When dereferencing a struct or union return a pointer to the struct or
	// union.
//	if (node->tp->type==bt_struct || node->tp->type==bt_union) {
//        return GenerateExpression(node,F_REG|F_MEM,size);
//    }

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
				ap1->GenSignExtend(siz1,size,flags);
			else
				ap1->MakeLegal(flags,siz1);
      ap1->MakeLegal(flags,size);
			return (ap1);
		}

  if(node->p[0]->nodetype == en_autocon)
  {
    ap1 = allocOperand();
		ap1->isPtr = node->nodetype == en_wp_ref || node->nodetype == en_hp_ref;
		ap1->mode = am_indx;
		ap1->preg = regFP;
		ap1->segment = stackseg;
		ap1->offset = makeinode(en_icon,node->p[0]->i);
		ap1->offset->sym = node->p[0]->sym;
		ap1->isUnsigned = !su;
		if (!node->isUnsigned)
			ap1->GenSignExtend(siz1,size,flags);
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
	        ap1->GenSignExtend(siz1,size,flags);
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
			ap1->GenSignExtend(siz1, size, flags);
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
	        ap1->GenSignExtend(siz1,size,flags);
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
			ap1->GenSignExtend(siz1, size, flags);
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
			ap1->GenSignExtend(siz1, size, flags);
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
		ap1->mode = node->p[0]->i < regFirstArg ? am_ind : am_reg;
//		ap1->mode = node->p[0]->tp->val_flag ? am_reg : am_ind;
		ap1->preg = node->p[0]->i;
		ap1->MakeLegal(flags,size);
	    Leave("Genderef",3);
        return ap1;
	}
	else if (node->p[0]->nodetype == en_fpregvar) {
		/*error(ERR_DEREF)*/;
		ap1 = allocOperand();
		ap1->isPtr = node->nodetype == en_wp_ref || node->nodetype == en_hp_ref;
		ap1->mode = node->p[0]->i < regFirstArg ? am_ind : am_fpreg;
		ap1->preg = node->p[0]->i;
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
			ap1 = GenerateDereference(node->p[0]->p[0],F_REG,8,0);
			ap2 = GenerateExpression(node->p[0]->p[1],F_REG,8);
			if (ap1->offset && ap2->offset) {
				GenerateTriadic(op_add,0,ap1,makereg(0),make_immed(ap2->offset->i));
			}
			ReleaseTempReg(ap2);
			//ap1->mode = node->p[0]->i < 18 ? am_ind : am_reg;
			//ap1->preg = node->p[0]->i;
			ap1->type = stdvector.GetIndex();
			ap1->MakeLegal(flags,size);
			return (ap1);
		}
	}
  ap1 = GenerateExpression(node->p[0],F_REG | F_IMMED,8); /* generate address */
	ap1->isPtr = node->nodetype == en_wp_ref || node->nodetype == en_hp_ref;
	if( ap1->mode == am_reg)
    {
			// This seems a bit of a kludge. If we are dereferencing and there's a
			// pointer in the register, then we want the value at the pointer location.
			if (ap1->isPtr) {
				GenLoad(ap1, make_indirect(ap1->preg), size, size);
				ap1->mode = am_reg;
			}
			else
			{
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
					ap1->GenSignExtend(siz1, size, flags);
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
	ap1->isPtr = node->nodetype == en_wp_ref || node->nodetype == en_hp_ref;
	if (use_gp) {
        ap1->mode = am_indx;
        ap1->preg = regGP;
    	ap1->segment = dataseg;
    }
    else {
        ap1->mode = am_direct;
	    ap1->isUnsigned = !su | ap1->isPtr;
    }
//    ap1->offset = makeinode(en_icon,node->p[0]->i);
    ap1->isUnsigned = !su | ap1->isPtr;
	if (!node->isUnsigned)
	    ap1->GenSignExtend(siz1,size,flags);
	else
		ap1->MakeLegal(flags,siz1);
    ap1->isVolatile = node->isVolatile;
    ap1->MakeLegal(flags,size);
xit:
    Leave("</Genderef>",0);
    return (ap1);
}


void GenMemop(int op, Operand *ap1, Operand *ap2, int ssize)
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
	{
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
Operand *GenerateAssignMultiply(ENODE *node,int flags, int size, int op)
{
	Operand *ap1, *ap2, *ap3;
    int             ssize;
    ssize = GetNaturalSize(node->p[0]);
    if( ssize > size )
            size = ssize;
	if (node->p[0]->IsBitfield()) {
		ap3 = GetTempRegister();
		ap1 = GenerateBitfieldDereference(node->p[0], F_REG | F_MEM, size);
		GenerateDiadic(op_mov, 0, ap3, ap1);
		ap2 = GenerateExpression(node->p[1], F_REG | F_IMMED, size);
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
        ap1 = GenerateExpression(node->p[0],F_FPREG | F_MEM,ssize);
        ap2 = GenerateExpression(node->p[1],F_FPREG,size);
        op = op_fmul;
    }
    else if (node->etype==bt_vector) {
        ap1 = GenerateExpression(node->p[0],F_REG | F_MEM,ssize);
        ap2 = GenerateExpression(node->p[1],F_REG,size);
		op = ap2->type==stdvector.GetIndex() ? op_vmul : op_vmuls;
    }
    else {
        ap1 = GenerateExpression(node->p[0],F_ALL & ~F_IMMED,ssize);
        ap2 = GenerateExpression(node->p[1],F_REG | F_IMMED,size);
    }
	if (ap1->mode==am_reg) {
	    GenerateTriadic(op,0,ap1,ap1,ap2);
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
    ap1->GenSignExtend(ssize,size,flags);
    ap1->MakeLegal(flags,size);
    return (ap1);
}

/*
 *      generate /= and %= nodes.
 */
Operand *GenerateAssignModiv(ENODE *node,int flags,int size,int op)
{
	Operand *ap1, *ap2, *ap3;
    int             siz1;
    int isFP;
 
    siz1 = GetNaturalSize(node->p[0]);
	if (node->p[0]->IsBitfield()) {
		ap3 = GetTempRegister();
		ap1 = GenerateBitfieldDereference(node->p[0], F_REG | F_MEM, size);
		GenerateDiadic(op_mov, 0, ap3, ap1);
		ap2 = GenerateExpression(node->p[1], F_REG | F_IMMED, size);
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
        ap1 = GenerateExpression(node->p[0],F_FPREG,siz1);
        ap2 = GenerateExpression(node->p[1],F_FPREG,size);
		GenerateTriadic(op,siz1==4?'s':siz1==8?'d':siz1==12?'t':siz1==16?'q':'d',ap1,ap1,ap2);
	    ReleaseTempReg(ap2);
		ap1->MakeLegal(flags,size);
	    return (ap1);
//        else if (op==op_mod || op==op_modu)
//           op = op_fdmod;
    }
    else {
        ap1 = GetTempRegister();
        ap2 = GenerateExpression(node->p[0],F_ALL & ~F_IMMED,siz1);
    }
	if (ap2->mode==am_reg && ap2->preg != ap1->preg)
		GenerateDiadic(op_mov,0,ap1,ap2);
	else if (ap2->mode==am_fpreg && ap2->preg != ap1->preg)
		GenerateDiadic(op_mov,0,ap1,ap2);
	else
        GenLoad(ap1,ap2,siz1,siz1);
    //GenerateSignExtend(ap1,siz1,2,flags);
    if (isFP)
        ap3 = GenerateExpression(node->p[1],F_FPREG,8);
		else {
			// modu doesn't support immediate mode
			ap3 = GenerateExpression(node->p[1], op==op_modu ? F_REG : F_REG | F_IMMED, 8);
		}
	if (op==op_fdiv) {
		GenerateTriadic(op,siz1==4?'s':siz1==8?'d':siz1==12?'t':siz1==16?'q':'d',ap1,ap1,ap3);
	}
	else
		GenerateTriadic(op,0,ap1,ap1,ap3);
    ReleaseTempReg(ap3);
    //GenerateDiadic(op_ext,0,ap1,0);
	if (ap2->mode==am_reg)
		GenerateDiadic(op_mov,0,ap2,ap1);
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

Operand *GenerateAssign(ENODE *node, int flags, int size);

// Generate an assignment to a structure type. The type passed must be a
// structure type.

void GenerateStructAssign(TYP *tp, int64_t offset, ENODE *ep, Operand *base)
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
				ap1 = GenerateExpression(ep, F_REG, thead->tp->size);
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
				case 1:	GenerateDiadic(op_sb, 0, ap2, make_indexed(offset, base->preg)); break;
				case 2:	GenerateDiadic(op_sc, 0, ap2, make_indexed(offset, base->preg)); break;
				case 4:	GenerateDiadic(op_sh, 0, ap2, make_indexed(offset, base->preg)); break;
				case 512:	GenerateDiadic(op_sv, 0, ap2, make_indexed(offset, base->preg)); break;
				default:	GenerateDiadic(op_sw, 0, ap2, make_indexed(offset, base->preg)); break;
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
			ap1 = GenerateExpression(ep->p[2],F_REG,thead->tp->size);
			if (ap1->mode==am_imm) {
				ap2 = GetTempRegister();
				GenLdi(ap2,ap1);
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
			case 1:	GenerateDiadic(op_sb,0,ap2,make_indexed(offset,base->preg)); break;
			case 2:	GenerateDiadic(op_sc,0,ap2,make_indexed(offset,base->preg)); break;
			case 4:	GenerateDiadic(op_sh,0,ap2,make_indexed(offset,base->preg)); break;
			case 512:	GenerateDiadic(op_sv,0,ap2,make_indexed(offset,base->preg)); break;
			default:	GenerateDiadic(op_sw,0,ap2,make_indexed(offset,base->preg)); break;
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


Operand *GenerateAggregateAssign(ENODE *node1, ENODE *node2);

// Generate an assignment to an array.

void GenerateArrayAssign(TYP *tp, ENODE *node1, ENODE *node2, Operand *base)
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
			ap1 = GenerateExpression(ep1,F_REG|F_IMMED,sizeOfWord);
			ap2 = GetTempRegister();
			if (ap1->mode==am_imm)
				GenLdi(ap2,ap1);
			else {
				if (ap1->offset)
					offset2 = ap1->offset->i;
				else
					offset2 = 0;
				GenerateDiadic(op_mov,0,ap2,ap1);
			}
			switch(tp->GetElementSize())
			{
			case 1:	GenerateDiadic(op_sb,0,ap2,make_indexed(offset,base->preg)); break;
			case 2:	GenerateDiadic(op_sc,0,ap2,make_indexed(offset,base->preg)); break;
			case 4:	GenerateDiadic(op_sh,0,ap2,make_indexed(offset,base->preg)); break;
			case 512:	GenerateDiadic(op_sv,0,ap2,make_indexed(offset,base->preg)); break;
			default:	GenerateDiadic(op_sw,0,ap2,make_indexed(offset,base->preg)); break;
			}
			offset += tp->GetElementSize();
			ReleaseTempReg(ap2);
			ReleaseTempReg(ap1);
			ep1 = ep1->p[2];
		}
	}
}

Operand *GenerateAggregateAssign(ENODE *node1, ENODE *node2)
{
	Operand *base, *base2;
	TYP *tp;
	int64_t offset = 0;

	if (node1==nullptr || node2==nullptr)
		return nullptr;
	//DumpStructEnodes(node2);
	base = GenerateExpression(node1,F_REG,sizeOfWord);
	base2 = GenerateExpression(node2, F_REG, sizeOfWord);
	GenerateDiadic(op_mov, 0, makereg(regFirstArg), base);
	GenerateDiadic(op_mov, 0, makereg(regFirstArg+1), base2);
	GenerateDiadic(op_ldi, 0, makereg(regFirstArg+2), make_immed(node2->tp->size));
	GenerateMonadic(op_call, 0, make_string("memcpy"));
	ReleaseTempReg(base2);
	return (base);
	//base = GenerateDereference(node1,F_MEM,sizeOfWord,0);
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
Operand *GenerateAssign(ENODE *node, int flags, int size)
{
	Operand *ap1, *ap2 ,*ap3;
	TYP *tp;
    int ssize;

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
		ap1 = GenerateExpression(node->p[0],F_REG,ssize);
		ap2 = GenerateExpression(node->p[1],F_REG,size);
		GenerateMonadic(op_push,0,make_immed(node->tp->size));
		GenerateMonadic(op_push,0,ap2);
		GenerateMonadic(op_push,0,ap1);
		GenerateMonadic(op_bsr,0,make_string("memcpy_"));
		GenerateTriadic(op_addui,0,makereg(regSP),makereg(regSP),make_immed(24));
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
	//	ap1 = GenerateExpression(node->p[0],F_MEM,ssize);
	//	ap2 = GenerateExpression(node->p[1],F_MEM,size);
	//}
	//else {
		ap1 = GenerateExpression(node->p[0], F_REG | F_FPREG | F_MEM | F_VREG | F_VMREG, ssize);
		ap2 = GenerateExpression(node->p[1],F_ALL,size);
		if (node->p[0]->isUnsigned && !node->p[1]->isUnsigned)
		    ap2->GenZeroExtend(size,ssize);
//	}
	if (ap1->mode == am_reg || ap1->mode==am_fpreg) {
		switch(ap2->mode) {
		case am_reg:
			GenerateHint(2);
			if (ap2->isPtr) {
				GenerateZeradic(op_setwb);
				ap1->isPtr = TRUE;
			}
			GenerateDiadic(op_mov, 0, ap1, ap2);
			break;
		case am_fpreg:
			GenerateHint(2);
			if (ap1->mode==am_fpreg)
				GenerateDiadic(op_mov,0,ap1,ap2);
			else
				GenerateDiadic(op_mov,0,ap1,ap2);
			break;
		case am_imm:
			if (ap2->isPtr)
				GenerateZeradic(op_setwb);
			GenerateDiadic(op_ldi,0,ap1,ap2);
			ap1->isPtr = ap2->isPtr;
			break;
		default:
			GenLoad(ap1,ap2,ssize,size);
			ap1->isPtr = ap2->isPtr;
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
				GenerateDiadic(op_ldi,0,ap3,ap2);
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
						GenerateTriadic(op_sub,0,makereg(regSP),makereg(regSP),make_immed(3 * sizeOfWord));
						ap3 = GetTempRegister();
						GenerateDiadic(op_ldi,0,ap3,make_immed(size));
						GenerateDiadic(op_sw,0,ap3,make_indexed(2 * sizeOfWord,regSP));
						GenerateDiadic(op_mov,0,ap3,ap2);
						GenerateDiadic(op_sw,0,ap3,make_indexed(1 * sizeOfWord,regSP));
						GenerateDiadic(op_mov,0,ap3,ap1);
						GenerateDiadic(op_sw,0,ap3,make_indirect(regSP));
					}
					else {
						GenerateMonadic(op_push,0,make_immed(size));
						GenerateMonadic(op_push,0,ap2);
						GenerateMonadic(op_push,0,ap1);
					}
					GenerateDiadic(op_jal,0,makereg(regLR),make_string("memcpy_"));
					GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(3*sizeOfWord));
				}
			}
			else {
				ap3->isPtr = ap2->isPtr;
                GenLoad(ap3,ap2,ssize,size);
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
			GenerateDiadic(op_ldi,0,ap3,make_immed(size));
			GenerateTriadic(op_push,0,ap3,ap2,ap1);
			GenerateDiadic(op_jal,0,makereg(LR),make_string("memcpy"));
			GenerateTriadic(op_addui,0,makereg(SP),makereg(SP),make_immed(24));
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

Operand *GenAutocon(ENODE *node, int flags, int size, int type)
{
	Operand *ap1, *ap2;

	if (type==stddouble.GetIndex() || type==stdflt.GetIndex() || type==stdtriple.GetIndex() || type==stdquad.GetIndex())
		ap1 = GetTempFPRegister();
	else
		ap1 = GetTempRegister();
	ap2 = allocOperand();
	ap2->isPtr = node->etype == bt_pointer;
	ap2->mode = am_indx;
	ap2->preg = regFP;          /* frame pointer */
	ap2->offset = node;     /* use as constant node */
	ap2->type = type;
	ap1->type = type;
	GenerateDiadic(op_lea,0,ap1,ap2);
	ap1->MakeLegal(flags,size);
	return (ap1);             /* return reg */
}

//
// General expression evaluation. returns the addressing mode
// of the result.
//
Operand *GenerateExpression(ENODE *node, int flags, int size)
{   
	Operand *ap1, *ap2;
  int natsize;
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
		ap1 = allocOperand();
		ap1->offset = node;
		ap1->type = 9999;
		return (ap1);
	case en_fcon:
    ap1 = allocOperand();
		ap1->isPtr = node->IsPtr();
		ap1->mode = am_direct;
    ap1->offset = node;
		ap1->type = stddouble.GetIndex();
		// Don't allow the constant to be loaded into an integer register.
    ap1->MakeLegal(flags & ~F_REG,size);
    Leave("</GenerateExpression>",2); 
    return (ap1);
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
      return (ap1);

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
                return ap1;             // return reg
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
            return ap1;

    case en_nacon:
            if (use_gp) {
                ap1 = GetTempRegister();
                ap2 = allocOperand();
                ap2->mode = am_indx;
                ap2->preg = regGP;      // global pointer
                ap2->offset = node;     // use as constant node
                GenerateDiadic(op_lea,0,ap1,ap2);
				ap1->MakeLegal(flags,size);
				Leave("GenExpression",6); 
                return ap1;             // return reg
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
            return ap1;
	case en_clabcon:
            ap1 = allocOperand();
            ap1->mode = am_imm;
            ap1->offset = node;
			ap1->isUnsigned = node->isUnsigned;
            ap1->MakeLegal(flags,size);
			Leave("GenExpression",7); 
            return ap1;
  case en_autocon:	return GenAutocon(node, flags, size, stdint.GetIndex());
  case en_autofcon:	
		switch (node->tp->type)
		{
		case bt_float:	return GenAutocon(node, flags, size, stdflt.GetIndex());
		case bt_double:	return GenAutocon(node, flags, size, stddouble.GetIndex());
		case bt_triple:	return GenAutocon(node, flags, size, stdtriple.GetIndex());
		case bt_quad:	return GenAutocon(node, flags, size, stdquad.GetIndex());
		case bt_pointer:	return GenAutocon(node, flags, size, stdint.GetIndex());
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
            return ap1;             /* return reg */
    case en_ub_ref:
	case en_uc_ref:
	case en_uh_ref:
	case en_uw_ref:
		ap1 = GenerateDereference(node, flags, size, 0);
		ap1->isUnsigned = TRUE;
		return ap1;
	case en_hp_ref:
	case en_wp_ref:
		ap1 = GenerateDereference(node,flags,size,0);
		ap1->isPtr = TRUE;
		ap1->isUnsigned = TRUE;
    return ap1;
	case en_vector_ref:	return GenerateDereference(node,flags,512,0);
	case en_ref32:	return GenerateDereference(node,flags,4,1);
	case en_ref32u:	return GenerateDereference(node,flags,4,0);
  case en_b_ref:	return GenerateDereference(node,flags,1,1);
	case en_c_ref:	return GenerateDereference(node,flags,2,1);
	case en_h_ref:	return GenerateDereference(node,flags,4,1);
  case en_w_ref:	return GenerateDereference(node,flags,8,1);
	case en_flt_ref:
		ap1 = GenerateDereference(node, flags, size, 1);
		ap1->type = stdflt.GetIndex();
		ap1->MakeLegal(flags, size);
		return (ap1);
	case en_dbl_ref:
		ap1 = GenerateDereference(node, flags, size, 1);
		ap1->type = stddouble.GetIndex();
		ap1->MakeLegal(flags, size);
		return (ap1);
	case en_triple_ref:
		ap1 = GenerateDereference(node, flags, size, 1);
		ap1->type = stdtriple.GetIndex();
		ap1->MakeLegal(flags, size);
		return (ap1);
	case en_quad_ref:
		ap1 = GenerateDereference(node,flags,size,1);
		ap1->type = stdquad.GetIndex();
		ap1->MakeLegal(flags, size);
		return (ap1);
	case en_ubfieldref:
	case en_ucfieldref:
	case en_uhfieldref:
	case en_uwfieldref:
			ap1 = (flags & BF_ASSIGN) ? GenerateDereference(node,flags & ~BF_ASSIGN,size,0) : GenerateBitfieldDereference(node,flags,size);
			ap1->isUnsigned = TRUE;
			return ap1;
	case en_wfieldref:
	case en_bfieldref:
	case en_cfieldref:
	case en_hfieldref:
			ap1 = (flags & BF_ASSIGN) ? GenerateDereference(node,flags & ~BF_ASSIGN,size,1) : GenerateBitfieldDereference(node,flags,size);
			return ap1;
	case en_regvar:
  case en_tempref:
    ap1 = allocOperand();
		ap1->isPtr = node->IsPtr();
    ap1->mode = am_reg;
    ap1->preg = node->i;
    ap1->tempflag = 0;      /* not a temporary */
    ap1->MakeLegal(flags,size);
    return (ap1);

	case en_tempfpref:
		ap1 = allocOperand();
		ap1->isPtr = node->IsPtr();
		ap1->mode = node->IsPtr() ? am_reg : am_fpreg;
		ap1->preg = node->i;
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
    return (ap1);

	case en_fpregvar:
//    case en_fptempref:
    ap1 = allocOperand();
		ap1->isPtr = node->IsPtr();
		ap1->mode = node->IsPtr() ? am_reg : am_fpreg;
    ap1->preg = node->i;
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
    return (ap1);

	case en_abs:	return node->GenUnary(flags,size,op_abs);
    case en_uminus: return node->GenUnary(flags,size,op_neg);
    case en_compl:  return node->GenUnary(flags,size,op_com);
	case en_not:	return (node->GenUnary(flags, 8, op_not));
    case en_add:    return node->GenBinary(flags,size,op_add);
    case en_sub:    return node->GenBinary(flags,size,op_sub);
    case en_i2d:
         ap1 = GetTempFPRegister();	
         ap2=GenerateExpression(node->p[0],F_REG,8);
         GenerateDiadic(op_itof,'d',ap1,ap2);
         ReleaseTempReg(ap2);
         return (ap1);
    case en_i2q:
         ap1 = GetTempFPRegister();	
         ap2 = GenerateExpression(node->p[0],F_REG,8);
		 GenerateTriadic(op_csrrw,0,makereg(0),make_immed(0x18),ap2);
		 GenerateZeradic(op_nop);
		 GenerateZeradic(op_nop);
         GenerateDiadic(op_itof,'q',ap1,makereg(63));
         ReleaseTempReg(ap2);
         return (ap1);
    case en_i2t:
         ap1 = GetTempFPRegister();	
         ap2 = GenerateExpression(node->p[0],F_REG,8);
		 GenerateTriadic(op_csrrw,0,makereg(0),make_immed(0x18),ap2);
		 GenerateZeradic(op_nop);
		 GenerateZeradic(op_nop);
         GenerateDiadic(op_itof,'t',ap1,makereg(63));
         ReleaseTempReg(ap2);
         return (ap1);
    case en_d2i:
         ap1 = GetTempRegister();	
         ap2 = GenerateExpression(node->p[0],F_FPREG,8);
         GenerateDiadic(op_ftoi,'d',ap1,ap2);
         ReleaseTempReg(ap2);
         return (ap1);
    case en_q2i:
         ap1 = GetTempRegister();
         ap2 = GenerateExpression(node->p[0],F_FPREG,8);
         GenerateDiadic(op_ftoi,'q',makereg(63),ap2);
		 GenerateZeradic(op_nop);
		 GenerateZeradic(op_nop);
		 GenerateTriadic(op_csrrw,0,ap1,make_immed(0x18),makereg(0));
         ReleaseTempReg(ap2);
         return (ap1);
    case en_t2i:
         ap1 = GetTempRegister();
         ap2 = GenerateExpression(node->p[0],F_FPREG,8);
         GenerateDiadic(op_ftoi,'t',makereg(63),ap2);
		 GenerateZeradic(op_nop);
		 GenerateZeradic(op_nop);
		 GenerateTriadic(op_csrrw,0,ap1,make_immed(0x18),makereg(0));
         ReleaseTempReg(ap2);
         return (ap1);
	case en_s2q:
		ap1 = GetTempFPRegister();
        ap2 = GenerateExpression(node->p[0],F_FPREG,8);
        GenerateDiadic(op_fcvtsq,0,ap1,ap2);
		ap1->type = stdquad.GetIndex();
		ReleaseTempReg(ap2);
		return ap1;
	case en_d2q:
		ap1 = GetTempFPRegister();
		ap2 = GenerateExpression(node->p[0], F_FPREG, 8);
		GenerateDiadic(op_fcvtdq, 0, ap1, ap2);
		ap1->type = stdquad.GetIndex();
		ReleaseTempReg(ap2);
		return ap1;
	case en_t2q:
		ap1 = GetTempFPRegister();
		ap2 = GenerateExpression(node->p[0], F_FPREG, 8);
		GenerateDiadic(op_fcvttq, 0, ap1, ap2);
		ap1->type = stdquad.GetIndex();
		ReleaseTempReg(ap2);
		return ap1;

	case en_vadd:	  return node->GenBinary(flags,size,op_vadd);
	case en_vsub:	  return node->GenBinary(flags,size,op_vsub);
	case en_vmul:	  return node->GenBinary(flags,size,op_vmul);
	case en_vadds:	  return node->GenBinary(flags,size,op_vadds);
	case en_vsubs:	  return node->GenBinary(flags,size,op_vsubs);
	case en_vmuls:	  return node->GenBinary(flags,size,op_vmuls);
	case en_vex:      return node->GenBinary(flags,size,op_vex);
	case en_veins:    return node->GenBinary(flags,size,op_veins);

	case en_fadd:	  return node->GenBinary(flags,size,op_fadd);
	case en_fsub:	  return node->GenBinary(flags,size,op_fsub);
	case en_fmul:	  return node->GenBinary(flags,size,op_fmul);
	case en_fdiv:	  return node->GenBinary(flags,size,op_fdiv);

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

	case en_land:	return (node->GenLand(flags,op_and));
	case en_lor:	return (node->GenLand(flags, op_or));
	case en_and:    return node->GenBinary(flags,size,op_and);
    case en_or:     return node->GenBinary(flags,size,op_or);
	case en_xor:	return node->GenBinary(flags,size,op_xor);
    case en_mul:    return node->GenMultiply(flags,size,op_mul);
    case en_mulu:   return node->GenMultiply(flags,size,op_mulu);
    case en_div:    return node->GenDivMod(flags,size,op_div);
    case en_udiv:   return node->GenDivMod(flags,size,op_divu);
    case en_mod:    return node->GenDivMod(flags,size,op_mod);
    case en_umod:   return node->GenDivMod(flags,size,op_modu);
    case en_asl:    return node->GenShift(flags,size,op_asl);
    case en_shl:    return node->GenShift(flags,size,op_shl);
    case en_shlu:   return node->GenShift(flags,size,op_shl);
    case en_asr:	return node->GenShift(flags,size,op_asr);
    case en_shr:	return node->GenShift(flags,size,op_asr);
    case en_shru:   return node->GenShift(flags,size,op_shru);
	case en_rol:   return node->GenShift(flags,size,op_rol);
	case en_ror:   return node->GenShift(flags,size,op_ror);
	/*	
	case en_asfadd: return GenerateAssignAdd(node,flags,size,op_fadd);
	case en_asfsub: return GenerateAssignAdd(node,flags,size,op_fsub);
	case en_asfmul: return GenerateAssignAdd(node,flags,size,op_fmul);
	case en_asfdiv: return GenerateAssignAdd(node,flags,size,op_fdiv);
	*/
    case en_asadd:  return node->GenAssignAdd(flags,size,op_add);
    case en_assub:  return node->GenAssignAdd(flags,size,op_sub);
    case en_asand:  return node->GenAssignLogic(flags,size,op_and);
    case en_asor:   return node->GenAssignLogic(flags,size,op_or);
	case en_asxor:  return node->GenAssignLogic(flags,size,op_xor);
    case en_aslsh:  return (node->GenAssignShift(flags,size,op_shl));
    case en_asrsh:  return (node->GenAssignShift(flags,size,op_asr));
	case en_asrshu: return (node->GenAssignShift(flags,size,op_shru));
    case en_asmul: return GenerateAssignMultiply(node,flags,size,op_mul);
    case en_asmulu: return GenerateAssignMultiply(node,flags,size,op_mulu);
    case en_asdiv: return GenerateAssignModiv(node,flags,size,op_div);
    case en_asdivu: return GenerateAssignModiv(node,flags,size,op_divu);
    case en_asmod: return GenerateAssignModiv(node,flags,size,op_mod);
    case en_asmodu: return GenerateAssignModiv(node,flags,size,op_modu);
    case en_assign:
            return (GenerateAssign(node,flags,size));

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
      return GenExpr(node);

	case en_cond:
    return (node->GenHook(flags,size));
  case en_void:
    natsize = GetNaturalSize(node->p[0]);
    ReleaseTempRegister(GenerateExpression(node->p[0],F_ALL | F_NOVALUE,natsize));
		ap1 = GenerateExpression(node->p[1], flags, size);
		ap1->isPtr = node->IsPtr();
    return (ap1);

  case en_fcall:
		return (GenerateFunctionCall(node,flags));

	case en_sxb:
		ap2 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0], F_REG, 8);
		GenerateDiadic(op_sxb, 0, ap2, ap1);
		ReleaseTempReg(ap1);
		ap2->MakeLegal( flags, 8);
		return (ap2);
	case en_sxc:
		ap2 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0], F_REG, 8);
		GenerateDiadic(op_sxc, 0, ap2, ap1);
		ReleaseTempReg(ap1);
		ap2->MakeLegal( flags, 8);
		return (ap2);
	case en_sxh:
		ap2 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0], F_REG, 8);
		GenerateDiadic(op_sxh, 0, ap2, ap1);
		ReleaseTempReg(ap1);
		ap2->MakeLegal( flags, 8);
		return (ap2);
	case en_cubw:
	case en_cubu:
	case en_cbu:
			ap1 = GenerateExpression(node->p[0],F_REG,size);
			GenerateTriadic(op_and,0,ap1,ap1,make_immed(0xff));
			return (ap1);
	case en_cucw:
	case en_cucu:
	case en_ccu:
			ap1 = GenerateExpression(node->p[0],F_REG,size);
			GenerateDiadic(op_zxc,0,ap1,ap1);
			return ap1;
	case en_ccwp:
		ap1 = GenerateExpression(node->p[0], F_REG, size);
		ap1->isPtr = TRUE;
		GenerateDiadic(op_sxc, 0, ap1, ap1);
		return ap1;
	case en_cucwp:
		ap1 = GenerateExpression(node->p[0], F_REG, size);
		ap1->isPtr = TRUE;
		GenerateDiadic(op_zxc, 0, ap1, ap1);
		return ap1;
	case en_cuhw:
	case en_cuhu:
	case en_chu:
			ap1 = GenerateExpression(node->p[0],F_REG,size);
			GenerateDiadic(op_zxh,0,ap1,ap1);
			return ap1;
	case en_cbw:
			ap1 = GenerateExpression(node->p[0],F_REG,size);
			//GenerateDiadic(op_sxb,0,ap1,ap1);
			GenerateDiadic(op_sxb,0,ap1,ap1);
			return ap1;
	case en_ccw:
			ap1 = GenerateExpression(node->p[0],F_REG,size);
			GenerateDiadic(op_sxc,0,ap1,ap1);
			return ap1;
	case en_chw:
			ap1 = GenerateExpression(node->p[0],F_REG,size);
			GenerateDiadic(op_sxh,0,ap1,ap1);
			return ap1;
	case en_object_list:
			ap1 = GetTempRegister();
			GenerateDiadic(op_lea,0,ap1,make_indexed(-8,regFP));
			ap1->MakeLegal(flags,sizeOfWord);
			return (ap1);
  default:
    printf("DIAG - uncoded node (%d) in GenerateExpression.\n", node->nodetype);
    return 0;
  }
	return(0);
}

// return the natural evaluation size of a node.

int GetNaturalSize(ENODE *node)
{ 
	int siz0, siz1;
	if( node == NULL )
		return 0;
	switch( node->nodetype )
	{
	case en_uwfieldref:
	case en_wfieldref:
		return sizeOfWord;
	case en_bfieldref:
	case en_ubfieldref:
		return 1;
	case en_cfieldref:
	case en_ucfieldref:
		return 2;
	case en_hfieldref:
	case en_uhfieldref:
		return 4;
	case en_icon:
		if (node->i >= -128 && node->i < 128)
			return (1);
		if( -32768 <= node->i && node->i <= 32767 )
			return (2);
		if (-2147483648LL <= node->i && node->i <= 2147483647LL)
			return (4);
		return (8);
	case en_fcon:
		return node->tp->precision / 16;
	case en_tcon: return 6;
	case en_fcall:  case en_labcon: case en_clabcon:
	case en_cnacon: case en_nacon:  case en_autocon: case en_classcon:
	case en_tempref:
	case en_cbw: case en_cubw:
	case en_ccw: case en_cucw:
	case en_chw: case en_cuhw:
	case en_cbu: case en_ccu: case en_chu:
	case en_cubu: case en_cucu: case en_cuhu:
	case en_ccwp: case en_cucwp:
	case en_sxb:	case en_sxc:	case en_sxh:
		return 8;
	case en_regvar:
	case en_fpregvar:
		if (node->tp)
			return (node->tp->size);
		else
			return (8);
	case en_autofcon:
		return 8;
	case en_ref32: case en_ref32u:
		return 4;
	case en_b_ref:
	case en_ub_ref:
		return 1;
	case en_cbc:
	case en_c_ref:	return 2;
	case en_uc_ref:	return 2;
	case en_cbh:	return 2;
	case en_cch:	return 2;
	case en_h_ref:	return 4;
	case en_uh_ref:	return 4;
	case en_flt_ref: return sizeOfFPS;
	case en_w_ref:  case en_uw_ref:
		return 8;
	case en_hp_ref:
		return 4;
	case en_wp_ref:
		return 8;
	case en_autovcon:
	case en_vector_ref:
		return 512;
	case en_dbl_ref:
		return sizeOfFPD;
	case en_quad_ref:
		return sizeOfFPQ;
	case en_triple_ref:
		return sizeOfFPT;
	case en_tempfpref:
	if (node->tp)
		return node->tp->precision/16;
	else
		return 8;
	case en_not:    case en_compl:
	case en_uminus: case en_assign:
		return GetNaturalSize(node->p[0]);
	case en_fadd:	case en_fsub:
	case en_fmul:	case en_fdiv:
	case en_fsadd:	case en_fssub:
	case en_fsmul:	case en_fsdiv:
	case en_vadd:	case en_vsub:
	case en_vmul:	case en_vdiv:
	case en_vadds:	case en_vsubs:
	case en_vmuls:	case en_vdivs:
	case en_add:    case en_sub:
	case en_mul:    case en_mulu:
	case en_div:	case en_udiv:
	case en_mod:    case en_umod:
	case en_and:    case en_or:     case en_xor:
	case en_asl:
	case en_shl:    case en_shlu:
	case en_shr:	case en_shru:
	case en_asr:	case en_asrshu:
	case en_feq:    case en_fne:
	case en_flt:    case en_fle:
	case en_fgt:    case en_fge:
	case en_eq:     case en_ne:
	case en_lt:     case en_le:
	case en_gt:     case en_ge:
	case en_ult:	case en_ule:
	case en_ugt:	case en_uge:
	case en_land:   case en_lor:
	case en_asadd:  case en_assub:
	case en_asmul:  case en_asmulu:
	case en_asdiv:	case en_asdivu:
	case en_asmod:  case en_asmodu: case en_asand:
	case en_asor:   case en_asxor:	case en_aslsh:
	case en_asrsh:
		siz0 = GetNaturalSize(node->p[0]);
		siz1 = GetNaturalSize(node->p[1]);
		if( siz1 > siz0 )
			return siz1;
		else
			return siz0;
	case en_void:   case en_cond:
		return GetNaturalSize(node->p[1]);
	case en_bchk:
		return (GetNaturalSize(node->p[0]));
	case en_chk:
		return 8;
	case en_q2i:
	case en_t2i:
		return (sizeOfWord);
	case en_i2d:
		return (sizeOfWord);
	case en_i2t:
	case en_d2t:
		return (sizeOfFPT);
	case en_i2q:
	case en_d2q:
	case en_t2q:
		return (sizeOfFPQ);
	default:
		printf("DIAG - natural size error %d.\n", node->nodetype);
		break;
	}
	return 0;
}


static void GenerateCmp(ENODE *node, int op, int label, unsigned int prediction)
{
	Enter("GenCmp");
	GenerateCmp(node, op, label, 0, prediction);
	Leave("GenCmp",0);
}

//
// Generate a jump to label if the node passed evaluates to
// a true condition.
//
void GenerateTrueJump(ENODE *node, int label, unsigned int prediction)
{ 
	Operand  *ap1;
	int    siz1;

	if( node == 0 )
		return;
	switch( node->nodetype )
	{
	case en_bchk:	break;
	case en_eq:	GenerateCmp(node, op_eq, label, prediction); break;
	case en_ne: GenerateCmp(node, op_ne, label, prediction); break;
	case en_lt: GenerateCmp(node, op_lt, label, prediction); break;
	case en_le:	GenerateCmp(node, op_le, label, prediction); break;
	case en_gt: GenerateCmp(node, op_gt, label, prediction); break;
	case en_ge: GenerateCmp(node, op_ge, label, prediction); break;
	case en_ult: GenerateCmp(node, op_ltu, label, prediction); break;
	case en_ule: GenerateCmp(node, op_leu, label, prediction); break;
	case en_ugt: GenerateCmp(node, op_gtu, label, prediction); break;
	case en_uge: GenerateCmp(node, op_geu, label, prediction); break;
	case en_feq: GenerateCmp(node, op_feq, label, prediction); break;
	case en_fne: GenerateCmp(node, op_fne, label, prediction); break;
	case en_flt: GenerateCmp(node, op_flt, label, prediction); break;
	case en_fle: GenerateCmp(node, op_fle, label, prediction); break;
	case en_fgt: GenerateCmp(node, op_fgt, label, prediction); break;
	case en_fge: GenerateCmp(node, op_fge, label, prediction); break;
	case en_veq: GenerateCmp(node, op_vseq, label, prediction); break;
	case en_vne: GenerateCmp(node, op_vsne, label, prediction); break;
	case en_vlt: GenerateCmp(node, op_vslt, label, prediction); break;
	case en_vle: GenerateCmp(node, op_vsle, label, prediction); break;
	case en_vgt: GenerateCmp(node, op_vsgt, label, prediction); break;
	case en_vge: GenerateCmp(node, op_vsge, label, prediction); break;
	case en_lor:
		GenerateTrueJump(node->p[0],label,prediction);
		GenerateTrueJump(node->p[1],label,prediction);
		break;
	default:
		siz1 = GetNaturalSize(node);
		ap1 = GenerateExpression(node,F_REG|F_FPREG,siz1);
		//                        GenerateDiadic(op_tst,siz1,ap1,0);
		ReleaseTempRegister(ap1);
		if (ap1->mode == am_fpreg)
			GenerateTriadic(op_fbne, 0, ap1, makefpreg(0), make_label(label));
		else
			GenerateTriadic(op_bne,0,ap1,makereg(0),make_label(label));
		break;
	}
}

//
// Generate code to execute a jump to label if the expression
// passed is false.
//
void GenerateFalseJump(ENODE *node,int label, unsigned int prediction)
{
	Operand *ap;
	int siz1;
	int lab0;

	if( node == (ENODE *)NULL )
		return;
	switch( node->nodetype )
	{
	case en_bchk:	break;
	case en_eq:	GenerateCmp(node, op_ne, label, prediction); break;
	case en_ne: GenerateCmp(node, op_eq, label, prediction); break;
	case en_lt: GenerateCmp(node, op_ge, label, prediction); break;
	case en_le: GenerateCmp(node, op_gt, label, prediction); break;
	case en_gt: GenerateCmp(node, op_le, label, prediction); break;
	case en_ge: GenerateCmp(node, op_lt, label, prediction); break;
	case en_ult: GenerateCmp(node, op_geu, label, prediction); break;
	case en_ule: GenerateCmp(node, op_gtu, label, prediction); break;
	case en_ugt: GenerateCmp(node, op_leu, label, prediction); break;
	case en_uge: GenerateCmp(node, op_ltu, label, prediction); break;
	case en_feq: GenerateCmp(node, op_fne, label, prediction); break;
	case en_fne: GenerateCmp(node, op_feq, label, prediction); break;
	case en_flt: GenerateCmp(node, op_fge, label, prediction); break;
	case en_fle: GenerateCmp(node, op_fgt, label, prediction); break;
	case en_fgt: GenerateCmp(node, op_fle, label, prediction); break;
	case en_fge: GenerateCmp(node, op_flt, label, prediction); break;
	case en_veq: GenerateCmp(node, op_vsne, label, prediction); break;
	case en_vne: GenerateCmp(node, op_vseq, label, prediction); break;
	case en_vlt: GenerateCmp(node, op_vsge, label, prediction); break;
	case en_vle: GenerateCmp(node, op_vsgt, label, prediction); break;
	case en_vgt: GenerateCmp(node, op_vsle, label, prediction); break;
	case en_vge: GenerateCmp(node, op_vslt, label, prediction); break;
	case en_land:
		GenerateFalseJump(node->p[0],label,prediction^1);
		GenerateFalseJump(node->p[1],label,prediction^1);
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
		ap = GenerateExpression(node,F_REG|F_FPREG,siz1);
		//                        GenerateDiadic(op_tst,siz1,ap,0);
		ReleaseTempRegister(ap);
		if (ap->mode==am_fpreg)
			GenerateTriadic(op_fbeq, 0, ap, makefpreg(0), make_label(label));
		else
			GenerateTriadic(op_beq,0,ap,makereg(0),make_label(label));
		break;
	}
}
