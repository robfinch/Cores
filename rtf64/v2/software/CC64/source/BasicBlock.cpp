#include "stdafx.h"

extern bool HasTargetReg(OCODE *);
BasicBlock *basicBlocks[10000];
BasicBlock *sortedBlocks[10000];
int BasicBlock::nBasicBlocks = 0;
BasicBlock *BasicBlock::RootBlock = nullptr;

BasicBlock *BasicBlock::MakeNew()
{
	BasicBlock *bb;

	bb = (BasicBlock *)allocx(sizeof(BasicBlock));
	bb->live = CSet::MakeNew();
	bb->gen = CSet::MakeNew();
	bb->kill = CSet::MakeNew();
	bb->LiveIn = CSet::MakeNew();
	bb->LiveOut = CSet::MakeNew();
	bb->MustSpill = CSet::MakeNew();
	bb->NeedLoad = CSet::MakeNew();
	bb->color = CSet::MakeNew();
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
	case op_rts:	return true;
	case op_jal:	return true;
	case op_call: return true;
	case op_jsr:  return true;
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
	case op_bnei:	return (true);
	case op_bchk:	return (true);
	case op_band:	return (true);
	case op_bor:	return (true);
	case op_bnand:	return (true);
	case op_bnor:	return (true);
		//case op_ibne:	return (true);
	//case op_dbnz:	return (true);
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
	currentFn->RootBlock = bbs = BasicBlock::MakeNew();
	bbs->code = start;
	bbs->num = num;
	bbs->length = 0;
	pb = bbs;
	basicBlocks[0] = currentFn->RootBlock;
	start->leader = true;
	for (ip = start; ip; ip = ip2) {
		ip->bb = pb;
		pb->isRetBlock = false;
		pb->depth = ip->loop_depth + 1;
		ip2 = ip->fwd;
		if (ip->opcode != op_label && ip->opcode != op_remark && ip->opcode != op_rem2 && ip->opcode != op_hint && ip->opcode != op_hint2)
			pb->length++;
		if (ip->opcode == op_ret || ip->opcode == op_rti) {
			pb->isRetBlock = true;
			currentFn->ReturnBlock = pb;
		}
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
			pb->length = 0;
			basicBlocks[num] = pb;
		}
	}
	nBasicBlocks = num;
	currentFn->LastBlock = pb->prev;
	if (currentFn->LastBlock==nullptr)
		currentFn->LastBlock = currentFn->RootBlock;
	// ASSERT(LastBlock!=nullptr);
	pb->next = nullptr;
	dfs.printf("%s: ", (char *)currentFn->sym->name->c_str());
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

int bbdcmp(const void *a, const void *b)
{
	BasicBlock *aa, *bb;

	aa = (BasicBlock *)a;
	bb = (BasicBlock *)b;
	return (aa->depth < bb->depth ? 1 : aa->depth == bb->depth ? 0 : -1);
}

void BasicBlock::DepthSort()
{
	memcpy(sortedBlocks, basicBlocks, (currentFn->LastBlock->num+1)*sizeof(BasicBlock *));
	qsort(sortedBlocks, (size_t)currentFn->LastBlock->num+1, sizeof(BasicBlock *), bbdcmp);
}

CSet *BasicBlock::livo;

