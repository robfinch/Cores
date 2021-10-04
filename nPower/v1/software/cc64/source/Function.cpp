// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2021  Robert Finch, Waterloo
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
extern char irfile[256];
extern int defaultcc;
extern bool isLeaf;
extern CSet* ru, * rru;
extern std::string* UnknownFuncName();

Function::Function()
{
	rmask = CSet::MakeNew();
	fprmask = CSet::MakeNew();
	prmask = CSet::MakeNew();
	NumFixedAutoParms = 0;
}

Statement *Function::ParseBody()
{
	std::string lbl;
	char *p;
	OCODE *ip;
	int oc;
	int label, lab1;

	dfs.printf("<Parse function body>:%s|\n", (char *)sym->name->c_str());

	lbl = std::string("");
	lastst;
	needpunc(begin, 47);

	tmpReset();
	//ParseAutoDeclarations();
	lbl += *sym->mangledName;
	ofs.printf("\n#{++ %s\n", (char* )lbl.c_str());
	lbl = std::string("");
	cseg();
	if (sym->storage_class == sc_static)
	{
		//lbl = GetNamespace() + std::string("_");
		//strcpy(lbl,GetNamespace());
		//strcat(lbl,"_");
		//		strcpy(lbl,sp->name);
		lbl += *sym->mangledName;
		if (sym->tp->type == bt_pointer)
			lbl += "_func";
		else
			lbl += "\n\t.align 4\n";
		//			gen_strlab((char *)lbl.c_str());
		GenerateMonadic(op_fnname, 0, MakeStringAsNameConst((char *)lbl.c_str(), codeseg));
	}
	//	put_label((unsigned int) sp->value.i);
	else {
		if (sym->storage_class == sc_global) {
			lbl = "\n\t.global ";
			lbl += *sym->mangledName;
			lbl += "\n\t.align 4\n";
			if (!IsInline) {
				ofs.printf((char*)lbl.c_str());
				//GenerateMonadic(op_verbatium, 0, MakeStringAsNameConst(my_strdup((char*)lbl.c_str()), codeseg));
				//GenerateMonadic(op_verbatium, 0, MakeStringAsNameConst("\n;{+",codeseg));
				GenerateMonadic(op_fnname, 0, MakeStringAsNameConst((char *)sym->mangledName->c_str(), codeseg));
				ofs.printf("\n");
			}
			lbl = "public code ";
		}
		else {
			lbl = *sym->mangledName;
			if (!IsInline) {
				lbl = "\n\t.local ";
				lbl += *sym->mangledName;
				ofs.printf((char*)lbl.c_str());
				lbl = "\n\t.align 4\n";
				ofs.printf((char*)lbl.c_str());
				lbl = *sym->mangledName;
				//GenerateMonadic(op_verbatium, 0, MakeStringAsNameConst("\n;{+", codeseg));
				GenerateMonadic(op_fnname, 0, MakeStringAsNameConst((char*)lbl.c_str(), codeseg));
				ofs.printf("\n");
			}
		}
		//		strcat(lbl,sp->name);
		lbl += *sym->mangledName;
		if (sym->tp->type == bt_pointer)
			lbl += "_func";
		//gen_strlab(lbl);
	}
	ofs.printf("\t.sdreg r27\n");
	ofs.printf("\t.sd2reg r28\n");
	dfs.printf("B");
	p = my_strdup((char *)lbl.c_str());
	dfs.printf("b");
	if (!IsInline && false)
		GenerateMonadic(op_fnname, 0, MakeStringAsNameConst(p, codeseg));
	currentFn = this;
	IsLeaf = TRUE;
	DoesThrow = false;
	doesJAL = false;
	UsesPredicate = FALSE;
	UsesNew = FALSE;
	regmask = 0;
	bregmask = 0;
	currentStmt = (Statement *)NULL;
	dfs.printf("C");
	stmtdepth = 0;
	body = sym->stmt = sym->stmt->ParseCompound();
	if (lastst == kw_catch) {
		int lab1;
		Statement stmt;

		currentFn->hasDefaultCatch = true;
		currentFn->body->next = stmt.ParseCatch();
	}
	dfs.printf("D");
	//	stmt->stype = st_funcbody;
	while (lc_auto % sizeOfWord)	// round frame size to word
		++lc_auto;
	if (pass==1)
		stkspace = round8(lc_auto);
	if (!IsInline) {
		pass = 1;
		if (pl.tail)
			oc = pl.tail->opcode;
		else
			oc = op_remark;
		ip = pl.tail;
		looplevel = 0;
		max_reg_alloc_ptr = 0;
		max_stack_use = 0;
		label = nextlabel;
		Generate();
		if (pass == 1) {
			stkspace += (ArgRegCount - regFirstArg) * sizeOfWord;
			argbot = -stkspace;
			stkspace += max_stack_use;// GetTempMemSpace();
			tempbot = -stkspace;
		}
		pass = 2;
		pl.tail = ip;
		if (pl.tail)
			pl.tail->fwd = nullptr;
		looplevel = 0;
		//nextlabel = label;
		Generate();
		dfs.putch('E');

		PeepOpt();
		FlushPeep();
		lbl = "\t.type ";
		lbl += *sym->mangledName;
		ofs.printf(lbl.c_str());
		ofs.printf(",@function\n");
		lbl = "\t.size ";
		lbl += *sym->mangledName;
		ofs.printf(lbl.c_str());
		lbl = ",$-";
		lbl += *sym->mangledName;
		ofs.printf(lbl.c_str());
		ofs.printf("\n# stacksize=%d\n",stkspace + compiler.GetReturnBlockSize());
		ofs.printf("\t.set ___stack");
		lbl = *sym->mangledName;
		ofs.printf(lbl.c_str());
		ofs.printf(",%d\n", stkspace + compiler.GetReturnBlockSize());

//		if (sym->storage_class == sc_global) {
//			ofs.printf("endpublic\r\n\r\n");
//		}
		if (!IsInline)
			;
	}
	//if (sp->stkspace)
	//ofs.printf("%sSTKSIZE_ EQU %d\r\n", (char *)sp->mangledName->c_str(), sp->stkspace);
	isFuncBody = false;
	dfs.printf("</ParseFunctionBody>\n");
	return (sym->stmt);
}

void Function::Init()
{
	IsLeaf = isLeaf;
	IsNocall = isNocall;
	IsPascal = isPascal;
	sym->IsKernel = isKernel;
	IsInterrupt = isInterrupt;
	IsTask = isTask;
//	NumParms = nump;
//	numa = numarg;
	IsVirtual = isVirtual;
	IsInline = isInline;

	isPascal = defaultcc==1;
	isKernel = FALSE;
	isOscall = FALSE;
	isInterrupt = FALSE;
	isTask = FALSE;
	isNocall = FALSE;
}

void Function::DoFuncptrAssign(Function *sp)
{
	ENODE* node, * ep1, * ep2;
	TYP* tp1, * tp2;
	Expression exp;
	e_node op;
	SYM* asym;

	NextToken();
	ep1 = nullptr;
	tp1 = TYP::Make(bt_pointer, sizeOfPtr);
	tp1->btpp = TYP::Make(bt_func, sizeOfWord);
	tp1->btp = tp1->btpp->GetIndex();
	asym = nullptr;
	exp.nameref2(sp->sym->name->c_str(), &ep1, en_ref, FALSE, nullptr, nullptr, sp->sym);
	exp.CondDeref(&ep1, sp->sym->tp);

	op = en_assign;
	ep2 = nullptr;
	tp2 = exp.ParseAssignOps(&ep2, asym);
	if (tp2 == nullptr || !IsLValue(ep1))
		error(ERR_LVALUE);
	else {
		tp1 = forcefit(&ep2, tp2, &ep1, tp1, false, true);
		ep1 = makenode(op, ep1, ep2);
		ep1->tp = tp1;
	}
	// Move vars with initialization data over to the data segment.
	if (ep1->segment == bssseg)
		ep1->segment = dataseg;
	if (sp->sym->initexp)
		sp->sym->initexp->p[0] = ep1;
	else
		sp->sym->initexp = ep1;
	doinit(sp->sym);
}

