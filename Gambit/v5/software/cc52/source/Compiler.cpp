// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2019  Robert Finch, Waterloo
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

extern int lstackptr;
extern int options(char *);
extern int openfiles(char *);
extern void summary();
extern void ParseGlobalDeclarations();
extern void makename(char *s, char *e);
extern char *errtext(int errnum);
extern std::string *classname;
extern void doInitCleanup();

Compiler::Compiler()
{
}

int Compiler::GetReturnBlockSize()
{
	return (4 * sizeOfWord);
}

int Compiler::main2(int argc, char **argv)
{
	uctran_off = 0;
	optimize =1;
	exceptions=1;
	dfs.printf("c64 starting...\r\n");
	while(--argc) {
        if( **++argv == '-')
            options(*argv);
		else {
			if (PreprocessFile(*argv) == -1)
				break;
			if( openfiles(*argv)) {
				lineno = 0;
				initsym();
				lstackptr = 0;
				lastst = 0;
				NextToken();
				compile();
				summary();
//				MBlk::ReleaseAll();
//				ReleaseGlobalMemory();
				CloseFiles();
			}
        }
    }
	//getchar();
	return 0;
}

// Builds the debugging log as an XML document
//
void Compiler::compile()
{
	GlobalDeclaration *gd;
	int nn;

	dfs.printf("<compile>\n");
	genst_cumulative = 0;
	typenum = 1;
	symnum = 257;
	pass = 1;
	classname = nullptr;
	//pCSETable = new CSETable;
	//pCSETable->Clear();
	ZeroMemory(&gsyms[0],sizeof(gsyms));
	ZeroMemory(&defsyms,sizeof(defsyms));
	ZeroMemory(&tagtable,sizeof(tagtable));
	ZeroMemory(&symbolTable,sizeof(symbolTable));
	ZeroMemory(&typeTable,sizeof(typeTable));
	ZeroMemory(&functionTable, sizeof(functionTable));
	ZeroMemory(&DataLabels, sizeof(DataLabels));
	AddStandardTypes();

	RTFClasses::Random::srand((RANDOM_TYPE)time(NULL));
	decls = GlobalDeclaration::Make();
	gd = decls;
	lastst = tk_nop;

	funcnum = 0;
	AddBuiltinFunctions();
	Instruction::SetMap();

	MachineReg::MarkColorable();

	getch();
	lstackptr = 0;
	lastst = 0;
	NextToken();
	try {
		while(lastst != my_eof)
		{
			if (gd==nullptr)
				break;
			dfs.printf("<Parsing GlobalDecl>\n");
			gd->Parse();
			dfs.printf("</Parsing GlobalDecl>\n");
			if( lastst != my_eof) {
				NextToken();
				gd->next = (Declaration *)GlobalDeclaration::Make();
				gd = (GlobalDeclaration*)gd->next;
			}
		}
		doInitCleanup();
		dfs.printf("</compile>\n");
	}
	catch (C64PException * ex) {
		dfs.printf(errtext(ex->errnum));
 		dfs.printf("</compile>\n");
	}
	dumplits();
}

int Compiler::PreprocessFile(char *nm)
{
	static char outname[1000];
	static char sysbuf[500];

	strcpy_s(outname, sizeof(outname), nm);
	makename(outname,".fpp");
	sprintf_s(sysbuf, sizeof(sysbuf), "fpp -b %s %s", nm, outname);
	return system(sysbuf);
}

void Compiler::CloseFiles()
{    
	lfs.close();
	ofs.close();
	dfs.close();
	ifs->close();
}

