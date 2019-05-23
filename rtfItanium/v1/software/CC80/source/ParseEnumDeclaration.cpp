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

extern TABLE tagtable;
extern TYP *head;
extern TYP stdconst;

void Declaration::ParseEnum(TABLE *table)
{   
	SYM *sp;
  TYP *tp;
	int amt = 1;

  if(lastst == id) {
    if((sp = search(lastid,&tagtable)) == NULL) {
      sp = allocSYM();
      sp->tp = TYP::Make(bt_enum,1);
      sp->storage_class = sc_type;
      sp->SetName(*(new std::string(lastid)));
      sp->tp->sname = new std::string(*sp->name);
      NextToken();
      if(lastst != begin)
        error(ERR_INCOMPLETE);
      else {
				tagtable.insert(sp);
				NextToken();
				ParseEnumerationList(table,amt,sp);
      }
		}
    else
      NextToken();
    head = sp->tp;
  }
  else {
    tp = allocTYP();	// fix here
    tp->type = bt_enum;
		tp->size = 2;
		if (lastst==openpa) {
			NextToken();
			amt = (int)GetIntegerExpression((ENODE **)NULL);
			needpunc(closepa,10);
		}
    if( lastst != begin)
      error(ERR_INCOMPLETE);
    else {
      NextToken();
      ParseEnumerationList(table,amt,nullptr);
    }
    head = tp;
  }
}

void Declaration::ParseEnumerationList(TABLE *table, int amt, SYM *parent)
{
	int evalue;
  SYM *sp;
  evalue = 0;
  while(lastst == id) {
    sp = allocSYM();
    sp->SetName(*(new std::string(lastid)));
    sp->storage_class = sc_const;
    sp->tp = &stdconst;
		if (parent)
			sp->parent = parent->id;
		else
			sp->parent = 0;
    table->insert(sp);
    NextToken();
		if (lastst==assign) {
			NextToken();
			sp->value.i = GetIntegerExpression((ENODE **)NULL);
			evalue = (int)sp->value.i+amt;
		}
		else
			sp->value.i = evalue++;
    if(lastst == comma)
      NextToken();
    else if(lastst != end)
      break;
  }
  needpunc(end,48);
}
