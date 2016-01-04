// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2015  Robert Finch, Stratford
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
#include        <stdio.h>
#include <string.h>
#include        "c.h"
#include        "expr.h"
#include "Statement.h"
#include        "gen.h"
#include        "cglbdec.h"

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

TYP             *head = (TYP *)NULL;
TYP             *tail = (TYP *)NULL;
char            *declid = (char *)NULL;
TABLE           tagtable = {(SYM *)0,(SYM *)0};
TYP             stdconst = { bt_long, bt_long, 1, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, 0, 0, 8, {0, 0}, 0, "stdconst"};
char *names[20];
int nparms = 0;
int funcdecl = 0;		//0,1, or 2
int nfc = 0;
int isFirstCall = 0;
int catchdecl = FALSE;
int isTypedef = FALSE;
int isUnion = FALSE;
int isUnsigned = FALSE;
int isSigned = FALSE;
int isVolatile = FALSE;
int isIO = FALSE;
int isConst = FALSE;
int missingArgumentName = FALSE;
int disableSubs;
int parsingParameterList = FALSE;
int unnamedCnt = 0;
int needParseFunction = FALSE;
int isStructDecl = FALSE;
int worstAlignment = 0;
char *stkname = 0;

/* variable for bit fields */
static int		bit_max;	// largest bitnumber
int bit_offset;	/* the actual offset */
int      bit_width;	/* the actual width */
int bit_next;	/* offset for next variable */

int declbegin(int st);
void dodecl(int defclass);
void ParseDeclarationSuffix();
void declstruct(int ztype);
void structbody(TYP *tp, int ztype);
void ParseEnumDeclaration(TABLE *table);
void enumbody(TABLE *table);

int     imax(int i, int j)
{       return (i > j) ? i : j;
}


char *litlate(char *s)
{
	char    *p;
    p = xalloc(strlen(s) + 1);
    strcpy(p,s);
    return p;
}

TYP *maketype(int bt, int siz)
{
	TYP *tp;
    tp = allocTYP();
    tp->val_flag = 0;
    tp->isArray = FALSE;
    tp->size = siz;
    tp->type = bt;
	tp->typeno = bt;
    tp->sname = 0;
    tp->lst.head = 0;
	tp->isUnsigned = FALSE;
	tp->isVolatile = FALSE;
	tp->isIO = FALSE;
	tp->isConst = FALSE;
    return tp;
}

