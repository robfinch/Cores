// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - 'C' derived language compiler
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

#define EXPR_DEBUG
extern SYM *currentClass;
static int isscalar(TYP *tp);
static unsigned char sizeof_flag = 0;
static TYP *ParseCastExpression(ENODE **node);
TYP *forcefit(ENODE **node1,TYP *tp1,ENODE **node2,TYP *tp2);
extern void backup();
extern char *inpline;
extern int parsingParameterList;
extern char *TraceName(SYM *);
extern SYM *gsearch2(std::string , __int16, TypeArray *,bool);
extern SYM *search2(std::string na,TABLE *tbl,TypeArray *typearray);
extern int GetReturnBlockSize();
extern int round8(int n);

ENODE *pep1;
TYP *ptp1;	// the type just previous to the last dot
int pop;   // the just previous operator.

// Tells subsequent levels that ParseCastExpression already fetched a token.
//static unsigned char expr_flag = 0;

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

TYP             stdint;
TYP             stduint;
TYP             stdlong;
TYP             stdulong;
TYP             stdshort;
TYP             stdushort;
TYP             stdchar;
TYP             stduchar;
TYP             stdbyte;
TYP             stdubyte;
TYP             stdstring;
TYP				stddbl;
TYP				stdtriple;
TYP				stdflt;
TYP				stddouble;
TYP             stdfunc;
TYP             stdexception;
extern TYP      *head;          /* shared with ParseSpecifier */
extern TYP	*tail;

/*
 *      expression evaluation
 *
 *      this set of routines builds a parse tree for an expression.
 *      no code is generated for the expressions during the build,
 *      this is the job of the codegen module. for most purposes
 *      expression() is the routine to call. it will allow all of
 *      the C operators. for the case where the comma operator is
 *      not valid (function parameters for instance) call NonCommaExpression().
 *
 *      each of the routines returns a pointer to a describing type
 *      structure. each routine also takes one parameter which is a
 *      pointer to an expression node by reference (address of pointer).
 *      the completed expression is returned in this pointer. all
 *      routines return either a pointer to a valid type or NULL if
 *      the hierarchy of the next operator is too low or the next
 *      symbol is not part of an expression.
 */

TYP     *expression();  /* forward ParseSpecifieraration */
TYP     *NonCommaExpression();      /* forward ParseSpecifieraration */
TYP     *ParseUnaryExpression();       /* forward ParseSpecifieraration */

int nest_level = 0;
bool isMember;

void Enter(char *p)
{
/*
  int nn;
     
  for (nn = 0; nn < nest_level && nn < 60; nn++)
    printf("  ");
  printf("%s: %d\r\n", p, lineno);
  nest_level++;
*/
}
void Leave(char *p, int n)
{
/*
     int nn;
     
     nest_level--;
     for (nn = 0; nn < nest_level; nn++)
         printf("   ");
     printf("%s (%d)\r\n", p, n);
*/
}

/*
 *      build an expression node with a node type of nt and values
 *      v1 and v2.
 */
ENODE *makenode(int nt, ENODE *v1, ENODE *v2)
{
	ENODE *ep;
  ep = (ENODE *)xalloc(sizeof(ENODE));
  ep->nodetype = (enum e_node)nt;
  ep->constflag = FALSE;
	ep->isUnsigned = FALSE;
	ep->etype = bt_void;
	ep->esize = -1;
	ep->p[0] = v1;
	ep->p[1] = v2;
	ep->p[2] = 0;
    return ep;
}

ENODE *makefcnode(int nt, ENODE *v1, ENODE *v2, SYM *sp)
{
	ENODE *ep;
  ep = (ENODE *)xalloc(sizeof(ENODE));
  ep->nodetype = (enum e_node)nt;
  ep->sym = sp;
  ep->constflag = FALSE;
	ep->isUnsigned = FALSE;
	ep->etype = bt_void;
	ep->esize = -1;
	ep->p[0] = v1;
	ep->p[1] = v2;
	ep->p[2] = 0;
  return ep;
}

ENODE *makesnode(int nt, std::string *v1, std::string *v2, __int64 i)
{
	ENODE *ep;
  ep = allocEnode();
  ep->nodetype = (enum e_node)nt;
  ep->constflag = FALSE;
	ep->isUnsigned = FALSE;
	ep->etype = bt_void;
	ep->esize = -1;
	ep->sp = v1;
  ep->msp = v2;
	ep->i = i;
	ep->p[0] = 0;
	ep->p[1] = 0;
	ep->p[2] = 0;
  return ep;
}

ENODE *makenodei(int nt, ENODE *v1, __int64 i)
{
	ENODE *ep;
  ep = allocEnode();
  ep->nodetype = (enum e_node)nt;
  ep->constflag = FALSE;
	ep->isUnsigned = FALSE;
	ep->etype = bt_void;
	ep->esize = -1;
	ep->i = i;
	ep->p[0] = v1;
	ep->p[1] = (ENODE *)NULL;
	ep->p[2] = 0;
    return ep;
}

ENODE *makeinode(int nt, int64_t v1)
{
	ENODE *ep;
  ep = allocEnode();
  ep->nodetype = (enum e_node)nt;
  ep->constflag = TRUE;
	ep->isUnsigned = FALSE;
	ep->etype = bt_void;
	ep->esize = -1;
  ep->i = v1;
	ep->p[1] = 0;
	ep->p[0] = 0;
	ep->p[2] = 0;
    return ep;
}

ENODE *makefnode(int nt, double v1)
{
	ENODE *ep;
  ep = allocEnode();
  ep->nodetype = (enum e_node)nt;
  ep->constflag = TRUE;
	ep->isUnsigned = FALSE;
	ep->etype = bt_void;
	ep->esize = -1;
	ep->f = v1;
  ep->f1 = v1;
//    ep->f2 = v2;
	ep->p[0] = 0;
	ep->p[1] = 0;
	ep->p[2] = 0;
  return ep;
}

bool IsMemberOperator(int op)
{
  return op==dot || op==pointsto || op==double_colon;
}

bool IsClassExpr()
{
  TYP *tp;

	if (pep1) {// && IsMemberOperator(pop)) {
		if (pep1->tp) {
			if (pep1->tp->type==bt_class){
				return true;
			}
			else if (pep1->tp->type==bt_pointer) {
			  tp = pep1->tp->GetBtp();
			  if (tp==nullptr)
			     throw new C64PException(ERR_NULLPOINTER,4);
				if (tp->type==bt_class) {
					return true;
				}
			}
		}
	}
	return false;
}

void PromoteConstFlag(ENODE *ep)
{
  if (ep->p[0]==nullptr || ep->p[1]==nullptr) {
    ep->constflag = false;
    return;
  }
	ep->constflag = ep->p[0]->constflag && ep->p[1]->constflag;
}

/*
 *      build the proper dereference operation for a node using the
 *      type pointer tp.
 */
TYP *deref(ENODE **node, TYP *tp)
{
  dfs.printf("Enter Deref");
  if (tp==nullptr || node==nullptr || *node==nullptr)
    throw new C64PException(ERR_NULLPOINTER,8);
	switch( tp->type ) {
		case bt_byte:
			if (tp->isUnsigned) {
				*node = makenode(en_ub_ref,*node,(ENODE *)NULL);
				(*node)->isUnsigned = TRUE;
			}
			else {
				*node = makenode(en_b_ref,*node,(ENODE *)NULL);
			}
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
			if (tp->isUnsigned)
	            tp = &stdubyte;//&stduint;
			else
	            tp = &stdbyte;//&stdint;
            break;
		case bt_ubyte:
			*node = makenode(en_ub_ref,*node,(ENODE *)NULL);
			(*node)->isUnsigned = TRUE;
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
            tp = &stdubyte;//&stduint;
            break;
		case bt_uchar:
		case bt_char:
        case bt_enum:
			if (tp->isUnsigned) {
				*node = makenode(en_uc_ref,*node,(ENODE *)NULL);
				(*node)->isUnsigned = TRUE;
			}
			else
				*node = makenode(en_c_ref,*node,(ENODE *)NULL);
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
			if (tp->isUnsigned)
	            tp = &stduchar;
			else
	            tp = &stdchar;
            break;
		case bt_ushort:
		case bt_short:
			if (tp->isUnsigned) {
				*node = makenode(en_uh_ref,*node,(ENODE *)NULL);
				(*node)->esize = tp->size;
				(*node)->etype = (enum e_bt)tp->type;
				(*node)->isUnsigned = TRUE;
				tp = &stduint;
			}
			else {
				*node = makenode(en_h_ref,*node,(ENODE *)NULL);
				(*node)->esize = tp->size;
				(*node)->etype = (enum e_bt)tp->type;
				tp = &stdint;
			}
      break;
		case bt_exception:
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
			(*node)->isUnsigned = TRUE;
			*node = makenode(en_uw_ref,*node,(ENODE *)NULL);
            break;

		case bt_ulong:
		case bt_long:
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
			if (tp->isUnsigned) {
				(*node)->isUnsigned = TRUE;
				*node = makenode(en_uw_ref,*node,(ENODE *)NULL);
			}
			else {
				*node = makenode(en_w_ref,*node,(ENODE *)NULL);
			}
      break;

		case bt_pointer:
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
            *node = makenode(en_uw_ref,*node,(ENODE *)NULL);
			(*node)->isUnsigned = TRUE;
            break;

		case bt_unsigned:
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
            *node = makenode(en_uw_ref,*node,(ENODE *)NULL);
			(*node)->isUnsigned = TRUE;
            break;

    case bt_triple:
            *node = makenode(en_triple_ref,*node,(ENODE *)NULL);
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
            tp = &stdtriple;
            break;
        case bt_double:
            *node = makenode(en_dbl_ref,*node,(ENODE *)NULL);
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
			(*node)->isDouble = TRUE;
            tp = &stddbl;
            break;
        case bt_float:
            *node = makenode(en_flt_ref,*node,(ENODE *)NULL);
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
            tp = &stdflt;
            break;
		case bt_bitfield:
			if (tp->isUnsigned){
				if (tp->size==1)
					*node = makenode(en_ubfieldref, *node, (ENODE *)NULL);
				else if (tp->size==2)
					*node = makenode(en_ucfieldref, *node, (ENODE *)NULL);
				else if (tp->size==4)
					*node = makenode(en_uhfieldref, *node, (ENODE *)NULL);
				else
					*node = makenode(en_wfieldref, *node, (ENODE *)NULL);
				(*node)->isUnsigned = TRUE;
			}
			else {
				if (tp->size==1)
					*node = makenode(en_bfieldref, *node, (ENODE *)NULL);
				else if (tp->size==2)
					*node = makenode(en_cfieldref, *node, (ENODE *)NULL);
				else if (tp->size==4)
					*node = makenode(en_hfieldref, *node, (ENODE *)NULL);
				else
					*node = makenode(en_wfieldref, *node, (ENODE *)NULL);
			}
			(*node)->bit_width = tp->bit_width;
			(*node)->bit_offset = tp->bit_offset;
			/*
			* maybe it should be 'unsigned'
			*/
			(*node)->etype = (enum e_bt)stdint.type;
			(*node)->esize = tp->size;
			tp = &stdint;
			break;
		//case bt_func:
		//case bt_ifunc:
		//	(*node)->esize = tp->size;
		//	(*node)->etype = tp->type;
		//	(*node)->isUnsigned = TRUE;
		//	*node = makenode(en_uw_ref,*node,NULL);
  //          break;
		case bt_class:
		case bt_struct:
		case bt_union:
		  dfs.printf("F");
			(*node)->esize = tp->size;
			(*node)->etype = (e_bt)tp->type;
      *node = makenode(en_struct_ref,*node,NULL);
			(*node)->isUnsigned = TRUE;
      break;
		default:
		  dfs.printf("Deref :%d\n", tp->type);
		  if ((*node)->msp)
		     dfs.printf("%s\n",(char *)(*node)->msp->c_str());
			error(ERR_DEREF);
			break;
    }
	(*node)->isVolatile = tp->isVolatile;
  dfs.printf("Leave Deref");
    return tp;
}

