// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2020  Robert Finch, Waterloo
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

void OCODE::Remove()
{
	currentFn->pl.Remove(this);
};

// Return true if the instruction has a target register.

bool OCODE::HasTargetReg() const
{
	if (insn) {
		if (insn->opcode == op_call || insn->opcode == op_jal)
			return (oper1->type != bt_void);
		return (insn->HasTarget());
	}
	else
		return (false);
}

bool OCODE::HasTargetReg(int regno) const
{
	int rg1, rg2;
	if (HasTargetReg()) {
		GetTargetReg(&rg1, &rg2);
		if (rg1 == regno || rg2 == regno)
			return (true);
	}
	return (false);
}

bool OCODE::HasSourceReg(int regno) const
{
	if (insn == nullptr)
		return (false);
	// Push has an implied target, so oper1 is actually a source.
	if (oper1 && !insn->HasTarget() || opcode==op_push) {
		if (oper1->preg==regno)
			return (true);
		if (oper1->sreg==regno)
			return (true);
	}
	if (oper2 && oper2->preg==regno)
		return (true);
	if (oper2 && oper2->sreg==regno)
		return (true);
	if (oper3 && oper3->preg==regno)
		return (true);
	if (oper3 && oper3->sreg==regno)
		return (true);
	if (oper4 && oper4->preg==regno)
		return (true);
	if (oper4 && oper4->sreg==regno)
		return (true);
	// The call instruction implicitly has register arguments as source registers.
	if (opcode==op_call) {
		if (IsArgumentReg(regno))
			return(true);
	}
	return (false);
}

bool OCODE::IsFlowControl() {
	if (insn)
		return (insn->IsFlowControl());
	else
		return (false);
}

// Get target reg needs to distinguish floating-point registers from regular
// general purpose registers. It returns a one for floating-point registers or
// a zero for general-purpose registers.

int OCODE::GetTargetReg(int *rg1, int *rg2) const
{
	if (insn==nullptr)
		return(0);
	if (insn->HasTarget()) {
		// Handle implicit targets
		switch(insn->opcode) {
		case op_pop:
		case op_unlk:
		case op_link:
			*rg1 = regSP;
			*rg2 = oper1->preg;
			return(0);
		case op_divmod:
		case op_mul:
		case op_mulu:
		case op_sort:
		case op_demux:
		case op_mov2:
			*rg1 = oper1->preg;
			*rg2 = oper1->sreg;
			return (0);
		case op_pea:
		case op_push:
		case op_ret:
		case op_call:
			*rg1 = regSP;
			*rg2 = 0;
			return (0);
		default:
			if (oper1) {
				if (oper1->mode == am_fpreg) {
					*rg1 = oper1->preg;
					*rg2 = 0;
					return (1);
				}
				else {
					*rg1 = oper1->preg;
					*rg2 = 0;
					return (0);
				}
			}
			else {
				*rg1 = 0;
				*rg2 = 0;
				return (0);
			}
		}
	}
	else {
		*rg1 = 0;
		*rg2 = 0;
		return (0);
	}
}

OCODE *OCODE::Clone(OCODE *c)
{
	OCODE *cd;
	cd = (OCODE *)xalloc(sizeof(OCODE));
	memcpy(cd, c, sizeof(OCODE));
	return (cd);
}

void OCODE::Swap(OCODE *ip1, OCODE *ip2)
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


//
//      mov r3,r3 removed
//
// Code Like:
//		add		r3,r2,#10
//		mov		r3,r5
// Changed to:
//		mov		r3,r5

void OCODE::OptMove()
{
	if (OCODE::IsEqualOperand(oper1, oper2)) {
		MarkRemove();
		optimized++;
		return;
	}
}

//	   sge		$v1,$r12,$v2
//     redor	$v2,$v1
// Translates to:
//	   sge		$v1,$r12,$v2
//     mov		$v2,$v1
// Because redundant moves will be eliminated by further compiler
// optimizations.

void OCODE::OptRedor()
{
	if (back == nullptr)
		return;
	if (back->insn->IsSetInsn()) {
		if (back->oper1->preg == oper2->preg) {
			opcode = op_mov;
			insn = GetInsn(op_mov);
			optimized++;
		}
	}
}


bool OCODE::IsSubiSP()
{
	if (opcode == op_sub) {
		if (oper3->mode == am_imm) {
			if (oper1->preg == regSP && oper2->preg == regSP) {
				return (true);
			}
		}
	}
	return (false);
}


