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

// This class is currently only used by the CreateForest() function.
// It maintains a stack for tree traversal.

class WorkList
{
	int ndx;
	BasicBlock *p[10000];
public:
	WorkList() { ndx = 0; };
	void push(BasicBlock *q) {
		if (ndx < 9999) {
			p[ndx] = q;
			ndx++;
		}
	};
	BasicBlock *pop() {
		ndx--;
		return p[ndx];
	};
	bool IsEmpty() {
		return (ndx==0);
	};
};

WorkList wl;
Tree *tree;
int Var::nvar;

Var *Var::MakeNew()
{
	Var *p;

	p = (Var *)allocx(sizeof(Var));
	p->forest = CSet::MakeNew();
	p->visited = CSet::MakeNew();
	nvar++;
	return (p);
}

// Live ranges are represented as tree structures.
// Since there could be multiple live ranges (trees) for any given variable
// the group of ranges (or trees) is called a forest.
/*
void Var::CreateForest()
{
	Edge *ep;
	BasicBlock *p, *b;
	CSet *pushSet;

	pushSet = CSet::MakeNew();
	treeno = 0;
	tree = Tree::MakeNew();
	tree->next = trees;
	tree->num = treeno;
	treeno++;
	trees = tree;
	wl.push(LastBlock);
	pushSet->clear();
	while (!wl.IsEmpty()) {
		b = wl.pop();
		if (b->LiveOut->isMember(num)) {
			tree->tree->add(b->num);
			for (ep = b->ihead; ep; ep = ep->next) {
				//if (ep->backedge)
				//	continue;
				p = ep->src;
				if (p) {
//					if (p->LiveOut->isMember(num)) {
//						tree->tree->add(p->num);
						if (!pushSet->isMember(p->num)) {
							wl.push(p);
							pushSet->add(p->num);
						}
//					}
				}
			}
			/*
			for (ep = b->ohead; ep; ep = ep->next) {
				//if (!ep->backedge)
				//	continue;
				p = ep->dst;
				if (p) {
					if (p->LiveOut->isMember(num)) {
						tree->tree->add(p->num);
						if (!pushSet->isMember(p->num)) {
							wl.push(p);
							pushSet->add(p->num);
						}
					}
				}
			}
			*/
			/*
			if (b->prev) {
				if (b->prev->LiveOut->isMember(num)) {
					tree->tree->add(b->prev->num);
				}
				else {
					tree = Tree::MakeNew();
					tree->next = trees;
					tree->num = treeno;
					treeno++;
					trees = tree;
				}
				wl.push(b->prev);
			}
			*/
/*
		}
		else {
			tree = Tree::MakeNew();
			tree->next = trees;
			tree->num = treeno;
			treeno++;
			trees = tree;
			for (ep = b->ihead; ep; ep = ep->next) {
				p = ep->src;
				if (p) {
					if (!pushSet->isMember(p->num)) {
						wl.push(p);
						pushSet->add(p->num);
					}
				}
			}
			//if (b->prev)
			//	wl.push(b->prev);
		}
	}
}
*/

void Var::GrowTree(Tree *t, BasicBlock *b)
{
	Edge *ep;
	BasicBlock *p;

	for (ep = b->ihead; ep; ep = ep->next) {
//		if (!ep->backedge) {
			p = ep->src;
			if (!visited->isMember(p->num)) {
				visited->add(p->num);
				if (p->LiveOut->isMember(num)) {
					if (t==nullptr) {
						t = Tree::MakeNew();
						::forest.PlantTree(t);
						trees.PlantTree(t);
						trees.map[num] = t->num;
						::forest.map[num] = t->num;
						t->var = num;
						t->lattice = b->depth;
					}
					t->blocks->add(p->num);
					t->lattice = max(t->lattice, p->depth);
					forest->add(p->num);
					GrowTree(t, p);
				}
				else
					GrowTree(nullptr, p);
			}
//		}
	}
	for (ep = b->ohead; ep; ep = ep->next) {
//		if (ep->backedge) {
			p = ep->src;
			if (!visited->isMember(p->num)) {
				visited->add(p->num);
				if (p->LiveOut->isMember(num)) {
					if (t==nullptr) {
						t = Tree::MakeNew();
						::forest.PlantTree(t);
						trees.PlantTree(t);
						trees.map[num] = t->num;
						::forest.map[num] = t->num;
						t->lattice = b->depth;
						t->var = num;
					}
					t->blocks->add(p->num);
					t->lattice = max(t->lattice, p->depth);
					forest->add(p->num);
					GrowTree(t, p);
				}
				else {
					GrowTree(nullptr, p);
				}
			}
//		}
	}
}

