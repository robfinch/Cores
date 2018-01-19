#include "stdafx.h"

BasicBlock *RootBlock;
BasicBlock *LastBlock;
extern bool HasTargetReg(OCODE *);
int nBasicBlocks;
BasicBlock *basicBlocks[10000];

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
	bb->ihead = nullptr;
	bb->ohead = nullptr;
	bb->itail = nullptr;
	bb->otail = nullptr;
	return (bb);
}

// Detect basic block separater instruction

bool IsBasicBlockSeparater(OCODE *ip)
{
	if (ip->opcode==op_label)
		return (false);
	switch(ip->opcode) {
	case op_rte:	return (true);
	case op_ret:	return true;
	case op_jal:	return true;
	case op_jmp:	return true;
	case op_bra:	return true;
	case op_beq:	return true;
	case op_bne:	return true;
	case op_blt:	return true;
	case op_bge:	return true;
	case op_ble:	return true;
	case op_bgt:	return true;
	case op_bltu:	return true;
	case op_bgeu:	return true;
	case op_bleu:	return true;
	case op_bgtu:	return true;
	case op_bbs:	return (true);
	case op_bbc:	return (true);
	case op_beqi:	return (true);
	default:	return (false);
	}
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
	basicBlocks[0] = RootBlock;
	start->leader = true;
	for (ip = start; ip; ip = ip2) {
		ip->bb = pb;
		pb->depth = ip->loop_depth;
		ip2 = ip->fwd;
		if (IsBasicBlockSeparater(ip)) {
			pb->lcode = ip;
			if (ip->fwd)
				ip->fwd->leader = true;
			num++;
			pb->next = BasicBlock::MakeNew();
			pb->next->prev = pb;
			pb->next->code = ip2;
			pb = pb->next;
			pb->num = num;
			basicBlocks[num] = pb;
		}
	}
	nBasicBlocks = num;
	LastBlock = pb->prev;
	if (LastBlock==nullptr)
		LastBlock = RootBlock;
	// ASSERT(LastBlock!=nullptr);
	pb->next = nullptr;
	dfs.printf("%s: ", (char *)currentFn->name->c_str());
	dfs.printf("%d basic blocks\n", num);
	return (bbs);
}

