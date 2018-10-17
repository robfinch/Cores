// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// CC64 - 'C' derived language compiler
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

static void AddToPeepList(OCODE *newc);
void PrintPeepList();
static void Remove();
void peep_add(OCODE *ip);
static void PeepoptSub(OCODE *ip);
void peep_cmp(OCODE *ip);
static void opt_peep();
void put_ocode(OCODE *p);
void CreateControlFlowGraph();
extern void ComputeLiveVars();
extern void DumpLiveVars();
extern Instruction *GetInsn(int);
void CreateVars();
void ComputeLiveRanges();
void DumpLiveRanges();
void RemoveMoves();
void DumpVarForests();
void DumpLiveRegs();
void CreateVarForests();
void DeleteSets();
void RemoveCode();
bool Coalesce();
void ComputeSpillCosts();
extern void CalcDominatorTree();
Var *FindVar(int num);
void ExpandReturnBlocks();
bool RemoveEnabled = true;
unsigned int ArgRegCount;
int count;
Map map;

OCODE *LabelTable[50000];

OCODE    *peep_head = NULL,
                *peep_tail = NULL;

extern Var *varlist;


IGraph iGraph;
int optimized;	// something got optimized

void GenerateZeradic(int op)
{
	dfs.printf("<GenerateZeradic>");
	OCODE *cd;
	dfs.printf("A");
	cd = (OCODE *)allocx(sizeof(OCODE));
	dfs.printf("B");
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = 0;
	cd->oper1 = NULL;
	dfs.printf("C");
	cd->oper2 = NULL;
	cd->oper3 = NULL;
	cd->oper4 = NULL;
	dfs.printf("D");
	cd->loop_depth = looplevel;
	AddToPeepList(cd);
	dfs.printf("</GenerateZeradic>\r\n");
}

void GenerateMonadic(int op, int len, Operand *ap1)
{
	dfs.printf("<GenerateMonadic>");
	OCODE *cd;
	dfs.printf("A");
	cd = (OCODE *)allocx(sizeof(OCODE));
	dfs.printf("B");
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = ap1->Clone();
	dfs.printf("C");
	cd->oper2 = NULL;
	cd->oper3 = NULL;
	cd->oper4 = NULL;
	dfs.printf("D");
	cd->loop_depth = looplevel;
	AddToPeepList(cd);
	dfs.printf("</GenerateMonadic>\n");
}

void GenerateDiadic(int op, int len, Operand *ap1, Operand *ap2)
{
	OCODE *cd;
	cd = (OCODE *)xalloc(sizeof(OCODE));
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = ap1->Clone();
	cd->oper2 = ap2->Clone();
	if (ap2) {
		if (ap2->mode == am_ind || ap2->mode==am_indx) {
			//if (ap2->preg==regSP || ap2->preg==regFP)
			//	cd->opcode |= op_ss;
		}
	}
	cd->oper3 = NULL;
	cd->oper4 = NULL;
	cd->loop_depth = looplevel;
	AddToPeepList(cd);
}

void GenerateTriadic(int op, int len, Operand *ap1, Operand *ap2, Operand *ap3)
{
	OCODE    *cd;
	cd = (OCODE *)allocx(sizeof(OCODE));
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = ap1->Clone();
	cd->oper2 = ap2->Clone();
	cd->oper3 = ap3->Clone();
	cd->oper4 = NULL;
	cd->loop_depth = looplevel;
	AddToPeepList(cd);
}

void Generate4adic(int op, int len, Operand *ap1, Operand *ap2, Operand *ap3, Operand *ap4)
{
	OCODE *cd;
	cd = (OCODE *)allocx(sizeof(OCODE));
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = ap1->Clone();
	cd->oper2 = ap2->Clone();
	cd->oper3 = ap3->Clone();
	cd->oper4 = ap4->Clone();
	cd->loop_depth = looplevel;
	AddToPeepList(cd);
}