void Var::CreateForest()
{
	BasicBlock *b, *p;
	Edge *ep;
	Tree *t;
	char buf[2000];

	b = currentFn->LastBlock;
	visited->add(b->num);
	// First see if a tree starts right at the last basic block.
	if (b->LiveOut->isMember(num)) {
		t = Tree::MakeNew();
		::forest.PlantTree(t);
		trees.PlantTree(t);
		trees.map[num] = t->num;
		::forest.map[num] = t->num;
		t->var = num;
		t->lattice = b->depth;
		t->blocks->add(b->num);
		forest->add(b->num);
		GrowTree(t, b);
	}
	//else
	{
	// Next check all the input edges to the last block that
	// haven't yet been visited for additional trees.
	for (ep = b->ihead; ep; ep = ep->next) {
//		if (!ep->backedge) {
			p = ep->src;
			if (!visited->isMember(p->num)) {
				visited->add(p->num);
				if (p->LiveOut->isMember(num)) {
					t = Tree::MakeNew();
					::forest.PlantTree(t);
					trees.PlantTree(t);
					trees.map[num] = t->num;
					::forest.map[num] = t->num;
					t->var = num;
					t->lattice = p->depth;
					t->blocks->add(p->num);
					forest->add(p->num);
					GrowTree(t, p);
				}
				else {
					GrowTree(nullptr, p);
				}
			}
//		}
	}
	for (ep = b->ohead; ep; ep = ep->next) {
//		if (ep->backedge) {
			p = ep->src;
			if (!visited->isMember(p->num)) {
				visited->add(p->num);
				if (p->LiveOut->isMember(num)) {
					t = Tree::MakeNew();
					::forest.PlantTree(t);
					trees.PlantTree(t);
					trees.map[num] = t->num;
					::forest.map[num] = t->num;
					t->var = num;
					t->lattice = p->depth;
					t->blocks->add(p->num);
					forest->add(p->num);
					GrowTree(t, p);
				}
				else {
					GrowTree(nullptr, p);
				}
			}
//		}
	}
	}
	// Next try moving through the previous basic blocks, there may not be edges
	// to them.
	for (p = b->prev; p; p = p->prev)
	{
		if (!visited->isMember(p->num)) {
			visited->add(p->num);
			if (p->LiveOut->isMember(num)) {
				t = Tree::MakeNew();
				::forest.PlantTree(t);
				trees.PlantTree(t);
				trees.map[num] = t->num;
				::forest.map[num] = t->num;
				t->var = num;
				t->lattice = p->depth;
				t->blocks->add(p->num);
				forest->add(p->num);
				GrowTree(t, p);
			}
			else {
				GrowTree(nullptr, p);
			}
		}
	}
	trees.var = this;
	dfs.printf("Visited r%d: ", num);
	visited->sprint(buf, sizeof(buf));
	dfs.printf(buf);
	dfs.printf("\n");
}

void Var::CreateForests()
{
	Var *v;

	Tree::treeno = 0;
	::forest.treecount = 0;
	for (v = currentFn->varlist; v; v = v->next) {
		v->visited->clear();
		v->forest->clear();
		v->CreateForest();
	}
}

// Find variable info or create if not found.

Var *Var::Find(int num)
{
	Var *vp;

	for (vp = currentFn->varlist; vp; vp = vp->next) {
		if (vp->num == num)
			break;
	}
	if (vp==nullptr) {
		vp = Var::MakeNew();
		vp->cnum = nvar-1;
		vp->num = num;
		vp->next = currentFn->varlist;
		currentFn->varlist = vp;
	}
	return (vp);
}

// Find variable info, but don't create