/*
* dereference the node if val_flag is zero. If val_flag is non_zero and
* tp->type is bt_pointer (array reference) set the size field to the
* pointer size if this code is not executed on behalf of a sizeof
* operator
*/
TYP *CondDeref(ENODE **node, TYP *tp)
{
  TYP *tp1;
  long sz;
  
  if (tp->val_flag == 0)
    return deref(node, tp);
  if (tp->type == bt_pointer && sizeof_flag == 0) {
   	sz = tp->size;
    tp1 = tp->GetBtp();
    if (tp1==NULL)
      printf("DIAG: CondDeref: tp1 is NULL\r\n");
    tp =(TYP *) TYP::Make(bt_pointer, 8);
    tp->btp = tp1->GetIndex();
    tp->size2 = sz;
  }
  else if (tp->type==bt_pointer)
    return tp;
  //    else if (tp->type==bt_struct || tp->type==bt_union)
  //       return deref(node, tp);
  return tp;
}


/*
 *      nameref will build an expression tree that references an
 *      identifier. if the identifier is not in the global or
 *      local symbol table then a look-ahead to the next character
 *      is done and if it indicates a function call the identifier
 *      is coerced to an external function name. non-value references
 *      generate an additional level of indirection.
 */
TYP *nameref2(std::string name, ENODE **node,int nt,bool alloc,TypeArray *typearray, TABLE *tbl)
{
	SYM *sp;
    TYP *tp;
	std::string stnm;

	dfs.puts("<nameref2>\n");
	if (tbl) {
		dfs.printf("searching table for:%d:%s|",TABLE::matchno,(char *)name.c_str());
		tbl->Find(name,bt_long,typearray,true);
//		gsearch2(name,bt_long,typearray,true);
		sp = SYM::FindExactMatch(TABLE::matchno, name, bt_long, typearray);
//		if (sp==nullptr) {
//			printf("notfound\r\n");
//			sp = gsearch2(name,bt_long,typearray,false);
//		}
	}
	else {
	dfs.printf("A:%d:%s",TABLE::matchno,(char *)name.c_str());
		sp = SYM::FindExactMatch(TABLE::matchno, name, bt_long, typearray);
//		memset(typearray,0,sizeof(typearray));
//		sp = gsearch2(name,typearray);
	}
	if (sp==nullptr && !alloc) {
		dfs.printf("returning nullptr");
		*node = makeinode(en_labcon,9999);
		tp = nullptr;
		goto xit;
	}
	if( sp == NULL ) {
	  int nn;
    while( my_isspace(lastch) )
      getch();
    if( lastch == '(') {
      sp = allocSYM();
      sp->tp = &stdfunc;
      sp->SetName(*(new std::string(lastid)));
      sp->storage_class = sc_external;
      sp->IsUndefined = TRUE;
			dfs.printf("Insert at nameref\r\n");
			typearray->Print();
      //    gsyms[0].insert(sp);
      tp = &stdfunc;
      *node = makesnode(en_cnacon,sp->name,sp->BuildSignature(),sp->value.i);
      (*node)->constflag = TRUE;
      (*node)->sym = sp;
			if (sp->tp->isUnsigned)
				(*node)->isUnsigned = TRUE;
			(*node)->esize = 8;
    }
    else {
			dfs.printf("Undefined symbol2 in nameref\r\n");
      tp = (TYP *)NULL;
      *node = makeinode(en_labcon,9999);
      error(ERR_UNDEFINED);
    }
  }
  else {
    int nn;
    dfs.printf("sp is not null\n");
    typearray->Print();
    if( (tp = sp->tp) == NULL ) {
      error(ERR_UNDEFINED);
      goto xit;            // guard against untyped entries
    }
    switch( sp->storage_class ) {
    case sc_static:
			if (sp->tp->type==bt_func || sp->tp->type==bt_ifunc) {
					//strcpy(stnm,GetNamespace());
					//strcat(stnm,"_");
					stnm = "";
					stnm += *sp->name;
					*node = makesnode(en_cnacon,&stnm,sp->BuildSignature(),sp->value.i);
					(*node)->constflag = TRUE;
					(*node)->esize = 8;
					//*node = makesnode(en_nacon,sp->name);
					//(*node)->constflag = TRUE;
				}
				else {
					*node = makeinode(en_labcon,sp->value.i);
					(*node)->constflag = TRUE;
					(*node)->esize = sp->tp->size;//8;
				}
				if (sp->tp->isUnsigned) {
					(*node)->isUnsigned = TRUE;
					(*node)->esize = sp->tp->size;
				}
				(*node)->etype = bt_pointer;//sp->tp->type;
				(*node)->isDouble = sp->tp->type==bt_double;
      break;

		case sc_thread:
  		*node = makeinode(en_labcon,sp->value.i);
  		(*node)->constflag = TRUE;
  		(*node)->esize = sp->tp->size;
  		(*node)->etype = bt_pointer;//sp->tp->type;
  		if (sp->tp->isUnsigned)
  			(*node)->isUnsigned = TRUE;
  		(*node)->isDouble = sp->tp->type==bt_double;
  		break;

    case sc_global:
    case sc_external:
  		if (sp->tp->type==bt_func || sp->tp->type==bt_ifunc)
  	    *node = makesnode(en_cnacon,sp->name,sp->mangledName,sp->value.i);
  	  else
  	    *node = makesnode(en_nacon,sp->name,sp->mangledName,sp->value.i);
      (*node)->constflag = TRUE;
			(*node)->esize = sp->tp->size;
			(*node)->etype = bt_pointer;//sp->tp->type;
			(*node)->isUnsigned = sp->tp->isUnsigned;
			(*node)->isDouble = sp->tp->type==bt_double;
      break;

    case sc_const:
      if (sp->tp->type==bt_float || sp->tp->type==bt_double || sp->tp->type==bt_triple)
      	*node = makefnode(en_fcon,sp->value.f);
      else {
      	*node = makeinode(en_icon,sp->value.i);
      	if (sp->tp->isUnsigned)
      		(*node)->isUnsigned = TRUE;
      }
                    (*node)->constflag = TRUE;
      (*node)->esize = sp->tp->size;
      (*node)->isDouble = sp->tp->type==bt_double;
      break;

    default:        /* auto and any errors */
			if (sp->storage_class == sc_member) {	// will get this for a class member
  			// If it's a member we need to pass r25 the class pointer on
  				// the stack.
  			isMember = true;
  			if ((sp->tp->type==bt_func || sp->tp->type==bt_ifunc) 
  			  ||(sp->tp->type==bt_pointer && (sp->tp->GetBtp()->type == bt_func ||sp->tp->GetBtp()->type == bt_ifunc)))
        {
  				*node = makesnode(en_cnacon,sp->name,sp->BuildSignature(),25);
  			}
  			else {
  				*node = makeinode(en_classcon,sp->value.i);
  			}
  			if (sp->tp->isUnsigned)
					(*node)->isUnsigned = TRUE;
			}
      else {
				if( sp->storage_class != sc_auto) {
					error(ERR_ILLCLASS);
				}
				//sc_member
				if (sp->tp->type==bt_float || sp->tp->type==bt_double || sp->tp->type==bt_triple)
					*node = makeinode(en_autofcon,sp->value.i);
				else {
					*node = makeinode(en_autocon,sp->value.i);
					if (sp->tp->isUnsigned)
						(*node)->isUnsigned = TRUE;
				}
			}
      (*node)->esize = sp->tp->size;
      (*node)->etype = bt_pointer;//sp->tp->type;
      (*node)->isDouble = sp->tp->type==bt_double;
      break;
    }
    (*node)->isPascal = sp->IsPascal;
    (*node)->SetType(sp->tp);
    (*node)->sym = sp;
    dfs.printf("tp:%p ",(char *)tp);
    // Not sure about this if - wasn't here in the past.
    if (sp->tp->type!=bt_func && sp->tp->type!=bt_ifunc)
      tp = CondDeref(node,tp);
    dfs.printf("deref tp:%p ",(char *)tp);
  }
  if (nt)
     NextToken();
xit:
  if (!tp)
	   dfs.printf("returning nullptr2");
  dfs.puts("</nameref2>\n");
  return tp;
}

TYP *nameref(ENODE **node,int nt)
{
	TYP *tp;
  bool found;
 
	dfs.puts("<Nameref>\n");
	dfs.printf("GSearchfor:%s|",lastid);
	found = false;
/*
	if (ptp1) {
	  if (ptp1->type == bt_pointer) {
      found = ptp1->GetBtp()->lst.FindRising(lastid) > 0;
	  }
	  else {
      found = ptp1->lst.FindRising(lastid) > 0;
    }
  }
  if (!found)
 */
  gsearch2(lastid,(__int16)bt_long,nullptr,false);
	tp = nameref2(lastid, node, nt, true, nullptr, nullptr);
	dfs.puts("</Nameref>\n");
	return tp;
}
/*
      // Look for a function
  		gsearch2(lastid,(__int16)bt_long,nullptr,false);
			while( my_isspace(lastch) )
				getch();
			if(lastch == '(') {
				NextToken();
        tptr = nameref(&pnode,TRUE);
				tptr = ExprFunction(nullptr, &pnode);
			}
*/
/*
 *      ArgumentList will build a list of parameter expressions in
 *      a function call and return a pointer to the last expression
 *      parsed. since parameters are generally pushed from right
 *      to left we get just what we asked for...
 */
ENODE *ArgumentList(ENODE *hidden, TypeArray *typearray)
{
	ENODE *ep1, *ep2;
	TYP *typ;
	int nn;

  dfs.printf("<ArgumentList>");
	nn = 0;
  ep1 = 0;
	if (hidden) {
    ep1 = makenode(en_void,hidden,ep1);
	}
	typearray->Clear();
  while( lastst != closepa)
	{
    typ = NonCommaExpression(&ep2);          // evaluate a parameter
    if (typ)
       dfs.printf("%03d ", typ->typeno);
    else
       dfs.printf("%03d ", 0);
    // If a function pointer is passed, we want a pointer type
    if (typ->typeno==bt_func || typ->typeno == bt_ifunc)
       typearray->Add((int)bt_pointer);
    else
        typearray->Add(typ);
    ep1 = makenode(en_void,ep2,ep1);
    if(lastst != comma) {
      dfs.printf("lastst=%d", lastst);
      break;
    }
    NextToken();
  }
  NextToken();
  dfs.printf("</ArgumentList>\n");
  return ep1;
}

