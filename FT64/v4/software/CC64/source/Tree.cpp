#include "stdafx.h"

int Tree::treecount;

Tree *Tree::MakeNew() {
	Tree *t;
	t = (Tree*)allocx(sizeof(Tree));
	t->tree = CSet::MakeNew();
	alltrees[treecount] = t;
	treecount++;
	return (t);
}
