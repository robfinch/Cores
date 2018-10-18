// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
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

Statement *Function::ParseBody()
{
	std::string lbl;
	char *p;
	OCODE *ip;

	dfs.printf("<Parse function body>:%s|\n", (char *)sym->name->c_str());

	lbl = std::string("");
	needpunc(begin, 47);

	tmpReset();
	//ParseAutoDeclarations();
	cseg();
	if (sym->storage_class == sc_static)
	{
		//lbl = GetNamespace() + std::string("_");
		//strcpy(lbl,GetNamespace());
		//strcat(lbl,"_");
		//		strcpy(lbl,sp->name);
		lbl += *sym->mangledName;
		//gen_strlab(lbl);
	}
	//	put_label((unsigned int) sp->value.i);
	else {
		if (sym->storage_class == sc_global)
			lbl = "public code ";
		//		strcat(lbl,sp->name);
		lbl += *sym->mangledName;
		//gen_strlab(lbl);
	}
	dfs.printf("B");
	p = my_strdup((char *)lbl.c_str());
	dfs.printf("b");
	if (!IsInline)
		GenerateMonadic(op_fnname, 0, make_string(p));
	currentFn = this;
	IsLeaf = TRUE;
	DoesThrow = FALSE;
	UsesPredicate = FALSE;
	UsesNew = FALSE;
	regmask = 0;
	bregmask = 0;
	currentStmt = (Statement *)NULL;
	dfs.printf("C");
	stmtdepth = 0;
	sym->stmt = Statement::ParseCompound();
	dfs.printf("D");
	//	stmt->stype = st_funcbody;
	while (lc_auto % sizeOfWord)	// round frame size to word
		++lc_auto;
	stkspace = lc_auto;
	if (!IsInline) {
		pass = 1;
		ip = peep_tail;
		looplevel = 0;
		Gen();
		stkspace += (ArgRegCount - regFirstArg) * sizeOfWord;
		argbot = -stkspace;
		stkspace += GetTempMemSpace();
		tempbot = -stkspace;
		pass = 2;
		peep_tail = ip;
		peep_tail->fwd = nullptr;
		looplevel = 0;
		Gen();
		dfs.putch('E');

		flush_peep();
		if (sym->storage_class == sc_global) {
			ofs.printf("endpublic\r\n\r\n");
		}
	}
	//if (sp->stkspace)
	//ofs.printf("%sSTKSIZE_ EQU %d\r\n", (char *)sp->mangledName->c_str(), sp->stkspace);
	isFuncBody = false;
	dfs.printf("</ParseFunctionBody>\n");
	return (sym->stmt);
}

void Function::Init(int nump, int numarg)
{
	IsNocall = isNocall;
	IsPascal = isPascal;
	sym->IsKernel = isKernel;
	IsInterrupt = isInterrupt;
	IsTask = isTask;
	NumParms = nump;
	numa = numarg;
	IsVirtual = isVirtual;
	IsInline = isInline;

	isPascal = FALSE;
	isKernel = FALSE;
	isOscall = FALSE;
	isInterrupt = FALSE;
	isTask = FALSE;
	isNocall = FALSE;
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
	int nump, numar;
	std::string nme;

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
	BuildParameterList(&nump, &numar);
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

	if (sp != osp) {
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
	}
	dfs.printf("D");
	if (sp->sym->tp->type == bt_pointer) {
		if (lastst == assign) {
			doinit(sp->sym);	// was doinit(sym);
		}
		sp->Init(nump, numar);
		return (1);
	}
j2:
	dfs.printf("E");
	if (lastst == semicolon || lastst == comma) {	// Function prototype
		dfs.printf("e");
		sp->IsPrototype = 1;
		sp->Init(nump, numar);
		sp->params.MoveTo(&sp->proto);
		goto j1;
	}
	else if (lastst == kw_attribute) {
		while (lastst == kw_attribute) {
			Declaration::ParseFunctionAttribute(sp);
		}
		goto j2;
	}
	else if (lastst != begin) {
		dfs.printf("F");
		//			NextToken();
		//			ParameterDeclaration::Parse(2);
		sp->BuildParameterList(&nump, &numar);
		// for old-style parameter list
		//needpunc(closepa);
		if (lastst == semicolon) {
			sp->IsPrototype = 1;
			sp->Init(nump, numar);
		}
		// Check for end of function parameter list.
		else if (funcdecl == 2 && lastst == closepa) {
			;
		}
		else {
			sp->Init(nump, numar);
			sp->sym->stmt = ParseBody();
			Summary(sp->sym->stmt);
		}
	}
	//                error(ERR_BLOCK);
	else {
		dfs.printf("G");
		sp->Init(nump, numar);
		// Parsing declarations sets the storage class to extern when it really
		// should be global if there is a function body.
		if (sp->sym->storage_class == sc_external)
			sp->sym->storage_class = sc_global;
		sp->sym->stmt = ParseBody();
		Summary(sp->sym->stmt);
	}
j1:
	dfs.printf("F");
	dfs.puts("</ParseFunction>\n");
	return (0);
}

