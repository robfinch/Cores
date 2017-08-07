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

extern TABLE tagtable;
extern TYP *head;
extern TYP *stdconst;
extern int bit_next;
extern int bit_offset;
extern int bit_width;
extern int parsingParameterList;
extern int funcdecl;
extern int isStructDecl;
extern bool isPrivate;

int16_t typeno = bt_last;

int StructDeclaration::Parse(int ztype)
{
  SYM *sp;
  TYP *tp;
	int ret;
	int psd;
	ENODE nd;
	ENODE *pnd = &nd;

  sp = nullptr;
	psd = isStructDecl;
	isStructDecl++;
	ret = 0;
	bit_offset = 0;
	bit_next = 0;
	bit_width = -1;
  if(lastst == id) {
    if((sp = tagtable.Find(lastid,false)) == NULL) {
      sp = allocSYM();
  		sp->SetName(*(new std::string(lastid)));
      sp->tp = TYP::alloc();
      sp->tp->type = (e_bt)ztype;
		  sp->tp->typeno = typeno++;
      sp->tp->lst.Clear();
      sp->storage_class = sc_type;
      sp->tp->sname = new std::string(*sp->name);
      sp->tp->alignment = 0;
      NextToken();

			if (lastst == kw_align) {
        NextToken();
        sp->tp->alignment = GetIntegerExpression(&pnd);
      }

			// Could be a forward structure declaration like:
			// struct buf;
			if (lastst==semicolon) {
				ret = 1;
        tagtable.insert(sp);
        NextToken();
			}
			// Defining a pointer to an unknown struct ?
			else if (lastst == star) {
        tagtable.insert(sp);
			}
      else if(lastst != begin)
        error(ERR_INCOMPLETE);
      else {
        tagtable.insert(sp);
        NextToken();
        ParseMembers(sp, sp->tp,ztype);
      }
    }
    // Else it is a known structure
		else {
      NextToken();
      if (lastst==kw_align) {
        NextToken();
        sp->tp->alignment = GetIntegerExpression(&pnd);
      }
			if (lastst==begin) {
        NextToken();
        ParseMembers(sp,sp->tp,ztype);
			}
		}
    head = sp->tp;
  }
  // Else there was no tag identifier
  else {
    tp = TYP::alloc();
    tp->type = (e_bt)ztype;
	  tp->typeno = typeno++;
    tp->sname = new std::string("");

    if (lastst==kw_align) {
      NextToken();
      tp->alignment = GetIntegerExpression(&pnd);
    }

    if( lastst != begin)
      error(ERR_INCOMPLETE);
    else {
			NextToken();
			ParseMembers(sp,tp,ztype);
    }
    head = tp;
  }
	isStructDecl = psd;
	return ret;
}

void StructDeclaration::ParseMembers(SYM * sym, TYP *tp, int ztype)
{
	int slc;
  bool priv;

  slc = 0;
  tp->val_flag = 1;
//	tp->val_flag = FALSE;
  while( lastst != end) {
    priv = isPrivate;
    isPrivate = false;    
    if(ztype == bt_struct || ztype==bt_class)
      slc += declare(sym,&(tp->lst),sc_member,slc,ztype);
    else
      slc = imax(slc,declare(sym,&tp->lst,sc_member,0,ztype));
    isPrivate = priv;
  }
	bit_offset = 0;
	bit_next = 0;
	bit_width = -1;
  tp->size = tp->alignment ? tp->alignment : slc;
  NextToken();
}

