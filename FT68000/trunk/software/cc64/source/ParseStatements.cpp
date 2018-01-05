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

extern TYP *head, *tail;
extern TYP stdbyte;
extern int catchdecl;
Statement *ParseCatchStatement();
int iflevel;
int looplevel;
int foreverlevel;
int loopexit;
Statement *currentStmt;
char *llptr;
extern char *lptr;
extern char inpline[132];

Statement *NewStatement(int typ, int gt) {
	Statement *s = (Statement *)xalloc(sizeof(Statement));
	memset(s, '\0', sizeof(Statement));
	s->stype = typ;
	s->predreg = -1;
	s->outer = currentStmt;
	s->s1 = (Statement *)NULL;
	s->s2 = (Statement *)NULL;
	s->ssyms.Clear();
	s->lptr = my_strdup(inpline);
	s->prediction = 0;
	//memset(s->ssyms,0,sizeof(s->ssyms));
	if (gt) NextToken();
	return s;
};


int GetTypeHash(TYP *p)
{
	int n;
	TYP *p1;

	n = 0;
	do {
		if (p->type==bt_pointer)
			n+=20000;
		p1 = p;
		p = p->GetBtp();
	} while (p);
	n += p1->typeno;
	return n;
}


Statement *ParseCheckStatement() 
{       
	Statement *snp;
    snp = NewStatement(st_check, TRUE);
    if( expression(&(snp->exp)) == 0 ) 
        error(ERR_EXPREXPECT); 
    needpunc( semicolon,31 );
    return snp; 
} 
  
Statement *Statement::ParseWhile() 
{       
	Statement *snp;

	currentFn->UsesPredicate = TRUE;
    snp = NewStatement(st_while, TRUE);
	snp->predreg = iflevel;
	iflevel++;
	looplevel++;
	if ((iflevel > maxPn-1) && isThor)
	    error(ERR_OUTOFPREDS);
    if( lastst != openpa ) 
        error(ERR_EXPREXPECT); 
    else { 
        NextToken(); 
        if( expression(&(snp->exp)) == 0 ) 
            error(ERR_EXPREXPECT); 
        needpunc( closepa,13 ); 
		if (lastst==kw_do)
			NextToken();
        snp->s1 = Statement::Parse(); 
		// Empty statements return NULL
		if (snp->s1)
			snp->s1->outer = snp;
    } 
	iflevel--;
	looplevel--;
    return snp; 
} 
  
Statement *Statement::ParseUntil()
{
	Statement *snp; 

	currentFn->UsesPredicate = TRUE;
    snp = NewStatement(st_until, TRUE);
	snp->predreg = iflevel;
	iflevel++;
	looplevel++;
	if ((iflevel > maxPn-1) && isThor)
	    error(ERR_OUTOFPREDS);
    if( lastst != openpa ) 
        error(ERR_EXPREXPECT); 
    else { 
        NextToken(); 
        if( expression(&(snp->exp)) == 0 ) 
            error(ERR_EXPREXPECT); 
        needpunc( closepa,14 ); 
        snp->s1 = Statement::Parse(); 
		// Empty statements return NULL
		if (snp->s1)
			snp->s1->outer = snp;
   	} 
	iflevel--;
	looplevel--;
    return snp; 
} 
  
Statement *Statement::ParseDo() 
{       
	Statement *snp; 

	currentFn->UsesPredicate = TRUE;
	snp = NewStatement(st_do, TRUE); 
	snp->predreg = iflevel;
	iflevel++;
	looplevel++;
	if ((iflevel > maxPn-1) && isThor)
	    error(ERR_OUTOFPREDS);
    snp->s1 = Statement::Parse(); 
	// Empty statements return NULL
	if (snp->s1)
		snp->s1->outer = snp;
	if (lastst == kw_until)
		snp->stype = st_dountil;
	else if (lastst== kw_loop)
		snp->stype = st_doloop;
    if( lastst != kw_while && lastst != kw_until && lastst != kw_loop ) 
        error(ERR_WHILEXPECT); 
    else { 
        NextToken(); 
		if (snp->stype!=st_doloop) {
        if( expression(&(snp->exp)) == 0 ) 
            error(ERR_EXPREXPECT); 
		}
        if( lastst != end )
            needpunc( semicolon,15 );
    } 
	iflevel--;
	looplevel--;
    return snp; 
} 
  