void BasicBlock::ComputeLiveVars()
{
	OCODE *ip;
	int tr, nn;
	static CSet OldLiveIn, OldLiveOut;
	int rg1, rg2;
	bool eol;
	char buf [4000];

	dfs.printf("----- Compute Live Vars -----\n");
	if (livo==nullptr)
		livo = CSet::MakeNew();
	livo->clear();
	changed = false;
	gen->clear();
	kill->clear();
	eol = false;
	for (ip = code; ip && !eol; ip = ip->fwd) {
		if (ip->remove || ip->remove2)
			continue;
		if (ip->opcode == op_label)
			continue;
		// Call and jal may return a value in $v0,$v1.
		if (ip->opcode == op_call || ip->opcode == op_jal) {
			kill->add(1);
			gen->add(1);
			kill->add(2);
			gen->add(2);
		}
		if (ip->HasTargetReg()) {
			ip->GetTargetReg(&rg1, &rg2);
			tr = rg1;
			if (!isRetBlock) {
				// Should check the register classes here.
				if ((tr & 0xFFF) >= 0x800) {
					kill->add((tr & 0xfff) - 0x780);
				}
				else {
					kill->add(tr);
				}
			}
			if (tr >= regFirstArg && tr <= regLastArg)
				gen->add(tr);
			// There could be a second target
			tr = rg2;
			if (tr) {
				if (!isRetBlock) {
					if ((tr & 0xFFF) >= 0x800) {
						kill->add((tr & 0xfff) - 0x780);
					}
					else {
						kill->add(tr);
					}
				}
				if (tr >= regFirstArg && tr <= regLastArg)
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
				if (ip->oper1->preg)
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
				if (ip->oper2->preg)
					gen->add(ip->oper2->preg);
			}
			if (ip->oper2->mode == am_indx2) {
				if (ip->oper1->sreg)
					gen->add(ip->oper2->sreg);
			}
//				}
		}
		if (ip->oper3) {
			if ((ip->oper3->preg & 0xfff) >= 0x800) {
				gen->add((ip->oper3->preg & 0xfff)-0x780);
			}
			else {
				if (ip->oper3->preg)
					gen->add(ip->oper3->preg);
			}
		}
		if (ip->oper4) {
			if ((ip->oper4->preg & 0xfff) >= 0x800) {
				gen->add((ip->oper4->preg & 0xfff)-0x780);
			}
			else {
				if (ip->oper4->preg)
					gen->add(ip->oper4->preg);
			}
		}
		eol = ip == lcode;
	}
	OldLiveIn.clear();
	OldLiveOut.clear();
	OldLiveIn.copy(*LiveIn);
	OldLiveOut.copy(*LiveOut);
	LiveIn->copy(*LiveOut);
	LiveIn->remove(*kill);
	LiveIn->add(gen);
	//if (isRetBlock) {
	//	eol = false;
	//	for (ip = code; ip && !eol; ip = ip->fwd) {
	//		if (ip->HasTargetReg()) {
	//			ip->GetTargetReg(&rg1, &rg2);
	//			if (!LiveOut->isMember(rg1) && !LiveIn->isMember(rg1)) {
	//				ip->Remove();
	//			}
	//		}
	//		eol = ip == lcode;
	//	}
	//}
	gen->resetPtr();
	kill->resetPtr();
	dfs.printf("%d: ", num);
	for (nn = 0; nn < gen->NumMember(); nn++)
		dfs.printf("g%d ", gen->nextMember());
	dfs.printf(" || ");
	for (nn = 0; nn < kill->NumMember(); nn++)
		dfs.printf("k%d ", kill->nextMember());
	dfs.printf("\n");
	dfs.printf("Edges to: ");
	LiveOut->copy(*LiveIn);
	if (ohead!=nullptr)
		AddLiveOut(this);
	dfs.printf("- - - - Live Out - - - -");
	LiveOut->sprint(buf, sizeof(buf));
	dfs.printf(buf);
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

void BasicBlock::ExpandReturnBlocks()
{
	BasicBlock *bb;
	Edge *p;
	OCODE *ip, *nc, *oc, *bk;

	if (currentFn->ReturnBlock == nullptr)
		return;
	for (bb = currentFn->RootBlock; bb; bb = bb->next) {

		// Prevent the same edge from being added multiple times.
		for (p = bb->ohead; p; p = p->next) {
			if (p->dst == currentFn->ReturnBlock && currentFn->ReturnBlock->length < 32) {
				oc = bb->lcode;
				bk = bb->lcode->back;
				oc = bb->lcode = OCODE::Clone(currentFn->ReturnBlock->code);
				for (ip = ip->fwd; ip != currentFn->ReturnBlock->lcode; ip = ip->fwd) {
					oc->back = bk;
					oc->fwd = OCODE::Clone(ip);
					bk = oc;
					oc = oc->fwd;
				}
				oc->fwd = bb->next->code;
				bb->lcode = nc;
				break;
			}
		}

	}

}


void BasicBlock::UpdateLive(int r)
{
	if (NeedLoad->isMember(r)) {
		NeedLoad->remove(r);
		if (!MustSpill->isMember(r)) {
			forest.trees[r]->infinite = true;
		}
	}
	forest.trees[r]->stores += depth * 4;
	live->remove(r);
}


void BasicBlock::CheckForDeaths(int r)
{
	int m;

	if (!live->isMember(r)) {
		NeedLoad->resetPtr();
		for (m = NeedLoad->nextMember(); m >= 0; m = NeedLoad->nextMember()) {
			forest.trees[m]->loads += depth * 4;
			MustSpill->add(m);
		}
		NeedLoad->clear();
	}
}


void BasicBlock::ComputeSpillCosts()
{
	BasicBlock *b;
	OCODE *ip;
	Instruction *i;
	Operand *pam;
	int r;
	bool endLoop;

	forest.ClearCosts();

	for (b = currentFn->RootBlock; b; b = b->next) {
		b->NeedLoad->clear();
		// build the set live from b->liveout
		b->BuildLivesetFromLiveout();
		//*b->live = *b->LiveOut;
		*b->MustSpill = *b->live;
		endLoop = false;
		for (ip = b->lcode; ip && !endLoop; ip = ip->back) {
			if (ip->opcode == op_label)
				continue;
			if (ip->opcode == op_mov) {
				r = ip->oper1->preg;
				r = forest.map[r];
				forest.trees[r]->copies++;
			}
			else {
				if (ip->oper1 && ip->insn->HasTarget()) {
					r = ip->oper1->preg;
					r = forest.map[r];
					forest.trees[r]->others += ip->insn->extime;
				}
			}
			i = ip->insn;
			// examine instruction i updating sets and accumulating costs
			if (i->HasTarget()) {
				r = ip->oper1->preg;
				r = forest.map[r];
				b->UpdateLive(r);
			}
			// This is a loop in the Briggs thesis, but we only allow 4 operands
			// so the loop is unrolled.
			if (ip->oper1) {
				if (!i->HasTarget()) {
					r = ip->oper1->preg;
					r = forest.map[r];
					b->CheckForDeaths(r);
					if (r = ip->oper1->sreg) {	// '=' is correct
						r = forest.map[r];
						b->CheckForDeaths(r);
					}
				}
			}
			if (ip->oper2) {
				r = ip->oper1->preg;
				r = forest.map[r];
				b->CheckForDeaths(r);
				if (r = ip->oper1->sreg) {
					r = forest.map[r];
					b->CheckForDeaths(r);
				}
			}
			if (ip->oper3) {
				r = ip->oper1->preg;
				r = forest.map[r];
				b->CheckForDeaths(r);
				if (r = ip->oper1->sreg) {
					r = forest.map[r];
					b->CheckForDeaths(r);
				}
			}
			if (ip->oper4) {
				r = ip->oper1->preg;
				r = forest.map[r];
				b->CheckForDeaths(r);
				if (r = ip->oper1->sreg) {
					r = forest.map[r];
					b->CheckForDeaths(r);
				}
			}
			// Re-examine uses to update live and needload
			pam = ip->oper1;
			if (pam && !i->HasTarget()) {
				r = pam->preg;
				r = forest.map[r];
				//r = Var::Find2(pam->lrpreg)->cnum;
				b->live->add(r);
				b->NeedLoad->add(r);
				if (pam->sreg) {
					//r = Var::Find2(pam->lrsreg)->cnum;
					r = pam->sreg;
					r = forest.map[r];
					b->live->add(r);
					b->NeedLoad->add(r);
				}
			}
			pam = ip->oper2;
			if (ip->oper2) {
				r = ip->oper2->preg;
				r = forest.map[r];
//				r = Var::Find2(pam->lrpreg)->cnum;
				b->live->add(r);
				b->NeedLoad->add(r);
				if (ip->oper2->sreg) {
					r = ip->oper2->sreg;
					r = forest.map[r];
//					r = Var::Find2(pam->lrsreg)->cnum;
					b->live->add(r);
					b->NeedLoad->add(r);
				}
			}
			pam = ip->oper3;
			if (ip->oper3) {
				r = ip->oper3->preg;
				r = forest.map[r];
//				r = Var::Find2(pam->lrpreg)->cnum;
				b->live->add(r);
				b->NeedLoad->add(r);
				if (ip->oper3->sreg) {
//					r = Var::Find2(pam->lrsreg)->cnum;
					r = ip->oper3->sreg;
					r = forest.map[r];
					b->live->add(r);
					b->NeedLoad->add(r);
				}
			}
			pam = ip->oper4;
			if (ip->oper4) {
//				r = Var::Find2(pam->lrpreg)->cnum;
				r = ip->oper4->preg;
				r = forest.map[r];
				b->live->add(r);
				b->NeedLoad->add(r);
				if (ip->oper4->sreg) {
					r = ip->oper4->sreg;
					r = forest.map[r];
//					r = Var::Find2(pam->lrsreg)->cnum;
					b->live->add(r);
					b->NeedLoad->add(r);
				}
			}
			if (ip == b->code)
				endLoop = true;
		}
		b->NeedLoad->resetPtr();
		for (r = b->NeedLoad->nextMember(); r >= 0; r = b->NeedLoad->nextMember()) {
			//Var::FindByCnum(r)->trees.loads += b->depth * 4;
			//forest.loads += b->depth * 4;
			if (forest.trees[r])
				forest.trees[r]->loads += b->depth * 4;
		}
	}

	forest.SummarizeCost();
}


// We don't actually want entire ranges. Only the part of the
// range that the basic block is sitting on. There could be
// multiple pieces to the range associated with a var.

void BasicBlock::BuildLivesetFromLiveout()
{
	int m;
	int v;
	int K = nregs;

	live->clear();
	LiveOut->resetPtr();
	//for (m = LiveOut->nextMember(); m >= 0; m = LiveOut->nextMember()) {
	//	vr = Var::Find2(m);
	//	v = vr->cnum;
	//	if (v >= 0) live->add(v);
	//}
	
	for (m = LiveOut->nextMember(); m >= 0; m = LiveOut->nextMember()) {
		// Find the live range associated with value m
		v = Var::FindTreeno(map.newnums[m],num);
		if (v >= 0 && ::forest.trees[v]->color==K) {
			live->add(v);
		}
		// else compiler error
	}
	
}


// Update the CFG by uniting the son's edges with the father's.

void BasicBlock::Unite(int father, int son)
{
	Edge *ep;

	for (ep = basicBlocks[son]->ohead; ep; ep = ep->next) {
		basicBlocks[father]->MakeOutputEdge(ep->dst);
	}
	for (ep = basicBlocks[son]->ihead; ep; ep = ep->next) {
		basicBlocks[father]->MakeInputEdge(ep->src);
	}
	for (ep = basicBlocks[son]->dhead; ep; ep = ep->next) {
		basicBlocks[father]->MakeDomEdge(ep->dst);
	}
}

// Insert a register move operation before block.

void BasicBlock::InsertMove(int reg, int rreg, int blk)
{
	OCODE *cd, *ip;

	cd = (OCODE *)allocx(sizeof(OCODE));
	cd->opcode = op_mov;
	cd->insn = GetInsn(op_mov);
	cd->oper1 = allocOperand();
	cd->oper1->mode = am_reg;
	cd->oper1->preg = rreg;
	cd->oper2 = allocOperand();
	cd->oper2->mode = am_reg;
	cd->oper2->preg = reg;
	ip = basicBlocks[blk]->code;

	basicBlocks[blk]->code = cd;
	cd->back = ip->back;
	cd->fwd = ip;
	cd->bb = ip->bb;
	if (ip->back)
		ip->back->fwd = cd;
	ip->back = cd;
	cd->leader = true;
	ip->leader = false;
}

// The interference graph works based on tree numbers
// Basic blocks work based on basic block numbers.
// There is some conversion required.

bool BasicBlock::Coalesce()
{
	OCODE *ip;
	int dst, src, dtree, stree;
	int father, son, ft, st;
	bool improved;
	int nn;

	improved = false;

	for (nn = 0; nn <= currentFn->LastBlock->num; nn++) {
		for (ip = sortedBlocks[nn]->code; ip && ip != sortedBlocks[nn]->lcode; ip = ip->fwd) {
			if (ip->remove)
				continue;
			if (ip->insn == nullptr)
				continue;
			if (ip->insn->opcode == op_mov) {
				dst = Var::PathCompress(ip->oper1->preg, ip->bb->num, &dtree);
				src = Var::PathCompress(ip->oper2->preg, ip->bb->num, &stree);
				if (dst < 0 || src < 0)
					continue;
				if (stree != dtree) {
					// For iGraph we just want the tree number not the bb number.
					ft = min(stree, dtree);
					st = max(stree, dtree);
					if (src <= dst) {
						father = src;
						son = dst;
					}
					else {
						father = dst;
						son = src;
					}
					if (!iGraph.DoesInterfere(father, son)) {
						iGraph.Unite(father, son);
						// update graph so father contains all edges from son
						if (father != son)
							Unite(father, son);
						improved = true;
						ip->MarkRemove();
					}
				}
			}
		}
	}
	return (improved);
}


void DumpLiveRegs()
{
	int regno;
	BasicBlock *b;

	dfs.printf("<LiveRegisters>\n");
	for (regno = 1; regno < nregs; regno++) {
		dfs.printf("Reg:%d ", regno);
		for (b = currentFn->RootBlock; b; b = b->next) {
			if (/*b->LiveOut->isMember(regno) || */b->LiveIn->isMember(regno))
				dfs.printf("%d ", b->num);
		}
		dfs.printf("\n");
	}
	dfs.printf("</LiveRegisters>\n");
}

void BasicBlock::InsertSpillCode(int reg, int64_t offs)
{
	OCODE *cd;

	if (this == nullptr)
		return;
	cd = (OCODE *)xalloc(sizeof(OCODE));
	cd->insn = GetInsn(op_sth);
	cd->opcode = op_sth;
	cd->oper1 = allocOperand();
	cd->oper2 = allocOperand();
	cd->oper1->mode = am_reg;
	cd->oper1->preg = reg;
	cd->oper2->mode = am_indx;
	cd->oper2->preg = regFP;
	cd->oper2->offset = allocEnode();
	cd->oper2->offset->nodetype = en_icon;
	cd->oper2->offset->i = offs;
	cd->bb = this;
	if (num==0)
		PeepList::InsertBefore(lcode, cd);
	else
		PeepList::InsertBefore(code, cd);
}

void BasicBlock::InsertFillCode(int reg, int64_t offs)
{
	OCODE *cd;

	if (this == nullptr)
		return;
	cd = (OCODE *)xalloc(sizeof(OCODE));
	cd->insn = GetInsn(op_ldh);
	cd->opcode = op_ldh;
	cd->oper1 = allocOperand();
	cd->oper2 = allocOperand();
	cd->oper1->mode = am_reg;
	cd->oper1->preg = reg;
	cd->oper2->mode = am_indx;
	cd->oper2->preg = regFP;
	cd->oper2->offset = allocEnode();
	cd->oper2->offset->nodetype = en_icon;
	cd->oper2->offset->i = offs;
	cd->bb = this;
	if (currentFn->rcode->bb==this)
		PeepList::InsertAfter(currentFn->rcode, cd);
	else
		PeepList::InsertBefore(lcode, cd);
}

void BasicBlock::SetAllUncolored()
{
	int n;

	for (n = 0; n < BasicBlock::nBasicBlocks; n++)
		basicBlocks[n]->isColored = false;
}

void BasicBlock::Color()
{
	int r;
	OCODE *ip;

	return;
	for (ip = code; ip; ip = ip->fwd) {
		if (ip->remove)
			continue;
		if (ip->insn == nullptr)
			continue;
		if (ip->oper1) {
			r = ip->oper1->preg;
			r = forest.map[r];
			ip->oper1->preg = forest.trees[r]->color;
			r = ip->oper1->sreg;
			r = forest.map[r];
			ip->oper1->sreg = forest.trees[r]->color;
		}
		if (ip->oper2) {
			r = ip->oper2->preg;
			r = forest.map[r];
			ip->oper2->preg = forest.trees[r]->color;
			r = ip->oper2->sreg;
			r = forest.map[r];
			ip->oper2->sreg = forest.trees[r]->color;
		}
		if (ip->oper3) {
			r = ip->oper3->preg;
			r = forest.map[r];
			ip->oper3->preg = forest.trees[r]->color;
			r = ip->oper3->sreg;
			r = forest.map[r];
			ip->oper3->sreg = forest.trees[r]->color;
		}
		if (ip->oper4) {
			r = ip->oper4->preg;
			r = forest.map[r];
			ip->oper4->preg = forest.trees[r]->color;
			r = ip->oper4->sreg;
			r = forest.map[r];
			ip->oper4->sreg = forest.trees[r]->color;
		}
		if (ip == lcode)
			break;
	}
}

void BasicBlock::ColorAll()
{
	int nn;

	for (nn = 0; nn <= currentFn->LastBlock->num; nn++) {
		basicBlocks[nn]->Color();
	}
}
