// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2017  Robert Finch, Waterloo
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

/*
 *	68000 C compiler
 *
 *	Copyright 1984, 1985, 1986 Matthew Brandt.
 *  all commercial rights reserved.
 *
 *	This compiler is intended as an instructive tool for personal use. Any
 *	use for profit without the written consent of the author is prohibited.
 *
 *	This compiler may be distributed freely for non-commercial use as long
 *	as this notice stays intact. Please forward any enhancements or questions
 *	to:
 *
 *		Matthew Brandt
 *		Box 920337
 *		Norcross, Ga 30092
 */

/*
 *      this module contains all of the code generation routines
 *      for evaluating expressions and conditions.
 */

int hook_predreg=15;

AMODE *GenerateExpression();            /* forward ParseSpecifieraration */
extern AMODE *GenExprRaptor64(ENODE *node);

extern AMODE *copy_addr(AMODE *);
extern AMODE *GenExpr(ENODE *node);
extern AMODE *GenerateFunctionCall(ENODE *node, int flags);
extern void GenLdi(AMODE*,AMODE *);
extern void GenerateCmp(ENODE *node, int op, int label, int predreg, unsigned int prediction);

void GenerateRaptor64Cmp(ENODE *node, int op, int label, int predreg);
void GenerateTable888Cmp(ENODE *node, int op, int label, int predreg);
void GenerateThorCmp(ENODE *node, int op, int label, int predreg);
void GenLoad(AMODE *ap3, AMODE *ap1, int ssize, int size);
void GenerateZeroExtend(AMODE *ap, int isize, int osize);
void GenerateSignExtend(AMODE *ap, int isize, int osize, int flags);

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


static char fpsize(AMODE *ap1)
{
	if (ap1->FloatSize)
		return (ap1->FloatSize);
	if (ap1->offset==nullptr)
		return ('d');
	if (ap1->offset->tp==nullptr)
		return ('d');
	switch(ap1->offset->tp->precision) {
	case 32:	return ('s');
	case 64:	return ('d');
	case 96:	return ('t');
	case 128:	return ('q');
	default:	return ('t');
	}
}

static char fsize(ENODE *n)
{
	switch(n->etype) {
	case bt_float:	return ('d');
	case bt_double:	return ('d');
	case bt_triple:	return ('t');
	case bt_quad:	return ('q');
	default:	return ('d');
	}
}

/*
 *      construct a reference node for an internal label number.
 */
AMODE *make_label(int lab)
{
	ENODE *lnode;
	AMODE *ap;

	lnode = allocEnode();
	lnode->nodetype = en_labcon;
	lnode->i = lab;
	ap = allocAmode();
	ap->mode = am_direct;
	ap->offset = lnode;
	ap->isUnsigned = TRUE;
	return ap;
}

AMODE *make_clabel(int lab)
{
	ENODE *lnode;
    AMODE *ap;

    lnode = allocEnode();
    lnode->nodetype = en_clabcon;
    lnode->i = lab;
	if (lab==-1)
		printf("-1\r\n");
    ap = allocAmode();
    ap->mode = am_direct;
    ap->offset = lnode;
	ap->isUnsigned = TRUE;
    return ap;
}

AMODE *make_string(char *s)
{
	ENODE *lnode;
	AMODE *ap;

	lnode = allocEnode();
	lnode->nodetype = en_nacon;
	lnode->sp = new std::string(s);
	ap = allocAmode();
	ap->mode = am_direct;
	ap->offset = lnode;
	return ap;
}

/*
 *      make a node to reference an immediate value i.
 */
AMODE *make_immed(int64_t i)
{
	AMODE *ap;
    ENODE *ep;
    ep = allocEnode();
    ep->nodetype = en_icon;
    ep->i = i;
    ap = allocAmode();
    ap->mode = am_immed;
    ap->offset = ep;
    return ap;
}

AMODE *make_indirect(int i)
{
	AMODE *ap;
    ENODE *ep;
    ep = allocEnode();
    ep->nodetype = en_uw_ref;
    ep->i = 0;
    ap = allocAmode();
	ap->mode = am_ind;
	ap->preg = i;
    ap->offset = 0;//ep;	//=0;
    return ap;
}

AMODE *make_indexed(int64_t o, int i)
{
	AMODE *ap;
    ENODE *ep;
    ep = allocEnode();
    ep->nodetype = en_icon;
    ep->i = o;
    ap = allocAmode();
	ap->mode = am_indx;
	ap->preg = i;
    ap->offset = ep;
    return ap;
}

/*
 *      make a direct reference to a node.
 */
AMODE *make_offset(ENODE *node)
{
	AMODE *ap;
	ap = allocAmode();
	ap->mode = am_direct;
	ap->offset = node;
	return ap;
}
        
AMODE *make_indx(ENODE *node, int rg)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_indx;
    ap->offset = node;
    ap->preg = rg;
    return ap;
}

AMODE *make_ainc(int rg)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_ainc;
	ap->preg = rg;
	return (ap);
}

AMODE *make_adec(int rg)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_adec;
	ap->preg = rg;
	return (ap);
}

AMODE *make_dreg(int rg)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_dreg;
	ap->preg = rg & 7;
	return (ap);
}

AMODE *make_areg(int rg)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_areg;
	ap->preg = rg & 7;
	return (ap);
}


void GenerateHint(int num)
{
	GenerateMonadic(op_hint,0,make_immed(num));
}

void GenerateComment(char *cm)
{
	GenerateMonadic(op_rem2,0,make_string(cm));
}


// ----------------------------------------------------------------------------
//      MakeLegalAmode will coerce the addressing mode in ap1 into a
//      mode that is satisfactory for the flag word.
// ----------------------------------------------------------------------------
void MakeLegalAmode(AMODE *ap,int flags, int size)
{
	AMODE *ap2;
	int64_t i;

//     Enter("MkLegalAmode");
	if (ap==(AMODE*)NULL) return;
//	if (flags & F_NOVALUE) return;
    if( ((flags & F_VOL) == 0) || ap->tempflag )
    {
        switch( ap->mode ) {
            case am_immed:
					i = ((ENODE *)(ap->offset))->i;
					if (flags & F_IMM8) {
						if (i < 256 && i >= 0)
							return;
					}
					else if (flags & F_IMM6) {
						if (i < 64 && i >= 0)
							return;
					}
					else if (flags & F_IMM0) {
						if (i==0)
							return;
					}
                    else if( flags & F_IMMED )
                        return;         /* mode ok */
                    break;
			case am_areg:
					if (flags & F_AREG)
						return;
					break;
			case am_dreg:
					if (flags & F_DREG)
						return;
					break;
            case am_fpreg:
                    if( flags & F_FPREG )
                        return;
                    break;
            case am_ind:
			case am_indx:
            case am_indx2: 
			case am_direct:
			case am_indx3:
                    if( flags & F_MEM )
                        return;
                    break;
            }
        }

		if (flags & F_AREG) {
            ReleaseTempRegister(ap);      /* maybe we can use it... */
			ap2 = GetTempAddressReg();
			if (ap->mode == am_ind || ap->mode==am_indx)
                GenLoad(ap,ap2,size,size);
			else if (ap->mode==am_immed) {
			    GenerateDiadic(op_move,'l',ap,ap2);
            }
			else {
				if (ap->mode==am_areg || ap->mode==am_dreg)
					GenerateDiadic(op_move,'l',ap,ap2);
				else
                    GenLoad(ap,ap2,size,size);
			}
            ap->mode = am_areg;
            ap->preg = ap2->preg;
            ap->deep = ap2->deep;
            ap->tempflag = 1;
            return;
		}
		if (flags & F_DREG) {
            ReleaseTempRegister(ap);      /* maybe we can use it... */
			ap2 = GetTempDataReg();
			if (ap->mode == am_ind || ap->mode==am_indx)
                GenLoad(ap,ap2,size,size);
			else if (ap->mode==am_immed) {
			    GenerateDiadic(op_move,'l',ap,ap2);
            }
			else {
				if (ap->mode==am_areg || ap->mode==am_dreg)
					GenerateDiadic(op_move,'l',ap,ap2);
				else
                    GenLoad(ap,ap2,size,size);
			}
            ap->mode = am_dreg;
            ap->preg = ap2->preg;
            ap->deep = ap2->deep;
            ap->tempflag = 1;
            return;
		}
		// Here we wanted the mode to be non-register (memory/immed)
		// Should fix the following to place the result in memory and
		// not a register.
        if( size == 1 )
		{
			ReleaseTempRegister(ap);
			ap2 = GetTempDataReg();
			GenerateDiadic(op_move,'l',ap,ap2);
			if (ap->isUnsigned)
				GenerateDiadic(op_and,'l',make_immed(255),ap2);
			else {
				GenerateDiadic(op_ext,'w',ap2,ap2);
			}
			ap->mode = ap2->mode;
			ap->preg = ap2->preg;
			ap->deep = ap2->deep;
			size = 2;
        }
        ap2 = GetTempDataReg();
		switch(ap->mode) {
		case am_ind:
		case am_indx:
            GenLoad(ap2,ap,size,size);
			break;
		case am_immed:
			GenerateDiadic(op_move,'l',ap,ap2);
			break;
		case am_areg:
		case am_dreg:
			GenerateDiadic(op_move,'l',ap2,ap);
			break;
		default:
            GenLoad(ap2,ap,size,size);
		}
    ap->mode = am_dreg;
    ap->preg = ap2->preg;
    ap->deep = ap2->deep;
    ap->tempflag = 1;
//     Leave("MkLegalAmode",0);
}

