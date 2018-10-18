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

extern int64_t initbyte();
extern int64_t initchar();
extern int64_t initshort();
extern int64_t initlong();
extern int64_t initquad();
extern int64_t initfloat();
extern int64_t inittriple();
int64_t InitializePointer(TYP *);
extern short int brace_level;
TYP *typ_vector[100];
short int typ_sp = 0;

void push_typ(TYP *tp)
{
	if (typ_sp < 99) {
		typ_vector[typ_sp] = tp;
		typ_sp++;
	}
}

TYP *pop_typ()
{
	if (typ_sp >= 0) {
		typ_sp--;
		return (typ_vector[typ_sp]);
	}
}

bool TYP::IsScalar()
{
	return
		type == bt_byte ||
		type == bt_char ||
		type == bt_short ||
		type == bt_long ||
		type == bt_ubyte ||
		type == bt_uchar ||
		type == bt_ushort ||
		type == bt_ulong ||
		type == bt_enum ||
		type == bt_exception ||
		type == bt_unsigned;
}


TYP *TYP::GetBtp() {
    if (btp==0)
      return nullptr;
    return &compiler.typeTable[btp];
};
TYP *TYP::GetPtr(int n) {
  if (n==0)
    return nullptr;
  return &compiler.typeTable[n];
};
int TYP::GetIndex() { return this - &compiler.typeTable[0]; };

TYP *TYP::Copy(TYP *src)
{
	TYP *dst = nullptr;
 
  dfs.printf("<TYP__Copy>\n");
	if (src) {
		dst = allocTYP();
//		if (dst==nullptr)
//			throw gcnew C64::C64Exception();
		memcpy(dst,src,sizeof(TYP));
		dfs.printf("A");
		if (src->btp && src->GetBtp()) {
  		dfs.printf("B");
			dst->btp = Copy(src->GetBtp())->GetIndex();
		}
		dfs.printf("C");
		// We want to keep any base type indicator so Clear() isn't called.
		dst->lst.head = 0;
		dst->lst.tail = 0;
		dst->sname = new std::string(*src->sname);
		dfs.printf("D");
		TABLE::CopySymbolTable(&dst->lst,&src->lst);
	}
  dfs.printf("</TYP__Copy>\n");
	return dst;
}

TYP *TYP::Make(int bt, int siz)
{
	TYP *tp;
	dfs.puts("<TYP__Make>\n");
	tp = allocTYP();
	if (tp == nullptr)
		return nullptr;
	tp->val_flag = 0;
	tp->isArray = FALSE;
	tp->size = siz;
	tp->type = (e_bt)bt;
	tp->typeno = bt;
	tp->precision = siz * 8;
	if (bt == bt_pointer)
		tp->isUnsigned = TRUE;
	dfs.puts("</TYP__Make>\n");
	return tp;
}

// Given just a type number return the size

int TYP::GetSize(int num)
{
  if (num == 0)
    return (0);
  return (compiler.typeTable[num].size);
}

// Basic type is one of the built in types supported by the compiler.
// Returns the basic type number for the type. The basic type number does
// not include complex types like struct, union, or class. For a struct,
// union, or class one of bt_struct, bt_union or bt_class is returned.

int TYP::GetBasicType(int num)
{
  if (num==0)
    return 0;
  return compiler.typeTable[num].type;
}

int TYP::GetHash()
{
	int n;
	TYP *p, *p1;

	n = 0;
	p = this;
	if (p==nullptr)
		throw new C64PException(ERR_NULLPOINTER,2);
	do {
		if (p->type==bt_pointer)
			n+=20000;
		p1 = p;
		p = p->GetBtp();
	} while (p);
	n += p1->typeno;
	return n;
}

int TYP::GetElementSize()
{
	int n;
	TYP *p, *p1;

	n = 0;
	p = this;
	do {
		p1 = p;
		p = p->GetBtp();
	} while (p);
	switch(p1->type) {
	case bt_byte:
	case bt_ubyte:
		return 1;
	case bt_char:
	case bt_uchar:
		return 2;
	case bt_short:
	case bt_ushort:
		return 4;
	case bt_long:
	case bt_ulong:
	case bt_pointer:
		return 8;
	case bt_float:
	case bt_double:
		return 8;
	case bt_struct:
	case bt_class:
		return p1->size;
	default:
		return 8;
	}
	return n;
}

