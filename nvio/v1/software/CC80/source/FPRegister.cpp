// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
#include "stdafx.h"
/*
int tmpregs[] = {3,4,5,6,7,8,9,10};
int regstack[8];
int rsp=7;
int regmask=0;

int tmpbregs[] = {3,4,5,6,7,8};
int bregstack[6];
int brsp=5;
int bregmask = 0;
*/
static short int next_fpreg;
#define MAX_REG 4			/* max. scratch data	register (D2) */
#define	MAX_REG_STACK	30

// Only registers 5,6,7 and 8 are used for temporaries
static short int fpreg_in_use[256];	// 0 to 15
static short int save_fpreg_in_use[256];

static struct {
    enum e_am mode;
    short int reg;
	union {
		char isPushed;	/* flags if pushed or corresponding reg_alloc * number */
		char allocnum;
	} f;
} 
	fpreg_stack[MAX_REG_STACK + 1],
	fpreg_alloc[MAX_REG_STACK + 1],
	save_fpreg_alloc[MAX_REG_STACK + 1],
	stacked_fpregs[MAX_REG_STACK + 1];

static short int fpreg_stack_ptr;
static short int fpreg_alloc_ptr;
static short int save_fpreg_alloc_ptr;

char tmpfpregs[] = {3,4,5,6,7,8,9,10};
char regfpstack[18];
int fprsp=17;
int fpregmask=0;

void initFPRegStack()
{
	int i;

    next_fpreg = 3;
	//for (rsp=0; rsp < 3; rsp=rsp+1)
	//	regstack[rsp] = tmpregs[rsp];
	//rsp = 0;
	for (i = 0; i <= 255; i++) {
		fpreg_in_use[i] = -1;
	}
    fpreg_stack_ptr = 0;
    fpreg_alloc_ptr = 0;
//    act_scratch = 0;
    memset(fpreg_stack,0,sizeof(fpreg_stack));
    memset(fpreg_alloc,0,sizeof(fpreg_alloc));
    memset(stacked_fpregs,0,sizeof(stacked_fpregs));
    memset(save_fpreg_alloc,0,sizeof(save_fpreg_alloc));
}

void GenerateTempFPRegPush(int reg, int rmode, int number)
{
	AMODE *ap1;
    ap1 = allocAmode();
    ap1->preg = reg;
    ap1->mode = rmode;
    ap1->isFloat = TRUE;

	GenerateMonadic(op_push,'t',ap1);
	TRACE(printf("pushing r%d\r\n", reg);)
    fpreg_stack[fpreg_stack_ptr].mode = (enum e_am)rmode;
    fpreg_stack[fpreg_stack_ptr].reg = reg;
    fpreg_stack[fpreg_stack_ptr].f.allocnum = number;
    if (fpreg_alloc[number].f.isPushed=='T')
		fatal("GenerateTempRegPush(): register already pushed");
    fpreg_alloc[number].f.isPushed = 'T';
	if (++fpreg_stack_ptr > MAX_REG_STACK)
		fatal("GenerateTempRegPush(): register stack overflow");
}

void GenerateTempFPRegPop(int reg, int rmode, int number)
{
	AMODE *ap1;
 
    if (fpreg_stack_ptr-- == -1)
		fatal("GenerateTempRegPop(): register stack underflow");
    /* check if the desired register really is on stack */
    if (fpreg_stack[fpreg_stack_ptr].f.allocnum != number)
		fatal("GenerateTempRegPop()/2");
	if (fpreg_in_use[reg] >= 0)
		fatal("GenerateTempRegPop():register still in use");
	TRACE(printf("popped r%d\r\n", reg);)
	fpreg_in_use[reg] = number;
	ap1 = allocAmode();
	ap1->preg = reg;
	ap1->mode = rmode;
	ap1->isFloat = TRUE;
	GenerateMonadic(op_pop,'t',ap1);
    fpreg_alloc[number].f.isPushed = 'F';
}

void initfpstack()
{
	initFPRegStack();
}

AMODE *GetTempFPRegister()
{
	AMODE *ap;
    
	if (fpreg_in_use[next_fpreg] >= 0)
		GenerateTempFPRegPush(next_fpreg, am_fpreg, fpreg_in_use[next_fpreg]);
	TRACE(printf("GetTempRegister:r%d\r\n", next_fpreg);)
    fpreg_in_use[next_fpreg] = fpreg_alloc_ptr;
    ap = allocAmode();
    ap->mode = am_fpreg;
    ap->preg = next_fpreg;
    ap->deep = fpreg_alloc_ptr;
    ap->isFloat = TRUE;
    fpreg_alloc[fpreg_alloc_ptr].reg = next_fpreg;
    fpreg_alloc[fpreg_alloc_ptr].mode = am_fpreg;
    fpreg_alloc[fpreg_alloc_ptr].f.isPushed = 'F';
    if (next_fpreg++ >= 10)
  		next_fpreg = 3;		/* wrap around */
    if (fpreg_alloc_ptr++ == MAX_REG_STACK)
		fatal("GetTempRegister(): register stack overflow");
	return ap;
}

