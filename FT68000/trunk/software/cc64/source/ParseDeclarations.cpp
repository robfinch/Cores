// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2017  Robert Finch, Waterloo
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

TYP *head = (TYP *)NULL;
TYP *tail = (TYP *)NULL;
std::string *declid;
//char *Declaration::declid = (char *)NULL;
TABLE tagtable;
TYP stdconst;
TYP stdvector;
TYP *stdvectormask;
Stringx names[20];
int nparms = 0;
int funcdecl = 0;		//0,1, or 2
int nfc = 0;
int isFirstCall = 0;
int catchdecl = FALSE;
int isTypedef = FALSE;
bool isUnion = false;
int isUnsigned = FALSE;
int isSigned = FALSE;
int isVolatile = FALSE;
int isVirtual = FALSE;
bool isInline = false;
int isIO = FALSE;
int isConst = FALSE;
bool isRegister = false;
bool isAuto = false;
bool isFuncBody;
bool isFuncPtr;
int missingArgumentName = FALSE;
int disableSubs;
int parsingParameterList = FALSE;
int unnamedCnt = 0;
int needParseFunction = 0;
int isStructDecl = FALSE;
int worstAlignment = 0;
char *stkname = 0;
std::string *classname;
bool isPrivate = true;
SYM *currentClass;
int mangledNames = FALSE;

/* variable for bit fields */
static int		bit_max;	// largest bitnumber
int bit_offset;	/* the actual offset */
int      bit_width;	/* the actual width */
int bit_next;	/* offset for next variable */

int declbegin(int st);
void dodecl(int defclass);
SYM *ParseDeclarationSuffix(SYM *);
void declstruct(int ztype);
void structbody(TYP *tp, int ztype);
void ParseEnumDeclaration(TABLE *table);
void enumbody(TABLE *table);
extern int ParseClassDeclaration(int ztype);
extern ENODE *ArgumentList(ENODE *hidden,int*,int);
TYP *nameref2(std::string name, ENODE **node,int nt,bool alloc,TypeArray*, TABLE* tbl);
SYM *search2(std::string na,TABLE *tbl,int *typearray);
SYM *gsearch2(std::string na, __int16, int *typearray, bool exact);
extern ENODE *makesnode(int,std::string *,std::string *,__int64);

extern TYP *CopyType(TYP *src);

int     imax(int i, int j)
{       return (i > j) ? i : j;
}


char *my_strdup(char *s)
{
	char *p;
	int n = strlen(s);
	int m = sizeof(char);
	p = (char *)allocx(sizeof(char)*(n+1));
	memcpy(p,s,sizeof(char)*(n));
	p[n] = '\0';
	return p;
}

void Declaration::SetType(SYM *sp)
{
	if (head) {
		if (bit_width <= 0) {
			sp->tp = head;
		}
		else {
			if (head->IsFloatType()) {
				sp->tp = head;
				sp->tp->precision = bit_width;
			}
			else if (head->IsVectorType()) {
				sp->tp = head;
				sp->tp->numele = bit_width;
			}
			else {
				sp->tp = TYP::Make(bt_bitfield,head->size);
				//  		*(sp->tp) = *head;
				sp->tp->bit_width = bit_width;
				sp->tp->bit_offset = bit_offset;
			}
		}
	}
	else {
		sp->tp = TYP::Make(bt_long,sizeOfWord);
		sp->tp->lst.head = sp->GetIndex();
	}
}

// Ignore const
void Declaration::ParseConst()
{
	isConst = TRUE;
	NextToken();
}

void Declaration::ParseTypedef()
{
	isTypedef = TRUE;
	NextToken();
}

void Declaration::ParseNaked()
{
	isNocall = TRUE;
	head = (TYP *)TYP::Make(bt_oscall,2);
	tail = head;
	NextToken();
}

void Declaration::ParseVoid()
{
	head = (TYP *)TYP::Make(bt_void,0);
	tail = head;
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
}

void Declaration::ParseLong()
{
	NextToken();
	if (lastst==kw_int) {
		bit_max = 32;
		NextToken();
	}
	else if (lastst==kw_float) {
		head = (TYP *)TYP::Make(bt_double,8);
		tail = head;
		bit_max = head->precision;
		NextToken();
	}
	else if (lastst==kw_double) {
		head = TYP::Copy(&stddouble);
		//head = (TYP *)TYP::Make(bt_quad,8);
		tail = head;
		bit_max = head->precision;
		NextToken();
	}
	else {
		if (isUnsigned) {
			head =(TYP *)TYP::Make(bt_ulong,8);
			tail = head;
			bit_max = head->precision;
		}
		else {
			head = (TYP *)TYP::Make(bt_long,8);
			tail = head;
			bit_max = head->precision;
		}
	}
	//NextToken();
	if (lastst==kw_task) {
		isTask = TRUE;
		NextToken();
		bit_max = 32;
	}
	if (lastst==kw_oscall) {
		isOscall = TRUE;
		NextToken();
		bit_max = 32;
	}
	else if (lastst==kw_nocall || lastst==kw_naked) {
		isNocall = TRUE;
		NextToken();
		bit_max = 32;
	}
	head->isUnsigned = isUnsigned;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
	head->isConst = isConst;
}

void Declaration::ParseInt()
{
//printf("Enter ParseInt\r\n");
	if (isUnsigned) {
		head = TYP::Make(bt_ulong,4);
		tail = head;
	}
	else {
		head = TYP::Make(bt_long,4);
		tail = head;
	}
	bit_max = 32;
	if (head==nullptr)
		return;
	head->isUnsigned = isUnsigned;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
	head->isConst = isConst;
	NextToken();
	if (lastst==kw_vector) {
		int btp = head->GetIndex();
		head = TYP::Make(bt_vector,512);
		head->numele = maxVL;
		head->btp = btp;
		tail = head;
		NextToken();
	}
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
//printf("Leave ParseInt\r\n");
}

void Declaration::ParseFloat()
{
	head = TYP::Copy(&stddouble);
	tail = head;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
	head->isConst = isConst;
	NextToken();
	if (lastst==kw_vector) {
		int btp = head->GetIndex();
		head = TYP::Make(bt_vector,512);
		head->numele = maxVL;
		head->btp = btp;
		tail = head;
		NextToken();
	}
	bit_max = head->precision;
}

