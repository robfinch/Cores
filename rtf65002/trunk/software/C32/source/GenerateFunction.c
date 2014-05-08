// ============================================================================
// (C) 2013 Robert Finch
// All Rights Reserved.
// robfinch<remove>@opencores.org
//
// C32 - 'C' derived language compiler
//  - 32 bit CPU
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

void GenerateReturn(SYM *sym, Statement *stmt);


// Generate a function body.
//
void GenerateFunction(SYM *sym, Statement *stmt)
{
	throwlab = retlab = contlab = breaklab = -1;
	lastsph = 0;
	memset(semaphores,0,sizeof(semaphores));
	throwlab = nextlabel++;
	if (sym->IsInterrupt) {
		//GenerateTriadic(op_subui,0,makereg(30),makereg(30),make_immed(30*8));
		//GenerateDiadic(op_sm,0,make_indirect(30), make_mask(0x9FFFFFFE));
	}
	if (!sym->IsNocall) {
		GenerateDiadic(op_subsp,0,make_string("sp"),make_immed(2));
		// For a leaf routine don't bother to store exception link register.
		if (sym->IsLeaf)
			GenerateDiadic(op_st, 0, makereg(REG_BP), make_indexed(0,REG_SP));
		else {
			GenerateDiadic(op_st, 0, makereg(REG_BP), make_indexed(0,REG_SP));
			//GenerateDiadic(op_st, 0, makereg(REG_BP), make_indexed(0,REG_DSP));
			GenerateDiadic(op_st, 0, makereg(REG_XL), make_indexed(1,REG_SP));
			GenerateDiadic(op_lea,0, makereg(REG_XL), make_label(throwlab));
		}
		GenerateDiadic(op_tsr,0,makereg(REG_SP),makereg(REG_BP));
		if (lc_auto)
			GenerateDiadic(op_subsp,0,makereg(REG_SP),make_immed(lc_auto));
	}
	if (optimize)
		opt1(stmt);
    GenerateStatement(stmt);
    GenerateReturn(sym,0);
	// Generate code for the hidden default catch
	GenerateLabel(throwlab);
	if (sym->IsLeaf){
		if (sym->DoesThrow) {
			GenerateMonadic(op_pop,0,makereg(0));							// pop off the return address
			GenerateMonadic(op_push,0,makereg(REG_XL));							// and push XL back
			GenerateDiadic(op_bra,0,make_label(retlab),NULL);				// goto regular return cleanup code
		}
	}
	else {
		GenerateMonadic(op_pop,0,makereg(0));							// pop off the return address
		GenerateDiadic(op_ld,0,makereg(REG_XL),make_indexed(1,REG_BP));		// load throw return address from stack into LR
		GenerateMonadic(op_push,0,makereg(REG_XL));							// and push it back
		GenerateDiadic(op_bra,0,make_label(retlab),NULL);				// goto regular return cleanup code
	}
}

void GenerateRegisterVariableLoad()
{
	int cnt, nn;

	if( save_mask != 0 ) {
		cnt = (bitsset(save_mask)-1)*1;
		for (nn = 15; nn >=1 ; nn--) {
			if (save_mask & (1 << nn)) {
				GenerateTriadic(op_ld,0,makereg(nn),make_indexed(cnt,REG_SP),NULL);
				cnt -= 1;
			}
		}
		GenerateDiadic(op_subsp,0,makereg(REG_SP),make_immed(-popcnt(save_mask)*1));
	}
}

