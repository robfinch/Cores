// ============================================================================
// (C) 2012,2013 Robert Finch
// All Rights Reserved.
// robfinch<remove>@opencores.org
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
#include "c.h"
#include "expr.h"
#include "Statement.h"
#include "gen.h"
#include "cglbdec.h"

static short int next_reg;
#define MAX_REG 4			/* max. scratch data	register (D2) */
#define	MAX_REG_STACK	30

// Only registers 5,6,7 and 8 are used for temporaries
static short int reg_in_use[16];	// 0 to 15

static struct {
    enum e_am       mode;
    short int       reg;
    short int       isPushed;	/* flags if pushed or corresponding reg_alloc * number */
	short int       allocnum;
} reg_stack[MAX_REG_STACK + 1], reg_alloc[MAX_REG_STACK + 1];

static short int reg_stack_ptr;
static short int reg_alloc_ptr;

char tmpregs[] = {5,6,7,8};
char regstack[18];
int rsp=17;
int regmask=0;

void initRegStack()
{
	int i;

    next_reg = 5;
	//for (rsp=0; rsp < 3; rsp=rsp+1)
	//	regstack[rsp] = tmpregs[rsp];
	//rsp = 0;
    for (i = 0; i <= 15; i++)
		reg_in_use[i] = -1;
    reg_stack_ptr = 0;
    reg_alloc_ptr = 0;
//    act_scratch = 0;
}

void GenerateTempRegPush(int reg, int rmode, int number, int opt)
{
	AMODE *ap1;
    ap1 = allocAmode();
    ap1->preg = reg;
    ap1->mode = rmode;

	GenerateMonadic(op_push,0,ap1);
    reg_stack[reg_stack_ptr].mode = rmode;
    reg_stack[reg_stack_ptr].reg = reg;
    reg_stack[reg_stack_ptr].allocnum = number;
    if (reg_alloc[number].isPushed)
		fatal("GenerateTempRegPush(): register already pushed");
    reg_alloc[number].isPushed = opt;
	if (++reg_stack_ptr > MAX_REG_STACK)
		fatal("GenerateTempRegPush(): register stack overflow");
}

void GenerateTempRegPop(int reg, int rmode, int number)
{
	AMODE *ap1;
 
    if (reg_stack_ptr-- == -1)
		fatal("GenerateTempRegPop(): register stack underflow");
    /* check if the desired register really is on stack */
  //  if (reg_stack[reg_stack_ptr].allocnum != number)
		//fatal("GenerateTempRegPop()/2");
	if (reg_in_use[reg_stack[reg_stack_ptr].reg] >= 0)
		fatal("GenerateTempRegPop():register still in use");
	//reg_in_use[reg] = number;
	reg_in_use[reg_stack[reg_stack_ptr].reg] = reg_stack[reg_stack_ptr].allocnum;
	ap1 = allocAmode();
    //ap1->preg = reg;
    //ap1->mode = rmode;
	ap1->preg = reg_stack[reg_stack_ptr].reg;
	ap1->mode = reg_stack[reg_stack_ptr].mode;
	GenerateMonadic(op_pop,0,ap1);
    reg_alloc[reg_stack[reg_stack_ptr].allocnum].isPushed = 0;
}

void initstack()
{
	initRegStack();
}

AMODE *GetTempRegister()
{
	AMODE *ap;

	if (reg_in_use[next_reg] >= 0)
		GenerateTempRegPush(next_reg, am_reg, reg_in_use[next_reg], 1);
    reg_in_use[next_reg] = reg_alloc_ptr;
    ap = allocAmode();
    ap->mode = am_reg;
    ap->preg = next_reg;
    ap->deep = reg_alloc_ptr;
    reg_alloc[reg_alloc_ptr].reg = next_reg;
    reg_alloc[reg_alloc_ptr].mode = am_reg;
    reg_alloc[reg_alloc_ptr].isPushed = 0;
	reg_alloc[reg_alloc_ptr].allocnum = reg_alloc_ptr;
    if (next_reg++ >= 8)
		next_reg = 5;		/* wrap around */
    if (reg_alloc_ptr++ == MAX_REG_STACK)
		fatal("GetTempRegister(): register stack overflow");
	return ap;
}

int PopFromRstk()
{
	int reg = 0;

	if (rsp < 8) {
		reg = regstack[rsp];
		rsp = rsp + 1;
		regmask |= (1 << (reg));
	}
	else
		error(ERR_EXPRTOOCOMPLEX);
	return reg;
}

void PushOnRstk(int reg)
{
	if (rsp > 0) {
		rsp = rsp - 1;
		regstack[rsp] = reg;
		regmask &= ~(1 << (reg));
	}
	else
		printf("DIAG - register stack underflow.\r\n");
}

//int SaveTempRegs()
//{
//	if (popcnt(regmask)==1) {
//		GenerateTriadic(op_subui,0,makereg(30),makereg(30),make_immed(8));
//		GenerateTriadic(op_sw,0,make_mask(regmask),make_indirect(30),NULL);
//	}
//	else if (regmask != 0) {
//		GenerateTriadic(op_subui,0,makereg(30),makereg(30),make_immed(popcnt(regmask)*8));
//		GenerateTriadic(op_sm,0,make_indirect(30),make_mask(regmask),NULL);
//	}
//	return regmask;
//}
//

