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

char *prefix;
extern int GetReturnBlockSize();
extern int nparms;
extern Stringx names[20];
extern bool isRegister;

SYM *makeint2(std::string na);

int round2(int n)
{
    while (n & 1) n++;
    return n;
}

SYM *SYM::GetPtr(int n)
{ 
	if (n==0)
		return nullptr;
	if (n < 0 || n > 32767)
		return nullptr;
	return &compiler.symbolTable[n]; 
}

SYM *SYM::GetNextPtr()
{ 
	if (next==0)
		return nullptr;
	if (next < 0 || next > 32767)
		return nullptr;
	return &compiler.symbolTable[next];
}

SYM *SYM::GetParentPtr()
{
	if (parent==0)
	   return nullptr;
	if (parent < 0 || parent > 32767)
		return nullptr;
	return &compiler.symbolTable[parent];
};

int SYM::GetIndex()
{
	if (this==nullptr)
		return 0; 
	return this - &compiler.symbolTable[0];
};

// Get the parameter types into an array of short integers.
// Only the first 20 parameters are processed.
//
TypeArray *SYM::GetParameterTypes()
{
	TypeArray *i16;
	SYM *sp;
	int nn;

//	printf("Enter GetParameterTypes()\n");
	i16 = new TypeArray();
	i16->Clear();
	sp = GetPtr(params.GetHead());
	for (nn = 0; sp; nn++) {
		i16->Add(sp->tp,(__int16)(sp->IsRegister ? sp->reg : 0));
		sp = sp->GetNextPtr();
	}
//	printf("Leave GetParameterTypes()\n");
	return i16;
}

TypeArray *SYM::GetProtoTypes()
{
	TypeArray *i16;
	SYM *sp;
	int nn;

//	printf("Enter GetParameterTypes()\n");
	nn = 0;
	i16 = new TypeArray();
	i16->Clear();
	sp = GetPtr(proto.GetHead());
	// If there's no prototype try for a parameter list.
	if (sp==nullptr)
		return (GetParameterTypes());
	for (nn = 0; sp; nn++) {
		i16->Add(sp->tp,(__int16)sp->IsRegister ? sp->reg : 0);
		sp = sp->GetNextPtr();
	}
//	printf("Leave GetParameterTypes()\n");
	return i16;
}

uint8_t hashadd(char *nm)
{
	uint8_t hsh;

	for(hsh=0;*nm;nm++)
		hsh += *nm;
	return hsh;
}

SYM *search2(std::string na,TABLE *tbl,TypeArray *typearray)
{
	SYM *thead;
	TypeArray *ta;

	if (na=="" || tbl==nullptr)
		return nullptr;
//	printf("Enter search2\n");
	if (tbl==&gsyms[0])
		thead = compiler.symbolTable[0].GetPtr(hashadd((char *)na.c_str()));
	else
		thead = &compiler.symbolTable[tbl->GetHead()];
	while( thead != NULL) {
		if (thead->name->length() != 0) {
		  /*
			if (prefix)
				strncpy(namebuf,prefix,sizeof(namebuf)-1);
			else
				namebuf[0]='\0';
			strncat(namebuf,thead->name,sizeof(namebuf)-1);
			*/
			if(thead->name->compare(na)==0) {
				if (typearray) {
					ta = thead->GetProtoTypes();
					if (ta->IsEqual(typearray))
						break;
					if (ta)
						delete ta;
				}
				else
					break;
			}
		}
    thead = thead->GetNextPtr();
    }
//	printf("Leave search2\n");
    return thead;
}

SYM *search(std::string na,TABLE *tbl)
{
	return search2(na,tbl,nullptr);
}

