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

char *prefix;
extern int GetReturnBlockSize();
extern int nparms;
extern std::string names[20];

SYM *makeint2(std::string na);

int round8(int n)
{
    while (n & 7) n++;
    return n;
}

SYM *SYM::GetPtr(int n)
{ 
  if (n==0)
    return nullptr;
  if (n > 32767)
     return nullptr;
  return &compiler.symbolTable[n]; 
}

SYM *SYM::GetNextPtr()
{ 
  if (next==0)
     return nullptr;
  if (next > 32767)
     return nullptr;
  return &compiler.symbolTable[next];
}

SYM *SYM::GetParentPtr()
{
	if (parent==0)
	   return nullptr;
  if (parent > 32767)
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

//	printf("Enter GetParameterTypes()\r\n");
	i16 = new TypeArray();
	i16->Clear();
	sp = GetPtr(params.GetHead());
	for (nn = 0; sp; nn++) {
	  i16->Add(sp->tp);
		sp = sp->GetNextPtr();
	}
//	printf("Leave GetParameterTypes()\r\n");
	return i16;
}

TypeArray *SYM::GetProtoTypes()
{
	TypeArray *i16;
	SYM *sp;
	int nn;

//	printf("Enter GetParameterTypes()\r\n");
	nn = 0;
	i16 = new TypeArray();
	i16->Clear();
	sp = GetPtr(proto.GetHead());
	for (nn = 0; sp; nn++) {
	  i16->Add(sp->tp);
		sp = sp->GetNextPtr();
	}
//	printf("Leave GetParameterTypes()\r\n");
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
	int nn;
	TypeArray *ta;
	char namebuf[1000];

	if (na=="" || tbl==nullptr)
		return nullptr;
//	printf("Enter search2\r\n");
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
						delete[] ta;
				}
				else
					break;
			}
		}
    thead = thead->GetNextPtr();
    }
//	printf("Leave search2\r\n");
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

	dfs.printf("\ngsearch2 for: |%s|\n", (char *)na.c_str());
	prefix = nullptr;
	// There might not be a current statement if global declarations are
	// being processed.
	if (currentStmt==NULL) {
	  dfs.printf("Stmt=null, looking in global table\n");
		if (gsyms[0].Find(na,rettype,typearray,exact)) {
			sp = TABLE::match[TABLE::matchno-1];
			dfs.printf("Found in global symbol table\n");
			return sp;
		}
		return nullptr;
	}
	else {
    dfs.printf("Looking in statement table\n");
		if (currentStmt->ssyms.Find(na,rettype,typearray,exact)) {
			sp = TABLE::match[TABLE::matchno-1];
     	dfs.printf("Found as an auto var\n");
			return sp;
		}
		st = currentStmt->outer;
		while (st) {
    dfs.printf("Looking in outer statement table\n");
			if (st->ssyms.Find(na,rettype,typearray,exact)) {
				sp = TABLE::match[TABLE::matchno-1];
       	dfs.printf("Found as an auto var\n");
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
      				return sp;
      			}
    		  }
    			// Search for class member
    			dfs.printf("Looking at class members %p\n",(char *)&p->tp->lst);
    			if (p->tp->type == bt_class) {
    			  SYM *tab;
    				if (p->tp->lst.Find(na,rettype,typearray,exact)) {
    					sp = TABLE::match[TABLE::matchno-1];
             	dfs.printf("Found in class\n");
    					return sp;
    				}
    				tab = p->GetPtr(p->tp->lst.base);
       			dfs.printf("Looking at base class members:%p\n",(char *)tab);
    				while(tab) {
        				if (tab->tp->lst.Find(na,rettype,typearray,exact)) {
        					sp = TABLE::match[TABLE::matchno-1];
                	dfs.printf("Found in base class\n");
        					return sp;
        				}
        				tab = tab->GetPtr(tab->tp->lst.base);
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
			return sp;
		}
	}
xit:
  return sp;
}

// A wrapper for gsearch2() when we only care about finding any match.

SYM *gsearch(std::string name)
{
	return gsearch2(name, bt_long, nullptr, false);
}


void SYM::PrintParameterTypes()
{
	int nn;
	TypeArray *ta = GetParameterTypes();
	dfs.printf("Parameter types(%s)\n",(char *)name->c_str());
	ta->Print();
	if (ta)
		delete[] ta;
  ta = GetProtoTypes();
	dfs.printf("Proto types(%s)\n",(char *)name->c_str());
	ta->Print();
	if (ta)
		delete[] ta;
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

//	printf("Enter Find(char *)\r\n");
	sp = tp->lst.Find(nme,false);
	if (sp==nullptr) {
		if (parent) {
			sp = GetPtr(parent)->Find(nme);
		}
	}
//	printf("Leave Find(char *):%p\r\n",sp);
	return sp;
}


