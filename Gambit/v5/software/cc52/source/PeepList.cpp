// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
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
// Methods that operate on the entire peep list.
// ============================================================================
//
#include "stdafx.h"
extern int optimized;
extern OCODE *LabelTable[50000];
extern void opt_peep();

OCODE *PeepList::FindLabel(int64_t i)
{
	if (i >= 50000 || i < 0)
		return (nullptr);
	return (LabelTable[i]);
}


// Count the length of the peep list from the current position to the end of
// the list. Used during some code generation optimizations.

int PeepList::Count(OCODE *ip)
{
	int cnt;

	for (cnt = 0; ip && ip != tail; cnt++)
		ip = ip->fwd;
	return (cnt);
}

bool PeepList::HasCall(OCODE *ip)
{
	int cnt;

	for (cnt = 0; ip; ip = ip->fwd) {
		if (ip->opcode == op_call || ip->opcode == op_jal) {
			return (true);
		}
		if (ip == tail)
			break;
	}
	return (false);
}

bool PeepList::FindTarget(OCODE *ip, int reg)
{
	for (; ip; ip = ip->fwd) {
		if (ip->HasTargetReg()) {
			if (ip->opcode == op_call || ip->opcode == op_jal) {
				if (reg == 1 || reg == 2)
					return (true);
			}
			if (ip->oper1->preg == reg)
				return (true);
		}
	}
	//Dump("=====PeepList=====\n");
	return (false);
}

void PeepList::InsertBefore(OCODE *an, OCODE *cd)
{
	cd->fwd = an;
	cd->back = an->back;
	if (an->back)
		an->back->fwd = cd;
	an->back = cd;
}

void PeepList::InsertAfter(OCODE *an, OCODE *cd)
{
	cd->fwd = an->fwd;
	cd->back = an;
	if (an->fwd)
		an->fwd->back = cd;
	an->fwd = cd;
}

void PeepList::Add(OCODE *cd)
{
	if (!dogen)
		return;
	if (cd == nullptr)
		return;
	if (head == NULL)
	{
		ArgRegCount = regFirstArg;
		head = tail = cd;
		cd->fwd = nullptr;
		cd->back = nullptr;
	}
	else
	{
		cd->fwd = nullptr;
		cd->back = tail;
		if (tail)
			tail->fwd = cd;
		tail = cd;
	}
	if (cd->opcode != op_label) {
		if (cd->oper1 && IsArgumentReg(cd->oper1->preg))
			ArgRegCount = max(ArgRegCount, cd->oper1->preg);
		if (cd->oper2 && IsArgumentReg(cd->oper2->preg))
			ArgRegCount = max(ArgRegCount, cd->oper2->preg);
		if (cd->oper3 && IsArgumentReg(cd->oper3->preg))
			ArgRegCount = max(ArgRegCount, cd->oper3->preg);
		if (cd->oper4 && IsArgumentReg(cd->oper4->preg))
			ArgRegCount = max(ArgRegCount, cd->oper4->preg);
	}
}

void PeepList::MarkAllKeep()
{
	OCODE *ip;

	for (ip = head; ip != NULL; ip = ip->fwd)
	{
		ip->remove = false;
	}
}

void PeepList::MarkAllKeep2()
{
	OCODE *ip;

	for (ip = head; ip != NULL; ip = ip->fwd)
	{
		ip->remove2 = false;
	}
}

void PeepList::Remove(OCODE *ip)
{
	OCODE *ip1, *ip2;

	ip1 = ip->fwd;
	ip2 = ip->back;
	if (ip1 && ip1->comment == nullptr)
		ip1->comment = ip->comment;
	if (ip2)
		ip2->fwd = ip1;
	if (ip1)
		ip1->back = ip2;
	if (ip == head)
		head = ip->fwd;
}

void PeepList::Remove()
{
	OCODE *ip, *ip1;

	if (1)//(RemoveEnabled)
		for (ip = head; ip; ip = ip1) {
			ip1 = ip->fwd;
			if (ip->remove)
				Remove(ip);
		}
}

void PeepList::Remove2()
{
	OCODE *ip, *ip1, *ip2;

	if (1)//if (RemoveEnabled)
		for (ip = head; ip; ip = ip1) {
			ip1 = ip->fwd;
			ip2 = ip->back;
			if (ip->remove2) {
				if (ip1 && ip1->comment == nullptr)
					ip1->comment = ip->comment;
				if (ip2)
					ip2->fwd = ip1;
				if (ip1)
					ip1->back = ip2;
				if (ip == head)
					head = ip->fwd;
			}
		}
}