void GenLoad(AMODE *ap3, AMODE *ap1, int ssize, int size)
{
    if (ap3->isUnsigned) {
        switch(size) {
        case 1:	GenerateDiadic(op_move,'b',ap3,ap1); break;
        case 2:	GenerateDiadic(op_move,'w',ap3,ap1); break;
        case 4:	GenerateDiadic(op_move,'l',ap3,ap1); break;
        }
    }
    else {
        switch(size) {
        case 1:	GenerateDiadic(op_move,'b',ap3,ap1); break;
        case 2:	GenerateDiadic(op_move,'w',ap3,ap1); break;
        case 4:	GenerateDiadic(op_move,'l',ap3,ap1); break;
        }
    }
}

void GenStore(AMODE *ap1, AMODE *ap3, int size)
{
	switch(size) {
	case 1: GenerateDiadic(op_move,'b',ap1,ap3); break;
	case 2: GenerateDiadic(op_move,'w',ap1,ap3); break;
	case 4: GenerateDiadic(op_move,'l',ap1,ap3); break;
	}
}

/*
 *      if isize is not equal to osize then the operand ap will be
 *      loaded into a register (if not already) and if osize is
 *      greater than isize it will be extended to match.
 */
void GenerateSignExtend(AMODE *ap, int isize, int osize, int flags)
{    
	AMODE *ap1;

	if( isize == osize )
        return;
	if (ap->isUnsigned)
		return;
    if(ap->mode != am_dreg && ap->mode != am_areg && ap->mode != am_fpreg) {
		ap1 = GetTempDataReg();
		GenLoad(ap1,ap,isize,isize);
		switch( isize )
		{
		case 1:	GenerateMonadic(op_ext,'w',ap1);
		case 2:	GenerateMonadic(op_ext,'l',ap1); break;
		}
		GenStore(ap1,ap,osize);
		ReleaseTempRegister(ap1);
		return;
        //MakeLegalAmode(ap,flags & (F_REG|F_FPREG),isize);
	}
	if (ap->mode != am_dreg) {
		ap1 = GetTempDataReg();
		GenerateDiadic(op_move,'l',ap,ap1);
		switch( isize )
		{
		case 1:	GenerateMonadic(op_ext,'w',ap1);
		case 2:	GenerateMonadic(op_ext,'l',ap1); break;
		}
		GenerateDiadic(op_move,'l',ap1,ap);
		return;
	}
	switch( isize )
	{
	case 1:	GenerateMonadic(op_ext,'w',ap);
	case 2:	GenerateMonadic(op_ext,'l',ap); break;
	}
}

void GenerateZeroExtend(AMODE *ap, int isize, int osize)
{    
    if(ap->mode != am_dreg && ap->mode != am_areg)
        MakeLegalAmode(ap,F_DREG,isize);
	switch( osize )
	{
	case 1:	GenerateDiadic(op_and,'l',make_immed(0xFF),ap); break;
	case 2:	GenerateDiadic(op_and,'l',make_immed(0xFFFF),ap); break;
    }
}

/*
 *      return true if the node passed can be generated as a short
 *      offset.
 */
int isshort(ENODE *node)
{
	return node->nodetype == en_icon &&
        (node->i >= -32768 && node->i <= 32767);
}

/*
 *      return true if the node passed can be evaluated as a byte
 *      offset.
 */
int isbyte(ENODE *node)
{
	return node->nodetype == en_icon &&
       (-128 <= node->i && node->i <= 127);
}

int ischar(ENODE *node)
{
	return node->nodetype == en_icon &&
        (node->i >= -32768 && node->i <= 32767);
}

// ----------------------------------------------------------------------------
// Generate code to evaluate an index node (^+) and return the addressing mode
// of the result. This routine takes no flags since it always returns either
// am_ind or am_indx.
//
// No reason to ReleaseTempReg() because the registers used are transported
// forward.
// ----------------------------------------------------------------------------
AMODE *GenerateIndex(ENODE *node)
{       
	AMODE *ap1, *ap2;
	
    if( (node->p[0]->nodetype == en_tempref || node->p[0]->nodetype==en_regvar)
    	 && (node->p[1]->nodetype == en_tempref || node->p[1]->nodetype==en_regvar))
    {       /* both nodes are registers */
    	// Don't need to free ap2 here. It is included in ap1.
		GenerateHint(8);
        ap1 = GenerateExpression(node->p[0],F_AREG,sizeOfWord);
        ap2 = GenerateExpression(node->p[1],F_AREG,sizeOfWord);
		GenerateHint(9);
        ap1->mode = am_indx2;
        ap1->sreg = ap2->preg;
		ap1->deep2 = ap2->deep2;
		ap1->offset = makeinode(en_icon,0);
		ap1->scale = node->scale;
        return (ap1);
    }
	GenerateHint(8);
    ap1 = GenerateExpression(node->p[0],F_AREG | F_DREG | F_IMMED,sizeOfWord);
    if( ap1->mode == am_immed )
    {
		ap2 = GenerateExpression(node->p[1],F_AREG,sizeOfWord);
		GenerateHint(9);
		ap2->mode = am_indx;
		ap2->offset = ap1->offset;
		ap2->isUnsigned = ap1->isUnsigned;
		return (ap2);
    }
    ap2 = GenerateExpression(node->p[1],F_ALL,sizeOfWord);   /* get right op */
	GenerateHint(9);
    if( ap2->mode == am_immed && ap1->mode == am_areg ) /* make am_indx */
    {
        ap2->mode = am_indx;
        ap2->preg = ap1->preg;
        ap2->deep = ap1->deep;
        return ap2;
    }
	if (ap2->mode == am_ind && (ap1->mode==am_areg || ap1->mode==am_dreg)) {
        ap2->mode = am_indx2;
        ap2->sreg = ap1->preg;
		ap2->deep2 = ap1->deep;
        return ap2;
	}
	if (ap2->mode == am_direct && (ap1->mode==am_areg||ap1->mode==am_dreg)) {
        ap2->mode = am_indx;
        ap2->preg = ap1->preg;
        ap2->deep = ap1->deep;
        return ap2;
    }
	// ap1->mode must be F_REG
	MakeLegalAmode(ap2,F_DREG,sizeOfWord);
    ap1->mode = am_indx2;            /* make indexed */
	ap1->sreg = ap2->preg;
	ap1->deep2 = ap2->deep;
	ap1->offset = makeinode(en_icon,0);
	ap1->scale = node->scale;
    return ap1;                     /* return indexed */
}

long GetReferenceSize(ENODE *node)
{
    switch( node->nodetype )        /* get load size */
    {
    case en_b_ref:
    case en_ub_ref:
    case en_bfieldref:
    case en_ubfieldref:
            return 1;
	case en_c_ref:
	case en_uc_ref:
	case en_cfieldref:
	case en_ucfieldref:
			return 2;
	case en_ref32:
	case en_ref32u:
			return 4;
	case en_h_ref:
	case en_uh_ref:
	case en_hfieldref:
	case en_uhfieldref:
			return sizeOfWord/2;
    case en_w_ref:
	case en_uw_ref:
    case en_wfieldref:
	case en_uwfieldref:
            return sizeOfWord;
	case en_tempref:
	case en_fpregvar:
	case en_regvar:
            return sizeOfWord;
	case en_dbl_ref:
            return sizeOfFPD;
	case en_quad_ref:
			return sizeOfFPQ;
	case en_flt_ref:
			return sizeOfFPD;
    case en_triple_ref:
            return sizeOfFPT;
	case en_struct_ref:
            return sizeOfPtr;
	case en_vector_ref:
			return 512;
//			return node->esize;
    }
	return 8;
}

