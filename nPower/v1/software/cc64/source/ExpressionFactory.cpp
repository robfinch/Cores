#include "stdafx.h"

ENODE* ExpressionFactory::Makefnode(int nt, double v1)
{
	ENODE* ep;
	ep = allocEnode();
	ep->nodetype = (enum e_node)nt;
	ep->constflag = TRUE;
	ep->isUnsigned = FALSE;
	ep->etype = bt_quad;
	ep->esize = -1;
	ep->f = v1;
	ep->f1 = v1;
	//    ep->f2 = v2;
	ep->p[0] = 0;
	ep->p[1] = 0;
	ep->p[2] = 0;
	return (ep);
}

ENODE* ExpressionFactory::Makepnode(int nt, Posit64 v1)
{
	ENODE* ep;
	ep = allocEnode();
	ep->nodetype = (enum e_node)nt;
	ep->constflag = TRUE;
	ep->isUnsigned = FALSE;
	ep->etype = bt_posit;
	ep->esize = -1;
	ep->posit = v1;
	//    ep->f2 = v2;
	ep->p[0] = 0;
	ep->p[1] = 0;
	ep->p[2] = 0;
	return (ep);
}

ENODE* ExpressionFactory::MakePositNode(int nt, Posit64 v1)
{
	ENODE* ep;
	ep = allocEnode();
	ep->nodetype = (enum e_node)nt;
	ep->constflag = TRUE;
	ep->isUnsigned = FALSE;
	ep->etype = bt_posit;
	ep->esize = -1;
	ep->posit = v1;
	//    ep->f2 = v2;
	ep->p[0] = 0;
	ep->p[1] = 0;
	ep->p[2] = 0;
	return (ep);
}

ENODE* ExpressionFactory::Makenode(int nt, ENODE* v1, ENODE* v2, ENODE* v3, ENODE* v4)
{
	ENODE* ep;
	ep = (ENODE*)xalloc(sizeof(ENODE));
	ep->nodetype = (enum e_node)nt;

	if (v1 != nullptr && v2 != nullptr) {
		ep->constflag = v1->constflag && v2->constflag;
		ep->isUnsigned = v1->isUnsigned && v2->isUnsigned;
	}
	else if (v1 != nullptr) {
		ep->constflag = v1->constflag;
		ep->isUnsigned = v1->isUnsigned;
	}
	else if (v2 != nullptr) {
		ep->constflag = v2->constflag;
		ep->isUnsigned = v2->isUnsigned;
	}
	ep->etype = bt_void;
	ep->esize = -1;
	ep->p[0] = v1;
	ep->p[1] = v2;
	ep->p[2] = v3;
	ep->p[3] = v4;
	return (ep);
}

ENODE* ExpressionFactory::Makenode(int nt, ENODE* v1, ENODE* v2, ENODE* v3)
{
	ENODE* ep;
	ep = (ENODE*)xalloc(sizeof(ENODE));
	ep->nodetype = (enum e_node)nt;

	if (v1 != nullptr && v2 != nullptr) {
		ep->constflag = v1->constflag && v2->constflag;
		ep->isUnsigned = v1->isUnsigned && v2->isUnsigned;
	}
	else if (v1 != nullptr) {
		ep->constflag = v1->constflag;
		ep->isUnsigned = v1->isUnsigned;
	}
	else if (v2 != nullptr) {
		ep->constflag = v2->constflag;
		ep->isUnsigned = v2->isUnsigned;
	}
	ep->etype = bt_void;
	ep->esize = -1;
	ep->p[0] = v1;
	ep->p[1] = v2;
	ep->p[2] = v3;
	return (ep);
}

ENODE* ExpressionFactory::Makenode(int nt, ENODE* v1, ENODE* v2)
{
	ENODE* ep;
	ep = (ENODE*)xalloc(sizeof(ENODE));
	ep->nodetype = (enum e_node)nt;

	if (v1 != nullptr && v2 != nullptr) {
		ep->constflag = v1->constflag && v2->constflag;
		ep->isUnsigned = v1->isUnsigned && v2->isUnsigned;
	}
	else if (v1 != nullptr) {
		ep->constflag = v1->constflag;
		ep->isUnsigned = v1->isUnsigned;
	}
	else if (v2 != nullptr) {
		ep->constflag = v2->constflag;
		ep->isUnsigned = v2->isUnsigned;
	}
	ep->etype = bt_void;
	ep->esize = -1;
	ep->p[0] = v1;
	ep->p[1] = v2;
	return (ep);
}

ENODE* ExpressionFactory::Makenode()
{
	ENODE* ep;
	ep = (ENODE*)xalloc(sizeof(ENODE));
	return (ep);
}