// first look in the current compound statement for the symbol,
// Next look in progressively more outer compound statements
// Next look in the local symbol table for the function
// Finally look in the global symbol table.
//
SYM *gsearch2(std::string na, __int16 rettype, TypeArray *typearray, bool exact)
{
	SYM *sp;
	Statement *st;
	SYM *p;

	dfs.printf("\n<gsearch2> for: |%s|\n", (char *)na.c_str());
	prefix = nullptr;
	sp = nullptr;
	// There might not be a current statement if global declarations are
	// being processed.
	if (currentStmt==NULL) {
	  dfs.printf("Stmt=null, looking in global table\n");
		if (gsyms[0].Find(na,rettype,typearray,exact)) {
			sp = TABLE::match[TABLE::matchno-1];
			dfs.printf("Found in global symbol table\n");
			dfs.puts("</gsearch2>\n");
			return sp;
		}
		dfs.puts("</gsearch2>\n");
		return nullptr;
	}
	else {
    dfs.printf("Looking in statement table\n");
		if (currentStmt->ssyms.Find(na,rettype,typearray,exact)) {
			sp = TABLE::match[TABLE::matchno-1];
     	dfs.printf("Found as an auto var\n");
			dfs.puts("</gsearch2>\n");
			return sp;
		}
		st = currentStmt->outer;
		while (st) {
    dfs.printf("Looking in outer statement table\n");
			if (st->ssyms.Find(na,rettype,typearray,exact)) {
				sp = TABLE::match[TABLE::matchno-1];
       	dfs.printf("Found as an auto var\n");
  			dfs.puts("</gsearch2>\n");
				return sp;
			}
			st = st->outer;
		}
		p = currentFn;
		if (p) {
      dfs.printf("Looking in function's symbol table\n");
  		if (currentFn->lsyms.Find(na,rettype,typearray,exact)) {
  			sp = TABLE::match[TABLE::matchno-1];
       	dfs.printf("Found in function symbol table (a label)\n");
  			dfs.puts("</gsearch2>\n");
  			return sp;
  		}
  		while(p) {
  			dfs.printf("Searching method/class:%s|%p\n",(char *)p->name->c_str(),(char *)p);
  			if (p->tp) {
    			if (p->tp->type != bt_class) {
      			dfs.printf("Looking at params %p\n",(char *)&p->params);
      			if (p->params.Find(na,rettype,typearray,exact)) {
      				sp = TABLE::match[TABLE::matchno-1];
             	dfs.printf("Found as parameter\n");
        			dfs.puts("</gsearch2>\n");
      				return sp;
      			}
    		  }
    			// Search for class member
    			dfs.printf("Looking at class members %p\n",(char *)&p->tp->lst);
    			if (p->tp->type == bt_class) {
    			  SYM *tab;
    			  int nn;
    				if (p->tp->lst.Find(na,rettype,typearray,exact)) {
    					sp = TABLE::match[TABLE::matchno-1];
             	dfs.printf("Found in class\n");
        			dfs.puts("</gsearch2>\n");
    					return sp;
    				}
    				dfs.printf("Base=%d",p->tp->lst.base);
    				tab = p->GetPtr(p->tp->lst.base);
    				dfs.printf("Base=%p",(char *)tab);
    				if (tab) {
    				  dfs.puts("Has a base class");
    				  if (tab->tp) {
           			dfs.printf("Looking at base class members:%p\n",(char *)tab);
        				nn = tab->tp->lst.FindRising(na);
        				if (nn > 0) {
                 	dfs.printf("Found in base class\n");
        				  if (exact) {
           				  //sp = sp->FindRisingMatch();
        				    sp = SYM::FindExactMatch(TABLE::matchno, na, bt_long, typearray);
        				    if (sp) {
                			dfs.puts("</gsearch2>\n");
        				      return sp;
      				      }
        				  }
        				  else {
    				        sp = TABLE::match[0];
                		dfs.puts("</gsearch2>\n");
    				        return sp;
    				      }
    				    }
      				}
    			  }
  			  }
  			}
  			p = p->GetParentPtr();
  		}
  	}
		// Finally, look in the global symbol table
		dfs.printf("Looking at global symbols\n");
		if (gsyms[0].Find(na,rettype,typearray,exact)) {
			sp = TABLE::match[TABLE::matchno-1];
			dfs.printf("Found in global symbol table\n");
			dfs.puts("</gsearch2>\n");
			return sp;
		}
	}

	dfs.puts("</gsearch2>\n");
  return sp;
}

// A wrapper for gsearch2() when we only care about finding any match.

SYM *gsearch(std::string name)
{
	return gsearch2(name, bt_long, nullptr, false);
}


void SYM::PrintParameterTypes()
{
	TypeArray *ta = GetParameterTypes();
	dfs.printf("Parameter types(%s)\n",(char *)name->c_str());
	ta->Print();
	if (ta)
		delete[] ta;
  ta = GetProtoTypes();
	dfs.printf("Proto types(%s)\n",(char *)name->c_str());
	ta->Print();
	if (ta)
		delete ta;
}


// Create a copy of a symbol, used when creating derived classes from base
// classes. The type is copyied and extended by a derived class.

SYM *SYM::Copy(SYM *src)
{
	SYM *dst = nullptr;

  dfs.printf("Enter SYM::Copy\n");
	if (src) {
		dst = allocSYM();
		dfs.printf("A");
		memcpy(dst, src, sizeof(SYM));
//		dst->tp = TYP::Copy(src->tp);
//		dst->name = src->name;
//		dst->shortname = src->shortname;
		dst->SetNext(0);
  }
  dfs.printf("Leave SYM::Copy\n");
	return dst;
}