// Push temporaries on the stack.

void Function::SaveGPRegisterVars()
{
	int cnt;
	int nn;

	if (mask != 0) {
		cnt = 0;
		GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), make_immed(popcnt(mask) * 8));
		for (nn = 0; nn < 64; nn++) {
			if (rmask & (0x8000000000000000ULL >> nn)) {
				GenerateDiadic(op_sw, 0, makereg(nn), make_indexed(cnt, regSP));
				cnt += sizeOfWord;
			}
		}
	}
}

void Function::SaveFPRegisterVars()
{
	int cnt;
	int nn;

	if (fpmask != 0) {
		cnt = 0;
		GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), make_immed(popcnt(fpmask) * 8));
		for (nn = 0; nn < 64; nn++) {
			if (fprmask & (0x8000000000000000ULL >> nn)) {
				GenerateDiadic(op_sf, 'd', makefpreg(nn), make_indexed(cnt, regSP));
				cnt += sizeOfWord;
			}
		}
	}
}

void Function::SaveRegisterVars()
{
	SaveGPRegisterVars();
	SaveFPRegisterVars();
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
			GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), make_immed(count * sizeOfWord));
			for (count = nn = 0; nn < ta->length; nn++) {
				if (ta->preg[nn]) {
					switch (ta->types[nn]) {
					case bt_quad:	GenerateDiadic(op_sf, 'q', makereg(ta->preg[nn] & 0x7fff), make_indexed(count*sizeOfWord, regSP)); count += 2; break;
					case bt_float:	GenerateDiadic(op_sf, 'd', makereg(ta->preg[nn] & 0x7fff), make_indexed(count*sizeOfWord, regSP)); count += 1; break;
					case bt_double:	GenerateDiadic(op_sf, 'd', makereg(ta->preg[nn] & 0x7fff), make_indexed(count*sizeOfWord, regSP)); count += 1; break;
					case bt_triple:	GenerateDiadic(op_sf, 't', makereg(ta->preg[nn] & 0x7fff), make_indexed(count*sizeOfWord, regSP)); count += 2; break;
					default:	GenerateDiadic(op_sw, 0, makereg(ta->preg[nn] & 0x7fff), make_indexed(count*sizeOfWord, regSP)); count += 1; break;
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
		GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), make_immed(count * sizeOfWord));
		for (count = nn = 0; nn < ta->length; nn++) {
			if (ta->preg[nn]) {
				switch (ta->types[nn]) {
				case bt_quad:	GenerateDiadic(op_lf, 'q', makereg(ta->preg[nn] & 0x7fff), make_indexed(count*sizeOfWord, regSP)); count += 2; break;
				case bt_float:	GenerateDiadic(op_lf, 'd', makereg(ta->preg[nn] & 0x7fff), make_indexed(count*sizeOfWord, regSP)); count += 1; break;
				case bt_double:	GenerateDiadic(op_lf, 'd', makereg(ta->preg[nn] & 0x7fff), make_indexed(count*sizeOfWord, regSP)); count += 1; break;
				case bt_triple:	GenerateDiadic(op_lf, 't', makereg(ta->preg[nn] & 0x7fff), make_indexed(count*sizeOfWord, regSP)); count += 2; break;
				default:	GenerateDiadic(op_lw, 0, makereg(ta->preg[nn] & 0x7fff), make_indexed(count*sizeOfWord, regSP)); count += 1; break;
				}
			}
		}
	}
}