void Declaration::ParseDouble()
{
	head = (TYP *)TYP::Make(bt_double,8);
	tail = head;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
	head->isConst = isConst;
	NextToken();
	if (lastst==kw_vector) {
		int btp = head->GetIndex();
		head = TYP::Make(bt_vector,512);
		head->numele = maxVL;
		head->btp = btp;
		tail = head;
		NextToken();
	}
	bit_max = head->precision;
}

void Declaration::ParseVector()
{
	int btp;

	head = (TYP *)TYP::Make(bt_double,sizeOfFPD);
	tail = head;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
	head->isConst = isConst;
	NextToken();
	btp = head->GetIndex();
	head = TYP::Make(bt_vector,512);
	head->numele = maxVL;
	head->btp = btp;
	tail = head;
	NextToken();
	bit_max = head->precision;
}

void Declaration::ParseVectorMask()
{
	head = (TYP *)TYP::Make(bt_vector_mask,sizeOfWord);
	tail = head;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
	head->isConst = isConst;
	head->numele = maxVL;
	NextToken();
	bit_max = head->precision;
}

void Declaration::ParseInt32()
{
	if (isUnsigned) {
		head = (TYP *)TYP::Make(bt_int32u,4);
		tail = head;
	}
	else {
		head = (TYP *)TYP::Make(bt_int32,4);
		tail = head;
	}
	bit_max = 32;
	NextToken();
	if( lastst == kw_int )
		NextToken();
	head->isUnsigned = isUnsigned;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
	head->isConst = isConst;
	head->isShort = TRUE;
}

void Declaration::ParseInt64()
{
	if (isUnsigned) {
		head = (TYP *)TYP::Make(bt_ulong,8);
		tail = head;
	}
	else {
		head = (TYP *)TYP::Make(bt_long,8);
		tail = head;
	}
	bit_max = 64;
	NextToken();
	if( lastst == kw_int )
		NextToken();
	head->isUnsigned = isUnsigned;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
	head->isConst = isConst;
	head->isShort = TRUE;
}

void Declaration::ParseInt16()
{
	if (isUnsigned) {
		head = (TYP *)TYP::Make(bt_uchar,2);
		tail = head;
	}
	else {
		head =(TYP *)TYP::Make(bt_char,2);
		tail = head;
	}
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
	bit_max = 16;
}

void Declaration::ParseInt8()
{
	if (isUnsigned) {
		head = (TYP *)TYP::Make(bt_ubyte,1);
		tail = head;
	}
	else {
		head =(TYP *)TYP::Make(bt_byte,1);
		tail = head;
	}
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
	bit_max = head->precision;
}

void Declaration::ParseByte()
{
	if (isUnsigned) {
		head = (TYP *)TYP::Make(bt_ubyte,1);
		tail = head;
	}
	else {
		head =(TYP *)TYP::Make(bt_byte,1);
		tail = head;
	}
	NextToken();
	head->isUnsigned = !isSigned;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
	head->isConst = isConst;
	bit_max = head->precision;
}

SYM *Declaration::ParseId()
{
	SYM *sp;

  dfs.printf("<ParseId>%s",lastid);
	sp = tagtable.Find(lastid,false);//gsyms[0].Find(lastid);
	if (sp==nullptr)
		sp = gsyms[0].Find(lastid,false);
	if (sp) {
		dfs.printf("Actually found type.\r\n");
		if (sp->storage_class==sc_typedef || sp->storage_class==sc_type) {
			NextToken();
			head = tail = sp->tp;
		}
		else
			head = tail = sp->tp;
//					head = tail = maketype(bt_long,4);
	}
	else {
		head = (TYP *)TYP::Make(bt_long,4);
		tail = head;
		bit_max = 32;
	}
  dfs.puts("</ParseId>");
	return sp;
}

// Parse a specifier. This is the first part of a declaration.
// Returns:
// 0 usually, 1 if only a specifier is present
//
int Declaration::ParseSpecifier(TABLE *table)
{
	SYM *sp;

	dfs.printf("<ParseSpecifier>\n");
	isUnsigned = FALSE;
	isSigned = FALSE;
	isVolatile = FALSE;
	isVirtual = FALSE;
	isIO = FALSE;
	isConst = FALSE;
	dfs.printf("A");
	for (;;) {
		switch (lastst) {
				
			case kw_const:		ParseConst();	break;
			case kw_typedef:	ParseTypedef(); break;
			case kw_nocall:
			case kw_naked:		ParseNaked();	break;

			case kw_oscall:
				isOscall = TRUE;
				head = tail = (TYP *)TYP::Make(bt_oscall,2);
				NextToken();
				goto lxit;

			case kw_interrupt:
				isInterrupt = TRUE;
				head = (TYP *)TYP::Make(bt_interrupt,2);
				tail = head;
				NextToken();
				if (lastst==openpa) {
                    NextToken();
                    if (lastst!=id) 
                       error(ERR_IDEXPECT);
                    needpunc(closepa,49);
                    stkname = my_strdup(lastid);
                }
				goto lxit;

      case kw_virtual:
        dfs.printf("virtual");
        isVirtual = TRUE;
        NextToken();
        break;

			case kw_kernel:
				isKernel = TRUE;
				head =(TYP *) TYP::Make(bt_kernel,2);
				tail = head;
				NextToken();
				goto lxit;

			case kw_pascal:
				isPascal = TRUE;
				NextToken();
				break;

			case kw_inline:
				isInline = TRUE;
				NextToken();
				break;

			case kw_register:
				isRegister = TRUE;
				NextToken();
				break;

			// byte and char default to unsigned unless overridden using
			// the 'signed' keyword
			//
			case kw_byte:   ParseByte(); goto lxit;
			case kw_char:	ParseInt16(); goto lxit;
			case kw_int8:	ParseInt8(); goto lxit;
			case kw_int16:	ParseInt16(); goto lxit;
			case kw_int32:	ParseInt32(); goto lxit;
			case kw_int64:	ParseInt64(); goto lxit;
			case kw_short:	ParseInt32();	goto lxit;
			case kw_long:	ParseLong();	goto lxit;	// long, long int
			case kw_int:	ParseInt();		goto lxit;

            case kw_task:
                isTask = TRUE;
                NextToken();
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
				head = (TYP *)TYP::Make(bt_ellipsis,4);
				tail = head;
				head->isVolatile = isVolatile;
				head->isIO = isIO;
				head->isConst = isConst;
				NextToken();
				bit_max = 32;
				goto lxit;

			case id:	sp = ParseId();	goto lxit;

			case kw_float:	ParseFloat(); goto lxit;
			case kw_double:	ParseDouble(); goto lxit;

			case kw_triple:
				head = TYP::Copy(&stdtriple);
				tail = head;
				head->isVolatile = isVolatile;
				head->isIO = isIO;
				head->isConst = isConst;
				NextToken();
				bit_max = head->precision;
				goto lxit;

			case kw_vector:	ParseVector(); goto lxit;
			case kw_vector_mask: ParseVectorMask(); goto lxit;

			case kw_void:	ParseVoid(); goto lxit;

			case kw_enum:
				NextToken();
				ParseEnumDeclaration(table);
				bit_max = 16;
				goto lxit;

			case kw_class:
				ClassDeclaration::Parse(bt_class);
				goto lxit;

			case kw_struct:
				NextToken();
				if (StructDeclaration::Parse(bt_struct))
					return 1;
				goto lxit;

			case kw_union:
				NextToken();
				if (StructDeclaration::Parse(bt_union))
					return 1;
				goto lxit;

      case kw_exception:
				head = (TYP *)TYP::Make(bt_exception,4);
				tail = head;
				head->isVolatile = isVolatile;
				head->isIO = isIO;
				head->isConst = isConst;
				NextToken();
				bit_max = 32;
				goto lxit;
				
			default:
				goto lxit;
			}
	}
lxit:;
	dfs.printf("</ParseSpecifier>\n");
	return 0;
}