SYM *SYM::Find(std::string nme)
{
	SYM *sp;

//	printf("Enter Find(char *)\n");
	sp = tp->lst.Find(nme,false);
	if (sp==nullptr) {
		if (parent) {
			sp = GetPtr(parent)->Find(nme);
		}
	}
//	printf("Leave Find(char *):%p\n",sp);
	return sp;
}


// First check the return type because it's simple to do.
// Then check the parameters.

bool SYM::CheckSignatureMatch(SYM *a, SYM *b) const
{
	std::string ta,tb;

//	if (a->tp->typeno != b->tp->typeno)
//		return false;

	ta = a->BuildSignature()->substr(5);
	tb = b->BuildSignature()->substr(5);
	return ta.compare(tb)==0;
}


// Convert a type number to a character string
// These will always be four characters.

std::string *TypenoToChars(int typeno)
{
	const char *alphabet =
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ123456";
	char c[8];
	std::string *str;

  dfs.puts("<TypenoToChars>");
  str = new std::string();
  dfs.putch('A');
	c[0] = alphabet[typeno & 31];
  dfs.putch('B');
	c[1] = alphabet[(typeno>>5) & 31];
  dfs.putch('C');
	c[2] = alphabet[(typeno>>10) & 31];
  c[3] = alphabet[(typeno>>15) & 31];
  c[4] = '\0';
  c[5] = '\0';
  c[6] = '\0';
  c[7] = '\0';
  dfs.puts("D:");
	str->append(c);
	dfs.printf("%s",(char *)str->c_str());
  dfs.puts("</TypenoToChars>");
	return str;
}

// Get the mangled name for the function
//
std::string *SYM::GetNameHash()
{
	std::string *nh;
  SYM *sp;
  int nn;

  dfs.puts("<GetNameHash>");
  dfs.printf("tp:%p",(char *)tp);
//  if (tp==(TYP *)0x500000005LL) {
//    nh = new std::string("TAA");
//    return nh;
//  }
	nh = TypenoToChars(tp->typeno);
  dfs.putch('A');
  sp = GetParentPtr();
  if (sp) {
     nh->append(*sp->GetNameHash());
	   sp = GetPtr(sp->tp->lst.base);
     dfs.putch('B');
   	 for (nn = 0; sp && nn < 200; nn++) {
  	   dfs.putch('.');
  	   nh->append(*sp->GetNameHash());
       sp = GetPtr(sp->tp->lst.base);
  	 }
	   if (nn >= 200) {
	     error(ERR_CIRCULAR_LIST);
    }
	}
/*
	if (parent) {
	  sp = GetPtr(parent);
		nh += sp->GetNameHash();
	}
*/
  dfs.puts("</GetNameHash>\n");
	return nh;
}

// Build a function signature string including
// the return type, base classes, and any parameters.

std::string *SYM::BuildSignature(int opt)
{
	std::string *str;
	std::string *nh;

	dfs.printf("<BuildSignature>");
	if (mangledNames) {
		str = new std::string("_Z");		// 'C' likes this
		dfs.printf("A");
		nh = GetNameHash();
		dfs.printf("B");
		str->append(*nh);
		dfs.printf("C");
		delete nh;
		dfs.printf("D");
		if (name > (std::string *)0x15)
			str->append(*name);
		if (opt) {
			dfs.printf("E");
			str->append(*GetParameterTypes()->BuildSignature());
		}
		else {
			dfs.printf("F");
			str->append(*GetProtoTypes()->BuildSignature());
		}
	}
	else {
		str = new std::string("");
		str->append(*name);
	}
	dfs.printf(":%s</BuildSignature>",(char *)str->c_str());
	return str;
}


// Check if the passed parameter list matches the one in the
// symbol.
// Allows a null pointer to be passed indicating no parameters

bool SYM::ProtoTypesMatch(TypeArray *ta)
{
	TypeArray *tb;

	tb = GetProtoTypes();
	if (tb->IsEqual(ta)) {
	  delete tb;
	  return true;
	}
  delete tb;
  return false;
}

bool SYM::ParameterTypesMatch(TypeArray *ta)
{
	TypeArray *tb;

	tb = GetProtoTypes();
	if (tb->IsEqual(ta)) {
	  delete tb;
	  return true;
	}
  delete tb;
  return false;
}