/*
*      funcbody starts with the current symbol being either
*      the first parameter id or the begin for the local
*      block. If begin is the current symbol then funcbody
*      assumes that the function has no parameters.
*/
int Function::Parse()
{
	Function *osp, *sp;
	int nump, numar, ellipos;
	std::string nme;

	currentFn = this;
	sp = this;
	dfs.puts("<ParseFunction>\n");
	isFuncBody = true;
	if (this == nullptr) {
		fatal("Compiler error: Function::Parse: SYM is NULL\r\n");
	}
	dfs.printf("***********************************\n");
	dfs.printf("***********************************\n");
	dfs.printf("***********************************\n");
	if (sym->parent)
		dfs.printf("Parent: %s\n", (char *)sym->GetParentPtr()->name->c_str());
	dfs.printf("Parsing function: %s\n", (char *)sym->name->c_str());
	dfs.printf("***********************************\n");
	dfs.printf("***********************************\n");
	dfs.printf("***********************************\n");
	stkname = ::stkname;
	sp_init = ::sp_init;
	DoesContextSave = ::DoesContextSave;
	if (verbose) printf("Parsing function: %s\r\n", (char *)sym->name->c_str());
	nump = nparms;
	iflevel = 0;
	looplevel = 0;
	foreverlevel = 0;
	// There could be unnamed parameters in a function prototype.
	dfs.printf("A");
	// declare parameters
	// Building a parameter list here allows both styles of parameter
	// declarations. the original 'C' style is parsed here. Originally the
	// parameter types appeared as list after the parenthesis and before the
	// function body.
	//if (NumParms == -1)
		nump = sp->NumParms;
		sp->BuildParameterList(&nump, &numar, &ellipos);
		if (ellipos >= 0)
			sp->NumFixedAutoParms = ellipos + 1;
		else
			sp->NumFixedAutoParms = nump;
	dfs.printf("B");
	sym->mangledName = BuildSignature(1);  // build against parameters

											  // If the symbol has a parent then it must be a class
											  // method. Search the parent table(s) for matching
											  // signatures.
	osp = this;
	nme = *sym->name;
	if (sym->parent) {
		Function *sp2;
		dfs.printf("Parent Class:%s|", (char *)sym->GetParentPtr()->name->c_str());
		sp2 = sym->GetParentPtr()->Find(nme)->fi;
		if (sp2) {
			dfs.printf("Found at least inexact match");
			sp2 = FindExactMatch(TABLE::matchno);
		}
		if (sp2 == nullptr)
			error(ERR_METHOD_NOTFOUND);
		else
			sp = sp2;
		PrintParameterTypes();
	}
	else {
		if (gsyms[0].Find(nme)) {
			sp = TABLE::match[TABLE::matchno - 1]->fi;
		}
	}
	dfs.printf("C");

	if (sp && sp != osp) {
		dfs.printf("Function::Parse: sp changed\n");
		params.CopyTo(&sp->params);
		proto.CopyTo(&sp->proto);
		sp->derivitives = derivitives;
		sp->sym->mangledName = sym->mangledName;
		// Should free osp here. It's not needed anymore
		FreeFunction(osp);
	}
	if (lastst == closepa) {
		NextToken();
		while (lastst == kw_attribute)
			Declaration::ParseFunctionAttribute(sp);
		//if (lastst == closepa)
		//	NextToken();
		if (lastst == openpa) {
			int np, na;
			SYM* sp = (SYM*)allocSYM();
			Function* fn = compiler.ff.MakeFunction(sym->number, sp, false);
			fn->BuildParameterList(&np, &na, &ellipos);
			if (ellipos >= 0)
				fn->NumFixedAutoParms = ellipos + 1;
			else
				fn->NumFixedAutoParms = np;
			if (lastst == closepa) {
				NextToken();
				while (lastst == kw_attribute)
					Declaration::ParseFunctionAttribute(fn);
			}
		}
	}
	dfs.printf("D");
	if (sp && sp->sym->tp->type == bt_pointer) {
		if (lastst == assign) {
			DoFuncptrAssign(sp);
		}
		else if (lastst == begin) {
			ENODE* node, *node2;

			node = makesnode(en_cnacon, new std::string(*UnknownFuncName()), new std::string(*UnknownFuncName()), stringlit((char *)UnknownFuncName()->c_str()));
			node2 = makesnode(en_cnacon, new std::string(*UnknownFuncName()), new std::string(*UnknownFuncName()), stringlit((char*)UnknownFuncName()->c_str()));
			node = makenode(en_assign, node, node2);
			sp->sym->initexp = node;
			doinit(sp->sym);
			goto j2;
		}
		sp->Init();
		return (1);
	}
j2:
	dfs.printf("E");
	if (sp && (lastst == semicolon || lastst == comma)) {	// Function prototype
		dfs.printf("e");
		sp->IsPrototype = 1;
		sp->Init();
		sp->params.MoveTo(&sp->proto);
		goto j1;
	}
	else if (lastst == kw_attribute) {
		while (lastst == kw_attribute) {
			Declaration::ParseFunctionAttribute(sp);
		}
		goto j2;
	}
	else if (sp && lastst != begin) {
		dfs.printf("F");
		//			NextToken();
		//			ParameterDeclaration::Parse(2);
		nump = sp->NumParms;
		sp->BuildParameterList(&nump, &numar, &ellipos);
		if (ellipos >= 0)
			sp->NumFixedAutoParms = ellipos + 1;
		else
			sp->NumFixedAutoParms = nump;
		// for old-style parameter list
		//needpunc(closepa);
		if (lastst == semicolon) {
			sp->IsPrototype = 1;
			sp->Init();
		}
		// Check for end of function parameter list.
		else if (funcdecl == 2 && lastst == closepa) {
			;
		}
		else if (lastst == assign)
			DoFuncptrAssign(sp);
		else {
			sp->numa = numa;
			sp->NumParms = nump;
			sp->Init();
			sp->sym->stmt = ParseBody();
			Summary(sp->sym->stmt);
		}
	}
	//                error(ERR_BLOCK);
	else {
		dfs.printf("G");
		if (sp) {
			sp->Init();
			// Parsing declarations sets the storage class to extern when it really
			// should be global if there is a function body.
			if (sp->sym->storage_class == sc_external)
				sp->sym->storage_class = sc_global;
			sp->sym->stmt = ParseBody();
			Summary(sp->sym->stmt);
		}
	}
j1:
	dfs.printf("F");
	dfs.puts("</ParseFunction>\n");
	return (0);
}

/*
void Function::StackGPRs()
{
	int nn;

	GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), MakeImmediate(31 * sizeOfWord));
	for (nn = 1; nn < 31; nn = nn + 1) {
		GenerateDiadic(op_sto, 0, makereg(nn), MakeIndexed((nn - 1) * sizeOfWord, regSP));
	}
	// Get usp
	GenerateTriadic(op_csrrw, 0, makereg(2), MakeImmediate(0x00), makereg(regZero));
	GenerateDiadic(op_sto, 0, makereg(2), MakeIndexed(30 * sizeOfWord, regSP));
}
*/

// Push temporaries on the stack.

void Function::SaveGPRegisterVars()
{
	int cnt;
	int nn;

	if (rmask) {
		if (rmask->NumMember()) {
			cnt = 0;
			GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), cg.MakeImmediate(rmask->NumMember() * 8));
			rmask->resetPtr();
			for (nn = rmask->lastMember(); nn >= 0; nn = rmask->prevMember()) {
				GenerateDiadic(cpu.stt_op, 0, makereg(nregs - 1 - nn), MakeIndexed(cnt, regSP));
				cnt += sizeOfWord;
			}
		}
	}
}

void Function::SaveFPRegisterVars()
{
	int cnt;
	int nn;

	if (fprmask) {
		if (fprmask->NumMember()) {
			cnt = 0;
			GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), cg.MakeImmediate(fprmask->NumMember() * 8));
			fprmask->resetPtr();
			for (nn = fprmask->lastMember(); nn >= 0; nn = fprmask->prevMember()) {
				GenerateDiadic(op_sto, 0, makereg(nregs - 1 - nn), MakeIndexed(cnt, regSP));
				cnt += sizeOfWord;
			}
		}
	}
}

void Function::SavePositRegisterVars()
{
	int cnt;
	int nn;

	if (prmask) {	// optimization may be off
		if (prmask->NumMember()) {
			cnt = 0;
			GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), cg.MakeImmediate(prmask->NumMember() * 8));
			prmask->resetPtr();
			for (nn = prmask->lastMember(); nn >= 0; nn = prmask->prevMember()) {
				GenerateDiadic(op_psto, ' ', makefpreg(nregs - 1 - nn), MakeIndexed(cnt, regSP));
				cnt += sizeOfWord;
			}
		}
	}
}

void Function::SaveRegisterVars()
{
	SaveGPRegisterVars();
	SaveFPRegisterVars();
	SavePositRegisterVars();
}


// Saves any registers used as parameters in the calling function.