void Declaration::ParseDoubleColon(SYM *sp)
{
	SYM *sym;
	bool gotDouble = false;

	while (lastst==double_colon) {
		gotDouble = true;
		sym = tagtable.Find(lastid,false);
		if (sym)
			sp->parent = sym->GetIndex();//gsearch(lastid);
		else {
			sp->parent = 0;
			break;
		}
		NextToken();
		if (lastst != id) {
			error(ERR_IDEXPECT);
			break;
		}
	}
	if (gotDouble)
	    NextToken();
	currentClass = sp->GetParentPtr();
	if (sp->parent)
		dfs.printf("Setting parent:%s|\r\n",
	(char *)sp->GetParentPtr()->name->c_str());
}

void Declaration::ParseBitfieldSpec(bool isUnion)
{
	dfs.puts("<ParseBitfieldSpec>");
	NextToken();
	bit_width = (int)GetIntegerExpression((ENODE **)NULL);
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
	dfs.puts("</ParseBitfieldSpec>\n");
}

SYM *Declaration::ParsePrefixId()
{
	SYM *sp;

	dfs.puts("<ParsePrefixId>");            
	if (declid) delete declid;
	declid = new std::string(lastid);
	dfs.printf("B|%s|",(char *)declid->c_str());
	sp = allocSYM();
	dfs.printf("C"); 
	if (funcdecl==1) {
		if (nparms > 19)
			error(ERR_TOOMANY_PARAMS);
		else {
			names[nparms].str = *declid;
			nparms++;
		}
	}
	dfs.printf("D"); 
	NextToken();
	ParseDoubleColon(sp);
	if (declid) delete declid;
	declid = new std::string(lastid);
	sp->SetName(*declid);
	dfs.printf("E"); 
	if (lastst == colon) {
		ParseBitfieldSpec(isUnion);
		goto lxit;	// no ParseDeclarationSuffix()
	}
	sp->SetName(*declid);
	sp = ParseSuffix(sp);
	lxit:
	dfs.puts("</ParsePrefixId>");
	return sp;
}

SYM *Declaration::ParsePrefixOpenpa(bool isUnion)
{
	TYP *temp1, *temp2, *temp3, *temp4;
	SYM *sp;

	dfs.puts("<ParsePrefixOpenpa>\n");
	NextToken();
	temp1 = head;
	temp2 = tail;
	head = tail = (TYP *)NULL;	// It might be a typecast following.
	// Do we have (getchar)()
	// This processing is difficult to do with a loop, so a recursive
	// call is made.
	sp = ParsePrefix(isUnion); 
	needpunc(closepa,20);
	// Head could be NULL still if a type hasn't been found
	// eg. int (getchar)();
	if (head)
		isFuncPtr = head->type == bt_pointer;
	temp3 = head;
	temp4 = tail;
	head = temp1;
	tail = temp2;
	sp = ParseSuffix(sp);
	// (getchar)() returns temp4 = NULL
	if (temp4!=NULL) {
		temp4->btp = head->GetIndex();
		if(temp4->type == bt_pointer && temp4->val_flag != 0 && head != NULL)
			temp4->size *= head->size;
		head = temp3;
	}
	dfs.puts("</ParsePrefixOpenpa>\n");
	return sp;
}

// There may be only a single identifier in the prefix. This identifier may
// contain a class spec or namespace spec.

SYM *Declaration::ParsePrefix(bool isUnion)
{   
	TYP *temp1;
	SYM *sp;

	dfs.printf("<ParseDeclPrefix>(%d)\n",lastst);

	sp = nullptr;
j1:
	switch (lastst) {

	case kw_const:
		isConst = TRUE;
		NextToken();
		goto j1; 

//		case ellipsis:
	case id:
		sp = ParsePrefixId();
		goto lxit;

	case star:
		dfs.putch('*');
		temp1 = TYP::Make(bt_pointer,sizeOfWord);
		temp1->btp = head->GetIndex();
		head = temp1;
		if(tail == NULL)
			tail = head;
		NextToken();
		if (lastst==closepa)
			goto lxit;
		sp = ParsePrefix(isUnion);
		goto lxit;

	case openpa:
		sp = ParsePrefixOpenpa(isUnion);
		goto lxit;

	default:
		sp = ParseSuffix(sp);
		dfs.printf("Z");
		goto lxit;
	}
lxit:
	dfs.puts("</ParseDeclPrefix>\n");
	return sp;
}


