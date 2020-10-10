#include "stdafx.h"

extern ENODE* makenodei(int nt, ENODE* v1, int i);

Expression::Expression()
{
	head = (TYP*)nullptr;
	tail = (TYP*)nullptr;
}

Function* Expression::MakeFunction(int symnum, SYM* sym, bool isPascal) {
	Function* fn = compiler.ff.MakeFunction(symnum, sym, isPascal);
	return (fn);
};


ENODE* Expression::ParseRealConst(ENODE** node)
{
	ENODE* pnode;
	TYP* tptr;

	pnode = compiler.ef.Makefnode(en_fcon, rval);
	pnode->constflag = TRUE;
	pnode->i = quadlit(&rval128);
	pnode->f128 = rval128;
	pnode->segment = rodataseg;
	switch (float_precision) {
	case 'Q': case 'q':
		tptr = &stdquad;
		break;
	case 'D': case 'd':
		tptr = &stddouble;
		break;
	case 'T': case 't':
		tptr = &stdtriple;
		break;
	case 'S': case 's':
		tptr = &stdflt;
		break;
	default:
		tptr = &stddouble;
		break;
	}
	pnode->SetType(tptr);
	tptr->isConst = TRUE;
	NextToken();
}

ENODE* Expression::ParseStringConst(ENODE** node, int sizeof_flag)
{
	char* str;
	ENODE* pnode;
	TYP* tptr;

	str = GetStrConst();
	if (sizeof_flag) {
		tptr = (TYP*)TYP::Make(bt_pointer, 0);
		tptr->size = strlen(str) + (int64_t)1;
		tptr->btp = TYP::Make(bt_char, 2)->GetIndex();// stdchar.GetIndex();
		tptr->GetBtp()->isConst = TRUE;
		tptr->val_flag = 1;
		tptr->isConst = TRUE;
		tptr->isUnsigned = TRUE;
	}
	else {
		tptr = &stdstring;
	}
	pnode = makenodei(en_labcon, (ENODE*)NULL, 0);
	if (sizeof_flag == 0)
		pnode->i = stringlit(str);
	free(str);
	pnode->etype = bt_pointer;
	pnode->esize = 2;
	pnode->constflag = TRUE;
	pnode->segment = rodataseg;
	pnode->SetType(tptr);
	tptr->isConst = TRUE;
	return (pnode);
}
