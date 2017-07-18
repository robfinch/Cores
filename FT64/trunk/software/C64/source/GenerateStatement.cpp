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

extern char *rtrim(char *);
extern int caselit(scase *casetab,int);

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

/*
 *      generate a direct reference to a string label.
 */
AMODE *make_strlab(std::string s)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_direct;
    ap->offset = makesnode(en_nacon,&s,&s,-1);
    return ap;
}

void GenMixedSource(Statement *stmt)
{
    if (mixedSource) {
        rtrim(stmt->lptr);
        if (strcmp(stmt->lptr,last_rem)!=0) {
          	GenerateMonadic(op_rem,0,make_string(stmt->lptr));
          	strncpy_s(last_rem,131,stmt->lptr,130);
          	last_rem[131] = '\0';
        }
    }
}

/*
 *      generate code to evaluate a while statement.
 */
void GenerateWhile(struct snode *stmt)
{
	int lab1, lab2;

    initstack();            /* initialize temp registers */
    lab1 = contlab;         /* save old continue label */
    lab2 = breaklab;        /* save old break label */
    contlab = nextlabel++;  /* new continue label */
    GenerateLabel(contlab);
    if( stmt->s1 != NULL )      /* has block */
    {
		breaklab = nextlabel++;
		initstack();
		GenerateFalseJump(stmt->exp,breaklab);
		GenerateStatement(stmt->s1);
		GenerateMonadic(op_bra,0,make_clabel(contlab));
		GenerateLabel(breaklab);
		breaklab = lab2;        /* restore old break label */
    }
    else					        /* no loop code */
    {
		initstack();
		GenerateTrueJump(stmt->exp,contlab);
    }
    contlab = lab1;         /* restore old continue label */
}

/*
 *      generate code to evaluate an until statement.
 */
void GenerateUntil(Statement *stmt)
{
	int lab1, lab2;

	initstack();            /* initialize temp registers */
	lab1 = contlab;         /* save old continue label */
	lab2 = breaklab;        /* save old break label */
	contlab = nextlabel++;  /* new continue label */
	GenerateLabel(contlab);
	if( stmt->s1 != NULL )      /* has block */
	{
		breaklab = nextlabel++;
		initstack();
		GenerateTrueJump(stmt->exp,breaklab);
		GenerateStatement(stmt->s1);
		GenerateMonadic(op_bra,0,make_clabel(contlab));
		GenerateLabel(breaklab);
		breaklab = lab2;        /* restore old break label */
	}
	else					        /* no loop code */
	{
		initstack();
		GenerateFalseJump(stmt->exp,contlab);
	}
	contlab = lab1;         /* restore old continue label */
}


//      generate code to evaluate a for loop
//
void GenerateFor(struct snode *stmt)
{
	int     old_break, old_cont, exit_label, loop_label;

    old_break = breaklab;
    old_cont = contlab;
    loop_label = nextlabel++;
    exit_label = nextlabel++;
    contlab = nextlabel++;
    initstack();
    if( stmt->initExpr != NULL )
            ReleaseTempRegister(GenerateExpression(stmt->initExpr,F_ALL | F_NOVALUE
                    ,GetNaturalSize(stmt->initExpr)));
    GenerateLabel(loop_label);
    initstack();
    if( stmt->exp != NULL )
            GenerateFalseJump(stmt->exp,exit_label);
    if( stmt->s1 != NULL )
	{
            breaklab = exit_label;
            GenerateStatement(stmt->s1);
	}
	GenerateLabel(contlab);
    initstack();
    if( stmt->incrExpr != NULL )
            ReleaseTempRegister(GenerateExpression(stmt->incrExpr,F_ALL | F_NOVALUE,GetNaturalSize(stmt->incrExpr)));
    GenerateMonadic(op_bra,0,make_clabel(loop_label));
    breaklab = old_break;
    contlab = old_cont;
    GenerateLabel(exit_label);
}


