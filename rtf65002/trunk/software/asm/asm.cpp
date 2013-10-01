/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved
=============================================================== */

// asm.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "asm.h"

#include <stdio.h>
#include <stdlib.h>
#include <search.h>
#include <share.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <fcntl.h>
#include "fwlib.h"
#include "sym.h"
#include "asmbuf.h"
#include "fstreamS19.h"
#include "registry.h"
#define ALLOC
#include "Assembler.h"
#include "err.h"
#include "macro.h"
#include "Cpu.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// The one and only application object

CWinApp theApp;

namespace RTFClasses
{
	Debug debug(0,"");
	Assembler theAssembler;

	char *Assembler::verstr = "Finitron 65002 assembler   version 1.0   %.24s     Page %d\r\n";
	char *Assembler::verstr2 = "asm V1.0  (c) 2013 Finitron - 65002 cross assembler\r\n";

	Cpu *getCpu()
	{
		return theAssembler.getCpu();
	}
}

int _tmain(int argc, _TCHAR **argv, _TCHAR **envp)
{
	int nRetCode = 0;

	// initialize MFC and print and error on failure
	if (!AfxWinInit(::GetModuleHandle(NULL), NULL, ::GetCommandLine(), 0))
	{
		// TODO: change error code to suit your needs
//		::cerr << _T("Fatal Error: MFC initialization failed") << endl;
		nRetCode = 1;
	}
	else
		nRetCode = RTFClasses::theAssembler.main(argc, argv, envp);

	return nRetCode;
}

using namespace std;

namespace RTFClasses
{
	void Assembler::displayHelp()
	{
		fprintf(stderr,
			"\r\nasm <source file> [options]\n\n\r"
			"   /o[[-][b][s][-][l][y][:<filename>] - set output option\n\r"
			"      - - indicates disable option\n\r"
			"      b - binary output\r\n"
			"      e - error output file\r\n"
			"      s - S19 file format output\r\n"
			"      m - mem output file\r\n"
			"      l - listing file\r\n"
			"      y - symbol table\r\n"
			"      : - override ouput file name\r\n\r\n"
			"   /P:<processor>\r\n"
			"      6502\r\n"
			"      W65C02\r\n"
			"      W65C816S\r\n"
			"      RTF65002\r\n\r\n"
 			"   /REGISTER:<string> - enter registration code\r\n\r\n"
			"Example:  asm br4.asm /olye      ; Generate listing, symbols, and error\r\n"
			"    Default is to generate a binary output file '.bin'\r\n"
			"    Default source file extension is '.asm'\r\n\r\n"
			"Press enter\r\n"
			);
		getchar();
		fprintf(stderr,
			"\r\n"
			"* This program is distributed WITHOUT ANY WARRANTY; without even the implied\r\n"
			"warentee of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\r\n\r\n");
	}


	bool Assembler::validateRegistration()
	{
		// Validate registration
		int regdate = 0;
		int t = time(NULL);
		Registry reg("Software\\Finitron\\asm65816");
		if (!reg.check("RegCode", "ASM65816")) {
			fprintf(stderr, "This program isn't registered. It'll stop working after 45 days\r\n");
			fprintf(stderr, "unless it's registered.\r\n");
			fprintf(stderr, "Use the /REGISTER option to register this program.\r\n");
			reg.read("DATE", &regdate, sizeof(regdate));
			if (regdate == 0)
			{
				reg.create();
				reg.write("DATE", REG_DWORD, &t, sizeof(int) );
			}
			//else if (t - regdate > 3974400)
			//	return false;
		}
		return true;
	}


	void Assembler::openOutputStreams()
	{
		if (fBinOut)
			if ((fpBin = fopen(fnameBin, "wb")) == NULL)
				throw Err(E_OPEN, fnameBin);
		if (fListing)
			if ((fpList = fopen(fnameList, "wb")) == NULL)
				throw Err(E_OPEN, fnameList);
		if (bMemOut)
			if ((fpMem = fopen(fnameMem, "wb")) == NULL)
				throw Err(E_OPEN, fnameMem);
		if (bVerOut)
			if ((fpVer = fopen(fnameVer, "wb")) == NULL)
				throw Err(E_OPEN, fnameVer);
		if (fSOut)
			if (!gSOut.open(fnameS, ios::out))
				throw Err(E_OPEN, fnameS);
		if (fErrOut)
		{
			if ((fpErr = fopen(fnameErr, "wb")) == NULL)
				throw Err(E_OPEN, fnameErr);
		}
		else
			fpErr = stderr;

		if (bObjOut) {
			if (ObjFile.open(fnameObj, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYRW) < 0) {
				throw Err(E_OPEN, fnameObj);
			}
		}
	}