// Parse a specifier. This is the first part of a declaration.
// Returns:
// 0 usually, 1 if only a specifier is present
//
int ParseSpecifier(TABLE *table)
{
	SYM *sp;

	isUnsigned = FALSE;
	isSigned = FALSE;
	isVolatile = FALSE;
	isIO = FALSE;
	isConst = FALSE;
	for (;;) {
		switch (lastst) {
			case kw_const:	// Ignore 'const'
				isConst = TRUE;
				NextToken();
				break;

			case kw_typedef:
				isTypedef = TRUE;
				NextToken();
				break;

			case kw_nocall:
			case kw_naked:
				isNocall = TRUE;
				head = tail = maketype(bt_oscall,8);
				NextToken();
				break;

			case kw_oscall:
				isOscall = TRUE;
				head = tail = maketype(bt_oscall,8);
				NextToken();
				goto lxit;

			case kw_interrupt:
				isInterrupt = TRUE;
				head = tail = maketype(bt_interrupt,8);
				NextToken();
				if (lastst==openpa) {
                    NextToken();
                    if (lastst!=id) 
                       error(ERR_IDEXPECT);
                    needpunc(closepa);
                    stkname = litlate(lastid);
                }
				goto lxit;

			case kw_kernel:
				isKernel = TRUE;
				head = tail = maketype(bt_kernel,8);
				NextToken();
				goto lxit;

			case kw_pascal:
				isPascal = TRUE;
				head = tail = maketype(bt_pascal,8);
				NextToken();
				break;

			// byte and char default to unsigned unless overridden using
			// the 'signed' keyword
			//
			case kw_byte:
				if (isUnsigned)
					head = tail = maketype(bt_ubyte,1);
				else
					head = tail = maketype(bt_byte,1);
				NextToken();
				head->isUnsigned = !isSigned;
				head->isVolatile = isVolatile;
				head->isIO = isIO;
				head->isConst = isConst;
				bit_max = 8;
				goto lxit;
			
			case kw_char:
				if (isUnsigned)
					head = tail = maketype(bt_uchar,2);
				else
					head = tail = maketype(bt_char,2);
				NextToken();
				head->isUnsigned = !isSigned;
				head->isVolatile = isVolatile;
				head->isIO = isIO;
				head->isConst = isConst;
				bit_max = 16;
				goto lxit;

			case kw_int16:
				if (isUnsigned)
					head = tail = maketype(bt_uchar,2);
				else
					head = tail = maketype(bt_char,2);
				NextToken();
				head->isUnsigned = isUnsigned;
				head->isVolatile = isVolatile;
				head->isIO = isIO;
				head->isConst = isConst;
				bit_max = 16;
				goto lxit;

			case kw_int32:
			case kw_short:
				if (isUnsigned)
					head = tail = maketype(bt_ushort,4);
				else
					head = tail = maketype(bt_short,4);
				bit_max = 32;
				NextToken();
				if( lastst == kw_int )
					NextToken();
				head->isUnsigned = isUnsigned;
				head->isVolatile = isVolatile;
				head->isIO = isIO;
				head->isConst = isConst;
				head->isShort = TRUE;
				goto lxit;
				break;

			case kw_long:	// long, long int
				NextToken();
				if (lastst==kw_int) {
					NextToken();
				}
				else if (lastst==kw_float) {
					head = tail = maketype(bt_double,8);
					NextToken();
				}
				else {
					if (isUnsigned)
						head = tail = maketype(bt_ulong,8);
					else
						head = tail = maketype(bt_long,8);
				}
				//NextToken();
				if (lastst==kw_task) {
				    isTask = TRUE;
				    NextToken();
                }
				if (lastst==kw_oscall) {
					isOscall = TRUE;
					NextToken();
				}
				else if (lastst==kw_nocall || lastst==kw_naked) {
					isNocall = TRUE;
					NextToken();
				}
				head->isUnsigned = isUnsigned;
				head->isVolatile = isVolatile;
				head->isIO = isIO;
				head->isConst = isConst;
				bit_max = 64;
				goto lxit;
				break;

			case kw_int64:
			case kw_int:
				if (isUnsigned)
					head = tail = maketype(bt_ulong,8);
				else
					head = tail = maketype(bt_long,8);
				head->isUnsigned = isUnsigned;
				head->isVolatile = isVolatile;
				head->isIO = isIO;
				head->isConst = isConst;
				NextToken();
				if (lastst==kw_task) {
				    isTask = TRUE;
				    NextToken();
                }
				if (lastst==kw_oscall) {
					isOscall = TRUE;
					NextToken();
				}
				else if (lastst==kw_nocall || lastst==kw_naked) {
					isNocall = TRUE;
					NextToken();
				}
				bit_max = 64;
				goto lxit;
				break;

            case kw_task:
                isTask = TRUE;
                NextToken();
				break;

			case kw_int8:
				if (isUnsigned)
					head = tail = maketype(bt_ubyte,1);
				else
					head = tail = maketype(bt_byte,1);
				head->isUnsigned = isUnsigned;
				head->isVolatile = isVolatile;
				head->isIO = isIO;
				head->isConst = isConst;
				NextToken();
				if (lastst==kw_oscall) {
					isOscall = TRUE;
					NextToken();
				}
				if (lastst==kw_nocall || lastst==kw_naked) {
					isNocall = TRUE;
					NextToken();
				}
				bit_max = 8;
				goto lxit;
				break;

			case kw_signed:
				isSigned = TRUE;
				NextToken();
				break;

			case kw_unsigned:
				NextToken();
				isUnsigned = TRUE;
				break;

			case kw_volatile:
				NextToken();
				if (lastst==kw_inout) {
                    NextToken();
                    isIO = TRUE;
                }
				isVolatile = TRUE;
				break;

			case ellipsis:
			case id:                /* no type ParseSpecifierarator */
				sp = search(lastid,&gsyms[0]);
				if (sp) {
					if (sp->storage_class==sc_typedef) {
						NextToken();
						head = tail = sp->tp;
					}
					else
						head = tail = sp->tp;
//					head = tail = maketype(bt_long,4);
				}
				else {
					head = tail = maketype(bt_long,8);
					bit_max = 64;
				}
				goto lxit;
				break;

			case kw_float:
				head = tail = maketype(bt_float,4);
				head->isVolatile = isVolatile;
				head->isIO = isIO;
				head->isConst = isConst;
				NextToken();
				bit_max = 32;
				goto lxit;

			case kw_double:
				head = tail = maketype(bt_double,8);
				head->isVolatile = isVolatile;
				head->isIO = isIO;
				head->isConst = isConst;
				NextToken();
				bit_max = 64;
				goto lxit;

			case kw_triple:
				head = tail = maketype(bt_triple,12);
				head->isVolatile = isVolatile;
				head->isIO = isIO;
				head->isConst = isConst;
				NextToken();
				bit_max = 96;
				goto lxit;

			case kw_void:
				head = tail = maketype(bt_void,0);
				head->isVolatile = isVolatile;
				head->isIO = isIO;
				head->isConst = isConst;
				NextToken();
				if (lastst==kw_interrupt) {
					isInterrupt = TRUE;
					NextToken();
				}
				if (lastst==kw_nocall || lastst==kw_naked) {
					isNocall = TRUE;
					NextToken();
				}
				bit_max = 0;
				goto lxit;

			case kw_enum:
				NextToken();
				ParseEnumDeclaration(table);
				bit_max = 16;
				goto lxit;

			case kw_struct:
				NextToken();
				if (ParseStructDeclaration(bt_struct))
					return 1;
				goto lxit;

			case kw_union:
				NextToken();
				if (ParseStructDeclaration(bt_union))
					return 1;
				goto lxit;

            case kw_exception:
				head = tail = maketype(bt_exception,8);
				head->isVolatile = isVolatile;
				head->isIO = isIO;
				head->isConst = isConst;
				NextToken();
				bit_max = 64;
				goto lxit;
				
            case kw_inline:
                NextToken();
                break;

			default:
				goto lxit;
			}
	}
lxit:;
	return 0;
}

