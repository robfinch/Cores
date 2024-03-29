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

#define EXPR_DEBUG
#define NUM_DIMEN	20
extern SYM *currentClass;
extern int defaultcc;
static unsigned char sizeof_flag = 0;
extern void backup();
extern char *inpline;
extern int parsingParameterList;
extern SYM *gsearch2(std::string , __int16, TypeArray *,bool);
extern SYM *search2(std::string na,TABLE *tbl,TypeArray *typearray);
extern int round10(int n);

ENODE *pep1;
TYP *ptp1;	// the type just previous to the last dot
int pop;   // the just previous operator.
int laststrlen;

// Tells subsequent levels that ParseCastExpression already fetched a token.
//static unsigned char expr_flag = 0;

TYP				stdvoid;
TYP             stdint;
TYP             stduint;
TYP             stdlong;
TYP             stdulong;
TYP             stdshort;
TYP             stdushort;
TYP             stdchar;
TYP             stduchar;
TYP             stdichar;
TYP             stdiuchar;
TYP             stdbyte;
TYP             stdubyte;
TYP             stdstring;
TYP             stdistring;
TYP             stdastring;
TYP				stddbl;
TYP				stdtriple;
TYP				stdflt;
TYP				stddouble;
TYP				stdquad;
TYP             stdfunc;
TYP             stdexception;
extern TYP      *head;          /* shared with ParseSpecifier */
extern TYP	*tail;
ENODE *postfixList = nullptr;

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