	void Assembler::initializeForPass()
	{
		errorsDuringPass = 0;
		StartAddress = 0;
		fStartDefined = false;
		fFirstCode = true;
		setProcessor(giProcessor);
		InputLine = 0;
		OutputLine = 1;
		errcount = 0;
		errors = 0;
		warnings = 0;
		ProgramCounter.reset();
		DataCounter.reset();
		BSSCounter.reset();
		Macro::zeroCounter();
		bFirstObj = true;
		FileNum = -1;
		CurFileNum = -1;
		FileLevel = 0;
		localSymTbl = NULL;     // Local Symbol table
		ForceErr = 0;
		NumInsn = 0;
		ByteCount = 0;
		fprintf(fpErr, "\r\nPass %d\r\n",pass);
	}

	int Assembler::main(int argc, _TCHAR **argv, _TCHAR **envp)
	{
		int nRetCode = 1;

		m_argc = argc;
		m_argv = argv;
		m_envp = envp;

		try {
			debug.set(0, getExeName());
			debug.log5("********************************************");
			debug.log5("********************************************");
			debug.log5("***** Starting Assembly                *****");
			debug.log5("********************************************");
			debug.log5("********************************************");
			progArg = argv;
			progArgc = argc;

			char sfname[300];
			int x;

			//   setbuf(stdout, NULL);    // for debugging

			// Initialize vars
			FileNum = -1;              // Working file number (will be incremented on open)
			CurFileNum = 0;
			InputLine = 0;             // Overall input line number
			OutputLine = 1;

			page = 1;                  // page number    Listing variables
			col = 1;                   // column number
			PageLength = 60;           // page length
			PageWidth = 80;            // page width

			Debug = 0;
			liston = 0;
			fListing = false;
			fBinOut = true;
			fSOut = false;
			fErrOut = false;
			fpErr = stderr;
			ShowLines = 0;
			verbose = 0;
			Processor = 1;
			giProcessor.copy("6502");
			setProcessor(giProcessor);

			WarnLevel = 0;
			errcount = 0;              // number of errors
			errtype = true;            // global error flag

			CollectingMacro = false;
			Macro::zeroCounter();
			InComment = 0;
			InComment2 = 0;
			InQuote = 0;
			CommentChar = '~';
			pass = 1;                  // assembler's current pass

			gSzChar = 0;               // operand size character
			DoingDc = FALSE;

			ProgramCounter.reset();        // current program location during assembly
			DataCounter.reset();           // current initialized data address during assembly
			BSSCounter.reset();            // current uninitialized data area during assembly
			CurrentArea = CODE_AREA;   // Current output area.

			fpFormat = FP_IEEE;			// default to IEEE format

			// Blank out operands
			for (x = 0; x < MAX_OPERANDS; x++)
				gOperand[x] = "";

			// Allocate storage for symbols.
			gSymbolTable = new SymbolTable(1000);   // Global symbol table
			extRefTbl = new ExtRefTbl(500);    // External reference table

			macroTbl = new HashTable(200);
			//   StructTbl = new CStructTbl(100);

			// set up input/working buffers
	//		ibuf->set(inbuf, sizeof(inbuf));        // input buffer which can contain macro expansion

			// begin processing
			fprintf(stderr, "\r\n");
			fprintf(stderr, verstr2);
			memset(ofname, '\0', sizeof(ofname));
			memset(fnameObj, '\0', sizeof(fnameObj));
			memset(fnameBin, '\0', sizeof(fnameBin));
			memset(fnameList, '\0', sizeof(fnameList));
			memset(fnameMem, '\0', sizeof(fnameMem));
			memset(fnameVer, '\0', sizeof(fnameVer));
			memset(fnameSym, '\0', sizeof(fnameSym));
			memset(fnameS, '\0', sizeof(fnameS));
			memset(fnameErr, '\0', sizeof(fnameErr));

			if(argc == 1)
			{
				displayHelp();
				return 0;
			}

			fprintf(stderr,
				"email comments, suggestions, bug reports to:\r\n\r\n"
				"\temail@finitron.ca\r\n\r\n");
			fprintf(stderr,
				"* This program is distributed WITHOUT ANY WARRANTY; without even the implied\r\n"
				"warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\r\n\r\n");

			// Validate registration
			if (!validateRegistration())
				return 0;

			// Parse command line switches.
			for(x = 1;  x < progArgc; x++)
				if (strchr("-/+", *progArg[x]))
					parseCmdLine(&x);

			// Get source file name.
			strcpy(sfname, progArg[1]);
			if (!strchr(sfname, '.'))
				strcat(sfname, ".asm");   // Add extension ?

			// Get object file name. If there is no output file name set
			// then copy the source name to the output name and change
			// the extension. This is somewhat tricky because of new
			// filename conventions. You must search for the last dot
			// that is part of the filename, not a directory path.
			if(!strlen(ofname))
			{
				char *p1, *p2, *p3;
				int xx;
				// Search for the last '.'
				p1 = strrchr(sfname, '.');
				p2 = strrchr(sfname, '\\');
				p3 = strrchr(sfname, '/');
				p2 = (p3 > p2) ? p3 : p2;
				p1 = (p2 > p1) ? p2 : p1;
				xx = (p1 > sfname) ? (p1 - sfname) : strlen(sfname);
				strncpy(ofname, sfname, xx);
			}

			strcpy(fnameObj, ofname);
			strcpy(fnameBin, ofname);
			strcpy(fnameList, ofname);
			strcpy(fnameMem, ofname);
			strcpy(fnameVer, ofname);
			strcpy(fnameSym, ofname);
			strcpy(fnameS, ofname);
			strcpy(fnameErr, ofname);
			strcat(fnameObj, ".o");
			strcat(fnameBin, ".bin");
			strcat(fnameList, ".lst");
			strcat(fnameMem, ".mem");
			strcat(fnameVer, ".ver");
			strcat(fnameSym, ".sym");
			strcat(fnameS, ".S19");
			strcat(fnameErr, ".err");

			// Open output streams.
			openOutputStreams();

			//  Main assembling loop.
			bOutOfPhase = 0;
			bGen = false;
			errorsDuringPass = 0;

//			for(pass = 1; (pass <= 20 || bOutOfPhase) && errorsDuringPass==0; pass++) {
			for(pass = 1; pass <= 20; pass++) {
				initializeForPass();
				if (pass > 1)
					fprintf(fpErr, " - Out of Phase Symbols: %d\r\n", bOutOfPhase);
				else
					fprintf(fpErr, "\r\n");
				bOutOfPhase = 0;
				processFile(sfname);
			}
			// Output generation pass
			bOutOfPhase = 0;
			bGen = true;
			initializeForPass();
			processFile(sfname);

			// Flush object buffer.
			if (bObjOut) {
				ObjFile.flush();
				ObjFile.close();
			}

			fprintf(fpList, "\r\nNumber of instructions processed: %d\r\n", NumInsn);
			fprintf(fpList, "Number of opcode bytes: %I64d\r\n", ByteCount);
			fprintf(fpList, "Bytes per instruction: %lf\r\n", (double)((double)ByteCount/(double)NumInsn));
			// Close streams
			if (fBinOut)
				fclose(fpBin);
			if (fListing)
				fclose(fpList);
			if (bMemOut)
				fclose(fpMem);
			if (bVerOut)
				fclose(fpVer);
			if (fSOut)
				gSOut.close(StartAddress);

			// Display symbol table.
			if(fSymOut) {
			fpSym = fopen(fnameSym, "w");
			if (fpSym) {
				int ii;

				fprintf(fpSym, "Global symbols:\n");
				gSymbolTable->print(fpSym, 1);

				// Print local symbol tables
				fprintf(fpSym, "\n\nLocal symbols:\n");
				for (ii = 0; ii < FileNum; ii++)
					if (File[ii].lst) {
					fprintf(fpSym, "File:%s\n", File[ii].name);
					printf("File:%s\n", File[ii].name);
					File[ii].lst->print(fpSym, 1);
					fprintf(fpSym, "\n\n");
					}

				macroTbl->print(fpSym, 0);
				fclose(fpSym);
			}
			else
				Err(E_OPEN, fnameSym);
			}
			fprintf(fpErr, "Errors: %d\r\n", errors);
			fprintf(fpErr, "Warnings: %d\r\n", warnings);
			if (fpErr != stderr)
				fclose(fpErr);
			delete macroTbl;
			delete gSymbolTable;
			delete extRefTbl;
			return FALSE;
		}
		catch (Err e)
		{
			printf("Caught error:\r\n");
			nRetCode = 0;
		}
		return nRetCode;
	}


