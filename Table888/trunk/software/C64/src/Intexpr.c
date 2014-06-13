// ============================================================================
//        __
//   \\__/ o\    (C) 2012,2013  Robert Finch, Stratford
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
#include <stdio.h>
#include "c.h"
#include "expr.h"
#include "gen.h"
#include "cglbdec.h"

__int64 GetIntegerExpression()       /* simple integer value */
{ 
	TYP *tp;
	ENODE *node;

	tp = expression(&node);
	if (node==NULL) {
		error(ERR_SYNTAX);
		return 0;
	}
	opt4(&node);	// This should reduce to a single integer expressionk
	if (node==NULL) {
		fatal("Compiler Error: GetIntegerExpression: node is NULL");
		return 0;
	}
	if (node->nodetype != en_icon) {
		error(ERR_INT_CONST);
		return 0;
	}
	return node->i;
}
