// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2015  Robert Finch, Stratford
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
#include        <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#define _GNU_SOURCE
#include <string.h>
#include <libgen.h>
#include <inttypes.h>
#include        "c.h"
#include        "expr.h"
#include        "gen.h"
#include        "cglbdec.h"

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

extern TABLE    tagtable;
int		mainflag;
extern int      total_errors;
int uctran_off;
extern int lstackptr;

int main(int argc, char **argv)
{
	uctran_off = 0;
	optimize =1;
	exceptions=1;
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
				memset(gsyms,0,sizeof(gsyms));
				memset(&defsyms,0,sizeof(defsyms));
				memset(&tagtable,0,sizeof(tagtable));
				getch();
				lstackptr = 0;
				lastst = 0;
				NextToken();
				compile();
				summary();
				ReleaseGlobalMemory();
				closefiles();
			}
        }
    }
	//getchar();
	return 0;
}

int	options(char *s)
{
    int nn;

	if (s[1]=='o') {
        for (nn = 2; s[nn]; nn++) {
            switch(s[nn]) {
            case 'r':     opt_noregs = TRUE; break;
            case 'p':     opt_nopeep = TRUE; break;
            case 'x':     opt_noexpr = TRUE; break;
            }
        }
        if (nn==2) {
            opt_noregs = TRUE;
            opt_nopeep = TRUE;
            opt_noexpr = TRUE;
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
		if (strcmp(&s[2],"Thor")==0) {
			gCpu = THOR;
			regXLR = 11;	// branch register
		}
		else if (strcmp(&s[2],"Raptor64")==0) {
			gCpu = RAPTOR64;
			regSP = 30;
			regPC = 29;
			regBP = 27;
			regXLR = 28;
			regLR = 31;
		}
		else if (strcmp(&s[2],"816")==0) {
             gCpu = W65C816;
             regSP = 30 * 4 + 128;
             regBP = 27 * 4 + 128;
             regXLR = 28 * 4 + 128;
             regLR = 31 * 4 + 128;
        }
        else if (strcmp(&s[2],"FISA64")==0) {
             gCpu = FISA64;
             regLR = 31;
             regPC = 29;
             regSP = 30;
             regBP = 27;
             regXLR = 28;
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
	return 0;
}

int PreProcessFile(char *nm)
{
	static char outname[1000];
	static char sysbuf[1000];

	strcpy(outname, nm);
	makename(outname,".fpp");
	sprintf(sysbuf, "fpp -b %s %s", nm, outname);
	return system(sysbuf);
}

int     openfiles(char *s)
{
	int     ofl,oflg;
	int i;
	char *p;
        strcpy(infile,s);
        strcpy(listfile,s);
        strcpy(outfile,s);
		//strcpy(outfileG,s);
		//_splitpath(s,NULL,NULL,nmspace[0],NULL);
		strcpy(nmspace[0],basename(s));
		p = strrchr(nmspace[0],'.');
		if (p)
			*p = '\0';
		makename(infile,".fpp");
        makename(listfile,".lis");
        makename(outfile,".s");
        if( (input = fopen(infile,"r")) == 0) {
                printf(" cant open %s\n",infile);
                return 0;
                }
        ofl = creat(outfile,-1);
        if( ofl < 0 )
                {
                printf(" cant create %s\n",outfile);
                fclose(input);
                return 0;
                }
        //oflg = _creat(outfileG,-1);
        //if( oflg < 0 )
        //        {
        //        printf(" cant create %s\n",outfileG);
        //        fclose(input);
        //        return 0;
        //        }
        if( (output = fdopen(ofl,"w")) == 0) {
                printf(" cant open %s\n",outfile);
                fclose(input);
                return 0;
                }
        //if( (outputG = _fdopen(oflg,"w")) == 0) {
        //        printf(" cant open %s\n",outfileG);
        //        fclose(input);
        //        fclose(output);
        //        return 0;
        //        }
        if( (list = fopen(listfile,"w")) == 0) {
                printf(" cant open %s\n",listfile);
                fclose(input);
                fclose(output);
                //fclose(outputG);
                return 0;
                }
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
    	printf("\n -- %d errors found.",total_errors);
    fprintf(list,"\f\n *** global scope typedef symbol table ***\n\n");
    ListTable(&gsyms[0],0);
    fprintf(list,"\n *** structures and unions ***\n\n");
    ListTable(&tagtable,0);
	fflush(list);
}

void closefiles()
{       
	fclose(input);
    fclose(output);
	//fclose(outputG);
    fclose(list);
}

char *GetNamespace()
{
	return nmspace[0];
//	return nmspace[incldepth];
}
