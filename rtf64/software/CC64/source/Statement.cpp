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
extern int isidch(char);

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

Statement* Statement::MakeStatement(int typ, int gt) {
	return (compiler.sf.MakeStatement(typ, gt));
};

Statement *Statement::ParseCheckStatement()
{
	Statement *snp;
	snp = MakeStatement(st_check, TRUE);
	if (expression(&(snp->exp)) == 0)
		error(ERR_EXPREXPECT);
	needpunc(semicolon, 31);
	return snp;
}

Statement *Statement::ParseWhile()
{
	Statement *snp;

	currentFn->UsesPredicate = TRUE;
	snp = MakeStatement(st_while, TRUE);
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
	snp = MakeStatement(st_until, TRUE);
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
	snp = MakeStatement(st_do, TRUE);
	snp->predreg = iflevel;
	iflevel++;
	looplevel++;
	snp->s1 = Statement::Parse();
	snp->lptr2 = my_strdup(inpline);
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
	snp = MakeStatement(st_for, TRUE);
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
	snp = MakeStatement(st_forever, TRUE);
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
	snp = MakeStatement(st_firstcall, TRUE);
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
	snp = MakeStatement(st_if, FALSE);
	snp->predreg = iflevel;
	snp->kw = kw_if;
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
		snp->s2->kw = kw_else;
		if (snp->s2)
			snp->s2->outer = snp;
	}
	else if (lastst == kw_elsif) {
		snp->s2 = ParseIf();
		snp->s2->kw = kw_elsif;
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
	AutoDeclaration ad;
	Expression exp;

	snp = MakeStatement(st_catch, TRUE);
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
	if (lastst == closepa) {
		NextToken();
		snp->label = (int64_t*)NULL;
		snp->s2 = (Statement*)99999;
		snp->s1 = Statement::Parse();
		// Empty statements return NULL
		if (snp->s1)
			snp->s1->outer = snp;
		return snp;
	}
	if (lastst == ellipsis) {
		NextToken();
		needpunc(closepa, 33);
		snp->label = (int64_t*)NULL;
		snp->s2 = (Statement*)99999;
		snp->s1 = Statement::Parse();
		// Empty statements return NULL
		if (snp->s1)
			snp->s1->outer = snp;
		return snp;
	}
	catchdecl = TRUE;
	ad.Parse(NULL, &snp->ssyms);
	cseg();
	catchdecl = FALSE;
	needpunc(closepa, 34);

	if ((sp = snp->ssyms.Find(*declid, false)) == NULL)
		sp = makeint((char *)declid->c_str());
	node = makenode(sp->storage_class == sc_static ? en_labcon : en_autocon, NULL, NULL);
	node->bit_offset = sp->tp->bit_offset;
	node->bit_width = sp->tp->bit_width;
	// nameref looks up the symbol using lastid, so we need to back it up and
	// restore it.
	strncpy_s(buf, sizeof(buf), lastid, 199);
	strncpy_s(lastid, sizeof(lastid), declid->c_str(), sizeof(lastid) - 1);
	exp.nameref(&node, FALSE);
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

int64_t* Statement::GetCasevals()
{
	int nn;
	int64_t* bf;
	int64_t buf[257];

	NextToken();
	nn = 0;
	do {
		buf[nn] = GetIntegerExpression((ENODE**)NULL);
		nn++;
		if (lastst != comma)
			break;
		NextToken();
	} while (nn < 256);
	if (nn == 256)
		error(ERR_TOOMANYCASECONSTANTS);
	bf = (int64_t*)xalloc(sizeof(int64_t) * (nn + 1));
	bf[0] = nn;
	for (; nn > 0; nn--)
		bf[nn] = buf[nn - 1];
	needpunc(colon, 35);
	return (bf);
}

Statement *Statement::ParseCase()
{
	Statement *snp;
	Statement *head, *tail;
	int64_t buf[256];
	int nn;
	int64_t *bf;

	snp = MakeStatement(st_case, FALSE);
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
		needpunc(colon, 35);
	}
	else if (lastst == kw_default) {
		NextToken();
		snp->s2 = (Statement *)1;
		snp->stype = st_default;
		needpunc(colon, 35);
	}
	else {
		snp = Parse();
		snp->s2 = nullptr;
		//error(ERR_NOCASE);
		//return (Statement *)NULL;
	}
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

Statement* Statement::ParseDefault()
{
	Statement* snp;

	snp = MakeStatement(st_default, FALSE);
	NextToken();
	snp->s2 = (Statement*)1;
	snp->stype = st_default;
	needpunc(colon, 35);
	snp->s1 = Parse();
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
		if (top->stype == st_default && top->s2 && def)
			return (TRUE);
		if (top->stype == st_default && top->s2)
			def = top->s2;
	}
	return (FALSE);
}

Statement *Statement::ParseSwitch()
{
	Statement *snp;
	Statement *head, *tail;
	bool needEnd = true;

	snp = MakeStatement(st_switch, TRUE);
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
	if (lastst != begin)
		needEnd = false;
	else
		NextToken();
	//needpunc(begin, 36);
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
		if (!needEnd)
			break;
	}
	snp->s1 = head;
	if (needEnd)
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
	snp = MakeStatement(st_return, TRUE);
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
	snp = MakeStatement(st_throw, TRUE);
	tp = expression(&(snp->exp));
	snp->num = tp->GetHash();
	if (lastst != end)
		needpunc(semicolon, 38);
	return (snp);
}

Statement *Statement::ParseBreak()
{
	Statement *snp;

	snp = MakeStatement(st_break, TRUE);
	if (lastst != end)
		needpunc(semicolon, 39);
	if (looplevel == foreverlevel)
		loopexit = TRUE;
	return (snp);
}

Statement *Statement::ParseContinue()
{
	Statement *snp;

	snp = MakeStatement(st_continue, TRUE);
	if (lastst != end)
		needpunc(semicolon, 40);
	return (snp);
}

Statement *Statement::ParseStop()
{
	Statement *snp;

	snp = MakeStatement(st_stop, TRUE);
	snp->num = (int)GetIntegerExpression(NULL);
	if (lastst != end)
		needpunc(semicolon, 43);
	return snp;
}

Statement *Statement::ParseAsm()
{
	static char buf[4000];
	static char buf2[50];
	int nn;
	bool first = true;
	SYM* sp, * thead, * firsts;
	int sn, lo, tn;
	char* p;

	Statement *snp;
	snp = MakeStatement(st_asm, FALSE);
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
	snp->label = (int64_t*)allocx(4000);
	strncpy((char*)snp->label, buf, 4000);
	return (snp);
}