// First check the return type because it's simple to do.
// Then check the parameters.

bool SYM::CheckSignatureMatch(SYM *a, SYM *b) const
{
	std::string ta,tb;

//	if (a->tp->typeno != b->tp->typeno)
//		return false;

	ta = a->BuildSignature().substr(5);
	tb = b->BuildSignature().substr(5);
	return ta.compare(tb)==0;
}


// Convert a type number to a character string
// These will always be three characters.

std::string TypenoToChars(__int16 typeno)
{
	const std::string alphabet =
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ123456";
	char c1,c2,c3;
	std::string str;

	c1 = alphabet[typeno & 31];
	c2 = alphabet[(typeno>>5) & 31];
	c3 = alphabet[(typeno>>10) & 31];
	str += c1;
	str += c2;
	str += c3;
	return str;
}

// Get the mangled name for the function
//
std::string SYM::GetNameHash()
{
	std::string nh;
  SYM *sp;

	nh = TypenoToChars(tp->typeno);
	if (parent) {
	  sp = GetPtr(parent);
		nh += sp->GetNameHash();
	}
	return nh;
}

// Build a function signature string including
// the return type, base classes, and any parameters.

std::string SYM::BuildSignature(int opt)
{
	std::string str;
	SYM *sp;
	int n;

	str = "_Z";		// 'C' likes this
	str += GetNameHash();
	str += *name;
	if (opt)
	   str += GetParameterTypes()->BuildSignature();
	else
	   str += GetProtoTypes()->BuildSignature();
	return str;
}


// Check if the passed parameter list matches the one in the
// symbol.
// Allows a null pointer to be passed indicating no parameters

bool SYM::ParameterTypesMatch(TypeArray *ta)
{
	TypeArray *tb;
	int nn;

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

bool SYM::ParameterTypesMatch(SYM *sym)
{
	TypeArray *ta;
	bool ret;

	ta = sym->GetParameterTypes();
	ret = ParameterTypesMatch(ta);
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

	sp1 = nullptr;
	for (nn = 0; nn < mm; nn++) {
	  dfs.printf(".");
		sp1 = TABLE::match[nn];
		if (sp1->ParameterTypesMatch(this)) {
			return sp1;
		}
	}
	return nullptr;
}

SYM *SYM::FindExactMatch(int mm, std::string name, int rettype, TypeArray *typearray)
{
	SYM *sp1;
	int nn;

	sp1 = nullptr;
	for (nn = 0; nn < mm; nn++) {
		sp1 = TABLE::match[nn];
		if (sp1->ParameterTypesMatch(typearray))
			return sp1;
	}
	return nullptr;
}

void SYM::BuildParameterList(int *num)
{
	int i, poffset;
	SYM *sp1;
	int onp;
	int np;

	dfs.printf("BuildParameterList\r\n");
	poffset = GetReturnBlockSize();
//	sp->parms = (SYM *)NULL;
	onp = nparms;
	nparms = 0;
	np = ParameterDeclaration::Parse(1);
	*num += np;
dfs.printf("B");
	nparms = onp;
	for(i = 0;i < np && i < 20;++i) {
		if( (sp1 = currentFn->params.Find(names[i],false)) == NULL) {
printf("C");
			sp1 = makeint2(names[i]);
//			lsyms.insert(sp1);
		}
		sp1->parent = parent;
		sp1->value.i = poffset;
		// Check for aggregate types passed as parameters. Structs
		// and unions use the type size. There could also be arrays
		// passed.
		poffset += round8(sp1->tp->size);
		if (round8(sp1->tp->size) > 8)
			IsLeaf = FALSE;
		sp1->storage_class = sc_auto;
	}
	// Process extra hidden parameter
	if (tp) {
		if (tp->GetBtp()) {
			if (tp->GetBtp()->type==bt_struct || tp->GetBtp()->type==bt_union || tp->GetBtp()->type==bt_class ) {
				sp1 = makeint2("_pHiddenStructPtr");
				sp1->parent = parent;
				sp1->value.i = poffset;
				poffset += 8;
				sp1->storage_class = sc_auto;
				sp1->next = 0;
				// record parameter list
				params.insert(sp1);
		//		nparms++;
				*num = *num + 1;
			}
		}
	}
	dfs.printf("Leave BuildParameterList\r\n");
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
    sprintf(buf, "_p%d", nn);
    sym->name = new std::string(buf);
    sym->tp = allocTYP();
    // should really go figure the type number out,
    // 
    sym->tp->type = (e_bt) ta->types[nn];
    sym->tp->typeno = ta->types[nn];
    proto.insert(sym);
  }
}


