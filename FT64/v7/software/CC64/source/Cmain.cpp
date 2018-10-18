// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Waterloo
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
/*
 *	68000 C compiler
 *
 *	Copyright 1984, 1985, 1986 Matthew Brandt.
 *  all commercial rights reserved.
 *
 *	This compiler is intended as an instructive tool for personal use. Any
 *	use for profit without the written consent of the author is prohibited.
 *
 *	This compiler may be distributed freely for non-commercial use as long
 *	as this notice stays intact. Please forward any enhancements or questions
 *	to:
 *
 *		Matthew Brandt
 *		Box 920337
 *		Norcross, Ga 30092
 */

void makename(char *s, char *e);
void summary();
int options(char *);
int openfiles(char *);
void closefiles();
int PreProcessFile(char *);

char            infile[256],
                listfile[256],
                outfile[256],
				outfileG[256];
std::string	dbgfile;

extern TABLE    tagtable;
int		mainflag;
extern int      total_errors;
int uctran_off;
extern int lstackptr;

Compiler compiler;

int main(int argc, char **argv)
{
	opt_nopeep = FALSE;
	uctran_off = 0;
	optimize =1;
	exceptions=1;
	cpu.SupportsPop = false;
	cpu.SupportsPush = false;
	cpu.SupportsLink = false;
	cpu.SupportsUnlink = false;

//	printf("c64 starting...\r\n");
	while(--argc) {
    if( **++argv == '-')
      options(*argv);
		else {
			if (PreProcessFile(*argv) == -1)
				break;
			if( openfiles(*argv)) {
				lineno = 0;
				initsym();
	compiler.compile();
//				compile();
				summary();
				MBlk::ReleaseAll();
//				ReleaseGlobalMemory();
				closefiles();
			}
    }
    dfs.printf("<CmdNext>Next on command line (%d).</CmdNext>\n", argc);
  }
	//getchar();
	dfs.printf("<Exit></Exit>\n");
	dfs.close();
 	exit(0);
	return (0);
}

int	options(char *s)
{
    int nn;

	if (s[1]=='o') {
        for (nn = 2; s[nn]; nn++) {
            switch(s[nn]) {
            case 'r':     opt_noregs = TRUE; break;
			case 'p':     ::opt_nopeep = TRUE; break;
            case 'x':     opt_noexpr = TRUE; break;
			case 'c':	  opt_nocgo = TRUE; break;
            }
        }
        if (nn==2) {
            opt_noregs = TRUE;
            ::opt_nopeep = TRUE;
            opt_noexpr = TRUE;
			opt_nocgo = TRUE;
            optimize = FALSE;
        }
    }
	else if (s[1]=='f') {
		if (strcmp(&s[2],"no-exceptions")==0)
			exceptions = 0;
		if (strcmp(&s[2],"farcode")==0)
			farcode = 1;
	}
	else if (s[1]=='a') {
        address_bits = atoi(&s[2]);
    }
	else if (s[1]=='p') {
        if (strcmp(&s[2],"FISA64")==0) {
             gCpu = FISA64;
             regLR = 31;
             regPC = 29;
             regSP = 30;
             regFP = 27;
             regGP = 26;
             regXLR = 28;
             use_gp = TRUE;
        }
	}
	else if (s[1]=='w')
		wcharSupport = 0;
	else if (s[1]=='v') {
         if (s[2]=='0')
             verbose = 0;
         else
             verbose = 1;
    }
	else if (s[1] == 'r') {
		if (s[2] == 'v') {
			opt_vreg = TRUE;
			regSP = 1023;
			regFP = 1022;
			regLR = 1021;
			regXLR = 1020;
			regGP = 1019;
			regTP = 1018;
			regCLP = 1017;              // class pointer
			regPP = 1016;				// program pointer
			regZero = 0;
			regFirstTemp = 3;
			regLastTemp = 511;
			regFirstRegvar = 512;
			regLastRegvar = 979;
			regFirstArg = 980;
			regLastArg = 1011;
		}
		else
		{
			regSP = 31;
			regFP = 30;
			regLR = 29;
			regXLR = 28;
			regGP = 27;
			regTP = 26;
			regCLP = 25;                // class pointer
			regPP = 24;					// program pointer
			regZero = 0;
			regFirstTemp = 3;
			regLastTemp = 10;
			regFirstRegvar = 11;
			regLastRegvar = 17;
			regFirstArg = 18;
			regLastArg = 22;
		}
	}
    else if (s[1]=='S')
        mixedSource = TRUE;
	return 0;
}

