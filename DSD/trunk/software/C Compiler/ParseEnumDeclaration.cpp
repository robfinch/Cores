// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C32 - 'C' derived language compiler
//  - 32 bit CPU
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

extern TABLE tagtable;
extern TYP *head;
extern TYP stdconst;

void enumbody(TABLE *table);

void ParseEnumDeclaration(TABLE *table)
{   
	SYM *sp;
    TYP     *tp;
    if( lastst == id) {
        if((sp = search(lastid,&tagtable)) == NULL) {
            sp = allocSYM();
            sp->tp = TYP::Make(bt_enum,1);
            sp->storage_class = sc_type;
            sp->SetName(*(new std::string(lastid)));
            sp->tp->sname = new std::string(*sp->name);
            NextToken();
            if( lastst != begin)
                    error(ERR_INCOMPLETE);
            else {
				tagtable.insert(sp);
				NextToken();
				ParseEnumerationList(table);
            }
        }
        else
            NextToken();
        head = sp->tp;
    }
    else {
        tp = allocTYP();	// fix here
        tp->type = bt_enum;
		tp->size = 1;
        if( lastst != begin)
            error(ERR_INCOMPLETE);
        else {
            NextToken();
            ParseEnumerationList(table);
        }
    head = tp;
    }
}

void ParseEnumerationList(TABLE *table)
{
	int     evalue;
    SYM     *sp;
    evalue = 0;
    while(lastst == id) {
        sp = allocSYM();
        sp->SetName(*(new std::string(lastid)));
        sp->storage_class = sc_const;
        sp->tp = &stdconst;
        table->insert(sp);
        NextToken();
		if (lastst==assign) {
			NextToken();
			sp->value.i = GetIntegerExpression((ENODE **)NULL);
			evalue = (int)sp->value.i+1;
		}
		else
			sp->value.i = evalue++;
        if( lastst == comma)
                NextToken();
        else if(lastst != end)
                break;
    }
    needpunc(end,48);
}

