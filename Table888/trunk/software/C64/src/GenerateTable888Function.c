// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - Raptor64 'C' derived language compiler
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
#include <string.h>
#include "c.h"
#include "expr.h"
#include "Statement.h"
#include "gen.h"
#include "cglbdec.h"

extern int     breaklab;
extern int     contlab;
extern int     retlab;
extern int		throwlab;

extern int lastsph;
extern char *semaphores[20];

extern TYP              stdfunc;

void GenerateTable888Return(SYM *sym, Statement *stmt);


// Generate a function body.
//
void GenerateTable888Function(SYM *sym, Statement *stmt)
{
	char buf[20];
	char *bl;
	int cnt, nn;
	AMODE *ap, *ap2;
	ENODE *ep;
	SYM *sp;

	throwlab = retlab = contlab = breaklab = -1;
	lastsph = 0;
	memset(semaphores,0,sizeof(semaphores));
	throwlab = nextlabel++;
	while( lc_auto & 7 )	/* round frame size to word */
		++lc_auto;
	if (sym->IsInterrupt) {
		//GenerateTriadic(op_subui,0,makereg(30),makereg(30),make_immed(30*8));
		//GenerateDiadic(op_sm,0,make_indirect(30), make_mask(0x9FFFFFFE));
	}
	// 24[bp]   return address
	// 16[bp]	flags
	// 8[bp]	catch link register
	// 0[bp]	base pointer
	if (!sym->IsNocall) {
//		GenerateTriadic(op_subui,0,makereg(SP),makereg(SP),make_immed(32));
		if (lc_auto || sym->NumParms > 0) {
			//GenerateMonadic(op_link,0,make_immed(24));
			GenerateTriadic(op_subui,0,makereg(SP),makereg(SP),make_immed(24));
			GenerateDiadic(op_sw,0,makereg(BP),make_indirect(SP));
			GenerateDiadic(op_mov,0,makereg(BP),makereg(SP));
		}
		else
			GenerateTriadic(op_subui,0,makereg(SP),makereg(SP),make_immed(24));
		if (exceptions) {
			GenerateDiadic(op_sw, 0, makereg(CLR), make_indexed(8,SP));
			ep = xalloc(sizeof(struct enode));
			ep->nodetype = en_clabcon;
			ep->i = throwlab;
			ap = allocAmode();
			ap->mode = am_immed;
			ap->offset = ep;
			GenerateDiadic(op_ldi,0, makereg(CLR), ap);
		}
		if (lc_auto || sym->NumParms > 0) {
//			GenerateDiadic(op_mov,0,makereg(BP),makereg(SP));
			if (lc_auto)
				GenerateTriadic(op_subui,0,makereg(SP),makereg(SP),make_immed(lc_auto));
		}

		// Save registers used as register variables.
		// **** Done in Analyze.c ****
		//if( save_mask != 0 ) {
		//	GenerateTriadic(op_subui,0,makereg(SP),makereg(SP),make_immed(popcnt(save_mask)*8));
		//	cnt = (bitsset(save_mask)-1)*8;
		//	for (nn = 31; nn >=1 ; nn--) {
		//		if (save_mask & (1 << nn)) {
		//			GenerateTriadic(op_sw,0,makereg(nn),make_indexed(cnt,SP),NULL);
		//			cnt -= 8;
		//		}
		//	}
		//}
	}
	if (optimize)
		sym->NumRegisterVars = opt1(stmt);
    GenerateStatement(stmt);
    GenerateTable888Return(sym,0);
	// Generate code for the hidden default catch
	if (exceptions) {
		GenerateLabel(throwlab);
		GenerateDiadic(op_lw,0,makereg(CLR),make_indexed(8,BP));		// load throw return address from stack into LR
		GenerateDiadic(op_sw,0,makereg(CLR),make_indexed(24,BP));		// and store it back (so it can be picked up by RTS)
		GenerateDiadic(op_bra,0,make_clabel(retlab),NULL);				// goto regular return cleanup code
	}
}