void Function::SaveRegisterArguments()
{
	TypeArray *ta;
	int count;

	if (this == nullptr)
		return;
	ta = GetProtoTypes();
	if (ta) {
		int nn;
		if (!cpu.SupportsPush) {
			for (count = nn = 0; nn < ta->length; nn++)
				if (ta->preg[nn]) {
					count++;
					if (ta->types[nn] == bt_quad || ta->types[nn] == bt_triple)
						count++;
				}
			GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), cg.MakeImmediate(count * sizeOfWord));
			for (count = nn = 0; nn < ta->length; nn++) {
				if (ta->preg[nn]) {
					switch (ta->types[nn]) {
					case bt_quad:	GenerateDiadic(op_stf, 'q', makereg(ta->preg[nn] & 0x7fff), MakeIndexed(count*sizeOfWord, regSP)); count += 2; break;
					case bt_float:	GenerateDiadic(op_stf, 'd', makereg(ta->preg[nn] & 0x7fff), MakeIndexed(count*sizeOfWord, regSP)); count += 1; break;
					case bt_double:	GenerateDiadic(op_stf, 'd', makereg(ta->preg[nn] & 0x7fff), MakeIndexed(count*sizeOfWord, regSP)); count += 1; break;
					case bt_triple:	GenerateDiadic(op_stf, 't', makereg(ta->preg[nn] & 0x7fff), MakeIndexed(count*sizeOfWord, regSP)); count += 2; break;
					case bt_posit:	GenerateDiadic(op_stf, 'd', makereg(ta->preg[nn] & 0x7fff), MakeIndexed(count * sizeOfWord, regSP)); count += 1; break;
					default:	GenerateDiadic(op_sto, 0, makereg(ta->preg[nn] & 0x7fff), MakeIndexed(count*sizeOfWord, regSP)); count += 1; break;
					}
				}
			}
		}
		else {
			for (count = nn = 0; nn < ta->length; nn++) {
				if (ta->preg[nn]) {
					switch (ta->types[nn]) {
					case bt_quad:	GenerateMonadic(op_pushf, 'q', makereg(ta->preg[nn] & 0x7fff)); break;
					case bt_float:	GenerateMonadic(op_pushf, 'd', makereg(ta->preg[nn] & 0x7fff)); break;
					case bt_double:	GenerateMonadic(op_pushf, 'd', makereg(ta->preg[nn] & 0x7fff)); break;
					case bt_triple:	GenerateMonadic(op_pushf, 't', makereg(ta->preg[nn] & 0x7fff)); break;
					case bt_posit:	GenerateMonadic(op_push, ' ', makereg(ta->preg[nn] & 0x7fff)); break;
					default:	GenerateMonadic(op_push, 0, makereg(ta->preg[nn] & 0x7fff)); break;
					}
				}
			}
		}
	}
}


void Function::RestoreRegisterArguments()
{
	TypeArray *ta;
	int count;

	if (this == nullptr)
		return;
	ta = GetProtoTypes();
	if (ta) {
		int nn;
		for (count = nn = 0; nn < ta->length; nn++)
			if (ta->preg[nn]) {
				count++;
				if (ta->types[nn] == bt_quad || ta->types[nn] == bt_triple)
					count++;
			}
		GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), cg.MakeImmediate(count * sizeOfWord));
		for (count = nn = 0; nn < ta->length; nn++) {
			if (ta->preg[nn]) {
				switch (ta->types[nn]) {
				case bt_quad:	GenerateDiadic(op_ldf, 'q', makereg(ta->preg[nn] & 0x7fff), MakeIndexed(count*sizeOfWord, regSP)); count += 2; break;
				case bt_float:	GenerateDiadic(op_ldf, 'd', makereg(ta->preg[nn] & 0x7fff), MakeIndexed(count*sizeOfWord, regSP)); count += 1; break;
				case bt_double:	GenerateDiadic(op_ldf, 'd', makereg(ta->preg[nn] & 0x7fff), MakeIndexed(count*sizeOfWord, regSP)); count += 1; break;
				case bt_triple:	GenerateDiadic(op_ldf, 't', makereg(ta->preg[nn] & 0x7fff), MakeIndexed(count*sizeOfWord, regSP)); count += 2; break;
				case bt_posit:	GenerateDiadic(op_ldf, ' ', makereg(ta->preg[nn] & 0x7fff), MakeIndexed(count * sizeOfWord, regSP)); count += 1; break;
				default:	GenerateDiadic(op_ldo, 0, makereg(ta->preg[nn] & 0x7fff), MakeIndexed(count*sizeOfWord, regSP)); count += 1; break;
				}
			}
		}
	}
}


int Function::RestoreGPRegisterVars()
{
	int cnt2 = 0, cnt;
	int nn;
	int64_t mask;

	if (save_mask == nullptr)
		return (0);
	if (save_mask->NumMember()) {
		if (cpu.SupportsLDM && save_mask->NumMember() > 2) {
			mask = 0;
			for (nn = 0; nn < 32; nn++)
				if (save_mask->isMember(nn))
					mask = mask | (1LL << (nn-1));
			//GenerateMonadic(op_reglist, 0, cg.MakeImmediate(mask, 16));
			GenerateDiadic(op_ldm, 0, cg.MakeIndirect(regSP), cg.MakeImmediate(mask, 16));
		}
		else {
			cnt2 = cnt = save_mask->NumMember() * sizeOfWord;
			cnt = 0;
			save_mask->resetPtr();
			for (nn = save_mask->nextMember(); nn >= 0; nn = save_mask->nextMember()) {
				GenerateDiadic(cpu.ldt_op, 0, makereg(nn), MakeIndexed(cnt, regSP));
				cnt += sizeOfWord;
			}
		}
	}
	return (cnt2);
}

// Restore fp registers used as register variables.
int Function::RestoreFPRegisterVars()
{
	int cnt2 = 0, cnt;
	int nn;

	if (fpsave_mask == nullptr)
		return (0);
	if (fpsave_mask->NumMember()) {
		cnt2 = cnt = (fpsave_mask->NumMember() - 1)*sizeOfWord;
		fpsave_mask->resetPtr();
		for (nn = fpsave_mask->nextMember(); nn >= 1; nn = fpsave_mask->nextMember()) {
			GenerateDiadic(op_fldo, 0, makefpreg(nn), MakeIndexed(cnt2 - cnt, regSP));
			cnt -= sizeOfWord;
		}
		GenerateTriadic(op_addi, 0, makereg(regSP), makereg(regSP), MakeImmediate(cnt2 + sizeOfFP));
	}
	return (cnt2);
}

int Function::RestorePositRegisterVars()
{
	int cnt2 = 0, cnt;
	int nn;

	if (psave_mask == nullptr)
		return (0);
	if (psave_mask->NumMember()) {
		cnt2 = cnt = (psave_mask->NumMember() - 1) * sizeOfWord;
		psave_mask->resetPtr();
		for (nn = psave_mask->nextMember(); nn >= 1; nn = psave_mask->nextMember()) {
			GenerateDiadic(op_pldo, 0, compiler.of.makepreg(nn), MakeIndexed(cnt2 - cnt, regSP));
			cnt -= sizeOfWord;
		}
		GenerateTriadic(op_addi, 0, makereg(regSP), makereg(regSP), MakeImmediate(cnt2 + sizeOfFP));
	}
	return (cnt2);
}

void Function::RestoreRegisterVars()
{
	RestorePositRegisterVars();
	RestoreFPRegisterVars();
	cg.GenerateHint(begin_restore_regvars);
	RestoreGPRegisterVars();
	cg.GenerateHint(end_restore_regvars);
}

void Function::SaveTemporaries(int *sp, int *fsp, int* psp)
{
	if (this) {
		if (UsesTemps) {
			*sp = TempInvalidate(fsp, psp);
			//*fsp = TempFPInvalidate();
		}
	}
	else {
		*sp = TempInvalidate(fsp, psp);
		//*fsp = TempFPInvalidate();
	}
}

void Function::RestoreTemporaries(int sp, int fsp, int psp)
{
	if (this) {
		if (UsesTemps) {
			//TempFPRevalidate(fsp);
			TempRevalidate(sp, fsp, psp);
		}
	}
	else {
		//TempFPRevalidate(fsp);
		TempRevalidate(sp, fsp, psp);
	}
}


// Unlink the stack

