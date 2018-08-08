#include "stdafx.h"

extern BasicBlock *LastBlock;
Var *varlist;
Tree *alltrees[500];

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
int treeno;

Var *Var::MakeNew()
{
	Var *p;

	p = (Var *)allocx(sizeof(Var));
	p->forest = CSet::MakeNew();
	p->visited = CSet::MakeNew();
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
						t->next = trees;
						t->num = treeno;
						t->var = num;
						treeno++;
						trees = t;
					}
					t->tree->add(p->num);
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
						t->next = trees;
						t->num = treeno;
						t->var = num;
						treeno++;
						trees = t;
					}
					t->tree->add(p->num);
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

	treeno = 1;
	b = LastBlock;
	visited->add(b->num);
	// First see if a tree starts right at the last basic block.
	if (b->LiveOut->isMember(num)) {
		t = Tree::MakeNew();
		t->next = trees;
		t->num = treeno;
		t->var = num;
		treeno++;
		trees = t;
		t->tree->add(b->num);
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
					t->next = trees;
					t->num = treeno;
					t->var = num;
					treeno++;
					trees = t;
					t->tree->add(p->num);
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
					t->next = trees;
					t->num = treeno;
					t->var = num;
					treeno++;
					trees = t;
					t->tree->add(p->num);
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
				t->next = trees;
				t->num = treeno;
				t->var = num;
				treeno++;
				trees = t;
				t->tree->add(p->num);
				forest->add(p->num);
				GrowTree(t, p);
			}
			else {
				GrowTree(nullptr, p);
			}
		}
	}
	dfs.printf("Visited r%d: ", num);
	visited->sprint(buf, sizeof(buf));
	dfs.printf(buf);
	dfs.printf("\n");
}

void Var::CreateForests()
{
	Var *v;

	Tree::treecount = 0;
	treeno = 0;
	for (v = varlist; v; v = v->next) {
		v->visited->clear();
		v->forest->clear();
		v->CreateForest();
	}
}

// Find variable info or create if not found.

Var *Var::Find(int num)
{
	Var *vp;

	for (vp = varlist; vp; vp = vp->next) {
		if (vp->num == num)
			break;
	}
	if (vp==nullptr) {
		vp = Var::MakeNew();
		vp->num = num;
		vp->next = varlist;
		varlist = vp;
	}
	return (vp);
}

Var *Var::Find2(int num)
{
	Var *vp;

	for (vp = varlist; vp; vp = vp->next) {
		if (vp->num == num)
			return(vp);
	}
	return (nullptr);
}

void Var::DumpForests()
{
	Var *vp;
	Tree *rg;
	char buf[2000];

	dfs.printf("<VarForests>\n");
	for (vp = varlist; vp; vp = vp->next) {
		dfs.printf("Var%d:", vp->num);
		if (vp->trees)
			dfs.printf(" %d trees\n", vp->trees->num);
		else
			dfs.printf(" no trees\n");
		for (rg = vp->trees; rg; rg = rg->next) {
			if (!rg->tree->isEmpty()) {
				rg->tree->sprint(buf, sizeof(buf));
				dfs.printf(buf);
				dfs.printf("\n");
			}
		}
		vp->forest->sprint(buf, sizeof(buf));
		dfs.printf(buf);
		dfs.printf("\n");
	}
	dfs.printf("</VarForests>\n");
}
