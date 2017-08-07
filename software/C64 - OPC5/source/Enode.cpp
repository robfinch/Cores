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


//
// Apply all constant optimizations.
//
extern void opt0(ENODE **);
extern void fold_const(ENODE **);

void ENODE::OptimizeConstants()
{
	ENODE *pnode = this;

    if (opt_noexpr==FALSE) {
    	opt0(&pnode);
    	fold_const(&pnode);
    	opt0(&pnode);
    }
}

