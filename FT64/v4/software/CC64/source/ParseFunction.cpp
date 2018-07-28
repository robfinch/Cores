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

SYM *makeint(char *name);

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

extern int funcdecl;
extern int nparms;
extern char *stkname;
extern int isVirtual;
extern bool isFuncBody;
extern bool isInline;
extern unsigned int ArgRegCount;

static Statement *ParseFunctionBody(SYM *sp);
void funcbottom(Statement *stmt);
void ListCompound(Statement *stmt);

static int round2(int n)
{
    while (n & 1) n++;
    return (n);
}

static int round8(int n)
{
    while (n & 7) n++;
    return (n);
}

// Return the stack offset where parameter storage begins.
int GetReturnBlockSize()
{
	return (4*sizeOfWord);
	if (currentFn) {
		if (currentFn->IsLeaf) {
		    return (exceptions ? sizeOfWord*3 : sizeOfWord);
		}
	}
	else
		throw new C64PException(ERR_NULLPOINTER,'R');
    return (exceptions ? sizeOfWord*3 : sizeOfWord);
}

static bool SameType(TYP *tp1, TYP *tp2)
{
	bool ret = false;

//	printf("Enter SameType\r\n");
	while(false) {
		if (tp1->type == tp2->type) {
			if (!tp1->GetBtp() && !tp2->GetBtp()) {
				ret = true;
				break;
			}
			if (tp1->GetBtp() && !tp2->GetBtp()) {
				ret = false;
				break;
			}
			if (!tp1->GetBtp() && tp2->GetBtp()) {
				ret = false;
				break;
			}
			ret = SameType(tp1->GetBtp(),tp2->GetBtp());
			break;
		}
		else {
			ret = false;
			break;
		}
	}

//	printf("Leave SameType\r\n");
	return ret;
}

void CheckParameterListMatch(SYM *s1, SYM *s2)
{
	s1 = s1->parms;
	s2 = s2->parms;
	if (!SameType(s1->tp,s2->tp))
		error(ERR_PARMLIST_MISMATCH);
}

/*      function compilation routines           */

/*
 *      funcbody starts with the current symbol being either
 *      the first parameter id or the begin for the local
 *      block. If begin is the current symbol then funcbody
 *      assumes that the function has no parameters.
 */
