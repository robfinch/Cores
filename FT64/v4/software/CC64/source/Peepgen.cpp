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
static void Remove();
void MarkRemove(OCODE *ip);
void peep_add(OCODE *ip);
static void PeepoptSub(OCODE *ip);
void peep_move(OCODE	*ip);
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
void Renumber();
bool RemoveEnabled = true;
extern BasicBlock *basicBlocks[10000];
unsigned int ArgRegCount;

OCODE    *peep_head = NULL,
                *peep_tail = NULL;

extern Var *varlist;
extern BasicBlock *RootBlock;
extern BasicBlock *LastBlock;

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
	OCODE *cd;
	cd = (OCODE *)allocx(sizeof(OCODE));
	cd->predop = pop;
	cd->pregreg = pr;
	cd->insn = GetInsn(op);
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
	OCODE *cd;
	dfs.printf("A");
	cd = (OCODE *)allocx(sizeof(OCODE));
	dfs.printf("B");
	cd->predop = 1;
	cd->pregreg = 15;
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

void GenerateMonadic(int op, int len, AMODE *ap1)
{
	dfs.printf("Enter GenerateMonadic\r\n");
	OCODE *cd;
	dfs.printf("A");
	cd = (OCODE *)allocx(sizeof(OCODE));
	dfs.printf("B");
	cd->predop = 1;
	cd->pregreg = 15;
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = copy_addr(ap1);
	cd->oper1->isTarget = 1;
	dfs.printf("C");
	cd->oper2 = NULL;
	cd->oper3 = NULL;
	cd->oper4 = NULL;
	dfs.printf("D");
	cd->loop_depth = looplevel;
	AddToPeepList(cd);
	dfs.printf("Leave GenerateMonadic\r\n");
}

// NT = no target register
void GenerateMonadicNT(int op, int len, AMODE *ap1)
{
	dfs.printf("Enter GenerateMonadic\r\n");
	OCODE *cd;
	dfs.printf("A");
	cd = (OCODE *)allocx(sizeof(OCODE));
	dfs.printf("B");
	cd->predop = 1;
	cd->pregreg = 15;
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = copy_addr(ap1);
	dfs.printf("C");
	cd->oper2 = NULL;
	cd->oper3 = NULL;
	cd->oper4 = NULL;
	dfs.printf("D");
	cd->loop_depth = looplevel;
	AddToPeepList(cd);
	dfs.printf("Leave GenerateMonadic\r\n");
}

void GeneratePredicatedDiadic(int pop, int pr, int op, int len, AMODE *ap1, AMODE *ap2)
{
	OCODE *cd;
	cd = (OCODE *)allocx(sizeof(OCODE));
	cd->predop = pop;
	cd->pregreg = pr;
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = copy_addr(ap1);
	cd->oper2 = copy_addr(ap2);
	cd->oper3 = NULL;
	cd->oper4 = NULL;
	currentFn->UsesPredicate = TRUE;
	cd->loop_depth = looplevel;
	AddToPeepList(cd);
}

void GenerateDiadic(int op, int len, AMODE *ap1, AMODE *ap2)
{
	OCODE *cd;
	cd = (OCODE *)xalloc(sizeof(OCODE));
	cd->predop = 1;
	cd->pregreg = 15;
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = copy_addr(ap1);
	cd->oper1->isTarget = 1;
	cd->oper2 = copy_addr(ap2);
	if (ap2) {
		if (ap2->mode == am_ind || ap2->mode==am_indx) {
			if (ap2->preg==regSP || ap2->preg==regFP)
				cd->opcode |= op_ss;
		}
	}
	cd->oper3 = NULL;
	cd->oper4 = NULL;
	cd->loop_depth = looplevel;
	AddToPeepList(cd);
}

