#include "stdafx.h"

extern int defaultcc;
extern SYM* currentClass;
extern ENODE* makenodei(int nt, ENODE* v1, int i);
extern ENODE* makefcnode(int nt, ENODE* v1, ENODE* v2, SYM* sp);
extern ENODE* makefqnode(int nt, Float128* f128);
extern TYP* CondDeref(ENODE** node, TYP* tp);
extern int IsBeginningOfTypecast(int st);
extern int NumericLiteral(ENODE*);

Expression::Expression()
{
	int nn;

	head = (TYP*)nullptr;
	tail = (TYP*)nullptr;
	sizeof_flag = 0;
	totsz = 0;
	got_pa = false;
	cnt = 0;
	numdimen = 0;
	pep1 = (ENODE*)nullptr;
	isMember = false;
	for (nn = 0; nn < 10; nn++)
		sa[nn] = 0;
	parsingAggregate = 0;
}

Function* Expression::MakeFunction(int symnum, SYM* sym, bool isPascal) {
	Function* fn = compiler.ff.MakeFunction(symnum, sym, isPascal);
	return (fn);
};

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

ENODE* Expression::SetIntConstSize(TYP* tptr, int64_t val)
{
	ENODE* pnode;

	pnode = makeinode(en_icon, val);
	pnode->constflag = TRUE;
	if (val >= -128 && ival < 128)
		pnode->esize = 1;
	else if (val >= -32768 && val < 32768)
		pnode->esize = 2;
	else if (val >= -2147483648LL && val < 2147483648LL)
		pnode->esize = 4;
	else
		pnode->esize = 8;
/*
* ???
	else if (val >= -54975581300LL && val < 54975581300LL)
		pnode->esize = 5;
	else
		pnode->esize = 2;
*/
	pnode->SetType(tptr);
	return (pnode);
}


ENODE* Expression::ParseCharConst(ENODE** node, int sz)
{
	ENODE* pnode;
	TYP* tptr;

	tptr = &stdchar;
	pnode = makeinode(en_icon, ival);
	pnode->constflag = TRUE;
	pnode->esize = sz;
	pnode->SetType(tptr);
	NextToken();
	return (pnode);
}

ENODE* Expression::ParseFloatMax()
{
	ENODE* pnode;
	TYP* tptr;

	tptr = &stdquad;
	pnode = compiler.ef.Makefnode(en_fcon, rval);
	pnode->constflag = TRUE;
	pnode->SetType(tptr);
//	pnode->i = NumericLiteral(Float128::FloatMax());
	if (parsingAggregate == 0 && sizeof_flag == 0)
		pnode->i = NumericLiteral(pnode);
	NextToken();
	return (pnode);
}

ENODE* Expression::ParseRealConst(ENODE** node)
{
	ENODE* pnode;
	TYP* tptr;

	pnode = compiler.ef.Makefnode(en_fcon, rval);
	pnode->constflag = TRUE;
	//pnode->i = quadlit(&rval128);
	pnode->f128 = rval128;
	if (parsingAggregate == 0 && sizeof_flag == 0)
		pnode->i = NumericLiteral(pnode);
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
	NextToken();
	return (pnode);
}

ENODE* Expression::ParsePositConst(ENODE** node)
{
	ENODE* pnode;
	TYP* tptr;

	pnode = compiler.ef.MakePositNode(en_pcon, pval64);
	pnode->constflag = TRUE;
	pnode->posit = pval64;
	//if (parsingAggregate==0 && sizeof_flag == 0)
	//	pnode->i = NumericLiteral(pnode);
	pnode->segment = codeseg;
	tptr = &stdposit;
	switch (float_precision) {
	case 'D': case 'd':
		tptr = &stdposit;
		pnode->esize = 8;
		break;
	case 'S': case 's':
		tptr = &stdposit32;
		pnode->esize = 4;
		break;
	case 'H': case 'h':
		tptr = &stdposit16;
		pnode->esize = 2;
		break;
	default:
		tptr = &stdposit;
		pnode->esize = 8;
		break;
	}
	pnode->SetType(tptr);
	NextToken();
	return (pnode);
}