int ParseFunction(SYM *sp)
{
    SYM *osp;
	Statement *stmt;
	int nump, numa;
	std::string name;

  dfs.puts("<ParseFunction>\n");
  isFuncBody = true;
	if (sp==NULL) {
		fatal("Compiler error: ParseFunction: SYM is NULL\r\n");
	}
	dfs.printf("***********************************\n");
	dfs.printf("***********************************\n");
	dfs.printf("***********************************\n");
	if (sp->parent)
		dfs.printf("Parent: %s\n", (char *)sp->GetParentPtr()->name->c_str());
	dfs.printf("Parsing function: %s\n", (char *)sp->name->c_str());
	dfs.printf("***********************************\n");
	dfs.printf("***********************************\n");
	dfs.printf("***********************************\n");
	sp->stkname = stkname;
	if (verbose) printf("Parsing function: %s\r\n", (char *)sp->name->c_str());
  nump = nparms;
  iflevel = 0;
  looplevel = 0;
  	foreverlevel = 0;
		// There could be unnamed parameters in a function prototype.
	dfs.printf("A");
  // declare parameters
  // Building a parameter list here allows both styles of parameter
  // declarations. the original 'C' style is parsed here. Originally the
  // parameter types appeared as list after the parenthesis and before the
  // function body.
	sp->BuildParameterList(&nump, &numa);
	dfs.printf("B");
  sp->mangledName = sp->BuildSignature(1);  // build against parameters

	// If the symbol has a parent then it must be a class
	// method. Search the parent table(s) for matching
	// signatures.
	osp = sp;
	name = *sp->name;
	if (sp->parent) {
	  SYM *sp2;
	  dfs.printf("Parent Class:%s|",(char *)sp->GetParentPtr()->name->c_str());
		sp2 = sp->GetParentPtr()->Find(name);
		if (sp2) {
		  dfs.printf("Found at least inexact match");
      sp2 = sp->FindExactMatch(TABLE::matchno);
    }
		if (sp2 == nullptr)
      error(ERR_METHOD_NOTFOUND);
    else
      sp = sp2;
		sp->PrintParameterTypes();
	}
	else {
		if (gsyms[0].Find(name)) {
			sp = TABLE::match[TABLE::matchno-1];
		}
	}
	dfs.printf("C");

  if (sp != osp) {
    dfs.printf("ParseFunction: sp changed\n");
    osp->params.CopyTo(&sp->params);
    osp->proto.CopyTo(&sp->proto);
    sp->derivitives = osp->derivitives;
    sp->mangledName = osp->mangledName;
    // Should free osp here. It's not needed anymore
  }
	if (lastst == closepa) {
		NextToken();
		while (lastst == kw_attribute)
			Declaration::ParseFunctionAttribute(sp);
	}
	dfs.printf("D");
	if (sp->tp->type == bt_pointer) {
		if (lastst==assign) {
			doinit(sp);
		}
		sp->IsNocall = isNocall;
		sp->IsPascal = isPascal;
		sp->IsKernel = isKernel;
		sp->IsInterrupt = isInterrupt;
		sp->IsTask = isTask;
		sp->NumParms = nump;
		sp->numa = numa;
		sp->IsVirtual = isVirtual;
		sp->IsInline = isInline;
		isPascal = FALSE;
		isKernel = FALSE;
		isOscall = FALSE;
		isInterrupt = FALSE;
		isTask = FALSE;
		isNocall = FALSE;
//	    ReleaseLocalMemory();        /* release local symbols (parameters)*/
		return 1;
	}
j2:
	dfs.printf("E");
	if (lastst == semicolon) {	// Function prototype
		dfs.printf("e");
		sp->IsPrototype = 1;
		sp->IsNocall = isNocall;
		sp->IsPascal = isPascal;
		sp->IsKernel = isKernel;
		sp->IsInterrupt = isInterrupt;
		sp->IsTask = isTask;
		sp->IsVirtual = isVirtual;
		sp->IsInline = isInline;
		sp->NumParms = nump;
		sp->numa = numa;
		sp->params.MoveTo(&sp->proto);
		isPascal = FALSE;
		isKernel = FALSE;
		isOscall = FALSE;
		isInterrupt = FALSE;
		isTask = FALSE;
		isNocall = FALSE;
//	    ReleaseLocalMemory();        /* release local symbols (parameters)*/
		goto j1;
	}
	else if (lastst == kw_attribute) {
		while(lastst==kw_attribute) {
			Declaration::ParseFunctionAttribute(sp);
		}
		goto j2;
	}
	else if(lastst != begin) {
			dfs.printf("F");
//			NextToken();
//			ParameterDeclaration::Parse(2);
			sp->BuildParameterList(&nump, &numa);
			// for old-style parameter list
			//needpunc(closepa);
			if (lastst==semicolon) {
				sp->IsPrototype = 1;
				sp->IsNocall = isNocall;
				sp->IsPascal = isPascal;
				sp->IsInline = isInline;
    			sp->IsKernel = isKernel;
				sp->IsInterrupt = isInterrupt;
    			sp->IsTask = isTask;
				sp->IsRegister = isRegister;
				sp->IsVirtual = isVirtual;
				sp->NumParms = nump;
				sp->numa = numa;
				isPascal = FALSE;
    			isKernel = FALSE;
				isOscall = FALSE;
				isInterrupt = FALSE;
    			isTask = FALSE;
				isNocall = FALSE;
//				ReleaseLocalMemory();        /* release local symbols (parameters)*/
			}
			// Check for end of function parameter list.
			else if (funcdecl==2 && lastst==closepa) {
			  ;
			}
			else {
				sp->IsNocall = isNocall;
				sp->IsPascal = isPascal;
    		sp->IsKernel = isKernel;
				sp->IsInterrupt = isInterrupt;
    		sp->IsTask = isTask;
			  sp->IsVirtual = isVirtual;
			  sp->IsRegister = isRegister;
			  sp->IsInline = isInline;
				isPascal = FALSE;
    		isKernel = FALSE;
				isOscall = FALSE;
				isInterrupt = FALSE;
    		isTask = FALSE;
				isNocall = FALSE;
				sp->NumParms = nump;
				sp->numa = numa;
				stmt = ParseFunctionBody(sp);
				funcbottom(stmt);
			}
		}
//                error(ERR_BLOCK);
    else {
dfs.printf("G");
			sp->IsNocall = isNocall;
			sp->IsPascal = isPascal;
			sp->IsInline = isInline;
			sp->IsKernel = isKernel;
			sp->IsInterrupt = isInterrupt;
			sp->IsTask = isTask;
			sp->IsVirtual = isVirtual;
			isPascal = FALSE;
			isKernel = FALSE;
			isOscall = FALSE;
			isInterrupt = FALSE;
			isTask = FALSE;
			isNocall = FALSE;
			sp->NumParms = nump;
			sp->numa = numa;
			// Parsing declarations sets the storage class to extern when it really
			// should be global if there is a function body.
			if (sp->storage_class==sc_external)
				sp->storage_class =sc_global;
			stmt = ParseFunctionBody(sp);
			funcbottom(stmt);
    }
j1:
dfs.printf("F");
  dfs.puts("</ParseFunction>\n");
  return 0;
}

