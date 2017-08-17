// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - 'C' derived language compiler
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

extern char *rtrim(char *);
extern int caselit(scase *casetab,int);
extern void validate(AMODE *ap);
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

#define SWI15	15

int     breaklab;
int     contlab;
int     retlab;

int lastsph;
char *semaphores[20];
char last_rem[132];

extern TYP *stdfunc;
extern int pwrof2(int);

int bitsset(int64_t mask)
{
	int nn,bs=0;
	for (nn =0; nn < 64; nn++)
		if (mask & (1LL << nn)) bs++;
	return bs;
}

AMODE *makereg(int r)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_reg;
    ap->preg = r;
    return ap;
}

AMODE *makefpreg(int r)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_fpreg;
    ap->preg = r;
    ap->isFloat = TRUE;
    return ap;
}

AMODE *makesreg(int r)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_sreg;
    ap->preg = r;
    return ap;
}

AMODE *makebreg(int r)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_breg;
    ap->preg = r;
    return ap;
}

AMODE *makepred(int r)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_predreg;
    ap->preg = r;
    return ap;
}

/*
 *      generate the mask address structure.
 */
AMODE *make_mask(int mask)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_mask;
    ap->offset = (ENODE *)mask;
    return ap;
}

/*
 *      make a direct reference to an immediate value.
 */
AMODE *make_direct(int i)
{
	return make_offset(makeinode(en_icon,i));
}

AMODE *make_indexed2(int lab, int i)
{
	AMODE *ap;
    ENODE *ep;
    ep = ENODE::alloc();
    ep->nodetype = en_clabcon;
    ep->i = lab;
    ap = allocAmode();
	ap->mode = am_indx;
	ap->preg = i;
    ap->offset = ep;
	ap->isUnsigned = TRUE;
    return ap;
}

//
// Generate a direct reference to a string label.
//
AMODE *make_strlab(std::string s)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_direct;
    ap->offset = makesnode(en_nacon,&s,&s,-1);
    return ap;
}

void GenerateUBranch(int lab)
{
	GenerateTriadic(op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab));
}

