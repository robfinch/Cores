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
extern TYP stdconst;
extern int parsingParameterList;
extern int funcdecl;
extern int isStructDecl;
extern bool isPrivate;

int16_t typeno = bt_last;

int StructDeclaration::ParseTag(TABLE* table, e_bt ztype, SYM** sym)
{
  SYM* sp;
  ENODE nd;
  ENODE* pnd = &nd;
  int ret = 0;

  if ((sp = tagtable.Find(lastid, false)) == NULL) {
    sp = allocSYM();
    sp->SetName(*(new std::string(lastid)));
    sp->tp = allocTYP();
    sp->tp->type = (e_bt)ztype;
    sp->tp->typeno = typeno++;
    sp->tp->lst.Clear();
    sp->storage_class = sc_type;
    sp->tp->sname = new std::string(*sp->name);
    sp->tp->alignment = 0;
    tagtable.insert(sp);
    NextToken();

    ParseAttributes(sp);

    // Could be a forward structure declaration like:
    // struct buf;
    if (lastst == semicolon) {
      ret = 1;
      tagtable.insert(sp);
      table->insert(sp);
      NextToken();
      goto xit;
    }
    // Defining a pointer to an unknown struct ?
    if (lastst == star) {
      table->insert(sp);
      goto xit;
    }
    if (isTypedef) {
      table->insert(sp);
      if (lastst == id)
        NextToken();
      if (lastst == begin) {
        NextToken();
        ParseMembers(sp, ztype);
      }
      goto xit;
    }
    if (lastst != begin)
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
    ParseAttributes(sp);
    if (lastst == begin) {
      NextToken();
      ParseMembers(sp, ztype);
    }
    else if (lastst == star) {
      table->insert(sp);
      goto xit;
    }
  }
xit:
  *sym = sp;
  head = sp->tp;
  return (ret);
}

void StructDeclaration::ParseAttributes(SYM* sym)
{
  ENODE nd;
  ENODE* pnd = &nd;

  for (;;) {
    if (lastst == kw_attribute)
      ParseAttribute(nullptr);
    else if (lastst == kw_align) {
      NextToken();
      sym->tp->alignment = (int)GetIntegerExpression(&pnd, sym, 0);
    }
    else
      break;
  }
}

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


SYM* StructDeclaration::CreateSymbol(char *nmbuf, TABLE* table, e_bt ztype, int* ret)
{
  SYM* sp;
  ENODE nd;
  ENODE* pnd = &nd;

  sp = allocSYM();
  sp->SetName(*(new std::string(nmbuf)));
  sp->tp = allocTYP();
  sp->tp->type = (e_bt)ztype;
  sp->tp->typeno = typeno++;
  sp->tp->lst.Clear();
  sp->storage_class = sc_type;
  sp->tp->sname = new std::string(*sp->name);
  sp->tp->alignment = 0;

  ParseAttributes(sp);

  // Could be a forward structure declaration like:
  // struct buf;
  if (lastst == semicolon) {
    *ret = 1;
    tagtable.insert(sp);
    table->insert(sp);
    NextToken();
    goto xit;
  }
  // Defining a pointer to an unknown struct ?
  if (lastst == star) {
    table->insert(sp);
    goto xit;
  }
  if (isTypedef) {
    table->insert(sp);
    if (lastst == id)
      NextToken();
    if (lastst == begin) {
      NextToken();
      ParseMembers(sp, ztype);
    }
    goto xit;
  }
  if (lastst != begin)
    error(ERR_INCOMPLETE);
  else {
    tagtable.insert(sp);
    table->insert(sp);
    NextToken();
    ParseMembers(sp, ztype);
  }
xit:
  head = sp->tp;
  return (sp);
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
  head = tail = 0;
  if (lastst == kw_attribute)
    ParseAttribute(nullptr);
  if (lastst == id) {
    if (ParseTag(table, (e_bt)ztype, &sp))
      ret = 1;
  }
  // Else there was no tag identifier
  else {
    sprintf(nmbuf, "__noname_tag%d", cnt);
    cnt++;
    sp = CreateSymbol(nmbuf, table, (e_bt)ztype, &ret);
    isym = sp;
    // Else it is a known structure
    if (false) {
      NextToken();
      ParseAttributes(sp);
      if (lastst == begin) {
        NextToken();
        ParseMembers(sp, ztype);
      }
    }
    sp = isym;
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
      tp->alignment = (int)GetIntegerExpression(&pnd,sp,0);
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
    sp->tp->alignment = (int)GetIntegerExpression(&pnd,sp,0);
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
  SYM* sp;
  char nmbuf[300];
  static int nmx = 0;

	slc = 0;
	sym->tp->val_flag = 1;
	//	tp->val_flag = FALSE;
	while( lastst != end) {
		priv = isPrivate;
		isPrivate = false;    
		if(ztype == bt_struct || ztype==bt_class)
			slc += declare(sym,&(sym->tp->lst),sc_member,slc,ztype,&sp);
		else // union
			slc = imax(slc,declare(sym,&(sym->tp->lst),sc_member,0,ztype,&sp));
		isPrivate = priv;
	}
	bit_offset = 0;
	bit_next = 0;
	bit_width = -1;
	sym->tp->size = sym->tp->alignment ? sym->tp->alignment : slc;
	//ListTable(&tp->lst,0);
	NextToken();
  /*
  if (lastst != id) {
    sprintf_s(nmbuf, sizeof(nmbuf), "__noname_struct%d", nmx);
    nmx++;
    isym = allocSYM();
    isym->SetName(*(new std::string(nmbuf)));
    isym->tp = sym->tp;
  }
  */
}

