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

int     breaklab;
int     contlab;
int     retlab;
int		throwlab;

int lastsph;
char *semaphores[20];
char last_rem[132];

extern TYP              stdfunc;

static SYM *makeint(char *name)
{
	SYM *sp;
	TYP *tp;

	sp = allocSYM();
	tp = TYP::Make(bt_long, 8);
	tp->sname = new std::string("");
	tp->isUnsigned = FALSE;
	tp->isVolatile = FALSE;
	sp->SetName(name);
	sp->storage_class = sc_auto;
	sp->SetType(tp);
	currentFn->sym->lsyms.insert(sp);
	return (sp);
}


Statement *NewStatement(int typ, int gt) {
	Statement *s = (Statement *)xalloc(sizeof(Statement));
	ZeroMemory(s, sizeof(Statement));
	s->stype = typ;
	s->predreg = -1;
	s->outer = currentStmt;
	s->s1 = (Statement *)NULL;
	s->s2 = (Statement *)NULL;
	s->ssyms.Clear();
	s->lptr = my_strdup(inpline);
	s->prediction = 0;
	s->depth = stmtdepth;
	//memset(s->ssyms,0,sizeof(s->ssyms));
	if (gt) NextToken();
	return s;
};


Statement *ParseCheckStatement()
{
	Statement *snp;
	snp = NewStatement(st_check, TRUE);
	if (expression(&(snp->exp)) == 0)
		error(ERR_EXPREXPECT);
	needpunc(semicolon, 31);
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
	if ((iflevel > maxPn - 1) && isThor)
		error(ERR_OUTOFPREDS);
	if (lastst != openpa)
		error(ERR_EXPREXPECT);
	else {
		NextToken();
		if (expression(&(snp->exp)) == 0)
			error(ERR_EXPREXPECT);
		needpunc(closepa, 13);
		if (lastst == kw_do)
			NextToken();
		snp->s1 = Statement::Parse();
		// Empty statements return NULL
		if (snp->s1)
			snp->s1->outer = snp;
	}
	iflevel--;
	looplevel--;
	return (snp);
}

