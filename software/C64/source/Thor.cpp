// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Stratford
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

extern int     breaklab;
extern int     contlab;
extern int     retlab;
extern int		throwlab;

extern int lastsph;
extern char *semaphores[20];

extern TYP              stdfunc;

int TempInvalidate();
void TempRevalidate(int);
void ReleaseTempRegister(AMODE *ap);
AMODE *GetTempRegister();

// ----------------------------------------------------------------------------
// AllocateRegisterVars will allocate registers for the expressions that have
// a high enough desirability.
// ----------------------------------------------------------------------------

int AllocateThorRegisterVars()
{
	CSE *csp;
    ENODE *exptr;
    int reg, mask, rmask;
	int brreg, brmask, brrmask;
    AMODE *ap, *ap2;
	int nn;
	int cnt;

	reg = 11;
	brreg = 1008;
    mask = 0;
	rmask = 0;
	brmask = 0;
	brrmask = 0;
    while( bsort(&olist) );         /* sort the expression list */
    csp = olist;
    while( csp != NULL ) {
        if( OptimizationDesireability(csp) < 3 )	// was < 3
            csp->reg = -1;
//        else if( csp->duses > csp->uses / 4 && reg < 18 )
		else {
			if ((csp->exp->nodetype==en_clabcon || csp->exp->nodetype==en_cnacon)) {
				if (brreg < 1010)
					csp->reg = brreg++;
				else
					csp->reg = -1;
			}
			else {
				if( reg < 18 )	// was / 4
					csp->reg = reg++;
				else
					csp->reg = -1;
			}
		}
        if( csp->reg != -1 )
		{
			if (csp->reg < 1000) {
				rmask = rmask | (1 << (31 - csp->reg));
				mask = mask | (1 << csp->reg);
			}
			else {
				brrmask = brrmask | (1 << (15 - (csp->reg-1000)));
				brmask = brmask | (1 << (csp->reg-1000));
			}
		}
        csp = csp->next;
    }
	if( mask != 0 ) {
		cnt = 0;
		GenerateTriadic(op_subui,0,makereg(SP),makereg(SP),make_immed(bitsset(rmask)*8));
		for (nn = 0; nn < 32; nn++) {
			if (rmask & (0x80000000 >> nn)) {
                GenerateDiadic(op_sw,0,makereg(nn&31),make_indexed(cnt,SP));
//				GenerateMonadic(op_push,0,makereg(nn&31));//,make_indexed(cnt,SP),NULL);
				cnt+=8;
			}
		}
	}
	if( brmask != 0 ) {
		cnt = 0;
		GenerateTriadic(op_subui,0,makereg(SP),makereg(SP),make_immed(bitsset(brrmask)*8));
		for (nn = 0; nn < 16; nn++) {
			if (brrmask & (0x8000 >> nn)) {
				GenerateTriadic(op_sws,0,makebreg(nn&15),make_indexed(cnt,SP),NULL);
				cnt+=8;
			}
		}
	}
    save_mask = mask;
	bsave_mask = brmask;
    csp = olist;
    while( csp != NULL ) {
            if( csp->reg != -1 )
                    {               /* see if preload needed */
                    exptr = csp->exp;
                    if( !IsLValue(exptr) || (exptr->p[0]->i > 0) )
                            {
                            initstack();
                            ap = GenerateExpression(exptr,F_REG|F_BREG|F_IMMED,8);
							if (csp->reg < 1000) {
								ap2 = makereg(csp->reg);
								if (ap->mode==am_immed)
									GenerateDiadic(op_ldi,0,ap2,ap);
								else
									GenerateDiadic(op_mov,0,ap2,ap);
							}
							else {
								ap2 = makebreg(csp->reg-1000);
								ap2->isPascal = ap->isPascal;
								if (ap->mode==am_immed)
									GenerateDiadic(op_ldis,0,ap2,ap);
								else
									GenerateDiadic(op_mtspr,0,ap2,ap);
							}
                            ReleaseTempRegister(ap);
                            }
                    }
            csp = csp->next;
            }
	return popcnt(mask) + popcnt(brmask);
}


void GenerateThorCmp(ENODE *node, int op, int label, int predreg)
{
	int size;
	struct amode *ap1, *ap2;
	static char buf[4][20];
	static int ndx;
	char *buf2;

	ndx++;
	ndx = ndx % 4;
	size = GetNaturalSize(node);
	ap1 = GenerateExpression(node->p[0],F_REG, size);
	ap2 = GenerateExpression(node->p[1],F_REG|F_IMMED,size);
	ReleaseTempRegister(ap2);
	ReleaseTempRegister(ap1);
	sprintf(buf[ndx], "p%d", predreg);
	buf2 = my_strdup(buf[ndx]);
	if (ap2->mode==am_immed)
  	    GenerateTriadic(op_cmpi,0,make_string(buf2),ap1,ap2);
	else
	    GenerateTriadic(op_cmp,0,make_string(buf2),ap1,ap2);
	GeneratePredicatedMonadic(predreg,PredOp(op),op_br,0,make_clabel(label));
}