// Take care of trailing [] in a declaration. These indicate array indicies.

void Declaration::ParseSuffixOpenbr()
{
	TYP *temp1;
	long sz2;

	NextToken();
	temp1 = (TYP *)TYP::Make(bt_pointer,8);
	temp1->val_flag = 1;
	temp1->isArray = TRUE;
	temp1->btp = head->GetIndex();
	if(lastst == closebr) {
		temp1->size = 0;
		temp1->numele = 0;
		if (head)
			temp1->dimen = head->dimen + 1;
		else
			temp1->dimen = 1;
		NextToken();
	}
	else if(head != NULL) {
		sz2 = (int)GetIntegerExpression((ENODE **)NULL);
		temp1->size = sz2 * head->size;
		temp1->numele = sz2;
		temp1->dimen = head->dimen + 1;
		dfs.printf("Setting array size:%d\n", (int)temp1->size);
		temp1->alignment = head->alignment;
		needpunc(closebr,21);
	}
	else {
		sz2 = (int)GetIntegerExpression((ENODE **)NULL);
		temp1->size = sz2;
		temp1->numele = sz2;
		temp1->dimen = 1;
		needpunc(closebr,22);
	}
	head = temp1;
	if( tail == NULL)
		tail = head;
}

void Declaration::ParseFunctionAttribute(SYM *sym)
{
	NextToken();
	needpunc(openpa,0);
	do {
		switch(lastst) {
		case kw_no_temps:
			sym->UsesTemps = false;
			NextToken();
			break;
		/*
		case kw_no_parms:
			sym->UsesStackParms = false;
			NextToken();
			break;
		*/
		}
	} while (lastst==comma);
	needpunc(closepa,0);
}


// Take care of following open parenthesis (). These indicate a function
// call. There may or may not be following parameters. A following '{' is
// looked for and if found a flag is set to parse the function body.

void Declaration::ParseSuffixOpenpa(SYM *sp)
{
	TYP *temp1;
	TYP *tempHead, *tempTail;
	int fd;
	std::string odecl;
	int isd;
	int nump = 0;
	int numa = 0;
	SYM *cf;
	
	dfs.printf("<openpa>\n");
	dfs.printf("****************************\n");
	dfs.printf("****************************\n");
	dfs.printf("Function: %s\n", (char *)sp->name->c_str());
	dfs.printf("****************************\n");
	dfs.printf("****************************\n");
	NextToken();
	sp->IsPascal = isPascal;
	sp->IsInline = isInline;
  
	// An asterik before the function name indicates a function pointer but only
	// if it's bracketed properly, otherwise it could be the return value that's
	// a pointer.
	//  isFuncPtr = head->type==bt_pointer;
	temp1 =(TYP *) TYP::Make(bt_func,0/*isFuncPtr ? bt_func : bt_ifunc,0*/);
	temp1->val_flag = 1;
	dfs.printf("o ");
	if (isFuncPtr) {
		dfs.printf("Got function pointer in declarations.\n");
		temp1->btp = head->btp;
		head->btp = temp1->GetIndex();
	}
	else {
		temp1->btp= head->GetIndex();
		head = temp1;
	}
	dfs.printf("p ");
	if (tail==NULL) {
		if (temp1->GetBtp())
			tail = temp1->GetBtp();
		else
			tail = temp1;
	}
	dfs.printf("q ");
	needParseFunction = 1;
	sp->params.Clear();
	sp->parent = currentClass->GetIndex();
	if(lastst == closepa) {
		NextToken();
		while (lastst == kw_attribute)
			ParseFunctionAttribute(sp);
	  if(lastst == begin) {
		  temp1->type = bt_ifunc;
		  needParseFunction = 2;
	  }
	  else {
		  if (lastst != semicolon) {
				goto j2;
			cf = currentFn;
			currentFn = sp;
			nump = 0;
			sp->BuildParameterList(&nump, &numa);
			currentFn = cf;
			if (lastst==begin) {
				temp1->type = bt_ifunc;
				currentFn = sp;
				sp->NumParms = nump;
				sp->numa = numa;
				needParseFunction = 2;
				goto j1;
			}
		}
	      temp1->type = bt_func;
		  needParseFunction = 0;
		  dfs.printf("Set false\n");
	  }
	  currentFn = sp;
	  sp->NumParms = 0;
	  sp->numa = 0;
j1: ;
  }
  else {
j2:
    dfs.printf("r");
	  currentFn = sp;
    dfs.printf("s");
    temp1->type = bt_func;
  	// Parse the parameter list for a function pointer passed as a
  	// parameter.
  	// Parse parameter list for a function pointer defined within
  	// a structure.
  	if (parsingParameterList || isStructDecl) {
      dfs.printf("s ");
  		fd = funcdecl;
  		needParseFunction = FALSE;
  	  dfs.printf("Set false\n");
		if (declid)
  			odecl = *declid;
		else
			odecl = "";
  		tempHead = head;
  		tempTail = tail;
  		isd = isStructDecl;
  		//ParseParameterDeclarations(10);	// parse and discard
  		funcdecl = 10;
  //				SetType(sp);
  		sp->BuildParameterList(&nump, &numa);
  		needParseFunction = 0;
  	  dfs.printf("Set false\n");
  //				sp->parms = sym;
  		sp->NumParms = nump;
  		isStructDecl = isd;
  		head = tempHead;
  		tail = tempTail;
  		if (declid) delete declid;
  		declid = new std::string(odecl);
  		funcdecl = fd;
		// There may be more parameters in the list.
		if (lastst==comma) {
			return;
		}
  		needpunc(closepa,23);
  
  		if (lastst==begin) {
  		  needParseFunction = 2;
  		  dfs.printf("Set true1\n");
  			if (sp->params.GetHead() && sp->proto.GetHead()) {
  			  dfs.printf("Matching parameter types to prototype.\n");
  			  if (!sp->ParameterTypesMatch(sp))
  			     error(ERR_PARMLIST_MISMATCH);
  		  }
  			temp1->type = bt_ifunc;
  		}
  		// If the declaration is ending in a semicolon then it was really
  		// a function prototype, so move the parameters to the prototype
  		// area.
  		else if (lastst==semicolon) {
  			sp->params.CopyTo(&sp->proto);
      }
  	  else {
		if (funcdecl > 0 && lastst==closepa)
			;
		else
  			error(ERR_SYNTAX);
  	  }
      dfs.printf("Z\r\n");
//				if (isFuncPtr)
//					temp1->type = bt_func;
//				if (lastst != begin)
//					temp1->type = bt_func;
//				if (lastst==begin) {
//					ParseFunction(sp);
//				}
    }
    dfs.printf("Y");
	  sp->PrintParameterTypes();
    dfs.printf("X");
  }
  dfs.printf("</openpa>\n");
}