// Generate diadic without a target register.
void GenerateDiadicNT(int op, int len, AMODE *ap1, AMODE *ap2)
{
	OCODE *cd;
	cd = (OCODE *)xalloc(sizeof(OCODE));
	cd->predop = 1;
	cd->pregreg = 15;
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = copy_addr(ap1);
	cd->oper2 = copy_addr(ap2);
	if (ap2) {
		if (ap2->mode == am_ind || ap2->mode==am_indx) {
			if (ap2->preg==regSP || ap2->preg==regFP)
				cd->opcode |= op_ss;
		}
	}
	cd->oper3 = NULL;
	cd->oper4 = NULL;
	cd->loop_depth = looplevel;
	AddToPeepList(cd);
}

void GenerateTriadic(int op, int len, AMODE *ap1, AMODE *ap2, AMODE *ap3)
{
	OCODE    *cd;
	cd = (OCODE *)allocx(sizeof(OCODE));
	cd->predop = 1;
	cd->pregreg = 15;
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = copy_addr(ap1);
	cd->oper1->isTarget = 1;
	cd->oper2 = copy_addr(ap2);
	cd->oper3 = copy_addr(ap3);
	cd->oper4 = NULL;
	cd->loop_depth = looplevel;
	AddToPeepList(cd);
}

void GenerateTriadicNT(int op, int len, AMODE *ap1, AMODE *ap2, AMODE *ap3)
{
	OCODE    *cd;
	cd = (OCODE *)allocx(sizeof(OCODE));
	cd->predop = 1;
	cd->pregreg = 15;
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = copy_addr(ap1);
	cd->oper2 = copy_addr(ap2);
	cd->oper3 = copy_addr(ap3);
	cd->oper4 = NULL;
	cd->loop_depth = looplevel;
	AddToPeepList(cd);
}

void Generate4adic(int op, int len, AMODE *ap1, AMODE *ap2, AMODE *ap3, AMODE *ap4)
{
	OCODE *cd;
	cd = (OCODE *)allocx(sizeof(OCODE));
	cd->predop = 1;
	cd->pregreg = 15;
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = copy_addr(ap1);
	cd->oper1->isTarget = true;
	cd->oper2 = copy_addr(ap2);
	cd->oper3 = copy_addr(ap3);
	cd->oper4 = copy_addr(ap4);
	cd->loop_depth = looplevel;
	AddToPeepList(cd);
}

void Generate4adicNT(int op, int len, AMODE *ap1, AMODE *ap2, AMODE *ap3, AMODE *ap4)
{
	OCODE *cd;
	cd = (OCODE *)allocx(sizeof(OCODE));
	cd->predop = 1;
	cd->pregreg = 15;
	cd->insn = GetInsn(op);
	cd->opcode = op;
	cd->length = len;
	cd->oper1 = copy_addr(ap1);
	cd->oper2 = copy_addr(ap2);
	cd->oper3 = copy_addr(ap3);
	cd->oper4 = copy_addr(ap4);
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
	AddToPeepList(newl);
}


// Detect references to labels
// Potential looping is N^2 although the inner loop is aborted as soon as a
// reference is found. It's a good thing functions are small and without
// too many lables.

