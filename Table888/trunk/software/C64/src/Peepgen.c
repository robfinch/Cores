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
#include        <stdio.h>
#include <stdlib.h>
#include <string.h>
#include        "c.h"
#include        "expr.h"
#include "Statement.h"
#include        "gen.h"
#include        "cglbdec.h"

static void AddToPeepList(struct ocode *newc);
void peep_add(struct ocode *ip);
static void PeepoptSub(struct ocode *ip);
void peep_move(struct ocode	*ip);
void peep_cmp(struct ocode *ip);
void opt3();
void put_ocode(struct ocode *p);

struct ocode    *peep_head = NULL,
                *peep_tail = NULL;

AMODE *copy_addr(AMODE *ap)
{
	AMODE *newap;
    if( ap == NULL )
        return NULL;
    newap = allocAmode();
	memcpy(newap,ap,sizeof(AMODE));
    return newap;
}

void GeneratePredicatedMonadic(int pr, int pop, int op, int len, AMODE *ap1)
{
	struct ocode *cd;
    cd = (struct ocode *)xalloc(sizeof(struct ocode));
	cd->predop = pop;
	cd->pregreg = pr;
    cd->opcode = op;
    cd->length = len;
    cd->oper1 = copy_addr(ap1);
    cd->oper2 = NULL;
	cd->oper3 = NULL;
	cd->oper4 = NULL;
	currentFn->UsesPredicate = TRUE;
    AddToPeepList(cd);
}

void GenerateMonadic(int op, int len, AMODE *ap1)
{
	struct ocode *cd;
    cd = (struct ocode *)xalloc(sizeof(struct ocode));
	cd->predop = 1;
	cd->pregreg = 15;
    cd->opcode = op;
    cd->length = len;
    cd->oper1 = copy_addr(ap1);
    cd->oper2 = NULL;
	cd->oper3 = NULL;
	cd->oper4 = NULL;
    AddToPeepList(cd);
}

void GeneratePredicatedDiadic(int pop, int pr, int op, int len, AMODE *ap1, AMODE *ap2)
{
	struct ocode *cd;
    cd = (struct ocode *)xalloc(sizeof(struct ocode));
	cd->predop = pop;
	cd->pregreg = pr;
    cd->opcode = op;
    cd->length = len;
    cd->oper1 = copy_addr(ap1);
    cd->oper2 = copy_addr(ap2);
	cd->oper3 = NULL;
	cd->oper4 = NULL;
	currentFn->UsesPredicate = TRUE;
    AddToPeepList(cd);
}

void GenerateDiadic(int op, int len, AMODE *ap1, AMODE *ap2)
{
	struct ocode *cd;
    cd = (struct ocode *)xalloc(sizeof(struct ocode));
	cd->predop = 1;
	cd->pregreg = 15;
    cd->opcode = op;
    cd->length = len;
    cd->oper1 = copy_addr(ap1);
    cd->oper2 = copy_addr(ap2);
	if (ap2) {
		if (ap2->mode == am_ind || ap2->mode==am_indx) {
			if (ap2->preg==SP || ap2->preg==BP)
				cd->opcode |= op_ss;
		}
	}
	cd->oper3 = NULL;
	cd->oper4 = NULL;
    AddToPeepList(cd);
}

void GenerateTriadic(int op, int len, AMODE *ap1, AMODE *ap2, AMODE *ap3)
{
	struct ocode    *cd;
    cd = (struct ocode *)xalloc(sizeof(struct ocode));
	cd->predop = 1;
	cd->pregreg = 15;
    cd->opcode = op;
    cd->length = len;
    cd->oper1 = copy_addr(ap1);
    cd->oper2 = copy_addr(ap2);
	cd->oper3 = copy_addr(ap3);
	cd->oper4 = NULL;
    AddToPeepList(cd);
}

void Generate4adic(int op, int len, AMODE *ap1, AMODE *ap2, AMODE *ap3, AMODE *ap4)
{
	struct ocode    *cd;
    cd = (struct ocode *)xalloc(sizeof(struct ocode));
	cd->predop = 1;
	cd->pregreg = 15;
    cd->opcode = op;
    cd->length = len;
    cd->oper1 = copy_addr(ap1);
    cd->oper2 = copy_addr(ap2);
	cd->oper3 = copy_addr(ap3);
	cd->oper4 = copy_addr(ap4);
    AddToPeepList(cd);
}

static void AddToPeepList(struct ocode *cd)
{
	if( peep_head == NULL )
    {
		peep_head = peep_tail = cd;
		cd->fwd = NULL;
		cd->back = NULL;
    }
    else
    {
		cd->fwd = NULL;
		cd->back = peep_tail;
		peep_tail->fwd = cd;
		peep_tail = cd;
    }
}

/*
 *      add a compiler generated label to the peep list.
 */