Statement *Statement::ParseFor() 
{
	Statement *snp; 

	currentFn->UsesPredicate = TRUE;
	snp = NewStatement(st_for, TRUE);
	snp->predreg = iflevel;
	iflevel++;
	looplevel++;
	if ((iflevel > maxPn-1) && isThor)
	    error(ERR_OUTOFPREDS);
    needpunc(openpa,16); 
    if( expression(&(snp->initExpr)) == NULL ) 
        snp->initExpr = (ENODE *)NULL; 
    needpunc(semicolon,32); 
    if( expression(&(snp->exp)) == NULL ) 
        snp->exp = (ENODE *)NULL; 
    needpunc(semicolon,17); 
    if( expression(&(snp->incrExpr)) == NULL ) 
        snp->incrExpr = (ENODE *)NULL; 
    needpunc(closepa,18); 
    snp->s1 = Statement::Parse(); 
	// Empty statements return NULL
	if (snp->s1)
		snp->s1->outer = snp;
	iflevel--;
	looplevel--;
    return snp; 
} 

// The forever statement tries to detect if there's an infinite loop and a
// warning is output if there is no obvious loop exit.
// Statements that might exit a loop set the loopexit variable true. These
// statements include throw, return, break, and goto. There are other ways
// to exit a loop that aren't easily detectable (exit() or setjmp).

Statement *Statement::ParseForever() 
{
	Statement *snp; 
    snp = NewStatement(st_forever, TRUE);
    snp->stype = st_forever; 
    foreverlevel = looplevel;
    snp->s1 = Statement::Parse(); 
    if (loopexit==0)
    	error(ERR_INFINITELOOP);
	// Empty statements return NULL
	if (snp->s1)
		snp->s1->outer = snp;
    return snp; 
} 

  
// Firstcall allocates a hidden static variable that tracks the first time
// the firstcall statement is entered.
 
Statement *Statement::ParseFirstcall() 
{
	Statement *snp; 
	SYM *sp;
	int st;

	dfs.puts("<ParseFirstcall>");
	snp = NewStatement(st_firstcall, TRUE); 
	sp = allocSYM();
	//	sp->SetName(*(new std::string(snp->fcname)));
	sp->storage_class = sc_static;
	sp->value.i = nextlabel++;
	sp->tp = &stdbyte;
	st = lastst;
	lastst = kw_firstcall;       // fake out doinit()
	doinit(sp);
	lastst = st;
	// doinit should set realname
	snp->fcname = my_strdup(sp->realname);
	snp->s1 = Statement::Parse(); 
	// Empty statements return NULL
	if (snp->s1)
		snp->s1->outer = snp;
	dfs.puts("</ParseFirstcall>");
	return snp; 
} 
  
Statement *Statement::ParseIf() 
{
	Statement *snp; 

	dfs.puts("<ParseIf>");
	NextToken();
	if (lastst == kw_firstcall)
		return (ParseFirstcall());
	currentFn->UsesPredicate = TRUE;
	snp = NewStatement(st_if, FALSE);
	snp->predreg = iflevel;
	iflevel++;
	if ((iflevel > maxPn-1) && isThor)
		error(ERR_OUTOFPREDS);
	if( lastst != openpa ) 
		error(ERR_EXPREXPECT); 
	else {
		NextToken(); 
		if( expression(&(snp->exp)) == 0 ) 
			error(ERR_EXPREXPECT); 
		if (lastst == semicolon) {
			NextToken();
			snp->prediction = (GetIntegerExpression(NULL) & 1) | 2;
		}
		needpunc( closepa,19 ); 
		if (lastst==kw_then)
			NextToken();
		snp->s1 = Statement::Parse(); 
		if (snp->s1)
			snp->s1->outer = snp;
		if( lastst == kw_else ) { 
			NextToken(); 
			snp->s2 = Statement::Parse(); 
			if (snp->s2)
				snp->s2->outer = snp;
		} 
		else if (lastst == kw_elsif) {
			snp->s2 = ParseIf(); 
			if (snp->s2)
				snp->s2->outer = snp;
		}
		else 
			snp->s2 = 0; 
	} 
	iflevel--;
	dfs.puts("</ParseIf>");
	return snp; 
} 

