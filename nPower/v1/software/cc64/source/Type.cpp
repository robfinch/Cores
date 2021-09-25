// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2021  Robert Finch, Waterloo
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
	return (nullptr);
}

bool TYP::IsScalar()
{
	return
		type == bt_byte ||
		type == bt_ichar ||
		type == bt_char ||
		type == bt_short ||
		type == bt_long ||
		type == bt_ubyte ||
		type == bt_iuchar ||
		type == bt_uchar ||
		type == bt_ushort ||
		type == bt_ulong ||
		type == bt_enum ||
		type == bt_exception ||
		type == bt_unsigned;
}


TYP *TYP::GetBtp() {
	if (this == nullptr)
		return (nullptr);
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
		if (src->btp && src->btpp) {
  		dfs.printf("B");
			dst->btpp = Copy(src->btpp);
			dst->btp = dst->btpp->GetIndex();// Copy(src->btpp)->GetIndex();
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
	return (dst);
}

TYP *TYP::Make(int bt, int64_t siz)
{
	TYP *tp;
	dfs.puts("<TYP__Make>\n");
	tp = allocTYP();
	if (tp == nullptr)
		return (nullptr);
	tp->val_flag = 0;
	tp->isArray = FALSE;
	tp->size = siz;
	tp->type = bt;
	tp->typeno = bt;
	tp->precision = siz * 8;
	if (bt == bt_pointer)
		tp->isUnsigned = TRUE;
	dfs.puts("</TYP__Make>\n");
	return (tp);
}

// Given just a type number return the size

int64_t TYP::GetSize(int num)
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
			n+=8192;//20000;
		p1 = p;
		p = p->btpp;
	} while (p);
	n += p1->typeno;
	return (n);
}

int64_t TYP::GetElementSize()
{
	int n;
	TYP *p, *p1;

	n = 0;
	p = this;
	do {
		p1 = p;
		p = p->btpp;
	} while (p);
	switch(p1->type) {
	case bt_byte:
	case bt_ubyte:
		return 1;
	case bt_ichar:
	case bt_iuchar:
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
	case bt_posit:
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
	case bt_uchar:
	case bt_ichar:
	case bt_iuchar:
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
		case bt_posit:
			lfs.printf("Posit");
			break;
		case bt_pointer:
            if( val_flag == 0)
                    lfs.printf("Pointer to ");
            else
                    lfs.printf("Array of ");
            btpp->put_ty();
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
            btpp->put_ty();
            break;
    }
}