	/* -----------------------------------------------------------------------------
	Description:
		look for a symbol, store with appropriate counter

	Parameters :
		(char *) pointer to line containing label

	----------------------------------------------------------------------------- */

	void Assembler::label(char *label, int oclass)
	{
		Symbol *p, *q = NULL;
		Symbol tdef;

		/* -----------------------------------------------------------
				See if the symbol exists in the symbol table
			already. If it does then the label is being multiply
			defined.
		----------------------------------------------------------- */
		p = NULL;
		tdef.setName(label);
		if (oclass == PUB || FileLevel == 0)
			p = gSymbolTable->find(&tdef);
		else
			if (localSymTbl)
				p = localSymTbl->find(&tdef);

		if (pass == 1)
		{
			// Check if label has been defined already.
			if(p != NULL && p->isDefined() == 1) {
				ForceErr = 1;
				Err(E_DEFINED, label);
				ForceErr = 0;
				return;
			}

			// Allocate storage and insert into symbol table.
			if (p == NULL) {
				if (oclass == PUB || FileLevel == 0)
					q = new Symbol;
				else {
					if (localSymTbl)
						q = new Symbol;
					else
						return;
				}
				if (q == NULL) {
					Err(E_MEMORY);
					return;
				}
				q->setName(label);
				if (oclass == PUB || FileLevel == 0)
					p = gSymbolTable->insert(q);
				else {
					if (localSymTbl)
						p = localSymTbl->insert(q);
					else {
						delete q;
						return;
					}
				}
			}

			// Set section and offset value
			p->define(oclass); // was q->define

			return;
		}

		// On subsequent pass label must already exist in symbol table.
		if (p == NULL) {
			Err(E_LABEL);
			return;
		}

		// Special symbol
		if (p->getName().equalsNoCase("start")) {
			StartAddress = (__int32)p->getValue();
			fStartDefined = true;
		}

		//    On subsequent pass address of label must coincide with
		// the section counter or there is a phase discrepancy.
		if (p->getValue() != getCounter().val) {
			bOutOfPhase++;
			p->phaseErr = true;
			// set the new value
			p->setValue(getCounter().val);
		}
		else
			p->phaseErr = false;
	//		Err(E_PHASE, label);

		emit0();
	}