Statement *Statement::ParseCatch()
{
	Statement *snp;
	SYM *sp;
	TYP *tp,*tp1,*tp2;
    ENODE *node;
    static char buf[200];
    
	snp = NewStatement(st_catch, TRUE);
	currentStmt = snp;
	if (lastst != openpa) {
		snp->label = (int64_t *)NULL;
		snp->s2 = (Statement *)99999;
		snp->s1 = Statement::Parse();
		// Empty statements return NULL
		if (snp->s1)
			snp->s1->outer = snp;
		return snp;
	}
    needpunc(openpa,33);
	tp = head;
	tp1 = tail;
	catchdecl = TRUE;
	AutoDeclaration::Parse(NULL,&snp->ssyms);
	cseg();
	catchdecl = FALSE;
	tp2 = head;
	head = tp;
	tail = tp1;
    needpunc(closepa,34);
    
	if( (sp = snp->ssyms.Find(*declid,false)) == NULL)
        sp = makeint((char *)declid->c_str());
    node = makenode(sp->storage_class==sc_static ? en_labcon : en_autocon,NULL,NULL);
    // nameref looks up the symbol using lastid, so we need to back it up and
    // restore it.
    strncpy_s(buf,sizeof(buf),lastid,199);
    strncpy_s(lastid, sizeof(lastid), declid->c_str(),sizeof(lastid)-1);
    nameref(&node,FALSE);
    strcpy_s(lastid,sizeof(lastid),buf);
	snp->s1 = Statement::Parse();
	// Empty statements return NULL
	if (snp->s1)
		snp->s1->outer = snp;
	snp->exp = node;	// save name reference
	if (sp->tp->typeno >= bt_last)
		error(ERR_CATCHSTRUCT);
	snp->num = sp->tp->GetHash();
	// Empty statements return NULL
//	if (snp->s2)
//		snp->s2->outer = snp;
	return snp;
}

Statement *Statement::ParseCase()
{
	Statement *snp; 
    Statement *head, *tail;
	int64_t buf[256];
	int nn;
	int64_t *bf;

    snp = NewStatement(st_case, FALSE); 
	if (lastst == kw_fallthru)	// ignore "fallthru"
		NextToken();
    if( lastst == kw_case ) { 
        NextToken(); 
        snp->s2 = 0;
		nn = 0;
		do {
			buf[nn] = GetIntegerExpression((ENODE **)NULL);
			nn++;
			if (lastst != comma)
				break;
			NextToken();
		} while (nn < 256);
		if (nn==256)
			error(ERR_TOOMANYCASECONSTANTS);
		bf = (int64_t *)xalloc(sizeof(int64_t)*(nn+1));
		bf[0] = nn;
		for (; nn > 0; nn--)
			bf[nn]=buf[nn-1];
		snp->casevals = (int64_t *)bf;
    }
    else if( lastst == kw_default) { 
        NextToken(); 
        snp->s2 = (Statement *)1; 
		snp->stype = st_default;
    } 
    else { 
        error(ERR_NOCASE); 
        return (Statement *)NULL;
    } 
    needpunc(colon,35); 
    head = (Statement *)NULL; 
    while( lastst != end && lastst != kw_case && lastst != kw_default ) { 
		if( head == NULL ) {
			head = tail = Statement::Parse(); 
			if (head)
				head->outer = snp;
		}
		else { 
			tail->next = Statement::Parse(); 
			if( tail->next != NULL )  {
				tail->next->outer = snp;
				tail = tail->next;
			}
		}
        tail->next = 0; 
    } 
    snp->s1 = head; 
    return (snp); 
} 
  
