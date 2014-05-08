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

/*******************************************************
	Modified to support RTF65002 'C32' language
	by Robert Finch
	robfinch@finitron.ca
*******************************************************/

__int32 GetIntegerExpression()       /* simple integer value */
{ 
	__int32 temp;
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
