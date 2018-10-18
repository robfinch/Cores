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

extern char *rtrim(char *);
extern int caselit(scase *casetab,int64_t);

Operand *makereg(int r)
{
	Operand *ap;
    ap = allocOperand();
    ap->mode = am_reg;
    ap->preg = r;
    return (ap);
}

Operand *makevreg(int r)
{
	Operand *ap;
    ap = allocOperand();
    ap->mode = am_reg;
    ap->preg = r;
	ap->type = stdvector.GetIndex();
    return (ap);
}

Operand *makevmreg(int r)
{
	Operand *ap;
    ap = allocOperand();
    ap->mode = am_vmreg;
    ap->preg = r;
    return (ap);
}

Operand *makefpreg(int r)
{
	Operand *ap;
    ap = allocOperand();
    ap->mode = am_fpreg;
    ap->preg = r;
    ap->type = stddouble.GetIndex();
    return (ap);
}

Operand *makesreg(int r)
{
	Operand *ap;
    ap = allocOperand();
    ap->mode = am_sreg;
    ap->preg = r;
    return (ap);
}

Operand *makebreg(int r)
{
	Operand *ap;
    ap = allocOperand();
    ap->mode = am_breg;
    ap->preg = r;
    return (ap);
}

/*
 *      generate the mask address structure.
 */
Operand *make_mask(int mask)
{
	Operand *ap;
    ap = allocOperand();
    ap->mode = am_mask;
    ap->offset = (ENODE *)mask;
    return (ap);
}

/*
 *      make a direct reference to an immediate value.
 */
Operand *make_direct(int i)
{
	return make_offset(makeinode(en_icon,i));
}

Operand *make_indexed2(int lab, int i)
{
	Operand *ap;
    ENODE *ep;
    ep = allocEnode();
    ep->nodetype = en_clabcon;
    ep->i = lab;
    ap = allocOperand();
	ap->mode = am_indx;
	ap->preg = i;
    ap->offset = ep;
	ap->isUnsigned = TRUE;
    return (ap);
}

//
// Generate a direct reference to a string label.
//
Operand *make_strlab(std::string s)
{
	Operand *ap;
    ap = allocOperand();
    ap->mode = am_direct;
    ap->offset = makesnode(en_nacon,new std::string(s),new std::string(s),-1);
    return (ap);
}

