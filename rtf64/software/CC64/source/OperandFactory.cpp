// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
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

//
//      construct a reference node for an internal label number.
//
Operand *OperandFactory::MakeDataLabel(int lab, int ndxreg)
{
	ENODE *lnode;
	Operand *ap;

	lnode = allocEnode();
	lnode->nodetype = en_labcon;
	lnode->i = lab;
	DataLabels[lab] = true;
	ap = allocOperand();
	if (ndxreg != regZero) {
		ap->mode = am_indx;
		ap->preg = ndxreg;
	}
	else
		ap->mode = am_direct;
	ap->offset = lnode;
	ap->isUnsigned = TRUE;
	return (ap);
}

Operand *OperandFactory::MakeCodeLabel(int lab)
{
	ENODE *lnode;
	Operand *ap;

	lnode = allocEnode();
	lnode->nodetype = en_clabcon;
	lnode->i = lab;
	if (lab == -1) {
		printf("-1\r\n");
	}
	ap = allocOperand();
	ap->mode = am_direct;
	ap->offset = lnode;
	ap->isUnsigned = TRUE;
	return (ap);
}

Operand *OperandFactory::MakeStringAsNameConst(char *s, e_sg seg)
{
	ENODE *lnode;
	Operand *ap;

	lnode = allocEnode();
	lnode->nodetype = en_nacon;
	lnode->sp = new std::string(s);
	lnode->segment = seg;
	ap = allocOperand();
	ap->mode = am_direct;
	ap->offset = lnode;
	return (ap);
}

Operand *OperandFactory::MakeString(char *s)
{
	ENODE *lnode;
	Operand *ap;

	lnode = allocEnode();
	lnode->nodetype = en_scon;
	lnode->sp = new std::string(s);
	ap = allocOperand();
	ap->mode = am_direct;
	ap->offset = lnode;
	return (ap);
}

/*
 *      make a node to reference an immediate value i.
 */
Operand *OperandFactory::MakeImmediate(int64_t i)
{
	Operand *ap;
	ENODE *ep;
	ep = allocEnode();
	ep->nodetype = en_icon;
	ep->i = i;
	ap = allocOperand();
	ap->mode = am_imm;
	ap->offset = ep;
	return (ap);
}

Operand *OperandFactory::MakeIndirect(short int regno)
{
	Operand *ap;
	ENODE *ep;
	ep = allocEnode();
	ep->nodetype = en_ref;
	ep->tp = &stduint;
	ep->i = 0;
	ap = allocOperand();
	ap->mode = am_ind;
	ap->preg = regno;
	ap->offset = 0;
	return (ap);
}

Operand *OperandFactory::MakeIndexed(int64_t offset, int regno)
{
	Operand *ap;
	ENODE *ep;
	ep = allocEnode();
	ep->nodetype = en_icon;
	ep->i = offset;
	ap = allocOperand();
	ap->mode = am_indx;
	ap->preg = regno;
	ap->offset = ep;
	return (ap);
}

Operand *OperandFactory::MakeIndexed(ENODE *node, int regno)
{
	Operand *ap;
	ap = allocOperand();
	ap->mode = am_indx;
	ap->offset = node;
	ap->preg = regno;
	return (ap);
}

Operand* OperandFactory::MakeMemoryIndirect(int disp, int regno)
{
	Operand* ap;
	ENODE* ep;
	ep = allocEnode();
	ep->nodetype = en_icon;
	ep->i = disp;
	ap = allocOperand();
	ap->mode = am_mem_indirect;
	ap->offset = ep;
	ap->preg = regno;
	return (ap);
}

Operand *OperandFactory::MakeNegIndexed(ENODE *node, int regno)
{
	Operand *ap;
	ap = allocOperand();
	ap->mode = am_indx;
	ap->offset = node->Clone();
	ap->offset->isNeg = true;
	ap->preg = regno;
	return (ap);
}

Operand *OperandFactory::MakeIndexedCodeLabel(int lab, int i)
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