void GenerateLabel(int labno)
{      
	struct ocode *newl;
    newl = (struct ocode *)xalloc(sizeof(struct ocode));
    newl->opcode = op_label;
    newl->oper1 = (struct amode *)labno;
	newl->oper2 = (struct amode *)currentFn->name;
    AddToPeepList(newl);
}

//void gen_ilabel(char *name)
//{      
//	struct ocode    *new;
//    new = (struct ocode *)xalloc(sizeof(struct ocode));
//    new->opcode = op_ilabel;
//    new->oper1 = (struct amode *)name;
//    add_peep(new);
//}

/*
 *      output all code and labels in the peep list.
 */
void flush_peep()
{
	if (optimize)
		opt3();         /* do the peephole optimizations */
    while( peep_head != NULL )
    {
		if( peep_head->opcode == op_label )
			put_label((int64_t)peep_head->oper1,"",GetNamespace(),'C');
		else
			put_ocode(peep_head);
		peep_head = peep_head->fwd;
    }
}

/*
 *      output the instruction passed.
 */
void put_ocode(struct ocode *p)
{
	put_code(p);
//	put_code(p->opcode,p->length,p->oper1,p->oper2,p->oper3,p->oper4);
}

/*
 *      peephole optimization for move instructions.
 *      makes quick immediates when possible.
 *      changes move #0,d to clr d.
 *      changes long moves to address registers to short when
 *              possible.
 *      changes move immediate to stack to pea.
 *      mov r3,r3 removed
 */
void peep_move(struct ocode	*ip)
{
	if (equal_address(ip->oper1, ip->oper2)) {
		if (ip->fwd)
			ip->fwd->back = ip->back;
		if (ip->back)
			ip->back->fwd = ip->fwd;
	}
	return;
}

/*
 *      compare two address nodes and return true if they are
 *      equivalent.
 */
int equal_address(AMODE *ap1, AMODE *ap2)
{
	if( ap1 == NULL || ap2 == NULL )
		return FALSE;
    if( ap1->mode != ap2->mode )
        return FALSE;
    switch( ap1->mode )
    {
        case am_reg:
            return ap1->preg == ap2->preg;
    }
    return FALSE;
}

/*
 *      peephole optimization for add instructions.
 *      makes quick immediates out of small constants.
 */
void peep_add(struct ocode *ip)
{
     AMODE *a;
     
     // IF add to SP is followed by a move to SP, eliminate the add
     if (ip==NULL)
         return;
     if (ip->fwd==NULL)
         return;
        if (ip->oper1) {
            a = ip->oper1;
            if (a->mode==am_reg) {
                if (a->preg==regSP) {
                    if (ip->fwd->opcode==op_mov) {
                        if (ip->fwd->oper1->mode==am_reg) {
                            if (ip->fwd->oper1->preg == regSP) {
                                if (ip->back==NULL)
                                    return;
                                ip->back->fwd = ip->fwd;
                                ip->fwd->back = ip->back;
                            }
                        }
                    }
                }
            }
     }
	return;
}

// 'subui' followed by a 'bne' gets turned into 'loop'
//
static void PeepoptSub(struct ocode *ip)
{  
	if (ip->opcode==op_subui) {
		if (ip->oper3) {
			if (ip->oper3->mode==am_immed) {
				if (ip->oper3->offset->nodetype==en_icon && ip->oper3->offset->i==1) {
					if (ip->fwd) {
						if (ip->fwd->opcode==op_ne && ip->fwd->oper2->mode==am_reg && ip->fwd->oper2->preg==0) {
							if (ip->fwd->oper1->preg==ip->oper1->preg) {
								ip->opcode = op_loop;
								ip->oper2 = ip->fwd->oper3;
								ip->oper3 = NULL;
								if (ip->fwd->back) ip->fwd->back = ip;
								ip->fwd = ip->fwd->fwd;
								return;
							}
						}
					}
				}
			}
		}
	}
	return;
}

/*
 *      peephole optimization for compare instructions.
 */
void peep_cmp(struct ocode *ip)
{
	return;
}

/*
 *      changes multiplies and divides by convienient values
 *      to shift operations. op should be either op_asl or
 *      op_asr (for divide).
 */
