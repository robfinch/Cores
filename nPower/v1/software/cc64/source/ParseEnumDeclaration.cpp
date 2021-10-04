// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2021  Robert Finch, Waterloo
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

SYM* FindEnum(char *txt)
{
  SYM* sp;

  sp = search(std::string(txt), &tagtable);
  if (sp == nullptr)
    return (nullptr);
  if (sp->tp->type == bt_enum)
    return (sp);
  return (nullptr);
}


void Declaration::ParseEnum(TABLE *table)
{   
	SYM *sp;
  TYP *tp;
	int amt = 1;
  bool power = false;

  if(lastst == id) {
    if((sp = search(std::string(lastid),&tagtable)) == NULL) {
      sp = allocSYM();
      sp->tp = TYP::Make(bt_enum,1);
      sp->storage_class = sc_type;
      sp->SetName(*(new std::string(lastid)));
      sp->tp->sname = new std::string(*sp->name);
      NextToken();
      if (lastst == openpa) {
        NextToken();
        if (lastst == star) {
          NextToken();
          power = true;
        }
        amt = (int)GetIntegerExpression((ENODE**)NULL, nullptr, 0);
        needpunc(closepa, 10);
      }
      if (lastst != begin)
        ;// error(ERR_INCOMPLETE);
      else {
				tagtable.insert(sp);
				NextToken();
				ParseEnumerationList(table,amt,sp,power);
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
      if (lastst == star) {
        NextToken();
        power = true;
      }
      amt = (int)GetIntegerExpression((ENODE **)NULL,nullptr,0);
			needpunc(closepa,10);
		}
    if( lastst != begin)
      error(ERR_INCOMPLETE);
    else {
      NextToken();
      ParseEnumerationList(table,amt,nullptr,power);
    }
    head = tp;
  }
}

void Declaration::ParseEnumerationList(TABLE *table, int amt, SYM *parent, bool power)
{
	int16_t evalue;
  SYM *sp;
  if (power)
    evalue = 1;
  else
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
			sp->value.i = GetIntegerExpression((ENODE **)NULL,sp,0);
			evalue = (int)sp->value.i;
		}
		else
			sp->value.i = evalue;
    if(lastst == comma)
      NextToken();
    else if(lastst != end)
      break;
    if (power)
      evalue *= amt;
    else
      evalue += amt;
  }
  needpunc(end,48);
}