	/* -----------------------------------------------------------------------------
	Description :
	----------------------------------------------------------------------------- */
	int opcmp(void *a, void *b)
	{
		return stricmp((char *)a, ((Mne *)b)->mne);
	}


	void Assembler::copyChToMacro(char ch)
	{
		if (macrobuf.len() >= MAX_MACRO_EXP)
			throw Err(E_MACSIZE);
		macrobuf += ch;
	}


	bool Assembler::inBlockComment()
	{
		return InComment||InComment2;
	}

	int Assembler::CollectMacroLine()
	{
		char ch;

		// Copy macro indicator to start of line
		copyChToMacro('+');

		// Loop until newline or end of buffer encountered.
		while(1)
		{
	StartOfLoop:
		// If end of buffer then reset quote flag
		if (ibuf->peekCh() < 1)
			break;

		//    If end of line detected then copy newline to macro buffer
		if (ibuf->peekCh() == '\n') {
			copyChToMacro(ibuf->nextCh());
			break;
		}

		// Check for end of comments
		if (InComment2) {
			if ((ibuf->peekCh() == '*') && (ibuf->getPtr()[1] == '/')) {
				copyChToMacro(ibuf->nextCh());
				InComment2--;
				goto EndOfLoop;
			}
		}

		if (InComment) {
			if (ibuf->peekCh() == CommentChar) {
				InComment--;
				goto EndOfLoop;
			}
		}

		// If we're not already in a comment look for one.
		if (!inBlockComment()) {
			if ((strncmp(ibuf->getPtr(), "comment", 7) == 0) && !IsIdentChar(ibuf->getPtr()[7]))
			{
				int count = 7;

				// Copy 'comment' to macro buffer
				while(count)
				{
					copyChToMacro(ibuf->nextCh());
					--count;
				}
				// Get the comment char and copy to macro buffer.
				while(1) {
					copyChToMacro(ibuf->nextCh());
					if (!isspace(ch)) {
						CommentChar = ch;
						break;
					}
				}
				InComment++;   // We're now in comment
				continue;
			}
		}
	      
		if (!inBlockComment())
		{
			if (ibuf->peekCh() == '/' && ibuf->getPtr()[1] == '*') {
				int count = 2;
				// Copy '/ *' to macro buffer
				while(count)
				{
					copyChToMacro(ibuf->nextCh());
					--count;
				}
				InComment2++;
				continue;
			}
		}

		// look for quote
		if (ibuf->peekCh() == '"') {
			while(1) {
				if (macrobuf.len() >= MAX_MACRO_EXP) {
					Err(E_MACSIZE);
					goto ExitPt;
				}
				ch = ibuf->nextCh();
				if (ch < 1) goto ExitPt;
				macrobuf += ch;
				if (ch == '"') goto StartOfLoop;
				if (ch =='\n') goto ExitPt;
			}
		}

		// look for quote
		if (ibuf->peekCh() == '\'') {
			while(1) {
				if (macrobuf.len() >= MAX_MACRO_EXP) {
					Err(E_MACSIZE);
					goto ExitPt;
				}
				ch = ibuf->nextCh();
				if (ch < 1) goto ExitPt;
				macrobuf += ch;
				if (ch == '\'') goto StartOfLoop;
				if (ch =='\n') goto ExitPt;
			}
		}

	EndOfLoop:
		// Skip over comment
		if (ibuf->peekCh() == ';') {
			if (ibuf->getPtr()[1] != ';') {
				ibuf->scanToEOL();
				macrobuf.rtrim();
				copyChToMacro('\n');
				goto ExitPt;
			}
			// Preserve comment
			else {
				while(1) {
					if (macrobuf.len() >= MAX_MACRO_EXP) {
						Err(E_MACSIZE);
						goto ExitPt;
					}
					ch = ibuf->nextCh();
					if (ch < 1) goto ExitPt;
					macrobuf += ch;
					if (ch =='\n') goto ExitPt;
				}
			}
		}
			// Copy character to macro buffer.
			copyChToMacro(ibuf->nextCh());
		}
	ExitPt:
		return TRUE;
	}