int ParseDeclarationPrefix(char isUnion)
{   
	TYP *temp1, *temp2, *temp3, *temp4;
	SYM *sp;
	int nn;
	char buf[200];
j2:
	switch (lastst) {
		case kw_const:
			isConst = TRUE;
			NextToken();
			goto j2;

		case ellipsis:
        case id:
j1:
                declid = litlate(lastid);
				if (funcdecl==1)
					names[nparms++] = declid;
                NextToken();
				if (lastst == colon) {
					NextToken();
					bit_width = GetIntegerExpression((ENODE **)NULL);
					if (isUnion)
						bit_offset = 0;
					else
						bit_offset = bit_next;
					if (bit_width < 0 || bit_width > bit_max) {
						error(ERR_BITFIELD_WIDTH);
						bit_width = 1;
					}
					if (bit_width == 0 || bit_offset + bit_width > bit_max)
						bit_offset = 0;
					bit_next = bit_offset + bit_width;
					break;	// no ParseDeclarationSuffix()
				}
				//if (lastst==closepa) {
				//	return 1;
				//}
	//			if (lastst==closepa) {
	//				sp = search(lastid,&gsyms[0]);
	//				if (strcmp(lastid,"getchar")==0)
	//					printf("found");
	//				if (sp) {
	//					if (sp->storage_class==sc_typedef)
	//						head = tail = sp->tp;
	//					else
	//						head = tail = sp->tp;
	////					head = tail = maketype(bt_long,4);
	//				}
	//				else {
	//					head = tail = maketype(bt_long,8);
	//					bit_max = 64;
	//				}
	//				break;
	//			}
				ParseDeclarationSuffix();
                break;
        case star:
                temp1 = maketype(bt_pointer,8);
                temp1->btp = head;
                head = temp1;
                if(tail == NULL)
                        tail = head;
                NextToken();
				//if (lastst==closepa) {	// (*)
				//	sprintf(buf,"_unnamed%d", unnamedCnt);
				//	unnamedCnt++;
				//	declid = litlate(buf);
				//	NextToken();
				//	ParseDeclarationSuffix();
				//	return 2;
				//}
				// Loop back to process additional prefix info.
				goto j2;
                //return ParseDeclarationPrefix(isUnion);
                break;
        case openpa:
                NextToken();
                temp1 = head;
                temp2 = tail;
                head = tail = (TYP *)NULL;	// It might be a typecast following.
				// Do we have (getchar)()
				nn = ParseDeclarationPrefix(isUnion); 
				/*if (nn==1) {
					head = temp1;
					tail = temp2;
					goto j1;
				}*/
				//else if (nn == 2) {
				//	head = temp1;
				//	tail = temp2;
				//	NextToken();
				//	ParseDeclarationSuffix();
				//	break;
				//}
                needpunc(closepa);
                temp3 = head;
                temp4 = tail;
                head = temp1;
                tail = temp2;
                ParseDeclarationSuffix();
				// (getchar)() returns temp4 = NULL
				if (temp4!=NULL) {
					temp4->btp = head;
					if(temp4->type == bt_pointer && temp4->val_flag != 0 && head != NULL)
						temp4->size *= head->size;
	                head = temp3;
				}
				//if (head==NULL)
				//	head = tail = maketype(bt_long,8);
                break;
        default:
                ParseDeclarationSuffix();
                break;
        }
	return 0;
}