ENODE* Expression::ParseStringConst(ENODE** node)
{
	char* str;
	ENODE* pnode;
	TYP* tptr;

	str = GetStrConst();
	if (sizeof_flag) {
		tptr = (TYP*)TYP::Make(bt_pointer, 0);
		tptr->size = strlen(str) + (int64_t)1;
		tptr->btp = TYP::Make(bt_char, 2)->GetIndex();// stdchar.GetIndex();
		tptr->val_flag = 1;
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
	return (pnode);
}

ENODE* Expression::ParseInlineStringConst(ENODE** node)
{
	ENODE* pnode;
	TYP* tptr;
	char* str;

	str = GetStrConst();
	if (sizeof_flag) {
		tptr = (TYP*)TYP::Make(bt_pointer, 0);
		tptr->size = strlen(str) + (int64_t)1;
		tptr->btp = TYP::Make(bt_ichar, 2)->GetIndex();// stdchar.GetIndex();
		tptr->val_flag = 1;
		tptr->isUnsigned = TRUE;
	}
	else {
		tptr = &stdistring;
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
	return (pnode);
}

ENODE* Expression::ParseStringConstWithSizePrefix(ENODE** node)
{
	ENODE* pnode;
	TYP* tptr;
	char* str;

	str = GetStrConst();
	if (sizeof_flag) {
		tptr = (TYP*)TYP::Make(bt_pointer, 0);
		tptr->size = strlen(str) + (int64_t)1;
		switch (str[0]) {
		case 'B':
			tptr->btp = TYP::Make(bt_byte, 1)->GetIndex();
			break;
		case 'W':
			tptr->btp = TYP::Make(bt_char, 2)->GetIndex();
			break;
		case 'T':
			tptr->btp = TYP::Make(bt_short, 4)->GetIndex();
			break;
		case 'O':
			tptr->btp = TYP::Make(bt_long, 8)->GetIndex();
			break;
		}
		tptr->val_flag = 1;
		tptr->isUnsigned = TRUE;
	}
	else {
		tptr = &stdastring;
	}
	pnode = makenodei(en_labcon, (ENODE*)NULL, 0);
	if (sizeof_flag == 0)
		pnode->i = stringlit(str);
	switch (str[0]) {
	case 'B': pnode->esize = 1; break;
	case 'W': pnode->esize = 2; break;
	case 'T': pnode->esize = 4; break;
	case 'O': pnode->esize = 8; break;
	}
	free(str);
	pnode->etype = bt_pointer;
	pnode->constflag = TRUE;
	pnode->segment = rodataseg;
	pnode->SetType(tptr);
	return (pnode);
}

ENODE* Expression::ParseThis(ENODE** node)
{
	dfs.puts("<ExprThis>");
	ENODE* pnode;
	TYP* tptr;
	TYP* tptr2;

	tptr2 = TYP::Make(bt_class, 0);
	if (currentClass == nullptr) {
		error(ERR_THIS);
	}
	else {
		// This does not make copies of contained classes / structures / unions
		// It uses the existing references. See TYP::Copy()
		memcpy(tptr2, currentClass->tp, sizeof(TYP));
	}
	NextToken();
	tptr = TYP::Make(bt_pointer, sizeOfPtr);
	tptr->btp = tptr2->GetIndex();
	tptr->isUnsigned = TRUE;
	dfs.puts((char*)tptr->GetBtp()->sname->c_str());
	pnode = makeinode(en_regvar, regCLP);
	pnode->SetType(tptr);
	dfs.puts("</ExprThis>");
	return (pnode);
}

ENODE* Expression::ParseAggregate(ENODE** node)
{
	ENODE* pnode;
	TYP* tptr;
	int64_t sz = 0;
	ENODE* list, * cnode;
	bool cnst = true;
	bool consistentType = true;
	TYP* tptr2;
	int64_t n;
	int64_t pos = 0;

	parsingAggregate++;
	NextToken();
	head = tail = nullptr;
	list = makenode(en_list, nullptr, nullptr);
	tptr2 = nullptr;
	while (lastst != end) {
		if (lastst == openbr) {
			n = GetConstExpression(&cnode);
			needpunc(closebr,49);
			while (pos < n && pos < 1000000) {
				pnode = makenode(en_void, nullptr, nullptr);
				pnode->SetType(tptr2);
				list->AddToList(pnode);
				pos++;
			}
		}
		tptr = ParseNonCommaExpression(&pnode);
		if (!pnode->constflag)
			cnst = false;
		if (tptr2 != nullptr && tptr->type != tptr2->type)
			consistentType = false;
		pnode->SetType(tptr);
		//sz = sz + tptr->size;
		sz = sz + pnode->esize;
		list->esize = pnode->esize;
		list->AddToList(pnode);
		pos++;
		if (lastst != comma)
			break;
		NextToken();
		tptr2 = tptr;
	}
	needpunc(end, 9);
	pnode = makenode(en_aggregate, list, nullptr);
	pnode->SetType(tptr = TYP::Make(consistentType ? bt_array : bt_struct, sz));
	pnode->esize = sz;
	pnode->i = litlist(pnode);
	pnode->segment = cnst ? rodataseg : dataseg;
	list->i = pnode->i;
	list->segment = pnode->segment;
	parsingAggregate--;
	return (pnode);
}

ENODE* Expression::ParseNameRef()
{
	ENODE* pnode;
	TYP* tptr;

	tptr = nameref(&pnode, TRUE);
	if (tptr == nullptr) {
		if (currentSym) {
			if (currentSym->name->compare(lastid) == 0) {
				tptr = currentSym->tp;
			}
		}
	}
	// Convert a reference to a constant to a constant. Need this for
	// GetIntegerExpression().
	if (pnode->IsRefType()) {
		if (pnode->p[0]) {
			if (pnode->p[0]->nodetype == en_icon) {
				pnode = SetIntConstSize(tptr, pnode->p[0]->i);
			}
		}
		//else if (pnode->p[0]->nodetype == en_fcon) {
		//	rval = pnode->p[0]->f;
		//	rval128 = pnode->p[0]->f128;
		//	goto j2;
		//}
	}
	pnode->SetType(tptr);
	//pnode->p[3] = (ENODE *)tptr->size;
	//				if (pnode->nodetype==en_nacon)
	//					pnode->p[0] = makenode(en_list,tptr->BuildEnodeTree(),nullptr);
			//else if (sp = gsyms->Find(lastid, false)) {
			//	if (TABLE::matchno > 1) {
			//		for (i = 0; i < TABLE::matchno) {
			//			sp = TABLE::match[i];
			//		}
			//	}
			//	if (sp->tp == &stdconst) {
			//		ival = sp->value.i;
			//		lastst = iconst;
			//		return;
			//	}
			//}

	/*
			// Try and find the symbol, if not found, assume a function
			// but only if it's followed by a (
			if (TABLE::matchno==0) {
				while( my_isspace(lastch) )
					getch();
				if( lastch == '(') {
					NextToken();
					tptr = ExprFunction(nullptr, &pnode);
				}
				else {
					tptr = nameref(&pnode,TRUE);
				}
			}
			else
	*/
	/*
	if (tptr==NULL) {
		tptr = allocTYP();
		tptr->type = bt_long;
		tptr->typeno = bt_long;
		tptr->alignment = 8;
		tptr->bit_offset = 0;
		tptr->GetBtp() = nullptr;
		tptr->isArray = false;
		tptr->isConst = false;
		tptr->isIO = false;
		tptr->isShort = false;
		tptr->isUnsigned = false;
		tptr->size = 8;
		tptr->sname = my_strdup(lastid);
	}
	*/
	return (pnode);
}

ENODE* Expression::ParseMinus()
{
	ENODE* ep1;
	TYP* tp;

	NextToken();
	tp = ParseCastExpression(&ep1);
	if (tp == NULL) {
		error(ERR_IDEXPECT);
		return (nullptr);
	}
	else if (ep1->constflag && (ep1->nodetype == en_icon)) {
		ep1->i = -ep1->i;
	}
	else if (ep1->constflag && (ep1->nodetype == en_fcon)) {
		ep1->f = -ep1->f;
		ep1->f128.sign = !ep1->f128.sign;
		// A new literal label is required.
		//ep1->i = quadlit(&ep1->f128);
		ep1->i = NumericLiteral(ep1);
	}
	else
	{
		ep1 = makenode(en_uminus, ep1, (ENODE*)NULL);
		ep1->constflag = ep1->p[0]->constflag;
		ep1->isUnsigned = ep1->p[0]->isUnsigned;
		ep1->esize = tp->size;
		ep1->etype = (e_bt)tp->type;
	}
	ep1->SetType(tp);
	return (ep1);
}

ENODE* Expression::ParseNot()
{
	ENODE* ep1;
	TYP* tp;

	NextToken();
	tp = ParseCastExpression(&ep1);
	if (tp == NULL) {
		error(ERR_IDEXPECT);
		return (nullptr);
	}
	ep1 = makenode(en_not, ep1, (ENODE*)NULL);
	ep1->constflag = ep1->p[0]->constflag;
	ep1->isUnsigned = ep1->p[0]->isUnsigned;
	ep1->SetType(tp);
	ep1->esize = tp->size;
	return (ep1);
}

ENODE* Expression::ParseCom()
{
	ENODE* ep1;
	TYP* tp;

	NextToken();
	tp = ParseCastExpression(&ep1);
	if (tp == NULL) {
		error(ERR_IDEXPECT);
		return (nullptr);
	}
	ep1 = makenode(en_compl, ep1, (ENODE*)NULL);
	ep1->constflag = ep1->p[0]->constflag;
	ep1->isUnsigned = ep1->p[0]->isUnsigned;
	ep1->SetType(tp);
	ep1->esize = tp->size;
	return (ep1);
}

ENODE* Expression::ParseStar()
{
	ENODE* ep1;
	TYP* tp, *tp1;
	int typ;

	NextToken();
	tp = ParseCastExpression(&ep1);
	if (tp == NULL) {
		error(ERR_IDEXPECT);
		return (nullptr);
	}
	if (tp->GetBtp() == NULL)
		error(ERR_DEREF);
	else {
		// A star before a function pointer just means that we want to
		// invoke the function. We want to retain the pointer to the
		// function as the type.
		if (tp->GetBtp()->type != bt_func && tp->GetBtp()->type != bt_ifunc) {
			tp = tp->GetBtp();
		}
		else
			goto j1;
		//else {
		//	tp1 = tp;
		//	break;	// Don't derefence the function pointer
		//}
	}
	tp1 = tp;
	// Debugging?
	if (tp->type == bt_pointer)
		typ = tp->GetBtp()->type;
	//Autoincdec(tp,&ep1);
	tp = CondDeref(&ep1, tp);
j1:
	ep1->SetType(tp);
	return (ep1);
}

ENODE* Expression::ParseSizeof()
{
	Declaration decl;
	ENODE* ep1;
	TYP* tp, * tp1;
	SYM* sp;
	bool flag2 = false;

	NextToken();
	
	if (lastst == openpa) {
		flag2 = true;
		NextToken();
	}
	
//	ParseCastExpression(&ep1);
	if (flag2 && IsBeginningOfTypecast(lastst)) {
		tp = head;
		tp1 = tail;
		decl.ParseSpecifier(0, &sp, sc_none);
		decl.ParsePrefix(FALSE);
		if (decl.head != NULL)
			ep1 = makeinode(en_icon, decl.head->size);
		else {
			error(ERR_IDEXPECT);
			ep1 = makeinode(en_icon, 1);
		}
		head = tp;
		tail = tp1;
	}
	else if (flag2) {
		sizeof_flag++;
		tp = ParseCastExpression(&ep1);
		sizeof_flag--;
		if (tp == 0) {
			error(ERR_SYNTAX);
			ep1 = makeinode(en_icon, 1);
		}
		else
			ep1 = makeinode(en_icon, (long)tp->size);
	}
	else {
		sizeof_flag++;
		tp = ParseUnaryExpression(&ep1, false);
		sizeof_flag--;
		if (tp == 0) {
			error(ERR_SYNTAX);
			ep1 = makeinode(en_icon, 1);
		}
		else
			ep1 = makeinode(en_icon, (long)tp->size);
	}
	if (flag2)
		needpunc(closepa, 2);
	ep1->constflag = TRUE;
	ep1->esize = 2;//??? 8?
	tp = &stdint;
	ep1->SetType(tp);
	return (ep1);
}

ENODE* Expression::ParseTypenum()
{
	ENODE* ep1;
	TYP* tp, * tp1;
	Declaration decl;
	SYM* sp;

	NextToken();
	needpunc(openpa, 3);
	tp = head;
	tp1 = tail;
	decl.ParseSpecifier(0, &sp, sc_none);
	decl.ParsePrefix(FALSE);
	if (head != NULL)
		ep1 = makeinode(en_icon, head->GetHash());
	else {
		error(ERR_IDEXPECT);
		ep1 = makeinode(en_icon, 1);
	}
	head = tp;
	tail = tp1;
	ep1->constflag = TRUE;
	ep1->esize = 2;
	tp = &stdint;
	if (ep1) ep1->SetType(tp);
	needpunc(closepa, 4);
	return (ep1);
}

ENODE* Expression::ParseNew(bool autonew)
{
	ENODE* ep1, *ep2, * ep3, * ep4, * ep5;
	TYP* tp, * tp1;
	Declaration decl;
	SYM* sp;

	std::string* name = new std::string(autonew ? "__autonew" : "__new");

	currentFn->UsesNew = TRUE;
	currentFn->IsLeaf = FALSE;
	NextToken();
	if (IsBeginningOfTypecast(lastst)) {

		tp = head;
		tp1 = tail;
		decl.ParseSpecifier(0, &sp, sc_none);
		decl.ParsePrefix(FALSE);
		if (head != NULL)
			ep1 = makeinode(en_icon, head->size + 64);
		else {
			error(ERR_IDEXPECT);
			ep1 = makeinode(en_icon, 65);
		}
		ep4 = nullptr;
		ep2 = makeinode(en_icon, head->GetHash());
		ep3 = makenode(en_object_list, nullptr, nullptr);
		//ep4 = makeinode(en_icon, head->typeno);
		ep5 = makenode(en_void, ep1, nullptr);
		//ep5 = nullptr;
		//ep5 = makenode(en_void,ep2,ep5);
		//ep5 = makenode(en_void,ep3,ep5);
		//ep5 = makenode(en_void, ep4, ep5);
		ep2 = makesnode(en_cnacon, name, name, 0);
		ep1 = makefcnode(en_fcall, ep2, ep5, nullptr);
		head = tp;
		tail = tp1;
	}
	else {
		sizeof_flag++;
		tp = ParseUnaryExpression(&ep1, got_pa);
		sizeof_flag--;
		if (tp == 0) {
			error(ERR_SYNTAX);
			ep1 = makeinode(en_icon, 65);
		}
		else
			ep1 = makeinode(en_icon, (int64_t)tp->size+64);
		ep3 = makenode(en_void, ep1, nullptr);
		ep2 = makesnode(en_cnacon, name, name, 0);
		ep1 = makefcnode(en_fcall, ep2, ep3, nullptr);
	}
	ep1->isAutonew = autonew;
	if (autonew)
		currentFn->hasAutonew = true;
	if (ep1) ep1->SetType(tp);
	return (ep1);
}

ENODE* Expression::ParseDelete()
{
	ENODE* ep1, *ep2;
	TYP* tp;
	bool needbr = false;

	currentFn->IsLeaf = FALSE;
	NextToken();
	{
		std::string* name = new std::string("__delete");

		if (lastst == openbr)
			NextToken();
		tp = ParseCastExpression(&ep1);
		if (needbr)
			needpunc(closebr, 50);
		tp = deref(&ep1, tp);
		ep2 = makesnode(en_cnacon, name, name, 0);
		ep1 = makefcnode(en_fcall, ep2, ep1, nullptr);
		if (ep1) ep1->SetType(tp);
	}
	return (ep1);
}

ENODE* Expression::ParseAddressOf()
{
	ENODE* ep1, * ep2;
	TYP* tp, * tp1;

	NextToken();
	tp = ParseCastExpression(&ep1);
	if (tp == NULL) {
		error(ERR_IDEXPECT);
		return (nullptr);
	}
	if (ep1) {
		/*
						t = ep1->tp->type;
		//				if (IsLValue(ep1) && !(t == bt_pointer || t == bt_struct || t == bt_union || t == bt_class)) {
						if (t == bt_struct || t == bt_union || t == bt_class) {
							////ep1 = ep1->p[0];
							//if (ep1) {
							//	ep1 = makenode(en_addrof, ep1, nullptr);
							//	ep1->esize = 8;     // converted to a pointer so size is now 8
							//}
						}
						else */
		ep2 = ep1;
		if (IsLValue(ep1)) {
			if (ep1->nodetype != en_add) {	// array or pointer manipulation
				if (ep1->p[0])	// Cheesy hack
					ep1 = ep1->p[0];
			}
		}
		ep1->esize = sizeOfPtr;		// converted to a pointer so size is now 8
		tp1 = TYP::Make(bt_pointer, sizeOfPtr);
		tp1->btp = tp->GetIndex();
		tp1->val_flag = FALSE;
		tp1->isUnsigned = TRUE;
		tp = tp1;
	}
	if (ep1) ep1->SetType(tp);
	return (ep1);
}

ENODE* Expression::ParseMulf()
{
	ENODE* ep1, * ep2;
	TYP* tp, * tp1, * tp2;

	NextToken();
	needpunc(openpa, 46);
	tp1 = ParseNonCommaExpression(&ep1);
	needpunc(comma, 47);
	tp2 = ParseNonCommaExpression(&ep2);
	needpunc(closepa, 48);
	ep1 = makenode(en_mulf, ep1, ep2);
	ep1->isUnsigned = TRUE;
	ep1->esize = sizeOfWord;
	tp = &stduint;
	ep1->SetType(tp);
	return (ep1);
}

ENODE* Expression::ParseBytndx()
{
	ENODE* ep1, * ep2;
	TYP* tp, * tp1, * tp2;

	NextToken();
	needpunc(openpa, 46);
	tp1 = ParseNonCommaExpression(&ep1);
	needpunc(comma, 47);
	tp2 = ParseNonCommaExpression(&ep2);
	needpunc(closepa, 48);
	ep1 = makenode(en_bytendx, ep1, ep2);
	ep1->esize = sizeOfWord;
	tp = &stdint;
	if (ep1) ep1->SetType(tp);
	return (ep1);
}

ENODE* Expression::ParseWydndx()
{
	ENODE* ep1, * ep2;
	TYP* tp, * tp1, * tp2;

	NextToken();
	needpunc(openpa, 46);
	tp1 = ParseNonCommaExpression(&ep1);
	needpunc(comma, 47);
	tp2 = ParseNonCommaExpression(&ep2);
	needpunc(closepa, 48);
	ep1 = makenode(en_wydendx, ep1, ep2);
	ep1->esize = sizeOfWord;
	tp = &stdint;
	if (ep1) ep1->SetType(tp);
	return (ep1);
}

// Parsing other intrinsics

/*
case kw_abs:
	NextToken();
	if (lastst==openpa) {
		flag2 = TRUE;
		NextToken();
	}
			tp = ParseCastExpression(&ep1);
			if( tp == NULL ) {
					error(ERR_IDEXPECT);
					return (TYP *)NULL;
			}
			ep1 = makenode(en_abs,ep1,(ENODE *)NULL);
			ep1->constflag = ep1->p[0]->constflag;
	ep1->isUnsigned = ep1->p[0]->isUnsigned;
	ep1->esize = tp->size;
	if (flag2)
		needpunc(closepa,2);
	break;

case kw_max:
case kw_min:
	{
		TYP *tp1, *tp2, *tp3;

		flag2 = lastst==kw_max;
		NextToken();
		needpunc(comma,2);
		tp1 = ParseCastExpression(&ep1);
		if( tp1 == NULL ) {
			error(ERR_IDEXPECT);
			return (TYP *)NULL;
		}
		needpunc(comma,2);
		tp2 = ParseCastExpression(&ep2);
		if( tp1 == NULL ) {
			error(ERR_IDEXPECT);
			return (TYP *)NULL;
		}
		if (lastst==comma) {
			NextToken();
			tp3 = ParseCastExpression(&ep3);
			if( tp1 == NULL ) {
				error(ERR_IDEXPECT);
				return (TYP *)NULL;
			}
		}
		else
			tp3 = nullptr;
		tp = forcefit(&ep2,tp2,&ep1,tp1,1);
		tp = forcefit(&ep3,tp3,&ep2,tp,1);
		ep1 = makenode(flag2 ? en_max : en_min,ep1,ep2);
		ep1->p[2] = ep3;
		ep1->constflag = ep1->p[0]->constflag & ep2->p[0]->constflag & ep3->p[0]->constflag;
		ep1->isUnsigned = ep1->p[0]->isUnsigned;
		ep1->esize = tp->size;
		needpunc(closepa,2);
	}
	break;
*/

SYM* Expression::FindMember(TABLE* tbl, char* name)
{
	int ii;
	SYM* sp, * first, * mbr;
	TYP* tp;

	ii = tbl->FindRising(name);
	if (ii == 0)
		goto j1;
	sp = TABLE::match[ii - 1];
	sp = sp->FindRisingMatch();
	if (sp != nullptr)
		return (sp);
	if (sp == NULL) {
		goto j1;
	}
	if (sp->IsPrivate && sp->parent != currentFn->sym->parent) {
		error(ERR_PRIVATE);
		return (nullptr);
	}
j1:
	first = sp = SYM::GetPtr(tbl->head);
	do {
		if (sp == nullptr)
			break;
		if (sp->name->compare(name) == 0) {
			return (sp);
		}
		sp = sp->GetNextPtr();
	} while (sp != first);
	first = sp = SYM::GetPtr(tbl->head);
	do {
		if (sp == nullptr)
			break;
		tp = sp->tp;
		mbr = FindMember(&tp->lst, name);
		if (mbr)
			return (mbr);
		sp = sp->GetNextPtr();
	} while (sp != first);
	return (nullptr);
}

SYM* Expression::FindMember(TYP* tp1, char *name)
{
	int ii;
	SYM* sp, * first, *mbr;
	TYP* tp;

	ii = tp1->lst.FindRising(name);
	if (ii == 0)
		goto j1;
	sp = TABLE::match[ii - 1];
	sp = sp->FindRisingMatch();
	if (sp != nullptr)
		return (sp);
	if (sp == NULL) {
		goto j1;
	}
	if (sp->IsPrivate && sp->parent != currentFn->sym->parent) {
		error(ERR_PRIVATE);
		return (nullptr);
	}
j1:
	first = sp = SYM::GetPtr(tp1->lst.head);
	do {
		if (sp == nullptr)
			break;
		if (sp->name->compare(name) == 0) {
			return (sp);
		}
		sp = sp->GetNextPtr();
	} while (sp != first);
	first = sp = SYM::GetPtr(tp1->lst.head);
	do {
		if (sp == nullptr)
			break;
		tp = sp->tp;
		mbr = FindMember(tp, name);
		if (mbr)
			return (mbr);
		sp = sp->GetNextPtr();
	} while (sp != first);
	mbr = FindMember(&tagtable, name);
	return (mbr);
}


ENODE* Expression::ParseDotOperator(TYP* tp1, ENODE *ep1)
{
	TypeArray typearray;
	ENODE* ep2, * ep3, * qnode;
	TYP* ptp1;
	SYM* sp;
	char* name;
	int ii;
	bool iu;

	ExpressionHasReference = true;
	if (tp1 == nullptr) {
		error(ERR_UNDEFINED);
		goto xit;
	}
	NextToken();       /* past -> or . */
	if (tp1->IsVectorType()) {
		ParseNonAssignExpression(&qnode);
		ep2 = makenode(en_shl, qnode, makeinode(en_icon, 3));
		// The dot operation will deference the result below so the
		// old dereference operation isn't needed. It is stripped 
		// off by using ep->p[0] rather than ep.
		ep1 = makenode(en_add, ep1->p[0], ep2);
		tp1 = tp1->GetBtp();
		tp1 = CondDeref(&ep1, tp1);
		goto xit;
	}
	if (lastst != id) {
		error(ERR_IDEXPECT);
		goto xit;
	}
	dfs.printf("dot search: %p\r\n", (char*)&tp1->lst);
	ptp1 = tp1;
	pep1 = ep1;
	name = lastid;
	sp = FindMember(tp1, name);
	/*
	ii = tp1->lst.FindRising(name);
	if (ii == 0) {
		dfs.printf("Nomember1");
		error(ERR_NOMEMBER);
		goto xit;
	}
	sp = TABLE::match[ii - 1];
	sp = sp->FindRisingMatch();
	if (sp == NULL) {
		dfs.printf("Nomember2");
		error(ERR_NOMEMBER);
		goto xit;
	}
	if (sp->IsPrivate && sp->parent != currentFn->sym->parent) {
		error(ERR_PRIVATE);
		goto xit;
	}
	*/
	if (sp == nullptr) {
		dfs.printf("Nomember1");
		error(ERR_NOMEMBER);
		goto xit;
	}
	tp1 = sp->tp;
	dfs.printf("tp1->type:%d", tp1->type);
	if (tp1 == nullptr)
		throw new C64PException(ERR_NULLPOINTER, 5);
	if (tp1->type == bt_ifunc || tp1->type == bt_func) {
		// build the name vector and create a nacon node.
		dfs.printf("%s is a func\n", (char*)sp->name->c_str());
		NextToken();
		if (lastst == openpa) {
			NextToken();
			ep2 = ParseArgumentList(pep1, &typearray);
			typearray.Print();
			sp = Function::FindExactMatch(ii, name, bt_long, &typearray)->sym;
			if (sp) {
				//						sp = TABLE::match[TABLE::matchno-1];
				ep3 = makesnode(en_cnacon, sp->name, sp->mangledName, sp->value.i);
				ep3->isPascal = sp->fi->IsPascal;
				ep1 = makenode(en_fcall, ep3, ep2);
				ep1->isPascal = ep3->isPascal;
				tp1 = sp->tp->GetBtp();
				currentFn->IsLeaf = FALSE;
			}
			else {
				error(ERR_METHOD_NOTFOUND);
				goto xit;
			}
			ep1->SetType(tp1);
			goto xit;
		}
		// Else: we likely wanted the addres of the function since the
		// function is referenced without o parameter list indicator. Goto
		// the regular processing code.
		goto j2;
	}
	else {
	j2:
		dfs.printf("tp1->type:%d", tp1->type);
		qnode = makeinode(en_icon, sp->value.i);
		qnode->constflag = TRUE;
		if (sp->tp->bit_offset) {
			qnode->bit_offset = makeinode(en_icon, sp->tp->bit_offset->i);
			qnode->bit_width = makeinode(en_icon, sp->tp->bit_width->i);
		}
		iu = ep1->isUnsigned;
		ep1 = makenode(en_add, ep1, qnode);
		ep1->bit_offset = qnode->bit_offset;
		ep1->bit_width = qnode->bit_width;
		ep1->isPascal = ep1->p[0]->isPascal;
		ep1->constflag = ep1->p[0]->constflag;
		ep1->isUnsigned = iu;
		ep1->esize = sizeOfWord;
		ep1->p[2] = pep1;
		//if (tp1->type==bt_pointer && (tp1->GetBtp()->type==bt_func || tp1->GetBtp()->type==bt_ifunc))
		//	dfs.printf("Pointer to func");
		//else
		tp1 = CondDeref(&ep1, tp1);
		ep1->SetType(tp1);
		dfs.printf("tp1->type:%d", tp1->type);
	}
	if (tp1 == nullptr)
		getchar();
	NextToken();       /* past id */
	dfs.printf("B");
xit:
	ep1->tp = tp1;
	return (ep1);
}

ENODE* Expression::ParsePointsTo(TYP* tp1, ENODE* ep1)
{
	if (tp1 == NULL) {
		error(ERR_UNDEFINED);
		goto xit;
	}
	if (tp1->type == bt_struct) {
		//printf("hello");
		//ep1 = makenode(reftype, ep1, (ENODE *)NULL);
	}
	else
		if (tp1->type != bt_pointer) {
			error(ERR_NOPOINTER);
		}
		else
			tp1 = tp1->GetBtp();
	if (tp1->val_flag == FALSE) {
		ep1 = makenode(en_ref, ep1, (ENODE*)NULL);
		ep1->isPascal = ep1->p[0]->isPascal;
		ep1->tp = tp1;
	}
xit:
	if (ep1) ep1->tp = tp1;
	return (ep1);
}

ENODE* Expression::ParseOpenpa(TYP* tp1, ENODE* ep1)
{
	TypeArray typearray;
	ENODE* ep2, * ep3, * ep4;
	TYP* tp2, * tp3;
	SYM* sp;
	char* name;

	if (tp1 == NULL) {
		error(ERR_UNDEFINED);
		goto xit;
	}
	tp2 = ep1->tp;
	if (tp2 == nullptr) {
		error(ERR_UNDEFINED);
		goto xit;
	}
	if (tp2->type == bt_vector_mask) {
		NextToken();
		tp1 = expression(&ep2);
		needpunc(closepa, 9);
		ApplyVMask(ep2, ep1);
		ep1 = ep2;
		goto xit;
	}
	if (tp2->type == bt_pointer) {
		dfs.printf("Got function pointer.\n");
	}
	dfs.printf("tp2->type=%d", tp2->type);
	name = lastid;
	//NextToken();
	tp3 = tp1->GetBtp();
	ep4 = nullptr;
	if (tp3) {
		if (tp3->type == bt_struct || tp3->type == bt_union || tp3->type == bt_class)
			ep4 = makenode(en_regvar, NULL, NULL);
	}
	//ep2 = ArgumentList(ep1->p[2],&typearray);
	ep2 = ParseArgumentList(ep4, &typearray);
	typearray.Print();
	dfs.printf("Got Type: %d", tp1->type);
	if (tp1->type == bt_pointer) {
		dfs.printf("Got function pointer.\n");
		ep1 = makefcnode(en_fcall, ep1, ep2, nullptr);
		currentFn->IsLeaf = FALSE;
		goto xit;
	}
	dfs.printf("openpa calling gsearch2");
	sp = ep1->sym;
	/*
	sp = nullptr;
	ii = tp1->lst.FindRising(name);
	if (ii) {
		sp = Function::FindExactMatch(TABLE::matchno, name, bt_long, &typearray)->sym;
	}
	if (!sp)
		sp = gsearch2(name,bt_long,&typearray,true);
	*/
	if (sp == nullptr) {
		sp = allocSYM();
		sp->fi = MakeFunction(sp->id, sp, defaultcc == 1);
		sp->storage_class = sc_external;
		sp->SetName(name);
		sp->tp = TYP::Make(bt_func, 0);
		sp->tp->btp = TYP::Make(bt_long, sizeOfWord)->GetIndex();
		sp->fi->AddProto(&typearray);
		sp->mangledName = sp->fi->BuildSignature();
		gsyms[0].insert(sp);
	}
	else if (sp->IsUndefined) {
		sp->tp = TYP::Make(bt_func, 0);
		sp->tp->btp = TYP::Make(bt_long, sizeOfWord)->GetIndex();
		if (!sp->fi) {
			sp->fi = MakeFunction(sp->id, sp, defaultcc == 1);
		}
		sp->fi->AddProto(&typearray);
		sp->mangledName = sp->fi->BuildSignature();
		gsyms[0].insert(sp);
		sp->IsUndefined = false;
	}
	if (sp->tp->type == bt_pointer) {
		dfs.printf("Got function pointer");
		ep1 = makefcnode(en_fcall, ep1, ep2, sp);
		currentFn->IsLeaf = FALSE;
	}
	else {
		dfs.printf("Got direct function %s ", (char*)sp->name->c_str());
		ep3 = makesnode(en_cnacon, sp->name, sp->mangledName, sp->value.i);
		ep1 = makefcnode(en_fcall, ep3, ep2, sp);
		//if (sp->fi)
		{
			if (!sp->fi->IsInline)
				currentFn->IsLeaf = FALSE;
		}
		//else
		//	currentFn->IsLeaf = FALSE;
	}
	tp1 = sp->tp->GetBtp();
	//			tp1 = ExprFunction(tp1, &ep1);
xit:
	if (ep1) ep1->tp = tp1;
	return (ep1);
}

ENODE* Expression::ParseOpenbr(TYP* tp1, ENODE* ep1)
{
	ENODE* pnode, * rnode, * qnode, * snode;
	TYP* tp2, * tp3, * tp4;
	SYM* sp1;
	int cnt2;
	int64_t elesize, sz1;
	bool cf = false;	// constant flag
	bool uf = false;	// unsigned flag

	pnode = ep1;
	if (tp1 == nullptr) {
		error(ERR_UNDEFINED);
		goto xit;
	}
	NextToken();
	if (tp1->type == bt_pointer) {
		tp2 = expression(&rnode);
		tp3 = tp1;
		tp4 = tp1;
		if (rnode == nullptr) {
			error(ERR_EXPREXPECT);
			throw new C64PException(ERR_EXPREXPECT, 9);
		}
	}
	else {
		tp2 = tp1;
		rnode = pnode;
		tp3 = expression(&pnode);
		if (tp3 == NULL) {
			error(ERR_UNDEFINED);
			throw new C64PException(ERR_UNDEFINED, 10);
			goto xit;
		}
		tp1 = tp3;
		tp4 = tp1;
	}
	if (cnt == 0) {
		numdimen = tp1->dimen;
		cnt2 = 1;
		for (; tp4; tp4 = tp4->GetBtp()) {
			sa[cnt2] = max(tp4->numele, 1);
			cnt2++;
			if (cnt2 > 9) {
				error(ERR_TOOMANYDIMEN);
				break;
			}
		}
		if (tp1->type == bt_pointer) {
			sa[numdimen + 1] = tp1->GetBtp()->size;
			sa[numdimen + 1] = ep1->esize;
		}
		else
			sa[numdimen + 1] = tp1->size;
	}
	if (cnt == 0)
		totsz = tp1->size;
	if (tp1->type != bt_pointer) {
		if (lastst == colon) {
			NextToken();
			tp3 = expression(&qnode);
			snode = qnode;
			qnode = compiler.ef.Makenode(en_sub, pnode->Clone(), qnode);
			//qnode = compiler.ef.Makenode(en_sub, qnode, makeinode(en_icon, 1));
			//ep1 = compiler.ef.Makenode(pnode->isUnsigned ? en_extu : en_ext, rnode, pnode, qnode);
			rnode->nodetype = en_fieldref;
			rnode->bit_offset = snode;
			rnode->bit_width = qnode;
			rnode->esize = tp3->size;
			ep1 = rnode;//compiler.ef.Makenode(en_bitoffset, rnode, snode, qnode);
			//ep1 = compiler.ef.Makenode(en_void, rnode, nullptr);
		}
		else {
			qnode = makeinode(en_icon, 0);
			//ep1 = compiler.ef.Makenode(pnode->isUnsigned ? en_extu : en_ext, rnode, pnode->Clone(), qnode->Clone());
			rnode->nodetype = en_fieldref;
			rnode->bit_offset = pnode;
			rnode->bit_width = qnode;
			rnode->esize = tp3->size;
			ep1 = rnode;//compiler.ef.Makenode(en_bitoffset, rnode, pnode, qnode);
			snode = pnode;
			//ep1 = compiler.ef.Makenode(en_void, rnode, nullptr);
		}
		//rnode->bit_offset = pnode;
		//rnode->bit_width = qnode;
		//ep1->bit_offset = pnode->Clone();
		//ep1->bit_width = qnode->Clone();
		needpunc(closebr, 9);
		//tp1 = CondDeref(&ep1, tp2);
		tp1->type = bt_bitfield;
		tp1->bit_offset = snode->Clone();
		tp1->bit_width = qnode->Clone();
		ep1->tp = tp1;
		return (ep1);
		error(ERR_NOPOINTER);
	}
	else
		tp1 = tp1->GetBtp();
	//if (cnt==0) {
	//	switch(numdimen) {
	//	case 1: sz1 = sa[numdimen+1]; break;
	//	case 2: sz1 = sa[1]*sa[numdimen+1]; break;
	//	case 3: sz1 = sa[1]*sa[2]*sa[numdimen+1]; break;
	//	default:
	//		sz1 = sa[numdimen+1];	// could be a void = 0
	//		for (cnt2 = 1; cnt2 < numdimen; cnt2++)
	//			sz1 = sz1 * sa[cnt2];
	//	}
	//}
	//else if (cnt==1) {
	//	switch(numdimen) {
	//	case 2:	sz1 = sa[numdimen+1]; break;
	//	case 3: sz1 = sa[1]*sa[numdimen+1]; break;
	//	default:
	//		sz1 = sa[numdimen+1];	// could be a void = 0
	//		for (cnt2 = 1; cnt2 < numdimen-1; cnt2++)
	//			sz1 = sz1 * sa[cnt2];
	//	}
	//}
	//else if (cnt==2) {
	//	switch(numdimen) {
	//	case 3: sz1 = sa[numdimen+1]; break;
	//	default:
	//		sz1 = sa[numdimen+1];	// could be a void = 0
	//		for (cnt2 = 1; cnt2 < numdimen-2; cnt2++)
	//			sz1 = sz1 * sa[cnt2];
	//	}
	//}
	//else
	{
		if (numdimen) {
			sz1 = 1;
			for (cnt2 = 1; cnt2 <= numdimen; cnt2++)
				sz1 = sz1 * sa[cnt2];
			elesize = sa[numdimen + 1] / sz1;
		}
		else
			elesize = tp1->size;
		sa[0] = elesize;
		sz1 = sa[0];// sa[numdimen + 1];	// could be a void = 0
		for (cnt2 = 1; cnt2 < numdimen - cnt; cnt2++)
			sz1 = sz1 * sa[cnt2];
	}
	qnode = makeinode(en_icon, sz1);
	qnode->etype = bt_ushort;
	qnode->esize = 8;
	qnode->constflag = TRUE;
	qnode->isUnsigned = TRUE;
	cf = qnode->constflag;

	qnode = makenode(en_mulu, qnode, rnode);
	qnode->etype = bt_short;
	qnode->esize = 8;
	qnode->constflag = cf & rnode->constflag;
	qnode->isUnsigned = rnode->isUnsigned;
	if (rnode->sym)
		qnode->sym = rnode->sym;

	//(void) cast_op(&qnode, &tp_int32, tp1);
	cf = pnode->constflag;
	uf = pnode->isUnsigned;
	sp1 = pnode->sym;
	pnode = makenode(en_add, qnode, pnode);
	pnode->etype = bt_pointer;
	pnode->esize = sizeOfPtr;
	pnode->constflag = cf & qnode->constflag;
	pnode->isUnsigned = uf & qnode->isUnsigned;
	if (pnode->sym == nullptr)
		pnode->sym = sp1;
	if (pnode->sym == nullptr)
		pnode->sym = qnode->sym;

	tp1 = CondDeref(&pnode, tp1);
	pnode->tp = tp1;
	ep1 = pnode;
	needpunc(closebr, 9);
	cnt++;
xit:
	ep1->tp = tp1;
	return (ep1);
}

ENODE* Expression::MakeStaticNameNode(SYM* sp)
{
	std::string stnm;
	ENODE* node;

	if (sp->tp->type == bt_func || sp->tp->type == bt_ifunc) {
		//strcpy(stnm,GetNamespace());
		//strcat(stnm,"_");
		stnm = "";
		stnm += *sp->name;
		node = makesnode(en_cnacon, new std::string(stnm), sp->fi->BuildSignature(), sp->value.i);
		node->isPascal = sp->fi->IsPascal;
		node->constflag = TRUE;
		node->esize = 8;
		//*node = makesnode(en_nacon,sp->name);
		//(*node)->constflag = TRUE;
	}
	else {
		node = makeinode(en_labcon, sp->value.i);
		node->constflag = FALSE;
		node->esize = sp->tp->size;//8;
		node->segment = dataseg;
	}
	if (sp->tp->isUnsigned) {
		node->isUnsigned = TRUE;
		node->esize = sp->tp->size;
	}
	node->etype = bt_pointer;//sp->tp->type;
	return (node);
}

ENODE* Expression::MakeThreadNameNode(SYM* sp)
{
	ENODE* node;

	node = makeinode(en_labcon, sp->value.i);
	node->segment = tlsseg;
	node->constflag = FALSE;
	node->esize = sp->tp->size;
	node->etype = bt_pointer;//sp->tp->type;
	if (sp->tp->isUnsigned)
		node->isUnsigned = TRUE;
	return (node);
}

ENODE* Expression::MakeGlobalNameNode(SYM* sp)
{
	ENODE* node;

	if (sp->tp->type == bt_func || sp->tp->type == bt_ifunc) {
		node = makesnode(en_cnacon, sp->name, sp->mangledName, sp->value.i);
		node->isPascal = sp->fi->IsPascal;
	}
	else {
		node = makesnode(en_nacon, sp->name, sp->mangledName, sp->value.i);
		node->segment = dataseg;
	}
	node->constflag = FALSE;
	node->esize = sp->tp->size;
	node->etype = bt_pointer;//sp->tp->type;
	node->isUnsigned = TRUE;// sp->tp->isUnsigned;
	return (node);
}

ENODE* Expression::MakeExternNameNode(SYM* sp)
{
	ENODE* node;

	if (sp->tp->type == bt_func || sp->tp->type == bt_ifunc) {
		node = makesnode(en_cnacon, sp->name, sp->mangledName, sp->value.i);
		node->isPascal = sp->fi->IsPascal;
		node->constflag = TRUE;
	}
	else {
		node = makesnode(en_nacon, sp->name, sp->mangledName, sp->value.i);
		node->segment = dataseg;
		node->constflag = FALSE;
	}
	node->esize = sp->tp->size;
	node->etype = bt_pointer;//sp->tp->type;
	node->isUnsigned = TRUE;// sp->tp->isUnsigned;
	return (node);
}

ENODE* Expression::MakeConstNameNode(SYM* sp)
{
	ENODE* node;

	if (sp->tp->type == bt_quad)
		node = makefqnode(en_fqcon, &sp->f128);
	else if (sp->tp->type == bt_float || sp->tp->type == bt_double || sp->tp->type == bt_triple)
		node = compiler.ef.Makefnode(en_fcon, sp->value.f);
	else if (sp->tp->type == bt_posit)
		node = compiler.ef.Makepnode(en_pcon, sp->p);
	else {
		node = makeinode(en_icon, sp->value.i);
		if (sp->tp->isUnsigned)
			node->isUnsigned = TRUE;
	}
	node->constflag = TRUE;
	node->esize = sp->tp->size;
	node->segment = rodataseg;
	return (node);
}

ENODE* Expression::MakeMemberNameNode(SYM* sp)
{
	ENODE* node;

	// If it's a member we need to pass r25 the class pointer on
	// the stack.
	isMember = true;
	if ((sp->tp->type == bt_func || sp->tp->type == bt_ifunc)
		|| (sp->tp->type == bt_pointer && (sp->tp->GetBtp()->type == bt_func || sp->tp->GetBtp()->type == bt_ifunc)))
	{
		node = makesnode(en_cnacon, sp->name, sp->fi->BuildSignature(), 25);
		node->isPascal = sp->fi->IsPascal;
	}
	else {
		node = makeinode(en_classcon, sp->value.i);
	}
	if (sp->tp->isUnsigned || sp->tp->type == bt_pointer)
		node->isUnsigned = TRUE;
	node->esize = sp->tp->size;
	switch (node->nodetype) {
	case en_regvar:		node->etype = bt_long;	break;//sp->tp->type;
	case en_fpregvar:	node->etype = sp->tp->type;	break;//sp->tp->type;
	case en_pregvar:	node->etype = sp->tp->type;	break;//sp->tp->type;
	default:			node->etype = bt_pointer;break;//sp->tp->type;
	}
	return (node);
}

ENODE* Expression::MakeAutoNameNode(SYM* sp)
{
	ENODE* node;

	if (sp->tp->IsVectorType())
		node = makeinode(en_autovcon, sp->value.i);
	else if (sp->tp->type == bt_vector_mask)
		node = makeinode(en_autovmcon, sp->value.i);
	else if (sp->tp->IsFloatType())
		node = makeinode(en_autofcon, sp->value.i);
	else if (sp->tp->IsPositType())
		node = makeinode(en_autopcon, sp->value.i);
	else {
		node = makeinode(en_autocon, sp->value.i);
		node->bit_offset = sp->tp->bit_offset;
		node->bit_width = sp->tp->bit_width;
		if (sp->tp->isUnsigned)
			node->isUnsigned = TRUE;
	}
	if (sp->IsRegister) {
		if (sp->tp->IsFloatType())
			node->nodetype = en_fpregvar;
		else if (sp->tp->IsPositType())
			node->nodetype = en_pregvar;
		else
			node->nodetype = en_regvar;
		//(*node)->i = sp->reg;
		node->rg = sp->reg;
		node->tp = sp->tp;
		//(*node)->tp->val_flag = TRUE;
	}
	node->esize = sp->tp->size;
	switch (node->nodetype) {
	case en_regvar:		node->etype = bt_long;	break;//sp->tp->type;
	case en_fpregvar:	node->etype = sp->tp->type;	break;//sp->tp->type;
	case en_pregvar:	node->etype = sp->tp->type;	break;//sp->tp->type;
	default:			node->etype = bt_pointer;break;//sp->tp->type;
	}
	return (node);
}

ENODE* Expression::MakeUnknownFunctionNameNode(std::string nm, TYP** tp, TypeArray* typearray, ENODE* args)
{
	ENODE* node, * namenode;
	SYM* sp;

	sp = allocSYM();
	sp->fi = compiler.ff.MakeFunction(sp->id, sp, defaultcc == 1);
	sp->tp = &stdfunc;
	sp->tp->btp = bt_long;
	sp->SetName(*(new std::string(nm)));
	sp->storage_class = sc_external;
	sp->IsUndefined = TRUE;
	dfs.printf("Insert at nameref\r\n");
	typearray->Print();
	    gsyms[0].insert(sp);
	*tp = &stdfunc;
	namenode = makesnode(en_cnacon, sp->name, sp->BuildSignature(1), sp->value.i);
	node = makefcnode(en_fcall, namenode, args, sp);
	node->constflag = TRUE;
	node->sym = sp;
	if (sp->tp->isUnsigned)
		node->isUnsigned = TRUE;
	node->esize = 8;
	node->isPascal = sp->fi->IsPascal;
	return (node);
}