// Generate a return statement.
//
void GenerateTable888Return(SYM *sym, Statement *stmt)
{
	AMODE *ap;
	int nn;
	int lab1;
	int cnt;
	int sz;

	// Generate code to evaluate the return expression.
    if( stmt != NULL && stmt->exp != NULL )
	{
		initstack();
		sz = GetNaturalSize(stmt->exp);
		ap = GenerateExpression(stmt->exp,F_ALL & ~F_BREG,sz);
		// Force return value into register 1
		if( ap->preg != 1 ) {
			if (ap->mode == am_immed)
				GenerateDiadic(op_ldi, 0, makereg(1),ap);
			else if (ap->mode == am_reg)
				GenerateDiadic(op_mov, 0, makereg(1),ap);
			else {
				if (stmt->exp->isUnsigned) {
					switch(sz) {
					case 1: GenerateDiadic(op_lbu,0,makereg(1),ap); break;
					case 2: GenerateDiadic(op_lcu,0,makereg(1),ap); break;
					case 4: GenerateDiadic(op_lhu,0,makereg(1),ap); break;
					case 8: GenerateDiadic(op_lw,0,makereg(1),ap); break;
					}
				}
				else {
					switch(sz) {
					case 1: GenerateDiadic(op_lb,0,makereg(1),ap); break;
					case 2: GenerateDiadic(op_lc,0,makereg(1),ap); break;
					case 4: GenerateDiadic(op_lh,0,makereg(1),ap); break;
					case 8: GenerateDiadic(op_lw,0,makereg(1),ap); break;
					}
				}
			}
		}
		ReleaseTempRegister(ap);
	}

	// Generate the return code only once. Branch to the return code for all returns.
	if( retlab == -1 )
    {
		retlab = nextlabel++;
		GenerateLabel(retlab);
		// Unlock any semaphores that may have been set
		for (nn = lastsph - 1; nn >= 0; nn--)
			GenerateDiadic(op_sb,0,makereg(0),make_string(semaphores[nn]));
		if (sym->IsNocall)	// nothing to do for nocall convention
			return;
		// Restore registers used as register variables.
		if( bsave_mask != 0 ) {
			cnt = (bitsset(bsave_mask)-1)*8;
			for (nn = 15; nn >=1 ; nn--) {
				if (bsave_mask & (1 << nn)) {
					GenerateTriadic(op_lws,0,makebreg(nn),make_indexed(cnt,SP),NULL);
					cnt -= 8;
				}
			}
			GenerateTriadic(op_addui,0,makereg(SP),makereg(SP),make_immed(popcnt(bsave_mask)*8));
		}
		if( save_mask != 0 ) {
			cnt = (bitsset(save_mask)-1)*8;
			for (nn = 31; nn >=1 ; nn--) {
				if (save_mask & (1 << nn)) {
					//GenerateDiadic(op_lw,0,makereg(nn),make_indexed(cnt,SP));
					GenerateMonadic(op_pop,0,makereg(nn));//,make_indexed(cnt,SP),NULL);
					cnt -= 8;
				}
			}
			//GenerateTriadic(op_addui,0,makereg(SP),makereg(SP),make_immed(popcnt(save_mask)*8));
		}
		// Unlink the stack
		// For a leaf routine the link register and exception link register doesn't need to be saved/restored.
		if (lc_auto || sym->NumParms > 0) {
			//GenerateMonadic(op_unlk,0,NULL);
			GenerateDiadic(op_mov,0,makereg(SP),makereg(BP));
			GenerateDiadic(op_lw,0,makereg(BP),make_indirect(SP));
		}

		if (exceptions)
			GenerateDiadic(op_lw,0,makereg(CLR),make_indexed(8,SP));
		//GenerateDiadic(op_lws,0,make_string("pregs"),make_indexed(24,SP));
		//if (isOscall) {
		//	GenerateDiadic(op_move,0,makereg(0),make_string("_TCBregsave"));
		//	gen_regrestore();
		//}
		GenerateTriadic(op_addui,0,makereg(SP),makereg(SP),make_immed(24));
		// Generate the return instruction. For the Pascal calling convention pop the parameters
		// from the stack.
		if (sym->IsInterrupt) {
			//GenerateTriadic(op_addui,0,makereg(30),makereg(30),make_immed(24));
			//GenerateDiadic(op_lm,0,make_indirect(30),make_mask(0x9FFFFFFE));
			//GenerateTriadic(op_addui,0,makereg(30),makereg(30),make_immed(popcnt(0x9FFFFFFE)*8));
			GenerateMonadic(op_rti,0,NULL);
			return;
		}
		if (sym->IsPascal) {
			GenerateMonadic(op_rts,0,make_immed(sym->NumParms * 8));
		}
		else {
			GenerateMonadic(op_rts,0,make_immed(0));
		}
    }
	// Just branch to the already generated stack cleanup code.
	else {
		GenerateMonadic(op_bra,0,make_clabel(retlab));
	}
}