static void AddToPeepList(OCODE *cd)
{
	if (!dogen)
		return;

	if( peep_head == NULL )
	{
		ArgRegCount = regFirstArg;
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
	if (cd->opcode!=op_label) {
		if (cd->oper1 && IsArgumentReg(cd->oper1->preg))
			ArgRegCount = max(ArgRegCount,cd->oper1->preg);
		if (cd->oper2 && IsArgumentReg(cd->oper2->preg))
			ArgRegCount = max(ArgRegCount,cd->oper2->preg);
		if (cd->oper3 && IsArgumentReg(cd->oper3->preg))
			ArgRegCount = max(ArgRegCount,cd->oper3->preg);
		if (cd->oper4 && IsArgumentReg(cd->oper4->preg))
			ArgRegCount = max(ArgRegCount,cd->oper4->preg);
	}
}


// Count the length of the peep list from the current position to the end of
// the list.

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
	newl->oper1 = (Operand *)labno;
	newl->oper2 = (Operand *)my_strdup((char *)currentFn->sym->name->c_str());
	AddToPeepList(newl);
}


// Detect references to labels

void PeepOpt::SetLabelReference()
{
	OCODE *p, *q;
	struct clit *ct;
	int nn;

	ZeroMemory(LabelTable, sizeof(LabelTable));
	for (p = peep_head; p; p = p->fwd) {
		if (p->opcode == op_label) {
			LabelTable[(int)p->oper1] = p;
			p->isReferenced = false;
		}
	}
	for (q = peep_head; q; q = q->fwd) {
		if (q->opcode!=op_label && q->opcode!=op_nop) {
			if (q->oper1 && (q->oper1->mode==am_direct || q->oper1->mode==am_imm)) {
				if (p = PeepList::FindLabel(q->oper1->offset->i)) {
					p->isReferenced = true;
				}
			}
			if (q->oper2 && (q->oper2->mode==am_direct || q->oper2->mode==am_imm)) {
				if (p = PeepList::FindLabel(q->oper2->offset->i)) {
					p->isReferenced = true;
				}
			}
			if (q->oper3 && (q->oper3->mode==am_direct || q->oper3->mode==am_imm)) {
				if (p = PeepList::FindLabel(q->oper3->offset->i)) {
					p->isReferenced = true;
				}
			}
			if (q->oper4 && (q->oper4->mode==am_direct || q->oper4->mode==am_imm)) {
				if (p = PeepList::FindLabel(q->oper4->offset->i)) {
					p->isReferenced = true;
				}
			}
			// Now search case tables for label
			for (ct = casetab; ct; ct = ct->next) {
				for (nn = 0; nn < ct->num; nn++)
					if (p = PeepList::FindLabel(ct->cases[nn].label))
						p->isReferenced = true;
			}
		}
	}
}

void PeepOpt::EliminateUnreferencedLabels()
{
	OCODE *p;

	for (p = peep_head; p; p = p->fwd) {
		if (p->opcode == op_label)
			p->remove = false;
		if (p->opcode == op_label && !p->isReferenced) {
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
			peep_head->store(ofs);
		peep_head = peep_head->fwd;
	}
}

void peep_add(OCODE *ip)
{
     Operand *a;
     
     // IF add to SP is followed by a move to SP, eliminate the add
     if (ip==NULL)
         return;
     if (ip->fwd==NULL)
         return;
	 if (ip->fwd->opcode == op_bra) {
		 if (ip->oper3->offset) {
			 if (ip->oper1->preg == ip->oper2->preg && ip->oper3->offset->i == 1) {
				 ip->opcode = op_ibne;
				 ip->insn = GetInsn(op_ibne);
				 ip->oper2->preg = 0;
				 ip->oper3 = ip->fwd->oper1;
				 MarkRemove(ip->fwd);
				 optimized++;
			 }
		 }
		 return;
	 }
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
								optimized++;
                            }
                        }
                    }
                }
            }
     }
	return;
}

static bool IsSubiSP(OCODE *ip)
{
	if (ip->opcode == op_sub) {
		if (ip->oper3->mode == am_imm) {
			if (ip->oper1->preg == regSP && ip->oper2->preg == regSP) {
				return (true);
			}
		}
	}
	return (false);
}

