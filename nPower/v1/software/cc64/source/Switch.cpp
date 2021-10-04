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

extern int     breaklab;
extern int     contlab;
extern int     retlab;
extern int		throwlab;

int64_t* Statement::GetCasevals()
{
	int nn;
	int64_t* bf;
	int64_t buf[257];

	NextToken();
	nn = 0;
	do {
		buf[nn] = GetIntegerExpression((ENODE**)NULL,nullptr,0);
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
	Statement *snp, * p;
	Statement *head, *tail;
	int64_t buf[256];
	int nn;
	int64_t *bf;

	snp = MakeStatement(st_case, FALSE);
	snp->fallthru = true;
	if (lastst == kw_case) {
		p = currentStmt;
		snp->s2 = 0;
		nn = 0;
		bf = GetCasevals();
		snp->casevals = (int64_t*)bf;
		head = (Statement*)NULL;
		
		while (lastst != end && lastst != kw_case && lastst != kw_default) {
			if (lastst == kw_fallthru)
				snp->fallthru = true;
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
		tail->next = 0;
		currentStmt = p;
//		NextToken();
		snp->s1 = head;
		
		//snp->s1 = Statement::Parse();
		snp->s2 = nullptr;
	}
	else {
		snp = Parse();
		snp->s2 = nullptr;
		//error(ERR_NOCASE);
		//return (Statement *)NULL;
	}
	/*
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
	*/
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

// A switch statement is like a compound statement, it is just a list of statements.

Statement *Statement::ParseSwitch()
{
	Statement *snp;
	Statement *head, *tail;
	AutoDeclaration ad;
	bool needEnd = true;

	snp = MakeStatement(st_switch, TRUE);
	snp->nkd = false;
	iflevel++;
	looplevel++;
	needpunc(openpa, 0);
	if (expression(&(snp->exp), nullptr) == NULL)
		error(ERR_EXPREXPECT);
	if (lastst == semicolon) {
		NextToken();
		if (lastst == kw_naked) {
			NextToken();
			snp->nkd = true;
		}
	}
	needpunc(closepa, 0);
	//if (lastst != begin)
	//	needEnd = false;
	//else
	//	NextToken();
	needpunc(begin, 36);
	ad.Parse(NULL, &snp->ssyms);
	cseg();
	head = 0;
//	if (!needEnd)
//		snp->s1->Parse();
//	else
	{
		while (lastst != end) {
			if (head == (Statement*)NULL) {
				head = tail = Parse();
				if (head)
					head->outer = snp;
			}
			else {
				tail->next = Parse();
				if (tail->next != (Statement*)NULL) {
					tail->next->outer = snp;
					tail = tail->next;
				}
			}
			if (tail == (Statement*)NULL) break;	// end of file in switch
			tail->next = (Statement*)NULL;
			if (!needEnd)
				break;
		}
		snp->s1 = head;
	}
	tail->next = (Statement*)NULL;
	if (needEnd)
		NextToken();
	if (snp->s1->CheckForDuplicateCases())
		error(ERR_DUPCASE);
	iflevel--;
	looplevel--;
	return (snp);
}


//=============================================================================
//=============================================================================
// C O D E   G E N E R A T I O N
//=============================================================================
//=============================================================================

//
// Generate a switch composed of a series of compare and branch instructions.
// Also called a linear switch.
//
int case_cmp(const void* a, const void* b) {
	Case* aa = (Case*)a;
	Case* bb = (Case*)b;
	if (aa->val < bb->val)
		return -1;
	if (aa->val == bb->val)
		return 0;
	return 1;
}

void Statement::GenerateCmpw(Operand* ap, int64_t val)
{
	Operand* ap2;

	if (val < -32768LL || val > 32767LL) {
		ap2 = GetTempRegister();
		cg.GenerateLoadConst(MakeImmediate(val), ap2);
		GenerateTriadic(op_cmpw, 0, makecreg(0), ap, ap2);
		ReleaseTempReg(ap2);
	}
	else
		GenerateTriadic(op_cmpwi, 0, makecreg(0), ap, MakeImmediate(val));
}

void Statement::GenerateSwitchCase(Case* cases, int ncase, int ndx, int xitlab, int deflab)
{
	int mm, nn;

	if (!cases[ndx].done) {
		for (nn = ndx; nn >= 0 && cases[nn].val == cases[ndx].val; nn--);
		nn++;
		for (mm = ndx; mm < ncase && cases[mm].val == cases[ndx].val; mm++);
		mm--;
		GenerateLabel(cases[nn].label);
		cases[nn].stmt->GenMixedSource();
		cases[nn].stmt->GenerateCase();
		cases[nn].done = true;
		if (!cases[nn].stmt->fallthru)
			GenerateMonadic(cpu.bra_op, 0, MakeCodeLabel(xitlab));
		else
			GenerateMonadic(cpu.bra_op, 0, MakeCodeLabel(nn==ncase-1 ? deflab : cases[nn].label + 1));
	}
}

void Statement::GenerateSwitchLo(Case* cases, int ncase, Operand* ap, int lo, int xitlab, int deflab, bool is_unsigned, bool one_hot)
{
	int lab2;
	Operand* ap3;

	lab2 = nextlabel++;
	if (one_hot && cpu.SupportsBBC) {
		ap3 = MakeImmediate(pwrof2(cases[lo].val));
		GenerateTriadic(op_bbc, 0, ap, ap3, MakeCodeLabel(lab2));
	}
	else {
		GenerateCmpw(ap, cases[lo].val);
		GenerateDiadic(op_bne, 0, makecreg(0), MakeCodeLabel(lab2));
	}
	if (opt_size && cases[lo].done) {
		GenerateMonadic(cpu.bra_op, 0, MakeCodeLabel(cases[lo].label));
	}
	else {
		//cases[lo].stmt->GenMixedSource();
		GenerateSwitchCase(cases, ncase, lo, xitlab, deflab);
	}
	GenerateLabel(lab2);
}

void Statement::GenerateSwitchLop1(Case* cases, int ncase, Operand* ap, int lo, int xitlab, int deflab, bool is_unsigned, bool one_hot)
{
	int lab1;
	Operand* ap3;

	lab1 = nextlabel++;
	if (one_hot && cpu.SupportsBBC) {
		ap3 = MakeImmediate(pwrof2(cases[lo + 1].val));
		GenerateTriadic(op_bbc, 0, ap, ap3, MakeCodeLabel(cases[lo + 2].done ? (deflab > 0 ? deflab : xitlab) : lab1));
	}
	else {
		GenerateCmpw(ap, cases[lo + 1].val);
		GenerateDiadic(op_bne, 0, makecreg(0), MakeCodeLabel(cases[lo + 2].done ? (deflab > 0 ? deflab : xitlab) : lab1));
	}
	if (opt_size && cases[lo + 1].done) {
		GenerateMonadic(cpu.bra_op, 0, MakeCodeLabel(cases[lo + 1].label));
	}
	else {
		//cases[lo + 1].stmt->GenMixedSource();
		GenerateSwitchCase(cases, ncase, lo + 1, xitlab, deflab);
	}
	GenerateLabel(lab1);
}

void Statement::GenerateSwitchLop2(Case* cases, int ncase, Operand* ap, int lo, int xitlab, int deflab, bool is_unsigned, bool one_hot)
{
	if (cases[lo + 2].val == cases[lo + 1].val && opt_size) {	// always false
		GenerateCmpw(ap, cases[lo + 2].val);
		GenerateDiadic(op_beq, 0, makecreg(0), MakeCodeLabel(cases[lo + 1].label));
		GenerateMonadic(cpu.bra_op, 0, MakeCodeLabel(deflab > 0 ? deflab : xitlab));
	}
	else {
		if (opt_size) {
			if (one_hot && cpu.SupportsBBS) {
				if (!cases[lo + 2].done && cpu.SupportsBBC) {
					GenerateTriadic(op_bbc, 0, ap, MakeImmediate(pwrof2(cases[lo + 2].val)), MakeCodeLabel(deflab > 0 ? deflab : xitlab));
					GenerateSwitchCase(cases, ncase, lo + 2, xitlab, deflab);
				}
				else {
					GenerateTriadic(op_bbs, 0, ap, MakeImmediate(pwrof2(cases[lo + 2].val)), MakeCodeLabel(cases[lo + 2].label));
					GenerateMonadic(cpu.bra_op, 0, MakeCodeLabel(deflab > 0 ? deflab : xitlab));
				}
			}
			else {
				{
					GenerateCmpw(ap, cases[lo + 2].val);
					GenerateDiadic(op_beq, 0, makecreg(0), MakeCodeLabel(cases[lo + 2].label));
				}
				GenerateMonadic(cpu.bra_op, 0, MakeCodeLabel(deflab > 0 ? deflab : xitlab));
			}
		}
		else {
			if (one_hot && cpu.SupportsBBC) {
				GenerateTriadic(op_bbc, 0, ap, MakeImmediate(pwrof2(cases[lo + 2].val)), MakeCodeLabel(deflab > 0 ? deflab : xitlab));
			}
			else {
				GenerateCmpw(ap, cases[lo + 2].val);
				GenerateDiadic(op_bne, 0, makecreg(0), MakeCodeLabel(deflab > 0 ? deflab : xitlab));
			}
		}
	}
	GenerateSwitchCase(cases, ncase, lo + 2, xitlab, deflab);
}


void Statement::GenerateSwitchSearch(Case *cases, int ncase, Operand* ap, int midlab, int lo, int hi, int xitlab, int deflab, bool is_unsigned, bool one_hot)
{
	int hilab, lolab;
	int mid;
	int lab1, lab2;
	Operand* ap3;

	// Less than three cases left, use linear search
	if (hi - lo < 3) {
		GenerateLabel(midlab);
		lab1 = nextlabel++;
		lab2 = nextlabel++;
		if (!cases[lo].done)
			GenerateSwitchLo(cases, ncase, ap, lo, xitlab, deflab, is_unsigned, one_hot);
		GenerateSwitchLop1(cases, ncase, ap, lo, xitlab, deflab, is_unsigned, one_hot);
		if (!cases[lo+2].done)
			GenerateSwitchLop2(cases, ncase, ap, lo, xitlab, deflab, is_unsigned, one_hot);
		return;
	}
	hilab = nextlabel++;
	lolab = nextlabel++;
	mid = ((lo + hi) >> 1);
	GenerateLabel(midlab);
	if (cases[mid].val >= -32768 && cases[mid].val < 32768) {
		ap3 = MakeImmediate(cases[mid].val);
		GenerateTriadic(is_unsigned ? op_cmplwi : op_cmpwi, 0, makecreg(0), ap, ap3);
		GenerateDiadic(op_bge, 0, makecreg(0), MakeCodeLabel(hilab));
		GenerateDiadic(op_blt, 0, makecreg(0), MakeCodeLabel(lolab));
	}
	else {
		//GenerateDiadic(cpu.ldi_op, 0, ap2, MakeImmediate(cases[mid].val));
		ap3 = GetTempRegister();
		cg.GenerateLoadConst(MakeImmediate(cases[mid].val), ap3);
		GenerateTriadic(is_unsigned ? op_cmplw : op_cmpw, 0, makecreg(0), ap, ap3);
		ReleaseTempReg(ap3);
		GenerateDiadic(op_bge, 0, makecreg(0), MakeCodeLabel(hilab));
		GenerateDiadic(op_blt, 0, makecreg(0), MakeCodeLabel(lolab));
	}
	if (opt_size)
		GenerateLabel(cases[mid].label);
	GenerateSwitchCase(cases, ncase, mid, xitlab, deflab);
	GenerateSwitchSearch(cases, ncase, ap, hilab, mid, hi, xitlab, deflab, is_unsigned, one_hot);
	GenerateSwitchSearch(cases, ncase, ap, lolab, lo, mid, xitlab, deflab, is_unsigned, one_hot);
}

// Count the number of switch values. There may be more than one value per case.

int Statement::CountSwitchCasevals()
{
	int numcases;
	Statement* stmt;
	int64_t* bf;

	numcases = 0;
	for (stmt = s1; stmt != nullptr; stmt = stmt->next) {
		if (stmt->s2)
			;
		else {
			if (stmt->stype == st_case) {
				bf = (int64_t*)stmt->casevals;
				if (bf != nullptr)
					numcases = numcases + bf[0];
			}
		}
	}
	return (numcases);
}

int Statement::CountSwitchCases()
{
	int numcases;
	Statement* stmt;

	numcases = 0;
	for (stmt = s1; stmt != nullptr; stmt = stmt->next) {
		if (stmt->s2)
			;
		else {
			if (stmt->stype == st_case) {
				numcases++;
			}
		}
	}
	return (numcases);
}

bool Statement::IsOneHotSwitch()
{
	Statement* stmt;
	int64_t* bf;
	int nn;

	for (stmt = s1; stmt != nullptr; stmt = stmt->next) {
		if (stmt->s2)
			;
		else {
			if (stmt->stype == st_case) {
				bf = (int64_t*)stmt->casevals;
				if (bf != nullptr) {
					for (nn = bf[0]; nn >= 1; nn--) {
						if (pwrof2(bf[nn]) < 0)
							return (false);
					}
				}
			}
		}
	}
	return (true);
}


// A binary search approach is used if there are more than two case statements.

void Statement::GenerateLinearSwitch()
{
	int curlab, xitlab;
	int64_t* bf;
	int nn, jj;
	int lo, hi, mid, midlab, deflab;
	Statement* defcase, * stmt;
	Operand* ap, * ap1, * ap2;
	Statement** stmts;
	int64_t* casevals;
	int numcases;
	int defc;
	Case* cases;
	bool is_unsigned;

	// Count the number of switch values.
	numcases = CountSwitchCasevals();

	// Fill in an array of case values and corresponding statements.
	cases = new Case [numcases];
	jj = 0;
	defcase = nullptr;
	for (stmt = s1; stmt != nullptr; stmt = stmt->next) {
		if (stmt->stype==st_default) {
			defcase = stmt->s1;
		}
		else {
			if (stmt->stype == st_case) {
				bf = stmt->casevals;
				if (bf) {
					for (nn = 1; nn <= bf[0]; nn++) {
						cases[jj].first = nn==1;
						cases[jj].done = false;
						cases[jj].label = nextlabel;
						cases[jj].stmt = stmt;
						cases[jj].val = bf[nn];
						jj++;
					}
					nextlabel++;
				}
			}
		}
	}

	curlab = nextlabel++;
	initstack();
	if (exp == NULL) {
		error(ERR_BAD_SWITCH_EXPR);
		return;
	}
	ap = cg.GenerateExpression(exp, am_reg, exp->GetNaturalSize(), 0);
	is_unsigned = ap->isUnsigned;
	//        if( ap->preg != 0 )
	//                GenerateDiadic(op_mov,0,makereg(1),ap);
	//		ReleaseTempRegister(ap);
	if (numcases > 2) {
		qsort(&cases[0], numcases, sizeof(Case), case_cmp);
		midlab = nextlabel++;
		deflab = defcase!=nullptr ? nextlabel++ : 0;
		GenerateSwitchSearch(cases, numcases, ap, midlab, 0, numcases - 1, breaklab, deflab, is_unsigned, IsOneHotSwitch());
		if (defcase != nullptr) {
			GenerateLabel(deflab);
			defcase->GenMixedSource();
			defcase->Generate();
		}
		GenerateLabel(breaklab);
		delete[] cases;
		return;
	}
	delete[] cases;
	for (stmt = s1; stmt != NULL; stmt = stmt->next)
	{
		stmt->GenMixedSource();
		stmt->Generate();
		if (stmt->s2)          /* default case ? */
		{
			stmt->label = (int64_t *)curlab;
			defcase = stmt;
		}
		else
		{
				bf = (int64_t*)stmt->casevals;
				if (bf) {
					nn = (int)bf[0];
					if (nn < 10) {
						for (nn = (int)bf[0]; nn >= 1; nn--) {
							/* Can't use bbs here! There could be other bits in the value besides the one tested.
							if ((jj = pwrof2(bf[nn])) != -1) {
								GenerateTriadic(op_bbs, 0, ap, MakeImmediate(jj), MakeCodeLabel(curlab));
							}
							else
							*/
							{
								ap2 = GetTempRegister();
								{
									//GenerateTriadic(op_seq, 0, ap2, ap, MakeImmediate(bf[nn]));
									if (bf[nn] >= -32768 && bf[nn] <= 32767) {
										GenerateTriadic(op_cmpwi, 0, makecreg(0), ap, MakeImmediate(bf[nn]));
										GenerateDiadic(op_beq, 0, makecreg(0), MakeCodeLabel(curlab));
									}
									else {
										GenerateDiadic(cpu.ldi_op, 0, ap2, MakeImmediate(bf[nn]));
										GenerateTriadic(op_cmpw, 0, makecreg(0), ap, ap2);
										GenerateDiadic(op_beq, 0, makecreg(0), MakeCodeLabel(curlab));
									}
								}
								ReleaseTempRegister(ap2);
							}
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
		GenerateMonadic(cpu.bra_op, 0, MakeCodeLabel(breaklab));
	else
		GenerateMonadic(cpu.bra_op, 0, MakeCodeLabel((int)defcase->label));
	ReleaseTempRegister(ap);
	GenerateLabel(breaklab);
}


// Generate case for a switch statement.
//
Statement* Statement::GenerateCase()
{
	Statement *stmt = this;
	Statement* otr = nullptr;

	if (this == nullptr)
		return (nullptr);

	// Still need to generate the label for the benefit of a tabular switch
	// even if there is no code.
	stmt->GenMixedSource();
	GenerateLabel((int)stmt->label);
	if (stmt->s1 != nullptr)
		stmt->s1->Generate();
	return (otr);
}

void Statement::GenerateDefault()
{
	Statement* stmt = this;

	stmt->GenMixedSource();
	GenerateLabel((int)stmt->label);
	if (stmt->s1 != (Statement*)NULL) {
		stmt->s1->Generate();
		/*
		for (stmt = stmt->s1->next; stmt; stmt = stmt->next) {
			// Still need to generate the label for the benefit of a tabular switch
			// even if there is no code.
			stmt->Generate();
		}
		*/
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

// Compute if the switch should be tabular
// The switch is tabular if the value density is greater than 33%.

bool Statement::IsTabularSwitch(int64_t numcases, int64_t minv, int64_t maxv, bool nkd)
{
	return (numcases * 100 / max((maxv - minv), 1) > 33 && (maxv - minv) > (nkd ? 6 : 10));
}

void Statement::GenerateTabularSwitch(int64_t minv, int64_t maxv, Operand* ap, bool HasDefcase, int deflbl, int tablabel)
{
	Operand* ap2;

	ap2 = GetTempRegister();
	GenerateTriadic(op_sub, 0, ap, ap, MakeImmediate(minv));
	//GenerateTriadic(op_sltu, 0, ap2, ap, MakeImmediate(maxv - minv - 1));
	GenerateTriadic(op_cmplwi, 0, makecreg(0), ap, MakeImmediate(maxv - minv - 1));
	GenerateDiadic(op_blt, 0, makecreg(0), MakeCodeLabel(HasDefcase ? deflbl : breaklab));
	ReleaseTempRegister(ap2);
	GenerateTriadic(op_slwi, 0, ap, ap, MakeImmediate(4));
	GenerateDiadic(cpu.ldo_op, 0, ap, compiler.of.MakeIndexedCodeLabel(tablabel, ap->preg));
	currentFn->IsLeaf = false;
	GenerateMonadic(op_mtlr, 0, ap);
	GenerateZeradic(op_blr);
	//GenerateMonadic(op_bra, 0, MakeCodeLabel(defcase ? deflbl : breaklab));
	ReleaseTempRegister(ap);
	s1->Generate();
	GenerateLabel(breaklab);
}

void Statement::GenerateNakedTabularSwitch(int64_t minv, Operand* ap, int tablabel)
{
	if (minv != 0)
		GenerateTriadic(op_sub, 0, ap, ap, MakeImmediate(minv));
	GenerateTriadic(op_slwi, 0, ap, ap, MakeImmediate(3));
	GenerateDiadic(cpu.ldo_op, 0, ap, compiler.of.MakeIndexedCodeLabel(tablabel, ap->preg));
	currentFn->IsLeaf = false;
	GenerateMonadic(op_mtlr, 0, ap);
	GenerateZeradic(op_blr);
	ReleaseTempRegister(ap);
	s1->Generate();
	GenerateLabel(breaklab);
}

void Statement::GetMinMaxSwitchValue(int64_t* minv, int64_t* maxv)
{
	Statement* st;
	int64_t* bf;
	int nn;

	*minv = 0x7FFFFFFFFFFFFFFFLL;
	*maxv = 0LL;
	for (st = s1; st != (Statement*)NULL; st = st->next)
	{
		if (st->s2) {
			;
		}
		else {
			bf = st->casevals;
			if (bf) {
				for (nn = bf[0]; nn >= 1; nn--) {
					*minv = min(bf[nn], *minv);
					*maxv = max(bf[nn], *maxv);
				}
			}
		}
	}
}


//
// Analyze and generate best switch statement.
//
void Statement::GenerateSwitch()
{
	Operand *ap, *ap1, *ap2, *ap3;
	Statement *st, *defcase;
	int oldbreak;
	int tablabel;
	int numcases, numcasevals, maxcasevals;
	int64_t *bf;
	int64_t nn;
	int64_t mm, kk;
	int64_t minv, maxv;
	int deflbl;
	int curlab;
	oldbreak = breaklab;
	breaklab = nextlabel++;
	bf = (int64_t *)label;
	struct scase* casetab;
	OCODE* ip;
	bool is_unsigned;

	st = s1;
	deflbl = 0;
	defcase = nullptr;
	curlab = nextlabel++;

	numcases = CountSwitchCases();
	numcasevals = CountSwitchCasevals();
	GetMinMaxSwitchValue(&minv, &maxv);
	maxcasevals = maxv - minv + 1;
	if (maxcasevals > 1000000) {
		error(ERR_TOOMANYCASECONSTANTS);
		return;
	}
	casetab = new struct scase[maxcasevals + 1];

	// Record case values and labels.
	mm = 0;
	for (st = s1; st != (Statement *)NULL; st = st->next)
	{
		if (st->s2) {
			defcase = st->s1;
			deflbl = curlab;
			st->label = (int64_t *)deflbl;
			curlab = nextlabel++;
		}
		else {
			bf = st->casevals;
			if (bf) {
				for (nn = bf[0]; nn >= 1; nn--) {
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
	if (IsTabularSwitch((int64_t)numcasevals, minv, maxv, nkd)) {
		if (deflbl == 0)
			deflbl = nextlabel++;
		// Use last entry for default
		casetab[maxcasevals].label = deflbl;
		casetab[maxcasevals].val = maxv + 1;
		casetab[maxcasevals].pass = pass;
		// Inherit mm from above
		for (kk = minv; kk <= maxv; kk++) {
			for (nn = 0; nn < maxcasevals; nn++) {
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
		qsort(&casetab[0], maxcasevals+1, sizeof(struct scase), casevalcmp);
		tablabel = caselit(casetab, maxcasevals+1);
		initstack();
		ap = cg.GenerateExpression(exp, am_reg, exp->GetNaturalSize(), 0);
		is_unsigned = ap->isUnsigned;
		if (nkd)
			GenerateNakedTabularSwitch(minv, ap, tablabel);
		else
			GenerateTabularSwitch(minv, maxv, ap, defcase != nullptr, deflbl, tablabel);
	}
	else {
		GenerateLinearSwitch();
	}
	breaklab = oldbreak;
	delete[] casetab;
}