// Generate a return statement.
//
void GenerateReturn(SYM *sym, Statement *stmt)
{
	AMODE *ap;
	int nn;
	int lab1;
	int cnt;

    if( stmt != NULL && stmt->exp != NULL )
	{
		initstack();
		ap = GenerateExpression(stmt->exp,F_REG|F_IMMED,1);
		// Force return value into register 1
		if( ap->preg != 1 )
			GenerateDiadic(op_ld, 0, makereg(1),ap);
		ReleaseTempRegister(ap);
	}
	// Generate the return code only once. Branch to the return code for all returns.
	if( retlab == -1 )
    {
		retlab = nextlabel++;
		GenerateLabel(retlab);
		// Unlock any semaphores that may have been set
		for (nn = lastsph - 1; nn >= 0; nn--)
			GenerateDiadic(op_st,0,makereg(0),make_string(semaphores[nn]));
		if (sym->IsNocall)	// nothing to do for nocall convention
			return;
		// Restore registers used as register variables.
		GenerateRegisterVariableLoad();

		// Unlink the stack
		// For a leaf routine the link register and exception link register doesn't need to be saved/restored.
		GenerateDiadic(op_trs,0,makereg(REG_BP),makereg(REG_SP));
		if (sym->IsLeaf)
			GenerateDiadic(op_ld,0,makereg(REG_BP),make_indexed(0,REG_SP));
		else {
			GenerateDiadic(op_ld,0,makereg(REG_BP),make_indexed(0,REG_SP));
			GenerateDiadic(op_ld,0,makereg(REG_XL),make_indexed(1,REG_SP));
		}
		//if (isOscall) {
		//	GenerateDiadic(op_move,0,makereg(0),make_string("_TCBregsave"));
		//	gen_regrestore();
		//}
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
			GenerateDiadic(op_subsp,0,makereg(REG_SP),make_immed(-(2+sym->NumParms * 1)));
			GenerateMonadic(op_rts,0,NULL);
		}
		else {
			GenerateDiadic(op_subsp,0,makereg(REG_SP),make_immed(-2));
			GenerateMonadic(op_rts,0,NULL);
		}
    }
	// Just branch to the already generated stack cleanup code.
	else {
		GenerateDiadic(op_bra,0,make_label(retlab),0);
	}
	//checkstack();
}

// push the operand expression onto the stack.
//
static void GeneratePushParameter(ENODE *ep, int i, int n)
{    
	AMODE *ap;
	ap = GenerateExpression(ep,F_REG,1);
	GenerateMonadic(op_push,0,ap);
//	GenerateDiadic(op_st,0,ap,make_indexed((n-i)*1-1,REG_SP));
	ReleaseTempRegister(ap);
}

// push entire parameter list onto stack
//
static int GeneratePushParameterList(ENODE *plist)
{
	ENODE *st = plist;
	int i,n;
	// count the number of parameters
	for(n = 0; plist != NULL; n++ )
		plist = plist->p[1];
	// move stack pointer down by number of parameters
	//if (st)
	//	GenerateDiadic(op_subsp,0,makereg(REG_SP),make_immed(n*1));
	plist = st;
    for(i = 0; plist != NULL; i++ )
    {
		GeneratePushParameter(plist->p[0],i,n);
		plist = plist->p[1];
    }
    return i;
}

AMODE *GenerateFunctionCall(ENODE *node, int flags)
{ 
	AMODE *ap, *result;
	SYM *sym;
    int             i;
	int msk;

 	msk = SaveTempRegs();
	sym = NULL;
    i = GeneratePushParameterList(node->p[1]);
	// Call the function
	if( node->p[0]->nodetype == en_nacon ) {
        GenerateDiadic(op_jsr,0,make_offset(node->p[0]),NULL);
		sym = gsearch(node->p[0]->sp);
	}
    else
    {
		ap = GenerateExpression(node->p[0],F_REG,1);
		ap->mode = am_ind;
		GenerateMonadic(op_jsr,0,ap);
		ReleaseTempRegister(ap);
    }
	// Pop parameters off the stack
	if (i!=0) {
		if (sym) {
			if (!sym->IsPascal)
				GenerateDiadic(op_subsp,0,makereg(REG_SP),make_immed(-i));
		}
		else
			GenerateDiadic(op_subsp,0,makereg(REG_SP),make_immed(-i));
	}
	RestoreTempRegs(msk);
    result = GetTempRegister();
    if( result->preg != 1 || (flags & F_REG) == 0 )
		if (sym) {
			if (sym->tp->btp->type==bt_void)
				;
			else
				GenerateDiadic(op_ld,0,result,makereg(1));
		}
		else
			GenerateDiadic(op_ld,0,result,makereg(1));
    return result;
}