void OCODE::OptAdd()
{
	// Add zero to self.
	if (IsEqualOperand(oper1, oper2)) {
		if (oper3->mode == am_imm) {
			if (oper3->offset->nodetype == en_icon) {
				if (oper3->offset->i == 0) {
					MarkRemove();
					optimized++;
				}
			}
		}
	}
}
// 'subui' followed by a 'bne' gets turned into 'loop'
//
void OCODE::OptSubtract()
{
	OCODE *ip2;

	ip2 = fwd;
	// Subtract zero from self.
	if (IsEqualOperand(oper1, oper2)) {
		if (oper3->mode == am_imm) {
			if (oper3->offset->nodetype == en_icon) {
				if (oper3->offset->i == 0) {
					MarkRemove();
					optimized++;
					return;
				}
			}
		}
	}
	//if (oper2->isPtr && oper3->isPtr && oper2->mode == am_reg && oper3->mode == am_reg) {
	//	opcode = op_ptrdif;
	//	insn = GetInsn(op_ptrdif);
	//	oper4 = MakeImmediate(1);
	//}
	//if (ip2->opcode == op_asr || ip2->opcode == op_stpru) {
	//	if (Operand::IsEqual(ip2->oper2,oper1)) {
	//		if (oper2->isPtr && oper3->isPtr && oper2->mode == am_reg && oper3->mode == am_reg) {
	//			if (ip2->oper3->mode == am_imm) {
	//				if (ip2->oper3->offset->i < 8) {
	//					opcode = op_ptrdif;
	//					insn = GetInsn(op_ptrdif);
	//					oper4 = MakeImmediate(ip2->oper3->offset->i);
	//					ip2->MarkRemove();
	//					optimized++;
	//				}
	//			}
	//		}
	//	}
	//}
	while (ip2->opcode == op_hint)
		ip2 = ip2->fwd;
	if (IsSubiSP() && ip2->fwd)
		if (ip2->IsSubiSP()) {
			oper3->offset->i += ip2->oper3->offset->i;
			ip2->MarkRemove();
		}
	if (IsSubiSP() && oper3->offset->i == 0)
		MarkRemove();
	return;
	if (opcode == op_subui) {
		if (oper3) {
			if (oper3->mode == am_imm) {
				if (oper3->offset->nodetype == en_icon && oper3->offset->i == 1) {
					if (fwd) {
						if (fwd->opcode == op_ne && fwd->oper2->mode == am_reg && fwd->oper2->preg == 0) {
							if (fwd->oper1->preg == oper1->preg) {
								opcode = op_loop;
								oper2 = fwd->oper3;
								oper3 = NULL;
								fwd->MarkRemove();
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


// This optimization eliminates an 'AND' instruction when the value
// in the register is a constant less than one of the two special
// constants 255 or 65535. This is typically a result of a zero
// extend operation.
//
// So code like:
//		ld		r3,#4
//		and		r3,r3,#255
// Eliminates the useless 'and' operation.

void OCODE::OptAnd()
{
	// This doesn't work properly yet in all cases.
	if (oper1 && oper2 && oper3) {
		if (oper1->mode == am_reg && oper2->mode == am_reg && oper3->mode == am_imm) {
			if (oper1->preg == oper2->preg && oper3->offset->i == -1) {
				MarkRemove();
				optimized++;
			}
		}
	}
	return;
	if (oper2 == nullptr || oper3 == nullptr)
		throw new C64PException(ERR_NULLPOINTER, 0x50);
	if (oper2->offset == nullptr || oper3->offset == nullptr)
		return;
	if (oper2->offset->constflag == false)
		return;
	if (oper3->offset->constflag == false)
		return;
	if (
		oper3->offset->i != 1 &&
		oper3->offset->i != 3 &&
		oper3->offset->i != 7 &&
		oper3->offset->i != 15 &&
		oper3->offset->i != 31 &&
		oper3->offset->i != 63 &&
		oper3->offset->i != 127 &&
		oper3->offset->i != 255 &&
		oper3->offset->i != 511 &&
		oper3->offset->i != 1023 &&
		oper3->offset->i != 2047 &&
		oper3->offset->i != 4095 &&
		oper3->offset->i != 8191 &&
		oper3->offset->i != 16383 &&
		oper3->offset->i != 32767 &&
		oper3->offset->i != 65535)
		// Could do this up to 32 bits
		return;
	if (oper2->offset->i < oper3->offset->i) {
		MarkRemove();
	}
}

// Strip out useless masking operations generated by type conversions.

void OCODE::OptLoad()
{
	if (oper2->mode != am_imm)
		return;
	// This optimization is also caught by the code generator.
	if (oper2->offset->i == 0) {
		opcode = op_mov;
		oper2->mode = am_reg;
		oper2->preg = 0;
		optimized++;
		return;
	}
	if (!fwd)
		return;
	if (fwd->opcode != op_and)
		return;
	if (fwd->oper1->preg != oper1->preg)
		return;
	if (fwd->oper2->preg != oper1->preg)
		return;
	if (fwd->oper3->mode != am_imm)
		return;
	oper2->offset->i = oper2->offset->i & fwd->oper3->offset->i;
	fwd->MarkRemove();
	/*
	if (fwd->fwd)
		fwd->fwd->back = this;
	fwd = fwd->fwd;
	*/
	optimized++;
}


// Remove the sign extension of a value after a sign-extending load.
// This most commonly is generated by character processing.

void OCODE::OptLoadChar()
{
	if (fwd) {
		if (fwd->opcode == op_sext16 || fwd->opcode == op_sxc ||
			(fwd->opcode == op_bfext && fwd->oper3->offset->i == 0 && fwd->oper4->offset->i == 15)) {
			if (fwd->oper1->preg == oper1->preg) {
				fwd->MarkRemove();
				//if (fwd->fwd) {
				//	fwd->fwd->back = this;
				//}
				//fwd = fwd->fwd;
			}
		}
	}
}

void OCODE::OptLoadByte()
{
	if (fwd) {
		if (fwd->opcode == op_sext8 || fwd->opcode == op_sxb ||
			(fwd->opcode == op_bfext && fwd->oper3->offset->i == 0 && fwd->oper4->offset->i == 7)) {
			if (fwd->oper1->preg == oper1->preg) {
				fwd->MarkRemove();
				//if (fwd->fwd) {
				//	fwd->fwd->back = this;
				//}
				//fwd = fwd->fwd;
			}
		}
	}
}


void OCODE::OptLoadHalf()
{
	if (fwd) {
		if (fwd->opcode == op_sext32 || fwd->opcode == op_sxh ||
			(fwd->opcode == op_bfext && fwd->oper3->offset->i == 0 && fwd->oper4->offset->i == 31)) {
			if (fwd->oper1->preg == oper1->preg) {
				fwd->MarkRemove();
				//if (fwd->fwd) {
				//	fwd->fwd->back = this;
				//}
				//fwd = fwd->fwd;
			}
		}
	}
}

// Search ahead and remove this load if the register is def'd again without a use.
void OCODE::OptLoadWord()
{
	OCODE *ip;

	for (ip = fwd; ip; ip = ip->fwd) {
		if (ip->opcode == op_label)
			break;
		if (ip->opcode == op_call || ip->opcode == op_jal)
			break;
		if (ip->opcode == op_hint || ip->opcode == op_rem)
			continue;
		if (ip->HasSourceReg(oper1->preg))
			break;
		if (ip->HasTargetReg()) {
			if (ip->oper1->preg == oper1->preg) {
				MarkRemove();
				optimized++;
				break;
			}
		}
	}
}

void OCODE::OptSxb()
{
	if (fwd == nullptr)
		return;
	if (fwd->opcode != op_and)
		return;
	if (fwd->oper3->mode != am_imm)
		return;
	if (fwd->oper3->offset->i != 255)
		return;
	MarkRemove();
	optimized++;
}



// Place the store half so it's more likely to optimize away a load.

void OCODE::OptStoreHalf()
{
	if (back && (back->opcode == op_bfextu || back->opcode == op_bfext)) {
		if (back->oper1->preg == oper1->preg) {
			if (back->oper3->offset->i == 0 && back->oper4->offset->i == 31) {
				Swap(back, this);
			}
		}
	}
}


// Optimize away a store followed immediately by a load of the same value. But
// do not if it's a volatile variable.
// Eg.
// SH   r3,Address
// LH	r3,Address
// Turns into
// SH   r3,Address

void OCODE::OptStore()
{
	OCODE *ip;

	if (opcode == op_stp)
		OptStoreHalf();
	for (ip = fwd; ip; ip = ip->fwd)
		if (ip->opcode != op_rem && ip->opcode != op_hint)
			break;
	if (opcode == op_label || ip->opcode == op_label)
		return;
	if (!OCODE::IsEqualOperand(oper1, ip->oper1))
		return;
	if (!OCODE::IsEqualOperand(oper2, ip->oper2))
		return;
	if (opcode == op_stp && ip->opcode != op_ldp)
		return;
	if (opcode == op_std && ip->opcode != op_ldd)
		return;
	if (ip->isVolatile)
		return;
	ip->MarkRemove();
	optimized++;
}

// Remove instructions that branch to the next label.
//
void OCODE::OptBra()
{
	OCODE *p;

	for (p = fwd; p && p->opcode == op_label; p = p->fwd)
		if (oper1->offset->i == (int)p->oper1) {
			MarkRemove();
			optimized++;
			break;
		}
	OptUctran();
	return;
}

// Optimize unconditional control flow transfers
// Instructions that follow an unconditional transfer won't be executed
// unless there is a label to branch to them.
//
void OCODE::OptUctran()
{
	if (uctran_off) return;

	while (fwd != nullptr && fwd->opcode != op_label)
	{
		fwd = fwd->fwd;
		if (fwd != nullptr)
			fwd->back = this;
		optimized++;
	}
}

void OCODE::OptJAL()
{
	if (oper1->preg != 0)
		return;
	OptUctran();
}

//
//      changes multiplies and divides by convienient values
//      to shift operations. op should be either op_asl or
//      op_asr (for divide).
//
void OCODE::OptMul()
{
	int shcnt;
	int64_t num;

	if (oper3->mode != am_imm)
		return;
	if (oper3->offset->nodetype != en_icon)
		return;

	num = oper3->offset->i;

	// remove multiply by 1
	// This shouldn't get through Optimize, but does sometimes.
	if (num == 1) {
		MarkRemove();
		optimized++;
		return;
	}
	for (shcnt = 1; shcnt < 64; shcnt++) {
		if (num == (int64_t)1 << shcnt) {
			num = shcnt;
			optimized++;
			break;
		}
	}
	if (shcnt == 64)
		return;
	oper3->offset->i = shcnt;
	opcode = op_sll;
	optimized++;
}

void OCODE::OptMulu()
{
	int shcnt;
	int64_t num;

	if (oper3->mode != am_imm)
		return;
	if (oper3->offset->nodetype != en_icon)
		return;

	num = oper3->offset->i;

	// remove multiply by 1
	// This shouldn't get through Optimize, but does sometimes.
	if (num == 1) {
		MarkRemove();
		optimized++;
		return;
	}
	for (shcnt = 1; shcnt < 64; shcnt++) {
		if (num == (int64_t)1 << shcnt) {
			num = shcnt;
			optimized++;
			break;
		}
	}
	if (shcnt == 64)
		return;
	oper3->offset->i = shcnt;
	opcode = op_stpl;
	optimized++;
}

void OCODE::OptDiv()
{
	int shcnt;
	int64_t num;

	if (oper3->mode != am_imm)
		return;
	if (oper3->offset->nodetype != en_icon)
		return;

	num = oper3->offset->i;

	// remove divide by 1
	// This shouldn't get through Optimize, but does sometimes.
	if (num == 1) {
		MarkRemove();
		optimized++;
		return;
	}
	for (shcnt = 1; shcnt < 64; shcnt++) {
		if (num == (int64_t)1 << shcnt) {
			num = shcnt;
			optimized++;
			break;
		}
	}
	if (shcnt == 64)
		return;
	oper3->offset->i = shcnt;
	opcode = op_asr;
	optimized++;
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

	if (ip->oper1->mode != am_imm)
		return;
	if (ip->oper1->offset->nodetype != en_icon)
		return;

	num = ip->oper1->offset->i;

	// remove multiply / divide by 1
	// This shouldn't get through Optimize, but does sometimes.
	if (num == 1) {
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
	if (shcnt == 32)
		return;
	ip->oper1->offset->i = num;
	ip->opcode = op;
	ip->length = 2;
	optimized++;
}

void OCODE::OptDoubleTargetRemoval()
{
	OCODE *ip2;
	int rg1, rg2, rg3, rg4;

	if (!HasTargetReg())
		return;
	for (ip2 = fwd; ip2 && (ip2->opcode == op_rem || ip2->opcode == op_hint); ip2 = ip2->fwd);
	if (ip2 == nullptr)
		return;
	if (!ip2->HasTargetReg())
		return;
	ip2->GetTargetReg(&rg1, &rg2);
	GetTargetReg(&rg3, &rg4);
	// Should look at this more carefully sometime. Generally however target 
	// register classes won't match between integer and float instructions.
	if ((insn->amclass1 ^ ip2->insn->amclass1) != 0)
		return;
	if (rg1 != rg3)
		return;
	if (ip2->HasSourceReg(rg3))
		return;
	// push has an implicit target, but we don't want to remove it.
	if (opcode == op_push)
		return;
	//if (rg3 == regSP)
	//	return;
	MarkRemove();
	optimized++;
}

void OCODE::OptIndexScale()
{
	OCODE *frwd;

	if (fwd == nullptr || back == nullptr)
		return;
	// Make sure we have the right kind of a shift left.
	if (back->opcode != op_stpl || back->oper3 == nullptr || back->oper3->offset == nullptr)
		return;
	if (back->oper3->offset->i < 1 || back->oper3->offset->i > 3)
		return;
	// Now search for double indexed operation. There could be multiple matches.
	for (frwd = fwd; frwd; frwd = frwd->fwd) {
		// If there's an intervening flow control, can't optimize.
		if (frwd->insn) {
			if (frwd->insn->IsFlowControl()) {
				frwd = nullptr;
				break;
			}
		}
		// If there's a intervening flow control target, can't optimize.
		if (frwd->opcode == op_label) {
			frwd = nullptr;
			break;
		}
		if (frwd->oper2) {
			// Found a double index.
			if (frwd->oper2->mode == am_indx2) {
				// Is it the right one?
				if (frwd->oper2->preg == back->oper1->preg) {
					frwd->oper2->preg = back->oper2->preg;
					frwd->oper2->scale = 1 << back->oper3->offset->i;
					back->MarkRemove();
					optimized++;
				}
			}
		}
		// If the target register is assigned to something else
		// abort optimization.
		// If the scaling register is assigned to something else
		// abort optimization.
		else if (frwd->oper1) {
			if (frwd->HasTargetReg()) {
				if (frwd->oper1->preg == back->oper1->preg) {
					frwd = nullptr;
					break;
				}
				if (frwd->oper1->preg == back->oper2->preg) {
					frwd = nullptr;
					break;
				}
			}
		}
	}
}

void OCODE::OptCom()
{
	if (back == nullptr || fwd == nullptr)
		return;
	if (fwd->remove || back->remove)
		return;
	// If not all in registers
	if (back->oper1->mode != am_reg
		|| back->oper2->mode != am_reg
		|| (back->oper3 && back->oper3->mode != am_reg))
		return;
	if (back->opcode != op_and
		&& back->opcode != op_or
		&& back->opcode != op_xor
		)
		return;
	if (fwd->opcode != op_com)
		return;
	if (fwd->oper2->mode != am_reg)
		return;
	if (back->oper1->preg != fwd->oper2->preg)
		return;
	if (fwd->opcode != op_com)
		return;
	switch (back->opcode) {
	case op_and:
		back->opcode = op_nand;
		back->insn = GetInsn(op_nand);
		back->oper1->preg = fwd->oper1->preg;
		fwd->MarkRemove();
		optimized++;
		break;
	case op_or:
		back->opcode = op_nor;
		back->insn = GetInsn(op_nor);
		back->oper1->preg = fwd->oper1->preg;
		fwd->MarkRemove();
		optimized++;
		break;
	case op_xor:
		back->opcode = op_xnor;
		back->insn = GetInsn(op_xnor);
		back->oper1->preg = fwd->oper1->preg;
		fwd->MarkRemove();
		optimized++;
		break;
	}
}

// Process compiler hint opcodes

void OCODE::OptHint()
{
	OCODE *frwd, *bck;
	Operand *am;
	int rg1, rg2;

	if ((back && back->opcode == op_label) || (fwd && fwd->opcode == op_label))
		return;
	if (remove)
		return;
	if (remove)
		return;

	switch (oper1->offset->i) {

		// hint #1
		// Takes care of redundant moves at the parameter setup point
		// Code Like:
		//    MOV r3,#constant
		//    MOV r18,r3
		// Translated to:
		//    MOV r18,#constant
	case 1:

		if (fwd && fwd->opcode != op_mov) {
			Remove();	// remove the hint
			optimized++;
			return;
		}

		if (fwd && fwd->oper1->preg >= regFirstArg && fwd->oper1->preg < regLastArg) {
			if (OCODE::IsEqualOperand(fwd->oper2, back->oper1)) {
				back->oper1 = fwd->oper1;
				MarkRemove();
				fwd->MarkRemove();
				optimized++;
				return;
			}
		}

		if (back && back->opcode != op_mov) {
			MarkRemove();
			optimized++;
			return;
		}

		if (IsEqualOperand(fwd->oper2, back->oper1)) {
			back->oper1 = fwd->oper1;
			MarkRemove();
			fwd->MarkRemove();
			optimized++;
		}
		else {
			MarkRemove();
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
		// This optimization didn't work with:
		// ldi $t1,#0
		// mov $t0,$t1
		// It optimized it to:
		// ldi  $t1,#0
		// It didn't set the back->oper1 properly.
		return;
		if (fwd == nullptr || back == nullptr)
			break;
		if (fwd->opcode != op_mov) {
			MarkRemove();
			break;
		}
		if (IsEqualOperand(fwd->oper2, back->oper1)) {
			if (back->HasTargetReg()) {
				if (!(fwd->oper1->mode == am_fpreg && back->opcode == op_ldi)) {
					// Search forward to see if the target register is used anywhere.
					for (frwd = fwd->fwd; frwd; frwd = frwd->fwd) {
						// If the register has been targeted again, it is okay to opt.
						if (frwd->HasTargetReg()) {
							frwd->GetTargetReg(&rg1, &rg2);
							if (back->oper1) {
								if (rg1 == back->oper1->preg && back->insn->amclass1 == frwd->insn->amclass1)
									break;
							}
						}
						if (frwd->HasSourceReg(back->oper1->preg)) {
							return;
						}
					}
					back->oper1 = fwd->oper1->Clone();
					fwd->MarkRemove();
					MarkRemove();
					optimized++;
				}
			}
		}
		else {
			MarkRemove();
			optimized++;
		}
		break;

		// hint #3
		//	   and r5,r2,r3
		//     com r1,r5
		// Translates to:
		//     nand r5,r2,r3
	case 3:
		OptCom();
		break;

		// hint #9
		// Index calc.
		//		shl r1,r3,#3
		//		sw r4,[r11+r1]
		// Becomes:
		//		sw r4,[r11+r3*8]
	case 9:
		OptIndexScale();
		break;
		// Following is dead code
		//if (fwd->oper2->mode != am_indx2)
		//	break;
		if (fwd->oper2->preg == back->oper1->preg) {
			if ((back->opcode == op_stpl) && back->oper3->offset &&
				(back->oper3->offset->i == 1
					|| back->oper3->offset->i == 2
					|| back->oper3->offset->i == 3)) {
				fwd->oper2->preg = back->oper2->preg;
				fwd->oper2->scale = 1 << back->oper3->offset->i;
				back->MarkRemove();
				optimized++;
				am = back->oper1;
				frwd = fwd->fwd;
				bck = back->back;
				while (back->opcode == op_hint)	// It should be
					bck = back->back;
				// We search backwards for another shl related to a forward op to
				// accomodate assignment operations. Assignment operations may
				// generate indexed code like the following:
				//    shl for target
				//    shl for source
				//    load source
				//    store target
				if (frwd->oper2) {
					if ((bck->opcode == op_stpl) && bck->oper3->offset &&
						(am->preg != frwd->oper2->preg && am->preg != frwd->oper2->sreg) &&
						(bck->oper3->offset->i == 1
							|| bck->oper3->offset->i == 2
							|| bck->oper3->offset->i == 3)
						) {
						frwd->oper2->preg = bck->oper2->preg;
						frwd->oper2->scale = 1 << bck->oper3->offset->i;
						bck->MarkRemove();
						optimized++;
					}
				}
			}
		}
		break;
	}
}

// Remove extra labels at end of subroutines

void OCODE::OptLabel()
{
	if (this == nullptr)
		return;
	if (fwd)
		return;
	if (back)
		back->fwd = nullptr;
	optimized++;
}


// Search ahead for additional LDI instructions loading the same constant
// and remove them.
// Remove sign / zero extension when not needed.

void OCODE::OptLdi()
{
	OCODE *ip;

	if (fwd) {
		if (oper2->offset->constflag) {
			if (fwd->opcode == op_sxh) {
				if (oper2->offset->i >= -2147483648L && oper2->offset->i <= 2147483647L) {
					fwd->MarkRemove();
					optimized++;
				}
			}
			if (fwd->opcode == op_sxc) {
				if (oper2->offset->i >= -32768 && oper2->offset->i <= 32767) {
					fwd->MarkRemove();
					optimized++;
				}
			}
			if (fwd->opcode == op_sxb) {
				if (oper2->offset->i >= -128 && oper2->offset->i <= 127) {
					fwd->MarkRemove();
					optimized++;
				}
			}
			if (fwd->opcode == op_zxh) {
				if (oper2->offset->i >= 0 && oper2->offset->i <= 4294967295L) {
					fwd->MarkRemove();
					optimized++;
				}
			}
			if (fwd->opcode == op_zxc) {
				if (oper2->offset->i >= 0 && oper2->offset->i <= 65535) {
					fwd->MarkRemove();
					optimized++;
				}
			}
			if (fwd->opcode == op_zxb) {
				if (oper2->offset->i >= 0 && oper2->offset->i <= 255) {
					fwd->MarkRemove();
					optimized++;
				}
			}
		}
	}
	for (ip = fwd; ip; ip = ip->fwd) {
		if (ip->IsFlowControl())
			return;
		if (ip->HasTargetReg()) {
			if (ip->oper1) {
				if (ip->oper1->preg == oper1->preg) {
					if (ip->opcode == op_ldi) {
						if (ip->oper2->offset->i == oper2->offset->i) {
							ip->MarkRemove();
							optimized++;
						}
						else
							return;
					}
					else
						return;
				}
				else
					return;
			}
		}
	}
}


void OCODE::OptLea()
{
	OCODE *ip, *ip2;
	bool opt = true;

	// Remove a move following a LEA
	ip = fwd;
	if (ip) {
		if (ip->opcode == op_mov) {
			if (ip->oper2->preg == oper1->preg) {
				for (ip2 = ip->fwd; ip2; ip2 = ip2->fwd)
				{
					if (ip2->opcode == op_label) {
						opt = false;
						break;
					}
					if (ip2->HasTargetReg(oper1->preg))
						break;
					if (ip2->HasSourceReg(oper1->preg)) {
						opt = false;
						break;
					}
				}
				if (opt) {
					oper1->preg = ip->oper1->preg;
					ip->MarkRemove();
					optimized++;
				}
			}
		}
	}
	for (ip = fwd; ip; ip = ip->fwd) {
		if (ip->HasTargetReg()) {
			if (ip->oper1) {
				if (ip->oper1->preg == oper1->preg) {
					if (ip->opcode == op_ldi) {
						if (ip->oper2->offset->i == oper2->offset->i) {
							ip->MarkRemove();
							optimized++;
						}
						else
							return;
					}
					else
						return;
				}
			}
		}
	}
}

void OCODE::OptPfi()
{
	OCODE *ip;
	int n;
	int count;

	ip = fwd;
	count = 0;
	for (n = 0; n < 32 && ip; n = n + 1) {
		if (ip->remove)
			continue;
		if (ip->opcode == op_pfi) {
			if (count < 5) {
				ip->MarkRemove();
				optimized++;
			}
			else
				count = 0;
		}
		else {
			count = count + 1;
		}
		ip = ip->fwd;
	}
}

void OCODE::storeHex(txtoStream& ofs)
{
	ENODE *ep;

	switch (opcode) {
	case op_label:
		ofs.printf("L");
		ofs.printf("%05X", (int)oper1);
		ofs.printf(GetNamespace());
		ofs.printf("\n");
		break;
	case op_fnname:
		ep = (ENODE *)oper1->offset;
		ofs.printf("F%s:\n", (char *)ep->sp->c_str());
		break;
	default:
		ofs.printf("C");
		insn->storeHex(ofs);
		ofs.printf("L%01d", length);
		if (oper1) oper1->storeHex(ofs);
		if (oper2) oper2->storeHex(ofs);
		if (oper3) oper3->storeHex(ofs);
		if (oper4) oper4->storeHex(ofs);
		ofs.printf("\n");
	}
}

OCODE *OCODE::loadHex(txtiStream& ifs)
{
	OCODE *cd;
	char buf[20];

	cd = (OCODE *)allocx(sizeof(OCODE));
	ifs.read(buf, 1);
	if (buf[0] != 'I') {
		while (!ifs.eof() && buf[0] != '\n')
			ifs.read(buf, 1);
		return (nullptr);
	}
	cd->insn = Instruction::loadHex(ifs);
	cd->opcode = cd->insn->opcode;
	ifs.read(buf, 1);
	if (buf[0] == 'L') {
		ifs.read(buf, 1);
		buf[1] = '\0';
		cd->length = atoi(buf);
		ifs.read(buf, 1);
	}
	cd->oper1 = nullptr;
	cd->oper2 = nullptr;
	cd->oper3 = nullptr;
	cd->oper4 = nullptr;
	switch (buf[0]) {
	case '1': cd->oper1 = Operand::loadHex(ifs); break;
	case '2': cd->oper2 = Operand::loadHex(ifs); break;
	case '3': cd->oper3 = Operand::loadHex(ifs); break;
	case '4': cd->oper4 = Operand::loadHex(ifs); break;
	default:
		while (!ifs.eof() && buf[0] != '\n')
			ifs.read(buf, 1);
	}
	return (cd);
}

//
// Output a generic instruction.
//
void OCODE::store(txtoStream& ofs)
{
	static BasicBlock *b = nullptr;
	int op = opcode;
	Operand *ap1, *ap2, *ap3, *ap4;
	ENODE *ep;
	int predreg = pregreg;
	char buf[8];
	int nn;

	nn = 0;
	ap1 = oper1;
	ap2 = oper2;
	ap3 = oper3;
	ap4 = oper4;

	if (bb != b) {
		if (bb->num == 0) {
			ofs.printf(";====================================================\n");
			ofs.printf("; Basic Block %d\n", bb->num);
			ofs.printf(";====================================================\n");
		}
		b = bb;
	}
	if (comment) {
		if (comment->oper1->offset)
			ofs.printf("; %s\n", (char *)comment->oper1->offset->sp->c_str());
	}
	if (remove)
		ofs.printf(";-1");
	if (remove2)
		ofs.printf(";-2");
	if (op != op_fnname)
	{
		if (op == op_rem2) {
			ofs.printf(";\t");
			ofs.printf("%6.6s\t", "");
			ofs.printf(ap1->offset->sp->c_str());
			ofs.printf("\n");
			return;
		}
		else {
			ofs.printf("\t");
			ofs.printf("%6.6s\t", "");
			if (insn) {
				if (opcode == op_string) {
					ofs.printf("dc");
				}
				else
					nn = insn->store(ofs);
			}
			buf[0] = '\0';
			if (length) {
				if (length <= 16) {
					switch (length) {
					case 1:	sprintf_s(buf, sizeof(buf), ".b"); nn += 2; break;
					case 2:	sprintf_s(buf, sizeof(buf), ".c"); nn += 2; break;
					case 4:	sprintf_s(buf, sizeof(buf), ".h"); nn += 2; break;
					}
				}
				else {
					if (length != 'w' && length != 'W') {
						sprintf_s(buf, sizeof(buf), ".%c", length);
						nn += 2;
					}
				}
			}
			ofs.write(buf);
			// The longest mnemonic is 7 chars
			while (nn < 9) {
				ofs.write(" ");
				nn++;
			}
		}
	}
	if (op == op_fnname) {
		ep = (ENODE *)oper1->offset;
		ofs.printf("%s:", (char *)ep->sp->c_str());
	}
	else if (ap1 != 0)
	{
		ofs.printf("\t");
		ap1->store(ofs);
		if (ap2 != 0)
		{
			if (op == op_push || op == op_pop)
				ofs.printf("/");
			else
				ofs.printf(",");
			if (op == op_cmp && ap2->mode != am_reg)
				printf("aha\r\n");
			ap2->store(ofs);
			if (ap3 != NULL) {
				if (op == op_push || op == op_pop)
					ofs.printf("/");
				else
					ofs.printf(",");
				ap3->store(ofs);
				if (ap4 != NULL) {
					if (op == op_push || op == op_pop)
						ofs.printf("/");
					else
						ofs.printf(",");
					ap4->store(ofs);
				}
			}
		}
	}
	ofs.printf("\n");
}