//
//  Return the addressing mode of a dereferenced node.
//
AMODE *GenerateDereference(ENODE *node,int flags,int size, int su)
{    
	AMODE *ap1;
    int siz1;

    Enter("Genderef");
	siz1 = GetReferenceSize(node);
	// When dereferencing a struct or union return a pointer to the struct or
	// union.
//	if (node->tp->type==bt_struct || node->tp->type==bt_union) {
//        return GenerateExpression(node,F_REG|F_MEM,size);
//    }
    if( node->p[0]->nodetype == en_add )
    {
//        ap2 = GetTempRegister();
        ap1 = GenerateIndex(node->p[0]);
//        GenerateTriadic(op_add,0,ap2,makereg(ap1->preg),makereg(regGP));
		ap1->isUnsigned = !su;//node->isUnsigned;
		// *** may have to fix for stackseg
		ap1->segment = dataseg;
//		ap2->mode = ap1->mode;
//		ap2->segment = dataseg;
//		ap2->offset = ap1->offset;
//		ReleaseTempRegister(ap1);
		if (!node->isUnsigned)
			GenerateSignExtend(ap1,siz1,size,flags);
		else
		    MakeLegalAmode(ap1,flags,siz1);
        MakeLegalAmode(ap1,flags,size);
		goto xit;
    }
    else if( node->p[0]->nodetype == en_autocon )
    {
        ap1 = allocAmode();
        ap1->mode = am_indx;
        ap1->preg = regBP;
		ap1->segment = stackseg;
        ap1->offset = makeinode(en_icon,node->p[0]->i);
		ap1->offset->sym = node->p[0]->sym;
		ap1->isUnsigned = !su;
		if (!node->isUnsigned)
	        GenerateSignExtend(ap1,siz1,size,flags);
		else
		    MakeLegalAmode(ap1,flags,siz1);
        MakeLegalAmode(ap1,flags,size);
		goto xit;
    }
    else if( node->p[0]->nodetype == en_classcon )
    {
        ap1 = allocAmode();
        ap1->mode = am_indx;
        ap1->preg = regCLP;
		ap1->segment = dataseg;
        ap1->offset = makeinode(en_icon,node->p[0]->i);
		ap1->offset->sym = node->p[0]->sym;
		ap1->isUnsigned = !su;
		if (!node->isUnsigned)
	        GenerateSignExtend(ap1,siz1,size,flags);
		else
		    MakeLegalAmode(ap1,flags,siz1);
        MakeLegalAmode(ap1,flags,size);
		goto xit;
    }
    else if( node->p[0]->nodetype == en_autofcon )
    {
        ap1 = allocAmode();
        ap1->mode = am_indx;
        ap1->preg = regBP;
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
		ap1->type = stddouble.GetIndex();
//	    MakeLegalAmode(ap1,flags,siz1);
        MakeLegalAmode(ap1,flags,size);
		goto xit;
    }
    else if(( node->p[0]->nodetype == en_labcon || node->p[0]->nodetype==en_nacon ) && use_gp)
    {
        ap1 = allocAmode();
        ap1->mode = am_indx;
        ap1->preg = regGP;
		ap1->segment = dataseg;
        ap1->offset = node->p[0];//makeinode(en_icon,node->p[0]->i);
		ap1->isUnsigned = !su;
		if (!node->isUnsigned)
	        GenerateSignExtend(ap1,siz1,size,flags);
		else
		    MakeLegalAmode(ap1,flags,siz1);
        ap1->isVolatile = node->isVolatile;
        MakeLegalAmode(ap1,flags,size);
		goto xit;
    }
	else if (node->p[0]->nodetype == en_regvar) {
        ap1 = allocAmode();
		// For parameters we want Rn, for others [Rn]
		// This seems like an error earlier in the compiler
		// See setting val_flag in ParseExpressions
		if (node->p[0]->i < 8) {
			ap1->mode = am_dreg;
			ap1->preg = node->p[0]->i & 7;
		}
		else if (node->p[0]->i < 16)
			ap1->mode = am_ind;
		else
			ap1->mode = am_ind;
		//ap1->mode = node->p[0]->i < 18 ? am_ind : am_reg;
//		ap1->mode = node->p[0]->tp->val_flag ? am_reg : am_ind;
        MakeLegalAmode(ap1,flags,size);
	    Leave("Genderef",3);
        return ap1;
	}
	else if (node->p[0]->nodetype == en_fpregvar) {
		//error(ERR_DEREF);
        ap1 = allocAmode();
		ap1->mode = node->p[0]->i < 18 ? am_ind : am_fpreg;
		ap1->preg = node->p[0]->i;
		ap1->type = stddouble.GetIndex();
        MakeLegalAmode(ap1,flags,size);
	    Leave("Genderef",3);
        return ap1;
	}
    ap1 = GenerateExpression(node->p[0],F_AREG | F_IMMED,4); /* generate address */
    if( ap1->mode == am_areg || ap1->mode==am_fpreg)
    {
//        ap1->mode = am_ind;
          if (use_gp) {
              ap1->mode = am_indx;
              ap1->sreg = regGP;
          }
          else
             ap1->mode = am_ind;
		  if (node->p[0]->constflag==TRUE)
			  ap1->offset = node->p[0];
		  else
			ap1->offset = nullptr;	// ****
		ap1->isUnsigned = !su;
		if (!node->isUnsigned)
	        GenerateSignExtend(ap1,siz1,size,flags);
		else
		    MakeLegalAmode(ap1,flags,siz1);
        ap1->isVolatile = node->isVolatile;
        MakeLegalAmode(ap1,flags,size);
		goto xit;
    }
    if( ap1->mode == am_fpreg )
    {
//        ap1->mode = am_ind;
          if (use_gp) {
              ap1->mode = am_indx;
              ap1->sreg = regGP;
          }
          else
             ap1->mode = am_ind;
		ap1->offset = 0;	// ****
		ap1->isUnsigned = !su;
		if (!node->isUnsigned)
	        GenerateSignExtend(ap1,siz1,size,flags);
		else
		    MakeLegalAmode(ap1,flags,siz1);
        MakeLegalAmode(ap1,flags,size);
		goto xit;
    }
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
        ap1->mode = am_direct;
	    ap1->isUnsigned = !su;
    }
//    ap1->offset = makeinode(en_icon,node->p[0]->i);
    ap1->isUnsigned = !su;
	if (!node->isUnsigned)
	    GenerateSignExtend(ap1,siz1,size,flags);
	else
		MakeLegalAmode(ap1,flags,siz1);
    ap1->isVolatile = node->isVolatile;
    MakeLegalAmode(ap1,flags,size);
xit:
    Leave("Genderef",0);
    return ap1;
}

//
// Generate code to evaluate a unary minus or complement.
//
AMODE *GenerateUnary(ENODE *node,int flags, int size, int op)
{
	AMODE *ap;

    ap = GenerateExpression(node->p[0],F_DREG,size);
	switch(size) {
	case 1:	GenerateMonadic(op,'b',ap); break;
	case 2:	GenerateMonadic(op,'w',ap); break;
	case 4:	GenerateMonadic(op,'l',ap); break;
	}
    MakeLegalAmode(ap,flags,size);
    return (ap);
}

// Generate code for a binary expression

AMODE *GenerateBinary(ENODE *node,int flags, int size, int op)
{
	AMODE *ap1, *ap2, *ap3, *ap4;
	
	if (op==op_fadd || op==op_fsub || op==op_fmul || op==op_fdiv ||
        op==op_fdadd || op==op_fdsub || op==op_fdmul || op==op_fddiv ||
	    op==op_fsadd || op==op_fssub || op==op_fsmul || op==op_fsdiv)
	{
   		ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0],F_REG,size);
		ap2 = GenerateExpression(node->p[1],F_REG,size);
		// Generate a convert operation ?
		if (fpsize(ap1) != fpsize(ap2)) {
			if (fpsize(ap2)=='s')
				GenerateDiadic(op_fcvtsq, 0, ap2, ap2);
		}
	    GenerateTriadic(op,fpsize(ap1),ap3,ap1,ap2);
	}
	else {
		ap1 = GenerateExpression(node->p[0],F_AREG|F_DREG,size);
		ap2 = GenerateExpression(node->p[1],F_AREG|F_DREG|F_IMMED,size);
		if (ap1->mode==am_areg && ap2->mode==am_areg)
			GenerateDiadic(op,'l',ap2,ap1);
		else if (ap1->mode==am_dreg && ap2->mode==am_dreg)
			GenerateDiadic(op,'l',ap2,ap1);
		else if (ap2->mode==am_immed)
			GenerateDiadic(op,'l',ap2,ap1);
		else {
			if (ap1->mode == am_areg)
				ap3 = GetTempAddressReg();
			else
				ap3 = GetTempDataReg();
			GenerateDiadic(op_move,'l',ap2,ap3);
			ReleaseTempReg(ap3);
			ReleaseTempReg(ap2);
			GenerateDiadic(op,'l',ap2,ap1);
			MakeLegalAmode(ap1,flags,size);
			return (ap1);
		}
	}
	if (ap2)
		ReleaseTempReg(ap2);
    MakeLegalAmode(ap1,flags,size);
    return (ap1);
}

/*
 *      generate code to evaluate a mod operator or a divide
 *      operator.
 */
AMODE *GenerateModDiv(ENODE *node,int flags,int size, int op)
{
	AMODE *ap1, *ap2, *ap3;

	if( node->p[0]->nodetype == en_icon ) //???
		swap_nodes(node);
	if (op==op_fdiv) {
		ap3 = GetTempRegister();
		ap1 = GenerateExpression(node->p[0],F_REG,8);
		ap2 = GenerateExpression(node->p[1],F_REG,8);
	}
	else {
		ap3 = GetTempDataReg();
		ap1 = GenerateExpression(node->p[0],F_DREG,4);
		ap2 = GenerateExpression(node->p[1],F_DREG | F_IMMED,4);
		GenerateDiadic(op_move,'l',ap2,make_adec(7));
		GenerateDiadic(op_move,'l',ap1,make_adec(7));
		switch(op) {
		case op_div:	GenerateMonadic(op_jsr,0,make_string("_div")); break;
		case op_divu:	GenerateMonadic(op_jsr,0,make_string("_divu")); break;
		case op_mod:	GenerateMonadic(op_jsr,0,make_string("_mod")); break;
		case op_modu:	GenerateMonadic(op_jsr,0,make_string("_modu")); break;
		}
		GenerateDiadic(op_add,'l',make_immed(8),make_areg(7));
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		GenerateDiadic(op_move,'l',make_dreg(0),ap3);
		MakeLegalAmode(ap3,flags,2);
		return (ap3);
	}
	GenerateTriadic(op,0,ap3,ap1,ap2);
//    GenerateDiadic(op_ext,0,ap3,0);
  MakeLegalAmode(ap3,flags,2);
  ReleaseTempReg(ap2);
  ReleaseTempReg(ap1);
  return (ap3);
}