// Take care of the () or [] trailing part of a declaration.
// There could be multiple sets of [] so a loop is formed to accomodate
// this. There will be only a single set of () indicating parameters.

SYM *Declaration::ParseSuffix(SYM *sp)
{
	dfs.printf("<ParseDeclSuffix>\n");

  while(true) {
    switch (lastst) {

    case openbr:
      ParseSuffixOpenbr();  
      break;                // We want to loop back for more brackets
  
    case openpa:
    	// The declaration doesn't have to have an identifier name; it could
    	// just be a type chain. so sp incoming might be null. We need a place
    	// to stuff the parameter / protoype list so we may as well create
    	// the symbol here if it isn't yet defined.
    	if (sp==nullptr)
    		sp = allocSYM();
      ParseSuffixOpenpa(sp);
      goto lxit;
      
    default:
      goto lxit;
    }
  }
lxit:
  dfs.printf("</ParseDeclSuffix>\n");
	return sp;
}

// Get the natural alignment for a given type.

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
		return alignment(tp->GetBtp());
	else
		return AL_POINTER;
	case bt_float:          return AL_FLOAT;
	case bt_double:         return AL_DOUBLE;
	case bt_triple:         return AL_TRIPLE;
	case bt_class:
	case bt_struct:
	case bt_union:          
		return (tp->alignment) ?  tp->alignment : AL_STRUCT;
	case bt_int32:
	case bt_int32u:
		return (AL_BYTE * 4);
	default:                return AL_CHAR;
	}
}


// Figure out the worst alignment required.

int walignment(TYP *tp)
{
	SYM *sp;

	//printf("DIAG: type NULL in alignment()\r\n");
	if (tp==NULL)
		return imax(AL_BYTE,worstAlignment);
	switch(tp->type) {
	case bt_byte:	case bt_ubyte:		return imax(AL_BYTE,worstAlignment);
	case bt_char:   case bt_uchar:     return imax(AL_CHAR,worstAlignment);
	case bt_short:  case bt_ushort:    return imax(AL_SHORT,worstAlignment);
	case bt_long:   case bt_ulong:     return imax(AL_LONG,worstAlignment);
	case bt_int32:  case bt_int32u:    return imax(AL_BYTE*4,worstAlignment);
    case bt_enum:           return imax(AL_CHAR,worstAlignment);
    case bt_pointer:
            if(tp->val_flag)
                return imax(alignment(tp->GetBtp()),worstAlignment);
            else
				return imax(AL_POINTER,worstAlignment);
    case bt_float:          return imax(AL_FLOAT,worstAlignment);
    case bt_double:         return imax(AL_DOUBLE,worstAlignment);
    case bt_triple:         return imax(AL_TRIPLE,worstAlignment);
	case bt_class:
    case bt_struct:
    case bt_union:          
		sp =(SYM *) sp->GetPtr(tp->lst.GetHead());
        worstAlignment = tp->alignment;
		while(sp != NULL) {
            if (sp->tp && sp->tp->alignment) {
                worstAlignment = imax(worstAlignment,sp->tp->alignment);
            }
            else
     			worstAlignment = imax(worstAlignment,walignment(sp->tp));
			sp = sp->GetNextPtr();
        }
		return worstAlignment;
    default:                return imax(AL_CHAR,worstAlignment);
    }
}

int roundAlignment(TYP *tp)
{
	worstAlignment = 0;
	if (tp->type == bt_struct || tp->type == bt_union || tp->type==bt_class) {
		return walignment(tp);
	}
	return alignment(tp);
}


// Round the size of the type up according to the worst alignment.

int roundSize(TYP *tp)
{
	int sz;
	int wa;

	worstAlignment = 0;
	if (tp->type == bt_struct || tp->type == bt_union || tp->type == bt_class) {
		wa = walignment(tp);
		sz = tp->size;
		if (sz == 0)
			return 0;
		while(sz % wa)
			sz++;
		return sz;
	}
	return tp->size;
}

// When going to insert a class method, check the base classes to see if it's
// a virtual function override. If it's an override, then add the method to
// the list of overrides for the virtual function.