Statement *Statement::ParseUntil()
{
	Statement *snp;

	currentFn->UsesPredicate = TRUE;
	snp = NewStatement(st_until, TRUE);
	snp->predreg = iflevel;
	iflevel++;
	looplevel++;
	if ((iflevel > maxPn - 1) && isThor)
		error(ERR_OUTOFPREDS);
	if (lastst != openpa)
		error(ERR_EXPREXPECT);
	else {
		NextToken();
		if (expression(&(snp->exp)) == 0)
			error(ERR_EXPREXPECT);
		needpunc(closepa, 14);
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
	snp->s1 = Statement::Parse();
	// Empty statements return NULL
	if (snp->s1)
		snp->s1->outer = snp;
	switch (lastst) {
	case kw_until:	snp->stype = st_dountil; break;
	case kw_loop:	snp->stype = st_doloop; break;
	case kw_while:	snp->stype = st_dowhile; break;
	default:	snp->stype = st_doonce; break;
	}
	if (lastst != kw_while && lastst != kw_until && lastst != kw_loop)
		error(ERR_WHILEXPECT);
	else {
		NextToken();
		if (snp->stype != st_doloop) {
			if (expression(&(snp->exp)) == 0)
				error(ERR_EXPREXPECT);
		}
		if (lastst != end)
			needpunc(semicolon, 15);
	}
	iflevel--;
	looplevel--;
	return (snp);
}

Statement *Statement::ParseFor()
{
	Statement *snp;

	currentFn->UsesPredicate = TRUE;
	snp = NewStatement(st_for, TRUE);
	snp->predreg = iflevel;
	iflevel++;
	looplevel++;
	if ((iflevel > maxPn - 1) && isThor)
		error(ERR_OUTOFPREDS);
	needpunc(openpa, 16);
	if (expression(&(snp->initExpr)) == NULL)
		snp->initExpr = (ENODE *)NULL;
	needpunc(semicolon, 32);
	if (expression(&(snp->exp)) == NULL)
		snp->exp = (ENODE *)NULL;
	needpunc(semicolon, 17);
	if (expression(&(snp->incrExpr)) == NULL)
		snp->incrExpr = (ENODE *)NULL;
	needpunc(closepa, 18);
	snp->s1 = Statement::Parse();
	// Empty statements return NULL
	if (snp->s1)
		snp->s1->outer = snp;
	iflevel--;
	looplevel--;
	return (snp);
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
	if (loopexit == 0)
		error(ERR_INFINITELOOP);
	// Empty statements return NULL
	if (snp->s1)
		snp->s1->outer = snp;
	return (snp);
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
	bool needpa = true;

	dfs.puts("<ParseIf>");
	NextToken();
	if (lastst == kw_firstcall)
		return (ParseFirstcall());
	currentFn->UsesPredicate = TRUE;
	snp = NewStatement(st_if, FALSE);
	snp->predreg = iflevel;
	iflevel++;
	if (lastst != openpa)
		needpa = false;
	NextToken();
	if (expression(&(snp->exp)) == 0)
		error(ERR_EXPREXPECT);
	if (lastst == semicolon) {
		NextToken();
		snp->prediction = (GetIntegerExpression(NULL) & 1) | 2;
	}
	if (needpa)
		needpunc(closepa, 19);
	else if (lastst != kw_then)
		error(ERR_SYNTAX);
	if (lastst == kw_then)
		NextToken();
	snp->s1 = Statement::Parse();
	if (snp->s1)
		snp->s1->outer = snp;
	if (lastst == kw_else) {
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
	iflevel--;
	dfs.puts("</ParseIf>");
	return (snp);
}

Statement *Statement::ParseCatch()
{
	Statement *snp;
	SYM *sp;
	TYP *tp, *tp1, *tp2;
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
	needpunc(openpa, 33);
	tp = head;
	tp1 = tail;
	catchdecl = TRUE;
	AutoDeclaration::Parse(NULL, &snp->ssyms);
	cseg();
	catchdecl = FALSE;
	tp2 = head;
	head = tp;
	tail = tp1;
	needpunc(closepa, 34);

	if ((sp = snp->ssyms.Find(*declid, false)) == NULL)
		sp = makeint((char *)declid->c_str());
	node = makenode(sp->storage_class == sc_static ? en_labcon : en_autocon, NULL, NULL);
	// nameref looks up the symbol using lastid, so we need to back it up and
	// restore it.
	strncpy_s(buf, sizeof(buf), lastid, 199);
	strncpy_s(lastid, sizeof(lastid), declid->c_str(), sizeof(lastid) - 1);
	nameref(&node, FALSE);
	strcpy_s(lastid, sizeof(lastid), buf);
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
	if (lastst == kw_case) {
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
		if (nn == 256)
			error(ERR_TOOMANYCASECONSTANTS);
		bf = (int64_t *)xalloc(sizeof(int64_t)*(nn + 1));
		bf[0] = nn;
		for (; nn > 0; nn--)
			bf[nn] = buf[nn - 1];
		snp->casevals = (int64_t *)bf;
	}
	else if (lastst == kw_default) {
		NextToken();
		snp->s2 = (Statement *)1;
		snp->stype = st_default;
	}
	else {
		error(ERR_NOCASE);
		return (Statement *)NULL;
	}
	needpunc(colon, 35);
	head = (Statement *)NULL;
	while (lastst != end && lastst != kw_case && lastst != kw_default) {
		if (head == NULL) {
			head = tail = Statement::Parse();
			if (head)
				head->outer = snp;
		}
		else {
			tail->next = Statement::Parse();
			if (tail->next != NULL) {
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
			for (cnt = 1; cnt < top->casevals[0] + 1; cnt++) {
				for (cnt2 = 0; cnt2 < ndx; cnt2++)
					if (top->casevals[cnt] == buf[cnt2])
						return (TRUE);
				if (ndx > 999)
					throw new C64PException(ERR_TOOMANYCASECONSTANTS, 1);
				buf[ndx] = top->casevals[cnt];
				ndx++;
			}
		}
	}

	// Check for duplicate default: statement
	def = nullptr;
	for (top = head; top != (Statement *)NULL; top = top->next)
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
	needpunc(openpa, 0);
	if (expression(&(snp->exp)) == NULL)
		error(ERR_EXPREXPECT);
	if (lastst == semicolon) {
		NextToken();
		if (lastst == kw_naked) {
			NextToken();
			snp->nkd = true;
		}
	}
	needpunc(closepa, 0);
	needpunc(begin, 36);
	head = 0;
	while (lastst != end) {
		if (head == (Statement *)NULL) {
			head = tail = ParseCase();
			if (head)
				head->outer = snp;
		}
		else {
			tail->next = ParseCase();
			if (tail->next != (Statement *)NULL) {
				tail->next->outer = snp;
				tail = tail->next;
			}
		}
		if (tail == (Statement *)NULL) break;	// end of file in switch
		tail->next = (Statement *)NULL;
	}
	snp->s1 = head;
	NextToken();
	if (head->CheckForDuplicateCases())
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
	if (lastst != end)
		needpunc(semicolon, 37);
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
	if (lastst != end)
		needpunc(semicolon, 38);
	return (snp);
}

Statement *Statement::ParseBreak()
{
	Statement *snp;

	snp = NewStatement(st_break, TRUE);
	if (lastst != end)
		needpunc(semicolon, 39);
	if (looplevel == foreverlevel)
		loopexit = TRUE;
	return (snp);
}

Statement *Statement::ParseContinue()
{
	Statement *snp;

	snp = NewStatement(st_continue, TRUE);
	if (lastst != end)
		needpunc(semicolon, 40);
	return (snp);
}

Statement *Statement::ParseStop()
{
	Statement *snp;

	snp = NewStatement(st_stop, TRUE);
	snp->num = (int)GetIntegerExpression(NULL);
	if (lastst != end)
		needpunc(semicolon, 43);
	return snp;
}

Statement *Statement::ParseAsm()
{
	static char buf[3501];
	int nn;
	bool first = true;

	Statement *snp;
	snp = NewStatement(st_asm, FALSE);
	while (my_isspace(lastch))
		getch();
	NextToken();
	if (lastst == kw_leafs) {
		currentFn->IsLeaf = FALSE;
		while (my_isspace(lastch))
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
		if (lastch == '}')
			break;
		if (lastch == '\r' || lastch == '\n')
			continue;
		if (nn < 3500) buf[nn++] = '\n';
		if (nn < 3500) buf[nn++] = '\t';
		if (nn < 3500) buf[nn++] = '\t';
		if (nn < 3500) buf[nn++] = '\t';
		if (nn < 3500) buf[nn++] = lastch;
		while (lastch != '\n') {
			getch();
			if (lastch == '}')
				goto j1;
			if (lastch == '\r' || lastch == '\n')
				break;
			if (nn < 3500) buf[nn++] = lastch;
		}
	} while (lastch != -1 && nn < 3500);
j1:
	if (nn >= 3500)
		error(ERR_ASMTOOLONG);
	buf[nn] = '\0';
	snp->label = (int64_t *)my_strdup(buf);
	return (snp);
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
	while (lastst == kw_catch) {
		if (hd == NULL) {
			hd = tl = ParseCatch();
			if (hd)
				hd->outer = snp;
		}
		else {
			tl->next = ParseCatch();
			if (tl->next != NULL) {
				tl->next->outer = snp;
				tl = tl->next;
			}
		}
		if (tl == (Statement *)NULL) break;	// end of file in try
		tl->next = (Statement *)NULL;
	}
	snp->s2 = hd;
	return (snp);
}

Statement *Statement::ParseExpression()
{
	Statement *snp;

	dfs.printf("<ParseExpression>\n");
	snp = NewStatement(st_expr, FALSE);
	if (expression(&(snp->exp)) == NULL) {
		error(ERR_EXPREXPECT);
		NextToken();
	}
	if (lastst != end)
		needpunc(semicolon, 44);
	dfs.printf("</ParseExpression>\n");
	return (snp);
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
	if (lastst == colon) {
		NextToken();
		TRACE(printf("Compound <%s>\r\n", lastid);)
			if (strcmp(lastid, "clockbug") == 0)
				printf("clockbug\r\n");
		NextToken();
	}
	AutoDeclaration::Parse(NULL, &snp->ssyms);
	cseg();
	// Add the first statement at the head of the list.
	p = currentStmt;
	if (lastst == kw_prolog) {
		NextToken();
		currentFn->prolog = snp->prolog = Statement::Parse();
	}
	if (lastst == kw_epilog) {
		NextToken();
		currentFn->epilog = snp->epilog = Statement::Parse();
	}
	if (lastst == kw_prolog) {
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
	while (lastst != end) {
		if (lastst == kw_prolog) {
			NextToken();
			currentFn->prolog = snp->prolog = Statement::Parse();
		}
		else if (lastst == kw_epilog) {
			NextToken();
			currentFn->epilog = snp->epilog = Statement::Parse();
		}
		else
		{
			tail->next = Statement::Parse();
			if (tail->next != NULL) {
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
	if ((sp = currentFn->sym->lsyms.Find(lastid, false)) == NULL) {
		sp = allocSYM();
		sp->SetName(*(new std::string(lastid)));
		sp->storage_class = sc_label;
		sp->tp = TYP::Make(bt_label, 0);
		sp->value.i = nextlabel++;
		currentFn->sym->lsyms.insert(sp);
	}
	else {
		if (sp->storage_class != sc_ulabel)
			error(ERR_LABEL);
		else
			sp->storage_class = sc_label;
	}
	NextToken();       /* get past id */
	needpunc(colon, 45);
	if (sp->storage_class == sc_label) {
		snp->label = (int64_t *)sp->value.i;
		snp->next = (Statement *)NULL;
		return (snp);
	}
	return (0);
}

Statement *Statement::ParseGoto()
{
	Statement *snp;
	SYM *sp;

	NextToken();
	loopexit = TRUE;
	if (lastst != id) {
		error(ERR_IDEXPECT);
		return ((Statement *)NULL);
	}
	snp = NewStatement(st_goto, FALSE);
	if ((sp = currentFn->sym->lsyms.Find(lastid, false)) == NULL) {
		sp = allocSYM();
		sp->SetName(*(new std::string(lastid)));
		sp->value.i = nextlabel++;
		sp->storage_class = sc_ulabel;
		sp->tp = 0;
		currentFn->sym->lsyms.insert(sp);
	}
	NextToken();       /* get past label name */
	if (lastst != end)
		needpunc(semicolon, 46);
	if (sp->storage_class != sc_label && sp->storage_class != sc_ulabel)
		error(ERR_LABEL);
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
	switch (lastst) {
	case semicolon:
		snp = NewStatement(st_empty, 1);
		break;
	case begin:
		NextToken();
		stmtdepth++;
		snp = ParseCompound();
		stmtdepth--;
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
		if (lastch == ':')
			return ParseLabel();
		// else fall through to parse expression
	default:
		snp = ParseExpression();
		break;
	}
	if (snp != NULL) {
		snp->next = (Statement *)NULL;
	}
	dfs.puts("</Parse>");
	return (snp);
}


/*
*      repcse will scan through a block of statements replacing the
*      optimized expressions with their temporary references.
*/
void Statement::repcse()
{
	Statement *block = this;

	while (block != NULL) {
		switch (block->stype) {
		case st_compound:
			block->prolog->repcse();
			block->repcse_compound();
			block->epilog->repcse();
			break;
		case st_return:
		case st_throw:
			block->exp->repexpr();
			break;
		case st_check:
			block->exp->repexpr();
			break;
		case st_expr:
			block->exp->repexpr();
			break;
		case st_while:
		case st_until:
		case st_dowhile:
		case st_dountil:
			block->exp->repexpr();
		case st_do:
		case st_doloop:
		case st_forever:
			block->s1->repcse();
			block->s2->repcse();
			break;
		case st_for:
			block->initExpr->repexpr();
			block->exp->repexpr();
			block->s1->repcse();
			block->incrExpr->repexpr();
			break;
		case st_if:
			block->exp->repexpr();
			block->s1->repcse();
			block->s2->repcse();
			break;
		case st_switch:
			block->exp->repexpr();
			block->s1->repcse();
			break;
		case st_try:
		case st_catch:
		case st_case:
		case st_default:
		case st_firstcall:
			block->s1->repcse();
			break;
		}
		block = block->next;
	}
}

void Statement::repcse_compound()
{
	SYM *sp;

	sp = sp->GetPtr(ssyms.GetHead());
	while (sp) {
		if (sp->initexp) {
			sp->initexp->repexpr();
		}
		sp = sp->GetNextPtr();
	}
	s1->repcse();
}

void Statement::scan_compound()
{
	SYM *sp;

	sp = sp->GetPtr(ssyms.GetHead());
	while (sp) {
		if (sp->initexp) {
			opt_const(&sp->initexp);
			sp->initexp->scanexpr(0);
		}
		sp = sp->GetNextPtr();
	}
	s1->scan();
}


//      scan will gather all optimizable expressions into the expression
//      list for a block of statements.

void Statement::scan()
{
	Statement *block = this;

	dfs.printf("<Statement__Scan>");
	loop_active = 1;
	while (block != NULL) {
		dfs.printf("B");
		switch (block->stype) {
		case st_compound:
			dfs.printf("C\n");
			block->prolog->scan();
			block->scan_compound();
			block->epilog->scan();
			dfs.printf("c");
			break;
		case st_check:
		case st_return:
		case st_throw:
		case st_expr:
			dfs.printf("E");
			opt_const(&block->exp);
			block->exp->scanexpr(0);
			dfs.printf("e");
			break;
		case st_dowhile:
			dfs.printf("{do}");
			loop_active++;
			opt_const(&block->exp);
			block->exp->scanexpr(0);
			block->s1->scan();
			loop_active--;
			dfs.printf("{/do}");
			break;
		case st_while:
		case st_until:
		case st_dountil:
			loop_active++;
			opt_const(&block->exp);
			block->exp->scanexpr(0);
			block->s1->scan();
			loop_active--;
			break;
		case st_do:
		case st_doloop:
		case st_forever:
			loop_active++;
			block->s1->scan();
			loop_active--;
			break;
		case st_for:
			loop_active++;
			opt_const(&block->initExpr);
			block->initExpr->scanexpr(0);
			opt_const(&block->exp);
			block->exp->scanexpr(0);
			block->s1->scan();
			opt_const(&block->incrExpr);
			block->incrExpr->scanexpr(0);
			loop_active--;
			break;
		case st_if:
			dfs.printf("{if}");
			opt_const(&block->exp);
			block->exp->scanexpr(0);
			block->s1->scan();
			block->s2->scan();
			dfs.printf("{/if}");
			break;
		case st_switch:
			opt_const(&block->exp);
			block->exp->scanexpr(0);
			block->s1->scan();
			break;
		case st_firstcall:
		case st_case:
		case st_default:
			block->s1->scan();
			break;
			//case st_spinlock:
			//        scan(block->s1);
			//        scan(block->s2);
			//        break;
			// nothing to process for these statement
		case st_break:
		case st_continue:
		case st_goto:
			break;
		default:;// printf("Uncoded statement in scan():%d\r\n", block->stype);
		}
		block = block->next;
	}
	dfs.printf("</Statement__Scan>");
}


//=============================================================================
//=============================================================================
// C O D E   G E N E R A T I O N
//=============================================================================
//=============================================================================

void Statement::GenMixedSource()
{
	if (mixedSource) {
		rtrim(lptr);
		if (strcmp(lptr, last_rem) != 0) {
			GenerateMonadic(op_rem, 0, make_string(lptr));
			strncpy_s(last_rem, 131, lptr, 130);
			last_rem[131] = '\0';
		}
	}
}

void Statement::GenerateWhile()
{
	int lab1, lab2;

	initstack();
	lab1 = contlab;
	lab2 = breaklab;
	contlab = nextlabel++;
	GenerateLabel(contlab);
	if (s1 != NULL)
	{
		breaklab = nextlabel++;
		initstack();
		GenerateFalseJump(exp, breaklab, 2);
		looplevel++;
		s1->Generate();
		looplevel--;
		GenerateMonadic(op_bra, 0, make_clabel(contlab));
		GenerateLabel(breaklab);
		breaklab = lab2;
	}
	else
	{
		initstack();
		GenerateTrueJump(exp, contlab, prediction);
	}
	contlab = lab1;
}

void Statement::GenerateUntil()
{
	int lab1, lab2;

	initstack();
	lab1 = contlab;
	lab2 = breaklab;
	contlab = nextlabel++;
	GenerateLabel(contlab);
	if (s1 != NULL)
	{
		breaklab = nextlabel++;
		initstack();
		GenerateTrueJump(exp, breaklab, 2);
		looplevel++;
		s1->Generate();
		looplevel--;
		GenerateMonadic(op_bra, 0, make_clabel(contlab));
		GenerateLabel(breaklab);
		breaklab = lab2;
	}
	else
	{
		initstack();
		GenerateFalseJump(exp, contlab, prediction);
	}
	contlab = lab1;
}


void Statement::GenerateFor()
{
	int old_break, old_cont, exit_label, loop_label;

	old_break = breaklab;
	old_cont = contlab;
	loop_label = nextlabel++;
	exit_label = nextlabel++;
	contlab = nextlabel++;
	initstack();
	if (initExpr != NULL)
		ReleaseTempRegister(GenerateExpression(initExpr, F_ALL | F_NOVALUE
			, GetNaturalSize(initExpr)));
	GenerateLabel(loop_label);
	initstack();
	if (exp != NULL)
		GenerateFalseJump(exp, exit_label, 2);
	if (s1 != NULL)
	{
		breaklab = exit_label;
		looplevel++;
		s1->Generate();
		looplevel--;
	}
	GenerateLabel(contlab);
	initstack();
	if (incrExpr != NULL)
		ReleaseTempRegister(GenerateExpression(incrExpr, F_ALL | F_NOVALUE, GetNaturalSize(incrExpr)));
	GenerateMonadic(op_bra, 0, make_clabel(loop_label));
	breaklab = old_break;
	contlab = old_cont;
	GenerateLabel(exit_label);
}


void Statement::GenerateForever()
{
	int old_break, old_cont, exit_label, loop_label;
	old_break = breaklab;
	old_cont = contlab;
	loop_label = nextlabel++;
	exit_label = nextlabel++;
	contlab = loop_label;
	GenerateLabel(loop_label);
	if (s1 != NULL)
	{
		breaklab = exit_label;
		looplevel++;
		s1->Generate();
		looplevel--;
	}
	GenerateMonadic(op_bra, 0, make_clabel(loop_label));
	breaklab = old_break;
	contlab = old_cont;
	GenerateLabel(exit_label);
}

void Statement::GenerateIf()
{
	int lab1, lab2, oldbreak;
	ENODE *ep, *node;
	int size;
	Operand *ap1;

	lab1 = nextlabel++;     // else label
	lab2 = nextlabel++;     // exit label
	oldbreak = breaklab;    // save break label
	initstack();            // clear temps
	ep = node = exp;

	// Note the compiler makes two passes at code generation. During the first pass
	// the node type is set to en_bchk and the node pointers are manipulated. So for
	// the second pass this does not need to be done again.
	/*
	if (ep->nodetype == en_bchk) {
	size = GetNaturalSize(node);
	ap1 = GenerateExpression(node->p[0], F_REG, size);
	ap2 = GenerateExpression(node->p[1], F_REG, size);
	ap3 = GenerateExpression(node->p[2], F_REG|F_IMM0, size);
	if (ap3->mode == am_imm) {
	ReleaseTempReg(ap3);
	ap3 = makereg(0);
	}
	Generate4adic(op_bchk, 0, ap1, ap3, ap2, make_label(lab1));	// the nodes are processed in reversed order
	ReleaseTempRegister(ap3);
	ReleaseTempRegister(ap2);
	ReleaseTempRegister(ap1);
	}
	else if (!opt_nocgo && ep->nodetype==en_lor && ep->p[0]->nodetype == en_lt && ep->p[1]->nodetype == en_ge && equalnode(ep->p[0]->p[0], ep->p[1]->p[0])) {
	ep->nodetype = en_bchk;
	if (ep->p[0])
	ep->p[2] = ep->p[0]->p[1];
	else
	ep->p[2] = NULL;
	ep->p[1] = ep->p[1]->p[1];
	ep->p[0] = ep->p[0]->p[0];
	size = GetNaturalSize(node);
	ap1 = GenerateExpression(node->p[0], F_REG, size);
	ap2 = GenerateExpression(node->p[1], F_REG, size);
	ap3 = GenerateExpression(node->p[2], F_REG, size);
	Generate4adic(op_bchk, 0, ap1, ap2, ap3, make_label(lab1));
	ReleaseTempRegister(ap3);
	ReleaseTempRegister(ap2);
	ReleaseTempRegister(ap1);
	}
	else
	*/
	// Check for bbc optimization
	if (!opt_nocgo && ep->nodetype == en_and && ep->p[1]->nodetype == en_icon && pwrof2(ep->p[1]->i) >= 0) {
		size = GetNaturalSize(node);
		ap1 = GenerateExpression(node->p[0], F_REG, size);
		GenerateTriadic(op_bbc, 0, ap1, make_immed(pwrof2(ep->p[1]->i)), make_label(lab1));
		ReleaseTempRegister(ap1);
	}
	else
		GenerateFalseJump(exp, lab1, prediction);
	s1->Generate();
	if (s2 != 0)             /* else part exists */
	{
		GenerateDiadic(op_bra, 0, make_clabel(lab2), 0);
		if (mixedSource)
			GenerateMonadic(op_rem, 0, make_string("; else"));
		GenerateLabel(lab1);
		s2->Generate();
		GenerateLabel(lab2);
	}
	else
		GenerateLabel(lab1);
	breaklab = oldbreak;
}

void Statement::GenerateDoOnce()
{
	int oldcont, oldbreak;
	oldcont = contlab;
	oldbreak = breaklab;
	contlab = nextlabel++;
	GenerateLabel(contlab);
	breaklab = nextlabel++;
	looplevel++;
	s1->Generate();
	looplevel--;
	GenerateLabel(breaklab);
	breaklab = oldbreak;
	contlab = oldcont;
}

void Statement::GenerateDoWhile()
{
	int oldcont, oldbreak;
	oldcont = contlab;
	oldbreak = breaklab;
	contlab = nextlabel++;
	GenerateLabel(contlab);
	breaklab = nextlabel++;
	looplevel++;
	s1->Generate();
	looplevel--;
	initstack();
	GenerateTrueJump(exp, contlab, 3);
	GenerateLabel(breaklab);
	breaklab = oldbreak;
	contlab = oldcont;
}

void Statement::GenerateDoUntil()
{
	int oldcont, oldbreak;
	oldcont = contlab;
	oldbreak = breaklab;
	contlab = nextlabel++;
	GenerateLabel(contlab);
	breaklab = nextlabel++;
	looplevel++;
	s1->Generate();
	looplevel--;
	initstack();
	GenerateFalseJump(exp, contlab, 3);
	GenerateLabel(breaklab);
	breaklab = oldbreak;
	contlab = oldcont;
}

void Statement::GenerateDoLoop()
{
	int oldcont, oldbreak;
	oldcont = contlab;
	oldbreak = breaklab;
	contlab = nextlabel++;
	GenerateLabel(contlab);
	breaklab = nextlabel++;
	looplevel++;
	s1->Generate();
	looplevel--;
	GenerateMonadic(op_bra, 0, make_clabel(contlab));
	GenerateLabel(breaklab);
	breaklab = oldbreak;
	contlab = oldcont;
}


/*
*      generate a call to a library routine.
*/
//void call_library(char *lib_name)
//{    
//	SYM     *sp;
//    sp = gsearch(lib_name);
//    if( sp == NULL )
//    {
//		++global_flag;
//		sp = allocSYM();
//		sp->tp = &stdfunc;
//		sp->name = lib_name;
//		sp->storage_class = sc_external;
//		insert(sp,&gsyms);
//		--global_flag;
//    }
//    GenerateDiadic(op_call,0,make_strlab(lib_name),NULL);
//}

//
// Generate a switch composed of a series of compare and branch instructions.
// Also called a linear switch.
//
void Statement::GenerateLinearSwitch()
{
	int curlab;
	int64_t *bf;
	int nn, jj;
	Statement *defcase, *stmt;
	Operand *ap, *ap1;

	curlab = nextlabel++;
	defcase = 0;
	initstack();
	if (exp == NULL) {
		error(ERR_BAD_SWITCH_EXPR);
		return;
	}
	ap = GenerateExpression(exp, F_REG, GetNaturalSize(exp));
	//        if( ap->preg != 0 )
	//                GenerateDiadic(op_mov,0,makereg(1),ap);
	//		ReleaseTempRegister(ap);
	for (stmt = s1; stmt != NULL; stmt = stmt->next)
	{
		stmt->GenMixedSource();
		if (stmt->s2)          /* default case ? */
		{
			stmt->label = (int64_t *)curlab;
			defcase = stmt;
		}
		else
		{
			bf = (int64_t *)stmt->casevals;
			for (nn = (int)bf[0]; nn >= 1; nn--) {
				if ((jj = pwrof2(bf[nn])) != -1) {
					GenerateTriadic(op_bbs, 0, ap, make_immed(jj), make_clabel(curlab));
				}
				else if (bf[nn] < -256 || bf[nn] > 255) {
					ap1 = GetTempRegister();
					GenerateTriadic(op_xor, 0, ap1, ap, make_immed(bf[nn]));
					ReleaseTempRegister(ap1);
					GenerateTriadic(op_beq, 0, ap1, makereg(0), make_clabel(curlab));
				}
				else {
					GenerateTriadic(op_beqi, 0, ap, make_immed(bf[nn]), make_clabel(curlab));
				}
			}
			//GenerateDiadic(op_dw,0,make_label(curlab), make_direct(stmt->label));
			stmt->label = (int64_t *)curlab;
		}
		if (stmt->s1 != NULL && stmt->next != NULL)
			curlab = nextlabel++;
	}
	if (defcase == NULL)
		GenerateMonadic(op_bra, 0, make_clabel(breaklab));
	else
		GenerateMonadic(op_bra, 0, make_clabel((int)defcase->label));
	ReleaseTempRegister(ap);
}


// generate all cases for a switch statement.
//
void Statement::GenerateCase()
{
	Statement *stmt;

	for (stmt = this; stmt != (Statement *)NULL; stmt = stmt->next)
	{
		stmt->GenMixedSource();
		if (stmt->s1 != (Statement *)NULL)
		{
			GenerateLabel((int)stmt->label);
			stmt->s1->Generate();
		}
		else if (stmt->next == (Statement *)NULL)
			GenerateLabel((int)stmt->label);
	}
}

static int casevalcmp(const void *a, const void *b)
{
	int64_t aa, bb;
	aa = ((scase *)a)->val;
	bb = ((scase *)b)->val;
	if (aa < bb)
		return -1;
	else if (aa == bb)
		return 0;
	else
		return 1;
}


// Currently inline in GenerateSwitch()
void Statement::GenerateTabularSwitch()
{
}

//
// Analyze and generate best switch statement.
//
void Statement::GenerateSwitch()
{
	Operand *ap, *ap1, *ap2;
	Statement *st, *defcase;
	int oldbreak;
	int tablabel;
	int64_t *bf;
	int64_t nn;
	int64_t mm, kk;
	int64_t minv, maxv;
	int deflbl;
	int curlab;
	oldbreak = breaklab;
	breaklab = nextlabel++;
	bf = (int64_t *)label;
	minv = 0x7FFFFFFFL;
	maxv = 0;
	struct scase casetab[512];

	st = s1;
	mm = 0;
	deflbl = 0;
	defcase = nullptr;
	curlab = nextlabel++;
	// Determine minimum and maximum values in all cases
	// Record case values and labels.
	for (st = s1; st != (Statement *)NULL; st = st->next)
	{
		if (st->s2) {
			defcase = st->s2;
			deflbl = curlab;
			curlab = nextlabel++;
		}
		else {
			bf = st->casevals;
			for (nn = bf[0]; nn >= 1; nn--) {
				minv = min(bf[nn], minv);
				maxv = max(bf[nn], maxv);
				st->label = (int64_t *)curlab;
				casetab[mm].label = curlab;
				casetab[mm].val = bf[nn];
				mm++;
			}
			curlab = nextlabel++;
		}
	}
	//
	// check case density
	// If there are enough cases
	// and if the case is dense enough use a computed jump
	if (mm * 100 / max((maxv - minv), 1) > 50 && (maxv - minv) > (nkd ? 7 : 12)) {
		if (deflbl == 0)
			deflbl = nextlabel++;
		for (nn = mm; nn < 512; nn++) {
			casetab[nn].label = deflbl;
			casetab[nn].val = maxv + 1;
		}
		for (kk = minv; kk < maxv; kk++) {
			for (nn = 0; nn < mm; nn++) {
				if (casetab[nn].val == kk)
					goto j1;
			}
			// value not found
			casetab[mm].val = kk;
			casetab[mm].label = defcase ? (int)defcase->label : breaklab;
			mm++;
		j1:;
		}
		qsort(&casetab[0], 512, sizeof(struct scase), casevalcmp);
		tablabel = caselit(casetab, maxv - minv + 1);
		ap = GenerateExpression(exp, F_REG, GetNaturalSize(exp));
		ap1 = GetTempRegister();
		ap2 = GetTempRegister();
		if (!nkd) {
			GenerateDiadic(op_ldi, 0, ap1, make_immed(minv));
			GenerateTriadic(op_blt, 0, ap, ap1, make_clabel(defcase ? (int)defcase->label : breaklab));
			GenerateDiadic(op_ldi, 0, ap2, make_immed(maxv + 1));
			GenerateTriadic(op_bge, 0, ap, ap2, make_clabel(defcase ? (int)defcase->label : breaklab));
			//Generate4adic(op_chk,0,ap,ap1,ap2,make_clabel(defcase ? (int)defcase->label : breaklab));
		}
		if (minv != 0)
			GenerateTriadic(op_sub, 0, ap, ap, make_immed(minv));
		GenerateTriadic(op_shl, 0, ap, ap, make_immed(3));
		GenerateDiadic(op_lw, 0, ap, make_indexed2(tablabel, ap->preg));
		GenerateDiadic(op_jal, 0, makereg(0), make_indexed(0, ap->preg));
		s1->GenerateCase();
		GenerateLabel(breaklab);
		return;
	}
	GenerateLinearSwitch();
	s1->GenerateCase();
	GenerateLabel(breaklab);
	breaklab = oldbreak;
}

void Statement::GenerateTry()
{
	int lab1, curlab;
	int oldthrow;
	Operand *a, *ap2;
	ENODE *node;
	Statement *stmt;

	lab1 = nextlabel++;
	oldthrow = throwlab;
	throwlab = nextlabel++;

	a = make_clabel(throwlab);
	a->mode = am_imm;
	GenerateDiadic(op_ldi, 0, makereg(regXLR), a);
	s1->Generate();
	GenerateMonadic(op_bra, 0, make_clabel(lab1));
	GenerateLabel(throwlab);
	// Generate catch statements
	// r1 holds the value to be assigned to the catch variable
	// r2 holds the type number
	for (stmt = s2; stmt; stmt = stmt->next) {
		stmt->GenMixedSource();
		throwlab = oldthrow;
		curlab = nextlabel++;
		GenerateLabel(curlab);
		if (stmt->num == 99999)
			;
		else {
			ap2 = GetTempRegister();
			GenerateDiadic(op_ldi, 0, ap2, make_immed(stmt->num));
			ReleaseTempReg(ap2);
			GenerateTriadic(op_bne, 0, makereg(2), ap2, make_clabel(nextlabel));
		}
		// move the throw expression result in 'r1' into the catch variable.
		node = stmt->exp;
		ap2 = GenerateExpression(node, F_REG | F_MEM, GetNaturalSize(node));
		if (ap2->mode == am_reg)
			GenerateDiadic(op_mov, 0, ap2, makereg(1));
		else
			GenStore(makereg(1), ap2, GetNaturalSize(node));
		ReleaseTempRegister(ap2);
		//            GenStore(makereg(1),make_indexed(sym->value.i,regFP),sym->tp->size);
		stmt->s1->Generate();
	}
	GenerateLabel(nextlabel);
	nextlabel++;
	GenerateLabel(lab1);
	a = make_clabel(oldthrow);
	a->mode = am_imm;
	GenerateDiadic(op_ldi, 0, makereg(regXLR), a);
}

void Statement::GenerateThrow()
{
	Operand *ap;

	if (exp != NULL)
	{
		initstack();
		ap = GenerateExpression(exp, F_ALL, 8);
		if (ap->mode == am_imm)
			GenerateDiadic(op_ldi, 0, makereg(1), ap);
		else if (ap->mode != am_reg)
			GenerateDiadic(op_lw, 0, makereg(1), ap);
		else if (ap->preg != 1)
			GenerateDiadic(op_mov, 0, makereg(1), ap);
		ReleaseTempRegister(ap);
		// If a system exception is desired create an appropriate BRK instruction.
		if (num == bt_exception) {
			GenerateDiadic(op_brk, 0, makereg(1), make_immed(1));
			return;
		}
		GenerateDiadic(op_ldi, 0, makereg(2), make_immed(num));
	}
	GenerateMonadic(op_bra, 0, make_clabel(throwlab));
}

void Statement::GenerateCheck()
{
	Operand *ap1, *ap2, *ap3;
	ENODE *node, *ep;
	int size;

	initstack();
	ep = node = exp;
	if (ep->p[0]->nodetype == en_lt && ep->p[1]->nodetype == en_ge && ENODE::IsEqual(ep->p[0]->p[0], ep->p[1]->p[0])) {
		ep->nodetype = en_chk;
		if (ep->p[0])
			ep->p[2] = ep->p[0]->p[1];
		else
			ep->p[2] = NULL;
		ep->p[1] = ep->p[1]->p[1];
		ep->p[0] = ep->p[0]->p[0];
	}
	else if (ep->p[0]->nodetype == en_ge && ep->p[1]->nodetype == en_lt && ENODE::IsEqual(ep->p[0]->p[0], ep->p[1]->p[0])) {
		ep->nodetype = en_chk;
		if (ep->p[1])
			ep->p[2] = ep->p[1]->p[1];
		else
			ep->p[2] = NULL;
		ep->p[1] = ep->p[0]->p[1];
		ep->p[0] = ep->p[0]->p[0];
	}
	if (ep->nodetype != en_chk) {
		/*
		printf("ep->p[0]->p[0]->i %d\r\n", ep->p[0]->p[0]->i);
		printf("ep->p[1]->p[0]->i %d\r\n", ep->p[1]->p[0]->i);
		printf("ep->p[0]->p[0]->nt: %d\r\n", ep->p[0]->p[0]->nodetype);
		printf("ep->p[1]->p[0]->nt: %d\r\n", ep->p[1]->p[0]->nodetype);
		printf("ep->p[0]->nodetype=%s ",ep->p[0]->nodetype==en_lt ? "en_lt" : ep->p[0]->nodetype==en_ge ? "en_ge" : "en_??");
		printf("ep->p[1]->nodetype=%s\r\n",ep->p[1]->nodetype==en_lt ? "en_lt" : ep->p[1]->nodetype==en_ge ? "en_ge" : "en_??");
		printf("equalnode:%d\r\n",equalnode(ep->p[0]->p[0],ep->p[1]->p[0]));
		*/
		error(ERR_CHECK);
		return;
	}
	size = GetNaturalSize(node);
	ap1 = GenerateExpression(node->p[0], F_REG, size);
	ap2 = GenerateExpression(node->p[1], F_REG | F_IMM0, size);
	ap3 = GenerateExpression(node->p[2], F_REG | F_IMMED, size);
	if (ap2->mode == am_imm) {
		ap2->mode = am_reg;
		ap2->preg = 0;
	}
	GenerateTriadic(ap3->mode == am_imm ? op_chki : op_chk, 0, ap1, ap2, ap3);
	ReleaseTempRegister(ap3);
	ReleaseTempRegister(ap2);
	ReleaseTempRegister(ap1);
}

void Statement::GenerateCompound()
{
	SYM *sp;

	sp = sp->GetPtr(ssyms.GetHead());
	while (sp) {
		if (sp->initexp) {
			initstack();
			ReleaseTempRegister(GenerateExpression(sp->initexp, F_ALL, 8));
		}
		sp = sp->GetNextPtr();
	}
	// Generate statement will process the entire list of statements in
	// the block.
	s1->Generate();
}

// The same as generating a compound statement but leaves out the generation of
// the prolog and epilog clauses.
void Statement::GenerateFuncBody()
{
	SYM *sp;

	sp = sp->GetPtr(ssyms.GetHead());
	while (sp) {
		if (sp->initexp) {
			initstack();
			ReleaseTempRegister(GenerateExpression(sp->initexp, F_ALL, 8));
		}
		sp = sp->GetNextPtr();
	}
	// Generate statement will process the entire list of statements in
	// the block.
	s1->Generate();
}

void Statement::Generate()
{
	Operand *ap;
	Statement *stmt;

	for (stmt = this; stmt != NULL; stmt = stmt->next)
	{
		stmt->GenMixedSource();
		switch (stmt->stype)
		{
		case st_funcbody:
			stmt->GenerateFuncBody();
			break;
		case st_compound:
			stmt->GenerateCompound();
			break;
		case st_try:
			stmt->GenerateTry();
			break;
		case st_throw:
			stmt->GenerateThrow();
			break;
		case st_stop:
			stmt->GenerateStop();
			break;
		case st_asm:
			stmt->GenerateAsm();
			break;
		case st_label:
			GenerateLabel((int64_t)stmt->label);
			break;
		case st_goto:
			GenerateMonadic(op_bra, 0, make_clabel((int64_t)stmt->label));
			break;
			//case st_critical:
			//                    GenerateCritical(stmt);
			//                    break;
		case st_check:
			stmt->GenerateCheck();
			break;
		case st_expr:
			initstack();
			ap = GenerateExpression(stmt->exp, F_ALL | F_NOVALUE,
				GetNaturalSize(stmt->exp));
			ReleaseTempRegister(ap);
			tmpFreeAll();
			break;
		case st_return:
			currentFn->GenReturn(stmt);
			break;
		case st_if:
			stmt->GenerateIf();
			break;
		case st_do:
		case st_dowhile:
			stmt->GenerateDoWhile();
			break;
		case st_dountil:
			stmt->GenerateDoUntil();
			break;
		case st_doloop:
			stmt->GenerateForever();
			break;
		case st_doonce:
			stmt->GenerateDoOnce();
			break;
		case st_while:
			stmt->GenerateWhile();
			break;
		case st_until:
			stmt->GenerateUntil();
			break;
		case st_for:
			stmt->GenerateFor();
			break;
		case st_forever:
			stmt->GenerateForever();
			break;
		case st_firstcall:
			stmt->GenerateFirstcall();
			break;
		case st_continue:
			if (contlab == -1)
				error(ERR_NOT_IN_LOOP);
			GenerateDiadic(isThor ? op_br : op_bra, 0, make_clabel(contlab), 0);
			break;
		case st_break:
			if (breaklab == -1)
				error(ERR_NOT_IN_LOOP);
			GenerateDiadic(op_bra, 0, make_clabel(breaklab), 0);
			break;
		case st_switch:
			stmt->GenerateSwitch();
			break;
		case st_empty:
			break;
		default:
			printf("DIAG - unknown statement.\n");
			break;
		}
	}
}

void Statement::GenerateStop()
{
	GenerateMonadic(op_stop, 0, make_immed(num));
}

void Statement::GenerateAsm()
{
	GenerateMonadic(op_asm, 0, make_string((char *)label));
}

void Statement::GenerateFirstcall()
{
	int     lab1, lab2;
	Operand *ap1;

	lab1 = contlab;
	lab2 = breaklab;
	contlab = nextlabel++;
	if (s1 != NULL)
	{
		initstack();
		breaklab = nextlabel++;
		ap1 = GetTempRegister();
		GenerateDiadic(op_lh, 0, ap1, make_string(fcname));
		GenerateTriadic(op_beq, 0, ap1, makereg(0), make_clabel(breaklab));
		ReleaseTempRegister(ap1);
		GenerateDiadic(op_sh, 0, makereg(0), make_string(fcname));
		s1->Generate();
		GenerateLabel(breaklab);
		breaklab = lab2;
	}
	contlab = lab1;
}