/*
 *      return 1 if st in set of [ kw_char, kw_short, kw_long, kw_int,
 *      kw_float, kw_double, kw_struct, kw_union ]
 */
static int IsIntrinsicType(int st)
{
	return  st == kw_byte || st==kw_char || st == kw_short || st == kw_int || st==kw_void ||
				st == kw_int16 || st == kw_int8 || st == kw_int32 || st == kw_int16 ||
                st == kw_long || st == kw_float || st == kw_double || st == kw_triple || 
                st == kw_enum || st == kw_struct || st == kw_union ||
                st== kw_unsigned || st==kw_signed || st==kw_exception ||
				st == kw_const;
}

int IsBeginningOfTypecast(int st)
{
	SYM *sp;
	if (st==id) {
		sp = tagtable.Find(lastid,false);
		if (sp == nullptr)
			sp = gsyms[0].Find(lastid,false);
		if (sp)
			return sp->storage_class==sc_typedef;
		return FALSE;
	}
	else
		return IsIntrinsicType(st) || st==kw_volatile;
}

SYM *makeint2(std::string name)
{
  SYM *sp;
  TYP *tp;
  sp = allocSYM();
  tp = TYP::Make(bt_long,8);
  tp->sname = new std::string("");
  sp->SetName(name);
  sp->storage_class = sc_auto;
  sp->SetType(tp);
	sp->IsPrototype = FALSE;
  return sp;
}


// Create a list of dummy parameters based on argument types.
// This is needed in order to add a function to the tables if
// the function hasn't been encountered before.

SYM *CreateDummyParameters(ENODE *ep, SYM *parent, TYP *tp)
{
	int i, poffset;
	SYM *sp1;
	SYM *list;
	int nn;
	ENODE *p;
	static char buf[20];

	list = nullptr;
	poffset = GetReturnBlockSize();

	// Process hidden parameter
	if (tp) {
		if (tp->GetBtp()) {
			if (tp->GetBtp()->type==bt_struct || tp->GetBtp()->type==bt_union || tp->GetBtp()->type==bt_class ) {
				sp1 = makeint2(std::string(my_strdup("_pHiddenStructPtr")));
				sp1->parent = parent->GetIndex();
				sp1->value.i = poffset;
				poffset += 8;
				sp1->storage_class = sc_auto;
				sp1->next = 0;
				list = sp1;
			}
		}
	}
	nn = 0;
	for(p = ep; p; p = p->p[1]) {
		sprintf(buf,"_p%d", nn);
		sp1 = makeint2(std::string(my_strdup(buf)));
		if (p->p[0]==nullptr)
			sp1->tp =(TYP *) TYP::Make(bt_long,8);
		else
			sp1->SetType(p->p[0]->tp);
		sp1->parent = parent->GetIndex();
		sp1->value.i = poffset;
		// Check for aggregate types passed as parameters. Structs
		// and unions use the type size. There could also be arrays
		// passed.
		poffset += round8(sp1->tp->size);
//		if (round8(sp1->tp->size) > 8)
		sp1->storage_class = sc_auto;
		sp1->next = 0;

		// record parameter list
		if (list == nullptr) {
			list = sp1;
		}
		else {
			sp1->SetNext(list->GetIndex());
			list = sp1;
		}
		nn++;
	}
	return list;
}


// ----------------------------------------------------------------------------
//      primary will parse a primary expression and set the node pointer
//      returning the type of the expression parsed. primary expressions
//      are any of:
//                      id
//                      constant
//                      string
//                      ( expression )
//                      this
// ----------------------------------------------------------------------------
TYP *ParsePrimaryExpression(ENODE **node, int got_pa)
{
	ENODE *pnode, *qnode, *rnode, *snode, *rnode1, *pnode1, *qnode1, *qnode2;
	ENODE *ep2;
	int64_t i ;
    SYM *sp;
    TYP *tptr;
	TypeArray typearray;

	qnode1 = (ENODE *)NULL;
	qnode2 = (ENODE *)NULL;
	pnode = (ENODE *)NULL;
    *node = (ENODE *)NULL;
    Enter("ParsePrimary ");
    if (got_pa) {
        tptr = expression(&pnode);
        needpunc(closepa,7);
        *node = pnode;
        if (pnode==NULL)
           dfs.printf("pnode is NULL\r\n");
        else
           (*node)->SetType(tptr);
        if (tptr)
        Leave("ParsePrimary", tptr->type);
        else
        Leave("ParsePrimary", 0);
        return tptr;
    }
    switch( lastst ) {
	case ellipsis:
    case id:
        tptr = nameref(&pnode,TRUE);
/*
		// Try and find the symbol, if not found, assume a function
		// but only if it's followed by a (
		if (TABLE::matchno==0) {
			while( my_isspace(lastch) )
				getch();
			if( lastch == '(') {
				NextToken();
				tptr = ExprFunction(nullptr, &pnode);
			}
			else {
				tptr = nameref(&pnode,TRUE);
			}
		}
		else
*/
		/*
		if (tptr==NULL) {
			tptr = allocTYP();
			tptr->type = bt_long;
			tptr->typeno = bt_long;
			tptr->alignment = 8;
			tptr->bit_offset = 0;
			tptr->GetBtp() = nullptr;
			tptr->isArray = false;
			tptr->isConst = false;
			tptr->isIO = false;
			tptr->isShort = false;
			tptr->isUnsigned = false;
			tptr->size = 8;
			tptr->sname = my_strdup(lastid);
		}
		*/
        break;
    case iconst:
        tptr = &stdint;
        tptr->isConst = TRUE;
        pnode = makeinode(en_icon,ival);
        pnode->constflag = TRUE;
		if (ival >= -128 && ival < 128)
			pnode->esize = 1;
		else if (ival >= -32768 && ival < 32768)
			pnode->esize = 2;
		else if (ival >= -2147483648LL && ival < 2147483648LL)
			pnode->esize = 4;
		else
			pnode->esize = 8;
        pnode->SetType(tptr);
        NextToken();
        break;
    case rconst:
        tptr = &stddouble;
        tptr->isConst = TRUE;
        pnode = makefnode(en_fcon,rval);
        pnode->constflag = TRUE;
        pnode->isDouble = TRUE;
        pnode->SetType(tptr);
        NextToken();
        break;
    case sconst:
		if (sizeof_flag) {
			tptr = (TYP *)TYP::Make(bt_pointer, 0);
			tptr->size = strlen(laststr) + 1;
			tptr->btp = stdchar.GetIndex();
            tptr->GetBtp()->isConst = TRUE;
			tptr->val_flag = 1;
			tptr->isConst = TRUE;
		}
		else {
            tptr = &stdstring;
		}
        pnode = makenodei(en_labcon,(ENODE *)NULL,0);
		if (sizeof_flag == 0)
			pnode->i = stringlit(laststr);
		pnode->etype = bt_pointer;
		pnode->esize = 8;
        pnode->constflag = TRUE;
        pnode->SetType(tptr);
     	tptr->isConst = TRUE;
        NextToken();
        break;

    case openpa:
        NextToken();
j1:
//        if( !IsBeginningOfTypecast(lastst) ) {
//		expr_flag = 0;
        tptr = expression(&pnode);
        pnode->SetType(tptr);
        needpunc(closepa,8);
//        }
        //else {			/* cast operator */
        //    ParseSpecifier(0); /* do cast ParseSpecifieraration */
        //    ParseDeclarationPrefix(FALSE);
        //    tptr = head;
        //    needpunc(closepa);
        //    if( ParseUnaryExpression(&pnode) == NULL ) {
        //        error(ERR_IDEXPECT);
        //        tptr = NULL;
        //    }
        //}
        break;

    case kw_this:
        {
          dfs.puts("<ExprThis>");
          TYP *tptr2;

          tptr2 = TYP::Make(bt_class,0);
          if (currentClass==nullptr) {
            error(ERR_THIS);
          }
          else {
            memcpy(tptr2,currentClass->tp,sizeof(TYP));
          }
          NextToken();
          tptr = TYP::Make(bt_pointer,8);
          tptr->btp = tptr2->GetIndex();
          dfs.puts((char *)tptr->GetBtp()->sname->c_str());
          pnode = makeinode(en_regvar,regCLP);
          dfs.puts("</ExprThis>");
        }
        break;

    default:
        Leave("ParsePrimary", 0);
        return (TYP *)NULL;
    }
fini:   *node = pnode;
    if (*node)
       (*node)->SetType(tptr);
    if (tptr)
    Leave("ParsePrimary", tptr->type);
    else
    Leave("ParsePrimary", 0);
    return tptr;
}

/*
 *      this function returns true if the node passed is an IsLValue.
 *      this can be qualified by the fact that an IsLValue must have
 *      one of the dereference operators as it's top node.
 */