void Function::RestoreGPRegisterVars()
{
	int cnt2, cnt;
	int nn;

	if (save_mask != 0) {
		cnt2 = cnt = popcnt(save_mask)*sizeOfWord;
		cnt = 0;
		for (nn = 0; nn < 64; nn++) {
			if (save_mask & (1LL << nn)) {
				GenerateDiadic(op_lw, 0, makereg(nn), make_indexed(cnt, regSP));
				cnt += sizeOfWord;
			}
		}
		GenerateTriadic(op_add, 0, makereg(regSP), makereg(regSP), make_immed(cnt2));
	}
}

void Function::RestoreFPRegisterVars()
{
	int cnt2, cnt;
	int nn;

	if (fpsave_mask != 0) {
		cnt2 = cnt = popcnt(fpsave_mask)*sizeOfWord;
		cnt = 0;
		for (nn = 0; nn < 64; nn++) {
			if (fpsave_mask & (1LL << nn)) {
				GenerateDiadic(op_lf, 'd', makefpreg(nn), make_indexed(cnt, regSP));
				cnt += sizeOfWord;
			}
		}
		GenerateTriadic(op_add, 0, makereg(regSP), makereg(regSP), make_immed(cnt2));
	}
}

void Function::RestoreRegisterVars()
{
	RestoreGPRegisterVars();
	RestoreFPRegisterVars();
}

void Function::SaveTemporaries(int *sp, int *fsp)
{
	if (this) {
		if (UsesTemps) {
			*sp = TempInvalidate(fsp);
			//*fsp = TempFPInvalidate();
		}
	}
	else {
		*sp = TempInvalidate(fsp);
		//*fsp = TempFPInvalidate();
	}
}

void Function::RestoreTemporaries(int sp, int fsp)
{
	if (this) {
		if (UsesTemps) {
			//TempFPRevalidate(fsp);
			TempRevalidate(sp, fsp);
		}
	}
	else {
		//TempFPRevalidate(fsp);
		TempRevalidate(sp, fsp);
	}
}


// Unlink the stack

void Function::UnlinkStack()
{
	GenerateDiadic(op_mov, 0, makereg(regSP), makereg(regFP));
	GenerateDiadic(op_lw, 0, makereg(regFP), make_indirect(regSP));
	if (exceptions) {
		if (!IsLeaf || DoesThrow)
			GenerateDiadic(op_lw, 0, makereg(regXLR), make_indexed(2 * sizeOfWord, regSP));
	}
	if (!IsLeaf)
		GenerateDiadic(op_lw, 0, makereg(regLR), make_indexed(3 * sizeOfWord, regSP));
	//	GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(3*sizeOfWord));
}

bool Function::GenDefaultCatch()
{
	GenerateLabel(throwlab);
	if (IsLeaf) {
		if (DoesThrow) {
			GenerateDiadic(op_lw, 0, makereg(regLR), make_indexed(2 * sizeOfWord, regFP));		// load throw return address from stack into LR
			GenerateDiadic(op_sw, 0, makereg(regLR), make_indexed(3 * sizeOfWord, regFP));		// and store it back (so it can be loaded with the lm)
																									//GenerateDiadic(op_spt,0,makereg(0),make_indexed(3 * sizeOfWord, regFP));
																									//			GenerateDiadic(op_bra,0,make_label(retlab),NULL);				// goto regular return cleanup code
			return (true);
		}
	}
	else {
		GenerateDiadic(op_lw, 0, makereg(regLR), make_indexed(2 * sizeOfWord, regFP));		// load throw return address from stack into LR
		GenerateDiadic(op_sw, 0, makereg(regLR), make_indexed(3 * sizeOfWord, regFP));		// and store it back (so it can be loaded with the lm)
																								//GenerateDiadic(op_spt, 0, makereg(0), make_indexed(3 * sizeOfWord, regFP));
																								//		GenerateDiadic(op_bra,0,make_label(retlab),NULL);				// goto regular return cleanup code
		return (true);
	}
	return (false);
}


