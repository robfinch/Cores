#include "stdafx.h"

// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - 'C' derived language compiler
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

//
// Copy the node passed into a new enode so it wont get corrupted during
// substitution.
//
ENODE *ENODE::Duplicate()
{       
	ENODE *temp;

    if( this == NULL )
        return (ENODE *)NULL;
    temp = ENODE::alloc();
	memcpy(temp,this,sizeof(ENODE));	// copy all the fields
    return (temp);
}


ENODE *ENODE::alloc()
{
	ENODE *p;
	p = (ENODE *)allocx(sizeof(ENODE));
	p->sp = new std::string();
	return p;
};

bool ENODE::IsEqual(ENODE *node1, ENODE *node2)
{
    if (node1 == NULL || node2 == NULL) {
		return false;
    }
    if (node1->nodetype != node2->nodetype) {
		return false;
    }
    switch (node1->nodetype) {
//			return (node1->f == node2->f);
	case en_regvar:
	case en_fpregvar:
	case en_icon:
	case en_labcon:
	case en_classcon:	// Check type ?
	case en_autocon:
	case en_autofcon:
	{
		return (node1->i == node2->i);
	}
	case en_nacon:{
		return (node1->sp->compare(*node2->sp)==0);
	}
	case en_cnacon:
		return (node1->sp->compare(*node2->sp)==0);
	default:
		if( IsLValue(node1,true) && IsEqual(node1->p[0], node2->p[0])  )
			return true;
		return false;
	}
}


//
// Apply all constant optimizations.
//
extern void opt0(ENODE **);
extern void fold_const(ENODE **);

void ENODE::OptimizeConstants(ENODE **pnode)
{
    if (opt_noexpr==FALSE) {
    	opt0(pnode);
    	fold_const(pnode);
    	opt0(pnode);
    }
}