// Take care of the () or [] trailing part of a declaration
//
void ParseDeclarationSuffix()
{
	TYP     *temp1;
	int fd, npf;
	char *odecl;
	TYP *tempHead, *tempTail;
	long sz2;

    switch (lastst) {
    case openbr:

        NextToken();
        temp1 = maketype(bt_pointer,0);
        temp1->val_flag = 1;
        temp1->isArray = TRUE;
        temp1->btp = head;
        if(lastst == closebr) {
			temp1->size = 0;
			NextToken();
        }
        else if(head != NULL) {
            sz2 = GetIntegerExpression((ENODE **)NULL);
			temp1->size = sz2 * head->size;
			temp1->alignment = head->alignment;
			needpunc(closebr);
		}
        else {
            sz2 = GetIntegerExpression((ENODE **)NULL);
			temp1->size = sz2;
			needpunc(closebr);
		}
        head = temp1;
        if( tail == NULL)
                tail = head;
        ParseDeclarationSuffix();
        break;

    case openpa:
        NextToken();
        temp1 = maketype(bt_func,0);
        temp1->val_flag = 1;
        temp1->btp = head;
        head = temp1;
		needParseFunction = TRUE;
		if (tail==NULL) {
			if (temp1->btp)
				tail = temp1->btp;
			else
				tail = temp1;
		}
        if( lastst == closepa) {
            NextToken();
//            temp1->type = bt_ifunc;			// this line wasn't present
			if(lastst == begin) {
                temp1->type = bt_ifunc;
			}
			else
				needParseFunction = FALSE;
        }
		else {
            temp1->type = bt_ifunc;
			// Parse the parameter list for a function pointer passed as a
			// parameter.
			// Parse parameter list for a function pointer defined within
			// a structure.
			if (parsingParameterList || isStructDecl) {
				fd = funcdecl;
				needParseFunction = FALSE;
				odecl = declid;
				tempHead = head;
				tempTail = tail;
				ParseParameterDeclarations(10);	// parse and discard
				head = tempHead;
				tail = tempTail;
				declid = odecl;
				funcdecl = fd;
				needpunc(closepa);
				if (lastst != begin)
					temp1->type = bt_func;
			}
		}
        break;
    }
}