//     generate code to evaluate a forever loop
//
void GenerateForever(Statement *stmt)
{
	int old_break, old_cont, exit_label, loop_label;
    old_break = breaklab;
    old_cont = contlab;
    loop_label = nextlabel++;
    exit_label = nextlabel++;
    contlab = loop_label;
    GenerateLabel(loop_label);
    if( stmt->s1 != NULL )
	{
        breaklab = exit_label;
        GenerateStatement(stmt->s1);
	}
    GenerateMonadic(op_bra,0,make_clabel(loop_label));
    breaklab = old_break;
    contlab = old_cont;
    GenerateLabel(exit_label);
}

/*
 *      generate code to evaluate an if statement.
 */
void GenerateIf(Statement *stmt)
{
	int lab1, lab2, oldbreak;
    lab1 = nextlabel++;     /* else label */
    lab2 = nextlabel++;     /* exit label */
    oldbreak = breaklab;    /* save break label */
    initstack();            /* clear temps */
	if (gCpu!=888)
		if (stmt->predreg==70)
			GenerateFalseJump(stmt->exp,lab1);
    GenerateFalseJump(stmt->exp,lab1);
    //if( stmt->s1 != 0 && stmt->s1->next != 0 )
    //    if( stmt->s2 != 0 )
    //        breaklab = lab2;
    //    else
    //        breaklab = lab1;
    GenerateStatement(stmt->s1);
    if( stmt->s2 != 0 )             /* else part exists */
    {
        GenerateDiadic(op_bra,0,make_clabel(lab2),0);
        if (mixedSource)
          	GenerateMonadic(op_rem,0,make_string("; else"));
        GenerateLabel(lab1);
        //if( stmt->s2 == 0 || stmt->s2->next == 0 )
        //    breaklab = oldbreak;
        //else
        //    breaklab = lab2;
        GenerateStatement(stmt->s2);
        GenerateLabel(lab2);
    }
    else                            /* no else code */
        GenerateLabel(lab1);
    breaklab = oldbreak;
}

/*
 *      generate code for a do - while loop.
 */
void GenerateDo(Statement *stmt)
{
	int     oldcont, oldbreak;
    oldcont = contlab;
    oldbreak = breaklab;
    contlab = nextlabel++;
    GenerateLabel(contlab);
	breaklab = nextlabel++;
	GenerateStatement(stmt->s1);      /* generate body */
	initstack();
	GenerateTrueJump(stmt->exp,contlab);
	GenerateLabel(breaklab);
    breaklab = oldbreak;
    contlab = oldcont;
}

/*
 *      generate code for a do - while loop.
 */
