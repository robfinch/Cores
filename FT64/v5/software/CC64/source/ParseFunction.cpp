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

SYM *makeint(char *name);

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

void funcbottom(Statement *stmt);
void ListCompound(Statement *stmt);

static int round2(int n)
{
    while (n & 1) n++;
    return (n);
}

static int round8(int n)
{
    while (n & 7) n++;
    return (n);
}

// Return the stack offset where parameter storage begins.
int GetReturnBlockSize()
{
	return (4*sizeOfWord);
	if (currentFn) {
		if (currentFn->IsLeaf) {
		    return (exceptions ? sizeOfWord*3 : sizeOfWord);
		}
	}
	else
		throw new C64PException(ERR_NULLPOINTER,'R');
    return (exceptions ? sizeOfWord*3 : sizeOfWord);
}

static bool SameType(TYP *tp1, TYP *tp2)
{
	bool ret = false;

//	printf("Enter SameType\r\n");
	while(false) {
		if (tp1->type == tp2->type) {
			if (!tp1->GetBtp() && !tp2->GetBtp()) {
				ret = true;
				break;
			}
			if (tp1->GetBtp() && !tp2->GetBtp()) {
				ret = false;
				break;
			}
			if (!tp1->GetBtp() && tp2->GetBtp()) {
				ret = false;
				break;
			}
			ret = SameType(tp1->GetBtp(),tp2->GetBtp());
			break;
		}
		else {
			ret = false;
			break;
		}
	}

//	printf("Leave SameType\r\n");
	return ret;
}

SYM *makeint(char *name)
{  
	SYM *sp;
	TYP *tp;

	sp = allocSYM();
	tp = TYP::Make(bt_long,2);
	tp->sname = new std::string("");
	tp->isUnsigned = FALSE;
	tp->isVolatile = FALSE;
	sp->SetName(name);
	sp->storage_class = sc_auto;
	sp->SetType(tp);
	currentFn->sym->lsyms.insert(sp);
	return sp;
}

void check_table(SYM *head)
{   
	while( head != 0 ) {
		if( head->storage_class == sc_ulabel )
			lfs.printf("*** UNDEFINED LABEL - %s\n",(char *)head->name->c_str());
		head = head->GetNextPtr();
	}
}

void funcbottom(Statement *stmt)
{ 
	dfs.printf("Enter funcbottom\n");
	nl();
    check_table(SYM::GetPtr(currentFn->sym->lsyms.GetHead()));
    lc_auto = 0;
    lfs.printf("\n\n*** local symbol table ***\n\n");
    ListTable(&currentFn->sym->lsyms,0);
	// Should recurse into all the compound statements
	if (stmt==NULL)
		dfs.printf("DIAG: null statement in funcbottom.\r\n");
	else {
		if (stmt->stype==st_compound)
			ListCompound(stmt);
	}
    lfs.printf("\n\n\n");
//    ReleaseLocalMemory();        // release local symbols
	isPascal = FALSE;
	isKernel = FALSE;
	isOscall = FALSE;
	isInterrupt = FALSE;
	isNocall = FALSE;
	dfs.printf("Leave funcbottom\n");
}

std::string TraceName(SYM *sp)
{
  std::string namebuf;
  SYM *vector[64];
  int deep = 0;

  do {
    vector[deep] = sp;
    sp = sp->GetParentPtr();
    deep++;
    if (deep > 63) {
      break; // should be an error
    }
  } while (sp);
  deep--;
  namebuf = "";
  while(deep > 0) {
    namebuf += *vector[deep]->name;
    namebuf += "_";
    deep--;
  }
  namebuf += *vector[deep]->name;
  return namebuf;
}

int TempBot()
{
	return (currentFn->tempbot);
}