void Function::UnlinkStack(int64_t amt)
{
	Operand* ap;

	/* auto news are garbage collected
	if (hasAutonew) {
		GenerateMonadic(op_call, 0, MakeStringAsNameConst("__autodel",codeseg));
		GenerateMonadic(op_bex, 0, MakeDataLabel(throwlab));
	}
	*/
	if (alstk) {
		GenerateMonadic(op_hint, 0, MakeImmediate(begin_stack_unlink));
		GenerateDiadic(op_mr, 0, makereg(regSP), makereg(regFP));
		GenerateZeradic(op_nop);
		GenerateZeradic(op_nop);
		GenerateDiadic(op_lwz, 0, makereg(regFP), MakeIndirect(regSP));
		GenerateZeradic(op_nop);
		GenerateZeradic(op_nop);
		if (doesJAL) {
			ap = GetTempRegister();
			GenerateDiadic(op_lwz, 0, ap, MakeIndexed(2 * sizeOfWord, regFP));
			GenerateZeradic(op_nop);
			GenerateZeradic(op_nop);
			GenerateMonadic(op_mtlr, 0, ap);
			ReleaseTempReg(ap);
		}
		GenerateMonadic(op_hint, 0, MakeImmediate(end_stack_unlink));
	}
	return;

	// Dead code follows
	if (!cpu.SupportsLeave)
		GenerateMonadic(op_hint, 0, MakeImmediate(begin_stack_unlink));
	if (cpu.SupportsLeave) {
	}
	else if (!IsLeaf && doesJAL) {
		if (alstk) {
			GenerateDiadic(cpu.mov_op, 0, makereg(regSP), makereg(regFP));
			GenerateDiadic(cpu.ldt_op, 0, makereg(regFP), MakeIndirect(regSP));
			GenerateDiadic(cpu.ldt_op, 0, makereg(regLR), MakeIndexed(2 * sizeOfWord, regFP));
			if (IsFar)
				GenerateDiadic(cpu.ldt_op, 0, makereg(regCS), MakeIndexed(3 * sizeOfWord, regFP));
		}
	}
	cg.GenerateUnlink(amt);
	if (cpu.SupportsLeave) {
	}
	else if (!IsLeaf && doesJAL) {
		if (!alstk) {
			GenerateDiadic(cpu.mov_op, 0, makereg(regSP), makereg(regFP));
			GenerateDiadic(cpu.ldt_op, 0, makereg(regFP), MakeIndirect(regSP));
			GenerateDiadic(cpu.ldt_op, 0, makereg(regLR), MakeIndexed(2 * sizeOfWord, regFP));
			if (IsFar)
				GenerateDiadic(cpu.ldt_op, 0, makereg(regCS), MakeIndexed(3 * sizeOfWord, regFP));
		}
	}
	//	GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),MakeImmediate(3*sizeOfWord));
	GenerateMonadic(op_hint, 0, MakeImmediate(end_stack_unlink));
}

int64_t Function::SizeofReturnBlock()
{
	return (Compiler::GetReturnBlockSize());
	return ((int64_t)(IsLeaf ? 1 : doesJAL ? 2 : 1));
}

// For a leaf routine don't bother to store the link register.
void Function::SetupReturnBlock()
{
	Operand *ap, *ap1;
	int n;
	char buf[300];
	
	alstk = false;
	GenerateMonadic(op_hint,0,MakeImmediate(begin_return_block));
	GenerateTriadic(op_addi, 0, makereg(regSP), makereg(regSP), MakeImmediate(-Compiler::GetReturnBlockSize()));
	GenerateDiadic(op_stw, 0, makereg(regFP), MakeIndirect(regSP));
	GenerateDiadic(op_mr, 0, makereg(regFP), makereg(regSP));
	if (stkspace != 0)
		GenerateTriadic(op_addi, 0, makereg(regSP), makereg(regSP), MakeImmediate(-stkspace));
	alstk = true;
	// Put this marker here so that storing the link register relative to the
	// frame pointer counts as a frame pointer reference.
	GenerateMonadic(op_hint, 0, MakeImmediate(end_return_block));
	//	GenerateTriadic(op_stdp, 0, makereg(regFP), makereg(regZero), MakeIndirect(regSP));
	n = 0;
	if (!currentFn->IsLeaf && doesJAL) {
		n |= 2;
		/*
		if (alstk) {
			GenerateDiadic(op_sto, 0, makereg(regLR), MakeIndexed(1 * sizeOfWord + stkspace, regSP));
		}
		else
		*/
		if (!cpu.SupportsEnter) {
			//if (IsFar)
			//	GenerateMonadic(op_di, 0, MakeImmediate(2));
			ap = GetTempRegister();
			GenerateMonadic(op_mflr, 0, ap);
			GenerateZeradic(op_nop);
			GenerateZeradic(op_nop);
			GenerateDiadic(op_stw, 0, ap, MakeIndexed(2 * sizeOfWord, regFP));
			ReleaseTempReg(ap);
			if (IsFar)
				GenerateDiadic(cpu.stt_op, 0, makereg(regRS), MakeIndexed(3 * sizeOfWord, regFP));
		}
	}
	/*
	switch (n) {
	case 0:	break;
	case 1:	GenerateDiadic(op_std, 0, makereg(regXLR), MakeIndexed(2 * sizeOfWord, regSP)); break;
	case 2:	GenerateDiadic(op_std, 0, makereg(regLR), MakeIndexed(3 * sizeOfWord, regSP)); break;
	case 3:	GenerateTriadic(op_stdp, 0, makereg(regXLR), makereg(regLR), MakeIndexed(2 * sizeOfWord, regSP)); break;
	}
	*/
	retlab = nextlabel++;
	ap = MakeDataLabel(retlab, regZero);
	ap->mode = am_imm;
	//if (!cpu.SupportsLink)
	//	GenerateDiadic(op_mov, 0, makereg(regFP), makereg(regSP));
	//if (!alstk) {
	//	GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), MakeImmediate(stkspace));
		//spAdjust = pl.tail;
//	}
	// Store the catch handler address at 16[$FP]
	if (exceptions) {
		ap = GetTempRegister();
		DataLabels[defCatchLabel] = true;
		defCatchLabelPatchPoint = currentFn->pl.tail;
		sprintf_s(buf, sizeof(buf), "%s_%05lld@ha", currentFn->sym->mangledName->c_str(), defCatchLabel);
		GenerateDiadic(op_lis, 0, ap, MakeStringAsNameConst(buf, codeseg));
		sprintf_s(buf, sizeof(buf), "%s_%05lld@l", currentFn->sym->mangledName->c_str(), defCatchLabel);
		GenerateTriadic(op_addi, 0, ap, ap, MakeStringAsNameConst(buf, codeseg));
		if (IsFar)
			GenerateMonadic(op_di, 0, MakeImmediate(2));
		GenerateDiadic(cpu.stt_op, 0, ap, MakeIndexed((int64_t)32, regFP));
		if (IsFar) {
			GenerateDiadic(cpu.stt_op, 0, makereg(regCS), MakeIndexed((int64_t)40, regFP));
		}
//		GenerateDiadic(cpu.mov_op, 0, makereg(regAFP), makereg(regFP));
		GenerateMonadic(op_bex, 0, cg.MakeCodeLabel(currentFn->defCatchLabel));
	}
	tryCount = 0;
}