Var *Var::Find2(int num)
{
	Var *vp;
	Tree *t;

	for (vp = currentFn->varlist; vp; vp = vp->next) {
		//t = ::forest.trees[num];
		//if (t == nullptr)
		//	return (nullptr);
		if (vp->num == num)//map.newnums[num])
			return(vp);
	}
	return (nullptr);
}


// Find by machine register. Not used after renumbering.

Var *Var::FindByMac(int num)
{
	Var *vp;

	for (vp = currentFn->varlist; vp; vp = vp->next) {
		if (vp->num == num)
			return(vp);
	}
	return (nullptr);
}

Var *Var::FindByTreeno(int tn)
{
	Var *vp;
	Tree *t;
	int nn;

	for (vp = currentFn->varlist; vp; vp = vp->next) {
		for (nn = 0; nn < vp->trees.treecount; nn++) {
			t = vp->trees.trees[nn];
			if (t->treeno == tn)
				return (vp);
		}
	}
	return (nullptr);
}

void Var::Renumber(int num, int nnum)
{
	Var *vp;

	for (vp = currentFn->varlist; vp; vp = vp->next) {
		if (vp->num == num) {
			vp->num = -nnum;
		}
	}
}

void Var::RenumberNeg()
{
	Var *vp;

	for (vp = currentFn->varlist; vp; vp = vp->next) {
		if (vp->num < 0)
			vp->num = -vp->num;
	}
}

Var *Var::FindByCnum(int num)
{
	Var *vp;

	for (vp = currentFn->varlist; vp; vp = vp->next) {
		if (vp->cnum == num)
			return(vp);
	}
	return (nullptr);
}

CSet *Var::Find3(int reg, int blocknum)
{
	Var *v;
	Tree *t;
	int n;

	v = Find2(reg);
	// Find the tree with the basic block
	for (n = 0; n < v->trees.treecount; n++) {
		t = v->trees.trees[n];
		if (t->blocks->isMember(blocknum)) {
			return (t->blocks);
		}
	}
	// else error:
	return (nullptr);
}


// Find a specific tree that reg is associated with given
// the basic block number.

int Var::FindTreeno(int reg, int blocknum)
{
	Var *v;
	Tree *t;
	int n, m;

	// Find the associated variable
	v = Find2(reg);
	if (v == nullptr)
		return (-1);

	// Find the tree with the basic block. The individual trees in a given
	// var should be disjoint. Only one tree will contain the block.
	for (m = n = 0; n < v->trees.treecount; n++) {
		t = v->trees.trees[n];
		if (t->blocks->isMember(blocknum))
			return(t->num);
	}
	return (-1);
}


// Copy trees from one var to another.

void Var::Transplant(Var *v)
{
	int nn;

	for (nn = 0; nn < v->trees.treecount; nn++) {
		if (trees.treecount < 500) {
			trees.trees[trees.treecount] = v->trees.trees[nn];
			trees.treecount++;
		}
		else
			throw new C64PException(ERR_TOOMANY_TREES,1);
	}
}


// Coalescing currently doesn't make use of the interference graph.
// This algorithm is slow (n^2).

