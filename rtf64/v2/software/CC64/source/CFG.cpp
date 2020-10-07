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
// ============================================================================
//
#include "stdafx.h"

extern BasicBlock *basicBlocks[10000];
extern Instruction *GetInsn(int);

void CFG::Create()
{
	OCODE *ip, *ip1;
	int nn;
	struct scase *cs;

	for (ip = currentFn->pl.head; ip; ip = ip->fwd) {
		if (ip->leader) {
		if (ip->back) {
		// if not unconditional control transfer
			if (ip->back->opcode != op_ret && ip->back->opcode != op_bra && ip->back->opcode!=op_jmp) {
				ip->back->bb->MakeOutputEdge(ip->bb);
				ip->bb->MakeInputEdge(ip->back->bb);
			}
		}
		}
		//}
		switch(ip->opcode) {
		case op_bex:
		case op_bra:
		case op_jmp:
			if (ip->oper1->offset) {
				if (ip1 = FindLabel(ip->oper1->offset->i)) {
					ip->bb->MakeOutputEdge(ip1->bb);
					ip1->bb->MakeInputEdge(ip->bb);
				}
			}
			break;
		case op_beq:
		case op_bne:
		case op_blt:
		case op_bge:
		case op_ble:
		case op_bgt:
		case op_bltu:
		case op_bgeu:
		case op_bleu:
		case op_bgtu:
		case op_bbs:
		case op_bbc:
		case op_beqi:
		case op_bnei:
		//case op_ibne:
			if (0) {
				if (ip->oper1->mode==am_reg && ip->back && ip->back->oper3) {
					if (ip1 = FindLabel(ip->back->oper3->offset->i)) {
						ip->bb->MakeOutputEdge(ip1->bb);
						ip1->bb->MakeInputEdge(ip->bb);
					}
				}
			}
			else {
				if (ip->oper2 == nullptr) {
					if (ip1 = FindLabel(ip->oper1->offset->i)) {
						ip->bb->MakeOutputEdge(ip1->bb);
						ip1->bb->MakeInputEdge(ip->bb);
					}
				}
				else if (ip1 = FindLabel(ip->oper2->offset->i)) {
					ip->bb->MakeOutputEdge(ip1->bb);
					ip1->bb->MakeInputEdge(ip->bb);
				}
			}
			break;
		case op_bchk:
			if (ip1 = FindLabel(ip->oper4->offset->i)) {
				ip->bb->MakeOutputEdge(ip1->bb);
				ip1->bb->MakeInputEdge(ip->bb);
			}
			break;
		case op_jal:
			// Was it a switch statement ?
			if (ip->oper3) {
				for (nn = 1; nn < ((struct scase *)(ip->oper3))->label; nn++) {
					cs = &((struct scase *)(ip->oper3))[1];
					ip1 = FindLabel(cs->label);
					if (ip1) {
						ip->bb->MakeOutputEdge(ip1->bb);
						ip1->bb->MakeInputEdge(ip->bb);
					}
				}
			}
			else {
				// Could be a jal [LR] for a ret statement in which case there's
				// only one operand.
				if (ip->oper2) {
					if (ip->oper2->mode != am_reg) {
						if (ip1 = FindLabel(ip->oper2->offset->i)) {
							ip->bb->MakeOutputEdge(ip1->bb);
							ip1->bb->MakeInputEdge(ip->bb);
						}
					}
				}
			}
			break;
		}
	}
}

static CSet *visited;
static CSet *paths[1000];
static int npaths;

// Walk down the path beginning at block b.

static void DownPath(BasicBlock *b)
{
	Edge *e;
	int path;
	bool first;

	if (visited->isMember(b->num))
		return;
	path = npaths-1;
	paths[path]->add(b->num);
	visited->add(b->num);
	first = true;
	for (e = b->ohead; e; e = e->next) {
		if (!first) {
			paths[npaths] = CSet::MakeNew();
			paths[npaths]->add(paths[path]);
			npaths++;
		}
//		if (!e->backedge) {
			first = false;
			DownPath(e->dst);
//		}
	}
}