// Generate a return statement.
//
void Function::GenerateReturn(Statement* stmt)
{
	Operand* ap, * ap2;
	int nn;
	int cnt, cnt2;
	int64_t toAdd;
	SYM* p;
	bool isFloat, isPosit;
	int64_t sz;

	// Generate the return expression and force the result into r1.
	if (stmt != NULL && stmt->exp != NULL)
	{
		initstack();
		isFloat = sym->tp->btpp && sym->tp->btpp->IsFloatType();
		isPosit = sym->tp->btpp && sym->tp->btpp->IsPositType();
		if (isFloat)
			ap = cg.GenerateExpression(stmt->exp, am_reg, sizeOfFP, 1);
		else if (isPosit)
			ap = cg.GenerateExpression(stmt->exp, am_reg, sizeOfPosit, 1);
		else
			ap = cg.GenerateExpression(stmt->exp, am_reg | am_imm, sizeOfWord, 1);
		GenerateMonadic(op_hint, 0, MakeImmediate(2));
		if (ap->mode == am_imm)
			GenerateDiadic(cpu.ldi_op, 0, makereg(regFirstArg), ap);
		else if (ap->mode == am_reg) {
			if (sym->tp->btpp && (sym->tp->btpp->type == bt_struct || sym->tp->btpp->type == bt_union || sym->tp->btpp->type == bt_class)) {
				if ((sz = sym->tp->btpp->size) > sizeOfWord) {
					p = params.Find("_pHiddenStructPtr", false);
					if (p) {
						if (p->IsRegister)
							GenerateDiadic(cpu.mov_op, 0, makereg(regFirstArg), makereg(p->reg));
						else
							GenerateDiadic(cpu.ldo_op, 0, makereg(regFirstArg), MakeIndexed(p->value.i, regFP));
						ap2 = GetTempRegister();
						GenerateDiadic(cpu.ldi_op, 0, ap2, MakeImmediate(sym->tp->btpp->size));
						if (cpu.SupportsPush) {
							GenerateMonadic(op_push, 0, ap2);
							GenerateMonadic(op_push, 0, ap);
							GenerateMonadic(op_push, 0, makereg(1));
						}
						else {
							GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), MakeImmediate(sizeOfWord * 3));
							GenerateDiadic(cpu.stt_op, 0, makereg(1), MakeIndirect(regSP));
							GenerateDiadic(cpu.stt_op, 0, ap, MakeIndexed(sizeOfWord, regSP));
							GenerateDiadic(cpu.stt_op, 0, ap2, MakeIndexed(sizeOfWord * 2, regSP));
						}
						ReleaseTempReg(ap2);
						GenerateMonadic(op_call, 0, MakeStringAsNameConst("__aacpy", codeseg));
						GenerateMonadic(op_bex, 0, MakeDataLabel(throwlab, regZero));
						if (!IsPascal)
							GenerateTriadic(op_addi, 0, makereg(regSP), makereg(regSP), MakeImmediate(sizeOfWord * 3));
					}
					else {
						error(ERR_MISSING_HIDDEN_STRUCTPTR);
					}
				}
				else {
					if (ap->isPtr) {
						if (sz > 4)
							GenLoad(makereg(regFirstArg), MakeIndirect(ap->preg), 8, 8);
						else if (sz > 2)
							GenLoad(makereg(regFirstArg), MakeIndirect(ap->preg), 4, 4);
						else if (sz > 1)
							GenLoad(makereg(regFirstArg), MakeIndirect(ap->preg), 2, 2);
						else
							GenLoad(makereg(regFirstArg), MakeIndirect(ap->preg), 1, 1);
					}
					else
						GenerateDiadic(cpu.mov_op, 0, makereg(regFirstArg), ap);
				}
			}
			else {
				if (sym->tp->btpp->IsFloatType() || sym->tp->btpp->IsPositType())
					GenerateDiadic(cpu.mov_op, 0, makereg(regFirstArg), ap);
				else if (sym->tp->btpp->IsVectorType())
					GenerateDiadic(cpu.mov_op, 0, makevreg(regFirstArg), ap);
				else
					GenerateDiadic(cpu.mov_op, 0, makereg(regFirstArg), ap);
			}
		}
		else if (ap->mode == am_reg) {
			if (isFloat)
				GenerateDiadic(cpu.mov_op, 0, makereg(regFirstArg), ap);
			else
				GenerateDiadic(cpu.mov_op, 0, makereg(regFirstArg), ap);
		}
		else if (ap->mode == am_reg) {
			if (isPosit)
				GenerateDiadic(cpu.mov_op, 0, compiler.of.makepreg(regFirstArg), ap);
			else
				GenerateDiadic(cpu.mov_op, 0, makereg(regFirstArg), ap);
		}
		else if (ap->typep == &stddouble) {
			if (isFloat)
				GenerateDiadic(op_ldf, 'd', makereg(regFirstArg), ap);
			else
				GenerateDiadic(cpu.ldo_op, 0, makereg(regFirstArg), ap);
		}
		else {
			if (sym->tp->btpp->IsVectorType())
				GenLoad(makevreg(regFirstArg), ap, sizeOfWord, sizeOfWord);
			else
				GenLoad(makereg(regFirstArg), ap, sizeOfWord, sizeOfWord);
		}
		ReleaseTempRegister(ap);
	}

	// Generate the return code only once. Branch to the return code for all returns.
	if (retGenerated) {
		GenerateMonadic(cpu.bra_op, 0, MakeCodeLabel(retlab));
		return;
	}
	retGenerated = true;
	GenerateLabel(retlab);
	rcode = pl.tail;

	// Unreferenced objects are garbage collected by the system. There's no need
	// to manage a list of them.

	//if (currentFn->UsesNew) {
	//	if (cpu.SupportsPush)
	//		GenerateMonadic(op_push, 0, makereg(regFirstArg));
	//	else {
	//		GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), MakeImmediate(8));
	//		GenerateDiadic(op_std, 0, makereg(regFirstArg), MakeIndirect(regSP));
	//	}
	//	GenerateDiadic(op_lea, 0, makereg(regFirstArg), MakeIndexed(-sizeOfWord, regFP));
	//	GenerateMonadic(op_call, 0, MakeStringAsNameConst("__AddGarbage"));
	//	GenerateDiadic(op_ldd, 0, makereg(regFirstArg), MakeIndirect(regSP));
	//	GenerateTriadic(op_add, 0, makereg(regSP), makereg(regSP), MakeImmediate(8));
	//}

	// Unlock any semaphores that may have been set
	for (nn = lastsph - 1; nn >= 0; nn--)
		GenerateDiadic(cpu.stb_op, 0, makereg(0), MakeStringAsNameConst(semaphores[nn], dataseg));

	// Restore fp registers used as register variables.
	//if (fpsave_mask->NumMember()) {
	//	cnt2 = cnt = (fpsave_mask->NumMember() - 1)*sizeOfFP;
	//	fpsave_mask->resetPtr();
	//	for (nn = fpsave_mask->lastMember(); nn >= 1; nn = fpsave_mask->prevMember()) {
	//		GenerateDiadic(op_lf, 'd', makefpreg(nregs - 1 - nn), MakeIndexed(cnt2 - cnt, regSP));
	//		cnt -= sizeOfWord;
	//	}
	//	GenerateTriadic(op_add, 0, makereg(regSP), makereg(regSP), MakeImmediate(cnt2 + sizeOfFP));
	//}
	RestoreRegisterVars();
	if (IsNocall) {
		if (epilog) {
			epilog->Generate();
			return;
		}
		return;
	}
	toAdd = 0;
	UnlinkStack(0);
	toAdd = Compiler::GetReturnBlockSize();
	if (!alstk) {
		// The size of the return block is included in the link instruction, so the
		// unlink instruction will reverse the allocation.
		if (cpu.SupportsLink)
			toAdd = 0;
		else if (cpu.SupportsLeave)
			toAdd = 0;
	}
	else if (currentFn->IsLeaf) {
		if (!IsNocall)
			toAdd = Compiler::GetReturnBlockSize();
		else
			toAdd = 0;
	}

	if (epilog) {
		epilog->Generate();
		return;
	}

	// Local variables and the return block must be deallocated before the return instruction.
	// The return address is between these and the parameters. Parameters can be deallocated
	// during the return. For leaf routines, the return address is not present, so it is 
	// safe to combine the de-allocations.
	//if (!currentFn->IsLeaf) {
	//	GenerateTriadic(op_add, 0, makereg(regSP), makereg(regSP), MakeImmediate(toAdd));
	//	toAdd = 0;
	//}

	// If Pascal calling convention remove parameters from stack by adding to stack pointer
	// based on the number of parameters. However if a non-auto register parameter is
	// present, then don't add to the stack pointer for it. (Remove the previous add effect).
	// Also, do not add to the stack pointer for the ellipsis parameter.
	if (IsPascal) {
		TypeArray *ta;
		int nn;
		ta = GetProtoTypes();
		for (nn = 0; nn < ta->length; nn++) {
			switch (ta->types[nn]) {
			case bt_float:
			case bt_quad:
				if (ta->preg[nn] && (ta->preg[nn] & 0x8000) == 0)
					;
				else
					toAdd += sizeOfFPQ;
				break;
			case bt_double:
				if (ta->preg[nn] && (ta->preg[nn] & 0x8000) == 0)
					;
				else
					toAdd += sizeOfFPD;
				break;
			case bt_triple:
				if (ta->preg[nn] && (ta->preg[nn] & 0x8000) == 0)
					;
				else
					toAdd += sizeOfFPT;
				break;
			case bt_posit:
				if (ta->preg[nn] && (ta->preg[nn] & 0x8000) == 0)
					;
				else
					toAdd += sizeOfPosit;
				break;
			case bt_ellipsis:
				break;
			default:
				if (ta->preg[nn] && (ta->preg[nn] & 0x8000) == 0)
					;
				else
					toAdd += sizeOfWord;
			}
		}
	}
	//	if (toAdd != 0)
	//		GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),MakeImmediate(toAdd));
	// Generate the return instruction. For the Pascal calling convention pop the parameters
	// from the stack.
	if (IsInterrupt) {
		//RestoreRegisterSet(sym);
		GenerateZeradic(op_rti);
		return;
	}

	if (!IsInline) {
		if (toAdd > 0) {
			cg.GenerateHint(begin_sp_dealloc);
			GenerateTriadic(op_addi, 0, makereg(regSP), makereg(regSP), MakeImmediate(toAdd));
			cg.GenerateHint(end_sp_dealloc);
			toAdd = 0;
		}
		if (currentFn->IsFar)
			GenerateMonadic(cpu.bra_op, 0, MakeStringAsNameConst("_FAR_RET", codeseg));
		else
			GenerateZeradic(currentFn->IsLeaf ? cpu.ret_op : cpu.ret_op);// , MakeImmediate(toAdd));
	}
	else
		GenerateTriadic(op_addi, 0, makereg(regSP), makereg(regSP), MakeImmediate(toAdd));
}


