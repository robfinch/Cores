// ============================================================================
//        __
//   \\__/ o\    (C) 2012,2013  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - Raptor64 'C' derived language compiler
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
#include        <stdio.h>
#include <string.h>
#include        "c.h"
#include        "expr.h"
#include "Statement.h"
#include        "gen.h"
#include        "cglbdec.h"

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
/*******************************************************
	Copyright 2012	Robert Finch
	Modified to support Raptor64 'C64' language
	by Robert Finch
	robfinch@opencores.org
*******************************************************/

extern TABLE tagtable;
extern TYP *head;
extern TYP stdconst;
extern int bit_next;
extern int bit_offset;
extern int bit_width;

__int16 typeno = bt_last;

void ParseStructMembers(TYP *tp, int ztype);

void ParseStructDeclaration(int ztype)
{
    SYM     *sp;
    TYP     *tp;
	bit_offset = 0;
	bit_next = 0;
	bit_width = -1;
    if(lastst == id) {
        if((sp = search(lastid,&tagtable)) == NULL) {
            sp = allocSYM();
            sp->name = litlate(lastid);
            sp->tp = allocTYP();
            sp->tp->type = ztype;
			sp->tp->typeno = typeno++;
            sp->tp->lst.head = 0;
            sp->storage_class = sc_type;
            sp->tp->sname = sp->name;
            NextToken();
            if(lastst != begin)
                error(ERR_INCOMPLETE);
            else    {
                insert(sp,&tagtable);
                NextToken();
                ParseStructMembers(sp->tp,ztype);
                }
        }
        else
            NextToken();
        head = sp->tp;
    }
    else {
        tp = allocTYP();
        tp->type = ztype;
        tp->sname = 0;
        tp->lst.head = 0;
        if( lastst != begin)
            error(ERR_INCOMPLETE);
        else {
			NextToken();
			ParseStructMembers(tp,ztype);
        }
        head = tp;
    }
}

void ParseStructMembers(TYP *tp, int ztype)
{
	int     slc;
    slc = 0;
    tp->val_flag = 1;
    while( lastst != end) {
        if(ztype == bt_struct)
            slc += declare(&(tp->lst),sc_member,slc,ztype);
        else
            slc = imax(slc,declare(&tp->lst,sc_member,0,ztype));
    }
	bit_offset = 0;
	bit_next = 0;
	bit_width = -1;
    tp->size = slc;
    NextToken();
}