// Check if the parameter type list of two different symbols
// match.

bool SYM::ProtoTypesMatch(SYM *sym)
{
	TypeArray *ta;
	bool ret;

	ta = sym->GetProtoTypes();
	ret = ProtoTypesMatch(ta);
	delete ta;
	return ret;
}

bool SYM::ParameterTypesMatch(SYM *sym)
{
	TypeArray *ta;
	bool ret;

	ta = GetProtoTypes();
	ret = sym->ParameterTypesMatch(ta);
	delete ta;
	return ret;
}

// Lookup the exactly matching method from the results returned by a
// find operation. Find might return multiple values if there are 
// overloaded functions.

// Parameters:
//    mm = number of entries to search (typically the value 
//         TABLE::matchno teh number of matches found

SYM *SYM::FindExactMatch(int mm)
{
	SYM *sp1;
	int nn;
  TypeArray *ta, *tb;
 
	sp1 = nullptr;
	for (nn = 0; nn < mm; nn++) {
	  dfs.printf("%d",nn);
		sp1 = TABLE::match[nn];
		// Matches sp1 prototype list against this's parameter list
		ta = sp1->GetProtoTypes();
		tb = GetParameterTypes();
		if (ta->IsEqual(tb)) {
		  delete ta;
		  delete tb;
			return sp1;
		}
	  delete ta;
	  delete tb;
	}
	return nullptr;
}

SYM *SYM::FindExactMatch(int mm, std::string name, int rettype, TypeArray *typearray)
{
	SYM *sp1;
	int nn;
  TypeArray *ta;

	sp1 = nullptr;
	for (nn = 0; nn < mm; nn++) {
		sp1 = TABLE::match[nn];
		ta = sp1->GetProtoTypes();
		if (ta->IsEqual(typearray)) {
		  delete ta;
			return sp1;
	  }
	  delete ta;
	}
	return nullptr;
}

int SYM::FindNextExactMatch(int startpos, TypeArray * tb)
{
	SYM *sp1;
	int nn;
  TypeArray *ta;

	sp1 = nullptr;
	for (nn = startpos; nn < TABLE::matchno; nn++) {
		sp1 = TABLE::match[nn];
		ta = sp1->GetProtoTypes();
		if (ta->IsEqual(tb)) {
		  delete ta;
		  return nn;
	  }
	  delete ta;
	}
	return -1;
}

SYM *SYM::FindRisingMatch(bool ignore)
{
  int nn;
  int em;
  int iter;
  SYM *sym;
  std::string nme;
  TypeArray *ta;
  
  nme = *name;
  sym = nullptr;
  ta = GetProtoTypes();
  dfs.printf("<FindRisingMatch>%s type %d ", (char *)name->c_str(), tp->type);
  if (GetParentPtr()!=nullptr)
     nn = GetParentPtr()->tp->lst.FindRising(nme);
  else
    nn = 1;
//  nn = tp->lst.FindRising(nme);
  iter = 0;
  if (nn) {
    dfs.puts("Found method:");
    for (iter = 0; true; iter = em + 1) {
      em = FindNextExactMatch(iter,ta);
      if (em < 0)
        break;
      sym = TABLE::match[em];
      if (!ignore || sym->GetParentPtr() != GetParentPtr()) { // ignore entry here
        dfs.puts("Found in a base class:");
        break;
      }
      sym = nullptr;
    }
  }
  if (ta)
    delete ta;
  dfs.printf("</FindRisingMatch>\n");
  return sym;
}