int IsLValue(ENODE *node)
{
	switch( node->nodetype ) {
    case en_b_ref:
	case en_c_ref:
	case en_h_ref:
    case en_w_ref:
	case en_ub_ref:
	case en_uc_ref:
	case en_uh_ref:
    case en_uw_ref:
	case en_wfieldref:
	case en_uwfieldref:
	case en_bfieldref:
	case en_ubfieldref:
	case en_cfieldref:
	case en_ucfieldref:
	case en_hfieldref:
	case en_uhfieldref:
    case en_triple_ref:
	case en_dbl_ref:
	case en_flt_ref:
	case en_struct_ref:
            return TRUE;
	case en_cbc:
	case en_cbh:
    case en_cbw:
	case en_cch:
	case en_ccw:
	case en_chw:
	case en_cfd:
	case en_cubw:
	case en_cucw:
	case en_cuhw:
	case en_cbu:
	case en_ccu:
	case en_chu:
	case en_cubu:
	case en_cucu:
	case en_cuhu:
            return IsLValue(node->p[0]);
    }
    return FALSE;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
TYP *Autoincdec(TYP *tp, ENODE **node, int flag)
{
	ENODE *ep1, *ep2;
	int su;

	ep1 = *node;
	if( IsLValue(ep1) ) {
		if (tp->type == bt_pointer) {
			ep2 = makeinode(en_icon,tp->GetBtp()->size);
			ep2->esize = 8;
		}
		else {
			ep2 = makeinode(en_icon,1);
			ep2->esize = 1;
		}
		ep2->constflag = TRUE;
		ep2->isUnsigned = tp->isUnsigned;
		su = ep1->isUnsigned;
		ep1 = makenode(flag ? en_assub : en_asadd,ep1,ep2);
		ep1->isUnsigned = tp->isUnsigned;
		ep1->esize = tp->size;
	}
    else
        error(ERR_LVALUE);
	*node = ep1;
	if (*node)
    	(*node)->SetType(tp);
	return tp;
}


__int64 MultiplyFact(int num, int *fact)
{
  __int64 res;
  int nn;

  res = 1;
  for (nn = 1; nn <= num; nn++)
    res = res * fact[nn];
  return res;
}

// ----------------------------------------------------------------------------
// A Postfix Expression is:
//		primary
//		postfix_expression[expression]
//		postfix_expression()
//		postfix_expression(argument expression list)
//		postfix_expression.ID
//		postfix_expression->ID
//		postfix_expression++
//		postfix_expression--
// ----------------------------------------------------------------------------

TYP *ParsePostfixExpression(ENODE **node, int got_pa)
{
	TYP *tp1, *tp2, *otp1;
	ENODE *ep1, *ep2, *ep3, *ep4;
	ENODE *rnode[20],*cnode[20],*qnode[20],*rnode1,*rnode2,*q1node;
	SYM *sp;
	int iu;
	int size;
	TYP *p, *q;
	int na,ii,nn;
	int sz[20],fact[20];
	bool classdet = false;
	TypeArray typearray;
	std::string name;

    ep1 = (ENODE *)NULL;
    Enter("<ParsePostfix>");
    *node = (ENODE *)NULL;
	tp1 = ParsePrimaryExpression(&ep1, got_pa);
//	if (ep1==NULL)
//	   printf("DIAG: ParsePostFix: ep1 is NULL\r\n");
	if (tp1 == NULL) {
        Leave("</ParsePostfix>",0);
		return (TYP *)NULL;
    }
	pep1 = nullptr;
	while(1) {
	  pop = lastst;
		switch(lastst) {
		case openbr:
			if (tp1==NULL) {
				error(ERR_UNDEFINED);
				goto j1;
			}
      if( tp1->type != bt_pointer )
        error(ERR_NOPOINTER);
      else {
//            	printf("size:%d size2:%d\r\n", tp1->size, tp1->size2);
        size = tp1->size2;
        tp1 = tp1->GetBtp();
      }
//            NextToken();
/*
			if ((tp1->val_flag && (tp1->size==1 || tp1->size==2 || tp1->size==4 || tp1->size==8))) {
				expression(&rnode[0]);
//				ep1 = makenode(en_add,rnode,ep1);
				ep1 = makenode(en_add,ep1,rnode[0]);
      			ep1->constflag = rnode[0]->constflag && ep1->p[1]->constflag;
				ep1->isUnsigned = rnode[0]->isUnsigned && ep1->p[1]->isUnsigned;
				ep1->scale = tp1->size;
				ep1->esize = 8;             // was 8
			}
			else
*/
      {
				p = tp1;
				if (p==NULL) {
					printf("p is null\r\n");
					break;
			}
//				qnode = makeinode(en_icon,size);
      for (na = 0; na < 20 && p; na++) {
        sz[na] = p->size;
        if (lastst== openbr) {
         	NextToken();
			   	expression(&rnode[na]);
			   	if (rnode[na]==nullptr) {
			   	  dfs.printf("rnode[] is null\n");
   	        goto j1;
   	      }
          needpunc(closebr,9);
		    }
		    else {
         	rnode[na] = makeinode(en_icon, 0);
				}
        p = p->GetBtp();
      }
      na--;
      if (na>19) {
        error(ERR_TOOMANYDIMEN);
        na = 19;
        break;
      }
      switch(na) {
      case 0: 
        fact[0] = sz[0];
        cnode[0] = makeinode(en_icon,fact[0]);
        cnode[0]->constflag = TRUE;
        cnode[0]->isUnsigned = tp1->isUnsigned;
        qnode[0] = makenode(en_mulu,rnode[0],cnode[0]);
        qnode[0]->constflag = rnode[0]->constflag;
        ep1 = makenode(en_add,qnode[0],ep1);
 				ep1->constflag = qnode[0]->constflag && ep1->p[1]->constflag;
 				ep1->isUnsigned = qnode[0]->isUnsigned && ep1->p[1]->isUnsigned;
 				ep1->scale = 1;
 				ep1->esize = 8;
        tp1 = CondDeref(&ep1,tp1);
        break;
      case 1: 
        fact[0] = sz[na];
        fact[1] = sz[na-1]/sz[na];
        if (fact[1]==0) {
			  	error(ERR_BADARRAYNDX);
         	break;
        }
        //fact[2] = size/sz[0];
        cnode[0] = makeinode(en_icon,size/fact[1]);
        cnode[0]->constflag = TRUE;
        cnode[0]->isUnsigned = tp1->isUnsigned;
        qnode[0] = makenode(en_mulu,rnode[0],cnode[0]);
        qnode[0]->constflag = rnode[0]->constflag;
        cnode[1] = makeinode(en_icon,fact[0]);
        cnode[1]->constflag = TRUE;
        cnode[1]->isUnsigned = tp1->isUnsigned;
        qnode[1] = makenode(en_mulu,rnode[1],cnode[1]);
        qnode[1]->constflag = rnode[1]->constflag;
        ep2 = makenode(en_add,qnode[0],qnode[1]);
        ep2->constflag = qnode[0]->constflag && qnode[1]->constflag;
 				ep2->isUnsigned = qnode[0]->isUnsigned && qnode[1]->isUnsigned;
        ep1 = makenode(en_add,ep2,ep1);
        ep1->constflag = ep1->p[0]->constflag && ep2->p[0]->constflag;
 				ep1->isUnsigned = ep1->p[0]->isUnsigned && ep2->p[0]->isUnsigned;
  			ep1->scale = 1;
  			ep1->esize = 8;
  			tp1 = deref(&ep1,tp1);
//        tp1 = CondDeref(&ep1,tp1);
        break;
      case 2: 
        fact[0] = sz[na];
        fact[1] = sz[na-1]/sz[na];
        fact[2] = sz[na-2]/sz[na-1];
        //fact[3] = size/sz[0];
        cnode[0] = makeinode(en_icon,size/fact[1]);
        cnode[0]->constflag = TRUE;
        cnode[0]->isUnsigned = tp1->isUnsigned;
        qnode[0] = makenode(en_mulu,rnode[0],cnode[0]);
        qnode[0]->constflag = rnode[0]->constflag;
        cnode[1] = makeinode(en_icon,size/(fact[1]*fact[2]));
        cnode[1]->constflag = TRUE;
        cnode[1]->isUnsigned = tp1->isUnsigned;
        qnode[1] = makenode(en_mulu,rnode[1],cnode[1]);
        qnode[1]->constflag = rnode[1]->constflag;
        cnode[2] = makeinode(en_icon,fact[0]);
        cnode[2]->constflag = TRUE;
        cnode[2]->isUnsigned = tp1->isUnsigned;
        qnode[2] = makenode(en_mulu,rnode[2],cnode[2]);
        qnode[2]->constflag = rnode[2]->constflag;
        
        ep2 = makenode(en_add,qnode[0],qnode[1]);
        ep2->constflag = qnode[0]->constflag && qnode[1]->constflag;
 				ep2->isUnsigned = qnode[0]->isUnsigned && qnode[1]->isUnsigned;
 				
        ep1 = makenode(en_add,ep1,ep2);
        ep1->constflag = ep1->p[0]->constflag && ep2->p[0]->constflag;
 				ep1->isUnsigned = ep1->p[0]->isUnsigned && ep2->p[0]->isUnsigned;
 				
        ep1 = makenode(en_add,ep1,qnode[2]);
        ep1->constflag = qnode[2]->constflag && ep1->p[0]->constflag;
    		ep1->isUnsigned = qnode[2]->isUnsigned && ep1->p[0]->isUnsigned;
    		
    		ep1->scale = 1;
    		ep1->esize = 8;
  			tp1 = deref(&ep1,tp1);
//        tp1 = CondDeref(&ep1,tp1);
        break;

      default:
        fact[0] = sz[na];
        for (ii = 1,nn = na-1; nn >= 0; nn--, ii++) {
          fact[ii] = sz[nn]/sz[nn+1];
        }
        for (ii = 0; ii < na; ii++) {
          cnode[ii] = makeinode(en_icon,size/MultiplyFact(ii+1,fact));
          cnode[ii]->constflag = TRUE;
          cnode[ii]->isUnsigned = tp1->isUnsigned;
          qnode[ii] = makenode(en_mulu,rnode[ii],cnode[ii]);
          qnode[ii]->constflag = rnode[ii]->constflag;
        }
        cnode[ii] = makeinode(en_icon,fact[0]);
        cnode[ii]->constflag = TRUE;
        cnode[ii]->isUnsigned = tp1->isUnsigned;
        qnode[ii] = makenode(en_mulu,rnode[ii],cnode[ii]);
        qnode[ii]->constflag = rnode[ii]->constflag;
        ep2 = qnode[0];
        for (ii = 1; ii <= na; ii++) {
          ep2 = makenode(en_add,ep2,qnode[ii]);
          ep2->constflag = ep2->p[0]->constflag && qnode[ii]->constflag;
          ep2->isUnsigned = ep2->p[0]->isUnsigned && qnode[ii]->isUnsigned;
        }
        ep1 = makenode(en_add,ep2,ep1);
        ep1->constflag = ep1->p[0]->constflag && ep1->p[1]->constflag;
        ep1->isUnsigned = ep1->p[0]->isUnsigned && ep1->p[1]->isUnsigned;
    		ep1->scale = 1;
    		ep1->esize = 8;
  			tp1 = deref(&ep1,tp1);
//        tp1 = CondDeref(&ep1,tp1);
      }
    }
    break;
/*
                if (lastst==openbr) {
                    na = 2;
                    qnode = makeinode(en_icon,size/(tp1->size/tp1->GetBtp()->size));
    				qnode->constflag = TRUE;
    				qnode->isUnsigned = tp1->isUnsigned;
                    q1node = makeinode(en_icon,tp1->GetBtp()->size);
                    printf("sz:%d\r\n", tp1->size/tp1->GetBtp()->size);
                    NextToken();
                    expression(&rnode1);
    				if (rnode1==NULL) {
    					error(ERR_EXPREXPECT);
    					break;
    				}
                    needpunc(closebr);
                    qnode = makenode(en_mulu,rnode,qnode);
                    qnode->constflag = rnode->constflag && qnode->p[0]->constflag;
                    q1node = makenode(en_mulu,rnode1,q1node);
//                    ep1 = makenode(en_add,qnode,q1node);
                    q1node->constflag = rnode1->constflag && q1node->p[0]->constflag;
                    ep2 = makenode(en_add,qnode,q1node);
                    ep2->constflag = qnode->constflag && q1node->constflag;
    				ep2->isUnsigned = qnode->isUnsigned && q1node->isUnsigned;
                    ep1 = makenode(en_add,ep1,ep2);
                    ep1->constflag = ep1->p[0]->constflag && ep2->p[0]->constflag;
    				ep1->isUnsigned = ep1->p[0]->isUnsigned && ep2->p[0]->isUnsigned;
    				ep1->scale = 1;
    				ep1->esize = 8;
                    tp1 = CondDeref(&ep1,tp1);
                    break;
                }
				
*
 *      we could check the type of the expression here...
									
 *
				if (rnode==NULL) {
					error(ERR_EXPREXPECT);
					break;
				}
				qnode = makenode(en_mulu,rnode,qnode);
				qnode->constflag = rnode->constflag && qnode->p[0]->constflag;
				ep1 = makenode(en_add,qnode,ep1);
				ep1->constflag = qnode->constflag && ep1->p[1]->constflag;
				ep1->isUnsigned = qnode->isUnsigned && ep1->p[1]->isUnsigned;
				ep1->scale = 1;
				ep1->esize = 8;
			}
            tp1 = CondDeref(&ep1,tp1);
//            needpunc(closebr);
*/
//            break;

		case openpa:
			if (tp1==NULL) {
				error(ERR_UNDEFINED);
				goto j1;
			}
			tp2 = ep1->tp;
			if (tp2->type == bt_pointer) {
        dfs.printf("Got function pointer.\n");
			}
			dfs.printf("tp2->type=%d",tp2->type);
		  name = lastid;
		  NextToken();
      ep2 = ArgumentList(ep1->p[2],&typearray);
      typearray.Print();
      dfs.printf("Got Type: %d",tp1->type);
      if (tp1->type==bt_pointer) {
        dfs.printf("Got function pointer.\n");
        ep1 = makenode(en_fcall,ep1,ep2);
  	    currentFn->IsLeaf = FALSE;
        break;
      }
      dfs.printf("openpa calling gsearch2");
      sp = nullptr;
      ii = tp1->lst.FindRising(name);
      if (ii) {
        sp = SYM::FindExactMatch(TABLE::matchno, name, bt_long, &typearray);
      }
      if (!sp)
        sp = gsearch2(name,bt_long,&typearray,true);
      if (sp==nullptr) {
        sp = allocSYM();
        sp->storage_class = sc_external;
        sp->SetName(name);
        sp->tp = TYP::Make(bt_func,0);
        sp->tp->btp = TYP::Make(bt_long,8)->GetIndex();
        sp->AddProto(&typearray);
        sp->mangledName = sp->BuildSignature();
        gsyms[0].insert(sp);
      }
      else if (sp->IsUndefined) {
        sp->tp = TYP::Make(bt_func,0);
        sp->tp->btp = TYP::Make(bt_long,8)->GetIndex();
        sp->AddProto(&typearray);
        sp->mangledName = sp->BuildSignature();
        gsyms[0].insert(sp);
        sp->IsUndefined = false;
      }
      if (sp->tp->type==bt_pointer) {
        dfs.printf("Got function pointer");
        ep1 = makefcnode(en_fcall,ep1,ep2,sp);
        currentFn->IsLeaf = FALSE;
      }
      else {
        dfs.printf("Got direct function %s ", (char *)sp->name->c_str());
  	    ep3 = makesnode(en_cnacon,sp->name,sp->mangledName,sp->value.i);
        ep1 = makefcnode(en_fcall,ep3,ep2,sp);
  	    currentFn->IsLeaf = FALSE;
      }
      tp1 = sp->tp->GetBtp();
//			tp1 = ExprFunction(tp1, &ep1);
      break;

		case pointsto:
			if (tp1==NULL) {
				error(ERR_UNDEFINED);
				goto j1;
			}
      if( tp1->type != bt_pointer ) {
          error(ERR_NOPOINTER);
      }
      else
          tp1 = tp1->GetBtp();
      if( tp1->val_flag == FALSE )
          ep1 = makenode(en_w_ref,ep1,(ENODE *)NULL);
		 // fall through to dot operation
		case dot:
			if (tp1==NULL) {
				error(ERR_UNDEFINED);
				goto j1;
			}
      NextToken();       /* past -> or . */
      if(lastst != id) {
        error(ERR_IDEXPECT);
  			break;
			}
			dfs.printf("dot search: %p\r\n", (char *)&tp1->lst);
			ptp1 = tp1;
			pep1 = ep1;
			name = lastid;
      ii = tp1->lst.FindRising(name);
			if (ii==0) {
			  dfs.printf("Nomember1");
        error(ERR_NOMEMBER);
				break;
			}
			sp = TABLE::match[ii-1];
			sp = sp->FindRisingMatch();
      if( sp == NULL ) {
			  dfs.printf("Nomember2");
        error(ERR_NOMEMBER);
				break;
      }
			if (sp->IsPrivate && sp->parent != currentFn->parent) {
        error(ERR_PRIVATE);
				break;
			}
      tp1 = sp->tp;
      dfs.printf("tp1->type:%d",tp1->type);
      if (tp1==nullptr)
        throw new C64PException(ERR_NULLPOINTER,5);
			if (tp1->type==bt_ifunc || tp1->type==bt_func) {
				// build the name vector and create a nacon node.
				dfs.printf("%s is a func\n",(char *)sp->name->c_str());
				NextToken();
				if (lastst==openpa) {
				  NextToken();
				  ep2 = ArgumentList(pep1,&typearray);
				  typearray.Print();
				  sp = SYM::FindExactMatch(ii,name,bt_long,&typearray);
				  if (sp) {
//				    sp = TABLE::match[TABLE::matchno-1];
				    ep3 = makesnode(en_cnacon,sp->name,sp->mangledName,sp->value.i);
				    ep1 = makenode(en_fcall,ep3,ep2);
				    tp1 = sp->tp->GetBtp();
				    currentFn->IsLeaf = FALSE;
          }
          else {
            error(ERR_METHOD_NOTFOUND);
            goto j1;
          }
          ep1->SetType(tp1);
          break;
				}
				// Else: we likely wanted the addres of the function since the
        // function is referenced without o parameter list indicator. Goto
        // the regular processing code.
				goto j2;
			}
			else {
j2:
      dfs.printf("tp1->type:%d",tp1->type);
				qnode[0] = makeinode(en_icon,sp->value.i);
				qnode[0]->constflag = TRUE;
				iu = ep1->isUnsigned;
				ep1 = makenode(en_add,ep1,qnode[0]);
				ep1->constflag = ep1->p[0]->constflag;
				ep1->isUnsigned = iu;
				ep1->esize = 8;
				ep1->p[2] = pep1;
				if (tp1->type==bt_pointer && (tp1->GetBtp()->type==bt_func || tp1->GetBtp()->type==bt_ifunc))
				  dfs.printf("Pointer to func");
	      else
			    tp1 = CondDeref(&ep1,tp1);
        ep1->SetType(tp1);
        dfs.printf("tp1->type:%d",tp1->type);
      }
			if (tp1==nullptr)
				getchar();
      NextToken();       /* past id */
			dfs.printf("B");
      break;
		case autodec:
			NextToken();
			Autoincdec(tp1,&ep1,1);
			break;
		case autoinc:
			NextToken();
			Autoincdec(tp1,&ep1,0);
			break;
		default:	goto j1;
		}
	}
j1:
	*node = ep1;
	if (ep1)
    	(*node)->SetType(tp1);
	if (tp1)
	Leave("</ParsePostfix>", tp1->type);
	else
	Leave("</ParsePostfix>", 0);
	return tp1;
}

/*
 *      ParseUnaryExpression evaluates unary expressions and returns the type of the
 *      expression evaluated. unary expressions are any of:
 *
 *                      postfix expression
 *                      ++unary
 *                      --unary
 *                      !cast_expression
 //                     not cast_expression
 *                      ~cast_expression
 *                      -cast_expression
 *                      +cast_expression
 *                      *cast_expression
 *                      &cast_expression
 *                      sizeof(typecast)
 *                      sizeof unary
 *                      typenum(typecast)
 //                     new 
 *
 */
TYP *ParseUnaryExpression(ENODE **node, int got_pa)
{
	TYP *tp, *tp1;
    ENODE *ep1, *ep2, *ep3;
    int flag2;
	SYM *sp;

  Enter("<ParseUnary>");
    ep1 = NULL;
    *node = (ENODE *)NULL;
	flag2 = FALSE;
	if (got_pa) {
        tp = ParsePostfixExpression(&ep1, got_pa);
		*node = ep1;
        if (ep1)
    		(*node)->SetType(tp);
        if (tp)
        Leave("</ParseUnary>", tp->type);
        else
        Leave("</ParseUnary>", 0);
		return tp;
	}
    switch( lastst ) {
    case autodec:
		NextToken();
		tp = ParseUnaryExpression(&ep1, got_pa);
		Autoincdec(tp,&ep1,1);
		break;
    case autoinc:
		NextToken();
		tp = ParseUnaryExpression(&ep1, got_pa);
		Autoincdec(tp,&ep1,0);
		break;
	case plus:
        NextToken();
        tp = ParseCastExpression(&ep1);
        if( tp == NULL ) {
            error(ERR_IDEXPECT);
            return (TYP *)NULL;
        }
        break;
    case minus:
        NextToken();
        tp = ParseCastExpression(&ep1);
        if( tp == NULL ) {
            error(ERR_IDEXPECT);
            return (TYP *)NULL;
        }
        ep1 = makenode(en_uminus,ep1,(ENODE *)NULL);
        ep1->constflag = ep1->p[0]->constflag;
		ep1->isUnsigned = ep1->p[0]->isUnsigned;
		ep1->esize = tp->size;
		ep1->etype = (e_bt)tp->type;
        break;

    case nott:
    case kw_not:
      NextToken();
      tp = ParseCastExpression(&ep1);
      if( tp == NULL ) {
        error(ERR_IDEXPECT);
        return (TYP *)NULL;
      }
      ep1 = makenode(en_not,ep1,(ENODE *)NULL);
      ep1->constflag = ep1->p[0]->constflag;
      ep1->isUnsigned = ep1->p[0]->isUnsigned;
      ep1->esize = tp->size;
      break;

    case cmpl:
        NextToken();
        tp = ParseCastExpression(&ep1);
        if( tp == NULL ) {
            error(ERR_IDEXPECT);
            return 0;
        }
        ep1 = makenode(en_compl,ep1,(ENODE *)NULL);
        ep1->constflag = ep1->p[0]->constflag;
		ep1->isUnsigned = ep1->p[0]->isUnsigned;
		ep1->esize = tp->size;
        break;

    case star:
        NextToken();
        tp = ParseCastExpression(&ep1);
        if( tp == NULL ) {
            error(ERR_IDEXPECT);
            return (TYP *)NULL;
        }
        if( tp->GetBtp() == NULL )
			    error(ERR_DEREF);
        else {
          // A star before a function pointer just means that we want to
          // invoke the function. We want to retain the pointer to the
          // function as the type.
          if (tp->GetBtp()->type!=bt_func && tp->GetBtp()->type!=bt_ifunc)
            tp = tp->GetBtp();
        }
		    tp1 = tp;
	      //Autoincdec(tp,&ep1);
		    tp = CondDeref(&ep1,tp);
        break;

    case bitandd:
        NextToken();
        tp = ParseCastExpression(&ep1);
        if( tp == NULL ) {
            error(ERR_IDEXPECT);
            return (TYP *)NULL;
        }
        if( IsLValue(ep1))
            ep1 = ep1->p[0];
        ep1->esize = 8;     // converted to a pointer so size is now 8
        tp1 = TYP::Make(bt_pointer,8);
        tp1->btp = tp->GetIndex();
        tp1->val_flag = FALSE;
        tp = tp1;
//        printf("tp %p: %d\r\n", tp, tp->type);
/*
		sp = search("ta_int",&tp->GetBtp()->lst);
		if (sp) {
			printf("bitandd: ta_int\r\n");
		}
*/
        break;
    case kw_sizeof:
        NextToken();
		if (lastst==openpa) {
			flag2 = TRUE;
			NextToken();
		}
		if (flag2 && IsBeginningOfTypecast(lastst)) {
			tp = head;
			tp1 = tail;
			Declaration::ParseSpecifier(0);
			Declaration::ParsePrefix(FALSE);
			if( head != NULL )
				ep1 = makeinode(en_icon,head->size);
			else {
				error(ERR_IDEXPECT);
				ep1 = makeinode(en_icon,1);
			}
			head = tp;
			tail = tp1;
		}
		else {
			sizeof_flag++;
			tp = ParseUnaryExpression(&ep1, got_pa);
			sizeof_flag--;
			if (tp == 0) {
				error(ERR_SYNTAX);
				ep1 = makeinode(en_icon,1);
			} else
				ep1 = makeinode(en_icon, (long) tp->size);
		}
		if (flag2)
			needpunc(closepa,2);
		ep1->constflag = TRUE;
		ep1->esize = 8;
		tp = &stdint;
        break;

    case kw_new:
      NextToken();
      if (IsBeginningOfTypecast(lastst)) {
        std::string *name = new std::string("_malloc");
        
        tp = head;
        tp1 = tail;
  			Declaration::ParseSpecifier(0);
  			Declaration::ParsePrefix(FALSE);
  			if( head != NULL )
  				ep1 = makeinode(en_icon,head->size);
  			else {
  				error(ERR_IDEXPECT);
  				ep1 = makeinode(en_icon,1);
  			}
  			ep3 = makenode(en_void,ep1,nullptr);
  			ep2 = makesnode(en_cnacon, name, name, 0);
  			ep1 = makefcnode(en_fcall, ep2, ep3, nullptr);
  			head = tp;
  			tail = tp1;
      }
      else {
        std::string *name = new std::string("_malloc");

  			sizeof_flag++;
  			tp = ParseUnaryExpression(&ep1, got_pa);
  			sizeof_flag--;
  			if (tp == 0) {
  				error(ERR_SYNTAX);
  				ep1 = makeinode(en_icon,1);
  			} else
  				ep1 = makeinode(en_icon, (long) tp->size);
  			ep3 = makenode(en_void,ep1,nullptr);
  			ep2 = makesnode(en_cnacon, name, name, 0);
  			ep1 = makefcnode(en_fcall, ep2, ep3, nullptr);
      }
      break;

    case kw_delete:
      NextToken();
      {
        std::string *name = new std::string("_free");
        
  			if (lastst==openbr) {
  	      NextToken();
    			needpunc(closebr,50);
		    }
        tp1 = ParseCastExpression(&ep1);
        tp1 = deref(&ep1, tp1);
  			ep2 = makesnode(en_cnacon, name, name, 0);
  			ep1 = makefcnode(en_fcall, ep2, ep1, nullptr);
      }
      break;

    case kw_typenum:
      NextToken();
      needpunc(openpa,3);
  		tp = head;
	    tp1 = tail;
      Declaration::ParseSpecifier(0);
      Declaration::ParsePrefix(FALSE);
      if( head != NULL )
        ep1 = makeinode(en_icon,GetTypeHash(head));
      else {
        error(ERR_IDEXPECT);
        ep1 = makeinode(en_icon,1);
      }
      head = tp;
	    tail = tp1;
      ep1->constflag = TRUE;
	    ep1->esize = 8;
      tp = &stdint;
      needpunc(closepa,4);
      break;

    default:
        tp = ParsePostfixExpression(&ep1, got_pa);
        break;
    }
    *node = ep1;
    if (ep1)
	    (*node)->SetType(tp);
    if (tp)
    Leave("</ParseUnary>", tp->type);
    else
    Leave("</ParseUnary>", 0);
    return tp;
}

// ----------------------------------------------------------------------------
// A cast_expression is:
//		unary_expression
//		(type name)cast_expression
// ----------------------------------------------------------------------------
static TYP *ParseCastExpression(ENODE **node)
{
	TYP *tp, *tp1, *tp2;
	ENODE *ep1, *ep2;

    Enter("ParseCast ");
    *node = (ENODE *)NULL;
	switch(lastst) {
 /*
	case openpa:
		NextToken();
        if(IsBeginningOfTypecast(lastst) ) {
            ParseSpecifier(0); // do cast declaration
            ParseDeclarationPrefix(FALSE);
            tp = head;
			tp1 = tail;
            needpunc(closepa);
            if((tp2 = ParseCastExpression(&ep1)) == NULL ) {
                error(ERR_IDEXPECT);
                tp = (TYP *)NULL;
            }
			ep2 = makenode(en_void,ep1,(ENODE *)NULL);
			ep2->constflag = ep1->constflag;
			ep2->isUnsigned = ep1->isUnsigned;
			ep2->etype = ep1->etype;
			ep2->esize = ep1->esize;
			forcefit(&ep2,tp2,&ep1,tp);
			head = tp;
			tail = tp1;
        }
		else {
			tp = ParseUnaryExpression(&ep1,1);
		}
		break;
*/
	case openpa:
		NextToken();
        if(IsBeginningOfTypecast(lastst) ) {
            Declaration::ParseSpecifier(0); // do cast declaration
            Declaration::ParsePrefix(FALSE);
            tp = head;
			tp1 = tail;
            needpunc(closepa,5);
            if((tp2 = ParseCastExpression(&ep1)) == NULL ) {
                error(ERR_IDEXPECT);
                tp = (TYP *)NULL;
            }
            if (tp2->isConst) {
                *node = ep1;
                return tp;
            }
            if (tp->type == bt_double)
                ep2 = makenode(en_tempfpref,(ENODE *)NULL,(ENODE *)NULL);
            else
                ep2 = makenode(en_tempref,(ENODE *)NULL,(ENODE *)NULL);
			ep2 = makenode(en_void,ep2,ep1);
			ep2->constflag = ep1->constflag;
			ep2->isUnsigned = ep1->isUnsigned;
			ep2->etype = ep1->etype;
			ep2->esize = ep1->esize;
			forcefit(&ep2,tp2,&ep1,tp);
			head = tp;
			tail = tp1;
			*node = ep2;
      		(*node)->SetType(tp);
			return tp;
        }
		else {
			tp = ParseUnaryExpression(&ep1,1);
		}
		break;

	default:
		tp = ParseUnaryExpression(&ep1,0);
		break;
	}
	*node = ep1;
	if (ep1)
	    (*node)->SetType(tp);
	if (tp)
	Leave("ParseCast", tp->type);
	else
	Leave("ParseCast", 0);
	return tp;
}

// ----------------------------------------------------------------------------
//      forcefit will coerce the nodes passed into compatible
//      types and return the type of the resulting expression.
// ----------------------------------------------------------------------------
TYP *forcefit(ENODE **node1,TYP *tp1,ENODE **node2,TYP *tp2)
{
	ENODE *n2;

	if (tp1==tp2)	// duh
		return tp1;
	if (node2)
		n2 = *node2;
	else
		n2 = (ENODE *)NULL;
	switch( tp1->type ) {
	case bt_ubyte:
		switch(tp2->type) {
		case bt_long:	*node1 = makenode(en_cubw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_ulong:	*node1 = makenode(en_cubu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_short:	*node1 = makenode(en_cubw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_ushort:	*node1 = makenode(en_cubu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_char:	*node1 = makenode(en_cubw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_uchar:	*node1 = makenode(en_cubu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_byte:	*node1 = makenode(en_cubw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_ubyte:	*node1 = makenode(en_cubu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_enum:	*node1 = makenode(en_cubw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_pointer:*node1 = makenode(en_cubu,*node1,*node2); (*node1)->esize = 8; return tp2;
		case bt_exception:	*node1 = makenode(en_cubu,*node1,*node2); (*node1)->esize = 8; return &stdexception;
		}
		return tp1;
	case bt_byte:
		switch(tp2->type) {
		case bt_long:	*node1 = makenode(en_cbw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_ulong:	*node1 = makenode(en_cbu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_short:	*node1 = makenode(en_cbw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_ushort:	*node1 = makenode(en_cbu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_char:	*node1 = makenode(en_cbw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_uchar:	*node1 = makenode(en_cbu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_byte:	*node1 = makenode(en_cbw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_ubyte:	*node1 = makenode(en_cbu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_enum:	*node1 = makenode(en_cbw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_pointer:*node1 = makenode(en_cbu,*node1,*node2); (*node1)->esize = 8; return tp2;
		case bt_exception:	*node1 = makenode(en_cbu,*node1,*node2); (*node1)->esize = 8; return &stdexception;
		}
		return tp1;
	case bt_enum:
		switch(tp2->type) {
		case bt_long:	*node1 = makenode(en_ccw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_ulong:	*node1 = makenode(en_ccu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_short:	*node1 = makenode(en_ccw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_ushort:	*node1 = makenode(en_ccu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_char:	*node1 = makenode(en_ccw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_uchar:	*node1 = makenode(en_ccu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_byte:	*node1 = makenode(en_ccw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_ubyte:	*node1 = makenode(en_ccu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_enum:	*node1 = makenode(en_ccw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_pointer:*node1 = makenode(en_ccu,*node1,*node2); (*node1)->esize = 8; return tp2;
		case bt_exception:	*node1 = makenode(en_ccu,*node1,*node2); (*node1)->esize = 8; return &stdexception;
		}
		return tp1;
	case bt_uchar:
		switch(tp2->type) {
		case bt_long:	*node1 = makenode(en_cucw,*node1,n2); (*node1)->esize = 8; return &stdlong;
		case bt_ulong:	*node1 = makenode(en_cucu,*node1,n2); (*node1)->esize = 8; return &stdulong;
		case bt_short:	*node1 = makenode(en_cucw,*node1,n2); (*node1)->esize = 8; return &stdlong;
		case bt_ushort:	*node1 = makenode(en_cucu,*node1,n2); (*node1)->esize = 8; return &stdulong;
		case bt_char:	*node1 = makenode(en_cucw,*node1,n2); (*node1)->esize = 8; return &stdlong;
		case bt_uchar:	*node1 = makenode(en_cucu,*node1,n2); (*node1)->esize = 8; return &stdulong;
		case bt_byte:	*node1 = makenode(en_cucw,*node1,n2); (*node1)->esize = 8; return &stdlong;
		case bt_ubyte:	*node1 = makenode(en_cucu,*node1,n2); (*node1)->esize = 8; return &stdulong;
		case bt_enum:	*node1 = makenode(en_cucw,*node1,n2); (*node1)->esize = 8; return &stdlong;
		case bt_pointer:*node1 = makenode(en_cucu,*node1,n2); (*node1)->esize = 8; return tp2;
		case bt_exception:	*node1 = makenode(en_cucu,*node1,*node2); (*node1)->esize = 8; return &stdexception;
		}
		return tp1;
	case bt_char:
		switch(tp2->type) {
		case bt_long:	*node1 = makenode(en_ccw,*node1,n2); (*node1)->esize = 8; return &stdlong;
		case bt_ulong:	*node1 = makenode(en_ccu,*node1,n2); (*node1)->esize = 8; return &stdulong;
		case bt_short:	*node1 = makenode(en_ccw,*node1,n2); (*node1)->esize = 8; return &stdlong;
		case bt_ushort:	*node1 = makenode(en_ccu,*node1,n2); (*node1)->esize = 8; return &stdulong;
		case bt_char:	*node1 = makenode(en_ccw,*node1,n2); (*node1)->esize = 8; return &stdlong;
		case bt_uchar:	*node1 = makenode(en_ccu,*node1,n2); (*node1)->esize = 8; return &stdulong;
		case bt_byte:	*node1 = makenode(en_ccw,*node1,n2); (*node1)->esize = 8; return &stdlong;
		case bt_ubyte:	*node1 = makenode(en_ccu,*node1,n2); (*node1)->esize = 8; return &stdulong;
		case bt_enum:	*node1 = makenode(en_ccw,*node1,n2); (*node1)->esize = 8; return &stdlong;
		case bt_pointer:*node1 = makenode(en_ccu,*node1,n2); (*node1)->esize = 8; return tp2;
		case bt_exception:	*node1 = makenode(en_ccu,*node1,*node2); (*node1)->esize = 8; return &stdexception;
		}
		return tp1;
	case bt_ushort:
		switch(tp2->type) {
		case bt_long:	*node1 = makenode(en_cuhw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_ulong:	*node1 = makenode(en_cuhu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_short:	*node1 = makenode(en_cuhw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_ushort:	*node1 = makenode(en_cuhu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_char:	*node1 = makenode(en_cuhw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_uchar:	*node1 = makenode(en_cuhu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_byte:	*node1 = makenode(en_cuhw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_ubyte:	*node1 = makenode(en_cuhu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_enum:	*node1 = makenode(en_cuhw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_pointer:*node1 = makenode(en_cuhu,*node1,*node2); (*node1)->esize = 8; return tp2;
		case bt_exception:	*node1 = makenode(en_cuhu,*node1,*node2); (*node1)->esize = 8; return &stdexception;
		}
		return tp1;
	case bt_short:
		switch(tp2->type) {
		case bt_long:	*node1 = makenode(en_chw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_ulong:	*node1 = makenode(en_chu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_short:	*node1 = makenode(en_chw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_ushort:	*node1 = makenode(en_chu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_char:	*node1 = makenode(en_chw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_uchar:	*node1 = makenode(en_chu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_byte:	*node1 = makenode(en_chw,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_ubyte:	*node1 = makenode(en_chu,*node1,*node2); (*node1)->esize = 8; return &stdulong;
		case bt_enum:	*node1 = makenode(en_chu,*node1,*node2); (*node1)->esize = 8; return &stdlong;
		case bt_pointer:*node1 = makenode(en_chu,*node1,*node2); (*node1)->esize = 8; return tp2;
		case bt_exception:	*node1 = makenode(en_chu,*node1,*node2); (*node1)->esize = 8; return &stdexception;
		}
		return tp1;
	case bt_exception:
    case bt_long:
    case bt_ulong:
        if( tp2->type == bt_pointer	)
			return tp2;
        if (tp2->type==bt_double) {
            *node1 = makenode(en_i2d,*node1,*node2);
            return tp2;
        }
		//if (tp2->type == bt_double || tp2->type == bt_float) {
		//	*node1 = makenode(en_i2d,*node1,*node2);
		//	return tp2;
		//}
		return tp1;
    case bt_pointer:
            if( isscalar(tp2) || tp2->type == bt_pointer)
                return tp1;
			// pointer to function was really desired.
			if (tp2->type == bt_func || tp2->type==bt_ifunc)
				return tp1;
            break;
    case bt_unsigned:
            if( tp2->type == bt_pointer )
                return tp2;
            else if( isscalar(tp2) )
                return tp1;
            break;
	case bt_float:
			if (tp2->type == bt_double)
				return &stddbl;
			return tp1;
	case bt_double:
			if (tp2->type == bt_long)
				*node1 = makenode(en_d2i,*node1,*node2);
			return tp2;
	case bt_triple:
			if (tp2->type == bt_long)
				*node2 = makenode(en_i2t,*node2,*node1);
			return tp1;
	case bt_class:
	case bt_struct:
	case bt_union:
			if (tp2->size > tp1->size)
				return tp2;
			return tp1;
	// Really working with pointers to functions.
	case bt_func:
	case bt_ifunc:
			return tp1;
    }
    error( ERR_MISMATCH );
    return tp1;
}

/*
 *      this function returns true when the type of the argument is
 *      one of char, short, unsigned, or long.
 */
static int isscalar(TYP *tp)
{
	return
			tp->type == bt_byte ||
			tp->type == bt_char ||
      tp->type == bt_short ||
      tp->type == bt_long ||
			tp->type == bt_ubyte ||
			tp->type == bt_uchar ||
      tp->type == bt_ushort ||
      tp->type == bt_ulong ||
      tp->type == bt_exception ||
      tp->type == bt_unsigned;
}

/*
 *      multops parses the multiply priority operators. the syntax of
 *      this group is:
 *
 *              unary
 *              unary * unary
 *              unary / unary
 *              unary % unary
 */
TYP *multops(ENODE **node)
{
	ENODE *ep1, *ep2;
	TYP *tp1, *tp2;
	int	oper;
    
    Enter("Mulops");
    ep1 = (ENODE *)NULL;
    *node = (ENODE *)NULL;
	tp1 = ParseCastExpression(&ep1);
	if( tp1 == 0 ) {
        Leave("Mulops NULL",0);
		return 0;
    }
        while( lastst == star || lastst == divide || lastst == modop) {
                oper = lastst;
                NextToken();       /* move on to next unary op */
                tp2 = ParseCastExpression(&ep2);
                if( tp2 == 0 ) {
                        error(ERR_IDEXPECT);
                        *node = ep1;
                        if (ep1)
                            (*node)->SetType(tp1);
                        return tp1;
                        }
                tp1 = forcefit(&ep2,tp2,&ep1,tp1);
                switch( oper ) {
                        case star:
                                if (tp1->type==bt_triple) {
									ep1 = makenode(en_ftmul,ep1,ep2);
                                }  
								else if (tp1->type==bt_double)
									ep1 = makenode(en_fdmul,ep1,ep2);
								else if (tp1->type==bt_float)
									ep1 = makenode(en_fsmul,ep1,ep2);
								else if( tp1->isUnsigned )
                                        ep1 = makenode(en_mulu,ep1,ep2);
                                else
                                        ep1 = makenode(en_mul,ep1,ep2);
								ep1->esize = tp1->size;
								ep1->etype = (e_bt)tp1->type;
                                break;
                        case divide:
                                if (tp1->type==bt_triple)
									ep1 = makenode(en_ftdiv,ep1,ep2);
								else if (tp1->type==bt_double)
									ep1 = makenode(en_fddiv,ep1,ep2);
								else if (tp1->type==bt_float)
									ep1 = makenode(en_fsdiv,ep1,ep2);
                                else if( tp1->isUnsigned )
                                    ep1 = makenode(en_udiv,ep1,ep2);
                                else
                                    ep1 = makenode(en_div,ep1,ep2);
                                break;
								ep1->esize = tp1->size;
								ep1->etype = (e_bt)tp1->type;
                        case modop:
                                if( tp1->isUnsigned )
                                        ep1 = makenode(en_umod,ep1,ep2);
                                else
                                        ep1 = makenode(en_mod,ep1,ep2);
								ep1->esize = tp1->size;
								ep1->etype = tp1->type;
                                break;
                        }
                PromoteConstFlag(ep1);
                }
        *node = ep1;
        if (ep1)
		    (*node)->SetType(tp1);
    Leave("Mulops",0);
        return tp1;
}

// ----------------------------------------------------------------------------
// Addops handles the addition and subtraction operators.
// ----------------------------------------------------------------------------

static TYP *addops(ENODE **node)
{
	ENODE    *ep1, *ep2, *ep3, *ep4;
    TYP             *tp1, *tp2;
    int             oper;
	int sz1, sz2;

    Enter("Addops");
    ep1 = (ENODE *)NULL;
    *node = (ENODE *)NULL;
	sz1 = sz2 = 0;
	tp1 = multops(&ep1);
    if( tp1 == (TYP *)NULL )
        goto xit;
	if (tp1->type == bt_pointer) {
        if (tp1->GetBtp()==NULL) {
            printf("DIAG: pointer to NULL type.\r\n");
            goto xit;    
        }
        else
		    sz1 = tp1->GetBtp()->size;
    }
    while( lastst == plus || lastst == minus ) {
            oper = (lastst == plus);
            NextToken();
            tp2 = multops(&ep2);
            if( tp2 == 0 ) {
                    error(ERR_IDEXPECT);
                    *node = ep1;
                    goto xit;
                    }
			if (tp2->type == bt_pointer)
				sz2 = tp2->GetBtp()->size;
			// Difference of two pointers to the same type of object...
			// Divide the result by the size of the pointed to object.
			if (!oper && (tp1->type == bt_pointer) && (tp2->type == bt_pointer) && (sz1==sz2))
			{
  				ep1 = makenode( en_sub,ep1,ep2);
				ep4 = makeinode(en_icon, sz1);
				ep1 = makenode(en_udiv,ep1,ep4);
			}
			else {
                if( tp1->type == bt_pointer ) {
                        tp2 = forcefit(&ep2,tp2,0,&stdint);
                        ep3 = makeinode(en_icon,tp1->GetBtp()->size);
                        ep3->constflag = TRUE;
    					ep3->esize = tp2->size;
                        ep2 = makenode(en_mulu,ep3,ep2);
                        ep2->constflag = ep2->p[1]->constflag;
    					ep2->esize = tp2->size;
                        }
                else if( tp2->type == bt_pointer ) {
                        tp1 = forcefit(&ep1,tp1,0,&stdint);
                        ep3 = makeinode(en_icon,tp2->GetBtp()->size);
                        ep3->constflag = TRUE;
    					ep3->esize = tp2->size;
                        ep1 = makenode(en_mulu,ep3,ep1);
                        ep1->constflag = ep1->p[1]->constflag;
    					ep2->esize = tp2->size;
                        }
                tp1 = forcefit(&ep2,tp2,&ep1,tp1);
                if (tp1->type==bt_triple) {
    				ep1 = makenode( oper ? en_ftadd : en_ftsub,ep1,ep2);
                }
    			else if (tp1->type==bt_double)
    				ep1 = makenode( oper ? en_fdadd : en_fdsub,ep1,ep2);
    			else if (tp1->type==bt_float)
    				ep1 = makenode( oper ? en_fsadd : en_fssub,ep1,ep2);
    			else
    				ep1 = makenode( oper ? en_add : en_sub,ep1,ep2);
            }
            PromoteConstFlag(ep1);
			ep1->esize = tp1->size;
			ep1->etype = tp1->type;
            }
    *node = ep1;
xit:
    if (*node)
    	(*node)->SetType(tp1);
    Leave("Addops",0);
    return tp1;
}

// ----------------------------------------------------------------------------
// Shiftop handles the shift operators << and >>.
// ----------------------------------------------------------------------------
TYP *shiftop(ENODE **node)
{
	ENODE    *ep1, *ep2;
    TYP             *tp1, *tp2;
    int             oper;

    Enter("Shiftop");
    *node = NULL;
	tp1 = addops(&ep1);
	if( tp1 == 0)
        goto xit;
    while( lastst == lshift || lastst == rshift) {
            oper = (lastst == lshift);
            NextToken();
            tp2 = addops(&ep2);
            if( tp2 == 0 )
                    error(ERR_IDEXPECT);
            else    {
                    tp1 = forcefit(&ep2,tp2,&ep1,tp1);
					if (tp1->type==bt_float||tp1->type==bt_double)
						error(ERR_UNDEF_OP);
					else {
						if (tp1->isUnsigned)
							ep1 = makenode(oper ? en_shlu : en_shru,ep1,ep2);
						else
							ep1 = makenode(oper ? en_shl : en_asr,ep1,ep2);
						ep1->esize = tp1->size;
						PromoteConstFlag(ep1);
						}
                    }
            }
    *node = ep1;
 xit:
     if (*node)
     	(*node)->SetType(tp1);
    Leave("Shiftop",0);
    return tp1;
}

/*
 *      relation handles the relational operators < <= > and >=.
 */
TYP     *relation(ENODE **node)
{       ENODE    *ep1, *ep2;
        TYP             *tp1, *tp2;
        int             nt;
        Enter("Relation");
        *node = (ENODE *)NULL;
        tp1 = shiftop(&ep1);
        if( tp1 == 0 )
                goto xit;
        for(;;) {
                switch( lastst ) {

                        case lt:
                                if (tp1->type==bt_double)
                                    nt = en_flt;
                                else if( tp1->isUnsigned )
                                        nt = en_ult;
                                else
                                        nt = en_lt;
                                break;
                        case gt:
                                if (tp1->type==bt_double)
                                    nt = en_fgt;
                                else if( tp1->isUnsigned )
                                        nt = en_ugt;
                                else
                                        nt = en_gt;
                                break;
                        case leq:
                                if (tp1->type==bt_double)
                                    nt = en_fle;
                                else if( tp1->isUnsigned )
                                        nt = en_ule;
                                else
                                        nt = en_le;
                                break;
                        case geq:
                                if (tp1->type==bt_double)
                                    nt = en_fge;
                                else if( tp1->isUnsigned )
                                        nt = en_uge;
                                else
                                        nt = en_ge;
                                break;
                        default:
                                goto fini;
                        }
                NextToken();
                tp2 = shiftop(&ep2);
                if( tp2 == 0 )
                        error(ERR_IDEXPECT);
                else    {
                        tp1 = forcefit(&ep2,tp2,&ep1,tp1);
                        ep1 = makenode(nt,ep1,ep2);
						ep1->esize = 8;
						PromoteConstFlag(ep1);
                        }
                }
fini:   *node = ep1;
xit:
     if (*node)
		(*node)->SetType(tp1);
        Leave("Relation",0);
        return tp1;
}

/*
 *      equalops handles the equality and inequality operators.
 */
TYP     *equalops(ENODE **node)
{
	ENODE    *ep1, *ep2;
    TYP             *tp1, *tp2;
    int             oper;
    Enter("EqualOps");
    *node = (ENODE *)NULL;
    tp1 = relation(&ep1);
    if( tp1 == (TYP *)NULL )
        goto xit;
    while( lastst == eq || lastst == neq ) {
        oper = (lastst == eq);
        NextToken();
        tp2 = relation(&ep2);
        if( tp2 == NULL )
                error(ERR_IDEXPECT);
        else {
            tp1 = forcefit(&ep2,tp2,&ep1,tp1);
            if (tp1->type==bt_double)
                ep1 = makenode( oper ? en_feq : en_fne,ep1,ep2);
            else
                ep1 = makenode( oper ? en_eq : en_ne,ep1,ep2);
			ep1->esize = 8;
			ep1->etype = tp1->type;
            PromoteConstFlag(ep1);
        }
	}
    *node = ep1;
 xit:
     if (*node)
     	(*node)->SetType(tp1);
    Leave("EqualOps",0);
    return tp1;
}

/*
 *      binop is a common routine to handle all of the legwork and
 *      error checking for bitand, bitor, bitxor, andop, and orop.
 */
TYP *binop(ENODE **node, TYP *(*xfunc)(ENODE **),int nt, int sy)
{
	ENODE    *ep1, *ep2;
        TYP             *tp1, *tp2;
        Enter("Binop");
        *node = (ENODE *)NULL;
        tp1 = (*xfunc)(&ep1);
        if( tp1 == 0 )
            goto xit;
        while( lastst == sy ) {
                NextToken();
                tp2 = (*xfunc)(&ep2);
                if( tp2 == 0 )
                        error(ERR_IDEXPECT);
                else    {
                        tp1 = forcefit(&ep2,tp2,&ep1,tp1);
                        ep1 = makenode(nt,ep1,ep2);
						ep1->esize = tp1->size;
						ep1->etype = tp1->type;
		                PromoteConstFlag(ep1);
                        }
                }
        *node = ep1;
xit:
     if (*node)
		(*node)->SetType(tp1);
        Leave("Binop",0);
        return tp1;
}

TYP *bitwiseand(ENODE **node)
/*
 *      the bitwise and operator...
 */
{       return binop(node,equalops,en_and,bitandd);
}

TYP     *bitwisexor(ENODE **node)
{       return binop(node,bitwiseand,en_xor,uparrow);
}

TYP     *bitwiseor(ENODE **node)
{       return binop(node,bitwisexor,en_or,bitorr);
}

TYP     *andop(ENODE **node)
{       return binop(node,bitwiseor,en_land,land);
}

TYP *orop(ENODE **node)
{
	return binop(node,andop,en_lor,lor);
}

/*
 *      this routine processes the hook operator.
 */
TYP *conditional(ENODE **node)
{
	TYP             *tp1, *tp2, *tp3;
    ENODE    *ep1, *ep2, *ep3;
    Enter("Conditional");
    *node = (ENODE *)NULL;
    tp1 = orop(&ep1);       /* get condition */
    if( tp1 == (TYP *)NULL )
        goto xit;
    if( lastst == hook ) {
			iflevel++;
	        if ((iflevel > maxPn-1) && isThor)
	            error(ERR_OUTOFPREDS);
            NextToken();
            if( (tp2 = conditional(&ep2)) == NULL) {
                    error(ERR_IDEXPECT);
                    goto cexit;
                    }
            needpunc(colon,6);
            if( (tp3 = conditional(&ep3)) == NULL) {
                    error(ERR_IDEXPECT);
                    goto cexit;
                    }
            tp1 = forcefit(&ep3,tp3,&ep2,tp2);
            ep2 = makenode(en_void,ep2,ep3);
			ep2->esize = tp1->size;
            ep1 = makenode(en_cond,ep1,ep2);
            ep1->predreg = iflevel;
			ep1->esize = tp1->size;
			iflevel--;
            }
cexit:  *node = ep1;
xit:
     if (*node)
     	(*node)->SetType(tp1);
    Leave("Conditional",0);
    return tp1;
}

// ----------------------------------------------------------------------------
//      asnop handles the assignment operators. currently only the
//      simple assignment is implemented.
// ----------------------------------------------------------------------------
TYP *asnop(ENODE **node)
{      
	ENODE    *ep1, *ep2, *ep3;
    TYP             *tp1, *tp2;
    int             op;

    Enter("Assignop");
    *node = (ENODE *)NULL;
    tp1 = conditional(&ep1);
    if( tp1 == 0 )
        goto xit;
    for(;;) {
        switch( lastst ) {
            case assign:
                op = en_assign;
ascomm:         NextToken();
                tp2 = asnop(&ep2);
ascomm2:        if( tp2 == 0 || !IsLValue(ep1) )
                    error(ERR_LVALUE);
				else {
					tp1 = forcefit(&ep2,tp2,&ep1,tp1);
					ep1 = makenode(op,ep1,ep2);
					ep1->esize = tp1->size;
					ep1->etype = tp1->type;
					ep1->isUnsigned = tp1->isUnsigned;
					// Struct assign calls memcpy, so function is no
					// longer a leaf routine.
					if (tp1->size > 8)
						currentFn->IsLeaf = FALSE;
				}
				break;
			case asplus:
				op = en_asadd;
ascomm3:        tp2 = asnop(&ep2);
				if( tp1->type == bt_pointer ) {
					ep3 = makeinode(en_icon,tp1->GetBtp()->size);
					ep3->esize = 8;
					ep2 = makenode(en_mul,ep2,ep3);
					ep2->esize = 8;
				}
				goto ascomm;
			case asminus:
				op = en_assub;
				goto ascomm3;
			case astimes:
                
				if (tp1->isUnsigned)
					op = en_asmulu;
				else
					op = en_asmul;
				goto ascomm;
			case asdivide:
				if (tp1->isUnsigned)
					op = en_asdivu;
				else
					op = en_asdiv;
				goto ascomm;
			case asmodop:
				if (tp1->isUnsigned)
					op = en_asmodu;
				else
					op = en_asmod;
				goto ascomm;
			case aslshift:
				op = en_aslsh;
				goto ascomm;
			case asrshift:
				if (tp1->isUnsigned)
					op = en_asrshu;
				else
					op = en_asrsh;
				goto ascomm;
			case asand:
				op = en_asand;
				goto ascomm;
			case asor:
				op = en_asor;
				goto ascomm;
			case asxor:
				op = en_asxor;
				goto ascomm;
			default:
				goto asexit;
			}
	}
asexit: *node = ep1;
xit:
     if (*node)
     	(*node)->SetType(tp1);
    Leave("Assignop",0);
        return tp1;
}

// ----------------------------------------------------------------------------
// Evaluate an expression where the comma operator is not legal.
// Externally visible entry point for GetIntegerExpression() and
// ArgumentList().
// ----------------------------------------------------------------------------
TYP *NonCommaExpression(ENODE **node)
{
	TYP *tp;
	pep1 = nullptr;
	Enter("NonCommaExpression");
    *node = (ENODE *)NULL;
    tp = asnop(node);
    if( tp == (TYP *)NULL )
        *node =(ENODE *)NULL;
    Leave("NonCommaExpression",tp ? tp->type : 0);
     if (*node)
     	(*node)->SetType(tp);
    return tp;
}

/*
 *      evaluate the comma operator. comma operators are kept as
 *      void nodes.
 */
TYP *commaop(ENODE **node)
{
	TYP *tp1,*tp2;
	ENODE *ep1,*ep2;

  *node = (ENODE *)NULL;
	tp1 = NonCommaExpression(&ep1);
	if (tp1==(TYP *)NULL)
		return (TYP *)NULL;
	while(1) {
		if (lastst==comma) {
			NextToken();
			tp2 = NonCommaExpression(&ep2);
      ep1 = makenode(en_void,ep1,ep2);
			ep1->esize = tp1->size;
		}
		else
			break;
	}
	*node = ep1;
     if (*node)
     	(*node)->SetType(tp1);
	return tp1;
}

//TYP *commaop(ENODE **node)
//{  
//	TYP             *tp1;
//        ENODE    *ep1, *ep2;
//        tp1 = asnop(&ep1);
//        if( tp1 == NULL )
//                return NULL;
//        if( lastst == comma ) {
//				NextToken();
//                tp1 = commaop(&ep2);
//                if( tp1 == NULL ) {
//                        error(ERR_IDEXPECT);
//                        goto coexit;
//                        }
//                ep1 = makenode(en_void,ep1,ep2);
//                }
//coexit: *node = ep1;
//        return tp1;
//}

// ----------------------------------------------------------------------------
// Evaluate an expression where all operators are legal.
// ----------------------------------------------------------------------------
TYP *expression(ENODE **node)
{
	TYP *tp;
	Enter("<expression>");
	pep1 = nullptr;
  *node = (ENODE *)NULL;
  tp = commaop(node);
  if( tp == (TYP *)NULL )
      *node = (ENODE *)NULL;
  TRACE(printf("leave exp\r\n"));
  if (tp) {
     if (*node)
        (*node)->SetType(tp);
      Leave("Expression",tp->type);
  }
  else
  Leave("</Expression>",0);
  return tp;
}