Statement *Statement::ParseTry()
{
	Statement *snp;
	Statement *hd, *tl;

	hd = (Statement *)NULL;
	tl = (Statement *)NULL;
	snp = MakeStatement(st_try, TRUE);
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
	Expression exp;

	dfs.printf("<ParseExpression>\n");
	snp = MakeStatement(st_expr, FALSE);
	if (exp.ParseExpression(&(snp->exp)) == NULL) {
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
	AutoDeclaration ad;

	snp = MakeStatement(st_compound, FALSE);
	currentStmt = snp;
	head = 0;
	if (lastst == colon) {
		NextToken();
		TRACE(printf("Compound <%s>\r\n", lastid);)
			if (strcmp(lastid, "clockbug") == 0)
				printf("clockbug\r\n");
		NextToken();
	}
	ad.Parse(NULL, &snp->ssyms);
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
			if (tail) {
				tail->iexp = ad.Parse(NULL, &snp->ssyms);
			}
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

	snp = MakeStatement(st_label, FALSE);
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
	snp = MakeStatement(st_goto, FALSE);
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
	Statement *snp = nullptr;
	int64_t* bf = nullptr;

	dfs.puts("<Parse>");
j1:
	switch (lastst) {
	case semicolon:
		snp = MakeStatement(st_empty, 1);
		break;
	case begin:
		NextToken();
		stmtdepth++;
		snp = ParseCompound();
		stmtdepth--;
		return snp;
	case end:
		return (snp);
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
	case kw_case:	bf = GetCasevals(); goto j1;
	case kw_default: snp = ParseDefault(); break;
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
		snp->casevals = bf;
		bf = nullptr;
	}
	dfs.puts("</Parse>");
	return (snp);
}


//=============================================================================
//=============================================================================
// O P T I M I Z A T I O N
//=============================================================================
//=============================================================================

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

void Statement::update()
{
	Statement *block = this;

	while (block != NULL) {
		switch (block->stype) {
		case st_compound:
			block->prolog->update();
			block->update_compound();
			block->epilog->update();
			break;
		case st_return:
		case st_throw:
			block->exp->update();
			break;
		case st_check:
			block->exp->update();
			break;
		case st_expr:
			block->exp->update();
			break;
		case st_while:
		case st_until:
		case st_dowhile:
		case st_dountil:
			block->exp->update();
		case st_do:
		case st_doloop:
		case st_forever:
			block->s1->update();
			block->s2->update();
			break;
		case st_for:
			block->initExpr->update();
			block->exp->update();
			block->s1->update();
			block->incrExpr->update();
			break;
		case st_if:
			block->exp->update();
			block->s1->update();
			block->s2->update();
			break;
		case st_switch:
			block->exp->update();
			block->s1->update();
			break;
		case st_try:
		case st_catch:
		case st_case:
		case st_default:
		case st_firstcall:
			block->s1->update();
			break;
		}
		block = block->next;
	}
}

void Statement::update_compound()
{
	SYM *sp;

	sp = sp->GetPtr(ssyms.GetHead());
	while (sp) {
		if (sp->initexp) {
			sp->initexp->update();
		}
		sp = sp->GetNextPtr();
	}
	s1->update();
}


//=============================================================================
//=============================================================================
// C O D E   G E N E R A T I O N
//=============================================================================
//=============================================================================

Operand *Statement::MakeDataLabel(int lab, int ndxreg) { return (cg.MakeDataLabel(lab,ndxreg)); };
Operand *Statement::MakeCodeLabel(int lab) { return (cg.MakeCodeLabel(lab)); };
Operand *Statement::MakeStringAsNameConst(char *s, e_sg seg) { return (cg.MakeStringAsNameConst(s, seg)); };
Operand *Statement::MakeString(char *s) { return (cg.MakeString(s)); };
Operand *Statement::MakeImmediate(int64_t i) { return (cg.MakeImmediate(i)); };
Operand *Statement::MakeIndirect(int i) { return (cg.MakeIndirect(i)); };
Operand *Statement::MakeIndexed(int64_t o, int i) { return (cg.MakeIndexed(o, i)); };
Operand *Statement::MakeDoubleIndexed(int i, int j, int scale) { return (cg.MakeDoubleIndexed(i, j, scale)); };
Operand *Statement::MakeDirect(ENODE *node) { return (cg.MakeDirect(node)); };
Operand *Statement::MakeIndexed(ENODE *node, int rg) { return (cg.MakeIndexed(node, rg)); };

void Statement::GenStore(Operand *ap1, Operand *ap3, int size) { cg.GenerateStore(ap1, ap3, size); }

void Statement::GenMixedSource()
{
	if (mixedSource) {
		if (lptr) {
			rtrim(lptr);
			if (strcmp(lptr, last_rem) != 0) {
				GenerateMonadic(op_remark, 0, cg.MakeStringAsNameConst(lptr, codeseg));
				strncpy_s(last_rem, 131, lptr, 130);
				last_rem[131] = '\0';
			}
		}
	}
}

void Statement::GenMixedSource2()
{
	if (mixedSource) {
		if (lptr2) {
			rtrim(lptr2);
			if (strcmp(lptr2, last_rem) != 0) {
				GenerateMonadic(op_remark, 0, cg.MakeStringAsNameConst(lptr2, codeseg));
				strncpy_s(last_rem, 131, lptr2, 130);
				last_rem[131] = '\0';
			}
		}
	}
}

// For loops the loop inversion optimization is applied.
// Basically:
// while(x) {
// ...code
// }
// Gets translated to:
// if (x) {
//   do {
//   ...code
//   } while(x);
// }
// Placing the conditional test at the end of the loop
// removes a branch instruction from every iteration.

void Statement::GenerateWhile()
{
	int lab1, lab2;
	OCODE *loophead;

	initstack();
	lab1 = contlab;
	lab2 = breaklab;
	contlab = nextlabel++;
	breaklab = nextlabel++;
	loophead = currentFn->pl.tail;
	if (!opt_nocgo && !opt_size)
		cg.GenerateFalseJump(exp, breaklab, 2);
	GenerateLabel(contlab);
	if (s1 != NULL)
	{
		looplevel++;
		if (opt_nocgo) {
			initstack();
			cg.GenerateFalseJump(exp, breaklab, 2);
		}
		s1->Generate();
		looplevel--;
		if (!opt_nocgo && !opt_size) {
			initstack();
			cg.GenerateTrueJump(exp, contlab, 2);
		}
		else
			GenerateMonadic(op_bra, 0, cg.MakeCodeLabel(contlab));
	}
	else
	{
		initstack();
		cg.GenerateTrueJump(exp, contlab, prediction);
	}
	GenerateLabel(breaklab);
	currentFn->pl.OptLoopInvariants(loophead);
	breaklab = lab2;
	contlab = lab1;
}

void Statement::GenerateUntil()
{
	int lab1, lab2;
	OCODE *loophead;

	initstack();
	lab1 = contlab;
	lab2 = breaklab;
	contlab = nextlabel++;
	breaklab = nextlabel++;
	loophead = currentFn->pl.tail;
	if (!opt_nocgo && !opt_size)
		cg.GenerateTrueJump(exp, breaklab, 2);
	GenerateLabel(contlab);
	if (s1 != NULL)
	{
		looplevel++;
		if (opt_nocgo) {
			initstack();
			cg.GenerateTrueJump(exp, breaklab, 2);
		}
		s1->Generate();
		looplevel--;
		if (!opt_nocgo && !opt_size) {
			initstack();
			cg.GenerateFalseJump(exp, contlab, 2);
		}
		else
			GenerateMonadic(op_bra, 0, cg.MakeCodeLabel(contlab));
	}
	else
	{
		initstack();
		cg.GenerateFalseJump(exp, contlab, prediction);
	}
	currentFn->pl.OptLoopInvariants(loophead);
	GenerateLabel(breaklab);
	breaklab = lab2;
	contlab = lab1;
}


void Statement::GenerateFor()
{
	int old_break, old_cont, exit_label, loop_label;
	OCODE *loophead;

	old_break = breaklab;
	old_cont = contlab;
	loop_label = nextlabel++;
	exit_label = nextlabel++;
	contlab = nextlabel++;
	initstack();
	if (initExpr != NULL)
		ReleaseTempRegister(cg.GenerateExpression(initExpr, am_all | am_novalue
			, initExpr->GetNaturalSize()));
	loophead = currentFn->pl.tail;
	if (!opt_nocgo && !opt_size) {
		if (exp != NULL) {
			initstack();
			cg.GenerateFalseJump(exp, exit_label, 2);
		}
	}
	GenerateLabel(loop_label);
	if (opt_nocgo||opt_size) {
		if (exp != NULL) {
			initstack();
			cg.GenerateFalseJump(exp, exit_label, 2);
		}
	}
	if (s1 != NULL)
	{
		breaklab = exit_label;
		looplevel++;
		s1->Generate();
		looplevel--;
	}
	GenerateLabel(contlab);
	if (incrExpr != NULL) {
		initstack();
		ReleaseTempRegister(cg.GenerateExpression(incrExpr, am_all | am_novalue, incrExpr->GetNaturalSize()));
	}
	if (opt_nocgo||opt_size)
		GenerateMonadic(op_bra, 0, cg.MakeCodeLabel(loop_label));
	else {
		initstack();
		cg.GenerateTrueJump(exp, loop_label, 2);
	}
	if (!opt_nocgo)
		currentFn->pl.OptLoopInvariants(loophead);
	breaklab = old_break;
	contlab = old_cont;
	GenerateLabel(exit_label);
}


void Statement::GenerateForever()
{
	int old_break, old_cont, exit_label, loop_label;
	OCODE *loophead;

	old_break = breaklab;
	old_cont = contlab;
	loop_label = nextlabel++;
	exit_label = nextlabel++;
	contlab = loop_label;
	loophead = currentFn->pl.tail;
	GenerateLabel(loop_label);
	if (s1 != NULL)
	{
		breaklab = exit_label;
		looplevel++;
		s1->Generate();
		looplevel--;
	}
	GenerateMonadic(op_bra, 0, cg.MakeCodeLabel(loop_label));
	currentFn->pl.OptLoopInvariants(loophead);
	breaklab = old_break;
	contlab = old_cont;
	GenerateLabel(exit_label);
}

void Statement::GenerateIf()
{
	int lab1, lab2;
	ENODE *ep, *node;
	int size, siz1;
	Operand *ap1, *ap2, *ap3;

	lab1 = nextlabel++;     // else label
	lab2 = nextlabel++;     // exit label
	initstack();            // clear temps
	ep = node = exp;

	if (ep == nullptr)
		return;

	// Note the compiler makes two passes at code generation. During the first pass
	// the node type is set to en_bchk and the node pointers are manipulated. So for
	// the second pass this does not need to be done again.
	/*
	if (ep->nodetype == en_bchk) {
	size = GetNaturalSize(node);
	ap1 = GenerateExpression(node->p[0], am_reg, size);
	ap2 = GenerateExpression(node->p[1], am_reg, size);
	ap3 = GenerateExpression(node->p[2], am_reg|am_imm0, size);
	if (ap3->mode == am_imm) {
	ReleaseTempReg(ap3);
	ap3 = makereg(0);
	}
	Generate4adic(op_bchk, 0, ap1, ap3, ap2, MakeDataLabel(lab1));	// the nodes are processed in reversed order
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
	ap1 = GenerateExpression(node->p[0], am_reg, size);
	ap2 = GenerateExpression(node->p[1], am_reg, size);
	ap3 = GenerateExpression(node->p[2], am_reg, size);
	Generate4adic(op_bchk, 0, ap1, ap2, ap3, MakeDataLabel(lab1));
	ReleaseTempRegister(ap3);
	ReleaseTempRegister(ap2);
	ReleaseTempRegister(ap1);
	}
	else
	*/
	// Check for bbc optimization
	if (!opt_nocgo && ep->nodetype == en_and && ep->p[1]->nodetype == en_icon && pwrof2(ep->p[1]->i) >= 0) {
		size = node->GetNaturalSize();
		ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
		GenerateTriadic(op_bbc, 0, ap1, MakeImmediate(pwrof2(ep->p[1]->i)), MakeDataLabel(lab1, regZero));
		ReleaseTempRegister(ap1);
	}
	else if (!opt_nocgo && ep->nodetype == en_lor_safe) {
		/*
		OCODE *ip1 = currentFn->pl.tail;
		OCODE *ip2;
		int len;
		ap3 = GetTempRegister();
		siz1 = node->GetNaturalSize();
		ap1 = cg.GenerateExpression(node->p[0], am_reg, siz1);
		len = currentFn->pl.Count(ip1);
		if (len < 6) {
			ip2 = currentFn->pl.tail;
			ap2 = cg.GenerateExpression(node->p[1], am_reg, siz1);
			len = currentFn->pl.Count(ip2);
			if (len < 6) {
				GenerateTriadic(op_or, 0, ap3, ap1, ap2);
				GenerateTriadic(op_beq, 0, ap3, makereg(0), MakeDataLabel(lab1));
				ReleaseTempReg(ap2);
				ReleaseTempReg(ap1);
				ReleaseTempReg(ap3);
				goto j1;
			}
			ReleaseTempReg(ap2);
		}
		ReleaseTempReg(ap1);
		ReleaseTempReg(ap3);
		currentFn->pl.tail = ip1;
		if (ip1)
			currentFn->pl.tail->fwd = nullptr;
			*/
		cg.GenerateFalseJump(exp, lab1, prediction);
	}
	else if (!opt_nocgo && ep->nodetype == en_land_safe) {
		/*
		OCODE *ip1 = currentFn->pl.tail;
		OCODE *ip2;
		int len;
		ap3 = GetTempRegister();
		siz1 = node->GetNaturalSize();
		ap1 = cg.GenerateExpression(node->p[0], am_reg, siz1);
		len = currentFn->pl.Count(ip1);
		if (len < 6) {
			ip2 = currentFn->pl.tail;
			ap2 = cg.GenerateExpression(node->p[1], am_reg, siz1);
			len = currentFn->pl.Count(ip2);
			if (len < 6) {
				if (!ap1->isBool)
					GenerateDiadic(op_redor, 0, ap1, ap1);
				if (!ap2->isBool)
					GenerateDiadic(op_redor, 0, ap2, ap2);
				GenerateTriadic(op_and, 0, ap3, ap1, ap2);
				GenerateTriadic(op_beq, 0, ap3, makereg(0), MakeDataLabel(lab1));
				ReleaseTempReg(ap2);
				ReleaseTempReg(ap1);
				ReleaseTempReg(ap3);
				goto j1;
			}
			ReleaseTempReg(ap2);
		}
		ReleaseTempReg(ap1);
		ReleaseTempReg(ap3);
		currentFn->pl.tail = ip1;
		if (ip1)
			currentFn->pl.tail->fwd = nullptr;
			*/
		cg.GenerateFalseJump(exp, lab1, prediction);
	}
	else
		cg.GenerateFalseJump(exp, lab1, prediction);
j1:
	initstack();
	s1->Generate();
	if (s2 != 0)             /* else part exists */
	{
		GenerateDiadic(op_bra, 0, MakeCodeLabel(lab2), 0);
		if (mixedSource)
			GenerateMonadic(op_remark, 0, MakeStringAsNameConst("; else",codeseg));
		GenerateLabel(lab1);
		s2->Generate();
		GenerateLabel(lab2);
	}
	else
		GenerateLabel(lab1);
}

void Statement::GenerateDoOnce()
{
	int oldcont, oldbreak;
	OCODE *loophead;

	oldcont = contlab;
	oldbreak = breaklab;
	contlab = nextlabel++;
	breaklab = nextlabel++;
	loophead = currentFn->pl.tail;
	GenerateLabel(contlab);
	looplevel++;
	s1->Generate();
	looplevel--;
	GenerateLabel(breaklab);
	currentFn->pl.OptLoopInvariants(loophead);
	breaklab = oldbreak;
	contlab = oldcont;
}

void Statement::GenerateDoWhile()
{
	int oldcont, oldbreak;
	OCODE *loophead;

	oldcont = contlab;
	oldbreak = breaklab;
	contlab = nextlabel++;
	breaklab = nextlabel++;
	loophead = currentFn->pl.tail;
	GenerateLabel(contlab);
	looplevel++;
	s1->Generate();
	looplevel--;
	initstack();
	GenMixedSource2();
	cg.GenerateTrueJump(exp, contlab, 3);
	GenerateLabel(breaklab);
	currentFn->pl.OptLoopInvariants(loophead);
	breaklab = oldbreak;
	contlab = oldcont;
}

void Statement::GenerateDoUntil()
{
	int oldcont, oldbreak;
	OCODE *loophead;

	oldcont = contlab;
	oldbreak = breaklab;
	contlab = nextlabel++;
	breaklab = nextlabel++;
	loophead = currentFn->pl.tail;
	GenerateLabel(contlab);
	looplevel++;
	s1->Generate();
	looplevel--;
	initstack();
	GenMixedSource2();
	cg.GenerateFalseJump(exp, contlab, 3);
	GenerateLabel(breaklab);
	currentFn->pl.OptLoopInvariants(loophead);
	breaklab = oldbreak;
	contlab = oldcont;
}

void Statement::GenerateDoLoop()
{
	int oldcont, oldbreak;
	OCODE *loophead;

	oldcont = contlab;
	oldbreak = breaklab;
	contlab = nextlabel++;
	breaklab = nextlabel++;
	loophead = currentFn->pl.tail;
	GenerateLabel(contlab);
	looplevel++;
	s1->Generate();
	looplevel--;
	GenMixedSource2();
	GenerateMonadic(op_bra, 0, MakeCodeLabel(contlab));
	GenerateLabel(breaklab);
	currentFn->pl.OptLoopInvariants(loophead);
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
	int nn;
	Statement *defcase, *stmt;
	Operand *ap, *ap1;

	curlab = nextlabel++;
	defcase = 0;
	initstack();
	if (exp == NULL) {
		error(ERR_BAD_SWITCH_EXPR);
		return;
	}
	ap = cg.GenerateExpression(exp, am_reg, exp->GetNaturalSize());
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
				bf = (int64_t*)stmt->casevals;
				if (bf) {
					for (nn = (int)bf[0]; nn >= 1; nn--) {
					/* Can't use bbs here! There could be other bits in the value besides the one tested.
					if ((jj = pwrof2(bf[nn])) != -1) {
						GenerateTriadic(op_bbs, 0, ap, MakeImmediate(jj), MakeCodeLabel(curlab));
					}
					else
					*/
					if (bf[nn] >= -128 && bf[nn] < 127) {
						GenerateTriadic(op_beqi, 0, ap, MakeImmediate(bf[nn]), MakeCodeLabel(curlab));
					}
					else {
						GenerateTriadic(op_seq, 0, makecreg(0), ap, MakeImmediate(bf[nn]));
						GenerateDiadic(op_bt, 0, makecreg(0), MakeCodeLabel(curlab));
					}
				}
			}
			//GenerateDiadic(op_dw,0,MakeDataLabel(curlab), make_direct(stmt->label));
			stmt->label = (int64_t *)curlab;
		}
		if (stmt->s1 != NULL && stmt->next != NULL)
			curlab = nextlabel++;
	}
	if (defcase == NULL)
		GenerateMonadic(op_bra, 0, MakeCodeLabel(breaklab));
	else
		GenerateMonadic(op_bra, 0, MakeCodeLabel((int)defcase->label));
	ReleaseTempRegister(ap);
}