// For a leaf routine don't bother to store the link register.
void Function::SetupReturnBlock()
{
	Operand *ap;
	int n;

	GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), make_immed(4 * sizeOfWord));
	GenerateDiadic(op_sw, 0, makereg(regFP), make_indirect(regSP));
	GenerateDiadic(op_sw, 0, makereg(regZero), make_indexed(sizeOfWord, regSP));
	//	GenerateTriadic(op_swp, 0, makereg(regFP), makereg(regZero), make_indirect(regSP));
	n = 0;
	if (exceptions) {
		if (!IsLeaf || DoesThrow) {
			n = 1;
			GenerateDiadic(op_sw, 0, makereg(regXLR), make_indexed(2 * sizeOfWord, regSP));
		}
	}
	if (!IsLeaf) {
		n |= 2;
		GenerateDiadic(op_sw, 0, makereg(regLR), make_indexed(3 * sizeOfWord, regSP));
	}
	/*
	switch (n) {
	case 0:	break;
	case 1:	GenerateDiadic(op_sw, 0, makereg(regXLR), make_indexed(2 * sizeOfWord, regSP)); break;
	case 2:	GenerateDiadic(op_sw, 0, makereg(regLR), make_indexed(3 * sizeOfWord, regSP)); break;
	case 3:	GenerateTriadic(op_swp, 0, makereg(regXLR), makereg(regLR), make_indexed(2 * sizeOfWord, regSP)); break;
	}
	*/
	ap = make_label(throwlab);
	ap->mode = am_imm;
	if (exceptions && (!IsLeaf || DoesThrow))
		GenerateDiadic(op_ldi, 0, makereg(regXLR), ap);
	GenerateDiadic(op_mov, 0, makereg(regFP), makereg(regSP));
	GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), make_immed(stkspace));
	spAdjust = peep_tail;
}