void GenerateDoUntil(Statement *stmt)
{
	int     oldcont, oldbreak;
    oldcont = contlab;
    oldbreak = breaklab;
    contlab = nextlabel++;
    GenerateLabel(contlab);
    breaklab = nextlabel++;
    GenerateStatement(stmt->s1);      /* generate body */
    initstack();
    GenerateFalseJump(stmt->exp,contlab);
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

/*
 *      generate a linear search switch statement.
 */
void GenerateSwitch(Statement *stmt)
{    
	int             curlab;
	int *bf;
	int nn,jj;
  struct snode    *defcase;
  AMODE *ap, *ap1;

  curlab = nextlabel++;
  defcase = 0;
  initstack();
  if (stmt->exp==NULL) {
	  error(ERR_BAD_SWITCH_EXPR);
		return;
	}
        ap = GenerateExpression(stmt->exp,F_REG,GetNaturalSize(stmt->exp));
//        if( ap->preg != 0 )
//                GenerateDiadic(op_mov,0,makereg(1),ap);
//		ReleaseTempRegister(ap);
        stmt = stmt->s1;
        while( stmt != NULL )
        {
			GenMixedSource(stmt);
            if( stmt->s2 )          /* default case ? */
            {
				stmt->label = (int *)curlab;
				defcase = stmt;
            }
            else
            {
				bf = (int *)stmt->casevals;
				for (nn = bf[0]; nn >= 1; nn--) {
					if ((jj = pwrof2(bf[nn])) != -1) {
						GenerateTriadic(op_bbs,0,ap,make_immed(jj),make_clabel(curlab));
					}
					else if (bf[nn] < -256 || bf[nn] > 255) {
						ap1 = GetTempRegister();
						GenerateTriadic(op_cmp,0,ap1,ap,make_immed(bf[nn]));
						ReleaseTempRegister(ap1);
						GenerateTriadic(op_beq,0,ap1,makereg(0),make_clabel(curlab));
					}
					else {
						GenerateTriadic(op_beqi,0,ap,make_immed(bf[nn]),make_clabel(curlab));
					}
				}
		        //GenerateDiadic(op_dw,0,make_label(curlab), make_direct(stmt->label));
	            stmt->label = (int *)curlab;
            }
            if( stmt->s1 != NULL && stmt->next != NULL )
                curlab = nextlabel++;
            stmt = stmt->next;
        }
        if( defcase == NULL )
            GenerateMonadic(op_bra,0,make_clabel(breaklab));
        else
			GenerateMonadic(op_bra,0,make_clabel((int)defcase->label));
    ReleaseTempRegister(ap);
}


//      generate all cases for a switch statement.
//
void GenerateCase(Statement *stmt)
{
	while( stmt != (Statement *)NULL )
    {
		GenMixedSource(stmt);
		if( stmt->s1 != (Statement *)NULL )
		{
			GenerateLabel((int)stmt->label);
			GenerateStatement(stmt->s1);
		}
		else if( stmt->next == (Statement *)NULL )
			GenerateLabel((int)stmt->label);
		stmt = stmt->next;
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

/*
 *      analyze and generate best switch statement.
 */
void genxswitch(Statement *stmt)
{ 
	AMODE *ap, *ap1, *ap2;
	Statement *st, *defcase;
	int     oldbreak;
	int tablabel;
	int *bf;
	int nn,mm,kk;
	int minv,maxv;
	int deflbl;
	int curlab;
    oldbreak = breaklab;
    breaklab = nextlabel++;
	bf = (int *)stmt->label;
	minv = 0x7FFFFFFFL;
	maxv = 0;
	struct scase casetab[512];

	st = stmt->s1;
	mm = 0;
	deflbl = 0;
	defcase = nullptr;
	curlab = nextlabel++;
	// Determine minimum and maximum values in all cases
	// Record case values and labels.
	while( st != (Statement *)NULL )
	{
		if (st->s2) {
			defcase = st->s2;
			deflbl = (int)st->s2->label;
		}
		else {
			bf = st->casevals;
			for (nn = bf[0]; nn >= 1; nn--) {
				if (bf[nn] < minv) minv = bf[nn];
				if (bf[nn] > maxv) maxv = bf[nn];
				st->label = (int *)curlab;
				casetab[mm].label = curlab;
				casetab[mm].val = bf[nn];
				mm++;
			}
			curlab = nextlabel++;
		}
		st = st->next;
	}
	//
	// check case density
	// If there are enough cases
	// and if the case is dense enough use a computed jump
	if (mm * 100 / (maxv-minv) > 50 && (maxv-minv) > (stmt->nkd ? 7 : 12)) {
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
	    ap = GenerateExpression(stmt->exp,F_REG,GetNaturalSize(stmt->exp));
		ap1 = GetTempRegister();
		ap2 = GetTempRegister();
		if (!stmt->nkd) {
			GenerateDiadic(op_ldi,0,ap1,make_immed(minv));
			GenerateDiadic(op_ldi,0,ap2,make_immed(maxv+1));
			Generate4adic(op_chk,0,ap,ap1,ap2,make_clabel(defcase ? (int)defcase->label : breaklab));
		}
		GenerateTriadic(op_sub,0,ap,ap,make_immed(minv));
		GenerateTriadic(op_shl,0,ap,ap,make_immed(3));
		GenerateDiadic(op_lw,0,ap,make_indexed2(tablabel,ap->preg));
		GenerateDiadic(op_jal,0,makereg(0),make_indexed(0,ap->preg));
		GenerateCase(stmt->s1);
		GenerateLabel(breaklab);
		return;
	}
	GenerateSwitch(stmt);
	GenerateCase(stmt->s1);
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
/*
void gen_regsave()
{
	int lab1;

	lab1 = nextlabel++;
	GenerateLabel(lab1);
	GenerateDiadic(op_tas,1,make_strlab("sfRunningTCB"),NULL);
	GenerateDiadic(op_bmi,0,make_label(lab1),NULL);
	GenerateDiadic(op_move,0,makereg(1),make_strlab("a0save"));
	GenerateDiadic(op_move,0,make_strlab("RunningTCB"),makereg(1));
	GenerateDiadic(op_movem,0,make_strlab("d0-d7/a0-a7"),make_strlab("(a0)"));
	GenerateDiadic(op_move,0,make_strlab("a0save"),make_strlab("32(a0)"));
	GenerateDiadic(op_move,0,make_strlab("usp"),makereg(1));
	GenerateDiadic(op_move,0,makereg(1),make_strlab("64(a0)"));
	GenerateDiadic(op_move,0,make_strlab("4(a7)"),make_strlab("68(a0)"));

	//GenerateDiadic(op_move,4,make_string("sr"),make_string("_TCBsrsave"));
	//GenerateDiadic(op_movem,4,make_mask(0xFFFF),make_string("_TCBregsave"));
	//GenerateDiadic(op_move,4,make_string("usp"),make_string("a0"));
	//GenerateDiadic(op_move,4,make_string("a0"),make_string("_TCBuspsave"));
}

void gen_regrestore()
{
	GenerateDiadic(op_move,0,make_strlab("_TCBuspsave"),make_string("a0"));
	GenerateDiadic(op_move,0,make_string("a0"),make_string("usp"));
	GenerateDiadic(op_movem,0,make_string("_TCBregsave"),make_mask(0xFFFF));
	GenerateDiadic(op_move,0,make_string("_TCBsrsave"),make_string("sr"));
}
*/
/*
void gen_vortex(struct snode *stmt)
{
    int lab1;

    lab1 = nextlabel++;
    GenerateDiadic(op_bra,0,make_label(lab1),0);
    //gen_ilabel(stmt->label);
	gen_regsave();
	GenerateStatement(stmt->s1);
	gen_regrestore();
	GenerateDiadic(op_rte,0,0,0);
    GenerateLabel(lab1);
}
*/

void GenerateTry(Statement *stmt)
{
  int lab1,curlab;
	int oldthrow;
	AMODE *a, *ap2;
	ENODE *node;

  lab1 = nextlabel++;
	oldthrow = throwlab;
	throwlab = nextlabel++;

    a = make_clabel(throwlab);
    a->mode = am_immed;
	GenerateDiadic(op_ldi,0,makereg(regXLR),a);
	GenerateStatement(stmt->s1);
  GenerateMonadic(op_bra,0,make_clabel(lab1));
	GenerateLabel(throwlab);
	stmt = stmt->s2;
	// Generate catch statements
	// r1 holds the value to be assigned to the catch variable
	// r2 holds the type number
	while (stmt) {
    GenMixedSource(stmt);
		throwlab = oldthrow;
		curlab = nextlabel++;
		GenerateLabel(curlab);
		if (stmt->s2==(Statement *)99999)
			;
		else {
			GenerateTriadic(op_bnei,0,makereg(2),make_immed((int)stmt->s2),make_clabel(nextlabel));
		}
		// move the throw expression result in 'r1' into the catch variable.
		node = (ENODE *)stmt->label;
    {
      ap2 = GenerateExpression(node,F_REG|F_MEM,GetNaturalSize(node));
      if (ap2->mode==am_reg)
         GenerateDiadic(op_mov,0,ap2,makereg(1));
      else
         GenStore(makereg(1),ap2,GetNaturalSize(node));
      ReleaseTempRegister(ap2);
    }
//            GenStore(makereg(1),make_indexed(sym->value.i,regBP),sym->tp->size);
		GenerateStatement(stmt->s1);
		stmt=stmt->next;
	}
	GenerateLabel(nextlabel);
	nextlabel++;
  GenerateLabel(lab1);
    a = make_clabel(oldthrow);
    a->mode = am_immed;
	GenerateDiadic(op_ldi,0,makereg(regXLR),a);
}

void GenerateThrow(Statement *stmt)
{
	AMODE *ap;

    if( stmt != NULL && stmt->exp != NULL )
	{
		initstack();
		ap = GenerateExpression(stmt->exp,F_ALL,8);
		if (ap->mode==am_immed) {
           	GenerateDiadic(op_ldi,0,makereg(1),ap);
        }
		else if( ap->mode != am_reg)
			GenerateDiadic(op_lw,0,makereg(1),ap);
		else if (ap->preg != 1 )
			GenerateDiadic(op_mov,0,makereg(1),ap);
		ReleaseTempRegister(ap);
		GenerateDiadic(op_ldi,0,makereg(2),make_immed((int)stmt->label));
	}
	GenerateMonadic(op_bra,0,make_clabel(throwlab));
}

void GenerateCheck(Statement * stmt)
{
     AMODE *ap1, *ap2, *ap3;
     ENODE *node, *ep;
     int size;

    initstack();
    ep = node = stmt->exp;
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

void GenerateSpinlock(Statement *stmt)
{
	int lab1, lab2, lab3;
	AMODE *ap1, *ap2;
	AMODE *ap;
	int sp = 0;

	lab1 = nextlabel++;
	lab2 = nextlabel++;
	lab3 = nextlabel++;

    if( stmt != (Statement *)NULL && stmt->exp != (ENODE *)NULL )
	{
		initstack();
		ap1 = GetTempRegister();
		ap2 = GetTempRegister();
		ap = GenerateExpression(stmt->exp,F_REG,8);
		GenerateDiadic(op_mov,0,makereg(1),ap);
		if (stmt->initExpr) {
		    GenerateTriadic(op_ori, 0, makereg(2),makereg(0),make_immed((int64_t)stmt->initExpr));
        }
        else {
            GenerateDiadic(op_ldi,0,makereg(2),make_immed(-1));
        }
        GenerateMonadic(op_bsr,0,make_string("_LockSema"));
        if (stmt->initExpr)
            GenerateDiadic(op_beq,0,makereg(1),make_clabel(lab2));
		ReleaseTempRegister(ap);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
        // We treat this statement generation like a function call and save
        // the used temporary beforehand.  The statement might reinitialize
        // the expression vars. There aren't any other cases where temporaries
        // are needed after statements are generated.
       	GenerateMonadic(op_push,0,ap);
		GenerateStatement(stmt->s1);
    	GenerateMonadic(op_pop,0,ap);
		// unlock
		if (isRaptor64)
			GenerateDiadic(op_outb, 0, makereg(0), make_indexed((int64_t)stmt->incrExpr,ap->preg));
		else if (isFISA64) {
            GenerateDiadic(op_mov, 0, makereg(1), makereg(ap->preg));
            GenerateMonadic(op_bsr, 0, make_string("_UnlockSema"));
        }
		else
			GenerateDiadic(op_sw, 0, makereg(0), make_indexed((int64_t)stmt->incrExpr,ap->preg));
		if (stmt->initExpr) {
			GenerateMonadic(isThor?op_br:op_bra,0,make_clabel(lab3));
			GenerateLabel(lab2);
			GenerateStatement(stmt->s2);
			GenerateLabel(lab3);
		}
		else {
			printf("Warning: The lockfail code is unreachable because spinlock tries are infinite.\r\n");
		}
	}

	//ap1 = GetTempRegister();
	//ap2 = GetTempRegister();
	//if (stmt->exp) {
	//	lab2 = nextlabel++;
	//	GenerateTriadic(op_ori,0,ap2,makereg(0),make_immed(stmt->exp));
	//    GenerateLabel(lab1);
	//	GenerateTriadic(op_beq,0,ap2,makereg(0),make_label(lab2));
	//	GenerateTriadic(op_subui,0,ap2,ap2,make_immed(1));
	//	GenerateTriadic(op_lwr,0,ap1,make_string(stmt->label),NULL);
	//	GenerateTriadic(op_bne,0,ap1,makereg(0),make_label(lab1),NULL);
	//	GenerateTriadic(op_not,0,ap1,ap1,NULL);
	//	GenerateTriadic(op_swc,0,ap1,make_string(stmt->label),NULL);
	//	GenerateTriadic(op_bnr,0,make_label(lab1),NULL,NULL);
	//}
	//else {
	//	GenerateLabel(lab1);
	//	GenerateTriadic(op_lwr,0,ap1,make_string(stmt->label),NULL);
	//	GenerateTriadic(op_bne,0,ap1,makereg(0),make_label(lab1),NULL);
	//	GenerateTriadic(op_not,0,ap1,ap1,NULL);
	//	GenerateTriadic(op_swc,0,ap1,make_string(stmt->label),NULL);
	//	GenerateTriadic(op_bnr,0,make_label(lab1),NULL,NULL);
	//}
	//ReleaseTempRegister(ap1);
	//ReleaseTempRegister(ap2);
	//GenerateStatement(stmt->s1);
	//GenerateDiadic(op_sb,0,makereg(0),make_string(stmt->label));
	//if (stmt->exp) {
	//	lab3 = nextlabel++;
	//	GenerateTriadic(op_bra,0,make_label(lab3),NULL,NULL);
	//	GenerateLabel(lab2);
	//	GenerateStatement(stmt->s2);
	//	GenerateLabel(lab3);
	//}
	//else {
	//	printf("Warning: The lockfail code is unreachable because spinlock tries are infinite.\r\n");
	//}
}

void GenerateSpinUnlock(Statement *stmt)
{
	AMODE *ap;

    if( stmt != NULL && stmt->exp != NULL )
	{
		initstack();
		ap = GenerateExpression(stmt->exp,F_REG|F_IMMED,8);
		// Force return value into register 1
		if( ap->preg != 1 ) {
			if (ap->mode == am_immed) {
			    GenerateTriadic(op_ori, 0, makereg(1),makereg(0),ap);
            }
			else
				GenerateDiadic(op_mov, 0, makereg(1),ap);
			if (isRaptor64)
				GenerateDiadic(op_outb, 0, makereg(0),make_indexed((int64_t)stmt->incrExpr,1));
    		else if (isFISA64) {
                GenerateMonadic(op_bsr, 0, make_string("_UnlockSema"));
            }
			else
				GenerateDiadic(op_sb, 0, makereg(0),make_indexed((int64_t)stmt->incrExpr,1));
		}
		ReleaseTempRegister(ap);
	}
}

void GenerateCompound(Statement *stmt)
{
	SYM *sp;

//    if (stmt->prolog)
//        GenerateStatement(stmt->prolog);
	sp = sp->GetPtr(stmt->ssyms.GetHead());
	while (sp) {
		if (sp->initexp) {
        	initstack();
			ReleaseTempRegister(GenerateExpression(sp->initexp,F_ALL,8));
        }
		sp = sp->GetNextPtr();
	}
	// Generate statement will process the entire list of statements in
	// the block.
	GenerateStatement(stmt->s1);
//    if (stmt->epilog)
//        GenerateStatement(stmt->epilog);
}

// The same as generating a compound statement but leaves out the generation of
// the prolog and epilog clauses.
void GenerateFuncbody(Statement *stmt)
{
	SYM *sp;

	sp = sp->GetPtr(stmt->ssyms.GetHead());
	while (sp) {
		if (sp->initexp) {
        	initstack();
			ReleaseTempRegister(GenerateExpression(sp->initexp,F_ALL,8));
        }
		sp = sp->GetNextPtr();
	}
	// Generate statement will process the entire list of statements in
	// the block.
	GenerateStatement(stmt->s1);
}

/*
 *      genstmt will generate a statement and follow the next pointer
 *      until the block is generated.
 */
void GenerateStatement(Statement *stmt)
{
	AMODE *ap;
 
	while( stmt != NULL )
    {
        GenMixedSource(stmt);
        switch( stmt->stype )
                {
				//case st_vortex:
				//		gen_vortex(stmt);
				//		break;
	            case st_funcbody:
                        GenerateFuncbody(stmt);
                        break;
				case st_compound:
						GenerateCompound(stmt);
						break;
				case st_try:
						GenerateTry(stmt);
						break;
				case st_throw:
						GenerateThrow(stmt);
						break;
				case st_intoff:
						GenerateIntoff(stmt);
						break;
				case st_stop:
						GenerateStop(stmt);
						break;
				case st_inton:
						GenerateInton(stmt);
						break;
				case st_asm:
						GenerateAsm(stmt);
						break;
                case st_label:
                        GenerateLabel((int64_t)stmt->label);
                        break;
                case st_goto:
                        GenerateMonadic(isThor?op_br:op_bra,0,make_clabel((int64_t)stmt->label));
                        break;
				//case st_critical:
    //                    GenerateCritical(stmt);
    //                    break;
				case st_spinlock:
						GenerateSpinlock(stmt);
						break;
				case st_spinunlock:
						GenerateSpinUnlock(stmt);
						break;
				case st_check:
                        GenerateCheck(stmt);
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
                        GenerateIf(stmt);
                        break;
                case st_do:
                        GenerateDo(stmt);
                        break;
                case st_dountil:
                        GenerateDoUntil(stmt);
                        break;
                case st_doloop:
                        GenerateForever(stmt);
                        break;
                case st_while:
                        GenerateWhile(stmt);
                        break;
                case st_until:
                        GenerateUntil(stmt);
                        break;
                case st_for:
                        GenerateFor(stmt);
                        break;
                case st_forever:
                        GenerateForever(stmt);
                        break;
                case st_firstcall:
                        GenerateFirstcall(stmt);
                        break;
                case st_continue:
						if (contlab==-1)
							error(ERR_NOT_IN_LOOP);
                        GenerateDiadic(isThor?op_br:op_bra,0,make_clabel(contlab),0);
                        break;
                case st_break:
						if (breaklab==-1)
							error(ERR_NOT_IN_LOOP);
                        GenerateDiadic(op_bra,0,make_clabel(breaklab),0);
                        break;
                case st_switch:
                        genxswitch(stmt);
                        break;
				case st_empty:
						break;
                default:
                        printf("DIAG - unknown statement.\n");
                        break;
                }
        stmt = stmt->next;
    }
}

void GenerateIntoff(Statement *stmt)
{
//	GenerateDiadic(op_move,0,make_string("sr"),make_string("_TCBsrsave"));
	GenerateMonadic(op_sei,0,(AMODE *)NULL);
}

void GenerateInton(Statement *stmt)
{
//	GenerateDiadic(op_move,0,make_string("_TCBsrsave"),make_string("sr"));
}

void GenerateStop(Statement *stmt)
{
	GenerateMonadic(op_stop,0,make_immed(0));
}

void GenerateAsm(Statement *stmt)
{
	GenerateMonadic(op_asm,0,make_string((char *)stmt->label));
}

void GenerateFirstcall(Statement *stmt)
{
	int     lab1, lab2;
	AMODE *ap1;

    lab1 = contlab;         /* save old continue label */
    lab2 = breaklab;        /* save old break label */
    contlab = nextlabel++;  /* new continue label */
    if( stmt->s1 != NULL )      /* has block */
    {
        breaklab = nextlabel++;
		ap1 = GetTempRegister();
		GenerateDiadic(op_ldt,0,ap1,make_string(stmt->fcname));
       	GenerateTriadic(op_beq,0,ap1,makereg(0),make_clabel(breaklab));
		ReleaseTempRegister(ap1);
		GenerateDiadic(op_stt,0,makereg(0),make_string(stmt->fcname));
		GenerateStatement(stmt->s1);
        GenerateLabel(breaklab);
        breaklab = lab2;        /* restore old break label */
    }
    contlab = lab1;         /* restore old continue label */
}