// generate all cases for a switch statement.
//
void Statement::GenerateCase()
{
	Statement *stmt = this;

//	for (stmt = this; stmt != (Statement *)NULL; stmt = stmt->next)
//	{
		stmt->GenMixedSource();
		// Still need to generate the label for the benefit of a tabular switch
		// even if there is no code.
		GenerateLabel((int)stmt->label);
		if (stmt->s1 != (Statement *)NULL)
			stmt->s1->Generate();
//		else if (stmt->next == (Statement *)NULL)
//			GenerateLabel((int)stmt->label);
//	}
}

void Statement::GenerateDefault()
{
	Statement* stmt = this;

	//	for (stmt = this; stmt != (Statement *)NULL; stmt = stmt->next)
	//	{
	stmt->GenMixedSource();
	// Still need to generate the label for the benefit of a tabular switch
	// even if there is no code.
	GenerateLabel((int)stmt->label);
	if (stmt->s1 != (Statement*)NULL)
		stmt->s1->Generate();
	//		else if (stmt->next == (Statement *)NULL)
	//			GenerateLabel((int)stmt->label);
	//	}
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
	OCODE* ip;

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
			st->label = (int64_t *)deflbl;
			curlab = nextlabel++;
		}
		else {
			bf = st->casevals;
			if (bf) {
				for (nn = bf[0]; nn >= 1; nn--) {
					minv = min(bf[nn], minv);
					maxv = max(bf[nn], maxv);
					st->label = (int64_t*)curlab;
					casetab[mm].label = curlab;
					casetab[mm].val = bf[nn];
					casetab[mm].pass = pass;
					mm++;
				}
			}
			curlab = nextlabel++;
		}
	}
	//
	// check case density
	// If there are enough cases
	// and if the case is dense enough use a computed jump
	if (mm * 100 / max((maxv - minv), 1) > 50 && (maxv - minv) > (nkd ? 6 : 10)) {
		if (deflbl == 0)
			deflbl = nextlabel++;
		for (nn = mm; nn < 512; nn++) {
			casetab[nn].label = deflbl;
			casetab[nn].val = maxv + 1;
			casetab[nn].pass = pass;
		}
		for (kk = minv; kk <= maxv; kk++) {
			for (nn = 0; nn < mm; nn++) {
				if (casetab[nn].val == kk)
					goto j1;
			}
			// value not found
			casetab[mm].val = kk;
			casetab[mm].label = defcase ? deflbl : breaklab;
			casetab[mm].pass = pass;
			mm++;
		j1:;
		}
		qsort(&casetab[0], mm, sizeof(struct scase), casevalcmp);
		tablabel = caselit(casetab, mm);
		initstack();
		ap = cg.GenerateExpression(exp, am_reg, exp->GetNaturalSize());
		if (!nkd) {
			//GenerateDiadic(op_ldi, 0, ap1, MakeImmediate(minv));
			//GenerateTriadic(op_blt, 0, ap, ap1, MakeCodeLabel(defcase ? deflbl : breaklab));
			//GenerateDiadic(op_ldi, 0, ap2, MakeImmediate(maxv + 1));
			//GenerateTriadic(op_bge, 0, ap, ap2, MakeCodeLabel(defcase ? deflbl : breaklab));
			GenerateTriadic(op_sge, 0, makecreg(0), ap, MakeImmediate(minv));
			GenerateTriadic(op_sle, 0, makecreg(0), ap, MakeImmediate(maxv));
			ip = currentFn->pl.tail;
			ip->insn2 = Instruction::Get(op_and);
			GenerateDiadic(op_bf, 0, makecreg(0), MakeCodeLabel(defcase ? deflbl : breaklab));
			if (minv != 0)
				GenerateTriadic(op_sub, 0, ap, ap, MakeImmediate(minv));
			GenerateTriadic(op_asl, 0, ap, ap, MakeImmediate(3));
			GenerateDiadic(op_ldo, 0, ap, compiler.of.MakeIndexedCodeLabel(tablabel, ap->preg));
			GenerateDiadic(op_mov, 0, makereg(98), ap);
			GenerateZeradic(op_nop);
			GenerateZeradic(op_nop);
			GenerateMonadic(op_jmp, 0, MakeIndirect(98));
			//GenerateMonadic(op_bra, 0, MakeCodeLabel(defcase ? deflbl : breaklab));
			ReleaseTempRegister(ap);
			s1->GenerateCase();
			GenerateLabel(breaklab);
			return;
			//Generate4adic(op_chk,0,ap,ap1,ap2,MakeCodeLabel(defcase ? (int)defcase->label : breaklab));
		}
		if (minv != 0)
			GenerateTriadic(op_sub, 0, ap, ap, MakeImmediate(minv));
		GenerateTriadic(op_asl, 0, ap, ap, MakeImmediate(3));
		GenerateDiadic(op_ldo, 0, ap, compiler.of.MakeIndexedCodeLabel(tablabel, ap->preg));
		GenerateDiadic(op_mov, 0, makereg(98), ap);
		GenerateZeradic(op_nop);
		GenerateZeradic(op_nop);
		GenerateMonadic(op_jmp, 0, MakeIndirect(98));
		for (st = s1; st != (Statement*)NULL; st = st->next)
			st->GenerateCase();
		GenerateLabel(breaklab);
		ReleaseTempRegister(ap);
		return;
	}
	GenerateLinearSwitch();
	for (st = s1; st != (Statement*)NULL; st = st->next)
		st->GenerateCase();
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
	char buf[200];

	lab1 = nextlabel++;
	oldthrow = throwlab;
	throwlab = nextlabel++;

	a = MakeCodeLabel(throwlab);
	a->mode = am_imm;
	// Push catch handler address on catch handler address stack