/*
 *      exchange the two operands in a node.
 */
void swap_nodes(ENODE *node)
{
	ENODE *temp;
    temp = node->p[0];
    node->p[0] = node->p[1];
    node->p[1] = temp;
}

/*
 *      generate code to evaluate a multiply node. 
 */
AMODE *GenerateMultiply(ENODE *node, int flags, int size, int op)
{       
	AMODE *ap1, *ap2, *ap3;
  Enter("Genmul");
    if( node->p[0]->nodetype == en_icon )
        swap_nodes(node);
    if (op==op_fmul) {
        ap3 = GetTempRegister();
        ap1 = GenerateExpression(node->p[0],F_REG,8);
        ap2 = GenerateExpression(node->p[1],F_REG,8);
    }
    else {
        ap3 = GetTempDataReg();
        ap1 = GenerateExpression(node->p[0],F_DREG,sizeOfWord);
        ap2 = GenerateExpression(node->p[1],F_DREG | F_IMMED,sizeOfWord);
		GenerateDiadic(op_move,'l',ap2,make_adec(7));
		GenerateDiadic(op_move,'l',ap1,make_adec(7));
		switch(op) {
		case op_mul:	GenerateMonadic(op_jsr,0,make_string("_mul"));
		case op_mulu:	GenerateMonadic(op_jsr,0,make_string("_mulu"));
		}
		GenerateDiadic(op_add,'l',make_immed(8),make_areg(7));
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap1);
		GenerateDiadic(op_move,'l',make_dreg(0),ap3);
		MakeLegalAmode(ap3,flags,2);
		return (ap3);
    }
	GenerateTriadic(op,0,ap3,ap1,ap2);
	ReleaseTempReg(ap2);
	ReleaseTempReg(ap1);
	MakeLegalAmode(ap3,flags,2);
	Leave("Genmul",0);
	return ap3;
}

//
// Generate code to evaluate a condition operator node (?:)
//
AMODE *GenerateHook(ENODE *node,int flags, int size)
{
	AMODE *ap1, *ap2;
    int false_label, end_label;
	struct ocode *ip1;
	int n1;

    false_label = nextlabel++;
    end_label = nextlabel++;
    flags = (flags & (F_DREG|F_AREG)) | F_VOL;
	ip1 = peep_tail;
	ap2 = GenerateExpression(node->p[1]->p[1],flags,size);
	n1 = PeepCount(ip1);
	if (opt_nocgo)
		n1 = 9999;
	if (n1 > 4) {
		peep_tail = ip1;
		peep_tail->fwd = nullptr;
	}
    GenerateFalseJump(node->p[0],false_label,0);
    node = node->p[1];
    ap1 = GenerateExpression(node->p[0],flags,size);
	if (n1 > 4)
		GenerateMonadic(op_bra,0,make_clabel(end_label));
	else {
		if( !equal_address(ap1,ap2) )
		{
			GenerateMonadic(op_hint,0,make_immed(2));
			GenerateDiadic(op_move,'l',ap1,ap2);
		}
	}
    GenerateLabel(false_label);
	if (n1 > 4) {
		ap2 = GenerateExpression(node->p[1],flags,size);
		if( !equal_address(ap1,ap2) )
		{
			GenerateMonadic(op_hint,0,make_immed(2));
			GenerateDiadic(op_move,'l',ap2,ap1);
		}
	}
	if (n1 > 4) {
		ReleaseTempReg(ap2);
		GenerateLabel(end_label);
		return (ap1);
	}
	else {
		ReleaseTempReg(ap1);
		GenerateLabel(end_label);
		return (ap2);
	}
}

void GenMemop(int op, AMODE *ap1, AMODE *ap2, int ssize)
{
	AMODE *ap3;

	if (ap1->type==stddouble.GetIndex()) {
     	ap3 = GetTempDataReg();
		GenLoad(ap3,ap1,ssize,ssize);
		GenerateTriadic(op,ap1->FloatSize,ap3,ap3,ap2);
		GenStore(ap3,ap1,ssize);
		ReleaseTempReg(ap3);
		return;
	}
   	ap3 = GetTempDataReg();
    GenLoad(ap3,ap1,ssize,ssize);
	GenerateDiadic(op,0,ap3,ap2);
	ReleaseTempReg(ap3);
}

AMODE *GenerateAssignAdd(ENODE *node,int flags, int size, int op)
{
	AMODE *ap1, *ap2;
    int ssize;
	bool negf = false;

    ssize = GetNaturalSize(node->p[0]);
    if( ssize > size )
            size = ssize;
    if (node->etype==bt_double || node->etype==bt_quad || node->etype==bt_float||node->etype==bt_triple) {
        ap1 = GenerateExpression(node->p[0],F_REG|F_MEM,ssize);
        ap2 = GenerateExpression(node->p[1],F_REG,size);
        if (op==op_add)
           op = op_fadd;
        else if (op==op_sub)
           op = op_fsub;
    }
    else {
        ap1 = GenerateExpression(node->p[0],F_ALL,ssize);
        ap2 = GenerateExpression(node->p[1],F_DREG | F_IMMED,size);
    }
	if (ap1->mode==am_dreg) {
	    GenerateDiadic(op,ssize,ap2,ap1);
	}
	// todo: check ssize
	else if (ap1->mode==am_areg) {
		if (ssize==1 || ssize=='b')
			printf("Illegal size\r\n");
	    GenerateDiadic(op,ssize,ap2,ap1);
	}
	else if (ap1->mode==am_fpreg) {
	    GenerateTriadic(op,fpsize(ap1),ap1,ap1,ap2);
	    ReleaseTempReg(ap2);
	    MakeLegalAmode(ap1,flags,size);
		return (ap1);
	}
	else {
		GenMemop(op, ap1, ap2, ssize);
	}
    ReleaseTempReg(ap2);
	if (ap1->type!=stddouble.GetIndex() && !ap1->isUnsigned)
		GenerateSignExtend(ap1,ssize,size,flags);
    MakeLegalAmode(ap1,flags,size);
    return (ap1);
}

AMODE *GenerateAssignLogic(ENODE *node,int flags, int size, int op)
{
	AMODE *ap1, *ap2, *ap3;
    int             ssize;
    ssize = GetNaturalSize(node->p[0]);
    if( ssize > size )
            size = ssize;
    ap1 = GenerateExpression(node->p[0],F_ALL,ssize);
    ap2 = GenerateExpression(node->p[1],F_DREG | F_IMMED,size);
	if (ap1->mode==am_dreg && ap2->mode==am_dreg)
	    GenerateDiadic(op,'l',ap2,ap1);
	else if (ap1->mode==am_areg && ap2->mode==am_areg)
	    GenerateDiadic(op,'l',ap2,ap1);
	else if (ap1->mode==am_dreg) {
		ap3 = GetTempDataReg();
		GenerateDiadic(op_move,'l',ap2,ap3);
	    GenerateDiadic(op,0,ap3,ap1);
		ReleaseTempReg(ap3);
	}
	else if (ap1->mode==am_areg) {
		ap3 = GetTempAddressReg();
		GenerateDiadic(op_move,'l',ap2,ap3);
	    GenerateDiadic(op,0,ap3,ap1);
		ReleaseTempReg(ap3);
	}
	else {
		GenMemop(op, ap1, ap2, ssize);
	}
    ReleaseTempRegister(ap2);
	if (!ap1->isUnsigned)
		GenerateSignExtend(ap1,ssize,size,flags);
    MakeLegalAmode(ap1,flags,size);
    return (ap1);
}

