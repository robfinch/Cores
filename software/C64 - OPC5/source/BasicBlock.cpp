#include "stdafx.h"

BasicBlock *RootBlock;
BasicBlock *LastBlock;

// Detect which instructions have target registers.
// ToDo: create an instruction class
// This could be an attribute of the instruction.

bool HasTargetReg(OCODE *ip)
{
	switch(ip->opcode) {
	case op_mov:
	case op_inc:
	case op_dec:
	case op_add:
	case op_adc:
	case op_sub:
	case op_sbc:
	case op_and:
	case op_or:
	case op_xor:
	case op_ld:
	case op_lsr:
	case op_ror:
	case op_asr:
	case op_pop:
	case op_not:
	case op_in:
		return (true);
	}
	return (false);
}

BasicBlock *BasicBlock::MakeNew()
{
	BasicBlock *bb;

	bb = (BasicBlock *)allocx(sizeof(BasicBlock));
	bb->gen = CSet::MakeNew();
	bb->kill = CSet::MakeNew();
	bb->LiveIn = CSet::MakeNew();
	bb->LiveOut = CSet::MakeNew();
	bb->MustSpill = CSet::MakeNew();
	bb->NeedLoad = CSet::MakeNew();
	return (bb);
}

// Detect basic block separater instruction

bool IsBasicBlockSeparater(OCODE *ip)
{
	if (ip->opcode==op_label)
		return (false);
	// Move to program counter is a branch
	// As is inc / dec PC
	if ((ip->opcode==op_mov || ip->opcode==op_inc || ip->opcode==op_dec)
		&& ip->oper1 && ip->oper1->preg==regPC)
		return (true);
	return (false);
}

// Break the program down into basic blocks

BasicBlock *BasicBlock::Blockize(OCODE *start)
{
	OCODE *ip, *ip2;
	BasicBlock *bbs, *pb;
	int num;

	num = 0;
	RootBlock = bbs = BasicBlock::MakeNew();
	bbs->code = start;
	bbs->num = num;
	pb = bbs;
	for (ip = start; ip; ip = ip2) {
		ip->bb = pb;
		ip2 = ip->fwd;
		if (IsBasicBlockSeparater(ip)) {
			if (ip->fwd)
				ip->fwd->leader = true;
			num++;
			pb->next = BasicBlock::MakeNew();
			pb->next->prev = pb;
			pb->next->code = ip2;
			pb = pb->next;
			pb->num = num;
		}
	}
	LastBlock = pb;
	pb->next = nullptr;
	return (bbs);
}

Edge *BasicBlock::MakeOutputEdge(BasicBlock *dst)
{
	Edge *edge;

	edge = (Edge *)allocx(sizeof(Edge));
	edge->src = this;
	edge->dst = dst;
	if (otail) {
		otail->next = edge;
		edge->prev = otail;
		otail = edge;
	}
	else {
		ohead = otail = edge;
	}
	return (edge);
}

Edge *BasicBlock::MakeInputEdge(BasicBlock *src)
{
	Edge *edge;

	edge = (Edge *)allocx(sizeof(Edge));
	edge->src = src;
	edge->dst = this;
	if (itail) {
		itail->next = edge;
		edge->prev = itail;
		itail = edge;
	}
	else {
		ihead = itail = edge;
	}
	return (edge);
}

void BasicBlock::ComputeLiveVars()
{
	OCODE *ip;
	Edge *ep;
	static CSet OldLiveIn, OldLiveOut;
//	char buf [4000];

	changed = false;
	gen->clear();
	kill->clear();
	for (ip = code; ip && (!ip->leader || ip == code); ip = ip->fwd) {
		if (ip->opcode!=op_label) {
			if (HasTargetReg(ip)) {
				kill->add(ip->oper1->vpreg & 0xfffL);
			}
			else if (ip->oper1 && ip->oper1->mode == am_reg) {
				gen->add(ip->oper1->vpreg & 0xfffL);
			}
			if (ip->oper2) {
				if (ip->oper2->mode == am_reg) {
					gen->add(ip->oper2->vpreg & 0xfffL);
				}
			}
			if (ip->oper3) {
				if (ip->oper3->mode == am_reg) {
					gen->add(ip->oper3->vpreg & 0xfffL);
				}
			}
			if (ip->oper4) {
				if (ip->oper4->mode == am_reg) {
					gen->add(ip->oper4->vpreg & 0xfffL);
				}
			}
		}
	}
	OldLiveIn.clear();
	OldLiveOut.clear();
	OldLiveIn.copy(*LiveIn);
	OldLiveOut.copy(*LiveOut);
	LiveIn->copy(*LiveOut);
	LiveIn->remove(*kill);
	LiveIn->add(gen);
	//gen->resetPtr();
	//kill->resetPtr();
	//dfs.printf("%d: ", num);
	//for (nn = 0; nn < gen->NumMember(); nn++)
	//	dfs.printf("g%d ", gen->nextMember());
	//dfs.printf(" || ");
	//for (nn = 0; nn < kill->NumMember(); nn++)
	//	dfs.printf("k%d ", kill->nextMember());
	//dfs.printf("\n");
	//dfs.printf("Edges to: ");
	for (ep = ohead; ep; ep = ep->next) {
		if (ep->dst) {
			//dfs.printf("%d ", ep->dst->num);
			LiveOut->add(ep->dst->LiveIn);
			//LiveOut->sprint(buf,sizeof(buf));
			//dfs.printf("LiveOut: %s", buf);
		}
	}
//	dfs.printf("\n");
	if (OldLiveIn != *LiveIn)
		changed = true;
	if (OldLiveOut != *LiveOut)
		changed = true;
}

// Keeps iterating until there are no changes detected in the LiveIn / LiveOut
// sets. Also has an iteration limit in case something's wrong with the compiler.

void ComputeLiveVars()
{
	BasicBlock *b;
	bool changed;
	int iter;
	int changes;

	changed = false;
	for (iter = 0; (iter==0 || changed) && iter < 10000; iter++) {
		changes = 0;
		changed = false;
		for (b = LastBlock; b; b = b->prev) {
			b->ComputeLiveVars();
			if (b->changed) {
				changes++;
				changed = true;
			}
		}
	}
}

void DumpLiveVars()
{
	BasicBlock *b;
	int nn;

	dfs.printf("<LiveVarTable>\n");
	for (b = RootBlock; b; b = b->next) {
		b->LiveIn->resetPtr();
		b->LiveOut->resetPtr();
		dfs.printf("%d: ", b->num);
		for (nn = 0; nn < b->LiveIn->NumMember(); nn++)
			dfs.printf("vi%d ", b->LiveIn->nextMember());
		dfs.printf(" || ");
		for (nn = 0; nn < b->LiveOut->NumMember(); nn++)
			dfs.printf("vo%d ", b->LiveOut->nextMember());
		dfs.printf("\n");
	}
	dfs.printf("</LiveVarTable>\n");
}

