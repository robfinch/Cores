// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2020  Robert Finch, Waterloo
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
extern TYP stdconst;
extern int parsingParameterList;
extern int funcdecl;
extern int isStructDecl;
extern bool isPrivate;

int16_t typeno = bt_last;

void StructDeclaration::ParseAttribute(SYM* sym)
{
  int opa_cnt = 0;

  NextToken();
  needpunc(openpa, 0);
  while (lastst == openpa) {
    NextToken();
    opa_cnt++;
  }
  do {
    switch (lastst) {
    case id:
      NextToken();
      break;
    }
  } while (lastst == comma);
  while (lastst == closepa) {
    NextToken();
    opa_cnt--;
    if (opa_cnt == 0)
      break;
  }
  needpunc(closepa, 0);
}


int StructDeclaration::Parse(TABLE* table, int ztype, SYM** sym)
{
  SYM *sp;
  TYP *tp;
	int ret;
	int psd;
	ENODE nd;
	ENODE *pnd = &nd;
  static int cnt = 0;
  char nmbuf[500];

  sp = nullptr;
	psd = isStructDecl;
	isStructDecl++;
	ret = 0;
	bit_offset = 0;
	bit_next = 0;
	bit_width = -1;
  if (lastst == kw_attribute)
    ParseAttribute(nullptr);
  if(lastst == id) {
    if((sp = tagtable.Find(lastid,false)) == NULL) {
      sp = allocSYM();
  		sp->SetName(*(new std::string(lastid)));
      sp->tp = allocTYP();
      sp->tp->type = (e_bt)ztype;
		  sp->tp->typeno = typeno++;
      sp->tp->lst.Clear();
      sp->storage_class = sc_type;
      sp->tp->sname = new std::string(*sp->name);
      sp->tp->alignment = 0;
      NextToken();

      for (;;) {
        if (lastst == kw_attribute)
          ParseAttribute(nullptr);
        else if (lastst == kw_align) {
          NextToken();
          sp->tp->alignment = (int)GetIntegerExpression(&pnd);
        }
        else
          break;
      }

			// Could be a forward structure declaration like:
			// struct buf;
			if (lastst==semicolon) {
				ret = 1;
        tagtable.insert(sp);
        table->insert(sp);
        NextToken();
			}
			// Defining a pointer to an unknown struct ?
			else if (lastst == star) {
        tagtable.insert(sp);
        table->insert(sp);
      }
      else if(lastst != begin)
        error(ERR_INCOMPLETE);
      else {
        tagtable.insert(sp);
        table->insert(sp);
        NextToken();
        ParseMembers(sp, ztype);
      }
    }
    // Else it is a known structure
		else {
      NextToken();
      for (;;) {
        if (lastst == kw_attribute)
          ParseAttribute(nullptr);
        else if (lastst == kw_align) {
          NextToken();
          sp->tp->alignment = (int)GetIntegerExpression(&pnd);
        }
        else
          break;
      }
			if (lastst==begin) {
        NextToken();
        ParseMembers(sp, ztype);
			}
		}
    head = sp->tp;
  }
  // Else there was no tag identifier
  else {
    sprintf(nmbuf, "__noname%d", cnt);
    cnt++;
    if ((sp = tagtable.Find(nmbuf, false)) == NULL) {
      sp = allocSYM();
      sp->SetName(*(new std::string(nmbuf)));
      sp->tp = allocTYP();
      sp->tp->type = (e_bt)ztype;
      sp->tp->typeno = typeno++;
      sp->tp->lst.Clear();
      sp->storage_class = sc_type;
      sp->tp->sname = new std::string(*sp->name);
      sp->tp->alignment = 0;

      for (;;) {
        if (lastst == kw_attribute)
          ParseAttribute(nullptr);
        else if (lastst == kw_align) {
          NextToken();
          sp->tp->alignment = (int)GetIntegerExpression(&pnd);
        }
        else
          break;
      }

      // Could be a forward structure declaration like:
      // struct buf;
      if (lastst == semicolon) {
        ret = 1;
        tagtable.insert(sp);
        table->insert(sp);
        NextToken();
      }
      // Defining a pointer to an unknown struct ?
      else if (lastst == star) {
        tagtable.insert(sp);
        table->insert(sp);
      }
      else if (lastst != begin)
        error(ERR_INCOMPLETE);
      else {
        tagtable.insert(sp);
        table->insert(sp);
        NextToken();
        ParseMembers(sp, ztype);
      }
    }
    // Else it is a known structure
    else {
      NextToken();
      for (;;) {
        if (lastst == kw_attribute)
          ParseAttribute(nullptr);
        else if (lastst == kw_align) {
          NextToken();
          sp->tp->alignment = (int)GetIntegerExpression(&pnd);
        }
        else
          break;
      }
      if (lastst == begin) {
        NextToken();
        ParseMembers(sp, ztype);
      }
    }
    head = sp->tp;
    goto xit;
    //***** DEAD code follows *****
    sp->SetName(*(new std::string(nmbuf)));
    cnt++;
    sp->tp = allocTYP();
    sp->tp->type = (e_bt)ztype;
    sp->tp->typeno = typeno++;
    sp->tp->lst.Clear();
    sp->storage_class = sc_type;
    sp->tp->sname = new std::string(*sp->name);
    sp->tp->alignment = 0;

    tp = allocTYP();
    tp->type = (e_bt)ztype;
	  tp->typeno = typeno++;
    tp->sname = new std::string("");

    if (lastst==kw_align) {
      NextToken();
      tp->alignment = (int)GetIntegerExpression(&pnd);
    }

    if( lastst != begin)
      error(ERR_INCOMPLETE);
    else {
			NextToken();
			ParseMembers(sp,ztype);
    }
    head = tp;
  }
xit:
for (;;) {
  if (lastst == kw_attribute)
    ParseAttribute(nullptr);
  else if (lastst == kw_align) {
    NextToken();
    sp->tp->alignment = (int)GetIntegerExpression(&pnd);
  }
  else
    break;
}
isStructDecl = psd;
  *sym = sp;
	return (ret);
}

void StructDeclaration::ParseMembers(SYM *sym, int ztype)
{
	int slc;
	bool priv;

	slc = 0;
	sym->tp->val_flag = 1;
	//	tp->val_flag = FALSE;
	while( lastst != end) {
		priv = isPrivate;
		isPrivate = false;    
		if(ztype == bt_struct || ztype==bt_class)
			slc += declare(sym,&(sym->tp->lst),sc_member,slc,ztype);
		else // union
			slc = imax(slc,declare(sym,&(sym->tp->lst),sc_member,0,ztype));
		isPrivate = priv;
	}
	bit_offset = 0;
	bit_next = 0;
	bit_width = -1;
	sym->tp->size = sym->tp->alignment ? sym->tp->alignment : slc;
	//ListTable(&tp->lst,0);
	NextToken();
}