Operand *OperandFactory::MakeDoubleIndexed(int i, int j, int scale)
{
	Operand *ap;
	ap = allocOperand();
	ap->mode = am_indx2;
	ap->preg = i;
	ap->sreg = j;
	ap->scale = scale;
	return (ap);
}

//
// Make a direct reference to a node.
//
Operand *OperandFactory::MakeDirect(ENODE *node)
{
	Operand *ap;
	ap = allocOperand();
	ap->mode = am_direct;
	ap->offset = node;
	return ap;
}

Operand *OperandFactory::makereg(int r)
{
	Operand *ap;
	ap = allocOperand();
	ap->mode = am_reg;
	ap->preg = r;
	return (ap);
}

Operand *OperandFactory::makevreg(int r)
{
	Operand *ap;
	ap = allocOperand();
	ap->mode = am_reg;
	ap->preg = r;
	ap->type = stdvector.GetIndex();
	return (ap);
}

Operand *OperandFactory::makevmreg(int r)
{
	Operand *ap;
	ap = allocOperand();
	ap->mode = am_vmreg;
	ap->preg = r;
	return (ap);
}

Operand *OperandFactory::makefpreg(int r)
{
	Operand *ap;
	ap = allocOperand();
	ap->mode = am_fpreg;
	ap->preg = r|0x20;
	ap->type = stddouble.GetIndex();
	return (ap);
}

Operand* OperandFactory::makepreg(int r)
{
	Operand* ap;
	ap = allocOperand();
	ap->mode = am_preg;
	ap->preg = r|0x40;
	ap->type = stdposit.GetIndex();
	return (ap);
}

Operand *OperandFactory::makecreg(int r)
{
	Operand *ap;
	ap = allocOperand();
	ap->mode = am_creg;
	ap->preg = r|=0x70;
	ap->isBool = true;
	return (ap);
}

//Operand *OperandFactory::makesreg(int r)
//{
//	Operand *ap;
//	ap = allocOperand();
//	ap->mode = am_sreg;
//	ap->preg = r;
//	return (ap);
//}
//
//Operand *makebreg(int r)
//{
//	Operand *ap;
//	ap = allocOperand();
//	ap->mode = am_breg;
//	ap->preg = r;
//	return (ap);
//}
//
/*
 *      generate the mask address structure.
 */
Operand *OperandFactory::MakeMask(int mask)
{
	Operand *ap;
	ap = allocOperand();
	ap->mode = am_mask;
	ap->offset = (ENODE *)mask;
	return (ap);
}

//
// Generate a direct reference to a string label.
//
Operand *OperandFactory::MakeStrlab(std::string s, e_sg seg)
{
	Operand *ap;
	ap = allocOperand();
	ap->mode = am_direct;
	ap->offset = makesnode(en_nacon, new std::string(s), new std::string(s), -1);
	ap->offset->segment = seg;
	return (ap);
}

Operand *makereg(int r)
{
	return(compiler.of.makereg(r));
}

Operand *makevreg(int r)
{
	return(compiler.of.makevreg(r));
}

Operand *makevmreg(int r)
{
	return(compiler.of.makevmreg(r));
}

Operand *makefpreg(int r)
{
	return(compiler.of.makefpreg(r));
}

Operand* makepreg(int r)
{
	return(compiler.of.makepreg(r));
}

Operand *makecreg(int r)
{
	return(compiler.of.makecreg(r));
}

//Operand *makesreg(int r)
//{
//	Operand *ap;
//    ap = allocOperand();
//    ap->mode = am_sreg;
//    ap->preg = r;
//    return (ap);
//}
//
//Operand *makebreg(int r)
//{
//	Operand *ap;
//    ap = allocOperand();
//    ap->mode = am_breg;
//    ap->preg = r;
//    return (ap);
//}
//
/*
 *      generate the mask address structure.
 */
Operand *make_mask(int mask)
{
	return (compiler.of.MakeMask(mask));
}

//
// Generate a direct reference to a string label.
//
Operand *make_strlab(std::string s, e_sg seg)
{
	return (compiler.of.MakeStrlab(s, seg));
}


