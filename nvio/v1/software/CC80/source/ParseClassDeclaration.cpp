// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// CC64 - Raptor64 'C' derived language compiler
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
extern int bit_next;
extern int bit_offset;
extern int bit_width;
extern int parsingParameterList;
extern int funcdecl;
extern int isStructDecl;

extern int16_t typeno;
extern int isTypedef;
extern std::string *classname;
extern bool isPrivate;
extern SYM *currentClass;

extern int roundSize(TYP *tp);

// Class declarations have the form:
//
//	class identifier [: base class]
//  {
//		class members
//	}
//
// We could also have a forward reference:
//
//	class identifier;
//
// Or a pointer to a class:
//
//	class *identifier;
//
int ClassDeclaration::Parse(int ztype)
{
    SYM *sp, *bcsp;
	int ret;
	int psd;
	ENODE nd;
	ENODE *pnd = &nd;
	char *idsave;
	int alignment;
  SYM *cls;

  cls = currentClass;
	dfs.puts("<ParseClassDeclaration>\n");
	alignment = 0;
	isTypedef = TRUE;
	NextToken();
	if (lastst != id) {
		error(ERR_SYNTAX);
		goto lxit;
	}
//	ws = allocSYM();
	idsave = my_strdup(lastid);
//	ws->name = idsave;
//	ws->storage_class = sc_typedef;
	// Passes lastid onto struct parsing

	psd = isStructDecl;
	isStructDecl++;
	ret = 0;
	bit_offset = 0;
	bit_next = 0;
	bit_width = -1;

  dfs.printf("---------------------------------");
  dfs.printf("Class decl:%s\n", lastid);
  dfs.printf("---------------------------------");
	if((sp = tagtable.Find(std::string(lastid),false)) == NULL) {
    sp = allocSYM();
    sp->SetName(*(new std::string(lastid)));
		sp->tp = nullptr;
    NextToken();
    dfs.printf("A");
		if (lastst == kw_align) {
      NextToken();
      alignment = (int)GetIntegerExpression(&pnd);
    }
    else
      alignment = AL_STRUCT;

		// Could be a forward structure declaration like:
		// struct buf;
		if (lastst==semicolon) {
      dfs.printf("B");
			ret = 1;
			printf("classdecl insert1\r\n");
      tagtable.insert(sp);
      NextToken();
		}
		// Defining a pointer to an unknown struct ?
		else if (lastst == star) {
      dfs.printf("C");
			printf("classdecl insert2\r\n");
      tagtable.insert(sp);
		}
		else if (lastst==colon) {
      dfs.printf("D");
			NextToken();
			// Absorb and ignore public/private keywords
			if (lastst == kw_public || lastst==kw_private)
				NextToken();
			if (lastst != id) {
				error(ERR_SYNTAX);
				goto lxit;
			}
			bcsp = tagtable.Find(std::string(lastid),false);
			if (bcsp==nullptr) {
				error(ERR_UNDEFINED);
				goto lxit;
			}
      dfs.printf("E");
			// Copy the type chain of base class
			//sp->tp = TYP::Copy(bcsp->tp);
			// Start off at the size of the base.
			sp->tp = allocTYP();
			sp->tp->lst.SetBase(bcsp->GetIndex());
			dfs.printf("Set base class: %d\n", sp->tp->lst.base);
			sp->tp->size = bcsp->tp->size;
			sp->tp->type = (e_bt)ztype;
			sp->tp->typeno = typeno++;
      sp->tp->sname = new std::string(*sp->name);
      sp->tp->alignment = alignment;
	    sp->storage_class = sc_type;
			NextToken();
			if (lastst != begin) {
        error(ERR_INCOMPLETE);
				goto lxit;
			}
			/*
			sp->tp = allocTYP();
			sp->tp->typeno = typeno++;
      sp->tp->sname =  new std::string(*sp->name);
      sp->tp->alignment = alignment;
			sp->tp->type = (e_bt)ztype;
			sp->tp->lst.SetBase(bcsp->GetIndex());
	    sp->storage_class = sc_type;
	    */
      tagtable.insert(sp);
      NextToken();
      currentClass = sp;
      dfs.printf("f");
      ParseMembers(sp,ztype);
      dfs.printf("G");
		}
    else if(lastst != begin)
      error(ERR_INCOMPLETE);
    else {
			if (sp->tp == nullptr) {
				sp->tp = allocTYP();
			}
			sp->tp->size = 0;
			sp->tp->typeno = typeno++;
      sp->tp->sname = new std::string(*sp->name);
      sp->tp->alignment = alignment;
			sp->tp->type = (e_bt)ztype;
			sp->tp->lst.SetBase(0);
	    sp->storage_class = sc_type;
      tagtable.insert(sp);
      NextToken();
      currentClass = sp;
      ParseMembers(sp,ztype);
    }
  }
  // Else the class was found in the tag table.
	else {
    NextToken();
    if (lastst==kw_align) {
	    NextToken();
      sp->tp->alignment = (int)GetIntegerExpression(&pnd);
    }
		if (lastst==begin) {
        NextToken();
        currentClass = sp;
        ParseMembers(sp,ztype);
		}
	}
  head = sp->tp;
	isStructDecl = psd;
lxit:
	isTypedef = TRUE;
	if (classname) delete classname;
	classname = new std::string(idsave);
	currentClass = cls;
	dfs.puts("</ParseClassDeclaration>\n");
	return ret;
}

void ClassDeclaration::ParseMembers(SYM *sym, int ztype)
{
	int slc;
	TYP *tp = sym->tp;
	int ist;
	SYM *hsym;
	std::string *name;

	isPrivate = true;
	if (sym->tp->size)
		slc = sym->tp->roundSize();
	else
		slc = 0;

//	slc = 0;
  tp->val_flag = 1;
//	tp->val_flag = FALSE;
	ist = isTypedef;
	isTypedef = false;

	// First add a hidden member that indicates the class number. The type
	// number is used during virtual function calls to determine which
	// method to call. This is the first field in the class so it can be
	// refeerenced as 0[r25].
	hsym = allocSYM();
	name = new std::string("_typeno");
  hsym->SetName(*name);
	hsym->storage_class = sc_member;
	hsym->value.i = sym->tp->typeno;
	hsym->tp = TYP::Make(bt_char,2);
  hsym->tp->sname = new std::string("_typeno");
  hsym->tp->alignment = 2;
	tp->lst.insert(hsym);
  slc += 2;

  while( lastst != end) {
		if (lastst==kw_public)
			isPrivate = false;
		if (lastst==kw_private)
			isPrivate = true;
		if (lastst==kw_public || lastst==kw_private) {
			NextToken();
			if (lastst==colon)
				NextToken();
		}
		if (lastst==kw_unique || lastst==kw_static) {
			NextToken();
      declare(sym,&(tp->lst),sc_static,slc,ztype);
		}
		else {
			if(ztype == bt_struct || ztype==bt_class)
				slc += declare(sym,&(tp->lst),sc_member,slc,ztype);
			else
				slc = imax(slc,declare(sym,&(tp->lst),sc_member,0,ztype));
		}
  }
	bit_offset = 0;
	bit_next = 0;
	bit_width = -1;
  tp->size = tp->alignment ? tp->alignment : slc;
  NextToken();
	isTypedef = ist;
}