int GetPtrSize()
{
	return sizeOfPtr;
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

	if (v1!=nullptr && v2 != nullptr) {
		ep->constflag = v1->constflag && v2->constflag;
		ep->isUnsigned = v1->isUnsigned && v2->isUnsigned;
	}
	else if (v1 != nullptr) {
		ep->constflag = v1->constflag;
		ep->isUnsigned = v1->isUnsigned;
	}
	else if (v2 != nullptr) {
		ep->constflag = v2->constflag;
		ep->isUnsigned = v2->isUnsigned;
	}
	ep->etype = bt_void;
	ep->esize = -1;
	ep->p[0] = v1;
	ep->p[1] = v2;
	ep->p[2] = 0;
  return (ep);
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

ENODE *makesnode(int nt, std::string *v1, std::string *v2, int64_t i)
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

ENODE *makenodei(int nt, ENODE *v1, int i)
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

ENODE *makefqnode(int nt, Float128 *f128)
{
	ENODE *ep;
  ep = allocEnode();
  ep->nodetype = (enum e_node)nt;
  ep->constflag = TRUE;
	ep->isUnsigned = FALSE;
	ep->etype = bt_void;
	ep->esize = -1;
  Float128::Assign(&ep->f128,f128);
//    ep->f2 = v2;
	ep->p[0] = 0;
	ep->p[1] = 0;
	ep->p[2] = 0;
  return ep;
}

char *GetStrConst()
{
	int len;
	char *str, *nstr;

	len = MAX_STLP1 + 1;
	str = (char *)malloc(len);
	if (str == nullptr) {
		error(ERR_OUT_OF_MEMORY);
	}
	strcpy_s(str, len, laststr);
	do {
		NextToken();
		if (lastst == sconst || lastst==isconst || lastst==asconst) {
			len = strlen(str) + MAX_STLP1 + 1;
			nstr = (char *)malloc(len*2+2);
			if (nstr == nullptr) {
				error(ERR_OUT_OF_MEMORY);
				break;
			}
			strcpy_s(nstr, len, str);
			strcat_s(&nstr[1], len, laststr);
			free(str);
			str = nstr;
		}
	} while (lastst == sconst || lastst == isconst);
	laststrlen = strlen(str);
	return (str);
}

void AddToList(ENODE *list, ENODE *ele)
{
	ENODE *p, *pp;

	p = list;
	pp = nullptr;
	while (p) {
		pp = p;
		p = p->p[2];
	}
	if (pp) {
		pp->p[2] = ele;
	}
	else
		list->p[2] = ele;
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

//
// Build the proper dereference operation for a node using the
// type pointer tp.
//
TYP *deref(ENODE **node, TYP *tp)
{
	SYM *sp;

  dfs.printf("<Deref>");
  if (tp==nullptr || node==nullptr || *node==nullptr)
    throw new C64PException(ERR_NULLPOINTER,8);
	sp = (*node)->sym;
	switch(tp->type) {
	case bt_byte:
		if (tp->isUnsigned) {
			*node = makenode(en_ref,*node,(ENODE *)NULL);
			(*node)->isUnsigned = TRUE;
		}
		else {
			*node = makenode(en_ref,*node,(ENODE *)NULL);
		}
		(*node)->esize = tp->size;
		(*node)->etype = (enum e_bt)tp->type;
		if (tp->isUnsigned)
	          tp = &stdubyte;//&stduint;
		else
	          tp = &stdbyte;//&stdint;
		(*node)->sym = sp;
		(*node)->tp = tp;
    break;

		case bt_ubyte:
			*node = makenode(en_ref,*node,(ENODE *)NULL);
			(*node)->isUnsigned = TRUE;
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
            tp = &stdubyte;//&stduint;
						(*node)->sym = sp;
						(*node)->tp = tp;
						break;
		case bt_ichar:
		case bt_iuchar:
			if (tp->isUnsigned) {
				*node = makenode(en_ref, *node, (ENODE *)NULL);
				(*node)->isUnsigned = TRUE;
			}
			else
				*node = makenode(en_ref, *node, (ENODE *)NULL);
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
			if (tp->isUnsigned)
				tp = &stdiuchar;
			else
				tp = &stdichar;
			(*node)->sym = sp;
			(*node)->tp = tp;
			break;
		case bt_uchar:
		case bt_char:
        case bt_enum:
			if (tp->isUnsigned) {
				*node = makenode(en_ref,*node,(ENODE *)NULL);
				(*node)->isUnsigned = TRUE;
			}
			else
				*node = makenode(en_ref,*node,(ENODE *)NULL);
			//(*node)->esize = sizeOfPtr;
			//(*node)->etype = bt_pointer;
			//(*node)->tp = TYP::Make(bt_pointer, sizeOfPtr);
			//if (tp->isUnsigned)
			//	(*node)->tp->btp = stduchar.GetIndex();
			//else
			//	(*node)->tp->btp = stdchar.GetIndex();
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
			if (tp->isUnsigned)
	      tp = &stduchar;
			else
	      tp = &stdchar;
			(*node)->sym = sp;
			(*node)->tp = tp;
			break;

		case bt_ushort:
		case bt_short:
			if (tp->isUnsigned) {
				*node = makenode(en_ref,*node,(ENODE *)NULL);
				(*node)->esize = tp->size;
				(*node)->etype = (enum e_bt)tp->type;
				(*node)->isUnsigned = TRUE;
				tp = &stdushort;
			}
			else {
				*node = makenode(en_ref,*node,(ENODE *)NULL);
				(*node)->esize = tp->size;
				(*node)->etype = (enum e_bt)tp->type;
				(*node)->isUnsigned = FALSE;
				tp = &stdshort;
			}
			(*node)->sym = sp;
			(*node)->tp = tp;
			break;

		case bt_exception:
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
			(*node)->isUnsigned = TRUE;
			*node = makenode(en_ref,*node,(ENODE *)NULL);
			(*node)->sym = sp;
			(*node)->tp = tp;
			break;

		case bt_ulong:
		case bt_long:
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
			if (tp->isUnsigned) {
				(*node)->isUnsigned = TRUE;
				*node = makenode(en_ref,*node,(ENODE *)NULL);
			}
			else {
				*node = makenode(en_ref,*node,(ENODE *)NULL);
			}
			(*node)->sym = sp;
			(*node)->tp = tp;
			break;

		case bt_vector:
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
      *node = makenode(en_ref,*node,(ENODE *)NULL);
			(*node)->isUnsigned = TRUE;
			(*node)->sym = sp;
			(*node)->tp = tp;
			break;

		case bt_vector_mask:
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
      *node = makenode(en_ref,*node,(ENODE *)NULL);
			(*node)->isUnsigned = TRUE;
			(*node)->vmask = (*node)->p[0]->vmask;
			(*node)->sym = sp;
			(*node)->tp = tp;
			(*node)->tp = tp;
			break;

		// Pointers (addresses) are always unsigned
		case bt_pointer:
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
			*node = makenode(en_ref, *node, (ENODE *)NULL);
			(*node)->isUnsigned = TRUE;
			(*node)->sym = sp;
			(*node)->tp = tp;
			break;

		case bt_unsigned:
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
      *node = makenode(en_ref,*node,(ENODE *)NULL);
			(*node)->isUnsigned = TRUE;
			(*node)->sym = sp;
			(*node)->tp = tp;
			break;

    case bt_triple:
            *node = makenode(en_ref,*node,(ENODE *)NULL);
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
            tp = &stdtriple;
						(*node)->sym = sp;
						(*node)->tp = tp;
						break;
		case bt_quad:
            *node = makenode(en_ref,*node,(ENODE *)NULL);
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
            tp = &stdquad;
						(*node)->sym = sp;
						(*node)->tp = tp;
						break;
        case bt_double:
            *node = makenode(en_ref,*node,(ENODE *)NULL);
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
            tp = &stddouble;
						(*node)->sym = sp;
						(*node)->tp = tp;
						break;
        case bt_float:
            *node = makenode(en_ref,*node,(ENODE *)NULL);
			(*node)->esize = tp->size;
			(*node)->etype = (enum e_bt)tp->type;
            tp = &stdflt;
						(*node)->sym = sp;
						(*node)->tp = tp;
						break;
		case bt_bitfield:
			if (tp->isUnsigned){
				*node = makenode(en_fieldref, *node, (ENODE *)NULL);
				(*node)->isUnsigned = TRUE;
			}
			else {
				*node = makenode(en_fieldref, *node, (ENODE *)NULL);
			}
			(*node)->bit_width = tp->bit_width;
			(*node)->bit_offset = tp->bit_offset;
			/*
			* maybe it should be 'unsigned'
			*/
			(*node)->etype = tp->type;//(enum e_bt)stdint.type;
			(*node)->esize = tp->size;
			tp = &stdint;
			(*node)->sym = sp;
			(*node)->tp = tp;
			break;
		//case bt_func:
		//case bt_ifunc:
		//	(*node)->esize = tp->size;
		//	(*node)->etype = tp->type;
		//	(*node)->isUnsigned = TRUE;
		//	*node = makenode(en_uw_ref,*node,NULL);
  //    break;
		//case bt_class:
		//case bt_struct:
		//case bt_union:
		//  dfs.printf("F");
		//	(*node)->esize = tp->size;
		//	(*node)->etype = (e_bt)tp->type;
  //    *node = makenode(en_struct_ref,*node,NULL);
		//	(*node)->isUnsigned = TRUE;
  //    break;

		// Not sure about this, dereferencing a void type.
		// NULL is often defined as a pointer with the value zero.
		// It's actually a pointer to void that's desired for dereferencing.
		// For now, uses a pointer to word or half word.
		case bt_void:
			(*node)->esize = 0;
			(*node)->etype = (enum e_bt)tp->type;
			*node = makenode(en_ref, *node, (ENODE *)NULL);
			(*node)->isUnsigned = TRUE;
			(*node)->sym = sp;
			(*node)->tp = tp;
			break;

		default:
		  dfs.printf("Deref :%d\n", tp->type);
		  if ((*node)->msp)
		     dfs.printf("%s\n",(char *)(*node)->msp->c_str());
			error(ERR_DEREF);
			break;
    }
	(*node)->isVolatile = tp->isVolatile;
	(*node)->constflag = tp->isConst;
	(*node)->sym = sp;
	(*node)->tp = tp;
	dfs.printf("</Deref>");
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
	int64_t sz;
	int dimen;
	int numele;
  
	//if (tp->type == bt_pointer && !tp->isArray)
	//	return (tp);
	if (tp->isArray == false)
		if (tp->type != bt_struct
			&& tp->type != bt_union
			&& tp->type != bt_class
			&& tp->type != bt_ifunc
			&& tp->type != bt_func
			)
			return (deref(node, tp));
	if (tp->type == bt_pointer && sizeof_flag == 0) {
		sz = tp->size;
		dimen = tp->dimen;
		numele = tp->numele;
		tp1 = tp->GetBtp();
		if (tp1==NULL)
			printf("DIAG: CondDeref: tp1 is NULL\r\n");
		tp =(TYP *) TYP::Make(bt_pointer, sizeOfPtr);
		tp->isArray = true;
		tp->dimen = dimen;
		tp->numele = numele;
		tp->btp = tp1->GetIndex();
		tp->isUnsigned = TRUE;
	}
	else if (tp->type==bt_pointer)
		return (tp);
	//    else if (tp->type==bt_struct || tp->type==bt_union)
	//       return deref(node, tp);
	return (tp);
}
/*
TYP *CondDeref(ENODE **node, TYP *tp)
{
  if (tp->val_flag == 0)
    return deref(node, tp);
  if (tp->type == bt_pointer && sizeof_flag == 0)
   	tp->size = 2;
  return tp;
}
*/

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
	SYM *sp = nullptr;
	Function *fn;
	TYP *tp;
	int typ;
	std::string stnm;

	dfs.puts("<nameref2>\n");
	if (tbl) {
		dfs.printf("searching table for:%d:%s|",TABLE::matchno,(char *)name.c_str());
		tbl->Find(name,bt_long,typearray,true);
		//		gsearch2(name,bt_long,typearray,true);
		sp = Function::FindExactMatch(TABLE::matchno, name, bt_long, typearray)->sym;
		//		if (sp==nullptr) {
		//			printf("notfound\r\n");
		//			sp = gsearch2(name,bt_long,typearray,false);
		//		}
	}
	else {
	dfs.printf("A:%d:%s",TABLE::matchno,(char *)name.c_str());
	fn = Function::FindExactMatch(TABLE::matchno, name, bt_long, typearray);
	// If we didn't have an exact match and no (parameter) types are known
	// return the match if there is only a single one.
	if (fn==nullptr) {
		TypeArray *ta, *tb;
		int n;
		if (TABLE::matchno == 1 && typearray == nullptr)
			sp = TABLE::match[0];
		// This is a hack in lieu of better declaration processing.
		// Declarations can generate multiple copies of the function
		// information if there are prototypes. If all the function
		// information is the same then it may match.
		else if (TABLE::matchno > 1) {
			bool isSame = true;
			ta = tb = nullptr;
			for (n = 0; n < TABLE::matchno; n++) {
				sp = TABLE::match[n];
				ta = sp->fi->GetProtoTypes();
				if (n > 0) {
					if (!ta->IsEqual(tb))
						isSame = false;
				}
				tb = ta;
			}
			if (!isSame)
				sp = nullptr;
		}
		else
			sp = nullptr;
	}
	else
		sp = fn->sym;
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
		while( my_isspace(lastch) )
			getch();
		if( lastch == '(') {
			sp = allocSYM();
			sp->fi = allocFunction(sp->id);
			sp->fi->sym = sp;
			sp->fi->IsPascal = defaultcc == 1;
			sp->tp = &stdfunc;
			sp->SetName(*(new std::string(lastid)));
			sp->storage_class = sc_external;
			sp->IsUndefined = TRUE;
			dfs.printf("Insert at nameref\r\n");
			typearray->Print();
			//    gsyms[0].insert(sp);
			tp = &stdfunc;
			*node = makesnode(en_cnacon,sp->name, sp->BuildSignature(1),sp->value.i);
			(*node)->constflag = TRUE;
			(*node)->sym = sp;
			if (sp->tp->isUnsigned)
				(*node)->isUnsigned = TRUE;
			(*node)->esize = 8;
			(*node)->isPascal = sp->fi->IsPascal;
		}
		else {
			dfs.printf("Undefined symbol2 in nameref\r\n");
			tp = (TYP *)NULL;
			*node = makeinode(en_labcon,9999);
			error(ERR_UNDEFINED);
		}
	}
	else {
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
				*node = makesnode(en_cnacon,new std::string(stnm), sp->fi->BuildSignature(),sp->value.i);
				(*node)->isPascal = sp->fi->IsPascal;
				(*node)->constflag = TRUE;
				(*node)->esize = 8;
				//*node = makesnode(en_nacon,sp->name);
				//(*node)->constflag = TRUE;
			}
			else {
				*node = makeinode(en_labcon,sp->value.i);
				(*node)->constflag = TRUE;
				(*node)->esize = sp->tp->size;//8;
				(*node)->segment = dataseg;
			}
			if (sp->tp->isUnsigned) {
				(*node)->isUnsigned = TRUE;
				(*node)->esize = sp->tp->size;
			}
			(*node)->etype = bt_pointer;//sp->tp->type;
			break;

		case sc_thread:
			*node = makeinode(en_labcon,sp->value.i);
			(*node)->segment = tlsseg;
			(*node)->constflag = TRUE;
			(*node)->esize = sp->tp->size;
			(*node)->etype = bt_pointer;//sp->tp->type;
			if (sp->tp->isUnsigned)
				(*node)->isUnsigned = TRUE;
			break;

		case sc_global:
		case sc_external:
			if (sp->tp->type == bt_func || sp->tp->type == bt_ifunc) {
				*node = makesnode(en_cnacon, sp->name, sp->mangledName, sp->value.i);
				(*node)->isPascal = sp->fi->IsPascal;
			}
			else
				*node = makesnode(en_nacon,sp->name,sp->mangledName,sp->value.i);
			(*node)->constflag = TRUE;
			(*node)->esize = sp->tp->size;
			(*node)->etype = bt_pointer;//sp->tp->type;
			(*node)->isUnsigned = TRUE;// sp->tp->isUnsigned;
			break;

		case sc_const:
			if (sp->tp->type==bt_quad)
				*node = makefqnode(en_fqcon,&sp->f128);
			else if (sp->tp->type==bt_float || sp->tp->type==bt_double || sp->tp->type==bt_triple)
				*node = makefnode(en_fcon,sp->value.f);
			else {
				*node = makeinode(en_icon,sp->value.i);
				if (sp->tp->isUnsigned)
				(*node)->isUnsigned = TRUE;
			}
			(*node)->constflag = TRUE;
			(*node)->esize = sp->tp->size;
			break;

		default:        /* auto and any errors */
			if (sp->storage_class == sc_member) {	// will get this for a class member
				// If it's a member we need to pass r25 the class pointer on
				// the stack.
				isMember = true;
				if ((sp->tp->type==bt_func || sp->tp->type==bt_ifunc) 
				||(sp->tp->type==bt_pointer && (sp->tp->GetBtp()->type == bt_func ||sp->tp->GetBtp()->type == bt_ifunc)))
				{
					*node = makesnode(en_cnacon,sp->name, sp->fi->BuildSignature(),25);
					(*node)->isPascal = sp->fi->IsPascal;
				}
				else {
					*node = makeinode(en_classcon,sp->value.i);
				}
				if (sp->tp->isUnsigned || sp->tp->type==bt_pointer)
					(*node)->isUnsigned = TRUE;
			}
			else {
				if( sp->storage_class != sc_auto) {
					error(ERR_ILLCLASS);
				}
				//sc_member
				if (sp->tp->IsVectorType())
					*node = makeinode(en_autovcon,sp->value.i);
				else if (sp->tp->type==bt_vector_mask)
					*node = makeinode(en_autovmcon,sp->value.i);
				else if (sp->tp->IsFloatType())
					*node = makeinode(en_autofcon,sp->value.i);
				else {
					*node = makeinode(en_autocon,sp->value.i);
					if (sp->tp->isUnsigned)
						(*node)->isUnsigned = TRUE;
				}
				if (sp->IsRegister) {
					if (sp->tp->IsFloatType())
						(*node)->nodetype = en_fpregvar;
					else
						(*node)->nodetype = en_regvar;
					//(*node)->i = sp->reg;
					(*node)->rg = sp->reg;
					(*node)->tp = sp->tp;
					//(*node)->tp->val_flag = TRUE;
				}
			}
			(*node)->esize = sp->tp->size;
			switch((*node)->nodetype) {
			case en_regvar:		(*node)->etype = bt_long;	break;//sp->tp->type;
			case en_fpregvar:	(*node)->etype = sp->tp->type;	break;//sp->tp->type;
			default:			(*node)->etype = bt_pointer;break;//sp->tp->type;
			}
			//(*node)->etype = ((*node)->nodetype == en_regvar) ? bt_long : bt_pointer;//sp->tp->type;
			break;
		}
		(*node)->SetType(sp->tp);
		(*node)->sym = sp;
		dfs.printf("tp:%p ",(char *)tp);
		// Not sure about this if - wasn't here in the past.
//		if (sp->tp->type!=bt_func && sp->tp->type!=bt_ifunc)
		tp = CondDeref(node,tp);
		dfs.printf("deref tp:%p ",(char *)tp);
	}
	if (nt)
		NextToken();
xit:
	(*node)->sym = sp;
	if (sp) {
		if (sp->fi)
			(*node)->isPascal = sp->fi->IsPascal;
	}
	if (!tp)
		dfs.printf("returning nullptr2");
	dfs.puts("</nameref2>\n");
	return (tp);
}