Edge *BasicBlock::MakeOutputEdge(BasicBlock *dst)
{
	Edge *edge;
	Edge *p;

	// Prevent the same edge from being added multiple times.
	for (p = ohead; p; p = p->next) {
		if (p->dst==dst)
			return (nullptr);
	}
	edge = (Edge *)allocx(sizeof(Edge));
	edge->src = this;
	edge->dst = dst;
	edge->backedge = dst->num < num;
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
	Edge *p;

	// Prevent the same edge from being added multiple times.
	for (p = ihead; p; p = p->next)
		if (p->src==src)
			return (nullptr);
	edge = (Edge *)allocx(sizeof(Edge));
	edge->src = src;
	edge->dst = this;
	edge->backedge = src->num > num;
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

Edge *BasicBlock::MakeDomEdge(BasicBlock *dst)
{
	Edge *edge;
	Edge *p;

	// Prevent the same edge from being added multiple times.
	for (p = dhead; p; p = p->next)
		if (p->dst==dst)
			return (nullptr);
	edge = (Edge *)allocx(sizeof(Edge));
	edge->src = this;
	edge->dst = dst;
	if (dtail) {
		dtail->next = edge;
		edge->prev = dtail;
		dtail = edge;
	}
	else {
		dhead = dtail = edge;
	}
	return (edge);
}

CSet *BasicBlock::livo;

void BasicBlock::ComputeLiveVars()
{
	OCODE *ip;
	Edge *ep;
	int tr;
	static CSet OldLiveIn, OldLiveOut;
//	char buf [4000];

	if (livo==nullptr)
		livo = CSet::MakeNew();
	livo->clear();
	changed = false;
	gen->clear();
	kill->clear();
	for (ip = code; ip && (!ip->leader || ip == code); ip = ip->fwd) {
		if (ip->remove || ip->remove2)
			continue;
		if (ip->opcode!=op_label) {
			if (ip->HasTargetReg()) {
				tr = ip->GetTargetReg() & 0xffff;
				if ((tr & 0xFFF) >= 0x800) {
					kill->add((tr & 0xfff)-0x780);
				}
				else {
					kill->add(tr);
				}
				if (tr >= 18 && tr <= 24)
					gen->add(tr);
				// There could be a second target
				tr = (ip->GetTargetReg() >> 16) & 0xffff;
				if (tr) {
					if ((tr & 0xFFF) >= 0x800) {
						kill->add((tr & 0xfff)-0x780);
					}
					else {
						kill->add(tr);
					}
					if (tr >= 18 && tr <= 24)
						gen->add(tr);
				}
			}
			// If there was an explicit target it would have been oper1
			// there was an else here
			else 
			//if (ip->oper1 && ip->oper1->mode == am_reg) {
			if (ip->oper1) {
				if ((ip->oper1->preg & 0xfff) >= 0x800) {
					gen->add((ip->oper1->preg & 0xfff)-0x780);
				}
				else {
					gen->add(ip->oper1->preg);
				}
			}
			// Stack operations implicitly read SP. It doesn't appear in the operx operands.
			if (ip->opcode==op_push || ip->opcode==op_pop || ip->opcode==op_link || ip->opcode==op_unlk) {
				gen->add(regSP);
			}
			if (ip->oper2) {
//				if (ip->oper2->mode == am_reg) {
					if ((ip->oper2->preg & 0xfff) >= 0x800) {
						gen->add((ip->oper2->preg & 0xfff)-0x780);
					}
					else {
						gen->add(ip->oper2->preg);
					}
					if (ip->oper2->mode == am_indx2) {
						gen->add(ip->oper2->sreg);
					}
//				}
			}
			if (ip->oper3) {
//				if (ip->oper3->mode == am_reg) {
					if ((ip->oper3->preg & 0xfff) >= 0x800) {
						gen->add((ip->oper3->preg & 0xfff)-0x780);
					}
					else {
						gen->add(ip->oper3->preg);
					}
//				}
			}
			if (ip->oper4) {
//				if (ip->oper4->mode == am_reg) {
					if ((ip->oper4->preg & 0xfff) >= 0x800) {
						gen->add((ip->oper4->preg & 0xfff)-0x780);
					}
					else {
						gen->add(ip->oper4->preg);
					}
//				}
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
	if (ohead==nullptr)
		LiveOut->copy(*LiveIn);
	else
		AddLiveOut(this);
	/*
	for (ep = ohead; ep; ep = ep->next) {
		if (ep->dst) {
			//dfs.printf("%d ", ep->dst->num);
			LiveOut->add(ep->dst->LiveIn);
			//LiveOut->sprint(buf,sizeof(buf));
			//dfs.printf("LiveOut: %s", buf);
		}
	}
	*/
//	dfs.printf("\n");
	if (OldLiveIn != *LiveIn)
		changed = true;
	if (OldLiveOut != *LiveOut)
		changed = true;
}

void BasicBlock::AddLiveOut(BasicBlock *ip)
{
	Edge *ep;

	for (ep = ohead; ep; ep = ep->next) {
		if (!livo->isMember(ep->dst->num)) {
			livo->add(ep->dst->num);
			if (ep->dst) {
				AddLiveOut(ep->dst);
			//dfs.printf("%d ", ep->dst->num);
				LiveOut->add(ep->dst->LiveIn);
			//LiveOut->sprint(buf,sizeof(buf));
			//dfs.printf("LiveOut: %s", buf);
			}
		}
	}
}

bool BasicBlock::IsIdom(BasicBlock *b)
{
	Edge *e;

	for (e = dhead; e; e = e->next) {
		if (e->dst==b)
			return (true);
	}
	return (false);
}

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
	int lomax, limax;

	lomax = limax = 0;
	for (b = RootBlock; b; b = b->next) {
		lomax = max(lomax,b->LiveOut->NumMember());
		limax = max(limax,b->LiveIn->NumMember());
	}

	dfs.printf("<table style=\"width:100%\">\n");
	//dfs.printf("<LiveVarTable>\n");
	for (b = RootBlock; b; b = b->next) {
		b->LiveIn->resetPtr();
		b->LiveOut->resetPtr();
		dfs.printf("<tr><td>%d: </td>", b->num);
		for (nn = 0; nn < b->LiveIn->NumMember(); nn++)
			dfs.printf("<td>vi%d </td>", b->LiveIn->nextMember());
		for (; nn < limax; nn++)
			dfs.printf("<td></td>");
		dfs.printf("<td> || </td>");
		for (nn = 0; nn < b->LiveOut->NumMember(); nn++)
			dfs.printf("<td>vo%d </td>", b->LiveOut->nextMember());
		for (; nn < lomax; nn++)
			dfs.printf("<td></td>");
		dfs.printf("</tr>\n");
	}
	//dfs.printf("</LiveVarTable>\n");
	dfs.printf("</table>\n");
}

void DumpLiveRegs()
{
	int regno;
	BasicBlock *b;

	dfs.printf("<LiveRegisters>\n");
	for (regno = 1; regno < 32; regno++) {
		dfs.printf("Reg:%d ", regno);
		for (b = RootBlock; b; b = b->next) {
			if (/*b->LiveOut->isMember(regno) || */b->LiveIn->isMember(regno))
				dfs.printf("%d ", b->num);
		}
		dfs.printf("\n");
	}
	dfs.printf("</LiveRegisters>\n");
}


