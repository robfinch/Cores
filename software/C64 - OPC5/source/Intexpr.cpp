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

int GetIntegerExpression(ENODE **pnode)       /* simple integer value */
{ 
	TYP *tp;
	ENODE *node;

	tp = NonCommaExpression(&node);
	if (node==NULL) {
		error(ERR_SYNTAX);
		return 0;
	}
	ENODE::OptimizeConstants(&node);	// This should reduce to a single integer expression
	if (node==NULL) {
		fatal("Compiler Error: GetIntegerExpression: node is NULL");
		return 0;
	}
	if (node->nodetype != en_icon && node->nodetype != en_cnacon) {
        printf("\r\nnode:%d \n", node->nodetype);
		error(ERR_INT_CONST);
		return 0;
	}
	if (pnode)
		*pnode = node;
	return node->i;
}