int alignment(TYP *tp)
{
	//printf("DIAG: type NULL in alignment()\r\n");
	if (tp==NULL)
		return AL_BYTE;
	switch(tp->type) {
	case bt_byte:	case bt_ubyte:	return AL_BYTE;
	case bt_char:   case bt_uchar:  return AL_CHAR;
	case bt_short:  case bt_ushort: return AL_SHORT;
	case bt_long:   case bt_ulong:  return AL_LONG;
    case bt_enum:           return AL_CHAR;
    case bt_pointer:
            if(tp->val_flag)
                return alignment(tp->btp);
            else
				return AL_POINTER;
    case bt_float:          return AL_FLOAT;
    case bt_double:         return AL_DOUBLE;
    case bt_triple:         return AL_TRIPLE;
    case bt_struct:
    case bt_union:          
         return (tp->alignment) ?  tp->alignment : AL_STRUCT;
    default:                return AL_CHAR;
    }
}

int walignment(TYP *tp)
{
	int ii;
	SYM *sp;

	//printf("DIAG: type NULL in alignment()\r\n");
	if (tp==NULL)
		return imax(AL_BYTE,worstAlignment);
	switch(tp->type) {
	case bt_byte:	case bt_ubyte:		return imax(AL_BYTE,worstAlignment);
	case bt_char:   case bt_uchar:     return imax(AL_CHAR,worstAlignment);
	case bt_short:  case bt_ushort:    return imax(AL_SHORT,worstAlignment);
	case bt_long:   case bt_ulong:     return imax(AL_LONG,worstAlignment);
    case bt_enum:           return imax(AL_CHAR,worstAlignment);
    case bt_pointer:
            if(tp->val_flag)
                return imax(alignment(tp->btp),worstAlignment);
            else
				return imax(AL_POINTER,worstAlignment);
    case bt_float:          return imax(AL_FLOAT,worstAlignment);
    case bt_double:         return imax(AL_DOUBLE,worstAlignment);
    case bt_triple:         return imax(AL_TRIPLE,worstAlignment);
    case bt_struct:
    case bt_union:          
		sp = tp->lst.head;
        worstAlignment = tp->alignment;
		while(sp != NULL) {
            if (sp->tp && sp->tp->alignment) {
                worstAlignment = imax(worstAlignment,sp->tp->alignment);
            }
            else
     			worstAlignment = imax(worstAlignment,walignment(sp->tp));
			sp = sp->next;
        }
		return worstAlignment;
    default:                return imax(AL_CHAR,worstAlignment);
    }
}

int roundAlignment(TYP *tp)
{
	worstAlignment = 0;
	if (tp->type == bt_struct || tp->type == bt_union) {
		return walignment(tp);
	}
	return alignment(tp);
}

int roundSize(TYP *tp)
{
	int sz;
	int wa;

	worstAlignment = 0;
	if (tp->type == bt_struct || tp->type == bt_union) {
		wa = walignment(tp);
		sz = tp->size;
		while(sz % wa)
			sz++;
		return sz;
	}
	return tp->size;
}

/*
 *      process declarations of the form:
 *
 *              <type>  <specifier>, <specifier>...;
 *
 *      leaves the declarations in the symbol table pointed to by
 *      table and returns the number of bytes declared. al is the
 *      allocation type to assign, ilc is the initial location
 *      counter. if al is sc_member then no initialization will
 *      be processed. ztype should be bt_struct for normal and in
 *      structure ParseSpecifierarations and sc_union for in union ParseSpecifierarations.
 */