void TYP::put_ty()
{
	switch(type) {
	case bt_exception:
            lfs.printf("Exception");
            break;
	case bt_byte:
            lfs.printf("Byte");
            break;
	case bt_ubyte:
            lfs.printf("Unsigned Byte");
            break;
    case bt_char:
            lfs.printf("Char");
            break;
    case bt_short:
            lfs.printf("Short");
            break;
    case bt_enum:
            lfs.printf("enum ");
            goto ucont;
    case bt_long:
            lfs.printf("Long");
            break;
    case bt_unsigned:
            lfs.printf("unsigned long");
            break;
    case bt_float:
            lfs.printf("Float");
            break;
    case bt_double:
            lfs.printf("Double");
            break;
    case bt_pointer:
            if( val_flag == 0)
                    lfs.printf("Pointer to ");
            else
                    lfs.printf("Array of ");
            GetBtp()->put_ty();
            break;
    case bt_class:
            lfs.printf("class ");
            goto ucont;
    case bt_union:
            lfs.printf("union ");
            goto ucont;
    case bt_struct:
            lfs.printf("struct ");
ucont:                  if(sname->length() == 0)
                    lfs.printf("<no name> ");
            else
                    lfs.printf("%s ",(char *)sname->c_str());
            break;
    case bt_ifunc:
    case bt_func:
            lfs.printf("Function returning ");
            GetBtp()->put_ty();
            break;
    }
}