SYM *makeint(char *name)
{  
	SYM *sp;
	TYP *tp;

	sp = allocSYM();
	tp = TYP::Make(bt_long,2);
	tp->sname = new std::string("");
	tp->isUnsigned = FALSE;
	tp->isVolatile = FALSE;
	sp->SetName(name);
	sp->storage_class = sc_auto;
	sp->SetType(tp);
	sp->IsPrototype = FALSE;
	currentFn->lsyms.insert(sp);
	return sp;
}

void check_table(SYM *head)
{   
	while( head != 0 ) {
		if( head->storage_class == sc_ulabel )
			lfs.printf("*** UNDEFINED LABEL - %s\n",(char *)head->name->c_str());
		head = head->GetNextPtr();
	}
}

void funcbottom(Statement *stmt)
{ 
	dfs.printf("Enter funcbottom\n");
	nl();
    check_table(SYM::GetPtr(currentFn->lsyms.GetHead()));
    lc_auto = 0;
    lfs.printf("\n\n*** local symbol table ***\n\n");
    ListTable(&currentFn->lsyms,0);
	// Should recurse into all the compound statements
	if (stmt==NULL)
		dfs.printf("DIAG: null statement in funcbottom.\r\n");
	else {
		if (stmt->stype==st_compound)
			ListCompound(stmt);
	}
    lfs.printf("\n\n\n");
//    ReleaseLocalMemory();        // release local symbols
	isPascal = FALSE;
	isKernel = FALSE;
	isOscall = FALSE;
	isInterrupt = FALSE;
	isNocall = FALSE;
	dfs.printf("Leave funcbottom\n");
}

std::string TraceName(SYM *sp)
{
  std::string namebuf;
  SYM *vector[64];
  int deep = 0;

  do {
    vector[deep] = sp;
    sp = sp->GetParentPtr();
    deep++;
    if (deep > 63) {
      break; // should be an error
    }
  } while (sp);
  deep--;
  namebuf = "";
  while(deep > 0) {
    namebuf += *vector[deep]->name;
    namebuf += "_";
    deep--;
  }
  namebuf += *vector[deep]->name;
  return namebuf;
}

static Statement *ParseFunctionBody(SYM *sp)
{    
	std::string lbl;
	char *p;
	OCODE *ip;

  dfs.printf("<Parse function body>:%s|\n", (char *)sp->name->c_str());

	lbl = std::string("");
	needpunc(begin,47);
     
  tmpReset();
    //ParseAutoDeclarations();
	cseg();
	if (sp->storage_class == sc_static)
	{
		//strcpy(lbl,GetNamespace());
		//strcat(lbl,"_");
//		strcpy(lbl,sp->name);
    lbl = *sp->mangledName;
		//gen_strlab(lbl);
	}
	//	put_label((unsigned int) sp->value.i);
	else {
		if (sp->storage_class == sc_global)
			lbl = "public code ";
//		strcat(lbl,sp->name);
		lbl += *sp->mangledName;
		//gen_strlab(lbl);
	}
  dfs.printf("B");
  p = my_strdup((char *)lbl.c_str());
  dfs.printf("b");
	if (!sp->IsInline)
		GenerateMonadicNT(op_fnname,0,make_string(p));
	currentFn = sp;
	currentFn->IsLeaf = TRUE;
	currentFn->DoesThrow = FALSE;
	currentFn->UsesPredicate = FALSE;
	currentFn->UsesNew = FALSE;
	regmask = 0;
	bregmask = 0;
	currentStmt = (Statement *)NULL;
  dfs.printf("C");
  stmtdepth = 0;
	sp->stmt = Statement::ParseCompound();
  dfs.printf("D");
//	stmt->stype = st_funcbody;
	while( lc_auto % sizeOfWord )	// round frame size to word
		++lc_auto;
	sp->stkspace = lc_auto;
	if (!sp->IsInline) {
		pass = 1;
		ip = peep_tail;
		looplevel = 0;
		GenerateFunction(sp);
		sp->stkspace += (ArgRegCount-regFirstArg) * sizeOfWord;
		sp->argbot = -sp->stkspace;
		sp->stkspace += GetTempMemSpace();
		sp->tempbot = -sp->stkspace;
		pass = 2;
		peep_tail = ip;
		peep_tail->fwd = nullptr;
		looplevel = 0;
		GenerateFunction(sp);
		dfs.putch('E');

		flush_peep();
		if (sp->storage_class == sc_global) {
			ofs.printf("endpublic\r\n\r\n");
		}
	}
	//if (sp->stkspace)
	//ofs.printf("%sSTKSIZE_ EQU %d\r\n", (char *)sp->mangledName->c_str(), sp->stkspace);
	isFuncBody = false;
	dfs.printf("</ParseFunctionBody>\n");
	return sp->stmt;
}

int TempBot()
{
	return (currentFn->tempbot);
}

