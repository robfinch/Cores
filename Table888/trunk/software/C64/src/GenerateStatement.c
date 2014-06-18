// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2014  Robert Finch, Stratford
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
#include <stdio.h>
#include "c.h"
#include "expr.h"
#include "Statement.h"
#include "gen.h"
#include "cglbdec.h"

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

extern TYP              stdfunc;


int bitsset(int mask)
{
	int nn,bs=0;
	for (nn =0; nn < 32; nn++)
		if (mask & (1 << nn)) bs++;
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
    ap->offset = mask;
    return ap;
}

/*
 *      make a direct reference to an immediate value.
 */
AMODE *make_direct(__int64 i)
{
	return make_offset(makeinode(en_icon,i,0));
}

/*
 *      generate a direct reference to a string label.
 */
AMODE *make_strlab(char *s)
{
	AMODE *ap;
    ap = allocAmode();
    ap->mode = am_direct;
    ap->offset = makesnode(en_nacon,s);
    return ap;
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
		GenerateFalseJump(stmt->exp,breaklab,stmt->predreg);
		GenerateStatement(stmt->s1);
		GenerateDiadic(op_bra,0,make_clabel(contlab),NULL);
		GenerateLabel(breaklab);
		breaklab = lab2;        /* restore old break label */
    }
    else					        /* no loop code */
    {
		initstack();
		GenerateTrueJump(stmt->exp,contlab,stmt->predreg);
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
            GenerateTrueJump(stmt->exp,breaklab,stmt->predreg);
            GenerateStatement(stmt->s1);
            GenerateDiadic(op_bra,0,make_clabel(contlab),NULL);
            GenerateLabel(breaklab);
            breaklab = lab2;        /* restore old break label */
        }
        else					        /* no loop code */
        {
            initstack();
            GenerateFalseJump(stmt->exp,contlab,stmt->predreg);
        }
        contlab = lab1;         /* restore old continue label */
}