// 'subui' followed by a 'bne' gets turned into 'loop'
//
static void PeepoptSub(OCODE *ip)
{  
	if (IsSubiSP(ip) && ip->fwd)
		if (IsSubiSP(ip->fwd)) {
			ip->oper3->offset->i += ip->fwd->oper3->offset->i;
			MarkRemove(ip->fwd);
	}
	if (IsSubiSP(ip) && ip->oper3->offset->i == 0)
		MarkRemove(ip);
	return;
	if (ip->opcode==op_subui) {
		if (ip->oper3) {
			if (ip->oper3->mode==am_imm) {
				if (ip->oper3->offset->nodetype==en_icon && ip->oper3->offset->i==1) {
					if (ip->fwd) {
						if (ip->fwd->opcode==op_ne && ip->fwd->oper2->mode==am_reg && ip->fwd->oper2->preg==0) {
							if (ip->fwd->oper1->preg==ip->oper1->preg) {
								ip->opcode = op_loop;
								ip->oper2 = ip->fwd->oper3;
								ip->oper3 = NULL;
								if (ip->fwd->back) ip->fwd->back = ip;
								ip->fwd = ip->fwd->fwd;
								optimized++;
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

static void MergeSubi(OCODE *first, OCODE *last, int64_t amt)
{
	OCODE *ip;

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

// 'subui'
//
static void PeepoptSubSP()
{  
	OCODE *ip;
	OCODE *first_subi = nullptr;
	OCODE *last_subi = nullptr;
	int64_t amt = 0;

	for (ip = peep_head; ip; ip = ip->fwd) {
		if (IsSubiSP(ip)) {
			if (first_subi==nullptr)
				last_subi = first_subi = ip;
			else
				last_subi = ip;
			amt += ip->oper3->offset->i;
		}
		else if (ip->opcode==op_push || ip->insn->IsFlowControl()) {
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
	int shcnt;
	int64_t num;

	if( ip->oper1->mode != am_imm )
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
void PeepoptUctran(OCODE *ip)
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

void PeepoptJAL(OCODE *ip)
{
	if (ip->oper1->preg!=0)
		return;
	PeepoptUctran(ip);
}

// Remove instructions that branch to the next label.
//
void PeepoptBranch(OCODE *ip)
{
	OCODE *p;

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
        
void PeepoptBcc(OCODE * ip)
{
     OCODE *fwd1, *fwd2, *fwd3, *fwd4, *fwd5;
     if (!ip->fwd)
         return;
     fwd1 = ip->fwd;
     if (fwd1->opcode != op_ldi || fwd1->oper2->mode != am_imm)
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
     if (fwd4->opcode != op_ldi || fwd4->oper2->mode != am_imm)
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
     if (!OCODE::IsEqualOperand(fwd1->oper1,fwd4->oper1))
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

void PeepoptLc(OCODE *ip)
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

void PeepoptLea(OCODE *ip)
{
	OCODE *ip2;
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
  if (ip2->oper1->mode != am_reg)
     return;
  // And it's the same register as the LEA
  if (ip2->oper1->preg != ip->oper1->preg)
     return;
  ip->opcode = op_pea;
  ip->oper1 = ip->oper2->Clone();
  ip->oper2 = NULL;
  ip->fwd = ip2->fwd;
}

// LW followed by a push of the same register gets translated to PUSH.

void PeepoptLw(OCODE *ip)
{
	OCODE *ip2;

	return;
	ip2 = ip->fwd;
	if (!ip2)
	   return;
    if (ip2->opcode != op_push)
       return;
    if (ip2->oper1->mode != am_reg)
       return;
    if (ip->oper2->mode != am_ind && ip->oper2->mode != am_indx)
       return;
    if (ip->oper1->preg != ip2->oper1->preg)
       return;     
    ip->opcode = op_push;
    ip->oper1 = ip->oper2->Clone();
    ip->oper2 = NULL;
    ip->fwd = ip2->fwd;
}

// LC0I followed by a push of the same register gets translated to PUSH.

void PeepoptLc0i(OCODE *ip)
{
	OCODE *ip2;

    if (!isFISA64)
       return;
	ip2 = ip->fwd;
	if (!ip2)
	   return;
    if (ip2->opcode != op_push)
       return;
    if (ip->oper2->offset->i > 0x1fffLL || ip->oper2->offset->i <= -0x1fffLL)
       return;
    ip->opcode = op_push;
    ip->oper1 = ip->oper2->Clone();
    ip->oper2 = NULL;
    ip->fwd = ip2->fwd;
}


// Combine a chain of push operations into a single push

void PeepoptPushPop(OCODE *ip)
{
	OCODE *ip2,*ip3,*ip4;

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
	if (ip->oper1->mode == am_imm)
		return;
	ip2 = ip->fwd;
	if (!ip2)
		return;
	if (ip2->opcode!=ip->opcode)
		return;
	if (ip2->oper1->mode==am_imm)
		return;
	ip->oper2 = ip2->oper1->Clone();
	ip->fwd = ip2->fwd;
	ip3 = ip2->fwd;
	if (!ip3)
		return;
	if (ip3->opcode!=ip->opcode)
		return;
	if (ip3->oper1->mode==am_imm)
		return;
	ip->oper3 = ip3->oper1->Clone();
	ip->fwd = ip3->fwd;
	ip4 = ip3->fwd;
	if (!ip4)
		return;
	if (ip4->opcode!=ip->opcode)
		return;
	if (ip4->oper1->mode==am_imm)
		return;
	ip->oper4 = ip4->oper1->Clone();
	ip->fwd = ip4->fwd;
}


// Strip out useless masking operations generated by type conversions.

void peep_ld(OCODE *ip)
{
	if (ip->oper2->mode != am_imm)
		return;
	if (ip->oper2->offset->i==0) {
		ip->opcode = op_mov;
		ip->oper2->mode = am_reg;
		ip->oper2->preg = 0;
		optimized++;
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
	if (ip->fwd->oper3->mode != am_imm)
		return;
	ip->oper2->offset->i = ip->oper2->offset->i & ip->fwd->oper3->offset->i;
	if (ip->fwd->fwd)
		ip->fwd->fwd->back = ip;
	ip->fwd = ip->fwd->fwd;
	optimized++;
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
	if (ip->back)
		ip->back->fwd = nullptr;
	optimized++;
}
 
// Optimize away duplicate sign extensions that the compiler sometimes
// generates. This handles sxb, sxcm and sxh.

void PeepoptSxb(OCODE *ip)
{
	// Optimize away sign extension of a signed load
	if (ip->back) {
		if (ip->back->opcode == op_lb && ip->opcode == op_sxb) {
			if (ip->back->oper1->preg == ip->oper1->preg && ip->oper1->preg==ip->oper2->preg) {
				MarkRemove(ip);
				optimized++;
				return;
			}
		}
		if (ip->back->opcode == op_lc && ip->opcode == op_sxc) {
			if (ip->back->oper1->preg == ip->oper1->preg && ip->oper1->preg == ip->oper2->preg) {
				MarkRemove(ip);
				optimized++;
				return;
			}
		}
		if (ip->back->opcode == op_lh && ip->opcode == op_sxh) {
			if (ip->back->oper1->preg == ip->oper1->preg && ip->oper1->preg == ip->oper2->preg) {
				MarkRemove(ip);
				optimized++;
				return;
			}
		}
	}
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
void PeepoptSxbAnd(OCODE *ip)
{
     if (!ip->fwd)
         return;
     if (ip->opcode != op_sxb)
         return;
     if (ip->fwd->opcode != op_and)
         return;
	 if (ip->fwd->oper3->mode != am_imm)
		 return;
     if (ip->fwd->oper3->offset->i != 255)
         return;
	MarkRemove(ip);
	optimized++;
}


// Eliminate branchs to the next line of code.

static void opt_nbr()
{
	OCODE *ip,*pip;
	
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


// Process compiler hint opcodes

static void PeepoptHint(OCODE *ip)
{
	OCODE *fwd, *back;
	Operand *am;

	if ((ip->back && ip->back->opcode==op_label) || (ip->fwd && ip->fwd->opcode==op_label))
		return;
	if (ip->remove)
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
		if (ip->fwd && ip->fwd->opcode != op_mov) {
			MarkRemove(ip);
			optimized++;
			return;
		}
		
		if (ip->fwd && ip->fwd->oper1->preg >= 18 && ip->fwd->oper1->preg < 24) {
			if (OCODE::IsEqualOperand(ip->fwd->oper2, ip->back->oper1)) {
				ip->back->oper1 = ip->fwd->oper1;
				MarkRemove(ip);
				MarkRemove(ip->fwd);
				optimized++;
				return;
			}
		}

		if (ip->back && ip->back->opcode != op_mov) {
			MarkRemove(ip);
			optimized++;
			return;
		}
		
		if (OCODE::IsEqualOperand(ip->fwd->oper2, ip->back->oper1)) {
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

	// Can't do this optimization:
	// what if x = (~(y=(a & b)))
	// The embedded assignment to y which might be used later would be lost.
	//
	// hint #2
	// Takes care of redundant moves at the function return point
	// Code like:
	//     MOV R3,arg
	//     MOV R1,R3
	// Translated to:
	//     MOV r1,arg
	case 2:
		return;
		if (ip->fwd==nullptr || ip->back==nullptr)
			break;
		if (ip->fwd->remove || ip->back->remove)
			break;
		if (OCODE::IsEqualOperand(ip->fwd->oper2, ip->back->oper1)) {
			if (ip->back->HasTargetReg()) {
				if (!(ip->fwd->oper1->mode == am_fpreg && ip->back->opcode==op_ldi)) {
					ip->back->oper1 = ip->fwd->oper1;
					MarkRemove(ip->fwd);
					optimized++;
				}
			}
		}
		else {
			MarkRemove(ip);
			optimized++;
		}
		break;

	// hint #3
	//	   and r5,r2,r3
	//     com r1,r5
	// Translates to:
	//     nand r5,r2,r3
	case 3:
		if (ip->back == nullptr || ip->fwd == nullptr)
			break;
		if (ip->fwd->remove || ip->back->remove)
			break;
		// If not all in registers
		if (ip->back->oper1->mode != am_reg
			|| ip->back->oper2->mode != am_reg
			|| (ip->back->oper3 && ip->back->oper3->mode != am_reg))
			break;
		if (ip->back->opcode != op_and
			&& ip->back->opcode != op_or
			&& ip->back->opcode != op_xor
			)
			break;
		if (ip->fwd->opcode != op_com)
			break;
		if (ip->fwd->oper2->mode != am_reg)
			break;
		if (ip->back->oper1->preg != ip->fwd->oper2->preg)
			break;
		if (ip->fwd->opcode != op_com)
			break;
		switch (ip->back->opcode) {
		case op_and:
			ip->back->opcode = op_nand;
			ip->back->insn = GetInsn(op_nand);
			ip->back->oper1->preg = ip->fwd->oper1->preg;
			MarkRemove(ip->fwd);
			optimized++;
			break;
		case op_or:
			ip->back->opcode = op_nor;
			ip->back->insn = GetInsn(op_nor);
			ip->back->oper1->preg = ip->fwd->oper1->preg;
			MarkRemove(ip->fwd);
			optimized++;
			break;
		case op_xor:
			ip->back->opcode = op_xnor;
			ip->back->insn = GetInsn(op_xnor);
			ip->back->oper1->preg = ip->fwd->oper1->preg;
			MarkRemove(ip->fwd);
			optimized++;
			break;
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
		if (ip->fwd->oper2->mode != am_indx2)
			break;
		if (ip->fwd->oper2->preg == ip->back->oper1->preg) {
			if ((ip->back->opcode == op_shl) && ip->back->oper3->offset &&
				(ip->back->oper3->offset->i == 1
					|| ip->back->oper3->offset->i == 2
					|| ip->back->oper3->offset->i == 3)) {
				ip->fwd->oper2->preg = ip->back->oper2->preg;
				ip->fwd->oper2->scale = 1 << ip->back->oper3->offset->i;
				MarkRemove(ip->back);
				optimized++;
				am = ip->back->oper1;
				fwd = ip->fwd->fwd;
				back = ip->back->back;
				while (back->opcode == op_hint)	// It should be
					back = back->back;
				// We search backwards for another shl related to a forward op to
				// accomodate assignment operations. Assignment operations may
				// generate indexed code like the following:
				//    shl for target
				//    shl for source
				//    load source
				//    store target
				if (fwd->oper2) {
					if ((back->opcode == op_shl) && back->oper3->offset &&
						(am->preg != fwd->oper2->preg && am->preg != fwd->oper2->sreg) &&
						(back->oper3->offset->i == 1
							|| back->oper3->offset->i == 2
							|| back->oper3->offset->i == 3)
						) {
						fwd->oper2->preg = back->oper2->preg;
						fwd->oper2->scale = 1 << back->oper3->offset->i;
						MarkRemove(back);
						optimized++;
					}
				}
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

static void Swap(OCODE *ip1, OCODE *ip2)
{
	OCODE *ip1b = ip1->back, *ip1f = ip1->fwd;
	OCODE *ip2b = ip2->back, *ip2f = ip2->fwd;
	ip1b->fwd = ip2;
	ip2f->back = ip1;
	ip1->fwd = ip2f;
	ip1->back = ip2;
	ip2->fwd = ip1;
	ip2->back = ip1b;
}

static void PeepoptSh(OCODE *ip)
{
	if (ip->back && (ip->back->opcode==op_bfextu || ip->back->opcode==op_bfext)) {
		if (ip->back->oper1->preg==ip->oper1->preg) {
			if (ip->back->oper3->offset->i == 0 && ip->back->oper4->offset->i==31) {
				Swap(ip->back,ip);
			}
		}
	}
}

static void PeepoptStore(OCODE *ip)
{
	if (ip->opcode==op_sh)
		PeepoptSh(ip);
	if (ip->opcode==op_label || ip->fwd->opcode==op_label)
		return;
	if (!OCODE::IsEqualOperand(ip->oper1, ip->fwd->oper1))
		return;
	if (!OCODE::IsEqualOperand(ip->oper2, ip->fwd->oper2))
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

static void PeepoptAnd(OCODE *ip)
{
	// This doesn't work properly yet in all cases.
	if (ip->oper1 && ip->oper2 && ip->oper3) {
		if (ip->oper1->mode==am_reg && ip->oper2->mode==am_reg && ip->oper3->mode == am_imm) {
			if (ip->oper1->preg==ip->oper2->preg && ip->oper3->offset->i==-1) {
				MarkRemove(ip);
				optimized++;
			}
		}
	}
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
	OCODE *ip;

	for (ip = peep_head; ip != NULL; ip = ip->fwd)
	{
		if (ip->opcode != op_label && ip->opcode!=op_nop
			&& ip->opcode != op_link && ip->opcode != op_unlk) {
			if (ip->oper1) {
				if (ip->oper1->preg==regFP || ip->oper1->sreg==regFP)
					refBP++;
			}
			if (ip->oper2) {
				if (ip->oper2->preg==regFP || ip->oper2->sreg==regFP)
					refBP++;
			}
			if (ip->oper3) {
				if (ip->oper3->preg==regFP || ip->oper3->sreg==regFP)
					refBP++;
			}
			if (ip->oper4) {
				if (ip->oper4->preg==regFP || ip->oper4->sreg==regFP)
					refBP++;
			}
		}
	}
	return (refBP);
}

void MarkRemove(OCODE *ip)
{
	ip->remove = true;
}

void MarkRemove2(OCODE *ip)
{
	ip->remove2 = true;
}

static void MarkAllKeep()
{
	OCODE *ip;

	for (ip = peep_head; ip != NULL; ip = ip->fwd )
	{
		ip->remove = false;
	}
}

void Remove()
{
	OCODE *ip, *ip1, *ip2;

	if (RemoveEnabled)
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

void IRemove()
{
	Remove();
}

static void Remove2()
{
	OCODE *ip, *ip1, *ip2;

	if (RemoveEnabled)
	for (ip = peep_head; ip; ip = ip1) {
		ip1 = ip->fwd;
		ip2 = ip->back;
		if (ip->remove2) {
			if (ip1 && ip1->comment==nullptr)
				ip1->comment = ip->comment;
			if (ip2)
				ip2->fwd = ip1;
			if (ip1)
				ip1->back = ip2;
		}
	}
}

static void RemoveDoubleTargets(OCODE *ip)
{
	OCODE *ip2;
	int rg1, rg2, rg3, rg4;

	if (!ip->HasTargetReg())
		return;
	for (ip2 = ip->fwd; ip2 && (ip2->opcode==op_rem || ip2->opcode==op_hint); ip2 = ip2->fwd);
	if (ip2==nullptr)
		return;
	if (!ip2->HasTargetReg())
		return;
	ip2->GetTargetReg(&rg1, &rg2);
	ip->GetTargetReg(&rg3, &rg4);
	// Should look at this more carefully sometime. Generally however target 
	// register classes won't match between integer and float instructions.
	if (ip->insn->regclass1 != ip2->insn->regclass1)
		return;
	if (rg1 != rg3)
		return;
	if (ip2->HasSourceReg(rg3))
		return;
	if (rg3==regSP)
		return;
	MarkRemove(ip);
	optimized++;
}


// Remove stack linkage code for when there are no references to the base 
// pointer.

static void RemoveLinkUnlink()
{
	OCODE *ip;

	for (ip = peep_head; ip != NULL; ip = ip->fwd)
	{
		if (ip->opcode==op_link || ip->opcode==op_unlk) {
			MarkRemove(ip);
		}
	}
}

static void RemoveCompilerHints()
{
	OCODE *ip;

    for(ip = peep_head; ip != NULL; ip = ip->fwd)
    {
        if (ip->opcode==op_hint) {
			MarkRemove(ip);
		}
	}
}


// Potentially any called routine could throw an exception. So call
// instructions could act like branches to the default catch tacked
// onto the end of a subroutine. This is important to prevent the
// default catch from being optimized away. It's possible that there's
// no other way to reach the catch.
// A bex instruction, which isn't a real instruction, is added to the
// instruction stream so that links are created in the CFG to the
// catch handlers. At a later stage of the compile all the bex
// instructions are removed, since they were there only to aid in
// compiler optimizations.

static void RemoveCompilerHints2()
{
	OCODE *ip;

    for(ip = peep_head; ip != NULL; ip = ip->fwd)
    {
		if (ip->opcode==op_bex)
			MarkRemove(ip);
	}
	Remove();
}

//
//      peephole optimizer. This routine calls the instruction
//      specific optimization routines above for each instruction
//      in the peep list.
//
static void opt_peep()
{  
	OCODE *ip;
	int rep;
	
	PrintPeepList();
	// Move the return code pointer past the label which may be removed by
	// optimization.
	if (currentFn->rcode)
		currentFn->rcode = currentFn->rcode->fwd;

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
			PeepOpt::SetLabelReference();
			PeepOpt::EliminateUnreferencedLabels();
			Remove();
			//MarkAllKeep();
			for (ip = peep_head; ip != NULL; ip = ip->fwd )
			{
				if (!ip->remove) {
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
				case op_mov:
					ip->OptMove();
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
				case op_brk:
				case op_jmp:
				case op_ret:
				case op_rts:
				case op_rte:
				case op_rtd:
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
				case op_redor:
					ip->OptRedor();
					break;
				}
				}
			}
			Remove();
			
			for (ip = peep_head; ip != NULL; ip = ip->fwd )
				RemoveDoubleTargets(ip);
			Remove();
			
		}
		//PeepoptSubSP();

		// Remove the link and unlink instructions if no references
		// to BP.
		if (CountBPReferences()==0)
			RemoveLinkUnlink();
		Remove();
	}

	// Get rid of extra labels that clutter up the output
	PeepOpt::SetLabelReference();
	PeepOpt::EliminateUnreferencedLabels();

	// Remove all the compiler hints that didn't work out.
	RemoveCompilerHints();
	Remove();

	currentFn->RootBlock = BasicBlock::Blockize(peep_head);
	dfs.printf("<PeepList:1>\n");
	PrintPeepList();
	dfs.printf("</PeepList:1>\n");
	forest.func = currentFn;
//	RootBlock->ExpandReturnBlocks();
	CFG::Create();

	RemoveMoves();
	currentFn->ComputeLiveVars();
	MarkAllKeep();
	
	currentFn->DumpLiveVars();
	currentFn->CreateVars();
	Var::CreateForests();
	Var::DumpForests(0);
	CFG::CalcDominanceFrontiers();
	CFG::InsertPhiInsns();
	RemoveCompilerHints2();
	CFG::Rename();
	count = 0;
	forest.pass = 0;
	do {
		forest.pass++;
		if (!opt_vreg)
			return;
		forest.Renumber();
		BasicBlock::ComputeSpillCosts();
		RemoveCode();
		iGraph.frst = &forest;
		iGraph.BuildAndCoalesce();
		iGraph.Print(3);
		forest.Simplify();
		iGraph.Print(4);
		forest.Select();
		Var::DumpForests(1);
		forest.SpillCode();
	} while (!forest.IsAllTreesColored() && forest.pass < 32);
	dfs.printf("Loops for color graphing allocator: %d\n", forest.pass);

	// Substitute real registers for virtual ones.
	BasicBlock::ColorAll();
	if (count == 2) {
		dfs.printf("Register allocator max loops.\n");
	}
	Var::DumpForests(2);
	//DumpLiveRegs();

	dfs.printf("<PeepList:2>\n");
	PrintPeepList();
	dfs.printf("</PeepList:2>\n");
}

// Remove move instructions which will create false interferences.
// The move instructions are just marked for removal so they aren't
// considered during live variable computation. They are unmarked
// later, but may be subsequently removed if ranges are coalesced.

void RemoveMoves()
{
	OCODE *ip;
	int reg1, reg2;
	bool foundMove;
	foundMove = false;

	for (ip = peep_head; ip; ip = ip->fwd) {
		if (ip->opcode==op_mov) {
			foundMove = true;
			if (ip->oper1 && ip->oper2) {
				reg1 = ip->oper1->preg;
				reg2 = ip->oper2->preg;
				// Registers used as register parameters cannot be coalesced.
				if (IsArgumentReg(reg1) || IsArgumentReg(reg2))
					continue;
				// Remove the move instruction
				MarkRemove(ip);
			}
		}
	}
	if (!foundMove)
		dfs.printf("No move instruction joins live ranges.\n");
}

// Remove useless code where there are no output links from the basic block.

void RemoveCode()
{
	int nn,mm;
	Var *v;
	Tree *t;
	OCODE *p;
	int count;
	int rg1, rg2;

	count = 0;
	//printf((char *)currentFn->name->c_str());
	//printf("\r\n");
	for (v = currentFn->varlist; v; v = v->next) {
		if (IsCalleeSave(v->num))
			continue;
		if (v->num < 5 || v->num==regLR || v->num==regXLR)
			continue;
		for (mm = 0; mm < v->trees.treecount; mm++) {
			t = v->trees.trees[mm];
			nn = t->blocks->lastMember();
			do {
				for (p = basicBlocks[nn]->lcode; p && !p->leader; p = p->back) {
					if (p->opcode==op_label)
						continue;
					if (p->opcode==op_ret)
						continue;
					p->GetTargetReg(&rg1, &rg2);
					if (rg1 == v->num && rg2==0) {
						if (p->bb->ohead==nullptr) {
							MarkRemove2(p);
							count++;
						}
					}
					if (!p->remove && p->HasSourceReg(v->num))
						goto j1;
				}
			} while((nn = t->blocks->prevMember()) >= 0);
j1:	;
		}
		//Remove2();
	}
	dfs.printf("<CodeRemove>%d</CodeRemove>\n", count);
}


void PrintPeepList()
{
	OCODE *ip;
	Instruction *insn;

	return;
	for (ip = peep_head; ip; ip = ip->fwd) {
		if (ip == currentFn->rcode)
			dfs.printf("***rcode***");
		insn = GetInsn(ip->opcode);
		if (insn)
			dfs.printf("%s ", insn->mnem);
		else if (ip->opcode == op_label)
			dfs.printf("%s%d:", (char *)ip->oper2, (int)ip->oper1);
		else
			dfs.printf("op(%d)", ip->opcode);
		if (ip->bb)
			dfs.printf("bb:%d\n", ip->bb->num);
		else
			dfs.printf("bb nul\n");
	}
}