//	GenerateDiadic(op_ldi, 0, makereg(regAsm), MakeCodeLabel(throwlab));
//	GenerateTriadic(op_gcsub, 0, makereg(regXHSP), makereg(regXHSP), MakeImmediate(sizeOfWord));
//	GenerateDiadic(op_sto, 0, makereg(regAsm), MakeIndexed((int64_t)0, regXHSP));
	GenerateTriadic(op_gcsub, 0, makereg(regSP), makereg(regSP), MakeImmediate(sizeOfWord*(int64_t)2));
	GenerateDiadic(op_ldo, 0, makereg(regAsm), MakeStringAsNameConst("__xhandler_head", dataseg));
	GenerateDiadic(op_sto, 0, makereg(regAsm), MakeIndexed(sizeOfWord, regSP));
	sprintf_s(buf, sizeof(buf), "#%s_%lld", GetNamespace(), (int64_t)throwlab);
	GenerateDiadic(op_ldi, 0, makereg(regAsm), MakeStringAsNameConst(buf,codeseg));
	GenerateDiadic(op_sto, 0, makereg(regAsm), MakeIndexed((int64_t)0, regSP));
	GenerateDiadic(op_sto, 0, makereg(regSP), MakeStringAsNameConst("__xhandler_head", dataseg));
	s1->Generate();
	// Restore previous handler
	GenerateDiadic(op_ldo, 0, makereg(regAsm), MakeIndexed(sizeOfWord, regSP));
	GenerateDiadic(op_sto, 0, makereg(regAsm), MakeStringAsNameConst("__xhandler_head", dataseg));
	GenerateTriadic(op_add, 0, makereg(regSP), makereg(regSP), MakeImmediate(sizeOfWord * (int64_t)2));
	GenerateMonadic(op_bra, 0, MakeCodeLabel(lab1));	// branch around catch statements
	GenerateLabel(throwlab);
	// Generate catch statements
	// r1 holds the value to be assigned to the catch variable
	// r2 holds the type number
	for (stmt = s2; stmt; stmt = stmt->next) {
		stmt->GenMixedSource();
		throwlab = oldthrow;
		if (stmt->num == 99999)
			;
		else {
			curlab = nextlabel++;
			GenerateTriadic(op_sne, 0, makecreg(0), makereg(regFirstArg+1), MakeImmediate(stmt->num));
			GenerateDiadic(op_bt, 0, makecreg(0), MakeCodeLabel(curlab));
		}
		// move the throw expression result in 'r1' into the catch variable.
		node = stmt->exp;
		if (node) {
			ap2 = cg.GenerateExpression(node, am_reg | am_mem, node->GetNaturalSize());
			if (ap2->mode == am_reg)
				GenerateDiadic(op_mov, 0, ap2, makereg(regFirstArg));
			else
				GenStore(makereg(regFirstArg), ap2, node->GetNaturalSize());
			ReleaseTempRegister(ap2);
		}
		stmt->s1->Generate();
		GenerateLabel(curlab);
	}
	// Restore previous handler
	// Here the none of the catch handlers could process the throw. Move to the next
	// level of handlers.
	GenerateDiadic(op_ldo, 0, makereg(regAsm), MakeIndexed(sizeOfWord, regSP));
	GenerateDiadic(op_sto, 0, makereg(regAsm), MakeStringAsNameConst("__xhandler_head", dataseg));
	GenerateTriadic(op_add, 0, makereg(regSP), makereg(regSP), MakeImmediate(sizeOfWord * (int64_t)2));
	GenerateMonadic(op_brk, 0, MakeImmediate(239));
	GenerateLabel(lab1);
	throwlab = oldthrow;
	a = MakeCodeLabel(throwlab);
	a->mode = am_imm;
}