	// Check for first type of block comment and advance past the
	// comment indicator.
	// "comment ~"
	bool Assembler::isBlockComment1()
	{
		if (!inBlockComment()) {
			if ((strncmp(ibuf->getPtr(), "comment", 7) == 0) && !IsIdentChar(ibuf->peekCh(7))) {
				ibuf->move(7);
				CommentChar = ibuf->nextNonSpace();
				InComment++;
				return true;
			}
		}
		return false;
	}


	// Check for second type of block comment
	// "/*"
	bool Assembler::isBlockComment2()
	{
		if (!InComment)
		{
			if (ibuf->peekCh() == '/' && ibuf->peekCh(1) == '*') {
				InComment2++;
				ibuf->nextCh();
				ibuf->nextCh();
				return true;
			}
		}
		return false;
	}


	// look for end of comments
	bool Assembler::isEndOfComment()
	{
		if (InComment2) {
			if (ibuf->peekCh() == '*' && ibuf->peekCh(1) == '/') {
				--InComment2;
				ibuf->nextCh();
				ibuf->nextCh();
				return true;
			}
		}
		else if (InComment) {
			if (ibuf->peekCh() == CommentChar) {
				ibuf->nextCh();
				--InComment;
				return true;
			}
		}
		return false;
	}

	// Process pseudops
	// return true if a pseudo-op was handled, else false
	bool Assembler::processPseudo(char *buf)
	{
		String p(buf);

		p.toLower();
		if (p=="align") {
			align();
			return true;
		}
		if (p=="cpu") {
			a_cpu();
			return true;
		}
		if (p=="endm") {
			endm();
			return true;
		}
		if (p=="db" || p=="byte") {
			db('B');
			return true;
		}
		if (p=="dc" || p=="dh" || p=="char") {
			db('C');
			return true;
		}
		if (p=="dw" || p=="word") {
			if (gProcessor=="W65C02")
				db('C');
			else
				db('W');
			return true;
		}
		if (p=="include") {
			include();
			return true;
		}
		if (p=="org") {
			org();
			return true;
		}
		if (p=="macro") {
			macro();
			return true;
		}
		if (p=="data") {
			data();
			return true;
		}
		if (p=="code") {
			code();
			return true;
		}
		if (p=="bss") {
			bss();
			return true;
		}
		if (p=="comment") {
			comment();
			return true;
		}
		if (p=="end") {
			end();
			return true;
		}
		if (p=="extern") {
			a_extern();
			return true;
		}
		if (p=="public") {
			a_public();
			return true;
		}
		if (p=="list") {
			list();
			return true;
		}
		if (p=="message") {
			message();
			return true;
		}
		return false;
	}