// Generate a function body.
//
void Function::Generate()
{
	int defcatch;
	Statement *stmt = this->sym->stmt;
	int lab0;
	int o_throwlab, o_retlab, o_contlab, o_breaklab;
	OCODE *ip;
	bool doCatch = true;
	int n;
	int sp, bp, gp, gp1;
	bool o_retgen;

	if (opt_vreg)
		cpu.SetVirtualRegisters();
	o_throwlab = throwlab;
	o_retlab = retlab;
	o_contlab = contlab;
	o_breaklab = breaklab;
	o_retgen = retGenerated;

	retGenerated = false;
	throwlab = retlab = contlab = breaklab = -1;
	lastsph = 0;
	memset(semaphores, 0, sizeof(semaphores));
	throwlab = nextlabel++;
	defcatch = nextlabel++;
	lab0 = nextlabel++;
	defCatchLabel = nextlabel++;

	while (lc_auto % sizeOfWord)	// round frame size to word
		++lc_auto;
	// The prolog code can't be optimized because it'll run *before* any variables
	// assigned to registers are available. About all we can do here is constant
	// optimizations.
	if (prolog) {
		prolog->scan();
		prolog->Generate();
	}
	if (IsInterrupt) {
		if (DoesContextSave)
			GenerateMonadic(op_asm, 0, MakeStringAsNameConst("\n  mSaveContext", codeseg));
		if (sp_init) {
			GenerateDiadic(cpu.ldi_op, 0, makereg(regSP), MakeImmediate(sp_init));
		}
		/*
		if (stkname) {
			GenerateDiadic(op_lea, 0, makereg(SP), MakeStringAsNameConst(stkname,dataseg));
			GenerateTriadic(op_ori, 0, makereg(SP), makereg(SP), MakeImmediate(0xFFFFF00000000000LL));
		}
		*/
		//		StackGPRs();
	}
	// Setup the return block.
	if (!IsNocall)
		SetupReturnBlock();
	stmt->CheckReferences(&sp, &bp, &gp, &gp1);
	if (gp != 0) {
		Operand* ap = GetTempRegister();
		//cg.GenerateLoadConst(MakeStringAsNameConst("#__data_base", dataseg), ap);
		GenerateDiadic(op_lis, 0, makereg(regGP), MakeStringAsNameConst("__data_start@ha", dataseg));
		GenerateTriadic(op_addi, 0, makereg(regGP), makereg(regGP), MakeStringAsNameConst("__data_start@l", dataseg));
		//GenerateTriadic(op_base, 0, makereg(regGP), makereg(regGP), ap);
		ReleaseTempRegister(ap);
	}
	if (gp1 != 0) {
		Operand* ap = GetTempRegister();
		//cg.GenerateLoadConst(MakeStringAsNameConst("#__rodata_base", dataseg), ap);
		GenerateDiadic(op_lis, 0, makereg(regGP1), MakeStringAsNameConst("_start_rodata@ha", dataseg));
		GenerateTriadic(op_addi, 0, makereg(regGP1), makereg(regGP1), MakeStringAsNameConst("_start_rodata@l", dataseg));
		//if (!compiler.os_code)
		//GenerateTriadic(op_base, 0, makereg(regGP1), makereg(regGP1), ap);
		ReleaseTempRegister(ap);
	}
	if (!IsInline)
		GenerateMonadic(op_hint, 0, MakeImmediate(start_funcbody));

	if (optimize) {
		if (currentFn->csetbl == nullptr)
			currentFn->csetbl = new CSETable;
		currentFn->csetbl->Optimize(stmt);
	}
	fpsave_mask = ::fpsave_mask;// CSet::MakeNew();
	save_mask = ::save_mask;// CSet::MakeNew();
	psave_mask = ::psave_mask;// CSet::MakeNew();
	stmt->Generate();
/*
	if (exceptions) {
		ip = pl.tail;
		GenerateMonadic(op_bra, 0, MakeDataLabel(lab0, regZero));
		doCatch = GenDefaultCatch();
		GenerateLabel(lab0);
		if (!doCatch) {
			pl.tail = ip;
			if (pl.tail)
				pl.tail->fwd = nullptr;
		}
	}
*/
//	if (!IsInline)
		GenerateReturn(nullptr);

	// Inline code needs to branch around the default exception handler.
	if (exceptions && sym->IsInline)
		GenerateMonadic(cpu.bra_op,0,MakeCodeLabel(lab0));
	// Generate code for the hidden default catch
	if (exceptions && !IsNocall)
		GenerateDefaultCatch();
	if (exceptions && sym->IsInline)
		GenerateLabel(lab0);

	dfs.puts("<StaticRegs>");
	dfs.puts("====== Statically Assigned Registers =======\n");
	for (n = 0; n < nregs; n++) {
		if (regs[n].assigned && !regs[n].modified) {
			dfs.printf("r%d %c ", n, regs[n].isConst ? 'C' : 'V');
			dfs.printf("=%d\n", regs[n].val);
		}
	}
	dfs.puts("</StaticRegs>");
	currentFn->pl.Dump("===== Peeplist After Generate Pass %d =====\n");
	retGenerated = o_retgen;
	throwlab = o_throwlab;
	retlab = o_retlab;
	contlab = o_contlab;
	breaklab = o_breaklab;
}

// Get catch handler address for next higher catch and force a return to the 
// catch handler. This code jumps to the normal return code so the stack can
// be unwound. But the return address is also set to point to the next higher
// catch handler, so control is transferred there.

void Function::GenerateDefaultCatch()
{
	Operand* ap, * ap2;

	if (!isNocall) {
		initstack();
		if (!hasDefaultCatch)
			GenerateLabel(defCatchLabel);
//		GenerateDiadic(op_bal, 0, makereg(2), MakeStringAsNameConst("_DEFCAT", codeseg));
		ap = GetTempRegister();
		ap2 = GetTempRegister();
		GenerateDiadic(cpu.ldt_op, 0, ap, MakeIndexed((int64_t)0, regFP));				// Get previous frame pointer
		GenerateDiadic(cpu.ldt_op, 0, ap2, MakeIndexed((int64_t)4 * sizeOfWord, ap->preg));		// Get previous handler address
		if (IsLeaf)
			GenerateMonadic(op_mtlr, 0, ap2);
		else
			GenerateDiadic(cpu.stt_op, 0, ap2, MakeIndexed((int64_t)2 * sizeOfWord, regFP));				// move it to return address loc
		ReleaseTempReg(ap2);
		ReleaseTempReg(ap);
		//if (IsFar||true) {
		//	GenerateDiadic(cpu.ldo_op, 0, ap2, MakeIndexed((int64_t)40, ap->preg));		// Get previous handler address base
		//	GenerateDiadic(cpu.sto_op, 0, ap2, MakeIndexed((int64_t)24, regFP));				// move it to return address loc base
		//}
		GenerateMonadic(cpu.bra_op, 0, MakeCodeLabel(retlab));										// And execute return code
	}
}


// Get the parameter types into an array of short integers.
// Only the first 20 parameters are processed.
//
TypeArray *Function::GetParameterTypes()
{
	TypeArray *i16;
	SYM *sp;
	int nn;

	if (this == nullptr)
		return (nullptr);
	//	printf("Enter GetParameterTypes()\r\n");
	i16 = new TypeArray();
	i16->Clear();
	sp = sym->GetPtr(params.GetHead());
	for (nn = 0; sp; nn++) {
		i16->Add(sp->tp, (__int16)(sp->IsRegister ? sp->reg : 0));
		sp = sp->GetNextPtr();
	}
	//	printf("Leave GetParameterTypes()\r\n");
	return i16;
}

TypeArray *Function::GetProtoTypes()
{
	TypeArray *i16;
	SYM *sp;
	int nn;

	//	printf("Enter GetParameterTypes()\r\n");
	nn = 0;
	i16 = new TypeArray();
	i16->Clear();
	if (this == nullptr)
		return (i16);
	sp = sym->GetPtr(proto.GetHead());
	// If there's no prototype try for a parameter list.
	if (sp == nullptr)
		return (GetParameterTypes());
	for (nn = 0; sp; nn++) {
		i16->Add(sp->tp, (__int16)sp->IsRegister ? sp->reg : 0);
		sp = sp->GetNextPtr();
	}
	//	printf("Leave GetParameterTypes()\r\n");
	return i16;
}

void Function::PrintParameterTypes()
{
	TypeArray *ta = GetParameterTypes();
	dfs.printf("Parameter types(%s)\n", (char *)sym->name->c_str());
	ta->Print();
	if (ta)
		delete[] ta;
	ta = GetProtoTypes();
	dfs.printf("Proto types(%s)\n", (char *)sym->name->c_str());
	ta->Print();
	if (ta)
		delete ta;
}

// Build a function signature string including
// the return type, base classes, and any parameters.