void Statement::GenerateThrow()
{
	Operand *ap;

	if (exp != NULL)
	{
		initstack();
		ap = cg.GenerateExpression(exp, am_all, 8);
		if (ap->mode == am_imm)
			GenerateDiadic(op_ldi, 0, makereg(regFirstArg), ap);
		else if (ap->mode != am_reg)
			GenerateDiadic(op_ldo, 0, makereg(regFirstArg), ap);
		else if (ap->preg != 1)
			GenerateDiadic(op_mov, 0, makereg(regFirstArg), ap);
		ReleaseTempRegister(ap);
		// If a system exception is desired create an appropriate BRK instruction.
		if (num == bt_exception) {
			GenerateDiadic(op_brk, 0, makereg(regFirstArg), MakeImmediate(1));
			return;
		}
		GenerateDiadic(op_ldi, 0, makereg(regFirstArg+1), MakeImmediate(num));
	}
	// Jump to handler address.
	GenerateMonadic(op_brk, 0, MakeImmediate(239));
//	GenerateDiadic(op_ldo, 0, makereg(114), MakeStringAsNameConst("__xhandler_head", dataseg));
//	GenerateMonadic(op_jmp, 0, MakeIndexed((int64_t)0, 114));
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
	size = node->GetNaturalSize();
	ap1 = cg.GenerateExpression(node->p[0], am_reg, size);
	ap2 = cg.GenerateExpression(node->p[1], am_reg | am_imm0, size);
	ap3 = cg.GenerateExpression(node->p[2], am_reg | am_imm, size);
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
			ReleaseTempRegister(cg.GenerateExpression(sp->initexp, am_all, 8));
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
			ReleaseTempRegister(cg.GenerateExpression(sp->initexp, am_all, 8));
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
	SYM* sp;
	ENODE* ep1;

	for (stmt = this; stmt != NULL; stmt = stmt->next)
	{
		/*
		for (ep1 = stmt->iexp; ep1; ep1 = ep1->p[2]) {
			initstack();
			ReleaseTempRegister(cg.GenerateExpression(ep1->p[3], am_all, 8));
		}
		*/
		/*
		for (sp = SYM::GetPtr(stmt->lst.GetHead()); sp; sp = sp->GetNextPtr()) {
			if (sp->initexp) {
				initstack();
				ReleaseTempRegister(cg.GenerateExpression(sp->initexp, am_all, 8));
			}
		}*/
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
			GenerateMonadic(op_bra, 0, MakeCodeLabel((int64_t)stmt->label));
			break;
			//case st_critical:
			//                    GenerateCritical(stmt);
			//                    break;
		case st_check:
			stmt->GenerateCheck();
			break;
		case st_expr:
			if (stmt->exp) {
				initstack();
				ap = cg.GenerateExpression(stmt->exp, am_all | am_novalue,
					stmt->exp->GetNaturalSize());
				ReleaseTempRegister(ap);
				tmpFreeAll();
			}
			break;
		case st_return:
			currentFn->GenerateReturn(stmt);
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
			GenerateDiadic(isThor ? op_br : op_bra, 0, MakeCodeLabel(contlab), 0);
			break;
		case st_break:
			if (breaklab == -1)
				error(ERR_NOT_IN_LOOP);
			GenerateDiadic(op_bra, 0, MakeCodeLabel(breaklab), 0);
			break;
		case st_switch:
			stmt->GenerateSwitch();
			break;
		case st_case:
			stmt->GenerateCase();
			break;
		case st_default:
			stmt->GenerateDoUntil();
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
	GenerateMonadic(op_stop, 0, MakeImmediate(num));
}

void Statement::GenerateAsm()
{
	char buf2[50];
	SYM* thead, * firsts;
	int64_t tn, lo, bn, ll, i, j;
	char* p;
	char* buf = (char*)label;

	ll = strlen(buf);
	thead = firsts = SYM::GetPtr(currentFn->params.head);
	while (thead) {
		p = &buf[-1];
		while (p = strstr(p+1, &thead->name->c_str()[1])) {
			if (!isidch(p[-1])) {
				bn = p - buf;
				if (!isidch(p[tn = thead->name->length()])) {
					tn--;
					if (thead->IsParameter) {
						if (thead->IsRegister)
							sprintf_s(buf2, sizeof(buf2), "x%I64d", thead->reg);
						else
							sprintf_s(buf2, sizeof(buf2), "%I64d[$fp]", thead->value.i + currentFn->SizeofReturnBlock() * sizeOfWord);
						lo = strlen(buf2);
						
						if (lo==tn)
							memcpy(p, buf2, lo);
						else if (lo > tn) {
							for (i = strlen(&p[tn])+1; i >= 0; i--)
								p[lo + i] = p[tn + i];
							memcpy(p, buf2, lo);
						}
						else {
							for (i = 0; p[lo + i]; i++)
								p[tn + i] = p[lo + i];
							p[tn + i] = p[lo + i];
							memcpy(p, buf2, lo);
						}
						
					}
				}
			}
		}
		thead = thead->GetNextPtr();
		if (thead == firsts) {
			dfs.printf("Circular list.\n");
			throw new C64PException(ERR_CIRCULAR_LIST, 1);
		}
	}

	GenerateMonadic(op_asm, 0, MakeStringAsNameConst((char *)buf,codeseg));
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
		GenerateDiadic(op_ldp, 0, ap1, MakeStringAsNameConst(fcname,dataseg));
		GenerateTriadic(op_seq, 0, makecreg(0), ap1, makereg(0));
		GenerateDiadic(op_bt, 0, makecreg(0), MakeCodeLabel(breaklab));
		ReleaseTempRegister(ap1);
		GenerateDiadic(op_stp, 0, makereg(0), MakeStringAsNameConst(fcname,dataseg));
		s1->Generate();
		GenerateLabel(breaklab);
		breaklab = lab2;
	}
	contlab = lab1;
}

