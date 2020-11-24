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

//TYP *tail = (TYP *)NULL;
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
bool isLeaf = false;
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
int defaultcc = 1;

bool IsDeclBegin(int st)
{
	return (st == star || st == id || st == openpa || st == openbr);
}

int     imax(int i, int j)
{       return ((i > j) ? i : j);
}


char *my_strdup(char *s)
{
	char *p;
	int n = strlen(s);
	int m = sizeof(char);
	p = (char *)allocx(sizeof(char)*(n+1));
	memcpy(p,s,sizeof(char)*(n));
	p[n] = '\0';
	return (p);
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
				sp->tp->isUnsigned = head->isUnsigned;
				//  		*(sp->tp) = *head;
				// The width eventually ends up in an extract or deposit instruction so,
				// minus one is subtracted here. (The instruction wants one less than
				// the actual width.
				sp->tp->bit_width = makeinode(en_icon, (int64_t)bit_width-1);
				sp->tp->bit_offset = makeinode(en_icon, bit_offset);
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

void Declaration::ParseShort()
{
	bit_max = 32;
	NextToken();
	switch(lastst) {
	case kw_int:
		NextToken();
		if (isUnsigned) {
			head = (TYP *)TYP::Make(bt_ushort,4);
			tail = head;
		}
		else {
			head = (TYP *)TYP::Make(bt_short,4);
			tail = head;
		}
		break;
	default:
		if (isUnsigned) {
			head = (TYP *)TYP::Make(bt_ushort,4);
			tail = head;
		}
		else {
			head = (TYP *)TYP::Make(bt_short,4);
			tail = head;
		}
		break;
	}
	head->isUnsigned = isUnsigned;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
	head->isShort = TRUE;
}

void Declaration::ParseLong()
{
	NextToken();
	if (lastst==kw_int) {
		head = (TYP*)TYP::Make(bt_long, sizeOfWord);
		tail = head;
		bit_max = head->precision;
		NextToken();
	}
	else if (lastst == kw_long) {
		//head = (TYP*)TYP::Make(bt_i128, sizeOfWord * 2);
		//bit_max = 128;
		head = (TYP*)TYP::Make(bt_long, sizeOfWord);
		tail = head;
		bit_max = head->precision;
		NextToken();
		if (lastst == kw_int)
			NextToken();
	}
	else if (lastst==kw_float) {
		head = (TYP *)TYP::Make(bt_double,sizeOfFPD);
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
	else if (lastst == kw_posit) {
		head = (TYP*)TYP::Copy(&stdposit);
		tail = head;
		bit_max = head->precision;
		NextToken();
	}
	else {
		if (isUnsigned) {
			head =(TYP *)TYP::Make(bt_ulong,sizeOfWord);
			tail = head;
			bit_max = head->precision;
		}
		else {
			head = (TYP *)TYP::Make(bt_long,sizeOfWord);
			tail = head;
			bit_max = head->precision;
		}
	}
	//NextToken();
	if (lastst==kw_task) {
		isTask = TRUE;
		NextToken();
		bit_max = 64;
	}
	if (lastst==kw_oscall) {
		isOscall = TRUE;
		NextToken();
		bit_max = 64;
	}
	else if (lastst==kw_nocall || lastst==kw_naked) {
		isNocall = TRUE;
		NextToken();
		bit_max = 64;
	}
	head->isUnsigned = isUnsigned;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
}

void Declaration::ParseInt()
{
//printf("Enter ParseInt\r\n");
	if (isUnsigned) {
		head = TYP::Make(bt_ulong,sizeOfWord);
		tail = head;
	}
	else {
		head = TYP::Make(bt_long,sizeOfWord);
		tail = head;
	}
	bit_max = 64;
	if (head==nullptr)
		return;
	head->isUnsigned = isUnsigned;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
	NextToken();
	if (lastst == colon) {
		NextToken();
		if (lastst == iconst) {
			head->precision = ival;// (__int16)GetIntegerExpression(nullptr);
			NextToken();
			if (head->precision != 8
				&& head->precision != 16
				&& head->precision != 32
				&& head->precision != 40
				&& head->precision != 64
				&& head->precision != 80
				&& head->precision != 128) {
				error(ERR_PRECISION);
				head->precision = 64;
			}
		}
		else
			error(ERR_INT_CONST);
	}
	head->size = head->precision >> 3;
	bit_max = head->precision;
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

void Declaration::ParseBit()
{
	//printf("Enter ParseInt\r\n");
	head = TYP::Make(bt_bit, sizeOfWord);
	tail = head;
	if (head == nullptr)
		return;
	head->isUnsigned = isUnsigned;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
	head->isBits = true;
	NextToken();
	head->size = 8;
	bit_max = 64;
}

void Declaration::ParseFloat()
{
//	head = TYP::Copy(&stddouble);
	head = (TYP*)TYP::Make(bt_double, 8);
	tail = head;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
	NextToken();
	if (lastst == colon) {
		NextToken();
		if (lastst == iconst) {
			head->precision = ival;
			NextToken();
			if ((head->precision & 7) != 0
				|| head->precision < 16
				|| head->precision > 128) {
				error(ERR_PRECISION);
				head->precision = sizeOfWord * 8;
			}
		}
		else
			error(ERR_INT_CONST);
	}
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

void Declaration::ParsePosit()
{
	head = (TYP*)TYP::Make(bt_posit, 8);
	tail = head;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
	NextToken();
	if (lastst == colon) {
		NextToken();
		if (lastst == iconst) {
			head->precision = ival;
			head->size = head->precision / 8;
			NextToken();
			if ((head->precision & 7) != 0
				|| head->precision < 16
				|| head->precision > 128) {
				error(ERR_PRECISION);
				head->precision = sizeOfWord * 8;
			}
		}
		else
			error(ERR_INT_CONST);
	}
	if (lastst == kw_vector) {
		int btp = head->GetIndex();
		head = TYP::Make(bt_vector, 512);
		head->numele = maxVL;
		head->btp = btp;
		tail = head;
		NextToken();
	}
	bit_max = head->precision;
}

void Declaration::ParseTriple()
{
	head = (TYP *)TYP::Make(bt_triple, 12);
	head->precision = 96;
	tail = head;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
	NextToken();
	if (lastst == kw_vector) {
		int btp = head->GetIndex();
		head = TYP::Make(bt_vector, 512);
		head->numele = maxVL;
		head->btp = btp;
		tail = head;
		NextToken();
	}
	bit_max = head->precision;
}

void Declaration::ParseFloat128()
{
	head = (TYP *)TYP::Make(bt_quad, 16);
	tail = head;
	head->precision = 128;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
	NextToken();
	if (lastst == kw_vector) {
		int btp = head->GetIndex();
		head = TYP::Make(bt_vector, 512);
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
	head->numele = maxVL;
	NextToken();
	bit_max = head->precision;
}

void Declaration::ParseInt32()
{
	if (isUnsigned) {
		head = (TYP *)TYP::Make(bt_ushort,4);
		tail = head;
	}
	else {
		head = (TYP *)TYP::Make(bt_short,4);
		tail = head;
	}
	bit_max = 32;
	NextToken();
	if( lastst == kw_int )
		NextToken();
	head->isUnsigned = isUnsigned;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
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
	head->isShort = TRUE;
}

void Declaration::ParseChar()
{
	if (isUnsigned) {
		head = (TYP *)TYP::Make(isInline ? bt_iuchar : bt_uchar,2);
		tail = head;
	}
	else {
		head =(TYP *)TYP::Make(isInline ? bt_ichar : bt_char,2);
		tail = head;
	}
	head->isUnsigned = isUnsigned;
	head->isVolatile = isVolatile;
	head->isIO = isIO;
	NextToken();
	if (lastst == colon) {
		NextToken();
		if (lastst == iconst) {
			head->precision = ival;
			NextToken();
			if ((head->precision & 7) != 0
				|| head->precision > 32) {
				error(ERR_PRECISION);
				head->precision = 16;
			}
		}
		else
			error(ERR_INT_CONST);
	}
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
	bit_max = head->precision;
}

SYM *Declaration::ParseId()
{
	SYM *sp;

  dfs.printf("<ParseId>%s",lastid);
	sp = tagtable.Find(lastid,false);//gsyms[0].Find(lastid);
	if (sp == nullptr) {
		sp = gsyms[0].Find(lastid, false);
	}
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
		head = (TYP *)TYP::Make(bt_long,8);
		tail = head;
		bit_max = head->precision;
	}
	dfs.puts("</ParseId>");
	return (sp);
}

void Declaration::ParseClass()
{
	ClassDeclaration cd;

	NextToken();
	cd.bit_max = bit_max;
	cd.bit_next = bit_next;
	cd.bit_offset = bit_offset;
	cd.bit_width = bit_width;
	cd.Parse(bt_class);
	cd.GetType(&head, &tail);
	bit_max = cd.bit_max;
	bit_next = cd.bit_next;
	bit_offset = cd.bit_offset;
	bit_width = cd.bit_width;
}

int Declaration::ParseStruct(TABLE* table, e_bt typ, SYM **sp)
{
	StructDeclaration sd;
	int rv;

	NextToken();
	sd.bit_max = bit_max;
	sd.bit_next = bit_next;
	sd.bit_offset = bit_offset;
	sd.bit_width = bit_width;
	rv = sd.Parse(table, typ, sp);
	sd.GetType(&head, &tail);
	bit_max = sd.bit_max;
	bit_next = sd.bit_next;
	bit_offset = sd.bit_offset;
	bit_width = sd.bit_width;
	return (rv);
}

// Parse a specifier. This is the first part of a declaration.
// Returns:
// 0 usually, 1 if only a specifier is present
//
int Declaration::ParseSpecifier(TABLE* table, SYM** sym, e_sc sc)
{
	SYM *sp;
	ClassDeclaration cd;
	StructDeclaration sd;
	bool rv;

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
			case kw_bit:	ParseBit(); goto lxit;
			case kw_byte:   ParseByte(); goto lxit;
			case kw_char:	ParseChar(); goto lxit;
			case kw_int8:	ParseInt8(); goto lxit;
			case kw_int16:	ParseChar(); goto lxit;
			case kw_int32:	ParseInt32(); goto lxit;
			case kw_int64:	ParseInt64(); goto lxit;
			case kw_short:	ParseShort();	goto lxit;
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
				NextToken();
				bit_max = 32;
				goto lxit;

			case id:	sp = ParseId();	goto lxit;

			case kw_float:	ParseFloat(); goto lxit;
			case kw_double:	ParseDouble(); goto lxit;
			case kw_float128:	ParseFloat128(); goto lxit;
			case kw_posit:	ParsePosit(); goto lxit;

			case kw_triple:
				head = TYP::Copy(&stdtriple);
				tail = head;
				head->isVolatile = isVolatile;
				head->isIO = isIO;
				NextToken();
				bit_max = head->precision;
				goto lxit;

			case kw_vector:	ParseVector(); goto lxit;
			case kw_vector_mask: ParseVectorMask(); goto lxit;

			case kw_void:	ParseVoid(); goto lxit;

			case kw_enum:
				NextToken();
				ParseEnum(table);
				bit_max = 16;
				goto lxit;

			case kw_class:
				ParseClass();
				goto lxit;

			case kw_struct:
				if (ParseStruct(table, bt_struct, &sp)) {
					*sym = sp;
					return (1);
				}
				*sym = sp;
				goto lxit;

			case kw_union:
				if (ParseStruct(table, bt_union, &sp)) {
					*sym = sp;
					return (1);
				}
				*sym = sp;
				goto lxit;

      case kw_exception:
				head = (TYP *)TYP::Make(bt_exception,8);
				tail = head;
				head->isVolatile = isVolatile;
				head->isIO = isIO;
				NextToken();
				bit_max = 64;
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
		sp->fi = MakeFunction(sp->id, sp, defaultcc==1, false);
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
	//if (isFuncPtr) {
	//	head->btp = temp1->GetIndex();
	//}
	//else
	{
		head = temp1;
		tail = temp2;
	}
	sp = ParseSuffix(sp);
	// (getchar)() returns temp4 = NULL
	if (temp4!=NULL) {
		temp4->btp = head->GetIndex();
		if(temp4->type == bt_pointer && temp4->val_flag != 0 && head != NULL)
			temp4->size *= head->size;
		head = temp3;
	}
	dfs.puts("</ParsePrefixOpenpa>\n");
	return (sp);
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
		bit_max = sizeOfPtr * 8;
		dfs.putch('*');
		temp1 = TYP::Make(bt_pointer,sizeOfPtr);
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
	return (sp);
}


// Take care of trailing [] in a declaration. These indicate array indicies.

void Declaration::ParseSuffixOpenbr()
{
	TYP *temp1;
	long sz2;

	NextToken();
	temp1 = (TYP *)TYP::Make(bt_pointer,sizeOfPtr);
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
	if(tail == NULL)
		tail = head;
}

/*
void Declaration::ParseSuffixOpenbr()
{
	TYP *temp1;
	long sz2;

	NextToken();
	temp1 = (TYP *)TYP::Make(bt_pointer, sizeOfPtr);
	temp1->val_flag = 1;
	temp1->isArray = TRUE;
	if (tail)
		tail->btp = temp1->GetIndex();
	if (lastst == closebr) {
		temp1->size = 0;
		temp1->numele = 0;
		if (tail)
			temp1->dimen = tail->dimen + 1;
		else
			temp1->dimen = 1;
		NextToken();
	}
	else if (tail != NULL) {
		sz2 = (int)GetIntegerExpression((ENODE **)NULL);
		temp1->size = sz2 * head->size;
		temp1->numele = sz2;
		temp1->dimen = tail->dimen + 1;
		dfs.printf("Setting array size:%d\n", (int)temp1->size);
		temp1->alignment = tail->alignment;
		needpunc(closebr, 21);
	}
	else {
		sz2 = (int)GetIntegerExpression((ENODE **)NULL);
		temp1->size = sz2;
		temp1->numele = sz2;
		temp1->dimen = 1;
		needpunc(closebr, 22);
	}
	if (head == nullptr)
		head = temp1;
	tail = temp1;
}
*/
void Declaration::ParseFunctionAttribute(Function *sym)
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

void Declaration::ParseFunctionJ2(Function* sp)
{
	int fd;
	std::string odecl;
	TYP* tempHead, * tempTail;
	int isd;
	int nump = 0;
	int numa = 0;
	Function* cf;

	dfs.printf("r");
	//cf = currentFn;
 // currentFn = sp;
	dfs.printf("s");
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
		head = tail = nullptr;
		//ParseParameterDeclarations(10);	// parse and discard
		funcdecl = 10;
		//				SetType(sp);
		cf = currentFn;
		currentFn = sp;
		sp->BuildParameterList(&nump, &numa);
		currentFn = cf;
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
		if (lastst == comma) {
			return;
		}
		needpunc(closepa, 23);

		if (lastst == begin) {
			needParseFunction = 2;
			dfs.printf("Set true1\n");
			if (sp->params.GetHead() && sp->proto.GetHead()) {
				dfs.printf("Matching parameter types to prototype.\n");
				if (!sp->ParameterTypesMatch(sp))
					error(ERR_PARMLIST_MISMATCH);
			}
			//temp1->type = bt_ifunc;
		}
		// Could be a function prototype in a parameter list followed by a comma.
		else if (lastst == comma && parsingParameterList > 0) {
			sp->params.CopyTo(&sp->proto);
			return;
		}
		// If the declaration is ending in a semicolon then it was really
		// a function prototype, so move the parameters to the prototype
		// area.
		else if (lastst == semicolon) {
			sp->params.CopyTo(&sp->proto);
		}
		else {
			if (funcdecl > 0 && lastst == closepa)
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
	/*
	else {
		int ppl = parsingParameterList;
		parsingParameterList = false;
		cf = currentFn;
		currentFn = sp;
		sp->BuildParameterList(&nump, &numa);
		parsingParameterList = ppl;
		currentFn = cf;
		sp->NumParms = nump;
		sp->numa = numa;
		//needpunc(closepa,23);
		if (lastst == semicolon) {
			sp->params.CopyTo(&sp->proto);
			needParseFunction = false;
		}
	}
	*/
	dfs.printf("Y");
	sp->PrintParameterTypes();
	dfs.printf("X");
}

// Take care of following open parenthesis (). These indicate a function
// call. There may or may not be following parameters. A following '{' is
// looked for and if found a flag is set to parse the function body.

void Declaration::ParseSuffixOpenpa(Function *sp)
{
	TYP *temp1, *temp2;
	TYP *tempHead, *tempTail;
	int fd;
	std::string odecl;
	int isd;
	int nump = 0;
	int numa = 0;
	Function *cf;
	
	dfs.printf("<openpa>\n");
	dfs.printf("****************************\n");
	dfs.printf("****************************\n");
	dfs.printf("Function: %s\n", (char *)sp->sym->name->c_str());
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
		temp2 = (TYP *)TYP::Make(bt_pointer, 0);
		//temp1->btp = head->btp;
		//head->btp = temp1->GetIndex();
		temp1->btp = head->GetIndex();
		temp2->btp = temp1->GetIndex();
		head = temp1;
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
	sp->sym->parent = currentClass->GetIndex();
	if(lastst == closepa) {
		NextToken();
		while (lastst == kw_attribute)
			ParseFunctionAttribute(sp);
	  if(lastst == begin) {
		  temp1->type = bt_ifunc;
		  needParseFunction = 2;
			sp->NumParms = 0;
			sp->numa = 0;
		}
	  else {
		  if (lastst != semicolon) {
				ParseFunctionJ2(sp);
				return;
			}
	    temp1->type = bt_func;
		  needParseFunction = 0;
		  dfs.printf("Set false\n");
	  }
	  currentFn = sp;
	  sp->NumParms = 0;
	  sp->numa = 0;
  }
	else {
		ParseFunctionJ2(sp);
	}
  dfs.printf("</openpa>\n");
}


// Take care of the () or [] trailing part of a declaration.
// There could be multiple sets of [] so a loop is formed to accomodate
// this. There will be only a single set of () indicating parameters.

SYM *Declaration::ParseSuffix(SYM *sp)
{
	TYP* tp;
	ENODE* node;

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
			if (sp == nullptr) {
				sp = allocSYM();
				sp->fi = MakeFunction(sp->id, sp, defaultcc == 1, isInline);
			}
			else if (sp->fi == nullptr) {
				sp->fi = MakeFunction(sp->id, sp, defaultcc == 1, isInline);
			}
			ParseSuffixOpenpa(sp->fi);
			goto lxit;

		case assign:
			if (parsingParameterList) {
				NextToken();
				currentSym = sp;
				SetType(sp);
				GetConstExpression(&node);
				sp->defval = node;
			}
			goto lxit;
		
		default:
			goto lxit;
		}
	}
lxit:
	dfs.printf("</ParseDeclSuffix>\n");
	return (sp);
}

void Declaration::AssignParameterName()
{
	char buf[20];

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


void Declaration::ParseAssign(SYM *sp)
{
	TYP *tp1, *tp2;
	enum e_node op;
	ENODE *ep1, *ep2;
	Expression exp;
	exp.head = head;
	exp.tail = tail;

	if (parsingParameterList) {
		GetConstExpression(&ep2);
		sp->defval = ep2;
	}
	else {
		NextToken();
		ep1 = exp.MakeAutoNameNode(sp);
		ep1->sym = sp;
		tp1 = exp.CondDeref(&ep1, sp->tp);
		//tp1 = exp.nameref(&ep1, TRUE);
		op = en_assign;
		tp2 = exp.ParseAssignOps(&ep2);
		if (tp2 == nullptr || !IsLValue(ep1))
			error(ERR_LVALUE);
		else {
			tp1 = forcefit(&ep2, tp2, &ep1, tp1, false, true);
			ep1 = makenode(op, ep1, ep2);
			ep1->tp = tp1;
		}
		// Move vars with initialization data over to the data segment.
		if (ep1->segment == bssseg)
			ep1->segment = dataseg;
		sp->initexp = ep1;
	}
}


// Processing done when the end of a declaration (;) is reached.

void Declaration::DoDeclarationEnd(SYM *sp, SYM *sp1)
{
	int nn;
	TYP *tp1;
	ENODE *ep1, *ep2;
	Expression exp;

	if (sp == nullptr)
		return;
	if (sp->tp == nullptr)
		return;
	if (sp->tp->type == bt_class && (sp->storage_class != sc_type
		&& sp->storage_class != sc_typedef)) {
		nn = sp->tp->lst.FindRising(*sp->tp->sname);
		if (nn > 0) {
			if (sp1) {
				ep1 = nullptr;
				// Build an expression that references the ctor.
				tp1 = exp.nameref2(*sp->tp->sname, &ep1, TRUE, false, nullptr, nullptr);
				// Create a function call node for the ctor.
				if (tp1 != nullptr) {
					// Make an expresison that references the var name as the
					// argument to the ctor.
					ep2 = makesnode(en_nacon, sp->name, sp->mangledName, sp->value.i);
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

void Declaration::DoInsert(SYM *sp, TABLE *table)
{
	dfs.printf("<DoInsert>");
	if ((sp->tp->type == bt_class)
		&& (sp->storage_class == sc_type || sp->storage_class == sc_typedef))
		; // Do nothing. The class was already entered in the tag table.
	else if ((sp->tp->type == bt_struct || sp->tp->type == bt_union)
		&& (sp->storage_class == sc_type && sp->storage_class != sc_typedef)
		&& sp->tp->sname->length() > 0)
		; // If there was no struct tag and this is a typedef, then it
			// still needs to be inserted into the table.
	else {
		dfs.printf("insert type: %d\n", sp->tp->type);
		dfs.printf("***Inserting:%s into %p\n", (char *)sp->name->c_str(), (char *)table);
		// Need to know the type before a name can be generated.
		if (sp->tp->type == bt_func || sp->tp->type == bt_ifunc)
			if (sp->fi)
				sp->mangledName = sp->BuildSignature(!sp->fi->IsPrototype);
		if (sp->parent && ((sp->tp->type == bt_func || sp->tp->type == bt_ifunc)
			|| (sp->tp->type == bt_pointer && (sp->tp->GetBtp()->type == bt_func || sp->tp->GetBtp()->type == bt_ifunc))))
		{
			//insState = 1;
			sp->fi->InsertMethod();
		}
		else {
			//insState = 2;
			table->insert(sp);
		}
	}
	dfs.printf("</DoInsert>\n");
}

SYM *Declaration::FindSymbol(SYM *sp, TABLE *table)
{
	SYM *sp1;
	Function *fn;

	dfs.printf("<FindSymbol>");
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
				sp1 = sp->fi->FindExactMatch(TABLE::matchno)->sym;
			}
		}
	}
	else
		sp1 = table->Find(*sp->name, false);
	dfs.printf("h");
	if (sp->tp) {
		dfs.printf("h1");
		if (sp->tp->type == bt_ifunc || sp->tp->type == bt_func) {
			dfs.printf("h2");
			fn = sp->fi->FindExactMatch(TABLE::matchno);
			if (fn)
				sp1 = fn->sym;
			else
				sp1 = nullptr;
			dfs.printf("i");
		}
	}
	else {
		dfs.printf("j");
		if (TABLE::matchno)
			sp1 = TABLE::match[TABLE::matchno - 1];
		else
			sp1 = nullptr;
	}
	dfs.printf("</FindSymbol>\n");
	return (sp1);
}

int Declaration::ParseFunction(TABLE* table, SYM* sp, e_sc al)
{
	SYM* sp1;
	bool flag;
	bool fn_doneinit = false;

	sp1 = FindSymbol(sp, table);
	dfs.printf("k");
	flag = false;
	if (sp1) {
		if (sp1->tp) {
			dfs.printf("l");
			flag = sp1->tp->type == bt_func;
		}
	}
	if (sp->tp->type == bt_ifunc && flag) {
		MakeFunction(sp, sp1);
		sp = sp1;
	}
	else {
		// Here the symbol wasn't found in the table.
		if (sp1 == nullptr)
			DoInsert(sp, table);
	}
	dfs.printf("J");
	if (needParseFunction) {
		needParseFunction = FALSE;
		currentFn = sp->fi;
		fn_doneinit = sp->fi->Parse();
		if (lastst == closepa) {
			NextToken();
			if (lastst == openpa) {
				int np, na;
				SYM* sp = (SYM*)allocSYM();
				NextToken();
				Function* fn = compiler.ff.MakeFunction(sp->number, sp, false);
				fn->BuildParameterList(&np, &na);
				if (lastst == closepa) {
					NextToken();
					while (lastst == kw_attribute)
						Declaration::ParseFunctionAttribute(fn);
				}
				needpunc(closepa, 52);
			}
		}
		/*
		fn = sp->fi->FindExactMatch(TABLE::matchno);
		if (fn) {
			if (!sp->fi->alloced)
				delete sp->fi;
			sp->fi = fn;
			insState = 0;
		}
		else {
			fn = MakeFunctiontion(sp->id);
			memcpy(fn, sp->fi, sizeof(Function));
			if (!sp->fi->alloced)
				delete sp->fi;
			sp->fi = fn;
			switch (insState) {
			case 1:	sp->fi->InsertMethod(); break;
			case 2: table->insert(sp); break;
			}
			insState = 3;
		}
		*/
		if (sp->tp->type != bt_pointer)
			return (1);
	}
	/*
	if (insState == 1 || insState == 2) {
		if (sp->tp->type == bt_ifunc || sp->tp->type == bt_func) {
			fn = sp->fi->FindExactMatch(TABLE::matchno);
			if (fn) {
				if (!sp->fi->alloced)
					delete sp->fi;
				sp->fi = fn;
			}
			else {
				fn = allocFunction(sp->id);
				memcpy(fn, sp->fi, sizeof(Function));
				if (!sp->fi->alloced)
					delete sp->fi;
				sp->fi = fn;
				switch (insState) {
				case 1:	sp->fi->InsertMethod(); break;
				case 2: table->insert(sp); break;
				}
				insState = 3;
			}
		}
		else if (insState==2)
			table->insert(sp);
	}
		*/
		//         if(sp->tp->type == bt_ifunc) { /* function body follows */
		//             ParseFunction(sp);
		//             return nbytes;
		//         }
	dfs.printf("K");
	if ((al == sc_global || al == sc_static || al == sc_thread) && !fn_doneinit &&
		sp->tp->type != bt_func && sp->tp->type != bt_ifunc && sp->storage_class != sc_typedef)
		doinit(sp);
	return (0);
}

void Declaration::FigureStructOffsets(int64_t bgn, SYM* sp)
{
	TABLE* pt;
	SYM* hd;
	int64_t nn;
	int64_t ps;
	int64_t bt;

	ps = bgn;
	for (hd = SYM::GetPtr(sp->tp->lst.head); hd; hd = hd->GetNextPtr()) {
		hd->value.i = ps;
		hd->tp->struct_offset = ps;
		if (hd->tp->IsStructType())
			FigureStructOffsets(ps, hd);
		if (hd->tp->bit_offset > 0)
			continue;
		if (sp->tp->type != bt_union)
			ps = ps + hd->tp->size;
	}
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
int Declaration::declare(SYM *parent,TABLE *table,e_sc al,int ilc,int ztype)
{ 
	SYM *sp;
	SYM *sp1;
	Function *fn;
	TYP *dhead, *tp1, *tp2;
	ENODE *ep1, *ep2;
	int op;
	int fn_doneinit = 0;
	bool flag;
	int parentBytes = 0;
	std::string name;
	std::string tmpstr;
  int nbytes;
	static int decl_level = 0;
	int itdef;
	int insState = 0;
	SYM* fp;

	itdef = isTypedef;
	decl_level++;
	dfs.printf("<declare>\n");
	nbytes = 0;
	insState = 0;
	dfs.printf("A");
	classname = new std::string("");
	sp = nullptr;
	sp1 = nullptr;
	if (ParseSpecifier(table, &sp, al)) {
		goto xit1;
	}
	ofs.write(" ");
	dfs.printf("B");
	dhead = head;
	for(;;) {
	  if (declid) delete declid;
		declid = nullptr;
		dfs.printf("b");
		bit_width = -1;
		sp = ParsePrefix(ztype==bt_union);
		if (dhead->type == bt_bit) {
			if (head->isArray) {
				head->size += 7;
				head->size /= 8;
			}
		}
		if (declid==nullptr)
			declid = new std::string("");
		if (al == sc_static) {
			tmpstr = GetNamespace();
			tmpstr += *declid;
			declid = new std::string(tmpstr);
		}
		// If a function declaration is taking place and just the type is
		// specified without a parameter name, assign an internal compiler
		// generated name.
		if (funcdecl>0 && funcdecl != 10 && declid->length()==0)
			AssignParameterName();

		dfs.printf("C");
		if (declid->length() > 0 || classname->length() != 0) {      // otherwise just struct tag...
			if (sp == nullptr) {
				sp = allocSYM();
				sp->name = declid;
				//if (funcdecl > 0)
				//	sp->fi = MakeFunction(sp->id, sp, isPascal, isInline);
			}
			SetType(sp);
			fp = FindSymbol(sp, table);
			// If storage has already been allocated, go back and blank it out.
			if (fp && fp->storage_pos != 0) {
				int cnt = 0;
				std::streampos cpos = ofs.tellp();
				std::streampos pos = fp->storage_pos;
				ofs.seekp(fp->storage_pos);
				while (pos < fp->storage_endpos && fp->storage_endpos > fp->storage_pos && cnt < 65536) {
					cnt++;
					ofs.write(" ");
				}
				ofs.seekp(cpos);
			}
			sp->storage_pos = ofs.tellp();
			if (funcdecl <= 0)
				sp->IsInline = isInline;
			sp->IsRegister = isRegister;
			isRegister = false;
			sp->IsAuto = isAuto;
			sp->IsParameter = parsingParameterList > 0;
			if (sp->parent < 0)// was nullptr
				sp->parent = parent->GetIndex();
			if (al == sc_member)
				sp->IsPrivate = isPrivate;
			else
				sp->IsPrivate = false;
			sp->SetName(classname->length() > 0 ? *classname : *declid);
			dfs.printf("D");
			if (classname) delete classname;
			classname = new std::string("");
			if (sp->tp->type == bt_func || sp->tp->type == bt_ifunc) {
				if (sp->fi)
					sp->fi->IsVirtual = isVirtual;
			}
			sp->storage_class = al;
			sp->isConst = isConst;
			if (al != sc_member && !parsingParameterList) {
				//							sp->isTypedef = isTypedef;
				if (isTypedef) {
					sp->storage_class = sc_typedef;
				}
				isTypedef = FALSE;
			}
			if (!sp->IsTypedef())
				nbytes = GenerateStorage(nbytes, al, ilc);
			dfs.printf("G");
			if ((sp->tp->type == bt_func) && sp->storage_class == sc_global)
				sp->storage_class = sc_external;

			// Set the (struct member) storage offset.
			sp->SetStorageOffset(head, nbytes, al, ilc, ztype);

			// Increase the storage allocation by the type size.
			nbytes = sp->AdjustNbytes(nbytes, al, ztype);

			dfs.printf("H");
			// For a class declaration there may not be any variables declared as
			// part of the declaration. In that case the symbol name is an empty
			// string. There's nothing to insert in the symbol table.
			name = *sp->name;
			//if (strcmp(name.c_str(), "__Skip") == 0)
			//	printf("hl");
//			if (sp->name->length() > 0) {
			if (sp->storage_class == sc_member)
				table->insert(sp);
			else
				if (ParseFunction(table, sp, al)) {
					sp->storage_endpos = ofs.tellp();
					return (nbytes);
				}
//			}
		}
		if (funcdecl>0) {
			if (lastst == closepa) {
				goto xit1;
			}
			if (lastst == comma) {
				break;
				NextToken();
				if (IsDeclBegin(lastst) == false)
					goto xit1;
				head = dhead;
				continue;
//				break;
			}
			if (lastst==semicolon) {
				break;
			}
		}
		else if (catchdecl==TRUE) {
			if (lastst==closepa)
				goto xit1;
		}

		// If semi-colon is encountered we are at the end of the declaration.
		else if (lastst == semicolon) {
			DoDeclarationEnd(sp, sp1);
			break;	// semicolon
		}

		// Handle an assignment
		else if (lastst == assign) {
			ParseAssign(sp);
			if (lastst==semicolon)
				break;
		}
		// See if there is a list of variable declarations
    needpunc(comma,24);
    if(IsDeclBegin(lastst) == false)
      break;
    head = dhead;
  }
  NextToken();
xit1:
	if (sp)
		sp->storage_endpos = ofs.tellp();
	if (decl_level == 1) {
		if (sp && sp->tp->IsStructType()) {
			TYP* tp;
			tp = sp->tp->Copy(sp->tp);
			sp->tp = tp;
			FigureStructOffsets(0,sp);
		}
	}
	dfs.printf("</declare>\n");
	isTypedef = itdef;
	decl_level--;
  return (nbytes);
}

void GlobalDeclaration::Parse()
{
	dfs.puts("<ParseGlobalDecl>\n");
	isPascal = defaultcc==1;
	isInline = false;
	isLeaf = false;
	head = tail = nullptr;
	for(;;) {
		lc_auto = 0;
		bool notVal = false;
		isFuncPtr = false;
		currentClass = nullptr;
		currentFn = nullptr;
		currentStmt = nullptr;
		isFuncBody = false;
		worstAlignment = 0;
		funcdecl = 0;

		switch(lastst) {
		case kw_leaf:
			NextToken();
			isLeaf = true;
			break;
		case kw_pascal:
		  NextToken();
		  isPascal = TRUE;
		  break;
		case kw_cdecl:
			NextToken();
			isPascal = FALSE;
			break;
		case kw_inline:
		  NextToken();
		  isInline = true;
		  break;
		case id:
			lc_static += declare(NULL, &gsyms[0], sc_global, lc_static, bt_struct);
			isInline = false;
			break;
		case ellipsis:
		case kw_kernel:
		case kw_interrupt:
        case kw_task:
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
				case kw_enum: case kw_void: case kw_bit:
				case kw_float: case kw_double: case kw_float128: case kw_posit:
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
j1:
        NextToken();
				if (lastst==kw_pascal) {
					isPascal = TRUE;
					goto j1;
				}
				if (lastst == kw_leaf) {
					isLeaf = TRUE;
					goto j1;
				}
				if (lastst==kw_kernel) {
					isKernel = TRUE;
					goto j1;
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
				else if (strcmp(lastid, "___cdecl") == 0) {
					NextToken();
					defaultcc = 0;
				}
				else if (strcmp(lastid, "_pascal") == 0) {
					NextToken();
					defaultcc = 1;
				}
				else if (strcmp(lastid, "_gp") == 0) {
					NextToken();
					use_gp = notVal;
				}
      }
	  else if (lastst==kw_short) {
		  NextToken();
		  if (lastst==id) {
			  if (strcmp(lastid,"_pointers")==0)
				  sizeOfPtr = 4;
		  }
	  }
	  else if (lastst==kw_long) {
		  NextToken();
		  if (lastst==id) {
			  if (strcmp(lastid,"_pointers")==0)
				  sizeOfPtr = 8;
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

ENODE *AutoDeclaration::Parse(SYM *parent, TABLE *ssyms)
{
	SYM *sp;
	ENODE* ep1;

//	printf("Enter ParseAutoDecls\r\n");
    for(;;) {
		funcdecl = 0;
		isFuncPtr = false;
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
		case kw_bit:
		case kw_int8: case kw_int16: case kw_int32: case kw_int64: case kw_int40: case kw_int80:
		case kw_byte: case kw_char: case kw_int: case kw_short: case kw_unsigned: case kw_signed:
        case kw_long: case kw_struct: case kw_union: case kw_class:
        case kw_enum: case kw_void:
				case kw_float: case kw_double: case kw_float128: case kw_posit:
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
	ep1 = nullptr;
	for (sp = SYM::GetPtr(ssyms->GetHead()); sp; sp = sp->GetNextPtr()) {
		if (sp->initexp) {
			ep1 = makenode(en_list, ep1, nullptr);
			ep1->p[3] = sp->initexp;
		}
	}
	return (ep1);
//	printf("Leave ParseAutoDecls\r\n");
}

int ParameterDeclaration::Parse(int fd)
{
	int ofd;
  int opascal;
	int oisInline;

	dfs.puts("<ParseParmDecls>\n");
	ofd = funcdecl;
	opascal = isPascal;
	oisInline = isInline;
	isPascal = defaultcc==1;
	funcdecl = fd;
	parsingParameterList++;
	nparms = 0;
	for(;;) {
		worstAlignment = 0;
		isFuncPtr = false;
		isAuto = false;
		isRegister = false;
		isInline = false;
		missingArgumentName = FALSE;
		dfs.printf("A(%d)",lastst);
j1:
		switch(lastst) {
		case kw_auto:
			NextToken();
			isAuto = true;
			goto j1;
		case kw_pascal:
			NextToken();
		  isPascal = TRUE;
		  goto j1;
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
		case kw_const:
		case ellipsis:
		case kw_inline:
		case kw_volatile:
        case kw_exception:
		case kw_int8: case kw_int16: case kw_int32: case kw_int64: case kw_int40: case kw_int80:
		case kw_byte: case kw_char: case kw_int: case kw_short: case kw_unsigned: case kw_signed:
    case kw_long: case kw_struct: case kw_union: case kw_class:
		case kw_enum: case kw_void: case kw_bit:
		case kw_float: case kw_double: case kw_float128: case kw_posit:
		case kw_vector: case kw_vector_mask:
dfs.printf("C");
			declare(NULL,&currentFn->params,sc_auto,0,bt_struct);
			isAuto = false;
	    break;
		case id:
			declare(NULL, &currentFn->params, sc_auto, 0, bt_struct);
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
		// A list of externals could be following a function prototype. This
		// could be confused with a parameter list.
    case kw_extern:
//					push_token();
//					goto xit;
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
			goto j1;
    default:
			goto xit;
		}
		dfs.printf("E");
		if (lastst == comma)
			NextToken();
	}
xit:
	parsingParameterList--;
	funcdecl = ofd;
	isPascal = opascal;
	isInline = oisInline;
	dfs.printf("</ParseParmDecls>\n");
	return (nparms);
}

GlobalDeclaration *GlobalDeclaration::Make()
{
  GlobalDeclaration *p = (GlobalDeclaration *)allocx(sizeof(GlobalDeclaration));
  return p;
}

void compile()
{
}

