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

static void AddToPeepList(struct ocode *newc);
static void Remove();
void MarkRemove(struct ocode *ip);
void peep_add(struct ocode *ip);
static void PeepoptSub(struct ocode *ip);
void peep_move(struct ocode	*ip);
void peep_cmp(struct ocode *ip);
static void opt_peep();
void put_ocode(struct ocode *p);

struct ocode    *peep_head = NULL,
                *peep_tail = NULL;

int optimized;	// something got optimized

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
	cd = (struct ocode *)allocx(sizeof(struct ocode));
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
	dfs.printf("<GenerateZeradic>\r\n");
	struct ocode *cd;
	dfs.printf("A");
	cd = (struct ocode *)allocx(sizeof(struct ocode));
	dfs.printf("B");
	cd->predop = 1;
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
	dfs.printf("</GenerateZeradic>\r\n");
}

void GenerateMonadic(int op, int len, AMODE *ap1)
{
	dfs.printf("Enter GenerateMonadic\r\n");
	struct ocode *cd;
	dfs.printf("A");
	cd = (struct ocode *)allocx(sizeof(struct ocode));
	dfs.printf("B");
	cd->predop = 1;
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
	dfs.printf("Leave GenerateMonadic\r\n");
}

void GeneratePredicatedDiadic(int pop, int pr, int op, int len, AMODE *ap1, AMODE *ap2)
{
	struct ocode *cd;
	cd = (struct ocode *)allocx(sizeof(struct ocode));
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
	cd->oper3 = NULL;
	cd->oper4 = NULL;
	AddToPeepList(cd);
}

void GenerateTriadic(int op, int len, AMODE *ap1, AMODE *ap2, AMODE *ap3)
{
	struct ocode    *cd;
	cd = (struct ocode *)allocx(sizeof(struct ocode));
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
	struct ocode *cd;
	cd = (struct ocode *)allocx(sizeof(struct ocode));
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

int PeepCount(struct ocode *ip)
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
	struct ocode *newl;
	newl = (struct ocode *)allocx(sizeof(struct ocode));
	newl->opcode = op_label;
	newl->oper1 = (struct amode *)labno;
	newl->oper2 = (struct amode *)my_strdup((char *)currentFn->name->c_str());
	AddToPeepList(newl);
}


// Detect references to labels
// Potential looping is N^2 although the inner loop is aborted as soon as a
// reference is found. It's a good thing functions are small and without
// too many lables.