	// Processes a line of the input file.

	int Assembler::processLine()
	{
		char idbuf[NAME_MAX+1];
		int oldline = -1, lbl = FALSE;
		Mne *optr;
		int idlen, sz;
		char
			*sptr;   // pointer to start of text on line
		int msol;
		__int64 pc1,pc2;
		String dmsg;

		errtype = true;

//		printf("%d: %.60s\r\n", lineno, ibuf->getPtr());

		lineExpanded = false;
		//dmsg = "Line ";
		//dmsg += InputLine;
		//dmsg += ": |";
		//dmsg += ibuf->getPtr();
		//dmsg.left(dmsg.find('\n'));
		//debug.log5(dmsg);

//	   printf("Line %05d: |%s", InputLine, ibuf->getPtr());

		// Save off pointer to start of line (for macro processing)
		msol = ibuf->ndx();
	   
	// skip any leading spaces on the line
	//   ibuf->SkipSpaces();
	 
		// Substitute any macros into the input buffer
		SearchAndSub();

		//    If collecting a macro search for the endm statement (which
		// must be the first statement on the line). If not found then
		// copy the input line to the macro buffer.
		if (CollectingMacro)
		{
			if (!inBlockComment())
			{
				if (ibuf->isNext("endm", 4)) {
					endm();
					goto LoopStart;   // Allows subsequent commands on line
				}
			}
			ibuf->moveTo(msol);   // reset to start of line
			return (CollectMacroLine());
		}


	LoopStart:
		while(1)
		{
			// Check for end of buffer.
			if (ibuf->peekCh() < 1)
				break;

			// Check for end of line
			if (ibuf->peekCh() == '\n') {
				ibuf->nextCh();
				break;
			}

			// look for end of comments
			if (isEndOfComment())
				continue;

			// Check for first type of block comment
			if (isBlockComment1())
				continue;

			// Check for second type of block comment
			if (isBlockComment2())
				continue;

			// Could already be in a comment
			if (inBlockComment())
				continue;

			// skip over macro indicator
			if (ibuf->peekCh()=='+') {
				lineExpanded = true;
				ibuf->nextCh();
				continue;
			}
			// Skip any leading spaces on the line
			ibuf->skipSpacesLF();

			// skip over macro indicator
			if (ibuf->peekCh()=='+') {
				lineExpanded = true;
				ibuf->nextCh();
				continue;
			}

			// As soon as we hit a semicolon ignore the remainder of the line
			if (ibuf->peekCh() == ';') {
				ibuf->scanToEOL(); // To advance ptr;
				break;
			}

			// Check for counter assignment
			// *=
			if (ibuf->peekCh() == '*') 
			{
				ibuf->nextNonSpaceLF();
				if (ibuf->peekCh() == '=')
				{
					ibuf->nextCh();
					strcpy(idbuf, "org");
					idlen = 3;
					goto SearchForMne;
				}
			}

			// try and find a mnemonic
			idlen = ibuf->getIdentifier(&sptr);
			if (idlen > 0)
			{
				memset(idbuf, '\0', sizeof(idbuf));
				strncpy(idbuf, sptr, min(idlen, NAME_MAX));
				if (processPseudo(idbuf))
					continue;
	SearchForMne:
				sz = sizeof(Mne);
				optr = (Mne *)bsearch(idbuf, (void *)getCpu()->table, getCpu()->nops, sz, (int (*)(const void*, const void*))opcmp);
				if (optr)
				{
					NumInsn++;
					pc1 = ProgramCounter.val;
					processMneumonic(optr);
					pc2 = ProgramCounter.val;
					ByteCount += (pc2-pc1);
					continue;
				}
				// If an identifier was found, but it's not an op or psuedo
				// op then it must be some sort of label
				else
				{
					ibuf->skipSpacesLF();         // skip any trailing spaces
					if (ibuf->peekCh() == ':')
					{
						ibuf->nextCh();          // skip over ':'
						label(idbuf, PRI);
					}
					else
					{
						// See if it's an equate. If not an equate then
						// assume a label without a following ':'
						if (equ(idbuf)) {
							ibuf->scanToEOL();
							break;
						}
						else
							label(idbuf, PRI);
					}
				}
			}

			// If first character is a dot then process a potential psuedo
			// op.
			else if (ibuf->peekCh() == '.')
			{
				ibuf->nextCh();
				if (isalpha(ibuf->peekCh()))
					continue;
				Err(E_EXTRADOT);
				continue;
			}

			// Check for statement separator
			else if (ibuf->peekCh() == ':')		// ignore
				ibuf->nextCh();

			else if (isspace(ibuf->peekCh()))   // ignore
				ibuf->nextCh();

			// Garbage on the input line
			else
			{
				Err(E_CHAR);
				ibuf->scanToEOL();    // Dump the line from input
				break;
			}
		}
		return TRUE;
	}