std::string *Function::BuildSignature(int opt)
{
	std::string *str;
	std::string *nh;

	dfs.printf("<BuildSignature>");
	if (this == nullptr) {
	}
	if (mangledNames) {
		str = new std::string("_Z");		// 'C' likes this
		dfs.printf("A");
		nh = sym->GetNameHash();
		dfs.printf("B");
		str->append(*nh);
		dfs.printf("C");
		delete nh;
		dfs.printf("D");
		if (sym->name > (std::string *)0x15)
			str->append(*sym->name);
		if (opt) {
			dfs.printf("E");
			str->append(*GetParameterTypes()->BuildSignature());
		}
		else {
			dfs.printf("F");
			str->append(*GetProtoTypes()->BuildSignature());
		}
	}
	else {
		str = new std::string("");
		if (this != nullptr)
			if (sym != nullptr)
				if (sym->name != nullptr)
					str->append(*sym->name);
	}
	dfs.printf(":%s</BuildSignature>", (char *)str->c_str());
	return str;
}

// Check if the passed parameter list matches the one in the
// symbol.
// Allows a null pointer to be passed indicating no parameters

bool Function::ProtoTypesMatch(TypeArray *ta)
{
	TypeArray *tb;

	tb = GetProtoTypes();
	if (tb->IsEqual(ta)) {
		delete tb;
		return true;
	}
	delete tb;
	return false;
}

bool Function::ParameterTypesMatch(TypeArray *ta)
{
	TypeArray *tb;

	tb = GetProtoTypes();
	if (tb->IsEqual(ta)) {
		delete tb;
		return true;
	}
	delete tb;
	return false;
}

// Check if the parameter type list of two different symbols
// match.

bool Function::ProtoTypesMatch(Function *sym)
{
	TypeArray *ta;
	bool ret;

	ta = sym->GetProtoTypes();
	ret = ProtoTypesMatch(ta);
	delete ta;
	return (ret);
}

bool Function::ParameterTypesMatch(Function *sym)
{
	TypeArray *ta;
	bool ret;

	ta = GetProtoTypes();
	ret = sym->ParameterTypesMatch(ta);
	delete ta;
	return (ret);
}

// First check the return type because it's simple to do.
// Then check the parameters.

bool Function::CheckSignatureMatch(Function *a, Function *b) const
{
	std::string ta, tb;

	//	if (a->tp->typeno != b->tp->typeno)
	//		return false;

	ta = a->BuildSignature()->substr(5);
	tb = b->BuildSignature()->substr(5);
	return (ta.compare(tb) == 0);
}


void Function::CheckParameterListMatch(Function *s1, Function *s2)
{
	if (!TYP::IsSameType(s1->parms->tp, s2->parms->tp, false))
		error(ERR_PARMLIST_MISMATCH);
}


// Parameters:
//    mm = number of entries to search (typically the value 
//         TABLE::matchno teh number of matches found

Function *Function::FindExactMatch(int mm)
{
	Function *sp1;
	int nn;
	TypeArray *ta, *tb;

	sp1 = nullptr;
	for (nn = 0; nn < mm; nn++) {
		dfs.printf("%d", nn);
		sp1 = TABLE::match[nn]->fi;
		// Matches sp1 prototype list against this's parameter list
		ta = sp1->GetProtoTypes();
		tb = GetParameterTypes();
		if (ta->IsEqual(tb)) {
			delete ta;
			delete tb;
			return (sp1);
		}
		delete ta;
		delete tb;
	}
	return (nullptr);
}

// Lookup the exactly matching method from the results returned by a
// find operation. Find might return multiple values if there are 
// overloaded functions.

Function *Function::FindExactMatch(int mm, std::string name, int rettype, TypeArray *typearray)
{
	Function *sp1;
	int nn;
	TypeArray *ta;

	sp1 = nullptr;
	for (nn = 0; nn < mm; nn++) {
		if (TABLE::match[nn] != nullptr) {
			sp1 = TABLE::match[nn]->fi;
			ta = sp1->GetProtoTypes();
			if (ta->IsEqual(typearray)) {
				delete ta;
				return sp1;
			}
			delete ta;
		}
	}
	return (nullptr);
}

void Function::BuildParameterList(int *num, int *numa, int* ellipos)
{
	int64_t poffset;
	int i, reg, fpreg, preg;
	SYM *sp1;
	int onp;
	int np;
	bool noParmOffset = false;
	Stringx oldnames[MAX_PARMS];
	int old_nparms;
	ParameterDeclaration pd;

	dfs.printf("<BuildParameterList>");
	if (this->hasParameters) {
		dfs.printf("Function parameter list already processed.");
		pd.Parse(1, true);
		return;
	}
	this->hasParameters = true;
	if (opt_vreg)
		cpu.SetVirtualRegisters();
	poffset = 0;//GetReturnBlockSize();
				//	sp->parms = (SYM *)NULL;
	old_nparms = nparms;
	for (np = 0; np < nparms; np++)
		oldnames[np] = names[np];
	onp = nparms;
	nparms = 0;
	reg = regFirstArg;
	fpreg = regFirstArg;
	preg = regFirstArg;
	// Parameters will be inserted into the symbol's parameter list when
	// declarations are processed.
	//if (strcmp(sym->name->c_str(), "__Skip") == 0)
	//	printf("hello");
	np = pd.ParameterDeclaration::Parse(1, false);
	*num += np;
	*numa = 0;
	if (pd.ellip >= 0)
		*ellipos = pd.ellip;
	dfs.printf("B");
	nparms = onp;
	this->NumParms = *num;
	for (i = 0; i < np && i < MAX_PARMS; ++i) {
		if ((sp1 = currentFn->params.Find(names[i].str, false)) == NULL) {
			dfs.printf("C");
			sp1 = makeint2(names[i].str);
			//			lsyms.insert(sp1);
		}
		sp1->parmno = i;
		sp1->parent = sym->parent;
		sp1->IsParameter = true;
		sp1->value.i = poffset;
		noParmOffset = false;
		if (sp1->tp->IsFloatType()) {
			if (reg > regLastArg)
				sp1->IsRegister = false;
			if (sp1->IsRegister && sp1->tp->size < 11) {
				sp1->reg = sp1->IsAuto ? reg | 0x8000 : reg;
				reg++;
				if ((reg & 0x8000) == 0) {
					noParmOffset = true;
					sp1->value.i = -1;
				}
			}
			else
				sp1->IsRegister = false;
		}
		else if (sp1->tp->IsPositType()) {
			if (reg > regLastArg)
				sp1->IsRegister = false;
			if (sp1->IsRegister && sp1->tp->size < 11) {
				sp1->reg = sp1->IsAuto ? reg | 0x8000 : reg;
				reg++;
				if ((reg & 0x8000) == 0) {
					noParmOffset = true;
					sp1->value.i = -1;
				}
			}
			else
				sp1->IsRegister = false;
		}
		else {
			if (reg > regLastArg)
				sp1->IsRegister = false;
			if (sp1->IsRegister && sp1->tp->size < 11) {
				sp1->reg = sp1->IsAuto ? reg | 0x8000 : reg;
				reg++;
				if ((reg & 0x8000) == 0) {
					noParmOffset = true;
					sp1->value.i = -1;
				}
			}
			else
				sp1->IsRegister = false;
		}
		if (!sp1->IsRegister)// && !sp1->IsInline)
			*numa += 1;
		// Check for aggregate types passed as parameters. Structs
		// and unions use the type size. There could also be arrays
		// passed.
		if (!noParmOffset)
			poffset += round8(sp1->tp->size);
		if (round8(sp1->tp->size) > sizeOfWord && !sp1->tp->IsVectorType())
			IsLeaf = FALSE;
		sp1->storage_class = sc_auto;
	}
	// Process extra hidden parameter
	// ToDo: verify that the hidden parameter is required here.
	// It is generated while processing expressions. It may not be needed
	// here.
	if (sym->tp) {
		if (sym->tp->btpp) {
			if (sym->tp->btpp->type == bt_struct || sym->tp->btpp->type == bt_union || sym->tp->btpp->type == bt_class) {
				if (sym->tp->btpp->size > sizeOfWord) {
					sp1 = makeStructPtr("_pHiddenStructPtr");
					sp1->parmno = i;
					sp1->IsParameter = true;
					sp1->parent = sym->parent;
					sp1->value.i = poffset;
					poffset += sizeOfWord;
					sp1->storage_class = sc_register;
					sp1->IsAuto = false;
					sp1->next = 0;
					sp1->IsRegister = true;
					if (reg > regLastArg)
						sp1->IsRegister = false;
					if (sp1->IsRegister && sp1->tp->size < 11) {
						sp1->reg = sp1->IsAuto ? reg | 0x8000 : reg;
						preg++;
						if ((reg & 0x8000) == 0) {
							noParmOffset = true;
							sp1->value.i = -1;
						}
					}
					else
						sp1->IsRegister = false;
					// record parameter list
					params.insert(sp1);
					//		nparms++;
					if (!sp1->IsRegister)
						*numa += 1;
					*num = *num + 1;
				}
			}
		}
	}
	nparms = old_nparms;
	for (np = 0; np < nparms; np++)
		names[np] = oldnames[np];
	dfs.printf("</BuildParameterList>\n");
}