// Detect references to labels

void PeepList::SetLabelReference()
{
	OCODE *p, *q;
	struct clit *ct;
	int nn;

	ZeroMemory(LabelTable, sizeof(LabelTable));
	for (p = head; p; p = p->fwd) {
		if (p->opcode == op_label) {
			LabelTable[(int)p->oper1] = p;
			p->isReferenced = DataLabels[(int)p->oper1];
		}
	}
	for (q = head; q; q = q->fwd) {
		if (q->opcode != op_label && q->opcode != op_nop) {
			if (q->oper1 && (q->oper1->mode == am_direct || q->oper1->mode == am_imm)) {
				if (p = PeepList::FindLabel(q->oper1->offset->i)) {
					p->isReferenced = true;
				}
			}
			if (q->oper2 && (q->oper2->mode == am_direct || q->oper2->mode == am_imm)) {
				if (p = PeepList::FindLabel(q->oper2->offset->i)) {
					p->isReferenced = true;
				}
			}
			if (q->oper3 && (q->oper3->mode == am_direct || q->oper3->mode == am_imm)) {
				if (p = PeepList::FindLabel(q->oper3->offset->i)) {
					p->isReferenced = true;
				}
			}
			if (q->oper4 && (q->oper4->mode == am_direct || q->oper4->mode == am_imm)) {
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


void PeepList::EliminateUnreferencedLabels()
{
	OCODE *p;

	for (p = head; p; p = p->fwd) {
		if (p->opcode == op_label)
			p->remove = false;
		if (p->opcode == op_label && !p->isReferenced) {
			p->MarkRemove();
			optimized++;
		}
	}
}



BasicBlock *PeepList::Blockize()
{
	return (BasicBlock::Blockize(head));
}

int PeepList::CountSPReferences()
{
	int refSP = 0;
	OCODE *ip;
	bool inFuncBody = false;

	for (ip = head; ip != NULL; ip = ip->fwd)
	{
		if (ip->opcode == op_hint && ip->oper1->offset->i == start_funcbody) {
			inFuncBody = true;
			continue;
		}
		if (ip->opcode == op_hint && ip->oper1->offset->i == begin_stack_unlink) {
			inFuncBody = false;
			continue;
		}
		if (ip->opcode == op_hint && ip->oper1->offset->i == end_stack_unlink) {
			inFuncBody = true;
			continue;
		}
		if (!inFuncBody)
			continue;
		if (ip->opcode == op_call || ip->opcode == op_jal) {
			refSP++;
			continue;
		}
		if (ip->opcode != op_label && ip->opcode != op_nop
			&& ip->opcode != op_link && ip->opcode != op_unlk) {
			if (ip->insn) {
				if (ip->insn->opcode != op_add && ip->insn->opcode != op_sub && ip->insn->opcode != op_mov) {
					if (ip->oper1) {
						if (ip->oper1->preg == regSP || ip->oper1->sreg == regSP)
							refSP++;
					}
					if (ip->oper2) {
						if (ip->oper2->preg == regSP || ip->oper2->sreg == regSP)
							refSP++;
					}
					if (ip->oper3) {
						if (ip->oper3->preg == regSP || ip->oper3->sreg == regSP)
							refSP++;
					}
					if (ip->oper4) {
						if (ip->oper4->preg == regSP || ip->oper4->sreg == regSP)
							refSP++;
					}
				}
			}
		}
	}
	return (refSP);
}

// Check for references to the base pointer. If nothing refers to the
// base pointer then the stack linkage instructions can be removed.

int PeepList::CountBPReferences()
{
	int refBP = 0;
	OCODE *ip;
	bool inFuncBody = false;

	for (ip = head; ip != NULL; ip = ip->fwd)
	{
		if (ip->opcode == op_hint && ip->oper1->offset->i == start_funcbody) {
			inFuncBody = true;
			continue;
		}
		if (ip->opcode == op_hint && ip->oper1->offset->i == begin_stack_unlink) {
			inFuncBody = false;
			continue;
		}
		if (ip->opcode == op_hint && ip->oper1->offset->i == end_stack_unlink) {
			inFuncBody = true;
			continue;
		}
		if (!inFuncBody)
			continue;
		if (ip->opcode != op_label && ip->opcode != op_nop
			&& ip->opcode != op_link && ip->opcode != op_unlk) {
			if (ip->oper1) {
				if (ip->oper1->preg == regFP || ip->oper1->sreg == regFP)
					refBP++;
			}
			if (ip->oper2) {
				if (ip->oper2->preg == regFP || ip->oper2->sreg == regFP)
					refBP++;
			}
			if (ip->oper3) {
				if (ip->oper3->preg == regFP || ip->oper3->sreg == regFP)
					refBP++;
			}
			if (ip->oper4) {
				if (ip->oper4->preg == regFP || ip->oper4->sreg == regFP)
					refBP++;
			}
		}
	}
	return (refBP);
}

// Remove stack linkage code for when there are no references to the base 
// pointer.

void PeepList::RemoveLinkUnlink()
{
	OCODE *ip;

	for (ip = head; ip != NULL; ip = ip->fwd)
	{
		if (ip->opcode == op_link || ip->opcode == op_unlk) {
			ip->MarkRemove();
		}
	}
}


// Eliminate branchs to the next line of code.

void PeepList::OptBranchToNext()
{
	OCODE *ip, *pip;

	// Previous ip must be set to something for the first iteration.
	// Use head as it's safe. This avoids an extra if statement in 
	// the loop.
	pip = head;
	for (ip = head; ip != NULL; ip = ip->fwd) {
		if (ip->opcode == op_label) {
			if (pip->opcode == op_br || pip->opcode == op_bra) {
				if ((int64_t)ip->oper1 == pip->oper1->offset->i) {
					pip->MarkRemove();
					optimized++;
				}
			}
		}
		pip = ip;
	}
	Remove();
}


void PeepList::OptDoubleTargetRemoval()
{
	OCODE *ip;

	for (ip = head; ip != NULL; ip = ip->fwd)
		ip->OptDoubleTargetRemoval();
	Remove();
}

// Optimize away the usage of a register containing just an integer constant
// value.

void PeepList::OptConstReg()
{
	OCODE *ip;
	Instruction *insn;
	MachineReg *mr, *mr2;
	Operand *top;
	int n;
	int count = 0;

	for (n = 0; n < nregs; n++) {
		if (regs[n].assigned && !regs[n].modified && regs[n].isConst && regs[n].offset != nullptr)
			regs[n].sub = true;
		else
			regs[n].sub = false;
	}

	for (ip = head; ip; ip = ip->fwd) {
		if (ip->insn) {
			// Swap operands around commutativly for addition and multiplication so
			// that constant is at right.
			if (ip->insn->opcode == op_add || ip->insn->opcode == op_mul || ip->insn->opcode == op_mulu) {
				if (ip->oper2->mode == am_reg) {
					mr = &regs[ip->oper2->preg];
					if (mr->assigned && !mr->modified && mr->isConst && mr->offset != nullptr) {
						top = ip->oper2;
						ip->oper2 = ip->oper3;
						ip->oper3 = top;
					}
				}
			}
			count += ip->oper2->OptRegConst(ip->insn->amclass2, true);
			count += ip->oper3->OptRegConst(ip->insn->amclass3, true);
			count += ip->oper4->OptRegConst(ip->insn->amclass4, true);
		}
	}

	if (count < 4) {
		for (ip = head; ip; ip = ip->fwd) {
			if (ip->insn) {
				ip->oper2->OptRegConst(ip->insn->amclass2, false);
				ip->oper3->OptRegConst(ip->insn->amclass3, false);
				ip->oper4->OptRegConst(ip->insn->amclass4, false);
			}
		}
		// Remove all def's of registers containing a constant
		for (ip = head; ip; ip = ip->fwd) {
			if (ip->insn) {
				if (ip->oper1) {
					for (n = 0; n < nregs; n++) {
						if (ip->oper1->mode == am_reg && ip->oper1->preg == n) {
							if (regs[n].sub && !regs[n].IsArg) {
								ip->MarkRemove();
							}
						}
					}
				}
			}
		}
	}
	Remove();
}


void PeepList::RemoveCompilerHints()
{
	OCODE *ip;

	for (ip = head; ip != NULL; ip = ip->fwd)
	{
		if (ip->opcode == op_hint) {
			ip->MarkRemove();
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

void PeepList::RemoveCompilerHints2()
{
	OCODE *ip;

	for (ip = head; ip != NULL; ip = ip->fwd)
	{
		if (ip->opcode == op_bex)
			ip->MarkRemove();
	}
	Remove();
}

// Remove move instructions which will create false interferences.
// The move instructions are just marked for removal so they aren't
// considered during live variable computation. They are unmarked
// later, but may be subsequently removed if ranges are coalesced.

// A reg might be used after returning from the function. For
// example the stack / frame pointer. So, we just assume there is
// a use without a def. This means moves in the return block are
// excluded from deletion.

void PeepList::RemoveMoves()
{
	OCODE *ip;
	int reg1, reg2;
	bool foundMove;
	foundMove = false;

	for (ip = head; ip; ip = ip->fwd) {
		if (ip->bb->isRetBlock)
			continue;
		if (ip->opcode == op_mov) {
			foundMove = true;
			if (ip->oper1 && ip->oper2) {
				reg1 = ip->oper1->preg;
				reg2 = ip->oper2->preg;
				// Registers used as register parameters cannot be coalesced.
				if (IsArgumentReg(reg1) || IsArgumentReg(reg2))
					continue;
				// Remove the move instruction
				ip->MarkRemove();
			}
		}
	}
	if (!foundMove)
		dfs.printf("No move instruction joins live ranges.\n");
}


// Optimizations dealing with an assortment of instructions.

void PeepList::OptInstructions()
{
	OCODE *ip;

	for (ip = head; ip != NULL; ip = ip->fwd)
	{
		if (!ip->remove) {
			switch (ip->opcode)
			{
			case op_rem:
				if (ip->fwd) {
					ip->fwd->comment = ip;
					ip->MarkRemove();
				}
				break;
			case op_ld:		ip->OptLoad();	break;
			case op_ldi:	ip->OptLdi();	break;
			case op_lea:	ip->OptLea();	break;
			case op_mov:	ip->OptMove();	break;
			case op_add:	ip->OptAdd(); break;
			case op_sub:	ip->OptSubtract(); break;
			case op_ldb:		ip->OptLoadByte(); break;
			case op_ldw:		ip->OptLoadChar(); break;
			case op_ldp:		ip->OptLoadHalf(); break;
			case op_ldh:		ip->OptLoadWord(); break;
			case op_sxb:	ip->OptSxb();	break;
			case op_br:
			case op_bra:	ip->OptBra(); break;
			case op_jal:	ip->OptJAL(); break;
			case op_brk:
			case op_jmp:
			case op_ret:
			case op_rts:
			case op_rte:
			case op_rtd:	ip->OptUctran(); break;
			case op_label:	ip->OptLabel(); break;
			case op_hint:	ip->OptHint(); break;
			case op_stp:
			case op_sth:		ip->OptStore();	break;
			case op_and:	ip->OptAnd(); break;
			case op_redor:	ip->OptRedor();	break;
			case op_mul:	ip->OptMul(); break;
			case op_mulu:	ip->OptMulu(); break;
			case op_div:	ip->OptDiv(); break;
			case op_push:	ip->OptPush(); break;
			case op_zxh:	ip->OptZxh(); break;
			}
		}
	}
}

// Hoist expressions that remain constant to the outside of the loop.
// But don't hoist expressions containing r1 as that is the return
// value from a function call.
// This needs more work:
// An incrementing expression incorrectly hoisted the load word
//		lw       	$v0,48[$fp]
//		sub      	$v0, $v0, #1
//		sw       	$v0, 48[$fp]

void PeepList::OptLoopInvariants(OCODE *loophead)
{
	OCODE *ip2, *ip3, *ip4, *ip5;
	bool canHoist;
	bool hsx;

	return;
	if (loophead == nullptr)
		return;
	ip3 = ip4 = loophead;
	for (ip2 = currentFn->pl.tail; ip2 && ip2 != ip4; ip2 = ip2->back) {
		canHoist = true;
		if (ip2->opcode == op_label || ip2->opcode == op_rem || ip2->opcode == op_hint)
			continue;
		// We don't want to move these outside the loop.
		if (ip2->insn->IsFlowControl())
			canHoist = false;
		// A store operation might be invariant, but stores can have side effects
		// eg. I/O updates.
		//if (ip2->insn) {
		//	if (ip2->insn->IsStore())
		//		canHoist = false;
		//}
		if (!ip2->HasTargetReg()) {
			if (ip2->oper1) {
				switch (ip2->oper1->mode) {
				case am_imm:
				case am_direct:
					break;
				case am_indx2:
					if (currentFn->pl.FindTarget(ip4, ip2->oper1->preg))
						canHoist = false;
					if (currentFn->pl.FindTarget(ip4, ip2->oper1->sreg))
						canHoist = false;
					break;
				default:
					if (currentFn->pl.FindTarget(ip4, ip2->oper1->preg))
						canHoist = false;
					break;
				}
			}
		}
		if (ip2->oper2) {
			switch (ip2->oper2->mode) {
			case am_imm:
			case am_direct:
				break;
			case am_indx2:
				if (currentFn->pl.FindTarget(ip4, ip2->oper2->preg))
					canHoist = false;
				if (currentFn->pl.FindTarget(ip4, ip2->oper2->sreg))
					canHoist = false;
				break;
			default:
				if (currentFn->pl.FindTarget(ip4, ip2->oper2->preg))
					canHoist = false;
				break;
			}
		}
		if (ip2->oper3) {
			switch (ip2->oper3->mode) {
			case am_imm:
			case am_direct:
				break;
			case am_indx2:
				if (currentFn->pl.FindTarget(ip4, ip2->oper3->preg))
					canHoist = false;
				if (currentFn->pl.FindTarget(ip4, ip2->oper3->sreg))
					canHoist = false;
				break;
			default:
				if (currentFn->pl.FindTarget(ip4, ip2->oper3->preg))
					canHoist = false;
				break;
			}
		}
		if (ip2->oper4) {
			switch (ip2->oper4->mode) {
			case am_imm:
			case am_direct:
				break;
			case am_indx2:
				if (currentFn->pl.FindTarget(ip4, ip2->oper4->preg))
					canHoist = false;
				if (currentFn->pl.FindTarget(ip4, ip2->oper4->sreg))
					canHoist = false;
				break;
			default:
				if (currentFn->pl.FindTarget(ip4, ip2->oper4->preg))
					canHoist = false;
				break;
			}
		}
		// Move the code outside of the loop.
		if (canHoist) {
			if (ip2 == currentFn->pl.tail)
				currentFn->pl.tail = ip2->back;
			hsx = false;
			ip5 = ip2->fwd;
			if (ip5) {
				if (ip2->insn->IsIntegerLoad() && ip5->insn->IsExt()) {
					if (ip2->oper1->preg == ip5->oper1->preg)
						hsx = true;
				}
			}
			else
				ip5 = ip2;
			currentFn->pl.Remove(ip2);
			currentFn->pl.InsertAfter(loophead, ip2);
			if (hsx) {
				currentFn->pl.Remove(ip5);
				currentFn->pl.InsertAfter(loophead, ip5);
			}
			ip4 = ip3;
			ip3 = ip5;
		}
	}
}

void PeepList::RemoveReturnBlock()
{
	OCODE *ip;
	bool do_remove = false;

	for (ip = head; ip; ip = ip->fwd) {
		if (ip->opcode == op_hint && ip->oper1->offset->i == begin_return_block) {
			do_remove = true;
			continue;
		}
		if (ip->opcode == op_hint && ip->oper1->offset->i == end_return_block) {
			do_remove = false;
			continue;
		}
		if (ip->opcode == op_hint && ip->oper1->offset->i == begin_stack_unlink) {
			do_remove = true;
			continue;
		}
		if (ip->opcode == op_hint && ip->oper1->offset->i == end_stack_unlink) {
			do_remove = false;
			continue;
		}
		if (ip->opcode == op_label || ip->opcode == op_fnname)
			continue;
		if (do_remove)
			ip->MarkRemove();
		if (ip->oper1 && ip->oper1->mode == am_indx && ip->oper1->preg == regFP) {
			ip->oper1->preg = regSP;
		}
		if (ip->oper2 && ip->oper2->mode == am_indx && ip->oper2->preg == regFP) {
			ip->oper2->preg = regSP;
		}
		if (ip->opcode == op_ret) {
			if (ip->back) {
				if (ip->back->opcode == op_add) {
					if (ip->back->oper1->preg == regSP) {
						ip->back->oper3->offset->i = 0;
						ip->back->MarkRemove();
					}
				}
			}
			if (ip->oper1)
				if (ip->oper1->offset)
					ip->oper1->offset->i = 0;
		}
	}
	currentFn->didRemoveReturnBlock = true;
}

void PeepList::RemoveStackCode()
{
	OCODE *ip;
	bool do_remove;

	return;
	do_remove = true;
	for (ip = head; ip; ip = ip->fwd) {
		if (ip->opcode == op_hint && ip->oper1->offset->i == start_funcbody) {
			do_remove = false;
			continue;
		}
		if (ip->opcode == op_hint && ip->oper1->offset->i == begin_stack_unlink) {
			do_remove = true;
			continue;
		}
		if (ip->opcode == op_hint && ip->oper1->offset->i == begin_ret) {
			do_remove = true;
			continue;
		}
		if (ip->opcode == op_hint && ip->oper1->offset->i == end_ret) {
			do_remove = false;
			continue;
		}
		if (ip->opcode == op_hint && ip->oper1->offset->i == end_stack_unlink) {
			do_remove = false;
			continue;
		}
		if (ip->opcode == op_label || ip->opcode == op_fnname)
			continue;
		if (do_remove)
			ip->MarkRemove();
		if (ip->insn) {
			if (ip->insn->opcode == op_add || ip->insn->opcode == op_sub) {
				if (ip->oper1->preg == regSP)
					ip->MarkRemove();
			}
		}
		if (ip->opcode == op_ret) {
			if (ip->back) {
				if (ip->back->opcode == op_add) {
					if (ip->back->oper1->preg == regSP) {
						ip->back->oper3->offset->i = 0;
						ip->back->MarkRemove();
					}
				}
			}
			if (ip->oper1)
				if (ip->oper1->offset)
					ip->oper1->offset->i = 0;
		}
	}
}

void PeepList::RemoveStackAlloc()
{
	OCODE *ip;

	for (ip = head; ip; ip = ip->fwd) {
		if (ip->insn) {
			if ((ip->opcode == op_add || ip->opcode == op_sub) && ip->oper1->mode == am_reg && ip->oper1->preg == regSP) {
				ip->MarkRemove();
			}
		}
	}
}

void PeepList::SetAllUncolored()
{
	OCODE *ip;

	for (ip = head; ip; ip = ip->fwd) {
		if (ip->insn) {
			if (ip->oper1)
				ip->oper1->scolored = ip->oper1->pcolored = false;
			if (ip->oper2)
				ip->oper2->scolored = ip->oper2->pcolored = false;
			if (ip->oper3)
				ip->oper3->scolored = ip->oper3->pcolored = false;
			if (ip->oper4)
				ip->oper4->scolored = ip->oper4->pcolored = false;
		}
	}
}

void PeepList::storeHex(txtoStream& ofs)
{
	OCODE *ip;

	for (ip = head; ip != NULL; ip = ip->fwd)
	{
		ip->storeHex(ofs);
	}
	ofs.printf("%c", 26);
}

void PeepList::loadHex(txtiStream& ifs)
{
	char buf[50];
	OCODE *cd;
	int op;

	head = tail = nullptr;
	while (!ifs.eof()) {
		ifs.read(buf, 1);
		switch (buf[0]) {
		case 'O':
			cd = OCODE::loadHex(ifs);
			Add(cd);
			break;
		default:	// ;
			while (buf[0] != '\n' && !ifs.eof())
				ifs.read(buf, 1);
			break;
		}
	}
}

//
// Output all code and labels in the peep list.
//
void PeepList::flush()
{
	static bool first = true;
	txtoStream* oofs;
	OCODE *ip;

/*
	if (pass == 2) {
		if (first) {
			compiler.storeTables();
			first = false;
		}
		oofs = new txtoStream();
		oofs->open(irfile, std::ios::out | std::ios::app);
		currentFn->pl.storeHex(*oofs);
		oofs->close();
		delete oofs;
	}
*/
	for (ip = head; ip; ip = ip->fwd)
	{
		if (ip->opcode == op_label)
			put_label((int)ip->oper1, "", GetNamespace(), 'C');
		else
			ip->store(ofs);
	}
}


// Output peep list for debugging
void PeepList::Dump(char *msg)
{
	OCODE *ip;
	Instruction *insn;

	return;
	dfs.printf("<PeepList>\n");
	dfs.printf(msg);
	dfs.printf("\n");
	for (ip = head; ip; ip = ip->fwd) {
		if (ip == currentFn->rcode)
			dfs.printf("***rcode***");
		insn = GetInsn(ip->opcode);
		if (ip->opcode == op_label)
			dfs.printf("%s%d:", (char *)ip->oper2, (int)ip->oper1);
		else if (insn)
			dfs.printf("   %s ", insn->mnem);
		else
			dfs.printf("op(%d)", ip->opcode);
		if (ip->bb)
			dfs.printf("bb:%d\n", ip->bb->num);
		else
			dfs.printf("bb nul\n");
	}
	dfs.printf("</PeepList>\n");
}

