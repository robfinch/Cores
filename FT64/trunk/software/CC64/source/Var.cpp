#include "stdafx.h"

extern BasicBlock *LastBlock;
Var *varlist;

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
	return (p);
}

// Live ranges are represented as tree structures.
// Since there could be multiple live ranges (trees) for any given variable
// the group of ranges (or trees) is called a forest.

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

void Var::CreateForests()
{
	Var *v;

	for (v = varlist; v; v = v->next) {
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

void Var::DumpForests()
{
	Var *vp;
	Tree *rg;
	char buf[2000];

	dfs.printf("<VarForests>\n");
	for (vp = varlist; vp; vp = vp->next) {
		dfs.printf("Var%d:\n", vp->num);
		for (rg = vp->trees; rg; rg = rg->next) {
			if (!rg->tree->isEmpty()) {
				rg->tree->sprint(buf, sizeof(buf));
				dfs.printf(buf);
				dfs.printf("\n");
			}
		}
	}
	dfs.printf("</VarForests>\n");
}