int PreProcessFile(char *nm)
{
	static char outname[1000];
	static char sysbuf[500];

	strcpy_s(outname, sizeof(outname), nm);
	makename(outname,".fpp");
	snprintf(sysbuf, sizeof(sysbuf), "fpp -b %s %s", nm, outname);
	return system(sysbuf);
}

int openfiles(char *s)
{
	char *p;
        strcpy_s(infile,sizeof(infile),s);
        strcpy_s(listfile,sizeof(listfile),s);
        strcpy_s(outfile,sizeof(outfile),s);
  dbgfile = s;

		//strcpy(outfileG,s);
		_splitpath(s,NULL,NULL,nmspace[0],NULL);
//		strcpy(nmspace[0],basename(s));
		p = strrchr(nmspace[0],'.');
		if (p)
			*p = '\0';
		makename(infile,".fpp");
        makename(listfile,".lis");
        makename(outfile,".s");
    dbgfile += ".xml";
		ifs = new std::ifstream();
		ifs->open(infile,std::ios::in);
/*
        if( (input = fopen(infile,"r")) == 0) {
				i = errno;
                printf(" cant open %s\n",infile);
                return 0;
                }
*/
/*
        ofl = creat(outfile,-1);
        if( ofl < 0 )
                {
                printf(" cant create %s\n",outfile);
                fclose(input);
                return 0;
                }
*/
        //oflg = _creat(outfileG,-1);
        //if( oflg < 0 )
        //        {
        //        printf(" cant create %s\n",outfileG);
        //        fclose(input);
        //        return 0;
        //        }
		ofs.open(outfile,std::ios::out|std::ios::trunc);
		dfs.open(dbgfile.c_str(),std::ios::out|std::ios::trunc);
		dfs.level = 1;
		dfs.puts("<title>C64D Compiler debug file</title>\n");
		dfs.level = 1;
		lfs.level = 1;
		ofs.level = 1;
/*
        if( (output = fdopen(ofl,"w")) == 0) {
                printf(" cant open %s\n",outfile);
                fclose(input);
                return 0;
                }
*/
        //if( (outputG = _fdopen(oflg,"w")) == 0) {
        //        printf(" cant open %s\n",outfileG);
        //        fclose(input);
        //        fclose(output);
        //        return 0;
        //        }
        try {
			lfs.open(listfile,std::ios::out|std::ios::trunc);
		}
		catch(...) {
			closefiles();
			return 0;
		}
/*
        if( (list = fopen(listfile,"w")) == 0) {
                printf(" cant open %s\n",listfile);
                fclose(input);
                fclose(output);
                //fclose(outputG);
                return 0;
                }
*/
        return 1;
}

void makename(char *s, char *e)
{
	int n;

	n = strlen(s);
	while(s[n]!='.' && n >= 0) n--;
	strcpy(&s[n],e);
	//while(*s != 0 && *s != '.')
 //       ++s;
 //   while(*s++ = *e++);
}

void summary()
{
//    if (verbose > 0)
  dfs.printf("<summary>\n");
    	printf("\n -- %d errors found.",total_errors);
    lfs.write("\f\n *** global scope typedef symbol table ***\n\n");
    ListTable(&gsyms[0],0);
    lfs.write("\n *** structures and unions ***\n\n");
    ListTable(&tagtable,0);
  dfs.printf("</summary>\n");
//	fflush(list);
}

void closefiles()
{ 
	dfs.printf("<closefiles>\n");
	ifs->close();
	delete ifs;
	dfs.printf("A");
	lfs.close();
	dfs.printf("B");
	ofs.close();
	dfs.printf("C");
	dfs.printf("</closefiles>\n");
}

char *GetNamespace()
{
	return nmspace[0];
//	return nmspace[incldepth];
}