int SaveTempRegs()
{
    int i;
	int nn;
	int rm;

	nn = 0; rm = 0;
	//for (i = 5; i <= 8; i++)
	//	if (reg_in_use[i] >= 0)
	//		nn = nn + 1;
	//if (nn > 0) {
	//	nn = 0; 
	//	for (i = 5; i <= 8; i++)
	//		if (reg_in_use[i] >= 0) {
	//			rm = rm | (1 << i);
	//			GenerateMonadic(op_push,0,makereg(i));
	//			reg_stack[reg_stack_ptr].mode = rmode;
	//			reg_stack[reg_stack_ptr].reg = reg;
	//			reg_stack[reg_stack_ptr].allocnum = number;
	//			if (reg_alloc[number].isPushed)
	//				fatal("GenerateTempRegPush()/1");
	//			reg_alloc[number].flag = 1;
	//			/* check on stack overflow */
	//			if (++reg_stack_ptr > MAX_REG_STACK)
	//				fatal("GenerateTempRegPush()/2");
	//			printf("Pushed temp reg.\r\n");
	//			reg_in_use[i] = -1;
	//			nn = nn + 1;
	//		}
	//	printf("Saved temporaries %x\r\n", rm);
	//}
	nn = 0;
    for (i = 0; i < reg_alloc_ptr; i++)
		if (reg_alloc[i].isPushed == 0) {
			nn++;
		}
	if (nn > 0) {
		//GenerateTriadic(op_sub,0,makereg(REG_DSP),makereg(REG_DSP),make_immed(nn));
		for (i = 0; i < reg_alloc_ptr; i++)
			if (reg_alloc[i].isPushed == 0) {
				rm = rm | (1 << reg_alloc[i].reg);
				GenerateTempRegPush(reg_alloc[i].reg, reg_alloc[i].mode, i, 2);
				/* mark the register void */
				reg_in_use[reg_alloc[i].reg] = -1;
			}
		//printf("Saved temporaries %x\r\n", rm);
	}
	return nn;
}

void RestoreTempRegs(int rgmask)
{
	int nn;
	int rm;
	int i;

	nn = 0;
 
	for(nn = rgmask; nn > 0; nn--)
		GenerateTempRegPop(0,0,0);
	//if (rgmask != 0) {
	//	for (nn = 1, rm = rgmask; nn <= 15; nn = nn + 1)
	//		if ((rm>>nn) & 1) {
	//			GenerateMonadic(op_pop,0,makereg(nn));
	//			reg_in_use[nn] = 0;
	//		}
	//}
}

/*
 * this routines checks if all allocated registers were freed
 */
void checkstack()
{
    int i;
    for (i=5; i<= 8; i++)
        if (reg_in_use[i] != -1)
            fatal("checkstack()/1");
	if (next_reg != 5) {
		printf("Nextreg: %d\r\n", next_reg);
        fatal("checkstack()/3");
	}
    if (reg_stack_ptr != 0)
        fatal("checkstack()/5");
    if (reg_alloc_ptr != 0)
        fatal("checkstack()/6");
}

/*
 * validate will make sure that if a register within an address mode has been
 * pushed onto the stack that it is popped back at this time.
 */
void validate(AMODE *ap)
{
    switch (ap->mode) {
	case am_reg:
		if ((ap->preg >= 5 && ap->preg <= 8) && reg_alloc[ap->deep].isPushed !=0 ) {
			GenerateTempRegPop(ap->preg, am_reg, (int) ap->deep);
		}
		break;
    case am_indx2:
		if ((ap->sreg >= 5 && ap->sreg <= 8) && reg_alloc[ap->deep].isPushed !=0) {
			GenerateTempRegPop(ap->sreg, am_reg, (int) ap->deep);
		}
		goto common;
    case am_indx3:
		if ((ap->sreg >= 5 && ap->sreg <= 8) && reg_alloc[ap->deep].isPushed !=0) {
			GenerateTempRegPop(ap->sreg, am_reg, (int) ap->deep);
		}
		goto common;
    case am_ind:
    case am_indx:
    case am_ainc:
    case am_adec:
common:
		if ((ap->preg >= 5 && ap->preg <= 8) && reg_alloc[ap->deep].isPushed !=0) {
			GenerateTempRegPop(ap->preg, am_reg, (int) ap->deep);
		}
		break;
    }
}


/*
 * release any temporary registers used in an addressing mode.
 */
void ReleaseTempRegister(AMODE *ap)
{
    int number;

	if (ap==NULL) {
		printf("DIAG - NULL pointer in ReleaseTempRegister\r\n");
		return;
	}

	validate(ap);
    switch (ap->mode) {
	case am_ind:
	case am_indx:
	case am_ainc:
	case am_adec:
	case am_reg:
common:
		if (ap->preg >= 5 && ap->preg <= 8) {
			if (reg_in_use[ap->preg]==-1)
				return;
			if (next_reg-- <= 5)
				next_reg = 8;
			number = reg_in_use[ap->preg];
			reg_in_use[ap->preg] = -1;
			break;
		}
		return;
    case am_indx2:
	case am_indx3:
		if (ap->sreg >= 5 && ap->sreg <= 8) {
			if (reg_in_use[ap->sreg]==-1)
				return;
			if (next_reg-- <= 5)
				next_reg = 8;
			number = reg_in_use[ap->sreg];
			reg_in_use[ap->sreg] = -1;
			break;
		}
		goto common;
    default:
		return;
    }
 //   /* some consistency checks */
	if (number != ap->deep) {
		printf("number %d ap->deep %d\r\n", number, ap->deep);
		//fatal("ReleaseTempRegister()/1");
	}
	if (reg_alloc_ptr-- == 0)
		fatal("ReleaseTempRegister(): no registers are allocated");
  //  if (reg_alloc_ptr != number)
		//fatal("ReleaseTempRegister()/3");
    if (reg_alloc[number].isPushed)
		fatal("ReleaseTempRegister(): register on stack");
}