void Compiler::AddStandardTypes()
{
	TYP *p, *pchar, *pint, *pbyte;
	TYP *pichar;

	p = TYP::Make(bt_long,sizeOfWord);
	stdint = *p;
	pint = p;
	p->precision = 52;
  
	p = TYP::Make(bt_long,sizeOfWord);
	p->isUnsigned = true;
	p->precision = 52;
	stduint = *p;
  
	p = TYP::Make(bt_long,sizeOfWord);
	p->precision = 52;
	stdlong = *p;
  
	p = TYP::Make(bt_long,sizeOfWord);
	p->isUnsigned = true;
	p->precision = 52;
	stdulong = *p;
  
	p = TYP::Make(bt_short,4);
	p->precision = 52;
	stdshort = *p;
  
	p = TYP::Make(bt_short,4);
	p->isUnsigned = true;
	p->precision = 52;
	stdushort = *p;
  
	p = TYP::Make(bt_char,1);
	stdchar = *p;
	p->precision = 13;
	pchar = p;
  
	p = TYP::Make(bt_char,1);
	p->isUnsigned = true;
	p->precision = 13;
	stduchar = *p;
  
	p = TYP::Make(bt_ichar, 1);
	stdichar = *p;
	p->precision = 13;
	pichar = p;

	p = TYP::Make(bt_iuchar, 1);
	stdiuchar = *p;
	p->precision = 13;
//	pchar = p;

	p = TYP::Make(bt_byte,1);
	stdbyte = *p;
	p->precision = 13;
	pbyte = p;
  
	p = TYP::Make(bt_ubyte,1);
	p->isUnsigned = true;
	p->precision = 13;
	stdubyte = *p;
  
	p = allocTYP();
	p->type = bt_pointer;
	p->typeno = bt_pointer;
	p->val_flag = 1;
	p->size = sizeOfPtr;
	p->btp = pchar->GetIndex();
	p->bit_width = -1;
	p->precision = 52;
	p->isUnsigned = true;
	stdstring = *p;
  
	p = allocTYP();
	p->type = bt_pointer;
	p->typeno = bt_pointer;
	p->val_flag = 1;
	p->size = 4;
	p->btp = pichar->GetIndex();
	p->bit_width = -1;
	p->precision = 52;
	p->isUnsigned = true;
	stdistring = *p;

	p = allocTYP();
	p->type = bt_pointer;
	p->typeno = bt_pointer;
	p->val_flag = 1;
	p->size = sizeOfPtr;
	p->btp = pbyte->GetIndex();
	p->bit_width = -1;
	p->precision = sizeOfPtr * 16;
	p->isUnsigned = true;
	stdastring = *p;

	p = allocTYP();
	p->type = bt_double;
	p->typeno = bt_double;
	p->size = 4;
	p->bit_width = -1;
	p->precision = 52;
	stddbl = *p;
	stddouble = *p;
  
	p = allocTYP();
	p->type = bt_triple;
	p->typeno = bt_triple;
	p->size = 6;
	p->bit_width = -1;
	p->precision = 78;
	stdtriple = *p;
  
	p = allocTYP();
	p->type = bt_quad;
	p->typeno = bt_quad;
	p->size = 8;
	p->bit_width = -1;
	p->precision = 104;
	stdquad = *p;
  
	p = allocTYP();
	p->type = bt_float;
	p->typeno = bt_float;
	p->size = 4;
	p->bit_width = -1;
	p->precision = 52;
	stdflt = *p;
  
	p = TYP::Make(bt_func,0);
	p->btp = pint->GetIndex();
	stdfunc = *p;

	p = allocTYP();
	p->type = bt_exception;
	p->typeno = bt_exception;
	p->size = 4;
	p->isUnsigned = true;
	p->precision = 52;
	p->bit_width = -1;
	stdexception = *p;

	p = allocTYP();
	p->type = bt_long;
	p->typeno = bt_long;
	p->val_flag = 1;
	p->size = 4;
	p->bit_width = -1;
	p->precision = 52;
	stdconst = *p;

	p = allocTYP();
	p->type = bt_vector;
	p->typeno = bt_vector;
	p->val_flag = 1;
	p->size = 512;
	p->bit_width = -1;
	p->precision = 64;
	stdvector = *p;

	p = allocTYP();
	p->type = bt_vector_mask;
	p->typeno = bt_vector_mask;
	p->val_flag = 1;
	p->size = 4;
	p->bit_width = -1;
	p->precision = 52;
	stdvectormask = p;

	p = allocTYP();
	p->type = bt_void;
	p->typeno = bt_void;
	p->val_flag = 1;
	p->size = 4;
	p->bit_width = -1;
	p->precision = 52;
	stdvoid = *p;
}

void Compiler::AddBuiltinFunctions()
{
	SYM *sp;
	TypeArray tanew, tadelete;

	sp = allocSYM();
	sp->SetName("__new");
	sp->fi = allocFunction(sp->id);
	sp->fi->sym = sp;
	sp->fi->IsPascal = true;
	tanew.Add(bt_long, 0);
	//tanew.Add(bt_pointer,19);
	//tanew.Add(bt_long, 20);
	sp->fi->AddProto(&tanew);
	sp->tp = &stdvoid;
	gsyms->insert(sp);

	sp = allocSYM();
	sp->SetName("__autonew");
	sp->fi = allocFunction(sp->id);
	sp->fi->sym = sp;
	sp->fi->IsPascal = true;
	tanew.Add(bt_long, 0);
	//tanew.Add(bt_pointer,19);
	//tanew.Add(bt_long, 20);
	sp->fi->AddProto(&tanew);
	sp->tp = &stdvoid;
	gsyms->insert(sp);

	sp = allocSYM();
	sp->SetName("__delete");
	sp->fi = allocFunction(sp->id);
	sp->fi->sym = sp;
	sp->fi->IsPascal = true;
	tadelete.Add(bt_pointer, 0);
	sp->fi->AddProto(&tadelete);
	sp->tp = &stdvoid;
	gsyms->insert(sp);
}

void Compiler::storeHex(txtoStream& ofs)
{
	int nn, mm;
	char buf[20];

	nn = compiler.symnum;
	sprintf_s(buf, sizeof(buf), "SYMTBL%05d\n", nn);
	ofs.write(buf);
	for (mm = 0; mm < nn; mm++)
		symbolTable[mm].storeHex(ofs);
	nn = compiler.funcnum;
	sprintf_s(buf, sizeof(buf), "FNCTBL%05d\n", nn);
	ofs.write(buf);
	for (mm = 0; mm < nn; mm++)
		functionTable[mm].storeHex(ofs);
	nn = typenum;
	sprintf_s(buf, sizeof(buf), "TYPTBL%05d\n", nn);
	ofs.write(buf);
	for (mm = 0; mm < nn; mm++)
		typeTable[mm].storeHex(ofs);
}

void Compiler::loadHex(txtiStream& ifs)
{

}

void Compiler::storeTables()
{
	txtoStream* oofs;
	extern char irfile[256];

	oofs = new txtoStream();
	oofs->open(irfile, std::ios::out);
	oofs->printf("; CC64 Hex Intermediate Representation File\n");
	oofs->printf("; This is an automatically generated file.\n");
	storeHex(*oofs);
	oofs->close();
	delete oofs;
}