// Discover all the paths in the CFG.

static void DiscoverPaths()
{
	BasicBlock *b;
	int n;
	char buf[2000];

	b = currentFn->RootBlock;
	visited = CSet::MakeNew();
	paths[0] = CSet::MakeNew();
	paths[0]->add(b->num);
	npaths = 1;
	DownPath(b);
	dfs.printf("<Paths>\n");
	for (n = 0; n < npaths; n++) {
		paths[n]->sprint(buf, sizeof(buf));
		dfs.printf("%d: ", n);
		dfs.printf("%s\n", buf);
	}
	dfs.printf("</Paths>\n");
}


void CFG::CalcDominatorTree()
{
	int n, m, o, ps;
	CSet *pathSet;
	bool oInAllPaths;

	DiscoverPaths();
	pathSet = CSet::MakeNew();
	for (n = currentFn->LastBlock->num; n >= 1; n--) {
		pathSet->clear();
		// Get all paths that contain n
		for (m = 0; m < npaths; m++)
			if (paths[m]->isMember(n))
				pathSet->add(m);
		// If o is in all paths to n, then o dominates over n. Note there could
		// be several o's that dominate over n. We only want the last one to do
		// so. So we start the search at n-1 and work backwards.
		for (o = n - 1; o >= 0; o--) {
			oInAllPaths = true;
			pathSet->resetPtr();
			for (ps = pathSet->nextMember(); ps >= 0; ps=pathSet->nextMember()) {
				if (!paths[ps]->isMember(o)) {
					oInAllPaths = false;
					break;
				}
			}
			if (oInAllPaths)
				break;
		}
		basicBlocks[o]->MakeDomEdge(basicBlocks[n]);
	}
}

void CFG::CalcDominanceFrontiers()
{
	BasicBlock *x;
	Edge *e;
	Edge *z;
	int y;

	CalcDominatorTree();
	for (x = currentFn->LastBlock; x; x = x->prev) {
		x->DF = nullptr;
		if (x->dhead) {
			x->DF = CSet::MakeNew();
			// Check the successors of X
			for (e = x->ohead; e; e = e->next) {
				if (!x->IsIdom(e->dst)) {
					x->DF->add(e->dst->num);
				}
			}
			// Check the children of X
			for (z = x->dhead; z; z = z->next) {
				if (z->dst->DF) {
					z->dst->DF->resetPtr();
					for (y = z->dst->DF->nextMember(); y >= 0; y = z->dst->DF->nextMember()) {
						if (!x->IsIdom(basicBlocks[y]))
							x->DF->add(y);
					}
				}
			}
		}
	}
}

void CFG::InsertPhiInsns()
{
	BasicBlock *x;
	OCODE *phiNode, *ip;
	CSet *w;
	Var *v;
	Edge *e;
	int IterCount = 0;
	int n, m, y;

	w = CSet::MakeNew();
	for (x = currentFn->RootBlock; x; x = x->next) {
		x->HasAlready = 0;
		x->Work = 0;
	}
	w->clear();
	for (v = currentFn->varlist; v; v = v->next) {
		// Don't bother considering r0 which always contains the constant zero.
		if (v->num==0)
			continue;
		IterCount++;
		v->forest->resetPtr();
		for (n = v->forest->nextMember(); n >= 0; n = v->forest->nextMember()) {
			x = basicBlocks[n];
			x->Work = IterCount;
			w->add(x->num);
		}
		w->resetPtr();
		while (w->NumMember() > 0) {
			n = w->nextMember();
			if (n < 0) {
				w->resetPtr();
				n = w->nextMember();
				if (n < 0)
					break;
			}
			w->remove(n);
			x = basicBlocks[n];
			if (x->DF) {
				x->DF->resetPtr();
				for (y = x->DF->nextMember(); y >= 0; y = x->DF->nextMember()) {
					if (basicBlocks[y]->HasAlready < IterCount) {
						// Place phi node at Y
						phiNode = (OCODE *)allocx(sizeof(OCODE));
						phiNode->insn = GetInsn(op_phi);
						phiNode->opcode = op_phi;
						phiNode->oper1 = makereg(v->num);
						phiNode->bb = basicBlocks[y];
						m = 0;
						for (e = phiNode->bb->ihead; e && m < 100; e = e->next) {
							phiNode->phiops[m] = e->src->num;
							m++;
						}
						ip = basicBlocks[y]->code;
						while (ip && ip->opcode==op_label) ip = ip->fwd;
						// For now this is disabled.
						// Peep::InsertBefore(ip,phiNode);
						basicBlocks[y]->HasAlready = IterCount;
						if (basicBlocks[y]->Work < IterCount) {
							basicBlocks[y]->Work = IterCount;
							w->add(y);
						}
					}
				}
			}
		}
	}
}