void SYM::BuildParameterList(int *num, int *numa)
{
	int i, poffset, preg, fpreg;
	SYM *sp1;
	int onp;
	int np;
	bool noParmOffset = false;

	dfs.printf("<BuildParameterList\n>");
	poffset = 0;//GetReturnBlockSize();
//	sp->parms = (SYM *)NULL;
	onp = nparms;
	nparms = 0;
	preg = regFirstParm;
	fpreg = 18;
	// Parameters will be inserted into the symbol's parameter list when
	// declarations are processed.
	np = ParameterDeclaration::Parse(1);
	*num += np;
	*numa = 0;
  dfs.printf("B");
	nparms = onp;
	for(i = 0;i < np && i < 20;++i) {
		if( (sp1 = currentFn->params.Find(names[i].str,false)) == NULL) {
      dfs.printf("C");
			sp1 = makeint2(names[i].str);
//			lsyms.insert(sp1);
		}
		sp1->parent = parent;
		sp1->IsParameter = true;
		sp1->value.i = poffset;
		noParmOffset = false;
		if (sp1->tp->IsFloatType()) {
			if (preg > regLastParm)
				sp1->IsRegister = false;
			if (sp1->IsRegister && sp1->tp->size < 11) {
				sp1->reg = sp1->IsAuto ? preg | 0x8000 : preg;
				preg++;
				if ((preg & 0x8000)==0) {
					noParmOffset = true;
					sp1->value.i = -1;
				}
			}
			else
				sp1->IsRegister = false;
		}
		else {
			if (preg > regLastParm)
				sp1->IsRegister = false;
			if (sp1->IsRegister && sp1->tp->size < 11) {
				sp1->reg = sp1->IsAuto ? preg | 0x8000 : preg;
				preg++;
				if ((preg & 0x8000)==0) {
					noParmOffset = true;
					sp1->value.i = -1;
				}
			}
			else
				sp1->IsRegister = false;
		}
		if (!sp1->IsRegister)
			*numa += 1;
		// Check for aggregate types passed as parameters. Structs
		// and unions use the type size. There could also be arrays
		// passed.
		if (!noParmOffset)
			poffset += sp1->tp->size;
		if (sp1->tp->size > 1 && sp1->tp->type != bt_long && sp1->tp->type != bt_ulong)
			IsLeaf = false;
		sp1->storage_class = sc_auto;
	}
	// Process extra hidden parameter
	// ToDo: verify that the hidden parameter is required here.
	// It is generated while processing expressions. It may not be needed
	// here.
	if (tp) {
		if (tp->GetBtp()) {
			if (tp->GetBtp()->type==bt_struct || tp->GetBtp()->type==bt_union || tp->GetBtp()->type==bt_class ) {
				IsLeaf = false;
				sp1 = makeStructPtr("_pHiddenStructPtr");
				sp1->parent = parent;
				sp1->IsParameter = true;
				sp1->value.i = poffset;
				poffset += sizeOfWord;
				sp1->storage_class = sc_register;
				sp1->IsAuto = false;
				sp1->next = 0;
				sp1->IsRegister = true;
				if (preg > regLastParm)
					sp1->IsRegister = false;
				if (sp1->IsRegister && sp1->tp->size < 11) {
					sp1->reg = sp1->IsAuto ? preg | 0x8000 : preg;
					preg++;
					if ((preg & 0x8000)==0) {
						noParmOffset = true;
						sp1->value.i = -1;
					}
				}
				else
					sp1->IsRegister = false;
				// record parameter list
				params.insert(sp1);
		//		nparms++;
				if (!sp1->IsRegister)
					*numa += 1;
				*num = *num + 1;
			}
		}
	}
	dfs.printf("</BuildParameterList>\n");
}

void SYM::AddParameters(SYM *list)
{
  SYM *nxt;

	while(list) {
	  nxt = list->GetNextPtr();
  	params.insert(SYM::Copy(list));
		list = nxt;
	}

}

void SYM::AddProto(SYM *list)
{
  SYM *nxt;

	while(list) {
	  nxt = list->GetNextPtr();
  	proto.insert(SYM::Copy(list));	// will clear next
		list = nxt;
	}
}

void SYM::AddProto(TypeArray *ta)
{
  SYM *sym;
  int nn;
  char buf [20];

  for (nn = 0; nn < ta->length; nn++) {
    sym = allocSYM();
    sprintf_s(buf, sizeof(buf), "_p%d", nn);
    sym->SetName(std::string(buf));
    sym->tp = TYP::Make(ta->types[nn],TYP::GetSize(ta->types[nn]));
    sym->tp->type = (e_bt) TYP::GetBasicType(ta->types[nn]);
	sym->IsRegister = ta->preg[nn] != 0;
	sym->reg = ta->preg[nn];
    proto.insert(sym);
  }
}

void SYM::AddDerived(SYM *sp)
{
	DerivedMethod *mthd;
 
	dfs.puts("<AddDerived>"); 
	mthd = (DerivedMethod *)allocx(sizeof(DerivedMethod));
	dfs.printf("A");
	if (sp->tp==nullptr)
		dfs.printf("Nullptr");
	if (sp->GetParentPtr()==nullptr)
		throw C64PException(ERR_NULLPOINTER,10);
	mthd->typeno = sp->GetParentPtr()->tp->typeno;
	dfs.printf("B");
	mthd->name = sp->BuildSignature();

	dfs.printf("C");
	if (derivitives) {
		dfs.printf("D");
		mthd->next = derivitives;
	}
	derivitives = mthd;
	dfs.puts("</AddDerived>"); 
}