// Generate a return statement.
//
void Function::GenReturn(Statement *stmt)
{
	Operand *ap, *ap2;
	int nn;
	int cnt, cnt2;
	int toAdd;
	SYM *p;
	bool isFloat;

	// Generate the return expression and force the result into r1.
	if (stmt != NULL && stmt->exp != NULL)
	{
		initstack();
		isFloat = sym->tp->GetBtp() && sym->tp->GetBtp()->IsFloatType();
		if (isFloat)
			ap = GenerateExpression(stmt->exp, F_FPREG, sizeOfFP);
		else
			ap = GenerateExpression(stmt->exp, F_REG | F_IMMED, sizeOfWord);
		GenerateMonadic(op_hint, 0, make_immed(2));
		if (ap->mode == am_imm)
			GenLdi(makereg(1), ap);
		else if (ap->mode == am_reg) {
			if (sym->tp->GetBtp() && (sym->tp->GetBtp()->type == bt_struct || sym->tp->GetBtp()->type == bt_union)) {
				p = params.Find("_pHiddenStructPtr", false);
				if (p) {
					if (p->IsRegister)
						GenerateDiadic(op_mov, 0, makereg(1), makereg(p->reg));
					else
						GenerateDiadic(op_lw, 0, makereg(1), make_indexed(p->value.i, regFP));
					GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), make_immed(sizeOfWord * 3));
					ap2 = GetTempRegister();
					GenerateDiadic(op_ldi, 0, ap2, make_immed(sym->tp->GetBtp()->size));
					GenerateDiadic(op_sw, 0, makereg(1), make_indirect(regSP));
					GenerateDiadic(op_sw, 0, ap, make_indexed(sizeOfWord,regSP));
					GenerateDiadic(op_sw, 0, ap2, make_indexed(sizeOfWord * 2, regSP));
					ReleaseTempReg(ap2);
					GenerateMonadic(op_call, 0, make_string("_memcpy"));
					GenerateTriadic(op_add, 0, makereg(regSP), makereg(regSP), make_immed(sizeOfWord * 3));
				}
				else {
					// ToDo compiler error
				}
			}
			else {
				if (sym->tp->GetBtp()->IsFloatType())
					GenerateDiadic(op_mov, 0, makefpreg(1), ap);
				else if (sym->tp->GetBtp()->IsVectorType())
					GenerateDiadic(op_mov, 0, makevreg(1), ap);
				else
					GenerateDiadic(op_mov, 0, makereg(1), ap);
			}
		}
		else if (ap->mode == am_fpreg) {
			if (isFloat)
				GenerateDiadic(op_mov, 0, makefpreg(1), ap);
			else
				GenerateDiadic(op_mov, 0, makereg(1), ap);
		}
		else if (ap->type == stddouble.GetIndex()) {
			if (isFloat)
				GenerateDiadic(op_lf, 'd', makereg(1), ap);
			else
				GenerateDiadic(op_lw, 0, makereg(1), ap);
		}
		else {
			if (sym->tp->GetBtp()->IsVectorType())
				GenLoad(makevreg(1), ap, sizeOfWord, sizeOfWord);
			else
				GenLoad(makereg(1), ap, sizeOfWord, sizeOfWord);
		}
		ReleaseTempRegister(ap);
	}

	// Generate the return code only once. Branch to the return code for all returns.
	if (retlab != -1) {
		GenerateMonadic(op_bra, 0, make_label(retlab));
		return;
	}
	retlab = nextlabel++;
	GenerateLabel(retlab);
	rcode = peep_tail;

	if (currentFn->UsesNew) {
		GenerateTriadic(op_sub, 0, makereg(regSP), makereg(regSP), make_immed(8));
		GenerateDiadic(op_sw, 0, makereg(regFirstArg), make_indirect(regSP));
		GenerateDiadic(op_lea, 0, makereg(regFirstArg), make_indexed(-sizeOfWord, regFP));
		GenerateMonadic(op_call, 0, make_string("__AddGarbage"));
		GenerateDiadic(op_lw, 0, makereg(regFirstArg), make_indirect(regSP));
		GenerateTriadic(op_add, 0, makereg(regSP), makereg(regSP), make_immed(8));
	}

	// Unlock any semaphores that may have been set
	for (nn = lastsph - 1; nn >= 0; nn--)
		GenerateDiadic(op_sb, 0, makereg(0), make_string(semaphores[nn]));

	// Restore fp registers used as register variables.
	if (fpsave_mask != 0) {
		cnt2 = cnt = (popcnt(fpsave_mask) - 1)*sizeOfFP;
		for (nn = 31; nn >= 1; nn--) {
			if (fpsave_mask & (1LL << nn)) {
				GenerateDiadic(op_lw, 0, makereg(nn), make_indexed(cnt2 - cnt, regSP));
				cnt -= sizeOfWord;
			}
		}
		GenerateTriadic(op_add, 0, makereg(regSP), makereg(regSP), make_immed(cnt2 + sizeOfFP));
	}
	RestoreRegisterVars();
	if (IsNocall) {
		if (epilog) {
			epilog->Generate();
			return;
		}
		return;
	}
	UnlinkStack();
	toAdd = 4 * sizeOfWord;

	if (epilog) {
		epilog->Generate();
		return;
	}

	// If Pascal calling convention remove parameters from stack by adding to stack pointer
	// based on the number of parameters. However if a non-auto register parameter is
	// present, then don't add to the stack pointer for it. (Remove the previous add effect).
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
			default:
				if (ta->preg[nn] && (ta->preg[nn] & 0x8000) == 0)
					;
				else
					toAdd += sizeOfWord;
			}
		}
	}
	//	if (toAdd != 0)
	//		GenerateTriadic(op_add,0,makereg(regSP),makereg(regSP),make_immed(toAdd));
	// Generate the return instruction. For the Pascal calling convention pop the parameters
	// from the stack.
	if (IsInterrupt) {
		//RestoreRegisterSet(sym);
		GenerateZeradic(op_rti);
		return;
	}

	if (!IsInline) {
		GenerateMonadic(op_ret, 0, make_immed(toAdd));
		//GenerateMonadic(op_jal,0,make_indirect(regLR));
	}
	else
		GenerateTriadic(op_add, 0, makereg(regSP), makereg(regSP), make_immed(toAdd));
}