int declare(TABLE *table,int al,int ilc,int ztype)
{ 
	SYM *sp, *sp1, *sp2;
    TYP *dhead, *tp1, *tp2;
	ENODE *ep1, *ep2;
	char stnm[200];
	int op;
	int fd;
	int fn_doneinit = 0;
	int bcnt;

    static long old_nbytes;
    int nbytes;

	nbytes = 0;
    if (ParseSpecifier(table))
		return nbytes;
    dhead = head;
    for(;;) {
        declid = (char *)NULL;
		bit_width = -1;
        ParseDeclarationPrefix(ztype==bt_union);
		// If a function declaration is taking place and just the type is
		// specified without a parameter name, assign an internal compiler
		// generated name.
		if (funcdecl>0 && funcdecl != 10 && declid==(char *)NULL) {
			sprintf(lastid, "_p%d", nparms);
			declid = litlate(lastid);
			names[nparms++] = declid;
			missingArgumentName = TRUE;
		}
        if( declid != NULL) {      /* otherwise just struct tag... */
            sp = allocSYM();
			sp->name = declid;
            sp->storage_class = al;
            sp->isConst = isConst;
			if (bit_width > 0 && bit_offset > 0) {
				// share the storage word with the previously defined field
				nbytes = old_nbytes - ilc;
			}
			old_nbytes = ilc + nbytes;
			if (al != sc_member) {
//							sp->isTypedef = isTypedef;
				if (isTypedef)
					sp->storage_class = sc_typedef;
				isTypedef = FALSE;
			}
			if ((ilc + nbytes) % roundAlignment(head)) {
				if (al==sc_thread)
					tseg();
				else
					dseg();
            }
            bcnt = 0;
            while( (ilc + nbytes) % roundAlignment(head)) {
                ++nbytes;
                bcnt++;
            }
            if( al != sc_member && al != sc_external && al != sc_auto) {
                if (bcnt > 0)
                    genstorage(bcnt);
            }

			// Set the struct member storage offset.
			if( al == sc_static || al==sc_thread) {
				sp->value.i = nextlabel++;
			}
			else if( ztype == bt_union)
                sp->value.i = ilc;
            else if( al != sc_auto )
                sp->value.i = ilc + nbytes;
			// Auto variables are referenced negative to the base pointer
			// Structs need to be aligned on the boundary of the largest
			// struct element. If a struct is all chars this will be 2.
			// If a struct contains a pointer this will be 8. It has to
			// be the worst case alignment.
			else {
                sp->value.i = -(ilc + nbytes + roundSize(head));
			}

			if (bit_width == -1)
				sp->tp = head;
			else {
				sp->tp = allocTYP();
				*(sp->tp) = *head;
				sp->tp->type = bt_bitfield;
				sp->tp->size = head->size;//tp_int.size;
				sp->tp->bit_width = bit_width;
				sp->tp->bit_offset = bit_offset;
			}
			if (isConst)
				sp->tp->isConst = TRUE;
            if((sp->tp->type == bt_func) && sp->storage_class == sc_global )
                sp->storage_class = sc_external;

			// Increase the storage allocation by the type size.
            if(ztype == bt_union)
                nbytes = imax(nbytes,roundSize(sp->tp));
			else if(al != sc_external) {
				// If a pointer to a function is defined in a struct.
				if (isStructDecl && (sp->tp->type==bt_func || sp->tp->type==bt_ifunc))
					nbytes += 8;
				else
					nbytes += roundSize(sp->tp);
			}
            
			if (sp->tp->type == bt_ifunc && (sp1 = search(sp->name,table)) != 0 && sp1->tp->type == bt_func )
            {
				sp1->tp = sp->tp;
				sp1->storage_class = sp->storage_class;
	            sp1->value.i = sp->value.i;
				sp1->IsPrototype = sp->IsPrototype;
				sp = sp1;
            }
			else {
				sp2 = search(sp->name,table);
				if (sp2 == NULL)
					insert(sp,table);
				else {
					if (funcdecl==2)
						sp2->tp = sp->tp;
					//else if (!sp2->IsPrototype)
					//	insert(sp,table);
				}
			}
			if (needParseFunction) {
				needParseFunction = FALSE;
				fn_doneinit = ParseFunction(sp);
				if (sp->tp->type != bt_pointer)
					return nbytes;
			}
   //         if(sp->tp->type == bt_ifunc) { /* function body follows */
   //             ParseFunction(sp);
   //             return nbytes;
   //         }
            if( (al == sc_global || al == sc_static || al==sc_thread) && !fn_doneinit &&
                    sp->tp->type != bt_func && sp->tp->type != bt_ifunc && sp->storage_class!=sc_typedef)
                    doinit(sp);
        }
		if (funcdecl>0) {
			if (lastst==comma || lastst==semicolon)
				break;
			if (lastst==closepa)
				goto xit1;
		}
		else if (catchdecl==TRUE) {
			if (lastst==closepa)
				goto xit1;
		}
		else if (lastst == semicolon)
			break;
		else if (lastst == assign) {
			tp1 = nameref(&ep1);
            op = en_assign;
//            NextToken();
            tp2 = asnop(&ep2);
            if( tp2 == 0 || !IsLValue(ep1) )
                  error(ERR_LVALUE);
            else    {
                    tp1 = forcefit(&ep1,tp1,&ep2,tp2);
                    ep1 = makenode(op,ep1,ep2);
                    }
			sp->initexp = ep1;
			if (lastst==semicolon)
				break;
		}

        needpunc(comma);
        if(declbegin(lastst) == 0)
                break;
        head = dhead;
    }
    NextToken();
xit1:
    return nbytes;
}

