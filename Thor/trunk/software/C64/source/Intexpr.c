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

__int64 GetIntegerExpression()       /* simple integer value */
{ 
	__int64 temp;
    SYM *sp;

	if(lastst == id) {
        sp = gsearch(lastid);
        if(sp == NULL) {
            error(ERR_UNDEFINED);
            NextToken();
            return 0;
        }
        if(sp->storage_class != sc_const) {
            error(ERR_SYNTAX);
            NextToken();
            return 0;
        }
        NextToken();
        return sp->value.i;
    }
    else if(lastst == iconst)
	{
		temp = ival;
		NextToken();
		return temp;
    }
    NextToken();
    error(ERR_SYNTAX);
    return 0;
}
