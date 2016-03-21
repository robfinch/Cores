#include "stdafx.h"

extern char *prefix;
SYM *search2(char *na,TABLE *tbl,TypeArray *typearray);
uint8_t hashadd(char *nm);

SYM *TABLE::match[100];
int TABLE::matchno;

TABLE::TABLE()
{
  base = 0;
  head = 0;
  tail = 0;
  owner = 0;
}

// Used when deriving classes from base clasases.

void TABLE::CopySymbolTable(TABLE *dst, TABLE *src)
{
	SYM *sp, *newsym;
	dfs.printf("Enter CopySymbolTable\n");
	if (src) {
	  dfs.printf("A");
		sp = sp->GetPtr(src->GetHead());
		printf("Copy symbol table\r\n");
		while (sp) {
  	  dfs.printf("B");
			newsym = SYM::Copy(sp);
  	  dfs.printf("C");
			dst->insert(newsym);
  	  dfs.printf("D");
			sp = sp->GetNextPtr();
		}
	}
	dfs.printf("Leave CopySymbolTable\n");
}

//Generic table insert routine, used for all inserts.

void TABLE::insert(SYM *sp)
{
	int nn;
	TypeArray *ta = sp->GetProtoTypes();
	TABLE *tab = this;
  SYM *p;
	int s1,s2,s3;
	std::string nm;
//  std::string sig;

	if (sp == nullptr || this == nullptr ) {
	  dfs.printf("Null pointer at insert\n");
		throw new C64PException(ERR_NULLPOINTER,1);
  }

  if (this==&tagtable) {
    dfs.printf("Insert into tagtable:%s|\n",(char *)sp->name->c_str());
  }
  else
    dfs.printf("Insert %s into %p", (char *)sp->name->c_str(), (char *)this);
    dfs.printf("(%s)\n",owner ? (char *)SYM::GetPtr(owner)->name->c_str(): (char *)"");
//  sig = sp->BuildSignature();
	if (tab==&gsyms[0]) {
	  dfs.printf("Insert into global table\n");
		s1 = hashadd((char *)sp->name->c_str());
		s2 = hashadd((char *)sp->name2->c_str());
		s3 = hashadd((char *)sp->name3->c_str());
//		tab = &gsyms[(s1&s2)|(s1&s3)|(s2&s3)];
		tab = &gsyms[s1];
	}

  nm = *sp->name;
  dfs.printf("Calling find\n");
  nn = tab->Find(nm,sp->tp->typeno,ta,true); 
  dfs.printf("Called find\n");
	if(nn == 0) {
    if( tab->head == 0) {
      tab->SetHead(sp->GetIndex());
			tab->SetTail(sp->GetIndex());
		}
    else {
      sp->GetPtr(tab->tail)->next = sp->GetIndex();
      tab->SetTail(sp->GetIndex());
    }
    sp->SetNext(0);
    dfs.printf("At insert:\n");
    sp->GetProtoTypes()->Print();
  }
  else
    error(ERR_DUPSYM);
	if (ta)
		delete ta;
//  p = tab->GetHead();
//  while(p) {
//    printf("Xele:%p|%s|\r\n", p, p->name.c_str());
//    p = p->GetNext();
//  }
}

// Parameters:
//  na:			the name to search for
//	rettype:	this parameter is ignored

int TABLE::Find(std::string na,__int16 rettype, TypeArray *typearray, bool exact)
{
	SYM *thead, *first;
	int nn;
	TypeArray *ta;
	char namebuf[1000];
	int s1,s2,s3;

	if (na.length()==0) {
	  dfs.printf("name is empty string\n");
		throw new C64PException(ERR_NULLPOINTER,1);
  }

	matchno = 0;
	if (this==&gsyms[0])
		thead = SYM::GetPtr(gsyms[hashadd((char *)na.c_str())].GetHead());
	else
		thead = SYM::GetPtr(head);
	first = thead;
//	while(thead != NULL) {
//	  lfs.printf("Ele:%s|\n", (char *)thead->name->c_str());
//	  thead = thead->GetNext();
// }
 thead = first;
	while( thead != NULL) {
//		dfs.printf((char *)"|%s|,|%s|\n",(char *)thead->name->c_str(),(char *)na.c_str());
		s1 = thead->name->compare(na);
		s2 = thead->name2->compare(na);
		s3 = thead->name3->compare(na);
//		dfs.printf("s1:%d ",s1);
//		dfs.printf("s2:%d ",s2);
//		dfs.printf("s3:%d\n",s3);
		if(((s1&s2)|(s1&s3)|(s2&s3))==0) {
		  dfs.printf("Match\n");
			match[matchno] = thead;
			matchno++;
			if (matchno > 98)
				break;
		
			if (exact) {
				ta = thead->GetProtoTypes();
				if (ta->IsEqual(typearray)) {
				  dfs.printf("Exact match");
				  ta->Print();
				  typearray->Print();
				  delete ta;
				  return 1;
				}
				ta->Print();
				delete ta;
			}
		}
    thead = thead->GetNextPtr();
    if (thead==first) {
      dfs.printf("Circular list.\n");
      throw new C64PException(ERR_CIRCULAR_LIST,1);
    }
  }
  printf("Leave search2\r\n");
  return exact ? 0 : matchno;
}

int TABLE::Find(std::string na)
{
	return Find(na,(__int16)bt_long,nullptr,false);
}


// Findrising searchs the table hierarchy at higher and higher
// levels until the symbol is found.
//
int TABLE::FindRising(std::string na)
{
	int sp;
  SYM *sym;

  dfs.printf("FindRising:%s|\n",(char *)na.c_str());
  if (this==nullptr)
    return 0;
	sp = Find(na);
	if (sp)
		return sp;
	while (base) {
	  sym = SYM::GetPtr(base);
	  dfs.printf("Searching class:%s|\n",(char *)sym->name->c_str());
		sp = sym->tp->lst.Find(na);
		if (sp)
  		return sp;
		base = sym->tp->lst.base;
	}
	return 0;
}

SYM *TABLE::Find(std::string na, bool opt)
{
	Find(na,(__int16)bt_long,nullptr,false);
	if (matchno==0)
		return nullptr;
	return match[matchno-1];
}