static void SetLabelReference()
{
	struct ocode *p, *q;
	struct clit *ct;
	int nn;

	for (p = peep_head; p; p = p->fwd) {
		if (p->opcode==op_label) {
			p->isReferenced = false;
			for (q = peep_head; q; q = q->fwd) {
				if (q != p) {
					if (q->opcode!=op_label && q->opcode!=op_nop) {
						if (q->oper1 && (q->oper1->mode==am_direct || q->oper1->mode==am_immed)) {
							if (q->oper1->offset->i == (int)p->oper1) {
								p->isReferenced = true;
								break;
							}
						}
						if (q->oper2 && (q->oper2->mode==am_direct || q->oper2->mode==am_immed)) {
							if (q->oper2->offset->i == (int)p->oper1) {
								p->isReferenced = true;
								break;
							}
						}
						if (q->oper3 && (q->oper3->mode==am_direct || q->oper3->mode==am_immed)) {
							if (q->oper3->offset->i == (int)p->oper1) {
								p->isReferenced = true;
								break;
							}
						}
						if (q->oper4 && (q->oper4->mode==am_direct || q->oper4->mode==am_immed)) {
							if (q->oper4->offset->i == (int)p->oper1) {
								p->isReferenced = true;
								break;
							}
						}
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

static void EliminateUnreferencedLabels()
{
	struct ocode *p;

	for (p = peep_head; p; p = p->fwd) {
		p->remove = false;
		if (p->opcode==op_label && !p->isReferenced) {
			MarkRemove(p);
			optimized++;
		}
	}
}


//
// Output all code and labels in the peep list.
//
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
void put_ocode(struct ocode *p)
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

void peep_move(struct ocode	*ip)
{
	if (equal_address(ip->oper1, ip->oper2)) {
		MarkRemove(ip);
		optimized++;
	}
	if (ip->fwd) {
		if (ip->fwd->opcode==op_move) {
			if (equal_address(ip->oper1,ip->fwd->oper1)
				&& equal_address(ip->oper2,ip->fwd->oper2))
			{
				MarkRemove(ip);
				optimized++;
				return;
			}
		}
	}
	if (ip->back) {
		if (ip->back->opcode==op_add || ip->back->opcode==op_and) {	// any ALU op
			if (equal_address(ip->back->oper1, ip->oper1)) {
				if (!(equal_address(ip->back->oper2,ip->oper1) || ip->back->oper2==nullptr)
					&& (equal_address(ip->back->oper3,ip->oper1) || ip->back->oper3==nullptr)
					&& (equal_address(ip->back->oper4,ip->oper1) || ip->back->oper4==nullptr)) { 
					ip->back->back->fwd = ip;
					ip->back = ip->back->back;
					optimized++;
				}
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
  case am_dreg:
	  if (ap2->mode!=am_dreg)
		  return(FALSE);
	  return (ap1->preg==ap2->preg);
  case am_areg:
	  if (ap2->mode!=am_areg)
		  return(FALSE);
	  return (ap1->preg==ap2->preg);
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
            if (a->mode==am_areg) {
                if (a->preg==regSP) {
                    if (ip->fwd->opcode==op_move) {
                        if (ip->fwd->oper1->mode==am_areg) {
                            if (ip->fwd->oper1->preg == regSP) {
                                if (ip->back==NULL)
                                    return;
                                ip->back->fwd = ip->fwd;
                                ip->fwd->back = ip->back;
								optimized++;
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
	return;
}

static bool IsSubiSP(struct ocode *ip)
{
	if (ip->opcode==op_sub) {
		if (ip->oper1->mode==am_immed) {
			if (ip->oper2->preg==regSP) {
				return (true);
			}
		}
	}
	return (false);
}

static void MergeSubi(struct ocode *first, struct ocode *last, int64_t amt)
{
	struct ocode *ip;

	if (first==nullptr)
		return;

	// First remove all the excess subtracts
	for (ip = first; ip && ip != last; ip = ip->fwd) {
		if (IsSubiSP(ip)) {
			MarkRemove(ip);
			optimized++;
		}
	}
	// Set the amount of the last subtract to the total amount
	if (ip)	 {// there should be one
		ip->oper3->offset->i = amt;
	}
}

static bool IsFlowControl(struct ocode *ip)
{
	if (ip->opcode==op_jal ||
		ip->opcode==op_jmp ||
		ip->opcode==op_ret ||
		ip->opcode==op_call ||
		ip->opcode==op_bra ||
		ip->opcode==op_beq ||
		ip->opcode==op_bne ||
		ip->opcode==op_blt ||
		ip->opcode==op_ble ||
		ip->opcode==op_bgt ||
		ip->opcode==op_bge ||
		ip->opcode==op_bltu ||
		ip->opcode==op_bleu ||
		ip->opcode==op_bgtu ||
		ip->opcode==op_bgeu ||
		ip->opcode==op_beqi ||
		ip->opcode==op_bnei ||
		ip->opcode==op_blti ||
		ip->opcode==op_blei ||
		ip->opcode==op_bgti ||
		ip->opcode==op_bgei ||
		ip->opcode==op_bltui ||
		ip->opcode==op_bleui ||
		ip->opcode==op_bgtui ||
		ip->opcode==op_bgeui
		)
		return (true);
	return (false);
}

// 'subui'
//
static void PeepoptSubSP()
{  
	struct ocode *ip;
	struct ocode *first_subi = nullptr;
	struct ocode *last_subi = nullptr;
	int64_t amt = 0;

	for (ip = peep_head; ip; ip = ip->fwd) {
		if (IsSubiSP(ip)) {
			if (first_subi==nullptr)
				last_subi = first_subi = ip;
			else
				last_subi = ip;
			amt += ip->oper3->offset->i;
		}
		else if (ip->opcode==op_push || IsFlowControl(ip)) {
			MergeSubi(first_subi, last_subi, amt);
			first_subi = last_subi = nullptr;
			amt = 0;
		}
	}
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
	int shcnt;
	int64_t num;

	if( ip->oper1->mode != am_immed )
		return;
	if( ip->oper1->offset->nodetype != en_icon )
		return;

	num = ip->oper1->offset->i;

  // remove multiply / divide by 1
	// This shouldn't get through Optimize, but does sometimes.
  if (num==1) {
		if (ip->back)
			ip->back->fwd = ip->fwd;
		if (ip->fwd)
			ip->fwd->back = ip->back;
		optimized++;
		return;
	}
  for (shcnt = 1; shcnt < 32; shcnt++) {
    if (num == (int64_t)1 << shcnt) {
      num = shcnt;
		optimized++;
      break;
    }
  }
  if (shcnt==32)
    return;
  ip->oper1->offset->i = num;
  ip->opcode = op;
  ip->length = 2;
	optimized++;
}

// Optimize unconditional control flow transfers
// Instructions that follow an unconditional transfer won't be executed
// unless there is a label to branch to them.
//
void PeepoptUctran(struct ocode *ip)
{
	if (uctran_off) return;
	while( ip->fwd != NULL && ip->fwd->opcode != op_label)
	{
		ip->fwd = ip->fwd->fwd;
		if( ip->fwd != NULL )
			ip->fwd->back = ip;
		optimized++;
	}
}

void PeepoptJAL(struct ocode *ip)
{
	if (ip->oper1->preg!=0)
		return;
	PeepoptUctran(ip);
}

// Remove instructions that branch to the next label.
//
void PeepoptBranch(struct ocode *ip)
{
	struct ocode *p;

	for (p = ip->fwd; p && p->opcode==op_label; p = p->fwd)
		if (ip->oper1->offset->i == (int)p->oper1) {
			MarkRemove(ip);
			optimized++;
			return;
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
        
void PeepoptBcc(struct ocode * ip)
{
     struct ocode *fwd1, *fwd2, *fwd3, *fwd4, *fwd5;
     if (!ip->fwd)
         return;
     fwd1 = ip->fwd;
     if (fwd1->opcode != op_ldi || fwd1->oper2->mode != am_immed)
         return;
     fwd2 = fwd1->fwd;
     if (!fwd2)
         return;
     if (fwd2->opcode != op_bra)
         return;
     fwd3 = fwd2->fwd;
     if (!fwd3)
         return;
     if (fwd3->opcode != op_label)
         return;
     fwd4 = fwd3->fwd;
     if (!fwd4)
         return;
     if (fwd4->opcode != op_ldi || fwd4->oper2->mode != am_immed)
         return;
     fwd5 = fwd4->fwd;
     if (!fwd5)
         return;
     if (fwd5->opcode != op_label)
         return;
     // now check labels match up
     if (ip->oper2!=fwd3->oper1)
         return;
     if (fwd2->oper1!=fwd5->oper1)
         return;
     // check for same target register
     if (!equal_address(fwd1->oper1,fwd4->oper1))
         return;
     // check ldi values
     if (fwd1->oper2->offset->i != 1)
         return;
     if (fwd4->oper2->offset->i != 0)
         return;
// *****
// need to check branch targets to make sure no other code targets the label.
// or this code might not work.
}

void PeepoptLc(struct ocode *ip)
{
	if (ip->fwd) {
		if (ip->fwd->opcode==op_sext16 || ip->fwd->opcode==op_sxc ||
			(ip->fwd->opcode==op_bfext && ip->fwd->oper3->offset->i==0 && ip->fwd->oper4->offset->i==15)) {
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

	return;
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
  // Pushing a single register     
  if (ip2->oper1->mode != am_areg)
     return;
  // And it's the same register as the LEA
  if (ip2->oper1->preg != ip->oper1->preg)
     return;
  ip->opcode = op_pea;
  ip->oper1 = copy_addr(ip->oper2);
  ip->oper2 = NULL;
  ip->fwd = ip2->fwd;
}

// LW followed by a push of the same register gets translated to PUSH.

void PeepoptLw(struct ocode *ip)
{
	struct ocode *ip2;

	return;
	ip2 = ip->fwd;
	if (!ip2)
	   return;
    if (ip2->opcode != op_push)
       return;
    if (ip2->oper1->mode != am_areg && ip2->oper1->mode != am_dreg)
       return;
    if (ip->oper2->mode != am_ind && ip->oper2->mode != am_indx)
       return;
    if (ip->oper1->preg != ip2->oper1->preg)
       return;     
    ip->opcode = op_push;
    ip->oper1 = copy_addr(ip->oper2);
    ip->oper2 = NULL;
    ip->fwd = ip2->fwd;
}

// Combine a chain of push operations into a single push

void PeepoptPushPop(struct ocode *ip)
{
	struct ocode *ip2,*ip3,*ip4;

	return;
	if (ip->opcode==op_pop) {
		ip2 = ip->fwd;
		if (ip2 && ip2->opcode==op_push) {
			ip3 = ip2->fwd;
			if (ip3 && ip3->opcode==op_ldi) {
				if (ip3->oper1->preg==ip2->oper1->preg && ip3->oper1->preg==ip->oper1->preg) {
					ip->back->fwd = ip2->fwd;
					ip->back->fwd->comment = ip2->comment;
				}
			}
		}
	}
	return;
    if (!isTable888)
        return;
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

void peep_ld(struct ocode *ip)
{
	if (ip->oper2->mode != am_immed)
		return;
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
	optimized++;
}


void PeepoptLd(struct ocode *ip)
{
    return;
}


// Remove extra labels at end of subroutines

void PeepoptLabel(struct ocode *ip)
{
    if (!ip)
        return;
    if (ip->fwd)
        return;
	if (ip->back)
		ip->back->fwd = nullptr;
	optimized++;
}
 
// Optimize away duplicate sign extensions that the compiler sometimes
// generates. This handles sxb, sxcm and sxh.

void PeepoptSxb(struct ocode *ip)
{
     if (!ip->fwd)
         return;
     if (ip->fwd->opcode != ip->opcode)
         return;
     if (ip->fwd->oper1->preg != ip->oper1->preg)
         return;
     if (ip->fwd->oper2->preg != ip->oper2->preg)
         return;
     // Now we must have the same instruction twice in a row. ELiminate the
     // duplicate.
     ip->fwd = ip->fwd->fwd;
     if (ip->fwd->fwd)
          ip->fwd->fwd->back = ip;
	optimized++;
}
void PeepoptSxbAnd(struct ocode *ip)
{
     if (!ip->fwd)
         return;
     if (ip->opcode != op_sxb)
         return;
     if (ip->fwd->opcode != op_and)
         return;
	 if (ip->fwd->oper3->mode != am_immed)
		 return;
     if (ip->fwd->oper3->offset->i != 255)
         return;
	MarkRemove(ip);
	optimized++;
}


// Eliminate branchs to the next line of code.

static void opt_nbr()
{
	struct ocode *ip,*pip;
	
	ip = peep_head;
	pip = peep_head;
	while(ip) { 
		if (ip->opcode==op_label) {
			if (pip->opcode==op_br || pip->opcode==op_bra) {
				if ((int64_t)ip->oper1==pip->oper1->offset->i)	{
					pip->back->fwd = pip->fwd;
					ip->back = pip->back;
					optimized++;
				}
			}
		}
		pip = ip;
		ip = ip->fwd;
	}
}


// Return true if the instruction has a target register.

static bool HasTargetReg(struct ocode *ip)
{
	switch(ip->opcode) {
	case op_lb:
	case op_lc:
	case op_lh:
	case op_lbu:
	case op_lcu:
	case op_lhu:
	case op_lw:
	case op_add:
	case op_sub:
	case op_and:
	case op_or:
	case op_mul:
	case op_div:
	case op_mulu:
	case op_divu:
		return true;
	}
	return false;
}

// Process compiler hint opcodes

static void PeepoptHint(struct ocode *ip)
{
	if ((ip->back && ip->back->opcode==op_label) || (ip->fwd && ip->fwd->opcode==op_label))
		return;

	switch (ip->oper1->offset->i) {

	// hint #1
	// Takes care of redundant moves at the parameter setup point
	// Code Like:
	//    MOV r3,#constant
	//    MOV r18,r3
	// Translated to:
	//    MOV r18,#constant
	case 1:
		if (ip->fwd && ip->fwd->opcode != op_move) {
			MarkRemove(ip);
			optimized++;
			return;
		}
		
		if (ip->back && ip->back->opcode != op_move) {
			MarkRemove(ip);
			optimized++;
			return;
		}
		
		if (equal_address(ip->fwd->oper2, ip->back->oper1)) {
			ip->back->oper1 = ip->fwd->oper1;
			MarkRemove(ip);
			MarkRemove(ip->fwd);
			optimized++;
		}
		else {
			MarkRemove(ip);
			optimized++;
		}
		break;

	// hint #2
	// Takes care of redundant moves at the function return point
	// Code like:
	//     MOV R3,arg
	//     MOV R1,R3
	// Translated to:
	//     MOV r1,arg
	case 2:
		if (ip->fwd==nullptr || ip->back==nullptr)
			break;
		if (equal_address(ip->fwd->oper2, ip->back->oper1)) {
			if (HasTargetReg(ip->back)) {
				ip->back->oper1 = ip->fwd->oper1;
				MarkRemove(ip->fwd);
				optimized++;
			}
		}
		else {
			MarkRemove(ip);
			optimized++;
		}
		break;

	// hint #9
	// Index calc.
	//		shl r1,r3,#3
	//		sw r4,[r11+r1]
	// Becomes:
	//		sw r4,[r11+r3*8]
	case 9:
		if (ip->fwd==nullptr || ip->back==nullptr)
			break;
		if (ip->fwd->oper2==nullptr || ip->back->oper3==nullptr)
			break;
		if (ip->fwd->oper2->preg == ip->back->oper1->preg) {
			if ((ip->back->opcode==op_shl) && ip->back->oper3->offset &&
				(ip->back->oper3->offset->i == 1 
				|| ip->back->oper3->offset->i == 2
				|| ip->back->oper3->offset->i == 3)) {
					ip->fwd->oper2->preg = ip->back->oper2->preg;
					ip->fwd->oper2->scale = 1 << ip->back->oper3->offset->i;
					MarkRemove(ip->back);
					optimized++;
			}
		}
		break;
	}
}

// A store followed by a load of the same address removes
// the load operation.
// Eg.
// SH   r3,Address
// LH	r3,Address
// Turns into
// SH   r3,Address
// Note this optimization won't be performed for volatile
// addresses.

static void PeepoptStore(struct ocode *ip)
{
	if (ip->opcode==op_label || ip->fwd->opcode==op_label)
		return;
	if (!equal_address(ip->oper1, ip->fwd->oper1))
		return;
	if (!equal_address(ip->oper2, ip->fwd->oper2))
		return;
	if (ip->opcode==op_sh && ip->fwd->opcode!=op_lh)
		return;
	if (ip->opcode==op_sw && ip->fwd->opcode!=op_lw)
		return;
	if (ip->fwd->isVolatile)
		return;
	MarkRemove(ip->fwd);
	optimized++;
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

static void PeepoptAnd(struct ocode *ip)
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
		MarkRemove(ip);
	}
}

// Check for references to the base pointer. If nothing refers to the
// base pointer then the stack linkage instructions can be removed.

static int CountBPReferences()
{
	int refBP = 0;
	struct ocode *ip;

	for (ip = peep_head; ip != NULL; ip = ip->fwd)
	{
		if (ip->opcode != op_label && ip->opcode!=op_nop
			&& ip->opcode != op_link && ip->opcode != op_unlk) {
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

void MarkRemove(struct ocode *ip)
{
	ip->remove = true;
}

static void MarkAllKeep()
{
	struct ocode *ip;

	for (ip = peep_head; ip != NULL; ip = ip->fwd )
	{
		ip->remove = false;
	}
}

static void Remove()
{
	struct ocode *ip, *ip1, *ip2;

	for (ip = peep_head; ip; ip = ip1) {
		ip1 = ip->fwd;
		ip2 = ip->back;
		if (ip->remove) {
			if (ip1 && ip1->comment==nullptr)
				ip1->comment = ip->comment;
			if (ip2)
				ip2->fwd = ip1;
			if (ip1)
				ip1->back = ip2;
		}
	}
}

// Remove stack linkage code for when there are no references to the base 
// pointer.

static void RemoveLinkUnlink()
{
	struct ocode *ip;

	for (ip = peep_head; ip != NULL; ip = ip->fwd)
	{
		if (ip->opcode==op_link || ip->opcode==op_unlk) {
			MarkRemove(ip);
		}
	}
}

static void RemoveCompilerHints()
{
	struct ocode *ip;

    for(ip = peep_head; ip != NULL; ip = ip->fwd)
    {
        if (ip->opcode==op_hint) {
			MarkRemove(ip);
		}
	}
}

//
//      peephole optimizer. This routine calls the instruction
//      specific optimization routines above for each instruction
//      in the peep list.
//
static void opt_peep()
{  
	struct ocode *ip;
	int rep;
	
	// Remove any dead code identified by the code generator.
	Remove();

	if (!::opt_nopeep) {

		opt_nbr();

		// Performing peephole optimizations may lead to further optimizations so do
		// the optimization step a few times.
		optimized = 0;
		for (rep = 0; (rep < 5) || (optimized && rep < 10); rep++)
		{
			// Peephole optimizations might lead to unreferenced labels, which may make
			// further peephole optimizations possible.
			SetLabelReference();
			EliminateUnreferencedLabels();
			Remove();
			MarkAllKeep();
			for (ip = peep_head; ip != NULL; ip = ip->fwd )
			{
				if (!ip->remove)
				switch( ip->opcode )
				{
				case op_rem:
					if (ip->fwd) {
						ip->fwd->comment = ip;
						MarkRemove(ip);
					}
					break;
				case op_ld:
					peep_ld(ip);
					PeepoptLd(ip);
				break;
				case op_move:
						peep_move(ip);
						break;
				case op_add:
				case op_adda:
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
				case op_lw:
						//PeepoptLw(ip);
						break;
				case op_sxb:
				case op_sxc:
				case op_sxh:
						PeepoptSxb(ip);
						PeepoptSxbAnd(ip);
						break;
				case op_br:
				case op_bra:
						PeepoptBranch(ip);
						PeepoptUctran(ip);
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
				case op_ret:
				case op_rts:
				case op_rte:
				case op_rtd:
				case op_rtl:
						PeepoptUctran(ip);
						break;
				case op_label:
						PeepoptLabel(ip);
						break;
				case op_hint:
						PeepoptHint(ip);
						break;
				case op_sh:
				case op_sw:
						PeepoptStore(ip);
						break;
				case op_and:
						PeepoptAnd(ip);
						break;
				}
			}
			Remove();
		}
		PeepoptSubSP();

		// Remove the link and unlink instructions if no references
		// to BP.
		if (CountBPReferences()==0)
			RemoveLinkUnlink();
		Remove();
	}

	// Get rid of extra labels that clutter up the output
	SetLabelReference();
	EliminateUnreferencedLabels();
	Remove();

	// Remove all the compiler hints that didn't work out.
	RemoveCompilerHints();
	Remove();
}
