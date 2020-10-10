#include "stdafx.h"

ENODE* ExpressionFactory::Makefnode(int nt, double v1)
{
	ENODE* ep;
	ep = allocEnode();
	ep->nodetype = (enum e_node)nt;
	ep->constflag = TRUE;
	ep->isUnsigned = FALSE;
	ep->etype = bt_void;
	ep->esize = -1;
	ep->f = v1;
	ep->f1 = v1;
	//    ep->f2 = v2;
	ep->p[0] = 0;
	ep->p[1] = 0;
	ep->p[2] = 0;
	return (ep);
}