void InsertMethod(SYM *sp)
{
  int nn;
  SYM *sym;
  std::string name;
  
  name = *sp->name;
  dfs.printf("<InsertMethod>%s type %d ", (char *)sp->name->c_str(), sp->tp->type);
  sp->GetParentPtr()->tp->lst.insert(sp);
  nn = sp->GetParentPtr()->tp->lst.FindRising(*sp->name);
  sym = sp->FindRisingMatch(true);
  if (sym) {
    dfs.puts("Found in a base class:");
    if (sym->IsVirtual) {
      dfs.printf("Found virtual:");
      sym->AddDerived(sp);
    }
  }
  dfs.printf("</InsertMethod>\n");
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
int Declaration::declare(SYM *parent,TABLE *table,int al,int ilc,int ztype)
{ 
	SYM *sp, *sp1;
  TYP *dhead, *tp1, *tp2;
	ENODE *ep1, *ep2;
	int op;
	int fn_doneinit = 0;
	int bcnt;
	bool flag;
	int parentBytes = 0;
  char buf[20];
  std::string name;
 
    static long old_nbytes;
    int nbytes;

	dfs.printf("Enter declare()\r\n");
	nbytes = 0;
	dfs.printf("A");
	classname = new std::string("");
	sp1 = nullptr;
	if (ParseSpecifier(table))
		goto xit1;
	dfs.printf("B");
	dhead = head;
	for(;;) {
	    if (declid) delete declid;
		declid = nullptr;
		dfs.printf("b");
		bit_width = -1;
		sp = ParsePrefix(ztype==bt_union);
		if (declid==nullptr)
			declid = new std::string("");
	  // If a function declaration is taking place and just the type is
	  // specified without a parameter name, assign an internal compiler
	  // generated name.
	  if (funcdecl>0 && funcdecl != 10 && declid->length()==0) {
		  sprintf_s(buf, sizeof(buf), "_p%d", nparms);
		  delete declid;
		  declid = new std::string(buf);
		  if (nparms > 19) {
		    error(ERR_TOOMANY_PARAMS);
      }
      else {
		    names[nparms].str = *declid;
		    nparms++;
	    }
		  missingArgumentName = TRUE;
	  }

    dfs.printf("C");
    if( declid->length() > 0 || classname->length()!=0) {      /* otherwise just struct tag... */
		  if (sp == nullptr) {
        sp = allocSYM();
		  }
		  SetType(sp);
		  sp->IsPascal = isPascal;
		  sp->IsInline = isInline;
		  sp->IsRegister = isRegister;
		  sp->IsAuto = isAuto;
		  sp->IsParameter = parsingParameterList > 0;
		  isRegister = false;
		  if (sp->parent < 0)// was nullptr
			  sp->parent = parent->GetIndex();
		  if (al==sc_member)
			  sp->IsPrivate = isPrivate;
		  else
			  sp->IsPrivate = false;
		  if (declid==nullptr)
		    declid = new std::string("");
      sp->SetName(classname->length() > 0 ? *classname : *declid);
      dfs.printf("D");
      if (classname) delete classname;
		  classname = new std::string("");
		  sp->IsVirtual = isVirtual;
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
dfs.printf("E");
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
/*
      dfs.printf("F");
		  if (sp->parent) {
        dfs.printf("f:%d",sp->parent);
        if (sp->GetParentPtr()->tp==nullptr) {
          dfs.printf("f:%d",sp->parent);
          dfs.printf("null type pointer.\n");
          parentBytes = 0;
        }
        else {
			    parentBytes = sp->GetParentPtr()->tp->size;
			    dfs.printf("ParentBytes=%d\n",parentBytes);
		    }
		  }
		  else
			  parentBytes = 0;
*/
			// Set the struct member storage offset.
		  if( al == sc_static || al==sc_thread) {
			  sp->value.i = nextlabel++;
		  }
		  else if( ztype == bt_union) {
        sp->value.i = ilc;// + parentBytes;
		  }
      else if( al != sc_auto ) {
        sp->value.i = ilc + nbytes;// + parentBytes;
		}
		// Auto variables are referenced negative to the base pointer
		// Structs need to be aligned on the boundary of the largest
		// struct element. If a struct is all chars this will be 2.
		// If a struct contains a pointer this will be 8. It has to
		// be the worst case alignment.
		else {
      sp->value.i = -(ilc + nbytes + roundSize(head));// + parentBytes);
		}

    dfs.printf("G");
		if (isConst)
			sp->tp->isConst = TRUE;
    if((sp->tp->type == bt_func) && sp->storage_class == sc_global )
      sp->storage_class = sc_external;

		// Increase the storage allocation by the type size.
    if(ztype == bt_union)
		nbytes = imax(nbytes,roundSize(sp->tp));
	else if(al != sc_external) {
		// If a pointer to a function is defined in a struct.
		if (isStructDecl) {
		    if (sp->tp->type==bt_func) {
			    nbytes += 8;
		    }
		    else if (sp->tp->type != bt_ifunc) {
			    nbytes += roundSize(sp->tp);
		    }
		}
		else {
		    nbytes += roundSize(sp->tp);
		}
	}

    dfs.printf("H");
      // For a class declaration there may not be any variables declared as
      // part of the declaration. In that case the symbol name is an empty
      // string. There's nothing to insert in the symbol table.
      name = *sp->name;
      if (sp->name->length() > 0) {
        //dfs.printf("Table:%p, sp:%p Fn:%p\r\n", table, sp, currentFn);
        if (sp->parent) {
          int nn;
          // If a function body is being processed we want to look for
          // symbols by rising through the hierarchy. Otherwise we want a
          // lower level defined symbol to shadow one at a hight level.
          if (isFuncBody) {
            nn = sp->GetParentPtr()->tp->lst.FindRising(*sp->name);
            if (nn)
              sp1 = sp->FindRisingMatch(false);
          }
          else {
            nn = sp->GetParentPtr()->tp->lst.Find(*sp->name);
            if (nn) {
              sp1 = sp->FindExactMatch(TABLE::matchno);
            }
          }
        }
        else
  			  sp1 = table->Find(*sp->name,false);

        dfs.printf("h");
        if (sp->tp) {
          dfs.printf("h1");
  			  if (sp->tp->type == bt_ifunc || sp->tp->type==bt_func) {
            dfs.printf("h2");
  				  sp1 = sp->FindExactMatch(TABLE::matchno);
            dfs.printf("i");
  			  }
  		  }
  			else {
  dfs.printf("j");
  				if (TABLE::matchno)
  					sp1 = TABLE::match[TABLE::matchno-1];
  				else
  					sp1 = nullptr;
  			}
  dfs.printf("k");
  			flag = false;
  			if (sp1) {
  			  if (sp1->tp) {
  dfs.printf("l");
  				   flag = sp1->tp->type == bt_func;
  	      }
  			}
  dfs.printf("I");
  			if (sp->tp->type == bt_ifunc && flag)
  			{
  dfs.printf("Ia");
  				dfs.printf("bt_ifunc\r\n");
  				sp1->SetType(sp->tp);
  				sp1->storage_class = sp->storage_class;
          sp1->value.i = sp->value.i;
          sp1->IsPascal = sp->IsPascal;
  				sp1->IsPrototype = sp->IsPrototype;
  				sp1->IsVirtual = sp->IsVirtual;
  				sp1->parent = sp->parent;
  				sp1->params = sp->params;
  				sp1->proto = sp->proto;
  				sp1->lsyms = sp->lsyms;
  				sp = sp1;
              }
  			else {
  dfs.printf("Ib");
  				// Here the symbol wasn't found in the table.
  				if (sp1 == nullptr) {
  dfs.printf("Ic");
            if ((sp->tp->type==bt_class)
               && (sp->storage_class == sc_type || sp->storage_class==sc_typedef))
              ; // Do nothing. The class was already entered in the tag table.
            else if ((sp->tp->type == bt_struct || sp->tp->type==bt_union)
               && (sp->storage_class == sc_type && sp->storage_class!=sc_typedef)
               && sp->tp->sname->length() > 0)
              ; // If there was no struct tag and this is a typedef, then it
                // still needs to be inserted into the table.
            else {
              dfs.printf("insert type: %d\n", sp->tp->type);
  					  dfs.printf("***Inserting:%s into %p\n",(char *)sp->name->c_str(), (char *) table);
  					   // Need to know the type before a name can be generated.
              sp->mangledName = sp->BuildSignature();
   					  if (sp->parent && ((sp->tp->type==bt_func || sp->tp->type==bt_ifunc)
   					  || (sp->tp->type==bt_pointer && (sp->tp->GetBtp()->type==bt_func || sp->tp->GetBtp()->type==bt_ifunc))))
              {
  					    InsertMethod(sp);
  			      }
  			      else {
                table->insert(sp);
  					  }
  				  }
  				}
  			}
  dfs.printf("J");
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
  dfs.printf("K");
              if( (al == sc_global || al == sc_static || al==sc_thread) && !fn_doneinit &&
                      sp->tp->type != bt_func && sp->tp->type != bt_ifunc && sp->storage_class!=sc_typedef)
                      doinit(sp);
          }
      }
		if (funcdecl>0) {
			if (lastst==comma || lastst==semicolon) {
				break;
			}
			if (lastst==closepa) {
				goto xit1;
			}
		}
		else if (catchdecl==TRUE) {
			if (lastst==closepa)
				goto xit1;
		}
		else if (lastst == semicolon) {
			if (sp) {
				if (sp->tp) {
					if (sp->tp->type==bt_class && (sp->storage_class != sc_type
            && sp->storage_class != sc_typedef)) {
            int nn;
            nn = sp->tp->lst.FindRising(*sp->tp->sname);
            if (nn > 0) {
              if (sp1) {
                ENODE *ep1,*ep2;
                ep1 = nullptr;
  							// Build an expression that references the ctor.
  							tp1 = nameref2(*sp->tp->sname,&ep1,TRUE,false,nullptr,nullptr);
  							// Create a function call node for the ctor.
  							if (tp1!=nullptr) {
  							  // Make an expresison that references the var name as the
  							  // argument to the ctor.
  							  ep2 = makesnode(en_nacon,sp->name,sp->mangledName,sp->value.i);
  								ep1 = makenode(en_fcall, ep1, ep2);
  							}
  							sp->initexp = ep1;
              }
            }
		/*
						// First see if there is a ctor. If there are no ctors there's
						// nothing to do.
						memset(typearray,0,sizeof(typearray));
						sp1 = search2(sp->tp->sname,&sp->tp->lst,typearray);
						if (sp1) {
							// Build an expression that references the ctor.
							tp1 = nameref2(sp->tp->sname,&ep1,TRUE,false,typearray);
							// Create a function call node for the ctor.
							if (tp1!=nullptr) {
								memcpy(typearray,GetParameterTypes(sp),sizeof(typearray));
								ep1 = makenode(en_fcall, ep1, nullptr);
							}
							sp->initexp = ep1;
						}
		*/
					}
				}
			}
			break;
		}
		else if (lastst == assign) {
			tp1 = nameref(&ep1,TRUE);
            op = en_assign;
//            NextToken();
            tp2 = asnop(&ep2);
            if( tp2 == 0 || !IsLValue(ep1) )
                  error(ERR_LVALUE);
            else    {
                    tp1 = forcefit(&ep1,tp1,&ep2,tp2,false);
                    ep1 = makenode(op,ep1,ep2);
                    }
			sp->initexp = ep1;
			if (lastst==semicolon)
				break;
		}
        needpunc(comma,24);
        if(declbegin(lastst) == 0)
                break;
        head = dhead;
    }
    NextToken();
xit1:
//	printf("Leave declare()\r\n");
    return nbytes;
}

int declbegin(int st)
{
	return st == star || st == id || st == openpa || st == openbr; 
}

void GlobalDeclaration::Parse()
{
  bool notVal = false;
  isFuncPtr = false;
  isPascal = FALSE;
  isInline = false;
	dfs.puts("<ParseGlobalDecl>\n");
  for(;;) {
    currentClass = nullptr;
    currentFn = nullptr;
    currentStmt = nullptr;
    isFuncBody = false;
		worstAlignment = 0;
		funcdecl = 0;
		switch(lastst) {
		case kw_pascal:
		  NextToken();
		  isPascal = TRUE;
		  break;
		case kw_inline:
		  NextToken();
		  isInline = true;
		  break;
		case ellipsis:
		case id:
        case kw_kernel:
		case kw_interrupt:
        case kw_task:
		case kw_cdecl:
		case kw_naked:
		case kw_nocall:
		case kw_oscall:
		case kw_typedef:
    case kw_virtual:
		case kw_volatile: case kw_const:
        case kw_exception:
		case kw_int8: case kw_int16: case kw_int32: case kw_int64: case kw_int40: case kw_int80:
		case kw_byte: case kw_char: case kw_int: case kw_short: case kw_unsigned: case kw_signed:
        case kw_long: case kw_struct: case kw_union: case kw_class:
        case kw_enum: case kw_void:
        case kw_float: case kw_double:
		case kw_vector: case kw_vector_mask:
                lc_static += declare(NULL,&gsyms[0],sc_global,lc_static,bt_struct);
				isInline = false;
				break;
        case kw_thread:
				NextToken();
                lc_thread += declare(NULL,&gsyms[0],sc_thread,lc_thread,bt_struct);
				isInline = false;
				break;
		case kw_register:
				NextToken();
                error(ERR_ILLCLASS);
                lc_static += declare(NULL,&gsyms[0],sc_global,lc_static,bt_struct);
				isInline = false;
				break;
		case kw_private:
        case kw_static:
                NextToken();
				lc_static += declare(NULL,&gsyms[0],sc_static,lc_static,bt_struct);
				isInline = false;
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
          declare(NULL,&gsyms[0],sc_external,0,bt_struct);
          isInline = false;
          --global_flag;
          break;
 
    case kw_not:
      NextToken();
      notVal = !notVal;
      break;

    case kw_using:
      NextToken();
      if (lastst==id) {
        if (strcmp(lastid,"_name")==0) {
          NextToken();
          if (lastst==id) {
            if (strcmp(lastid, "_mangler")==0) {
              NextToken();
              mangledNames = !notVal;
            }
          }
        }
        else if (strcmp(lastid,"_real")==0) {
          NextToken();
          if (lastst==id) {
            if (strcmp(lastid,"_names")==0) {
              NextToken();
              mangledNames = notVal;
            }
          }
        }
      }
      break;

    default:
      goto xit;
		}
	}
xit:
	dfs.puts("</ParseGlobalDecl>\n");
	;
}

void AutoDeclaration::Parse(SYM *parent, TABLE *ssyms)
{
	SYM *sp;

  isFuncPtr = false;
//	printf("Enter ParseAutoDecls\r\n");
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
	            lc_auto += declare(parent,ssyms,sc_auto,lc_auto,bt_struct);
				break;
		case ellipsis:
		case id: //return;
        dfs.printf("Found %s\n", lastid);
				sp = tagtable.Find(lastid,false);
				if (sp)
				   dfs.printf("Found in tagtable");
				if (sp==nullptr)
					sp = gsyms[0].Find(lastid,false);
				if (sp) {
				  dfs.printf("sp okay sc=%d\n", sp->storage_class);
					if (sp->storage_class==sc_typedef || sp->storage_class==sc_type) {
					  dfs.printf("Declaring var of type\n");
			            lc_auto += declare(parent,ssyms,sc_auto,lc_auto,bt_struct);
						break;
					}
				}
				goto xit;
        case kw_register:
                NextToken();
        case kw_exception:
		case kw_volatile: case kw_const:
		case kw_int8: case kw_int16: case kw_int32: case kw_int64: case kw_int40: case kw_int80:
		case kw_byte: case kw_char: case kw_int: case kw_short: case kw_unsigned: case kw_signed:
        case kw_long: case kw_struct: case kw_union: case kw_class:
        case kw_enum: case kw_void:
        case kw_float: case kw_double:
		case kw_vector: case kw_vector_mask:
            lc_auto += declare(parent,ssyms,sc_auto,lc_auto,bt_struct);
            break;
        case kw_thread:
                NextToken();
				lc_thread += declare(parent,ssyms,sc_thread,lc_thread,bt_struct);
				break;
        case kw_static:
                NextToken();
				lc_static += declare(parent,ssyms,sc_static,lc_static,bt_struct);
				break;
        case kw_extern:
                NextToken();
				if (lastst==kw_oscall || lastst==kw_interrupt || lastst == kw_nocall || lastst==kw_naked || lastst==kw_kernel)
					NextToken();
                ++global_flag;
                declare(NULL,&gsyms[0],sc_external,0,bt_struct);
                --global_flag;
                break;
        default:
                goto xit;
		}
	}