//      generate code to evaluate a for loop
//
void GenerateFor(struct snode *stmt)
{
	int     old_break, old_cont, exit_label, loop_label;
	AMODE *ap;

    old_break = breaklab;
    old_cont = contlab;
    loop_label = nextlabel++;
    exit_label = nextlabel++;
    contlab = loop_label;
    initstack();
    if( stmt->initExpr != NULL )
            ReleaseTempRegister(GenerateExpression(stmt->initExpr,F_ALL | F_NOVALUE
                    ,GetNaturalSize(stmt->initExpr)));
    GenerateLabel(loop_label);
    initstack();
    if( stmt->exp != NULL )
            GenerateFalseJump(stmt->exp,exit_label,stmt->predreg);
    if( stmt->s1 != NULL )
	{
            breaklab = exit_label;
            GenerateStatement(stmt->s1);
	}
    initstack();
    if( stmt->incrExpr != NULL )
            ReleaseTempRegister(GenerateExpression(stmt->incrExpr,F_ALL | F_NOVALUE,GetNaturalSize(stmt->incrExpr)));
    GenerateTriadic(op_bra,0,make_clabel(loop_label),NULL,NULL);
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
    GenerateDiadic(op_bra,0,make_clabel(loop_label),NULL);
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
			GenerateFalseJump(stmt->exp,lab1,stmt->predreg);
    GenerateFalseJump(stmt->exp,lab1,stmt->predreg);
    //if( stmt->s1 != 0 && stmt->s1->next != 0 )
    //    if( stmt->s2 != 0 )
    //        breaklab = lab2;
    //    else
    //        breaklab = lab1;
    GenerateStatement(stmt->s1);
    if( stmt->s2 != 0 )             /* else part exists */
    {
        GenerateDiadic(op_bra,0,make_clabel(lab2),0);
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
void GenerateDo(struct snode *stmt)
{
	int     oldcont, oldbreak;
    oldcont = contlab;
    oldbreak = breaklab;
    contlab = nextlabel++;
    GenerateLabel(contlab);
	breaklab = nextlabel++;
	GenerateStatement(stmt->s1);      /* generate body */
	initstack();
	GenerateTrueJump(stmt->exp,contlab,stmt->predreg);
	GenerateLabel(breaklab);
    breaklab = oldbreak;
    contlab = oldcont;
}

/*
 *      generate code for a do - while loop.
 */
void GenerateDoUntil(struct snode *stmt)
{
	int     oldcont, oldbreak;
    oldcont = contlab;
    oldbreak = breaklab;
    contlab = nextlabel++;
    GenerateLabel(contlab);
    breaklab = nextlabel++;
    GenerateStatement(stmt->s1);      /* generate body */
    initstack();
    GenerateFalseJump(stmt->exp,contlab,stmt->predreg);
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
	int nn;
	int predreg;
        struct snode    *defcase;
        struct amode    *ap;
		predreg = stmt->predreg;
        curlab = nextlabel++;
        defcase = 0;
        initstack();
		if (stmt->exp==NULL) {
			error(ERR_BAD_SWITCH_EXPR);
			return;
		}
        ap = GenerateExpression(stmt->exp,F_REG,4);
        if( ap->preg != 0 )
                GenerateDiadic(op_mov,0,makereg(1),ap);
		ReleaseTempRegister(ap);
        stmt = stmt->s1;
        while( stmt != NULL )
        {
            if( stmt->s2 )          /* default case ? */
            {
				stmt->label = curlab;
				defcase = stmt;
            }
            else
            {
				bf = stmt->label;
				for (nn = bf[0]; nn >= 1; nn--) {
					if (gCpu==888) {
						GenerateTriadic(op_cmp,0,make_string("flg0"),makereg(1),make_immed(bf[nn]));
						GenerateDiadic(op_beq,0,make_string("flg0"),make_clabel(curlab));
					}
					else {
						GenerateTriadic(op_cmp,0,makepred(predreg),makereg(1),make_immed(bf[nn]));
						GeneratePredicatedMonadic(predreg,PredOp(op_eq),op_bra,0,make_clabel(curlab));
					}
				}
		        //GenerateDiadic(op_dw,0,make_label(curlab), make_direct(stmt->label));
	            stmt->label = curlab;
            }
            if( stmt->s1 != NULL && stmt->next != NULL )
                curlab = nextlabel++;
            stmt = stmt->next;
        }
        if( defcase == NULL )
            GenerateTriadic(op_bra,0,make_clabel(breaklab),NULL,NULL);
        else
			GenerateTriadic(op_bra,0,make_clabel(defcase->label),NULL,NULL);
}


//      generate all cases for a switch statement.
//
void GenerateCase(Statement *stmt)
{
	while( stmt != NULL )
    {
		if( stmt->s1 != NULL )
		{
			GenerateLabel(stmt->label);
			GenerateStatement(stmt->s1);
		}
		else if( stmt->next == NULL )
			GenerateLabel(stmt->label);
		stmt = stmt->next;
    }
}

/*
 *      analyze and generate best switch statement.
 */
genxswitch(Statement *stmt)
{ 
	int     oldbreak;
    oldbreak = breaklab;
    breaklab = nextlabel++;
    GenerateSwitch(stmt);
    GenerateCase(stmt->s1);
    GenerateLabel(breaklab);
    breaklab = oldbreak;
}

int popcnt(int m)
{
	int n;
	int cnt;

	cnt =0;
	for (n = 0; n < 32; n = n + 1)
		if (m & (1 << n)) cnt = cnt + 1;
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
	char buf[20];
	AMODE *ap;
	SYM *sym;

    lab1 = nextlabel++;
	oldthrow = throwlab;
	throwlab = nextlabel++;

	GenerateDiadic(op_lea,0,makebreg(CLR),make_clabel(throwlab));
	GenerateStatement(stmt->s1);
    GenerateDiadic(op_bra,0,make_clabel(lab1),NULL);
	GenerateLabel(throwlab);
	stmt = stmt->s2;
	while (stmt) {
		throwlab = oldthrow;
		curlab = nextlabel++;
		GenerateLabel(curlab);
		if (stmt->s2==99999)
			;
		else
			GenerateTriadic(op_bnei,0,makereg(2),make_immed((int)stmt->s2),make_clabel(nextlabel));
		// move the throw expression result in 'r1' into the catch variable.
		sym = (SYM *)stmt->label;
		if (sym) {
			switch(sym->tp->size) {
			case 1:	GenerateDiadic(op_sb,0,makereg(1),make_indexed(sym->value.i,27));
			case 2: GenerateDiadic(op_sc,0,makereg(1),make_indexed(sym->value.i,27));
			case 4: GenerateDiadic(op_sh,0,makereg(1),make_indexed(sym->value.i,27));
			case 8: GenerateDiadic(op_sw,0,makereg(1),make_indexed(sym->value.i,27));
			}
		}
		GenerateStatement(stmt->s1);
		stmt=stmt->next;
	}
    GenerateLabel(lab1);
	GenerateDiadic(op_lea,0,makereg(28),make_clabel(oldthrow));
}

void GenerateThrow(Statement *stmt)
{
	AMODE *ap;

    if( stmt != NULL && stmt->exp != NULL )
	{
		initstack();
		ap = GenerateExpression(stmt->exp,F_ALL,8);
		if (ap->mode==am_immed)
			GenerateTriadic(op_ori,0,makereg(1),makereg(0),ap);
		else if( ap->mode != am_reg)
			GenerateDiadic(op_lw,0,makereg(1),ap);
		else if (ap->preg != 1 )
			GenerateTriadic(op_or,0,makereg(1),ap,makereg(0));
		ReleaseTempRegister(ap);
		GenerateTriadic(op_ori,0,makereg(2),makereg(0),make_immed((int)stmt->label));
	}
	GenerateDiadic(op_bra,0,make_clabel(throwlab),NULL);
}
/*
void GenerateCritical(struct snode *stmt)
{
	int lab1;

	lab1 = nextlabel++;
	semaphores[lastsph] = stmt->label;
	lastsph++;
    GenerateLabel(lab1);
	GenerateDiadic(op_tas,0,make_string(stmt->label),NULL);
	GenerateDiadic(op_bmi,0,make_label(lab1),NULL);
	GenerateStatement(stmt->s1);
	--lastsph;
	semaphores[lastsph] = NULL;
	GenerateDiadic(op_move,0,make_immed(0),make_string(stmt->label));
}
*/

void GenerateSpinlock(Statement *stmt)
{
	int lab1, lab2, lab3, lab4;
	AMODE *ap1, *ap2;
	AMODE *ap;

	lab1 = nextlabel++;
	lab2 = nextlabel++;
	lab3 = nextlabel++;

    if( stmt != NULL && stmt->exp != NULL )
	{
		initstack();
		ap1 = GetTempRegister();
		ap2 = GetTempRegister();
		ap = GenerateExpression(stmt->exp,F_REG,8);
		if (stmt->initExpr)
			GenerateTriadic(op_ori, 0, ap1,makereg(0),make_immed(stmt->initExpr));
		GenerateLabel(lab1);
		if (stmt->initExpr) {
			GenerateTriadic(op_sub, 0, ap1, ap1, make_immed(1));
			GenerateTriadic(op_eq, 0, ap1, makereg(0), make_label(lab2));
		}
		GenerateDiadic(op_inbu, 0, ap2, make_indexed(stmt->incrExpr,ap->preg));
		GenerateTriadic(op_eq, 0, ap2, makereg(0), make_label(lab1));
		GenerateStatement(stmt->s1);
		// unlock
		GenerateDiadic(op_outb, 0, makereg(0), make_indexed(stmt->incrExpr,ap->preg));
		if (stmt->initExpr) {
			GenerateTriadic(op_bra,0,make_clabel(lab3),NULL,NULL);
			GenerateLabel(lab2);
			GenerateStatement(stmt->s2);
			GenerateLabel(lab3);
		}
		else {
			printf("Warning: The lockfail code is unreachable because spinlock tries are infinite.\r\n");
		}
		ReleaseTempRegister(ap);
		ReleaseTempRegister(ap2);
		ReleaseTempRegister(ap1);
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

void GenerateSpinUnlock(struct snode *stmt)
{
	AMODE *ap;

    if( stmt != NULL && stmt->exp != NULL )
	{
		initstack();
		ap = GenerateExpression(stmt->exp,F_REG|F_IMMED,8);
		// Force return value into register 1
		if( ap->preg != 1 ) {
			if (ap->mode == am_immed)
				GenerateTriadic(op_ori, 0, makereg(1),makereg(0),ap);
			else
				GenerateDiadic(op_mov, 0, makereg(1),ap);
			GenerateDiadic(op_outb, 0, makereg(0),make_indexed(stmt->incrExpr,1));
		}
		ReleaseTempRegister(ap);
	}
}

void GenerateCompound(Statement *stmt)
{
	Statement *st;
	SYM *sp;

	sp = stmt->ssyms.head;
	while (sp) {
		if (sp->initexp)
			ReleaseTempRegister(GenerateExpression(sp->initexp,F_ALL,8));
		sp = sp->next;
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
        switch( stmt->stype )
                {
				//case st_vortex:
				//		gen_vortex(stmt);
				//		break;
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
                        GenerateLabel(stmt->label);
                        break;
                case st_goto:
                        GenerateDiadic(op_bra,0,make_clabel(stmt->label),0);
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
                case st_expr:
                        initstack();
                        ap = GenerateExpression(stmt->exp,F_ALL | F_NOVALUE,
                                GetNaturalSize(stmt->exp));
						ReleaseTempRegister(ap);
                        break;
                case st_return:
						if (gCpu==888)
							GenerateTable888Return(currentFn,stmt);
						else
							GenerateReturn(currentFn,stmt);
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
                        GenerateDiadic(op_bra,0,make_clabel(contlab),0);
                        break;
                case st_break:
                        GenerateDiadic(op_bra,0,make_clabel(breaklab),0);
                        break;
                case st_switch:
                        genxswitch(stmt);
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
	GenerateDiadic(op_sei,0,NULL,NULL);
}

void GenerateInton(Statement *stmt)
{
//	GenerateDiadic(op_move,0,make_string("_TCBsrsave"),make_string("sr"));
}

void GenerateStop(Statement *stmt)
{
	GenerateDiadic(op_stop,0,make_immed(0),NULL);
}

void GenerateAsm(Statement *stmt)
{
	GenerateTriadic(op_asm,0,make_string(stmt->label),NULL,NULL);
}

void GenerateFirstcall(Statement *stmt)
{
	int     lab1, lab2, lab3,lab4,lab5,lab6,lab7;
	char buf[20];
	AMODE *ap1,*ap2;

    lab1 = contlab;         /* save old continue label */
    lab2 = breaklab;        /* save old break label */
    contlab = nextlabel++;  /* new continue label */
	lab3 = nextlabel++;
	lab4 = nextlabel++;
	lab5 = nextlabel++;
	lab6 = nextlabel++;
	lab7 = nextlabel++;
    if( stmt->s1 != NULL )      /* has block */
    {
        breaklab = nextlabel++;
        GenerateLabel(lab3);	// marks address of brf
        GenerateDiadic(op_bra,0,make_clabel(lab7),NULL);	// branch to the firstcall statement
        GenerateLabel(lab6);	// prevent optimizer from optimizing move away
		GenerateDiadic(op_bra,0,make_clabel(breaklab),NULL);	// then branch around it
        GenerateLabel(lab7);	// prevent optimizer from optimizing move away
		ap1 = GetTempRegister();
		ap2 = GetTempRegister();
		GenerateDiadic(op_lea,0,ap2,make_label(lab3));
		GenerateTriadic(op_andi,0,ap2,ap2,make_immed(0x0c));
		GenerateTriadic(op_beqi,0,ap2,make_immed(0x08L),make_label(lab4));
		GenerateTriadic(op_beqi,0,ap2,make_immed(0x04L),make_label(lab5));
		GenerateDiadic(op_lea,0,ap2,make_label(lab3));
		GenerateDiadic(op_lw,0,ap1,make_indirect(ap2->preg));
		GenerateTriadic(op_andi,0,ap1,ap1,make_immed(0xFFFFFC0000000000L));
		GenerateTriadic(op_ori,0,ap1,ap1,make_immed(0x000037800000000L));	// nop instruction
		GenerateDiadic(op_sw,0,ap1,make_indirect(ap2->preg));
		GenerateDiadic(op_cache,0,make_string("invil"),make_indirect(ap2->preg));
		GenerateDiadic(op_bra,0,make_label(lab6),NULL);
		GenerateLabel(lab4);
		GenerateDiadic(op_lea,0,ap2,make_label(lab3));
		GenerateDiadic(op_lw,0,ap1,make_indirect(ap2->preg));
		GenerateTriadic(op_andi,0,ap1,ap1,make_immed(0x00000000000FFFFFL));
		GenerateTriadic(op_ori,0,ap1,ap1,make_immed(0x3780000000000000L));	// nop instruction
		GenerateDiadic(op_sw,0,ap1,make_indirect(ap2->preg));
		GenerateDiadic(op_cache,0,make_string("invil"),make_indirect(ap2->preg));
		GenerateDiadic(op_bra,0,make_label(lab6),NULL);
		GenerateLabel(lab5);
		GenerateDiadic(op_lea,0,ap2,make_label(lab3));
		GenerateDiadic(op_lw,0,ap1,make_indexed(4,ap2->preg));
		GenerateTriadic(op_andi,0,ap1,ap1,make_immed(0xFFFFFFFFFFF00000L));
		GenerateTriadic(op_ori,0,ap1,ap1,make_immed(0x00000000000DE000L));	// nop instruction
		GenerateDiadic(op_sw,0,ap1,make_indexed(4,ap2->preg));
		GenerateDiadic(op_cache,0,make_string("invil"),make_indexed(4,ap2->preg));
		GenerateLabel(lab6);
		GenerateStatement(stmt->s1);
        GenerateLabel(breaklab);
        breaklab = lab2;        /* restore old break label */
    }
    contlab = lab1;         /* restore old continue label */
}
