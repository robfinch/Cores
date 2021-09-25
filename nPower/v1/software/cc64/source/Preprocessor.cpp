// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// C64 - 'C' derived language compiler
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

std::ifstream *inclfile[10];
//int             incldepth = 0;
int             inclline[10];
char            *lptr;
int endifCount = 0;
extern void searchenv(char *filename, int, char *envname, char *pathname, int);
int dodefine();
int doinclude();
extern void getFilename();

int doifdef();
int doifndef();
int doendif();

int preprocess()
{   
	++lptr;
    lastch = ' ';
    NextToken();               /* get first word on line */
    if( lastst != id ) {
            error(ERR_PREPROC);
            return getline(incldepth == 0);
            }
    if( strcmp(lastkw,"include") == 0 )
            return doinclude();
    else if( strcmp(lastkw,"define") == 0 )
            return dodefine();
    else if (strcmp(lastkw,"ifdef")==0)
			return doifdef();
    else if (strcmp(lastkw,"ifndef")==0)
			return doifndef();
    else if (strcmp(lastkw,"endif")==0)
			return doendif();
	else
	{
        error(ERR_PREPROC);
        return getline(incldepth == 0);
    }
}

int doinclude()
{
	int     rv;
	static char pathname[5000];
	char *p;

	parseEsc = FALSE;
    NextToken();               /* get file to include */
	if (lastst==lt) {
		getFilename();
		searchenv(laststr, sizeof(laststr), "C64INC", pathname, sizeof(pathname));
	}
	else
		strcpy_s(pathname, sizeof(pathname), laststr);
	parseEsc = TRUE;
    if( lastst != sconst ) {
            error(ERR_INCLFILE);
            return getline(incldepth == 0);
            }
    inclline[incldepth] = lineno;
    inclfile[incldepth++] = ifs;  /* push current input file */
	ifs = new std::ifstream();
    printf("%s\r\n", pathname);
    if( ifs == nullptr ) {
            ifs = inclfile[--incldepth];
            error(ERR_CANTOPEN);
            rv = getline(incldepth == 0);
            }
    else    {
			ifs->open(pathname,std::ios::in);
			_splitpath_s(pathname,NULL,0,NULL,0,nmspace[incldepth],100,NULL,0);
//			strcpy(nmspace[incldepth],basename(pathname));
			p = strrchr(nmspace[incldepth],'.');
			if (p) *p = '\0';
            rv = getline(incldepth == 1);
            lineno = -32768;        /* dont list include files */
            }
    return rv;
}

int dodefine()
{   
	SYM *sp;
	
    NextToken();               /* get past #define */
    if( lastst != id ) {
            error(ERR_DEFINE);
            return getline(incldepth == 0);
            }
    ++global_flag;          /* always do #define as globals */
    sp = allocSYM();
    sp->SetName(std::string(lastid));
    sp->value.s = my_strdup(lptr-1);
    defsyms.insert(sp);
    --global_flag;
    return getline(incldepth == 0);
}

int doifdef()
{
	SYM *sp;
	int rv;
	char *lne;

	lne = inpline;
	NextToken();
    if( lastst != id ) {
        error(ERR_DEFINE);
        return getline(incldepth == 0);
    }
	endifCount++;
	sp = defsyms.Find(lastid,false);
	if (sp == NULL) {
		do
			rv = getline(incldepth == 0);
		while (rv==0 && endifCount!=0);
	}
    return getline(incldepth == 0);
}

int doifndef()
{
	SYM *sp;
	int rv;

	NextToken();
    if( lastst != id ) {
        error(ERR_DEFINE);
        return getline(incldepth == 0);
    }
	endifCount++;
	sp = defsyms.Find(lastid,false);
	if (sp != NULL) {
		do
			rv = getline(incldepth == 0);
		while (rv==0 && endifCount!=0);
	}
    return getline(incldepth == 0);
}

int doendif()
{
	endifCount--;
    return getline(incldepth == 0);
}