bool TYP::IsSameType(TYP *a, TYP *b, bool exact)
{
	if (a == b)
		return (true);

	switch (a->type) {

	case bt_float:
		if (b->type == bt_float)
			return (true);
		if (b->type == bt_double)
			return (true);
		return (false);

	case bt_double:
		if (b->type == bt_float)
			return (true);
		if (b->type == bt_double)
			return (true);
		return (false);

	case bt_long:
		if (b->type == bt_long)
			return (true);
		if (!exact) {
			if (b->type == bt_ulong)
				return (true);
			if (b->type == bt_short)
				return (true);
			if (b->type == bt_ushort)
				return (true);
			if (b->type == bt_char)
				return (true);
			if (b->type == bt_uchar)
				return (true);
			if (b->type == bt_byte)
				return (true);
			if (b->type == bt_ubyte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		return (false);

	case bt_ulong:
		if (b->type == bt_ulong)
			return (true);
		if (!exact) {
			if (b->type == bt_long)
				return (true);
			if (b->type == bt_short)
				return (true);
			if (b->type == bt_ushort)
				return (true);
			if (b->type == bt_char)
				return (true);
			if (b->type == bt_uchar)
				return (true);
			if (b->type == bt_byte)
				return (true);
			if (b->type == bt_ubyte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		return (false);

	case bt_short:
		if (b->type == bt_short)
			return (true);
		if (!exact) {
			if (b->type == bt_long)
				return (true);
			if (b->type == bt_ulong)
				return (true);
			if (b->type == bt_ushort)
				return (true);
			if (b->type == bt_char)
				return (true);
			if (b->type == bt_uchar)
				return (true);
			if (b->type == bt_byte)
				return (true);
			if (b->type == bt_ubyte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		return (false);

	case bt_ushort:
		if (b->type == bt_ushort)
			return (true);
		if (!exact) {
			if (b->type == bt_long)
				return (true);
			if (b->type == bt_ulong)
				return (true);
			if (b->type == bt_short)
				return (true);
			if (b->type == bt_char)
				return (true);
			if (b->type == bt_uchar)
				return (true);
			if (b->type == bt_byte)
				return (true);
			if (b->type == bt_ubyte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		return (false);

	case bt_uchar:
		if (b->type == bt_uchar)
			return (true);
		if (!exact) {
			if (b->type == bt_long)
				return (true);
			if (b->type == bt_ulong)
				return (true);
			if (b->type == bt_short)
				return (true);
			if (b->type == bt_ushort)
				return (true);
			if (b->type == bt_char)
				return (true);
			if (b->type == bt_byte)
				return (true);
			if (b->type == bt_ubyte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		return (false);

	case bt_char:
		if (b->type == bt_char)
			return (true);
		if (!exact) {
			if (b->type == bt_long)
				return (true);
			if (b->type == bt_ulong)
				return (true);
			if (b->type == bt_short)
				return (true);
			if (b->type == bt_ushort)
				return (true);
			if (b->type == bt_uchar)
				return (true);
			if (b->type == bt_byte)
				return (true);
			if (b->type == bt_ubyte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		return (false);

	case bt_byte:
		if (b->type == bt_byte)
			return (true);
		if (!exact) {
			if (b->type == bt_long)
				return (true);
			if (b->type == bt_ulong)
				return (true);
			if (b->type == bt_short)
				return (true);
			if (b->type == bt_ushort)
				return (true);
			if (b->type == bt_uchar)
				return (true);
			if (b->type == bt_char)
				return (true);
			if (b->type == bt_ubyte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		return (false);

	case bt_ubyte:
		if (b->type == bt_ubyte)
			return (true);
		if (!exact) {
			if (b->type == bt_long)
				return (true);
			if (b->type == bt_ulong)
				return (true);
			if (b->type == bt_short)
				return (true);
			if (b->type == bt_ushort)
				return (true);
			if (b->type == bt_uchar)
				return (true);
			if (b->type == bt_char)
				return (true);
			if (b->type == bt_byte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		return (false);

	case bt_pointer:
		if (a->val_flag && b->type == bt_struct) {
			return (true);
		}
		if (a->type != b->type)
			return (false);
		if (a->GetBtp() == b->GetBtp())
			return (true);
		if (a->GetBtp() && b->GetBtp())
			return (TYP::IsSameType(a->GetBtp(), b->GetBtp(), exact));
		return (false);

	case bt_struct:
	case bt_union:
	case bt_class:
		if (a->type != b->type)
			return (false);
		if (a->GetBtp() == b->GetBtp() || !exact)
			return (true);
		if (a->GetBtp() && b->GetBtp())
			return (TYP::IsSameType(a->GetBtp(), b->GetBtp(), exact));
		return (false);

	case bt_enum:
		if (a->typeno == b->typeno)
			return (true);
		if (!exact) {
			if (b->type == bt_long
				|| b->type == bt_ulong
				|| b->type == bt_short
				|| b->type == bt_ushort
				|| b->type == bt_char
				|| b->type == bt_uchar
				|| b->type == bt_enum
				)
				return (true);
		}
		return (false);
	}
	return (false);
}

// Initialize the type. Unions can't be initialized.

int64_t TYP::Initialize(TYP *tp2)
{
	int64_t nbytes;
	TYP *tp;
	int base, nn;
	int64_t sizes[100];

	for (base = typ_sp-1; base >= 0; base--) {
		if (typ_vector[base]->isArray)
			break;
		if (typ_vector[base]->IsStructType())
			break;
	}
	sizes[0] = typ_vector[min(base + 1,typ_sp-1)]->size * typ_vector[0]->numele;
	for (nn = 1; nn <= base; nn++)
		sizes[nn] = sizes[nn - 1] * typ_vector[nn]->numele;

j1:
	while (lastst == begin) {
		brace_level++;
		NextToken();
	}
	if (tp2)
		tp = tp2;
	else {
		tp = typ_vector[max(base-brace_level,0)];
	}
	do {
		switch (tp->type) {
		case bt_ubyte:
		case bt_byte:
			nbytes = initbyte();
			break;
		case bt_uchar:
		case bt_char:
		case bt_enum:
			nbytes = initchar();
			break;
		case bt_ushort:
		case bt_short:
			nbytes = initshort();
			break;
		case bt_pointer:
			if (tp->val_flag)
				nbytes = tp->InitializeArray(sizes[max(base-brace_level,0)]);
			else
				nbytes = InitializePointer(tp);
			break;
		case bt_exception:
		case bt_ulong:
		case bt_long:
			nbytes = initlong();
			break;
		case bt_struct:
			nbytes = tp->InitializeStruct();
			break;
		case bt_union:
			nbytes = tp->InitializeUnion();
			break;
		case bt_quad:
			nbytes = initquad();
			break;
		case bt_float:
		case bt_double:
			nbytes = initfloat();
			break;
		case bt_triple:
			nbytes = inittriple();
			break;
		default:
			error(ERR_NOINIT);
			nbytes = 0;
		}
		//if (brace_level > 0) {
		//	if (typ_vector[brace_level - 1]->val_flag) {

		//	}
		//}
		if (tp2 != nullptr)
			return (nbytes);
		if (lastst != comma)
			break;
		NextToken();
		if (lastst == end)
			break;
	} while (1);
j2:
	while (lastst == end) {
		brace_level--;
		NextToken();
	}
	if (brace_level != 0) {
		if (lastst == comma) {
			NextToken();
			if (lastst == end)
				goto j2;
			goto j1;
		}
	}
	return (nbytes);
}

int64_t TYP::InitializeArray(int64_t maxsz)
{
	int64_t nbytes;
	char *p;
	char *str;
	int64_t sz;

	nbytes = 0;
//	if (lastst == begin)
	{
//		NextToken();               /* skip past the brace */
		while (lastst != end) {
			// Allow char array initialization like { "something", "somethingelse" }
			if (lastst == sconst && (GetBtp()->type == bt_char || GetBtp()->type == bt_uchar)) {
				str = GetStrConst();
				nbytes = strlen(str) * 2 + 2;
				p = str;
				while (*p)
					GenerateChar(*p++);
				GenerateChar(0);
				free(str);
			}
			else
				nbytes += GetBtp()->Initialize(GetBtp());
			if (lastst == comma)
				NextToken();
			else if (lastst == end) {
				//brace_level--;
				break;
			}
			else if (lastst == semicolon)
				break;
			else
				error(ERR_PUNCT);
		}
//		NextToken();               /* skip closing brace */
	}
	//else if (lastst == sconst && (GetBtp()->type == bt_char || GetBtp()->type == bt_uchar)) {
	//	str = GetStrConst();
	//	nbytes = strlen(str) * 2 + 2;
	//	p = str;
	//	while (*p)
	//		GenerateChar(*p++);
	//	GenerateChar(0);
	//	free(str);
	//}
	//else if (lastst != semicolon)
	//	error(ERR_ILLINIT);
	if (nbytes < maxsz) {
		genstorage(maxsz - nbytes);
		nbytes = maxsz;
	}
	else if (maxsz != 0 && nbytes > maxsz)
		error(ERR_INITSIZE);    /* too many initializers */
	return (nbytes);
}

int64_t TYP::InitializeStruct()
{
	SYM *sp;
	int64_t nbytes;
	int count;

//	needpunc(begin, 25);
	nbytes = 0;
	sp = sp->GetPtr(lst.GetHead());      /* start at top of symbol table */
	count = 0;
	while (sp != 0) {
		while (nbytes < sp->value.i) {     /* align properly */
										   //                    nbytes += GenerateByte(0);
			GenerateByte(0);
			nbytes++;
		}
		nbytes += sp->tp->Initialize(sp->tp);
		if (lastst == comma)
			NextToken();
		else if (lastst == end || lastst==semicolon) {
			break;
		}
		else
			error(ERR_PUNCT);
		sp = sp->GetNextPtr();
		count++;
	}
	if (sp == nullptr) {
		if (lastst != end && lastst != semicolon) {
			error(ERR_INITSIZE);
			while (lastst != end && lastst != semicolon && lastst != end)
				NextToken();
		}
	}
	if (nbytes < size)
		genstorage(size - nbytes);
//	needpunc(end, 26);
	return (size);
}

int64_t TYP::GenerateT(TYP *tp, ENODE *node)
{
	int nbytes;
	int64_t val;
	TYP *tp2;
	int64_t n, nele;
	ENODE *nd;

	switch (tp->type) {
	case bt_byte:
		val = node->i;
		nbytes = 1; GenerateByte(val);
		break;
	case bt_ubyte:
		val = node->i;
		nbytes = 1;
		GenerateByte(val);
		break;
	case bt_char:
		val = node->i;
		nbytes = 2; GenerateChar(val); break;
	case bt_uchar:
		val = node->i;
		nbytes = 2; GenerateChar(val); break;
	case bt_short:
		val = node->i;
		nbytes = 4; GenerateHalf(val); break;
	case bt_ushort:
		val = node->i;
		nbytes = 4; GenerateHalf(val); break;
	case bt_long:
		val = node->i;
		nbytes = 8; GenerateLong(val); break;
	case bt_ulong:
		val = node->i;
		nbytes = 8; GenerateLong(val); break;
	case bt_float:
		nbytes = 8; GenerateFloat((Float128 *)&node->f128); break;
	case bt_double:
		nbytes = 8; GenerateFloat((Float128 *)&node->f128); break;
	case bt_quad:
		nbytes = 16; GenerateQuad((Float128 *)&node->f128); break;
	case bt_pointer:
		if (tp->val_flag) {
			nbytes = 0;
			nele = tp->numele;
			tp = tp->GetBtp();
			nd = node->p[0]->p[2];
			for (n = 0; n < nele; n++) {
				if (nd == nullptr)
					break;
				nbytes += GenerateT(tp,nd);
				nd = nd->p[2];
			}
		}
		else {
			val = node->i;
			nbytes = sizeOfPtr;
		}
		//case bt_struct:	nbytes = InitializeStruct(); break;
	}
	return (nbytes);
}

int64_t TYP::InitializeUnion()
{
	SYM *sp, *osp;
	int64_t nbytes;
	int64_t val;
	ENODE *node = nullptr;
	bool found = false;
	TYP *tp;
	int count;

	nbytes = 0;
	val = GetConstExpression(&node);
	if (node == nullptr)	// syntax error in GetConstExpression()
		return (0);
	sp = sp->GetPtr(lst.GetHead());      /* start at top of symbol table */
	osp = sp;
	count = 0;
	while (sp != 0) {
		// Detect array of values
		if (sp->tp->type == bt_pointer && sp->tp->val_flag) {
			tp = sp->tp->GetBtp();
			if (IsSameType(tp, node->tp, false))
			{
				nbytes = node->esize;
				nbytes = GenerateT(tp, node);
				found = true;
				while (lastst == comma && count < sp->tp->numele) {
					NextToken();
					val = GetConstExpression(&node);
					nbytes = node->esize;
					nbytes = GenerateT(tp, node);
					count++;
				}
				if (count >= sp->tp->numele)
					error(ERR_INITSIZE);
				goto j1;
			}
		}
		if (IsSameType(sp->tp, node->tp, false)) {
			nbytes = node->esize;
			nbytes = GenerateT(sp->tp, node);
			found = true;
			break;
		}
		sp = sp->GetNextPtr();
		if (sp == osp)
			break;
	}
j1:
	if (!found)
		error(ERR_INIT_UNION);
	if (lastst != semicolon && lastst != comma && lastst != end)
		error(ERR_PUNCT);
	if (nbytes < size)
		genstorage(size - nbytes);
	return (size);
}


// GC support

bool TYP::FindPointerInStruct()
{
	SYM *sp;

	sp = sp->GetPtr(lst.GetHead());      // start at top of symbol table
	while (sp != 0) {
		if (sp->tp->FindPointer())
			return (true);
		sp = sp->GetNextPtr();
	}
	return (false);
}

bool TYP::FindPointer()
{
	switch (type) {
	case bt_pointer: return (val_flag == FALSE);	// array ?
	case bt_struct: return (FindPointerInStruct());
	case bt_union: return (FindPointerInStruct());
	case bt_class: return (FindPointerInStruct());
	}
	return (false);
}


// Return whether or not the type might be able to be skipped over by the GC.

bool TYP::IsSkippable()
{
	switch (type) {
	case bt_struct:	return(true);
	case bt_union: return(true);
	case bt_class: return(true);
	case bt_pointer:
		if (val_flag == TRUE)
			return (true);
		return(false);
	}
	// For now primitive types are not skipped over. They would need to be 
	// grouped for skipping.
	return (false);
}

// The problem is there are two trees of information. The LHS and the RHS.
// The RHS is a tree of nodes containing expressions and data to load.
// The nodes in the RHS have to be matched up against the structure elements
// of the target LHS.

// This little bit of code is dead code. But it might be useful to match
// the expression trees at some point.

ENODE *TYP::BuildEnodeTree()
{
	ENODE *ep1, *ep2, *ep3;
	SYM *thead, *first;

	first = thead = SYM::GetPtr(lst.GetHead());
	ep1 = ep2 = nullptr;
	while (thead) {
		if (thead->tp->IsStructType()) {
			ep3 = thead->tp->BuildEnodeTree();
		}
		else
			ep3 = nullptr;
		ep1 = makenode(en_void, ep1, ep2);
		ep1->SetType(thead->tp);
		ep1->p[2] = ep3;
		thead = SYM::GetPtr(thead->next);
	}
	return (ep1);
}


// Get the natural alignment for a given type.

int TYP::Alignment()
{
	//printf("DIAG: type NULL in alignment()\r\n");
	if (this == NULL)
		return AL_BYTE;
	switch (type) {
	case bt_byte:	case bt_ubyte:	return AL_BYTE;
	case bt_char:   case bt_uchar:  return AL_CHAR;
	case bt_short:  case bt_ushort: return AL_SHORT;
	case bt_long:   case bt_ulong:  return AL_LONG;
	case bt_enum:           return AL_CHAR;
	case bt_pointer:
		if (val_flag)
			return (GetBtp()->Alignment());
		else
			return (sizeOfPtr);//isShort ? AL_SHORT : AL_POINTER);
	case bt_float:          return AL_FLOAT;
	case bt_double:         return AL_DOUBLE;
	case bt_triple:         return AL_TRIPLE;
	case bt_class:
	case bt_struct:
	case bt_union:
		return (alignment) ? alignment : AL_STRUCT;
	default:                return AL_CHAR;
	}
}


// Figure out the worst alignment required.

int TYP::walignment()
{
	SYM *sp;

	//printf("DIAG: type NULL in alignment()\r\n");
	if (this == NULL)
		return imax(AL_BYTE, worstAlignment);
	switch (type) {
	case bt_byte:	case bt_ubyte:		return imax(AL_BYTE, worstAlignment);
	case bt_char:   case bt_uchar:     return imax(AL_CHAR, worstAlignment);
	case bt_short:  case bt_ushort:    return imax(AL_SHORT, worstAlignment);
	case bt_long:   case bt_ulong:     return imax(AL_LONG, worstAlignment);
	case bt_enum:           return imax(AL_CHAR, worstAlignment);
	case bt_pointer:
		if (val_flag)
			return imax(GetBtp()->Alignment(), worstAlignment);
		else {
			return (imax(sizeOfPtr, worstAlignment));
			//				return (imax(AL_POINTER,worstAlignment));
		}
	case bt_float:          return imax(AL_FLOAT, worstAlignment);
	case bt_double:         return imax(AL_DOUBLE, worstAlignment);
	case bt_triple:         return imax(AL_TRIPLE, worstAlignment);
	case bt_class:
	case bt_struct:
	case bt_union:
		sp = (SYM *)sp->GetPtr(lst.GetHead());
		worstAlignment = alignment;
		while (sp != NULL) {
			if (sp->tp && sp->tp->alignment) {
				worstAlignment = imax(worstAlignment, sp->tp->alignment);
			}
			else
				worstAlignment = imax(worstAlignment, sp->tp->walignment());
			sp = sp->GetNextPtr();
		}
		return (worstAlignment);
	default:                return (imax(AL_CHAR, worstAlignment));
	}
}


int TYP::roundAlignment()
{
	worstAlignment = 0;
	if (type == bt_struct || type == bt_union || type == bt_class) {
		return walignment();
	}
	return Alignment();
}


// Round the size of the type up according to the worst alignment.

int TYP::roundSize()
{
	int sz;
	int wa;

	worstAlignment = 0;
	if (type == bt_struct || type == bt_union || type == bt_class) {
		wa = walignment();
		sz = size;
		if (sz == 0)
			return (0);
		if (sz % wa)
			sz += (wa - (sz % wa));
		//while (sz % wa)
		//	sz++;
		return (sz);
	}
	//	return ((tp->precision+7)/8);
	return (size);
}