// Generate a function body.
//
void Function::Gen()
{
	int defcatch;
	Statement *stmt = this->sym->stmt;
	int lab0;
	int o_throwlab, o_retlab, o_contlab, o_breaklab;
	OCODE *ip;
	bool doCatch = true;

	o_throwlab = throwlab;
	o_retlab = retlab;
	o_contlab = contlab;
	o_breaklab = breaklab;

	throwlab = retlab = contlab = breaklab = -1;
	lastsph = 0;
	memset(semaphores, 0, sizeof(semaphores));
	throwlab = nextlabel++;
	defcatch = nextlabel++;
	lab0 = nextlabel++;

	while (lc_auto % sizeOfWord)	// round frame size to word
		++lc_auto;
	if (IsInterrupt) {
		if (stkname) {
			GenerateDiadic(op_lea, 0, makereg(SP), make_string(stkname));
			GenerateTriadic(op_ori, 0, makereg(SP), makereg(SP), make_immed(0xFFFFF00000000000LL));
		}
		//SaveRegisterSet(sym);
	}
	// The prolog code can't be optimized because it'll run *before* any variables
	// assigned to registers are available. About all we can do here is constant
	// optimizations.
	if (prolog) {
		prolog->scan();
		prolog->Generate();
	}
	// Setup the return block.
	if (!IsNocall)
		SetupReturnBlock();
	if (optimize) {
		if (currentFn->csetbl == nullptr)
			currentFn->csetbl = new CSETable;
		currentFn->csetbl->Optimize(stmt);
	}
	stmt->Generate();

	if (exceptions) {
		ip = peep_tail;
		GenerateMonadic(op_bra, 0, make_label(lab0));
		doCatch = GenDefaultCatch();
		GenerateLabel(lab0);
		if (!doCatch) {
			peep_tail = ip;
			peep_tail->fwd = nullptr;
		}
	}

	if (!IsInline)
		GenReturn(nullptr);
	/*
	// Inline code needs to branch around the default exception handler.
	if (exceptions && sym->IsInline)
	GenerateMonadic(op_bra,0,make_label(lab0));
	// Generate code for the hidden default catch
	if (exceptions)
	GenerateDefaultCatch(sym);
	if (exceptions && sym->IsInline)
	GenerateLabel(lab0);
	*/
	throwlab = o_throwlab;
	retlab = o_retlab;
	contlab = o_contlab;
	breaklab = o_breaklab;
}

// Get the parameter types into an array of short integers.
// Only the first 20 parameters are processed.
//
TypeArray *Function::GetParameterTypes()
{
	TypeArray *i16;
	SYM *sp;
	int nn;

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
		sp1 = TABLE::match[nn]->fi;
		ta = sp1->GetProtoTypes();
		if (ta->IsEqual(typearray)) {
			delete ta;
			return sp1;
		}
		delete ta;
	}
	return (nullptr);
}