//
//      generate a *= node.
//
AMODE *GenerateAssignMultiply(ENODE *node,int flags, int size, int op)
{
	AMODE *ap1, *ap2;
    int             ssize;
    ssize = GetNaturalSize(node->p[0]);
    if( ssize > size )
            size = ssize;
    if (node->etype==bt_double || node->etype==bt_quad || node->etype==bt_float || node->etype==bt_triple) {
        ap1 = GenerateExpression(node->p[0],F_REG | F_MEM,ssize);
        ap2 = GenerateExpression(node->p[1],F_REG,size);
        op = op_fmul;
    }
    else {
        ap1 = GenerateExpression(node->p[0],F_ALL & ~F_IMMED,ssize);
        ap2 = GenerateExpression(node->p[1],F_DREG | F_IMMED,size);
    }
	switch(op) {
	case op_mul:
		if (size==8) {
			GenerateDiadic(op_move,'b',ap2,make_dreg(0));
			GenerateDiadic(op_move,'b',ap1,make_dreg(1));
			GenerateMonadic(op_ext,'w',make_dreg(0));
			GenerateMonadic(op_ext,'w',make_dreg(1));
			GenerateMonadic(op_ext,'l',make_dreg(0));
			GenerateMonadic(op_ext,'l',make_dreg(1));
			GenerateDiadic(op_move,'l',make_dreg(0),make_adec(7));
			GenerateDiadic(op_move,'l',make_dreg(1),make_adec(7));
			GenerateMonadic(op_jsr,0,make_string("_mul"));
			GenerateDiadic(op_adda,'l',make_immed(8),make_areg(7));
			GenerateDiadic(op_move,'b',make_dreg(0),ap1);
		}
		else if (size==16) {
			GenerateDiadic(op_move,'w',ap2,make_dreg(0));
			GenerateDiadic(op_move,'w',ap1,make_dreg(1));
			GenerateMonadic(op_ext,'l',make_dreg(0));
			GenerateMonadic(op_ext,'l',make_dreg(1));
			GenerateDiadic(op_move,'l',make_dreg(0),make_adec(7));
			GenerateDiadic(op_move,'l',make_dreg(1),make_adec(7));
			GenerateMonadic(op_jsr,0,make_string("_mul"));
			GenerateDiadic(op_adda,'l',make_immed(8),make_areg(7));
			GenerateDiadic(op_move,'w',make_dreg(0),ap1);
		}
		else {
			GenerateDiadic(op_move,'l',ap2,make_adec(7));
			GenerateDiadic(op_move,'l',ap1,make_adec(7));
			GenerateMonadic(op_jsr,0,make_string("_mul"));
			GenerateDiadic(op_adda,'l',make_immed(8),make_areg(7));
			GenerateDiadic(op_move,'l',make_dreg(0),ap1);
		}
		break;
	case op_mulu:
		if (size==8) {
			GenerateDiadic(op_move,'b',ap2,make_dreg(0));
			GenerateDiadic(op_move,'b',ap1,make_dreg(1));
			GenerateDiadic(op_and,'w',make_immed(255),make_dreg(0));
			GenerateDiadic(op_and,'w',make_immed(255),make_dreg(1));
			GenerateDiadic(op_mulu,0,make_dreg(1),make_dreg(0));
			GenerateDiadic(op_move,'b',make_dreg(0),ap1);
		}
		else if (size==16) {
			GenerateDiadic(op_move,'w',ap2,make_dreg(0));
			GenerateDiadic(op_move,'w',ap1,make_dreg(1));
			GenerateDiadic(op_mulu,0,make_dreg(1),make_dreg(0));
			GenerateDiadic(op_move,'w',make_dreg(0),ap1);
		}
		else {
			GenerateDiadic(op_move,'l',ap2,make_adec(7));
			GenerateDiadic(op_move,'l',ap1,make_adec(7));
			GenerateMonadic(op_jsr,0,make_string("_mulu"));
			GenerateDiadic(op_adda,'l',make_immed(8),make_areg(7));
			GenerateDiadic(op_move,'l',make_dreg(0),ap1);
		}
		break;
	}
    ReleaseTempReg(ap2);
    GenerateSignExtend(ap1,ssize,size,flags);
    MakeLegalAmode(ap1,flags,size);
    return (ap1);
}

/*
 *      generate /= and %= nodes.
 */
AMODE *GenerateAssignModiv(ENODE *node,int flags,int size,int op)
{
	AMODE *ap1, *ap2, *ap3;
    int             siz1;
    int isFP;
 
    siz1 = GetNaturalSize(node->p[0]);
    isFP = node->etype==bt_double || node->etype==bt_float || node->etype==bt_triple || node->etype==bt_quad;
    if (isFP) {
        if (op==op_div || op==op_divu)
           op = op_fdiv;
        ap1 = GenerateExpression(node->p[0],F_REG,siz1);
        ap2 = GenerateExpression(node->p[1],F_REG,size);
		GenerateTriadic(op,siz1==4?'s':siz1==8?'d':siz1==12?'t':siz1==16?'q':'d',ap1,ap1,ap2);
	    ReleaseTempReg(ap2);
		MakeLegalAmode(ap1,flags,size);
	    return ap1;
//        else if (op==op_mod || op==op_modu)
//           op = op_fdmod;
    }
    else {
        ap1 = GetTempDataReg();
        ap2 = GenerateExpression(node->p[0],F_ALL & ~F_IMMED,siz1);
    }
	if (ap2->mode==am_dreg && ap2->preg != ap1->preg)
		GenerateDiadic(op_move,'l',ap2,ap1);
	else if (ap2->mode==am_fpreg && ap2->preg != ap1->preg)
		GenerateDiadic(op_move,'l',ap2,ap1);
	else
        GenLoad(ap1,ap2,siz1,siz1);
    //GenerateSignExtend(ap1,siz1,2,flags);
    if (isFP)
        ap3 = GenerateExpression(node->p[1],F_REG,8);
    else
        ap3 = GenerateExpression(node->p[1],F_DREG|F_IMMED,8);
	if (op==op_fdiv) {
		GenerateTriadic(op,siz1==4?'s':siz1==8?'d':siz1==12?'t':siz1==16?'q':'d',ap1,ap1,ap3);
	}
	else
		GenerateTriadic(op,0,ap1,ap1,ap3);
	switch(op) {
	case op_mod:	
		GenerateDiadic(op_move,'l',ap1,make_adec(7));
		GenerateDiadic(op_move,'l',ap2,make_adec(7));
		GenerateMonadic(op_jsr,0,make_string("_mod"));
		GenerateDiadic(op_adda,'l',make_immed(8),make_areg(7));
		GenerateDiadic(op_move,'l',make_dreg(0),ap1);
		break;
	case op_modu:	
		GenerateDiadic(op_move,'l',ap1,make_adec(7));
		GenerateDiadic(op_move,'l',ap2,make_adec(7));
		GenerateMonadic(op_jsr,0,make_string("_modu"));
		GenerateDiadic(op_adda,'l',make_immed(8),make_areg(7));
		GenerateDiadic(op_move,'l',make_dreg(0),ap1);
		break;
	case op_div:	
		GenerateDiadic(op_move,'l',ap1,make_adec(7));
		GenerateDiadic(op_move,'l',ap2,make_adec(7));
		GenerateMonadic(op_jsr,0,make_string("_div"));
		GenerateDiadic(op_adda,'l',make_immed(8),make_areg(7));
		GenerateDiadic(op_move,'l',make_dreg(0),ap1);
		break;
	case op_divu:	
		GenerateDiadic(op_move,'l',ap1,make_adec(7));
		GenerateDiadic(op_move,'l',ap2,make_adec(7));
		GenerateMonadic(op_jsr,0,make_string("_divu"));
		GenerateDiadic(op_adda,'l',make_immed(8),make_areg(7));
		GenerateDiadic(op_move,'l',make_dreg(0),ap1);
		break;
	}
    ReleaseTempReg(ap3);
    ReleaseTempReg(ap2);
	if (!isFP)
		MakeLegalAmode(ap1,flags,size);
    return (ap1);
}

// The problem is there are two trees of information. The LHS and the RHS.
// The RHS is a tree of nodes containing expressions and data to load.
// The nodes in the RHS have to be matched up against the structure elements
// of the target LHS.

// This little bit of code is dead code. But it might be useful to match
// the expression trees at some point.

