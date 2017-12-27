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

extern void CreateControlFlowGraph();
static void AddToPeepList(OCODE *newc);
bool IsFlowCtrl(OCODE *ip);
void peep_add(OCODE *ip);
static void PeepoptSub(OCODE *ip);
void peep_move(OCODE	*ip);
void peep_cmp(OCODE *ip);
static void opt_peep();
void put_ocode(OCODE *p);
void CreateVars();
void RemoveMoves();
extern Var *varlist;

OCODE *peep_head = NULL;
OCODE *peep_tail = NULL;
int preload_count = 0;

AMODE *copy_addr(AMODE *ap)
{
	AMODE *newap;

	if( ap == NULL )
		return NULL;
	newap = allocAmode();
	memcpy(newap,ap,sizeof(AMODE));
	if (ap->offset) {
		if (ap->offset->nodetype==en_icon) {
			newap->offset = ap->offset->Duplicate();
		}
	}
	return newap;
}

void GeneratePredicatedMonadic(int pr, int pop, int op, int len, AMODE *ap1)
{
	OCODE *cd;
	cd = (OCODE *)allocx(sizeof(OCODE));
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

void GenerateZeradic(int op)
{
	dfs.printf("<GenerateZeradic>\n");
	OCODE *cd;
	dfs.printf("A");
	cd = (OCODE *)allocx(sizeof(OCODE));
	dfs.printf("B");
	cd->predop = 0;
	cd->pregreg = 15;
	cd->opcode = op;
	cd->length = 0;
	cd->oper1 = NULL;
	dfs.printf("C");
	cd->oper2 = NULL;
	cd->oper3 = NULL;
	cd->oper4 = NULL;
	dfs.printf("D");
	AddToPeepList(cd);
	dfs.printf("</GenerateZeradic>\n");
}

void GenerateMonadic(int op, int len, AMODE *ap1)
{
	OCODE *cd;

	dfs.printf("<GenerateMonadic>\n");
	dfs.printf("A");
	cd = (OCODE *)allocx(sizeof(OCODE));
	dfs.printf("B");
	cd->predop = 0;
	cd->pregreg = 15;
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = copy_addr(ap1);
	dfs.printf("C");
	cd->oper2 = NULL;
	cd->oper3 = NULL;
	cd->oper4 = NULL;
	dfs.printf("D");
	AddToPeepList(cd);
	dfs.printf("</GenerateMonadic>\n");
}

void GeneratePredicatedDiadic(int pop, int pr, int op, int len, AMODE *ap1, AMODE *ap2)
{
	OCODE *cd;
	cd = (OCODE *)allocx(sizeof(OCODE));
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
	OCODE *cd;
	cd = (OCODE *)xalloc(sizeof(OCODE));
	cd->predop = 0;
	cd->pregreg = 15;
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = copy_addr(ap1);
	cd->oper2 = copy_addr(ap2);
	if (ap2) {
		if (ap2->mode == am_ind || ap2->mode==am_indx) {
			if (ap2->preg==regSP || ap2->preg==regBP)
				cd->opcode |= op_ss;
		}
	}
	cd->oper3 = NULL;
	cd->oper4 = NULL;
	AddToPeepList(cd);
}

void GenerateTriadic(int op, int len, AMODE *ap1, AMODE *ap2, AMODE *ap3)
{
	OCODE *cd;
	cd = (OCODE *)allocx(sizeof(OCODE));
	cd->predop = 0;
	cd->pregreg = 15;
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = copy_addr(ap1);
	cd->oper2 = copy_addr(ap2);
	cd->oper3 = copy_addr(ap3);
	cd->oper4 = NULL;
	AddToPeepList(cd);
}

void GeneratePredicatedTriadic(int pop, int op, int len, AMODE *ap1, AMODE *ap2, AMODE *ap3)
{
	OCODE *cd;
	cd = (OCODE *)allocx(sizeof(OCODE));
	cd->predop = pop;
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
	OCODE *cd;
	cd = (OCODE *)allocx(sizeof(OCODE));
	cd->predop = 0;
	cd->pregreg = 15;
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = copy_addr(ap1);
	cd->oper2 = copy_addr(ap2);
	cd->oper3 = copy_addr(ap3);
	cd->oper4 = copy_addr(ap4);
	AddToPeepList(cd);
}

int GeneratePreload()
{
	OCODE *cd;
	cd = (OCODE *)allocx(sizeof(OCODE));
	cd->predop = 0;
	cd->pregreg = 0;
	cd->opcode = op_preload;
	cd->length = preload_count+1;
	cd->oper1 = nullptr;
	cd->oper2 = nullptr;
	cd->oper3 = nullptr;
	cd->oper4 = nullptr;
	AddToPeepList(cd);
	return ++preload_count;
}

void OverwritePreload(int handle, int op, int len, AMODE *ap1, AMODE *ap2, AMODE *ap3, AMODE *ap4)
{
	OCODE *ip;

	for (ip = peep_tail; ip; ip=ip->back) {
		if (ip->opcode==op_preload && ip->length==handle) {
			ip->opcode = op;
			ip->length = len;
			ip->oper1 = ap1;
			ip->oper2 = ap2;
			ip->oper3 = ap3;
			ip->oper4 = ap4;
			return;
		}
	}
}


// NOP out a range in the peep buffer.
void PeepNop(OCODE *ip1, OCODE *ip2)
{
	for (; ip1 != ip2; ip1 = ip1->fwd) {
		ip1->opcode = op_nop;
	}
	ip1->opcode = op_nop;
}

static void AddToPeepList(OCODE *cd)
{
	if (!dogen)
		return;

	if( peep_head == NULL )
	{
		peep_head = peep_tail = cd;
		cd->fwd = nullptr;
		cd->back = nullptr;
	}
	else
	{
		cd->fwd = nullptr;
		cd->back = peep_tail;
		peep_tail->fwd = cd;
		peep_tail = cd;
	}
}

static void MarkAllKeep()
{
	OCODE *ip;
	
	for (ip = peep_head; ip; ip = ip->fwd)
		ip->remove = false;
}

static inline void MarkRemove(OCODE *cd)
{
	cd->remove = true;	
}

void MarkRemoveRange(OCODE *bp, OCODE *ep)
{
	for (; bp != ep && bp; bp = bp->fwd)
		MarkRemove(bp);
	if (bp)
		MarkRemove(bp);
}

static void Remove()
{
	OCODE *cd;
	OCODE *ip1, *ip2;

	for (cd = peep_head; cd; cd = ip2) {
		ip1 = cd->back;
		ip2 = cd->fwd;
		if (cd->remove) {
			if (cd->comment)
				if (cd->back && cd->back->comment==nullptr)
					cd->back->comment = cd->comment;
			if (ip2)
				ip2->back = ip1;
			if (ip1)
				ip1->fwd = ip2;
			cd->fwd = nullptr;
			cd->back = nullptr;
			if (cd==peep_head)
				peep_head = ip2;
		}
	}
}

void PeepRemove()
{
	Remove();
}

int PeepCount(OCODE *ip)
{
	int cnt;

	for (cnt = 0; ip && ip != peep_tail; cnt++)
		ip = ip->fwd;
	return (cnt);
}

/*
 *      add a compiler generated label to the peep list.
 */
void GenerateLabel(int labno)
{      
	OCODE *newl;
	newl = (OCODE *)allocx(sizeof(OCODE));
	newl->opcode = op_label;
	newl->oper1 = (AMODE *)labno;
	newl->oper2 = (AMODE *)my_strdup((char *)currentFn->name->c_str());
	newl->oper3 = nullptr;
	newl->oper4 = nullptr;
	AddToPeepList(newl);
}

//void gen_ilabel(char *name)
//{      
//	OCODE    *new;
//    new = (OCODE *)xalloc(sizeof(OCODE));
//    new->opcode = op_ilabel;
//    new->oper1 = (struct amode *)name;
//    add_peep(new);
//}

/*
 *      output all code and labels in the peep list.
 */
void flush_peep()
{
	opt_peep();         /* do the peephole optimizations */
	while( peep_head != NULL )
	{
		if( peep_head->opcode == op_label )
			put_label((int)peep_head->oper1,"",GetNamespace(),'C');
		else
			put_ocode(peep_head);
		peep_head = peep_head->fwd;
	}
}

/*
 *      output the instruction passed.
 */
void put_ocode(OCODE *p)
{
	put_code(p);
//	put_code(p->opcode,p->length,p->oper1,p->oper2,p->oper3,p->oper4);
}

//
//      mov r3,r3 removed
//
// Code Like:
//		add		r3,r2,#10
//		mov		r3,r5
// Changed to:
//		mov		r3,r5

void peep_move(OCODE	*ip)
{
	if (ip==nullptr)
		return;
	if (ip->oper1==nullptr || ip->oper2==nullptr)
		return;
	if (ip->oper3) {
		if (ip->oper3->offset) {
			if (ip->oper3->offset->i==0)
				ip->oper3 = nullptr;
		}
	}
	if (equal_address(ip->oper1, ip->oper2)) {
		if (ip->oper3) {
			if (ip->oper3->offset) {
				if (ip->oper3->offset->i != 0)
					return;
			}
		}
		MarkRemove(ip);
	}
	// mov	r1,r5
	// mov	r5,r1
	if (ip->fwd) {
		if (ip->fwd->opcode==op_mov
			&& ip->fwd->oper3==nullptr 
			&& ip->oper3==nullptr) {
			if (equal_address(ip->oper1, ip->fwd->oper2)
				&& equal_address(ip->oper2, ip->fwd->oper1))
				MarkRemove(ip->fwd);
		}
	}
	return;
	if (ip->back) {
		if (ip->back->opcode==op_add || ip->back->opcode==op_and) {	// any ALU op
			if (equal_address(ip->back->oper1, ip->oper1)) {
				ip->back->back->fwd = ip;
				ip->back = ip->back->back;
			}
		}
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
  if( ap1->mode != ap2->mode  && !((ap1->mode==am_ind && ap2->mode==am_indx) || (ap1->mode==am_indx && ap2->mode==am_ind)))
    return FALSE;
  switch( ap1->mode )
  {
  case am_immed:
	  return (ap1->offset->i == ap2->offset->i);
  case am_reg:
    return ap1->preg == ap2->preg;
  case am_ind:
  case am_indx:
	  if (ap1->preg != ap2->preg)
		  return FALSE;
	  if (ap1->offset == ap2->offset)
		  return TRUE;
	  if (ap1->offset == NULL || ap2->offset==NULL)
		  return FALSE;
	  if (ap1->offset->i != ap2->offset->i)
		  return FALSE;
	  return TRUE;
  }
  return FALSE;
}

/*
 *      peephole optimization for add instructions.
 *      makes quick immediates out of small constants.
 */
void peep_add(OCODE *ip)
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
								MarkRemove(ip);
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
static void PeepoptSub(OCODE *ip)
{  
	return;
}

static bool IsSubiSP(OCODE *ip)
{
	if (ip->opcode==op_sub) {
		if (ip->oper3 && ip->oper3->mode==am_immed) {
			if (ip->oper1->preg==regSP && ip->oper2->preg==regSP) {
				return (true);
			}
		}
	}
	return (false);
}

static void MergeSubi(OCODE *first, OCODE *last, int amt)
{
	OCODE *ip;

	if (first==nullptr)
		return;

	// First remove all the excess subtracts
	for (ip = first; ip && ip != last; ip = ip->fwd) {
		if (IsSubiSP(ip)) {
			MarkRemove(ip);
		}
	}
	// Set the amount of the last subtract to the total amount
	if (ip)	 {// there should be one
		ip->oper3->offset->i = amt;
	}
}

// 'subui'
//
static void PeepoptSubSP()
{  
	OCODE *ip;
	OCODE *first_subi = nullptr;
	OCODE *last_subi = nullptr;
	int amt = 0;

	for (ip = peep_head; ip; ip = ip->fwd) {
		if (IsSubiSP(ip)) {
			if (first_subi==nullptr)
				last_subi = first_subi = ip;
			else
				last_subi = ip;
			amt += ip->oper3->offset->i;
		}
		else if (ip->opcode==op_push || IsFlowCtrl(ip)) {
			MergeSubi(first_subi, last_subi, amt);
			first_subi = last_subi = nullptr;
			amt = 0;
		}
	}
}

/*
 *      peephole optimization for compare instructions.
 */
void peep_cmp(OCODE *ip)
{
	return;
}

/*
 *      changes multiplies and divides by convienient values
 *      to shift operations. op should be either op_asl or
 *      op_asr (for divide).
 */
void PeepoptMuldiv(OCODE *ip, int op)
{  
	int shcnt, num;

  if( ip->oper1->mode != am_immed )
    return;
  if( ip->oper1->offset->nodetype != en_icon )
    return;

  num = ip->oper1->offset->i;

  // remove multiply / divide by 1
	// This shouldn't get through Optimize, but does sometimes.
  if (num==1) {
	  MarkRemove(ip);
		return;
	}
  for (shcnt = 1; shcnt < 32; shcnt++) {
    if (num == (int)1 << shcnt) {
      num = shcnt;
      break;
    }
  }
  if (shcnt==32)
    return;
  ip->oper1->offset->i = num;
  ip->opcode = op;
  ip->length = 2;
}

// Optimize unconditional control flow transfers
// Instructions that follow an unconditional transfer won't be executed
// unless there is a label to branch to them.
//
void PeepoptUctran(OCODE *ip)
{
	if (uctran_off) return;
	for(ip = ip->fwd; ip != NULL && ip->opcode != op_label; ip = ip->fwd)
	{
		if (ip->fwd && ip->fwd->comment==nullptr) {
			ip->fwd->comment = ip->comment;
		}
		MarkRemove(ip);
	}
}

void PeepoptJAL(OCODE *ip)
{
	if (ip->oper1->preg!=0)
		return;
	PeepoptUctran(ip);
}

// Remove instructions that branch to the next label.
// Convert moves to PC to inc/dec operations where possible.
//
void PeepoptBranch(OCODE *ip)
{
	OCODE *p, *q;
	int n;

	for (p = ip->fwd; p && p->opcode==op_label; p = p->fwd)
		if (ip->oper3 && ip->oper3->offset->i == (int)p->oper1) {
			MarkRemove(ip);
			return;
		}
		if (ip->opcode==op_mov
			&& ip->oper1->mode==am_reg
			&& ip->oper1->preg==regPC
			&& ip->oper2->mode==am_reg
			&& ip->oper2->preg==regZero
			) {
			n = 0;
			for (q = ip; n < 13 && q; q = q->fwd) {
				if (q->opcode==op_label
					&& (int)q->oper1==ip->oper3->offset->i) {
					ip->opcode = op_inc;
					ip->oper2 = ip->oper3;
					ip->oper3 = nullptr;
					ip->oper2->offset->sp = new std::string("-PC");
					return;
				}
				n += q->opcode!=op_label;
				if (q->oper3)
					n++;
			}
			n= 0;
			for (q = ip; n < 13 && q; q = q->back) {
				if (q->opcode==op_label
					&& (int)q->oper1==ip->oper3->offset->i) {
					ip->opcode = op_inc;
					ip->oper2 = ip->oper3;
					ip->oper3 = nullptr;
					ip->oper2->offset->sp = new std::string("-PC");
					return;
				}
				n += q->opcode!=op_label;
				if (q->oper3)
					n++;
			}
		}
	return;
}

// Look for the following sequence and convert it into a set operation.
// Bcc lab1
// ldi  rn,#1
// bra lab2
// lab1:
// ldi  rn,#0
// lab2:
        
void PeepoptBcc(OCODE * ip)
{
}

void PeepoptLc(OCODE *ip)
{
	return;
}

// LEA followed by a push of the same register gets translated to PEA.
// If LEA is followed by the push of more than one register, then leave it
// alone. The register order of the push matters.

void PeepoptLea(OCODE *ip)
{
}

// LW followed by a push of the same register gets translated to PUSH.

void PeepoptLw(OCODE *ip)
{
}

// Combine a chain of push operations into a single push

void PeepoptPushPop(OCODE *ip)
{
}


// Strip out useless masking operations generated by type conversions.

void peep_ld(OCODE *ip)
{
	if (ip->oper2==nullptr)
		return;
	if (ip->oper2->mode != am_immed)
		return;
	if (ip->oper2->offset->i==0) {
		ip->opcode = op_mov;
		ip->oper2->mode = am_reg;
		ip->oper2->preg = 0;
		return;
	}
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


void PeepoptLd(OCODE *ip)
{
    return;
}


// Remove extra labels at end of subroutines

void PeepoptLabel(OCODE *ip)
{
    if (!ip)
        return;
    if (ip->fwd)
        return;
    ip->back->fwd = NULL;
}
 
// Eliminate branchs to the next line of code.

static void opt_nbr()
{
	//OCODE *ip,*pip;
	//
	//ip = peep_head;
	//pip = peep_head;
	//while(ip) { 
	//	if (ip->opcode==op_label) {
	//		if (pip->opcode==op_br || pip->opcode==op_bra) {
	//			if ((int64_t)ip->oper1==pip->oper1->offset->i)	{
	//				pip->back->fwd = pip->fwd;
	//				ip->back = pip->back;
	//			}
	//		}
	//	}
	//	pip = ip;
	//	ip = ip->fwd;
	//}
}

// Detect if the instruction has a target register.

static bool HasTargetReg(OCODE *ip)
{
	switch(ip->opcode) {
	case op_add:
	case op_adc:
	case op_sub:
	case op_and:
	case op_or:
	case op_xor:
	case op_ror:
	case op_ld:
	case op_mov:
		return true;
	}
	return false;
}

// Process compiler hint opcodes

static void PeepoptHint(OCODE *ip)
{
	//if (ip->back->opcode==op_label || ip->fwd->opcode==op_label)
	//	return;

	switch (ip->oper1->offset->i) {

	// hint #1
	// Takes care of redundant moves at the parameter setup point
	// Code Like:
	//    MOV r3,#constant
	//    MOV r18,r3
	// Translated to:
	//    MOV r18,#constant
	case 1:
		if (ip->back->opcode==op_label || ip->fwd->opcode==op_label)
			return;
		if (ip->fwd->opcode != op_mov) {
			return;
		}
		if (ip->back->opcode != op_mov) {
			return;
		}
		if (HasTargetReg(ip->back)) {
			if (equal_address(ip->fwd->oper2, ip->back->oper1) && ip->back->oper2->mode==am_immed) {
				ip->back->oper1 = ip->fwd->oper1;
				MarkRemove(ip->fwd);
			}
		}
		break;

	// hint #2
	// Takes care of redundant moves at the funtion return point
	// Code like:
	//     MOV R3,arg
	//     MOV R1,R3
	// Translated to:
	//     MOV r1,arg
	case 2:
		if (ip->back->opcode==op_label || ip->fwd->opcode==op_label)
			return;
		if (ip->back && ip->back->oper1 && ip->fwd && ip->fwd->oper2) {
			if (HasTargetReg(ip->back)) {
				if (equal_address(ip->fwd->oper2, ip->back->oper1)) {
					ip->back->oper1 = ip->fwd->oper1;
					MarkRemove(ip->fwd);
				}
			}
		}
		break;

	case 8:
		{
			OCODE *ip1 = ip->fwd;
			OCODE *ip2;
			if (ip1)
				ip2 = ip1->fwd;
			if (ip1==nullptr || ip2==nullptr)
				return;
			if (equal_address(ip2->oper2, ip1->oper1)) {
				ip1->oper1 = ip2->oper1;
				MarkRemove(ip2);
			}
		}
		break;
	}
}

// A store followed by a load of the same address removes
// the load operation. However volatile loads are not
// removed.
// Eg.
// SH   r3,Address
// LH	r3,Address
// Turns into
// SH   r3,Address

static void PeepoptStore(OCODE *ip)
{
	if (ip->opcode==op_label || ip->fwd->opcode==op_label)
		return;
	if (!equal_address(ip->oper1, ip->fwd->oper1))
		return;
	if (!equal_address(ip->oper2, ip->fwd->oper2))
		return;
	if (ip->opcode==op_sto && ip->fwd->opcode!=op_ld)
		return;
	if (!ip->isVolatile)
		MarkRemove(ip->fwd);
}

// This optimization eliminates an 'AND' instruction when the value
// in the register is a constant less than one of the two special
// constants 255 or 65535. This is typically a result of a zero
// extend operation.
//
// So code like:
//		ld		r3,#4
//		and		r3,r3,#255
// Eliminates the useless 'and' operation.

static void PeepoptAnd(OCODE *ip)
{
	// This doesn't work properly yet in all cases.
	return;
	if (ip->oper2==nullptr || ip->oper3==nullptr)
		throw new C64PException(ERR_NULLPOINTER,0x50);
	if (ip->oper2->offset == nullptr || ip->oper3->offset==nullptr)
		return;
	if (ip->oper2->offset->constflag==false)
		return;
	if (ip->oper3->offset->constflag==false)
		return;
	if (
		ip->oper3->offset->i != 1 &&
		ip->oper3->offset->i != 3 &&
		ip->oper3->offset->i != 7 &&
		ip->oper3->offset->i != 15 &&
		ip->oper3->offset->i != 31 &&
		ip->oper3->offset->i != 63 &&
		ip->oper3->offset->i != 127 &&
		ip->oper3->offset->i != 255 &&
		ip->oper3->offset->i != 511 &&
		ip->oper3->offset->i != 1023 &&
		ip->oper3->offset->i != 2047 &&
		ip->oper3->offset->i != 4095 &&
		ip->oper3->offset->i != 8191 &&
		ip->oper3->offset->i != 16383 &&
		ip->oper3->offset->i != 32767 &&
		ip->oper3->offset->i != 65535)
		// Could do this up to 32 bits
		return;
	if (ip->oper2->offset->i < ip->oper3->offset->i) {
		ip->back->fwd = ip->fwd;
		ip->fwd->back = ip->back;
	}
}

int IsRet(OCODE *ip)
{
	if (ip==nullptr)
		return 0;
	if (ip->oper1==nullptr || ip->oper2==nullptr)
		return 0;
	if (ip->opcode==op_mov &&
		ip->oper1->mode==am_reg && ip->oper1->preg==15 &&
		ip->oper2->mode==am_reg && ip->oper2->preg==13 &&
		(ip->oper3==nullptr || ip->oper3->offset->i==0))
	return 1;
	return 0;
}

bool IsFlowCtrl(OCODE *ip)
{
	if (ip==nullptr)
		return false;
	if (ip->oper1==nullptr)
		return false;
	if (ip->oper3 && ip->opcode==op_mov
		&& ip->oper1->mode==am_reg && ip->oper1->preg==15
		&& ip->oper3->mode==am_direct)
		return true;
	if ((ip->opcode==op_inc || ip->opcode==op_dec)
		&& ip->oper1->mode==am_reg && ip->oper1->preg==15
		&& ip->oper2->mode==am_direct)
		return true;
	if (ip->opcode==op_jsr)
		return true;
	return false;
}

void PeepoptPred(OCODE *ip)
{
	OCODE *ip1, *ip2, *ip3, *ip4;
	ip1 = ip->fwd;
	if (ip1)
		ip2 = ip1->fwd;
	else
		return;
	if (ip2)
		ip3 = ip2->fwd;
	if (ip3)
		ip4 = ip3->fwd;
	if (ip1->opcode==op_label)
		return;
	if (ip->oper3==nullptr)
		return;
	if (ip2 && ip2->opcode==op_label) {
		if ((int)ip2->oper1 == ip->oper3->offset->i) {
			// pop_always, pop_nop, pop_z, pop_nz, pop_c, pop_nc, pop_mi, pop_pl
			switch(ip->predop) {
			// The code always branches over ip1. Eliminate the branch and the
			// the ip1 instruction.
			case pop_always:
				ip2->back = ip->back;
				ip->back->fwd = ip2;
				break;
			// The code never branches. Eliminate the jump
			case pop_nop:
				ip1->back = ip->back;
				ip->back->fwd = ip1;
				break;
			case pop_z:
			case pop_nz:
			case pop_c:
			case pop_nc:
			case pop_mi:
			case pop_pl:
				ip1->back = ip->back;
				ip->back->fwd = ip1;
				ip1->predop = ip->predop ^ 1;
				break;
			}
		}
		return;
	}
	return;
	if (ip3 && ip3->opcode==op_label) {
		if ((int)ip3->oper1 == ip->oper3->offset->i) {
			switch(ip->predop) {
			// The code always branches over ip1 and ip2. Eliminate the branch and the
			// the ip1 and ip2 instruction.
			case pop_always:
				ip3->back = ip->back;
				ip->back->fwd = ip3;
				break;
			// The code never branches. Eliminate the jump
			case pop_nop:
				ip1->back = ip->back;
				ip->back->fwd = ip1;
				break;
			case pop_z:
			case pop_nz:
			case pop_c:
			case pop_nc:
			case pop_mi:
			case pop_pl:
				// Eliminate the branch
				ip1->back = ip->back;
				ip->back->fwd = ip1;
				// And predicate the following instructions.
				ip1->predop = ip->predop ^ 1;
				ip2->predop = ip->predop ^ 1;
				break;
			}
		}
		return;
	}
	if (ip4 && ip4->opcode==op_label) {
		if ((int)ip4->oper1 == ip->oper3->offset->i) {
			switch(ip->predop) {
			// The code always branches over ip1 and ip2. Eliminate the branch and the
			// the ip1, ip2 and ip3 instruction.
			case pop_always:
				ip4->back = ip->back;
				ip->back->fwd = ip4;
				break;
			// The code never branches. Eliminate the jump
			case pop_nop:
				ip1->back = ip->back;
				ip->back->fwd = ip1;
				break;
			case pop_z:
			case pop_nz:
			case pop_c:
			case pop_nc:
			case pop_mi:
			case pop_pl:
				// Eliminate the branch
				ip1->back = ip->back;
				ip->back->fwd = ip1;
				// And predicate the following instructions.
				ip1->predop = ip->predop ^ 1;
				ip2->predop = ip->predop ^ 1;
				ip3->predop = ip->predop ^ 1;
				break;
			}
		}
		return;
	}
}

static void SetLabelReference()
{
	OCODE *p, *q;
	struct clit *ct;
	int nn;

	for (p = peep_head; p; p = p->fwd) {
		if (p->opcode==op_label) {
			p->isReferenced = false;
			for (q = peep_head; q; q = q->fwd) {
				if (q->oper3 && (q->oper3->mode==am_direct||q->oper3->mode==am_immed)) {
					if (q->oper3->offset->i == (int)p->oper1) {
						p->isReferenced = true;
						break;
					}
				}
				if (q->oper2 && q->oper2->mode==am_direct) {
					if (q->oper2->offset->i == (int)p->oper1) {
						p->isReferenced = true;
						break;
					}
				}
			}
			// Now search case tables for label
			for (ct = casetab; ct; ct = ct->next) {
				for (nn = 0; nn < ct->num; nn++)
					if (ct->cases[nn].label==(int)p->oper1)
						p->isReferenced = true;
			}
		}
	}
}

static int EliminateUnreferencedLabels()
{
	OCODE *p;
	int cnt;

	cnt = 0;
	for (p = peep_head; p; p = p->fwd) {
		if (p->opcode==op_label && !p->isReferenced) {
			MarkRemove(p);
			cnt++;
		}
	}
	return cnt;
}

// Count the references to the BP register. Exclude the function prolog /
// epilog code from the count.

static int CountBPReferences()
{
	OCODE *ip;
	int refBP;

	refBP = 0;
	for (ip = peep_head; ip != NULL; ip = ip->fwd)
	{
		if (ip->opcode != op_label && ip->opcode != op_preload && ip->opcode!=op_nop) {
			if (ip->opcode==op_hint) {
				if (ip->oper1->offset) {
					if ((ip->oper1->offset->i==4) || ip->oper1->offset->i==6) {
						ip = ip->fwd;
					while (ip && ip->opcode != op_hint)
						ip = ip->fwd;
					}
				}
			}
			if (ip->oper1) {
				if (ip->oper1->preg==regBP || ip->oper1->sreg==regBP)
					refBP++;
			}
			if (ip->oper2) {
				if (ip->oper2->preg==regBP || ip->oper2->sreg==regBP)
					refBP++;
			}
			if (ip->oper3) {
				if (ip->oper3->preg==regBP || ip->oper3->sreg==regBP)
					refBP++;
			}
			if (ip->oper4) {
				if (ip->oper4->preg==regBP || ip->oper4->sreg==regBP)
					refBP++;
			}
		}
	}
	return (refBP);
}


// Remove the stack linkage code, used when there are no references to BP.

static void RemoveLinkUnlink()
{
	OCODE *ip;

	for (ip = peep_head; ip != NULL; ip = ip->fwd)
	{
		if (ip->opcode==op_hint && (ip->oper1->offset->i==4 || ip->oper1->offset->i==6)) {
			MarkRemove(ip);
			ip = ip->fwd;
			while (ip && ip->opcode != op_hint) {
				MarkRemove(ip);
				ip = ip->fwd;
			}
		}
	}
}

// Remove all the compiler hints that didn't work out. Note hints are
// removed even if optimizations are turned off. Also remove all the
// preloads that didn't pan out.
static void RemoveHints()
{
	OCODE *ip;

	for(ip = peep_head; ip != NULL; ip = ip->fwd )
	{
		if (ip->opcode==op_hint || ip->opcode==op_preload || ip->opcode==op_nop) {
			MarkRemove(ip);
		}
	}
}

OCODE *FindLabel(int64_t i)
{
	OCODE *ip;

	for (ip = peep_head; ip; ip = ip->fwd) {
		if (ip->opcode==op_label) {
			if ((int)ip->oper1==i)
				return (ip);
		}
	}
	return nullptr;
}

/*
 *      peephole optimizer. This routine calls the instruction
 *      specific optimization routines above for each instruction
 *      in the peep list.
 */
static void opt_peep()
{  
	OCODE *ip;
	int rep;
	
	if (!::opt_nopeep) {
		opt_nbr();
		for (rep = 0; rep < 10; rep++)
		{
			SetLabelReference();
			EliminateUnreferencedLabels();
			MarkAllKeep();
			for (ip = peep_head; ip != NULL; ip = ip->fwd )
			{
				switch( ip->opcode )
				{
				case op_rem:
					if (ip->fwd) {
						if (ip->fwd->comment==nullptr)
							ip->fwd->comment = ip;
					}
					MarkRemove(ip);
					break;
				case op_ld:
					peep_ld(ip);
					PeepoptLd(ip);
					break;
				case op_mov:
						peep_move(ip);
						break;
				case op_add:
						peep_add(ip);
						break;
				case op_sub:
						PeepoptSub(ip);
						break;
				case op_cmp:
						peep_cmp(ip);
						break;
				case op_pop:
				case op_push:
						PeepoptPushPop(ip);
						break;
				case op_rti:
						PeepoptUctran(ip);
						break;
				case op_label:
						PeepoptLabel(ip);
						break;
				case op_hint:
						PeepoptHint(ip);
						break;
				case op_sto:
						PeepoptStore(ip);
						break;
				case op_and:
						PeepoptAnd(ip);
						break;
				}
				if (IsRet(ip))
					PeepoptUctran(ip);
				if (IsFlowCtrl(ip))
					PeepoptPred(ip);
				if (IsFlowCtrl(ip))
					PeepoptBranch(ip);
			}
			Remove();
		}
		PeepoptSubSP();
		ip = peep_head;

		// Check for references to the base pointer
		// Remove the link and unlink instructions if no references
		// to BP. 
		if (CountBPReferences()==0)
			RemoveLinkUnlink();
	}
	// Unreferenced labels are removed even if optimization is turned off.
	SetLabelReference();
	EliminateUnreferencedLabels();

	// Remove all the compiler hints that didn't work out. Note hints are
	// removed even if optimizations are turned off. Also remove all the
	// preloads that didn't pan out.
	RemoveHints();
	Remove();

	// In the works: code to support further optimizations
	BasicBlock::Blockize(peep_head);
	CreateControlFlowGraph();
	ComputeLiveVars();
	DumpLiveVars();
	Var::CreateVars();
	// If there are the same or fewer number of variables in the function as there
	// are machine registers available, then just allocate each var a register in a
	// simple fashion.
	if (Var::count < 4) {
		return;
	}
	Var::CreateForests();
	RemoveMoves();
	Var::DumpForests();
}

// Remove the mov operation from consideration.
// mov will create a false interference. Other instructions that copy from
// input to output could also create false interferences.

void RemoveMoves()
{
	OCODE *ip;
	BasicBlock *b;
	Var *v;
	Tree *t;

	for (ip = peep_head; ip; ip = ip->fwd) {
		if (ip->opcode==op_mov && ip->oper1 && ip->oper1->preg != regPC) {
			b = ip->bb;
			for (v = varlist; v; v = v->next) {
				for (t = v->trees; t; t = t->next) {
					t->tree->remove(b->num);
				}
			}
		}
	}
}