bool TYP::IsSameType(TYP *a, TYP *b, bool exact)
{
	if (a == b)
		return (true);
	if (a == nullptr || b == nullptr) {
		if (!exact)
			return (true);
		else
			return (false);
	}

	if (a->type == b->type && a->typeno == b->typeno)
		return (true);

	switch (a->type) {

	// None will match any type.
	// For argument lists where the argument is not specified so a default is
	// assumed.
	case bt_none:
		return (true);

	case bt_float:
		if (b->type == bt_float)
			return (true);
		if (b->type == bt_double)
			return (true);
		goto chk;

	case bt_double:
		if (b->type == bt_float)
			return (true);
		if (b->type == bt_double)
			return (true);
		goto chk;

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
			if (b->type == bt_ichar)
				return (true);
			if (b->type == bt_iuchar)
				return (true);
			if (b->type == bt_byte)
				return (true);
			if (b->type == bt_ubyte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		goto chk;

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
			if (b->type == bt_ichar)
				return (true);
			if (b->type == bt_iuchar)
				return (true);
			if (b->type == bt_byte)
				return (true);
			if (b->type == bt_ubyte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		goto chk;

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
			if (b->type == bt_ichar)
				return (true);
			if (b->type == bt_iuchar)
				return (true);
			if (b->type == bt_byte)
				return (true);
			if (b->type == bt_ubyte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		goto chk;

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
			if (b->type == bt_ichar)
				return (true);
			if (b->type == bt_iuchar)
				return (true);
			if (b->type == bt_byte)
				return (true);
			if (b->type == bt_ubyte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		goto chk;

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
			if (b->type == bt_ichar)
				return (true);
			if (b->type == bt_iuchar)
				return (true);
			if (b->type == bt_byte)
				return (true);
			if (b->type == bt_ubyte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		goto chk;

	case bt_iuchar:
		if (b->type == bt_iuchar)
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
			if (b->type == bt_ichar)
				return (true);
			if (b->type == bt_byte)
				return (true);
			if (b->type == bt_ubyte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		goto chk;

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
			if (b->type == bt_iuchar)
				return (true);
			if (b->type == bt_byte)
				return (true);
			if (b->type == bt_ubyte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		goto chk;

	case bt_ichar:
		if (b->type == bt_ichar)
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
			if (b->type == bt_uchar)
				return (true);
			if (b->type == bt_iuchar)
				return (true);
			if (b->type == bt_byte)
				return (true);
			if (b->type == bt_ubyte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		goto chk;

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
			if (b->type == bt_iuchar)
				return (true);
			if (b->type == bt_ichar)
				return (true);
			if (b->type == bt_ubyte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		goto chk;

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
			if (b->type == bt_iuchar)
				return (true);
			if (b->type == bt_ichar)
				return (true);
			if (b->type == bt_byte)
				return (true);
			if (b->type == bt_enum)
				return (true);
		}
		goto chk;

	case bt_pointer:
		if (a->val_flag && b->type == bt_struct) {
			return (true);
		}
		if (a->type != b->type)
			goto chk;
		if (a->btpp == b->btpp)
			return (true);
		if (a->btpp && b->btpp)
			return (TYP::IsSameType(a->btpp, b->btpp, exact));
		goto chk;

	case bt_struct:
	case bt_union:
	case bt_class:
		if (a->type != b->type)
			goto chk;
		if (a->btpp == b->btpp || !exact)
			return (true);
		if (a->btpp && b->btpp)
			return (TYP::IsSameType(a->btpp, b->btpp, exact));
		goto chk;

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
				|| b->type == bt_ichar
				|| b->type == bt_iuchar
				|| b->type == bt_enum
				)
				return (true);
		}
	}
chk:
	if (b->type == bt_union || a->type == bt_union)
		return (IsSameUnionType(a, b));
	if (a->type == bt_struct && b->type == bt_struct)
		return (IsSameStructType(a, b));
	return (false);
}

// Do we really want to compare all the fields?
// As long as the sizes are the same there should be no issues with
// memory overwrites.

bool TYP::IsSameStructType(TYP* a, TYP* b)
{
	SYM* spA, * spB;
	int64_t maxa = 0, maxb = 0;

	return (a->size == b->size);
	spA = spA->GetPtr(a->lst.GetHead());      /* start at top of symbol table */
	while (spA != nullptr) {
		maxa = maxa + spA->tp->size;
		spA = spA->GetNextPtr();
	}
	spB = spB->GetPtr(b->lst.GetHead());      /* start at top of symbol table */
	while (spB != nullptr) {
		maxb = maxb + spB->tp->size;
		spB = spB->GetNextPtr();
	}
	return (maxa == maxb);
}

// Unions are considered the same if the max size of the union is the same.
// The target needs to be at least the size o f the source. ToDo.

bool TYP::IsSameUnionType(TYP* a, TYP* b)
{
	SYM* spA, * spB;
	int64_t maxa=0, maxb=0;

	// union will match anything
	return (true);
	spA = spA->GetPtr(a->lst.GetHead());      /* start at top of symbol table */
	maxa = a->size;
	while (spA != nullptr) {
		maxa = max(maxa, spA->tp->size);
		spA = spA->GetNextPtr();
	}
	spB = spB->GetPtr(b->lst.GetHead());      /* start at top of symbol table */
	maxb = b->size;
	while (spB != nullptr) {
		maxb = max(maxb, spB->tp->size);
		spB = spB->GetNextPtr();
	}
	return (maxa==maxb);
}

// Initialize the type. Unions can't be initialized. Oh yes they can.

int64_t TYP::Initialize(ENODE* pnode, TYP *tp2, int opt, SYM* symi)
{
	int64_t nbytes;
	TYP *tp;
	int base, nn;
	int64_t sizes[100];
	char idbuf[sizeof(lastid)+1];
	ENODE* node;
	Expression exp;

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
		if (lastst == assign)
			NextToken();
		switch (tp->type) {
		case bt_ubyte:
		case bt_byte:
			nbytes = initbyte(symi, opt);
			break;
		case bt_uchar:
		case bt_char:
		case bt_enum:
			nbytes = initchar(symi, opt);
			break;
		case bt_ushort:
		case bt_short:
			nbytes = initshort(symi, opt);
			break;
		case bt_pointer:
			if (tp->val_flag)
				nbytes = tp->InitializeArray(sizes[max(base-brace_level,0)], symi);
			else
				nbytes = InitializePointer(tp, opt, symi);
			break;
		case bt_exception:
		case bt_ulong:
		case bt_long:
			//strncpy(idbuf, lastid, sizeof(lastid));
			//strncpy(lastid, pnode->sym->name->c_str(), sizeof(lastid));
			//gNameRefNode = exp.ParseNameRef();
			nbytes = initlong(symi, opt);
			//strncpy(lastid, idbuf, sizeof(lastid));
			break;
		case bt_struct:
			nbytes = tp->InitializeStruct(pnode,symi);
			break;
		case bt_union:
			nbytes = tp->InitializeUnion(symi);
			break;
		case bt_quad:
			nbytes = initquad(symi,opt);
			break;
		case bt_float:
		case bt_double:
			nbytes = initfloat(symi,opt);
			break;
		case bt_triple:
			nbytes = inittriple(symi, opt);
			break;
		case bt_posit:
			nbytes = initPosit(symi, opt);
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
		if (lastst != comma || brace_level==0)
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

int64_t TYP::InitializeArray(int64_t maxsz, SYM* symi)
{
	int64_t nbytes;
	int64_t size;
	char *p;
	char *str;
	int64_t pos = 0;
	int64_t n, nh;
	ENODE* cnode, *node;
	int64_t fill = 0;
	int64_t poscount = 0;
	Value* values;
	int64_t* buckets;
	int64_t* bucketshi;
	int npos = 0;
	bool recval;
	bool spitout;

	/*
	typedef struct _tagSP {
		std::streampos poses;
	} Strmpos;

	Strmpos* poses;
	*/
	// First create array full of empty elements.
	/*
	size = btpp->size;
	poses = new Strmpos[(numele+1) * sizeof(Strmpos)];
	for (n = 0; n < numele; n++) {
		poses[n].poses = ofs.tellp();
		btpp->Initialize(nullptr, btpp, 0);
	}
	poses[numele].poses = ofs.tellp();
	*/
	// Fill in the elements as encountered.
	nbytes = 0;
	values = new Value[100];
	buckets = new int64_t[100];
	ZeroMemory(buckets, 100 * sizeof(int64_t));
	bucketshi = new int64_t[100];
	ZeroMemory(bucketshi, 100 * sizeof(int64_t));
	npos = 0;
	recval = false;
	if (symi) {
		node = symi->enode;

	}
	if (lastst == begin)
		NextToken();
	{
//		NextToken();               /* skip past the brace */
		for (n = 0; lastst != end; n++) {
/*
			ofs.seekp(poses[n].poses);
*/
			if (lastst == openbr) {
				NextToken();
				if (npos > 98) {
					return (nbytes);
					//error(TOO_MANY_DESIGNATORS);
				}
				n = GetConstExpression(&cnode, symi);
//				ofs.seekp(poses[n].poses);
				//fill = min(1000000, n - pos + 1);
				if (lastst == ellipsis) {
					NextToken();
					nh = GetConstExpression(&cnode, symi);
				}
				else
					nh = n;
				needpunc(closebr,50);
				needpunc(assign,50);
				buckets[npos] = n;
				bucketshi[npos] = nh;
				recval = true;
			}

			// Allow char array initialization like { "something", "somethingelse" }
			if (lastst == sconst && (btpp->type == bt_char || btpp->type == bt_uchar
				|| btpp->type == bt_ichar || btpp->type == bt_iuchar)) {
				if (fill > 0) {
					while (fill > 0) {
						fill--;
						spitout = false;
						for (n = 0; n < npos; n++) {
							if (pos >= buckets[n] && pos <= bucketshi[n]) {
								p = (char*)values[n].sp->c_str();
								while (*p) {
									GenerateChar(*p++);
								}
								GenerateChar(0);
								spitout = true;
							}
						}
						if (!spitout)
							GenerateChar(0);
						pos++;
					}
				}
				str = GetStrConst();
				if (recval) {
					values[npos].sp = new std::string(str);
					npos++;
				}
				nbytes = strlen(str) * 2 + 2;
				spitout = false;
				for (n = 0; n < npos; n++) {
					if (pos >= buckets[n] && pos <= bucketshi[n]) {
						p = (char*)values[n].sp->c_str();
						while (*p) {
							GenerateChar(*p++);
						}
						GenerateChar(0);
						spitout = true;
					}
				}
				if (!spitout) {
					p = str;
					while (*p) {
						GenerateChar(*p++);
					}
					GenerateChar(0);
				}
				free(str);
				pos++;
			}
			else if (lastst == asconst && btpp->type == bt_byte) {
				while (fill > 0) {
					fill--;
					spitout = false;
					for (n = 0; n <= npos; n++) {
						if (pos >= buckets[n] && pos <= bucketshi[n]) {
							p = (char*)values[n].sp->c_str();
							while (*p) {
								GenerateByte(*p++);
							}
							GenerateByte(0);
							spitout = true;
						}
					}
					if (!spitout)
						GenerateByte(0);
					pos++;
				}
				str = GetStrConst();
				if (recval) {
					values[npos].sp = new std::string(str);
					npos++;
				}
				nbytes = strlen(str) * 1 + 1;
				spitout = false;
				for (n = 0; n < npos; n++) {
					if (pos >= buckets[n] && pos <= bucketshi[n]) {
						p = (char*)values[n].sp->c_str();
						while (*p) {
							GenerateByte(*p++);
						}
						GenerateByte(0);
						spitout = true;
					}
				}
				if (!spitout) {
					p = str;
					while (*p)
						GenerateByte(*p++);
					GenerateByte(0);
				}
				free(str);
				pos++;
			}
			else {
				switch (btpp->type) {
				case bt_array:
					nbytes += btpp->Initialize(nullptr, btpp, fill == 0, symi);
					pos++;
					break;
				case bt_byte:
				case bt_ubyte:
					if (recval) {
						values[npos].value.i = GetIntegerExpression(nullptr,symi,0);
						npos++;
					}
					spitout = false;
					for (n = 0; n < npos; n++) {
						if (pos >= buckets[n] && pos <= bucketshi[n]) {
							GenerateByte(values[n].value.i);
							nbytes += 1;
							spitout = true;
							pos++;
						}
					}
					if (!spitout && !recval) {
						GenerateByte(GetIntegerExpression(nullptr,symi,0));
						nbytes += 1;
						pos++;
					}
					break;
				case bt_char:
				case bt_uchar:
				case bt_ichar:
					if (recval) {
						values[npos].value.i = GetIntegerExpression(nullptr,symi,0);
						npos++;
					}
					spitout = false;
					for (n = 0; n < npos; n++) {
						if (pos >= buckets[n] && pos <= bucketshi[n]) {
							GenerateChar(values[n].value.i);
							nbytes += 2;
							spitout = true;
							pos++;
						}
					}
					if (!spitout && !recval) {
						GenerateChar(GetIntegerExpression(nullptr,symi,0));
						nbytes += 2;
						pos++;
					}
					break;
				case bt_class:
					nbytes += btpp->Initialize(nullptr, btpp, fill == 0, symi);
					pos++;
					break;
				case bt_double:
				case bt_float:
					if (recval) {
						values[npos].f128 = GetFloatExpression(nullptr, symi);
						npos++;
					}
					spitout = false;
					for (n = 0; n < npos; n++) {
						if (pos >= buckets[n] && pos <= bucketshi[n]) {
							GenerateFloat(&values[n].f128);
							nbytes += 8;
							spitout = true;
							pos++;
						}
					}
					if (!spitout && !recval) {
						GenerateFloat(GetFloatExpression(nullptr, symi));
						nbytes += 8;
						pos++;
					}
					break;
				case bt_enum:
					if (recval) {
						values[npos].value.i = GetIntegerExpression(nullptr,symi,0);
						npos++;
					}
					spitout = false;
					for (n = 0; n < npos; n++) {
						if (pos >= buckets[n] && pos <= bucketshi[n]) {
							GenerateChar(values[n].value.i);
							nbytes += 2;
							spitout = true;
							pos++;
						}
					}
					if (!spitout && !recval) {
						GenerateChar(GetIntegerExpression(nullptr,symi,0));
						nbytes += 2;
						pos++;
					}
					break;
				case bt_long:
				case bt_ulong:
					if (recval) {
						values[npos].value.i = GetIntegerExpression(nullptr,symi,0);
						npos++;
					}
					spitout = false;
					for (n = 0; n < npos; n++) {
						if (pos >= buckets[n] && pos <= bucketshi[n]) {
							GenerateLong(values[n].value.i);
							nbytes += 8;
							spitout = true;
							pos++;
						}
					}
					if (!spitout && !recval) {
						GenerateLong(GetIntegerExpression(nullptr,symi,0));
						nbytes += 8;
						pos++;
					}
					break;
				case bt_short:
				case bt_ushort:
					if (recval) {
						values[npos].value.i = GetIntegerExpression(nullptr,symi,0);
						npos++;
					}
					spitout = false;
					for (n = 0; n < npos; n++) {
						if (pos >= buckets[n] && pos <= bucketshi[n]) {
							GenerateHalf(values[n].value.i);
							nbytes += 4;
							spitout = true;
							pos++;
						}
					}
					if (!spitout && !recval) {
						GenerateHalf(GetIntegerExpression(nullptr,symi,0));
						nbytes += 4;
						pos++;
					}
					break;
				default:
					if (fill > 0) {
						while (fill > 0) {
							fill--;
							nbytes += btpp->Initialize(nullptr, btpp, fill == 0, symi);
							pos++;
						}
					}
					else {
						nbytes += btpp->Initialize(nullptr, btpp, 1, symi);
						pos++;
					}
					break;
				}
			}
			recval = false;
			// Allow an extra comma at the end of the list of values
			if (lastst == comma) {
				NextToken();
				if (lastst == end) {
					break;
				}
			}
			else if (lastst == end) {
				//brace_level--;
				break;
			}
			else if (lastst == semicolon)
				break;
			else
				error(ERR_PUNCT);
		}
		while (nbytes < maxsz) {
			GenerateByte(0);
			nbytes++;
		}
		/*
			switch (btpp->type) {
			case bt_array:
				nbytes += btpp->Initialize(nullptr, btpp, fill == 0);
				pos++;
				break;
			case bt_byte:
			case bt_ubyte:
				spitout = false;
				for (n = 0; n < npos; n++) {
					if (pos >= buckets[n] && pos <= bucketshi[n]) {
						GenerateByte(values[n].value.i);
						nbytes += 1;
						spitout = true;
						pos++;
					}
				}
				if (!spitout) {
					GenerateByte(0);
					nbytes += 1;
					pos++;
				}
				break;
			case bt_char:
			case bt_uchar:
			case bt_ichar:
				spitout = false;
				for (n = 0; n < npos; n++) {
					if (pos >= buckets[n] && pos <= bucketshi[n]) {
						GenerateChar(values[n].value.i);
						nbytes += 2;
						spitout = true;
						pos++;
					}
				}
				if (!spitout) {
					GenerateChar(0);
					nbytes += 2;
					pos++;
				}
				break;
			case bt_class:
				nbytes += btpp->Initialize(nullptr, btpp, fill == 0);
				pos++;
				break;
			case bt_double:
			case bt_float:
				spitout = false;
				for (n = 0; n < npos; n++) {
					if (pos >= buckets[n] && pos <= bucketshi[n]) {
						GenerateFloat(&values[n].f128);
						nbytes += 8;
						spitout = true;
						pos++;
					}
				}
				if (!spitout) {
					GenerateFloat(rval128.Zero());
					nbytes += 8;
					pos++;
				}
				break;
			case bt_enum:
				spitout = false;
				for (n = 0; n < npos; n++) {
					if (pos >= buckets[n] && pos <= bucketshi[n]) {
						GenerateChar(values[n].value.i);
						nbytes += 2;
						spitout = true;
						pos++;
					}
				}
				if (!spitout) {
					GenerateChar(0);
					nbytes += 2;
					pos++;
				}
				break;
			case bt_long:
			case bt_ulong:
				spitout = false;
				for (n = 0; n < npos; n++) {
					if (pos >= buckets[n] && pos <= bucketshi[n]) {
						GenerateLong(values[n].value.i);
						nbytes += 8;
						spitout = true;
						pos++;
						break;
					}
				}
				if (!spitout) {
					GenerateLong(0);
					nbytes += 8;
					pos++;
				}
				break;
			case bt_short:
			case bt_ushort:
				spitout = false;
				for (n = 0; n < npos; n++) {
					if (pos >= buckets[n] && pos <= bucketshi[n]) {
						GenerateHalf(values[n].value.i);
						nbytes += 4;
						spitout = true;
						pos++;
					}
				}
				if (!spitout) {
					GenerateHalf(0);
					nbytes += 4;
					pos++;
				}
				break;
			default:
				if (fill > 0) {
					while (fill > 0) {
						fill--;
						nbytes += btpp->Initialize(nullptr, btpp, fill == 0);
						pos++;
					}
				}
				else {
					nbytes += btpp->Initialize(nullptr, btpp, 1);
					pos++;
				}
				break;
			}
			*/
//		}
//		NextToken();               /* skip closing brace */
	}
	//else if (lastst == sconst && (btpp->type == bt_char || btpp->type == bt_uchar)) {
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
		;// error(ERR_INITSIZE);    /* too many initializers */
xit:
	/*
	ofs.seekp(poses[numele].poses);
	delete[] poses;
	return (numele * size);
	*/
	delete[] values;
	delete[] buckets;
	return (nbytes);
}

int64_t TYP::InitializeStruct(ENODE* node, SYM* symi)
{
	SYM *sp;
	int64_t nbytes;
	int count;
	
//	needpunc(begin, 25);
	nbytes = 0;
	sp = lst.headp;
	count = 0;
	while (sp != 0) {
		while (nbytes < sp->value.i) {     /* align properly */
										   //                    nbytes += GenerateByte(0);
			GenerateByte(0);
			nbytes++;
		}
		nbytes += sp->tp->Initialize(node, sp->tp, 1, symi);
		if (lastst == comma)
			NextToken();
		else if (lastst == end || lastst==semicolon) {
			break;
		}
		else
			error(ERR_PUNCT);
		sp = sp->nextp;
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
	int64_t nbytes;
	int64_t val;
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
	case bt_ichar:
	case bt_char:
		val = node->i;
		nbytes = 2; GenerateChar(val); break;
	case bt_iuchar:
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
	case bt_posit:
		nbytes = 8; GeneratePosit(node->posit); break;
	case bt_pointer:
		if (tp->val_flag) {
			nbytes = 0;
			nele = tp->numele;
			tp = tp->btpp;
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

int64_t TYP::InitializeUnion(SYM* symi)
{
	SYM *sp, *osp;
	int64_t nbytes;
	int64_t val;
	ENODE *node = nullptr;
	bool found = false;
	TYP *tp, *ntp;
	int count;

	nbytes = 0;
	val = GetConstExpression(&node, symi);
	if (node == nullptr)	// syntax error in GetConstExpression()
		return (0);
	sp = lst.headp;      /* start at top of symbol table */
	osp = sp;
	count = 0;
	while (sp != 0) {
		// Detect array of values
		if (sp->tp->type == bt_pointer && sp->tp->val_flag) {
			tp = sp->tp->btpp;
			ntp = node->tp->btpp;
			if (IsSameType(tp, ntp, false))
			{
				nbytes = node->esize;
				nbytes = GenerateT(tp, node);
				found = true;
				while (lastst == comma && count < sp->tp->numele) {
					NextToken();
					val = GetConstExpression(&node, symi);
					//nbytes = node->esize;
					nbytes += GenerateT(tp, node);
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
	if (compiler.nogcskips)
		return (false);
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
	case bt_ichar:   case bt_iuchar:  return AL_CHAR;
	case bt_short:  case bt_ushort: return AL_SHORT;
	case bt_long:   case bt_ulong:  return AL_LONG;
	case bt_enum:           return AL_CHAR;
	case bt_pointer:
		if (val_flag)
			return (btpp->Alignment());
		else
			return (sizeOfPtr);//isShort ? AL_SHORT : AL_POINTER);
	case bt_float:          return AL_FLOAT;
	case bt_double:         return AL_DOUBLE;
	case bt_posit:					return AL_POSIT;
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
	int64_t retval = 0;
	static int level = 0;

	level++;
	if (level > 15) {
		retval = imax(AL_BYTE, worstAlignment);
		goto xit;
	}
	//printf("DIAG: type NULL in alignment()\r\n");
	if (this == NULL) {
		retval = imax(AL_BYTE, worstAlignment);
		goto xit;
	}
	switch (type) {
	case bt_byte:	case bt_ubyte:		level--; return imax(AL_BYTE, worstAlignment);
	case bt_char:   case bt_uchar:     level--; return imax(AL_CHAR, worstAlignment);
	case bt_ichar:   case bt_iuchar:     level--; return imax(AL_CHAR, worstAlignment);
	case bt_short:  case bt_ushort:    level--; return imax(AL_SHORT, worstAlignment);
	case bt_long:   case bt_ulong:     level--; return imax(AL_LONG, worstAlignment);
	case bt_enum:           level--; return imax(AL_CHAR, worstAlignment);
	case bt_pointer:
		if (val_flag) {
			retval = imax(btpp->Alignment(), worstAlignment);
			goto xit;
		}
		else {
			return (imax(sizeOfPtr, worstAlignment));
			//				return (imax(AL_POINTER,worstAlignment));
		}
	case bt_float:          level--; return imax(AL_FLOAT, worstAlignment);
	case bt_double:         level--; return imax(AL_DOUBLE, worstAlignment);
	case bt_posit:					level--; return imax(AL_POSIT, worstAlignment);
	case bt_triple:         level--; return imax(AL_TRIPLE, worstAlignment);
	case bt_class:
	case bt_struct:
	case bt_union:
		sp = (SYM *)sp->GetPtr(lst.GetHead());
		worstAlignment = alignment;
		if (worstAlignment == 0)
			worstAlignment = 2;
		while (sp != NULL) {
			if (sp->tp && sp->tp->alignment) {
				worstAlignment = imax(worstAlignment, sp->tp->alignment);
			}
			else
				worstAlignment = imax(worstAlignment, sp->tp->walignment());
			sp = sp->GetNextPtr();
		}
		retval = worstAlignment;
		goto xit;
	default:                level--; return (imax(AL_CHAR, worstAlignment));
	}
xit:
	level--;
	return (retval);
}


int TYP::roundAlignment()
{
	worstAlignment = 0;
	if (this == nullptr)
		return (1);
	if (type == bt_struct || type == bt_union || type == bt_class) {
		return (walignment());
	}
	return (Alignment());
}


// Round the size of the type up according to the worst alignment.

int64_t TYP::roundSize()
{
	int64_t sz;
	int64_t wa;

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

void TYP::storeHex(txtoStream& ofs)
{

}