int Statement::CheckForDuplicateCases() 
{     
	Statement *head;
	Statement *top, *cur, *def;
	int cnt, cnt2;
	static int64_t buf[1000];
	int ndx;

	ndx = 0;
	head = this;
	cur = top = head;
	for (top = head; top != (Statement *)NULL; top = top->next)
	{
		if (top->casevals) {
			for (cnt = 1; cnt < top->casevals[0]+1; cnt++) {
				for (cnt2 = 0; cnt2 < ndx; cnt2++)
					if (top->casevals[cnt]==buf[cnt2])
						return (TRUE);
				if (ndx > 999)
					throw new C64PException(ERR_TOOMANYCASECONSTANTS,1);
				buf[ndx] = top->casevals[cnt];
				ndx++;
			}
		}
	}

	// Check for duplicate default: statement
	def = nullptr;
	for (top = head; top != (Statement *)NULL; top = top->next )
	{
		if (top->s2 && def)
			return (TRUE);
		if (top->s2)
			def = top->s2;
	}
	return (FALSE);
} 
  
Statement *Statement::ParseSwitch() 
{       
	Statement *snp; 
    Statement *head, *tail; 

    snp = NewStatement(st_switch, TRUE);
	snp->nkd = false;
	iflevel++;
	looplevel++;
	needpunc(openpa,0);
    if( expression(&(snp->exp)) == NULL ) 
        error(ERR_EXPREXPECT); 
	if (lastst==semicolon) {
		NextToken();
		if (lastst==kw_naked) {
			NextToken();
			snp->nkd = true;
		}
	}
	needpunc(closepa,0);
    needpunc(begin,36); 
    head = 0; 
    while( lastst != end ) { 
		if( head == (Statement *)NULL ) {
			head = tail = ParseCase(); 
			if (head)
				head->outer = snp;
		}
		else { 
			tail->next = ParseCase(); 
			if( tail->next != (Statement *)NULL ) {
				tail->next->outer = snp;
				tail = tail->next;
			}
		}
		if (tail==(Statement *)NULL) break;	// end of file in switch
        tail->next = (Statement *)NULL; 
    } 
    snp->s1 = head; 
    NextToken(); 
    if( head->CheckForDuplicateCases() ) 
        error(ERR_DUPCASE); 
	iflevel--;
	looplevel--;
    return (snp); 
} 
  
Statement *Statement::ParseReturn() 
{       
	Statement *snp;

	loopexit = TRUE;
	snp = NewStatement(st_return, TRUE);
    expression(&(snp->exp));
    if( lastst != end )
        needpunc( semicolon,37 );
    return (snp); 
} 
  
Statement *Statement::ParseThrow() 
{  
	Statement *snp;
	TYP *tp;

	currentFn->DoesThrow = TRUE;
	loopexit = TRUE;
	snp = NewStatement(st_throw, TRUE);
    tp = expression(&(snp->exp));
	snp->num = tp->GetHash();
    if( lastst != end )
        needpunc( semicolon,38 );
    return (snp);
} 
  
Statement *Statement::ParseBreak() 
{     
	Statement *snp; 

	snp = NewStatement(st_break, TRUE);
    if( lastst != end )
        needpunc( semicolon,39 );
    if (looplevel==foreverlevel)
    	loopexit = TRUE;
    return (snp); 
} 
  
Statement *Statement::ParseContinue() 
{
	Statement *snp; 

    snp = NewStatement(st_continue, TRUE);
    if( lastst != end )
        needpunc( semicolon,40 );
    return (snp);
} 
  
Statement *Statement::ParseStop() 
{
	Statement *snp; 

	snp = NewStatement(st_stop, TRUE); 
	snp->num = (int)GetIntegerExpression(NULL);
	if( lastst != end )
		needpunc( semicolon,43 );
	return snp;
} 
  
