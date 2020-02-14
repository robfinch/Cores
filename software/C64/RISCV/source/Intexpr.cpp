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

int64_t GetIntegerExpression(ENODE **pnode)       /* simple integer value */
{ 
	TYP *tp;
	ENODE *node;

	tp = Expression::ParseNonCommaExpression(&node);
	if (node==NULL) {
		error(ERR_SYNTAX);
		return (0);
	}
	// Do constant optimizations to reduce a set of constants to a single constant.
	// Otherwise some codes won't compile without errors.
	opt_const_unchecked(&node);	// This should reduce to a single integer expression
	if (node==NULL) {
		fatal("Compiler Error: GetIntegerExpression: node is NULL");
		return (0);
	}
	if (node->nodetype == en_add) {
		if (node->p[0]->nodetype == en_labcon && node->p[1]->nodetype == en_icon) {
			if (pnode)
				*pnode = node;
			return (node->i);
		}
		if (node->p[0]->nodetype == en_icon && node->p[1]->nodetype == en_labcon) {
			if (pnode)
				*pnode = node;
			return (node->i);
		}
	}
	if (node->nodetype != en_icon && node->nodetype != en_cnacon && node->nodetype != en_labcon) {
    printf("\r\nnode:%d \r\n", node->nodetype);
		error(ERR_INT_CONST);
		return (0);
	}
	if (pnode)
		*pnode = node;
	return (node->i);
}

Float128 *GetFloatExpression(ENODE **pnode)       /* simple integer value */
{ 
	TYP *tp;
	ENODE *node;
	Float128 *flt;

	flt = (Float128 *)allocx(sizeof(Float128));
	tp = Expression::ParseNonCommaExpression(&node);
	if (node==NULL) {
		error(ERR_SYNTAX);
		return 0;
	}
	opt_const_unchecked(&node);
	if (node==NULL) {
		fatal("Compiler Error: GetFloatExpression: node is NULL");
		return 0;
	}
	if (node->nodetype != en_fcon) {
		if (node->nodetype==en_uminus) {
			if (node->p[0]->nodetype != en_fcon) {
				printf("\r\nnode:%d \r\n", node->nodetype);
				error(ERR_INT_CONST);
				return (0);
			}
			Float128::Assign(flt, &node->p[0]->f128);
			flt->sign = !flt->sign;
			if (pnode)
				*pnode = node;
			return (flt);
		}
	}
	if (pnode)
		*pnode = node;
	return (&node->f128);
}

int64_t GetConstExpression(ENODE **pnode)       /* simple integer value */
{
	TYP *tp;
	ENODE *node;
	Float128 *flt;

	tp = Expression::ParseNonCommaExpression(&node);
	if (node == NULL) {
		error(ERR_SYNTAX);
		return (0);
	}
	opt_const_unchecked(&node);
	if (node == NULL) {
		fatal("Compiler Error: GetConstExpression: node is NULL");
		return (0);
	}
	switch (node->nodetype)
	{
	case en_uminus:
		switch (node->p[0]->nodetype) {
		case en_icon:
			if (pnode)
				*pnode = node;
			return (-node->i);
		case en_fcon:
			flt = (Float128 *)allocx(sizeof(Float128));
			Float128::Assign(flt, &node->p[0]->f128);
			flt->sign = !flt->sign;
			if (pnode)
				*pnode = node;
			return ((int64_t)flt);
		default:
			error(ERR_CONST);
			return (0);
		}
		break;
	case en_fcon:
		if (pnode)
			*pnode = node;
		return ((int64_t)&node->f128);
	case en_icon:
	case en_cnacon:
		if (pnode)
			*pnode = node;
		return (node->i);
	default:
		if (pnode)
			*pnode = node;
		//error(ERR_CONST);
		return (0);
	}
	error(ERR_CONST);
	return (0);
}