void PeepoptMuldiv(struct ocode *ip, int op)
{  
	int     shcnt;

    if( ip->oper1->mode != am_immed )
         return;
    if( ip->oper1->offset->nodetype != en_icon )
         return;

        shcnt = ip->oper1->offset->i;
		// remove multiply / divide by 1
		// This shouldn't get through Optimize, but does sometimes.
		if (shcnt==1) {
			if (ip->back)
				ip->back->fwd = ip->fwd;
			if (ip->fwd)
				ip->fwd->back = ip->back;
			return;
		}
/*      vax c doesn't do this type of switch well       */
        if( shcnt == 2) shcnt = 1;
        else if( shcnt == 4) shcnt = 2;
        else if( shcnt == 8) shcnt = 3;
        else if( shcnt == 16) shcnt = 4;
        else if( shcnt == 32) shcnt = 5;
        else if( shcnt == 64) shcnt = 6;
        else if( shcnt == 128) shcnt = 7;
        else if( shcnt == 256) shcnt = 8;
        else if( shcnt == 512) shcnt = 9;
        else if( shcnt == 1024) shcnt = 10;
        else if( shcnt == 2048) shcnt = 11;
        else if( shcnt == 4096) shcnt = 12;
        else if( shcnt == 8192) shcnt = 13;
        else if( shcnt == 16384) shcnt = 14;
		else if( shcnt == 32768) shcnt = 15;
		else if( shcnt == 65536) shcnt = 16;
        else return;
        ip->oper1->offset->i = shcnt;
        ip->opcode = op;
        ip->length = 4;
}

// Optimize unconditional control flow transfers
// Instructions that follow an unconditional transfer won't be executed
// unless there is a label to branch to them.
//
void PeepoptUctran(struct ocode    *ip)
{
	if (uctran_off) return;
	while( ip->fwd != NULL && ip->fwd->opcode != op_label)
    {
		ip->fwd = ip->fwd->fwd;
		if( ip->fwd != NULL )
			ip->fwd->back = ip;
    }
}

void PeepoptJAL(struct ocode *ip)
{
	if (ip->oper1->preg!=0 || ip->oper2->preg!=250)
		return;
	PeepoptUctran(ip);
}

// Search ahead up to four instructions and turn them into
// predicated instructions if possible, eliminating the branch.
// If there are more than four instructions then the sequence 
// is too long, leave it alone.
//
void PeepoptBranch(struct ocode *ip)
{
	struct ocode *fwd1,*fwd2,*fwd3,*fwd4;

	if (isTable888||isRaptor64)
		return;

	fwd1 = ip->fwd;
	if (fwd1)
		fwd2 = fwd1->fwd;
	if (fwd2)
		fwd3 = fwd2->fwd;
	if (fwd3)
		fwd4 = fwd3->fwd;

	if (fwd1) {
		if (fwd1->opcode == op_label && ip->oper1) {
			if (fwd1->opcode==op_label && (int64_t)fwd1->oper1==ip->oper1->offset->i) {
				fwd1->predop = InvPredOp(ip->predop);
				fwd1->pregreg = ip->pregreg;
				fwd1->back = ip->back;
				if (ip->back)
					ip->back->fwd = fwd1;
				return;
			}
			else if (fwd1->opcode==op_label)
				return;
		}
		if (fwd1->predop != 1)
			return;
	}
	if (fwd2) {
		if (fwd2->opcode==op_label && ip->oper1) {
			if (fwd2->opcode==op_label && (int64_t)fwd2->oper1==ip->oper1->offset->i) {
				fwd1->predop = InvPredOp(ip->predop);
				fwd1->pregreg = ip->pregreg;
				fwd2->predop = InvPredOp(ip->predop);
				fwd2->pregreg = ip->pregreg;
				fwd1->back = ip->back;
				if (ip->back)
					ip->back->fwd = fwd1;
				return;
			}
			else if (fwd2->opcode==op_label)
				return;
		}
		if (fwd2->predop != 1)
			return;
	}
	if (fwd3) {
		if (fwd3->opcode==op_label && ip->oper1) {
			if ((int64_t)fwd3->oper1==ip->oper1->offset->i) {
				fwd1->predop = InvPredOp(ip->predop);
				fwd1->pregreg = ip->pregreg;
				fwd2->predop = InvPredOp(ip->predop);
				fwd2->pregreg = ip->pregreg;
				fwd3->predop = InvPredOp(ip->predop);
				fwd3->pregreg = ip->pregreg;
				fwd1->back = ip->back;
				if (ip->back)
					ip->back->fwd = fwd1;
				return;
			}
			else if (fwd3->opcode==op_label)
				return;
		}
		if (fwd3->predop != 1)
			return;
	}
	if (fwd4) {
		if (fwd4->opcode==op_label && ip->oper1) {
			if (fwd4->opcode==op_label && (int64_t)fwd4->oper1==ip->oper1->offset->i) {
				fwd1->predop = InvPredOp(ip->predop);
				fwd1->pregreg = ip->pregreg;
				fwd2->predop = InvPredOp(ip->predop);
				fwd2->pregreg = ip->pregreg;
				fwd3->predop = InvPredOp(ip->predop);
				fwd3->pregreg = ip->pregreg;
				fwd4->predop = InvPredOp(ip->predop);
				fwd4->pregreg = ip->pregreg;
				fwd1->back = ip->back;
				if (ip->back)
					ip->back->fwd = fwd1;
				return;
			}
			else if (fwd4->opcode==op_label)
				return;
		}
		if (fwd4->predop != 1)
			return;
	}
	return;
}

