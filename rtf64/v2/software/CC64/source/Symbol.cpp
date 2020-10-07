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

char *prefix;
extern int nparms;
extern bool isRegister;

SYM *SYM::GetPtr(int n)
{ 
  if (n==0)
    return nullptr;
  if (n > 32767)
     return nullptr;
  return (SYM *)&compiler.symbolTable[n]; 
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
					ta = thead->fi->GetProtoTypes();
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
//	printf("Leave search2\r\n");
    return (thead);
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
			return (sp);
		}
		dfs.puts("</gsearch2>\n");
		return (nullptr);
	}
	else {
    dfs.printf("Looking in statement table\n");
		if (currentStmt->ssyms.Find(na,rettype,typearray,exact)) {
			sp = TABLE::match[TABLE::matchno-1];
     	dfs.printf("Found as an auto var\n");
			dfs.puts("</gsearch2>\n");
			return (sp);
		}
		st = currentStmt->outer;
		while (st) {
    dfs.printf("Looking in outer statement table\n");
			if (st->ssyms.Find(na,rettype,typearray,exact)) {
				sp = TABLE::match[TABLE::matchno-1];
       	dfs.printf("Found as an auto var\n");
  			dfs.puts("</gsearch2>\n");
				return (sp);
			}
			st = st->outer;
		}
		p = currentFn->sym;
		if (p) {
      dfs.printf("Looking in function's symbol table\n");
  		if (currentFn->sym->lsyms.Find(na,rettype,typearray,exact)) {
  			sp = TABLE::match[TABLE::matchno-1];
       	dfs.printf("Found in function symbol table (a label)\n");
  			dfs.puts("</gsearch2>\n");
  			return (sp);
  		}
  		while(p) {
  			dfs.printf("Searching method/class:%s|%p\n",(char *)p->name->c_str(),(char *)p);
  			if (p->tp) {
    			if (p->tp->type != bt_class) {
      			dfs.printf("Looking at params %p\n",(char *)&p->fi->params);
      			if (p->fi->params.Find(na,rettype,typearray,exact)) {
      				sp = TABLE::match[TABLE::matchno-1];
             	dfs.printf("Found as parameter\n");
        			dfs.puts("</gsearch2>\n");
      				return (sp);
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
    					return (sp);
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
        				    sp = Function::FindExactMatch(TABLE::matchno, na, bt_long, typearray)->sym;
        				    if (sp) {
                			dfs.puts("</gsearch2>\n");
        				      return (sp);
      				      }
        				  }
        				  else {
    				        sp = TABLE::match[0];
                		dfs.puts("</gsearch2>\n");
    				        return (sp);
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
			return (sp);
		}
	}

	dfs.puts("</gsearch2>\n");
  return (sp);
}

// A wrapper for gsearch2() when we only care about finding any match.

SYM *gsearch(std::string name)
{
	return (gsearch2(name, bt_long, nullptr, false));
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
		if (src->fi) {
			dst->fi = allocFunction(src->id);
			memcpy(dst->fi, src->fi, sizeof(Function));
			dst->fi->sym = dst;
			dst->fi->params.SetOwner(src->id);
			dst->fi->proto.SetOwner(src->id);
		}
  }
  dfs.printf("Leave SYM::Copy\n");
	return (dst);
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
	return (sp);
}

int SYM::FindNextExactMatch(int startpos, TypeArray * tb)
{
	SYM *sp1;
	int nn;
	TypeArray *ta;

	sp1 = nullptr;
	for (nn = startpos; nn < TABLE::matchno; nn++) {
		sp1 = TABLE::match[nn];
		if (fi) {
			ta = sp1->fi->GetProtoTypes();
			if (ta->IsEqual(tb)) {
				delete ta;
				return (nn);
			}
			delete ta;
		}
	}
	return (-1);
}


SYM *SYM::FindRisingMatch(bool ignore)
{
	int nn;
	int em;
	int iter;
	SYM *s = this;
	std::string nme;
	TypeArray *ta = nullptr;

	nme = *name;
	if (fi)
		ta = fi->GetProtoTypes();
	dfs.printf("<FindRisingMatch>%s type %d ", (char *)name->c_str(), tp->type);
	if (GetParentPtr() != nullptr)
		nn = GetParentPtr()->tp->lst.FindRising(nme);
	else
		nn = 1;
	//  nn = tp->lst.FindRising(nme);
	iter = 0;
	if (nn) {
		dfs.puts("Found method:");
		for (iter = 0; true; iter = em + 1) {
			em = FindNextExactMatch(iter, ta);
			if (em < 0)
				break;
			s = TABLE::match[em];
			if (!ignore || s->GetParentPtr() != GetParentPtr()) { // ignore entry here
				dfs.puts("Found in a base class:");
				break;
			}
			s = nullptr;
		}
	}
	if (ta)
		delete ta;
	dfs.printf("</FindRisingMatch>\n");
	return (s);
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
	if (this == nullptr) {
		str = new std::string("");
		str->append(*name);
		dfs.printf(":%s</BuildSignature>", (char *)str->c_str());
		return (str);
	}
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
			str->append(*fi->GetParameterTypes()->BuildSignature());
		}
		else {
			dfs.printf("F");
			str->append(*fi->GetProtoTypes()->BuildSignature());
		}
	}
	else {
		str = new std::string("");
		str->append(*name);
	}
	dfs.printf(":%s</BuildSignature>", (char *)str->c_str());
	return str;
}


// Called during declaration parsing.

// Auto variables are referenced negative to the base pointer
// Structs need to be aligned on the boundary of the largest
// struct element. If a struct is all chars this will be 2.
// If a struct contains a pointer this will be 8. It has to
// be the worst case alignment.

void SYM::SetStorageOffset(TYP *head, int nbytes, int al, int ilc, int ztype)
{
	// Set the struct member storage offset.
	if (al == sc_static || al == sc_thread) {
		value.i = nextlabel++;
	}
	else if (ztype == bt_union) {
		value.i = ilc;// + parentBytes;
	}
	else if (al != sc_auto) {
		value.i = ilc + nbytes;// + parentBytes;
	}
	else {
		value.i = -(ilc + nbytes + head->roundSize());// + parentBytes);
	}
	head->struct_offset = value.i;
}


// Increase the storage allocation by the type size.

int SYM::AdjustNbytes(int nbytes, int al, int ztype)
{
	if (ztype == bt_union)
		nbytes = imax(nbytes, tp->roundSize());
	else if (al != sc_external) {
		// If a pointer to a function is defined in a struct.
		if (isStructDecl) {
			if (tp->type == bt_func) {
				nbytes += 8;
			}
			else if (tp->type != bt_ifunc) {
				nbytes += tp->roundSize();
			}
		}
		else {
			nbytes += tp->roundSize();
		}
	}
	return (nbytes);
}

void SYM::storeHex(txtoStream& ofs)
{
	ofs.write("SYM:");
	ofs.writeAsHex((char *)this, sizeof(SYM));
	ofs.printf(":%05d", fi->number);
	ofs.printf(":%05d", tp->typeno);
}