void Function::AddParameters(SYM *list)
{
	SYM *nxt;

	while (list) {
		nxt = list->GetNextPtr();
		params.insert(SYM::Copy(list));
		list = nxt;
	}

}

void Function::AddProto(SYM *list)
{
	SYM *nxt;

	while (list) {
		nxt = list->GetNextPtr();
		proto.insert(SYM::Copy(list));	// will clear next
		list = nxt;
	}
}

void Function::AddProto(TypeArray *ta)
{
	SYM *sym;
	int nn;
	char buf[20];

	for (nn = 0; nn < ta->length; nn++) {
		sym = allocSYM();
		sprintf_s(buf, sizeof(buf), "_p%d", nn);
		sym->SetName(std::string(buf));
		sym->tp = TYP::Make(ta->types[nn], TYP::GetSize(ta->types[nn]));
		sym->tp->type = (e_bt)TYP::GetBasicType(ta->types[nn]);
		sym->IsRegister = ta->preg[nn] != 0;
		sym->reg = ta->preg[nn];
		proto.insert(sym);
	}
}

void Function::AddDerived()
{
	DerivedMethod *mthd;

	dfs.puts("<AddDerived>");
	mthd = (DerivedMethod *)allocx(sizeof(DerivedMethod));
	dfs.printf("A");
	if (sym->tp == nullptr)
		dfs.printf("Nullptr");
	if (sym->GetParentPtr() == nullptr)
		throw C64PException(ERR_NULLPOINTER, 10);
	mthd->typeno = sym->GetParentPtr()->tp->typeno;
	dfs.printf("B");
	mthd->name = BuildSignature();

	dfs.printf("C");
	if (derivitives) {
		dfs.printf("D");
		mthd->next = derivitives;
	}
	derivitives = mthd;
	dfs.puts("</AddDerived>");
}

bool Function::HasRegisterParameters()
{
	int nn;

	TypeArray *ta = GetParameterTypes();
	for (nn = 0; nn < ta->length; nn++) {
		if (ta->preg[nn] & 0x8000) {
			delete[] ta;
			return (true);
		}
	}
	delete[] ta;
	return (false);
}


void Function::CheckForUndefinedLabels()
{
	SYM *head = SYM::GetPtr(sym->lsyms.GetHead());

	while (head != 0) {
		if (head->storage_class == sc_ulabel)
			lfs.printf("*** UNDEFINED LABEL - %s\n", (char *)head->name->c_str());
		head = head->GetNextPtr();
	}
}


void Function::Summary(Statement *stmt)
{
	dfs.printf("<FuncSummary>\n");
	irfs.printf("\nFunction:%s\n", (char *)this->sym->name->c_str());
	nl();
	CheckForUndefinedLabels();
	lc_auto = 0;
	lfs.printf("\n\n*** local symbol table ***\n\n");
	ListTable(&sym->lsyms, 0);
	// Should recurse into all the compound statements
	if (stmt == NULL)
		dfs.printf("DIAG: null statement in Function::Summary.\r\n");
	else {
		if (stmt->stype == st_compound)
			stmt->ListCompoundVars();
		//stmt->storeHex(irfs);
	}
	lfs.printf("\n\n\n");
	//    ReleaseLocalMemory();        // release local symbols
	isPascal = defaultcc==1;
	isKernel = FALSE;
	isOscall = FALSE;
	isInterrupt = FALSE;
	isNocall = FALSE;
	ofs.printf("#--}\n");
	dfs.printf("</FuncSummary>\n");
}

//=============================================================================
//=============================================================================
// C O D E   G E N E R A T I O N
//=============================================================================
//=============================================================================

Operand *Function::MakeDataLabel(int lab, int ndxreg) { return (compiler.of.MakeDataLabel(lab, ndxreg)); }
Operand *Function::MakeCodeLabel(int lab) { return (compiler.of.MakeCodeLabel(lab)); }
Operand *Function::MakeString(char *s) { return (compiler.of.MakeString(s)); }
Operand *Function::MakeImmediate(int64_t i) { return (compiler.of.MakeImmediate(i)); }
Operand *Function::MakeIndirect(int i) { return (compiler.of.MakeIndirect(i)); }
Operand *Function::MakeDoubleIndexed(int i, int j, int scale) { return (compiler.of.MakeDoubleIndexed(i, j, scale)); }
Operand *Function::MakeDirect(ENODE *node) { return (compiler.of.MakeDirect(node)); }
Operand *Function::MakeStringAsNameConst(char *s, e_sg seg) { return (compiler.of.MakeStringAsNameConst(s, seg)); }
Operand *Function::MakeIndexed(int64_t o, int i) { return (cg.MakeIndexed(o, i)); }
Operand *Function::MakeIndexed(ENODE *node, int rg) { return (cg.MakeIndexed(node, rg)); }
void Function::GenLoad(Operand *ap3, Operand *ap1, int ssize, int size) { cg.GenerateLoad(ap3, ap1, ssize, size); }


// When going to insert a class method, check the base classes to see if it's
// a virtual function override. If it's an override, then add the method to
// the list of overrides for the virtual function.

void Function::InsertMethod()
{
	int nn;
	SYM *sy;
	std::string name;

	name = *sym->name;
	dfs.printf("<InsertMethod>%s type %d ", (char *)sym->name->c_str(), sym->tp->type);
	sym->GetParentPtr()->tp->lst.insert(sym);
	nn = sym->GetParentPtr()->tp->lst.FindRising(*sym->name);
	sy = sym->FindRisingMatch(true);
	if (sy) {
		dfs.puts("Found in a base class:");
		if (sy->fi->IsVirtual) {
			dfs.printf("Found virtual:");
			sy->fi->AddDerived();
		}
	}
	dfs.printf("</InsertMethod>\n");
}

void Function::CreateVars()
{
	BasicBlock *b;
	int nn;
	int num;

	varlist = nullptr;
	Var::nvar = 0;
	for (b = RootBlock; b; b = b->next) {
		b->LiveOut->resetPtr();
		for (nn = 0; nn < b->LiveOut->NumMember(); nn++) {
			num = b->LiveOut->nextMember();
			Var::Find(num);	// find will create the var if not found
		}
		//for (nn = 0; nn < b->LiveIn->NumMember(); nn++) {
		//	num = b->LiveIn->nextMember();
		//	Var::Find(num);	// find will create the var if not found
		//}
	}
}


void Function::ComputeLiveVars()
{
	BasicBlock *b;
	bool changed;
	int iter;
	int changes;

	changed = false;
	for (iter = 0; (iter == 0 || changed) && iter < 10000; iter++) {
		changes = 0;
		changed = false;
		for (b = LastBlock; b; b = b->prev) {
			b->ComputeLiveVars();
			if (b->changed) {
				changes++;
				changed = true;
			}
		}
	}
}

void Function::DumpLiveVars()
{
	BasicBlock *b;
	int nn;
	int lomax, limax;

	lomax = limax = 0;
	for (b = RootBlock; b; b = b->next) {
		lomax = max(lomax, b->LiveOut->NumMember());
		limax = max(limax, b->LiveIn->NumMember());
	}

	dfs.printf("<table style=\"width:100%\">\n");
	//dfs.printf("<LiveVarTable>\n");
	for (b = RootBlock; b; b = b->next) {
		b->LiveIn->resetPtr();
		b->LiveOut->resetPtr();
		dfs.printf("<tr><td>%d: </td>", b->num);
		for (nn = 0; nn < b->LiveIn->NumMember(); nn++)
			dfs.printf("<td>vi%d </td>", b->LiveIn->nextMember());
		for (; nn < limax; nn++)
			dfs.printf("<td></td>");
		dfs.printf("<td> || </td>");
		for (nn = 0; nn < b->LiveOut->NumMember(); nn++)
			dfs.printf("<td>vo%d </td>", b->LiveOut->nextMember());
		for (; nn < lomax; nn++)
			dfs.printf("<td></td>");
		dfs.printf("</tr>\n");
	}
	//dfs.printf("</LiveVarTable>\n");
	dfs.printf("</table>\n");
}


void Function::storeHex(txtoStream& ofs)
{

}

void Function::RemoveDuplicates()
{
	int n;

	n = compiler.funcnum - 1;
	if (n < 1)
		return;
	//if (compiler.functionTable[n].sym->name.compare(compiler.functionTable[n - 1].sym->name) == 0) {

	//}
}