void Statement::Dump()
{
	Statement *block = this;

	dfs.printf("Statement\n");
	while (block != NULL) {
		switch (block->stype) {
		case st_compound:
			block->prolog->Dump();
			block->DumpCompound();
			block->epilog->Dump();
			break;
		case st_return:
		case st_throw:
			block->exp->Dump();
			break;
		case st_check:
			block->exp->Dump();
			break;
		case st_expr:
			dfs.printf("st_expr\n");
			block->exp->Dump();
			break;
		case st_while:
		case st_until:
		case st_dowhile:
		case st_dountil:
			block->exp->Dump();
		case st_do:
		case st_doloop:
		case st_forever:
			block->s1->Dump();
			block->s2->Dump();
			break;
		case st_for:
			block->initExpr->Dump();
			block->exp->Dump();
			block->s1->Dump();
			block->incrExpr->Dump();
			break;
		case st_if:
			block->exp->Dump();
			block->s1->Dump();
			block->s2->Dump();
			break;
		case st_switch:
			block->exp->Dump();
			block->s1->Dump();
			break;
		case st_try:
		case st_catch:
		case st_case:
		case st_default:
		case st_firstcall:
			block->s1->Dump();
			break;
		}
		block = block->next;
	}
}

void Statement::DumpCompound()
{
	SYM *sp;

	sp = sp->GetPtr(ssyms.GetHead());
	while (sp) {
		if (sp->initexp) {
			sp->initexp->Dump();
		}
		sp = sp->GetNextPtr();
	}
	s1->Dump();
}