bool Var::Coalesce2()
{
	int reg1, reg2;
	Var *v1, *v2, *v3;
	Var *p, *q;
	Tree *t, *u;
	bool foundSameTree;
	bool improved;
	int nn, mm;

	improved = false;
	for (p = currentFn->varlist; p; p = p->next) {
		for (q = currentFn->varlist; q; q = q->next) {
			if (p == q)
				continue;
			reg1 = p->num;
			reg2 = q->num;
			// Registers used as register parameters cannot be coalesced.
			if ((reg1 >= regFirstArg && reg1 <= regLastArg)
				|| (reg2 >= regFirstArg && reg2 <= regLastArg))
				continue;
			// Coalesce the live ranges of the two variables into a single
			// range.
			//dfs.printf("Testing coalescence of live range r%d with ", reg1);
			//dfs.printf("r%d \n", reg2);
			//if (p->num)
				v1 = Var::Find2(p->num);
			//else
			//	v1 = p;
			//if (q->num)
				v2 = Var::Find2(q->num);
			//else
			//	v2 = q;
			if (v1 == nullptr || v2 == nullptr)
				continue;
			if (v1->trees.treecount == 0 || v2->trees.treecount == 0)
				continue;

			// Live ranges cannot be coalesced unless they are disjoint.
			if (!v1->forest->isDisjoint(*v2->forest)) {
				//dfs.printf("Live ranges overlap - no coalescence possible\n");
				continue;
			}

			dfs.printf("Coalescing live range r%d with ", reg1);
			dfs.printf("r%d \n", reg2);
			improved = true;
			//if (v1->trees.treecount == 0) {
			//	v3 = v1;
			//	v1 = v2;
			//	v2 = v3;
			//}

			v1->Transplant(v2);
			v1->forest->add(v2->forest);
/*
			for (nn = 0; nn < v2->trees.treecount; nn++) {
				t = v2->trees.trees[nn];
				foundSameTree = false;
				for (mm = 0; mm < v1->trees.treecount; mm++) {
					u = v1->trees.trees[mm];
					if (t->blocks->NumMember() >= u->blocks->NumMember()) {
						if (t->blocks->isSubset(*u->blocks)) {
							u->blocks->add(t->blocks);
							v1->forest->add(t->blocks);
							foundSameTree = true;
							break;
						}
					}
					else {
						if (u->blocks->isSubset(*t->blocks)) {
							foundSameTree = true;
							t->blocks->add(u->blocks);
							v2->forest->add(u->blocks);
							break;
						}
					}
				}

				if (!foundSameTree) {
					//t->next = v1->trees;
					//v1->trees = t;
					v1->Transplant(v2);
					v1->forest->add(v2->forest);
				}

			}
*/
			v2->trees.treecount = 0;
			v2->forest->clear();
			//v2->num = v1->num;
			//v2->Transplant(v1);
			//v2->forest->add(v1->forest);
		}
	}
	return (improved);
}

int Var::PathCompress(int reg, int blocknum, int *tr)
{
	Var *v;
	Tree *t;
	int n;

	*tr = -1;
	v = Find2(reg);
	if (v == nullptr) {
		*tr = -1;
		return (-1);
	}
	// Find the tree with the basic block
	for (n = 0; n < v->trees.treecount; n++) {
		t = v->trees.trees[n];
		if (t->blocks->isMember(blocknum)) {
			break;
		}
	}
	if (n < v->trees.treecount) {
		*tr = t->num;
		t->blocks->resetPtr();
		// The root of the tree is the lowest block number
		return (t->blocks->nextMember());
	}
	// else error: path not found
	return (-1);
}

void Var::DumpForests(int n)
{
	Var *vp;
	Tree *rg;
	int nn;
	char buf[2000];

	dfs.printf("<VarForests>%d\n", n);
	for (vp = currentFn->varlist; vp; vp = vp->next) {
		dfs.printf("Var%d:", vp->num);
		if (vp->trees.treecount > 0)
			dfs.printf(" %d trees\n", vp->trees.treecount);
		else
			dfs.printf(" no trees\n");
		for (nn = 0; nn < vp->trees.treecount; nn++) {
			dfs.printf("<Tree>%d ", vp->trees.trees[nn]->num);
			dfs.printf("Color:%d ", vp->trees.trees[nn]->color);
			rg = vp->trees.trees[nn];
			if (!rg->blocks->isEmpty()) {
				rg->blocks->sprint(buf, sizeof(buf));
				dfs.printf(buf);
				dfs.printf("</Tree>\n");
			}
		}
		dfs.printf("<Forest>");
		vp->forest->sprint(buf, sizeof(buf));
		dfs.printf(buf);
		dfs.printf("</Forest>\n");
	}
	dfs.printf("</VarForests>\n");
}


Var *Var::GetVarToSpill(CSet *exc)
{
	Var *vp;
	int tn, vn;
	int nn, mm;

	for (vp = currentFn->varlist; vp; vp = vp->next) {
		if (vp != this && vp->num > 2 && vp->num <= 17 && !exc->isMember(vp->num)) {
			tn = ::forest.map[this->num];
			vn = ::forest.map[vp->num];
			nn = min(tn, vn);
			mm = max(tn, vn);
			if (!iGraph.DoesInterfere(nn, mm)) {
				return (vp);
			}
		}
	}
	// error: no register could be spilled.
	return (nullptr);
}