void Statement::GenMixedSource()
{
    if (mixedSource) {
        rtrim(lptr);
        if (strcmp(lptr,last_rem)!=0) {
          	GenerateMonadic(op_rem,0,make_string(lptr));
          	strncpy_s(last_rem,131,lptr,130);
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
    if( s1 != NULL )
    {
		breaklab = nextlabel++;
		initstack();
		GenerateFalseJump(exp,breaklab,2);
		s1->Generate();
		GenerateTriadic(op_mov,0,makereg(regPC),makereg(regZero),make_clabel(contlab));
		GenerateLabel(breaklab);
		breaklab = lab2;
    }
    else
    {
		initstack();
		GenerateTrueJump(exp,contlab,prediction);
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
	if( s1 != NULL )
	{
		breaklab = nextlabel++;
		initstack();
		GenerateTrueJump(exp,breaklab,2);
		s1->Generate();
		GenerateUBranch(contlab);
		GenerateLabel(breaklab);
		breaklab = lab2;
	}
	else
	{
		initstack();
		GenerateFalseJump(exp,contlab,prediction);
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
    if( initExpr != NULL )
            ReleaseTempRegister(GenerateExpression(initExpr,F_ALL | F_NOVALUE
                    ,GetNaturalSize(initExpr)));
    GenerateLabel(loop_label);
    initstack();
    if( exp != NULL )
            GenerateFalseJump(exp,exit_label,2);
    if( s1 != NULL )
	{
            breaklab = exit_label;
            s1->Generate();
	}
	GenerateLabel(contlab);
    initstack();
    if( incrExpr != NULL )
            ReleaseTempRegister(GenerateExpression(incrExpr,F_ALL | F_NOVALUE,GetNaturalSize(incrExpr)));
    GenerateTriadic(op_mov,0,makereg(regPC),makereg(regZero),make_clabel(loop_label));
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
    if( s1 != NULL )
	{
        breaklab = exit_label;
        s1->Generate();
	}
    GenerateTriadic(op_mov,0,makereg(regPC),makereg(regZero),make_clabel(loop_label));
    breaklab = old_break;
    contlab = old_cont;
    GenerateLabel(exit_label);
}

void Statement::GenerateIf()
{
	int lab1, lab2, oldbreak;

    lab1 = nextlabel++;     // else label
    lab2 = nextlabel++;     // exit label
    oldbreak = breaklab;    // save break label
    initstack();            // clear temps
    GenerateFalseJump(exp,lab1,prediction);
	GenerateHint(8);
    s1->Generate();
	GenerateHint(9);
    if( s2 != 0 )             /* else part exists */
    {
	    GenerateTriadic(op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab2));
        if (mixedSource)
          	GenerateMonadic(op_rem,0,make_string("; else"));
        GenerateLabel(lab1);
		GenerateHint(8);
        s2->Generate();
		GenerateHint(9);
        GenerateLabel(lab2);
    }
    else
        GenerateLabel(lab1);
    breaklab = oldbreak;
}

void Statement::GenerateDo()
{
	int oldcont, oldbreak;
    oldcont = contlab;
    oldbreak = breaklab;
    contlab = nextlabel++;
    GenerateLabel(contlab);
	breaklab = nextlabel++;
	s1->Generate();
	initstack();
	GenerateTrueJump(exp,contlab,3);
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
    s1->Generate();
    initstack();
    GenerateFalseJump(exp,contlab,3);
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
	int *bf;
	int nn;
	Statement *defcase, *stmt;
	AMODE *ap;

	curlab = nextlabel++;
	defcase = 0;
	initstack();
		if (exp==NULL) {
		error(ERR_BAD_SWITCH_EXPR);
		return;
	}
    ap = GenerateExpression(exp,F_REG,GetNaturalSize(exp));
	GenerateDiadic(op_mov,0,makereg(2),ap);
	ReleaseTempReg(ap);
//        if( ap->preg != 0 )
//                GenerateDiadic(op_mov,0,makereg(1),ap);
//		ReleaseTempRegister(ap);
    for(stmt = s1; stmt != NULL; stmt = stmt->next )
    {
		stmt->GenMixedSource();
        if( stmt->s2 )          /* default case ? */
        {
			stmt->label = (int *)curlab;
			defcase = stmt;
        }
        else
        {
			bf = (int *)stmt->casevals;
			for (nn = bf[0]; nn >= 1; nn--) {
				GenerateTriadic(op_cmp,0,makereg(2),makereg(regZero),make_immed(bf[nn]));
				GeneratePredicatedTriadic(pop_z,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(curlab));
			}
	        //GenerateDiadic(op_dw,0,make_label(curlab), make_direct(stmt->label));
            stmt->label = (int *)curlab;
        }
        if( stmt->s1 != NULL && stmt->next != NULL )
            curlab = nextlabel++;
    }
    if( defcase == NULL )
        GenerateTriadic(op_mov,0,makereg(regPC),makereg(regZero),make_clabel(breaklab));
    else
		GenerateTriadic(op_mov,0,makereg(regPC),makereg(regZero),make_clabel((int)defcase->label));
}


// generate all cases for a switch statement.
//
void Statement::GenerateCase()
{
	Statement *stmt;

	for (stmt = this; stmt != (Statement *)NULL; stmt = stmt->next )
    {
		stmt->GenMixedSource();
		if(stmt->s1 != (Statement *)NULL )
		{
			GenerateLabel((int)stmt->label);
			stmt->s1->Generate();
		}
		else if(stmt->next == (Statement *)NULL)
			GenerateLabel((int)stmt->label);
    }
}

static int casevalcmp(const void *a, const void *b)
{
	int aa,bb;
	aa = ((scase *)a)->val;
	bb = ((scase *)b)->val;
	if (aa < bb)
		return -1;
	else if (aa==bb)
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
	AMODE *ap, *ap1;
	Statement *st, *defcase;
	int oldbreak;
	int tablabel;
	int *bf;
	int nn,mm,kk;
	int minv,maxv;
	int deflbl;
	int curlab;
    oldbreak = breaklab;
    breaklab = nextlabel++;
	bf = (int *)label;
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
	for(st = s1; st != (Statement *)NULL; st = st->next )
	{
		if (st->s2) {
			defcase = st->s2;
			deflbl = curlab;
			curlab = nextlabel++;
		}
		else {
			bf = st->casevals;
			for (nn = bf[0]; nn >= 1; nn--) {
				minv = min(bf[nn],minv);
				maxv = max(bf[nn],maxv);
				st->label = (int *)curlab;
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
	if (mm * 100 / max((maxv-minv),1) > 50 && (maxv-minv) > (nkd ? 7 : 12)) {
		if (deflbl==0)
			deflbl = nextlabel++;
		for (nn = mm; nn < 512; nn++) {
			casetab[nn].label = deflbl;
			casetab[nn].val = maxv+1;
		}
		for (kk = minv; kk < maxv; kk++) {
			for (nn = 0; nn < mm; nn++) {
				if (casetab[nn].val==kk)
					goto j1;
			}
			// value not found
			casetab[mm].val = kk;
			casetab[mm].label = defcase ? (int)defcase->label : breaklab;
			mm++;
j1:	;
		}
		qsort(&casetab[0],512,sizeof(struct scase),casevalcmp);
		tablabel = caselit(casetab,maxv-minv+1);
	    ap = GenerateExpression(exp,F_REG,GetNaturalSize(exp));
		validate(ap);
		ap1 = makereg(2);
		if (!nkd) {
			GenerateTriadic(op_cmp,0,ap1,makereg(regZero),make_immed(minv));
			GeneratePredicatedTriadic(pop_mi,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(defcase ? (int)defcase->label : breaklab));
			GenerateTriadic(op_cmp,0,ap1,makereg(regZero),make_immed(maxv+1));
			GeneratePredicatedTriadic(pop_pl,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(defcase ? (int)defcase->label : breaklab));
		}
		GenerateTriadic(op_sub,0,ap,makereg(regZero),make_immed(minv));
		//GenerateTriadic(op_add,0,ap,ap,make_immed(0));
		GenerateDiadic(op_ld,0,ap,make_indexed2(tablabel,ap->preg));
		GenerateTriadic(op_mov,0,makereg(regPC),makereg(ap->preg),make_immed(0));
		ReleaseTempReg(ap);
		s1->GenerateCase();
		GenerateLabel(breaklab);
		return;
	}
	GenerateLinearSwitch();
	s1->GenerateCase();
	GenerateLabel(breaklab);
    breaklab = oldbreak;
}

int popcnt(int64_t m)
{
	int n;
	int cnt;

	cnt =0;
	for (n = 0; n < 64; n = n + 1)
		if (m & (1LL << n)) cnt = cnt + 1;
	return cnt;
}

void Statement::GenerateTry()
{
	int lab1,curlab;
	int oldthrow;
	AMODE *a, *ap2;
	ENODE *node;
	Statement *stmt;

	lab1 = nextlabel++;
	oldthrow = compiler.throwlab;
	compiler.throwlab = nextlabel++;

	a = make_clabel(compiler.throwlab);
	GenerateTriadic(op_mov,0,makereg(regXLR),makereg(regZero),a);
	s1->Generate();
	GenerateUBranch(lab1);
	GenerateLabel(compiler.throwlab);
	// Generate catch statements
	// r1 holds the value to be assigned to the catch variable
	// r2 holds the type number
	for (stmt = s2; stmt; stmt = stmt->next) {
		stmt->GenMixedSource();
		compiler.throwlab = oldthrow;
		curlab = nextlabel++;
		GenerateLabel(curlab);
		if (stmt->num==99999)
			;
		else {
			GenerateTriadic(op_cmp,0,makereg(2),makereg(regZero),make_immed(stmt->num));
			GeneratePredicatedTriadic(pop_nz,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(nextlabel));
		}
		// move the throw expression result in 'r1' into the catch variable.
		node = stmt->exp;
		ap2 = GenerateExpression(node,F_REG|F_MEM,GetNaturalSize(node));
		if (ap2->mode==am_reg)
			GenerateDiadic(op_mov,0,ap2,makereg(1));
		else
			GenStore(makereg(1),ap2,GetNaturalSize(node));
		ReleaseTempRegister(ap2);
		//            GenStore(makereg(1),make_indexed(sym->value.i,regBP),sym->tp->size);
		stmt->s1->Generate();
	}
	GenerateLabel(nextlabel);
	nextlabel++;
	GenerateLabel(lab1);
	a = make_clabel(oldthrow);
	GenerateTriadic(op_mov,0,makereg(regXLR),makereg(regZero),a);
}

void Statement::GenerateThrow()
{
	AMODE *ap;

    if(exp != NULL )
	{
		initstack();
		ap = GenerateExpression(exp,F_ALL,GetNaturalSize(exp));
		if (ap->mode==am_immed)
           	GenLdi(makereg(1),ap);
		else if( ap->mode != am_reg)
			GenerateDiadic(op_ld,0,makereg(1),ap);
		else if (ap->preg != 1 )
			GenerateDiadic(op_mov,0,makereg(1),ap);
		ReleaseTempRegister(ap);
		GenLdi(makereg(2),make_immed(num));
	}
	GenerateUBranch(compiler.throwlab);
}

void Statement::GenerateCheck()
{
	AMODE *ap1, *ap2, *ap3;
	int lab1, lab2;
	int size;

	lab1 = nextlabel++;
	lab2 = nextlabel++;
	initstack();
	size = GetNaturalSize(exp);
	ap1 = GenerateExpression(exp,F_REG,size);
	ap2 = GenerateExpression(initExpr,F_REG,size);
	ap3 = GenerateExpression(incrExpr,F_REG,size);
	GenerateDiadic(op_cmp,0,ap1,ap2);
	if (size==2)
		GenerateDiadic(op_cmpc,0,ap1->amode2,ap2->amode2);
	GeneratePredicatedTriadic(ap1->isUnsigned ? pop_c : pop_mi,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab1));
	GenerateDiadic(op_cmp,0,ap1,ap3);
	if (size==2)
		GenerateDiadic(op_cmpc,0,ap1->amode2,ap3->amode2);
	GeneratePredicatedTriadic(ap1->isUnsigned ? pop_c : pop_mi,op_mov,0,makereg(regPC),makereg(regZero),make_clabel(lab2));
	GenerateLabel(lab1);
	GenerateMonadic(op_putpsr,0,make_immed(SWI15));
	GenerateLabel(lab2);
	ReleaseTempReg(ap3);
	ReleaseTempReg(ap2);
	ReleaseTempReg(ap1);
}

void Statement::GenerateCompound()
{
	SYM *sp;

	sp = sp->GetPtr(ssyms.GetHead());
	while (sp) {
		if (sp->initexp) {
        	initstack();
			ReleaseTempRegister(GenerateExpression(sp->initexp,F_ALL,GetNaturalSize(sp->initexp)));
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
			ReleaseTempRegister(GenerateExpression(sp->initexp,F_ALL,GetNaturalSize(sp->initexp)));
        }
		sp = sp->GetNextPtr();
	}
	// Generate statement will process the entire list of statements in
	// the block.
	s1->Generate();
}

void Statement::Generate()
{
	AMODE *ap;
	Statement *stmt;
 
	for(stmt = this; stmt != NULL; stmt = stmt->next )
    {
        stmt->GenMixedSource();
        switch( stmt->stype )
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
                GenerateUBranch((int64_t)stmt->label);
                break;
		//case st_critical:
//                    GenerateCritical(stmt);
//                    break;
		case st_check:
                stmt->GenerateCheck();
                break;
        case st_expr:
                initstack();
                ap = GenerateExpression(stmt->exp,F_ALL | F_NOVALUE,
                        GetNaturalSize(stmt->exp));
				ReleaseTempRegister(ap);
                break;
        case st_return:
				GenerateReturn(stmt);
                break;
        case st_if:
                stmt->GenerateIf();
                break;
        case st_do:
                stmt->GenerateDo();
                break;
        case st_dountil:
                stmt->GenerateDoUntil();
                break;
        case st_doloop:
                stmt->GenerateForever();
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
				if (contlab==-1)
					error(ERR_NOT_IN_LOOP);
                GenerateTriadic(op_mov,0,makereg(regPC),makereg(regZero),make_clabel(contlab));
                break;
        case st_break:
				if (breaklab==-1)
					error(ERR_NOT_IN_LOOP);
                GenerateTriadic(op_mov,0,makereg(regPC),makereg(regZero),make_clabel(breaklab));
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
}

void Statement::GenerateAsm()
{
	GenerateMonadic(op_asm,0,make_string((char *)label));
}

void Statement::GenerateFirstcall()
{
	int     lab1, lab2;
	AMODE *ap1;

    lab1 = contlab;
    lab2 = breaklab;
    contlab = nextlabel++;
    if( s1 != NULL )
    {
        breaklab = nextlabel++;
		ap1 = GetTempRegister();
		GenerateDiadic(op_ld,0,ap1,make_string(fcname));
       	GenerateTriadic(op_beq,0,ap1,makereg(0),make_clabel(breaklab));
		ReleaseTempRegister(ap1);
		GenerateDiadic(op_sto,0,makereg(0),make_string(fcname));
		s1->Generate();
        GenerateLabel(breaklab);
        breaklab = lab2;
    }
    contlab = lab1;
}