void Statement::CheckCompoundReferences(int* psp, int* pbp, int* pgp, int* pgp1)
{
	SYM* spp;
	int sp, bp, gp, gp1;

	spp = spp->GetPtr(ssyms.GetHead());
	while (spp) {
		if (spp->initexp) {
			spp->initexp->ResetSegmentCount();
			spp->initexp->CountSegments();
			*psp += exp->segcount[dataseg];
			*pbp += exp->segcount[dataseg];
			*pgp += exp->segcount[dataseg];
			*pgp1 += exp->segcount[rodataseg];
		}
		spp = spp->GetNextPtr();
	}
	s1->CheckReferences(&sp, &bp, &gp, &gp1);
	*psp += sp;
	*pbp += bp;
	*pgp += gp;
	*pgp1 += gp1;
}

void Statement::CheckReferences(int* psp, int* pbp, int* pgp, int* pgp1)
{
	int sp, bp, gp, gp1;
	*psp = 0;
	*pbp = 0;
	*pgp = 0;
	*pgp1 = 0;
	Statement* block = this;

	dfs.printf("Statement\n");
	while (block != NULL) {
		switch (block->stype) {
		case st_compound:
			block->prolog->CheckReferences(&sp, &bp, &gp, &gp1);
			*psp += sp;
			*pbp += bp;
			*pgp += gp;
			*pgp1 += gp1;
			block->CheckCompoundReferences(&sp, &bp, &gp, &gp1);
			*psp += sp;
			*pbp += bp;
			*pgp += gp;
			*pgp1 += gp1;
			block->epilog->CheckReferences(&sp, &bp, &gp, &gp1);
			*psp += sp;
			*pbp += bp;
			*pgp += gp;
			*pgp1 += gp1;
			break;
		case st_return:
		case st_throw:
			block->exp->ResetSegmentCount();
			block->exp->CountSegments();
			*psp += exp->segcount[dataseg];
			*pbp += exp->segcount[dataseg];
			*pgp += exp->segcount[dataseg];
			*pgp1 += exp->segcount[rodataseg];
			break;
		case st_check:
			block->exp->ResetSegmentCount();
			block->exp->CountSegments();
			*psp += exp->segcount[dataseg];
			*pbp += exp->segcount[dataseg];
			*pgp += exp->segcount[dataseg];
			*pgp1 += exp->segcount[rodataseg];
			break;
		case st_expr:
			block->exp->ResetSegmentCount();
			block->exp->CountSegments();
			*psp += exp->segcount[dataseg];
			*pbp += exp->segcount[dataseg];
			*pgp += exp->segcount[dataseg];
			*pgp1 += exp->segcount[rodataseg];
			break;
		case st_while:
		case st_until:
		case st_dowhile:
		case st_dountil:
			block->exp->ResetSegmentCount();
			block->exp->CountSegments();
			*psp += exp->segcount[dataseg];
			*pbp += exp->segcount[dataseg];
			*pgp += exp->segcount[dataseg];
			*pgp1 += exp->segcount[rodataseg];
		case st_do:
		case st_doloop:
		case st_forever:
			block->s1->CheckReferences(&sp, &bp, &gp, &gp1);
			*psp += sp;
			*pbp += bp;
			*pgp += gp;
			*pgp1 += gp1;
			block->s2->CheckReferences(&sp, &bp, &gp, &gp1);
			*psp += sp;
			*pbp += bp;
			*pgp += gp;
			*pgp1 += gp1;
			break;
		case st_for:
			block->initExpr->Dump();
			block->initExpr->ResetSegmentCount();
			block->initExpr->CountSegments();
			*psp += initExpr->segcount[dataseg];
			*pbp += initExpr->segcount[dataseg];
			*pgp += initExpr->segcount[dataseg];
			*pgp1 += initExpr->segcount[rodataseg];
			block->exp->ResetSegmentCount();
			block->exp->CountSegments();
			*psp += exp->segcount[dataseg];
			*pbp += exp->segcount[dataseg];
			*pgp += exp->segcount[dataseg];
			*pgp1 += exp->segcount[rodataseg];
			block->s1->CheckReferences(&sp, &bp, &gp, &gp1);
			*psp += sp;
			*pbp += bp;
			*pgp += gp;
			*pgp1 += gp1;
			block->incrExpr->Dump();
			break;
		case st_if:
			block->exp->ResetSegmentCount();
			block->exp->CountSegments();
			*psp += exp->segcount[dataseg];
			*pbp += exp->segcount[dataseg];
			*pgp += exp->segcount[dataseg];
			*pgp1 += exp->segcount[rodataseg];
			block->s1->CheckReferences(&sp, &bp, &gp, &gp1);
			*psp += sp;
			*pbp += bp;
			*pgp += gp;
			*pgp1 += gp1;
			block->s2->CheckReferences(&sp, &bp, &gp, &gp1);
			*psp += sp;
			*pbp += bp;
			*pgp += gp;
			*pgp1 += gp1;
			break;
		case st_switch:
			block->exp->ResetSegmentCount();
			block->exp->CountSegments();
			*psp += exp->segcount[dataseg];
			*pbp += exp->segcount[dataseg];
			*pgp += exp->segcount[dataseg];
			*pgp1 += exp->segcount[rodataseg];
			block->s1->CheckReferences(&sp, &bp, &gp, &gp1);
			*psp += sp;
			*pbp += bp;
			*pgp += gp;
			*pgp1 += gp1;
			break;
		case st_try:
		case st_catch:
		case st_case:
		case st_default:
		case st_firstcall:
			block->s1->CheckReferences(&sp, &bp, &gp, &gp1);
			*psp += sp;
			*pbp += bp;
			*pgp += gp;
			*pgp1 += gp1;
			break;
		}
		block = block->next;
	}
}