Statement *Statement::ParseAsm() 
{
	static char buf[3501];
	int nn;
	bool first = true;

	Statement *snp; 
    snp = NewStatement(st_asm, FALSE); 
    while( my_isspace(lastch) )
		getch(); 
    NextToken();
    if (lastst == kw_leafs) {
    	currentFn->IsLeaf = FALSE;
	    while( my_isspace(lastch) )
			getch(); 
    	NextToken();
	}
	if (lastst != begin)
		error(ERR_PUNCT);
	nn = 0;
	do {
		// skip over leading spaces on the line
		getch();
		while (isspace(lastch)) getch();
		if (lastch=='}')
			break;
		if (lastch=='\r' || lastch=='\n')
			continue;
		if (nn < 3500) buf[nn++] = '\n';
		if (nn < 3500) buf[nn++] = '\t';
		if (nn < 3500) buf[nn++] = '\t';
		if (nn < 3500) buf[nn++] = '\t';
		if (nn < 3500) buf[nn++] = lastch;
		while(lastch != '\n') {
			getch();
			if (lastch=='}')
				goto j1;
			if (lastch=='\r' || lastch=='\n')
				break;
			if (nn < 3500) buf[nn++] = lastch;
		}
	}
	while(lastch!=-1 && nn < 3500);
j1:
	if (nn >= 3500)
		error(ERR_ASMTOOLONG);
	buf[nn] = '\0';
	snp->label = (int64_t *)my_strdup(buf);
    return snp;
} 

Statement *Statement::ParseTry()
{
	Statement *snp;
	Statement *hd, *tl;

	hd = (Statement *)NULL;
	tl = (Statement *)NULL;
	snp = NewStatement(st_try, TRUE);
    snp->s1 = Statement::Parse();
	// Empty statements return NULL
	if (snp->s1)
		snp->s1->outer = snp;
	if (lastst != kw_catch)
        error(ERR_CATCHEXPECT);
    while( lastst == kw_catch ) {
		if( hd == NULL ) {
			hd = tl = ParseCatch(); 
			if (hd)
				hd->outer = snp;
		}
		else { 
			tl->next = ParseCatch(); 
			if( tl->next != NULL ) {
				tl->next->outer = snp;
				tl = tl->next;
			}
		}
		if (tl==(Statement *)NULL) break;	// end of file in try
        tl->next = (Statement *)NULL; 
    } 
    snp->s2 = hd;
    return snp;
} 
  
Statement *Statement::ParseExpression() 
{       
	Statement *snp;

	dfs.printf("<ParseExpression>\n");
	snp = NewStatement(st_expr, FALSE); 
	if( expression(&(snp->exp)) == NULL ) { 
		error(ERR_EXPREXPECT);
		NextToken(); 
	} 
	if( lastst != end )
		needpunc( semicolon,44 );
	dfs.printf("</ParseExpression>\n");
	return snp; 
} 

// Parse a compound statement.

Statement *Statement::ParseCompound()
{  
	Statement *snp;
	Statement *head, *tail; 
	Statement *p;

	snp = NewStatement(st_compound, FALSE); 
	currentStmt = snp;
	head = 0;
	if (lastst==colon) {
		NextToken();
		TRACE(printf("Compound <%s>\r\n",lastid);)
		if (strcmp(lastid,"clockbug")==0)
		printf("clockbug\r\n");
		NextToken();
	}
	AutoDeclaration::Parse(NULL,&snp->ssyms);
	cseg();
	// Add the first statement at the head of the list.
	p = currentStmt;
	if (lastst==kw_prolog) {
		NextToken();
		currentFn->prolog = snp->prolog = Statement::Parse();
	}
	if (lastst==kw_epilog) {
		NextToken();
		currentFn->epilog = snp->epilog = Statement::Parse();
	}
	if (lastst==kw_prolog) {
		NextToken();
		currentFn->prolog = snp->prolog = Statement::Parse();
	}
	if (lastst != end) {
		head = tail = Statement::Parse(); 
		if (head)
			head->outer = snp;
	}
	//else {
	//       head = tail = NewStatement(st_empty,1);
	//	if (head)
	//		head->outer = snp;
	//}
	// Add remaining statements onto the tail of the list.
	while( lastst != end) {
		if (lastst==kw_prolog) {
			NextToken();
			currentFn->prolog = snp->prolog = Statement::Parse();
		}
		else if (lastst==kw_epilog) {
			NextToken();
			currentFn->epilog = snp->epilog = Statement::Parse();
		}
		else
		{
			tail->next = Statement::Parse(); 
			if( tail->next != NULL ) {
				tail->next->outer = snp;
				tail = tail->next;
			}
		}
	}
	currentStmt = p;
	NextToken();
	snp->s1 = head;
	return (snp);
} 
  