TYP *nameref(ENODE **node,int nt)
{
	TYP *tp;
	std::string str;
	Function *fn;
	SYM *sym;

	dfs.puts("<Nameref>");
	dfs.printf("GSearchfor:%s|",lastid);
	str = GetNamespace();
	str += lastid;
	gsearch2(str.c_str(), (__int16)bt_long, nullptr, false);
	if (TABLE::matchno == 0) {
		gsearch2(lastid, (__int16)bt_long, nullptr, false);
		tp = nameref2(lastid, node, nt, true, nullptr, nullptr);
	}
	else {
		tp = nameref2(str.c_str(), node, nt, true, nullptr, nullptr);
	}
	dfs.puts("</Nameref>\n");
	return (tp);
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
//
// ArgumentList will build a list of parameter expressions in
// a function call and return a pointer to the last expression
// parsed. since parameters are generally pushed from right
// to left we get just what we asked for...
//
ENODE *Expression::ParseArgumentList(ENODE *hidden, TypeArray *typearray)
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
		typ = ParseNonCommaExpression(&ep2);          // evaluate a parameter
		if (typ)
			dfs.printf("%03d ", typ->typeno);
		else
			dfs.printf("%03d ", 0);
		if (ep2==nullptr)
			ep2 = makeinode(en_icon, 0);
		if (typ==nullptr) {
			error(ERR_BADARG);
			typearray->Add((int)bt_long,0);
		}
		else {
			// If a function pointer is passed, we want a pointer type
			if (typ->typeno==bt_func || typ->typeno == bt_ifunc)
				typearray->Add((int)bt_pointer,0);
			else
				typearray->Add(typ,0);
		}
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
			return (sp->storage_class==sc_typedef || sp->storage_class==sc_type);
		return (FALSE);
	}
	else
		return (IsIntrinsicType(st) || st==kw_volatile);
}

SYM *makeint2(std::string name)
{
	SYM *sp;
	TYP *tp;
	sp = allocSYM();
	tp = TYP::Make(bt_long,2);
	tp->sname = new std::string("");
	sp->SetName(name);
	sp->storage_class = sc_auto;
	sp->SetType(tp);
	return sp;
}


SYM *makeStructPtr(std::string name)
{
	SYM *sp;
	TYP *tp,*tp2;
	sp = allocSYM();
	tp = TYP::Make(bt_pointer,sizeOfPtr);
	tp2 = TYP::Make(bt_struct,sizeOfPtr);
	tp->btp = tp2->GetIndex();
	tp->sname = new std::string("");
	tp->isUnsigned = TRUE;
	sp->SetName(name);
	sp->storage_class = sc_auto;
	sp->SetType(tp);
	return sp;
}


// This function is dead code.
// Create a list of dummy parameters based on argument types.
// This is needed in order to add a function to the tables if
// the function hasn't been encountered before.