//=============================================================================
//=============================================================================
// D E B U G G I N G
//=============================================================================
//=============================================================================

// Recursively list the vars contained in compound statements.

void Statement::ListCompoundVars()
{
	Statement* ss1;

	ListTable(&ssyms, 0);
	for (ss1 = s1; ss1; ss1 = ss1->next) {
		if (ss1->stype == st_compound)
			ss1->ListCompoundVars();
		if (ss1->s1) {
			if (ss1->s1->stype == st_compound)
				ss1->s1->ListCompoundVars();
		}
		if (ss1->s2) {
			if (ss1->s2->stype == st_compound)
				ss1->s2->ListCompoundVars();
		}
	}
}

void Statement::storeHexDo(txtoStream& fs, e_stmt st)
{
	fs.printf("%02X:", st);
	if (s1)
		s1->storeHex(fs);
	if (exp)
		exp->storeHex(fs);
	fs.printf(":\n");
}

void Statement::storeHexWhile(txtoStream& fs, e_stmt st)
{
	fs.printf("%02X:", st);
	if (exp)
		exp->storeHex(fs);
	fs.printf(":\n");
	if (s1)
		s1->storeHex(fs);
}

void Statement::storeHexFor(txtoStream& fs)
{
	fs.printf("%02X:", st_for);
	if (initExpr)
		initExpr->storeHex(fs);
	fs.printf(":");
	if (exp)
		exp->storeHex(fs);
	fs.printf(":");
	if (incrExpr)
		incrExpr->storeHex(fs);
	fs.printf(":");
	if (s1)
		s1->storeHex(fs);
}

void Statement::storeHexForever(txtoStream& fs)
{
	fs.printf("%02X:", st_forever);
	if (s1)
		s1->storeHex(fs);
}

void Statement::storeHexSwitch(txtoStream& fs)
{
	Statement* st;
	int64_t* bf;
	int nn;

	fs.printf("%02X:", st_switch);
	if (exp)
		exp->storeHex(fs);
	fs.printf(":");
	for (st = s1; st != (Statement*)NULL; st = st->next)
	{
		if (st->s2) {
			fs.printf("%02X:", st_default);
			s2->storeHex(fs);
		}
		else {
			fs.printf("%02X:", st_case);
			bf = st->casevals;
			if (bf) {
				fs.printf("%02X:", bf[0]);
				for (nn = bf[0]; nn >= 1; nn--) {
					fs.printf("%02X", bf[nn]);
					if (nn > 1)
						fs.printf(",");
					else
						fs.printf(":");
				}
			}
			if (s1)
				s1->storeHex(fs);
		}
	}
}

void Statement::storeWhile(txtoStream& fs)
{
	fs.printf("while(");
	if (exp)
		exp->store(fs);
	fs.printf(")\n");
	if (s1)
		s1->storeHex(fs);
}

void Statement::storeHexIf(txtoStream& fs)
{
	fs.printf("%02X:", st_if);
	exp->storeHex(fs);
	if (prediction >= 2)
		fs.printf(";%d", (int)prediction);
	fs.printf(":\n");
	s1->storeHex(fs);
	if (s2) {
		if (s2->kw == kw_else)
			fs.printf("%02X:", st_else);
		else if (s2->kw == kw_elsif) {
			fs.printf("%02X:", st_elsif);
			s2->exp->storeHex(fs);
			if (s2->prediction >= 2)
				fs.printf(";%d", (int)s2->prediction);
			fs.printf(":\n");
		}
		s2->storeHex(fs);
	}
}

void Statement::storeIf(txtoStream& fs)
{
	fs.printf("if(");
	exp->store(fs);
	if (prediction >= 2)
		fs.printf(";%d", (int)prediction);
	fs.printf(")\n");
	s1->store(fs);
	if (s2) {
		if (s2->kw == kw_else)
			fs.printf("else\n");
		else if (s2->kw == kw_elsif) {
			fs.printf("elsif(");
			s2->exp->store(fs);
			if (s2->prediction >= 2)
				fs.printf(";%d", (int)s2->prediction);
			fs.printf(")\n");
		}
		s2->storeHex(fs);
	}
}

void Statement::storeHexCompound(txtoStream& fs)
{
	Statement* sp;

	fs.printf("%02X:", st_compound);
	for (sp = s1; sp; sp = sp->next) {
		sp->storeHex(fs);
	}
}

void Statement::storeCompound(txtoStream& fs)
{
	Statement* sp;

	for (sp = s1; sp; sp = sp->next) {
		sp->store(fs);
	}
}

void Statement::storeHex(txtoStream& fs)
{
	if (this == nullptr)
		return;
	switch (stype) {
	case st_compound:
		storeHexCompound(fs);
		break;
	case st_label:
		fs.printf("%02X:", st_label);
		fs.printf("%02X:", (int64_t)label);
		fs.printf(";");
		break;
	case st_goto:
		fs.printf("%02X:", st_goto);
		fs.printf("%02X:", (int64_t)label);
		fs.printf(";");
		break;
	case st_do:
	case st_dowhile:
	case st_dountil:
	case st_doonce:
		storeHexDo(fs, stype);
		break;
	case st_while:
	case st_until:
		storeHexWhile(fs, stype);
		break;
	case st_for:
		storeHexFor(fs);
		break;
	case st_forever:
		storeHexForever(fs);
		break;
	case st_break:
	case st_continue:
		fs.printf("%02X;", stype);
		break;
	case st_if:
		storeHexIf(fs);
		break;
	case st_return:
		fs.printf("%02X:", st_return);
		if (exp) {
			fs.printf("%02X:", st_expr);
			exp->storeHex(fs);
		}
		fs.printf(";\n");
		break;
	case st_switch:
		storeHexSwitch(fs);
		break;
	case st_expr:
		fs.printf("%02X:", st_expr);
		exp->storeHex(fs);
		fs.printf(";\n");
		break;
	}
}

void Statement::store(txtoStream& fs)
{
	switch (stype) {
	case st_compound:
		storeCompound(fs);
		break;
	case st_while:
		storeWhile(fs);
		break;
	case st_if:
		storeIf(fs);
		break;
	case st_return:
		fs.printf("return(");
		if (exp)
			exp->store(fs);
		fs.printf(");\n");
		break;
	case st_expr:
		exp->store(fs);
		break;
	}
}