Statement *Statement::ParseLabel()
{      
	Statement *snp;
	SYM *sp;

	snp = NewStatement(st_label, FALSE); 
	if( (sp = currentFn->lsyms.Find(lastid,false)) == NULL ) { 
		sp = allocSYM(); 
		sp->SetName(*(new std::string(lastid)));
		sp->storage_class = sc_label; 
		sp->tp = TYP::Make(bt_label,0);
		sp->value.i = nextlabel++; 
		currentFn->lsyms.insert(sp); 
	} 
	else { 
		if( sp->storage_class != sc_ulabel ) 
			error(ERR_LABEL); 
		else 
			sp->storage_class = sc_label; 
	} 
	NextToken();       /* get past id */ 
	needpunc(colon,45); 
	if( sp->storage_class == sc_label ) { 
		snp->label = (int64_t *)sp->value.i; 
		snp->next = (Statement *)NULL; 
		return snp; 
	} 
	return 0; 
} 
  
Statement *Statement::ParseGoto() 
{       
	Statement *snp; 
    SYM *sp;

    NextToken(); 
    loopexit = TRUE;
    if( lastst != id ) { 
        error(ERR_IDEXPECT); 
        return ((Statement *)NULL);
    } 
    snp = NewStatement(st_goto, FALSE);
    if( (sp = currentFn->lsyms.Find(lastid,false)) == NULL ) { 
        sp = allocSYM(); 
        sp->SetName(*(new std::string(lastid)));
        sp->value.i = nextlabel++; 
        sp->storage_class = sc_ulabel; 
        sp->tp = 0; 
        currentFn->lsyms.insert(sp); 
    }
    NextToken();       /* get past label name */
    if( lastst != end )
        needpunc( semicolon,46 );
    if( sp->storage_class != sc_label && sp->storage_class != sc_ulabel)
        error( ERR_LABEL );
    else { 
        snp->stype = st_goto;
        snp->label = (int64_t *)sp->value.i;
        snp->next = (Statement *)NULL;
        return (snp); 
    } 
    return ((Statement *)NULL);
} 
  
Statement *Statement::Parse() 
{
	Statement *snp; 
	dfs.puts("<Parse>");
    switch( lastst ) { 
    case semicolon: 
        snp = NewStatement(st_empty,1);
        break; 
    case begin: 
		NextToken(); 
        snp = ParseCompound();
        return snp; 
    case kw_check:
         snp = ParseCheckStatement();
         break;
	/*
    case kw_prolog:
         snp = NewStatement(st_empty,1);
         currentFn->prolog = Statement::Parse(); break;
    case kw_epilog:
         snp = NewStatement(st_empty,1);
         currentFn->epilog = Statement::Parse(); break;
	*/
    case kw_if: snp = ParseIf(); break; 
    case kw_while: snp = ParseWhile(); break; 
    case kw_until: snp = ParseUntil(); break; 
    case kw_for:   snp = ParseFor();   break; 
    case kw_forever: snp = ParseForever(); break; 
    case kw_firstcall: snp = ParseFirstcall(); break; 
    case kw_return: snp = ParseReturn(); break; 
    case kw_break: snp = ParseBreak(); break; 
    case kw_goto: snp = ParseGoto(); break; 
    case kw_continue: snp = ParseContinue(); break; 
    case kw_do:
	case kw_loop: snp = ParseDo(); break; 
    case kw_switch: snp = ParseSwitch(); break;
	case kw_try: snp = ParseTry(); break;
	case kw_throw: snp = ParseThrow(); break;
	case kw_stop: snp = ParseStop(); break;
	case kw_asm: snp = ParseAsm(); break;
    case id:
			SkipSpaces();
            if( lastch == ':' ) 
                return ParseLabel(); 
            // else fall through to parse expression
    default: 
            snp = ParseExpression(); 
            break; 
    } 
	if( snp != NULL ) {
        snp->next = (Statement *)NULL;
	}
	dfs.puts("</Parse>");
	return snp;
} 