/*
 * this routines checks if all allocated registers were freed
 */
void checkfpstack()
{
    int i;
    for (i=3; i<= 10; i++)
        if (fpreg_in_use[i] != -1)
            fatal("checkstack()/1");
	if (next_fpreg != 3) {
		//printf("Nextreg: %d\r\n", next_reg);
        fatal("checkstack()/3");
	}
    if (fpreg_stack_ptr != 0)
        fatal("checkstack()/5");
    if (fpreg_alloc_ptr != 0)
        fatal("checkstack()/6");
}

/*
 * validate will make sure that if a register within an address mode has been
 * pushed onto the stack that it is popped back at this time.
 */
void validateFP(AMODE *ap)
{
    switch (ap->mode) {
	case am_fpreg:
		if ((ap->preg >= 3 && ap->preg <= 10) && fpreg_alloc[ap->deep].f.isPushed == 'T' ) {
			GenerateTempFPRegPop(ap->preg, am_fpreg, (int) ap->deep);
		}
		break;
    }
}


/*
 * release any temporary registers used in an addressing mode.
 */
void ReleaseTempFPRegister(AMODE *ap)
{
    int number;

	TRACE(printf("ReleaseTempFPRegister:r%d r%d\r\n", ap->preg, ap->sreg);)

	if (ap==NULL) {
		printf("DIAG - NULL pointer in ReleaseTempRegister\r\n");
		return;
	}

//	validate(ap);
    switch (ap->mode) {
	case am_fpreg:
		if (ap->preg >= 3 && ap->preg <= 10) {
			if (fpreg_in_use[ap->preg]==-1)
				return;
			if (next_fpreg-- <= 3)
				next_fpreg = 10;
			number = fpreg_in_use[ap->preg];
			fpreg_in_use[ap->preg] = -1;
			break;
		}
		return;
    default:
		return;
    }
 //   /* some consistency checks */
	//if (number != ap->deep) {
	//	printf("number %d ap->deep %d\r\n", number, ap->deep);
	//	//fatal("ReleaseTempRegister()/1");
	//}
	if (fpreg_alloc_ptr-- == 0)
		fatal("ReleaseTempRegister(): no registers are allocated");
  //  if (reg_alloc_ptr != number)
		//fatal("ReleaseTempRegister()/3");
    if (fpreg_alloc[number].f.isPushed=='T')
		fatal("ReleaseTempRegister(): register on stack");
}

// The following is used to save temporary registers across function calls.
// Save the list of allocated registers and registers in use.
// Go through the allocated register list and generate a push instruction to
// put the register on the stack if it isn't already on the stack.

int TempFPInvalidate()
{
    int i;
	int sp;

	sp = 0;
	TRACE(printf("TempFPInvalidate()\r\n");)
	save_fpreg_alloc_ptr = fpreg_alloc_ptr;
	memcpy(save_fpreg_alloc, fpreg_alloc, sizeof(save_fpreg_alloc));
	memcpy(save_fpreg_in_use, fpreg_in_use, sizeof(save_fpreg_in_use));
	for (i = 0; i < fpreg_alloc_ptr; i++) {
        if (fpreg_in_use[fpreg_alloc[i].reg] != -1) {
    		if (fpreg_alloc[i].f.isPushed == 'F') {
    			GenerateTempFPRegPush(fpreg_alloc[i].reg, fpreg_alloc[i].mode, i);
    			stacked_fpregs[sp].reg = fpreg_alloc[i].reg;
    			stacked_fpregs[sp].mode = fpreg_alloc[i].mode;
    			stacked_fpregs[sp].f.allocnum = i;
    			sp++;
    			// mark the register void
    			fpreg_in_use[fpreg_alloc[i].reg] = -1;
    		}
        }
	}
	return sp;
}

// Pop back any temporary registers that were pushed before the function call.
// Restore the allocated and in use register lists.

void TempFPRevalidate(int sp)
{
	int nn;

	for (nn = sp-1; nn >= 0; nn--)
		GenerateTempFPRegPop(stacked_fpregs[nn].reg, stacked_fpregs[nn].mode, stacked_fpregs[nn].f.allocnum);
	fpreg_alloc_ptr = save_fpreg_alloc_ptr;
	memcpy(fpreg_alloc, save_fpreg_alloc, sizeof(fpreg_alloc));
	memcpy(fpreg_in_use, save_fpreg_in_use, sizeof(fpreg_in_use));
}