// Get the ordinal of which predecessor X is of Y.

int CFG::WhichPred(BasicBlock *x, int y)
{
	BasicBlock *b;
	Edge *e;
	int n;

	b = basicBlocks[y];
	n = 0;
	for (e = b->ihead; e; e = e->next) {
		if (e->src==x)
			return (n);
		n++;
	}
	return (-1);
}

// Set a subscript on a variable.

void CFG::Subscript(Operand *oper)
{
	Var *v;

	if (oper) {
		v = Var::FindByMac(oper->preg);
		if (v)
			oper->pregs = v->istk->tos();
		v = Var::FindByMac(oper->sreg);
		if (v)
			oper->sregs = v->istk->tos();
	}
}

void CFG::Search(BasicBlock *x)
{
	OCODE *s;
	BasicBlock *b;
	Var *v;
	Edge *e;
	int i, j, y;
	bool eol;
	int rg1, rg2;

	eol = false;
	for (s = x->code; s && !eol; s = s->fwd) {
		if (s->opcode!=op_label) {
			if (s->oper1 && !s->HasTargetReg())
				Subscript(s->oper1);
			if (s->oper2)
				Subscript(s->oper2);
			if (s->oper3)
				Subscript(s->oper3);
			if (s->oper4)
				Subscript(s->oper4);
			if (s->oper1 && s->HasTargetReg()) {
				s->GetTargetReg(&rg1, &rg2);
				v = Var::FindByMac(rg1);
				if (v) {
					i = v->subscript;
					s->oper1->pregs = i;
					v->istk->push(i);
					v->subscript++;
				}
				if (rg2) {
					v = Var::FindByMac(rg2);
					if (v) {
						i = v->subscript;
						s->oper1->sregs = i;
						v->istk->push(i);
						v->subscript++;
					}
				}
			}
		}
		eol = s == x->lcode;
	}
	for (e = x->ohead; e; e = e->next) {
		y = e->dst->num;
		j = WhichPred(x,y);
		if (j < 0 || j > 99) {	// Internal compiler error
			printf("DIAG: CFG Rename j=%d out of range.\n", j);
			fatal("");
			continue;
		}
		b = basicBlocks[y];
		eol = false;
		for (s = b->code; s && !eol; s = s->fwd) {
			if (s->opcode==op_phi) {
				v = Var::FindByMac(s->oper1->preg);
				if (v)
					s->phiops[j] = v->istk->tos();
			}
			eol = s == b->lcode;
		}
	}
	for (e = x->dhead; e; e = e->next)
		Search(e->dst);
	eol = false;
	for (s = x->code; s && !eol; s = s->fwd) {
		if (s->opcode!=op_label) {
			if (s->HasTargetReg()) {
				s->GetTargetReg(&rg1, &rg2);
				v = Var::FindByMac(rg1);
				if (v)
					v->istk->pop();
				if (rg2) {
					v = Var::FindByMac(rg2);
					if (v)
						v->istk->pop();
				}
			}
		}
		eol = s == x->lcode;
	}

}

void CFG::Rename()
{
	Var *v;

	for (v = currentFn->varlist; v; v = v->next) {
		v->istk = IntStack::MakeNew();
		v->istk->push(0);
		v->subscript = 0;
	}
	Search(currentFn->RootBlock);
}