	/* ---------------------------------------------------------------
		processFile(name);
		char *name;    // filename

		Description :
			Assembles a file.
	--------------------------------------------------------------- */

	void Assembler::processFile(char *fname)
	{
		int nargs = 0;
		time_t tim;
	//	char *p1;
		int p1;

		lineno = 0;

		// record file in table
		FileNum++;
		CurFileNum = FileNum;
		if (FileNum >= 255) {
			Err(E_FILES);
			return;
		}
		File[FileNum].errors = 0;
		File[FileNum].warnings = 0;
		File[FileNum].LastLine = 0;
				File[FileNum].name = fname;
				if (File[FileNum].load(fname)==0)
				{
					ForceErr = true;
					throw Err(E_OPEN, fname);
					return;
				}
			if (pass < 2) {

			if (FileLevel > 0)	// was == 1
				File[FileNum].lst = new SymbolTable(200);
			else
				File[FileNum].lst = NULL;
		}
		if (FileLevel > 0)	// was == 1
			localSymTbl = File[FileNum].lst;

		// echo filename
		fprintf(fpErr, "File: %s\r\n", fname);
		fprintf(fpErr, verstr2);
		fputs("\r\n", fpErr);
		page = 1;
		col = 1;

		if (isGenerationPass()) {
			bFirstObj = true;

			if(fListing) {
				time(&tim);
				fprintf(fpList, verstr, ctime(&tim), page);
				fputs(fname, fpList);
				fputs("\r\n\r\n", fpList);
			}
		}

		ibuf = File[FileNum].getBuf();
		getCpu()->getOp()->setInput(ibuf);
		ibuf->rewind();
		// Loop processing lines from file.
		while(1)
		{
//			p1 = ibuf->getPtr();		// save off start of line
			p1 = ibuf->ndx();
			if (ibuf->peekCh() == '\0') {
				break;
			}
			col = 1;
			if (!lineExpanded) {
				InputLine++;
				lineno++;
			}

			File[CurFileNum].LastLine = lineno;

			sol = p1;
			if(processLine() != TRUE)
				Err(E_INV);

			// Only output on second pass
			if (isGenerationPass() && fListing) {
//				if (col < SRC_COL)  // && col > 1)
				{
	//				fprintf(fpList, "%*s", SRC_COL-col, ""); // Tab out listing area
					OutListLine();
				}
			}
		}
		ibuf->rewind();

		if (isGenerationPass() && fListing)
			fputc('\f', fpList); // form feed
	}


	/* ---------------------------------------------------------------
   		Description :
			Searches and substitutes macro text for macro
		identifiers. We don't want to perform substitutions while
		inside comments	or quotes.
	--------------------------------------------------------------- */

