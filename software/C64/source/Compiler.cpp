// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - 'C' derived language compiler
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

Compiler::Compiler()
{
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

	dfs.printf("<compile>\n");
  typenum = 1;
  symnum = 257;
  classname = nullptr;
  ZeroMemory(&gsyms[0],sizeof(gsyms));
  ZeroMemory(&defsyms,sizeof(defsyms));
  ZeroMemory(&tagtable,sizeof(tagtable));
  ZeroMemory(&symbolTable,sizeof(symbolTable));
  ZeroMemory(&typeTable,sizeof(typeTable));
  AddStandardTypes();

	RTFClasses::Random::srand(time(NULL));
	decls = GlobalDeclaration::Make();
	gd = decls;
	lastst = tk_nop;

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

	strcpy(outname, nm);
	makename(outname,".fpp");
	snprintf(sysbuf, sizeof(sysbuf), "fpp -b %s %s", nm, outname);
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
  TYP *p, *pchar, *pint;

  p = TYP::Make(bt_long,8);
  stdint = *p;
  pint = p;
  
  p = TYP::Make(bt_long,8);
  p->isUnsigned = true;
  stduint = *p;
  
  p = TYP::Make(bt_long,8);
  stdlong = *p;
  
  p = TYP::Make(bt_long,8);
  p->isUnsigned = true;
  stdulong = *p;
  
  p = TYP::Make(bt_short,4);
  stdshort = *p;
  
  p = TYP::Make(bt_short,4);
  p->isUnsigned = true;
  stdushort = *p;
  
  p = TYP::Make(bt_char,2);
  stdchar = *p;
  pchar = p;
  
  p = TYP::Make(bt_char,2);
  p->isUnsigned = true;
  stduchar = *p;
  
  p = allocTYP();
  p->type = bt_byte;
  p->typeno = bt_byte;
  p->size = 1;
  p->size2 = 1;
  p->bit_width = -1;
  stdbyte = *p;
  
  p = allocTYP();
  p->type = bt_byte;
  p->typeno = bt_byte;
  p->size = 1;
  p->size2 = 1;
  p->isUnsigned = true;
  p->bit_width = -1;
  stdubyte = *p;
  
  p = allocTYP();
  p->type = bt_pointer;
  p->typeno = bt_pointer;
  p->val_flag = 1;
  p->size = 1;
  p->size2 = 1;
  p->btp = pchar->GetIndex();
  p->bit_width = -1;
  stdstring = *p;
  
  p = allocTYP();
  p->type = bt_double;
  p->typeno = bt_double;
  p->size = 8;
  p->size2 = 8;
  p->bit_width = -1;
  stddbl = *p;
  stddouble = *p;
  
  p = allocTYP();
  p->type = bt_float;
  p->typeno = bt_float;
  p->size = 4;
  p->size2 = 4;
  p->bit_width = -1;
  stdflt = *p;
  
  p = TYP::Make(bt_func,0);
  p->btp = pint->GetIndex();
  stdfunc = *p;

  p = allocTYP();
  p->type = bt_exception;
  p->typeno = bt_exception;
  p->size = 8;
  p->size2 = 8;
  p->isUnsigned = true;
  p->bit_width = -1;
  stdexception = *p;

  p = allocTYP();
  p->type = bt_long;
  p->typeno = bt_long;
  p->val_flag = 1;
  p->size = 8;
  p->size2 = 8;
  p->bit_width = -1;
  stdconst = *p;
  
}