ENODE *BuildEnodeTree(TYP *tp)
{
	ENODE *ep1, *ep2, *ep3;
	SYM *thead, *first;

	first = thead = SYM::GetPtr(tp->lst.GetHead());
	ep1 = ep2 = nullptr;
	while (thead) {
		if (thead->tp->IsStructType()) {
			ep3 = BuildEnodeTree(thead->tp);
		}
		else
			ep3 = nullptr;
		ep1 = makenode(en_void, ep2, ep1);
		ep1->SetType(thead->tp);
		ep1->p[2] = ep3;
		thead = SYM::GetPtr(thead->next);
	}
	return ep1;
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

AMODE *GenerateAssign(ENODE *node, int flags, int size);

// Generate an assignment to a structure type. The type passed must be a
// structure type.

void GenerateStructAssign(TYP *tp, int64_t offset, ENODE *ep, AMODE *base)
{
	SYM *thead, *first;
	AMODE *ap1, *ap2;
	int64_t offset2;

	first = thead = SYM::GetPtr(tp->lst.GetHead());
	ep = ep->p[0];
	while (thead) {
		if (ep == nullptr)
			break;
		if (thead->tp->IsAggregateType()) {
			if (ep->p[2])
				GenerateStructAssign(thead->tp, offset, ep->p[2], base);
		}
		else {
			ap2 = nullptr;
			if (ep->p[2]==nullptr)
				break;
			ap1 = GenerateExpression(ep->p[2],F_DREG,thead->tp->size);
			if (ap1->mode==am_immed) {
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
			case 1:	GenerateDiadic(op_move,'b',ap2,make_indexed(offset,base->preg)); break;
			case 2:	GenerateDiadic(op_move,'w',ap2,make_indexed(offset,base->preg)); break;
			case 4:	GenerateDiadic(op_move,'l',ap2,make_indexed(offset,base->preg)); break;
			case 512:	GenerateDiadic(op_sv,0,ap2,make_indexed(offset,base->preg)); break;
			default:	GenerateDiadic(op_move,'l',ap2,make_indexed(offset,base->preg)); break;
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


AMODE *GenerateAggregateAssign(ENODE *node1, ENODE *node2);

// Generate an assignment to an array.

void GenerateArrayAssign(TYP *tp, ENODE *node1, ENODE *node2, AMODE *base)
{
	ENODE *ep1;
	AMODE *ap1, *ap2;
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
			ap1 = GenerateExpression(ep1,F_DREG|F_IMMED,sizeOfWord);
			ap2 = GetTempRegister();
			if (ap1->mode==am_immed)
				GenLdi(ap2,ap1);
			else {
				if (ap1->offset)
					offset2 = ap1->offset->i;
				else
					offset2 = 0;
				GenerateDiadic(op_move,'l',ap1,ap2);
			}
			switch(tp->GetElementSize())
			{
			case 1:	GenerateDiadic(op_move,'b',ap2,make_indexed(offset,base->preg)); break;
			case 2:	GenerateDiadic(op_move,'w',ap2,make_indexed(offset,base->preg)); break;
			case 4:	GenerateDiadic(op_move,'l',ap2,make_indexed(offset,base->preg)); break;
			case 512:	GenerateDiadic(op_sv,0,ap2,make_indexed(offset,base->preg)); break;
			default:	GenerateDiadic(op_move,'l',ap2,make_indexed(offset,base->preg)); break;
			}
			offset += tp->GetElementSize();
			ReleaseTempReg(ap2);
			ReleaseTempReg(ap1);
			ep1 = ep1->p[2];
		}
	}
}

AMODE *GenerateAggregateAssign(ENODE *node1, ENODE *node2)
{
	AMODE *base;
	TYP *tp;
	int64_t offset = 0;

	if (node1==nullptr || node2==nullptr)
		return nullptr;
	//DumpStructEnodes(node2);
	base = GenerateExpression(node1,F_MEM,sizeOfWord);
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
AMODE *GenerateAssign(ENODE *node, int flags, int size)
{
	AMODE *ap1, *ap2 ,*ap3;
	TYP *tp;
    int ssize;

    Enter("GenAssign");

    if (node->p[0]->nodetype == en_uwfieldref ||
		node->p[0]->nodetype == en_wfieldref ||
		node->p[0]->nodetype == en_uhfieldref ||
		node->p[0]->nodetype == en_hfieldref ||
		node->p[0]->nodetype == en_ucfieldref ||
		node->p[0]->nodetype == en_cfieldref ||
		node->p[0]->nodetype == en_ubfieldref ||
		node->p[0]->nodetype == en_bfieldref) {

      Leave("GenAssign",0);
		return GenerateBitfieldAssign(node, flags, size);
    }

	ssize = GetReferenceSize(node->p[0]);
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
		ap1 = GenerateExpression(node->p[0],F_AREG|F_DREG|F_FPREG|F_MEM,ssize);
  		ap2 = GenerateExpression(node->p[1],F_ALL,size);
		if (node->p[0]->isUnsigned && !node->p[1]->isUnsigned)
		    GenerateZeroExtend(ap2,size,ssize);
//	}
	if (ap1->mode == am_dreg || ap1->mode==am_fpreg) {
		if (ap2->mode==am_dreg || ap2->mode==am_areg) {
			GenerateHint(2);
			GenerateDiadic(op_move,'l',ap2,ap1);
		}
		else if (ap2->mode==am_immed) {
			GenerateDiadic(op_move,'l',ap2,ap1);
		}
		else {
			GenLoad(ap1,ap2,ssize,size);
		}
	}
	// ap1 is memory
	else {
		if (ap2->mode == am_dreg || ap2->mode==am_areg || ap2->mode == am_fpreg) {
		    GenStore(ap2,ap1,ssize);
        }
		else if (ap2->mode == am_immed) {
			GenStore(ap2,ap1,ssize);
		}
		else {
//			if (ap1->isFloat)
//				ap3 = GetTempRegister();
//			else
			// Generate a memory to memory move (struct assignments)
			if (ssize > 8) {
				ap3 = GetTempRegister();
				GenerateDiadic(op_move,'l',make_immed(size),make_adec(7));
				GenerateDiadic(op_move,'l',ap2,make_adec(7));
				GenerateDiadic(op_move,'l',ap1,make_adec(7));
				GenerateMonadic(op_jsr,0,make_string("memcpy_"));
				GenerateDiadic(op_add,'l',make_immed(12),make_areg(regSP));
			}
			else {
				GenStore(ap2,ap1,ssize);
			}
		}
	}
	ReleaseTempReg(ap2);
    MakeLegalAmode(ap1,flags,size);
    Leave("GenAssign",1);
	return (ap1);
}

/*
 *      generate an auto increment or decrement node. op should be
 *      either op_add (for increment) or op_sub (for decrement).
 */
AMODE *GenerateAutoIncrement(ENODE *node,int flags,int size,int op)
{
	AMODE *ap1, *ap2;
    int siz1;

    siz1 = GetNaturalSize(node->p[0]);
    if( flags & F_NOVALUE )         /* dont need result */
            {
            ap1 = GenerateExpression(node->p[0],F_ALL,siz1);
			if (ap1->mode != am_dreg && ap1->mode != am_areg) {
                GenMemop(op, ap1, make_immed(node->i), size)
                ;
/*
				ap2 = GetTempRegister();
				if (ap1->isUnsigned) {
					switch(size) {
					case 1:	GenerateDiadic(op_lbu,0,ap2,ap1); break;
					case 2:	GenerateDiadic(op_lcu,0,ap2,ap1); break;
					case 4:	GenerateDiadic(op_lhu,0,ap2,ap1); break;
					case 8:	GenerateDiadic(op_lw,0,ap2,ap1); break;
					}
				}
				else {
					switch(size) {
					case 1:	GenerateDiadic(op_lb,0,ap2,ap1); break;
					case 2:	GenerateDiadic(op_lc,0,ap2,ap1); break;
					case 4:	GenerateDiadic(op_lh,0,ap2,ap1); break;
					case 8:	GenerateDiadic(op_lw,0,ap2,ap1); break;
					}
				}
	            GenerateTriadic(op,0,ap2,ap2,make_immed(node->i));
				switch(size) {
				case 1:	GenerateDiadic(op_sb,0,ap2,ap1); break;
				case 2:	GenerateDiadic(op_sc,0,ap2,ap1); break;
				case 4:	GenerateDiadic(op_sh,0,ap2,ap1); break;
				case 8:	GenerateDiadic(op_sw,0,ap2,ap1); break;
				}
				ReleaseTempRegister(ap2);
*/
			}
			else {
				GenerateDiadic(op,0,make_immed(node->i),ap1);
			}
            //ReleaseTempRegister(ap1);
            return (ap1);
            }
    ap2 = GenerateExpression(node->p[0],F_ALL,siz1);
	if (ap2->mode == am_dreg) {
		switch(siz1) {
		case 1:	GenerateDiadic(op,'b',make_immed(node->i),ap2);
		case 2:	GenerateDiadic(op,'w',make_immed(node->i),ap2);
		case 4:	GenerateDiadic(op,'l',make_immed(node->i),ap2);
		}
		return (ap2);
	}
	else if (ap2->mode == am_areg) {
		switch(siz1) {
		case 2:	GenerateDiadic(op,'w',make_immed(node->i),ap2);
		case 4:	GenerateDiadic(op,'l',make_immed(node->i),ap2);
		}
		return (ap2);
	}
	else {
//	    ap1 = GetTempRegister();
        GenMemop(op, ap2, make_immed(node->i), siz1);
        return ap2;
        GenLoad(ap1,ap2,siz1,siz1);
		GenerateTriadic(op,0,ap1,ap1,make_immed(node->i));
		GenStore(ap1,ap2,siz1);
//		ReleaseTempRegister(ap1);
	}
    //ReleaseTempRegister(ap2);
    //GenerateSignExtend(ap1,siz1,size,flags);
    return ap2;
}

// autocon and autofcon nodes

AMODE *GenAutocon(ENODE *node, int flags, int size, int type)
{
	AMODE *ap1, *ap2;

	ap1 = GetTempRegister();
	ap2 = allocAmode();
	ap2->mode = am_indx;
	ap2->preg = regBP;          /* frame pointer */
	ap2->offset = node;     /* use as constant node */
	ap2->type = type;
	GenerateDiadic(op_lea,0,ap1,ap2);
	MakeLegalAmode(ap1,flags,size);
	return ap1;             /* return reg */
}

//
// General expression evaluation. returns the addressing mode
// of the result.
//
AMODE *GenerateExpression(ENODE *node, int flags, int size)
{   
	AMODE *ap1, *ap2;
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
        return (AMODE *)NULL;
    }
	//size = node->esize;
    switch( node->nodetype )
    {
	case en_fcon:
        ap1 = allocAmode();
        ap1->mode = am_direct;
        ap1->offset = node;
		ap1->type = stdflt.GetIndex();
        MakeLegalAmode(ap1,flags,size);
        Leave("</GenerateExpression>",2); 
        return ap1;
		/*
            ap1 = allocAmode();
            ap1->mode = am_immed;
            ap1->offset = node;
			ap1->isFloat = TRUE;
            MakeLegalAmode(ap1,flags,size);
         Leave("GenExperssion",2); 
            return ap1;
		*/
    case en_icon:
        ap1 = allocAmode();
        ap1->mode = am_immed;
        ap1->offset = node;
        MakeLegalAmode(ap1,flags,size);
        Leave("GenExperssion",3); 
        return ap1;

	case en_labcon:
            if (use_gp) {
                ap1 = GetTempAddressReg();
                ap2 = allocAmode();
                ap2->mode = am_indx;
                ap2->preg = regGP;      // global pointer
                ap2->offset = node;     // use as constant node
                GenerateDiadic(op_lea,0,ap2,ap1);
                MakeLegalAmode(ap1,flags,size);
         Leave("GenExperssion",4); 
                return ap1;             // return reg
            }
            ap1 = allocAmode();
			/* this code not really necessary, see segments notes
			if (node->etype==bt_pointer && node->constflag) {
				ap1->segment = codeseg;
			}
			else {
				ap1->segment = dataseg;
			}
			*/
            ap1->mode = am_immed;
            ap1->offset = node;
			ap1->isUnsigned = node->isUnsigned;
            MakeLegalAmode(ap1,flags,size);
         Leave("GenExperssion",5); 
            return ap1;

    case en_nacon:
            if (use_gp) {
                ap1 = GetTempAddressReg();
                ap2 = allocAmode();
                ap2->mode = am_indx;
                ap2->preg = regGP;      // global pointer
                ap2->offset = node;     // use as constant node
                GenerateDiadic(op_lea,0,ap2,ap1);
                MakeLegalAmode(ap1,flags,size);
				Leave("GenExpression",6); 
                return ap1;             // return reg
            }
            // fallthru
	case en_cnacon:
            ap1 = allocAmode();
            ap1->mode = am_immed;
            ap1->offset = node;
			if (node->i==0)
				node->i = -1;
			ap1->isUnsigned = node->isUnsigned;
            MakeLegalAmode(ap1,flags,size);
			Leave("GenExpression",7); 
            return ap1;
	case en_clabcon:
            ap1 = allocAmode();
            ap1->mode = am_immed;
            ap1->offset = node;
			ap1->isUnsigned = node->isUnsigned;
            MakeLegalAmode(ap1,flags,size);
			Leave("GenExpression",7); 
            return ap1;
    case en_autocon:	return GenAutocon(node, flags, size, stdint.GetIndex());
    case en_autofcon:	return GenAutocon(node, flags, size, stddouble.GetIndex());
    case en_autovcon:	return GenAutocon(node, flags, size, stdvector.GetIndex());
    case en_autovmcon:	return GenAutocon(node, flags, size, stdvectormask->GetIndex());
    case en_classcon:
            ap1 = GetTempAddressReg();
            ap2 = allocAmode();
            ap2->mode = am_indx;
            ap2->preg = regCLP;     /* frame pointer */
            ap2->offset = node;     /* use as constant node */
            GenerateDiadic(op_lea,0,ap1,ap2);
            MakeLegalAmode(ap1,flags,size);
            return ap1;             /* return reg */
    case en_ub_ref:
	case en_uc_ref:
	case en_uh_ref:
	case en_uw_ref:
			ap1 = GenerateDereference(node,flags,size,0);
			ap1->isUnsigned = TRUE;
            return ap1;
	case en_struct_ref:
			ap1 = GenerateDereference(node,flags,size,0);
			ap1->isUnsigned = TRUE;
            return ap1;
	case en_vector_ref:	return GenerateDereference(node,flags,512,0);
	case en_ref32:	return GenerateDereference(node,flags,4,1);
	case en_ref32u:	return GenerateDereference(node,flags,4,0);
    case en_b_ref:	return GenerateDereference(node,flags,1,1);
	case en_c_ref:	return GenerateDereference(node,flags,2,1);
	case en_h_ref:	return GenerateDereference(node,flags,2,1);
    case en_w_ref:	return GenerateDereference(node,flags,4,1);
	case en_flt_ref:
	case en_dbl_ref:
    case en_triple_ref:
	case en_quad_ref:
			ap1 = GenerateDereference(node,flags,size,1);
			ap1->type = stddouble.GetIndex();
            return ap1;
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
            ap1 = allocAmode();
            ap1->mode = am_dreg;
            ap1->preg = node->i;
            ap1->tempflag = 0;      /* not a temporary */
            MakeLegalAmode(ap1,flags,size);
            return ap1;
    case en_tempfpref:
            ap1 = allocAmode();
            ap1->mode = am_fpreg;
            ap1->preg = node->i;
            ap1->tempflag = 0;      /* not a temporary */
            MakeLegalAmode(ap1,flags,size);
            return ap1;
	case en_fpregvar:
//    case en_fptempref:
            ap1 = allocAmode();
            ap1->mode = am_fpreg;
            ap1->preg = node->i;
            ap1->tempflag = 0;      /* not a temporary */
            MakeLegalAmode(ap1,flags,size);
            return ap1;
	case en_abs:	return GenerateUnary(node,flags,size,op_abs);
    case en_uminus: return GenerateUnary(node,flags,size,op_neg);
    case en_compl:  return GenerateUnary(node,flags,size,op_com);
    case en_add:    return GenerateBinary(node,flags,size,op_add);
    case en_sub:    return GenerateBinary(node,flags,size,op_sub);
    case en_i2d:
         ap1 = GetTempRegister();	
         //ap2=GenerateExpression(node->p[0],F_REG,8);
         //GenerateDiadic(op_itof,'d',ap1,ap2);
         //ReleaseTempReg(ap2);
         return ap1;
    case en_i2q:
         ap1 = GetTempRegister();	
   //      ap2 = GenerateExpression(node->p[0],F_REG,8);
		 //GenerateTriadic(op_csrrw,0,makereg(0),make_immed(0x18),ap2);
		 //GenerateZeradic(op_nop);
		 //GenerateZeradic(op_nop);
   //      GenerateDiadic(op_itof,'q',ap1,makereg(63));
   //      ReleaseTempReg(ap2);
         return ap1;
    case en_i2t:
         ap1 = GetTempRegister();	
   //      ap2 = GenerateExpression(node->p[0],F_REG,8);
		 //GenerateTriadic(op_csrrw,0,makereg(0),make_immed(0x18),ap2);
		 //GenerateZeradic(op_nop);
		 //GenerateZeradic(op_nop);
   //      GenerateDiadic(op_itof,'t',ap1,makereg(63));
   //      ReleaseTempReg(ap2);
         return ap1;
    case en_d2i:
         ap1 = GetTempRegister();	
         //ap2 = GenerateExpression(node->p[0],F_REG,8);
         //GenerateDiadic(op_ftoi,'d',ap1,ap2);
         //ReleaseTempReg(ap2);
         return ap1;
    case en_q2i:
         ap1 = GetTempRegister();
   //      ap2 = GenerateExpression(node->p[0],F_FPREG,8);
   //      GenerateDiadic(op_ftoi,'q',makereg(63),ap2);
		 //GenerateZeradic(op_nop);
		 //GenerateZeradic(op_nop);
		 //GenerateTriadic(op_csrrw,0,ap1,make_immed(0x18),makereg(0));
         ReleaseTempReg(ap2);
         return ap1;
    case en_t2i:
         ap1 = GetTempRegister();
   //      ap2 = GenerateExpression(node->p[0],F_FPREG,8);
   //      GenerateDiadic(op_ftoi,'t',makereg(63),ap2);
		 //GenerateZeradic(op_nop);
		 //GenerateZeradic(op_nop);
		 //GenerateTriadic(op_csrrw,0,ap1,make_immed(0x18),makereg(0));
   //      ReleaseTempReg(ap2);
         return ap1;
	case en_s2q:
		ap1 = GetTempRegister();
        ap2 = GenerateExpression(node->p[0],F_FPREG,8);
        GenerateDiadic(op_fcvtsq,0,ap1,ap2);
        ReleaseTempReg(ap2);
		return ap1;

	case en_fadd:	  return GenerateBinary(node,flags,size,op_fadd);
	case en_fsub:	  return GenerateBinary(node,flags,size,op_fsub);
	case en_fmul:	  return GenerateBinary(node,flags,size,op_fmul);
	case en_fdiv:	  return GenerateBinary(node,flags,size,op_fdiv);

	case en_fdadd:    return GenerateBinary(node,flags,size,op_fdadd);
    case en_fdsub:    return GenerateBinary(node,flags,size,op_fdsub);
    case en_fsadd:    return GenerateBinary(node,flags,size,op_fsadd);
    case en_fssub:    return GenerateBinary(node,flags,size,op_fssub);
    case en_fdmul:    return GenerateMultiply(node,flags,size,op_fdmul);
    case en_fsmul:    return GenerateMultiply(node,flags,size,op_fsmul);
    case en_fddiv:    return GenerateMultiply(node,flags,size,op_fddiv);
    case en_fsdiv:    return GenerateMultiply(node,flags,size,op_fsdiv);
	case en_ftadd:    return GenerateBinary(node,flags,size,op_ftadd);
    case en_ftsub:    return GenerateBinary(node,flags,size,op_ftsub);
    case en_ftmul:    return GenerateMultiply(node,flags,size,op_ftmul);
    case en_ftdiv:    return GenerateMultiply(node,flags,size,op_ftdiv);

	case en_and:    return GenerateBinary(node,flags,size,op_and);
    case en_or:     return GenerateBinary(node,flags,size,op_or);
	case en_xor:	return GenerateBinary(node,flags,size,op_xor);
    case en_mul:    return GenerateMultiply(node,flags,size,op_mul);
    case en_mulu:   return GenerateMultiply(node,flags,size,op_mulu);
    case en_div:    return GenerateModDiv(node,flags,size,op_div);
    case en_udiv:   return GenerateModDiv(node,flags,size,op_divu);
    case en_mod:    return GenerateModDiv(node,flags,size,op_mod);
    case en_umod:   return GenerateModDiv(node,flags,size,op_modu);
    case en_asl:    return GenerateShift(node,flags,size,op_asl);
    case en_shl:    return GenerateShift(node,flags,size,op_shl);
    case en_shlu:   return GenerateShift(node,flags,size,op_shlu);
    case en_asr:	return GenerateShift(node,flags,size,op_asr);
    case en_shr:	return GenerateShift(node,flags,size,op_asr);
    case en_shru:   return GenerateShift(node,flags,size,op_shru);
	case en_rol:   return GenerateShift(node,flags,size,op_rol);
	case en_ror:   return GenerateShift(node,flags,size,op_ror);
	/*	
	case en_asfadd: return GenerateAssignAdd(node,flags,size,op_fadd);
	case en_asfsub: return GenerateAssignAdd(node,flags,size,op_fsub);
	case en_asfmul: return GenerateAssignAdd(node,flags,size,op_fmul);
	case en_asfdiv: return GenerateAssignAdd(node,flags,size,op_fdiv);
	*/
    case en_asadd:  return GenerateAssignAdd(node,flags,size,op_add);
    case en_assub:  return GenerateAssignAdd(node,flags,size,op_sub);
    case en_asand:  return GenerateAssignLogic(node,flags,size,op_and);
    case en_asor:   return GenerateAssignLogic(node,flags,size,op_or);
	case en_asxor:  return GenerateAssignLogic(node,flags,size,op_xor);
    case en_aslsh:
            return GenerateAssignShift(node,flags,size,op_shl);
    case en_asrsh:
            return GenerateAssignShift(node,flags,size,op_asr);
    case en_asrshu:
            return GenerateAssignShift(node,flags,size,op_shru);
    case en_asmul: return GenerateAssignMultiply(node,flags,size,op_mul);
    case en_asmulu: return GenerateAssignMultiply(node,flags,size,op_mulu);
    case en_asdiv: return GenerateAssignModiv(node,flags,size,op_div);
    case en_asdivu: return GenerateAssignModiv(node,flags,size,op_divu);
    case en_asmod: return GenerateAssignModiv(node,flags,size,op_mod);
    case en_asmodu: return GenerateAssignModiv(node,flags,size,op_modu);
    case en_assign:
            return GenerateAssign(node,flags,size);
    case en_ainc: return GenerateAutoIncrement(node,flags,size,op_add);
    case en_adec: return GenerateAutoIncrement(node,flags,size,op_sub);

    case en_land:
        return (GenExpr(node));

	case en_lor:
      return (GenExpr(node));

	case en_not:
	    return (GenExpr(node));

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
            return GenerateHook(node,flags,size);
    case en_void:
            natsize = GetNaturalSize(node->p[0]);
            ReleaseTempRegister(GenerateExpression(node->p[0],F_ALL | F_NOVALUE,natsize));
            return (GenerateExpression(node->p[1],flags,size));

    case en_fcall:
		return (GenerateFunctionCall(node,flags));

	case en_cubw:
	case en_cubu:
	case en_cbu:
			ap1 = GenerateExpression(node->p[0],F_DREG,size);
			GenerateTriadic(op_and,0,ap1,ap1,make_immed(0xff));
			return (ap1);
	case en_cucw:
	case en_cucu:
	case en_ccu:
			ap1 = GenerateExpression(node->p[0],F_DREG,size);
			Generate4adic(op_bfextu,0,ap1,ap1,make_immed(0),make_immed(15));
			return ap1;
	case en_cuhw:
	case en_cuhu:
	case en_chu:
			ap1 = GenerateExpression(node->p[0],F_DREG,size);
			Generate4adic(op_bfextu,0,ap1,ap1,make_immed(0),make_immed(31));
			return ap1;
	case en_cbw:
			ap1 = GenerateExpression(node->p[0],F_DREG,size);
			//GenerateDiadic(op_sxb,0,ap1,ap1);
			Generate4adic(op_bfext,0,ap1,ap1,make_immed(0),make_immed(7));
			return ap1;
	case en_ccw:
			ap1 = GenerateExpression(node->p[0],F_DREG,size);
			Generate4adic(op_bfext,0,ap1,ap1,make_immed(0),make_immed(15));
			//GenerateDiadic(op_sxh,0,ap1,ap1);
			return ap1;
	case en_chw:
			ap1 = GenerateExpression(node->p[0],F_DREG,size);
			Generate4adic(op_bfext,0,ap1,ap1,make_immed(0),make_immed(31));
			//GenerateDiadic(op_sxh,0,ap1,ap1);
			return ap1;
    default:
            printf("DIAG - uncoded node (%d) in GenerateExpression.\n", node->nodetype);
            return 0;
    }
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
		return 2;
	case en_icon:
		if( -32768 <= node->i && node->i <= 32767 )
			return 2;
		if (-2147483648LL <= node->i && node->i <= 2147483647LL)
			return 4;
		return 8;
	case en_fcon:
		return node->tp->precision / 16;
	case en_tcon: return 6;
	case en_fcall:  case en_labcon: case en_clabcon:
	case en_cnacon: case en_nacon:  case en_autocon: case en_classcon:
	case en_tempref:
	case en_regvar:
	case en_fpregvar:
	case en_cbw: case en_cubw:
	case en_ccw: case en_cucw:
	case en_chw: case en_cuhw:
	case en_cbu: case en_ccu: case en_chu:
	case en_cubu: case en_cucu: case en_cuhu:
		return 4;
	case en_autofcon:
		return 4;
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
	case en_h_ref:	return 2;
	case en_uh_ref:	return 2;
	case en_flt_ref: return sizeOfFPS;
	case en_w_ref:  case en_uw_ref:
		return 4;
	case en_autovcon:
	case en_vector_ref:
		return 512;
	case en_dbl_ref:
		return sizeOfFPD;
	case en_quad_ref:
		return sizeOfFPQ;
	case en_triple_ref:
		return sizeOfFPT;
	case en_struct_ref:
	return node->esize;
	case en_tempfpref:
	if (node->tp)
		return node->tp->precision/16;
	else
		return 4;
	case en_not:    case en_compl:
	case en_uminus: case en_assign:
	case en_ainc:   case en_adec:
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
	case en_asmod:  case en_asand:
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
	case en_chk:
		return 4;
	case en_q2i:
	case en_t2i:
		return (sizeOfWord);
	case en_i2t:
		return (sizeOfFPT);
	case en_i2q:
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
	AMODE  *ap1;
	int    siz1;
	int    lab0;

	if( node == 0 )
		return;
	switch( node->nodetype )
	{
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
	case en_land:
		lab0 = nextlabel++;
		GenerateFalseJump(node->p[0],lab0,prediction);
		GenerateTrueJump(node->p[1],label,prediction^1);
		GenerateLabel(lab0);
		break;
	case en_lor:
		GenerateTrueJump(node->p[0],label,prediction);
		GenerateTrueJump(node->p[1],label,prediction);
		break;
	case en_not:
		GenerateFalseJump(node->p[0],label,prediction^1);
		break;
	default:
		siz1 = GetNaturalSize(node);
		ap1 = GenerateExpression(node,F_DREG,siz1);
		GenerateMonadic(op_tst,siz1,ap1);
		ReleaseTempRegister(ap1);
		GenerateMonadic(op_bne,0,make_label(label));
		break;
	}
}

//
// Generate code to execute a jump to label if the expression
// passed is false.
//
void GenerateFalseJump(ENODE *node,int label, unsigned int prediction)
{
	AMODE *ap;
	int siz1;
	int lab0;

	if( node == (ENODE *)NULL )
		return;
	switch( node->nodetype )
	{
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
		ap = GenerateExpression(node,F_DREG,siz1);
		GenerateMonadic(op_tst,siz1,ap);
		ReleaseTempRegister(ap);
		GenerateMonadic(op_beq,0,make_label(label));
		break;
	}
}