int declbegin(int st)
{
	return st == star || st == id || st == openpa || st == openbr; 
}

void ParseGlobalDeclarations()
{
    for(;;) {
		worstAlignment = 0;
		funcdecl = 0;
		switch(lastst) {
		case ellipsis:
		case id:
        case kw_kernel:
		case kw_interrupt:
        case kw_task:
		case kw_cdecl:
		case kw_pascal:
		case kw_naked:
		case kw_nocall:
		case kw_oscall:
		case kw_typedef:
		case kw_volatile: case kw_const:
        case kw_exception:
		case kw_int8: case kw_int16: case kw_int32: case kw_int64:
		case kw_byte: case kw_char: case kw_int: case kw_short: case kw_unsigned: case kw_signed:
        case kw_long: case kw_struct: case kw_union:
        case kw_enum: case kw_void:
        case kw_float: case kw_double:
                lc_static += declare(&gsyms[0],sc_global,lc_static,bt_struct);
				break;
        case kw_thread:
				NextToken();
                lc_thread += declare(&gsyms[0],sc_thread,lc_thread,bt_struct);
				break;
		case kw_register:
				NextToken();
                error(ERR_ILLCLASS);
                lc_static += declare(&gsyms[0],sc_global,lc_static,bt_struct);
				break;
		case kw_private:
        case kw_static:
                NextToken();
				lc_static += declare(&gsyms[0],sc_static,lc_static,bt_struct);
                break;
        case kw_extern:
                NextToken();
				if (lastst==kw_pascal) {
					isPascal = TRUE;
					NextToken();
				}
				if (lastst==kw_kernel) {
					isKernel = TRUE;
					NextToken();
				}
				else if (lastst==kw_oscall || lastst==kw_interrupt || lastst==kw_nocall || lastst==kw_naked)
					NextToken();
                ++global_flag;
                declare(&gsyms[0],sc_external,0,bt_struct);
                --global_flag;
                break;
        case kw_inline:
                NextToken();
                break;
        default:
                return;
		}
	}
}

