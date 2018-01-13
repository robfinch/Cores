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

extern char *rtrim(char *);
extern int caselit(scase *casetab,int64_t);

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

int     breaklab;
int     contlab;
int     retlab;
int		throwlab;

int lastsph;
char *semaphores[20];
char last_rem[132];

extern TYP              stdfunc;
extern int pwrof2(int64_t);

int bitsset(int64_t mask)
{
	int nn,bs=0;
	for (nn =0; nn < 64; nn++)
		if (mask & (1LL << nn)) bs++;
	return (bs);
}

AMODE *makereg(int r)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_reg;
    ap->preg = r;
    return (ap);
}

AMODE *makevreg(int r)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_reg;
    ap->preg = r;
	ap->type = stdvector.GetIndex();
    return (ap);
}

AMODE *makevmreg(int r)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_vmreg;
    ap->preg = r;
    return (ap);
}

AMODE *makefpreg(int r)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_fpreg;
    ap->preg = r;
    ap->type = stddouble.GetIndex();
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
    ep = allocEnode();
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
    ap->offset = makesnode(en_nacon,new std::string(s),new std::string(s),-1);
    return ap;
}

void Statement::GenMixedSource()
{
    if (mixedSource) {
        rtrim(lptr);
        if (strcmp(lptr,last_rem)!=0) {
          	GenerateMonadicNT(op_rem,0,make_string(lptr));
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
		looplevel++;
		s1->Generate();
		looplevel--;
		GenerateMonadicNT(op_bra,0,make_clabel(contlab));
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
		looplevel++;
		s1->Generate();
		looplevel--;
		GenerateMonadicNT(op_bra,0,make_clabel(contlab));
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
			looplevel++;
            s1->Generate();
			looplevel--;
	}
	GenerateLabel(contlab);
    initstack();
    if( incrExpr != NULL )
            ReleaseTempRegister(GenerateExpression(incrExpr,F_ALL | F_NOVALUE,GetNaturalSize(incrExpr)));
    GenerateMonadicNT(op_bra,0,make_clabel(loop_label));
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
		looplevel++;
        s1->Generate();
		looplevel--;
	}
    GenerateMonadicNT(op_bra,0,make_clabel(loop_label));
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
    s1->Generate();
    if( s2 != 0 )             /* else part exists */
    {
        GenerateDiadicNT(op_bra,0,make_clabel(lab2),0);
        if (mixedSource)
          	GenerateMonadicNT(op_rem,0,make_string("; else"));
        GenerateLabel(lab1);
        s2->Generate();
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
	looplevel++;
	s1->Generate();
	looplevel--;
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
	looplevel++;
    s1->Generate();
	looplevel--;
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
	int64_t *bf;
	int nn,jj;
	Statement *defcase, *stmt;
	AMODE *ap, *ap1;

	curlab = nextlabel++;
	defcase = 0;
	initstack();
		if (exp==NULL) {
		error(ERR_BAD_SWITCH_EXPR);
		return;
	}
    ap = GenerateExpression(exp,F_REG,GetNaturalSize(exp));
//        if( ap->preg != 0 )
//                GenerateDiadic(op_mov,0,makereg(1),ap);
//		ReleaseTempRegister(ap);
    for(stmt = s1; stmt != NULL; stmt = stmt->next )
    {
		stmt->GenMixedSource();
        if( stmt->s2 )          /* default case ? */
        {
			stmt->label = (int64_t *)curlab;
			defcase = stmt;
        }
        else
        {
			bf = (int64_t *)stmt->casevals;
			for (nn = (int)bf[0]; nn >= 1; nn--) {
				if ((jj = pwrof2(bf[nn])) != -1) {
					GenerateTriadicNT(op_bbs,0,ap,make_immed(jj),make_clabel(curlab));
				}
				else if (bf[nn] < -256 || bf[nn] > 255) {
					ap1 = GetTempRegister();
					GenerateTriadic(op_cmp,0,ap1,ap,make_immed(bf[nn]));
					ReleaseTempRegister(ap1);
					GenerateTriadicNT(op_beq,0,ap1,makereg(0),make_clabel(curlab));
				}
				else {
					GenerateTriadicNT(op_beqi,0,ap,make_immed(bf[nn]),make_clabel(curlab));
				}
			}
	        //GenerateDiadic(op_dw,0,make_label(curlab), make_direct(stmt->label));
            stmt->label = (int64_t *)curlab;
        }
        if( stmt->s1 != NULL && stmt->next != NULL )
            curlab = nextlabel++;
    }
    if( defcase == NULL )
        GenerateMonadicNT(op_bra,0,make_clabel(breaklab));
    else
		GenerateMonadicNT(op_bra,0,make_clabel((int)defcase->label));
    ReleaseTempRegister(ap);
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
	int64_t aa,bb;
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
	AMODE *ap, *ap1, *ap2;
	Statement *st, *defcase;
	int oldbreak;
	int tablabel;
	int64_t *bf;
	int64_t nn;
	int64_t mm,kk;
	int64_t minv,maxv;
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
		ap1 = GetTempRegister();
		ap2 = GetTempRegister();
		if (!nkd) {
			GenerateDiadic(op_ldi,0,ap1,make_immed(minv));
			GenerateTriadicNT(op_blt,0,ap,ap1,make_clabel(defcase ? (int)defcase->label : breaklab));
			GenerateDiadic(op_ldi,0,ap2,make_immed(maxv+1));
			GenerateTriadicNT(op_bge,0,ap,ap2,make_clabel(defcase ? (int)defcase->label : breaklab));
			//Generate4adic(op_chk,0,ap,ap1,ap2,make_clabel(defcase ? (int)defcase->label : breaklab));
		}
		if (minv != 0)
			GenerateTriadic(op_sub,0,ap,ap,make_immed(minv));
		GenerateTriadic(op_shl,0,ap,ap,make_immed(3));
		GenerateDiadic(op_lw,0,ap,make_indexed2(tablabel,ap->preg));
		GenerateDiadic(op_jal,0,makereg(0),make_indexed(0,ap->preg));
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
	oldthrow = throwlab;
	throwlab = nextlabel++;

	a = make_clabel(throwlab);
	a->mode = am_immed;
	GenerateDiadic(op_ldi,0,makereg(regXLR),a);
	s1->Generate();
	GenerateMonadicNT(op_bra,0,make_clabel(lab1));
	GenerateLabel(throwlab);
	// Generate catch statements
	// r1 holds the value to be assigned to the catch variable
	// r2 holds the type number
	for (stmt = s2; stmt; stmt = stmt->next) {
		stmt->GenMixedSource();
		throwlab = oldthrow;
		curlab = nextlabel++;
		GenerateLabel(curlab);
		if (stmt->num==99999)
			;
		else {
			ap2 = GetTempRegister();
			GenerateDiadic(op_ldi,0,ap2,make_immed(stmt->num));
			ReleaseTempReg(ap2);
			GenerateTriadicNT(op_bne,0,makereg(2),ap2,make_clabel(nextlabel));
		}
		// move the throw expression result in 'r1' into the catch variable.
		node = stmt->exp;
		ap2 = GenerateExpression(node,F_REG|F_MEM,GetNaturalSize(node));
		if (ap2->mode==am_reg)
			GenerateDiadic(op_mov,0,ap2,makereg(1));
		else
			GenStore(makereg(1),ap2,GetNaturalSize(node));
		ReleaseTempRegister(ap2);
		//            GenStore(makereg(1),make_indexed(sym->value.i,regFP),sym->tp->size);
		stmt->s1->Generate();
	}
	GenerateLabel(nextlabel);
	nextlabel++;
	GenerateLabel(lab1);
	a = make_clabel(oldthrow);
	a->mode = am_immed;
	GenerateDiadic(op_ldi,0,makereg(regXLR),a);
}

void Statement::GenerateThrow()
{
	AMODE *ap;

    if(exp != NULL )
	{
		initstack();
		ap = GenerateExpression(exp,F_ALL,8);
		if (ap->mode==am_immed)
           	GenerateDiadic(op_ldi,0,makereg(1),ap);
		else if( ap->mode != am_reg)
			GenerateDiadic(op_lw,0,makereg(1),ap);
		else if (ap->preg != 1 )
			GenerateDiadic(op_mov,0,makereg(1),ap);
		ReleaseTempRegister(ap);
		GenerateDiadic(op_ldi,0,makereg(2),make_immed(num));
	}
	GenerateMonadicNT(op_bra,0,make_clabel(throwlab));
}

void Statement::GenerateCheck()
{
     AMODE *ap1, *ap2, *ap3;
     ENODE *node, *ep;
     int size;

    initstack();
    ep = node = exp;
	if (ep->p[0]->nodetype==en_lt && ep->p[1]->nodetype==en_ge && equalnode(ep->p[0]->p[0],ep->p[1]->p[0])) {
        ep->nodetype = en_chk;
        if (ep->p[0])
            ep->p[2] = ep->p[0]->p[1];
        else
            ep->p[2] = NULL;
        ep->p[1] = ep->p[1]->p[1];
        ep->p[0] = ep->p[0]->p[0];
    }
	else if (ep->p[0]->nodetype==en_ge && ep->p[1]->nodetype==en_lt && equalnode(ep->p[0]->p[0],ep->p[1]->p[0])) {
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
	ap1 = GenerateExpression(node->p[0],F_REG,size);
	ap2 = GenerateExpression(node->p[1],F_REG|F_IMM0,size);
    ap3 = GenerateExpression(node->p[2],F_REG|F_IMMED,size);
	if (ap2->mode == am_immed) {
	   ap2->mode = am_reg;
	   ap2->preg = 0;
    }
	GenerateTriadic(ap3->mode==am_immed ? op_chki : op_chk,0,ap1,ap2,ap3);
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
			ReleaseTempRegister(GenerateExpression(sp->initexp,F_ALL,8));
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
			ReleaseTempRegister(GenerateExpression(sp->initexp,F_ALL,8));
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
                GenerateMonadicNT(op_bra,0,make_clabel((int64_t)stmt->label));
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
				tmpFreeAll();
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
                GenerateDiadic(isThor?op_br:op_bra,0,make_clabel(contlab),0);
                break;
        case st_break:
				if (breaklab==-1)
					error(ERR_NOT_IN_LOOP);
                GenerateDiadicNT(op_bra,0,make_clabel(breaklab),0);
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
	GenerateMonadicNT(op_stop,0,make_immed(num));
}

void Statement::GenerateAsm()
{
	GenerateMonadicNT(op_asm,0,make_string((char *)label));
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
       	initstack();
        breaklab = nextlabel++;
		ap1 = GetTempRegister();
		GenerateDiadic(op_lh,0,ap1,make_string(fcname));
       	GenerateTriadicNT(op_beq,0,ap1,makereg(0),make_clabel(breaklab));
		ReleaseTempRegister(ap1);
		GenerateDiadicNT(op_sh,0,makereg(0),make_string(fcname));
		s1->Generate();
        GenerateLabel(breaklab);
        breaklab = lab2;
    }
    contlab = lab1;
}