void Function::BuildParameterList(int *num, int *numa)
{
	int i, poffset, preg, fpreg;
	SYM *sp1;
	int onp;
	int np;
	bool noParmOffset = false;
	Stringx oldnames[20];
	int old_nparms;

	dfs.printf("<BuildParameterList\n>");
	poffset = 0;//GetReturnBlockSize();
				//	sp->parms = (SYM *)NULL;
	old_nparms = nparms;
	for (np = 0; np < nparms; np++)
		oldnames[np] = names[np];
	onp = nparms;
	nparms = 0;
	preg = regFirstArg;
	fpreg = regFirstArg;
	// Parameters will be inserted into the symbol's parameter list when
	// declarations are processed.
	np = ParameterDeclaration::Parse(1);
	*num += np;
	*numa = 0;
	dfs.printf("B");
	nparms = onp;
	this->NumParms = np;
	for (i = 0; i < np && i < 20; ++i) {
		if ((sp1 = currentFn->params.Find(names[i].str, false)) == NULL) {
			dfs.printf("C");
			sp1 = makeint2(names[i].str);
			//			lsyms.insert(sp1);
		}
		sp1->parent = sym->parent;
		sp1->IsParameter = true;
		sp1->value.i = poffset;
		noParmOffset = false;
		if (sp1->tp->IsFloatType()) {
			if (fpreg > regLastArg)
				sp1->IsRegister = false;
			if (sp1->IsRegister && sp1->tp->size < 11) {
				sp1->reg = sp1->IsAuto ? fpreg | 0x8000 : fpreg;
				fpreg++;
				if ((fpreg & 0x8000) == 0) {
					noParmOffset = true;
					sp1->value.i = -1;
				}
			}
			else
				sp1->IsRegister = false;
		}
		else {
			if (preg > regLastArg)
				sp1->IsRegister = false;
			if (sp1->IsRegister && sp1->tp->size < 11) {
				sp1->reg = sp1->IsAuto ? preg | 0x8000 : preg;
				preg++;
				if ((preg & 0x8000) == 0) {
					noParmOffset = true;
					sp1->value.i = -1;
				}
			}
			else
				sp1->IsRegister = false;
		}
		if (!sp1->IsRegister)
			*numa += 1;
		// Check for aggregate types passed as parameters. Structs
		// and unions use the type size. There could also be arrays
		// passed.
		if (!noParmOffset)
			poffset += round8(sp1->tp->size);
		if (round8(sp1->tp->size) > 8 && !sp1->tp->IsVectorType())
			IsLeaf = FALSE;
		sp1->storage_class = sc_auto;
	}
	// Process extra hidden parameter
	// ToDo: verify that the hidden parameter is required here.
	// It is generated while processing expressions. It may not be needed
	// here.
	if (sym->tp) {
		if (sym->tp->GetBtp()) {
			if (sym->tp->GetBtp()->type == bt_struct || sym->tp->GetBtp()->type == bt_union || sym->tp->GetBtp()->type == bt_class) {
				sp1 = makeStructPtr("_pHiddenStructPtr");
				sp1->parent = sym->parent;
				sp1->value.i = poffset;
				poffset += sizeOfWord;
				sp1->storage_class = sc_register;
				sp1->IsAuto = false;
				sp1->next = 0;
				sp1->IsRegister = true;
				if (preg > regLastArg)
					sp1->IsRegister = false;
				if (sp1->IsRegister && sp1->tp->size < 11) {
					sp1->reg = sp1->IsAuto ? preg | 0x8000 : preg;
					preg++;
					if ((preg & 0x8000) == 0) {
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
	nl();
	CheckForUndefinedLabels();
	lc_auto = 0;
	lfs.printf("\n\n*** local symbol table ***\n\n");
	ListTable(&sym->lsyms, 0);
	// Should recurse into all the compound statements
	if (stmt == NULL)
		dfs.printf("DIAG: null statement in funcbottom.\r\n");
	else {
		if (stmt->stype == st_compound)
			ListCompound(stmt);
	}
	lfs.printf("\n\n\n");
	//    ReleaseLocalMemory();        // release local symbols
	isPascal = FALSE;
	isKernel = FALSE;
	isOscall = FALSE;
	isInterrupt = FALSE;
	isNocall = FALSE;
	dfs.printf("</FuncSummary>\n");
}


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