SYM *CreateDummyParameters(ENODE *ep, SYM *parent, TYP *tp)
{
	int64_t poffset;
	SYM *sp1;
	SYM *list;
	int nn;
	ENODE *p;
	static char buf[20];

	list = nullptr;
	poffset = Compiler::GetReturnBlockSize();

	// Process hidden parameter
	if (tp) {
		if (tp->GetBtp()) {
			if (tp->GetBtp()->type==bt_struct || tp->GetBtp()->type==bt_union || tp->GetBtp()->type==bt_class ) {
				sp1 = makeint2(std::string(my_strdup("_pHiddenStructPtr")));
				sp1->parent = parent->GetIndex();
				sp1->value.i = poffset;
				poffset += sizeOfWord;
				sp1->storage_class = sc_auto;
				sp1->next = 0;
				list = sp1;
			}
		}
	}
	nn = 0;
	for(p = ep; p; p = p->p[1]) {
		sprintf_s(buf,sizeof(buf),"_p%d", nn);
		sp1 = makeint2(std::string(my_strdup(buf)));
		if (p->p[0]==nullptr)
			sp1->tp =(TYP *) TYP::Make(bt_long,2);
		else
			sp1->SetType(p->p[0]->tp);
		sp1->parent = parent->GetIndex();
		sp1->value.i = poffset;
		// Check for aggregate types passed as parameters. Structs
		// and unions use the type size. There could also be arrays
		// passed.
		poffset += round10(sp1->tp->size);
		poffset = round10(poffset);
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
// ----------------------------------------------------------------------------

ENODE *Sub1(TYP *tptr, int64_t val)
{
	ENODE *pnode;

	tptr->isConst = TRUE;
	pnode = makeinode(en_icon, val);
	pnode->constflag = TRUE;
	if (val >= -128 && ival < 128)
		pnode->esize = 1;
	else if (val >= -32768 && val < 32768)
		pnode->esize = 2;
	else if (val >= -2147483648LL && val < 2147483648LL)
		pnode->esize = 4;
	else if (val >= -54975581300LL && val < 54975581300LL)
		pnode->esize = 5;
	else
		pnode->esize = 2;
	pnode->SetType(tptr);
	return (pnode);
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
TYP *Expression::ParsePrimaryExpression(ENODE **node, int got_pa)
{
	ENODE *pnode, *qnode1, *qnode2;
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
    return (tptr);
  }
  switch( lastst ) {
	case ellipsis:
  case id:
    tptr = nameref(&pnode,TRUE);
		// Convert a reference to a constant to a constant. Need this for
		// GetIntegerExpression().
		if (pnode->IsRefType()) {
			if (pnode->p[0]->nodetype == en_icon) {
				pnode = Sub1(tptr, pnode->p[0]->i);
			}
			//else if (pnode->p[0]->nodetype == en_fcon) {
			//	rval = pnode->p[0]->f;
			//	rval128 = pnode->p[0]->f128;
			//	goto j2;
			//}
		}
				//pnode->p[3] = (ENODE *)tptr->size;
//				if (pnode->nodetype==en_nacon)
//					pnode->p[0] = makenode(en_list,tptr->BuildEnodeTree(),nullptr);
		//else if (sp = gsyms->Find(lastid, false)) {
		//	if (TABLE::matchno > 1) {
		//		for (i = 0; i < TABLE::matchno) {
		//			sp = TABLE::match[i];
		//		}
		//	}
		//	if (sp->tp == &stdconst) {
		//		ival = sp->value.i;
		//		lastst = iconst;
		//		return;
		//	}
		//}

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
  case cconst:
    tptr = &stdchar;
    tptr->isConst = TRUE;
    pnode = makeinode(en_icon,ival);
    pnode->constflag = TRUE;
		pnode->esize = 1;
    pnode->SetType(tptr);
    NextToken();
    break;
  case iconst:
    tptr = &stdint;
		pnode = Sub1(tptr, ival);
    NextToken();
    break;

	case kw_floatmax:
    tptr = &stdquad;
    tptr->isConst = TRUE;
    pnode = makefnode(en_fcon,rval);
    pnode->constflag = TRUE;
    pnode->SetType(tptr);
		pnode->i = quadlit(Float128::FloatMax());
    NextToken();
		break;

    case rconst:
j2:
      pnode = makefnode(en_fcon,rval);
      pnode->constflag = TRUE;
			pnode->i = quadlit(&rval128);
			pnode->f128 = rval128;
			switch(float_precision) {
			case 'Q': case 'q':
				tptr = &stdquad;
				//getch();
				break;
			case 'D': case 'd':
				tptr = &stddouble;
				//getch();
				break;
			case 'T': case 't':
				tptr = &stdtriple;
				//getch();
				break;
			case 'S': case 's':
				tptr = &stdflt;
				//getch();
				break;
			default:
				tptr = &stddouble;
				break;
			}
      pnode->SetType(tptr);
      tptr->isConst = TRUE;
      NextToken();
      break;

	case sconst:
	{
		char *str;

		str = GetStrConst();
		if (sizeof_flag) {
			tptr = (TYP *)TYP::Make(bt_pointer, 0);
			tptr->size = strlen(str) + 1;
			tptr->btp = TYP::Make(bt_char, 2)->GetIndex();// stdchar.GetIndex();
			tptr->GetBtp()->isConst = TRUE;
			tptr->val_flag = 1;
			tptr->isConst = TRUE;
			tptr->isUnsigned = TRUE;
		}
		else {
			tptr = &stdstring;
		}
		pnode = makenodei(en_labcon, (ENODE *)NULL, 0);
		if (sizeof_flag == 0)
			pnode->i = stringlit(str);
		free(str);
		pnode->etype = bt_pointer;
		pnode->esize = 2;
		pnode->constflag = TRUE;
		pnode->segment = rodataseg;
		pnode->SetType(tptr);
		tptr->isConst = TRUE;
	}
  break;
	case asconst:
	{
		char *str;

		str = GetStrConst();
		if (sizeof_flag) {
			tptr = (TYP *)TYP::Make(bt_pointer, 0);
			tptr->size = strlen(str) + 1;
			switch (str[0]) {
			case 'B':
				tptr->btp = TYP::Make(bt_byte, 1)->GetIndex();
				break;
			case 'C':
				tptr->btp = TYP::Make(bt_char, 2)->GetIndex();
				break;
			case 'H':
				tptr->btp = TYP::Make(bt_short, 4)->GetIndex();
				break;
			case 'W':
				tptr->btp = TYP::Make(bt_long, 8)->GetIndex();
				break;
			}
			tptr->GetBtp()->isConst = TRUE;
			tptr->val_flag = 1;
			tptr->isConst = TRUE;
			tptr->isUnsigned = TRUE;
		}
		else {
			tptr = &stdastring;
		}
		pnode = makenodei(en_labcon, (ENODE *)NULL, 0);
		if (sizeof_flag == 0)
			pnode->i = stringlit(str);
		switch (str[0]) {
		case 'B': pnode->esize = 1; break;
		case 'C': pnode->esize = 2; break;
		case 'H': pnode->esize = 4; break;
		case 'W': pnode->esize = 8; break;
		}
		free(str);
		pnode->etype = bt_pointer;
		pnode->constflag = TRUE;
		pnode->segment = rodataseg;
		pnode->SetType(tptr);
		tptr->isConst = TRUE;
	}
	break;
	case isconst:
	{
		char *str;

		str = GetStrConst();
		if (sizeof_flag) {
			tptr = (TYP *)TYP::Make(bt_pointer, 0);
			tptr->size = strlen(str) + 1;
			tptr->btp = TYP::Make(bt_ichar, 2)->GetIndex();// stdchar.GetIndex();
			tptr->GetBtp()->isConst = TRUE;
			tptr->val_flag = 1;
			tptr->isConst = TRUE;
			tptr->isUnsigned = TRUE;
		}
		else {
			tptr = &stdistring;
		}
		pnode = makenodei(en_labcon, (ENODE *)NULL, 0);
		if (sizeof_flag == 0)
			pnode->i = stringlit(str);
		free(str);
		pnode->etype = bt_pointer;
		pnode->esize = 2;
		pnode->constflag = TRUE;
		pnode->segment = rodataseg;
		pnode->SetType(tptr);
		tptr->isConst = TRUE;
	}
	break;

    case openpa:
        NextToken();

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
		tptr = TYP::Make(bt_pointer,sizeOfPtr);
		tptr->btp = tptr2->GetIndex();
		tptr->isUnsigned = TRUE;
		dfs.puts((char *)tptr->GetBtp()->sname->c_str());
		pnode = makeinode(en_regvar,regCLP);
		dfs.puts("</ExprThis>");
        break;

	case begin:
		{
			int sz = 0;
			ENODE *list;

			NextToken();
			head = tail = nullptr;
			list = makenode(en_list,nullptr,nullptr);
			while (lastst != end) {
				tptr = ParseNonCommaExpression(&pnode);
				pnode->SetType(tptr);
				//sz = sz + tptr->size;
				sz = sz + pnode->esize;
				list->esize = pnode->esize;
				AddToList(list, pnode);
				if (lastst!=comma)
					break;
				NextToken();
			}
			needpunc(end,9);
			pnode = makenode(en_aggregate,list,nullptr);
			pnode->SetType(tptr = TYP::Make(bt_struct,sz));
			pnode->esize = sz;
			pnode->i = litlist(pnode);
			list->i = pnode->i;
		}
		break;

    default:
        Leave("ParsePrimary", 0);
        return (TYP *)NULL;
    }
	*node = pnode;
    if (*node)
       (*node)->SetType(tptr);
    if (tptr)
    Leave("ParsePrimary", tptr->type);
    else
    Leave("ParsePrimary", 0);
    return tptr;
}

//
// This function returns true if the node passed is an IsLValue.
// this can be qualified by the fact that an IsLValue must have
// one of the dereference operators as it's top node.
// OR
// It's a simple add to an LValue (arrays), the result would still be an LValue
// We want arrays and structure types to be treated as LValues although they
// aren't really. This is because they are manipulated as pointers to RValues
// not RValues. And we don't want to have to test everywhere for struct types,
// so we just say it's an LValue.
//
int IsLValue(ENODE *node)
{
	if (node==nullptr)
		return FALSE;
	switch (node->nodetype) {
	case en_ref:
	case en_fieldref:
		return (TRUE);
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
	case en_ccwp:
	case en_cucwp:
		return IsLValue(node->p[0]);
		// Detect if there's an addition to a pointer happening.
	// For an array reference there will be an add node at the top of the
	// expression tree. This evaluates to an address which is essentially
	// the same as an *_ref node. It's an LValue.
	case en_add:
		return (IsLValue(node->p[0]) || IsLValue(node->p[1]));
	case en_nacon:
	case en_autocon:
		return (node->etype == bt_pointer || node->etype == bt_struct || node->etype == bt_union || node->etype == bt_class);
	// A typecast will connect the types with a void node
	case en_void:
		return (IsLValue(node->p[1]));
	}
/*
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
	case en_ccwp:
	case en_cucwp:
    return IsLValue(node->p[0]);
	// Detect if there's an addition to a pointer happening.
	// For an array reference there will be an add node at the top of the
	// expression tree. This evaluates to an address which is essentially
	// the same as an *_ref node. It's an LValue.
	case en_add:
		return (IsLValue(node->p[0]) || IsLValue(node->p[1]));
		if (node->tp)
			return (node->tp->type == bt_pointer || node->tp->type == bt_struct || node->tp->type == bt_union || node->tp->type == bt_class);
//			return (node->tp->type==bt_pointer && node->tp->isArray) || node->tp->type==bt_struct;
		else
			return (FALSE);
	case en_nacon:
	case en_autocon:
		return (node->etype == bt_pointer || node->etype == bt_struct || node->etype == bt_union || node->etype == bt_class);
	//case en_fcall:
	//	return (node->etype == bt_pointer);
	case en_addrof:
		return (TRUE);
	}
*/
	return (FALSE);
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
TYP *Autoincdec(TYP *tp, ENODE **node, int flag, bool isPostfix)
{
	ENODE *ep1, *ep2, *ep3;
	TYP *typ;
	int su;

	if (isPostfix)
		ep1 = (*node)->Clone();
	else
		ep1 = *node;
	if( IsLValue(ep1) ) {
		if (tp->type == bt_pointer) {
			typ = tp->GetBtp();
			ep2 = makeinode(en_icon,typ->size);
			ep2->esize = typ->size;
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
		if (isPostfix) {
			if (postfixList == nullptr)
				postfixList = ep1;
			else {
				for (ep2 = postfixList; ep2->p[1]; ep2 = ep2->p[1])
					;
				ep2->p[1] = makenode(en_void, ep2, ep1);
			}
		}
	}
    else
        error(ERR_LVALUE);
	if (!isPostfix) {
		*node = ep1;
		if (*node)
		    (*node)->SetType(tp);
	}
	return tp;
}


void ApplyVMask(ENODE *node, ENODE *mask)
{
	if (node==nullptr || mask==nullptr)
		return;
	if (node->p[0])
		ApplyVMask(node->p[0],mask);
	if (node->p[1])
		ApplyVMask(node->p[1],mask);
	if (node->p[2])
		ApplyVMask(node->p[2],mask);
	if (node->vmask==nullptr)
		node->vmask = mask;
	return;
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

TYP *Expression::ParsePostfixExpression(ENODE **node, int got_pa)
{
	TYP *tp1, *tp2, *tp3, *tp4;
	ENODE *ep1, *ep2, *ep3, *ep4;
	ENODE *rnode, *qnode, *pnode;
	SYM *sp, *sp1;
	int iu;
	int ii;
	bool classdet = false;
	TypeArray typearray;
	std::string name;
	int cf, uf, numdimen;
	int sz1, cnt, cnt2, totsz;
	int sa[20];
	bool firstBr = true;
	int64_t elesize;

  ep1 = (ENODE *)NULL;
  Enter("<ParsePostfix>");
  *node = (ENODE *)NULL;
	tp1 = ParsePrimaryExpression(&ep1, got_pa);
	if (ep1==NULL) {
//		ep1 = makeinode(en_icon, 0);
//		goto j1;
//	   printf("DIAG: ParsePostFix: ep1 is NULL\r\n");
	}
	if (tp1 == NULL) {
        Leave("</ParsePostfix>",0);
		return ((TYP *)NULL);
    }
	pep1 = nullptr;
	cnt = 0;
	while (1) {
		pop = lastst;
		switch(lastst) {
		case openbr:
			pnode = ep1;
			if (tp1==NULL) {
				error(ERR_UNDEFINED);
				goto j1;
			}
			NextToken();
			if( tp1->type == bt_pointer ) {
				tp2 = expression(&rnode);
				tp3 = tp1;
				tp4 = tp1;
				if (rnode==nullptr) {
					error(ERR_EXPREXPECT);
					throw new C64PException(ERR_EXPREXPECT,9);
				}
			}
			else {
				tp2 = tp1;
				rnode = pnode;
				tp3 = expression(&pnode);
				if (tp3==NULL) {
					error(ERR_UNDEFINED);
					throw new C64PException(ERR_UNDEFINED,10);
					goto j1;
				}
				tp1 = tp3;
				tp4 = tp1;
			}
			if (cnt==0) {
				numdimen = tp1->dimen;
				cnt2 = 1;
				for (; tp4; tp4 = tp4->GetBtp()) {
					sa[cnt2] = max(tp4->numele,1);
					cnt2++;
					if (cnt2 > 19) {
						error(ERR_TOOMANYDIMEN);
						break;
					}
				}
				if (tp1->type == bt_pointer) {
					sa[numdimen + 1] = tp1->GetBtp()->size;
					sa[numdimen + 1] = ep1->esize;
				}
				else
					sa[numdimen+1] = tp1->size;
			}
			if (cnt==0)
				totsz = tp1->size;
			firstBr = false;
			if (tp1->type != bt_pointer)
				error(ERR_NOPOINTER);
			else
				tp1 = tp1->GetBtp();
			//if (cnt==0) {
			//	switch(numdimen) {
			//	case 1: sz1 = sa[numdimen+1]; break;
			//	case 2: sz1 = sa[1]*sa[numdimen+1]; break;
			//	case 3: sz1 = sa[1]*sa[2]*sa[numdimen+1]; break;
			//	default:
			//		sz1 = sa[numdimen+1];	// could be a void = 0
			//		for (cnt2 = 1; cnt2 < numdimen; cnt2++)
			//			sz1 = sz1 * sa[cnt2];
			//	}
			//}
			//else if (cnt==1) {
			//	switch(numdimen) {
			//	case 2:	sz1 = sa[numdimen+1]; break;
			//	case 3: sz1 = sa[1]*sa[numdimen+1]; break;
			//	default:
			//		sz1 = sa[numdimen+1];	// could be a void = 0
			//		for (cnt2 = 1; cnt2 < numdimen-1; cnt2++)
			//			sz1 = sz1 * sa[cnt2];
			//	}
			//}
			//else if (cnt==2) {
			//	switch(numdimen) {
			//	case 3: sz1 = sa[numdimen+1]; break;
			//	default:
			//		sz1 = sa[numdimen+1];	// could be a void = 0
			//		for (cnt2 = 1; cnt2 < numdimen-2; cnt2++)
			//			sz1 = sz1 * sa[cnt2];
			//	}
			//}
			//else
			{
				if (numdimen) {
					sz1 = 1;
					for (cnt2 = 1; cnt2 <= numdimen; cnt2++)
						sz1 = sz1 * sa[cnt2];
					elesize = sa[numdimen + 1] / sz1;
				}
				else
					elesize = tp1->size;
				sa[0] = elesize;
				sz1 = sa[0];// sa[numdimen + 1];	// could be a void = 0
				for (cnt2 = 1; cnt2 < numdimen - cnt; cnt2++)
					sz1 = sz1 * sa[cnt2];
			}
			qnode = makeinode(en_icon,sz1);
			qnode->etype = bt_ushort;
			qnode->esize = 8;
			qnode->constflag = TRUE;
			qnode->isUnsigned = TRUE;
			cf = qnode->constflag;

			qnode = makenode(en_mulu, qnode, rnode);
			qnode->etype = bt_short;
			qnode->esize = 8;
			qnode->constflag = cf & rnode->constflag;
			qnode->isUnsigned = rnode->isUnsigned;
			if (rnode->sym)
				qnode->sym = rnode->sym;

			//(void) cast_op(&qnode, &tp_int32, tp1);
			cf = pnode->constflag;
			uf = pnode->isUnsigned;
			sp1 = pnode->sym;
			pnode = makenode(en_add, qnode, pnode);
			pnode->etype = bt_pointer;
			pnode->esize = sizeOfPtr;
			pnode->constflag = cf & qnode->constflag;
			pnode->isUnsigned = uf & qnode->isUnsigned;
			if (pnode->sym == nullptr)
				pnode->sym = sp1;
			if (pnode->sym == nullptr)
				pnode->sym = qnode->sym;

			tp1 = CondDeref(&pnode, tp1);
			pnode->tp = tp1;
			ep1 = pnode;
			needpunc(closebr,9);
			cnt++;
			break;

		case openpa:
			cnt = 0;
			if (tp1==NULL) {
				error(ERR_UNDEFINED);
				goto j1;
			}
			tp2 = ep1->tp;
			if (tp2==nullptr) {
				error(ERR_UNDEFINED);
				goto j1;
			}
			if (tp2->type==bt_vector_mask) {
				NextToken();
				tp1 = expression(&ep2);
				needpunc(closepa,9);
				ApplyVMask(ep2,ep1);
				ep1 = ep2;
				break;
			}
			if (tp2->type == bt_pointer) {
				dfs.printf("Got function pointer.\n");
			}
			dfs.printf("tp2->type=%d",tp2->type);
			name = lastid;
			NextToken();
			tp3 = tp1->GetBtp();
			ep4 = nullptr;
			if (tp3) {
				if (tp3->type==bt_struct || tp3->type==bt_union || tp3->type==bt_class)
					ep4 = makenode(en_regvar,NULL,NULL);
			}
			//ep2 = ArgumentList(ep1->p[2],&typearray);
			ep2 = ParseArgumentList(ep4,&typearray);
			typearray.Print();
			dfs.printf("Got Type: %d",tp1->type);
			if (tp1->type==bt_pointer) {
				dfs.printf("Got function pointer.\n");
				ep1 = makefcnode(en_fcall,ep1,ep2,nullptr);
				currentFn->IsLeaf = FALSE;
				break;
			}
			dfs.printf("openpa calling gsearch2");
			sp = ep1->sym;
			/*
			sp = nullptr;
			ii = tp1->lst.FindRising(name);
			if (ii) {
				sp = Function::FindExactMatch(TABLE::matchno, name, bt_long, &typearray)->sym;
			}
			if (!sp)
				sp = gsearch2(name,bt_long,&typearray,true);
			*/
			if (sp==nullptr) {
				sp = allocSYM();
				sp->fi = allocFunction(sp->id);
				sp->fi->sym = sp;
				sp->storage_class = sc_external;
				sp->SetName(name);
				sp->tp = TYP::Make(bt_func,0);
				sp->tp->btp = TYP::Make(bt_long,sizeOfWord)->GetIndex();
				sp->fi->AddProto(&typearray);
				sp->mangledName = sp->fi->BuildSignature();
				gsyms[0].insert(sp);
			}
			else if (sp->IsUndefined) {
				sp->tp = TYP::Make(bt_func,0);
				sp->tp->btp = TYP::Make(bt_long,sizeOfWord)->GetIndex();
				if (!sp->fi) {
					sp->fi = allocFunction(sp->id);
					sp->fi->sym = sp;
				}
				sp->fi->AddProto(&typearray);
				sp->mangledName = sp->fi->BuildSignature();
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
				//if (sp->fi)
				{
					if (!sp->fi->IsInline)
						currentFn->IsLeaf = FALSE;
				}
				//else
				//	currentFn->IsLeaf = FALSE;
			}
			tp1 = sp->tp->GetBtp();
//			tp1 = ExprFunction(tp1, &ep1);
			break;

		case pointsto:
			{
				//int reftype = sizeOfPtr==4 ? en_h_ref : en_w_ref;
				int reftype = sizeOfPtr==4 ? en_ref : en_ref;
				
				cnt = 0;
				if (tp1==NULL) {
					error(ERR_UNDEFINED);
					goto j1;
				}
				if (tp1->type == bt_struct) {
					//printf("hello");
					//ep1 = makenode(reftype, ep1, (ENODE *)NULL);
				}
				else
				if( tp1->type != bt_pointer) {
					error(ERR_NOPOINTER);
				}
				else {
					tp1 = tp1->GetBtp();
				}
				if( tp1->val_flag == FALSE ) {
					ep1 = makenode(en_ref,ep1,(ENODE *)NULL);
					ep1->isPascal = ep1->p[0]->isPascal;
					ep1->tp = tp1;
				}
			}

		 // fall through to dot operation
		case dot:
			cnt = 0;
			if (tp1==NULL) {
				error(ERR_UNDEFINED);
				goto j1;
			}
			NextToken();       /* past -> or . */
			if (tp1->IsVectorType()) {
				ParseNonAssignExpression(&qnode);
				ep2 = makenode(en_shl,qnode,makeinode(en_icon,3));
				// The dot operation will deference the result below so the
				// old dereference operation isn't needed. It is stripped 
				// off by using ep->p[0] rather than ep.
				ep1 = makenode(en_add,ep1->p[0],ep2);
				tp1 = tp1->GetBtp();
				tp1 = CondDeref(&ep1,tp1);
				break;
			}
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
			if (sp->IsPrivate && sp->parent != currentFn->sym->parent) {
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
					ep2 = ParseArgumentList(pep1,&typearray);
					typearray.Print();
					sp = Function::FindExactMatch(ii,name,bt_long,&typearray)->sym;
					if (sp) {
//						sp = TABLE::match[TABLE::matchno-1];
						ep3 = makesnode(en_cnacon,sp->name,sp->mangledName,sp->value.i);
						ep3->isPascal == sp->fi->IsPascal;
						ep1 = makenode(en_fcall,ep3,ep2);
						ep1->isPascal = ep3->isPascal;
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
				qnode = makeinode(en_icon,sp->value.i);
				qnode->constflag = TRUE;
				iu = ep1->isUnsigned;
				ep1 = makenode(en_add,ep1,qnode);
				ep1->isPascal = ep1->p[0]->isPascal;
				ep1->constflag = ep1->p[0]->constflag;
				ep1->isUnsigned = iu;
				ep1->esize = 8;
				ep1->p[2] = pep1;
				//if (tp1->type==bt_pointer && (tp1->GetBtp()->type==bt_func || tp1->GetBtp()->type==bt_ifunc))
				//	dfs.printf("Pointer to func");
				//else
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
			cnt = 0;
			NextToken();
			Autoincdec(tp1,&ep1,1,true);
			break;
		case autoinc:
			cnt = 0;
			NextToken();
			Autoincdec(tp1,&ep1,0,true);
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
	return (tp1);
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
												__mulf(a,b)
 //                     new 
 *
 */
TYP *Expression::ParseUnaryExpression(ENODE **node, int got_pa)
{
	TYP *tp, *tp1, *tp2;
  ENODE *ep1, *ep2, *ep3;
  int flag2;
	int typ;
	bool autonew = false;

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
		return (tp);
	}
  switch(lastst) {
  case autodec:
		NextToken();
		tp = ParseUnaryExpression(&ep1, got_pa);
		Autoincdec(tp,&ep1,1,false);
		break;
  case autoinc:
		NextToken();
		tp = ParseUnaryExpression(&ep1, got_pa);
		Autoincdec(tp,&ep1,0,false);
		break;
	case plus:
    NextToken();
    tp = ParseCastExpression(&ep1);
    if(tp == NULL) {
      error(ERR_IDEXPECT);
      return (TYP *)NULL;
    }
    break;

	// Negative constants are trapped here and converted to proper form.
    case minus:
        NextToken();
        tp = ParseCastExpression(&ep1);
        if( tp == NULL ) {
            error(ERR_IDEXPECT);
            return (TYP *)NULL;
        }
		else if (ep1->constflag && (ep1->nodetype==en_icon)) {
			ep1->i = -ep1->i;
		}
		else if (ep1->constflag && (ep1->nodetype==en_fcon)) {
			ep1->f = -ep1->f;
			ep1->f128.sign = !ep1->f128.sign;
			// A new literal label is required.
			ep1->i = quadlit(&ep1->f128);
		}
		else
		
		{
			ep1 = makenode(en_uminus,ep1,(ENODE *)NULL);
			ep1->constflag = ep1->p[0]->constflag;
			ep1->isUnsigned = ep1->p[0]->isUnsigned;
			ep1->esize = tp->size;
			ep1->etype = (e_bt)tp->type;
		}
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
		ep1->SetType(tp);
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
		ep1->SetType(tp);
		ep1->esize = tp->size;
        break;

    case star:
      NextToken();
      tp = ParseCastExpression(&ep1);
      if(tp == NULL) {
        error(ERR_IDEXPECT);
        return (TYP *)NULL;
      }
      if( tp->GetBtp() == NULL )
			  error(ERR_DEREF);
      else {
				// A star before a function pointer just means that we want to
				// invoke the function. We want to retain the pointer to the
				// function as the type.
				if (tp->GetBtp()->type != bt_func && tp->GetBtp()->type != bt_ifunc) {
					tp = tp->GetBtp();
				}
				else
					break;
				//else {
				//	tp1 = tp;
				//	break;	// Don't derefence the function pointer
				//}
      }
	    tp1 = tp;
			if (tp->type == bt_pointer)
				typ = tp->GetBtp()->type;
		//Autoincdec(tp,&ep1);
	    tp = CondDeref(&ep1,tp);
      break;

    case bitandd:
		{
			int t;

			NextToken();
			tp = ParseCastExpression(&ep1);
			if (tp == NULL) {
				error(ERR_IDEXPECT);
				return (TYP *)NULL;
			}
			if (ep1) {
/*
				t = ep1->tp->type;
//				if (IsLValue(ep1) && !(t == bt_pointer || t == bt_struct || t == bt_union || t == bt_class)) {
				if (t == bt_struct || t == bt_union || t == bt_class) {
					////ep1 = ep1->p[0];
					//if (ep1) {
					//	ep1 = makenode(en_addrof, ep1, nullptr);
					//	ep1->esize = 8;     // converted to a pointer so size is now 8
					//}
				}
				else */
				ep2 = ep1;
				if (IsLValue(ep1)) {
					if (ep1->nodetype != en_add) {	// array or pointer manipulation
						if (ep1->p[0])	// Cheesy hack
							ep1 = ep1->p[0];
					}
				}
				ep1->esize = 8;     // converted to a pointer so size is now 8
				tp1 = TYP::Make(bt_pointer, 8);
				tp1->btp = tp->GetIndex();
				tp1->val_flag = FALSE;
				tp1->isUnsigned = TRUE;
				tp = tp1;
			}
		}
    break;

	case kw_mulf:
		NextToken();
		needpunc(openpa,46);
		tp1 = ParseNonCommaExpression(&ep1);
		needpunc(comma, 47);
		tp2 = ParseNonCommaExpression(&ep2);
		needpunc(closepa, 48);
		ep1 = makenode(en_mulf, ep1, ep2);
		ep1->isUnsigned = TRUE;
		ep1->esize = 8;
		tp = &stduint;
		break;
/*
	case kw_abs:
		NextToken();
		if (lastst==openpa) {
			flag2 = TRUE;
			NextToken();
		}
        tp = ParseCastExpression(&ep1);
        if( tp == NULL ) {
            error(ERR_IDEXPECT);
            return (TYP *)NULL;
        }
        ep1 = makenode(en_abs,ep1,(ENODE *)NULL);
        ep1->constflag = ep1->p[0]->constflag;
		ep1->isUnsigned = ep1->p[0]->isUnsigned;
		ep1->esize = tp->size;
		if (flag2)
			needpunc(closepa,2);
		break;

	case kw_max:
	case kw_min:
		{
			TYP *tp1, *tp2, *tp3;

			flag2 = lastst==kw_max;
			NextToken();
			needpunc(comma,2);
			tp1 = ParseCastExpression(&ep1);
			if( tp1 == NULL ) {
				error(ERR_IDEXPECT);
				return (TYP *)NULL;
			}
			needpunc(comma,2);
			tp2 = ParseCastExpression(&ep2);
			if( tp1 == NULL ) {
				error(ERR_IDEXPECT);
				return (TYP *)NULL;
			}
			if (lastst==comma) {
				NextToken();
				tp3 = ParseCastExpression(&ep3);
				if( tp1 == NULL ) {
					error(ERR_IDEXPECT);
					return (TYP *)NULL;
				}
			}
			else
				tp3 = nullptr;
			tp = forcefit(&ep2,tp2,&ep1,tp1,1);
			tp = forcefit(&ep3,tp3,&ep2,tp,1);
			ep1 = makenode(flag2 ? en_max : en_min,ep1,ep2);
			ep1->p[2] = ep3;
			ep1->constflag = ep1->p[0]->constflag & ep2->p[0]->constflag & ep3->p[0]->constflag;
			ep1->isUnsigned = ep1->p[0]->isUnsigned;
			ep1->esize = tp->size;
			needpunc(closepa,2);
		}
		break;
*/
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
				tp = ParseUnaryExpression(&ep1, false);
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
			ep1->esize = 2;
			tp = &stdint;
      break;

		case kw_auto:
			NextToken();
			if (lastst != kw_new)
				break;
			autonew = true;

    case kw_new:
		{
			ENODE *ep4, *ep5;
			std::string *name = new std::string(autonew ? "__autonew" : "__new");

			currentFn->UsesNew = TRUE;
			currentFn->IsLeaf = FALSE;
			NextToken();
			if (IsBeginningOfTypecast(lastst)) {

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
				ep4 = nullptr;
				ep2 = makeinode(en_icon,head->GetHash());
				ep3 = makenode(en_object_list,nullptr,nullptr);
				ep4 = makeinode(en_icon, head->typeno);
				ep5 = makenode(en_void,ep1,nullptr);
				//ep5 = nullptr;
				//ep5 = makenode(en_void,ep2,ep5);
				//ep5 = makenode(en_void,ep3,ep5);
				//ep5 = makenode(en_void, ep4, ep5);
				ep2 = makesnode(en_cnacon, name, name, 0);
  				ep1 = makefcnode(en_fcall, ep2, ep5, nullptr);
					ep1->isAutonew = autonew;
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
  			ep3 = makenode(en_void,ep1,nullptr);
  			ep2 = makesnode(en_cnacon, name, name, 0);
  			ep1 = makefcnode(en_fcall, ep2, ep3, nullptr);
			}
		}
		break;

  case kw_delete:
		currentFn->IsLeaf = FALSE;
		NextToken();
		{
			std::string *name = new std::string("__delete");
        
  		if (lastst==openbr) {
				NextToken();
    		needpunc(closebr,50);
		  }
			tp = ParseCastExpression(&ep1);
			tp = deref(&ep1, tp);
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
			ep1 = makeinode(en_icon,head->GetHash());
		else {
			error(ERR_IDEXPECT);
			ep1 = makeinode(en_icon,1);
		}
		head = tp;
		tail = tp1;
		ep1->constflag = TRUE;
		ep1->esize = 2;
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
//		(type name) { const list }
// ----------------------------------------------------------------------------
TYP *Expression::ParseCastExpression(ENODE **node)
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
		if (IsBeginningOfTypecast(lastst)) {
			Declaration::ParseSpecifier(0); // do cast declaration
			Declaration::ParsePrefix(FALSE);
			tp = head;
			tp1 = tail;
			needpunc(closepa, 5);
			if ((tp2 = ParseCastExpression(&ep1)) == NULL) {
				error(ERR_IDEXPECT);
				tp = (TYP *)NULL;
			}
			/*
			if (tp2->isConst) {
				*node = ep1;
				return tp;
			}
			*/
			opt_const(&ep1);
			if (tp == nullptr)
				error(ERR_NULLPOINTER);
			// This is a bad idea
			if (ep1->nodetype == en_aggregate) {
				if (!ep1->AssignTypeToList(tp)) {
					error(ERR_CASTAGGR);
				}
				ep2 = ep1;
			}
			else
			{
				if (tp && tp->IsFloatType()) {
					//if (tp2->IsFloatType() && ep1->constflag)
					//	ep2 = makefnode(en_fcon, ep1->f);
					//else if (ep1->constflag)
					//	ep2 = makeinode(en_icon, ep1->i);
					//else
					ep2 = makenode(en_tempfpref, (ENODE *)NULL, (ENODE *)NULL);
				}
				else {
					//if (tp2->IsFloatType() && ep1->constflag)
					//	ep2 = makefnode(en_fcon, ep1->f);
					//else if (ep1->constflag)
					//	ep2 = makeinode(en_icon, ep1->i);
					//else
					ep2 = makenode(en_tempref, (ENODE *)NULL, (ENODE *)NULL);
					ep2->SetType(tp);
				}
				ep2 = makenode(en_void, ep2, ep1);
				if (ep1 == nullptr)
					error(ERR_NULLPOINTER);
				else {
					ep2->constflag = ep1->constflag;
					ep2->isUnsigned = ep1->isUnsigned;
					//ep2->etype = ep1->etype;
					//ep2->esize = ep1->esize;
	//				forcefit(&ep2,tp,&ep1,tp2,false);
					forcefit(&ep1, tp2, &ep2, tp, false, true);
				}
				//			forcefit(&ep2,tp2,&ep1,tp,false);
			}
			head = tp;
			tail = tp1;
			*node = ep1;
      (*node)->SetType(tp);
			return (tp);
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
	return (tp);
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
TYP *Expression::ParseMultOps(ENODE **node)
{
	ENODE *ep1, *ep2;
	TYP *tp1, *tp2;
	int	oper;
	bool isScalar;
    
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
				isScalar = !tp2->IsVectorType();
                tp1 = forcefit(&ep2,tp2,&ep1,tp1,true,false);
                switch( oper ) {
                case star:
									switch(tp1->type) {
									case bt_triple:
										ep1 = makenode(en_fmul,ep1,ep2);
										ep1->esize = sizeOfFPT;
										ep1->etype = bt_triple;
										break;
									case bt_double:
										ep1 = makenode(en_fmul,ep1,ep2);
										ep1->esize = sizeOfFPD;
										ep1->etype = bt_double;
										break;
									case bt_quad:
										ep1 = makenode(en_fmul,ep1,ep2);
										ep1->esize = sizeOfFPQ;
										ep1->etype = bt_quad;
										break;
									case bt_float:
										ep1 = makenode(en_fmul,ep1,ep2);
										ep1->esize = sizeOfFP;
										ep1->etype = bt_double;
										break;
									case bt_vector:
										if (isScalar)
											ep1 = makenode(en_vmuls,ep1,ep2);
										else
											ep1 = makenode(en_vmul,ep1,ep2);
										ep1->esize = 512;
										break;
	                default:
									// place constant as second operand.
									if (ep1->nodetype == en_icon) {
										if (tp1->isUnsigned)
											ep1 = makenode(en_mulu, ep2, ep1);
										else
											ep1 = makenode(en_mul, ep2, ep1);
									}
									else {
										if (tp1->isUnsigned)
											ep1 = makenode(en_mulu, ep1, ep2);
										else
											ep1 = makenode(en_mul, ep1, ep2);
									}
								}
								ep1->esize = tp1->size;
								ep1->etype = (e_bt)tp1->type;
                 break;
                case divide:
                if (tp1->type==bt_triple) {
									ep1 = makenode(en_fdiv,ep1,ep2);
									ep1->esize = sizeOfFPT;
									ep1->etype = bt_triple;
								}
								else if (tp1->type==bt_double) {
									ep1 = makenode(en_fdiv,ep1,ep2);
									ep1->esize = sizeOfFPD;
									ep1->etype = bt_double;
								}
								else if (tp1->type==bt_quad) {
									ep1 = makenode(en_fdiv,ep1,ep2);
									ep1->esize = sizeOfFPQ;
									ep1->etype = bt_quad;
								}
								else if (tp1->type==bt_float) {
									ep1 = makenode(en_fdiv,ep1,ep2);
									ep1->esize = sizeOfFP;
									ep1->etype = bt_double;
								}
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

TYP *Expression::ParseAddOps(ENODE **node)
{
	ENODE *ep1, *ep2, *ep3, *ep4;
  TYP *tp1, *tp2;
  int oper;
	int sz1, sz2;
	bool isScalar = true;
	bool onePtr = false;

  Enter("Addops");
  ep1 = (ENODE *)NULL;
  *node = (ENODE *)NULL;
	sz1 = sz2 = 0;
	tp1 = ParseMultOps(&ep1);
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
    tp2 = ParseMultOps(&ep2);
		if (tp2==nullptr)
			throw new C64PException(ERR_NULLPOINTER,1);
		isScalar = !tp2->IsVectorType();
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
			if (sz1 == 1 || sz1 == 2 || sz1 == 4 || sz1 == 8 || sz1 == 16 || sz1 == 32 || sz1 == 64 || sz1 == 128) {
				ep1 = makenode(en_ptrdif, ep1, ep2);
				ep1->p[4] = makeinode(en_icon, (int64_t)pwrof2(sz1));
			}
			else {
				ep1 = makenode(en_ptrdif, ep1, ep2);
				ep1->p[4] = makeinode(en_icon, (int64_t)0);
				ep4 = makeinode(en_icon, sz1);
				ep1 = makenode(en_div, ep1, ep4);
			}
			//else {
			//	ep1 = makenode(en_sub, ep1, ep2);
			//	ep4 = makeinode(en_icon, sz1);
			//	ep1 = makenode(en_div, ep1, ep4);
			//}
			tp1 = &stduint;
		}
		else {
			if( tp1->type == bt_pointer ) {
				onePtr = true;
				tp2 = forcefit(&ep2,tp2,0,&stdint,true,false);
				ep3 = makeinode(en_icon, tp1->GetBtp()->size);
				ep3->constflag = TRUE;
				ep3->esize = sizeOfWord;
    		//ep3->esize = tp2->size;
				//if (ep2->nodetype == en_icon) {
				//	ep2 = makeinode(en_icon, ep3->i * ep2->i);
				//	ep2->constflag = TRUE;
				//}
				//else
				{
					ep2 = makenode(en_mulu, ep3, ep2);
					ep2->constflag = ep2->p[1]->constflag;
					ep2->esize = sizeOfWord;
				}
			}
      else if( tp2->type == bt_pointer ) {
				onePtr = true;
        tp1 = forcefit(&ep1,tp1,0,&stdint,true,false);
				ep3 = makeinode(en_icon, sizeOfWord);// tp2->GetBtp()->size);
        ep3->constflag = TRUE;
		    ep3->esize = tp2->size;
        ep1 = makenode(en_mulu,ep3,ep1);
        ep1->constflag = ep1->p[1]->constflag;
				ep2->esize = sizeOfWord;
				tp1 = tp2;
      }
			if (!onePtr)
				tp1 = forcefit(&ep2,tp2,&ep1,tp1,true,false);
			switch (tp1->type) {
			case bt_triple:
    		ep1 = makenode( oper ? en_fadd : en_fsub,ep1,ep2);
				ep1->esize = sizeOfFPT;
				break;
			case bt_double:
    		ep1 = makenode( oper ? en_fadd : en_fsub,ep1,ep2);
				ep1->esize = sizeOfFPD;
				break;
			case bt_quad:
        //tp1 = forcefit(&ep1,tp1,&ep2,tp2,true,false);
    		ep1 = makenode( oper ? en_fadd : en_fsub,ep1,ep2);
				ep1->esize = sizeOfFPQ;
				break;
			case bt_float:
    		ep1 = makenode( oper ? en_fadd : en_fsub,ep1,ep2);
				ep1->esize = sizeOfFPS;
				break;
			case bt_vector:
				if (isScalar)
    			ep1 = makenode( oper ? en_vadds : en_vsubs,ep1,ep2);
				else
    			ep1 = makenode( oper ? en_vadd : en_vsub,ep1,ep2);
				ep1->esize = 8;
				break;
			// In the case of a pointer place any constant to be added
			// as the second operand. This will allow the use of immediate
			// mode addressing rather than having to load into a register.
			case bt_pointer:
				if (ep1->nodetype==en_icon && oper)
					ep1 = makenode(en_add, ep2, ep1);
				else
					ep1 = makenode(oper ? en_add : en_sub, ep1, ep2);
				break;
			default:
    			ep1 = makenode( oper ? en_add : en_sub,ep1,ep2);
			}
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
TYP *Expression::ParseShiftOps(ENODE **node)
{
	ENODE *ep1, *ep2;
  TYP *tp1, *tp2;
  int oper;

  Enter("Shiftop");
  *node = NULL;
	tp1 = ParseAddOps(&ep1);
	if( tp1 == 0)
    goto xit;
    while( lastst == lshift || lastst == rshift || lastst==lrot || lastst==rrot) {
            oper = (lastst == lshift);
			if (lastst==lrot || lastst==rrot)
				oper=2 + (lastst==lrot);
            NextToken();
            tp2 = ParseAddOps(&ep2);
            if( tp2 == 0 )
                    error(ERR_IDEXPECT);
            else    {
                    tp1 = forcefit(&ep2,tp2,&ep1,tp1,true,false);
					if (tp1->IsFloatType())
						error(ERR_UNDEF_OP);
					else {
						if (tp1->isUnsigned) {
							switch(oper) {
							case 0:	ep1 = makenode(en_shru,ep1,ep2); break;
							case 1:	ep1 = makenode(en_shlu,ep1,ep2); break;
							case 2:	ep1 = makenode(en_ror,ep1,ep2); break;
							case 3:	ep1 = makenode(en_rol,ep1,ep2); break;
							}
						}
						else {
							switch(oper) {
							case 0:	ep1 = makenode(en_asr,ep1,ep2); break;
							case 1:	ep1 = makenode(en_asl,ep1,ep2); break;
							case 2:	ep1 = makenode(en_ror,ep1,ep2); break;
							case 3:	ep1 = makenode(en_rol,ep1,ep2); break;
							}
						}
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

//
// relation handles the relational operators < <= > and >=.
//
TYP *Expression::ParseRelationalOps(ENODE **node)
{
	ENODE *ep1, *ep2;
  TYP *tp1, *tp2;
	bool isVector = false;
	int st;

  int nt;
  Enter("Relation");
  *node = (ENODE *)NULL;
  tp1 = ParseShiftOps(&ep1);
  if( tp1 == 0 )
    goto xit;
  for(;;) {
		if (tp1->IsVectorType())
			isVector = true;
		st = lastst;
		if (st != lt && st != leq && st != gt && st != geq)
			goto fini;
		NextToken();
		tp2 = ParseShiftOps(&ep2);
		if (tp2 == 0)
			error(ERR_IDEXPECT);
		else {
			if (tp2->IsVectorType())
				isVector = true;
			tp1 = forcefit(&ep2, tp2, &ep1, tp1, true, false);
		}
		switch(st) {
    case lt:
			if (tp1->IsVectorType())
				nt = en_vlt;
			else if (tp1->IsFloatType())
        nt = en_flt;
      else if( tp1->isUnsigned )
        nt = en_ult;
      else
        nt = en_lt;
      break;
    case gt:
			if (tp1->IsVectorType())
				nt = en_vgt;
			else if (tp1->IsFloatType())
        nt = en_fgt;
      else if( tp1->isUnsigned )
        nt = en_ugt;
      else
        nt = en_gt;
      break;
		case leq:
			if (tp1->IsVectorType())
				nt = en_vle;
			else if (tp1->IsFloatType())
        nt = en_fle;
      else if( tp1->isUnsigned )
        nt = en_ule;
      else
        nt = en_le;
      break;
		case geq:
			if (tp1->IsVectorType())
				nt = en_vge;
			else if (tp1->IsFloatType())
        nt = en_fge;
      else if( tp1->isUnsigned )
        nt = en_uge;
      else
        nt = en_ge;
      break;
    default:
      goto fini;
    }
		ep1 = makenode(nt, ep1, ep2);
		ep1->esize = 1;
		if (isVector)
			tp1 = TYP::Make(bt_vector_mask, sizeOfWord);
		PromoteConstFlag(ep1);
	}
fini: *node = ep1;
xit:
  if (*node)
		(*node)->SetType(tp1);
  Leave("Relation",0);
  return (tp1);
}

//
// equalops handles the equality and inequality operators.
//
TYP *Expression::ParseEqualOps(ENODE **node)
{
	ENODE *ep1, *ep2;
  TYP *tp1, *tp2;
  int oper;
	bool isVector = false;

  Enter("EqualOps");
  *node = (ENODE *)NULL;
  tp1 = ParseRelationalOps(&ep1);
  if( tp1 == (TYP *)NULL )
    goto xit;
	if (tp1->IsVectorType())
		isVector = true;
  while( lastst == eq || lastst == neq ) {
    oper = (lastst == eq);
    NextToken();
		//if (lastst == kw_nullptr) {
		//	NextToken();
		//	ep1 = makenode(en_isnullptr, ep1, nullptr);
		//	if (!oper)
		//		ep1 = makenode(en_not, ep1, nullptr);
		//}
		//else
		{
			tp2 = ParseRelationalOps(&ep2);
			if (tp2 == NULL)
				error(ERR_IDEXPECT);
			else {
				if (tp2->IsVectorType())
					isVector = true;
				tp1 = forcefit(&ep2, tp2, &ep1, tp1, true, false);
				if (tp1->IsVectorType())
					ep1 = makenode(oper ? en_veq : en_vne, ep1, ep2);
				else if (tp1->IsFloatType())
					ep1 = makenode(oper ? en_feq : en_fne, ep1, ep2);
				else
					ep1 = makenode(oper ? en_eq : en_ne, ep1, ep2);
				ep1->esize = 2;
				if (isVector)
					tp1 = TYP::Make(bt_vector_mask, sizeOfWord);
				ep1->etype = tp1->type;
				PromoteConstFlag(ep1);
			}
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
/*
TYP *Expression::ParseBinaryOps(ENODE **node, TYP *(*xfunc)(ENODE **),int nt, int sy)
{
	ENODE *ep1, *ep2;
	TYP *tp1, *tp2;
      
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
    else {
      tp1 = forcefit(&ep2,tp2,&ep1,tp1,true,false);
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
  return (tp1);
}
*/
TYP *Expression::ParseBitwiseAndOps(ENODE **node)
{
	ENODE *ep1, *ep2;
	TYP *tp1, *tp2;

	Enter("Binop");
	*node = (ENODE *)NULL;
	tp1 = ParseEqualOps(&ep1);
	if (tp1 == 0)
		goto xit;
	while (lastst == bitandd) {
		NextToken();
		tp2 = ParseEqualOps(&ep2);
		if (tp2 == 0)
			error(ERR_IDEXPECT);
		else {
			tp1 = forcefit(&ep2, tp2, &ep1, tp1, true, false);
			ep1 = makenode(en_and, ep1, ep2);
			ep1->esize = tp1->size;
			ep1->etype = tp1->type;
			PromoteConstFlag(ep1);
		}
	}
	*node = ep1;
xit:
	if (*node)
		(*node)->SetType(tp1);
	Leave("Binop", 0);
	return (tp1);
}

TYP *Expression::ParseBitwiseXorOps(ENODE **node)
{
	ENODE *ep1, *ep2;
	TYP *tp1, *tp2;

	Enter("Binop");
	*node = (ENODE *)NULL;
	tp1 = ParseBitwiseAndOps(&ep1);
	if (tp1 == 0)
		goto xit;
	while (lastst == uparrow) {
		NextToken();
		tp2 = ParseBitwiseAndOps(&ep2);
		if (tp2 == 0)
			error(ERR_IDEXPECT);
		else {
			tp1 = forcefit(&ep2, tp2, &ep1, tp1, true, false);
			ep1 = makenode(en_xor, ep1, ep2);
			ep1->esize = tp1->size;
			ep1->etype = tp1->type;
			PromoteConstFlag(ep1);
		}
	}
	*node = ep1;
xit:
	if (*node)
		(*node)->SetType(tp1);
	Leave("Binop", 0);
	return (tp1);
}

TYP *Expression::ParseBitwiseOrOps(ENODE **node)
{
	ENODE *ep1, *ep2;
	TYP *tp1, *tp2;

	Enter("Binop");
	*node = (ENODE *)NULL;
	tp1 = ParseBitwiseXorOps(&ep1);
	if (tp1 == 0)
		goto xit;
	while (lastst == bitorr) {
		NextToken();
		tp2 = ParseBitwiseXorOps(&ep2);
		if (tp2 == 0)
			error(ERR_IDEXPECT);
		else {
			tp1 = forcefit(&ep2, tp2, &ep1, tp1, true, false);
			ep1 = makenode(en_or, ep1, ep2);
			ep1->esize = tp1->size;
			ep1->etype = tp1->type;
			PromoteConstFlag(ep1);
		}
	}
	*node = ep1;
xit:
	if (*node)
		(*node)->SetType(tp1);
	Leave("Binop", 0);
	return (tp1);
}

TYP *Expression::ParseAndOps(ENODE **node)
{
	ENODE *ep1, *ep2;
	TYP *tp1, *tp2;

	Enter("Binop");
	*node = (ENODE *)NULL;
	tp1 = ParseBitwiseOrOps(&ep1);
	if (tp1 == 0)
		goto xit;
	while (lastst == land) {
		NextToken();
		tp2 = ParseBitwiseOrOps(&ep2);
		if (tp2 == 0)
			error(ERR_IDEXPECT);
		else {
			tp1 = forcefit(&ep2, tp2, &ep1, tp1, true, false);
			ep1 = makenode(en_land, ep1, ep2);
			ep1->esize = tp1->size;
			ep1->etype = tp1->type;
			PromoteConstFlag(ep1);
		}
	}
	*node = ep1;
xit:
	if (*node)
		(*node)->SetType(tp1);
	Leave("Binop", 0);
	return (tp1);
}

TYP *Expression::ParseSafeAndOps(ENODE **node)
{
	ENODE *ep1, *ep2;
	TYP *tp1, *tp2;

	Enter("Binop");
	*node = (ENODE *)NULL;
	tp1 = ParseAndOps(&ep1);
	if (tp1 == 0)
		goto xit;
	while (lastst == land_safe) {
		NextToken();
		tp2 = ParseAndOps(&ep2);
		if (tp2 == 0)
			error(ERR_IDEXPECT);
		else {
			tp1 = forcefit(&ep2, tp2, &ep1, tp1, true, false);
			ep1 = makenode(en_land_safe, ep1, ep2);
			ep1->esize = tp1->size;
			ep1->etype = tp1->type;
			PromoteConstFlag(ep1);
		}
	}
	*node = ep1;
xit:
	if (*node)
		(*node)->SetType(tp1);
	Leave("Binop", 0);
	return (tp1);
}

TYP *Expression::ParseOrOps(ENODE **node)
{
	ENODE *ep1, *ep2;
	TYP *tp1, *tp2;

	Enter("Binop");
	*node = (ENODE *)NULL;
	tp1 = ParseSafeAndOps(&ep1);
	if (tp1 == 0)
		goto xit;
	while (lastst == lor) {
		NextToken();
		tp2 = ParseSafeAndOps(&ep2);
		if (tp2 == 0)
			error(ERR_IDEXPECT);
		else {
			tp1 = forcefit(&ep2, tp2, &ep1, tp1, true, false);
			ep1 = makenode(en_lor, ep1, ep2);
			ep1->esize = tp1->size;
			ep1->etype = tp1->type;
			PromoteConstFlag(ep1);
		}
	}
	*node = ep1;
xit:
	if (*node)
		(*node)->SetType(tp1);
	Leave("Binop", 0);
	return (tp1);
}

TYP *Expression::ParseSafeOrOps(ENODE **node)
{
	ENODE *ep1, *ep2;
	TYP *tp1, *tp2;

	Enter("Binop");
	*node = (ENODE *)NULL;
	tp1 = ParseOrOps(&ep1);
	if (tp1 == 0)
		goto xit;
	while (lastst == lor_safe) {
		NextToken();
		tp2 = ParseOrOps(&ep2);
		if (tp2 == 0)
			error(ERR_IDEXPECT);
		else {
			tp1 = forcefit(&ep2, tp2, &ep1, tp1, true, false);
			ep1 = makenode(en_lor_safe, ep1, ep2);
			ep1->esize = tp1->size;
			ep1->etype = tp1->type;
			PromoteConstFlag(ep1);
		}
	}
	*node = ep1;
xit:
	if (*node)
		(*node)->SetType(tp1);
	Leave("Binop", 0);
	return (tp1);
}

/*
TYP *bitwiseand(ENODE **node)
{       return binop(node,Expression::ParseEqualOps,en_and,bitandd);
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

TYP     *safe_andop(ENODE **node)
{
	return binop(node, andop, en_land_safe, land_safe);
}

TYP *orop(ENODE **node)
{
	return binop(node,safe_andop,en_lor,lor);
}

TYP *safe_orop(ENODE **node)
{
	return binop(node, orop, en_lor_safe, lor_safe);
}
*/
//
//      this routine processes the hook operator.
//
TYP *Expression::ParseConditionalOps(ENODE **node)
{
	TYP *tp1, *tp2, *tp3;
  ENODE *ep1, *ep2, *ep3, *ep4;
	bool sh;

  Enter("Conditional");
  *node = (ENODE *)NULL;
  tp1 = ParseSafeOrOps(&ep1);       // get condition
  if(tp1 == (TYP *)NULL )
    goto xit;
	sh = lastst == safe_hook;
  if( lastst == hook || lastst == safe_hook) {
		ENODE *o_pfl = postfixList;

		postfixList = nullptr;
		iflevel++;
		NextToken();
		if((tp2 = ParseConditionalOps(&ep2)) == NULL) {
			error(ERR_IDEXPECT);
			goto cexit;
		}
		if (postfixList) {
//			ep2 = makenode(en_void, ep2, postfixList);
			ep2->pfl = postfixList;
		}
		postfixList = nullptr;
		needpunc(colon,6);
		if((tp3 = ParseConditionalOps(&ep3)) == NULL) {
			error(ERR_IDEXPECT);
			goto cexit;
		}
		if (postfixList) {
			//ep3 = makenode(en_void, ep3, postfixList);
			ep3->pfl = postfixList;
		}
		postfixList = o_pfl;
		forcefit(&ep3,tp3,&ep2,tp2,true,false);
		ep2 = makenode(en_void,ep2,ep3);
		ep1 = makenode(sh ? en_safe_cond:en_cond,ep1,ep2);
		tp1 = tp2;
		ep1->tp = tp2;
		ep1->esize = ep1->tp->size;
		iflevel--;
  }
cexit:  *node = ep1;
xit:
  if (*node)
    (*node)->SetType(tp1);
  Leave("Conditional",0);
  return (tp1);
}

// ----------------------------------------------------------------------------
//      asnop handles the assignment operators. currently only the
//      simple assignment is implemented.
// ----------------------------------------------------------------------------
TYP *Expression::ParseAssignOps(ENODE **node)
{      
	ENODE *ep1, *ep2, *ep3;
  TYP *tp1, *tp2;
  int op;

  Enter("Assignop");
  *node = (ENODE *)NULL;
  tp1 = ParseConditionalOps(&ep1);
  if (tp1 == 0)
    goto xit;
  for(;;) {
    switch( lastst ) {
      case assign:
        op = en_assign;
ascomm:
				NextToken();
        tp2 = ParseAssignOps(&ep2);
ascomm2:
		    if ( tp2 == 0 || !IsLValue(ep1) )
          error(ERR_LVALUE);
				else {
					//if (ep1->tp->IsAggregateType() && ep2->nodetype == en_aggregate) {
					//	ep2->p[0]->AssignTypeToList(ep1->tp);
					//	ep1 = makenode(op, ep1, ep2);
					//	ep1->esize = tp1->size;
					//	ep1->etype = tp1->type;
					//	ep1->isUnsigned = tp1->isUnsigned;
					//}
					//else
					{
						tp1 = forcefit(&ep2, tp2, &ep1, tp1, false, false);
						ep1 = makenode(op, ep1, ep2);
						ep1->esize = tp1->size;
						ep1->etype = tp1->type;
						ep1->isUnsigned = tp1->isUnsigned;
					}
					// Struct assign calls memcpy, so function is no
					// longer a leaf routine.
					if (tp1->size > 8)
						currentFn->IsLeaf = FALSE;
				}
				break;
			case asplus:
				op = en_asadd;
ascomm3:        
				NextToken();
				tp2 = ParseAssignOps(&ep2);
				if(tp1->type == bt_pointer) {
					ep3 = makeinode(en_icon, tp1->GetBtp()->size);
					ep3->esize = sizeOfPtr;
					ep2 = makenode(en_mul, ep2, ep3);
					ep2->esize = sizeOfPtr;
					ep2->isUnsigned = true;
				}
				goto ascomm2;
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
  return (tp1);
}

// ----------------------------------------------------------------------------
// Evaluate an expression where the assignment operator is not legal.
// ----------------------------------------------------------------------------
TYP *Expression::ParseNonAssignExpression(ENODE **node)
{
	TYP *tp;
	pep1 = nullptr;
	Enter("NonAssignExpression");
    *node = (ENODE *)NULL;
    tp = ParseConditionalOps(node);
    if( tp == (TYP *)NULL )
        *node =(ENODE *)NULL;
    Leave("NonAssignExpression",tp ? tp->type : 0);
     if (*node)
     	(*node)->SetType(tp);
    return tp;
}

// ----------------------------------------------------------------------------
// Evaluate an expression where the comma operator is not legal.
// Externally visible entry point for GetIntegerExpression() and
// ArgumentList().
// ----------------------------------------------------------------------------
TYP *Expression::ParseNonCommaExpression(ENODE **node)
{
	TYP *tp;
	ENODE *ep1;
	ENODE *o_pfl = postfixList;

	postfixList = nullptr;
	pep1 = nullptr;
	Enter("NonCommaExpression");
    *node = (ENODE *)NULL;
    tp = ParseAssignOps(node);
    if( tp == (TYP *)NULL )
        *node =(ENODE *)NULL;
    Leave("NonCommaExpression",tp ? tp->type : 0);
		if (postfixList)
			(*node)->pfl = postfixList;
		postfixList = o_pfl;
		if (*node)
     	(*node)->SetType(tp);
    return tp;
}

/*
 *      evaluate the comma operator. comma operators are kept as
 *      void nodes.
 */
TYP *Expression::ParseCommaOp(ENODE **node)
{
	TYP *tp1,*tp2;
	ENODE *ep1,*ep2;

  *node = (ENODE *)NULL;
	tp1 = ParseNonCommaExpression(&ep1);
	if (tp1==(TYP *)NULL)
		return (TYP *)NULL;
	while(1) {
		if (lastst==comma) {
			NextToken();
			tp2 = ParseNonCommaExpression(&ep2);
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

TYP *Expression::ParseExpression(ENODE **node)
{
	TYP *tp;
	Enter("<expression>");
	pep1 = nullptr;
  *node = (ENODE *)NULL;
  tp = ParseCommaOp(node);
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

TYP *expression(ENODE **node)
{
	return (Expression::ParseExpression(node));
}
