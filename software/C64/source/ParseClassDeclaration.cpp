// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Stratford
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
extern char *classname;
extern bool isPrivate;

extern int roundSize(TYP *tp);
static void ParseClassMembers(SYM * sym, int ztype);
void CopySymbolTable(TABLE *dst, TABLE *src);

TYP *CopyType(TYP *src)
{
	TYP *dst;
	dst = allocTYP();
//	if (dst==nullptr)
//		throw gcnew C64::C64Exception();
	memcpy(dst,src,sizeof(TYP));
	if (src->btp) {
		dst->btp = CopyType(src->btp);
	}
	dst->lst.head = 0;
	dst->lst.tail = 0;
	CopySymbolTable(&dst->lst,&src->lst);
	return dst;
}

SYM *CopySymbol(SYM *src)
{
	SYM *dst;

	dst = allocSYM();
//	if (dst==nullptr)
//		throw gcnew C64::C64Exception();
	memcpy(dst, src, sizeof(SYM));
	dst->tp = CopyType(src->tp);
	dst->next = nullptr;
	return dst;
}

void CopySymbolTable(TABLE *dst, TABLE *src)
{
	SYM *sp, *newsym;
	sp = src->head;
	while (sp) {
		newsym = CopySymbol(sp);
		insert(newsym,dst);
		sp = sp->next;
	}
}

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
int ParseClassDeclaration(int ztype)
{
    SYM *sp, *bcsp;
    TYP *tp;
	int gblflag;
	int ret;
	int psd;
	ENODE nd;
	ENODE *pnd = &nd;
	char *idsave;
	int alignment;

	alignment = 0;
	isTypedef = TRUE;
	NextToken();
	if (lastst != id) {
		error(ERR_SYNTAX);
		goto lxit;
	}
//	ws = allocSYM();
	idsave = litlate(lastid);
//	ws->name = idsave;
//	ws->storage_class = sc_typedef;
	// Passes lastid onto struct parsing

	psd = isStructDecl;
	isStructDecl++;
	ret = 0;
	bit_offset = 0;
	bit_next = 0;
	bit_width = -1;

	if((sp = search(lastid,&tagtable)) == NULL) {
		// If we encounted an unknown struct in a parameter list, we want
		// it to go into the global memory pool, not a local one.
		if (parsingParameterList) {
			gblflag = global_flag;
			global_flag++;
	        sp = allocSYM();
			sp->name = litlate(lastid);
			global_flag = gblflag;
		}
		else {
	        sp = allocSYM();
			sp->name = litlate(lastid);
		}
		sp->tp = nullptr;
        NextToken();

		if (lastst == kw_align) {
            NextToken();
            alignment = GetIntegerExpression(&pnd);
        }

		// Could be a forward structure declaration like:
		// struct buf;
		if (lastst==semicolon) {
			ret = 1;
            insert(sp,&tagtable);
            NextToken();
		}
		// Defining a pointer to an unknown struct ?
		else if (lastst == star) {
            insert(sp,&tagtable);
		}
		else if (lastst==colon) {
			NextToken();
			// Absorb and ignore public/private keywords
			if (lastst == kw_public || lastst==kw_private)
				NextToken();
			if (lastst != id) {
				error(ERR_SYNTAX);
				goto lxit;
			}
			bcsp = search(lastid,&tagtable);
			if (bcsp==nullptr) {
				error(ERR_UNDEFINED);
				goto lxit;
			}
			// Copy the type chain of base class
			sp->tp = CopyType(bcsp->tp);
			NextToken();
			if (lastst != begin) {
	            error(ERR_INCOMPLETE);
				goto lxit;
			}
			sp->tp->typeno = typeno++;
	        sp->tp->sname = sp->name;
		    sp->tp->alignment = alignment;
			sp->tp->type = (e_bt)ztype;
		    sp->storage_class = sc_type;
            insert(sp,&tagtable);
            NextToken();
            ParseClassMembers(sp,ztype);
		}
        else if(lastst != begin)
            error(ERR_INCOMPLETE);
        else    {
			if (sp->tp == nullptr) {
				sp->tp = allocTYP();
				sp->tp->lst.head = 0;
				sp->tp->lst.tail = 0;
				sp->tp->size = 0;
			}
			sp->tp->typeno = typeno++;
	        sp->tp->sname = sp->name;
		    sp->tp->alignment = alignment;
			sp->tp->type = (e_bt)ztype;
		    sp->storage_class = sc_type;
            insert(sp,&tagtable);
            NextToken();
            ParseClassMembers(sp,ztype);
            }
    }
	else {
        NextToken();
        if (lastst==kw_align) {
	        NextToken();
            sp->tp->alignment = GetIntegerExpression(&pnd);
        }
		if (lastst==begin) {
	        NextToken();
            ParseClassMembers(sp,ztype);
		}
	}
    head = sp->tp;
	isStructDecl = psd;
lxit:
	isTypedef = TRUE;
	classname = idsave;
	return ret;
}

static void ParseClassMembers(SYM * sym, int ztype)
{
	int slc;
	TYP *tp = sym->tp;
	int ist;

	isPrivate = true;
    slc = roundSize(sym->tp);
//	slc = 0;
    tp->val_flag = 1;
//	tp->val_flag = FALSE;
	ist = isTypedef;
	isTypedef = false;
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
				slc = imax(slc,declare(sym,&tp->lst,sc_member,0,ztype));
		}
    }
	bit_offset = 0;
	bit_next = 0;
	bit_width = -1;
    tp->size = tp->alignment ? tp->alignment : slc;
    NextToken();
	isTypedef = ist;
}