static void SetLabelReference()
{
	OCODE *p, *q;
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
	OCODE *p;

	for (p = peep_head; p; p = p->fwd) {
		if (p->opcode==op_label)
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

void peep_move(OCODE *ip)
{
	if (equal_address(ip->oper1, ip->oper2)) {
		MarkRemove(ip);
		optimized++;
		return;
	}
}

/*
 *      compare two address nodes and return true if they are
 *      equivalent.
 */
int equal_address(AMODE *ap1, AMODE *ap2)
{
	if( ap1 == NULL || ap2 == NULL )
		return (FALSE);
	if( ap1->mode != ap2->mode  && !((ap1->mode==am_ind && ap2->mode==am_indx) || (ap1->mode==am_indx && ap2->mode==am_ind)))
		return (FALSE);
	switch( ap1->mode )
	{
	case am_immed:
		return (ap1->offset->i == ap2->offset->i);
	case am_fpreg:
	case am_reg:
		return (ap1->preg == ap2->preg);
	case am_ind:
	case am_indx:
		if (ap1->preg != ap2->preg)
			return (FALSE);
		if (ap1->offset == ap2->offset)
			return (TRUE);
		if (ap1->offset == NULL || ap2->offset==NULL)
			return (FALSE);
		if (ap1->offset->i != ap2->offset->i)
			return (FALSE);
		return (TRUE);
	}
	return (FALSE);
}

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
static void PeepoptSub(OCODE *ip)
{  
	return;
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

static bool IsSubiSP(OCODE *ip)
{
	if (ip->opcode==op_sub) {
		if (ip->oper3->mode==am_immed) {
			if (ip->oper1->preg==regSP && ip->oper2->preg==regSP) {
				return (true);
			}
		}
	}
	return (false);
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

static bool IsFlowControl(OCODE *ip)
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
		ip->opcode==op_bgeui ||
		ip->opcode==op_beqi ||
		ip->opcode==op_bbs ||
		ip->opcode==op_bbc
		)
		return (true);
	return (false);
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
  ip->oper1 = copy_addr(ip->oper2);
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
    ip->oper1 = copy_addr(ip->oper2);
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
    ip->oper1 = copy_addr(ip->oper2);
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

void peep_ld(OCODE *ip)
{
	if (ip->oper2->mode != am_immed)
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
	if (ip->fwd->oper3->mode != am_immed)
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
		if (ip->fwd && ip->fwd->opcode != op_mov) {
			MarkRemove(ip);
			optimized++;
			return;
		}
		
		if (ip->fwd && ip->fwd->oper1->preg >= 18 && ip->fwd->oper1->preg < 24) {
			if (equal_address(ip->fwd->oper2, ip->back->oper1)) {
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
			if (ip->back->HasTargetReg()) {
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
		if (ip->fwd->oper2->mode != am_indx2)
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

static void PeepoptAnd(OCODE *ip)
{
	// This doesn't work properly yet in all cases.
	if (ip->oper1 && ip->oper2 && ip->oper3) {
		if (ip->oper1->mode==am_reg && ip->oper2->mode==am_reg && ip->oper3->mode == am_immed) {
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

void Peep::InsertBefore(OCODE *an, OCODE *cd)
{
	cd->fwd = an;
	cd->back = an->back;
	if (an->back)
		an->back->fwd = cd;
	an->back = cd;
}

void Peep::InsertAfter(OCODE *an, OCODE *cd)
{
	cd->fwd = an->fwd;
	cd->back = an;
	if (an->fwd)
		an->fwd->back = cd;
	an->fwd = cd;
}

static void Remove()
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

	if (!ip->HasTargetReg())
		return;
	for (ip2 = ip->fwd; ip2 && (ip2->opcode==op_rem || ip2->opcode==op_hint); ip2 = ip2->fwd);
	if (ip2==nullptr)
		return;
	if (!ip2->HasTargetReg())
		return;
	if (ip2->GetTargetReg() != ip->GetTargetReg())
		return;
	if (ip2->HasSourceReg(ip->GetTargetReg()))
		return;
	if (ip->GetTargetReg()==regSP)
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
	SetLabelReference();
	EliminateUnreferencedLabels();
	Remove();

	// Remove all the compiler hints that didn't work out.
	RemoveCompilerHints();
	Remove();

	RootBlock = BasicBlock::Blockize(peep_head);
	CFG::Create();
	RemoveMoves();
	ComputeLiveVars();
	MarkAllKeep();
	DumpLiveVars();
	CreateVars();
	Var::CreateForests();
	Var::DumpForests();
	CFG::CalcDominanceFrontiers();
	CFG::InsertPhiInsns();
	RemoveCompilerHints2();
	CFG::Rename();
	Renumber();
	ComputeSpillCosts();
	//RemoveCode();
	Coalesce();
	Var::DumpForests();
	//DumpLiveRegs();
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

void CreateVars()
{
	BasicBlock *b;
	int nn;
	int num;

	varlist = nullptr;
	for (b = RootBlock; b; b = b->next) {
		b->LiveOut->resetPtr();
		for (nn = 0; nn < b->LiveOut->NumMember(); nn++) {
			num = b->LiveOut->nextMember();
			Var::Find(num);
		}
	}
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
			reg1 = ip->oper1->preg;
			reg2 = ip->oper2->preg;
			// Registers used as register parameters cannot be coalesced.
			if (IsArgumentReg(reg1) || IsArgumentReg(reg2))
				continue;
			// Remove the move instruction
			MarkRemove(ip);
		}
	}
	if (!foundMove)
		dfs.printf("No move instruction joins live ranges.\n");
}

bool Coalesce()
{
	int reg1, reg2;
	Var *v1, *v2, *v3;
	Var *p, *q;
	Tree *t, *t1, *u;
	bool foundSameTree;
	bool improved;

	improved = false;
	for (p = varlist; p; p = p->next) {
		for (q = varlist; q; q = q->next) {
			if (p==q)
				continue;
			reg1 = p->num;
			reg2 = q->num;
			// Registers used as register parameters cannot be coalesced.
			if ((reg1 >= 18 && reg1 <= 24)
				|| (reg2 >= 18 && reg2 <= 24))
				continue;
			// Coalesce the live ranges of the two variables into a single
			// range.
			//dfs.printf("Testing coalescence of live range r%d with ", reg1);
			//dfs.printf("r%d \n", reg2);
			if (p->cnum)
				v1 = Var::Find2(p->cnum);
			else
				v1 = p;
			if (q->cnum)
				v2 = Var::Find2(q->cnum);
			else
				v2 = q;
			if (v1==nullptr || v2==nullptr)
				continue;
			// Live ranges cannot be coalesced unless they are disjoint.
			if (!v1->forest->isDisjoint(*v2->forest)) {
				//dfs.printf("Live ranges overlap - no coalescence possible\n");
				continue;
			}
			
			dfs.printf("Coalescing live range r%d with ", reg1);
			dfs.printf("r%d \n", reg2);
			improved = true;
			if (v1->trees==nullptr) {
				v3 = v1;
				v1 = v2;
				v2 = v3;
			}
			
			for (t = v2->trees; t; t = t1) {
				t1 = t->next;
				foundSameTree = false;
				for (u = v1->trees; u; u = u->next) {
					if (t->tree->NumMember() >= u->tree->NumMember()) {
						if (t->tree->isSubset(*u->tree)) {
							u->tree->add(t->tree);
							v1->forest->add(t->tree);
							foundSameTree = true;
							break;
						}
					}
					else {
						if (u->tree->isSubset(*t->tree)) {
							foundSameTree = true;
							t->tree->add(u->tree);
							v2->forest->add(u->tree);
							break;
						}
					}
				}
				
				if (!foundSameTree) {
					t->next = v1->trees;
					v1->trees = t;
					v1->forest->add(v2->forest);
				}
				
			}
			
			v2->trees = nullptr;
			v2->forest->clear();
			v2->cnum = v1->num;
		}
	}
	return (improved);
}

static void UpdateLive(BasicBlock *b, OCODE *ip)
{
	int r;

	r = ip->oper1->lrpreg;
	if (b->NeedLoad->isMember(r)) {
		b->NeedLoad->remove(r);
		if (!b->MustSpill->isMember(r)) {
			alltrees[r]->infinite = true;
		}
	}
	alltrees[r]->stores += b->depth;
	b->live->remove(r);
}

static void CheckForDeaths(BasicBlock *b, int r)
{
	int m;

	if (!b->live->isMember(r)) {
		b->NeedLoad->resetPtr();
		for (m = b->NeedLoad->nextMember(); m >= 0; m = b->NeedLoad->nextMember()) {
			alltrees[m]->loads += b->depth;
			b->MustSpill->add(m);
		}
		b->NeedLoad->clear();
	}
}

void ComputeSpillCosts()
{
	BasicBlock *b;
	OCODE *ip;
	Instruction *i;
	int r;
	bool endLoop;

	for (r = 0; r < Tree::treecount; r++) {
		alltrees[r]->loads = 0.0;
		alltrees[r]->stores = 0.0;
		alltrees[r]->copies = 0.0;
		alltrees[r]->infinite = false;
	}

	for (b = RootBlock; b; b = b->next) {
		b->NeedLoad->clear();
		// build the set live from b->liveout
		b->live = b->LiveOut;
		b->MustSpill = b->live;
		endLoop = false;
		for (ip = b->lcode; ip && !endLoop; ip = ip->back) {
			if (ip->opcode==op_label)
				continue;
			i = ip->insn;
			// examine instruction i updating sets and accumulating costs
			if (i->HasTarget) {
				UpdateLive(b, ip);
			}
			// This is a loop in the Briggs thesis, but we only allow 4 operands
			// so the loop is unrolled.
			if (ip->oper1) {
				if (!ip->oper1->isTarget) {
					r = ip->oper1->lrpreg;
					CheckForDeaths(b, r);
					if (r = ip->oper1->lrsreg)	// '=' is correct
						CheckForDeaths(b,r);
				}
			}
			if (ip->oper2) {
				r = ip->oper1->lrpreg;
				CheckForDeaths(b, r);
				if (r = ip->oper1->lrsreg)
					CheckForDeaths(b,r);
			}
			if (ip->oper3) {
				r = ip->oper1->lrpreg;
				CheckForDeaths(b, r);
				if (r = ip->oper1->lrsreg)
					CheckForDeaths(b,r);
			}
			if (ip->oper4) {
				r = ip->oper1->lrpreg;
				CheckForDeaths(b, r);
				if (r = ip->oper1->lrsreg)
					CheckForDeaths(b,r);
			}
			// Re-examine uses to update live and needload
			if (ip->oper1 && !ip->oper1->isTarget) {
				b->live->add(ip->oper1->lrpreg);
				b->NeedLoad->add(ip->oper1->lrpreg);
				if (ip->oper1->lrsreg) {
					b->live->add(ip->oper1->lrsreg);
					b->NeedLoad->add(ip->oper1->lrsreg);
				}
			}
			if (ip->oper2) {
				b->live->add(ip->oper2->lrpreg);
				b->NeedLoad->add(ip->oper2->lrpreg);
				if (ip->oper2->lrsreg) {
					b->live->add(ip->oper2->lrsreg);
					b->NeedLoad->add(ip->oper2->lrsreg);
				}
			}
			if (ip->oper3) {
				b->live->add(ip->oper3->lrpreg);
				b->NeedLoad->add(ip->oper3->lrpreg);
				if (ip->oper3->sreg) {
					b->live->add(ip->oper3->lrsreg);
					b->NeedLoad->add(ip->oper3->lrsreg);
				}
			}
			if (ip->oper4) {
				b->live->add(ip->oper4->lrpreg);
				b->NeedLoad->add(ip->oper4->lrpreg);
				if (ip->oper4->sreg) {
					b->live->add(ip->oper4->lrsreg);
					b->NeedLoad->add(ip->oper4->lrsreg);
				}
			}
			if (ip==b->code)
				endLoop = true;
		}
		b->NeedLoad->resetPtr();
		for (r = b->NeedLoad->nextMember(); r >= 0; r = b->NeedLoad->nextMember()) {
			alltrees[r]->loads += b->depth;
		}
	}

	// Summarize costs
	dfs.printf("<TreeCosts>\n");
	for (r = 0; r < Tree::treecount; r++) {
		// If alltrees[r].lattice = BOT
		alltrees[r]->cost = 2.0f * (alltrees[r]->loads + alltrees[r]->stores);
		// else
		// alltrees[r]->cost = alltrees[r]->loads - alltrees[r]->stores;
		alltrees[r]->cost -= alltrees[r]->copies;
		dfs.printf("Tree:%d ", r);
		dfs.printf("cost = %d\n", (int)alltrees[r]->cost);
	}
	dfs.printf("</TreeCosts>\n");
}

// Renumber the registers according to the tree (live range) numbers.
static void Renumber()
{
	OCODE *ip;
	Tree *t;
	int tt;
	BasicBlock *b;
	int bb;
	bool eol;

	for (tt = 0; tt < Tree::treecount; tt++) {
		t = alltrees[tt];
		t->tree->resetPtr();
		for (bb = t->tree->nextMember(); bb >= 0; bb = t->tree->nextMember()) {
			b = basicBlocks[bb];
			eol = false;
			for (ip = b->code; ip && !eol; ip = ip->fwd) {
				if (ip->opcode==op_label)
					continue;
				if (ip->oper1 && ip->oper1->preg == t->var)
					ip->oper1->lrpreg = t->num;
				if (ip->oper1 && ip->oper1->sreg == t->var)
					ip->oper1->lrsreg = t->num;
				if (ip->oper2 && ip->oper2->preg==t->var)
					ip->oper2->lrpreg = t->num;
				if (ip->oper2 && ip->oper2->sreg==t->var)
					ip->oper2->lrsreg = t->num;
				if (ip->oper3 && ip->oper3->preg==t->var)
					ip->oper3->lrpreg = t->num;
				if (ip->oper3 && ip->oper3->sreg==t->var)
					ip->oper3->lrsreg = t->num;
				if (ip->oper4 && ip->oper4->preg==t->var)
					ip->oper4->lrpreg = t->num;
				if (ip->oper4 && ip->oper4->sreg==t->var)
					ip->oper4->lrsreg = t->num;
				if (ip==b->lcode)
					eol = true;
			}
		}
	}
}

void RemoveCode()
{
	int nn;
	Var *v;
	Tree *t;
	OCODE *p;
	int count;

	count = 0;
	//printf((char *)currentFn->name->c_str());
	//printf("\r\n");
	for (v = varlist; v; v = v->next) {
		if (IsCalleeSave(v->num))
			continue;
		if (v->num==0 || v->num==regLR || v->num==regXLR)
			continue;
		for (t = v->trees; t; t = t->next) {
			nn = t->tree->lastMember();
			do {
				for (p = basicBlocks[nn]->lcode; p && !p->leader; p = p->back) {
					if (p->opcode==op_label)
						continue;
					if (p->opcode==op_ret)
						continue;
					if (p->GetTargetReg() == v->num) {
						if (p->bb->ohead==nullptr) {
							MarkRemove2(p);
							count++;
						}
					}
					if (!p->remove && p->HasSourceReg(v->num))
						goto j1;
				}
			} while((nn = t->tree->prevMember()) >= 0);
j1:	;
		}
		Remove2();
	}
	dfs.printf("<CodeRemove>%d</CodeRemove>\n", count);
}

/*
void BuildLivesetFromLiveout(BasicBlock *b)
{
	int m;

	b->live->clear();
	b->LiveOut->resetPtr();
	for (m = b->LiveOut->nextMember(); m >= 0; m = b->LiveOut->nextMember()) {
		// Find the live range assoicated with value m
		b->live->add();
	}
}

void Stage2()
{
	int bms;
	int *bitmatrix;
	int i, j;
	int bitndx, intndx;
	BasicBlock *b;
	OCODE *ip;
	bool eol;

	bms = Tree::treecount * Tree::treecount / sizeof(int);
	bitmatrix = new int[bms];
	ZeroMemory(bitmatrix, bms);
	bitndx = i + (j * j) / 2;
	intndx = bitndx / sizeof(int);
	bitndx %= (sizeof(int) * 8);

	// For each block 
	for (b = RootBlock; b; b = b->next) {
		BuildLivesetFromLiveout(b);
		eol = false;
		for (ip = b->lcode; ip && !eol; ip = ip->back) {
			// examine instruction ip and update graph and live
			if (ip->opcode==op_mov) {
				b->live->remove();
			}
			igraph->AddEdges(b->live,);
			b->live->remove();
			if (ip->oper1)
			b->live->add();
			eol = ip==b->lcode;
		}
	}

	delete bitmatrix;
}
*/