void PeepoptLc(struct ocode *ip)
{
	if (ip->fwd) {
		if (ip->fwd->opcode==op_sext16 || ip->fwd->opcode==op_sxc) {
			if (ip->fwd->oper1->preg == ip->oper1->preg) {
				if (ip->fwd->fwd) {
					ip->fwd->fwd->back = ip;
				}
				ip->fwd = ip->fwd->fwd;
			}
		}
	}
}

// LEA followed by a push of the same register gets translated to PEA.
// If LEA is followed by the push of more than one register, then leave it
// alone. The register order of the push matters.

void PeepoptLea(struct ocode *ip)
{
	struct ocode *ip2;
	int whop;

    whop = 0;
	ip2 = ip->fwd;
	if (!ip2)
	   return;
    if (ip2->opcode != op_push)
       return;
    whop =  ((ip2->oper1 != NULL) ? 1 : 0) +
            ((ip2->oper2 != NULL) ? 1 : 0) +
            ((ip2->oper3 != NULL) ? 1 : 0) +
            ((ip2->oper4 != NULL) ? 1 : 0);
    if (whop > 1)
        return;
         
    ip->opcode = op_pea;
    ip->oper1 = copy_addr(ip->oper2);
    ip->oper2 = NULL;
    ip->fwd = ip2->fwd;
}

// Combine a chain of push operations into a single push

void PeepoptPushPop(struct ocode *ip)
{
	struct ocode *ip2,*ip3,*ip4;

	if (ip->oper1->mode == am_immed)
		return;
	ip2 = ip->fwd;
	if (!ip2)
		return;
	if (ip2->opcode!=ip->opcode)
		return;
	if (ip2->oper1->mode==am_immed)
		return;
	ip->oper2 = copy_addr(ip2->oper1);
	ip->fwd = ip2->fwd;
	ip3 = ip2->fwd;
	if (!ip3)
		return;
	if (ip3->opcode!=ip->opcode)
		return;
	if (ip3->oper1->mode==am_immed)
		return;
	ip->oper3 = copy_addr(ip3->oper1);
	ip->fwd = ip3->fwd;
	ip4 = ip3->fwd;
	if (!ip4)
		return;
	if (ip4->opcode!=ip->opcode)
		return;
	if (ip4->oper1->mode==am_immed)
		return;
	ip->oper4 = copy_addr(ip4->oper1);
	ip->fwd = ip4->fwd;
}


// Strip out useless masking operations generated by type conversions.

void peep_ldi(struct ocode *ip)
{
	if (!ip->fwd)
		return;
	if (ip->fwd->opcode!=op_and)
		return;
	if (ip->fwd->oper1->preg != ip->oper1->preg)
		return;
	if (ip->fwd->oper2->preg != ip->oper1->preg)
		return;
	if (ip->fwd->oper3->mode != am_immed)
		return;
	ip->oper2->offset->i = ip->oper2->offset->i & ip->fwd->oper3->offset->i;
	if (ip->fwd->fwd)
		ip->fwd->fwd->back = ip;
	ip->fwd = ip->fwd->fwd;
}

/*
 *      peephole optimizer. This routine calls the instruction
 *      specific optimization routines above for each instruction
 *      in the peep list.
 */
void opt3()
{  
	struct ocode    *ip;
	int rep;
	
	for (rep = 0; rep < 2; rep++)
	{
    ip = peep_head;
    while( ip != NULL )
    {
        switch( ip->opcode )
        {
		case op_ldi:
			peep_ldi(ip);
			break;
            case op_mov:
                    peep_move(ip);
                    break;
            case op_add:
            case op_addu:
            case op_addui:
                    peep_add(ip);
                    break;
            case op_sub:
                    PeepoptSub(ip);
                    break;
            case op_cmp:
                    peep_cmp(ip);
                    break;
            case op_mul:
//                    PeepoptMuldiv(ip,op_shl);
                    break;
			case op_lc:
					PeepoptLc(ip);
					break;
            case op_bra:
					if (ip->predop==1 || isTable888)
	                    PeepoptUctran(ip);
					else
						PeepoptBranch(ip);
					break;
			case op_pop:
			case op_push:
					PeepoptPushPop(ip);
					break;
            case op_lea:
                    PeepoptLea(ip);
                    break;
			case op_jal:
					PeepoptJAL(ip);
					break;
            case op_jmp:
            case op_rts:
			case op_rti:
			case op_rtd:
					if (ip->predop==1 || isTable888)
						PeepoptUctran(ip);
					break;
            }
	       ip = ip->fwd;
        }
     }
}