xit:
	;
//	printf("Leave ParseAutoDecls\r\n");
}

int ParameterDeclaration::Parse(int fd)
{
	int ofd;
  int opascal;
	isAuto = false;

  isFuncPtr = false;
	nparms = 0;
	dfs.puts("<ParseParmDecls>\n");
	worstAlignment = 0;
	ofd = funcdecl;
	opascal = isPascal;
	isPascal = FALSE;
	isRegister = false;
	funcdecl = fd;
	missingArgumentName = FALSE;
	parsingParameterList++;
    for(;;) {
dfs.printf("A(%d)",lastst);
		switch(lastst) {
		case kw_auto:
			NextToken();
			isAuto = true;
			break;
		case kw_pascal:
      NextToken();
		  isPascal = TRUE;
		  break;
		case kw_cdecl:
    case kw_kernel:
		case kw_interrupt:
		case kw_naked:
		case kw_nocall:
		case kw_oscall:
		case kw_typedef:
dfs.printf("B");
      error(ERR_ILLCLASS);
      declare(NULL,&currentFn->params,sc_auto,0,bt_struct);
				isAuto = false;
			break;
		case ellipsis:
		case id:
		case kw_volatile: case kw_const:
        case kw_exception:
		case kw_int8: case kw_int16: case kw_int32: case kw_int64: case kw_int40: case kw_int80:
		case kw_byte: case kw_char: case kw_int: case kw_short: case kw_unsigned: case kw_signed:
    case kw_long: case kw_struct: case kw_union: case kw_class:
    case kw_enum: case kw_void:
    case kw_float: case kw_double:
	case kw_vector: case kw_vector_mask:
dfs.printf("C");
    declare(NULL,&currentFn->params,sc_auto,0,bt_struct);
				isAuto = false;
	            break;
        case kw_thread:
                NextToken();
                error(ERR_ILLCLASS);
				lc_thread += declare(NULL,&gsyms[0],sc_thread,lc_thread,bt_struct);
				isAuto = false;
				break;
        case kw_static:
                NextToken();
                error(ERR_ILLCLASS);
				lc_static += declare(NULL,&gsyms[0],sc_static,lc_static,bt_struct);
				isAuto = false;
				break;
        case kw_extern:
dfs.printf("D");
                NextToken();
                error(ERR_ILLCLASS);
				if (lastst==kw_oscall || lastst==kw_interrupt || lastst == kw_nocall || lastst==kw_naked || lastst==kw_kernel)
					NextToken();
                ++global_flag;
                declare(NULL,&gsyms[0],sc_external,0,bt_struct);
				isAuto = false;
                --global_flag;
                break;
		case kw_register:
				isRegister = true;
				NextToken();
				break;
        default:
				goto xit;
		}
dfs.printf("E");
	}
xit:
	parsingParameterList--;
	funcdecl = ofd;
	isPascal = opascal;
	dfs.printf("</ParseParmDecls>\n");
	return nparms;
}

GlobalDeclaration *GlobalDeclaration::Make()
{
  GlobalDeclaration *p = (GlobalDeclaration *)allocx(sizeof(GlobalDeclaration));
  return p;
}

void compile()
{
}