void ParseParameterDeclarations(int fd)
{
	int ofd;

	worstAlignment = 0;
	ofd = funcdecl;
	funcdecl = fd;
	missingArgumentName = FALSE;
	parsingParameterList++;
    for(;;) {
		switch(lastst) {
		case kw_cdecl:
        case kw_kernel:
		case kw_interrupt:
		case kw_naked:
		case kw_nocall:
		case kw_oscall:
		case kw_pascal:
		case kw_typedef:
                error(ERR_ILLCLASS);
                declare(&lsyms,sc_auto,0,bt_struct);
				break;
		case ellipsis:
		case id:
		case kw_volatile: case kw_const:
        case kw_exception:
		case kw_int8: case kw_int16: case kw_int32: case kw_int64:
		case kw_byte: case kw_char: case kw_int: case kw_short: case kw_unsigned: case kw_signed:
        case kw_long: case kw_struct: case kw_union:
        case kw_enum: case kw_void:
        case kw_float: case kw_double:
                declare(&lsyms,sc_auto,0,bt_struct);
	            break;
        case kw_thread:
                NextToken();
                error(ERR_ILLCLASS);
				lc_thread += declare(&gsyms[0],sc_thread,lc_thread,bt_struct);
				break;
        case kw_static:
                NextToken();
                error(ERR_ILLCLASS);
				lc_static += declare(&gsyms[0],sc_static,lc_static,bt_struct);
				break;
        case kw_extern:
                NextToken();
                error(ERR_ILLCLASS);
				if (lastst==kw_oscall || lastst==kw_interrupt || lastst == kw_nocall || lastst==kw_naked || lastst==kw_kernel)
					NextToken();
                ++global_flag;
                declare(&gsyms[0],sc_external,0,bt_struct);
                --global_flag;
                break;
		case kw_register:
				NextToken();
				break;
        default:
				parsingParameterList--;
                return;
		}
	}
	parsingParameterList--;
	funcdecl = ofd;
}


void ParseAutoDeclarations(TABLE *ssyms)
{
	SYM *sp;

	funcdecl = 0;
    for(;;) {
		worstAlignment = 0;
		switch(lastst) {
		case kw_cdecl:
        case kw_kernel:
		case kw_interrupt:
		case kw_naked:
		case kw_nocall:
		case kw_oscall:
		case kw_pascal:
		case kw_typedef:
                error(ERR_ILLCLASS);
	            lc_auto += declare(ssyms,sc_auto,lc_auto,bt_struct);
				break;
		case ellipsis:
		case id: //return;
				sp = search(lastid,&gsyms[0]);
				if (sp) {
					if (sp->storage_class==sc_typedef) {
			            lc_auto += declare(ssyms,sc_auto,lc_auto,bt_struct);
						break;
					}
				}
				return;
        case kw_register:
                NextToken();
        case kw_exception:
		case kw_volatile: case kw_const:
		case kw_int8: case kw_int16: case kw_int32: case kw_int64:
		case kw_byte: case kw_char: case kw_int: case kw_short: case kw_unsigned: case kw_signed:
        case kw_long: case kw_struct: case kw_union:
        case kw_enum: case kw_void:
        case kw_float: case kw_double:
            lc_auto += declare(ssyms,sc_auto,lc_auto,bt_struct);
            break;
        case kw_thread:
                NextToken();
				lc_thread += declare(ssyms,sc_thread,lc_thread,bt_struct);
				break;
        case kw_static:
                NextToken();
				lc_static += declare(ssyms,sc_static,lc_static,bt_struct);
				break;
        case kw_extern:
                NextToken();
				if (lastst==kw_oscall || lastst==kw_interrupt || lastst == kw_nocall || lastst==kw_naked || lastst==kw_kernel)
					NextToken();
                ++global_flag;
                declare(&gsyms[0],sc_external,0,bt_struct);
                --global_flag;
                break;
        default:
                return;
		}
	}
}

/*
 *      main compiler routine. this routine parses all of the
 *      declarations using declare which will call funcbody as
 *      functions are encountered.
 */
void compile()
{
	while(lastst != my_eof)
	{
		ParseGlobalDeclarations();
		if( lastst != my_eof)
			NextToken();
	}
	dumplits();
}