	void Assembler::SearchAndSub()
	{
		Macro tmacr, *mp;
		char *sptr, *eptr, *sptr1;
		String *plist[MAX_MACRO_PARMS];
		char nbuf[NAME_MAX+1];
		int na;
		int idlen = 0;
		int slen, tomove;
		int ic1, ic2, iq;
		int SkipNextIdentifier = 0;
		char ch;
		int indx;
		int startndx;

	//   printf("Search and Sub:");
		// Copy global comment indicators
		ic1 = InComment;
		ic2 = InComment2;
		startndx = ibuf->ndx();
		// iq should be 0 coming in since we SearchAndSub at start of line processing.
		iq = 0;
		while (ibuf->peekCh()) {

			if (ic2) {
				while(1) {
					if (ibuf->peekCh() == '*' && ibuf->peekCh(1) == '/') {
						ic2--;
						ibuf->nextCh();
						goto EndOfLoop;
					}
					ch = ibuf->nextCh();
					if (ch < 1 || ch == '\n')
						goto EndOfLoop2;
				}
			}

			if (ic1) {
				while(1) {
					if (ibuf->peekCh() == CommentChar) {
						--ic1;
						goto EndOfLoop;
					}
					ch = ibuf->nextCh();
					if (ch < 1 || ch == '\n')
						goto EndOfLoop2;
				}
			}

			// Comment to EOL ?
			if ((ibuf->peekCh() == '/' && ibuf->peekCh(1) == '/') || ibuf->peekCh() == ';') {
				while(1) {
					ch = ibuf->nextCh();
					if (ch < 1 || ch == '\n')
						goto EndOfLoop2;
				}
			}

			if (ibuf->peekCh() == '"') {
				ibuf->nextCh();
				while(1) {
					ch = ibuf->nextCh();
					if (ch < 1 || ch == '\n')
						goto EndOfLoop2;
					if (ch == '"')
						goto EndOfLoop;
				}
			}
	      
				if (ibuf->peekCh() == '\'') {
					ibuf->nextCh();
					while(1) {
						ch = ibuf->nextCh();
						if (ch < 1 || ch == '\n')
							goto EndOfLoop2;
						if (ch == '\'')
							goto EndOfLoop;
					}
				}

				if (ibuf->peekCh() == '\n') {
					ibuf->nextCh();
					goto EndOfLoop2;
				}

				// Block comment
				if (ibuf->peekCh() == '/' && ibuf->peekCh(1) == '*') {
					ic2++;
					ibuf->nextCh();
					ibuf->nextCh();
					continue;
				}

			sptr1 = ibuf->getPtr();
			idlen = ibuf->getIdentifier(&sptr, &eptr); // look for an identifier
			if (idlen) {
				indx = sptr-ibuf->getBuf();
				if ((strncmp(sptr, "comment", 7)==0) && !IsIdentChar(sptr[7])) {
					ic1++;
					CommentChar = ibuf->nextNonSpace();
					continue;
				}
				//    If macro definition found, we want to skip over the macro name
				// otherwise the macro will substitute for the macro name during the
				// second pass.
				if ((strnicmp(sptr, "macro", 5) == 0) && !IsIdentChar(sptr[5]))
					SkipNextIdentifier = TRUE;
				else {
					if (SkipNextIdentifier == TRUE)
						SkipNextIdentifier = FALSE;
					else {
						memset(nbuf, '\0', sizeof(nbuf));
						strncpy(nbuf, sptr, min(NAME_MAX, idlen));
						tmacr.setName(nbuf);
						mp = (Macro *)macroTbl->find(&tmacr);// if the identifier is a macro
						if (mp) {
							if (mp->Nargs() > 0) {
								na = ibuf->getParmList(plist);
								if (na != mp->Nargs())
									Err(E_MACROARG);
						}
						else
							na = 0;
						// slen = length of text substituted for
						slen = ibuf->getPtr() - sptr1;
						// tomove = number of characters to move
						//        = buffer size - current pointer position
						tomove = ibuf->getSize() - (ibuf->getPtr() - ibuf->getBuf());
						// sptr = where to begin substitution
						// printf("sptr:%.*s|,slen=%d,tomove=%d\n", slen, sptr,slen,tomove);
						mp->sub(plist, ibuf, indx, slen, tomove);
					}
				}
			}
		}
	EndOfLoop:
		ibuf->nextCh();
	}
	EndOfLoop2:
		// restore pointer
		ibuf->moveTo(startndx);
	}


	void Assembler::setProcessor(String proc)
	{
		if (proc.equalsNoCase("6502"))
		{
			cpu = &optab6502;
			gProcessor.copy("6502");
		}
		else if (proc.equalsNoCase("W65C02"))
		{
			cpu = &optabW65C02;
			gProcessor.copy("W65C02");
		}
		else if (proc.equalsNoCase("W65C816S"))
		{
			cpu = &optabW65C816S;
			gProcessor.copy("W65C816S");
		}
		else if (proc.equalsNoCase("RTF65002"))
		{
			cpu = &optabRTF65002;
			gProcessor.copy("RTF65002");
		}
		else
		{
			cpu = &optabRTF65002;
			gProcessor.copy("RTF65002");
		}
	//????
		getCpu()->getOp()->setInput(ibuf);
	}
}