// push the operand expression onto the stack.
// Complicated by the fact that Table888 allows up to four registers to be
// pushed with a single instruction. And we make use of it.
//
static void GenerateTable888PushParameter(ENODE *ep, int i, int n)
{    
	//static AMODE *ap[4];
	AMODE *ap;

	if (ep==NULL)
		return;
	ap = GenerateExpression(ep,F_REG,8);
	GenerateMonadic(op_push,0,ap);
/*	ap[i % 4] = GenerateExpression(ep,F_REG,8);
	if (n-1==i) {
		switch(i % 3) {
		case 0:	GenerateMonadic(op_push,0,ap[0]);
				ReleaseTempRegister(ap[0]);
				break;
		case 1: GenerateDiadic(op_push,0,ap[0],ap[1]);
				ReleaseTempRegister(ap[1]);
				ReleaseTempRegister(ap[0]);
				break;
		case 2: GenerateTriadic(op_push,0,ap[0],ap[1],ap[2]);
				ReleaseTempRegister(ap[2]);
				ReleaseTempRegister(ap[1]);
				ReleaseTempRegister(ap[0]);
				break;
		case 3: Generate4adic(op_push,0,ap[0],ap[1],ap[2],ap[3]);
				ReleaseTempRegister(ap[3]);
				ReleaseTempRegister(ap[2]);
				ReleaseTempRegister(ap[1]);
				ReleaseTempRegister(ap[0]);
				break;
		}
	}
	else {
		if ((i % 4)==3) {
			Generate4adic(op_push,0,ap[0],ap[1],ap[2],ap[3]);
			ReleaseTempRegister(ap[3]);
			ReleaseTempRegister(ap[2]);
			ReleaseTempRegister(ap[1]);
			ReleaseTempRegister(ap[0]);
		}
	}*/
}

// push entire parameter list onto stack
//
static int GenerateTable888PushParameterList(ENODE *plist)
{
	ENODE *st = plist;
	int i,n;
	// count the number of parameters
	for(n = 0; plist != NULL; n++ )
		plist = plist->p[1];
	plist = st;
    for(i = 0; plist != NULL; i++ )
    {
		GenerateTable888PushParameter(plist->p[0],i,n);
		plist = plist->p[1];
    }
    return i;
}

AMODE *GenerateTable888FunctionCall(ENODE *node, int flags)
{ 
	AMODE *ap, *result;
	SYM *sym;
    int             i;
	int msk;
	int sp;

	sp = TempInvalidate();
	sym = NULL;
    i = GenerateTable888PushParameterList(node->p[1]);
	// Call the function
	if( node->p[0]->nodetype == en_cnacon ) {
        GenerateMonadic(op_jsr,0,make_offset(node->p[0]));
		sym = gsearch(node->p[0]->sp);
	}
    else
    {
		ap = GenerateExpression(node->p[0],F_REG,8);
		if (node->p[0]->sp)
			sym = gsearch(node->p[0]->sp);
		ap->mode = am_ind;
		ap->offset = 0;
		GenerateMonadic(op_jsr,0,ap);
		ReleaseTempRegister(ap);
    }
	// Pop parameters off the stack
	if (i!=0) {
		if (sym) {
			if (!sym->IsPascal)
				GenerateTriadic(op_addui,0,makereg(SP),makereg(SP),make_immed(i * 8));
		}
		else
			GenerateTriadic(op_addui,0,makereg(SP),makereg(SP),make_immed(i * 8));
	}
	TempRevalidate(sp);
    result = GetTempRegister();
	if (flags & F_NOVALUE)
		;
	else {
		if( result->preg != 1 || (flags & F_REG) == 0 ) {
			if (sym) {
				if (sym->tp->btp->type==bt_void)
					;
				else
					GenerateDiadic(op_mov,0,result,makereg(1));
			}
			else
				GenerateDiadic(op_mov,0,result,makereg(1));
		}
	}
    return result;
}

